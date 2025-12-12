// File: entry/src/main/ets/components/NodeVisualCanvas.ets
/**
 * 节点可视化画布组件
 * 支持拖拽添加、排序、选中组件的所见即所得编辑器
 */

import { NodeComponentType, NodeComponentSchema, NodeSchema } from '../model/NodeSchema';
import { NodeComponentPreview } from './NodeComponentRenderer';
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
  
  onComponentSelect?: (componentId: string) => void;
  onComponentDelete?: (componentId: string) => void;
  onComponentReorder?: (fromIndex: number, toIndex: number) => void;
  onComponentAdd?: (type: NodeComponentType, index: number) => void;

  build() {
    Column({ space: 0 }) {
      // 画布标题
      Row({ space: 8 }) {
        Text('可视化画布')
          .fontSize(ThemeConfig.fontSizeL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.textPrimary);
        
        Text('WYSIWYG')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textTertiary)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(4);
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 });

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
        Scroll() {
          Column({ space: 16 }) {
            // 节点预览卡片容器
            Column({ space: 0 }) {
              Text('节点卡片预览')
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.textSecondary)
                .margin({ bottom: 12 });
              
              // 真实节点卡片
              Column({ space: 8 }) {
                if (this.schema.layout.length === 0) {
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
                  .height(200)
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
                } else {
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
                                    const dropData: DragInfo = JSON.parse(content);
                                    if (dropData.action === 'reorder' && this.onComponentReorder) {
                                      this.onComponentReorder(dropData.index, index);
                                    }
                                  } catch (e) {
                                    // 解析失败，说明是组件库拖入
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
                                      const dropData: DragInfo = JSON.parse(content);
                                      if (dropData.action === 'reorder' && this.onComponentReorder) {
                                        this.onComponentReorder(dropData.index, index + 1);
                                      }
                                    } catch (e) {
                                      // 解析失败，说明是组件库拖入
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
                this.schema.style.borderRadius !== undefined
                  ? this.schema.style.borderRadius
                  : 16
              )
              .border({
                width: this.schema.style.borderColor ? 3 : 2,
                color: this.schema.style.borderColor || this.schema.style.fillColor
              })
              .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetY: 2 });
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center);

            // 样式信息卡片
            Column({ space: 10 }) {
              Text('样式配置')
                .fontSize(ThemeConfig.fontSizeM)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.textPrimary);

              Row({ space: 8 }) {
                Text('主题色')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary)
                  .width(70);
                
                Row({ space: 6 }) {
                  Circle()
                    .width(16)
                    .height(16)
                    .fill(this.schema.style.fillColor);
                  
                  Text(this.schema.style.fillColor)
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textPrimary)
                    .fontWeight(FontWeight.Medium);
                }
              }

              Row({ space: 8 }) {
                Text('边框色')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary)
                  .width(70);
                
                Row({ space: 6 }) {
                  Circle()
                    .width(16)
                    .height(16)
                    .fill(this.schema.style.borderColor || this.schema.style.fillColor);
                  
                  Text(this.schema.style.borderColor || '同主题色')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textPrimary)
                    .fontWeight(FontWeight.Medium);
                }
              }

              Row({ space: 8 }) {
                Text('圆角')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary)
                  .width(70);
                
                Text(`${this.schema.style.borderRadius || 16}px`)
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textPrimary);
              }

              Row({ space: 8 }) {
                Text('组件数')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary)
                  .width(70);
                
                Text(`${this.schema.layout.length} 个`)
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.primaryColor)
                  .fontWeight(FontWeight.Medium);
              }
              
              Divider()
                .strokeWidth(0.5)
                .color(ColorResource.surfaceEmphasized)
                .opacity(0.3)
                .margin({ top: 6, bottom: 6 });
              
              Text('在右侧属性编辑器中编辑详细样式')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary)
                .lineHeight(16);
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorResource.surface)
            .borderRadius(12)
            .shadow(ThemeConfig.cardShadow);

            // 提示信息
            Column({ space: 8 }) {
              Text('💡 使用提示')
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.textPrimary);
              
              Text('• 从左侧组件库拖拽组件到画布')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textSecondary)
                .lineHeight(18);
              
              Text('• 点击组件查看/编辑属性')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textSecondary)
                .lineHeight(18);
              
              Text('• 点击右上角 × 删除组件')
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
}
