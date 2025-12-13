// File: entry/src/main/ets/pages/CustomComponentDesigner.ets

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import router from '@ohos.router';
import { PromptAction } from '@kit.ArkUI';
import { CustomComponentService } from '../services/CustomComponentService';
import { CustomComponentDefinition, CustomEnumItem, CustomRenderType } from '../model/CustomComponentSchema';

interface CustomComponentRouteParams {
  schemaId?: string;
}

@Entry
@Component
struct CustomComponentDesignerPage {
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private service: CustomComponentService = CustomComponentService.getInstance();

  @State searchKeyword: string = '';
  @State selectedId: string | null = null;

  @State importJson: string = '';
  @State exportJson: string = '';

  aboutToAppear() {
    const params = this.uiContext.getRouter().getParams() as CustomComponentRouteParams;
    console.log('[CustomComponentDesigner] params:', JSON.stringify(params));
    this.reloadList();
  }

  private reloadList(): void {
    const all = this.service.getAll();
    if (!this.selectedId && all.length > 0) {
      this.selectedId = all[0].id;
    }
    this.exportJson = this.service.exportToJson();
  }

  private getFilteredList(): CustomComponentDefinition[] {
    const all = this.service.getAll();
    const kw = this.searchKeyword.trim().toLowerCase();
    if (kw.length === 0) {
      return all;
    }
    return all.filter(item => item.name.toLowerCase().includes(kw) || item.id.toLowerCase().includes(kw));
  }

  private getSelected(): CustomComponentDefinition | null {
    if (!this.selectedId) {
      return null;
    }
    return this.service.getById(this.selectedId);
  }

  private createNew(): void {
    const id = `cc_${Date.now()}`;
    const def: CustomComponentDefinition = {
      id: id,
      name: '新自定义组件',
      renderType: 'text',
      description: '',
      textTemplate: '{value}',
      enums: [],
      min: 0,
      max: 100,
      unit: '%',
      style: {
        borderRadius: 8,
        paddingX: 8,
        paddingY: 4
      }
    };
    this.service.upsert(def);
    this.service.saveToStorage();
    this.selectedId = id;
    this.reloadList();
    this.promptAction.showToast({ message: '已创建自定义组件', duration: 1200 });
  }

  private deleteSelected(): void {
    const selected = this.getSelected();
    if (!selected) {
      return;
    }
    // ArkTS 对 AlertDialog 按钮对象字面量类型校验较严格，这里先采用“直接删除 + Toast”
    // 后续如需二次确认，可改为自定义 Dialog 组件。
    this.service.delete(selected.id);
    this.service.saveToStorage();
    const next = this.service.getAll();
    this.selectedId = next.length > 0 ? next[0].id : null;
    this.reloadList();
    this.promptAction.showToast({ message: '已删除', duration: 1200 });
  }

  private updateSelected(patch: Partial<CustomComponentDefinition>): void {
    const selected = this.getSelected();
    if (!selected) {
      return;
    }
    const updated: CustomComponentDefinition = {
      id: selected.id,
      name: patch.name !== undefined ? patch.name : selected.name,
      renderType: patch.renderType !== undefined ? patch.renderType : selected.renderType,
      description: patch.description !== undefined ? patch.description : selected.description,
      textTemplate: patch.textTemplate !== undefined ? patch.textTemplate : selected.textTemplate,
      enums: patch.enums !== undefined ? patch.enums : selected.enums,
      min: patch.min !== undefined ? patch.min : selected.min,
      max: patch.max !== undefined ? patch.max : selected.max,
      unit: patch.unit !== undefined ? patch.unit : selected.unit,
      style: patch.style !== undefined ? patch.style : selected.style
    };
    this.service.upsert(updated);
    this.service.saveToStorage();
    this.reloadList();
  }

  private addEnumItem(): void {
    const selected = this.getSelected();
    if (!selected) {
      return;
    }
    const nextEnums: CustomEnumItem[] = selected.enums ? [...selected.enums] : [];
    nextEnums.push({
      value: `value_${nextEnums.length + 1}`,
      label: `选项${nextEnums.length + 1}`,
      color: '#FFFFFF',
      backgroundColor: '#007AFF'
    });
    this.updateSelected({ enums: nextEnums });
  }

  private deleteEnumItem(index: number): void {
    const selected = this.getSelected();
    if (!selected || !selected.enums) {
      return;
    }
    const nextEnums: CustomEnumItem[] = [...selected.enums];
    if (index >= 0 && index < nextEnums.length) {
      nextEnums.splice(index, 1);
    }
    this.updateSelected({ enums: nextEnums });
  }

