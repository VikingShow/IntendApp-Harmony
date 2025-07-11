// File: entry/src/main/ets/components/CommonButton.ets

import { ThemeConfig } from '../utils/ThemeConfig';

@Component
export struct CommonButton {
  text: string = '';
  icon?: string;
  type: 'primary' | 'secondary' | 'danger' = 'primary';
  disabled: boolean = false;
  onButtonClick?: () => void;
  buttonSize: 'small' | 'medium' | 'large' = 'medium';

  @State private pressed: boolean = false;

  build() {
    Column() {
      Button() {
        Row({ space: ThemeConfig.spacingS }) {
          if (this.icon) {
            Text(this.icon)
              .fontSize(this.getIconSize())
              .fontColor(this.getTextColor())
          }
          Text(this.text)
            .fontSize(this.getFontSize())
            .fontColor(this.getTextColor())
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .height(this.getHeight())
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(ThemeConfig.radiusMedium)
      .shadow(this.pressed ? ThemeConfig.shadowSmall : ThemeConfig.shadowMedium)
      .opacity(this.disabled ? 0.5 : this.pressed ? 0.8 : 1)
      .scale({ x: this.pressed ? 0.98 : 1, y: this.pressed ? 0.98 : 1 })
      .animation({
        duration: ThemeConfig.animationFast,
        curve: Curve.EaseOut
      })
      .onClick(() => {
        if (!this.disabled && this.onButtonClick) {
          this.onButtonClick();
        }
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressed = false;
        }
      })
    }
  }

  private getBackgroundColor(): ResourceColor {
    if (this.disabled) {
      return ThemeConfig.gray200;
    }
    
    switch (this.type) {
      case 'primary': return ThemeConfig.primaryColor;
      case 'secondary': return ThemeConfig.secondaryLight;
      case 'danger': return ThemeConfig.errorColor;
      default: return ThemeConfig.primaryColor;
    }
  }

  private getTextColor(): ResourceColor {
    if (this.disabled) {
      return ThemeConfig.gray400;
    }
    
    switch (this.type) {
      case 'secondary': return ThemeConfig.gray700;
      default: return ThemeConfig.white;
    }
  }

  private getHeight(): number {
    switch (this.buttonSize) {
      case 'small': return 36;
      case 'large': return 56;
      default: return 48;
    }
  }

  private getFontSize(): number {
    switch (this.buttonSize) {
      case 'small': return ThemeConfig.fontSizeS;
      case 'large': return ThemeConfig.fontSizeL;
      default: return ThemeConfig.fontSizeM;
    }
  }

  private getIconSize(): number {
    switch (this.buttonSize) {
      case 'small': return 14;
      case 'large': return 20;
      default: return 16;
    }
  }
} 