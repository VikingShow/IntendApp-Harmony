// File: entry/src/main/ets/components/TemplateSelector.ets

import { NodeTemplate, TemplateCategory, ComponentConfig } from '../model/ComponentSystem';
import { TemplateManager } from '../services/TemplateManager';
import { ComponentRenderEngine } from '../services/ComponentRenderEngine';
import { TextComponent } from './custom/TextComponent';
import { TimeComponent } from './custom/TimeComponent';
import { ProgressComponent } from './custom/ProgressComponent';
import { StatusComponent } from './custom/StatusComponent';
import { TagComponent } from './custom/TagComponent';

/**
 * 模板选择器组件
 * 用于选择和应用节点模板
 */
@Component
export struct TemplateSelector {
  @State categories: TemplateCategory[] = [];
  @State selectedCategory: string = '';
  @State templates: NodeTemplate[] = [];
  @State selectedTemplate: NodeTemplate | null = null;
  @State showPreview: boolean = false;
  
  onTemplateSelected: (template: NodeTemplate) => void = () => {};
  onClose: () => void = () => {};

  private templateManager: TemplateManager = TemplateManager.getInstance();
  private renderEngine: ComponentRenderEngine = ComponentRenderEngine.getInstance();

  async aboutToAppear() {
    await this.loadCategories();
  }

  /**
   * 加载分类
   */
  async loadCategories() {
    try {
      this.categories = this.templateManager.getAllCategories();
      if (this.categories.length > 0) {
        this.selectedCategory = this.categories[0].id;
        await this.loadTemplates();
      }
    } catch (error) {
      console.error('[TemplateSelector] 加载分类失败:', error);
    }
  }

  /**
   * 加载模板
   */
  async loadTemplates() {
    try {
      this.templates = this.templateManager.getTemplatesByCategory(this.selectedCategory);
    } catch (error) {
      console.error('[TemplateSelector] 加载模板失败:', error);
    }
  }

  /**
   * 选择分类
   */
  onCategorySelected(categoryId: string) {
    this.selectedCategory = categoryId;
    this.loadTemplates();
    this.selectedTemplate = null;
    this.showPreview = false;
  }

  /**
   * 选择模板
   */
  onTemplateItemSelected(template: NodeTemplate) {
    this.selectedTemplate = template;
    this.showPreview = true;
  }

  /**
   * 应用模板
   */
  applyTemplate() {
    if (this.selectedTemplate) {
      this.onTemplateSelected(this.selectedTemplate);
      this.onClose();
    }
  }

  /**
   * 渲染组件预览
   */
  @Builder
  renderComponentPreview(component: ComponentConfig) {
    if (component.componentId === 'text_component') {
      TextComponent({
        text: '示例任务',
        maxLength: (component.properties.maxLength as number) || 100,
        fontSize: (component.style.fontSize as number) || 16,
        fontColor: (component.style.fontColor as string) || '#333333',
        fontWeight: (component.style.fontWeight as string) || 'normal',
        textAlign: (component.style.textAlign as string) || 'left',
        bgColor: (component.style.backgroundColor as string) || 'transparent',
        paddingValue: (component.style.padding as number) || 8,
        marginValue: (component.style.margin as number) || 4,
        borderRadiusValue: (component.style.borderRadius as number) || 4
      })
    } else if (component.componentId === 'time_component') {
      TimeComponent({
        showStartTime: (component.properties.showStartTime as boolean) !== false,
        showEndTime: (component.properties.showEndTime as boolean) !== false,
        showDuration: (component.properties.showDuration as boolean) !== false,
        timeFormat: (component.properties.timeFormat as string) || 'YYYY-MM-DD HH:mm',
        fontSize: (component.style.fontSize as number) || 14,
        fontColor: (component.style.fontColor as string) || '#666666',
        startTime: '2024-01-01 09:00',
        endTime: '2024-01-01 18:00',
        duration: '9小时'
      })
    } else if (component.componentId === 'progress_component') {
      ProgressComponent({
        showPercentage: (component.properties.showPercentage as boolean) !== false,
        showText: (component.properties.showText as boolean) !== false,
        progressText: (component.properties.progressText as string) || '进度',
        progress: 75,
        progressColor: (component.style.progressColor as string) || '#007DFF',
        bgColor: (component.style.backgroundColor as string) || '#F0F0F0',
        heightValue: (component.style.height as number) || 8,
        fontSize: (component.style.fontSize as number) || 14,
        fontColor: (component.style.fontColor as string) || '#333333'
      })
    } else if (component.componentId === 'status_component') {
      StatusComponent({
        statusType: 'progress',
        showIcon: (component.properties.showIcon as boolean) !== false,
        showText: (component.properties.showText as boolean) !== false,
        fontSize: (component.style.fontSize as number) || 14,
        fontColor: (component.style.fontColor as string) || '#333333'
      })
    } else if (component.componentId === 'tag_component') {
      TagComponent({
        tags: '重要,紧急',
        maxTags: (component.properties.maxTags as number) || 5,
        tagColor: (component.style.tagColor as string) || '#007DFF',
        textColor: (component.style.textColor as string) || '#FFFFFF',
        fontSize: (component.style.fontSize as number) || 12,
        borderRadiusValue: (component.style.borderRadius as number) || 4,
        paddingValue: (component.style.padding as number) || 6
      })
    } else {
      Text(`未知组件: ${component.componentId}`)
        .fontSize(12)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(8)
    }
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Column({ space: 8 }) {
        Row() {
          Text('🎨')
            .fontSize(24)
            .fontColor('#10B981')
          Text('选择项目模板')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2937')
            .layoutWeight(1)
          Button() {
            Text('✕')
              .fontSize(18)
              .fontColor('#6B7280')
          }
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .borderRadius(16)
          .onClick(() => {
            this.onClose();
          })
        }
        .width('100%')
        
        Text('选择适合的模板快速创建项目，每个模板都包含预设的组件和布局')
          .fontSize(14)
          .fontColor('#6B7280')
          .textAlign(TextAlign.Start)
          .width('100%')
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })

