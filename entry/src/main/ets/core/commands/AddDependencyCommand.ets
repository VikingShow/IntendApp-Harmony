// File: entry/src/main/ets/core/commands/AddDependencyCommand.ets
/**
 * 添加依赖关系命令
 * 
 * 本命令用于在两个任务之间建立依赖关系，支持撤销和重做。
 * 记录依赖关系的源任务和目标任务，允许用户撤销依赖创建操作。
 * 
 * 功能：
 * - 执行：在两个任务之间建立依赖关系
 * - 撤销：删除该依赖关系
 * - 重做：再次建立依赖关系
 * 
 * 使用场景：
 * - 用户通过连线创建任务依赖
 * - 批量导入依赖关系
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { Command } from './Command';
import { Project, Dependency } from '../../model/ProjectData';

/**
 * 添加依赖关系命令类
 * 
 * 记录要添加的依赖关系，实现依赖添加的撤销和重做。
 */
export class AddDependencyCommand implements Command {
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
   * 执行命令：添加依赖关系
   */
  execute(): void {
    // 检查依赖是否已存在
    const exists = this.project.dependencies.some(
      d => d.fromId === this.fromId && d.toId === this.toId
    );
    
    if (!exists) {
      const dependency: Dependency = {
        fromId: this.fromId,
        toId: this.toId
      };
      this.project.dependencies.push(dependency);
      console.log(`[AddDependencyCommand] 执行添加依赖: ${this.fromId} -> ${this.toId}`);
    } else {
      console.log(`[AddDependencyCommand] 依赖已存在，跳过: ${this.fromId} -> ${this.toId}`);
    }
  }

  /**
   * 撤销命令：删除依赖关系
   */
  undo(): void {
    this.project.dependencies = this.project.dependencies.filter(
      d => !(d.fromId === this.fromId && d.toId === this.toId)
    );
    console.log(`[AddDependencyCommand] 撤销添加依赖: ${this.fromId} -> ${this.toId}`);
  }

  /**
   * 重做命令：再次添加依赖关系
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
      return `添加依赖 "${fromTask.name}" → "${toTask.name}"`;
    }
    return `添加依赖关系`;
  }
}

