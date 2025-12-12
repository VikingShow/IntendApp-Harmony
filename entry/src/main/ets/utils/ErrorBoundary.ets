// File: entry/src/main/ets/utils/ErrorBoundary.ets
/**
 * 错误边界与回滚机制
 * 
 * 功能：
 * - 捕获渲染器和规则引擎错误
 * - 保存稳定状态快照
 * - 错误时回滚到上一次稳定状态
 * - 防止页面崩溃
 */

import { NodeSchema } from '../model/NodeSchema';

/**
 * 错误类型
 */
export enum ErrorType {
  RENDER_ERROR = 'RENDER_ERROR',
  RULE_ENGINE_ERROR = 'RULE_ENGINE_ERROR',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  STORAGE_ERROR = 'STORAGE_ERROR',
  UNKNOWN_ERROR = 'UNKNOWN_ERROR'
}

/**
 * 错误信息
 */
export interface ErrorInfo {
  type: ErrorType;
  message: string;
  timestamp: number;
  context?: string;
  stack?: string;
}

/**
 * 状态快照
 */
export interface StateSnapshot<T> {
  data: T;
  timestamp: number;
  version: number;
}

/**
 * 错误边界管理器
 */
export class ErrorBoundary<T> {
  /** 当前稳定状态 */
  private stableState: StateSnapshot<T> | null = null;
  /** 错误历史记录（最多保留10条） */
  private errorHistory: ErrorInfo[] = [];
  /** 最大错误历史记录数 */
  private readonly MAX_ERROR_HISTORY = 10;
  /** 快照版本号 */
  private snapshotVersion: number = 0;

  /**
   * 保存稳定状态快照
   * @param data 当前状态数据
   */
  public saveSnapshot(data: T): void {
    try {
      this.stableState = {
        data: this.deepClone(data),
        timestamp: Date.now(),
        version: ++this.snapshotVersion
      };
      console.log(`[ErrorBoundary] Snapshot saved, version=${this.snapshotVersion}`);
    } catch (error) {
      console.error('[ErrorBoundary] saveSnapshot failed:', error);
    }
  }

  /**
   * 获取最后的稳定状态
   */
  public getStableState(): StateSnapshot<T> | null {
    return this.stableState;
  }

  /**
   * 回滚到上一次稳定状态
   * @returns 是否回滚成功
   */
  public rollback(): T | null {
    if (!this.stableState) {
      console.warn('[ErrorBoundary] No stable state available for rollback');
      return null;
    }
    console.log(`[ErrorBoundary] Rolling back to version ${this.stableState.version}`);
    return this.deepClone(this.stableState.data);
  }

  /**
   * 记录错误
   * @param error 错误对象
   * @param type 错误类型
   * @param context 错误上下文
   */
  public recordError(error: Error | string, type: ErrorType, context?: string): void {
    const errorInfo: ErrorInfo = {
      type: type,
      message: error instanceof Error ? error.message : String(error),
      timestamp: Date.now(),
      context: context,
      stack: error instanceof Error ? error.stack : undefined
    };

    this.errorHistory.push(errorInfo);
    
    // 限制历史记录数量
    if (this.errorHistory.length > this.MAX_ERROR_HISTORY) {
      this.errorHistory.shift();
    }

    console.error(`[ErrorBoundary] ${type}: ${errorInfo.message}`, context);
  }

  /**
   * 获取错误历史
   */
  public getErrorHistory(): ErrorInfo[] {
    return [...this.errorHistory];
  }

  /**
   * 清空错误历史
   */
  public clearErrorHistory(): void {
    this.errorHistory = [];
  }

  /**
   * 尝试执行操作，失败时回滚
   * @param operation 要执行的操作
   * @param errorType 错误类型
   * @param context 错误上下文
   * @returns 操作结果
   */
  public tryWithRollback<R>(
    operation: () => R,
    errorType: ErrorType,
    context?: string
  ): R | null {
    try {
      return operation();
    } catch (error) {
      this.recordError(error instanceof Error ? error : new Error(String(error)), errorType, context);
      const rolledBackData = this.rollback();
      if (rolledBackData) {
        console.log('[ErrorBoundary] Rollback successful');
      }
      return null;
    }
  }

  /**
   * 异步操作的错误边界
   */
  public async tryWithRollbackAsync<R>(
    operation: () => Promise<R>,
    errorType: ErrorType,
    context?: string
  ): Promise<R | null> {
    try {
      return await operation();
    } catch (error) {
      this.recordError(error instanceof Error ? error : new Error(String(error)), errorType, context);
      const rolledBackData = this.rollback();
      if (rolledBackData) {
        console.log('[ErrorBoundary] Rollback successful');
      }
      return null;
    }
  }

  /**
   * 深度克隆对象（用于创建快照）
   */
  private deepClone(obj: T): T {
    try {
      // 使用 JSON 序列化/反序列化进行深拷贝
      // 注意：这种方法不支持 Map、Set、Function 等类型
      return JSON.parse(JSON.stringify(obj)) as T;
    } catch (error) {
      console.error('[ErrorBoundary] deepClone failed:', error);
      // 如果深拷贝失败，返回原对象（风险：可能导致状态污染）
      return obj;
    }
  }
}

/**
 * NodeSchema 专用错误边界
 */
export class SchemaErrorBoundary extends ErrorBoundary<NodeSchema[]> {
  /**
   * 验证 NodeSchema 数组的有效性
   * @param schemas NodeSchema 数组
   * @returns 验证错误信息，如果为空则表示验证通过
   */
  public validateSchemas(schemas: NodeSchema[]): string {
    if (!Array.isArray(schemas)) {
      return '数据格式错误：schemas 必须是数组';
    }

    for (let i = 0; i < schemas.length; i++) {
      const schema = schemas[i];
      
      if (!schema.id || typeof schema.id !== 'string') {
        return `第 ${i + 1} 个节点缺少有效的 id`;
      }
      
      if (!schema.name || typeof schema.name !== 'string') {
        return `第 ${i + 1} 个节点缺少有效的 name`;
      }
      
      if (!schema.style || typeof schema.style !== 'object') {
        return `第 ${i + 1} 个节点缺少 style 配置`;
      }
      
      if (!schema.style.fillColor || typeof schema.style.fillColor !== 'string') {
        return `第 ${i + 1} 个节点缺少 style.fillColor`;
      }

      if (schema.version === undefined || schema.version === null || typeof schema.version !== 'number') {
        return `第 ${i + 1} 个节点缺少有效的 version`;
      }
    }

    return '';
  }

  /**
   * 安全地应用 schema 更新
   * @param schemas 新的 schemas
   * @param currentSchemas 当前的 schemas
   * @returns 应用后的 schemas，如果失败则返回当前 schemas
   */
  public safeApplyUpdate(schemas: NodeSchema[], currentSchemas: NodeSchema[]): NodeSchema[] {
    // 先保存当前稳定状态
    this.saveSnapshot(currentSchemas);

    // 验证新的 schemas
    const validationError = this.validateSchemas(schemas);
    if (validationError.length > 0) {
      this.recordError(
        new Error(validationError),
        ErrorType.VALIDATION_ERROR,
        'safeApplyUpdate'
      );
      return currentSchemas;
    }

    // 尝试应用更新
    const result = this.tryWithRollback(
      () => {
        // 这里可以添加更多的安全检查
        return schemas;
      },
      ErrorType.RENDER_ERROR,
      'safeApplyUpdate'
    );

    return result !== null ? result : currentSchemas;
  }
}
