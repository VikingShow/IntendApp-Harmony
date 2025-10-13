// File: entry/src/main/ets/services/ProjectGroupService.ets
/**
 * 项目群管理服务模块
 * 
 * 本模块是项目群管理的核心业务逻辑层，负责统一管理项目群的生命周期和操作。
 * 完全复用 ProjectManager 的设计模式，将项目群操作封装为可复用的服务。
 * 
 * 主要功能：
 * 1. 项目群生命周期管理：创建、加载、保存、删除项目群
 * 2. 项目引用管理：添加、更新、删除、移动项目引用
 * 3. 依赖关系管理：建立、删除项目间的依赖关系
 * 4. 模板支持：基于模板快速创建项目群
 * 5. 自动保存：提供防抖的自动保存机制
 * 6. 事件通知：通过事件总线通知状态变化
 * 
 * 架构设计：
 * - 单例模式：全局唯一的项目群管理实例
 * - 服务容器：通过依赖注入管理服务依赖
 * - 事件驱动：使用事件总线实现松耦合通信
 * - 状态管理：维护当前项目群状态
 * - 错误处理：统一的错误处理和用户提示机制
 * 
 * 核心服务依赖：
 * - StorageService：项目群数据持久化
 * - EventBus：事件通信
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-01
 */

import { ProjectGroup, ProjectRef, ProjectDependency } from '../model/ProjectGroup';
import { StorageService } from '../services/StorageService';
import { EventBus, EventArgs } from '../core/EventBus';
import { ErrorHandler, ErrorType } from '../core/ErrorHandler';
import { PromptAction } from '@kit.ArkUI';

/**
 * 项目群状态接口
 * 定义项目群管理的当前状态信息
 */
export interface ProjectGroupState {
  /** 当前项目群对象 */
  projectGroup: ProjectGroup | null;
  /** 当前选中的项目引用 */
  selectedProjectRef: ProjectRef | null;
  /** 是否正在加载 */
  isLoading: boolean;
  /** 错误信息 */
  error: string | null;
}

/**
 * 项目群操作接口
 * 定义所有可用的项目群操作命令
 */
export interface ProjectGroupActions {
  /** 加载项目群 */
  loadProjectGroup: (groupId: string) => Promise<void>;
  /** 创建新项目群 */
  createNewProjectGroup: (name?: string) => Promise<void>;
  /** 保存项目群 */
  saveProjectGroup: () => Promise<void>;
  /** 更新项目群名称 */
  updateProjectGroupName: (name: string) => void;
  /** 添加项目引用 */
  addProjectRef: (projectId: string, projectName: string, x?: number, y?: number) => void;
  /** 更新项目引用 */
  updateProjectRef: (projectId: string, updates: Partial<ProjectRef>) => void;
  /** 删除项目引用 */
  deleteProjectRef: (projectId: string) => void;
  /** 选择项目引用 */
  selectProjectRef: (projectRef: ProjectRef | null) => void;
  /** 添加项目间依赖关系 */
  addDependency: (fromId: string, toId: string) => void;
  /** 删除项目间依赖关系 */
  removeDependency: (fromId: string, toId: string) => void;
  /** 移动项目引用位置 */
  moveProjectRef: (projectId: string, x: number, y: number) => void;
  /** 立即移动项目引用位置（不创建命令） */
  moveProjectRefImmediate: (projectId: string, x: number, y: number) => void;
}

/**
 * 项目群自定义事件
 */
export class ProjectGroupEvents {
  /** 项目群已加载 */
  static readonly GROUP_LOADED = 'project_group_loaded';
  /** 项目群已保存 */
  static readonly GROUP_SAVED = 'project_group_saved';
  /** 项目引用已选择 */
  static readonly PROJECT_REF_SELECTED = 'project_ref_selected';
  /** 项目引用已更新 */
  static readonly PROJECT_REF_UPDATED = 'project_ref_updated';
  /** 项目引用已删除 */
  static readonly PROJECT_REF_DELETED = 'project_ref_deleted';
}

/**
 * 位置信息接口
 */
interface PositionInfo {
  x: number;
  y: number;
}

/**
 * 项目群管理服务类
 * 
 * 采用单例模式设计，提供项目群的完整生命周期管理。
 * 完全复用 ProjectManager 的设计模式和架构。
 */
export class ProjectGroupService {
  private static instance: ProjectGroupService;
  private storageService: StorageService | null = null;
  private errorHandler: ErrorHandler;
  private eventBus: EventBus;
  private autoSaveTimer: number | null = null;
  private uiContext: UIContext | null = null;

  // 当前状态
  private currentState: ProjectGroupState = {
    projectGroup: null,
    selectedProjectRef: null,
    isLoading: false,
    error: null
  };

