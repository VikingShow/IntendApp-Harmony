// File: entry/src/main/ets/services/CriticalPathService.ets

import { Dependency } from '../model/ProjectData';
import { ErrorHandler, ErrorType } from '../core/ErrorHandler';

// Export the interface so it can be used in other files
export interface TaskWithDuration {
  id: string;
  duration: number;
  earlyStart?: number;
  earlyFinish?: number;
  lateStart?: number;
  lateFinish?: number;
  isCritical?: boolean;
}

/**
 * 验证结果接口
 */
export interface ValidationResult {
  isValid: boolean;
  error?: string;
}

/**
 * 关键路径计算结果
 */
export interface CriticalPathResult {
  success: boolean;
  criticalTasks: string[];
  projectDuration: number;
  error?: string;
}

/**
 * 关键路径服务类
 * 使用关键路径法(CPM)计算项目关键路径
 */
export class CriticalPathService {
  private errorHandler: ErrorHandler;

  constructor() {
    this.errorHandler = ErrorHandler.getInstance();
  }

  /**
   * 计算关键路径
   * @param tasks 任务列表
   * @param dependencies 依赖关系
   * @returns 计算结果
   */
  public calculate(tasks: TaskWithDuration[], dependencies: Dependency[]): CriticalPathResult {
    try {
      // 输入验证
      const validation = this.validateInput(tasks, dependencies);
      if (!validation.isValid) {
        const errorMessage = validation.error || '输入验证失败';
        this.errorHandler.handleValidationError(errorMessage, 'CriticalPathService.calculate');
        return {
          success: false,
          criticalTasks: [],
          projectDuration: 0,
          error: errorMessage
        };
      }

      // 检查循环依赖
      if (this.hasCircularDependency(tasks, dependencies)) {
        const error = '项目存在循环依赖，无法计算关键路径';
        this.errorHandler.handleBusinessError(error, 'CriticalPathService.calculate');
        return {
          success: false,
          criticalTasks: [],
          projectDuration: 0,
          error: error
        };
      }

      // 执行计算
      this.performCalculation(tasks, dependencies);

      // 获取结果
      const criticalTasks = tasks.filter(task => task.isCritical).map(task => task.id);
      const projectDuration = Math.max(...tasks.map(t => t.earlyFinish || 0));

      return {
        success: true,
        criticalTasks: criticalTasks,
        projectDuration: projectDuration
      };

    } catch (error) {
      this.errorHandler.handle(error as Error, 'CriticalPathService.calculate', ErrorType.BUSINESS);
      return {
        success: false,
        criticalTasks: [],
        projectDuration: 0,
        error: (error as Error).message
      };
    }
  }

  /**
   * 验证输入参数
   * @param tasks 任务列表
   * @param dependencies 依赖关系
   * @returns 验证结果
   */
  private validateInput(tasks: TaskWithDuration[], dependencies: Dependency[]): ValidationResult {
    if (!tasks || tasks.length === 0) {
      return { isValid: false, error: '任务列表不能为空' };
    }

    if (!dependencies) {
      return { isValid: false, error: '依赖关系不能为空' };
    }

    // 检查任务ID唯一性
    const taskIds = tasks.map(t => t.id);
    const uniqueIds = new Set(taskIds);
    if (taskIds.length !== uniqueIds.size) {
      return { isValid: false, error: '任务ID必须唯一' };
    }

    // 检查任务工期
    for (const task of tasks) {
      if (task.duration <= 0) {
        return { isValid: false, error: `任务 ${task.id} 的工期必须大于0` };
      }
    }

    // 检查依赖关系中的任务是否存在
    for (const dep of dependencies) {
      if (!taskIds.includes(dep.fromId)) {
        return { isValid: false, error: `依赖关系中的源任务 ${dep.fromId} 不存在` };
      }
      if (!taskIds.includes(dep.toId)) {
        return { isValid: false, error: `依赖关系中的目标任务 ${dep.toId} 不存在` };
      }
    }

    return { isValid: true };
  }

  /**
   * 检查是否存在循环依赖
   * @param tasks 任务列表
   * @param dependencies 依赖关系
   * @returns 是否存在循环依赖
   */
  private hasCircularDependency(tasks: TaskWithDuration[], dependencies: Dependency[]): boolean {
    const visited = new Set<string>();
    const recursionStack = new Set<string>();

    const dfs = (taskId: string): boolean => {
      if (recursionStack.has(taskId)) {
        return true; // 发现循环
      }
      if (visited.has(taskId)) {
        return false; // 已经访问过，无循环
      }

      visited.add(taskId);
      recursionStack.add(taskId);

      // 查找所有依赖此任务的任务
      const successors = dependencies
        .filter(dep => dep.fromId === taskId)
        .map(dep => dep.toId);

      for (const successor of successors) {
        if (dfs(successor)) {
          return true;
        }
      }

      recursionStack.delete(taskId);
      return false;
    };

    // 检查每个任务
    for (const task of tasks) {
      if (!visited.has(task.id)) {
        if (dfs(task.id)) {
          return true;
        }
      }
    }

    return false;
  }

