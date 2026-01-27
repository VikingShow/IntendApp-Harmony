// File: entry/src/main/ets/components/NodeComponentRenderer.ets
/**
 * 节点组件渲染器
 * 用于在节点工作台的可视化画布中渲染各种类型的组件
 */

import { NodeComponentType, NodeComponentSchema } from '../model/NodeSchema';
import { CustomComponentService } from '../services/CustomComponentService';
import { CustomComponentDefinition } from '../model/CustomComponentSchema';
import { unifiedDataChannel } from '@kit.ArkData';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { InlineCanvasIcon } from './InlineCanvasIcon';

/**
 * 可拖拽的组件项
 */
@Component
export struct DraggableComponentItem {
  @Prop type: NodeComponentType;
  @Prop label: string;
  @Prop description?: string;
  @Prop icon: Resource;
  @Prop dragPayload?: string;
  @Prop customComponentId?: string;
  @Prop isDragging: boolean = false;
  @State private allowDrag: boolean = false;
  @State private dragActive: boolean = false;
  private touchDownAt: number = 0;
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

        Row({ space: 6 }) {
          Text(this.label)
            .fontSize(ThemeConfig.fontSizeS)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary);

          if (this.description) {
            Text(this.description)
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textTertiary)
              .opacity(0.7)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center);

        Text('::')
          .fontSize(14)
          .fontColor(ColorResource.textTertiary);
      }
      .width('100%');

      // 实时预览区域 - 直接使用内容组件，与画布保持一致
      Column({ space: 0 }) {
        NodeComponentContent({
          component: { id: 'library-preview', type: this.type, customComponentId: this.customComponentId } as NodeComponentSchema
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
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.touchDownAt = Date.now();
        this.allowDrag = false;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.touchDownAt = 0;
        if (!this.dragActive) {
          this.allowDrag = false;
        }
      }
    })
    .onDragStart((event?: DragEvent) => {
      const now = Date.now();
      if (this.touchDownAt === 0 || now - this.touchDownAt < 350) {
        return;
      }
      this.dragActive = true;
      this.allowDrag = true;

      if (event) {
        const unifiedData = new unifiedDataChannel.UnifiedData();
        const plainText = new unifiedDataChannel.PlainText();
        plainText.textContent = this.dragPayload ? this.dragPayload : this.type;
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
      this.dragActive = false;
      this.allowDrag = false;
      this.touchDownAt = 0;
      if (this.handleDragEnd) {
        this.handleDragEnd();
      }
    })
    .draggable(true)
  }

  @Builder
  dragPreviewBuilder() {
    // 直接复用 NodeComponentPreview 来渲染一个真实的预览
    NodeComponentPreview({
      // 在 @Builder 中，不能声明变量，因此以内联方式创建对象
      component: { id: 'drag-preview', type: this.type, customComponentId: this.customComponentId } as NodeComponentSchema,
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
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
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
    } else if (this.component.type === 'CUSTOM_COMPONENT') {
      this.renderCustomComponent();
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
      InlineCanvasIcon({ kind: 'calendar', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
      Text('12/23 ~ 12/30 (8天)')
        .fontSize(11)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%');
  }

  @Builder
  renderTimeProgress() {
    Row({ space: 8 }) {
      InlineCanvasIcon({ kind: 'clock', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
      
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
      InlineCanvasIcon({ kind: 'select', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
      
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
      InlineCanvasIcon({ kind: 'checklist', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
      Text('3/5 完成')
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
      InlineCanvasIcon({ kind: 'user', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
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
        InlineCanvasIcon({ kind: 'tag', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })

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
      InlineCanvasIcon({ kind: 'pencil', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
      Text(`${this.component.fieldId || '字段'}: 未绑定`)
        .fontSize(11)
        .fontColor(ColorResource.textTertiary);
    }
    .width('100%');
  }

  private getPreviewValue(def: CustomComponentDefinition): string {
    if (def.renderType === 'progress') {
      return '45';
    }
    if (def.renderType === 'status_dot' || def.renderType === 'tag') {
      const first = def.enums && def.enums.length > 0 ? def.enums[0] : null;
      return first ? (first.label || first.value) : '进行中';
    }
    return '示例';
  }

  private applyTextTemplate(raw: string, value: string): string {
    if (!raw || raw.trim().length === 0) {
      return value;
    }
    return raw.replace('{value}', value);
  }

  @Builder
  renderCustomComponent() {
    if (!this.getCustomComponentDef()) {
      Text('自定义组件')
        .fontSize(11)
        .fontColor(ColorResource.textTertiary)
        .width('100%');
    } else {
      if (this.getCustomComponentRenderType() === 'tag') {
        Row({ space: 6 }) {
          Text(this.getCustomComponentPreviewValue())
            .fontSize(10)
            .fontColor(this.getCustomComponentTagTextColor())
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.getCustomComponentTagBackgroundColor())
            .borderRadius(4);
        }
        .width('100%');
      } else {
        if (this.getCustomComponentRenderType() === 'status_dot') {
          Row({ space: 6 }) {
            Circle()
              .width(8)
              .height(8)
              .fill(this.getCustomComponentStatusDotColor());
            Text(this.getCustomComponentPreviewValue())
              .fontSize(11)
              .fontColor(ColorResource.textSecondary);
          }
          .width('100%');
        } else {
          if (this.getCustomComponentRenderType() === 'progress') {
            Row({ space: 6 }) {
              Stack({ alignContent: Alignment.Start }) {
                Row()
                  .width('100%')
                  .height(6)
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .borderRadius(3);
                Row()
                  .width('45%')
                  .height(6)
                  .backgroundColor(this.getCustomComponentProgressColor())
                  .borderRadius(3);
              }
              .layoutWeight(1);
              Text('45%')
                .fontSize(10)
                .fontColor(this.getCustomComponentProgressColor());
            }
            .width('100%')
            .alignItems(VerticalAlign.Center);
          } else {
            Text(this.applyTextTemplate(this.getCustomComponentTemplate(), this.getCustomComponentPreviewValue()))
              .fontSize(11)
              .fontColor(this.getCustomComponentTextColor())
              .width('100%');
          }
        }
      }
    }
  }

  private getCustomComponentDef(): CustomComponentDefinition | null {
    return CustomComponentService.getInstance().getById(this.component.customComponentId || '');
  }

  private getCustomComponentRenderType(): string {
    const def = this.getCustomComponentDef();
    return def ? def.renderType : 'text';
  }

  private getCustomComponentPreviewValue(): string {
    const def = this.getCustomComponentDef();
    return def ? this.getPreviewValue(def) : '示例';
  }

  private getCustomComponentTemplate(): string {
    const def = this.getCustomComponentDef();
    return def && def.textTemplate ? def.textTemplate : '{value}';
  }

  private getCustomComponentTextColor(): string | Resource {
    const def = this.getCustomComponentDef();
    return def && def.style && def.style.textColor ? String(def.style.textColor) : ColorResource.textSecondary;
  }

  private getCustomComponentTagTextColor(): string | Resource {
    const def = this.getCustomComponentDef();
    const item = def && def.enums && def.enums.length > 0 ? def.enums[0] : null;
    if (item && item.color) return String(item.color);
    return ColorResource.primaryColor;
  }

  private getCustomComponentTagBackgroundColor(): string | Resource {
    const def = this.getCustomComponentDef();
    const item = def && def.enums && def.enums.length > 0 ? def.enums[0] : null;
    if (item && item.backgroundColor) return String(item.backgroundColor);
    return 'rgba(0, 122, 255, 0.1)';
  }

  private getCustomComponentStatusDotColor(): string | Resource {
    const def = this.getCustomComponentDef();
    const item = def && def.enums && def.enums.length > 0 ? def.enums[0] : null;
    if (item && item.color) return String(item.color);
    return '#34C759';
  }

  private getCustomComponentProgressColor(): string | Resource {
    const def = this.getCustomComponentDef();
    return def && def.style && def.style.backgroundColor ? String(def.style.backgroundColor) : '#409EFF';
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
          InlineCanvasIcon({ kind: 'calendar', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
          Text('12/23 ~ 12/30 (8天)')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary);
        }
        .width('100%');
      } else if (this.component.type === 'TIME_PROGRESS') {
        Row({ space: 8 }) {
          InlineCanvasIcon({ kind: 'clock', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
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
      } else if (this.component.type === 'TASK_PROGRESS') {
        Row({ space: 8 }) {
          InlineCanvasIcon({ kind: 'select', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
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
      } else if (this.component.type === 'CHECKLIST_SUMMARY') {
        Row({ space: 6 }) {
          InlineCanvasIcon({ kind: 'checklist', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
          Text('3/5 完成')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary);
        }
        .width('100%');
      } else if (this.component.type === 'PRIORITY_BADGE') {
        // DragDragDragDragDragXadgeDragDragDragDragextDragcon
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
          // DragDragDragDragX
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
          InlineCanvasIcon({ kind: 'user', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
          Text('张三')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary);
        }
        .width('100%');
      } else if (this.component.type === 'TAGS') {
        // DragDragDragDragDragXagDragDragDragDragext
        if (this.component.props?.style === 'text') {
          Text('前端, 紧急')
            .fontSize(11)
            .fontColor(ColorResource.textSecondary)
            .width('100%');
        } else {
          // DragDragDragDragX
          Row({ space: 6 }) {
            InlineCanvasIcon({ kind: 'tag', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })

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
        // DragDragDragDragDragXotDragDragDragDragabel
        if (this.component.props?.style === 'label') {
          Text('进行中')
            .fontSize(10)
            .fontColor(Color.White)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor('#67C23A')
            .borderRadius(4)
            .width('100%');
        } else {
          // DragDragDragDragX
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
          InlineCanvasIcon({ kind: 'pencil', iconSize: 12, iconColor: ThemeConfig.textSecondary, holeColor: ThemeConfig.backgroundCard })
      Text(`${this.component.fieldId || '字段'}: 未绑定`)
            .fontSize(11)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%');
      } else if (this.component.type === 'CUSTOM_COMPONENT') {
        this.renderCustomComponentContent();
      } else {
        Text('未知组件类型')
          .fontSize(11)
          .fontColor(ColorResource.textTertiary)
          .width('100%');
      }
    }
    .width('100%');
  }

  private getPreviewValue(def: CustomComponentDefinition): string {
    if (def.renderType === 'progress') {
      return '45';
    }
    if (def.renderType === 'status_dot' || def.renderType === 'tag') {
      const first = def.enums && def.enums.length > 0 ? def.enums[0] : null;
      return first ? (first.label || first.value) : '进行中';
    }
    return '示例';
  }

  private applyTextTemplate(raw: string, value: string): string {
    if (!raw || raw.trim().length === 0) {
      return value;
    }
    return raw.replace('{value}', value);
  }

  @Builder
  renderCustomComponentContent() {
    if (!this.getCustomComponentDef()) {
      Text('自定义组件')
        .fontSize(11)
        .fontColor(ColorResource.textTertiary)
        .width('100%');
    } else {
      if (this.getCustomComponentRenderType() === 'tag') {
        Row({ space: 6 }) {
          Text(this.getCustomComponentPreviewValue())
            .fontSize(10)
            .fontColor(this.getCustomComponentTagTextColor())
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.getCustomComponentTagBackgroundColor())
            .borderRadius(4);
        }
        .width('100%');
      } else {
        if (this.getCustomComponentRenderType() === 'status_dot') {
          Row({ space: 6 }) {
            Circle()
              .width(8)
              .height(8)
              .fill(this.getCustomComponentStatusDotColor());
            Text(this.getCustomComponentPreviewValue())
              .fontSize(11)
              .fontColor(ColorResource.textSecondary);
          }
          .width('100%');
        } else {
          if (this.getCustomComponentRenderType() === 'progress') {
            Row({ space: 6 }) {
              Stack({ alignContent: Alignment.Start }) {
                Row()
                  .width('100%')
                  .height(6)
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .borderRadius(3);
                Row()
                  .width('45%')
                  .height(6)
                  .backgroundColor(this.getCustomComponentProgressColor())
                  .borderRadius(3);
              }
              .layoutWeight(1);
              Text('45%')
                .fontSize(10)
                .fontColor(this.getCustomComponentProgressColor());
            }
            .width('100%')
            .alignItems(VerticalAlign.Center);
          } else {
            Text(this.applyTextTemplate(this.getCustomComponentTemplate(), this.getCustomComponentPreviewValue()))
              .fontSize(11)
              .fontColor(this.getCustomComponentTextColor())
              .width('100%');
          }
        }
      }
    }
  }

  private getCustomComponentDef(): CustomComponentDefinition | null {
    return CustomComponentService.getInstance().getById(this.component.customComponentId || '');
  }

  private getCustomComponentRenderType(): string {
    const def = this.getCustomComponentDef();
    return def ? def.renderType : 'text';
  }

  private getCustomComponentPreviewValue(): string {
    const def = this.getCustomComponentDef();
    return def ? this.getPreviewValue(def) : '示例';
  }

  private getCustomComponentTemplate(): string {
    const def = this.getCustomComponentDef();
    return def && def.textTemplate ? def.textTemplate : '{value}';
  }

  private getCustomComponentTextColor(): string | Resource {
    const def = this.getCustomComponentDef();
    return def && def.style && def.style.textColor ? String(def.style.textColor) : ColorResource.textSecondary;
  }

  private getCustomComponentTagTextColor(): string | Resource {
    const def = this.getCustomComponentDef();
    const item = def && def.enums && def.enums.length > 0 ? def.enums[0] : null;
    if (item && item.color) return String(item.color);
    return ColorResource.primaryColor;
  }

  private getCustomComponentTagBackgroundColor(): string | Resource {
    const def = this.getCustomComponentDef();
    const item = def && def.enums && def.enums.length > 0 ? def.enums[0] : null;
    if (item && item.backgroundColor) return String(item.backgroundColor);
    return 'rgba(0, 122, 255, 0.1)';
  }

  private getCustomComponentStatusDotColor(): string | Resource {
    const def = this.getCustomComponentDef();
    const item = def && def.enums && def.enums.length > 0 ? def.enums[0] : null;
    if (item && item.color) return String(item.color);
    return '#34C759';
  }

  private getCustomComponentProgressColor(): string | Resource {
    const def = this.getCustomComponentDef();
    return def && def.style && def.style.backgroundColor ? String(def.style.backgroundColor) : '#409EFF';
  }

}
