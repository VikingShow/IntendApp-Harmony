// entry/src/main/ets/components/DockablePanel.ets

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

@Component
export struct DockablePanel {
  private title: string = '';
  private onClose: () => void = () => {};
  @BuilderParam content: () => void;

  build() {
    Column({ space: 0 }) {
      // 标题栏
      Row({
        space: 8
      }) {
        Text(this.title)
          .fontSize(ThemeConfig.fontSizeM)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .layoutWeight(1);

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.ic_delete'))
            .width(16)
            .height(16)
            .fillColor(ColorResource.textSecondary)
        }
        .width(28)
        .height(28)
        .backgroundColor(ColorResource.backgroundSecondary)
        .onClick(() => {
          this.onClose();
        });
      }
      .width('100%')
      .height(44)
      .padding({
        left: 16,
        right: 8
      })
      .backgroundColor(ColorResource.surface)
      .border({ width: { bottom: 1 }, color: ColorResource.borderDivider });

      // 内容区
      Column() {
        this.content();
      }
      .layoutWeight(1)
      .width('100%')
      .padding(8)
      .backgroundColor(ColorResource.backgroundPrimary);
    }
    .width('100%')
    .height('100%')
    .borderRadius(ThemeConfig.radiusMedium)
    .border({ width: 1, color: ColorResource.borderDivider })
    .clip(true);
  }
}
