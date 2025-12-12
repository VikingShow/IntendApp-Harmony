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
  @Prop icon: string;
  @Prop isDragging: boolean = false;
  handleDragStart?: (type: NodeComponentType) => void;
  handleDragEnd?: () => void;

  build() {
    Row({ space: 10 }) {
      Text(this.icon)
        .fontSize(20)
        .fontColor(ColorResource.primaryColor);
      
      Column({ space: 2 }) {
        Text(this.label)
          .fontSize(ThemeConfig.fontSizeS)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary);
        
        Text(this.type)
          .fontSize(ThemeConfig.fontSizeXS - 1)
          .fontColor(ColorResource.textTertiary)
          .opacity(0.7);
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);
      
      Text('⋮⋮')
        .fontSize(16)
        .fontColor(ColorResource.textTertiary);
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
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

      // 返回一个 DragItemInfo 对象来自定义拖拽预览图，如果不需要则可以不返回
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
    Row({ space: 10 }) {
      Text(this.icon)
        .fontSize(20)
        .fontColor(ColorResource.primaryColor);
      
      Column({ space: 2 }) {
        Text(this.label)
          .fontSize(ThemeConfig.fontSizeS)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary);
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(ColorResource.surface)
    .borderRadius(8)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.15)', offsetY: 4 });
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
  handleDragStart?: () => void;
  handleDragEnd?: () => void;

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 0 }) {
        this.renderComponentContent();
      }
      .width('100%')
      .padding(10)
      .backgroundColor(ColorResource.surface)
      .borderRadius(6)
      .border({
        width: this.isSelected ? 2 : 1,
        color: this.isSelected ? ColorResource.primaryColor : ColorResource.surfaceEmphasized
      })
      .onClick(() => {
        if (this.handleClick) {
          this.handleClick();
        }
      })
      .onDragStart((event?: DragEvent) => {
        if (this.handleDragStart) {
          this.handleDragStart();
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
            .fontSize(18)
            .fontColor(Color.White);
        }
        .width(24)
        .height(24)
        .padding(0)
        .backgroundColor('#FF3B30')
        .borderRadius(12)
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
      Text('📅')
        .fontSize(12);
      Text('12/23 ~ 12/30 (8天)')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%');
  }

  @Builder
  renderTimeProgress() {
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
  }

  @Builder
  renderTaskProgress() {
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
  }

  @Builder
  renderChecklistSummary() {
    Row({ space: 6 }) {
      Text('☑️')
        .fontSize(12);
      Text('3/5 项已完成')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%');
  }

  @Builder
  renderPriorityBadge() {
    Row({ space: 6 }) {
      Text('🔥')
        .fontSize(12);
      Text('高优先级')
        .fontSize(11)
        .fontColor('#FF3B30')
        .fontWeight(FontWeight.Medium);
    }
    .width('100%');
  }

  @Builder
  renderAssignee() {
    Row({ space: 6 }) {
      Text('👤')
        .fontSize(12);
      Text('张三')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%');
  }

  @Builder
  renderTags() {
    Row({ space: 6 }) {
      Text('🏷️')
        .fontSize(12);
      
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

  @Builder
  renderStatusDot() {
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

  @Builder
  renderCustomField() {
    Row({ space: 6 }) {
      Text('✏️')
        .fontSize(12);
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
