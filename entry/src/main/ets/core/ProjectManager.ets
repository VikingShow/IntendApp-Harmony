// File: entry/src/main/ets/core/ProjectManager.ets
/**
 * 项目管理核心模块
 * 
 * 本模块是EasyFlow应用的核心业务逻辑层，负责统一管理项目的生命周期和操作。
 * 采用命令模式设计，将项目操作封装为可复用的命令对象，提供清晰的API接口。
 * 
 * 主要功能：
 * 1. 项目生命周期管理：创建、加载、保存、删除项目
 * 2. 任务管理：添加、更新、删除、移动任务
 * 3. 依赖关系管理：建立、删除任务间的依赖关系
 * 4. 关键路径计算：自动计算和更新项目关键路径
 * 5. 模板支持：基于模板快速创建项目
 * 6. 自动保存：提供防抖的自动保存机制
 * 7. 事件通知：通过事件总线通知状态变化
 * 
 * 架构设计：
 * - 命令模式：将操作封装为命令，支持撤销和重做
 * - 服务容器：通过依赖注入管理服务依赖
 * - 事件驱动：使用事件总线实现松耦合通信
 * - 状态管理：与AppState集成，实现响应式状态更新
 * - 错误处理：统一的错误处理和用户提示机制
 * 
 * 核心服务依赖：
 * - StorageService：项目数据持久化
 * - CriticalPathService：关键路径计算
 * - TemplateService：项目模板管理
 * - EventBus：事件通信
 * - ErrorHandler：错误处理
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode, ChecklistItem, Dependency } from '../model/ProjectData';
import { StorageService } from '../services/StorageService';
import { CriticalPathService, TaskWithDuration, CriticalPathResult } from '../services/CriticalPathService';
import { TemplateService } from '../services/TemplateService';
import { EventBus, Events } from './EventBus';
import { AppState } from './AppState';
import { ErrorHandler, ErrorType } from './ErrorHandler';
import { ServiceContainer } from './ServiceContainer';
import promptAction from '@ohos.promptAction';

/**
 * 项目状态接口
 * 定义项目管理的当前状态信息
 */
export interface ProjectState {
  /** 当前项目对象 */
  project: Project | null;
  /** 当前选中的任务 */
  selectedTask: TaskNode | null;
  /** 是否正在加载 */
  isLoading: boolean;
  /** 错误信息 */
  error: string | null;
}

/**
 * 项目操作接口
 * 定义所有可用的项目操作命令
 */
export interface ProjectActions {
  /** 加载项目 */
  loadProject: (projectId: string) => Promise<void>;
  /** 创建新项目 */
  createNewProject: (name?: string) => Promise<void>;
  /** 从模板创建项目 */
  createFromTemplate: (templateId: string, projectName: string) => Promise<void>;
  /** 保存项目 */
  saveProject: () => Promise<void>;
  /** 更新项目名称 */
  updateProjectName: (name: string) => void;
  /** 添加任务 */
  addTask: () => void;
  /** 更新任务 */
  updateTask: (taskId: string, updates: Partial<TaskNode>) => void;
  /** 删除任务 */
  deleteTask: (taskId: string) => void;
  /** 选择任务 */
  selectTask: (task: TaskNode | null) => void;
  /** 更新检查清单 */
  updateChecklist: (taskId: string, checklist: ChecklistItem[]) => void;
  /** 添加检查清单项 */
  addChecklistItem: (taskId: string, item: ChecklistItem) => void;
  /** 删除检查清单项 */
  deleteChecklistItem: (taskId: string, itemId: string) => void;
  /** 添加依赖关系 */
  addDependency: (fromId: string, toId: string) => void;
  /** 删除依赖关系 */
  removeDependency: (fromId: string, toId: string) => void;
  /** 计算关键路径 */
  calculateCriticalPath: () => void;
  /** 移动任务位置 */
  moveTask: (taskId: string, x: number, y: number) => void;
}

export class ProjectManager {
  private static instance: ProjectManager;
  private serviceContainer: ServiceContainer;
  private appState: AppState;
  private errorHandler: ErrorHandler;
  private eventBus: EventBus;
  private autoSaveTimer: number | null = null;

