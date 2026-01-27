// File: entry/src/main/ets/pages/CustomComponentDesigner.ets

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import router from '@ohos.router';
import { PromptAction } from '@kit.ArkUI';
import { CustomComponentService } from '../services/CustomComponentService';
import {
  CustomComponentDefinition,
  CustomComponentMeta,
  CustomEnumItem,
  CustomRenderType,
  CustomLayoutType,
  CustomStyleRule,
  CustomEventBinding,
  CustomActionType,
  CustomEventType
} from '../model/CustomComponentSchema';

type CustomStyleRuleOperator = 'equals' | 'notEquals' | 'contains' | 'greaterThan' | 'lessThan' | 'isEmpty' | 'isNotEmpty';

interface CustomComponentRouteParams {
  schemaId?: string;
}

@Entry
@Component
struct CustomComponentDesignerPage {
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private service: CustomComponentService = CustomComponentService.getInstance();

  @StorageProp('topRectHeight')
  topRectHeight: number = 0;

  @State searchKeyword: string = '';
  @State selectedId: string | null = null;

  @State importJson: string = '';
  @State exportJson: string = '';

  @State previewValue: string = '示例值';
  @State previewEnumIndex: number = 0;

  aboutToAppear() {
    const params = this.uiContext.getRouter().getParams() as CustomComponentRouteParams;
    console.log('[CustomComponentDesigner] params:', JSON.stringify(params));
    this.reloadList();
  }

  private castRuleOperator(input: string): CustomStyleRuleOperator {
    const v = (input || '').trim();
    if (v === 'equals' || v === 'notEquals' || v === 'contains' || v === 'greaterThan' || v === 'lessThan' || v === 'isEmpty' || v === 'isNotEmpty') {
      return v;
    }
    return 'equals';
  }

  private castEventType(input: string): CustomEventType {
    const v = (input || '').trim();
    if (v === 'click' || v === 'longPress') {
      return v;
    }
    return 'click';
  }

  private getHistoryCount(id: string): number {
    const list = this.service.getHistory(id);
    return list ? list.length : 0;
  }

  private buildPreviewDef(def: CustomComponentDefinition): CustomComponentDefinition {
    const enums = def.enums;
    const hasEnums = !!enums && enums.length > 0;
    const safeIndex = hasEnums ? Math.max(0, Math.min(enums.length - 1, this.previewEnumIndex)) : 0;
    const nextEnums = hasEnums ? [enums[safeIndex]] : enums;
    const nextTextTemplate = (def.textTemplate || '{value}').replace('{value}', this.previewValue);
    const previewDef: CustomComponentDefinition = {
      id: def.id,
      name: def.name,
      renderType: def.renderType,
      description: def.description,
      version: def.version,
      meta: def.meta,
      valueType: def.valueType,
      textTemplate: nextTextTemplate,
      layout: def.layout,
      enums: nextEnums,
      min: def.min,
      max: def.max,
      unit: def.unit,
      style: def.style,
      styleRules: def.styleRules,
      events: def.events
    };
    return previewDef;
  }

  private getLayoutTypeLabel(t: CustomLayoutType): string {
    switch (t) {
      case 'inline':
        return '单行';
      case 'left_center_right':
        return '三段';
      case 'stack':
        return '堆叠';
      default:
        return t;
    }
  }

  private ensureLayout(def: CustomComponentDefinition): void {
    if (def.layout) {
      return;
    }
    this.updateSelected({
      layout: {
        type: 'inline',
        template: {
          raw: def.textTemplate || '{value}'
        }
      }
    });
  }

  private upsertStyleRule(rule: CustomStyleRule, index: number): void {
    const selected = this.getSelected();
    if (!selected) {
      return;
    }
    const list: CustomStyleRule[] = selected.styleRules ? selected.styleRules.slice() : [];
    if (index >= 0 && index < list.length) {
      list[index] = rule;
    } else {
      list.push(rule);
    }
    this.updateSelected({ styleRules: list });
  }

  private deleteStyleRule(index: number): void {
    const selected = this.getSelected();
    if (!selected || !selected.styleRules) {
      return;
    }
    const list: CustomStyleRule[] = selected.styleRules.slice();
    if (index >= 0 && index < list.length) {
      list.splice(index, 1);
    }
    this.updateSelected({ styleRules: list });
  }

