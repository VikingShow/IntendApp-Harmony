// File: entry/src/main/ets/components/NodeComponentRenderer.ets
/**
 * 节点组件渲染器
 * 用于在节点工作台的可视化画布中渲染各种类型的组件
 */

import { NodeComponentType, NodeComponentSchema } from '../model/NodeSchema';
import { unifiedDataChannel } from '@kit.ArkData';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

/**
 * 可拖拽的组件项
 */
@Component
export struct DraggableComponentItem {
  @Prop type: NodeComponentType;
  @Prop label: string;
  @Prop icon: Resource;
  @Prop isDragging: boolean = false;
  handleDragStart?: (type: NodeComponentType) => void;
  handleDragEnd?: () => void;

  build() {
    Column({ space: 6 }) {
      // 头部：图标、名称和拖拽手柄
      Row({ space: 8 }) {
        Image(this.icon)
          .width(16)
          .height(16)
          .fillColor(ColorResource.textSecondary)

        Text(this.label)
          .fontSize(ThemeConfig.fontSizeS)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .layoutWeight(1);

        Text('⋮⋮')
          .fontSize(14)
          .fontColor(ColorResource.textTertiary);
      }
      .width('100%');

      // 实时预览区域 - 直接使用内容组件，与画布保持一致
      Column({ space: 0 }) {
        NodeComponentContent({
          component: { id: 'library-preview', type: this.type } as NodeComponentSchema
        })
      }
      .width('100%')
      .padding(8)
      .backgroundColor(ColorResource.backgroundSecondary)
      .borderRadius(6);
    }
    .width('100%')
    .padding(10)
    .backgroundColor(this.isDragging ? ColorResource.backgroundSecondary : ColorResource.surface)
    .borderRadius(8)
    .shadow(this.isDragging ? { radius: 8, color: 'rgba(0,0,0,0.15)', offsetY: 4 } : { radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
    .onDragStart((event?: DragEvent) => {
      if (event) {
        const unifiedData = new unifiedDataChannel.UnifiedData();
        const plainText = new unifiedDataChannel.PlainText();
        plainText.textContent = this.type;
        unifiedData.addRecord(plainText);
        event.setData(unifiedData);
      }

      if (this.handleDragStart) {
        this.handleDragStart(this.type);
      }

      return {
        builder: this.dragPreviewBuilder()
      };
    })
    .onDragEnd(() => {
      if (this.handleDragEnd) {
        this.handleDragEnd();
      }
    })
    .draggable(true)
    .priorityGesture(PanGesture({}))
  }

  @Builder
  dragPreviewBuilder() {
    // 直接复用 NodeComponentPreview 来渲染一个真实的预览
    NodeComponentPreview({
      // 在 @Builder 中，不能声明变量，因此以内联方式创建对象
      component: { id: 'drag-preview', type: this.type } as NodeComponentSchema,
      isSelected: false, // 预览项不是选中状态
      nodeColor: '#007AFF' // 为预览项提供一个中性的颜色
    })
      .width(220) // 预览宽度与画布中的卡片宽度保持一致
      .opacity(0.85) // 轻微透明，以区分于实际组件
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetY: 6 }); // 添加更明显的阴影
  }
}

/**
 * 实时预览的组件渲染
 */
