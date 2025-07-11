// File: entry/src/main/ets/components/LoadingView.ets

@Component
export struct LoadingView {
  message: string = '加载中...';

  build() {
    Column({ space: 16 }) {
      // 加载动画
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#007DFF')
      
      // 加载文本
      Text(this.message)
        .fontSize(16)
        .fontColor('#6B7280')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F8FAFC')
  }
} 