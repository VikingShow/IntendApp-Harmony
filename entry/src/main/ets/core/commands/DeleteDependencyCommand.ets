// File: entry/src/main/ets/core/commands/DeleteDependencyCommand.ets
/**
 * 删除依赖关系命令
 * 
 * 本命令用于删除两个任务之间的依赖关系，支持撤销和重做。
 * 记录被删除的依赖关系，允许用户撤销删除操作。
 * 
 * 功能：
 * - 执行：删除两个任务之间的依赖关系
 * - 撤销：恢复被删除的依赖关系
 * - 重做：再次删除依赖关系
 * 
 * 使用场景：
 * - 用户删除任务间的连线
 * - 批量删除依赖关系
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { Command } from './Command';
import { Project, Dependency } from '../../model/ProjectData';

/**
 * 删除依赖关系命令类
 * 
 * 记录被删除的依赖关系，实现依赖删除的撤销和重做。
 */
export class DeleteDependencyCommand implements Command {
  /** 目标项目对象 */
  private project: Project;
  
  /** 源任务ID */
  private fromId: string;
  
  /** 目标任务ID */
  private toId: string;

  /**
   * 构造函数
   * 
   * @param project 目标项目
   * @param fromId 源任务ID
   * @param toId 目标任务ID
   */
  constructor(project: Project, fromId: string, toId: string) {
    this.project = project;
    this.fromId = fromId;
    this.toId = toId;
  }

  /**
   * 执行命令：删除依赖关系
   */
  execute(): void {
    this.project.dependencies = this.project.dependencies.filter(
      d => !(d.fromId === this.fromId && d.toId === this.toId)
    );
    console.log(`[DeleteDependencyCommand] 执行删除依赖: ${this.fromId} -> ${this.toId}`);
  }

  /**
   * 撤销命令：恢复依赖关系
   */
  undo(): void {
    // 检查依赖是否已存在，避免重复添加
    const exists = this.project.dependencies.some(
      d => d.fromId === this.fromId && d.toId === this.toId
    );
    
    if (!exists) {
      const dependency: Dependency = {
        fromId: this.fromId,
        toId: this.toId
      };
      this.project.dependencies.push(dependency);
      console.log(`[DeleteDependencyCommand] 撤销删除依赖: ${this.fromId} -> ${this.toId}`);
    } else {
      console.log(`[DeleteDependencyCommand] 依赖已存在，跳过恢复: ${this.fromId} -> ${this.toId}`);
    }
  }

  /**
   * 重做命令：再次删除依赖关系
   */
  redo(): void {
    this.execute();
  }

  /**
   * 获取命令名称
   * @returns 命令描述
   */
  getName(): string {
    // 尝试获取任务名称以提供更友好的描述
    const fromTask = this.project.tasks.find(t => t.id === this.fromId);
    const toTask = this.project.tasks.find(t => t.id === this.toId);
    
    if (fromTask && toTask) {
      return `删除依赖 "${fromTask.name}" → "${toTask.name}"`;
    }
    return `删除依赖关系`;
  }
}

