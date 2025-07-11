// File: entry/src/main/ets/components/WelcomeView.ets

@Component
export struct WelcomeView {
  build() {
    Column({ space: 30 }) {
      Text('欢迎使用 EasyFlow！')
        .fontSize(38)
        .fontWeight(FontWeight.Bold)

      Column({ space: 15 }) {
        this.TipCard(
          '小贴士 1',
          '在左侧点击一个项目，即可在此处预览其详情。',
          $r('app.media.ic_select')
        )
        this.TipCard(
          '小贴士 2',
          '点击左上角的“+”按钮，开始您的第一个项目计划。',
          $r('app.media.ic_add_circle')
        )
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(40)
    .backgroundColor('#F9F9F9')
  }

  @Builder
  TipCard(title: string, content: string, icon: Resource) {
    Row({ space: 20 }) {
      Image(icon)
        .width(40)
        .height(40)
        .fillColor('#007DFF')

      Column({ space: 5 }) {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text(content)
          .fontSize(14)
          .fontColor(Color.Gray)
          .lineHeight(20)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}
