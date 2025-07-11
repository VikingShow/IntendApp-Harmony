// File: entry/src/main/ets/services/LoadingService.ets

import { TaskNode } from '../model/ProjectData';

export class LoadingService {
  private static instance: LoadingService;
  private loadingStates: Map<string, boolean> = new Map();
  private listeners: Set<(key: string, loading: boolean) => void> = new Set();

  static getInstance(): LoadingService {
    if (!LoadingService.instance) {
      LoadingService.instance = new LoadingService();
    }
    return LoadingService.instance;
  }

  /**
   * 设置加载状态
   */
  setLoading(key: string, loading: boolean): void {
    this.loadingStates.set(key, loading);
    this.notifyListeners(key, loading);
  }

  /**
   * 获取加载状态
   */
  isLoading(key: string): boolean {
    return this.loadingStates.get(key) || false;
  }

  /**
   * 添加状态监听器
   */
  addListener(listener: (key: string, loading: boolean) => void): void {
    this.listeners.add(listener);
  }

  /**
   * 移除状态监听器
   */
  removeListener(listener: (key: string, loading: boolean) => void): void {
    this.listeners.delete(listener);
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(key: string, loading: boolean): void {
    this.listeners.forEach(listener => {
      try {
        listener(key, loading);
      } catch (error) {
        console.error('LoadingService listener error:', error);
      }
    });
  }
} 