  private constructor() {
    this.serviceContainer = ServiceContainer.getInstance();
    this.appState = AppState.getInstance();
    this.errorHandler = ErrorHandler.getInstance();
    this.eventBus = EventBus.getInstance();
  }

  public static getInstance(): ProjectManager {
    if (!ProjectManager.instance) {
      ProjectManager.instance = new ProjectManager();
    }
    return ProjectManager.instance;
  }

  public async initialize(filesDir: string): Promise<void> {
    try {
      await this.serviceContainer.initialize(filesDir);
      console.log('[ProjectManager] 初始化完成');
    } catch (error) {
      this.errorHandler.handle(error as Error, 'ProjectManager.initialize', ErrorType.BUSINESS);
      const err = new Error('ProjectManager initialization failed');
      throw err;
    }
  }

  // 获取当前状态
  public getState(): ProjectState {
    return {
      project: this.appState.project,
      selectedTask: this.appState.selectedTask,
      isLoading: this.appState.isLoading,
      error: this.appState.error
    };
  }

  // 获取所有操作方法
  public getActions(): ProjectActions {
    return {
      loadProject: (projectId: string) => this.loadProject(projectId),
      createNewProject: (name?: string) => this.createNewProject(name),
      createFromTemplate: (templateId: string, projectName: string) => this.createFromTemplate(templateId, projectName),
      saveProject: () => this.saveProject(),
      updateProjectName: (name: string) => this.updateProjectName(name),
      addTask: () => this.addTask(),
      updateTask: (taskId: string, updates: Partial<TaskNode>) => this.updateTask(taskId, updates),
      deleteTask: (taskId: string) => this.deleteTask(taskId),
      selectTask: (task: TaskNode | null) => this.selectTask(task),
      updateChecklist: (taskId: string, checklist: ChecklistItem[]) => this.updateChecklist(taskId, checklist),
      addChecklistItem: (taskId: string, item: ChecklistItem) => this.addChecklistItem(taskId, item),
      deleteChecklistItem: (taskId: string, itemId: string) => this.deleteChecklistItem(taskId, itemId),
      addDependency: (fromId: string, toId: string) => this.addDependency(fromId, toId),
      removeDependency: (fromId: string, toId: string) => this.removeDependency(fromId, toId),
      calculateCriticalPath: () => this.calculateCriticalPath(),
      moveTask: (taskId: string, x: number, y: number) => this.moveTask(taskId, x, y)
    };
  }

  // 私有方法实现
  private async loadProject(projectId: string): Promise<void> {
    if (!this.serviceContainer.isInitialized()) {
      this.errorHandler.handleBusinessError('服务容器未初始化', 'ProjectManager.loadProject');
      return;
    }

    this.appState.setLoading(true);
    this.appState.clearError();

    try {
      const storageService = this.serviceContainer.get<StorageService>('storageService');
      const project = await storageService.getProject(projectId);
      
      if (project) {
        this.appState.setProject(project);
        this.appState.setSelectedTask(null);
        this.calculateCriticalPath();
        this.eventBus.emit(Events.PROJECT_LOADED, project);
        promptAction.showToast({ message: `项目 "${project.name}" 已加载` });
      } else {
        this.errorHandler.handleBusinessError(`项目 ${projectId} 不存在`, 'ProjectManager.loadProject');
      }
    } catch (error) {
      this.errorHandler.handleStorageError(error as Error, 'ProjectManager.loadProject');
    } finally {
      this.appState.setLoading(false);
    }
  }

  private async createNewProject(name: string = '新项目'): Promise<void> {
    try {
      const newProject = new Project(undefined, name);
      this.appState.setProject(newProject);
      this.appState.setSelectedTask(null);
      this.eventBus.emit(Events.PROJECT_LOADED, newProject);
      
      if (this.serviceContainer.isInitialized()) {
        await this.saveProject();
      }
    } catch (error) {
      this.errorHandler.handle(error as Error, 'ProjectManager.createNewProject', ErrorType.BUSINESS);
    }
  }

