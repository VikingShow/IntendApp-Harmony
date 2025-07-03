import { router } from "@kit.ArkUI"
import { IntendPage } from 'intend'
@Component
export struct Header {
  @State message: string = '最近使用'

  build() {
    Row() {
      Text(this.message)
        .fontFamily('HarmonyHeiTi-Bold')
        .fontSize(24)
        .textAlign(TextAlign.Start)
        .lineHeight(33)
        .fontWeight(700)
      Button('新建一图', { type: ButtonType.Normal, stateEffect: true })
        // .onClick(() => {
        //   router.pushUrl({ url: IntendPage })
        // })
        // .type(ButtonType.Capsule)
    }
    .padding({
      left: 16,
      right: 16
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .height(56)
    .margin({
      bottom: 11
    })
    .width('100%')
  }
}