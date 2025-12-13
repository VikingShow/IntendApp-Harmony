// File: entry/src/main/ets/model/CustomComponentSchema.ets

export type CustomRenderType = 'text' | 'tag' | 'progress' | 'status_dot' | 'custom';

export type CustomValueType = 'text' | 'number' | 'boolean' | 'enum';

export type CustomLayoutType = 'inline' | 'left_center_right' | 'stack';

export type CustomEventType = 'click' | 'longPress';

export type CustomActionType = 'none' | 'copy' | 'toast' | 'openUrl';

export interface CustomComponentMeta {
  author?: string;
  createdAt?: number;
  updatedAt?: number;
  tags?: string[];
}

export interface CustomTemplateSegment {
  type: 'text' | 'var';
  value: string;
  format?: string;
  defaultValue?: string;
}

export interface CustomTemplate {
  /** 原始模板字符串（便于编辑） */
  raw: string;
  /** 解析后的 token（便于渲染） */
  segments?: CustomTemplateSegment[];
}

export interface CustomStylePatch {
  textColor?: string;
  fontSize?: number;
  fontWeight?: number;
  borderRadius?: number;
  paddingX?: number;
  paddingY?: number;
  backgroundColor?: string;
  borderColor?: string;
  borderWidth?: number;
}

export interface CustomStyleRuleCondition {
  operator: 'equals' | 'notEquals' | 'contains' | 'greaterThan' | 'lessThan' | 'isEmpty' | 'isNotEmpty';
  value?: string | number | boolean;
}

export interface CustomStyleRule {
  id: string;
  name: string;
  enabled?: boolean;
  when: CustomStyleRuleCondition;
  then: CustomStylePatch;
}

export interface CustomEventActionParams {
  text?: string;
  url?: string;
}

export interface CustomEventAction {
  type: CustomActionType;
  params?: CustomEventActionParams;
}

export interface CustomEventBinding {
  event: CustomEventType;
  action: CustomEventAction;
}

export interface CustomComponentLayout {
  type: CustomLayoutType;
  leftTemplate?: CustomTemplate;
  centerTemplate?: CustomTemplate;
  rightTemplate?: CustomTemplate;
  /** inline/stack 布局时使用 */
  template?: CustomTemplate;
}

export interface CustomEnumItem {
  value: string;
  label: string;
  color?: string;
  backgroundColor?: string;
  icon?: string;
}

export interface CustomComponentStyle {
  textColor?: string;
  fontSize?: number;
  fontWeight?: number;
  borderRadius?: number;
  paddingX?: number;
  paddingY?: number;
  backgroundColor?: string;
  borderColor?: string;
  borderWidth?: number;
}

export interface CustomComponentDefinition {
  id: string;
  name: string;
  renderType: CustomRenderType;
  description?: string;

  version?: number;
  meta?: CustomComponentMeta;

  /** 组件值类型（用于全局渲染时的格式化/规则判断） */
  valueType?: CustomValueType;

  // for text
  textTemplate?: string;

  /** 高阶模板（renderType=custom 或希望多分区布局时使用） */
  layout?: CustomComponentLayout;

  // for tag/status_dot
  enums?: CustomEnumItem[];

  // for progress
  min?: number;
  max?: number;
  unit?: string;

  style?: CustomComponentStyle;

  /** 基于 value/枚举/区间 的样式规则 */
  styleRules?: CustomStyleRule[];

  /** 事件 -> 动作映射 */
  events?: CustomEventBinding[];
}
