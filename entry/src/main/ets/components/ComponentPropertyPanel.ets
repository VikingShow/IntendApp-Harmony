// File: entry/src/main/ets/components/ComponentPropertyPanel.ets
/**
 * 组件属性编辑面板
 * 根据选中的组件类型显示相应的属性编辑器
 */

import { NodeComponentType, NodeComponentSchema, NodeComponentProps, FieldSchema, FieldType, NodeStyleSchema } from '../model/NodeSchema';
import { CustomComponentDefinition } from '../model/CustomComponentSchema';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

@Component
export struct ComponentPropertyPanel {
  @Prop selectedComponent: NodeComponentSchema | null;
  @Prop availableFields: FieldSchema[] = [];
  @Prop customComponents: CustomComponentDefinition[] = [];
  @Prop schemaStyle: NodeStyleSchema | null = null;
  @Prop @Watch('onRefreshKeyChanged') refreshKey: number = 0;

  @State private newOptionInput: string = '';
  @State private localRefreshTrigger: number = 0;

  onFillColorChange?: (color: string) => void;
  onCriticalColorChange?: (color: string) => void;
  onPickFillColor?: () => void;
  onPickCriticalColor?: () => void;
  onBorderColorChange?: (color: string) => void;
  onBorderRadiusChange?: (radius: number) => void;
  onPropertyChange?: (component: NodeComponentSchema) => void;
  onFieldChange?: (field: FieldSchema) => void;

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
      'CUSTOM_FIELD': '自定义字段',
      'CUSTOM_COMPONENT': '自定义组件',
    };
    return typeMap[type] || type;
  }

  private getComponentIcon(type: NodeComponentType): Resource {
    const iconMap: Record<string, Resource> = {
      'TITLE': $r('app.media.ic_pin'),
      'DATE_RANGE': $r('app.media.ic_calendar'),
      'TIME_PROGRESS': $r('app.media.ic_clock'),
      'TASK_PROGRESS': $r('app.media.ic_select'),
      'CHECKLIST_SUMMARY': $r('app.media.ic_checklist'),
      'PRIORITY_BADGE': $r('app.media.ic_priority'),
      'ASSIGNEE': $r('app.media.ic_user'),
      'TAGS': $r('app.media.ic_tag'),
      'STATUS_DOT': $r('app.media.ic_status'),
      'CUSTOM_FIELD': $r('app.media.ic_edit'),
      'CUSTOM_COMPONENT': $r('app.media.ic_edit')
    };
    return iconMap[type] || $r('app.media.ic_project_file');
  }
  private getReservedFieldIdForType(type: NodeComponentType): string {
    if (type === 'PRIORITY_BADGE') return '_priority';
    if (type === 'ASSIGNEE') return '_assignee';
    if (type === 'TAGS') return '_tags';
    if (type === 'STATUS_DOT') return '_status';
    return '';
  }

  private getBoundFieldForSelectedComponent(): FieldSchema | null {
    if (!this.selectedComponent || this.availableFields.length === 0) {
      return null;
    }

    let fieldId: string | undefined = this.selectedComponent.fieldId;
    if (!fieldId || fieldId.length === 0) {
      fieldId = this.getReservedFieldIdForType(this.selectedComponent.type);
    }
    if (!fieldId || fieldId.length === 0) {
      return null;
    }

    const found = this.availableFields.find((f: FieldSchema) => f.id === fieldId);
    return found || null;
  }

  build() {
    Column({ space: 0 }) {
      // 标题栏
      Row({ space: 8 }) {
        Text('属性编辑器')
          .fontSize(ThemeConfig.fontSizeL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.textPrimary);

        Row()
          .layoutWeight(1);

        Text('?')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorResource.textSecondary)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(16)
          .onClick(() => {
            AlertDialog.show({
              title: '属性编辑器使用提示',
              message: '1. 上方可调整节点卡片的整体样式\n2. 选中画布中的组件后可编辑其属性\n3. 部分组件支持绑定自定义字段',
              confirm: {
                value: '知道了',
                action: () => {}
              }
            });
          });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 });

      this.PropertiesTabContent();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage);
  }

  // ========== 组件属性 Tab ==========
  @Builder
  PropertiesTabContent() {
    Column({ space: 0 }) {
      // 样式编辑区
      if (this.schemaStyle) {
        Column({ space: 6 }) {
          // 第一行：颜色配置
          Row({ space: 12 }) {
            // 普通颜色
            Row({ space: 6 }) {
              Text('普通')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary);
              Row()
                .width(32)
                .height(32)
                .backgroundColor(this.schemaStyle.fillColor || '#409EFF')
                .borderRadius(8)
                .onClick(() => {
                  if (this.onPickFillColor) {
                    this.onPickFillColor();
                  }
                });
              TextInput({ text: this.schemaStyle.fillColor, placeholder: '#hex' })
                .width(70)
                .height(26)
                .fontSize(10)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(4)
                .padding({ left: 6, right: 6 })
                .onChange((value: string) => {
                  if (this.onFillColorChange) {
                    this.onFillColorChange(value);
                  }
                });
            }

            // 关键颜色
            Row({ space: 6 }) {
              Text('关键')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary);
              Row()
                .width(32)
                .height(32)
                .backgroundColor(this.schemaStyle.criticalColor || '#D0021B')
                .borderRadius(8)
                .onClick(() => {
                  if (this.onPickCriticalColor) {
                    this.onPickCriticalColor();
                  }
                });
              TextInput({ text: this.schemaStyle.criticalColor || '', placeholder: '#hex' })
                .width(70)
                .height(26)
                .fontSize(10)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(4)
                .padding({ left: 6, right: 6 })
                .onChange((value: string) => {
                  if (this.onCriticalColorChange) {
                    this.onCriticalColorChange(value);
                  }
                });
            }
          }
          .width('100%');

          // 第二行：圆角
          Row({ space: 8 }) {
            Text(`圆角 ${this.schemaStyle.borderRadius || 16}px`)
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textTertiary)
              .width(60);
            Slider({
              value: this.schemaStyle.borderRadius || 16,
              min: 0,
              max: 64,
              step: 2,
              style: SliderStyle.InSet
            })
              .layoutWeight(1)
              .trackColor(ColorResource.backgroundSecondary)
              .selectedColor(ColorResource.primaryColor)
              .onChange((value: number) => {
                if (this.onBorderRadiusChange) {
                  this.onBorderRadiusChange(value);
                }
              });
          }
          .width('100%');
        }
        .width('100%')
        .padding(10)
        .backgroundColor(ColorResource.surface)
        .borderRadius(8)
        .margin({ left: 16, right: 16, top: 6, bottom: 6 });
      }

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3);

      // 组件属性区
      Column({ space: 0 }) {
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
          .padding({ left: 20, right: 20, top: 16, bottom: 20 })
          .justifyContent(FlexAlign.Center);
        } else {
          // 组件名称
          Row({ space: 6 }) {
            Image(this.getComponentIcon(this.selectedComponent.type))
              .width(16)
              .height(16)
              .fillColor(ColorResource.textSecondary)

            Text(this.getComponentTypeLabel(this.selectedComponent.type))
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.primaryColor)
              .fontWeight(FontWeight.Medium);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 8 });

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
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          .padding({ left: 20, right: 20, top: 8, bottom: 20 });
        }
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .layoutWeight(1);
  }

  @Builder
  renderComponentConfig() {
    if (this.selectedComponent) {
      Column({ space: 12 }) {
        Text('组件配置')
          .fontSize(ThemeConfig.fontSizeM)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary);

        if (this.selectedComponent.type === 'CUSTOM_COMPONENT') {
          Column({ space: 8 }) {
            Text('选择自定义组件')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary);

            if (this.customComponents.length === 0) {
              Column({ space: 6 }) {
                Text('暂无可用自定义组件')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary);

                Text('请先在“自定义组件”中创建组件')
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
                ForEach(this.customComponents, (def: CustomComponentDefinition) => {
                  Row({ space: 8 }) {
                    Radio({ value: def.id, group: 'customComponentBinding' })
                      .checked(this.selectedComponent?.customComponentId === def.id)
                      .onChange((isChecked: boolean) => {
                        if (isChecked && this.selectedComponent && this.onPropertyChange) {
                          const updated: NodeComponentSchema = {
                            id: this.selectedComponent.id,
                            type: this.selectedComponent.type,
                            fieldId: this.selectedComponent.fieldId,
                            customComponentId: def.id,
                            props: this.selectedComponent.props
                          };
                          this.onPropertyChange(updated);
                        }
                      });

                    Column({ space: 2 }) {
                      Text(def.name)
                        .fontSize(ThemeConfig.fontSizeS)
                        .fontColor(ColorResource.textPrimary);

                      Text(def.renderType)
                        .fontSize(ThemeConfig.fontSizeXS)
                        .fontColor(ColorResource.textTertiary);
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1);
                  }
                  .width('100%')
                  .padding(10)
                  .backgroundColor(
                    this.selectedComponent?.customComponentId === def.id
                      ? ColorResource.backgroundSecondary
                      : Color.Transparent
                  )
                  .borderRadius(6);
                }, (def: CustomComponentDefinition) => def.id);
              }
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start);
        }

        if (this.selectedComponent.type === 'CUSTOM_FIELD' || this.selectedComponent.type === 'CUSTOM_COMPONENT') {
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

                Button('去添加字段')
                  .height(32)
                  .fontSize(ThemeConfig.fontSizeXS)
                  .backgroundColor(ColorResource.primaryColor)
                  .fontColor(Color.White)
                  .borderRadius(6)
                  .margin({ top: 8 })
                  .onClick(() => {
                    // 字段管理已迁移到独立页面
                  });
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
                            customComponentId: this.selectedComponent?.customComponentId,
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
                        customComponentId: this.selectedComponent.customComponentId,
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

          // 对 TAGS 组件增加标签预选值配置
          if (this.selectedComponent.type === 'TAGS') {
            this.OptionsListEditor('_tags', '标签预选值', '输入新标签');
            this.StyleSelector(['标签', '文字'], ['tag', 'text']);
          }

        } else if (this.selectedComponent.type === 'PRIORITY_BADGE') {
          // 优先级组件配置
          this.OptionsListEditor('_priority', '优先级选项', '输入新选项');
          this.StyleSelector(['徽章', '文字', '图标'], ['badge', 'text', 'icon']);

        } else if (this.selectedComponent.type === 'STATUS_DOT') {
          // 状态点组件配置
          this.OptionsListEditor('_status', '状态选项', '输入新状态');
          this.StyleSelector(['圆点', '标签'], ['dot', 'label']);

          // 状态颜色说明
          Column({ space: 4 }) {
            Text('状态颜色参考')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textTertiary);

            Row({ space: 6 }) {
              this.ColorDot('#52C41A', '完成');
              this.ColorDot('#1890FF', '进行');
              this.ColorDot('#FAAD14', '阻塞');
              this.ColorDot('#D9D9D9', '未始');
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 8 });

        } else {
          // 其他组件（如日期范围、进度条等）自动配置
          Column({ space: 8 }) {
            Text('自动配置')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary);

            Text('该组件根据任务数据自动渲染，无需额外配置')
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
      'CUSTOM_FIELD': '显示自定义字段的值，需要先在字段管理中创建字段并绑定。',
      'CUSTOM_COMPONENT': 'Custom component bound to a field.',
    };
    return descriptions[type] || '该组件的详细说明暂未提供。';
  }

  private getFieldOptionsArray(fieldId: string): string[] {
    const field = this.availableFields.find((f: FieldSchema) => f.id === fieldId);
    if (field && field.options && field.options.length > 0) {
      return field.options as string[];
    }
    return [];
  }

  private getFieldLabelForId(fieldId: string): string {
    const labelMap: Record<string, string> = {
      '_priority': '优先级',
      '_status': '状态',
      '_tags': '标签',
      '_assignee': '负责人'
    };
    return labelMap[fieldId] || fieldId;
  }

  private getFieldTypeForId(fieldId: string): FieldType {
    if (fieldId === '_priority') return 'select';
    if (fieldId === '_status') return 'select';
    if (fieldId === '_tags') return 'checklist';
    if (fieldId === '_assignee') return 'text';
    return 'text';
  }

  private isStyleSelected(value: string, index: number): boolean {
    // 使用 localRefreshTrigger 确保重新计算
    const _ = this.localRefreshTrigger;
    const currentStyle = this.selectedComponent?.props?.style;
    return currentStyle === value || (index === 0 && !currentStyle);
  }

  private onRefreshKeyChanged(): void {
    // 当 refreshKey 变化时，增加本地刷新触发器以强制 UI 更新
    this.localRefreshTrigger++;
  }

  private addFieldOption(fieldId: string, newOption: string): void {
    if (!this.onFieldChange) {
      console.error('ComponentPropertyPanel: onFieldChange callback not set');
      return;
    }
    if (!newOption || !newOption.trim()) {
      return;
    }
    const trimmedOption = newOption.trim();

    // 查找现有字段，如果不存在则创建新的
    let field = this.availableFields.find((f: FieldSchema) => f.id === fieldId);
    let currentOptions: string[] = [];

    if (field && field.options) {
      currentOptions = field.options as string[];
    }

    // 检查是否已存在
    if (currentOptions.includes(trimmedOption)) {
      return;
    }

    const newOptions = [...currentOptions, trimmedOption];
    const updatedField: FieldSchema = {
      id: fieldId,
      label: field?.label || this.getFieldLabelForId(fieldId),
      type: field?.type || this.getFieldTypeForId(fieldId),
      required: field?.required || false,
      defaultValue: field?.defaultValue,
      options: newOptions
    };

    this.onFieldChange(updatedField);
    this.newOptionInput = '';
  }

  private removeFieldOption(fieldId: string, optionToRemove: string): void {
    if (!this.onFieldChange) {
      console.error('ComponentPropertyPanel: onFieldChange callback not set');
      return;
    }

    const field = this.availableFields.find((f: FieldSchema) => f.id === fieldId);
    let currentOptions: string[] = [];

    if (field && field.options) {
      currentOptions = field.options as string[];
    }

    const newOptions = currentOptions.filter((opt: string) => opt !== optionToRemove);
    const updatedField: FieldSchema = {
      id: fieldId,
      label: field?.label || this.getFieldLabelForId(fieldId),
      type: field?.type || this.getFieldTypeForId(fieldId),
      required: field?.required || false,
      defaultValue: field?.defaultValue,
      options: newOptions.length > 0 ? newOptions : undefined
    };

    this.onFieldChange(updatedField);
  }

  private updateComponentStyle(style: string): void {
    if (!this.selectedComponent) {
      console.error('ComponentPropertyPanel: selectedComponent is null');
      return;
    }
    if (!this.onPropertyChange) {
      console.error('ComponentPropertyPanel: onPropertyChange callback not set');
      return;
    }
    const newProps: NodeComponentProps = {
      style: style,
      maxLines: this.selectedComponent.props?.maxLines,
      highlight: this.selectedComponent.props?.highlight,
      color: this.selectedComponent.props?.color
    };
    const updated: NodeComponentSchema = {
      id: this.selectedComponent.id,
      type: this.selectedComponent.type,
      fieldId: this.selectedComponent.fieldId,
      customComponentId: this.selectedComponent.customComponentId,
      props: newProps
    };
    this.onPropertyChange(updated);
  }

  @Builder
  StyleOptionBtn(label: string, value: string, isSelected: boolean) {
    Text(label)
      .fontSize(ThemeConfig.fontSizeS)
      .fontColor(isSelected ? Color.White : ColorResource.textSecondary)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(isSelected ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
      .borderRadius(6)
      .onClick(() => {
        this.updateComponentStyle(value);
      });
  }

  @Builder
  ColorDot(color: string, label: string) {
    Row({ space: 4 }) {
      Circle()
        .width(10)
        .height(10)
        .fill(color);
      Text(label)
        .fontSize(ThemeConfig.fontSizeXS)
        .fontColor(ColorResource.textTertiary);
    }
  }

  // 通用选项列表编辑器
  @Builder
  OptionsListEditor(fieldId: string, title: string, placeholder: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textTertiary);

      // 选项列表
      ForEach(this.getFieldOptionsArray(fieldId), (option: string, index: number) => {
        Row({ space: 8 }) {
          Text(option)
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Text('×')
            .fontSize(16)
            .fontColor(ColorResource.textTertiary)
            .width(24)
            .height(24)
            .textAlign(TextAlign.Center)
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.removeFieldOption(fieldId, option);
            });
        }
        .width('100%')
        .padding(8)
        .backgroundColor(ColorResource.backgroundSecondary)
        .borderRadius(6);
      }, (option: string, index: number) => `${fieldId}_${index}_${option}`);

      // 新增选项
      Row({ space: 8 }) {
        TextInput({ text: this.newOptionInput, placeholder: placeholder })
          .layoutWeight(1)
          .height(32)
          .fontSize(ThemeConfig.fontSizeS)
          .backgroundColor(ColorResource.backgroundInput)
          .borderRadius(6)
          .padding({ left: 10, right: 10 })
          .onChange((value: string) => {
            this.newOptionInput = value;
          });

        Button('添加')
          .height(32)
          .fontSize(ThemeConfig.fontSizeXS)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .borderRadius(6)
          .onClick(() => {
            this.addFieldOption(fieldId, this.newOptionInput);
          });
      }
      .width('100%');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  // 通用样式选择器
  @Builder
  StyleSelector(labels: string[], values: string[]) {
    Column({ space: 6 }) {
      Text('显示样式')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textTertiary);

      Row({ space: 8 }) {
        ForEach(labels, (label: string, index: number) => {
          Text(label)
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(this.isStyleSelected(values[index], index) ? Color.White : ColorResource.textSecondary)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.isStyleSelected(values[index], index) ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(6)
            .onClick(() => {
              this.updateComponentStyle(values[index]);
            });
        }, (label: string, index: number) => `style_${index}_${label}_${this.localRefreshTrigger}_${this.selectedComponent?.props?.style || 'default'}`);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 8 });
  }
}
