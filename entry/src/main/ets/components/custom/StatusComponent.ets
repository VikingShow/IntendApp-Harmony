// File: entry/src/main/ets/components/custom/StatusComponent.ets

import { ComponentRenderContext, ComponentRenderResult } from '../../model/ComponentSystem';

/**
 * 状态组件
 * 显示任务状态信息
 */
@Component
export struct StatusComponent {
  @Prop statusType: string = 'progress';
  @Prop showIcon: boolean = true;
  @Prop showText: boolean = true;
  @Prop fontSize: number = 14;
  @Prop fontColor: string = '#333333';

  build() {
    Row({ space: 6 }) {
      if (this.showIcon) {
        Text(this.getStatusIcon())
          .fontSize(this.fontSize)
      }
      
      if (this.showText) {
        Text(this.getStatusText())
          .fontSize(this.fontSize)
          .fontColor(this.getStatusColor())
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(6)
    .backgroundColor(this.getStatusBackgroundColor())
    .borderRadius(6)
    .border({ 
      width: 1, 
      color: this.getStatusBorderColor(),
      radius: 6 
    })
  }

  /**
   * 获取状态图标
   */
  private getStatusIcon(): string {
    switch (this.statusType) {
      case 'progress':
        return '🔄';
      case 'completed':
        return '✅';
      case 'paused':
        return '⏸️';
      case 'cancelled':
        return '❌';
      default:
        return '🔘';
    }
  }

  /**
   * 获取状态文字
   */
  private getStatusText(): string {
    switch (this.statusType) {
      case 'progress':
        return '进行中';
      case 'completed':
        return '已完成';
      case 'paused':
        return '已暂停';
      case 'cancelled':
        return '已取消';
      default:
        return '未知状态';
    }
  }

  /**
   * 获取状态颜色
   */
  private getStatusColor(): string {
    switch (this.statusType) {
      case 'progress':
        return '#007DFF';
      case 'completed':
        return '#10B981';
      case 'paused':
        return '#F59E0B';
      case 'cancelled':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  /**
   * 获取状态背景颜色
   */
  private getStatusBackgroundColor(): string {
    switch (this.statusType) {
      case 'progress':
        return '#EFF6FF';
      case 'completed':
        return '#F0FDF4';
      case 'paused':
        return '#FFFBEB';
      case 'cancelled':
        return '#FEF2F2';
      default:
        return '#F9FAFB';
    }
  }

  /**
   * 获取状态边框颜色
   */
  private getStatusBorderColor(): string {
    switch (this.statusType) {
      case 'progress':
        return '#DBEAFE';
      case 'completed':
        return '#D1FAE5';
      case 'paused':
        return '#FED7AA';
      case 'cancelled':
        return '#FECACA';
      default:
        return '#E5E7EB';
    }
  }
}

/**
 * 状态组件渲染器
 */
export function renderStatusComponent(context: ComponentRenderContext): ComponentRenderResult {
  const componentConfig = context.componentConfig;
  const nodeData = context.nodeData;
  const properties = componentConfig.properties;
  const style = componentConfig.style;

  // 从节点数据中获取状态信息
  const statusType = (nodeData.status as string) || properties.statusType || 'progress';

  return {
    componentId: componentConfig.id,
    element: StatusComponent({
      statusType: statusType,
      showIcon: properties.showIcon !== false,
      showText: properties.showText !== false,
      fontSize: style.fontSize || 14,
      fontColor: style.fontColor || '#333333'
    }),
    data: properties,
    style: style
  };
}
