// entry/src/main/ets/components/SidebarMenu.ets

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

export interface MenuItem {
  id: string;
  label: string;
  icon: Resource;
}

@Component
export struct SidebarMenu {
  @Link menuItems: MenuItem[];
  @Link activePanelId: string;
  private onMenuItemClick: (panelId: string) => void = () => {};

  build() {
    Column({ space: 8 }) {
      ForEach(this.menuItems, (item: MenuItem) => {
        Column({ space: 4 }) {
          Image(item.icon)
            .width(24)
            .height(24)
            .fillColor(this.activePanelId === item.id ? ColorResource.primaryColor : ColorResource.textSecondary)

          Text(item.label)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.activePanelId === item.id ? ColorResource.primaryColor : ColorResource.textSecondary)
        }
        .width(56)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.activePanelId === item.id ? ColorResource.backgroundSecondary : Color.Transparent)
        .borderRadius(8)
        .onClick(() => {
          this.onMenuItemClick(item.id);
        });
      }, (item: MenuItem) => item.id);
    }
    .padding({ top: 16, bottom: 16 })
    .width(72)
    .height('100%')
    .backgroundColor(ColorResource.surface)
  }
}
