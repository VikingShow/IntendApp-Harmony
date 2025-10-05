// File: entry/src/main/ets/core/ServiceContainer.ets

import { StorageService } from '../services/StorageService';
import { CriticalPathService } from '../services/CriticalPathService';
import { TemplateService } from '../services/TemplateService';
import { LoadingService } from '../services/LoadingService';

/**
 * 服务容器 - 依赖注入容器
 * 用于管理服务实例的生命周期和依赖关系
 */
export class ServiceContainer {
  private static instance: ServiceContainer;
  private services: Map<string, object> = new Map();
  private initialized: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): ServiceContainer {
    if (!ServiceContainer.instance) {
      ServiceContainer.instance = new ServiceContainer();
    }
    return ServiceContainer.instance;
  }

  /**
   * 初始化所有服务
   * @param filesDir 文件目录路径
   */
  public async initialize(filesDir: string): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 注册核心服务
      this.register('storageService', StorageService.getInstance(filesDir));
      this.register('criticalPathService', new CriticalPathService());
      this.register('templateService', TemplateService.getInstance());
      this.register('loadingService', LoadingService.getInstance());

      // 设置服务依赖关系
      await this.setupDependencies();

      this.initialized = true;
      console.log('[ServiceContainer] 所有服务初始化完成');
    } catch (error) {
      console.error('[ServiceContainer] 服务初始化失败:', error);
      const err = new Error('ServiceContainer initialization failed');
      throw err;
    }
  }

  /**
   * 注册服务
   * @param key 服务键名
   * @param service 服务实例
   */
  public register<T extends object>(key: string, service: T): void {
    this.services.set(key, service);
  }

  /**
   * 获取服务
   * @param key 服务键名
   * @returns 服务实例
   */
  public get<T extends object>(key: string): T {
    const service = this.services.get(key);
    if (!service) {
      const error = new Error(`Service '${key}' not found. Make sure it's registered.`);
      throw error;
    }
    return service as T;
  }

  /**
   * 检查服务是否已注册
   * @param key 服务键名
   * @returns 是否已注册
   */
  public has(key: string): boolean {
    return this.services.has(key);
  }

  /**
   * 设置服务依赖关系
   */
  // TODO:这是干什么的？
  private async setupDependencies(): Promise<void> {
    const storageService = this.get<StorageService>('storageService');

  }

  /**
   * 获取所有已注册的服务键名
   * @returns 服务键名数组
   */
  public getRegisteredServices(): string[] {
    return Array.from(this.services.keys());
  }

  /**
   * 清理所有服务
   */
  public cleanup(): void {
    this.services.clear();
    this.initialized = false;
  }

  /**
   * 检查是否已初始化
   * @returns 是否已初始化
   */
  public isInitialized(): boolean {
    return this.initialized;
  }
}