  private async createFromTemplate(templateId: string, projectName: string): Promise<void> {
    try {
      const templateService = this.serviceContainer.get<TemplateService>('templateService');
      const newProject = templateService.createProjectFromTemplate(templateId, projectName);
      this.appState.setProject(newProject);
      this.appState.setSelectedTask(null);
      this.eventBus.emit(Events.PROJECT_LOADED, newProject);
      
      if (this.serviceContainer.isInitialized()) {
        await this.saveProject();
      }
    } catch (error) {
      this.errorHandler.handle(error as Error, 'ProjectManager.createFromTemplate', ErrorType.BUSINESS);
    }
  }

  private async saveProject(): Promise<void> {
    if (!this.appState.project) {
      this.errorHandler.handleBusinessError('没有可保存的项目', 'ProjectManager.saveProject');
      return;
    }

    if (!this.serviceContainer.isInitialized()) {
      this.errorHandler.handleBusinessError('服务容器未初始化', 'ProjectManager.saveProject');
      return;
    }

    try {
      this.appState.project.lastModified = Date.now();
      const storageService = this.serviceContainer.get<StorageService>('storageService');
      await storageService.saveProject(this.appState.project);
      this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
      promptAction.showToast({ message: `项目 "${this.appState.project.name}" 已保存` });
    } catch (error) {
      this.errorHandler.handleStorageError(error as Error, 'ProjectManager.saveProject');
    }
  }

  private updateProjectName(name: string): void {
    if (this.appState.project) {
      this.appState.project.name = name;
      this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
    }
  }

  private addTask(): void {
    if (!this.appState.project) return;

    const today = new Date();
    const tomorrow = new Date();
    tomorrow.setDate(today.getDate() + 1);

    const newTask: TaskNode = {
      id: `task_${Date.now()}`,
      name: '新任务',
      startDate: today,
      endDate: tomorrow,
      checklist: [],
      x: 50,
      y: 50
    };

    this.appState.project.tasks = this.appState.project.tasks.concat([newTask]);
    this.calculateCriticalPath();
    this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
    promptAction.showToast({ message: '新任务已添加' });
  }

  private updateTask(taskId: string, updates: Partial<TaskNode>): void {
    if (!this.appState.project) return;

    const taskIndex = this.appState.project.tasks.findIndex(t => t.id === taskId);
    if (taskIndex === -1) return;

    // 更新任务属性
    const originalTask = this.appState.project.tasks[taskIndex];
    const updatedTask = this.copyTaskNode(originalTask);
    
    // 手动更新属性
    if (updates.name !== undefined) updatedTask.name = updates.name;
    if (updates.startDate !== undefined) updatedTask.startDate = updates.startDate;
    if (updates.endDate !== undefined) updatedTask.endDate = updates.endDate;
    if (updates.checklist !== undefined) updatedTask.checklist = updates.checklist.slice();
    if (updates.x !== undefined) updatedTask.x = updates.x;
    if (updates.y !== undefined) updatedTask.y = updates.y;
    if (updates.isCritical !== undefined) updatedTask.isCritical = updates.isCritical;
    if (updates.earlyStart !== undefined) updatedTask.earlyStart = updates.earlyStart;
    if (updates.earlyFinish !== undefined) updatedTask.earlyFinish = updates.earlyFinish;
    if (updates.lateStart !== undefined) updatedTask.lateStart = updates.lateStart;
    if (updates.lateFinish !== undefined) updatedTask.lateFinish = updates.lateFinish;
    
    this.appState.project.tasks[taskIndex] = updatedTask;

    // 更新selectedTask以保持同步
    if (this.appState.selectedTask?.id === taskId) {
      this.appState.setSelectedTask(this.copyTaskNode(updatedTask));
    }

    // 先触发任务更新事件
    this.eventBus.emit(Events.TASK_UPDATED, updatedTask);
    
    // 然后触发项目保存事件
    this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
    
    // 最后重新计算关键路径
    this.calculateCriticalPath();
    
    // 自动保存到存储
    this.autoSaveProject();
  }

  private deleteTask(taskId: string): void {
    if (!this.appState.project) return;

    if (this.appState.selectedTask?.id === taskId) {
      this.appState.setSelectedTask(null);
    }

    this.appState.project.tasks = this.appState.project.tasks.filter(t => t.id !== taskId);
    this.appState.project.dependencies = this.appState.project.dependencies.filter(
      d => d.fromId !== taskId && d.toId !== taskId
    );

    this.eventBus.emit(Events.TASK_DELETED, taskId);
    this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
    this.calculateCriticalPath();
  }