  // 记录拖动开始时的位置（用于创建撤销/重做命令）
  private dragStartPositions: Map<string, PositionInfo> = new Map();

  private constructor() {
    this.errorHandler = ErrorHandler.getInstance();
    this.eventBus = EventBus.getInstance();
  }

  public static getInstance(): ProjectGroupService {
    if (!ProjectGroupService.instance) {
      ProjectGroupService.instance = new ProjectGroupService();
    }
    return ProjectGroupService.instance;
  }

  /**
   * 初始化服务
   */
  public async initialize(filesDir: string): Promise<void> {
    try {
      this.storageService = StorageService.getInstance(filesDir);
      console.log('[ProjectGroupService] 初始化完成');
    } catch (error) {
      this.errorHandler.handle(error as Error, 'ProjectGroupService.initialize', ErrorType.BUSINESS);
      throw new Error('ProjectGroupService initialization failed');
    }
  }

  /**
   * 设置UI上下文
   */
  public setContext(ctx: UIContext): void {
    this.uiContext = ctx;
  }

  /**
   * 获取当前状态
   */
  public getState(): ProjectGroupState {
    const state: ProjectGroupState = {
      projectGroup: this.currentState.projectGroup,
      selectedProjectRef: this.currentState.selectedProjectRef,
      isLoading: this.currentState.isLoading,
      error: this.currentState.error
    };
    return state;
  }

  /**
   * 获取所有操作方法
   */
  public getActions(): ProjectGroupActions {
    return {
      loadProjectGroup: (groupId: string) => this.loadProjectGroup(groupId),
      createNewProjectGroup: (name?: string) => this.createNewProjectGroup(name),
      saveProjectGroup: () => this.saveProjectGroup(),
      updateProjectGroupName: (name: string) => this.updateProjectGroupName(name),
      addProjectRef: (projectId: string, projectName: string, x?: number, y?: number) => 
        this.addProjectRef(projectId, projectName, x, y),
      updateProjectRef: (projectId: string, updates: Partial<ProjectRef>) => 
        this.updateProjectRef(projectId, updates),
      deleteProjectRef: (projectId: string) => this.deleteProjectRef(projectId),
      selectProjectRef: (projectRef: ProjectRef | null) => this.selectProjectRef(projectRef),
      addDependency: (fromId: string, toId: string) => this.addDependency(fromId, toId),
      removeDependency: (fromId: string, toId: string) => this.removeDependency(fromId, toId),
      moveProjectRef: (projectId: string, x: number, y: number) => this.moveProjectRef(projectId, x, y),
      moveProjectRefImmediate: (projectId: string, x: number, y: number) => 
        this.moveProjectRefImmediate(projectId, x, y)
    };
  }

  // ==================== 私有方法实现 ====================

  /**
   * 加载项目群
   */
  private async loadProjectGroup(groupId: string): Promise<void> {
    if (!this.storageService) {
      this.errorHandler.handleBusinessError('存储服务未初始化', 'ProjectGroupService.loadProjectGroup');
      return;
    }

    this.currentState.isLoading = true;
    this.currentState.error = null;

    try {
      const group = await this.storageService.getProjectGroup(groupId);
      
      if (group) {
        this.currentState.projectGroup = group;
        this.currentState.selectedProjectRef = null;
        this.eventBus.emit(ProjectGroupEvents.GROUP_LOADED, group);
        
        if (this.uiContext) {
          const promptAction = this.uiContext.getPromptAction();
          promptAction.showToast({ message: `项目群 "${group.name}" 已加载` });
        }
      } else {
        this.errorHandler.handleBusinessError(`项目群 ${groupId} 不存在`, 'ProjectGroupService.loadProjectGroup');
      }
    } catch (error) {
      this.errorHandler.handleStorageError(error as Error, 'ProjectGroupService.loadProjectGroup');
    } finally {
      this.currentState.isLoading = false;
    }
  }

  /**
   * 创建新项目群
   */
  private async createNewProjectGroup(name: string = '新项目群'): Promise<void> {
    try {
      const newGroup = new ProjectGroup(undefined, name);
      this.currentState.projectGroup = newGroup;
      this.currentState.selectedProjectRef = null;
      this.eventBus.emit(ProjectGroupEvents.GROUP_LOADED, newGroup);
      
      if (this.storageService) {
        await this.saveProjectGroup();
      }
    } catch (error) {
      this.errorHandler.handle(error as Error, 'ProjectGroupService.createNewProjectGroup', ErrorType.BUSINESS);
    }
  }