  /**
   * 执行关键路径计算
   * @param tasks 任务列表
   * @param dependencies 依赖关系
   */
  private performCalculation(tasks: TaskWithDuration[], dependencies: Dependency[]): void {
    // 1. 初始化
    tasks.forEach(task => {
      task.earlyStart = 0;
      task.earlyFinish = 0;
      task.lateStart = 0;
      task.lateFinish = 0;
      task.isCritical = false;
    });

    // 2. 正向传递 - 计算最早开始和最早结束时间
    this.forwardPass(tasks, dependencies);

    // 3. 反向传递 - 计算最晚开始和最晚结束时间
    this.backwardPass(tasks, dependencies);

    // 4. 计算关键路径
    this.calculateCriticalPath(tasks);
  }

  /**
   * 正向传递计算
   * @param tasks 任务列表
   * @param dependencies 依赖关系
   */
  private forwardPass(tasks: TaskWithDuration[], dependencies: Dependency[]): void {
    // 创建依赖关系映射，提高查找效率
    const predecessorMap = new Map<string, string[]>();
    dependencies.forEach(dep => {
      if (!predecessorMap.has(dep.toId)) {
        predecessorMap.set(dep.toId, []);
      }
      predecessorMap.get(dep.toId)!.push(dep.fromId);
    });

    // 按拓扑排序处理任务
    const processed = new Set<string>();
    let hasProgress = true;

    while (hasProgress) {
      hasProgress = false;
      
      for (const task of tasks) {
        if (processed.has(task.id)) continue;

        const predecessors = predecessorMap.get(task.id) || [];
        let maxEF = 0;
        let allPredecessorsProcessed = true;

        for (const predId of predecessors) {
          const predTask = tasks.find(t => t.id === predId);
          if (!predTask || !processed.has(predId)) {
            allPredecessorsProcessed = false;
            break;
          }
          maxEF = Math.max(maxEF, predTask.earlyFinish || 0);
        }

        if (allPredecessorsProcessed) {
          task.earlyStart = maxEF;
          task.earlyFinish = task.earlyStart + task.duration;
          processed.add(task.id);
          hasProgress = true;
        }
      }
    }
  }

  /**
   * 反向传递计算
   * @param tasks 任务列表
   * @param dependencies 依赖关系
   */
  private backwardPass(tasks: TaskWithDuration[], dependencies: Dependency[]): void {
    // 创建后继关系映射
    const successorMap = new Map<string, string[]>();
    dependencies.forEach(dep => {
      if (!successorMap.has(dep.fromId)) {
        successorMap.set(dep.fromId, []);
      }
      successorMap.get(dep.fromId)!.push(dep.toId);
    });

    // 计算项目总工期
    const maxProjectEF = Math.max(...tasks.map(t => t.earlyFinish || 0));

    // 按逆拓扑排序处理任务
    const processed = new Set<string>();
    let hasProgress = true;

    while (hasProgress) {
      hasProgress = false;
      
      for (const task of tasks) {
        if (processed.has(task.id)) continue;

        const successors = successorMap.get(task.id) || [];
        let minLS = Infinity;
        let allSuccessorsProcessed = true;

        if (successors.length === 0) {
          // 没有后继任务，最晚结束时间等于项目总工期
          task.lateFinish = maxProjectEF;
        } else {
          for (const succId of successors) {
            const succTask = tasks.find(t => t.id === succId);
            if (!succTask || !processed.has(succId)) {
              allSuccessorsProcessed = false;
              break;
            }
            minLS = Math.min(minLS, succTask.lateStart || Infinity);
          }
          
          if (allSuccessorsProcessed) {
            task.lateFinish = minLS;
          }
        }

        if (allSuccessorsProcessed || successors.length === 0) {
          task.lateStart = (task.lateFinish || 0) - task.duration;
          processed.add(task.id);
          hasProgress = true;
        }
      }
    }
  }

  /**
   * 计算关键路径
   * @param tasks 任务列表
   */
  private calculateCriticalPath(tasks: TaskWithDuration[]): void {
    const TOLERANCE = 0.001; // 浮点数比较容差

    tasks.forEach(task => {
      const slack = (task.lateStart || 0) - (task.earlyStart || 0);
      task.isCritical = Math.abs(slack) <= TOLERANCE;
    });
  }

  /**
   * 获取任务的浮动时间
   * @param task 任务
   * @returns 浮动时间
   */
  public getTaskSlack(task: TaskWithDuration): number {
    return (task.lateStart || 0) - (task.earlyStart || 0);
  }

  /**
   * 获取关键路径上的任务
   * @param tasks 任务列表
   * @returns 关键任务列表
   */
  public getCriticalTasks(tasks: TaskWithDuration[]): TaskWithDuration[] {
    return tasks.filter(task => task.isCritical);
  }

  /**
   * 获取项目总工期
   * @param tasks 任务列表
   * @returns 项目总工期
   */
  public getProjectDuration(tasks: TaskWithDuration[]): number {
    return Math.max(...tasks.map(t => t.earlyFinish || 0));
  }
}
