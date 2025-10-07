// File: entry/src/main/ets/core/commands/MoveTaskCommand.ets
/**
 * 移动任务命令
 * 
 * 本命令用于移动任务节点在画布上的位置，支持撤销和重做。
 * 记录任务移动前后的坐标，允许用户撤销移动操作。
 * 
 * 功能：
 * - 执行：将任务移动到新位置
 * - 撤销：将任务恢复到原位置
 * - 重做：再次将任务移动到新位置
 * 
 * 使用场景：
 * - 用户在画布上拖拽任务节点
 * - 通过代码调整任务布局
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { Command } from './Command';
import { Project, TaskNode } from '../../model/ProjectData';

/**
 * 移动任务命令类
 * 
 * 记录任务的旧坐标和新坐标，实现位置变更的撤销和重做。
 */
export class MoveTaskCommand implements Command {
  /** 目标项目对象 */
  private project: Project;
  
  /** 要移动的任务ID */
  private taskId: string;
  
  /** 移动前的X坐标 */
  private oldX: number;
  
  /** 移动前的Y坐标 */
  private oldY: number;
  
  /** 移动后的X坐标 */
  private newX: number;
  
  /** 移动后的Y坐标 */
  private newY: number;

  /**
   * 构造函数
   * 
   * @param project 目标项目
   * @param taskId 任务ID
   * @param oldX 移动前的X坐标
   * @param oldY 移动前的Y坐标
   * @param newX 移动后的X坐标
   * @param newY 移动后的Y坐标
   */
  constructor(
    project: Project,
    taskId: string,
    oldX: number,
    oldY: number,
    newX: number,
    newY: number
  ) {
    this.project = project;
    this.taskId = taskId;
    this.oldX = oldX;
    this.oldY = oldY;
    this.newX = newX;
    this.newY = newY;
  }

  /**
   * 执行命令：将任务移动到新位置
   */
  execute(): void {
    const task = this.findTask();
    if (task) {
      task.x = this.newX;
      task.y = this.newY;
      console.log(`[MoveTaskCommand] 执行移动: ${task.name} -> (${this.newX}, ${this.newY})`);
    } else {
      console.error(`[MoveTaskCommand] 未找到任务: ${this.taskId}`);
    }
  }

  /**
   * 撤销命令：将任务恢复到原位置
   */
  undo(): void {
    const task = this.findTask();
    if (task) {
      task.x = this.oldX;
      task.y = this.oldY;
      console.log(`[MoveTaskCommand] 撤销移动: ${task.name} -> (${this.oldX}, ${this.oldY})`);
    } else {
      console.error(`[MoveTaskCommand] 撤销失败，未找到任务: ${this.taskId}`);
    }
  }

  /**
   * 重做命令：再次将任务移动到新位置
   */
  redo(): void {
    this.execute();
  }

  /**
   * 获取命令名称
   * @returns 命令描述
   */
  getName(): string {
    const task = this.findTask();
    return `移动任务${task ? ` "${task.name}"` : ''}`;
  }

  /**
   * 查找任务对象
   * @returns 任务对象，如果未找到则返回undefined
   */
  private findTask(): TaskNode | undefined {
    return this.project.tasks.find(t => t.id === this.taskId);
  }
}

