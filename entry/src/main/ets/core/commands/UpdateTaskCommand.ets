// File: entry/src/main/ets/core/commands/UpdateTaskCommand.ets
/**
 * 更新任务命令
 * 
 * 本命令用于更新任务的属性（如名称、日期等），支持撤销和重做。
 * 记录任务更新前后的状态，允许用户撤销更新操作。
 * 
 * 功能：
 * - 执行：将任务属性更新为新值
 * - 撤销：将任务属性恢复为旧值
 * - 重做：再次将任务属性更新为新值
 * 
 * 使用场景：
 * - 用户编辑任务名称
 * - 修改任务日期
 * - 更新任务的其他属性
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { Command } from './Command';
import { Project, TaskNode, ChecklistItem } from '../../model/ProjectData';

/**
 * 更新任务命令类
 * 
 * 记录任务的旧状态和新状态，实现任务更新的撤销和重做。
 */
export class UpdateTaskCommand implements Command {
  /** 目标项目对象 */
  private project: Project;
  
  /** 要更新的任务ID */
  private taskId: string;
  
  /** 任务更新前的状态 */
  private oldState: Partial<TaskNode>;
  
  /** 任务更新后的状态 */
  private newState: Partial<TaskNode>;

  /**
   * 构造函数
   * 
   * @param project 目标项目
   * @param taskId 任务ID
   * @param oldState 更新前的状态
   * @param newState 更新后的状态
   */
  constructor(
    project: Project,
    taskId: string,
    oldState: Partial<TaskNode>,
    newState: Partial<TaskNode>
  ) {
    this.project = project;
    this.taskId = taskId;
    this.oldState = oldState;
    this.newState = newState;
  }

  /**
   * 执行命令：应用新状态到任务
   */
  execute(): void {
    const task = this.findTask();
    if (task) {
      this.applyState(task, this.newState);
      // 更新项目的lastModified时间戳，确保触发@Prop更新
      this.project.lastModified = Date.now();
      console.log(`[UpdateTaskCommand] 执行更新任务: ${task.name} (${this.taskId})`);
    } else {
      console.error(`[UpdateTaskCommand] 未找到任务: ${this.taskId}`);
    }
  }

  /**
   * 撤销命令：恢复任务的旧状态
   */
  undo(): void {
    const task = this.findTask();
    if (task) {
      this.applyState(task, this.oldState);
      // 更新项目的lastModified时间戳，确保触发@Prop更新
      this.project.lastModified = Date.now();
      console.log(`[UpdateTaskCommand] 撤销更新任务: ${task.name} (${this.taskId})`);
    } else {
      console.error(`[UpdateTaskCommand] 撤销失败，未找到任务: ${this.taskId}`);
    }
  }

  /**
   * 重做命令：再次应用新状态
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
    if (task) {
      // 判断更新了哪些属性，提供详细信息
      const details: string[] = [];
      
      // 名称变化
      if (this.newState.name !== undefined && this.oldState.name !== undefined) {
        details.push(`名称: "${this.oldState.name}" → "${this.newState.name}"`);
      } else if (this.newState.name !== undefined) {
        details.push(`名称: "${this.newState.name}"`);
      }
      
      // 开始日期变化
      if (this.newState.startDate !== undefined) {
        const oldDate = this.oldState.startDate ? this.formatDate(this.oldState.startDate) : '';
        const newDate = this.formatDate(this.newState.startDate);
        if (oldDate) {
          details.push(`开始: ${oldDate} → ${newDate}`);
        } else {
          details.push(`开始日期: ${newDate}`);
        }
      }
      
      // 结束日期变化
      if (this.newState.endDate !== undefined) {
        const oldDate = this.oldState.endDate ? this.formatDate(this.oldState.endDate) : '';
        const newDate = this.formatDate(this.newState.endDate);
        if (oldDate) {
          details.push(`结束: ${oldDate} → ${newDate}`);
        } else {
          details.push(`结束日期: ${newDate}`);
        }
      }
      
      // 子任务变化
      if (this.newState.checklist !== undefined) {
        const oldCount = this.oldState.checklist?.length || 0;
        const newCount = this.newState.checklist.length;
        if (oldCount !== newCount) {
          details.push(`子任务: ${oldCount} → ${newCount} 项`);
        } else {
          details.push(`子任务已更新 (${newCount} 项)`);
        }
      }
      
      if (details.length > 0) {
        return `编辑"${task.name}": ${details.join(', ')}`;
      }
      return `编辑任务 "${task.name}"`;
    }
    return `编辑任务`;
  }
  
  /**
   * 格式化日期为简短字符串
   * @param date 日期对象
   * @returns 格式化后的日期字符串
   */
  private formatDate(date: Date): string {
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${month}/${day}`;
  }

  /**
   * 查找任务对象
   * @returns 任务对象，如果未找到则返回undefined
   */
  private findTask(): TaskNode | undefined {
    return this.project.tasks.find(t => t.id === this.taskId);
  }

  /**
   * 应用状态到任务
   * @param task 目标任务
   * @param state 要应用的状态
   */
  private applyState(task: TaskNode, state: Partial<TaskNode>): void {
    if (state.name !== undefined) task.name = state.name;
    if (state.startDate !== undefined) task.startDate = state.startDate;
    if (state.endDate !== undefined) task.endDate = state.endDate;
    if (state.x !== undefined) task.x = state.x;
    if (state.y !== undefined) task.y = state.y;
    if (state.checklist !== undefined) {
      // 深拷贝 checklist，确保每个 ChecklistItem 都是新对象
      task.checklist = state.checklist.map((item): ChecklistItem => {
        return {
          id: item.id,
          text: item.text,
          isCompleted: item.isCompleted
        };
      });
    }
    if (state.isCritical !== undefined) task.isCritical = state.isCritical;
    if (state.earlyStart !== undefined) task.earlyStart = state.earlyStart;
    if (state.earlyFinish !== undefined) task.earlyFinish = state.earlyFinish;
    if (state.lateStart !== undefined) task.lateStart = state.lateStart;
    if (state.lateFinish !== undefined) task.lateFinish = state.lateFinish;
  }
}

