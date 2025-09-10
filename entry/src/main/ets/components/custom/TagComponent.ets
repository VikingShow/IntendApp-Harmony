// File: entry/src/main/ets/components/custom/TagComponent.ets

import { ComponentRenderContext, ComponentRenderResult } from '../../model/ComponentSystem';

/**
 * 标签组件
 * 显示标签列表
 */
@Component
export struct TagComponent {
  @Prop tags: string = '重要,紧急';
  @Prop maxTags: number = 5;
  @Prop tagColor: string = '#007DFF';
  @Prop textColor: string = '#FFFFFF';
  @Prop fontSize: number = 12;
  @Prop borderRadiusValue: number = 4;
  @Prop paddingValue: number = 6;

  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.getTagList(), (tag: string, index: number) => {
        Text(tag.trim())
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .fontWeight(FontWeight.Medium)
          .padding({ 
            left: this.paddingValue, 
            right: this.paddingValue, 
            top: this.paddingValue / 2, 
            bottom: this.paddingValue / 2 
          })
          .backgroundColor(this.tagColor)
          .borderRadius(this.borderRadiusValue)
          .margin({ right: 6, bottom: 4 })
      })
    }
    .width('100%')
  }

  /**
   * 获取标签列表
   */
  private getTagList(): string[] {
    if (!this.tags) return [];
    
    const tagArray = this.tags.split(',').map(tag => tag.trim()).filter(tag => tag.length > 0);
    return tagArray.slice(0, this.maxTags);
  }
}

/**
 * 标签组件渲染器
 */
export function renderTagComponent(context: ComponentRenderContext): ComponentRenderResult {
  const componentConfig = context.componentConfig;
  const nodeData = context.nodeData;
  const properties = componentConfig.properties;
  const style = componentConfig.style;

  // 从节点数据中获取标签信息，如果没有则使用配置中的默认值
  const tags = (nodeData.tags as string) || properties.tags || '重要,紧急';

  return {
    componentId: componentConfig.id,
    element: TagComponent({
      tags: tags,
      maxTags: properties.maxTags || 5,
      tagColor: style.tagColor || '#007DFF',
      textColor: style.textColor || '#FFFFFF',
      fontSize: style.fontSize || 12,
      borderRadiusValue: style.borderRadius || 4,
      paddingValue: style.padding || 6
    }),
    data: properties,
    style: style
  };
}