// File: entry/src/main/ets/model/CustomComponentSchema.ets

export type CustomRenderType = 'text' | 'tag' | 'progress' | 'status_dot' | 'custom';

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
}

export interface CustomComponentDefinition {
  id: string;
  name: string;
  renderType: CustomRenderType;
  description?: string;

  // for text
  textTemplate?: string;

  // for tag/status_dot
  enums?: CustomEnumItem[];

  // for progress
  min?: number;
  max?: number;
  unit?: string;

  style?: CustomComponentStyle;
}
