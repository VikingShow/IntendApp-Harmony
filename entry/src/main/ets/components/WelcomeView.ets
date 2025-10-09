// File: entry/src/main/ets/components/WelcomeView.ets

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

@Component
export struct WelcomeView {
  build() {
    Stack() {
      // 背景层 - 中国古代文化词汇
      // this.CulturalWordsBackground()
      
      // 主要内容层 - 铺满整个区域
      Column({ space: 32 }) {
        // 中心标题 - 增强视觉层次
        Column({ space: 20 }) {
          Text('一思不漏')
            .fontSize(ThemeConfig.fontSizeXXXXXXXL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.primaryColor)
            .textAlign(TextAlign.Center)
            .shadow({ radius: 4, color: ColorResource.hoverPrimaryLight, offsetX: 0, offsetY: 4 })
          Text('EazyFlow')
            .fontSize(ThemeConfig.fontSizeXXXL)
            .fontColor(ColorResource.surfaceBold)
            .fontWeight(ThemeConfig.fontWeightMedium)
            .textAlign(TextAlign.Center)
            // .shadow({ radius: 2, color: ThemeConfig.gray600 + '20', offsetX: 0, offsetY: 2 })
            .margin({ top: ThemeConfig.spacingS })
          Text('让每个想法都不被遗漏，让每个项目都井然有序')
            .fontSize(ThemeConfig.fontSizeL)
            .fontColor(ColorResource.surfaceEmphasized)
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
    .backgroundColor(ColorResource.backgroundPrimary)
  }

  // @Builder
  // CulturalWordsBackground() {
  //   Stack() {
  //     // 文化词汇 - 不同大小和位置
  //     this.CulturalWord('智慧', 24, 0.15, 0.2, ThemeConfig.culturalWord1)
  //     this.CulturalWord('创新', 20, 0.8, 0.15, ThemeConfig.culturalWord2)
  //     this.CulturalWord('专注', 18, 0.1, 0.7, ThemeConfig.culturalWord3)
  //     this.CulturalWord('效率', 22, 0.85, 0.8, ThemeConfig.culturalWord4)
  //     this.CulturalWord('协作', 16, 0.3, 0.1, ThemeConfig.culturalWord5)
  //     this.CulturalWord('规划', 19, 0.7, 0.3, ThemeConfig.culturalWord6)
  //     this.CulturalWord('执行', 17, 0.2, 0.9, ThemeConfig.culturalWord7)
  //     this.CulturalWord('成果', 21, 0.9, 0.6, ThemeConfig.culturalWord8)
  //     this.CulturalWord('管理', 23, 0.05, 0.5, ThemeConfig.culturalWord9)
  //     this.CulturalWord('团队', 18, 0.6, 0.05, ThemeConfig.culturalWord10)
  //
  //     // 连接线
  //     this.ConnectionLines()
  //   }
  //   .width('100%')
  //   .height('100%')
  // }
  //
  // @Builder
  // CulturalWord(text: string, fontSize: number, x: number, y: number, color: string) {
  //   Text(text)
  //     .fontSize(fontSize)
  //     .fontColor(color)
  //     .fontWeight(FontWeight.Medium)
  //     .position({ x: `${x * 100}%`, y: `${y * 100}%` })
  //     .opacity(0.6)
  // }
  //
  // @Builder
  // ConnectionLines() {
  //   // 连接线 - 使用简单的线条组件
  //   Stack() {
  //     // 连接线1: 智慧 -> 创新
  //     Line()
  //       .startPoint([150, 200])
  //       .endPoint([800, 150])
  //       .stroke(ThemeConfig.culturalWord1)
  //       .strokeWidth(1)
  //       .opacity(0.3)
  //
  //     // 连接线2: 专注 -> 效率
  //     Line()
  //       .startPoint([100, 700])
  //       .endPoint([850, 800])
  //       .stroke(ThemeConfig.culturalWord1)
  //       .strokeWidth(1)
  //       .opacity(0.3)
  //
  //     // 连接线3: 协作 -> 规划
  //     Line()
  //       .startPoint([300, 100])
  //       .endPoint([700, 300])
  //       .stroke(ThemeConfig.culturalWord1)
  //       .strokeWidth(1)
  //       .opacity(0.3)
  //
  //     // 连接线4: 执行 -> 成果
  //     Line()
  //       .startPoint([200, 900])
  //       .endPoint([900, 600])
  //       .stroke(ThemeConfig.culturalWord1)
  //       .strokeWidth(1)
  //       .opacity(0.3)
  //
  //     // 连接线5: 管理 -> 团队
  //     Line()
  //       .startPoint([50, 500])
  //       .endPoint([600, 50])
  //       .stroke(ThemeConfig.culturalWord1)
  //       .strokeWidth(1)
  //       .opacity(0.3)
  //   }
  //   .width('100%')
  //   .height('100%')
  // }

}

