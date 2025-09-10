// File: entry/src/main/ets/components/custom/TimeComponent.ets

import { ComponentRenderContext, ComponentRenderResult } from '../../model/ComponentSystem';

/**
 * 时间组件
 * 显示时间信息，包括开始时间、结束时间、持续时间
 */
@Component
export struct TimeComponent {
  @Prop showStartTime: boolean = true;
  @Prop showEndTime: boolean = true;
  @Prop showDuration: boolean = true;
  @Prop timeFormat: string = 'YYYY-MM-DD HH:mm';
  @Prop fontSize: number = 14;
  @Prop fontColor: string = '#666666';
  @Prop startTime: string = '';
  @Prop endTime: string = '';
  @Prop duration: string = '';

  build() {
    Column({ space: 4 }) {
      if (this.showStartTime && this.startTime) {
        Row({ space: 6 }) {
          Text('🕐')
            .fontSize(this.fontSize)
          Text(`开始: ${this.formatTime(this.startTime)}`)
            .fontSize(this.fontSize)
            .fontColor(this.fontColor)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      if (this.showEndTime && this.endTime) {
        Row({ space: 6 }) {
          Text('🕕')
            .fontSize(this.fontSize)
          Text(`结束: ${this.formatTime(this.endTime)}`)
            .fontSize(this.fontSize)
            .fontColor(this.fontColor)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      if (this.showDuration && this.duration) {
        Row({ space: 6 }) {
          Text('⏱️')
            .fontSize(this.fontSize)
          Text(`持续: ${this.duration}`)
            .fontSize(this.fontSize)
            .fontColor(this.fontColor)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 格式化时间
   */
  private formatTime(timeStr: string): string {
    if (!timeStr) return '';
    
    try {
      const date = new Date(timeStr);
      if (isNaN(date.getTime())) return timeStr;

      switch (this.timeFormat) {
        case 'YYYY-MM-DD HH:mm':
          return date.toLocaleString('zh-CN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
          });
        case 'MM-DD HH:mm':
          return date.toLocaleString('zh-CN', {
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
          });
        case 'HH:mm':
          return date.toLocaleString('zh-CN', {
            hour: '2-digit',
            minute: '2-digit'
          });
        default:
          return timeStr;
      }
    } catch (error) {
      return timeStr;
    }
  }
}

/**
 * 时间组件渲染器
 */
export function renderTimeComponent(context: ComponentRenderContext): ComponentRenderResult {
  const componentConfig = context.componentConfig;
  const nodeData = context.nodeData;
  const properties = componentConfig.properties;
  const style = componentConfig.style;

  // 从节点数据中获取时间信息
  const startTime = (nodeData.startTime as string) || '';
  const endTime = (nodeData.endTime as string) || '';
  const duration = (nodeData.duration as string) || '';

  return {
    componentId: componentConfig.id,
    element: TimeComponent({
      showStartTime: properties.showStartTime !== false,
      showEndTime: properties.showEndTime !== false,
      showDuration: properties.showDuration !== false,
      timeFormat: properties.timeFormat || 'YYYY-MM-DD HH:mm',
      fontSize: style.fontSize || 14,
      fontColor: style.fontColor || '#666666',
      startTime: startTime,
      endTime: endTime,
      duration: duration
    }),
    data: properties,
    style: style
  };
}
