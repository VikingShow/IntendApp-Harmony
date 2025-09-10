// File: entry/src/main/ets/components/custom/ProgressComponent.ets

import { ComponentRenderContext, ComponentRenderResult } from '../../model/ComponentSystem';

/**
 * 进度组件
 * 显示进度条和进度信息
 */
@Component
export struct ProgressComponent {
  @Prop showPercentage: boolean = true;
  @Prop showText: boolean = true;
  @Prop progressText: string = '进度';
  @Prop progress: number = 0;
  @Prop progressColor: string = '#007DFF';
  @Prop bgColor: string = '#F0F0F0';
  @Prop heightValue: number = 8;
  @Prop fontSize: number = 14;
  @Prop fontColor: string = '#333333';

  build() {
    Column({ space: 6 }) {
      if (this.showText) {
        Row() {
          Text(this.progressText)
            .fontSize(this.fontSize)
            .fontColor(this.fontColor)
            .layoutWeight(1)
          
          if (this.showPercentage) {
            Text(`${Math.round(this.progress)}%`)
              .fontSize(this.fontSize)
              .fontColor(this.fontColor)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
      }

      // 进度条
      Row() {
        // 进度条背景
        Column()
          .width('100%')
          .height(this.heightValue)
          .backgroundColor(this.bgColor)
          .borderRadius(this.heightValue / 2)
        
        // 进度条填充
        Column()
          .width(`${this.progress}%`)
          .height(this.heightValue)
          .backgroundColor(this.progressColor)
          .borderRadius(this.heightValue / 2)
          .position({ x: 0, y: 0 })
      }
      .width('100%')
      .height(this.heightValue)
      .borderRadius(this.heightValue / 2)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

/**
 * 进度组件渲染器
 */
export function renderProgressComponent(context: ComponentRenderContext): ComponentRenderResult {
  const componentConfig = context.componentConfig;
  const nodeData = context.nodeData;
  const properties = componentConfig.properties;
  const style = componentConfig.style;

  // 从节点数据中获取进度信息
  const progress = (nodeData.progress as number) || 0;

  return {
    componentId: componentConfig.id,
    element: ProgressComponent({
      showPercentage: properties.showPercentage !== false,
      showText: properties.showText !== false,
      progressText: properties.progressText || '进度',
      progress: Math.max(0, Math.min(100, progress)),
      progressColor: style.progressColor || '#007DFF',
      bgColor: style.backgroundColor || '#F0F0F0',
      heightValue: style.height || 8,
      fontSize: style.fontSize || 14,
      fontColor: style.fontColor || '#333333'
    }),
    data: properties,
    style: style
  };
}