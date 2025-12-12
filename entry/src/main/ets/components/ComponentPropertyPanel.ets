// File: entry/src/main/ets/components/ComponentPropertyPanel.ets
/**
 * 组件属性编辑面板
 * 根据选中的组件类型显示相应的属性编辑器
 */

import { NodeComponentType, NodeComponentSchema, FieldSchema } from '../model/NodeSchema';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

@Component
export struct ComponentPropertyPanel {
  @Prop selectedComponent: NodeComponentSchema | null;
  @Prop availableFields: FieldSchema[] = [];
  
  onPropertyChange?: (component: NodeComponentSchema) => void;

  private getComponentTypeLabel(type: NodeComponentType): string {
    const typeMap: Record<string, string> = {
      'TITLE': '标题',
      'DATE_RANGE': '日期范围',
      'TIME_PROGRESS': '时间进度',
      'TASK_PROGRESS': '任务进度',
      'CHECKLIST_SUMMARY': '清单统计',
      'PRIORITY_BADGE': '优先级',
      'ASSIGNEE': '负责人',
      'TAGS': '标签',
      'STATUS_DOT': '状态点',
      'CUSTOM_FIELD': '自定义字段'
    };
    return typeMap[type] || type;
  }

  private getComponentIcon(type: NodeComponentType): string {
    const iconMap: Record<string, string> = {
      'TITLE': '📌',
      'DATE_RANGE': '📅',
      'TIME_PROGRESS': '⏱️',
      'TASK_PROGRESS': '✅',
      'CHECKLIST_SUMMARY': '☑️',
      'PRIORITY_BADGE': '🔥',
      'ASSIGNEE': '👤',
      'TAGS': '🏷️',
      'STATUS_DOT': '🔴',
      'CUSTOM_FIELD': '✏️'
    };
    return iconMap[type] || '📦';
  }

