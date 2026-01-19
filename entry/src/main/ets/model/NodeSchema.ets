// File: entry/src/main/ets/model/NodeSchema.ets
/**
 * 节点 Schema 定义模块
 *
 * 本文件定义节点类型、字段、样式等可配置结构，
 * 用于驱动节点工作台和画布渲染的“schema 驱动”能力。
 *
 * 设计原则：
 * - 只做类型/结构定义，不直接修改现有 Project/TaskNode 结构
 * - 通过可选字段与扩展接口兼容已有代码
 * - 便于序列化和导入导出
 */

/**
 * 节点字段类型
 */
export type FieldType = 'text' | 'number' | 'date' | 'boolean' | 'select' | 'checklist';
export type NodeFieldValue = string | number | boolean | Date | string[] | null;

/**
 * 节点字段 Schema
 * 用于描述一个可配置字段的结构
 */
export interface FieldSchema {
  /** 字段唯一 ID（在一个节点类型内唯一） */
  id: string;
  /** 显示名称/标签 */
  label: string;
  /** 字段类型 */
  type: FieldType;
  /** 是否必填 */
  required?: boolean;
  /** 默认值 */
  defaultValue?: NodeFieldValue;
  /** 可选项列表（用于 select / tag 等） */
  options?: string[];
}

/**
 * 节点样式 Schema
 * 控制节点在画布上的基础视觉样式
 * 支持普通任务和关键任务的差异化显示
 */
export interface NodeStyleSchema {
  /** 普通任务边框颜色 */
  fillColor: string;
  /** 关键任务边框颜色（高优先级/关键路径） */
  criticalColor?: string;
  /** 普通任务填充色（可选，默认白色/深色模式自适应） */
  normalFillColor?: string;
  /** 关键任务填充色（可选） */
  criticalFillColor?: string;
  /** 额外边框颜色（用于选中状态等） */
  borderColor?: string;
  /** 圆角半径 (0-32) */
  borderRadius?: number;
  /** 边框粗细 (1-5) */
  borderWidth?: number;
  /** 图标标识（可约定成名称或代码点） */
  icon?: string;
  /** 是否启用阴影效果 */
  shadowEnabled?: boolean;
  /** 角标/徽章颜色 */
  badgeColor?: string;
}

/**
 * 单个节点的样式覆盖
 * 所有字段均为可选，按需覆盖 NodeStyleSchema
 */
export interface NodeStyleOverride {
  fillColor?: string;
  borderColor?: string;
  borderRadius?: number;
  icon?: string;
  badgeColor?: string;
}

/**
 * 节点内部组件类型
 * 用于描述节点内部卡片上展示哪些信息
 */
export type NodeComponentType =
  | 'TITLE'              // 任务标题
  | 'DATE_RANGE'         // 日期范围
  | 'TIME_PROGRESS'      // ⏱️ 时间进度条
  | 'TASK_PROGRESS'      // 任务完成进度条
  | 'CHECKLIST_SUMMARY'  // 清单统计
  | 'PRIORITY_BADGE'     // 优先级标签
  | 'ASSIGNEE'           // 负责人
  | 'TAGS'               // 标签列表
  | 'STATUS_DOT'         // 状态指示器
  | 'CUSTOM_FIELD';      // 自定义字段

/**
 * 节点内部组件 Schema
 * 表示卡片上的一个展示/交互区域
 */
export interface NodeComponentSchema {
  /** 组件唯一 ID（在一个节点类型内唯一） */
  id: string;
  /** 组件类型 */
  type: NodeComponentType;
  /**
   * 关联字段 ID
   * 当 type 为 CUSTOM_FIELD / TAG_LIST 等依赖字段的组件时使用
   */
  fieldId?: string;
  /**
   * 组件配置属性
   * 用于扩展诸如最大行数、是否高亮、颜色强化等
   */
  props?: NodeComponentProps;
}

export interface NodeComponentProps {
  maxLines?: number;
  highlight?: boolean;
  color?: string;
  /** 显示样式（如 badge/text/icon/dot/label/tag） */
  style?: string;
}

/**
 * 节点端口定义（用于连接关系）
 */
export interface NodePort {
  /** 端口 ID */
  id: string;
  /** 端口类型 */
  type: 'input' | 'output';
  /** 端口标签 */
  label: string;
  /** 数据类型约束（可选） */
  dataType?: string;
}

/**
 * 节点元数据
 */
export interface NodeMeta {
  /** 作者/创建者 */
  author?: string;
  /** 创建时间戳 */
  createdAt?: number;
  /** 最后修改时间戳 */
  updatedAt?: number;
  /** 标签列表 */
  tags?: string[];
  /** 分类 */
  category?: string;
  /** 备注说明 */
  notes?: string;
}

