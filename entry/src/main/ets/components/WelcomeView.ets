// File: entry/src/main/ets/components/WelcomeView.ets

import { ThemeConfig } from '../utils/ThemeConfig';

@Component
export struct WelcomeView {
  build() {
    Stack() {
      // 背景层 - 中国古代文化词汇
      this.CulturalWordsBackground()
      
      // 主要内容层 - 铺满整个区域
      Column({ space: 32 }) {
        // 中心标题 - 增强视觉层次
        Column({ space: 20 }) {
          Text('一思不漏')
            .fontSize(ThemeConfig.fontSizeXXXXXXXL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ThemeConfig.primaryColor)
            .textAlign(TextAlign.Center)
            .shadow({ radius: 4, color: ThemeConfig.primaryColor + '30', offsetX: 0, offsetY: 4 })
          Text('EazyFlow')
            .fontSize(ThemeConfig.fontSizeXXXL)
            .fontColor(ThemeConfig.gray600)
            .fontWeight(ThemeConfig.fontWeightMedium)
            .textAlign(TextAlign.Center)
            // .shadow({ radius: 2, color: ThemeConfig.gray600 + '20', offsetX: 0, offsetY: 2 })
            .margin({ top: ThemeConfig.spacingS })
          Text('让每个想法都不被遗漏，让每个项目都井然有序')
            .fontSize(ThemeConfig.fontSizeL)
            .fontColor(ThemeConfig.gray500)
            .textAlign(TextAlign.Center)
            .lineHeight(28)
            .fontWeight(ThemeConfig.fontWeightMedium)
            .margin({ top: ThemeConfig.spacingL })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: ThemeConfig.spacingXL, right: ThemeConfig.spacingXL, top: ThemeConfig.spacingXXXXL, bottom: ThemeConfig.spacingXXXXL })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeConfig.backgroundSecondary)
  }

  @Builder
  CulturalWordsBackground() {
    Stack() {
      // 文化词汇 - 不同大小和位置
      this.CulturalWord('智慧', 24, 0.15, 0.2, '#E2E8F0')
      this.CulturalWord('创新', 20, 0.8, 0.15, '#CBD5E1')
      this.CulturalWord('专注', 18, 0.1, 0.7, '#D1D5DB')
      this.CulturalWord('效率', 22, 0.85, 0.8, '#E5E7EB')
      this.CulturalWord('协作', 16, 0.3, 0.1, '#F3F4F6')
      this.CulturalWord('规划', 19, 0.7, 0.3, '#F1F5F9')
      this.CulturalWord('执行', 17, 0.2, 0.9, '#F8FAFC')
      this.CulturalWord('成果', 21, 0.9, 0.6, '#F9FAFB')
      this.CulturalWord('管理', 23, 0.05, 0.5, '#FAFBFC')
      this.CulturalWord('团队', 18, 0.6, 0.05, '#FCFCFD')
      
      // 连接线
      this.ConnectionLines()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CulturalWord(text: string, fontSize: number, x: number, y: number, color: string) {
    Text(text)
      .fontSize(fontSize)
      .fontColor(color)
      .fontWeight(FontWeight.Medium)
      .position({ x: `${x * 100}%`, y: `${y * 100}%` })
      .opacity(0.6)
  }

  @Builder
  ConnectionLines() {
    // 连接线 - 使用简单的线条组件
    Stack() {
      // 连接线1: 智慧 -> 创新
      Line()
        .startPoint([150, 200])
        .endPoint([800, 150])
        .stroke('#E2E8F0')
        .strokeWidth(1)
        .opacity(0.3)
      
      // 连接线2: 专注 -> 效率
      Line()
        .startPoint([100, 700])
        .endPoint([850, 800])
        .stroke('#E2E8F0')
        .strokeWidth(1)
        .opacity(0.3)
      
      // 连接线3: 协作 -> 规划
      Line()
        .startPoint([300, 100])
        .endPoint([700, 300])
        .stroke('#E2E8F0')
        .strokeWidth(1)
        .opacity(0.3)
      
      // 连接线4: 执行 -> 成果
      Line()
        .startPoint([200, 900])
        .endPoint([900, 600])
        .stroke('#E2E8F0')
        .strokeWidth(1)
        .opacity(0.3)
      
      // 连接线5: 管理 -> 团队
      Line()
        .startPoint([50, 500])
        .endPoint([600, 50])
        .stroke('#E2E8F0')
        .strokeWidth(1)
        .opacity(0.3)
    }
    .width('100%')
    .height('100%')
  }

}

// 新建方式选择弹窗
@Component
export struct NewProjectDialog {
  onBlank: () => void = () => {};
  onTemplate: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('新建项目')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button() {
          Text('×').fontSize(20)
        }
        .onClick(() => this.onClose())
      }
      .padding({ left: 24, right: 24, top: 24, bottom: 12 })

      Button() {
        Text('新建空白图').fontSize(16).fontColor(Color.White)
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('sys.color.brand'))
      .borderRadius(8)
      .margin({ top: 12 })
      .onClick(() => this.onBlank())

      Button() {
        Text('选择模板').fontSize(16).fontColor($r('sys.color.brand'))
      }
      .width('100%')
      .height(48)
      .backgroundColor('#F3F4F6')
      .borderRadius(8)
      .margin({ top: 12 })
      .onClick(() => this.onTemplate())
    }
    .width(320)
    .backgroundColor('#FFF')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#00000020', offsetX: 0, offsetY: 8 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