  build() {
    Column({ space: 0 }) {
      // 标题栏
      Column({ space: 8 }) {
        Text('属性编辑器')
          .fontSize(ThemeConfig.fontSizeL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.textPrimary);
        
        if (this.selectedComponent) {
          Row({ space: 6 }) {
            Text(this.getComponentIcon(this.selectedComponent.type))
              .fontSize(16);
            
            Text(this.getComponentTypeLabel(this.selectedComponent.type))
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.primaryColor)
              .fontWeight(FontWeight.Medium);
          }
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })
      .alignItems(HorizontalAlign.Start);

      if (!this.selectedComponent) {
        Column({ space: 12 }) {
          Text('← 请选择组件')
            .fontSize(ThemeConfig.fontSizeM)
            .fontColor(ColorResource.textTertiary);
          
          Text('在画布中点击组件以编辑属性')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary)
            .opacity(0.7)
            .textAlign(TextAlign.Center);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 基本信息
            Column({ space: 12 }) {
              Text('基本信息')
                .fontSize(ThemeConfig.fontSizeM)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.textPrimary);

              Column({ space: 10 }) {
                Row({ space: 8 }) {
                  Text('组件ID')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textTertiary)
                    .width(80);
                  
                  Text(this.selectedComponent.id)
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.textSecondary)
                    .fontFamily('monospace')
                    .layoutWeight(1);
                }

                Divider()
                  .strokeWidth(0.5)
                  .color(ColorResource.surfaceEmphasized)
                  .opacity(0.3);

                Row({ space: 8 }) {
                  Text('类型')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textTertiary)
                    .width(80);
                  
                  Text(this.getComponentTypeLabel(this.selectedComponent.type))
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textPrimary)
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1);
                }
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorResource.surface)
            .borderRadius(12)
            .shadow(ThemeConfig.cardShadow);

            // 组件配置
            this.renderComponentConfig();

            // 组件说明
            Column({ space: 8 }) {
              Text('组件说明')
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.textPrimary);
              
              Text(this.getComponentDescription(this.selectedComponent.type))
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textSecondary)
                .lineHeight(18);
            }
            .width('100%')
            .padding(12)
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(8)
            .alignItems(HorizontalAlign.Start);
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage);
  }

  @Builder
  renderComponentConfig() {
    if (this.selectedComponent) {
      Column({ space: 12 }) {
      Text('组件配置')
        .fontSize(ThemeConfig.fontSizeM)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorResource.textPrimary);

      if (this.selectedComponent.type === 'CUSTOM_FIELD') {
        // 自定义字段需要绑定字段
        Column({ space: 8 }) {
          Text('绑定字段')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
          
          if (this.availableFields.length === 0) {
            Column({ space: 6 }) {
              Text('暂无可用字段')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ColorResource.textTertiary);
              
              Text('请先在"字段管理"中添加字段')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textSecondary)
                .lineHeight(16);
            }
            .width('100%')
            .padding(12)
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(8)
            .alignItems(HorizontalAlign.Start);
          } else {
            Column({ space: 6 }) {
              ForEach(this.availableFields, (field: FieldSchema) => {
                Row({ space: 8 }) {
                  Radio({ value: field.id, group: 'fieldBinding' })
                    .checked(this.selectedComponent?.fieldId === field.id)
                    .onChange((isChecked: boolean) => {
                      if (isChecked && this.selectedComponent && this.onPropertyChange) {
                        const updated: NodeComponentSchema = {
                          id: this.selectedComponent.id,
                          type: this.selectedComponent.type,
                          fieldId: field.id,
                          props: this.selectedComponent.props
                        };
                        this.onPropertyChange(updated);
                      }
                    });
                  
                  Column({ space: 2 }) {
                    Text(field.label)
                      .fontSize(ThemeConfig.fontSizeS)
                      .fontColor(ColorResource.textPrimary);
                    
                    Text(field.type)
                      .fontSize(ThemeConfig.fontSizeXS)
                      .fontColor(ColorResource.textTertiary);
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1);
                }
                .width('100%')
                .padding(10)
                .backgroundColor(
                  this.selectedComponent?.fieldId === field.id
                    ? ColorResource.backgroundSecondary
                    : Color.Transparent
                )
                .borderRadius(6);
              }, (field: FieldSchema) => field.id);
            }
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      } else if (this.needsMaxLinesConfig(this.selectedComponent.type)) {
        // 需要最大行数配置
        Column({ space: 8 }) {
          Text('最大行数')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
          
          Row({ space: 12 }) {
            ForEach([1, 2, 3], (lines: number) => {
              Text(`${lines}行`)
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(
                  this.selectedComponent?.props?.maxLines === lines
                    ? Color.White
                    : ColorResource.textSecondary
                )
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor(
                  this.selectedComponent?.props?.maxLines === lines
                    ? ColorResource.primaryColor
                    : ColorResource.backgroundSecondary
                )
                .borderRadius(8)
                .onClick(() => {
                  if (this.selectedComponent && this.onPropertyChange) {
                    const updated: NodeComponentSchema = {
                      id: this.selectedComponent.id,
                      type: this.selectedComponent.type,
                      fieldId: this.selectedComponent.fieldId,
                      props: {
                        maxLines: lines,
                        highlight: this.selectedComponent.props?.highlight,
                        color: this.selectedComponent.props?.color
                      }
                    };
                    this.onPropertyChange(updated);
                  }
                });
            });
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      } else {
        // 其他组件的通用配置
        Column({ space: 8 }) {
          Text('该组件暂无特殊配置项')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
          
          Text('组件将使用默认样式渲染')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textSecondary)
            .lineHeight(16);
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorResource.backgroundSecondary)
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start);
      }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(ColorResource.surface)
      .borderRadius(12)
      .shadow(ThemeConfig.cardShadow);
    }
  }

  private needsMaxLinesConfig(type: NodeComponentType): boolean {
    return type === 'TITLE' || type === 'TAGS' || type === 'ASSIGNEE';
  }

  private getComponentDescription(type: NodeComponentType): string {
    const descriptions: Record<string, string> = {
      'TITLE': '显示任务的标题文本，通常放在节点卡片的顶部。支持设置最大行数以避免过长文本。',
      'DATE_RANGE': '显示任务的开始日期和结束日期，自动计算并显示工期天数。',
      'TIME_PROGRESS': '显示任务的时间进度条，基于当前日期与任务开始/结束日期计算进度百分比。',
      'TASK_PROGRESS': '显示任务的完成进度条，基于清单项的完成情况计算完成度。',
      'CHECKLIST_SUMMARY': '显示清单的统计信息，如"3/5 项已完成"。',
      'PRIORITY_BADGE': '显示任务的优先级标签，用于突出重要任务。',
      'ASSIGNEE': '显示任务的负责人信息。',
      'TAGS': '显示任务的标签列表，支持多个标签。',
      'STATUS_DOT': '显示任务当前状态的指示点，通过颜色区分不同状态。',
      'CUSTOM_FIELD': '显示自定义字段的值，需要先在字段管理中创建字段并绑定。'
    };
    return descriptions[type] || '该组件的详细说明暂未提供。';
  }
}
