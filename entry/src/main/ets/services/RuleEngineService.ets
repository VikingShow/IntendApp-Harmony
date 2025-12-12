// File: entry/src/main/ets/services/RuleEngineService.ets
/**
 * 规则引擎服务
 * 
 * 功能：
 * - 执行节点规则（事件驱动）
 * - 动作执行器（setVisible/setEnabled/setValue/validate）
 * - 规则队列管理
 * - 循环保护（最大迭代次数限制）
 */

import { 
  NodeRule, 
  NodeRuntimeState, 
  NodeFieldValue, 
  RuleCondition,
  RuleAction,
  RuleEventType,
  RuleActionType
} from '../model/NodeSchema';

/**
 * 规则执行结果
 */
export interface RuleExecutionResult {
  success: boolean;
  executedRules: number;
  iterations: number;
  errors: string[];
}

/**
 * 规则引擎配置
 */
export interface RuleEngineConfig {
  /** 最大迭代次数（防止无限循环） */
  maxIterations: number;
  /** 是否启用调试日志 */
  debug: boolean;
}

/**
 * 规则引擎服务（单例）
 */
export class RuleEngineService {
  private static instance: RuleEngineService;
  private config: RuleEngineConfig = {
    maxIterations: 10,
    debug: false
  };

  /** 规则执行队列 */
  private ruleQueue: NodeRule[] = [];
  /** 当前迭代次数 */
  private currentIteration: number = 0;

  /**
   * 获取单例实例
   */
  static getInstance(): RuleEngineService {
    if (!RuleEngineService.instance) {
      RuleEngineService.instance = new RuleEngineService();
    }
    return RuleEngineService.instance;
  }

  /**
   * 配置规则引擎
   */
  public configure(config: Partial<RuleEngineConfig>): void {
    this.config = { ...this.config, ...config };
  }

  /**
   * 执行节点加载事件规则
   * @param rules 节点的所有规则
   * @param runtimeState 运行时状态
   * @returns 执行结果
   */
  public executeNodeLoadRules(
    rules: NodeRule[],
    runtimeState: NodeRuntimeState
  ): RuleExecutionResult {
    const nodeLoadRules = rules.filter(r => r.enabled !== false && r.event === 'nodeLoad');
    return this.executeRules(nodeLoadRules, runtimeState, 'nodeLoad');
  }

  /**
   * 执行字段变化事件规则
   * @param rules 节点的所有规则
   * @param fieldId 变化的字段 ID
   * @param runtimeState 运行时状态
   * @returns 执行结果
   */
  public executeFieldChangeRules(
    rules: NodeRule[],
    fieldId: string,
    runtimeState: NodeRuntimeState
  ): RuleExecutionResult {
    const fieldChangeRules = rules.filter(
      r => r.enabled !== false && r.event === 'fieldChange' && r.watchFieldId === fieldId
    );
    return this.executeRules(fieldChangeRules, runtimeState, 'fieldChange', fieldId);
  }

  /**
   * 执行规则列表
   * @param rules 要执行的规则列表
   * @param runtimeState 运行时状态
   * @param eventType 事件类型
   * @param context 上下文信息
   * @returns 执行结果
   */
  private executeRules(
    rules: NodeRule[],
    runtimeState: NodeRuntimeState,
    eventType: RuleEventType,
    context?: string
  ): RuleExecutionResult {
    const result: RuleExecutionResult = {
      success: true,
      executedRules: 0,
      iterations: 0,
      errors: []
    };

    this.currentIteration = 0;
    this.ruleQueue = [...rules];

    try {
      while (this.ruleQueue.length > 0 && this.currentIteration < this.config.maxIterations) {
        this.currentIteration++;
        result.iterations = this.currentIteration;

        const rule = this.ruleQueue.shift();
        if (!rule) break;

        if (this.config.debug) {
          console.log(`[RuleEngine] Executing rule: ${rule.name} (iteration ${this.currentIteration})`);
        }

        // 评估条件
        const conditionsMet = this.evaluateConditions(rule.conditions, runtimeState);

        if (conditionsMet) {
          // 执行动作
          for (const action of rule.actions) {
            try {
              this.executeAction(action, runtimeState);
              result.executedRules++;
            } catch (error) {
              const errorMsg = `规则 "${rule.name}" 执行失败: ${error}`;
              result.errors.push(errorMsg);
              console.error(`[RuleEngine] ${errorMsg}`);
            }
          }
        }
      }

      // 检查是否达到最大迭代次数
      if (this.currentIteration >= this.config.maxIterations) {
        const warning = `规则执行达到最大迭代次数 (${this.config.maxIterations})，可能存在循环依赖`;
        result.errors.push(warning);
        console.warn(`[RuleEngine] ${warning}`);
        result.success = false;
      }

    } catch (error) {
      result.success = false;
      result.errors.push(`规则引擎执行异常: ${error}`);
      console.error('[RuleEngine] Execution error:', error);
    }

    return result;
  }

  /**
   * 评估条件列表（AND 逻辑）
   * @param conditions 条件列表
   * @param runtimeState 运行时状态
   * @returns 是否所有条件都满足
   */
  private evaluateConditions(
    conditions: RuleCondition[],
    runtimeState: NodeRuntimeState
  ): boolean {
    if (conditions.length === 0) {
      return true; // 无条件，直接执行
    }

    for (const condition of conditions) {
      if (!this.evaluateCondition(condition, runtimeState)) {
        return false;
      }
    }

    return true;
  }

