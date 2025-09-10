// File: entry/src/main/ets/model/ComponentSystem.ets

/**
 * 组件类型枚举
 */
export enum ComponentType {
  // 基础组件
  TEXT = 'text',
  TIME = 'time', 
  PROGRESS = 'progress',
  STATUS = 'status',
  TAG = 'tag',
  
  // 业务组件
  STUDY = 'study',
  TRAVEL = 'travel',
  WORK = 'work',
  LIFE = 'life',
  
  // 自定义组件
  COUNTER = 'counter',
  RATING = 'rating',
  LINK = 'link',
  IMAGE = 'image'
}

/**
 * 组件分类
 */
export enum ComponentCategory {
  BASIC = 'basic',
  BUSINESS = 'business',
  CUSTOM = 'custom'
}

/**
 * 组件位置配置
 */
export interface ComponentPosition {
  row: number;
  column: number;
  span?: number; // 跨列数
}

/**
 * 组件样式配置
 */
export interface ComponentStyle {
  fontSize?: number;
  fontColor?: string;
  backgroundColor?: string;
  borderColor?: string;
  borderWidth?: number;
  borderRadius?: number;
  padding?: number;
  margin?: number;
  textAlign?: 'left' | 'center' | 'right';
  fontWeight?: 'normal' | 'bold' | 'medium';
  progressColor?: string;
  height?: number;
  tagColor?: string;
  textColor?: string;
}

/**
 * 组件配置属性
 */
export interface ComponentProperties {
  text?: string;
  maxLength?: number;
  showStartTime?: boolean;
  showEndTime?: boolean;
  showDuration?: boolean;
  timeFormat?: string;
  showPercentage?: boolean;
  showText?: boolean;
  progressText?: string;
  statusType?: string;
  showIcon?: boolean;
  tags?: string;
  maxTags?: number;
}

/**
 * 组件配置
 */
export interface ComponentConfig {
  id: string;
  componentId: string;
  properties: ComponentProperties;
  style: ComponentStyle;
  position: ComponentPosition;
  visible: boolean;
}

/**
 * 组件定义
 */
export interface ComponentDefinition {
  id: string;
  type: ComponentType;
  name: string;
  description: string;
  icon: string;
  category: ComponentCategory;
  configSchema: ComponentConfigSchema;
  defaultProperties: ComponentProperties;
  defaultStyle: ComponentStyle;
}

/**
 * 组件配置模式
 */
export interface ComponentConfigSchema {
  properties: PropertySchema[];
  style: StyleSchema[];
}

/**
 * 属性选项
 */
export interface PropertyOption {
  label: string;
  value: string | number | boolean;
}

/**
 * 属性模式
 */
export interface PropertySchema {
  key: string;
  name: string;
  type: 'string' | 'number' | 'boolean' | 'select' | 'color' | 'date';
  required: boolean;
  defaultValue?: string | number | boolean;
  options?: PropertyOption[];
  min?: number;
  max?: number;
  placeholder?: string;
}

/**
 * 样式模式
 */
export interface StyleSchema {
  key: string;
  name: string;
  type: 'number' | 'color' | 'select';
  defaultValue?: string | number;
  options?: PropertyOption[];
  min?: number;
  max?: number;
}

/**
 * 布局配置
 */
export interface LayoutConfig {
  columns: number;
  rows: number;
  gap: number;
  padding: number;
}

/**
 * 节点模板
 */
export interface NodeTemplate {
  id: string;
  name: string;
  description: string;
  category: string;
  icon: string;
  components: ComponentConfig[];
  layout: LayoutConfig;
  createdAt: number;
  updatedAt: number;
}

/**
 * 自定义节点
 */
export interface CustomNode {
  id: string;
  templateId: string;
  components: ComponentConfig[];
  layout: LayoutConfig;
  data: Record<string, string | number | boolean>;
  createdAt: number;
  updatedAt: number;
}

/**
 * 模板分类
 */
export interface TemplateCategory {
  id: string;
  name: string;
  icon: string;
  description: string;
  templates: NodeTemplate[];
}

/**
 * 组件渲染上下文
 */
export interface ComponentRenderContext {
  nodeId: string;
  nodeData: Record<string, string | number | boolean>;
  componentConfig: ComponentConfig;
  onDataChange: (componentId: string, data: ComponentProperties) => void;
  onStyleChange: (componentId: string, style: ComponentStyle) => void;
}

/**
 * 组件渲染结果
 */
export interface ComponentRenderResult {
  componentId: string;
  element: Object; // ArkTS组件
  data: ComponentProperties;
  style: ComponentStyle;
}
