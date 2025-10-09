// File: entry/src/main/ets/services/CriticalPathService.ets
/**
 * 关键路径服务模块
 * 
 * 本模块实现了项目管理中的关键路径法（CPM - Critical Path Method）算法，
 * 用于计算项目的最短完成时间和关键任务识别。关键路径法是一种网络分析技术，
 * 通过分析任务之间的依赖关系，确定影响项目总工期的关键路径。
 * 
 * 主要功能：
 * 1. 计算任务的最早开始时间（ES）和最早结束时间（EF）
 * 2. 计算任务的最晚开始时间（LS）和最晚结束时间（LF）
 * 3. 识别关键路径上的关键任务
 * 4. 检测循环依赖关系
 * 5. 计算任务的浮动时间（Slack Time）
 * 
 * 算法原理：
 * - 正向传递：从项目开始节点开始，计算每个任务的最早开始和结束时间
 * - 反向传递：从项目结束节点开始，计算每个任务的最晚开始和结束时间
 * - 关键路径识别：浮动时间为0的任务构成关键路径
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Dependency } from '../model/ProjectData';
import { ErrorHandler, ErrorType } from '../core/ErrorHandler';

/**
 * 带工期的任务接口
 * 用于关键路径计算，包含任务的基本信息和计算所需的时间参数
 */
export interface TaskWithDuration {
  /** 任务唯一标识符 */
  id: string;
  /** 任务工期（天数） */
  duration: number;
  /** 最早开始时间（天数，从项目开始计算） */
  earlyStart?: number;
  /** 最早结束时间（天数，从项目开始计算） */
  earlyFinish?: number;
  /** 最晚开始时间（天数，从项目开始计算） */
  lateStart?: number;
  /** 最晚结束时间（天数，从项目开始计算） */
  lateFinish?: number;
  /** 是否为关键任务 */
  isCritical?: boolean;
}

/**
 * 验证结果接口
 * 用于返回输入参数验证的结果
 */
export interface ValidationResult {
  /** 验证是否通过 */
  isValid: boolean;
  /** 验证失败时的错误信息 */
  error?: string;
}

/**
 * 关键路径计算结果接口
 * 包含关键路径计算的所有结果信息
 */
export interface CriticalPathResult {
  /** 计算是否成功 */
  success: boolean;
  /** 关键任务ID列表 */
  criticalTasks: string[];
  /** 项目总工期（天数） */
  projectDuration: number;
  /** 计算失败时的错误信息 */
  error?: string;
}

/**
 * 关键路径服务类
 * 
 * 实现关键路径法（CPM）算法的核心服务类，提供项目关键路径计算功能。
 * 该类采用单例模式设计，确保全局只有一个实例，提高性能和内存使用效率。
 * 
 * 核心算法：
 * 1. 正向传递算法：计算任务的最早开始和结束时间
 * 2. 反向传递算法：计算任务的最晚开始和结束时间
 * 3. 关键路径识别：通过浮动时间计算确定关键任务
 * 4. 循环依赖检测：使用深度优先搜索检测项目中的循环依赖
 * 
 * 时间复杂度：O(V + E)，其中V是任务数量，E是依赖关系数量
 * 空间复杂度：O(V + E)
 */
export class CriticalPathService {
  /** 错误处理器实例，用于统一错误处理 */
  private errorHandler: ErrorHandler;

  /**
   * 构造函数
   * 初始化错误处理器
   */
  constructor() {
    this.errorHandler = ErrorHandler.getInstance();
  }

