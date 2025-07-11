// File: entry/src/main/ets/components/TemplateDialog.ets

import { TemplateService, ProjectTemplate } from '../services/TemplateService';
import { CommonButton } from './CommonButton';
import { ThemeConfig } from '../utils/ThemeConfig';

@Component
export struct TemplateDialog {
  visible: boolean = false;
  onClose: () => void = () => {};
  onTemplateSelected: (templateId: string, projectName: string) => void = () => {};

  @State selectedTemplate: ProjectTemplate | null = null;
  @State projectName: string = '';
  @State selectedCategory: string = 'development';

  private templateService: TemplateService = TemplateService.getInstance();

  build() {
    if (this.visible) {
      Column() {
        // 标题
        Row({ space: ThemeConfig.spacingM }) {
          Text('📋')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontColor(ThemeConfig.primaryColor)
          Text('选择项目模板')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeConfig.gray800)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(ThemeConfig.spacingL)
        .alignItems(VerticalAlign.Center)

        // 分类选择
        Column({ space: ThemeConfig.spacingM }) {
          Text('项目类型')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeConfig.gray800)

          Row({ space: ThemeConfig.spacingS }) {
            ForEach(['development', 'design', 'marketing'], (category: string) => {
              Button() {
                Text(this.getCategoryName(category))
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(this.selectedCategory === category ? Color.White : ThemeConfig.gray700)
              }
              .height(32)
              .backgroundColor(this.selectedCategory === category ? ThemeConfig.primaryColor : ThemeConfig.gray100)
              .borderRadius(ThemeConfig.radiusSmall)
              .onClick(() => {
                this.selectedCategory = category;
              })
            })
          }
          .width('100%')
        }
        .padding(ThemeConfig.spacingL)

        // 模板列表
        Column({ space: ThemeConfig.spacingM }) {
          Text('可用模板')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeConfig.gray800)

          List({ space: ThemeConfig.spacingS }) {
            ForEach(this.getTemplatesByCategory(), (template: ProjectTemplate) => {
              ListItem() {
                this.TemplateCard(template)
              }
            })
          }
          .layoutWeight(1)
        }
        .padding(ThemeConfig.spacingL)

        // 项目名称输入
        if (this.selectedTemplate) {
          Column({ space: ThemeConfig.spacingS }) {
            Text('项目名称')
              .fontSize(ThemeConfig.fontSizeM)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeConfig.gray800)

            TextInput({ 
              placeholder: '请输入项目名称',
              text: this.projectName 
            })
              .backgroundColor(ThemeConfig.gray50)
              .borderRadius(ThemeConfig.radiusMedium)
              .padding(ThemeConfig.spacingM)
              .onChange((value: string) => {
                this.projectName = value;
              })
          }
          .padding(ThemeConfig.spacingL)
        }

        // 底部按钮
        Row({ space: ThemeConfig.spacingM }) {
          CommonButton({
            text: '取消',
            type: 'secondary',
            onButtonClick: () => {
              this.onClose();
            }
          })
          .layoutWeight(1)

          if (this.selectedTemplate && this.projectName.trim()) {
            CommonButton({
              text: '创建项目',
              type: 'primary',
              onButtonClick: () => {
                this.createProject();
              }
            })
            .layoutWeight(1)
            .height(52)
            .padding({ top: 8, bottom: 8 })
          }
        }
        .padding(ThemeConfig.spacingL)
      }
      .width('100%')
      .backgroundColor(ThemeConfig.white)
      .borderRadius(ThemeConfig.radiusLarge)
      .shadow(ThemeConfig.shadowLarge)
      .margin(ThemeConfig.spacingL)
    }
  }

  @Builder
  TemplateCard(template: ProjectTemplate) {
    Row({ space: ThemeConfig.spacingM }) {
      // 模板图标
      Column() {
        Text(this.getCategoryIcon(template.category))
          .fontSize(ThemeConfig.fontSizeL)
      }
      .width(48)
      .height(48)
      .backgroundColor(this.getCategoryColor(template.category))
      .justifyContent(FlexAlign.Center)
      .borderRadius(ThemeConfig.radiusMedium)

      // 模板信息
      Column({ space: ThemeConfig.spacingXS }) {
        Text(template.name)
          .fontSize(ThemeConfig.fontSizeM)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeConfig.gray800)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(template.description)
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ThemeConfig.gray600)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(`${template.tasks.length} 个任务`)
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ThemeConfig.gray500)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(ThemeConfig.spacingM)
    .backgroundColor(this.selectedTemplate?.id === template.id ? ThemeConfig.primaryLight : ThemeConfig.white)
    .borderRadius(ThemeConfig.radiusMedium)
    .border({ 
      width: this.selectedTemplate?.id === template.id ? 2 : 1, 
      color: this.selectedTemplate?.id === template.id ? ThemeConfig.primaryColor : ThemeConfig.gray200, 
      radius: ThemeConfig.radiusMedium 
    })
    .onClick(() => {
      if (this.selectedTemplate?.id === template.id && this.projectName.trim()) {
        this.createProject();
      } else {
        this.selectedTemplate = template;
      }
    })
  }

  private getTemplatesByCategory(): ProjectTemplate[] {
    return this.templateService.getTemplatesByCategory(this.selectedCategory);
  }

  private getCategoryName(category: string): string {
    switch (category) {
      case 'development': return '开发';
      case 'design': return '设计';
      case 'marketing': return '营销';
      case 'research': return '研究';
      case 'other': return '其他';
      default: return '其他';
    }
  }

  private getCategoryIcon(category: string): string {
    switch (category) {
      case 'development': return '💻';
      case 'design': return '🎨';
      case 'marketing': return '📢';
      case 'research': return '🔬';
      case 'other': return '📋';
      default: return '📋';
    }
  }

  private getCategoryColor(category: string): ResourceColor {
    switch (category) {
      case 'development': return '#3B82F6';
      case 'design': return '#8B5CF6';
      case 'marketing': return '#F59E0B';
      case 'research': return '#10B981';
      case 'other': return '#6B7280';
      default: return '#6B7280';
    }
  }

  private createProject() {
    if (this.selectedTemplate && this.projectName.trim()) {
      this.onTemplateSelected(this.selectedTemplate.id, this.projectName.trim());
      this.onClose();
    }
  }
} 