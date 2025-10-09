// File: entry/src/main/ets/services/PerformanceService.ets

/**
 * 性能指标接口
 */
export interface PerformanceMetric {
  name: string;
  value: number;
  timestamp: number;
  unit: string;
}

/**
 * 用户行为事件接口
 */
export interface UserAction {
  action: string;
  context: string;
  timestamp: number;
  data?: Record<string, string | number | boolean>;
}

/**
 * 性能统计信息接口
 */
export interface PerformanceStats {
  totalMetrics: number;
  totalActions: number;
  averageMetrics: Record<string, number>;
  recentActions: UserAction[];
}

/**
 * 性能监控服务
 * 用于监控应用性能指标和用户行为
 */
export class PerformanceService {
  private static instance: PerformanceService;
  private metrics: PerformanceMetric[] = [];
  private userActions: UserAction[] = [];
  private maxMetricsCount: number = 1000;
  private maxActionsCount: number = 500;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): PerformanceService {
    if (!PerformanceService.instance) {
      PerformanceService.instance = new PerformanceService();
    }
    return PerformanceService.instance;
  }

  /**
   * 记录性能指标
   * @param name 指标名称
   * @param value 指标值
   * @param unit 单位
   */
  public recordMetric(name: string, value: number, unit: string = 'ms'): void {
    const metric: PerformanceMetric = {
      name,
      value,
      timestamp: Date.now(),
      unit
    };

    this.metrics.push(metric);

    // 保持指标数量在合理范围内
    if (this.metrics.length > this.maxMetricsCount) {
      this.metrics = this.metrics.slice(-this.maxMetricsCount / 2);
    }

    console.log(`[Performance] ${name}: ${value}${unit}`);
  }

  /**
   * 记录用户行为
   * @param action 行为名称
   * @param context 上下文
   * @param data 附加数据
   */
  public recordUserAction(action: string, context: string, data?: Record<string, string | number | boolean>): void {
    const userAction: UserAction = {
      action,
      context,
      timestamp: Date.now(),
      data
    };

    this.userActions.push(userAction);

    // 保持行为记录数量在合理范围内
    if (this.userActions.length > this.maxActionsCount) {
      this.userActions = this.userActions.slice(-this.maxActionsCount / 2);
    }

    console.log(`[UserAction] ${action} in ${context}`, data);
  }

  /**
   * 测量函数执行时间
   * @param name 测量名称
   * @param fn 要测量的函数
   * @returns 函数执行结果
   */
  public async measureAsync<T>(name: string, fn: () => Promise<T>): Promise<T> {
    const startTime = Date.now();
    try {
      const result = await fn();
      const duration = Date.now() - startTime;
      this.recordMetric(name, duration, 'ms');
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      this.recordMetric(`${name}_error`, duration, 'ms');
      const err = new Error(`Performance measurement failed for ${name}`);
      throw err;
    }
  }

  /**
   * 测量同步函数执行时间
   * @param name 测量名称
   * @param fn 要测量的函数
   * @returns 函数执行结果
   */
  public measure<T>(name: string, fn: () => T): T {
    const startTime = Date.now();
    try {
      const result = fn();
      const duration = Date.now() - startTime;
      this.recordMetric(name, duration, 'ms');
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      this.recordMetric(`${name}_error`, duration, 'ms');
      const err = new Error(`Performance measurement failed for ${name}`);
      throw err;
    }
  }

  /**
   * 获取性能指标
   * @param name 指标名称（可选）
   * @returns 性能指标数组
   */
  public getMetrics(name?: string): PerformanceMetric[] {
    if (name) {
      return this.metrics.filter(metric => metric.name === name);
    }
    return this.metrics.slice();
  }

  /**
   * 获取用户行为记录
   * @param action 行为名称（可选）
   * @returns 用户行为数组
   */
  public getUserActions(action?: string): UserAction[] {
    if (action) {
      return this.userActions.filter(userAction => userAction.action === action);
    }
    return this.userActions.slice();
  }

  /**
   * 获取平均性能指标
   * @param name 指标名称
   * @returns 平均值
   */
  public getAverageMetric(name: string): number {
    const metrics = this.getMetrics(name);
    if (metrics.length === 0) {
      return 0;
    }
    
    const sum = metrics.reduce((acc, metric) => acc + metric.value, 0);
    return sum / metrics.length;
  }

  /**
   * 获取唯一的指标名称列表
   * @returns 指标名称数组
   */
  private getUniqueMetricNames(): string[] {
    const names: string[] = [];
    const seen = new Set<string>();
    
    for (const metric of this.metrics) {
      if (!seen.has(metric.name)) {
        seen.add(metric.name);
        names.push(metric.name);
      }
    }
    
    return names;
  }

  /**
   * 获取性能统计信息
   * @returns 性能统计
   */
  public getPerformanceStats(): PerformanceStats {
    const averageMetrics: Record<string, number> = {};
    const uniqueMetricNames = this.getUniqueMetricNames();
    
    uniqueMetricNames.forEach(name => {
      averageMetrics[name] = this.getAverageMetric(name);
    });

    return {
      totalMetrics: this.metrics.length,
      totalActions: this.userActions.length,
      averageMetrics,
      recentActions: this.userActions.slice(-10)
    };
  }

  /**
   * 清除所有数据
   */
  public clear(): void {
    this.metrics = [];
    this.userActions = [];
  }

  /**
   * 导出性能数据
   * @returns 性能数据JSON字符串
   */
  public exportData(): string {
    return JSON.stringify({
      metrics: this.metrics,
      userActions: this.userActions,
      timestamp: Date.now()
    });
  }
}