@Component
export struct NodeComponentPreview {
  @Prop component: NodeComponentSchema;
  @Prop isSelected: boolean = false;
  @Prop nodeColor: string = '#007AFF';
  handleClick?: () => void;
  handleDelete?: () => void;
  handleDragStart?: (event?: DragEvent) => void;
  handleDragEnd?: () => void;

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 0 }) {
        this.renderComponentContent();
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 8, bottom: 8 })
      .backgroundColor(this.isSelected ? 'rgba(0, 122, 255, 0.08)' : Color.Transparent)
      .borderRadius(4)
      .border({
        width: this.isSelected ? 1 : 0,
        color: this.isSelected ? ColorResource.primaryColor : Color.Transparent
      })
      .onClick(() => {
        if (this.handleClick) {
          this.handleClick();
        }
      })
      .onDragStart((event?: DragEvent) => {
        if (this.handleDragStart) {
          this.handleDragStart(event);
        }
      })
      .onDragEnd(() => {
        if (this.handleDragEnd) {
          this.handleDragEnd();
        }
      })
      .draggable(true)
      .priorityGesture(PanGesture({}));

      if (this.isSelected && this.handleDelete) {
        Button() {
          Text('×')
            .fontSize(14)
            .fontColor(Color.White);
        }
        .width(32)
        .height(32)
        .padding(0)
        .backgroundColor('#FF3B30')
        .borderRadius(16)
        .margin({ top: -8, right: -8 })
        .onClick(() => {
          if (this.handleDelete) {
            this.handleDelete();
          }
        });
      }
    }
    .width('100%');
  }

  @Builder
  renderComponentContent() {
    if (this.component.type === 'TITLE') {
      this.renderTitle();
    } else if (this.component.type === 'DATE_RANGE') {
      this.renderDateRange();
    } else if (this.component.type === 'TIME_PROGRESS') {
      this.renderTimeProgress();
    } else if (this.component.type === 'TASK_PROGRESS') {
      this.renderTaskProgress();
    } else if (this.component.type === 'CHECKLIST_SUMMARY') {
      this.renderChecklistSummary();
    } else if (this.component.type === 'PRIORITY_BADGE') {
      this.renderPriorityBadge();
    } else if (this.component.type === 'ASSIGNEE') {
      this.renderAssignee();
    } else if (this.component.type === 'TAGS') {
      this.renderTags();
    } else if (this.component.type === 'STATUS_DOT') {
      this.renderStatusDot();
    } else if (this.component.type === 'CUSTOM_FIELD') {
      this.renderCustomField();
    } else {
      this.renderPlaceholder();
    }
  }

  @Builder
  renderTitle() {
    Text('任务标题示例')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor(ColorResource.textPrimary)
      .width('100%');
  }

  @Builder
  renderDateRange() {
    Row({ space: 4 }) {
      Image($r('app.media.ic_calendar'))
        .width(12)
        .height(12)
        .fillColor(ColorResource.textSecondary)
      Text('12/23 ~ 12/30 (8天)')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%');
  }

  @Builder
  renderTimeProgress() {
    Row({ space: 8 }) {
      Text('时间')
        .fontSize(10)
        .fontColor(ColorResource.textSecondary);
      
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(3);
        
        Row()
          .width('35%')
          .height(6)
          .backgroundColor('#409EFF')
          .borderRadius(3);
      }
      .layoutWeight(1);

      Text('35%')
        .fontSize(10)
        .fontColor('#409EFF')
        .fontWeight(FontWeight.Medium);
    }
    .width('100%')
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  renderTaskProgress() {
    Row({ space: 8 }) {
      Text('完成')
        .fontSize(10)
        .fontColor(ColorResource.textSecondary);
      
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(3);
        
        Row()
          .width('60%')
          .height(6)
          .backgroundColor('#67C23A')
          .borderRadius(3);
      }
      .layoutWeight(1);

      Text('60%')
        .fontSize(10)
        .fontColor('#67C23A')
        .fontWeight(FontWeight.Medium);
    }
    .width('100%')
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  renderChecklistSummary() {
    Row({ space: 6 }) {
      Image($r('app.media.ic_checklist'))
        .width(12)
        .height(12)
        .fillColor(ColorResource.textSecondary)
      Text('3/5 项已完成')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%');
  }

  @Builder
  renderPriorityBadge() {
    if (this.component.props?.style === 'text') {
      // 文字样式
      Text('高优先级')
        .fontSize(11)
        .fontColor('#FF3B30')
        .fontWeight(FontWeight.Medium)
        .width('100%');
    } else if (this.component.props?.style === 'icon') {
      // 图标样式
      Image($r('app.media.ic_priority'))
        .width(14)
        .height(14)
        .fillColor('#FF3B30')
    } else {
      // 默认徽章样式
      Row({ space: 6 }) {
        Text('高')
          .fontSize(10)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor('#FF3B30')
          .borderRadius(4);
        Text('高优先级')
          .fontSize(11)
          .fontColor('#FF3B30')
          .fontWeight(FontWeight.Medium);
      }
      .width('100%');
    }
  }

  @Builder
  renderAssignee() {
    Row({ space: 6 }) {
      Image($r('app.media.ic_user'))
        .width(12)
        .height(12)
        .fillColor(ColorResource.textSecondary)
      Text('张三')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%');
  }

  @Builder
  renderTags() {
    if (this.component.props?.style === 'text') {
      // 文字样式
      Text('前端, 紧急')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary)
        .width('100%');
    } else {
      // 默认标签样式
      Row({ space: 6 }) {
        Image($r('app.media.ic_tag'))
          .width(12)
          .height(12)
          .fillColor(ColorResource.textSecondary)

        Row({ space: 4 }) {
          Text('前端')
            .fontSize(10)
            .fontColor(ColorResource.primaryColor)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('rgba(0, 122, 255, 0.1)')
            .borderRadius(4);

          Text('紧急')
            .fontSize(10)
            .fontColor('#FF3B30')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('rgba(255, 59, 48, 0.1)')
            .borderRadius(4);
        }
      }
      .width('100%');
    }
  }

  @Builder
  renderStatusDot() {
    if (this.component.props?.style === 'label') {
      // 标签样式
      Text('进行中')
        .fontSize(10)
        .fontColor(Color.White)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor('#67C23A')
        .borderRadius(4)
        .width('100%');
    } else {
      // 默认圆点样式
      Row({ space: 6 }) {
        Circle()
          .width(8)
          .height(8)
          .fill('#67C23A');

        Text('进行中')
          .fontSize(11)
          .fontColor(ColorResource.textSecondary);
      }
      .width('100%');
    }
  }

  @Builder
  renderCustomField() {
    Row({ space: 6 }) {
      Image($r('app.media.ic_edit'))
        .width(12)
        .height(12)
        .fillColor(ColorResource.textSecondary)
      Text(this.component.fieldId || '未绑定字段')
        .fontSize(11)
        .fontColor(ColorResource.textTertiary);
    }
    .width('100%');
  }

  @Builder
  renderPlaceholder() {
    Text('未知组件类型')
      .fontSize(11)
      .fontColor(ColorResource.textTertiary)
      .width('100%');
  }
}

@Component
export struct NodeComponentContent {
  @Prop component: NodeComponentSchema;

  build() {
    Column({ space: 0 }) {
      if (this.component.type === 'TITLE') {
        Text('任务标题示例')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorResource.textPrimary)
          .width('100%');
      } else if (this.component.type === 'DATE_RANGE') {
        Row({ space: 4 }) {
          Image($r('app.media.ic_calendar'))
            .width(12)
            .height(12)
            .fillColor(ColorResource.textSecondary)
          Text('12/23 ~ 12/30 (8天)')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary);
        }
        .width('100%');
      } else if (this.component.type === 'TIME_PROGRESS') {
        Column({ space: 3 }) {
          Text('时间: 35%')
            .fontSize(10)
            .fontColor(ColorResource.textSecondary)
            .width('100%');
          
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(6)
              .backgroundColor(ColorResource.backgroundSecondary)
              .borderRadius(3);
            
            Row()
              .width('35%')
              .height(6)
              .backgroundColor('#409EFF')
              .borderRadius(3);
          }
          .width('100%');
        }
        .width('100%');
      } else if (this.component.type === 'TASK_PROGRESS') {
        Column({ space: 3 }) {
          Text('完成: 60%')
            .fontSize(10)
            .fontColor(ColorResource.textSecondary)
            .width('100%');
          
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(6)
              .backgroundColor(ColorResource.backgroundSecondary)
              .borderRadius(3);
            
            Row()
              .width('60%')
              .height(6)
              .backgroundColor('#67C23A')
              .borderRadius(3);
          }
          .width('100%');
        }
        .width('100%');
      } else if (this.component.type === 'CHECKLIST_SUMMARY') {
        Row({ space: 6 }) {
          Image($r('app.media.ic_checklist'))
            .width(12)
            .height(12)
            .fillColor(ColorResource.textSecondary)
          Text('3/5 项已完成')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary);
        }
        .width('100%');
      } else if (this.component.type === 'PRIORITY_BADGE') {
        // 支持不同样式：badge（默认）、text、icon
        if (this.component.props?.style === 'text') {
          Text('高优先级')
            .fontSize(11)
            .fontColor('#FF3B30')
            .fontWeight(FontWeight.Medium)
            .width('100%');
        } else if (this.component.props?.style === 'icon') {
          Image($r('app.media.ic_priority'))
            .width(14)
            .height(14)
            .fillColor('#FF3B30')
        } else {
          // 默认徽章样式
          Row({ space: 6 }) {
            Text('高')
              .fontSize(10)
              .fontColor(Color.White)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('#FF3B30')
              .borderRadius(4);
            Text('高优先级')
              .fontSize(11)
              .fontColor('#FF3B30')
              .fontWeight(FontWeight.Medium);
          }
          .width('100%');
        }
      } else if (this.component.type === 'ASSIGNEE') {
        Row({ space: 6 }) {
          Image($r('app.media.ic_user'))
            .width(12)
            .height(12)
            .fillColor(ColorResource.textSecondary)
          Text('张三')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary);
        }
        .width('100%');
      } else if (this.component.type === 'TAGS') {
        // 支持不同样式：tag（默认）、text
        if (this.component.props?.style === 'text') {
          Text('前端, 紧急')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary)
            .width('100%');
        } else {
          // 默认标签样式
          Row({ space: 6 }) {
            Image($r('app.media.ic_tag'))
              .width(12)
              .height(12)
              .fillColor(ColorResource.textSecondary)

            Row({ space: 4 }) {
              Text('前端')
                .fontSize(10)
                .fontColor(ColorResource.primaryColor)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('rgba(0, 122, 255, 0.1)')
                .borderRadius(4);

              Text('紧急')
                .fontSize(10)
                .fontColor('#FF3B30')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('rgba(255, 59, 48, 0.1)')
                .borderRadius(4);
            }
          }
          .width('100%');
        }
      } else if (this.component.type === 'STATUS_DOT') {
        // 支持不同样式：dot（默认）、label
        if (this.component.props?.style === 'label') {
          Text('进行中')
            .fontSize(10)
            .fontColor(Color.White)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor('#67C23A')
            .borderRadius(4)
            .width('100%');
        } else {
          // 默认圆点样式
          Row({ space: 6 }) {
            Circle()
              .width(8)
              .height(8)
              .fill('#67C23A');

            Text('进行中')
              .fontSize(11)
              .fontColor(ColorResource.textSecondary);
          }
          .width('100%');
        }
      } else if (this.component.type === 'CUSTOM_FIELD') {
        Row({ space: 6 }) {
          Image($r('app.media.ic_edit'))
            .width(12)
            .height(12)
            .fillColor(ColorResource.textSecondary)
          Text(this.component.fieldId || '未绑定字段')
            .fontSize(11)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%');
      } else {
        Text('未知组件类型')
          .fontSize(11)
          .fontColor(ColorResource.textTertiary)
          .width('100%');
      }
    }
    .width('100%');
  }
}