  /**
   * 保存项目群
   */
  private async saveProjectGroup(): Promise<void> {
    if (!this.currentState.projectGroup) {
      this.errorHandler.handleBusinessError('没有可保存的项目群', 'ProjectGroupService.saveProjectGroup');
      return;
    }

    if (!this.storageService) {
      this.errorHandler.handleBusinessError('存储服务未初始化', 'ProjectGroupService.saveProjectGroup');
      return;
    }

    try {
      this.currentState.projectGroup.lastModified = Date.now();
      await this.storageService.saveProjectGroup(this.currentState.projectGroup);
      this.eventBus.emit(ProjectGroupEvents.GROUP_SAVED, this.currentState.projectGroup);
    } catch (error) {
      this.errorHandler.handleStorageError(error as Error, 'ProjectGroupService.saveProjectGroup');
    }
  }

  /**
   * 更新项目群名称
   */
  private updateProjectGroupName(name: string): void {
    if (this.currentState.projectGroup) {
      this.currentState.projectGroup.name = name;
      this.eventBus.emit(ProjectGroupEvents.GROUP_SAVED, this.currentState.projectGroup);
    }
  }

  /**
   * 添加项目引用
   */
  private addProjectRef(projectId: string, projectName: string, x: number = 50, y: number = 50): void {
    if (!this.currentState.projectGroup) return;

    // 检查是否已存在
    const exists = this.currentState.projectGroup.projectRefs.some(ref => ref.id === projectId);
    if (exists) {
      if (this.uiContext) {
        const promptAction = this.uiContext.getPromptAction();
        promptAction.showToast({ message: '该项目已在项目群中' });
      }
      return;
    }

    const newProjectRef: ProjectRef = {
      id: projectId,
      name: projectName,
      x: x,
      y: y
    };

    this.currentState.projectGroup.addProjectRef(newProjectRef);
    this.eventBus.emit(ProjectGroupEvents.GROUP_SAVED, this.currentState.projectGroup);
    
    if (this.uiContext) {
      const promptAction = this.uiContext.getPromptAction();
      promptAction.showToast({ message: '项目已添加到项目群' });
    }

    // 自动保存
    this.autoSaveProjectGroup();
  }

  /**
   * 更新项目引用
   */
  private updateProjectRef(projectId: string, updates: Partial<ProjectRef>): void {
    if (!this.currentState.projectGroup) return;

    const projectRef = this.currentState.projectGroup.projectRefs.find(ref => ref.id === projectId);
    if (!projectRef) return;

    // 应用更新（手动复制属性）
    if (updates.name !== undefined) projectRef.name = updates.name;
    if (updates.x !== undefined) projectRef.x = updates.x;
    if (updates.y !== undefined) projectRef.y = updates.y;
    if (updates.earlyStart !== undefined) projectRef.earlyStart = updates.earlyStart;
    if (updates.earlyFinish !== undefined) projectRef.earlyFinish = updates.earlyFinish;
    if (updates.lateStart !== undefined) projectRef.lateStart = updates.lateStart;
    if (updates.lateFinish !== undefined) projectRef.lateFinish = updates.lateFinish;
    if (updates.isCritical !== undefined) projectRef.isCritical = updates.isCritical;

    // 更新选中的项目引用
    if (this.currentState.selectedProjectRef?.id === projectId) {
      const updatedRef: ProjectRef = {
        id: projectRef.id,
        name: projectRef.name,
        x: projectRef.x,
        y: projectRef.y,
        earlyStart: projectRef.earlyStart,
        earlyFinish: projectRef.earlyFinish,
        lateStart: projectRef.lateStart,
        lateFinish: projectRef.lateFinish,
        isCritical: projectRef.isCritical
      };
      this.currentState.selectedProjectRef = updatedRef;
    }

    this.eventBus.emit(ProjectGroupEvents.PROJECT_REF_UPDATED, projectRef);
    this.eventBus.emit(ProjectGroupEvents.GROUP_SAVED, this.currentState.projectGroup);
    
    // 自动保存
    this.autoSaveProjectGroup();
  }

  /**
   * 删除项目引用
   */
  private deleteProjectRef(projectId: string): void {
    if (!this.currentState.projectGroup) return;

    // 如果删除的是选中项目引用，清空选择
    if (this.currentState.selectedProjectRef?.id === projectId) {
      this.currentState.selectedProjectRef = null;
    }

    this.currentState.projectGroup.removeProjectRef(projectId);
    
    this.eventBus.emit(ProjectGroupEvents.PROJECT_REF_DELETED, projectId);
    this.eventBus.emit(ProjectGroupEvents.GROUP_SAVED, this.currentState.projectGroup);
  }

  /**
   * 选择项目引用
   */
  private selectProjectRef(projectRef: ProjectRef | null): void {
    this.currentState.selectedProjectRef = projectRef;
    this.eventBus.emit(ProjectGroupEvents.PROJECT_REF_SELECTED, projectRef);
  }

