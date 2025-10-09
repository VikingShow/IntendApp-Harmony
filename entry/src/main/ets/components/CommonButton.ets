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
            .fontWeight(ThemeConfig.fontWeightMedium)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(this.getHeight())
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(this.getBorderRadius())
      .shadow(this.pressed ? ThemeConfig.shadowSmall : ThemeConfig.buttonShadow)
      .opacity(this.disabled ? 0.5 : this.pressed ? 0.9 : 1)
      .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
      .animation({
        duration: ThemeConfig.animationFast,
        curve: ThemeConfig.animationEaseOut
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
      return ThemeConfig.surfaceNeutral;
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
      return ThemeConfig.surfaceStrong;
    }
    
    switch (this.type) {
      case 'secondary': return ThemeConfig.surfaceDark;
      default: return ThemeConfig.surface;
    }
  }

  private getHeight(): number {
    switch (this.buttonSize) {
      case 'small': return ThemeConfig.buttonHeightSmall;
      case 'large': return ThemeConfig.buttonHeightLarge;
      default: return ThemeConfig.buttonHeightMedium;
    }
  }

  private getBorderRadius(): number {
    switch (this.buttonSize) {
      case 'small': return ThemeConfig.radiusSmall;
      case 'large': return ThemeConfig.radiusLarge;
      default: return ThemeConfig.radiusMedium;
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