// entry/src/main/ets/components/DockingLayout.ets

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

/**
 * 一个简化的可停靠布局容器
 * 目前仅支持水平排列和重新排序
 */
@Component
export struct DockingLayout {
  @BuilderParam itemRenderer: (id: string) => void;
  @State panelIds: string[] = [];

  build() {
    Row({ space: 8 }) {
      ForEach(this.panelIds, (panelId: string) => {
        Column() {
          this.itemRenderer(panelId)
        }
        .layoutWeight(1)
        .height('100%')
        // TODO: 在这里添加拖拽逻辑
      }, (panelId: string) => panelId)
    }
    .width('100%')
    .height('100%')
    .padding(8)
    .backgroundColor(ColorResource.backgroundTertiary);
  }
}
