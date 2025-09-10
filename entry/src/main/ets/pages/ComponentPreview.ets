// File: entry/src/main/ets/pages/ComponentPreview.ets

import router from '@ohos.router';
import { NodeTemplate, ComponentConfig } from '../model/ComponentSystem';
import { TemplateManager } from '../services/TemplateManager';
import { ComponentRenderEngine } from '../services/ComponentRenderEngine';
import { TextComponent } from '../components/custom/TextComponent';
import { TimeComponent } from '../components/custom/TimeComponent';
import { ProgressComponent } from '../components/custom/ProgressComponent';
import { StatusComponent } from '../components/custom/StatusComponent';
import { TagComponent } from '../components/custom/TagComponent';

/**
 * 组件预览页面
 * 用于测试和预览自定义组件
 */
@Entry
@Component
struct ComponentPreviewPage {
  @State templates: NodeTemplate[] = [];
  @State selectedTemplate: NodeTemplate | null = null;
  @State showComponentList: boolean = true;
  @State sampleData: Record<string, string | number | boolean> = {};

  private templateManager: TemplateManager = TemplateManager.getInstance();
  private renderEngine: ComponentRenderEngine = ComponentRenderEngine.getInstance();

  async aboutToAppear() {
    await this.loadTemplates();
    this.initSampleData();
  }

  private initSampleData() {
    this.sampleData.id = 'preview';
    this.sampleData.name = '示例任务';
    this.sampleData.startTime = '2024-01-01 09:00:00';
    this.sampleData.endTime = '2024-01-01 18:00:00';
    this.sampleData.duration = '9小时';
    this.sampleData.progress = 75;
    this.sampleData.status = 'progress';
    this.sampleData.tags = '重要,紧急,示例';
  }

  async loadTemplates() {
    try {
      this.templates = this.templateManager.getAllTemplates();
      if (this.templates.length > 0) {
        this.selectedTemplate = this.templates[0];
      }
    } catch (error) {
      console.error('[ComponentPreview] 加载模板失败:', error);
    }
  }

  onTemplateSelected(template: NodeTemplate) {
    this.selectedTemplate = template;
    this.showComponentList = false;
  }

  onBackToList() {
    this.showComponentList = true;
    this.selectedTemplate = null;
  }

  onBackToHome() {
    router.back();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .backgroundColor('transparent')
          .onClick(() => this.onBackToHome())

        Text('组件预览')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        if (!this.showComponentList) {
          Button('返回列表')
            .fontSize(16)
            .fontColor('#007DFF')
            .backgroundColor('transparent')
            .onClick(() => this.onBackToList())
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E5E7EB' })

      if (this.showComponentList) {
        // 模板列表
        List() {
          ForEach(this.templates, (template: NodeTemplate) => {
            ListItem() {
              Row() {
                Column() {
                  Text(template.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .alignSelf(ItemAlign.Start)

                  Text(template.description)
                    .fontSize(14)
                    .fontColor('#666666')
                    .alignSelf(ItemAlign.Start)
                    .margin({ top: 4 })

                  Text(`分类: ${template.category}`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .alignSelf(ItemAlign.Start)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('预览')
                  .fontSize(14)
                  .fontColor('#007DFF')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor('#E6F7FF')
                  .borderRadius(4)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 8 })
              .onClick(() => this.onTemplateSelected(template))
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16 })
        .backgroundColor('#F8FAFC')
      } else if (this.selectedTemplate) {
        // 模板预览
        Scroll() {
          Column({ space: 16 }) {
            // 模板信息
            Column({ space: 8 }) {
              Text(this.selectedTemplate.name)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F2937')
                .alignSelf(ItemAlign.Start)

              Text(this.selectedTemplate.description)
                .fontSize(14)
                .fontColor('#6B7280')
                .alignSelf(ItemAlign.Start)

              Text(`分类: ${this.selectedTemplate.category}`)
                .fontSize(12)
                .fontColor('#9CA3AF')
                .alignSelf(ItemAlign.Start)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#F9FAFB')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Start)

            // 组件预览标题
            Text('组件预览')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#374151')
              .alignSelf(ItemAlign.Start)
              .margin({ left: 20 })

            // 渲染组件
            Column({ space: 8 }) {
              ForEach(this.selectedTemplate.components, (component: ComponentConfig) => {
                Column() {
                  this.renderComponent(component, this.sampleData)
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .border({ width: 1, color: '#E5E7EB', radius: 8 })
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .border({ width: 1, color: '#E5E7EB', radius: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        }
        .layoutWeight(1)
        .backgroundColor('#F8FAFC')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFC')
  }

  @Builder
  renderComponent(component: ComponentConfig, data: Record<string, string | number | boolean>) {
    if (component.componentId === 'text_component') {
      TextComponent({
        text: (data.name as string) || '示例文本',
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
        startTime: (data.startTime as string) || '',
        endTime: (data.endTime as string) || '',
        duration: (data.duration as string) || ''
      })
    } else if (component.componentId === 'progress_component') {
      ProgressComponent({
        showPercentage: (component.properties.showPercentage as boolean) !== false,
        showText: (component.properties.showText as boolean) !== false,
        progressText: (component.properties.progressText as string) || '进度',
        progress: (data.progress as number) || 0,
        progressColor: (component.style.progressColor as string) || '#007DFF',
        bgColor: (component.style.backgroundColor as string) || '#F0F0F0',
        heightValue: (component.style.height as number) || 8,
        fontSize: (component.style.fontSize as number) || 14,
        fontColor: (component.style.fontColor as string) || '#333333'
      })
    } else if (component.componentId === 'status_component') {
      StatusComponent({
        statusType: (data.status as string) || (component.properties.statusType as string) || 'progress',
        showIcon: (component.properties.showIcon as boolean) !== false,
        showText: (component.properties.showText as boolean) !== false,
        fontSize: (component.style.fontSize as number) || 14,
        fontColor: (component.style.fontColor as string) || '#333333'
      })
    } else if (component.componentId === 'tag_component') {
      TagComponent({
        tags: (data.tags as string) || (component.properties.tags as string) || '重要,紧急',
        maxTags: (component.properties.maxTags as number) || 5,
        tagColor: (component.style.tagColor as string) || '#007DFF',
        textColor: (component.style.textColor as string) || '#FFFFFF',
        fontSize: (component.style.fontSize as number) || 12,
        borderRadiusValue: (component.style.borderRadius as number) || 4,
        paddingValue: (component.style.padding as number) || 6
      })
    } else {
      Text(`未知组件: ${component.componentId}`)
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(16)
    }
  }
}