  private selectTask(task: TaskNode | null): void {
    this.appState.setSelectedTask(task);
    this.eventBus.emit(Events.TASK_SELECTED, task);
  }

  private updateChecklist(taskId: string, checklist: ChecklistItem[]): void {
    if (!this.appState.project) return;

    const updatedTask = this.appState.project.tasks.find(t => t.id === taskId);
    if (updatedTask) {
      console.log(`[ProjectManager] Updating checklist for task ${taskId}`);
      console.log(`[ProjectManager] Before: ${updatedTask.checklist.length} items`);
      
      updatedTask.checklist = checklist.slice();
      
      console.log(`[ProjectManager] After: ${updatedTask.checklist.length} items`);
      
      // 触发响应式更新 - 通过重新设置project来触发更新
      this.appState.setProject(this.appState.project);
      
      if (this.appState.selectedTask?.id === taskId) {
        this.appState.setSelectedTask(this.copyTaskNode(updatedTask));
        console.log(`[ProjectManager] Updated selectedTask with new checklist`);
      }
      
      // 触发事件和自动保存
      this.eventBus.emit(Events.TASK_UPDATED, updatedTask);
      this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
      this.autoSaveProject();
      
      console.log(`[ProjectManager] Checklist updated successfully`);
    }
  }

  private addChecklistItem(taskId: string, item: ChecklistItem): void {
    if (!this.appState.project) return;

    const task = this.appState.project.tasks.find(t => t.id === taskId);
    if (task) {
      console.log(`[ProjectManager] Adding checklist item to task ${taskId}: ${item.text}`);
      console.log(`[ProjectManager] Before: ${task.checklist.length} items`);
      
      // 创建新的checklist数组以触发响应式更新
      const newChecklist = task.checklist.concat([item]);
      task.checklist = newChecklist;
      
      console.log(`[ProjectManager] After: ${task.checklist.length} items`);
      
      // 触发响应式更新 - 通过重新设置project来触发更新
      this.appState.setProject(this.appState.project);
      
      if (this.appState.selectedTask?.id === taskId) {
        this.appState.setSelectedTask(this.copyTaskNode(task));
        console.log(`[ProjectManager] Updated selectedTask with new checklist`);
      }
      
      // 触发事件和自动保存
      this.eventBus.emit(Events.TASK_UPDATED, task);
      this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
      this.autoSaveProject();
      
      console.log(`[ProjectManager] Checklist item added successfully`);
    }
  }

  private deleteChecklistItem(taskId: string, itemId: string): void {
    if (!this.appState.project) return;

    const task = this.appState.project.tasks.find(t => t.id === taskId);
    if (task) {
      console.log(`[ProjectManager] Deleting checklist item ${itemId} from task ${taskId}`);
      console.log(`[ProjectManager] Before: ${task.checklist.length} items`);
      
      // 创建新的checklist数组以触发响应式更新
      const newChecklist = task.checklist.filter(item => item.id !== itemId);
      task.checklist = newChecklist;
      
      console.log(`[ProjectManager] After: ${task.checklist.length} items`);
      
      // 触发响应式更新 - 通过重新设置project来触发更新
      this.appState.setProject(this.appState.project);
      
      if (this.appState.selectedTask?.id === taskId) {
        this.appState.setSelectedTask(this.copyTaskNode(task));
        console.log(`[ProjectManager] Updated selectedTask with new checklist`);
      }
      
      // 触发事件和自动保存
      this.eventBus.emit(Events.TASK_UPDATED, task);
      this.eventBus.emit(Events.PROJECT_SAVED, this.appState.project);
      this.autoSaveProject();
      
      console.log(`[ProjectManager] Checklist item deleted successfully`);
    }
  }

  private addDependency(fromId: string, toId: string): void {
    if (!this.appState.project) return;

    const exists = this.appState.project.dependencies.some(
      d => d.fromId === fromId && d.toId === toId
    );

    if (!exists) {
      const newDependency: Dependency = {
        fromId: fromId,
        toId: toId
      };
      this.appState.project.dependencies = this.appState.project.dependencies.concat([newDependency]);
      this.calculateCriticalPath();
      promptAction.showToast({ message: '依赖已创建' });
    } else {
      promptAction.showToast({ message: '该依赖已存在' });
    }
  }

