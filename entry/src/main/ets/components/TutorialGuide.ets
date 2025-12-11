import { TutorialStep } from '../services/TutorialService';
import { ColorResource } from '../utils/ThemeConfig';

interface HighlightRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface ComponentPosition {
  left: number;
  top: number;
  width: number;
  height: number;
}

@Component
export struct TutorialGuide {
  @Prop currentStep: TutorialStep | null = null;
  @Prop currentStepIndex: number = 0;
  @Prop totalSteps: number = 0;
  @Prop isDarkMode: boolean = true;
  @State highlightRect: HighlightRect | null = null;
  onNext: () => void = () => {};
  onPrevious: () => void = () => {};
  onSkip: () => void = () => {};
  onFinish: () => void = () => {};
  
  @State tooltipX: number = 0;
  @State tooltipY: number = 0;
  @State tooltipWidth: number = 280;

  aboutToAppear() {
    console.log('[TutorialGuide] aboutToAppear, currentStep:', JSON.stringify(this.currentStep));
    if (this.currentStep?.targetId) {
      this.updateHighlightPosition();
    }
  }

  aboutToUpdate() {
    if (this.currentStep?.targetId) {
      setTimeout(() => {
        this.updateHighlightPosition();
      }, 100);
    }
  }

  private updateHighlightPosition() {
    if (!this.currentStep?.targetId) {
      this.highlightRect = null;
      return;
    }

    try {
      const componentInfo = this.getUIContext().getComponentUtils()
        .getRectangleById(this.currentStep.targetId);
      
      if (componentInfo && componentInfo.size && componentInfo.localOffset) {
        const padding = this.currentStep.highlightPadding || 8;
        const position: ComponentPosition = {
          left: componentInfo.localOffset.x,
          top: componentInfo.localOffset.y,
          width: componentInfo.size.width,
          height: componentInfo.size.height
        };
        
        this.highlightRect = {
          x: position.left - padding,
          y: position.top - padding,
          width: position.width + padding * 2,
          height: position.height + padding * 2
        };
        
        this.calculateTooltipPosition(position, padding);
      }
    } catch (error) {
      console.error('[TutorialGuide] Failed to get component position:', error);
      this.highlightRect = null;
    }
  }

