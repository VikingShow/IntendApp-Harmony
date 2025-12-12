// File: entry/src/main/ets/components/ColorPicker.ets
/**
 * 专业级HSV调色盘组件
 * 提供色相环 + 饱和度/明度选择器
 */

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

interface RGB {
  r: number;
  g: number;
  b: number;
}

interface HSV {
  h: number;
  s: number;
  v: number;
}

@Component
export struct ColorSelector {
  @Link selectedColor: string;
  @State hue: number = 0;
  @State saturation: number = 100;
  @State value: number = 100;
  private isUpdating: boolean = false;
  
  aboutToAppear() {
    this.syncFromColor();
  }

  private syncFromColor() {
    const rgb = this.hexToRgb(this.selectedColor);
    if (rgb) {
      const hsv = this.rgbToHsv(rgb.r, rgb.g, rgb.b);
      this.hue = hsv.h;
      this.saturation = hsv.s;
      this.value = hsv.v;
    }
  }

  private hexToRgb(hex: string): RGB | null {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
    } : null;
  }

  private rgbToHsv(r: number, g: number, b: number): HSV {
    r = r / 255;
    g = g / 255;
    b = b / 255;
    
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const delta = max - min;
    
    let h = 0;
    const s = max === 0 ? 0 : (delta / max) * 100;
    const v = max * 100;
    
    if (delta !== 0) {
      if (max === r) {
        h = 60 * (((g - b) / delta) % 6);
      } else if (max === g) {
        h = 60 * (((b - r) / delta) + 2);
      } else {
        h = 60 * (((r - g) / delta) + 4);
      }
    }
    
    if (h < 0) h += 360;
    
    return { h, s, v };
  }

  private hsvToRgb(h: number, s: number, v: number): RGB {
    s = s / 100;
    v = v / 100;
    
    const c = v * s;
    const x = c * (1 - Math.abs((h / 60) % 2 - 1));
    const m = v - c;
    
    let r = 0, g = 0, b = 0;
    
    if (h >= 0 && h < 60) {
      r = c; g = x; b = 0;
    } else if (h >= 60 && h < 120) {
      r = x; g = c; b = 0;
    } else if (h >= 120 && h < 180) {
      r = 0; g = c; b = x;
    } else if (h >= 180 && h < 240) {
      r = 0; g = x; b = c;
    } else if (h >= 240 && h < 300) {
      r = x; g = 0; b = c;
    } else {
      r = c; g = 0; b = x;
    }
    
    return {
      r: Math.round((r + m) * 255),
      g: Math.round((g + m) * 255),
      b: Math.round((b + m) * 255)
    };
  }

  private rgbToHex(r: number, g: number, b: number): string {
    return '#' + 
      r.toString(16).padStart(2, '0') +
      g.toString(16).padStart(2, '0') +
      b.toString(16).padStart(2, '0');
  }

  private updateColor() {
    this.isUpdating = true;
    const rgb = this.hsvToRgb(this.hue, this.saturation, this.value);
    this.selectedColor = this.rgbToHex(rgb.r, rgb.g, rgb.b).toUpperCase();
    setTimeout(() => {
      this.isUpdating = false;
    }, 50);
  }

  build() {
    Column({ space: 16 }) {
      // 色相条
      Column({ space: 8 }) {
        Text('色相')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textSecondary);
        
        Stack() {
          // 渐变背景
          Row()
            .width('100%')
            .height(24)
            .borderRadius(12)
            .linearGradient({
              angle: 90,
              colors: [
                [0xFF0000, 0.0],
                [0xFFFF00, 0.17],
                [0x00FF00, 0.33],
                [0x00FFFF, 0.5],
                [0x0000FF, 0.67],
                [0xFF00FF, 0.83],
                [0xFF0000, 1.0]
              ]
            });
          
          // 滑块
          Circle()
            .width(20)
            .height(20)
            .fill(Color.White)
            .stroke(ColorResource.surfaceEmphasized)
            .strokeWidth(2)
            .position({ x: `${(this.hue / 360) * 100}%`, y: 2 });
        }
        .width('100%')
        .height(24)
        .gesture(
          PanGesture()
            .onActionUpdate((event: GestureEvent) => {
              const x = event.offsetX;
              const width = 280;
              this.hue = Math.max(0, Math.min(360, (x / width) * 360));
              this.updateColor();
            })
        );
      }

      // 饱和度
      Column({ space: 8 }) {
        Text('饱和度')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textSecondary);
        
        Slider({
          value: this.saturation,
          min: 0,
          max: 100,
          step: 1
        })
          .width('100%')
          .trackColor(ColorResource.backgroundSecondary)
          .selectedColor(ColorResource.primaryColor)
          .onChange((value: number) => {
            this.saturation = value;
            this.updateColor();
          });
      }

      // 明度
      Column({ space: 8 }) {
        Text('明度')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textSecondary);
        
        Slider({
          value: this.value,
          min: 0,
          max: 100,
          step: 1
        })
          .width('100%')
          .trackColor(ColorResource.backgroundSecondary)
          .selectedColor(ColorResource.primaryColor)
          .onChange((value: number) => {
            this.value = value;
            this.updateColor();
          });
      }

      // 当前颜色预览
      Row({ space: 12 }) {
        Column()
          .width(60)
          .height(60)
          .backgroundColor(this.selectedColor)
          .borderRadius(8)
          .border({ width: 1, color: ColorResource.surfaceEmphasized });
        
        Column({ space: 4 }) {
          Text(this.selectedColor)
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary);
          
          Text(`H:${Math.round(this.hue)}° S:${Math.round(this.saturation)}% V:${Math.round(this.value)}%`)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textSecondary);
        }
        .alignItems(HorizontalAlign.Start);
      }
    }
    .width('100%')
  }
}
