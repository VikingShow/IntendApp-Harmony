// File: entry/src/main/ets/core/commands/Command.ets
/**
 * 命令接口
 * 
 * 本接口定义了命令模式的基本操作，所有可撤销的操作都需要实现此接口。
 * 命令模式将操作封装成对象，支持撤销、重做等功能。
 * 
 * 设计模式：命令模式（Command Pattern）
 * 主要方法：
 * - execute(): 执行命令
 * - undo(): 撤销命令
 * - redo(): 重做命令（通常等同于execute）
 * - getName(): 获取命令名称，用于调试和日志
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

export interface Command {
  /**
   * 执行命令
   * 执行具体的操作逻辑
   */
  execute(): void;

  /**
   * 撤销命令
   * 将状态恢复到执行命令之前
   */
  undo(): void;

  /**
   * 重做命令
   * 重新执行命令（通常与execute相同）
   */
  redo(): void;

  /**
   * 获取命令名称
   * 用于调试、日志记录和用户提示
   * @returns 命令的描述性名称
   */
  getName(): string;
}

