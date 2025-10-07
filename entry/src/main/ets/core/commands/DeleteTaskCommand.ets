// File: entry/src/main/ets/core/commands/DeleteTaskCommand.ets
/**
 * 删除任务命令
 * 
 * 本命令用于删除项目中的任务，支持撤销和重做。
 * 记录被删除的任务对象及其相关依赖关系，允许用户撤销删除操作。
 * 
 * 功能：
 * - 执行：从项目中删除任务及其相关依赖
 * - 撤销：恢复被删除的任务及其依赖关系
 * - 重做：再次删除任务
 * 
 * 使用场景：
 * - 用户删除任务节点
 * - 批量删除任务
 * 
 * 注意事项：
 * - 删除任务时会同时删除所有与该任务相关的依赖关系
 * - 撤销时需要恢复任务及其依赖关系
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { Command } from './Command';
import { Project, TaskNode, Dependency } from '../../model/ProjectData';

/**
 * 删除任务命令类
 * 
 * 记录被删除的任务和相关依赖，实现任务删除的撤销和重做。
 */
export class DeleteTaskCommand implements Command {
  /** 目标项目对象 */
  private project: Project;
  
  /** 被删除的任务对象 */
  private task: TaskNode;
  
  /** 任务在列表中的原始位置 */
  private taskIndex: number;
  
  /** 与该任务相关的依赖关系（需要一起删除） */
  private relatedDependencies: Dependency[];

  /**
   * 构造函数
   * 
   * @param project 目标项目
   * @param task 要删除的任务
   */
  constructor(project: Project, task: TaskNode) {
    this.project = project;
    this.task = task;
    
    // 记录任务的原始位置
    this.taskIndex = project.tasks.findIndex(t => t.id === task.id);
    
    // 记录所有与该任务相关的依赖关系
    this.relatedDependencies = project.dependencies.filter(
      d => d.fromId === task.id || d.toId === task.id
    );
  }

  /**
   * 执行命令：删除任务及其相关依赖
   */
  execute(): void {
    // 删除任务
    const index = this.project.tasks.findIndex(t => t.id === this.task.id);
    if (index !== -1) {
      this.project.tasks.splice(index, 1);
    }
    
    // 删除相关依赖
    this.project.dependencies = this.project.dependencies.filter(
      d => d.fromId !== this.task.id && d.toId !== this.task.id
    );
    
    console.log(`[DeleteTaskCommand] 执行删除任务: ${this.task.name} (${this.task.id})`);
    console.log(`[DeleteTaskCommand] 同时删除了 ${this.relatedDependencies.length} 个相关依赖`);
  }

  /**
   * 撤销命令：恢复被删除的任务及其依赖
   */
  undo(): void {
    // 恢复任务到原始位置
    if (this.taskIndex >= 0 && this.taskIndex <= this.project.tasks.length) {
      this.project.tasks.splice(this.taskIndex, 0, this.task);
    } else {
      // 如果原始位置无效，添加到末尾
      this.project.tasks.push(this.task);
    }
    
    // 恢复相关依赖
    this.relatedDependencies.forEach(dep => {
      // 检查依赖是否已存在，避免重复添加
      const exists = this.project.dependencies.some(
        d => d.fromId === dep.fromId && d.toId === dep.toId
      );
      if (!exists) {
        this.project.dependencies.push(dep);
      }
    });
    
    console.log(`[DeleteTaskCommand] 撤销删除任务: ${this.task.name} (${this.task.id})`);
    console.log(`[DeleteTaskCommand] 同时恢复了 ${this.relatedDependencies.length} 个相关依赖`);
  }

  /**
   * 重做命令：再次删除任务
   */
  redo(): void {
    this.execute();
  }

  /**
   * 获取命令名称
   * @returns 命令描述
   */
  getName(): string {
    return `删除任务 "${this.task.name}"`;
  }
}

