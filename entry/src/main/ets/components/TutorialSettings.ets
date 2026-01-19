import { TutorialService } from '../services/TutorialService';
import { ColorResource } from '../utils/ThemeConfig';
import { PromptAction } from '@kit.ArkUI';

@CustomDialog
export struct TutorialSettingsDialog {
  controller: CustomDialogController;
  private tutorialService: TutorialService = TutorialService.getInstance();
  onStartHomeTutorial: () => void = () => {};
  onStartIndexTutorial: () => void = () => {};
  promptAction?: PromptAction;

  build() {
    Column({ space: 0 }) {
      Column({ space: 4 }) {
        Text('新手引导设置')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .padding({ top: 24, left: 24, right: 24, bottom: 16 })

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)

      Column({ space: 0 }) {
        Row({ space: 12 }) {
          Image($r('app.media.ic_book'))
            .width(24)
            .height(24)
            .fillColor(ColorResource.textSecondary)
          Column({ space: 4 }) {
            Text('主页引导')
              .fontSize(15)
              .fontColor(ColorResource.textPrimary)
              .fontWeight(FontWeight.Medium)
            Text('介绍项目列表和创建功能')
              .fontSize(13)
              .fontColor(ColorResource.textSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('开始')
            .fontSize(14)
            .height(32)
            .padding({ left: 16, right: 16 })
            .backgroundColor(ColorResource.primaryColor)
            .fontColor(Color.White)
            .onClick(() => {
              this.controller.close();
              this.onStartHomeTutorial();
            })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.SpaceBetween)

        Divider()
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3)

        Row({ space: 12 }) {
          Image($r('app.media.ic_edit'))
            .width(24)
            .height(24)
            .fillColor(ColorResource.textSecondary)
          Column({ space: 4 }) {
            Text('编辑页引导')
              .fontSize(15)
              .fontColor(ColorResource.textPrimary)
              .fontWeight(FontWeight.Medium)
            Text('介绍任务编辑和画布操作')
              .fontSize(13)
              .fontColor(ColorResource.textSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('开始')
            .fontSize(14)
            .height(32)
            .padding({ left: 16, right: 16 })
            .backgroundColor(ColorResource.primaryColor)
            .fontColor(Color.White)
            .onClick(() => {
              this.controller.close();
              this.onStartIndexTutorial();
            })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.SpaceBetween)

        Divider()
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3)

        Row({ space: 12 }) {
          Image($r('app.media.ic_reset'))
            .width(24)
            .height(24)
            .fillColor(ColorResource.textSecondary)
          Column({ space: 4 }) {
            Text('重置所有引导')
              .fontSize(15)
              .fontColor(ColorResource.textPrimary)
              .fontWeight(FontWeight.Medium)
            Text('下次启动时重新显示引导')
              .fontSize(13)
              .fontColor(ColorResource.textSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('重置')
            .fontSize(14)
            .height(32)
            .padding({ left: 16, right: 16 })
            .backgroundColor(ColorResource.surfaceEmphasized)
            .fontColor(ColorResource.textPrimary)
            .onClick(async () => {
              await this.tutorialService.resetTutorial();
              if (this.promptAction) {
                this.promptAction.showToast({
                  message: '新手引导已重置',
                  duration: 2000
                });
              }
              this.controller.close();
            })
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)

      Row() {
        Button('关闭')
          .height(44)
          .fontSize(16)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.textSecondary)
          .onClick(() => {
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 12, bottom: 12 })
    }
    .width('85%')
    .constraintSize({ maxWidth: 360 })
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