  /**
   * 计算关键路径
   * 
   * 这是关键路径法（CPM）的核心方法，通过分析任务依赖关系计算项目关键路径。
   * 该方法会执行完整的CPM算法流程，包括输入验证、循环依赖检测、时间计算和关键路径识别。
   * 
   * 算法步骤：
   * 1. 输入参数验证：检查任务列表和依赖关系的有效性
   * 2. 循环依赖检测：使用DFS算法检测是否存在循环依赖
   * 3. 正向传递计算：计算每个任务的最早开始和结束时间
   * 4. 反向传递计算：计算每个任务的最晚开始和结束时间
   * 5. 关键路径识别：通过浮动时间计算确定关键任务
   * 
   * @param tasks 任务列表，包含任务ID、工期等基本信息
   * @param dependencies 依赖关系列表，定义任务之间的先后顺序
   * @returns CriticalPathResult 计算结果，包含关键任务列表和项目总工期
   * 
   * @throws Error 当输入参数无效或存在循环依赖时抛出错误
   * 
   * @example
   * ```typescript
   * const tasks = [
   *   { id: 'task1', duration: 5 },
   *   { id: 'task2', duration: 3 }
   * ];
   * const dependencies = [
   *   { fromId: 'task1', toId: 'task2' }
   * ];
   * const result = criticalPathService.calculate(tasks, dependencies);
   * console.log(result.criticalTasks); // 输出关键任务列表
   * ```
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
   * 
   * 对关键路径计算的输入参数进行完整性验证，确保算法能够正确执行。
   * 验证内容包括：任务列表非空、依赖关系有效性、任务ID唯一性、工期有效性等。
   * 
   * 验证规则：
   * 1. 任务列表不能为空
   * 2. 依赖关系列表不能为null
   * 3. 所有任务ID必须唯一
   * 4. 所有任务工期必须大于0
   * 5. 依赖关系中的任务ID必须在任务列表中存在
   * 
   * @param tasks 待验证的任务列表
   * @param dependencies 待验证的依赖关系列表
   * @returns ValidationResult 验证结果，包含是否通过和错误信息
   * 
   * @private
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
   * 
   * 使用深度优先搜索（DFS）算法检测项目中是否存在循环依赖关系。
   * 循环依赖会导致关键路径计算无法进行，因此必须在计算前进行检测。
   * 
   * 算法原理：
   * 1. 构建依赖关系的有向图
   * 2. 对每个未访问的节点执行DFS
   * 3. 使用递归栈记录当前路径上的节点
   * 4. 如果在DFS过程中遇到递归栈中的节点，则存在循环
   * 
   * 时间复杂度：O(V + E)，其中V是任务数量，E是依赖关系数量
   * 空间复杂度：O(V)，用于存储访问状态和递归栈
   * 
   * @param tasks 任务列表
   * @param dependencies 依赖关系列表
   * @returns boolean 如果存在循环依赖返回true，否则返回false
   * 
   * @private
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
   * 
   * 执行关键路径法（CPM）的核心计算流程，包括正向传递、反向传递和关键路径识别。
   * 该方法会修改传入的tasks数组，为每个任务计算时间参数并标记关键任务。
   * 
   * 计算流程：
   * 1. 初始化：将所有任务的时间参数重置为0
   * 2. 正向传递：计算最早开始和结束时间
   * 3. 反向传递：计算最晚开始和结束时间
   * 4. 关键路径识别：通过浮动时间确定关键任务
   * 
   * @param tasks 任务列表，计算完成后会包含所有时间参数
   * @param dependencies 依赖关系列表
   * 
   * @private
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
   * 
   * 计算任务的最早开始时间（ES）和最早结束时间（EF）。
   * 正向传递从项目开始节点开始，按照依赖关系的顺序依次计算每个任务的时间参数。
   * 
   * 计算公式：
   * - ES(task) = max(EF(predecessor)) for all predecessors
   * - EF(task) = ES(task) + Duration(task)
   * 
   * 算法特点：
   * 1. 使用拓扑排序确保按正确顺序处理任务
   * 2. 对于没有前驱的任务，ES默认为0
   * 3. 使用迭代方式处理，直到所有任务都被处理
   * 
   * @param tasks 任务列表，会被更新earlyStart和earlyFinish属性
   * @param dependencies 依赖关系列表
   * 
   * @private
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
   * 
   * 计算任务的最晚开始时间（LS）和最晚结束时间（LF）。
   * 反向传递从项目结束节点开始，按照依赖关系的逆序依次计算每个任务的时间参数。
   * 
   * 计算公式：
   * - LF(task) = min(LS(successor)) for all successors
   * - LS(task) = LF(task) - Duration(task)
   * - 对于没有后继的任务，LF = 项目总工期
   * 
   * 算法特点：
   * 1. 从项目结束节点开始反向计算
   * 2. 对于没有后继的任务，LF等于项目总工期
   * 3. 使用迭代方式处理，直到所有任务都被处理
   * 
   * @param tasks 任务列表，会被更新lateStart和lateFinish属性
   * @param dependencies 依赖关系列表
   * 
   * @private
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
   * 
   * 通过计算任务的浮动时间（Slack Time）来识别关键路径上的关键任务。
   * 浮动时间 = 最晚开始时间 - 最早开始时间，浮动时间为0的任务构成关键路径。
   * 
   * 关键路径定义：
   * - 关键路径是项目中从开始到结束的最长路径
   * - 关键路径上的任何任务延期都会导致整个项目延期
   * - 关键路径上的任务浮动时间为0或接近0
   * 
   * 算法原理：
   * 1. 计算每个任务的浮动时间：Slack = LS - ES
   * 2. 使用容差值处理浮点数精度问题
   * 3. 浮动时间小于等于容差值的任务标记为关键任务
   * 
   * @param tasks 任务列表，会被更新isCritical属性
   * 
   * @private
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
   * 
   * 计算指定任务的浮动时间（Slack Time），即任务可以延迟的时间而不影响项目总工期。
   * 浮动时间 = 最晚开始时间 - 最早开始时间
   * 
   * 浮动时间含义：
   * - 浮动时间 > 0：任务可以延迟，不会影响项目总工期
   * - 浮动时间 = 0：任务在关键路径上，不能延迟
   * - 浮动时间 < 0：项目计划存在问题（理论上不应该出现）
   * 
   * @param task 要计算浮动时间的任务
   * @returns number 浮动时间（天数），如果时间参数未计算则返回0
   * 
   * @public
   */
  public getTaskSlack(task: TaskWithDuration): number {
    return (task.lateStart || 0) - (task.earlyStart || 0);
  }

  /**
   * 获取关键路径上的任务
   * 
   * 从任务列表中筛选出所有关键任务，这些任务构成了项目的关键路径。
   * 关键任务是影响项目总工期的关键节点，任何延期都会导致整个项目延期。
   * 
   * @param tasks 任务列表
   * @returns TaskWithDuration[] 关键任务列表
   * 
   * @public
   */
  public getCriticalTasks(tasks: TaskWithDuration[]): TaskWithDuration[] {
    return tasks.filter(task => task.isCritical);
  }

  /**
   * 获取项目总工期
   * 
   * 计算项目的总工期，即所有任务中最大的最早结束时间。
   * 项目总工期决定了整个项目的最短完成时间。
   * 
   * @param tasks 任务列表
   * @returns number 项目总工期（天数）
   * 
   * @public
   */
  public getProjectDuration(tasks: TaskWithDuration[]): number {
    return Math.max(...tasks.map(t => t.earlyFinish || 0));
  }
}
