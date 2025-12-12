// File: entry/src/main/ets/components/ComponentLibrary.ets
/**
 * 组件库面板
 * 展示所有可用的节点组件类型，支持拖拽到画布
 */

import { NodeComponentType } from '../model/NodeSchema';
import { DraggableComponentItem } from './NodeComponentRenderer';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

interface ComponentTypeInfo {
  type: NodeComponentType;
  label: string;
  icon: string;
  description: string;
  category: 'basic' | 'data' | 'advanced';
}

@Component
export struct ComponentLibrary {
  @State selectedCategory: 'all' | 'basic' | 'data' | 'advanced' = 'all';
  @State draggedComponentType: NodeComponentType | null = null;
  
  onComponentClick?: (type: NodeComponentType) => void;
  onComponentDragStart?: (type: NodeComponentType) => void;
  onComponentDragEnd?: () => void;

  private componentTypes: ComponentTypeInfo[] = [
    // 基础组件
    { type: 'TITLE', label: '标题', icon: '📌', description: '任务名称标题', category: 'basic' },
    { type: 'DATE_RANGE', label: '日期范围', icon: '📅', description: '开始-结束日期', category: 'basic' },
    { type: 'STATUS_DOT', label: '状态点', icon: '🔴', description: '状态指示器', category: 'basic' },
    
    // 数据展示组件
    { type: 'TIME_PROGRESS', label: '时间进度', icon: '⏱️', description: '时间进度条', category: 'data' },
    { type: 'TASK_PROGRESS', label: '任务进度', icon: '✅', description: '完成度进度条', category: 'data' },
    { type: 'CHECKLIST_SUMMARY', label: '清单统计', icon: '☑️', description: '清单完成情况', category: 'data' },
    { type: 'PRIORITY_BADGE', label: '优先级', icon: '🔥', description: '优先级标签', category: 'data' },
    
    // 高级组件
    { type: 'ASSIGNEE', label: '负责人', icon: '👤', description: '任务负责人', category: 'advanced' },
    { type: 'TAGS', label: '标签', icon: '🏷️', description: '标签列表', category: 'advanced' },
    { type: 'CUSTOM_FIELD', label: '自定义字段', icon: '✏️', description: '绑定自定义字段', category: 'advanced' }
  ];

  private getFilteredComponents(): ComponentTypeInfo[] {
    if (this.selectedCategory === 'all') {
      return this.componentTypes;
    }
    return this.componentTypes.filter(c => c.category === this.selectedCategory);
  }

  build() {
    Column({ space: 0 }) {
      // 标题栏
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('组件库')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);
          
          Text(`${this.getFilteredComponents().length}`)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(Color.White)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(ColorResource.primaryColor)
            .borderRadius(8);
        }
        .width('100%');
        
        // 分类筛选
        Row({ space: 6 }) {
          Text('全部')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.selectedCategory === 'all' ? Color.White : ColorResource.textSecondary)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.selectedCategory === 'all' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.selectedCategory = 'all';
            });
          
          Text('基础')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.selectedCategory === 'basic' ? Color.White : ColorResource.textSecondary)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.selectedCategory === 'basic' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.selectedCategory = 'basic';
            });
          
          Text('数据')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.selectedCategory === 'data' ? Color.White : ColorResource.textSecondary)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.selectedCategory === 'data' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.selectedCategory = 'data';
            });
          
          Text('高级')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.selectedCategory === 'advanced' ? Color.White : ColorResource.textSecondary)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.selectedCategory === 'advanced' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.selectedCategory = 'advanced';
            });
        }
        .width('100%');
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      .alignItems(HorizontalAlign.Start);

      // 组件列表
      Scroll() {
        Column({ space: 8 }) {
          ForEach(this.getFilteredComponents(), (component: ComponentTypeInfo) => {
            Column({ space: 0 }) {
              DraggableComponentItem({
                type: component.type,
                label: component.label,
                icon: component.icon,
                isDragging: this.draggedComponentType === component.type,
                handleDragStart: (type: NodeComponentType) => {
                  this.draggedComponentType = type;
                  if (this.onComponentDragStart) {
                    this.onComponentDragStart(type);
                  }
                },
                handleDragEnd: () => {
                  this.draggedComponentType = null;
                  if (this.onComponentDragEnd) {
                    this.onComponentDragEnd();
                  }
                }
              })
              .onClick(() => {
                if (this.onComponentClick) {
                  this.onComponentClick(component.type);
                }
              });
              
              // 描述信息
              Text(component.description)
                .fontSize(ThemeConfig.fontSizeXS - 1)
                .fontColor(ColorResource.textTertiary)
                .opacity(0.7)
                .padding({ left: 12, right: 12, top: 4, bottom: 8 });
            }
            .width('100%');
          }, (component: ComponentTypeInfo) => component.type);

          // 使用说明
          Column({ space: 8 }) {
            Text('使用说明')
              .fontSize(ThemeConfig.fontSizeS)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorResource.textPrimary);
            
            Text('1. 点击组件快速添加到画布底部')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textSecondary)
              .lineHeight(18);
            
            Text('2. 长按组件拖拽到指定位置')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textSecondary)
              .lineHeight(18);
            
            Text('3. 在画布中点击组件进行编辑')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textSecondary)
              .lineHeight(18);
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 12 });
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 16 });
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage);
  }
}
