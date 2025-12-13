// File: entry/src/main/ets/components/NodeVisualCanvas.ets
/**
 * 节点可视化画布组件
 * 支持拖拽添加、排序、选中组件的所见即所得编辑器
 * 分为上下两部分：上部60%为可拖拽编辑区，下部40%为只读实时预览区
 */

import { NodeComponentType, NodeComponentSchema, NodeSchema } from '../model/NodeSchema';
import { NodeComponentPreview, NodeComponentContent } from './NodeComponentRenderer';
import { unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

interface DragInfo {
  action: 'reorder';
  index: number;
}

@Component
export struct NodeVisualCanvas {
  @Prop schema: NodeSchema | null;
  @Prop selectedComponentId: string | null;
  @Prop draggedLibraryType: NodeComponentType | null = null;
  @State dragOverIndex: number = -1;
  @State isDragOver: boolean = false;
  @State draggedComponentIndex: number = -1;
  @State previewMode: 'normal' | 'critical' = 'normal';
  @State livePreviewMode: 'normal' | 'critical' = 'normal';

  onComponentSelect?: (componentId: string) => void;
  onComponentDelete?: (componentId: string) => void;
  onComponentReorder?: (fromIndex: number, toIndex: number) => void;
  onComponentAdd?: (type: NodeComponentType, index: number) => void;

  build() {
    Column({ space: 0 }) {
      // ========== 上半部分：可拖拽编辑区域 (60%) ==========
      Column({ space: 0 }) {
        // 画布标题
        Row({ space: 8 }) {
          Text('编辑画布')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary);

          Text('可拖拽')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textTertiary)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(4);

          Row()
            .layoutWeight(1);

          Text('?')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorResource.textSecondary)
            .width(24)
            .height(24)
            .textAlign(TextAlign.Center)
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              AlertDialog.show({
                title: '可视化画布使用提示',
                message: '1. 从左侧组件库拖拽组件到画布\n2. 在画布中拖拽可调整组件顺序\n3. 点击组件可在右侧编辑其属性\n4. 下方预览区显示实际效果',
                confirm: {
                  value: '知道了',
                  action: () => {}
                }
              });
            });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 8 });

        if (!this.schema) {
          Column({ space: 12 }) {
            Text('← 请选择节点类型')
              .fontSize(ThemeConfig.fontSizeM)
              .fontColor(ColorResource.textTertiary);

            Text('从左侧列表选择要编辑的节点类型')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary)
              .opacity(0.7);
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          this.EditableCanvasContent();
        }
      }
      .width('100%')
      .layoutWeight(6)
      .backgroundColor(ColorResource.backgroundPage);

      // ========== 分隔线 ==========
      Row({ space: 8 }) {
        Row()
          .layoutWeight(1)
          .height(1)
          .backgroundColor(ColorResource.surfaceEmphasized)
          .opacity(0.3);

        Text('实时预览')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textTertiary);

        Row()
          .layoutWeight(1)
          .height(1)
          .backgroundColor(ColorResource.surfaceEmphasized)
          .opacity(0.3);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor(ColorResource.surface);

      // ========== 下半部分：实时预览区域 (40%) ==========
      Column({ space: 0 }) {
        if (!this.schema) {
          Column({ space: 12 }) {
            Text('← 请选择节点类型')
              .fontSize(ThemeConfig.fontSizeM)
              .fontColor(ColorResource.textTertiary);

            Text('选择后可在此查看实际效果预览')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary)
              .opacity(0.7);
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          this.LivePreviewContent();
        }
      }
      .width('100%')
      .layoutWeight(4)
      .backgroundColor(ColorResource.backgroundSecondary);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage);
  }

  // ========== 上半部分：可编辑画布内容 ==========
  @Builder
  EditableCanvasContent() {
    Scroll() {
      Column({ space: 12 }) {
        // 节点预览卡片容器
        Column({ space: 0 }) {
          Row({ space: 6 }) {
            Text('预览模式')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textTertiary);

            Row({ space: 4 }) {
              Text('普通')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(this.previewMode === 'normal' ? Color.White : ColorResource.textSecondary)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(this.previewMode === 'normal' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
                .borderRadius(8)
                .onClick(() => {
                  this.previewMode = 'normal';
                });

              Text('关键')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(this.previewMode === 'critical' ? Color.White : ColorResource.textSecondary)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(this.previewMode === 'critical' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
                .borderRadius(8)
                .onClick(() => {
                  this.previewMode = 'critical';
                });
            }
          }
          .width('100%')
          .margin({ bottom: 12 });

          // 真实节点卡片（可拖拽编辑）
          Column({ space: 8 }) {
            if (this.schema !== null && this.schema.layout.length === 0) {
              // 空状态
              Column({ space: 12 }) {
                Text('👈 从左侧拖入组件')
                  .fontSize(ThemeConfig.fontSizeM)
                  .fontColor(ColorResource.textTertiary);

                Text('或点击下方按钮快速添加')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary)
                  .opacity(0.7);

                Button('+ 添加标题组件')
                  .height(40)
                  .fontSize(ThemeConfig.fontSizeS)
                  .backgroundColor(ColorResource.primaryColor)
                  .fontColor(Color.White)
                  .borderRadius(8)
                  .margin({ top: 8 })
                  .onClick(() => {
                    if (this.onComponentAdd) {
                      this.onComponentAdd('TITLE', 0);
                    }
                  });
              }
              .width('100%')
              .height(160)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(ColorResource.backgroundSecondary)
              .borderRadius(12)
              .border({
                width: 2,
                color: ColorResource.surfaceEmphasized,
                style: BorderStyle.Dashed
              })
              .allowDrop([uniformTypeDescriptor.UniformDataType.PLAIN_TEXT])
              .onDragMove(() => {})
              .onDrop(async (event?: DragEvent) => {
                if (this.onComponentAdd && event) {
                  try {
                    const unifiedData = await event.getData();
                    const records = unifiedData.getRecords();
                    if (records.length > 0) {
                      const data: unifiedDataChannel.UnifiedRecord = records[0];
                      if (data.getType() === uniformTypeDescriptor.UniformDataType.PLAIN_TEXT) {
                        const typeToAdd = (data as unifiedDataChannel.PlainText).textContent as NodeComponentType;
                        this.onComponentAdd(typeToAdd, 0);
                      }
                    }
                  } catch (e) {
                    console.error('Drop error:', e);
                  }
                }
                this.isDragOver = false;
              })
              .onDragEnter(() => {
                this.isDragOver = true;
              })
              .onDragLeave(() => {
                this.isDragOver = false;
              });
            } else if (this.schema !== null) {
              // 渲染组件列表
              ForEach(this.schema.layout, (component: NodeComponentSchema, index: number) => {
                Column({ space: 0 }) {
                  // 上方拖放区（每个组件之间）
                  Row()
                    .width('100%')
                    .height(this.dragOverIndex === index && this.isDragOver ? 32 : 8)
                    .border({
                      width: 2,
                      color: ColorResource.primaryColor,
                      style: BorderStyle.Dashed
                    })
                    .borderRadius(6)
                    .opacity(this.dragOverIndex === index && this.isDragOver ? 0.5 : 0)
                    .onDragEnter(() => {
                      this.isDragOver = true;
                      this.dragOverIndex = index;
                    })
                    .allowDrop([uniformTypeDescriptor.UniformDataType.PLAIN_TEXT])
                    .onDragMove(() => {})
                    .onDrop(async (event?: DragEvent) => {
                      if (event) {
                        try {
                          const unifiedData = await event.getData();
                          const records = unifiedData.getRecords();
                          if (records.length > 0) {
                            const data: unifiedDataChannel.UnifiedRecord = records[0];
                            if (data.getType() === uniformTypeDescriptor.UniformDataType.PLAIN_TEXT) {
                              const content = (data as unifiedDataChannel.PlainText).textContent;
                              try {
                                const dropData = JSON.parse(content) as DragInfo;
                                if (dropData.action === 'reorder' && this.onComponentReorder) {
                                  this.onComponentReorder(dropData.index, index);
                                }
                              } catch (e) {
                                if (this.onComponentAdd) {
                                  this.onComponentAdd(content as NodeComponentType, index);
                                }
                              }
                            }
                          }
                        } catch (e) {
                          console.error('Drop error:', e);
                        }
                      }
                      this.isDragOver = false;
                      this.dragOverIndex = -1;
                    });

                  // 组件预览
                  NodeComponentPreview({
                    component: component,
                    isSelected: this.selectedComponentId === component.id,
                    nodeColor: this.schema ? this.schema.style.fillColor : '#007AFF',
                    handleClick: () => {
                      if (this.onComponentSelect) {
                        this.onComponentSelect(component.id);
                      }
                    },
                    handleDelete: () => {
                      if (this.onComponentDelete) {
                        this.onComponentDelete(component.id);
                      }
                    },
                    handleDragStart: (event?: DragEvent) => {
                      this.draggedComponentIndex = index;
                      if (event) {
                        const unifiedData = new unifiedDataChannel.UnifiedData();
                        const plainText = new unifiedDataChannel.PlainText();
                        const dragInfo: DragInfo = { action: 'reorder', index: index };
                        plainText.textContent = JSON.stringify(dragInfo);
                        unifiedData.addRecord(plainText);
                        event.setData(unifiedData);
                      }
                    },
                    handleDragEnd: () => {
                      this.draggedComponentIndex = -1;
                      this.isDragOver = false;
                      this.dragOverIndex = -1;
                    }
                  });

                  // 最后一个组件后的拖放区
                  if (this.schema && index === this.schema.layout.length - 1) {
                    Row()
                      .width('100%')
                      .height(this.dragOverIndex === index + 1 && this.isDragOver ? 32 : 8)
                      .border({
                        width: 2,
                        color: ColorResource.primaryColor,
                        style: BorderStyle.Dashed
                      })
                      .borderRadius(6)
                      .opacity(this.dragOverIndex === index + 1 && this.isDragOver ? 0.5 : 0)
                      .onDragEnter(() => {
                        this.isDragOver = true;
                        this.dragOverIndex = index + 1;
                      })
                      .allowDrop([uniformTypeDescriptor.UniformDataType.PLAIN_TEXT])
                      .onDragMove(() => {})
                      .onDrop(async (event?: DragEvent) => {
                        if (event) {
                          try {
                            const unifiedData = await event.getData();
                            const records = unifiedData.getRecords();
                            if (records.length > 0) {
                              const data: unifiedDataChannel.UnifiedRecord = records[0];
                              if (data.getType() === uniformTypeDescriptor.UniformDataType.PLAIN_TEXT) {
                                const content = (data as unifiedDataChannel.PlainText).textContent;
                                try {
                                  const dropData = JSON.parse(content) as DragInfo;
                                  if (dropData.action === 'reorder' && this.onComponentReorder) {
                                    this.onComponentReorder(dropData.index, index + 1);
                                  }
                                } catch (e) {
                                  if (this.onComponentAdd) {
                                    this.onComponentAdd(content as NodeComponentType, index + 1);
                                  }
                                }
                              }
                            }
                          } catch (e) {
                            console.error('Drop error:', e);
                          }
                        }
                        this.isDragOver = false;
                        this.dragOverIndex = -1;
                      });
                  }
                }
                .width('100%');
              }, (component: NodeComponentSchema) => component.id);
            }
          }
          .width(220)
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(
            this.schema !== null && this.schema.style.borderRadius !== undefined
              ? this.schema.style.borderRadius
              : 16
          )
          .border({
            width: this.schema !== null ? (this.schema.style.borderWidth || 2) : 2,
            color: this.schema !== null ? (this.previewMode === 'critical'
              ? (this.schema.style.criticalColor || '#FF3B30')
              : (this.schema.style.borderColor || this.schema.style.fillColor)) : '#007AFF'
          })
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetY: 2 });
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 16 });
      }
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto);
  }

  // ========== 下半部分：只读实时预览内容 ==========
  @Builder
  LivePreviewContent() {
    Scroll() {
      Column({ space: 12 }) {
        // 预览模式切换
        Row({ space: 8 }) {
          Text('预览模式')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textTertiary);

          Row({ space: 4 }) {
            Text('普通')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(this.livePreviewMode === 'normal' ? Color.White : ColorResource.textSecondary)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(this.livePreviewMode === 'normal' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
              .borderRadius(8)
              .onClick(() => {
                this.livePreviewMode = 'normal';
              });

            Text('关键')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(this.livePreviewMode === 'critical' ? Color.White : ColorResource.textSecondary)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(this.livePreviewMode === 'critical' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
              .borderRadius(8)
              .onClick(() => {
                this.livePreviewMode = 'critical';
              });
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center);

        // 真实效果预览卡片（只读，无拖拽）
        Column({ space: 8 }) {
          if (this.schema !== null && this.schema.layout.length === 0) {
            Column({ space: 8 }) {
              Text('暂无组件')
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ColorResource.textTertiary);
              Text('在上方编辑区添加组件后可预览实际效果')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary)
                .opacity(0.7);
            }
            .width('100%')
            .height(100)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(12);
          } else if (this.schema !== null) {
            // 渲染只读预览组件
            ForEach(this.schema.layout, (component: NodeComponentSchema) => {
              NodeComponentContent({
                component: component
              });
            }, (component: NodeComponentSchema) => component.id);
          }
        }
        .width(220)
        .padding(12)
        .backgroundColor(ColorResource.surface)
        .borderRadius(
          this.schema !== null && this.schema.style.borderRadius !== undefined
            ? this.schema.style.borderRadius
            : 16
        )
        .border({
          width: this.schema !== null ? (this.schema.style.borderWidth || 2) : 2,
          color: this.schema !== null ? (this.livePreviewMode === 'critical'
            ? (this.schema.style.criticalColor || '#FF3B30')
            : (this.schema.style.borderColor || this.schema.style.fillColor)) : '#007AFF'
        })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetY: 2 });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 20 });
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto);
  }
}
