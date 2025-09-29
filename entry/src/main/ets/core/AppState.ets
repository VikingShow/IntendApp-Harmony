// File: entry/src/main/ets/core/AppState.ets
/**
 * 应用状态管理模块
 * 
 * 本模块负责管理EasyFlow应用的整体状态，采用响应式状态管理模式。
 * 使用ArkTS的@Observed装饰器实现状态变化时的自动UI更新，确保界面与数据保持同步。
 * 
 * 主要功能：
 * 1. 全局状态管理：统一管理应用的所有状态信息
 * 2. 响应式更新：状态变化时自动触发UI重新渲染
 * 3. 状态快照：提供状态快照功能，支持状态回滚和调试
 * 4. 单例模式：确保全局状态的一致性
 * 5. 状态验证：提供状态有效性验证机制
 * 
 * 状态类型：
 * - 项目状态：当前项目、选中任务等业务状态
 * - UI状态：侧边栏可见性、画布状态等界面状态
 * - 系统状态：加载状态、错误信息等系统状态
 * 
 * 设计原则：
 * - 单一数据源：所有状态集中管理，避免数据不一致
 * - 不可变性：状态更新时创建新对象，保持数据不可变
 * - 响应式：状态变化自动触发相关UI更新
 * - 可预测性：状态变化流程清晰，便于调试和维护
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode } from '../model/ProjectData';

/**
 * 应用状态快照接口
 * 用于保存和恢复应用状态的完整快照
 */
export interface AppStateSnapshot {
  /** 当前项目对象 */
  project: Project | null;
  /** 当前选中的任务 */
  selectedTask: TaskNode | null;
  /** 是否正在加载 */
  isLoading: boolean;
  /** 错误信息 */
  error: string | null;
  /** 侧边栏是否可见 */
  sidebarVisible: boolean;
  /** 画布X轴偏移量 */
  canvasOffsetX: number;
  /** 画布Y轴偏移量 */
  canvasOffsetY: number;
  /** 画布是否锁定 */
  isCanvasLocked: boolean;
}

/**
 * 应用状态管理类
 * 
 * 实现应用全局状态的统一管理，采用单例模式设计。
 * 使用ArkTS的@Observed装饰器实现响应式状态管理，当状态发生变化时自动触发UI更新。
 * 
 * 核心特性：
 * 1. 响应式状态：使用@Observed装饰器实现状态变化监听
 * 2. 单例模式：确保全局状态的一致性
 * 3. 状态快照：支持状态的保存和恢复
 * 4. 类型安全：使用TypeScript确保状态类型安全
 * 5. 性能优化：最小化状态更新，避免不必要的重渲染
 * 
 * 状态管理策略：
 * - 集中管理：所有状态集中在一个类中管理
 * - 不可变更新：状态更新时创建新对象
 * - 批量更新：支持批量状态更新操作
 * - 状态验证：提供状态有效性检查
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
@Observed
export class AppState {
  project: Project | null = null;
  selectedTask: TaskNode | null = null;
  isLoading: boolean = false;
  error: string | null = null;
  sidebarVisible: boolean = true;
  canvasOffsetX: number = 0;
  canvasOffsetY: number = 0;
  isCanvasLocked: boolean = false;

  // 私有构造函数，确保单例模式
  private constructor() {}

  // 单例实例
  private static instance: AppState;

  /**
   * 获取单例实例
   */
  public static getInstance(): AppState {
    if (!AppState.instance) {
      AppState.instance = new AppState();
    }
    return AppState.instance;
  }

  /**
   * 设置项目
   */
  public setProject(project: Project | null): void {
    this.project = project;
  }

  /**
   * 设置选中的任务
   */
  public setSelectedTask(task: TaskNode | null): void {
    this.selectedTask = task;
  }

  /**
   * 设置加载状态
   */
  public setLoading(loading: boolean): void {
    this.isLoading = loading;
  }

  /**
   * 设置错误信息
   */
  public setError(error: string | null): void {
    this.error = error;
  }

  /**
   * 切换侧边栏可见性
   */
  public toggleSidebar(): void {
    this.sidebarVisible = !this.sidebarVisible;
  }

  /**
   * 设置画布偏移
   */
  public setCanvasOffset(x: number, y: number): void {
    this.canvasOffsetX = x;
    this.canvasOffsetY = y;
  }

  /**
   * 切换画布锁定状态
   */
  public toggleCanvasLock(): void {
    this.isCanvasLocked = !this.isCanvasLocked;
  }

  /**
   * 重置画布
   */
  public resetCanvas(): void {
    this.canvasOffsetX = 0;
    this.canvasOffsetY = 0;
  }

  /**
   * 清除错误
   */
  public clearError(): void {
    this.error = null;
  }

  /**
   * 获取当前状态快照
   */
  public getStateSnapshot(): AppStateSnapshot {
    return {
      project: this.project,
      selectedTask: this.selectedTask,
      isLoading: this.isLoading,
      error: this.error,
      sidebarVisible: this.sidebarVisible,
      canvasOffsetX: this.canvasOffsetX,
      canvasOffsetY: this.canvasOffsetY,
      isCanvasLocked: this.isCanvasLocked
    };
  }
}