  private upsertEvent(binding: CustomEventBinding, index: number): void {
    const selected = this.getSelected();
    if (!selected) {
      return;
    }
    const list: CustomEventBinding[] = selected.events ? selected.events.slice() : [];
    if (index >= 0 && index < list.length) {
      list[index] = binding;
    } else {
      list.push(binding);
    }
    this.updateSelected({ events: list });
  }

  private deleteEvent(index: number): void {
    const selected = this.getSelected();
    if (!selected || !selected.events) {
      return;
    }
    const list: CustomEventBinding[] = selected.events.slice();
    if (index >= 0 && index < list.length) {
      list.splice(index, 1);
    }
    this.updateSelected({ events: list });
  }

  private getActionTypeLabel(t: CustomActionType): string {
    switch (t) {
      case 'none':
        return '无';
      case 'copy':
        return '复制';
      case 'toast':
        return 'Toast';
      case 'openUrl':
        return '打开链接';
      default:
        return t;
    }
  }

  private duplicateSelected(): void {
    const selected = this.getSelected();
    if (!selected) {
      return;
    }
    const id = `cc_${Date.now()}`;
    const now = Date.now();
    const meta: CustomComponentMeta = {
      author: selected.meta?.author,
      createdAt: now,
      updatedAt: now,
      tags: selected.meta?.tags
    };
    const def: CustomComponentDefinition = {
      id: id,
      name: `${selected.name} 副本`,
      renderType: selected.renderType,
      description: selected.description,
      version: selected.version,
      meta: meta,
      valueType: selected.valueType,
      textTemplate: selected.textTemplate,
      layout: selected.layout,
      enums: selected.enums ? selected.enums.slice() : [],
      min: selected.min,
      max: selected.max,
      unit: selected.unit,
      style: selected.style,
      styleRules: selected.styleRules ? selected.styleRules.slice() : [],
      events: selected.events ? selected.events.slice() : []
    };
    this.service.upsert(def);
    this.service.saveToStorage();
    this.selectedId = id;
    this.reloadList();
    this.promptAction.showToast({ message: '已复制组件', duration: 1200 });
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
      valueType: 'text',
      description: '',
      textTemplate: '{value}',
      layout: {
        type: 'inline',
        template: {
          raw: '{value}'
        }
      },
      enums: [],
      min: 0,
      max: 100,
      unit: '%',
      style: {
        borderRadius: 8,
        paddingX: 8,
        paddingY: 4
      },
      styleRules: [],
      events: [],
      meta: {
        createdAt: Date.now(),
        updatedAt: Date.now()
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
    const nextMeta = patch.meta ? patch.meta : selected.meta;
    const mergedMeta: CustomComponentMeta = {
      author: nextMeta?.author,
      createdAt: nextMeta?.createdAt,
      updatedAt: Date.now(),
      tags: nextMeta?.tags
    };
    const updated: CustomComponentDefinition = {
      id: selected.id,
      name: patch.name !== undefined ? patch.name : selected.name,
      renderType: patch.renderType !== undefined ? patch.renderType : selected.renderType,
      description: patch.description !== undefined ? patch.description : selected.description,
      version: patch.version !== undefined ? patch.version : selected.version,
      meta: mergedMeta,
      valueType: patch.valueType !== undefined ? patch.valueType : selected.valueType,
      textTemplate: patch.textTemplate !== undefined ? patch.textTemplate : selected.textTemplate,
      layout: patch.layout !== undefined ? patch.layout : selected.layout,
      enums: patch.enums !== undefined ? patch.enums : selected.enums,
      min: patch.min !== undefined ? patch.min : selected.min,
      max: patch.max !== undefined ? patch.max : selected.max,
      unit: patch.unit !== undefined ? patch.unit : selected.unit,
      style: patch.style !== undefined ? patch.style : selected.style,
      styleRules: patch.styleRules !== undefined ? patch.styleRules : selected.styleRules,
      events: patch.events !== undefined ? patch.events : selected.events
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
    const nextEnums: CustomEnumItem[] = selected.enums ? selected.enums.slice() : [];
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
    const nextEnums: CustomEnumItem[] = selected.enums.slice();
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
    const nextEnums: CustomEnumItem[] = selected.enums.slice();
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
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) })
    .backgroundColor(ColorResource.backgroundPage);
  }

  @Builder
  RootContent() {
    // 顶部栏
    Row({ space: 12 }) {
      Row({ space: 6 }) {
        Image($r('app.media.ic_back'))
          .width(18)
          .height(18)
          .fillColor(ColorResource.primaryColor);
        Text('返回')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.primaryColor);
      }
      .padding({ left: 8, right: 12, top: 8, bottom: 8 })
      .borderRadius(8)
      .onClick(() => {
        router.back();
      });

      Column({ space: 2 }) {
        Text('自定义组件定义器')
          .fontSize(ThemeConfig.fontSizeL)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorResource.textPrimary);
        Text('自动保存')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textTertiary);
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Row({ space: 8 }) {
        Button('新建')
          .height(36)
          .fontSize(ThemeConfig.fontSizeS)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => this.createNew());

        Button('复制')
          .height(36)
          .fontSize(ThemeConfig.fontSizeS)
          .backgroundColor(ColorResource.surface)
          .fontColor(ColorResource.primaryColor)
          .borderRadius(8)
          .onClick(() => this.duplicateSelected());

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

                  Text(`${this.getRenderTypeLabel(item.renderType)} · ${item.id}`)
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

          Button('复制导出 JSON')
            .width('100%')
            .height(34)
            .fontSize(ThemeConfig.fontSizeXS)
            .backgroundColor(ColorResource.surface)
            .fontColor(ColorResource.primaryColor)
            .borderRadius(8)
            .onClick(() => {
              this.exportJson = this.service.exportToJson();
              this.promptAction.showToast({ message: '已刷新导出 JSON，请手动复制', duration: 1500 });
            });

          TextArea({ text: this.exportJson, placeholder: '导出 JSON 会显示在这里' })
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
            Text('请先选择一个自定义组件')
              .fontSize(ThemeConfig.fontSizeM)
              .fontColor(ColorResource.textTertiary);

            Text('或点击右上角“新建”创建')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textSecondary);
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          this.EditorPanel(this.getSelected() as CustomComponentDefinition);
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

  @Builder
  EditorPanel(def: CustomComponentDefinition) {
    Row({ space: 16 }) {
      // 左：编辑表单
      Scroll() {
        Column({ space: 14 }) {
          this.SectionTitle('基础信息');
          Column({ space: 8 }) {
            TextInput({ text: def.name, placeholder: '组件名称' })
              .width('100%')
              .height(40)
              .fontSize(ThemeConfig.fontSizeS)
              .backgroundColor(ColorResource.backgroundInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((v: string) => this.updateSelected({ name: v }));

            TextArea({ text: def.description || '', placeholder: '组件描述（可选）' })
              .width('100%')
              .height(70)
              .fontSize(ThemeConfig.fontSizeXS)
              .backgroundColor(ColorResource.backgroundInput)
              .borderRadius(8)
              .padding(10)
              .onChange((v: string) => this.updateSelected({ description: v }));

            Text(`ID: ${def.id}`)
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textTertiary);
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(12);

          this.SectionTitle('渲染类型');
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              ForEach((['text', 'tag', 'progress', 'status_dot', 'custom'] as CustomRenderType[]), (t: CustomRenderType) => {
                Text(this.getRenderTypeLabel(t))
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(def.renderType === t ? Color.White : ColorResource.textSecondary)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor(def.renderType === t ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
                  .borderRadius(12)
                  .onClick(() => {
                    this.updateSelected({ renderType: t });
                    if (t === 'custom') {
                      this.ensureLayout(def);
                    }
                  });
              }, (t: CustomRenderType) => t);
            }
            .width('100%');

            if (def.renderType === 'text') {
              TextInput({ text: def.textTemplate || '{value}', placeholder: '文本模板，如: {value}' })
                .width('100%')
                .height(40)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => this.updateSelected({ textTemplate: v }));
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(12);

          if (def.renderType === 'tag' || def.renderType === 'status_dot') {
            this.SectionTitle('枚举/状态');
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                Button('添加选项')
                  .height(32)
                  .fontSize(ThemeConfig.fontSizeXS)
                  .backgroundColor(ColorResource.primaryColor)
                  .fontColor(Color.White)
                  .borderRadius(8)
                  .onClick(() => this.addEnumItem());
              }
              .width('100%');

              if (!def.enums || def.enums.length === 0) {
                Text('暂无选项')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textTertiary);
              } else {
                Column({ space: 8 }) {
                  ForEach(def.enums, (item: CustomEnumItem, index: number) => {
                    Column({ space: 6 }) {
                      Row({ space: 8 }) {
                        TextInput({ text: item.label, placeholder: '标签' })
                          .layoutWeight(1)
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(8)
                          .padding({ left: 10, right: 10 })
                          .onChange((v: string) => this.updateEnumItem(index, { label: v }));

                        TextInput({ text: item.value, placeholder: 'value' })
                          .layoutWeight(1)
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(8)
                          .padding({ left: 10, right: 10 })
                          .onChange((v: string) => this.updateEnumItem(index, { value: v }));
                      }
                      Row({ space: 8 }) {
                        TextInput({ text: item.icon || '', placeholder: 'emoji图标(可选)' })
                          .layoutWeight(1)
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(8)
                          .padding({ left: 10, right: 10 })
                          .onChange((v: string) => this.updateEnumItem(index, { icon: v }));

                        TextInput({ text: item.color || '', placeholder: '文字色 #RRGGBB' })
                          .layoutWeight(1)
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(8)
                          .padding({ left: 10, right: 10 })
                          .onChange((v: string) => this.updateEnumItem(index, { color: v }));
                      }
                      Row({ space: 8 }) {
                        TextInput({ text: item.backgroundColor || '', placeholder: '背景色 #RRGGBB' })
                          .layoutWeight(1)
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(8)
                          .padding({ left: 10, right: 10 })
                          .onChange((v: string) => this.updateEnumItem(index, { backgroundColor: v }));

                        Button('删除')
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeXS)
                          .backgroundColor(ColorResource.backgroundSecondary)
                          .fontColor('#FF3B30')
                          .borderRadius(8)
                          .onClick(() => this.deleteEnumItem(index));
                      }
                    }
                    .padding(10)
                    .backgroundColor(ColorResource.backgroundSecondary)
                    .borderRadius(10);
                  }, (item: CustomEnumItem) => item.value + item.label);
                }
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor(ColorResource.surface)
            .borderRadius(12);
          }

          if (def.renderType === 'progress') {
            this.SectionTitle('进度配置');
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                TextInput({ text: String(def.min ?? 0), placeholder: 'min' })
                  .layoutWeight(1)
                  .height(36)
                  .fontSize(ThemeConfig.fontSizeS)
                  .backgroundColor(ColorResource.backgroundInput)
                  .borderRadius(8)
                  .padding({ left: 10, right: 10 })
                  .onChange((v: string) => {
                    const n = Number(v);
                    if (!Number.isNaN(n)) {
                      this.updateSelected({ min: n });
                    }
                  });
                TextInput({ text: String(def.max ?? 100), placeholder: 'max' })
                  .layoutWeight(1)
                  .height(36)
                  .fontSize(ThemeConfig.fontSizeS)
                  .backgroundColor(ColorResource.backgroundInput)
                  .borderRadius(8)
                  .padding({ left: 10, right: 10 })
                  .onChange((v: string) => {
                    const n = Number(v);
                    if (!Number.isNaN(n)) {
                      this.updateSelected({ max: n });
                    }
                  });
              }
              TextInput({ text: def.unit || '', placeholder: '单位，如 % / 天' })
                .width('100%')
                .height(36)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => this.updateSelected({ unit: v }));
            }
            .width('100%')
            .padding(12)
            .backgroundColor(ColorResource.surface)
            .borderRadius(12);
          }

          if (def.renderType === 'custom') {
            this.SectionTitle('布局/模板（高阶）');
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                ForEach((['inline', 'left_center_right', 'stack'] as CustomLayoutType[]), (t: CustomLayoutType) => {
                  Text(this.getLayoutTypeLabel(t))
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(def.layout?.type === t ? Color.White : ColorResource.textSecondary)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor(def.layout?.type === t ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
                    .borderRadius(12)
                    .onClick(() => {
                      const currentLayout = def.layout;
                      if (currentLayout) {
                        this.updateSelected({
                          layout: {
                            type: t,
                            leftTemplate: currentLayout.leftTemplate,
                            centerTemplate: currentLayout.centerTemplate,
                            rightTemplate: currentLayout.rightTemplate,
                            template: currentLayout.template
                          }
                        });
                      } else {
                        this.updateSelected({
                          layout: {
                            type: t,
                            template: { raw: '{value}' }
                          }
                        });
                      }
                    });
                }, (t: CustomLayoutType) => t);
              }
              .width('100%');

              if (!def.layout) {
                Button('初始化布局')
                  .height(32)
                  .fontSize(ThemeConfig.fontSizeXS)
                  .backgroundColor(ColorResource.primaryColor)
                  .fontColor(Color.White)
                  .borderRadius(8)
                  .onClick(() => this.ensureLayout(def));
              } else {
                if (def.layout.type === 'left_center_right') {
                  TextInput({ text: def.layout.leftTemplate?.raw || '', placeholder: '左侧模板，如: {icon}' })
                    .width('100%')
                    .height(36)
                    .fontSize(ThemeConfig.fontSizeS)
                    .backgroundColor(ColorResource.backgroundInput)
                    .borderRadius(8)
                    .padding({ left: 10, right: 10 })
                    .onChange((v: string) => {
                      const layout = def.layout;
                      if (!layout) {
                        return;
                      }
                      this.updateSelected({
                        layout: {
                          type: layout.type,
                          leftTemplate: { raw: v },
                          centerTemplate: layout.centerTemplate,
                          rightTemplate: layout.rightTemplate,
                          template: layout.template
                        }
                      });
                    });
                  TextInput({ text: def.layout.centerTemplate?.raw || '{value}', placeholder: '中间模板，如: {value}' })
                    .width('100%')
                    .height(36)
                    .fontSize(ThemeConfig.fontSizeS)
                    .backgroundColor(ColorResource.backgroundInput)
                    .borderRadius(8)
                    .padding({ left: 10, right: 10 })
                    .onChange((v: string) => {
                      const layout = def.layout;
                      if (!layout) {
                        return;
                      }
                      this.updateSelected({
                        layout: {
                          type: layout.type,
                          leftTemplate: layout.leftTemplate,
                          centerTemplate: { raw: v },
                          rightTemplate: layout.rightTemplate,
                          template: layout.template
                        }
                      });
                    });
                  TextInput({ text: def.layout.rightTemplate?.raw || '', placeholder: '右侧模板，如: {unit}' })
                    .width('100%')
                    .height(36)
                    .fontSize(ThemeConfig.fontSizeS)
                    .backgroundColor(ColorResource.backgroundInput)
                    .borderRadius(8)
                    .padding({ left: 10, right: 10 })
                    .onChange((v: string) => {
                      const layout = def.layout;
                      if (!layout) {
                        return;
                      }
                      this.updateSelected({
                        layout: {
                          type: layout.type,
                          leftTemplate: layout.leftTemplate,
                          centerTemplate: layout.centerTemplate,
                          rightTemplate: { raw: v },
                          template: layout.template
                        }
                      });
                    });
                } else {
                  TextArea({ text: def.layout.template?.raw || '{value}', placeholder: '模板，如: {value}{unit}' })
                    .width('100%')
                    .height(90)
                    .fontSize(ThemeConfig.fontSizeS)
                    .backgroundColor(ColorResource.backgroundInput)
                    .borderRadius(8)
                    .padding(10)
                    .onChange((v: string) => {
                      const layout = def.layout;
                      if (!layout) {
                        return;
                      }
                      this.updateSelected({
                        layout: {
                          type: layout.type,
                          leftTemplate: layout.leftTemplate,
                          centerTemplate: layout.centerTemplate,
                          rightTemplate: layout.rightTemplate,
                          template: { raw: v }
                        }
                      });
                    });
                }
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor(ColorResource.surface)
            .borderRadius(12);
          }

          this.SectionTitle('样式');
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              TextInput({ text: def.style?.textColor || '', placeholder: '文字色 #RRGGBB' })
                .layoutWeight(1)
                .height(36)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  const style = def.style;
                  this.updateSelected({
                    style: {
                      textColor: v,
                      fontSize: style?.fontSize,
                      fontWeight: style?.fontWeight,
                      borderRadius: style?.borderRadius,
                      paddingX: style?.paddingX,
                      paddingY: style?.paddingY,
                      backgroundColor: style?.backgroundColor,
                      borderColor: style?.borderColor,
                      borderWidth: style?.borderWidth
                    }
                  });
                });
              TextInput({ text: def.style?.backgroundColor || '', placeholder: '背景色 #RRGGBB' })
                .layoutWeight(1)
                .height(36)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  const style = def.style;
                  this.updateSelected({
                    style: {
                      textColor: style?.textColor,
                      fontSize: style?.fontSize,
                      fontWeight: style?.fontWeight,
                      borderRadius: style?.borderRadius,
                      paddingX: style?.paddingX,
                      paddingY: style?.paddingY,
                      backgroundColor: v,
                      borderColor: style?.borderColor,
                      borderWidth: style?.borderWidth
                    }
                  });
                });
            }

            Row({ space: 8 }) {
              TextInput({ text: String(def.style?.fontSize ?? ''), placeholder: '字号' })
                .layoutWeight(1)
                .height(36)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  const n = Number(v);
                  if (!Number.isNaN(n)) {
                    const style = def.style;
                    this.updateSelected({
                      style: {
                        textColor: style?.textColor,
                        fontSize: n,
                        fontWeight: style?.fontWeight,
                        borderRadius: style?.borderRadius,
                        paddingX: style?.paddingX,
                        paddingY: style?.paddingY,
                        backgroundColor: style?.backgroundColor,
                        borderColor: style?.borderColor,
                        borderWidth: style?.borderWidth
                      }
                    });
                  }
                });
              TextInput({ text: String(def.style?.borderRadius ?? ''), placeholder: '圆角' })
                .layoutWeight(1)
                .height(36)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  const n = Number(v);
                  if (!Number.isNaN(n)) {
                    const style = def.style;
                    this.updateSelected({
                      style: {
                        textColor: style?.textColor,
                        fontSize: style?.fontSize,
                        fontWeight: style?.fontWeight,
                        borderRadius: n,
                        paddingX: style?.paddingX,
                        paddingY: style?.paddingY,
                        backgroundColor: style?.backgroundColor,
                        borderColor: style?.borderColor,
                        borderWidth: style?.borderWidth
                      }
                    });
                  }
                });
            }

            Row({ space: 8 }) {
              TextInput({ text: String(def.style?.paddingX ?? ''), placeholder: 'paddingX' })
                .layoutWeight(1)
                .height(36)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  const n = Number(v);
                  if (!Number.isNaN(n)) {
                    const style = def.style;
                    this.updateSelected({
                      style: {
                        textColor: style?.textColor,
                        fontSize: style?.fontSize,
                        fontWeight: style?.fontWeight,
                        borderRadius: style?.borderRadius,
                        paddingX: n,
                        paddingY: style?.paddingY,
                        backgroundColor: style?.backgroundColor,
                        borderColor: style?.borderColor,
                        borderWidth: style?.borderWidth
                      }
                    });
                  }
                });
              TextInput({ text: String(def.style?.paddingY ?? ''), placeholder: 'paddingY' })
                .layoutWeight(1)
                .height(36)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(8)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  const n = Number(v);
                  if (!Number.isNaN(n)) {
                    const style = def.style;
                    this.updateSelected({
                      style: {
                        textColor: style?.textColor,
                        fontSize: style?.fontSize,
                        fontWeight: style?.fontWeight,
                        borderRadius: style?.borderRadius,
                        paddingX: style?.paddingX,
                        paddingY: n,
                        backgroundColor: style?.backgroundColor,
                        borderColor: style?.borderColor,
                        borderWidth: style?.borderWidth
                      }
                    });
                  }
                });
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(12);

          this.SectionTitle('规则（样式规则）');
          Column({ space: 10 }) {
            Button('添加规则')
              .height(32)
              .fontSize(ThemeConfig.fontSizeXS)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                const rule: CustomStyleRule = {
                  id: `r_${Date.now()}`,
                  name: '新规则',
                  enabled: true,
                  when: { operator: 'equals', value: '' },
                  then: {}
                };
                this.upsertStyleRule(rule, -1);
              });

            if (!def.styleRules || def.styleRules.length === 0) {
              Text('暂无规则')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary);
            } else {
              Column({ space: 8 }) {
                ForEach(def.styleRules, (r: CustomStyleRule, idx: number) => {
                  Column({ space: 6 }) {
                    Row({ space: 8 }) {
                      TextInput({ text: r.name, placeholder: '规则名' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const nextRule: CustomStyleRule = {
                            id: r.id,
                            name: v,
                            enabled: r.enabled,
                            when: r.when,
                            then: r.then
                          };
                          this.upsertStyleRule(nextRule, idx);
                        });
                      Button('删除')
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeXS)
                        .backgroundColor(ColorResource.backgroundSecondary)
                        .fontColor('#FF3B30')
                        .borderRadius(8)
                        .onClick(() => this.deleteStyleRule(idx));
                    }

                    Row({ space: 8 }) {
                      TextInput({ text: r.when.operator, placeholder: 'operator' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const nextOp = v as string;
                          const nextRule: CustomStyleRule = {
                            id: r.id,
                            name: r.name,
                            enabled: r.enabled,
                            when: {
                              operator: this.castRuleOperator(nextOp),
                              value: r.when.value
                            },
                            then: r.then
                          };
                          this.upsertStyleRule(nextRule, idx);
                        });
                      TextInput({ text: String(r.when.value ?? ''), placeholder: 'value' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const nextRule: CustomStyleRule = {
                            id: r.id,
                            name: r.name,
                            enabled: r.enabled,
                            when: {
                              operator: r.when.operator,
                              value: v
                            },
                            then: r.then
                          };
                          this.upsertStyleRule(nextRule, idx);
                        });
                    }

                    Row({ space: 8 }) {
                      TextInput({ text: r.then.textColor || '', placeholder: 'then.textColor' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const nextRule: CustomStyleRule = {
                            id: r.id,
                            name: r.name,
                            enabled: r.enabled,
                            when: r.when,
                            then: {
                              textColor: v,
                              backgroundColor: r.then.backgroundColor,
                              fontSize: r.then.fontSize,
                              fontWeight: r.then.fontWeight,
                              borderRadius: r.then.borderRadius,
                              paddingX: r.then.paddingX,
                              paddingY: r.then.paddingY,
                              borderColor: r.then.borderColor,
                              borderWidth: r.then.borderWidth
                            }
                          };
                          this.upsertStyleRule(nextRule, idx);
                        });
                      TextInput({ text: r.then.backgroundColor || '', placeholder: 'then.backgroundColor' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const nextRule: CustomStyleRule = {
                            id: r.id,
                            name: r.name,
                            enabled: r.enabled,
                            when: r.when,
                            then: {
                              textColor: r.then.textColor,
                              backgroundColor: v,
                              fontSize: r.then.fontSize,
                              fontWeight: r.then.fontWeight,
                              borderRadius: r.then.borderRadius,
                              paddingX: r.then.paddingX,
                              paddingY: r.then.paddingY,
                              borderColor: r.then.borderColor,
                              borderWidth: r.then.borderWidth
                            }
                          };
                          this.upsertStyleRule(nextRule, idx);
                        });
                    }
                  }
                  .padding(10)
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .borderRadius(10);
                }, (r: CustomStyleRule) => r.id);
              }
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(12);

          this.SectionTitle('事件');
          Column({ space: 10 }) {
            Button('添加事件')
              .height(32)
              .fontSize(ThemeConfig.fontSizeXS)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                const binding: CustomEventBinding = {
                  event: 'click',
                  action: { type: 'none' }
                };
                this.upsertEvent(binding, -1);
              });

            if (!def.events || def.events.length === 0) {
              Text('暂无事件')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary);
            } else {
              Column({ space: 8 }) {
                ForEach(def.events, (ev: CustomEventBinding, idx: number) => {
                  Column({ space: 6 }) {
                    Row({ space: 8 }) {
                      TextInput({ text: ev.event, placeholder: 'click/longPress' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const nextEvent = this.castEventType(v);
                          this.upsertEvent({ event: nextEvent, action: ev.action }, idx);
                        });
                      TextInput({ text: ev.action.type, placeholder: 'action' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const nextType = v as CustomActionType;
                          this.upsertEvent({ event: ev.event, action: { type: nextType, params: ev.action.params } }, idx);
                        });
                      Button('删除')
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeXS)
                        .backgroundColor(ColorResource.backgroundSecondary)
                        .fontColor('#FF3B30')
                        .borderRadius(8)
                        .onClick(() => this.deleteEvent(idx));
                    }
                    if (ev.action.type === 'toast' || ev.action.type === 'copy') {
                      TextInput({ text: ev.action.params?.text || '', placeholder: 'text (可选)' })
                        .width('100%')
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const params = ev.action.params;
                          this.upsertEvent({
                            event: ev.event,
                            action: {
                              type: ev.action.type,
                              params: {
                                text: v,
                                url: params?.url
                              }
                            }
                          }, idx);
                        });
                    }
                    if (ev.action.type === 'openUrl') {
                      TextInput({ text: ev.action.params?.url || '', placeholder: 'url' })
                        .width('100%')
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(8)
                        .padding({ left: 10, right: 10 })
                        .onChange((v: string) => {
                          const params = ev.action.params;
                          this.upsertEvent({
                            event: ev.event,
                            action: {
                              type: ev.action.type,
                              params: {
                                text: params?.text,
                                url: v
                              }
                            }
                          }, idx);
                        });
                    }
                  }
                  .padding(10)
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .borderRadius(10);
                }, (ev: CustomEventBinding) => ev.event + String(ev.action.type));
              }
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(12);

          this.SectionTitle('历史版本');
          Column({ space: 8 }) {
            if (this.getHistoryCount(def.id) === 0) {
              Text('暂无历史')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary);
            } else {
              Text(`共 ${this.getHistoryCount(def.id)} 条（最近 20 条）`)
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary);

              Row({ space: 8 }) {
                Button('回滚到上一版')
                  .height(32)
                  .fontSize(ThemeConfig.fontSizeXS)
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .fontColor(ColorResource.textPrimary)
                  .borderRadius(8)
                  .onClick(() => {
                    const ok = this.service.rollbackToVersion(def.id, 0);
                    if (ok) {
                      this.service.saveToStorage();
                      this.reloadList();
                      this.promptAction.showToast({ message: '已回滚到上一版', duration: 1500 });
                    }
                  });
              }
              .width('100%');
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(12);
        }
        .width('100%')
        .padding({ bottom: 40 });
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto);

      // 右：预览
      Column({ space: 10 }) {
        this.SectionTitle('预览');
        Column({ space: 8 }) {
          TextInput({ text: this.previewValue, placeholder: '预览 value' })
            .width('100%')
            .height(36)
            .fontSize(ThemeConfig.fontSizeS)
            .backgroundColor(ColorResource.backgroundInput)
            .borderRadius(8)
            .padding({ left: 10, right: 10 })
            .onChange((v: string) => {
              this.previewValue = v;
            });

          if (def.enums && def.enums.length > 0) {
            TextInput({ text: String(this.previewEnumIndex), placeholder: '枚举索引（0..n-1）' })
              .width('100%')
              .height(36)
              .fontSize(ThemeConfig.fontSizeS)
              .backgroundColor(ColorResource.backgroundInput)
              .borderRadius(8)
              .padding({ left: 10, right: 10 })
              .onChange((v: string) => {
                const n = Number(v);
                if (!Number.isNaN(n)) {
                  this.previewEnumIndex = Math.max(0, Math.min((def.enums?.length || 1) - 1, Math.floor(n)));
                }
              });
          }

          this.PreviewCard(this.buildPreviewDef(def));
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorResource.surface)
        .borderRadius(12);
      }
      .width(320)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(ThemeConfig.fontSizeM)
      .fontWeight(FontWeight.Medium)
      .fontColor(ColorResource.textPrimary);
  }
}