  private updateEnumItem(index: number, patch: Partial<CustomEnumItem>): void {
    const selected = this.getSelected();
    if (!selected || !selected.enums) {
      return;
    }
    const nextEnums: CustomEnumItem[] = [...selected.enums];
    if (index < 0 || index >= nextEnums.length) {
      return;
    }
    const current = nextEnums[index];
    nextEnums[index] = {
      value: patch.value !== undefined ? patch.value : current.value,
      label: patch.label !== undefined ? patch.label : current.label,
      color: patch.color !== undefined ? patch.color : current.color,
      backgroundColor: patch.backgroundColor !== undefined ? patch.backgroundColor : current.backgroundColor,
      icon: patch.icon !== undefined ? patch.icon : current.icon
    };
    this.updateSelected({ enums: nextEnums });
  }

  private doImport(mode: 'merge' | 'replace'): void {
    const ok = this.service.importFromJson(this.importJson, mode);
    if (ok) {
      this.service.saveToStorage();
      this.reloadList();
      this.promptAction.showToast({ message: '导入成功', duration: 1500 });
    } else {
      this.promptAction.showToast({ message: '导入失败：JSON格式不正确', duration: 2000 });
    }
  }

  build() {
    Column({ space: 0 }) {
      this.RootContent();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage);
  }

  @Builder
  RootContent() {
    // 顶部栏
    Row({ space: 12 }) {
      Row({ space: 6 }) {
        Text('←')
          .fontSize(20)
          .fontColor(ColorResource.primaryColor);
        Text('返回')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.primaryColor);
      }
      .padding({ left: 8, right: 12, top: 8, bottom: 8 })
      .borderRadius(8)
      .onClick(() => {
        router.back();
      });

      Text('自定义组件定义器')
        .fontSize(ThemeConfig.fontSizeL)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorResource.textPrimary)
        .layoutWeight(1);

      Row({ space: 8 }) {
        Button('新建')
          .height(36)
          .fontSize(ThemeConfig.fontSizeS)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => this.createNew());

