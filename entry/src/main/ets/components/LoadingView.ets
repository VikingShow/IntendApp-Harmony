// File: entry/src/main/ets/components/LoadingView.ets

import { ThemeConfig } from '../utils/ThemeConfig';

@Component
export struct LoadingView {
  message: string = '加载中...';
  loadingSize: 'small' | 'medium' | 'large' = 'medium';
  color: ResourceColor = ThemeConfig.primaryColor;
  bgColor: ResourceColor = ThemeConfig.white;

  @State private rotation: number = 0;

  aboutToAppear() {
    // 启动旋转动画
    this.startRotation();
  }

  private startRotation() {
    // 使用新的动画API
    const animate = () => {
      this.rotation = 360;
      
      setTimeout(() => {
        this.rotation = 0;
        animate();
      }, 1000);
    };
    
    animate();
  }

  build() {
    Column() {
      // 加载动画
      Stack() {
        // 背景圆环
        Circle()
          .width(this.getSize())
          .height(this.getSize())
          .stroke(this.color)
          .strokeWidth(2)
          .fill(Color.Transparent)
        
        // 旋转的进度圆环
        Circle()
          .width(this.getSize())
          .height(this.getSize())
          .stroke(this.color)
          .strokeWidth(3)
          .fill(Color.Transparent)
          .strokeDashArray([20, 20])
          .strokeDashOffset(0)
          .rotate({ angle: this.rotation })
      }
      .width(this.getSize())
      .height(this.getSize())

      // 加载文字
      if (this.message) {
        Text(this.message)
          .fontSize(this.getFontSize())
          .fontColor(ThemeConfig.gray500)
          .margin({ top: ThemeConfig.spacingM })
          .textAlign(TextAlign.Center)
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.bgColor)
  }

  private getSize(): number {
    switch (this.loadingSize) {
      case 'small': return 32;
      case 'large': return 64;
      default: return 48;
    }
  }

  private getFontSize(): number {
    switch (this.loadingSize) {
      case 'small': return ThemeConfig.fontSizeS;
      case 'large': return ThemeConfig.fontSizeL;
      default: return ThemeConfig.fontSizeM;
    }
  }
} 