// File: entry/src/main/ets/utils/ValidationUtils.ets

import { TaskNode } from '../model/ProjectData';

// 定义验证结果接口
interface ValidationResult {
  isValid: boolean;
  message: string;
}

export class ValidationUtils {
  /**
   * 验证项目名称
   */
  static validateProjectName(name: string): ValidationResult {
    if (!name || name.trim().length === 0) {
      return { isValid: false, message: '项目名称不能为空' };
    }
    
    if (name.trim().length > 50) {
      return { isValid: false, message: '项目名称不能超过50个字符' };
    }
    
    return { isValid: true, message: '' };
  }

  /**
   * 验证任务数据
   */
  static validateTaskData(task: TaskNode): ValidationResult {
    if (!task.name || task.name.trim().length === 0) {
      return { isValid: false, message: '任务名称不能为空' };
    }
    
    if (task.name.trim().length > 100) {
      return { isValid: false, message: '任务名称不能超过100个字符' };
    }
    
    if (task.startDate >= task.endDate) {
      return { isValid: false, message: '开始时间必须早于结束时间' };
    }
    
    // 检查日期是否合理（不能是过去很久的日期）
    const now = new Date();
    const oneYearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
    if (task.startDate < oneYearAgo) {
      return { isValid: false, message: '开始时间不能早于一年前' };
    }
    
    // 检查日期是否合理（不能是未来很久的日期）
    const oneYearLater = new Date(now.getFullYear() + 1, now.getMonth(), now.getDate());
    if (task.endDate > oneYearLater) {
      return { isValid: false, message: '结束时间不能晚于一年后' };
    }
    
    return { isValid: true, message: '' };
  }

  /**
   * 验证清单项
   */
  static validateChecklistItem(text: string): ValidationResult {
    if (!text || text.trim().length === 0) {
      return { isValid: false, message: '清单项内容不能为空' };
    }
    
    if (text.trim().length > 200) {
      return { isValid: false, message: '清单项内容不能超过200个字符' };
    }
    
    return { isValid: true, message: '' };
  }

  /**
   * 验证依赖关系
   */
  static validateDependency(fromId: string, toId: string, tasks: TaskNode[]): ValidationResult {
    if (fromId === toId) {
      return { isValid: false, message: '任务不能依赖自己' };
    }
    
    const fromTask = tasks.find(t => t.id === fromId);
    const toTask = tasks.find(t => t.id === toId);
    
    if (!fromTask || !toTask) {
      return { isValid: false, message: '依赖的任务不存在' };
    }
    
    // 检查是否会造成循环依赖
    if (ValidationUtils.wouldCreateCycle(fromId, toId, tasks)) {
      return { isValid: false, message: '不能创建循环依赖' };
    }
    
    return { isValid: true, message: '' };
  }

  /**
   * 检查是否会造成循环依赖
   */
  private static wouldCreateCycle(fromId: string, toId: string, tasks: TaskNode[]): boolean {
    // 简单的循环检测：检查从toId是否能到达fromId
    const visited = new Set<string>();
    const stack: string[] = [toId];
    
    while (stack.length > 0) {
      const current = stack.pop()!;
      
      if (current === fromId) {
        return true; // 发现循环
      }
      
      if (visited.has(current)) {
        continue;
      }
      
      visited.add(current);
      
      // 这里需要实际的依赖关系数据来检查
      // 由于当前没有完整的依赖关系数据，这里只是示例
      // 实际实现需要传入完整的依赖关系数组
    }
    
    return false;
  }
} 