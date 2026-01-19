/**
 * 数据验证工具模块
 * 提供项目、任务、检查清单等数据的验证功能
 */

import { TaskNode } from '../model/ProjectData';

/** 验证结果接口 */
interface ValidationResult {
  /** 验证是否通过 */
  isValid: boolean;
  /** 验证失败时的错误信息 */
  message: string;
}

/** 数据验证工具类 */
export class ValidationUtils {
  /** 验证项目名称：不能为空，长度不超过50个字符 */
  static validateProjectName(name: string): ValidationResult {
    if (!name || name.trim().length === 0) {
      return { isValid: false, message: '项目名称不能为空' };
    }
    
    if (name.trim().length > 50) {
      return { isValid: false, message: '项目名称不能超过50个字符' };
    }
    
    return { isValid: true, message: '' };
  }

  /** 验证任务名称：不能为空，长度不超过100个字符 */
  static validateTaskName(name: string): ValidationResult {
    if (!name || name.trim().length === 0) {
      return { isValid: false, message: '任务名称不能为空' };
    }

    if (name.trim().length > 100) {
      return { isValid: false, message: '任务名称不能超过100个字符' };
    }

    return { isValid: true, message: '' };
  }

  /** 验证任务数据：名称不为空，时间合理，开始时间早于结束时间 */
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
    
    const now = new Date();
    const oneYearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
    if (task.startDate < oneYearAgo) {
      return { isValid: false, message: '开始时间不能早于一年前' };
    }
    
    const oneYearLater = new Date(now.getFullYear() + 1, now.getMonth(), now.getDate());
    if (task.endDate > oneYearLater) {
      return { isValid: false, message: '结束时间不能晚于一年后' };
    }
    
    return { isValid: true, message: '' };
  }

  /** 验证检查清单项：内容不为空，长度不超过200个字符 */
  static validateChecklistItem(text: string): ValidationResult {
    if (!text || text.trim().length === 0) {
      return { isValid: false, message: '清单项内容不能为空' };
    }
    
    if (text.trim().length > 200) {
      return { isValid: false, message: '清单项内容不能超过200个字符' };
    }
    
    return { isValid: true, message: '' };
  }

  /** 验证依赖关系：任务不能依赖自己，不能循环依赖 */
  static validateDependency(fromId: string, toId: string, tasks: TaskNode[]): ValidationResult {
    if (fromId === toId) {
      return { isValid: false, message: '任务不能依赖自己' };
    }
    
    const fromTask = tasks.find(t => t.id === fromId);
    const toTask = tasks.find(t => t.id === toId);
    
    if (!fromTask || !toTask) {
      return { isValid: false, message: '依赖的任务不存在' };
    }
    
    if (ValidationUtils.wouldCreateCycle(fromId, toId, tasks)) {
      return { isValid: false, message: '不能创建循环依赖' };
    }
    
    return { isValid: true, message: '' };
  }

  /** 检查是否会造成循环依赖（使用深度优先搜索） */
  private static wouldCreateCycle(fromId: string, toId: string, tasks: TaskNode[]): boolean {
    const visited = new Set<string>();
    const stack: string[] = [toId];
    
    while (stack.length > 0) {
      const current = stack.pop()!;
      
      if (current === fromId) {
        return true;
      }
      
      if (visited.has(current)) {
        continue;
      }
      
      visited.add(current);
    }
    
    return false;
  }
} 