/**
 * 规则引擎：事件类型
 */
export type RuleEventType = 'nodeLoad' | 'fieldChange' | 'action';

/**
 * 规则引擎：动作类型
 */
export type RuleActionType = 'setVisible' | 'setEnabled' | 'setValue' | 'validate';

/**
 * 规则引擎：条件表达式
 */
export interface RuleCondition {
  /** 字段 ID */
  fieldId: string;
  /** 操作符 */
  operator: 'equals' | 'notEquals' | 'contains' | 'greaterThan' | 'lessThan' | 'isEmpty' | 'isNotEmpty';
  /** 比较值 */
  value?: NodeFieldValue;
}

/**
 * 规则引擎：动作定义
 */
export interface RuleAction {
  /** 动作类型 */
  type: RuleActionType;
  /** 目标字段 ID */
  targetFieldId: string;
  /** 动作参数（根据 type 不同而不同） */
  params?: RuleActionParams;
}

/**
 * 规则动作参数
 */
export interface RuleActionParams {
  /** setVisible/setEnabled 的布尔值 */
  boolValue?: boolean;
  /** setValue 的新值 */
  newValue?: NodeFieldValue;
  /** validate 的错误消息 */
  errorMessage?: string;
}

/**
 * 规则定义
 */
export interface NodeRule {
  /** 规则 ID */
  id: string;
  /** 规则名称 */
  name: string;
  /** 触发事件 */
  event: RuleEventType;
  /** 监听的字段 ID（仅 fieldChange 事件需要） */
  watchFieldId?: string;
  /** 条件列表（AND 逻辑） */
  conditions: RuleCondition[];
  /** 动作列表 */
  actions: RuleAction[];
  /** 是否启用 */
  enabled?: boolean;
}

/**
 * 节点运行时状态
 */
export interface NodeRuntimeState {
  /** 字段值映射（fieldId -> value） */
  values: Map<string, NodeFieldValue>;
  /** 字段可见性映射（fieldId -> visible） */
  visible: Map<string, boolean>;
  /** 字段启用状态映射（fieldId -> enabled） */
  enabled: Map<string, boolean>;
  /** 字段错误信息映射（fieldId -> errorMessage） */
  errors: Map<string, string>;
}

/**
 * 节点类型 Schema
 * 用于描述一类节点的样式、字段和布局
 */
export interface NodeSchema {
  /** 节点类型 ID */
  id: string;
  /** 版本号（每次发布递增） */
  version: number;
  /** 节点类型名称 */
  name: string;
  /** 类型说明，可用于节点工作台中展示简介 */
  description?: string;
  /** 元数据 */
  meta?: NodeMeta;
  /** 端口定义（用于节点间连接） */
  ports?: NodePort[];
  /** 样式配置 */
  style: NodeStyleSchema;
  /** 字段配置 */
  fields: FieldSchema[];
  /** 内部组件/布局配置 */
  layout: NodeComponentSchema[];
  /** 规则配置 */
  rules?: NodeRule[];
  /** 是否为系统内置类型（用于区分用户自定义） */
  isSystem?: boolean;
  /** 是否为草稿状态（true=草稿，false/undefined=已发布） */
  isDraft?: boolean;
  /** 草稿的父版本 ID（从已发布版本复制时使用） */
  parentVersionId?: string;
  /** 是否为新建项目时的默认节点类型 */
  isDefault?: boolean;
}

/**
 * 扩展版本的 Task 节点接口
 * 在原有 TaskNode 基础上增加 schema 相关字段
 *
 * 说明：这里使用“扩展接口”而不是直接修改 TaskNode，
 * 以保持对现有代码的兼容；需要使用 schema 功能的地方
 * 可以显式声明为 TaskNodeWithSchema。
 */
export interface TaskNodeWithSchema {
  /** 节点类型 ID，指向 NodeSchema.id */
  typeId?: string;
  /** 自定义字段值映射，键为 FieldSchema.id */
  customFields?: Map<string, NodeFieldValue>;
  /** 单个节点的样式覆盖 */
  styleOverride?: NodeStyleOverride;
}

/**
 * 扩展版本的 Project 接口
 * 在原有 Project 基础上挂载本项目内可用的节点类型集合
 */
export interface ProjectWithSchema {
  /** 本项目可用的节点类型集合 */
  nodeSchemas?: NodeSchema[];
  /** 来源模板 ID（用于“自定义项目模板”回溯） */
  sourceTemplateId?: string;
}
