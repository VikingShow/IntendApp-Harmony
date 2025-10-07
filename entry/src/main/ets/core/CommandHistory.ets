// File: entry/src/main/ets/core/CommandHistory.ets
/**
 * 命令历史记录管理器
 * 
 * 本模块负责管理所有可撤销操作的历史记录，实现撤销/重做功能。
 * 采用双栈结构（撤销栈和重做栈）来管理命令历史。
 * 
 * 核心功能：
 * 1. 命令执行：执行命令并记录到历史栈
 * 2. 撤销操作：从撤销栈弹出命令并执行撤销
 * 3. 重做操作：从重做栈弹出命令并重新执行
 * 4. 历史管理：限制历史记录大小，避免内存溢出
 * 
 * 工作原理：
 * - undoStack: 存储已执行的命令，用于撤销
 * - redoStack: 存储已撤销的命令，用于重做
 * - 执行新命令时，保持redoStack（允许重做之前的操作）
 * 
 * 设计模式：
 * - 单例模式：确保全局只有一个历史记录管理器
 * - 命令模式：管理命令对象的执行和撤销
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { Command } from './commands/Command';

/**
 * 命令历史记录管理器类
 * 
 * 使用单例模式，确保全局只有一个历史记录实例。
 * 提供撤销、重做、清空等操作，支持历史记录大小限制。
 */
export class CommandHistory {
  /** 撤销栈：存储已执行的命令 */
  private undoStack: Command[] = [];
  
  /** 重做栈：存储已撤销的命令 */
  private redoStack: Command[] = [];
  
  /** 最大历史记录数量，防止内存溢出 */
  private maxHistorySize: number = 50;

  /** 单例实例 */
  private static instance: CommandHistory;

  /**
   * 私有构造函数，确保单例模式
   */
  private constructor() {
    console.log('[CommandHistory] 初始化命令历史记录管理器');
  }

  /**
   * 获取单例实例
   * @returns CommandHistory实例
   */
  public static getInstance(): CommandHistory {
    if (!CommandHistory.instance) {
      CommandHistory.instance = new CommandHistory();
    }
    return CommandHistory.instance;
  }

  /**
   * 执行并记录命令
   * 
 * 工作流程：
 * 1. 执行命令
 * 2. 将命令压入撤销栈
 * 3. 保持重做栈（允许重做之前的操作）
 * 4. 保持完整的操作历史（不限制大小）
   * 
   * @param command 要执行的命令
   */
  public execute(command: Command): void {
    console.log(`[CommandHistory] 执行命令: ${command.getName()}`);
    
    // 执行命令
    command.execute();
    
    // 记录到撤销栈
    this.undoStack.push(command);
    
    // 注意：不清空重做栈，保持重做历史
    // 这样用户可以在执行新操作后仍然重做之前的操作
    
    // 注意：不限制历史记录大小，保持完整的操作历史
    // 历史记录将在应用退出时统一清空
    
    console.log(`[CommandHistory] 当前状态 - 可撤销: ${this.undoStack.length}, 可重做: ${this.redoStack.length}`);
  }

  /**
   * 撤销上一个命令
   * 
   * 工作流程：
   * 1. 从撤销栈弹出命令
   * 2. 执行命令的undo方法
   * 3. 将命令压入重做栈
   * 
   * @returns 是否成功撤销
   */
  public undo(): boolean {
    if (!this.canUndo()) {
      console.log('[CommandHistory] 没有可撤销的命令');
      return false;
    }

    const command = this.undoStack.pop()!;
    console.log(`[CommandHistory] 撤销命令: ${command.getName()}`);
    
    // 执行撤销
    command.undo();
    
    // 移到重做栈
    this.redoStack.push(command);
    
    console.log(`[CommandHistory] 撤销成功 - 可撤销: ${this.undoStack.length}, 可重做: ${this.redoStack.length}`);
    return true;
  }

  /**
   * 重做上一个撤销的命令
   * 
   * 工作流程：
   * 1. 从重做栈弹出命令
   * 2. 执行命令的redo方法
   * 3. 将命令压入撤销栈
   * 
   * @returns 是否成功重做
   */
  public redo(): boolean {
    if (!this.canRedo()) {
      console.log('[CommandHistory] 没有可重做的命令');
      return false;
    }

    const command = this.redoStack.pop()!;
    console.log(`[CommandHistory] 重做命令: ${command.getName()}`);
    
    // 执行重做
    command.redo();
    
    // 移到撤销栈
    this.undoStack.push(command);
    
    console.log(`[CommandHistory] 重做成功 - 可撤销: ${this.undoStack.length}, 可重做: ${this.redoStack.length}`);
    return true;
  }

  /**
   * 检查是否可以撤销
   * @returns 是否有可撤销的命令
   */
  public canUndo(): boolean {
    return this.undoStack.length > 0;
  }

  /**
   * 检查是否可以重做
   * @returns 是否有可重做的命令
   */
  public canRedo(): boolean {
    return this.redoStack.length > 0;
  }

  /**
   * 清空所有历史记录
   * 只在应用退出时调用，保持完整的操作历史
   */
  public clear(): void {
    console.log('[CommandHistory] 清空历史记录（应用退出）');
    this.undoStack = [];
    this.redoStack = [];
  }

  /**
   * 获取撤销栈大小
   * @returns 可撤销的命令数量
   */
  public getUndoCount(): number {
    return this.undoStack.length;
  }

  /**
   * 获取重做栈大小
   * @returns 可重做的命令数量
   */
  public getRedoCount(): number {
    return this.redoStack.length;
  }

  /**
   * 获取最后一个可撤销的命令名称
   * @returns 命令名称，如果没有则返回null
   */
  public getLastUndoCommandName(): string | null {
    if (this.undoStack.length === 0) {
      return null;
    }
    return this.undoStack[this.undoStack.length - 1].getName();
  }

  /**
   * 获取最后一个可重做的命令名称
   * @returns 命令名称，如果没有则返回null
   */
  public getLastRedoCommandName(): string | null {
    if (this.redoStack.length === 0) {
      return null;
    }
    return this.redoStack[this.redoStack.length - 1].getName();
  }
}

