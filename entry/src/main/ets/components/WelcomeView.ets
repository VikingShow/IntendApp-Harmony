// File: entry/src/main/ets/components/WelcomeView.ets

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { BreakpointSystem } from '../utils/BreakpointSystem';

@Component
export struct WelcomeView {
  @State private screenWidth: number = 0;
  onShowTutorialSettings?: () => void;

  aboutToAppear() {
    this.updateScreenSize();
  }

  private updateScreenSize() {
    try {
      const uiContext = this.getUIContext();
      // 使用默认值避免类型问题
      this.screenWidth = 840;
    } catch (error) {
      this.screenWidth = 840;
    }
  }

  build() {
    Stack() {
      // 主要内容层 - 铺满整个区域
      Column({ space: BreakpointSystem.getResponsiveSpacing(24, this.screenWidth) }) {
        // 中心标题 - 紧凑视觉层次
        Column({ space: BreakpointSystem.getResponsiveSpacing(16, this.screenWidth) }) {
          Text('一思不漏')
            .fontSize(BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXXXL, this.screenWidth))
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.primaryColor)
            .textAlign(TextAlign.Center)
          Text('EazyFlow')
            .fontSize(BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXL, this.screenWidth))
            .fontColor(ColorResource.surfaceBold)
            .fontWeight(ThemeConfig.fontWeightMedium)
            .textAlign(TextAlign.Center)
            .margin({ top: ThemeConfig.spacingXS })
          Text('"君子终日乾乾。夕惕若，厉无咎。"')
            .fontSize(BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeM, this.screenWidth))
            .fontColor(ColorResource.surfaceEmphasized)
            .textAlign(TextAlign.Center)
            .lineHeight(BreakpointSystem.getResponsiveSpacing(22, this.screenWidth))
            .fontWeight(ThemeConfig.fontWeightMedium)
            .margin({ top: ThemeConfig.spacingM })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ 
        left: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXL, this.screenWidth), 
        right: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXL, this.screenWidth), 
        top: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXXL, this.screenWidth), 
        bottom: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXXL, this.screenWidth) 
      })
      
      // 帮助按钮 - 右下角
      if (this.onShowTutorialSettings) {
        Button() {
          Text('?')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(48)
        .height(48)
        .type(ButtonType.Circle)
        .backgroundColor(ColorResource.primaryColor)
        .position({ x: '100%', y: '100%' })
        .translate({ x: -64, y: -64 })
        .shadow({
          radius: 12,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          if (this.onShowTutorialSettings) {
            this.onShowTutorialSettings();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPrimary)
  }
}

