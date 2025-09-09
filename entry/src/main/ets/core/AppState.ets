// File: entry/src/main/ets/core/AppState.ets

import { Project, TaskNode } from '../model/ProjectData';

/**
 * 应用状态快照接口
 */
export interface AppStateSnapshot {
  project: Project | null;
  selectedTask: TaskNode | null;
  isLoading: boolean;
  error: string | null;
  sidebarVisible: boolean;
  canvasOffsetX: number;
  canvasOffsetY: number;
  isCanvasLocked: boolean;
}

/**
 * 应用状态管理类
 * 使用ArkTS的@Observed装饰器实现响应式状态管理
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