  /**
   * 添加项目间依赖关系
   */
  private addDependency(fromId: string, toId: string): void {
    if (!this.currentState.projectGroup) return;

    // 检查依赖是否已存在
    const exists = this.currentState.projectGroup.dependencies.some(
      dep => dep.fromId === fromId && dep.toId === toId
    );

    if (!exists) {
      this.currentState.projectGroup.addDependency(fromId, toId);
      
      if (this.uiContext) {
        const promptAction = this.uiContext.getPromptAction();
        promptAction.showToast({ message: '依赖已创建' });
      }
    } else {
      if (this.uiContext) {
        const promptAction = this.uiContext.getPromptAction();
        promptAction.showToast({ message: '该依赖已存在' });
      }
    }
  }

  /**
   * 删除项目间依赖关系
   */
  private removeDependency(fromId: string, toId: string): void {
    if (!this.currentState.projectGroup) return;

    this.currentState.projectGroup.removeDependency(fromId, toId);
  }

  /**
   * 移动项目引用位置（拖拽结束时调用）
   */
  private moveProjectRef(projectId: string, x: number, y: number): void {
    if (!this.currentState.projectGroup) return;

    const projectRef = this.currentState.projectGroup.projectRefs.find(ref => ref.id === projectId);
    if (projectRef) {
      // 更新位置
      projectRef.x = x;
      projectRef.y = y;
      
      // 更新选中项目引用的显示
      if (this.currentState.selectedProjectRef?.id === projectId) {
        const updatedRef: ProjectRef = {
          id: projectRef.id,
          name: projectRef.name,
          x: projectRef.x,
          y: projectRef.y,
          earlyStart: projectRef.earlyStart,
          earlyFinish: projectRef.earlyFinish,
          lateStart: projectRef.lateStart,
          lateFinish: projectRef.lateFinish,
          isCritical: projectRef.isCritical
        };
        this.currentState.selectedProjectRef = updatedRef;
      }

      // 清除拖动开始位置记录
      this.dragStartPositions.delete(projectId);
      
      // 自动保存
      this.autoSaveProjectGroup();
    }
  }

  /**
   * 立即移动项目引用位置（拖拽过程中调用）
   */
  private moveProjectRefImmediate(projectId: string, x: number, y: number): void {
    if (!this.currentState.projectGroup) return;

    const projectRef = this.currentState.projectGroup.projectRefs.find(ref => ref.id === projectId);
    if (projectRef) {
      // 如果这是第一次移动，记录初始位置
      if (!this.dragStartPositions.has(projectId)) {
        const position: PositionInfo = { x: projectRef.x, y: projectRef.y };
        this.dragStartPositions.set(projectId, position);
      }
      
      // 更新位置
      projectRef.x = x;
      projectRef.y = y;
      
      // 更新选中项目引用的显示
      if (this.currentState.selectedProjectRef?.id === projectId) {
        const updatedRef: ProjectRef = {
          id: projectRef.id,
          name: projectRef.name,
          x: projectRef.x,
          y: projectRef.y,
          earlyStart: projectRef.earlyStart,
          earlyFinish: projectRef.earlyFinish,
          lateStart: projectRef.lateStart,
          lateFinish: projectRef.lateFinish,
          isCritical: projectRef.isCritical
        };
        this.currentState.selectedProjectRef = updatedRef;
      }
    }
  }

  /**
   * 自动保存项目群（带防抖）
   */
  private autoSaveProjectGroup(): void {
    // 清除之前的定时器
    if (this.autoSaveTimer !== null) {
      clearTimeout(this.autoSaveTimer);
    }
    
    // 设置新的定时器，延迟500ms后保存
    this.autoSaveTimer = setTimeout(async () => {
      if (this.currentState.projectGroup && this.storageService) {
        try {
          console.log(`[ProjectGroupService] 开始自动保存项目群: ${this.currentState.projectGroup.name}`);
          await this.storageService.saveProjectGroup(this.currentState.projectGroup);
          console.log(`[ProjectGroupService] 项目群已自动保存: ${this.currentState.projectGroup.name}`);
        } catch (error) {
          console.error(`[ProjectGroupService] 自动保存失败:`, error);
          this.errorHandler.handleStorageError(error as Error, 'ProjectGroupService.autoSaveProjectGroup');
        }
      }
      this.autoSaveTimer = null;
    }, 500);
  }

  /**
   * 清理资源
   */
  public cleanup(): void {
    if (this.autoSaveTimer !== null) {
      clearTimeout(this.autoSaveTimer);
      this.autoSaveTimer = null;
    }
  }
}