        Button('删除')
          .height(36)
          .fontSize(ThemeConfig.fontSizeS)
          .backgroundColor(ColorResource.backgroundSecondary)
          .fontColor('#FF3B30')
          .borderRadius(8)
          .onClick(() => this.deleteSelected());
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ColorResource.backgroundPage);

    Divider()
      .strokeWidth(0.5)
      .color(ColorResource.surfaceEmphasized)
      .opacity(0.2);

    Row({ space: 0 }) {
      // 左侧列表
      Column({ space: 10 }) {
        TextInput({ text: this.searchKeyword, placeholder: '搜索组件名/ID' })
          .width('100%')
          .height(40)
          .fontSize(ThemeConfig.fontSizeS)
          .backgroundColor(ColorResource.backgroundInput)
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.searchKeyword = value;
          });

        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.getFilteredList(), (item: CustomComponentDefinition) => {
              Row({ space: 8 }) {
                Column({ space: 2 }) {
                  Text(item.name)
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontWeight(this.selectedId === item.id ? FontWeight.Medium : FontWeight.Normal)
                    .fontColor(ColorResource.textPrimary)
                    .maxLines(1);

                  Text(`${item.renderType} · ${item.id}`)
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.textTertiary)
                    .maxLines(1);
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);
              }
              .width('100%')
              .padding(10)
              .backgroundColor(this.selectedId === item.id ? ColorResource.backgroundSecondary : ColorResource.surface)
              .borderRadius(8)
              .onClick(() => {
                this.selectedId = item.id;
              });
            }, (item: CustomComponentDefinition) => item.id);
          }
          .width('100%')
          .padding({ bottom: 16 });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto);

        // 导入导出（JSON）
        Column({ space: 8 }) {
          Text('导入/导出（JSON）')
            .fontSize(ThemeConfig.fontSizeS)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary);

          TextArea({ text: this.importJson, placeholder: '粘贴组件定义 JSON（数组）' })
            .width('100%')
            .height(90)
            .fontSize(ThemeConfig.fontSizeXS)
            .backgroundColor(ColorResource.backgroundInput)
            .borderRadius(8)
            .padding(10)
            .onChange((value: string) => {
              this.importJson = value;
            });

          Row({ space: 8 }) {
            Button('合并导入')
              .layoutWeight(1)
              .height(34)
              .fontSize(ThemeConfig.fontSizeXS)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => this.doImport('merge'));

            Button('覆盖导入')
              .layoutWeight(1)
              .height(34)
              .fontSize(ThemeConfig.fontSizeXS)
              .backgroundColor(ColorResource.backgroundSecondary)
              .fontColor(ColorResource.textPrimary)
              .borderRadius(8)
              .onClick(() => this.doImport('replace'));
          }

          Button('复制导出JSON')
            .width('100%')
            .height(34)
            .fontSize(ThemeConfig.fontSizeXS)
            .backgroundColor(ColorResource.surface)
            .fontColor(ColorResource.primaryColor)
            .borderRadius(8)
            .onClick(() => {
              this.exportJson = this.service.exportToJson();
              this.promptAction.showToast({ message: '已刷新导出JSON，请手动复制', duration: 1500 });
            });

          TextArea({ text: this.exportJson, placeholder: '导出JSON会显示在这里' })
            .width('100%')
            .height(90)
            .fontSize(ThemeConfig.fontSizeXS)
            .backgroundColor(ColorResource.backgroundInput)
            .borderRadius(8)
            .padding(10)
            .enabled(false);
        }
        .width('100%');
      }
      .width(320)
      .height('100%')
      .padding(16)
      .backgroundColor(ColorResource.backgroundPage);

      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.2);

      // 右侧编辑区
      Column({ space: 12 }) {
        if (!this.getSelected()) {
          Column({ space: 12 }) {
            Text('← 请选择一个自定义组件')
              .fontSize(ThemeConfig.fontSizeM)
              .fontColor(ColorResource.textTertiary);

            Text('或点击右上角“新建”创建')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary)
              .opacity(0.7);
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          Text('编辑区（后续保持现有逻辑）')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textSecondary);
        }
      }
      .layoutWeight(1)
      .height('100%')
      .padding(16)
      .backgroundColor(ColorResource.backgroundPage);
    }
    .width('100%')
    .layoutWeight(1);
  }

  private getRenderTypeLabel(t: CustomRenderType): string {
    switch (t) {
      case 'text':
        return '文本';
      case 'tag':
        return '标签';
      case 'progress':
        return '进度条';
      case 'status_dot':
        return '状态点';
      case 'custom':
        return '自定义';
      default:
        return t;
    }
  }

  @Builder
  PreviewCard(def: CustomComponentDefinition) {
    Column({ space: 10 }) {
      if (def.renderType === 'text') {
        Text((def.textTemplate || '{value}').replace('{value}', '示例值'))
          .fontSize(14)
          .fontColor(ColorResource.textPrimary);
      } else if (def.renderType === 'tag') {
        Text(def.enums && def.enums.length > 0 ? def.enums[0].label : '标签示例')
          .fontSize(12)
          .fontColor(def.enums && def.enums.length > 0 && def.enums[0].color ? def.enums[0].color : Color.White)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(def.enums && def.enums.length > 0 && def.enums[0].backgroundColor ? def.enums[0].backgroundColor : ColorResource.primaryColor)
          .borderRadius(8);
      } else if (def.renderType === 'status_dot') {
        Row({ space: 8 }) {
          Circle()
            .width(10)
            .height(10)
            .fill(def.enums && def.enums.length > 0 && def.enums[0].backgroundColor ? def.enums[0].backgroundColor : ColorResource.primaryColor);

          Text(def.enums && def.enums.length > 0 ? def.enums[0].label : '状态示例')
            .fontSize(12)
            .fontColor(ColorResource.textPrimary);
        }
      } else if (def.renderType === 'progress') {
        Column({ space: 6 }) {
          Text(`进度: ${Math.min((def.max ?? 100), Math.max((def.min ?? 0), Math.floor((def.max ?? 100) * 0.35)))}${def.unit || ''}`)
            .fontSize(12)
            .fontColor(ColorResource.textSecondary);

          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(8)
              .backgroundColor(ColorResource.backgroundSecondary)
              .borderRadius(4);

            Row()
              .width(`${Math.round((Math.min((def.max ?? 100), Math.max((def.min ?? 0), Math.floor((def.max ?? 100) * 0.35))) / (def.max ?? 100)) * 100)}%`)
              .height(8)
              .backgroundColor(ColorResource.primaryColor)
              .borderRadius(4);
          }
          .width('100%');
        }
        .width('100%');
      } else {
        Text('自定义组件（待扩展）')
          .fontSize(12)
          .fontColor(ColorResource.textTertiary);
      }
    }
    .width(260)
    .padding(14)
    .backgroundColor(ColorResource.backgroundSecondary)
    .borderRadius(12);
  }
}