  private removeDependency(fromId: string, toId: string): void {
    if (!this.appState.project) return;

    this.appState.project.dependencies = this.appState.project.dependencies.filter(
      d => !(d.fromId === fromId && d.toId === toId)
    );
    this.calculateCriticalPath();
  }

  private calculateCriticalPath(): void {
    if (!this.appState.project) return;

    const tasksWithDuration: TaskWithDuration[] = this.appState.project.tasks.map(
      (t: TaskNode): TaskWithDuration => ({
        id: t.id,
        duration: this.getDuration(t),
        isCritical: t.isCritical,
        earlyStart: t.earlyStart,
        earlyFinish: t.earlyFinish,
        lateStart: t.lateStart,
        lateFinish: t.lateFinish
      })
    );

    const criticalPathService = this.serviceContainer.get<CriticalPathService>('criticalPathService');
    const result = criticalPathService.calculate(tasksWithDuration, this.appState.project.dependencies);

    if (result.success) {
      // 更新任务的关键路径信息
      tasksWithDuration.forEach(calculatedTask => {
        const originalTask = this.appState.project!.tasks.find(t => t.id === calculatedTask.id);
        if (originalTask) {
          originalTask.isCritical = calculatedTask.isCritical;
          originalTask.earlyStart = calculatedTask.earlyStart;
          originalTask.earlyFinish = calculatedTask.earlyFinish;
          originalTask.lateStart = calculatedTask.lateStart;
          originalTask.lateFinish = calculatedTask.lateFinish;
        }
      });

      this.eventBus.emit(Events.CRITICAL_PATH_CALCULATED, this.appState.project);
    } else {
      this.errorHandler.handleBusinessError(result.error || '关键路径计算失败', 'ProjectManager.calculateCriticalPath');
    }
  }

  private moveTask(taskId: string, x: number, y: number): void {
    if (!this.appState.project) return;

    const task = this.appState.project.tasks.find(t => t.id === taskId);
    if (task) {
      task.x = x;
      task.y = y;
      
      if (this.appState.selectedTask?.id === taskId) {
        this.appState.setSelectedTask(this.copyTaskNode(task));
      }
    }
  }

  // 辅助方法：复制TaskNode对象
  private copyTaskNode(task: TaskNode): TaskNode {
    return {
      id: task.id,
      name: task.name,
      startDate: task.startDate,
      endDate: task.endDate,
      checklist: task.checklist.slice(),
      x: task.x,
      y: task.y,
      isCritical: task.isCritical,
      earlyStart: task.earlyStart,
      earlyFinish: task.earlyFinish,
      lateStart: task.lateStart,
      lateFinish: task.lateFinish
    };
  }

  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  // 自动保存项目到存储（带防抖）
  private autoSaveProject(): void {
    // 清除之前的定时器
    if (this.autoSaveTimer !== null) {
      clearTimeout(this.autoSaveTimer);
    }
    
    // 设置新的定时器，延迟500ms后保存
    this.autoSaveTimer = setTimeout(async () => {
      if (this.appState.project && this.serviceContainer.isInitialized()) {
        try {
          console.log(`[ProjectManager] 开始自动保存项目: ${this.appState.project.name} (${this.appState.project.id})`);
          const storageService = this.serviceContainer.get<StorageService>('storageService');
          await storageService.saveProject(this.appState.project);
          console.log(`[ProjectManager] 项目已自动保存: ${this.appState.project.name}`);
        } catch (error) {
          console.error(`[ProjectManager] 自动保存失败:`, error);
          this.errorHandler.handleStorageError(error as Error, 'ProjectManager.autoSaveProject');
        }
      } else {
        console.warn('[ProjectManager] 无法自动保存：项目为空或服务容器未初始化');
      }
      this.autoSaveTimer = null;
    }, 500);
  }

  // 清理资源
  public cleanup(): void {
    if (this.autoSaveTimer !== null) {
      clearTimeout(this.autoSaveTimer);
      this.autoSaveTimer = null;
    }
  }
}
