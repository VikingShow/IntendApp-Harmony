// File: entry/src/main/ets/core/commands/AddTaskCommand.ets
/**
 * 添加任务命令
 * 
 * 本命令用于添加新任务到项目中，支持撤销和重做。
 * 记录新添加的任务对象，允许用户撤销添加操作。
 * 
 * 功能：
 * - 执行：将任务添加到项目任务列表
 * - 撤销：从项目中删除该任务
 * - 重做：再次将任务添加到项目
 * 
 * 使用场景：
 * - 用户点击"添加任务"按钮
 * - 通过模板创建任务
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { Command } from './Command';
import { Project, TaskNode } from '../../model/ProjectData';

/**
 * 添加任务命令类
 * 
 * 记录要添加的任务对象，实现任务添加的撤销和重做。
 */
export class AddTaskCommand implements Command {
  /** 目标项目对象 */
  private project: Project;
  
  /** 要添加的任务对象 */
  private task: TaskNode;

  /**
   * 构造函数
   * 
   * @param project 目标项目
   * @param task 要添加的任务
   */
  constructor(project: Project, task: TaskNode) {
    this.project = project;
    this.task = task;
  }

  /**
   * 执行命令：添加任务到项目
   */
  execute(): void {
    this.project.tasks.push(this.task);
    console.log(`[AddTaskCommand] 执行添加任务: ${this.task.name} (${this.task.id})`);
  }

  /**
   * 撤销命令：从项目中删除任务
   */
  undo(): void {
    const index = this.project.tasks.findIndex(t => t.id === this.task.id);
    if (index !== -1) {
      this.project.tasks.splice(index, 1);
      console.log(`[AddTaskCommand] 撤销添加任务: ${this.task.name} (${this.task.id})`);
    } else {
      console.error(`[AddTaskCommand] 撤销失败，未找到任务: ${this.task.id}`);
    }
  }

  /**
   * 重做命令：再次添加任务到项目
   */
  redo(): void {
    this.execute();
  }

  /**
   * 获取命令名称
   * @returns 命令描述
   */
  getName(): string {
    return `添加任务 "${this.task.name}"`;
  }
}

