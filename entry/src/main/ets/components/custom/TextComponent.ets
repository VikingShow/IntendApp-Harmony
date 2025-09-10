// File: entry/src/main/ets/components/custom/TextComponent.ets

import { ComponentRenderContext, ComponentRenderResult } from '../../model/ComponentSystem';

/**
 * 文本组件
 * 显示文本内容，支持样式自定义
 */
@Component
export struct TextComponent {
  @Prop text: string = '文本内容';
  @Prop maxLength: number = 100;
  @Prop fontSize: number = 16;
  @Prop fontColor: string = '#333333';
  @Prop fontWeight: string = 'normal';
  @Prop textAlign: string = 'left';
  @Prop bgColor: string = 'transparent';
  @Prop paddingValue: number = 8;
  @Prop marginValue: number = 4;
  @Prop borderRadiusValue: number = 4;

  build() {
    Text(this.getDisplayText())
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .fontWeight(this.getFontWeight())
      .textAlign(this.getTextAlign())
      .maxLines(3)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
      .padding(this.paddingValue)
      .margin(this.marginValue)
      .backgroundColor(this.bgColor)
      .borderRadius(this.borderRadiusValue)
  }

  /**
   * 获取显示文本
   */
  private getDisplayText(): string {
    if (this.text.length > this.maxLength) {
      return this.text.substring(0, this.maxLength) + '...';
    }
    return this.text;
  }

  /**
   * 获取字体粗细
   */
  private getFontWeight(): FontWeight {
    switch (this.fontWeight) {
      case 'bold':
        return FontWeight.Bold;
      case 'medium':
        return FontWeight.Medium;
      default:
        return FontWeight.Normal;
    }
  }

  /**
   * 获取文本对齐方式
   */
  private getTextAlign(): TextAlign {
    switch (this.textAlign) {
      case 'center':
        return TextAlign.Center;
      case 'right':
        return TextAlign.End;
      default:
        return TextAlign.Start;
    }
  }
}

/**
 * 文本组件渲染器
 */
export function renderTextComponent(context: ComponentRenderContext): ComponentRenderResult {
  const componentConfig = context.componentConfig;
  const nodeData = context.nodeData;
  const properties = componentConfig.properties;
  const style = componentConfig.style;

  return {
    componentId: componentConfig.id,
    element: TextComponent({
      text: properties.text || '文本内容',
      maxLength: properties.maxLength || 100,
      fontSize: style.fontSize || 16,
      fontColor: style.fontColor || '#333333',
      fontWeight: style.fontWeight || 'normal',
      textAlign: style.textAlign || 'left',
      bgColor: style.backgroundColor || 'transparent',
      paddingValue: style.padding || 8,
      marginValue: style.margin || 4,
      borderRadiusValue: style.borderRadius || 4
    }),
    data: properties,
    style: style
  };
}