      // 分类选择
      Column({ space: 12 }) {
        Text('选择分类')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#374151')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20 })

        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.categories, (category: TemplateCategory) => {
              Button() {
                Column({ space: 8 }) {
                  Text(category.icon)
                    .fontSize(24)
                  Text(category.name)
                    .fontSize(14)
                    .fontColor(this.selectedCategory === category.id ? Color.White : '#374151')
                    .fontWeight(FontWeight.Medium)
                }
              }
              .width(80)
              .height(80)
              .backgroundColor(this.selectedCategory === category.id ? '#007DFF' : '#F9FAFB')
              .borderRadius(12)
              .border({ 
                width: this.selectedCategory === category.id ? 2 : 1, 
                color: this.selectedCategory === category.id ? '#007DFF' : '#E5E7EB',
                radius: 12 
              })
              .onClick(() => {
                this.onCategorySelected(category.id);
              })
            })
          }
          .padding({ left: 20, right: 20 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }

      // 模板列表
      Column({ space: 12 }) {
        Text('选择模板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#374151')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20 })

        if (this.templates.length === 0) {
          Column({ space: 16 }) {
            Text('📭')
              .fontSize(48)
              .opacity(0.5)
            Text('该分类下暂无模板')
              .fontSize(16)
              .fontColor('#6B7280')
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 12 }) {
            ForEach(this.templates, (template: NodeTemplate) => {
              ListItem() {
                Button() {
                  Row({ space: 16 }) {
                    // 模板图标
                    Column() {
                      Text(template.icon)
                        .fontSize(32)
                    }
                    .width(60)
                    .height(60)
                    .backgroundColor('#F0F9FF')
                    .borderRadius(12)
                    .justifyContent(FlexAlign.Center)

                    // 模板信息
                    Column({ space: 4 }) {
                      Text(template.name)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1F2937')
                        .alignSelf(ItemAlign.Start)
                      
                      Text(template.description)
                        .fontSize(14)
                        .fontColor('#6B7280')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .alignSelf(ItemAlign.Start)
                      
                      Text(`包含 ${template.components.length} 个组件`)
                        .fontSize(12)
                        .fontColor('#9CA3AF')
                        .alignSelf(ItemAlign.Start)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    // 选择按钮
                    if (this.selectedTemplate?.id === template.id) {
                      Text('✓')
                        .fontSize(20)
                        .fontColor('#10B981')
                    }
                  }
                }
                .width('100%')
                .height(80)
                .backgroundColor(this.selectedTemplate?.id === template.id ? '#F0FDF4' : '#FFFFFF')
                .borderRadius(12)
                .border({ 
                  width: this.selectedTemplate?.id === template.id ? 2 : 1, 
                  color: this.selectedTemplate?.id === template.id ? '#10B981' : '#E5E7EB',
                  radius: 12 
                })
                .onClick(() => {
                  this.onTemplateItemSelected(template);
                })
              }
            })
          }
          .width('100%')
          .height(300)
          .padding({ left: 20, right: 20 })
        }
      }

      // 预览区域
      if (this.showPreview && this.selectedTemplate) {
        Column({ space: 12 }) {
          Text('模板预览')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#374151')
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20 })

          // 预览内容
          Column({ space: 8 }) {
            ForEach(this.selectedTemplate.components, (component: ComponentConfig) => {
              Column() {
                this.renderComponentPreview(component)
              }
              .width('100%')
              .padding(8)
              .backgroundColor('#FFFFFF')
              .borderRadius(6)
              .border({ width: 1, color: '#E5E7EB', radius: 6 })
            })
          }
          .width('100%')
          .height(200)
          .backgroundColor('#F9FAFB')
          .borderRadius(8)
          .border({ width: 1, color: '#E5E7EB', radius: 8 })
          .margin({ left: 20, right: 20 })
          .padding(12)
        }
      }

      // 操作按钮
      Row({ space: 12 }) {
        Button('取消')
          .width('100%')
          .height(44)
          .backgroundColor('#F3F4F6')
          .borderRadius(8)
          .onClick(() => {
            this.onClose();
          })

        Button(this.selectedTemplate ? '创建项目' : '请先选择模板')
          .width('100%')
          .height(44)
          .backgroundColor(this.selectedTemplate ? '#10B981' : '#D1D5DB')
          .borderRadius(8)
          .enabled(!!this.selectedTemplate)
          .onClick(() => {
            this.applyTemplate();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