  private calculateTooltipPosition(
    componentInfo: ComponentPosition,
    padding: number
  ): void {
    const screenWidth = 360;
    const screenHeight = 780;
    const tooltipHeight = 200;
    const margin = 16;

    switch (this.currentStep?.position) {
      case 'top':
        this.tooltipX = componentInfo.left + componentInfo.width / 2 - this.tooltipWidth / 2;
        this.tooltipY = componentInfo.top - tooltipHeight - margin - padding;
        break;
      case 'bottom':
        this.tooltipX = componentInfo.left + componentInfo.width / 2 - this.tooltipWidth / 2;
        this.tooltipY = componentInfo.top + componentInfo.height + margin + padding;
        break;
      case 'left':
        this.tooltipX = componentInfo.left - this.tooltipWidth - margin - padding;
        this.tooltipY = componentInfo.top + componentInfo.height / 2 - tooltipHeight / 2;
        break;
      case 'right':
        this.tooltipX = componentInfo.left + componentInfo.width + margin + padding;
        this.tooltipY = componentInfo.top + componentInfo.height / 2 - tooltipHeight / 2;
        break;
      default:
        this.tooltipX = (screenWidth - this.tooltipWidth) / 2;
        this.tooltipY = (screenHeight - tooltipHeight) / 2;
    }

    if (this.tooltipX < margin) this.tooltipX = margin;
    if (this.tooltipX + this.tooltipWidth > screenWidth - margin) {
      this.tooltipX = screenWidth - this.tooltipWidth - margin;
    }
    if (this.tooltipY < margin) this.tooltipY = margin;
    if (this.tooltipY + tooltipHeight > screenHeight - margin) {
      this.tooltipY = screenHeight - tooltipHeight - margin;
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (!this.currentStep) {
        Column()
          .width(0)
          .height(0)
      } else {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.7)')
        .onClick(() => {})

      if (this.highlightRect) {
        Column()
          .position({ x: this.highlightRect.x, y: this.highlightRect.y })
          .width(this.highlightRect.width)
          .height(this.highlightRect.height)
          .borderRadius(12)
          .border({
            width: 3,
            color: ColorResource.primaryColor,
            style: BorderStyle.Solid
          })
          .backgroundColor('rgba(255, 255, 255, 0.05)')
          .shadow({
            radius: 20,
            color: ColorResource.primaryColor,
            offsetX: 0,
            offsetY: 0
          })
          .animation({
            duration: 300,
            curve: Curve.EaseInOut
          })
      }

      Column({ space: 16 }) {
        Column({ space: 8 }) {
          Text(this.currentStep.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDarkMode ? Color.White : '#1A1A1A')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text(this.currentStep.description)
            .fontSize(15)
            .fontColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.95)' : 'rgba(26, 26, 26, 0.85)')
            .lineHeight(22)
            .maxLines(5)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Row({ space: 8 }) {
          Text(`${this.currentStepIndex + 1} / ${this.totalSteps}`)
            .fontSize(13)
            .fontColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.7)' : 'rgba(26, 26, 26, 0.6)')
            .layoutWeight(1)

          if (this.currentStep.showSkip && this.currentStepIndex === 0) {
            Button('跳过')
              .fontSize(14)
              .height(36)
              .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.15)' : 'rgba(0, 0, 0, 0.08)')
              .fontColor(this.isDarkMode ? Color.White : '#1A1A1A')
              .onClick(() => this.onSkip())
          }

          if (this.currentStepIndex > 0) {
            Button('上一步')
              .fontSize(14)
              .height(36)
              .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.15)' : 'rgba(0, 0, 0, 0.08)')
              .fontColor(this.isDarkMode ? Color.White : '#1A1A1A')
              .onClick(() => this.onPrevious())
          }

          if (this.currentStepIndex < this.totalSteps - 1) {
            Button('下一步')
              .fontSize(14)
              .height(36)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .onClick(() => this.onNext())
          } else {
            Button('完成')
              .fontSize(14)
              .height(36)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .onClick(() => this.onFinish())
          }
        }
        .width('100%')
      }
      .padding(20)
      .width(this.currentStep.position === 'center' ? '85%' : this.tooltipWidth)
      .constraintSize({ maxWidth: this.currentStep.position === 'center' ? 320 : this.tooltipWidth })
      .backgroundColor(this.isDarkMode ? '#2D2D2D' : '#FFFFFF')
      .borderRadius(16)
      .shadow({
        radius: 24,
        color: this.isDarkMode ? 'rgba(0, 0, 0, 0.4)' : 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 8
      })
      .border({
        width: 1,
        color: this.isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        radius: 16
      })
      .position(
        this.currentStep.position === 'center'
          ? { x: '50%', y: '50%' }
          : { x: this.tooltipX, y: this.tooltipY }
      )
      .translate(
        this.currentStep.position === 'center'
          ? { x: '-50%', y: '-50%' }
          : { x: 0, y: 0 }
      )
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
      }
    }
    .width('100%')
    .height('100%')
  }
}

@CustomDialog
export struct TutorialWelcomeDialog {
  controller: CustomDialogController;
  onStart: () => void = () => {};
  onNeverShowAgain: (checked: boolean) => void = () => {};
  @State neverShowChecked: boolean = false;

  build() {
    Column({ space: 0 }) {
      Column({ space: 12 }) {
        Text('👋 欢迎使用 EasyFlow')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorResource.textPrimary)

        Text('首次使用？让我们通过简短的教程，帮助您快速上手 EasyFlow 的主要功能。')
          .fontSize(15)
          .fontColor(ColorResource.textSecondary)
          .lineHeight(22)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 32, left: 24, right: 24, bottom: 24 })

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)

      Row({ space: 8 }) {
        Checkbox({ name: 'neverShow' })
          .select(this.neverShowChecked)
          .onChange((value: boolean) => {
            this.neverShowChecked = value;
          })
          .width(20)
          .height(20)

        Text('不再提醒')
          .fontSize(14)
          .fontColor(ColorResource.textSecondary)
          .onClick(() => {
            this.neverShowChecked = !this.neverShowChecked;
          })
      }
      .padding({ left: 24, right: 24, top: 16, bottom: 16 })
      .width('100%')

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)

      Row({ space: 0 }) {
        Button('稍后')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.textSecondary)
          .borderRadius(0)
          .onClick(() => {
            this.onNeverShowAgain(this.neverShowChecked);
            this.controller.close();
          })

        Divider()
          .vertical(true)
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3)
          .height(48)

        Button('开始教程')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Medium)
          .borderRadius(0)
          .onClick(() => {
            this.onNeverShowAgain(this.neverShowChecked);
            this.onStart();
            this.controller.close();
          })
      }
      .width('100%')
    }
    .width('85%')
    .constraintSize({ maxWidth: 320 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14)
    .shadow({
      radius: 24,
      color: 'rgba(0, 0, 0, 0.12)',
      offsetX: 0,
      offsetY: 4
    })
  }
}