  /**
   * 评估单个条件
   * @param condition 条件
   * @param runtimeState 运行时状态
   * @returns 是否满足条件
   */
  private evaluateCondition(
    condition: RuleCondition,
    runtimeState: NodeRuntimeState
  ): boolean {
    const fieldValue = runtimeState.values.get(condition.fieldId);

    switch (condition.operator) {
      case 'equals':
        return fieldValue === condition.value;
      
      case 'notEquals':
        return fieldValue !== condition.value;
      
      case 'contains':
        if (typeof fieldValue === 'string' && typeof condition.value === 'string') {
          return fieldValue.includes(condition.value);
        }
        if (Array.isArray(fieldValue) && condition.value !== null && condition.value !== undefined) {
          return fieldValue.includes(condition.value);
        }
        return false;
      
      case 'greaterThan':
        if (typeof fieldValue === 'number' && typeof condition.value === 'number') {
          return fieldValue > condition.value;
        }
        return false;
      
      case 'lessThan':
        if (typeof fieldValue === 'number' && typeof condition.value === 'number') {
          return fieldValue < condition.value;
        }
        return false;
      
      case 'isEmpty':
        return fieldValue === null || fieldValue === undefined || fieldValue === '' || 
               (Array.isArray(fieldValue) && fieldValue.length === 0);
      
      case 'isNotEmpty':
        return fieldValue !== null && fieldValue !== undefined && fieldValue !== '' &&
               (!Array.isArray(fieldValue) || fieldValue.length > 0);
      
      default:
        console.warn(`[RuleEngine] Unknown operator: ${condition.operator}`);
        return false;
    }
  }

  /**
   * 执行动作
   * @param action 动作
   * @param runtimeState 运行时状态
   */
  private executeAction(
    action: RuleAction,
    runtimeState: NodeRuntimeState
  ): void {
    switch (action.type) {
      case 'setVisible':
        this.actionSetVisible(action, runtimeState);
        break;
      
      case 'setEnabled':
        this.actionSetEnabled(action, runtimeState);
        break;
      
      case 'setValue':
        this.actionSetValue(action, runtimeState);
        break;
      
      case 'validate':
        this.actionValidate(action, runtimeState);
        break;
      
      default:
        throw new Error(`Unknown action type: ${action.type}`);
    }
  }

  /**
   * 动作：设置字段可见性
   */
  private actionSetVisible(action: RuleAction, runtimeState: NodeRuntimeState): void {
    if (!action.params || action.params.boolValue === undefined) {
      throw new Error('setVisible action requires params.boolValue');
    }
    runtimeState.visible.set(action.targetFieldId, action.params.boolValue);
    
    if (this.config.debug) {
      console.log(`[RuleEngine] Set visible: ${action.targetFieldId} = ${action.params.boolValue}`);
    }
  }

  /**
   * 动作：设置字段启用状态
   */
  private actionSetEnabled(action: RuleAction, runtimeState: NodeRuntimeState): void {
    if (!action.params || action.params.boolValue === undefined) {
      throw new Error('setEnabled action requires params.boolValue');
    }
    runtimeState.enabled.set(action.targetFieldId, action.params.boolValue);
    
    if (this.config.debug) {
      console.log(`[RuleEngine] Set enabled: ${action.targetFieldId} = ${action.params.boolValue}`);
    }
  }

  /**
   * 动作：设置字段值
   */
  private actionSetValue(action: RuleAction, runtimeState: NodeRuntimeState): void {
    if (!action.params || action.params.newValue === undefined) {
      throw new Error('setValue action requires params.newValue');
    }
    runtimeState.values.set(action.targetFieldId, action.params.newValue);
    
    if (this.config.debug) {
      console.log(`[RuleEngine] Set value: ${action.targetFieldId} = ${action.params.newValue}`);
    }
  }

  /**
   * 动作：验证字段
   */
  private actionValidate(action: RuleAction, runtimeState: NodeRuntimeState): void {
    if (!action.params || !action.params.errorMessage) {
      throw new Error('validate action requires params.errorMessage');
    }
    runtimeState.errors.set(action.targetFieldId, action.params.errorMessage);
    
    if (this.config.debug) {
      console.log(`[RuleEngine] Validate: ${action.targetFieldId} = ${action.params.errorMessage}`);
    }
  }

  /**
   * 清空错误信息
   * @param runtimeState 运行时状态
   */
  public clearErrors(runtimeState: NodeRuntimeState): void {
    runtimeState.errors.clear();
  }

  /**
   * 初始化运行时状态
   * @param fieldIds 字段 ID 列表
   * @returns 初始化的运行时状态
   */
  public initializeRuntimeState(fieldIds: string[]): NodeRuntimeState {
    const state: NodeRuntimeState = {
      values: new Map(),
      visible: new Map(),
      enabled: new Map(),
      errors: new Map()
    };

    // 默认所有字段可见且启用
    fieldIds.forEach(fieldId => {
      state.values.set(fieldId, null);
      state.visible.set(fieldId, true);
      state.enabled.set(fieldId, true);
      state.errors.set(fieldId, '');
    });

    return state;
  }
}
