// File: entry/src/main/ets/core/ErrorHandler.ets


/**
 * 错误类型枚举
 */
export enum ErrorType {
  NETWORK = 'NETWORK',
  STORAGE = 'STORAGE',
  VALIDATION = 'VALIDATION',
  BUSINESS = 'BUSINESS',
  UNKNOWN = 'UNKNOWN'
}

/**
 * 错误信息接口
 */
export interface ErrorInfo {
  type: ErrorType;
  message: string;
  context: string;
  timestamp: number;
  stack?: string;
}

/**
 * 统一错误处理类
 * 提供错误分类、用户友好提示、错误上报等功能
 */
export class ErrorHandler {
  private static instance: ErrorHandler;
  private errorLog: ErrorInfo[] = [];
  private uiContext: UIContext | null = null;

  public setContext(ctx: UIContext) {
    this.uiContext = ctx;
  }

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler();
    }
    return ErrorHandler.instance;
  }

  /**
   * 处理错误
   * @param error 错误对象
   * @param context 错误上下文
   * @param type 错误类型
   */
  public handle(error: Error | string, context: string, type: ErrorType = ErrorType.UNKNOWN): void {
    const errorInfo: ErrorInfo = {
      type: type,
      message: typeof error === 'string' ? error : error.message,
      context: context,
      timestamp: Date.now(),
      stack: typeof error === 'object' ? error.stack : undefined
    };

    // 记录错误日志
    this.logError(errorInfo);

    // 显示用户友好的错误提示
    this.showUserFriendlyMessage(errorInfo);

    // 上报错误（可选）
    this.reportError(errorInfo);
  }

  /**
   * 处理网络错误
   * @param error 错误对象
   * @param context 错误上下文
   */
  public handleNetworkError(error: Error | string, context: string): void {
    this.handle(error, context, ErrorType.NETWORK);
  }

  /**
   * 处理存储错误
   * @param error 错误对象
   * @param context 错误上下文
   */
  public handleStorageError(error: Error | string, context: string): void {
    this.handle(error, context, ErrorType.STORAGE);
  }

  /**
   * 处理验证错误
   * @param error 错误对象
   * @param context 错误上下文
   */
  public handleValidationError(error: Error | string, context: string): void {
    this.handle(error, context, ErrorType.VALIDATION);
  }

  /**
   * 处理业务逻辑错误
   * @param error 错误对象
   * @param context 错误上下文
   */
  public handleBusinessError(error: Error | string, context: string): void {
    this.handle(error, context, ErrorType.BUSINESS);
  }

  /**
   * 记录错误日志
   * @param errorInfo 错误信息
   */
  private logError(errorInfo: ErrorInfo): void {
    this.errorLog.push(errorInfo);
    
    // 保持日志数量在合理范围内
    if (this.errorLog.length > 100) {
      this.errorLog = this.errorLog.slice(-50);
    }

    console.error(`[${errorInfo.context}] ${errorInfo.type}: ${errorInfo.message}`, errorInfo.stack);
  }

  /**
   * 显示用户友好的错误提示
   * @param errorInfo 错误信息
   */
  private showUserFriendlyMessage(errorInfo: ErrorInfo): void {
    if(this.uiContext){
      const promptAction = this.uiContext.getPromptAction();
      const userMessage = this.getUserFriendlyMessage(errorInfo);
      promptAction.showToast({
        message: userMessage,
        duration: 3000
      });
    }
  }

  /**
   * 获取用户友好的错误消息
   * @param errorInfo 错误信息
   * @returns 用户友好的错误消息
   */
  private getUserFriendlyMessage(errorInfo: ErrorInfo): string {
    switch (errorInfo.type) {
      case ErrorType.NETWORK:
        return '网络连接异常，请检查网络设置后重试';
      case ErrorType.STORAGE:
        return '数据存储失败，请重试';
      case ErrorType.VALIDATION:
        return errorInfo.message; // 验证错误直接显示具体消息
      case ErrorType.BUSINESS:
        return errorInfo.message; // 业务错误直接显示具体消息
      default:
        return '操作失败，请重试';
    }
  }

  /**
   * 上报错误（可扩展为发送到服务器）
   * @param errorInfo 错误信息
   */
  private reportError(errorInfo: ErrorInfo): void {
    // 这里可以实现错误上报逻辑
    // 例如：发送到服务器、本地存储等
    console.log('[ErrorHandler] 错误上报:', errorInfo);
  }

  /**
   * 获取错误日志
   * @returns 错误日志数组
   */
  public getErrorLog(): ErrorInfo[] {
    return [...this.errorLog];
  }

  /**
   * 清除错误日志
   */
  public clearErrorLog(): void {
    this.errorLog = [];
  }

  /**
   * 获取指定类型的错误数量
   * @param type 错误类型
   * @returns 错误数量
   */
  public getErrorCount(type: ErrorType): number {
    return this.errorLog.filter(error => error.type === type).length;
  }

  /**
   * 获取最近的错误
   * @param count 数量
   * @returns 最近的错误数组
   */
  public getRecentErrors(count: number = 10): ErrorInfo[] {
    return this.errorLog.slice(-count);
  }
}
