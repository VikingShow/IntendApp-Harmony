// File: entry/src/main/ets/pages/NodeWorkspace.ets
/**
 * 节点工作台页面（Node Workspace）
 *
 * 功能：
 * - 在左侧展示当前所有节点类型（系统内置 + 自定义）
 * - 在右侧编辑选中节点类型的名称、说明和基础样式（填充色）
 * - 通过 JSON 文本导出 / 导入全部节点 schema，便于分享和复用
 *
 * 设计：
 * - 使用与 Dashboard / TaskEditor 相同的卡片式风格和间距
 * - 左侧约占宽度的 1/3，右侧编辑区域约占 2/3
 */

import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import {
  NodeSchema,
  NodeComponentSchema,
  FieldSchema,
  FieldType,
  NodeComponentType,
  NodeStyleSchema
} from '../model/NodeSchema';
import { NodeSchemaService } from '../services/NodeSchemaService';
import { SchemaErrorBoundary, ErrorType } from '../utils/ErrorBoundary';
import { PromptAction } from '@kit.ArkUI';
import util from '@ohos.util';
import router from '@ohos.router';
import { ColorSelector } from '../components/ColorPicker';
import { ComponentLibrary } from '../components/ComponentLibrary';
import { NodeVisualCanvas } from '../components/NodeVisualCanvas';
import { ComponentPropertyPanel } from '../components/ComponentPropertyPanel';
import { fileIo as fs } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import pasteboard from '@ohos.pasteboard';

interface ConflictSchema {
  id: string;
  name: string;
}

/**
 * 差异比较工具
 */
interface SchemaChange {
  type: 'add' | 'remove' | 'modify';
  category: 'basic' | 'style' | 'field' | 'layout' | 'rule';
  name: string;
  oldValue?: string;
  newValue?: string;
  description?: string;
}

class SchemaDiffHelper {
  static compare(oldSchema: NodeSchema, newSchema: NodeSchema): SchemaChange[] {
    const changes: SchemaChange[] = [];

    // 1. 基本信息比较
    if (oldSchema.name !== newSchema.name) {
      changes.push({
        type: 'modify',
        category: 'basic',
        name: '名称',
        oldValue: oldSchema.name,
        newValue: newSchema.name
      });
    }
    if (oldSchema.description !== newSchema.description) {
      changes.push({
        type: 'modify',
        category: 'basic',
        name: '说明',
        oldValue: oldSchema.description || '(空)',
        newValue: newSchema.description || '(空)'
      });
    }

    // 2. 样式比较
    SchemaDiffHelper.compareStyle(oldSchema.style, newSchema.style, changes);

    // 3. 字段比较
    SchemaDiffHelper.compareFields(oldSchema.fields, newSchema.fields, changes);

    // 4. 布局比较
    SchemaDiffHelper.compareLayout(oldSchema.layout, newSchema.layout, changes);

    return changes;
  }

  private static compareStyle(oldStyle: NodeStyleSchema, newStyle: NodeStyleSchema, changes: SchemaChange[]) {
    // 直接比较每个已知的样式属性
    if (oldStyle.fillColor !== newStyle.fillColor) {
      changes.push({
        type: 'modify',
        category: 'style',
        name: '填充色',
        oldValue: String(oldStyle.fillColor || '默认'),
        newValue: String(newStyle.fillColor || '默认')
      });
    }
    if (oldStyle.criticalColor !== newStyle.criticalColor) {
      changes.push({
        type: 'modify',
        category: 'style',
        name: '关键色',
        oldValue: String(oldStyle.criticalColor || '默认'),
        newValue: String(newStyle.criticalColor || '默认')
      });
    }
    if (oldStyle.borderColor !== newStyle.borderColor) {
      changes.push({
        type: 'modify',
        category: 'style',
        name: '边框色',
        oldValue: String(oldStyle.borderColor || '默认'),
        newValue: String(newStyle.borderColor || '默认')
      });
    }
    if (oldStyle.borderRadius !== newStyle.borderRadius) {
      changes.push({
        type: 'modify',
        category: 'style',
        name: '圆角',
        oldValue: String(oldStyle.borderRadius || '默认'),
        newValue: String(newStyle.borderRadius || '默认')
      });
    }
    if (oldStyle.borderWidth !== newStyle.borderWidth) {
      changes.push({
        type: 'modify',
        category: 'style',
        name: '边框宽',
        oldValue: String(oldStyle.borderWidth || '默认'),
        newValue: String(newStyle.borderWidth || '默认')
      });
    }
    if (oldStyle.icon !== newStyle.icon) {
      changes.push({
        type: 'modify',
        category: 'style',
        name: '图标',
        oldValue: String(oldStyle.icon || '默认'),
        newValue: String(newStyle.icon || '默认')
      });
    }
    if (oldStyle.badgeColor !== newStyle.badgeColor) {
      changes.push({
        type: 'modify',
        category: 'style',
        name: '徽标色',
        oldValue: String(oldStyle.badgeColor || '默认'),
        newValue: String(newStyle.badgeColor || '默认')
      });
    }
  }

  private static compareFields(oldFields: FieldSchema[], newFields: FieldSchema[], changes: SchemaChange[]) {
    const oldMap = new Map(oldFields.map(f => [f.id, f]));
    const newMap = new Map(newFields.map(f => [f.id, f]));

    // 检查删除
    oldFields.forEach(f => {
      if (!newMap.has(f.id)) {
        changes.push({
          type: 'remove',
          category: 'field',
          name: f.label || '未知字段',
          description: `类型: ${f.type}`
        });
      }
    });

    // 检查新增和修改
    newFields.forEach(f => {
      const oldF = oldMap.get(f.id);
      if (!oldF) {
        changes.push({
          type: 'add',
          category: 'field',
          name: f.label || '新字段',
          description: `类型: ${f.type}`
        });
      } else {
        if (oldF.label !== f.label) {
          changes.push({
            type: 'modify',
            category: 'field',
            name: `${f.label} (名称)`,
            oldValue: oldF.label,
            newValue: f.label
          });
        }
        if (oldF.type !== f.type) {
          changes.push({
            type: 'modify',
            category: 'field',
            name: `${f.label} (类型)`,
            oldValue: oldF.type,
            newValue: f.type
          });
        }
        if (oldF.required !== f.required) {
          changes.push({
            type: 'modify',
            category: 'field',
            name: `${f.label} (必填)`,
            oldValue: oldF.required ? '是' : '否',
            newValue: f.required ? '是' : '否'
          });
        }
      }
    });
  }

  private static compareLayout(oldLayout: NodeComponentSchema[], newLayout: NodeComponentSchema[],
    changes: SchemaChange[]) {
    const oldMap = new Map(oldLayout.map(c => [c.id, c]));
    const newMap = new Map(newLayout.map(c => [c.id, c]));

    // 检查删除的组件
    oldLayout.forEach(c => {
      if (!newMap.has(c.id)) {
        changes.push({
          type: 'remove',
          category: 'layout',
          name: SchemaDiffHelper.getComponentTypeName(c.type),
          description: `ID: ${c.id}`
        });
      }
    });

    // 检查新增和修改的组件
    newLayout.forEach(c => {
      const oldC = oldMap.get(c.id);
      if (!oldC) {
        changes.push({
          type: 'add',
          category: 'layout',
          name: SchemaDiffHelper.getComponentTypeName(c.type),
          description: `ID: ${c.id}`
        });
      } else {
        // 检查类型变化
        if (oldC.type !== c.type) {
          changes.push({
            type: 'modify',
            category: 'layout',
            name: `组件 ${c.id}`,
            oldValue: SchemaDiffHelper.getComponentTypeName(oldC.type),
            newValue: SchemaDiffHelper.getComponentTypeName(c.type)
          });
        }
        // 检查关联字段变化
        if (oldC.fieldId !== c.fieldId) {
          changes.push({
            type: 'modify',
            category: 'layout',
            name: `${SchemaDiffHelper.getComponentTypeName(c.type)} 关联字段`,
            oldValue: oldC.fieldId || '(无)',
            newValue: c.fieldId || '(无)'
          });
        }
      }
    });
  }

  private static getComponentTypeName(type: string): string {
    const typeNames: Record<string, string> = {
      'TITLE': '任务标题',
      'DATE_RANGE': '日期范围',
      'TIME_PROGRESS': '时间进度条',
      'TASK_PROGRESS': '完成进度条',
      'CHECKLIST_SUMMARY': '清单统计',
      'PRIORITY_BADGE': '优先级标签',
      'ASSIGNEE': '负责人',
      'TAGS': '标签列表',
      'STATUS_DOT': '状态指示器',
      'CUSTOM_FIELD': '自定义字段'
    };
    return typeNames[type] || type;
  }
}

@CustomDialog
struct ImportConflictDialog {
  controller: CustomDialogController;
  conflictSchemas: ConflictSchema[] = [];
  onResolve: (resolution: 'rename' | 'newId' | 'skip') => void = () => {
  };

  build() {
    Column({ space: 0 }) {
      Column({ space: 12 }) {
        Text('导入冲突')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .width('100%');

        Text(`发现 ${this.conflictSchemas.length} 个 ID 冲突，请选择处理方式：`)
          .fontSize(14)
          .fontColor(ColorResource.textSecondary)
          .lineHeight(20)
          .width('100%');

        Column({ space: 6 }) {
          ForEach(this.conflictSchemas.slice(0, 3), (schema: ConflictSchema) => {
            Text(`• ${schema.name} (${schema.id})`)
              .fontSize(12)
              .fontColor(ColorResource.textTertiary)
              .width('100%');
          });

          if (this.conflictSchemas.length > 3) {
            Text(`... 还有 ${this.conflictSchemas.length - 3} 个`)
              .fontSize(12)
              .fontColor(ColorResource.textTertiary)
              .width('100%');
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorResource.backgroundSecondary)
        .borderRadius(8);
      }
      .width('100%')
      .padding({
        top: 24,
        left: 24,
        right: 24,
        bottom: 16
      });

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3);

      Column({ space: 8 }) {
        Button('自动重命名')
          .width('100%')
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.onResolve('rename');
            this.controller.close();
          });

        Button('生成新 ID')
          .width('100%')
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.surface)
          .fontColor(ColorResource.textPrimary)
          .borderRadius(8)
          .onClick(() => {
            this.onResolve('newId');
            this.controller.close();
          });

        Button('跳过冲突项')
          .width('100%')
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.surfaceSubtle)
          .fontColor(ColorResource.textSecondary)
          .borderRadius(8)
          .onClick(() => {
            this.onResolve('skip');
            this.controller.close();
          });
      }
      .width('100%')
      .padding(16);
    }
    .width('85%')
    .constraintSize({ maxWidth: 320 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14)
    .shadow({
      radius: 24,
      color: 'rgba(0, 0, 0, 0.12)',
      offsetX: 0,
      offsetY: 4
    });
  }
}

@CustomDialog
struct ExportJsonDialog {
  controller: CustomDialogController;
  json: string = '';

  private async copyToClipboard(text: string): Promise<void> {
    try {
      if (!text || text.length === 0) {
        return;
      }
      const data = pasteboard.createPlainTextData(text);
      // 创建 pasteboard 实例并使用正确的方法
      const systemPasteboard = pasteboard.getSystemPasteboard();
      try {
        await systemPasteboard.setPasteData(data);
      } catch (error) {
        console.error('[ExportJsonDialog] setPasteData failed:', error);
      }
    } catch (error) {
      console.error('[ExportJsonDialog] copyToClipboard error:', error);
    }
  }

  private async saveToFile(fileName: string, content: string): Promise<void> {
    try {
      if (!canIUse('SystemCapability.FileManagement.UserFileService')) {
        return;
      }
      if (!canIUse('SystemCapability.FileManagement.File.FileIO')) {
        return;
      }

      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = [fileName];

      const fileExtension = fileName.substring(fileName.lastIndexOf('.'));
      if (fileExtension && fileExtension.length > 1) {
        documentSaveOptions.fileSuffixChoices = [fileExtension];
      }

      const documentPicker = new picker.DocumentViewPicker();
      const uris = await documentPicker.save(documentSaveOptions);
      if (!uris || uris.length === 0) {
        return;
      }

      const uri = uris[0];
      const file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encodeInto(content);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);
    } catch (error) {
      console.error('[ExportJsonDialog] saveToFile error:', error);
    }
  }

  build() {
    Column({ space: 0 }) {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text('导出节点类型JSON')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Button('×')
            .width(28)
            .height(28)
            .fontSize(24)
            .fontColor(ColorResource.textSecondary)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.controller.close();
            });
        }
        .width('100%');

        Text('支持复制到剪贴板，或保存为 JSON 文件')
          .fontSize(14)
          .fontColor(ColorResource.textSecondary);

        TextArea({ text: this.json })
          .width('100%')
          .height(240)
          .fontSize(ThemeConfig.fontSizeXS)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(8)
          .padding(12)
          .enabled(false);
      }
      .width('100%')
      .padding(16);

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3);

      Row({ space: 12 }) {
        Button('复制')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.surface)
          .fontColor(ColorResource.primaryColor)
          .borderRadius(8)
          .onClick(() => {
            this.copyToClipboard(this.json);
          });

        Button('保存为文件')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            const fileName = `node_schemas_${Date.now()}.json`;
            this.saveToFile(fileName, this.json);
          });
      }
      .width('100%')
      .padding(16);
    }
    .width('90%')
    .constraintSize({ maxWidth: 520 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14);
  }
}

@CustomDialog
struct NodeColorPickerDialog {
  controller: CustomDialogController;
  currentColor: string = '#007AFF';
  @State selectedColor: string = '#007AFF';
  @State inputColor: string = '#007AFF';
  onConfirm: (color: string) => void = () => {
  };

  aboutToAppear() {
    const normalized = this.normalizeToHex(this.currentColor);
    this.selectedColor = normalized;
    this.inputColor = normalized;
  }

  private normalizeToHex(color: string): string {
    const trimmed = (color || '').trim();
    if (trimmed.length === 0) {
      return '#007AFF';
    }

    const hex3 = /^#([0-9A-Fa-f]{3})$/;
    const hex6 = /^#([0-9A-Fa-f]{6})$/;
    const rgb = /^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$/;
    const rgba = /^rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(0|1|0?\.\d+)\s*\)$/;

    const m6 = hex6.exec(trimmed);
    if (m6) {
      return `#${m6[1].toUpperCase()}`;
    }

    const m3 = hex3.exec(trimmed);
    if (m3) {
      const s = m3[1];
      return `#${(s[0] + s[0] + s[1] + s[1] + s[2] + s[2]).toUpperCase()}`;
    }

    const mrgb = rgb.exec(trimmed);
    if (mrgb) {
      const r = Math.max(0, Math.min(255, parseInt(mrgb[1], 10)));
      const g = Math.max(0, Math.min(255, parseInt(mrgb[2], 10)));
      const b = Math.max(0, Math.min(255, parseInt(mrgb[3], 10)));
      return this.rgbToHex(r, g, b);
    }

    const mrgba = rgba.exec(trimmed);
    if (mrgba) {
      const r = Math.max(0, Math.min(255, parseInt(mrgba[1], 10)));
      const g = Math.max(0, Math.min(255, parseInt(mrgba[2], 10)));
      const b = Math.max(0, Math.min(255, parseInt(mrgba[3], 10)));
      return this.rgbToHex(r, g, b);
    }

    return '#007AFF';
  }

  private rgbToHex(r: number, g: number, b: number): string {
    return (
      '#' +
      r.toString(16).padStart(2, '0') +
      g.toString(16).padStart(2, '0') +
      b.toString(16).padStart(2, '0')
    ).toUpperCase();
  }

  build() {
    Column({ space: 0 }) {
      Column({ space: 16 }) {
        Row({ space: 8 }) {
          Text('选择颜色')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Button('×')
            .width(28)
            .height(28)
            .fontSize(24)
            .fontColor(ColorResource.textSecondary)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.controller.close();
            });
        }
        .width('100%');

        Column({ space: 8 }) {
          Text('输入颜色（Hex / RGB / RGBA）')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textSecondary);

          TextInput({
            text: this.inputColor,
            placeholder: '#RRGGBB / rgb(0,0,0) / rgba(0,0,0,1)'
          })
            .width('100%')
            .height(40)
            .fontSize(ThemeConfig.fontSizeM)
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              this.inputColor = value;
              const normalized = this.normalizeToHex(value);
              this.selectedColor = normalized;
            });
        }
        .width('100%');

        ColorSelector({ selectedColor: $selectedColor });
      }
      .width('100%')
      .padding({
        top: 20,
        left: 20,
        right: 20,
        bottom: 16
      });

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3);

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.surfaceSubtle)
          .fontColor(ColorResource.textPrimary)
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
          });

        Button('确定')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.onConfirm(this.normalizeToHex(this.selectedColor));
            this.controller.close();
          });
      }
      .width('100%')
      .padding(16);
    }
    .width('90%')
    .constraintSize({ maxWidth: 360 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14)
    .shadow({
      radius: 24,
      color: 'rgba(0, 0, 0, 0.12)',
      offsetX: 0,
      offsetY: 4
    });
  }
}

@CustomDialog
struct ImportJsonDialog {
  controller: CustomDialogController;
  @State importJson: string = '';
  @State importMode: 'paste' | 'file' = 'paste';
  @State selectedFileName: string = '';
  onConfirm: (json: string) => void = () => {
  };

  private async chooseAndLoadJsonFile(): Promise<void> {
    try {
      if (!canIUse('SystemCapability.FileManagement.UserFileService')) {
        return;
      }
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      const documentPicker = new picker.DocumentViewPicker();
      const result = await documentPicker.select(documentSelectOptions);
      if (!result || result.length === 0) {
        return;
      }

      const uri = result[0];
      const parts = uri.split('/');
      this.selectedFileName = parts.length > 0 ? parts[parts.length - 1] : uri;

      if (!canIUse('SystemCapability.FileManagement.File.FileIO')) {
        return;
      }

      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(uri);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
      const content = decoder.decodeToString(new Uint8Array(buffer));
      this.importJson = content;

      if (!content || content.trim().length === 0) {
        console.warn('[ImportJsonDialog] Read empty content from file');
        this.selectedFileName += ' (空文件)';
      }
    } catch (error) {
      console.error('[ImportJsonDialog] chooseAndLoadJsonFile error:', error);
      this.selectedFileName = '读取文件失败';
      this.importJson = '';
    }
  }

  build() {
    Column({ space: 0 }) {
      Column({ space: 12 }) {
        Text('导入节点类型JSON')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary);

        // 导入方式切换
        Row({ space: 8 }) {
          Button('直接粘贴')
            .layoutWeight(1)
            .height(36)
            .fontSize(ThemeConfig.fontSizeS)
            .backgroundColor(this.importMode === 'paste' ? ColorResource.primaryColor :
              ColorResource.backgroundSecondary)
            .fontColor(this.importMode === 'paste' ? Color.White : ColorResource.textSecondary)
            .borderRadius(8)
            .onClick(() => {
              this.importMode = 'paste';
            });

          Button('从文件选择')
            .layoutWeight(1)
            .height(36)
            .fontSize(ThemeConfig.fontSizeS)
            .backgroundColor(this.importMode === 'file' ? ColorResource.primaryColor :
              ColorResource.backgroundSecondary)
            .fontColor(this.importMode === 'file' ? Color.White : ColorResource.textSecondary)
            .borderRadius(8)
            .onClick(() => {
              this.importMode = 'file';
            });
        }
        .width('100%');

        if (this.importMode === 'paste') {
          // 直接粘贴模式
          Text('请粘贴节点类型的JSON数据')
            .fontSize(14)
            .fontColor(ColorResource.textSecondary);

          TextArea({ text: this.importJson, placeholder: '{"id": "...", "name": "...", ...}' })
            .width('100%')
            .height(200)
            .fontSize(ThemeConfig.fontSizeXS)
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(8)
            .onChange((value: string) => {
              this.importJson = value;
            });
        } else {
          // 文件选择模式
          Text('选择JSON文件导入')
            .fontSize(14)
            .fontColor(ColorResource.textSecondary);

          Column({ space: 12 }) {
            Button('选择文件')
              .width('100%')
              .height(44)
              .fontSize(ThemeConfig.fontSizeS)
              .backgroundColor(ColorResource.backgroundSecondary)
              .fontColor(ColorResource.primaryColor)
              .borderRadius(8)
              .onClick(() => {
                this.chooseAndLoadJsonFile();
              });

            if (this.selectedFileName) {
              Text(`已选择: ${this.selectedFileName}`)
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textSecondary);
            }
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(8)
          .padding(16);
        }
      }
      .width('100%')
      .padding(16);

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3);

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.surfaceSubtle)
          .fontColor(ColorResource.textPrimary)
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
          });

        Button('导入')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .type(ButtonType.Normal)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.onConfirm(this.importJson);
            this.controller.close();
          });
      }
      .width('100%')
      .padding(16);
    }
    .width('90%')
    .constraintSize({ maxWidth: 400 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14);
  }
}

@CustomDialog
struct DeleteConfirmDialog {
  controller: CustomDialogController;
  schemaName: string = '';
  onConfirm: () => void = () => {
  };

  build() {
    Column({ space: 0 }) {
      Column({ space: 0 }) {
        Text('确认删除')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(`确定要删除节点类型"${this.schemaName}"吗？`)
          .fontSize(14)
          .fontColor(ColorResource.textSecondary)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({
        top: 24,
        left: 24,
        right: 24,
        bottom: 16
      })

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)

      Row({ space: 0 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .borderRadius(0)
          .onClick(() => {
            this.controller.close();
          })

        Divider()
          .vertical(true)
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3)
          .height(48)

        Button('删除')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor('#FF3B30')
          .fontWeight(FontWeight.Medium)
          .borderRadius(0)
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          })
      }
      .width('100%')
    }
    .width('85%')
    .constraintSize({ maxWidth: 300 })
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


@CustomDialog
struct VersionDiffDialog {
  controller: CustomDialogController;
  oldSchema: NodeSchema | null = null;
  newSchema: NodeSchema | null = null;
  @State changes: SchemaChange[] = [];

  aboutToAppear() {
    if (this.oldSchema && this.newSchema) {
      this.changes = SchemaDiffHelper.compare(this.oldSchema, this.newSchema);
    }
  }

  @Builder
  ChangeItem(change: SchemaChange) {
    Row() {
      // 图标/类型
      Column() {
        if (change.type === 'add') {
          Text('+')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#34C759');
        } else if (change.type === 'remove') {
          Text('-')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF3B30');
        } else {
          Text('•')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007AFF');
        }
      }
      .width(24)
      .alignItems(HorizontalAlign.Center);

      // 内容
      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text(this.getCategoryLabel(change.category))
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor(this.getCategoryColor(change.category))
            .padding({
              left: 4,
              right: 4,
              top: 2,
              bottom: 2
            })
            .borderRadius(4);

          Text(change.name)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary);
        }

        if (change.type === 'modify') {
          Row({ space: 4 }) {
            Text(change.oldValue)
              .fontSize(12)
              .fontColor(ColorResource.textSecondary)
              .decoration({ type: TextDecorationType.LineThrough, color: ColorResource.textSecondary });
            Text('→')
              .fontSize(12)
              .fontColor(ColorResource.textTertiary);
            Text(change.newValue)
              .fontSize(12)
              .fontColor(ColorResource.textPrimary);
          }
        } else if (change.description) {
          Text(change.description)
            .fontSize(12)
            .fontColor(ColorResource.textSecondary);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Top);
  }

  private getCategoryLabel(cat: string): string {
    const map: Record<string, string> = {
      'basic': '基本',
      'style': '样式',
      'field': '字段',
      'layout': '布局',
      'rule': '规则'
    };
    return map[cat] || cat;
  }

  private getCategoryColor(cat: string): string {
    const map: Record<string, string> = {
      'basic': '#8E8E93',
      'style': '#AF52DE',
      'field': '#007AFF',
      'layout': '#FF9500',
      'rule': '#FF2D55'
    };
    return map[cat] || '#8E8E93';
  }

  build() {
    Column({ space: 16 }) {
      // 标题
      Row() {
        Text('版本差异对比')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary);

        Blank();

        if (this.oldSchema && this.newSchema) {
          Text(`v${this.oldSchema.version} → v${this.newSchema.version}`)
            .fontSize(14)
            .fontColor(ColorResource.textSecondary);
        }
      }
      .width('100%');

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3);

      // 内容列表
      if (this.changes.length === 0) {
        Column() {
          Text('没有检测到差异')
            .fontSize(14)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%')
        .height(150)
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.changes, (change: SchemaChange) => {
            ListItem() {
              this.ChangeItem(change);
            }
          })
        }
        .width('100%')
        .height(300)
        .edgeEffect(EdgeEffect.Spring);
      }

      Button('关闭')
        .width('100%')
        .height(44)
        .fontSize(15)
        .backgroundColor(ColorResource.surface)
        .fontColor(ColorResource.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close();
        });
    }
    .width('90%')
    .constraintSize({ maxWidth: 450 })
    .padding(16)
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14);
  }
}

// 独立的卡片预览组件 - 使用 @Prop 确保响应式刷新
@Component
struct HistoryCardPreview {
  @Prop schema: NodeSchema;

  private getComponentContent(comp: NodeComponentSchema): string {
    const contentMap: Record<string, string> = {
      'TITLE': '任务标题',
      'DATE_RANGE': '📅 12/23 ~ 12/30',
      'CHECKLIST_SUMMARY': '☑️ 3/5 完成',
      'PRIORITY_BADGE': '🔥 高优先级',
      'ASSIGNEE': '👤 张三',
      'TAGS': '🏷️ 开发, 设计'
    };
    return contentMap[comp.type] || comp.type;
  }

  build() {
    Column({ space: 3 }) {
      if (this.schema.layout && this.schema.layout.length > 0) {
        ForEach(this.schema.layout.slice(0, 5), (comp: NodeComponentSchema, index: number) => {
          if (comp.type === 'TITLE') {
            Text('任务标题')
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorResource.textPrimary)
              .width('100%');
          } else if (comp.type === 'DATE_RANGE') {
            Text('📅 12/23 ~ 12/30')
              .fontSize(7)
              .fontColor(ColorResource.textSecondary)
              .width('100%');
          } else if (comp.type === 'TIME_PROGRESS') {
            Column({ space: 1 }) {
              Text('时间: 50%')
                .fontSize(6)
                .fontColor(ColorResource.textSecondary);
              Stack({ alignContent: Alignment.Start }) {
                Row().width('100%').height(3).backgroundColor(ColorResource.backgroundSecondary).borderRadius(1);
                Row().width('50%').height(3).backgroundColor(this.schema.style.fillColor).borderRadius(1);
              }
            }
            .width('100%');
          } else if (comp.type === 'TASK_PROGRESS') {
            Column({ space: 1 }) {
              Text('完成: 60%')
                .fontSize(6)
                .fontColor(ColorResource.textSecondary);
              Stack({ alignContent: Alignment.Start }) {
                Row().width('100%').height(3).backgroundColor(ColorResource.backgroundSecondary).borderRadius(1);
                Row().width('60%').height(3).backgroundColor('#67C23A').borderRadius(1);
              }
            }
            .width('100%');
          } else if (comp.type === 'CHECKLIST_SUMMARY') {
            Text('☑️ 3/5 完成')
              .fontSize(7)
              .fontColor(ColorResource.textSecondary)
              .width('100%');
          } else if (comp.type === 'PRIORITY_BADGE') {
            Text('🔥 高优先级')
              .fontSize(7)
              .fontColor('#FF3B30')
              .width('100%');
          } else if (comp.type === 'ASSIGNEE') {
            Text('👤 张三')
              .fontSize(7)
              .fontColor(ColorResource.textSecondary)
              .width('100%');
          } else if (comp.type === 'TAGS') {
            Text('🏷️ 开发, 设计')
              .fontSize(7)
              .fontColor(ColorResource.textSecondary)
              .width('100%');
          } else if (comp.type === 'STATUS_DOT') {
            Row({ space: 3 }) {
              Circle().width(6).height(6).fill('#34C759');
              Text('进行中').fontSize(7).fontColor(ColorResource.textSecondary);
            }
            .width('100%');
          } else {
            Text('自定义字段')
              .fontSize(7)
              .fontColor(ColorResource.textTertiary)
              .width('100%');
          }
        }, (comp: NodeComponentSchema, index: number) => `${this.schema.version}_${index}_${comp.id}`)

        if (this.schema.layout.length > 5) {
          Text(`... 还有 ${this.schema.layout.length - 5} 个组件`)
            .fontSize(6)
            .fontColor(ColorResource.textTertiary);
        }
      } else {
        Text('暂无组件')
          .fontSize(8)
          .fontColor(ColorResource.textTertiary);
      }
    }
    .width(110)
    .constraintSize({ minHeight: 60 })
    .padding(8)
    .backgroundColor(ColorResource.surface)
    .borderRadius(this.schema.style.borderRadius !== undefined ? this.schema.style.borderRadius / 2 : 8)
    .border({
      width: 2,
      color: this.schema.style.borderColor ? this.schema.style.borderColor : this.schema.style.fillColor
    })
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 1 });
  }
}

@CustomDialog
struct HistoryDialog {
  controller: CustomDialogController;
  schemaId: string = '';
  schemaName: string = '';
  @State history: NodeSchema[] = [];
  @State selectedPreviewSchema: NodeSchema | null = null;
  onRestore: (version: number) => void = () => {
  };
  onCompare: (oldVersion: NodeSchema, newVersion: NodeSchema) => void = () => {
  };

  aboutToAppear() {
    this.history = NodeSchemaService.getInstance().getHistory(this.schemaId);
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('版本历史')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary);
        Blank();
        Text(this.schemaName)
          .fontSize(14)
          .fontColor(ColorResource.textSecondary);
      }
      .width('100%');

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3);

      if (this.history.length === 0) {
        Column() {
          Text('暂无历史版本')
            .fontSize(14)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center);
      } else {
        // 左右布局：列表 + 预览
        Row({ space: 16 }) {
          // 左侧：版本列表
          List() {
            ForEach(this.history.slice().reverse(), (schema: NodeSchema) => {
              ListItem() {
                Row() {
                  Column({ space: 4 }) {
                    Row({ space: 8 }) {
                      Text(`v${schema.version}`)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.selectedPreviewSchema?.version === schema.version
                          ? ColorResource.primaryColor
                          : ColorResource.textPrimary);

                      if (schema.meta?.updatedAt) {
                        Text(new Date(schema.meta.updatedAt).toLocaleDateString())
                          .fontSize(10)
                          .fontColor(ColorResource.textSecondary);
                      }
                    }
                    .alignItems(VerticalAlign.Bottom);

                    // 组件数量信息
                    Text(`${schema.layout?.length || 0} 个组件`)
                      .fontSize(10)
                      .fontColor(ColorResource.textTertiary);
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start);

                  Row({ space: 6 }) {
                    Button('对比')
                      .height(24)
                      .fontSize(10)
                      .padding({ left: 8, right: 8 })
                      .backgroundColor(ColorResource.surface)
                      .fontColor(ColorResource.primaryColor)
                      .borderRadius(4)
                      .onClick(() => {
                        const currentVersion = NodeSchemaService.getInstance().getSchemaById(this.schemaId);
                        if (currentVersion) {
                          this.onCompare(schema, currentVersion);
                        }
                      });

                    Button('恢复')
                      .height(24)
                      .fontSize(10)
                      .padding({ left: 8, right: 8 })
                      .backgroundColor(ColorResource.surface)
                      .fontColor(ColorResource.primaryColor)
                      .borderRadius(4)
                      .onClick(() => {
                        this.onRestore(schema.version);
                        this.controller.close();
                      });
                  }
                }
                .width('100%')
                .padding({ top: 10, bottom: 10, left: 8, right: 8 })
                .backgroundColor(this.selectedPreviewSchema?.version === schema.version
                  ? ColorResource.primaryUltraLight
                  : Color.Transparent)
                .borderRadius(8)
                .onClick(() => {
                  this.selectedPreviewSchema = schema;
                });
              }
            })
          }
          .width('60%')
          .height(280)
          .edgeEffect(EdgeEffect.Spring);

          // 右侧：卡片预览（使用 key 强制刷新）
          Column({ space: 8 }) {
            Text('卡片预览')
              .fontSize(12)
              .fontColor(ColorResource.textSecondary);

            if (this.selectedPreviewSchema) {
              // 使用独立 @Component 组件确保响应式刷新
              HistoryCardPreview({ schema: this.selectedPreviewSchema });

              // 样式信息
              Column({ space: 4 }) {
                Row({ space: 4 }) {
                  Text('主题色')
                    .fontSize(9)
                    .fontColor(ColorResource.textTertiary);
                  Circle()
                    .width(10)
                    .height(10)
                    .fill(this.selectedPreviewSchema.style.fillColor);
                }

                // 关键色
                if (this.selectedPreviewSchema.style.criticalColor) {
                  Row({ space: 4 }) {
                    Text('关键色')
                      .fontSize(9)
                      .fontColor(ColorResource.textTertiary);
                    Circle()
                      .width(10)
                      .height(10)
                      .fill(this.selectedPreviewSchema.style.criticalColor);
                  }
                }

                if (this.selectedPreviewSchema.style.borderRadius !== undefined) {
                  Text(`圆角: ${this.selectedPreviewSchema.style.borderRadius}px`)
                    .fontSize(9)
                    .fontColor(ColorResource.textTertiary);
                }

                // 组件数量
                Text(`组件: ${this.selectedPreviewSchema.layout?.length || 0} 个`)
                  .fontSize(9)
                  .fontColor(ColorResource.textTertiary);
              }
              .margin({ top: 8 })
              .key(`info_${this.selectedPreviewSchema.version}_${this.selectedPreviewSchema.style.criticalColor || 'none'}`);
            } else {
              Column() {
                Text('点击左侧版本查看预览')
                  .fontSize(11)
                  .fontColor(ColorResource.textTertiary);
              }
              .width(100)
              .height(70)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(ColorResource.backgroundSecondary)
              .borderRadius(8);
            }
          }
          .width('40%')
          .height(280)
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Center);
        }
        .width('100%');
      }

      Button('关闭')
        .width('100%')
        .height(44)
        .fontSize(15)
        .backgroundColor(ColorResource.surface)
        .fontColor(ColorResource.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close();
        });
    }
    .width('90%')
    .constraintSize({ maxWidth: 500 })
    .padding(16)
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14);
  }
}

@CustomDialog
struct RenameNodeDialog {
  controller: CustomDialogController;
  oldName: string = '';
  @State newName: string = '';
  onConfirm: (name: string) => void = () => {
  };

  aboutToAppear() {
    this.newName = this.oldName;
  }

  build() {
    Column({ space: 16 }) {
      Text('重命名节点类型')
        .fontSize(17)
        .fontWeight(FontWeight.Medium);

      TextInput({ text: this.newName, placeholder: '请输入新的名称' })
        .onChange((value) => {
          this.newName = value;
        })
        .width('100%');

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor(ColorResource.surfaceSubtle)
          .fontColor(ColorResource.textPrimary)
          .onClick(() => this.controller.close());

        Button('确定')
          .layoutWeight(1)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .onClick(() => {
            if (this.newName.trim()) {
              this.onConfirm(this.newName);
              this.controller.close();
            }
          });
      }
      .width('100%');
    }
    .width(300)
    .padding(24)
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(12);
  }
}

@Entry
@Component
struct NodeWorkspacePage {
  private schemaService: NodeSchemaService = NodeSchemaService.getInstance();
  private errorBoundary: SchemaErrorBoundary = new SchemaErrorBoundary();
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private autoSaveTimer: number = -1;
  private readonly AUTO_SAVE_DELAY = 500;
  @State schemas: NodeSchema[] = [];
  @State selectedSchemaId: string | null = null;
  @State selectedSchemaObject: NodeSchema | null = null;
  @State schemaJson: string = '';
  @State showColorPicker: boolean = false;
  @State editingColorType: 'fill' | 'border' | 'critical' = 'fill';
  @State tempColor: string = '#007AFF';
  @State showBasicSection: boolean = true;
  @State showStyleSection: boolean = true;
  @State showFieldsSection: boolean = false;
  @State showLayoutSection: boolean = false;
  @State filterMode: 'all' | 'published' | 'draft' = 'all';
  @State searchKeyword: string = '';
  @State previewUpdatePending: boolean = false;
  @State currentEditorTab: number = 0;
  @State selectedComponentId: string | null = null;
  @State selectedComponentObject: NodeComponentSchema | null = null;
  @State componentRefreshKey: number = 0;
  @State currentViewMode: 'visual' | 'classic' = 'visual';
  @State draggedLibraryType: NodeComponentType | null = null;
  // 布局管理状态
  @State panelWidths: number[] = [20, 25, 30, 25]; // 默认宽度百分比
  @State panelCollapsed: boolean[] = [false, false, false, false]; // 折叠状态
  private readonly DEFAULT_WIDTHS = [20, 25, 30, 25];
  private deleteDialogController: CustomDialogController | null = null;
  private importConflictDialogController: CustomDialogController | null = null;
  private colorPickerDialogController: CustomDialogController | null = null;
  private importJsonDialogController: CustomDialogController | null = null;
  private exportJsonDialogController: CustomDialogController | null = null;
  private renameDialogController: CustomDialogController | null = null;
  private historyDialogController: CustomDialogController | null = null;
  private diffDialogController: CustomDialogController | null = null;
  private previewThrottleTimer: number = -1;
  private readonly PREVIEW_THROTTLE_DELAY = 80;

  private isValidColor(color: string): boolean {
    if (!color || color.trim().length === 0) {
      return false;
    }
    const hexPattern = /^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$/;
    const rgbPattern = /^rgb\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\)$/;
    const rgbaPattern = /^rgba\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*(0|1|0?\.\d+)\s*\)$/;

    return hexPattern.test(color.trim()) ||
    rgbPattern.test(color.trim()) ||
    rgbaPattern.test(color.trim());
  }

  aboutToAppear() {
    console.log('[NodeWorkspace] aboutToAppear (schema workspace v3 - three columns)');
    this.reloadSchemas();
    this.refreshSchemaJson();
    // 初始化错误边界快照
    this.errorBoundary.saveSnapshot(this.schemas);
    this.updateSelectedSchemaObject();
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.autoSaveTimer !== -1) {
      clearTimeout(this.autoSaveTimer);
      this.autoSaveTimer = -1;
    }
    if (this.previewThrottleTimer !== -1) {
      clearTimeout(this.previewThrottleTimer);
      this.previewThrottleTimer = -1;
    }
  }

  private reloadSchemas(): void {
    try {
      const preservedComponentId: string | null = this.selectedComponentId;
      const newSchemas = this.schemaService.getAllSchemas();
      // 使用错误边界验证和应用更新
      this.schemas = this.errorBoundary.safeApplyUpdate(newSchemas, this.schemas);
      if (!this.selectedSchemaId && this.schemas.length > 0) {
        this.selectedSchemaId = this.schemas[0].id;
      }
      this.updateSelectedSchemaObject();
      // 保留组件选择（仅在组件确实不存在时清空）
      if (this.selectedSchemaId && preservedComponentId) {
        const schema = this.schemaService.getSchemaById(this.selectedSchemaId);
        if (schema && schema.layout && schema.layout.some(c => c.id === preservedComponentId)) {
          this.selectedComponentId = preservedComponentId;
        } else {
          this.selectedComponentId = null;
        }
      }
    } catch (error) {
      console.error('[NodeWorkspace] reloadSchemas error:', error);
      this.errorBoundary.recordError(
        error instanceof Error ? error : new Error(String(error)),
        ErrorType.RENDER_ERROR,
        'reloadSchemas'
      );
      this.promptAction.showToast({
        message: '加载节点类型失败，已回滚到稳定状态',
        duration: 2000
      });
    }
  }

  private handleComponentDragStart(type: NodeComponentType): void {
    this.draggedLibraryType = type;
  }

  private handleComponentDragEnd(): void {
    this.draggedLibraryType = null;
  }

  /**
   * 自动保存（Debounce 500ms）
   */
  private scheduleAutoSave(): void {
    // 清除之前的定时器
    if (this.autoSaveTimer !== -1) {
      clearTimeout(this.autoSaveTimer);
    }

    // 设置新的定时器
    this.autoSaveTimer = setTimeout(() => {
      this.errorBoundary.tryWithRollbackAsync(
        async () => {
          await this.schemaService.saveToStorage();
          console.log('[NodeWorkspace] Auto-save completed');
          // 保存成功后更新快照
          this.errorBoundary.saveSnapshot(this.schemas);
        },
        ErrorType.STORAGE_ERROR,
        'autoSave'
      ).catch((error: Error) => {
        console.error('[NodeWorkspace] Auto-save failed:', error);
        this.promptAction.showToast({
          message: '自动保存失败',
          duration: 2000
        });
      });
      this.autoSaveTimer = -1;
    }, this.AUTO_SAVE_DELAY);
  }

  private refreshSchemaJson(): void {
    this.schemaJson = this.schemaService.exportSchemasToJson();
  }

  private handleImportFromJson(): void {
    // 先验证 JSON
    const errorMsg = this.schemaService.validateSchemaJson(this.schemaJson);
    if (errorMsg.length > 0) {
      this.promptAction.showToast({
        message: `导入失败：${errorMsg}`,
        duration: 3000
      });
      return;
    }

    // 检查 ID 冲突
    const conflicts = this.detectImportConflicts(this.schemaJson);
    if (conflicts.length > 0) {
      this.showImportConflictDialog(conflicts);
      return;
    }

    // 无冲突，直接导入
    this.performImport();
  }

  private detectImportConflicts(jsonStr: string): ConflictSchema[] {
    try {
      const importedSchemas: NodeSchema[] = JSON.parse(jsonStr) as NodeSchema[];
      const existingIds = new Set(this.schemas.map(s => s.id));
      const conflicts: ConflictSchema[] = [];

      importedSchemas.forEach(schema => {
        if (existingIds.has(schema.id)) {
          conflicts.push({ id: schema.id, name: schema.name });
        }
      });

      return conflicts;
    } catch (error) {
      console.error('[NodeWorkspace] detectImportConflicts error:', error);
      return [];
    }
  }

  private showImportConflictDialog(conflicts: ConflictSchema[]): void {
    if (this.importConflictDialogController) {
      this.importConflictDialogController.close();
      this.importConflictDialogController = null;
    }

    this.importConflictDialogController = new CustomDialogController({
      builder: ImportConflictDialog({
        conflictSchemas: conflicts,
        onResolve: (resolution: 'rename' | 'newId' | 'skip') => {
          this.resolveImportConflicts(resolution);
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.importConflictDialogController.open();
  }

  private resolveImportConflicts(resolution: 'rename' | 'newId' | 'skip'): void {
    try {
      const importedSchemas: NodeSchema[] = JSON.parse(this.schemaJson) as NodeSchema[];
      const existingIds = new Set(this.schemas.map(s => s.id));

      const resolvedSchemas: NodeSchema[] = [];

      for (const schema of importedSchemas) {
        if (!existingIds.has(schema.id)) {
          resolvedSchemas.push(schema);
          continue;
        }

        switch (resolution) {
          case 'rename':
            const renamedSchema: NodeSchema = {
              id: schema.id,
              version: schema.version,
              name: `${schema.name}_imported_${Date.now()}`,
              description: schema.description,
              meta: schema.meta,
              ports: schema.ports,
              style: schema.style,
              fields: schema.fields,
              layout: schema.layout,
              rules: schema.rules,
              isSystem: schema.isSystem,
              isDraft: schema.isDraft,
              parentVersionId: schema.parentVersionId
            };
            resolvedSchemas.push(renamedSchema);
            break;
          case 'newId':
            const newIdSchema: NodeSchema = {
              id: `${schema.id}_${Date.now()}`,
              version: schema.version,
              name: schema.name,
              description: schema.description,
              meta: schema.meta,
              ports: schema.ports,
              style: schema.style,
              fields: schema.fields,
              layout: schema.layout,
              rules: schema.rules,
              isSystem: schema.isSystem,
              isDraft: schema.isDraft,
              parentVersionId: schema.parentVersionId
            };
            resolvedSchemas.push(newIdSchema);
            break;
          case 'skip':
            break;
        }
      }

      // 更新 JSON 并导入
      this.schemaJson = JSON.stringify(resolvedSchemas, null, 2);
      this.performImport();

    } catch (error) {
      console.error('[NodeWorkspace] resolveImportConflicts error:', error);
      this.promptAction.showToast({
        message: '解决冲突失败',
        duration: 2000
      });
    }
  }

  private performImport(): void {
    // 使用错误边界保护导入操作
    const result = this.errorBoundary.tryWithRollback(
      () => {
        const ok = this.schemaService.importSchemasFromJson(this.schemaJson);
        if (!ok) {
          throw new Error('导入失败，请检查 JSON 格式');
        }
        return ok;
      },
      ErrorType.VALIDATION_ERROR,
      'importFromJson'
    );

    if (result) {
      this.reloadSchemas();
      this.schemaService.saveToStorage();
      this.promptAction.showToast({
        message: `成功导入 ${this.schemas.length} 个节点类型`,
        duration: 2000
      });
    } else {
      // 已经回滚到稳定状态
      this.reloadSchemas();
      this.promptAction.showToast({
        message: '导入失败，已回滚到之前的状态',
        duration: 2000
      });
    }
  }

  private updateSelectedSchemaObject(): void {
    this.selectedSchemaObject = this.getSelectedSchema();
  }

  private getSelectedSchema(): NodeSchema | null {
    if (!this.selectedSchemaId) {
      return null;
    }
    const schema = this.schemaService.getSchemaById(this.selectedSchemaId);
    return schema;
  }

  private isSelectedSchemaSystem(): boolean {
    const schema = this.getSelectedSchema();
    return !!(schema && schema.isSystem);
  }

  private createNewSchema(): void {
    const index = this.schemas.length + 1;
    const id = `custom_${Date.now()}`;
    const now = Date.now();
    const newSchema: NodeSchema = {
      id: id,
      version: 1,
      name: `自定义类型${index}`,
      description: '用户自定义的节点类型',
      meta: {
        author: 'user',
        createdAt: now,
        updatedAt: now,
        category: 'custom'
      },
      style: { fillColor: '#34C759' },
      fields: [],
      layout: [],
      rules: [],
      isSystem: false,
      isDraft: true
    };
    this.schemaService.upsertSchema(newSchema);
    this.selectedSchemaId = id;
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private showDiffDialog(oldSchema: NodeSchema, newSchema: NodeSchema): void {
    if (this.diffDialogController) {
      this.diffDialogController.close();
      this.diffDialogController = null;
    }
    this.diffDialogController = new CustomDialogController({
      builder: VersionDiffDialog({
        oldSchema: oldSchema,
        newSchema: newSchema
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.diffDialogController.open();
  }

  private showHistoryDialog(schema: NodeSchema): void {
    if (this.historyDialogController) {
      this.historyDialogController.close();
      this.historyDialogController = null;
    }
    this.historyDialogController = new CustomDialogController({
      builder: HistoryDialog({
        schemaId: schema.id,
        schemaName: schema.name,
        onRestore: (version: number) => {
          const success = this.schemaService.restoreToDraft(schema.id, version);
          if (success) {
            this.reloadSchemas();
            this.scheduleAutoSave();
            this.promptAction.showToast({
              message: `已将 v${version} 恢复为草稿`,
              duration: 2000
            });
          } else {
            this.promptAction.showToast({
              message: '恢复失败：当前已存在草稿，请先处理草稿',
              duration: 3000
            });
          }
        },
        onCompare: (oldVersion: NodeSchema, newVersion: NodeSchema) => {
          this.showDiffDialog(oldVersion, newVersion);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.historyDialogController.open();
  }

  private showRenameDialog(schema: NodeSchema): void {
    if (this.renameDialogController) {
      this.renameDialogController.close();
      this.renameDialogController = null;
    }
    this.renameDialogController = new CustomDialogController({
      builder: RenameNodeDialog({
        oldName: schema.name,
        onConfirm: (newName: string) => {
          // Temporarily select the schema to update it
          const originalSelected = this.selectedSchemaId;
          this.selectedSchemaId = schema.id;
          this.updateSelectedSchemaName(newName);
          this.selectedSchemaId = originalSelected;
          this.updateSelectedSchemaObject();
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.renameDialogController.open();
  }

  private showDeleteSchemaDialog(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    if (schema.isSystem) {
      this.promptAction.showToast({ message: '内置节点类型无法删除' });
      return;
    }

    this.deleteDialogController = new CustomDialogController({
      builder: DeleteConfirmDialog({
        schemaName: schema.name,
        onConfirm: () => {
          this.deleteSelectedSchema();
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });

    this.deleteDialogController.open();
  }

  private showImportDialog(): void {
    this.importJsonDialogController = new CustomDialogController({
      builder: ImportJsonDialog({
        onConfirm: (json: string) => {
          this.handleQuickImportFromJson(json);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });

    this.importJsonDialogController.open();
  }

  private showExportDialog(): void {
    this.refreshSchemaJson();
    this.exportJsonDialogController = new CustomDialogController({
      builder: ExportJsonDialog({
        json: this.schemaJson
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });
    this.exportJsonDialogController.open();
  }

  private handleQuickImportFromJson(json: string): void {
    if (!json || json.trim().length === 0) {
      this.promptAction.showToast({ message: '请输入JSON数据', duration: 2000 });
      return;
    }

    try {
      const parsed: Object = JSON.parse(json);

      // 处理数组情况（批量导入）
      if (Array.isArray(parsed)) {
        const parsedArray = parsed as object[];
        let successCount = 0;
        let failCount = 0;

        parsedArray.forEach((item: object) => {
          const schema = item as NodeSchema;
          // 简单验证
          if (schema.id && schema.name && schema.style) {
            // 确保可选字段存在
            if (!schema.fields) {
              schema.fields = [];
            }
            if (!schema.layout) {
              schema.layout = [];
            }
            if (!schema.rules) {
              schema.rules = [];
            }

            this.schemaService.upsertSchema(schema);
            successCount++;
          } else {
            failCount++;
          }
        });

        this.reloadSchemas();
        this.refreshSchemaJson();
        if (successCount > 0) {
          this.promptAction.showToast({
            message: `批量导入成功：${successCount} 个` + (failCount > 0 ? `，失败 ${failCount} 个` : ''),
            duration: 2000
          });
        } else {
          this.promptAction.showToast({ message: '导入失败：未找到有效的节点类型数据', duration: 2000 });
        }
        return;
      }

      // 处理单个对象情况
      const schema = parsed as NodeSchema;

      // 验证必要字段
      if (!schema.id || !schema.name || !schema.style) {
        this.promptAction.showToast({ message: 'JSON格式不正确，缺少必要字段(id, name, style)', duration: 2000 });
        return;
      }

      // 补充缺失的可选字段
      if (!schema.fields) {
        schema.fields = [];
      }
      if (!schema.layout) {
        schema.layout = [];
      }
      if (!schema.rules) {
        schema.rules = [];
      }

      // 检查是否已存在
      const existing = this.schemas.find(s => s.id === schema.id);
      if (existing) {
        this.promptAction.showToast({ message: `节点类型"${schema.name}"已存在，将覆盖旧版本`, duration: 2000 });
      }

      this.schemaService.upsertSchema(schema);
      this.reloadSchemas();
      this.selectedSchemaId = schema.id;
      this.promptAction.showToast({ message: `导入成功：${schema.name}`, duration: 2000 });
    } catch (error) {
      console.error('导入JSON失败', error);
      this.promptAction.showToast({ message: 'JSON格式错误，解析失败', duration: 2000 });
    }
  }

  private deleteSelectedSchema(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    this.schemaService.deleteSchema(schema.id);
    this.reloadSchemas();
    this.scheduleAutoSave();
    if (this.schemas.length > 0) {
      this.selectedSchemaId = this.schemas[0].id;
    } else {
      this.selectedSchemaId = null;
    }
    this.refreshSchemaJson();
    this.promptAction.showToast({ message: '节点类型已删除' });
  }

  private updateSelectedSchemaName(name: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    if (!name || name.trim().length === 0) {
      this.promptAction.showToast({ message: '节点类型名称不能为空' });
      return;
    }

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: name.trim(),
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: schema.fields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };
    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.updateSelectedSchemaObject();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateSelectedSchemaDescription(description: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: schema.fields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };
    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.updateSelectedSchemaObject();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateSelectedSchemaColor(color: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    if (!this.isValidColor(color)) {
      this.promptAction.showToast({ message: '颜色格式无效，请使用 #RRGGBB 格式' });
      return;
    }

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: {
        fillColor: color.trim(),
        criticalColor: schema.style.criticalColor,
        borderColor: schema.style.borderColor,
        borderRadius: schema.style.borderRadius,
        borderWidth: schema.style.borderWidth,
        icon: schema.style.icon,
        badgeColor: schema.style.badgeColor
      },
      fields: schema.fields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };
    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.updateSelectedSchemaObject();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateSelectedSchemaBorderColor(color: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    if (color.trim().length > 0 && !this.isValidColor(color)) {
      this.promptAction.showToast({ message: '颜色格式无效，请使用 #RRGGBB 格式' });
      return;
    }

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: {
        fillColor: schema.style.fillColor,
        criticalColor: schema.style.criticalColor,
        borderColor: color.trim().length > 0 ? color.trim() : undefined,
        borderRadius: schema.style.borderRadius,
        borderWidth: schema.style.borderWidth,
        icon: schema.style.icon,
        badgeColor: schema.style.badgeColor
      },
      fields: schema.fields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };
    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.updateSelectedSchemaObject();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateSelectedSchemaBorderRadius(radius: number): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    if (radius < 0) {
      return;
    }

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: {
        fillColor: schema.style.fillColor,
        criticalColor: schema.style.criticalColor,
        borderColor: schema.style.borderColor,
        borderRadius: radius,
        borderWidth: schema.style.borderWidth,
        icon: schema.style.icon,
        badgeColor: schema.style.badgeColor
      },
      fields: schema.fields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };
    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.updateSelectedSchemaObject();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateSelectedSchemaCriticalColor(color: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: {
        fillColor: schema.style.fillColor,
        criticalColor: color.trim().length > 0 ? color.trim() : undefined,
        borderColor: schema.style.borderColor,
        borderRadius: schema.style.borderRadius,
        borderWidth: schema.style.borderWidth,
        icon: schema.style.icon,
        badgeColor: schema.style.badgeColor
      },
      fields: schema.fields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };
    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.updateSelectedSchemaObject();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private showColorPickerDialog(colorType: 'fill' | 'border' | 'critical'): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    this.editingColorType = colorType;

    if (colorType === 'fill') {
      this.tempColor = schema.style.fillColor;
    } else if (colorType === 'border') {
      this.tempColor = schema.style.borderColor || schema.style.fillColor;
    } else if (colorType === 'critical') {
      this.tempColor = schema.style.criticalColor || '#FF3B30';
    }

    if (this.colorPickerDialogController) {
      this.colorPickerDialogController.close();
      this.colorPickerDialogController = null;
    }

    this.colorPickerDialogController = new CustomDialogController({
      builder: NodeColorPickerDialog({
        currentColor: this.tempColor,
        onConfirm: (color: string) => {
          if (this.editingColorType === 'fill') {
            this.updateSelectedSchemaColor(color);
          } else if (this.editingColorType === 'border') {
            this.updateSelectedSchemaBorderColor(color);
          } else if (this.editingColorType === 'critical') {
            this.updateSelectedSchemaCriticalColor(color);
          }
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.colorPickerDialogController.open();
  }

  private updateSelectedSchemaIcon(icon: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: {
        fillColor: schema.style.fillColor,
        criticalColor: schema.style.criticalColor,
        borderColor: schema.style.borderColor,
        borderRadius: schema.style.borderRadius,
        borderWidth: schema.style.borderWidth,
        icon: icon.trim().length > 0 ? icon.trim() : undefined,
        badgeColor: schema.style.badgeColor
      },
      fields: schema.fields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };
    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private addFieldToSelectedSchema(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const newField: FieldSchema = {
      id: `field_${Date.now()}`,
      label: '新字段',
      type: 'text',
      required: false
    };

    const updatedFields: FieldSchema[] = [];
    for (const field of schema.fields) {
      updatedFields.push(field);
    }
    updatedFields.push(newField);

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: updatedFields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };

    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private deleteFieldFromSelectedSchema(fieldId: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const updatedFields = schema.fields.filter(f => f.id !== fieldId);
    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: updatedFields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };

    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateFieldInSelectedSchema(fieldId: string, updatedField: FieldSchema): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    // 检查字段是否已存在
    const existingIndex = schema.fields.findIndex(f => f.id === fieldId);
    let updatedFields: FieldSchema[];
    if (existingIndex >= 0) {
      // 更新现有字段
      updatedFields = schema.fields.map(f => f.id === fieldId ? updatedField : f);
    } else {
      // 添加新字段
      updatedFields = [...schema.fields, updatedField];
    }
    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: updatedFields,
      layout: schema.layout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };

    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private addComponentToSelectedSchema(type: NodeComponentType = 'TITLE', index: number = -1): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const newComponent: NodeComponentSchema = {
      id: `component_${Date.now()}`,
      type: type
    };

    const updatedLayout: NodeComponentSchema[] = [...schema.layout];
    if (index >= 0 && index <= updatedLayout.length) {
      updatedLayout.splice(index, 0, newComponent);
    } else {
      updatedLayout.push(newComponent);
    }

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: schema.fields,
      layout: updatedLayout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };

    this.schemaService.upsertSchema(updated);
    this.selectedComponentId = newComponent.id;
    this.draggedLibraryType = null;
    this.reloadSchemas();
    this.updateSelectedComponentObject();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private deleteComponentFromSelectedSchema(componentId: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const updatedLayout = schema.layout.filter(c => c.id !== componentId);
    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: schema.fields,
      layout: updatedLayout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };

    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateComponentInSelectedSchema(componentId: string, updatedComponent: NodeComponentSchema): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const updatedLayout = schema.layout.map(c => c.id === componentId ? updatedComponent : c);
    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: schema.fields,
      layout: updatedLayout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };

    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.updateSelectedSchemaObject();
    this.updateSelectedComponentObject();
    this.componentRefreshKey++;
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private getFieldTypeLabel(type: FieldType): string {
    const typeMap: Record<string, string> = {
      'text': '文本',
      'number': '数字',
      'date': '日期',
      'boolean': '布尔',
      'select': '选择',
      'checklist': '清单'
    };
    return typeMap[type] || type;
  }

  private getComponentTypeLabel(type: NodeComponentType): string {
    const typeMap: Record<string, string> = {
      'TITLE': '标题',
      'DATE_RANGE': '日期范围',
      'TIME_PROGRESS': '时间进度',
      'TASK_PROGRESS': '任务进度',
      'CHECKLIST_SUMMARY': '清单统计',
      'PRIORITY_BADGE': '优先级',
      'ASSIGNEE': '负责人',
      'TAGS': '标签',
      'STATUS_DOT': '状态点',
      'CUSTOM_FIELD': '自定义字段'
    };
    return typeMap[type] || type;
  }

  private duplicateSelectedSchema(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const now = Date.now();
    const newId = `${schema.id}_copy_${Date.now()}`;
    const duplicated: NodeSchema = {
      id: newId,
      version: 1,
      name: `${schema.name} (副本)`,
      description: schema.description,
      meta: {
        author: 'user',
        createdAt: now,
        updatedAt: now,
        category: schema.meta?.category || 'custom'
      },
      ports: schema.ports ? [...schema.ports] : [],
      style: {
        fillColor: schema.style.fillColor,
        borderColor: schema.style.borderColor,
        borderRadius: schema.style.borderRadius,
        icon: schema.style.icon,
        badgeColor: schema.style.badgeColor
      },
      fields: [...schema.fields],
      layout: [...schema.layout],
      rules: schema.rules ? [...schema.rules] : [],
      isSystem: false,
      isDraft: true
    };

    this.schemaService.upsertSchema(duplicated);
    this.selectedSchemaId = newId;
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
    this.promptAction.showToast({
      message: `已复制节点类型"${schema.name}"`,
      duration: 2000
    });
  }

  private publishSelectedDraft(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    if (!schema.isDraft) {
      this.promptAction.showToast({ message: '该节点类型已是发布状态' });
      return;
    }
    if (schema.isSystem) {
      this.promptAction.showToast({ message: '系统内置类型无法发布' });
      return;
    }

    const ok = this.schemaService.publishDraft(schema.id);
    if (ok) {
      this.reloadSchemas();
      // 确保立即更新选中的 schema 对象以刷新按钮状态
      this.updateSelectedSchemaObject();
      this.scheduleAutoSave();
      this.promptAction.showToast({
        message: `节点类型"${schema.name}"已发布（版本 ${schema.version + 1}）`,
        duration: 2000
      });
    } else {
      this.promptAction.showToast({
        message: '发布失败',
        duration: 2000
      });
    }
  }

  private toggleSchemaPublishState(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    if (schema.isDraft) {
      this.publishSelectedDraft();
    } else {
      this.createDraftFromSelectedPublished();
    }
  }

  private createDraftFromSelectedPublished(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    if (schema.isDraft) {
      this.promptAction.showToast({ message: '该节点类型已是草稿状态' });
      return;
    }

    const ok = this.schemaService.createDraftFromPublished(schema.id);
    if (ok) {
      this.reloadSchemas();
      // 确保立即更新选中的 schema 对象以刷新按钮状态
      this.updateSelectedSchemaObject();
      this.scheduleAutoSave();
      this.promptAction.showToast({
        message: `已从"${schema.name}"创建草稿`,
        duration: 2000
      });
    } else {
      this.promptAction.showToast({
        message: '创建草稿失败（可能已存在草稿）',
        duration: 2000
      });
    }
  }

  private getFilteredSchemas(): NodeSchema[] {
    let filtered = this.schemas;

    // 按发布状态过滤
    if (this.filterMode === 'published') {
      filtered = filtered.filter(s => !s.isDraft);
    } else if (this.filterMode === 'draft') {
      filtered = filtered.filter(s => s.isDraft);
    }

    // 按搜索关键词过滤
    if (this.searchKeyword && this.searchKeyword.trim().length > 0) {
      const keyword = this.searchKeyword.trim().toLowerCase();
      filtered = filtered.filter(s =>
      s.name.toLowerCase().includes(keyword) ||
        (s.description && s.description.toLowerCase().includes(keyword)) ||
      s.id.toLowerCase().includes(keyword)
      );
    }

    return filtered;
  }

  private handleComponentSelect(componentId: string): void {
    this.selectedComponentId = componentId;
    this.updateSelectedComponentObject();
  }

  private handleComponentDelete(componentId: string): void {
    this.deleteComponentFromSelectedSchema(componentId);
    this.selectedComponentId = null;
    this.selectedComponentObject = null;
  }

  private handleComponentPropertyChange(component: NodeComponentSchema): void {
    this.updateComponentInSelectedSchema(component.id, component);
  }

  private handleComponentLibraryClick(type: NodeComponentType): void {
    this.addComponentToSelectedSchema(type, -1);
  }

  private handleComponentReorder(fromIndex: number, toIndex: number): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }

    const updatedLayout = [...schema.layout];
    const movedItem = updatedLayout.splice(fromIndex, 1)[0];

    // 计算插入位置
    let insertIndex = toIndex;
    if (fromIndex < toIndex) {
      insertIndex = toIndex - 1;
    }

    updatedLayout.splice(insertIndex, 0, movedItem);

    const updated: NodeSchema = {
      id: schema.id,
      version: schema.version,
      name: schema.name,
      description: schema.description,
      meta: schema.meta,
      ports: schema.ports,
      style: schema.style,
      fields: schema.fields,
      layout: updatedLayout,
      rules: schema.rules,
      isSystem: schema.isSystem,
      isDraft: schema.isDraft,
      parentVersionId: schema.parentVersionId
    };

    this.schemaService.upsertSchema(updated);
    this.reloadSchemas();
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private getSelectedComponent(): NodeComponentSchema | null {
    const schema = this.getSelectedSchema();
    if (!schema || !this.selectedComponentId) {
      return null;
    }
    const component = schema.layout.find(c => c.id === this.selectedComponentId);
    return component || null;
  }

  private updateSelectedComponentObject(): void {
    const component = this.getSelectedComponent();
    if (component) {
      // 创建新对象引用以确保@Prop检测到变化
      this.selectedComponentObject = {
        id: component.id,
        type: component.type,
        fieldId: component.fieldId,
        props: component.props ? {
          style: component.props.style,
          maxLines: component.props.maxLines,
          highlight: component.props.highlight,
          color: component.props.color
        } : undefined
      };
    } else {
      this.selectedComponentObject = null;
    }
  }

  // 布局管理方法
  private togglePanelCollapse(index: number): void {
    this.panelCollapsed[index] = !this.panelCollapsed[index];
  }

  private getPanelTitle(index: number): string {
    const titles = ['节点类型库', '组件库', '可视化画布', '属性编辑器'];
    return titles[index] || '';
  }

  private resetLayout(): void {
    this.panelWidths = [...this.DEFAULT_WIDTHS];
    this.panelCollapsed = [false, false, false, false];
    this.promptAction.showToast({ message: '布局已重置', duration: 1500 });
  }

  private getActualPanelWidth(index: number): string {
    if (this.panelCollapsed[index]) {
      return '0px'; // 折叠后完全隐藏
    }

    // 计算实际宽度百分比（排除已折叠的面板）
    const collapsedCount = this.panelCollapsed.filter(c => c).length;
    if (collapsedCount === 0) {
      return `${this.panelWidths[index]}%`;
    }

    // 重新分配剩余空间
    const activeWidthSum = this.panelWidths
      .filter((_, i) => !this.panelCollapsed[i])
      .reduce((sum, w) => sum + w, 0);

    if (activeWidthSum === 0) {
      return '25%';
    }

    const ratio = 100 / activeWidthSum;
    return `${this.panelWidths[index] * ratio}%`;
  }

  /**
   * 节流预览更新（80ms）
   */
  private schedulePreviewUpdate(): void {
    this.previewUpdatePending = true;

    if (this.previewThrottleTimer !== -1) {
      return; // 已有待处理的更新
    }

    this.previewThrottleTimer = setTimeout(() => {
      this.previewUpdatePending = false;
      this.previewThrottleTimer = -1;
      // 触发预览重新渲染（通过状态变化）
      console.log('[NodeWorkspace] Preview update executed');
    }, this.PREVIEW_THROTTLE_DELAY);
  }

  // 左侧：节点类型列表（20%宽度）
  @Builder
  private SchemaList() {
    Column({ space: 0 }) {

      // 标题区
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('节点类型库')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Text(`${this.getFilteredSchemas().length}`)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(Color.White)
            .padding({
              left: 6,
              right: 6,
              top: 2,
              bottom: 2
            })
            .backgroundColor(ColorResource.primaryColor)
            .borderRadius(8);
        }
        .width('100%');

        // 搜索框
        TextInput({ text: this.searchKeyword, placeholder: '搜索节点类型' })
          .width('100%')
          .height(36)
          .fontSize(ThemeConfig.fontSizeS)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.searchKeyword = value;
          });

        // 过滤器
        Row({ space: 6 }) {
          Text('全部')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.filterMode === 'all' ? Color.White : ColorResource.textSecondary)
            .padding({
              left: 10,
              right: 10,
              top: 4,
              bottom: 4
            })
            .backgroundColor(this.filterMode === 'all' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.filterMode = 'all';
            });

          Text('已发布')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.filterMode === 'published' ? Color.White : ColorResource.textSecondary)
            .padding({
              left: 10,
              right: 10,
              top: 4,
              bottom: 4
            })
            .backgroundColor(this.filterMode === 'published' ? ColorResource.primaryColor :
              ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.filterMode = 'published';
            });

          Text('草稿')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.filterMode === 'draft' ? Color.White : ColorResource.textSecondary)
            .padding({
              left: 10,
              right: 10,
              top: 4,
              bottom: 4
            })
            .backgroundColor(this.filterMode === 'draft' ? ColorResource.primaryColor :
              ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.filterMode = 'draft';
            });
        }
        .width('100%');
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: 16,
        right: 16,
        top: 16,
        bottom: 8
      });

      Scroll() {
        Column({ space: 4 }) {
          if (this.getFilteredSchemas().length === 0) {
            Text('暂无类型')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary);
          } else {
            ForEach(this.getFilteredSchemas(), (schema: NodeSchema) => {
              Row({ space: 10 }) {
                Circle()
                  .width(10)
                  .height(10)
                  .fill(schema.style.fillColor);

                Column({ space: 2 }) {
                  Row({ space: 6 }) {
                    Text(schema.name)
                      .fontSize(ThemeConfig.fontSizeS)
                      .fontWeight(this.selectedSchemaId === schema.id ? FontWeight.Medium : FontWeight.Normal)
                      .fontColor(this.selectedSchemaId === schema.id ? ColorResource.primaryColor :
                        ColorResource.textPrimary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1);

                    if (schema.isDraft) {
                      Text('草稿')
                        .fontSize(ThemeConfig.fontSizeXS - 1)
                        .fontColor('#FF9500')
                        .padding({
                          left: 4,
                          right: 4,
                          top: 1,
                          bottom: 1
                        })
                        .backgroundColor('rgba(255, 149, 0, 0.1)')
                        .borderRadius(3);
                    }

                    if (schema.isDefault) {
                      Text('默认')
                        .fontSize(ThemeConfig.fontSizeXS - 1)
                        .fontColor(ColorResource.primaryColor)
                        .padding({
                          left: 4,
                          right: 4,
                          top: 1,
                          bottom: 1
                        })
                        .backgroundColor('rgba(0, 122, 255, 0.1)')
                        .borderRadius(3);
                    }
                  }
                  .width('100%');

                  if (schema.version > 1 || schema.isSystem) {
                    Row({ space: 6 }) {
                      if (schema.isSystem) {
                        Text('系统')
                          .fontSize(ThemeConfig.fontSizeXS - 2)
                          .fontColor(ColorResource.textTertiary)
                          .opacity(0.7);
                      }
                      if (schema.version > 1) {
                        Text(`v${schema.version}`)
                          .fontSize(ThemeConfig.fontSizeXS - 2)
                          .fontColor(ColorResource.textTertiary)
                          .opacity(0.7);
                      }
                    }
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);

                // 更多操作菜单
                Row() {
                  Text('⋮')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ColorResource.textSecondary)
                    .textAlign(TextAlign.Center)
                    .width(24)
                    .height(24);
                }
                .margin({ left: 4 })
                .borderRadius(4)
                .backgroundColor(Color.Transparent)
                .bindMenu([
                  {
                    value: '编辑名称',
                    enabled: !schema.isSystem,
                    action: () => {
                      this.showRenameDialog(schema);
                    }
                  },
                  {
                    value: schema.isDefault ? '已设为默认' : '设为默认',
                    enabled: !schema.isDefault,
                    action: () => {
                      this.schemaService.setDefaultSchema(schema.id);
                      this.reloadSchemas();
                    }
                  },
                  {
                    value: '版本历史',
                    enabled: true,
                    action: () => {
                      this.showHistoryDialog(schema);
                    }
                  },
                  {
                    value: '当前版本: ' + (schema.isDraft ? `草稿(v${schema.version})` : `v${schema.version}`),
                    enabled: false, // 仅展示信息
                    action: () => {
                    }
                  }
                ])
              }
              .width('100%')
              .padding({
                top: 8,
                bottom: 8,
                left: 12,
                right: 12
              })
              .backgroundColor(
                this.selectedSchemaId === schema.id
                  ? ColorResource.backgroundElevated
                  : Color.Transparent
              )
              .borderRadius(6)
              .onClick(() => {
                this.selectedSchemaId = schema.id;
                this.updateSelectedSchemaObject();
              });
            }, (schema: NodeSchema) => schema.id);
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8 });
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.Top);

      // 底部操作按钮区
      Column({ space: 8 }) {
        Divider()
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3);

        // 第一行：新建 + 删除
        Row({ space: 8 }) {
          Button('+ 新建')
            .layoutWeight(1)
            .height(36)
            .fontSize(ThemeConfig.fontSizeS)
            .backgroundColor(ColorResource.primaryColor)
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.createNewSchema();
            });

          Button('删除')
            .layoutWeight(1)
            .height(36)
            .fontSize(ThemeConfig.fontSizeS)
            .backgroundColor('#FF3B30')
            .fontColor(Color.White)
            .borderRadius(8)
            .enabled(!!this.getSelectedSchema() && !this.isSelectedSchemaSystem())
            .opacity((this.getSelectedSchema() && !this.isSelectedSchemaSystem()) ? 1 : 0.4)
            .onClick(() => {
              this.showDeleteSchemaDialog();
            });
        }
        .width('100%');

        // 第二行：发布 + 存为草稿（使用 @State 变量驱动响应式更新）
        if (this.selectedSchemaObject) {
          Row({ space: 8 }) {
            Button('发布')
              .layoutWeight(1)
              .height(36)
              .fontSize(ThemeConfig.fontSizeS)
              .backgroundColor('#34C759')
              .fontColor(Color.White)
              .borderRadius(8)
              .enabled(this.selectedSchemaObject.isDraft && !this.selectedSchemaObject.isSystem)
              .opacity((this.selectedSchemaObject.isDraft && !this.selectedSchemaObject.isSystem) ? 1 : 0.4)
              .onClick(() => {
                this.publishSelectedDraft();
              });

            Button('存为草稿')
              .layoutWeight(1)
              .height(36)
              .fontSize(ThemeConfig.fontSizeS)
              .backgroundColor(ColorResource.surface)
              .fontColor(ColorResource.textPrimary)
              .borderRadius(8)
              .enabled(!this.selectedSchemaObject.isDraft && !this.selectedSchemaObject.isSystem)
              .opacity((!this.selectedSchemaObject.isDraft && !this.selectedSchemaObject.isSystem) ? 1 : 0.4)
              .onClick(() => {
                this.createDraftFromSelectedPublished();
              });
          }
          .width('100%');
        }
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        top: 8,
        bottom: 12
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
    .justifyContent(FlexAlign.Start)
  }

  // 中间：真实任务节点预览区域（40%宽度）
  @Builder
  private PreviewPanel() {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('类型预览')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary);

          Text('模板样式')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textTertiary)
            .padding({
              left: 6,
              right: 6,
              top: 3,
              bottom: 3
            })
            .backgroundColor(ColorResource.backgroundSecondary)
            .borderRadius(4);
        }

        Text('创建任务时可选择节点类型，应用此样式模板')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textSecondary)
          .lineHeight(16)
          .maxLines(2);
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20, top: 16 });

      if (!this.getSelectedSchema()) {
        Column() {
          Text('← 请选择节点类型')
            .fontSize(ThemeConfig.fontSizeM)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        Scroll() {
          Column({ space: 20 }) {
            // 节点类型模板预览
            Column({ space: 12 }) {
              Text('节点卡片样式预览')
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.textSecondary);

              // 真实任务节点卡片预览
              Column({ space: 0 }) {
                // 任务名称
                Text((this.getSelectedSchema() as NodeSchema).name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorResource.textPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });

                // 日期范围
                Text('12/23 ~ 12/30 (8天)')
                  .fontSize(11)
                  .fontColor(ColorResource.textSecondary)
                  .margin({ top: 6 });

                // 时间进度
                Column({ space: 3 }) {
                  Text('时间: 0%')
                    .fontSize(10)
                    .fontColor(ColorResource.textSecondary);

                  Stack({ alignContent: Alignment.Start }) {
                    Row()
                      .width('100%')
                      .height(6)
                      .backgroundColor(ColorResource.backgroundSecondary)
                      .borderRadius(3);

                    Row()
                      .width('0%')
                      .height(6)
                      .backgroundColor('#409EFF')
                      .borderRadius(3);
                  }
                }
                .margin({ top: 4 });

                // 完成进度
                Column({ space: 3 }) {
                  Text('完成: 0%')
                    .fontSize(10)
                    .fontColor(ColorResource.textSecondary);

                  Stack({ alignContent: Alignment.Start }) {
                    Row()
                      .width('100%')
                      .height(6)
                      .backgroundColor(ColorResource.backgroundSecondary)
                      .borderRadius(3);

                    Row()
                      .width('0%')
                      .height(6)
                      .backgroundColor('#67C23A')
                      .borderRadius(3);
                  }
                }
                .margin({ top: 4 });
              }
              .width(180)
              .height(110)
              .padding(12)
              .backgroundColor(ColorResource.surface)
              .borderRadius(
                (this.getSelectedSchema() as NodeSchema).style.borderRadius !== undefined
                  ? (this.getSelectedSchema() as NodeSchema).style.borderRadius!
                  : 16
              )
              .border({
                width: (this.getSelectedSchema() as NodeSchema).style.borderColor ? 3 : 2,
                color: (this.getSelectedSchema() as NodeSchema).style.borderColor
                  ? (this.getSelectedSchema() as NodeSchema).style.borderColor
                  : (this.getSelectedSchema() as NodeSchema).style.fillColor
              })
              .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetY: 2 });
            }
            .width('100%');

            // 节点信息卡片
            Column({ space: 12 }) {
              Text('类型详情')
                .fontSize(ThemeConfig.fontSizeM)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.textPrimary);

              Column({ space: 10 }) {
                // 类型名称
                Row({ space: 8 }) {
                  Text('类型名称')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textTertiary)
                    .width(80);
                  Text((this.getSelectedSchema() as NodeSchema).name)
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textPrimary)
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1);
                }

                Divider()
                  .strokeWidth(0.5)
                  .color(ColorResource.surfaceEmphasized)
                  .opacity(0.3);

                // 主题色（用作边框）
                Row({ space: 8 }) {
                  Text('主题色')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textTertiary)
                    .width(80);
                  Row({ space: 6 }) {
                    Circle()
                      .width(16)
                      .height(16)
                      .fill((this.getSelectedSchema() as NodeSchema).style.fillColor);
                    Text((this.getSelectedSchema() as NodeSchema).style.fillColor)
                      .fontSize(ThemeConfig.fontSizeS)
                      .fontColor(ColorResource.textPrimary)
                      .fontWeight(FontWeight.Medium);
                  }
                  .layoutWeight(1);
                }

                // 边框色
                if ((this.getSelectedSchema() as NodeSchema).style.borderColor) {
                  Row({ space: 8 }) {
                    Text('边框色')
                      .fontSize(ThemeConfig.fontSizeS)
                      .fontColor(ColorResource.textTertiary)
                      .width(80);
                    Row({ space: 6 }) {
                      Circle()
                        .width(16)
                        .height(16)
                        .fill((this.getSelectedSchema() as NodeSchema).style.borderColor as string);
                      Text((this.getSelectedSchema() as NodeSchema).style.borderColor as string)
                        .fontSize(ThemeConfig.fontSizeS)
                        .fontColor(ColorResource.textPrimary)
                        .fontWeight(FontWeight.Medium);
                    }
                    .layoutWeight(1);
                  }
                }

                // 圆角半径
                Row({ space: 8 }) {
                  Text('圆角半径')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textTertiary)
                    .width(80);
                  Text(`${(this.getSelectedSchema() as NodeSchema).style.borderRadius !== undefined ? (this.getSelectedSchema() as NodeSchema).style.borderRadius : 16}px`)
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textPrimary)
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1);
                }
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorResource.surface)
            .borderRadius(12)
            .shadow(ThemeConfig.cardShadow);
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
    }
    .width('40%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage);
  }

  // 右侧：编辑器（40%宽度）
  @Builder
  private EditorPanel() {
    Column({ space: 0 }) {
      // 固定顶部区域
      Column({ space: 12 }) {
        Column({ space: 4 }) {
          Text('类型编辑器')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary);

          Row({ space: 6 }) {
            if (this.getSelectedSchema()) {
              if ((this.getSelectedSchema() as NodeSchema).isSystem) {
                Text('系统内置')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textSecondary)
                  .padding({
                    left: 6,
                    right: 6,
                    top: 2,
                    bottom: 2
                  })
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .borderRadius(4);
              }

              if ((this.getSelectedSchema() as NodeSchema).isDraft) {
                Text('草稿状态')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor('#FF9500')
                  .padding({
                    left: 6,
                    right: 6,
                    top: 2,
                    bottom: 2
                  })
                  .backgroundColor('rgba(255, 149, 0, 0.1)')
                  .borderRadius(4);
              } else {
                Text('已发布')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor('#34C759')
                  .padding({
                    left: 6,
                    right: 6,
                    top: 2,
                    bottom: 2
                  })
                  .backgroundColor('rgba(52, 199, 89, 0.1)')
                  .borderRadius(4);
              }

              Text(`v${(this.getSelectedSchema() as NodeSchema).version}`)
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textSecondary)
                .padding({
                  left: 6,
                  right: 6,
                  top: 2,
                  bottom: 2
                })
                .backgroundColor(ColorResource.backgroundSecondary)
                .borderRadius(4);
            }
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);

        // 快捷操作按钮 - 全部在一行，增加间距和最小宽度
        Row({ space: 10 }) {
          Button({ type: ButtonType.Normal }) {
            Text('+ 新建')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(Color.White);
          }
          .height(38)
          .constraintSize({ minWidth: 70 })
          .padding({ left: 16, right: 16 })
          .backgroundColor(ColorResource.primaryColor)
          .borderRadius(ThemeConfig.radiusMedium)
          .onClick(() => {
            this.createNewSchema();
          });

          Button({ type: ButtonType.Normal }) {
            Text('复制')
              .fontSize(ThemeConfig.fontSizeS);
          }
          .height(38)
          .constraintSize({ minWidth: 60 })
          .padding({ left: 16, right: 16 })
          .backgroundColor(ColorResource.surface)
          .fontColor(ColorResource.textPrimary)
          .borderRadius(ThemeConfig.radiusMedium)
          .enabled(!!this.getSelectedSchema())
          .opacity(this.getSelectedSchema() ? 1 : 0.4)
          .onClick(() => {
            this.duplicateSelectedSchema();
          });

          Button({ type: ButtonType.Normal }) {
            Text('删除')
              .fontSize(ThemeConfig.fontSizeS);
          }
          .height(38)
          .constraintSize({ minWidth: 60 })
          .padding({ left: 16, right: 16 })
          .backgroundColor(ColorResource.surfaceSubtle)
          .fontColor('#FF3B30')
          .borderRadius(ThemeConfig.radiusMedium)
          .enabled(!this.isSelectedSchemaSystem())
          .opacity(this.isSelectedSchemaSystem() ? 0.4 : 1)
          .onClick(() => {
            this.showDeleteSchemaDialog();
          });

          // 草稿/发布操作按钮
          if (this.getSelectedSchema()) {
            if ((this.getSelectedSchema() as NodeSchema).isDraft) {
              Button({ type: ButtonType.Normal }) {
                Text('发布')
                  .fontSize(ThemeConfig.fontSizeS);
              }
              .height(38)
              .constraintSize({ minWidth: 60 })
              .padding({ left: 16, right: 16 })
              .backgroundColor('#34C759')
              .fontColor(Color.White)
              .borderRadius(ThemeConfig.radiusMedium)
              .enabled(!this.isSelectedSchemaSystem())
              .opacity(this.isSelectedSchemaSystem() ? 0.4 : 1)
              .onClick(() => {
                this.publishSelectedDraft();
              });
            } else {
              Button({ type: ButtonType.Normal }) {
                Text('草稿')
                  .fontSize(ThemeConfig.fontSizeS);
              }
              .height(38)
              .constraintSize({ minWidth: 60 })
              .padding({ left: 16, right: 16 })
              .backgroundColor(ColorResource.surface)
              .fontColor(ColorResource.textPrimary)
              .borderRadius(ThemeConfig.radiusMedium)
              .enabled(!this.isSelectedSchemaSystem())
              .opacity(this.isSelectedSchemaSystem() ? 0.4 : 1)
              .onClick(() => {
                this.createDraftFromSelectedPublished();
              });
            }
          }
        }
        .width('100%')


        // 可滚动的内容区域
        if (this.getSelectedSchema()) {
          Scroll() {
            Column({ space: 16 }) {
              this.AttributesTab()
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({
              left: 20,
              right: 20,
              top: 12,
              bottom: 20
            });
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          .align(Alignment.Top);
        } else {
          Column({ space: 12 }) {
            Text('请选择节点类型')
              .fontSize(ThemeConfig.fontSizeM)
              .fontColor(ColorResource.textTertiary)
              .textAlign(TextAlign.Center);

            Text('从左侧列表选择要编辑的节点类型')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary)
              .textAlign(TextAlign.Center);
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        }
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 16,
        bottom: 12
      });
    }
    .width('40%')
    .height('100%');
  }

  // Tabs 导航栏
  @Builder
  private EditorTabBar() {
    Row({ space: 4 }) {
      this.TabItem('属性', 0)
      this.TabItem('布局', 1)
      this.TabItem('样式', 2)
      this.TabItem('规则', 3)
      this.TabItem('JSON', 4)
    }
    .width('100%')
    .height(44)
    .backgroundColor(ColorResource.backgroundSecondary)
    .borderRadius(10)
    .padding(4);
  }

  // Tab 项
  @Builder
  private TabItem(label: string, index: number) {
    Text(label)
      .fontSize(ThemeConfig.fontSizeS)
      .fontColor(this.currentEditorTab === index ? ColorResource.primaryColor : ColorResource.textSecondary)
      .fontWeight(this.currentEditorTab === index ? FontWeight.Medium : FontWeight.Normal)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height('100%')
      .backgroundColor(this.currentEditorTab === index ? ColorResource.surface : Color.Transparent)
      .borderRadius(8)
      .onClick(() => {
        this.currentEditorTab = index;
      });
  }

  // Tab 内容区域
  @Builder
  private EditorTabContent() {
    this.AttributesTab()
  }

  // 属性 Tab
  @Builder
  private AttributesTab() {
    Column({ space: 16 }) {
      // 基本信息卡片
      Column({ space: 0 }) {
        Row({ space: 8 }) {
          Text('基本信息')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Text(this.showBasicSection ? '▼' : '▶')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ColorResource.surface)
        .borderRadius(ThemeConfig.radiusMedium)
        .onClick(() => {
          this.showBasicSection = !this.showBasicSection;
        });

        if (this.showBasicSection) {
          Column({ space: 12 }) {
            Column({ space: 6 }) {
              Text('类型名称')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary)
                .width('100%');

              TextInput({ text: (this.getSelectedSchema() as NodeSchema).name, placeholder: '输入节点类型名称' })
                .width('100%')
                .height(40)
                .fontSize(ThemeConfig.fontSizeM)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({ left: 12, right: 12 })
                .enabled(!this.isSelectedSchemaSystem())
                .opacity(this.isSelectedSchemaSystem() ? 0.6 : 1)
                .onChange((value: string) => {
                  this.updateSelectedSchemaName(value);
                });
            }

            Column({ space: 6 }) {
              Text('类型说明（可选）')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textTertiary)
                .width('100%');

              TextArea({
                text: (this.getSelectedSchema() as NodeSchema).description ?
                  (this.getSelectedSchema() as NodeSchema).description as string : '',
                placeholder: '输入节点类型的详细说明'
              })
                .width('100%')
                .height(60)
                .fontSize(ThemeConfig.fontSizeS)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 8
                })
                .enabled(!this.isSelectedSchemaSystem())
                .opacity(this.isSelectedSchemaSystem() ? 0.6 : 1)
                .onChange((value: string) => {
                  this.updateSelectedSchemaDescription(value);
                });
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(ThemeConfig.radiusMedium)
          .margin({ top: 8 });
        }
      }
      .width('100%');

      // 样式设置折叠区
      Column({ space: 0 }) {
        Row({ space: 8 }) {
          Text('样式设置')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Text(this.showStyleSection ? '▼' : '▶')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ColorResource.surface)
        .borderRadius(ThemeConfig.radiusMedium)
        .onClick(() => {
          this.showStyleSection = !this.showStyleSection;
        });

        if (this.showStyleSection) {
          Column({ space: 14 }) {
            // 普通任务颜色
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                Text('普通任务颜色')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorResource.textPrimary)
                  .layoutWeight(1);

                Button('调色盘')
                  .height(28)
                  .fontSize(ThemeConfig.fontSizeXS)
                  .backgroundColor(ColorResource.surface)
                  .fontColor(ColorResource.primaryColor)
                  .borderRadius(6)
                  .enabled(!this.isSelectedSchemaSystem())
                  .opacity(this.isSelectedSchemaSystem() ? 0.6 : 1)
                  .onClick(() => {
                    this.showColorPickerDialog('fill');
                  });
              }
              .width('100%');

              Row({ space: 8 }) {
                ForEach(['#007AFF', '#34C759', '#5AC8FA', '#5856D6', '#8E8E93', '#FF9500'], (color: string) => {
                  Stack() {
                    Circle()
                      .width(36)
                      .height(36)
                      .fill(color)
                      .opacity(this.isSelectedSchemaSystem() ? 0.6 : 1);

                    if ((this.getSelectedSchema() as NodeSchema).style.fillColor === color) {
                      Text('✓')
                        .fontSize(20)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Bold);
                    }
                  }
                  .enabled(!this.isSelectedSchemaSystem())
                  .onClick(() => {
                    this.updateSelectedSchemaColor(color);
                  });
                });
              }
              .width('100%');
            }
            .width('100%');

            Divider()
              .strokeWidth(0.5)
              .color(ColorResource.surfaceEmphasized)
              .opacity(0.3);

            // 关键任务颜色
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                Column({ space: 2 }) {
                  Text('关键任务颜色')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorResource.textPrimary);
                  Text('（关键路径/高优先级）')
                    .fontSize(ThemeConfig.fontSizeXS - 1)
                    .fontColor(ColorResource.textTertiary)
                    .opacity(0.7);
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Button('调色盘')
                  .height(28)
                  .fontSize(ThemeConfig.fontSizeXS)
                  .backgroundColor(ColorResource.surface)
                  .fontColor(ColorResource.primaryColor)
                  .borderRadius(6)
                  .enabled(!this.isSelectedSchemaSystem())
                  .opacity(this.isSelectedSchemaSystem() ? 0.6 : 1)
                  .onClick(() => {
                    this.showColorPickerDialog('critical');
                  });
              }
              .width('100%');

              Row({ space: 8 }) {
                ForEach(['#FF3B30', '#FF9500', '#FF2D55', '#AF52DE', '#BF5AF2', '#FF6B00'], (color: string) => {
                  Stack() {
                    Circle()
                      .width(36)
                      .height(36)
                      .fill(color)
                      .opacity(this.isSelectedSchemaSystem() ? 0.6 : 1);

                    if ((this.getSelectedSchema() as NodeSchema).style.criticalColor === color) {
                      Text('✓')
                        .fontSize(20)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Bold);
                    }
                  }
                  .enabled(!this.isSelectedSchemaSystem())
                  .onClick(() => {
                    this.updateSelectedSchemaCriticalColor(color);
                  });
                });
              }
              .width('100%');

              Text('提示：未设置时将使用系统默认关键任务色')
                .fontSize(ThemeConfig.fontSizeXS - 1)
                .fontColor(ColorResource.textTertiary)
                .lineHeight(16)
                .margin({ top: 4 });
            }
            .width('100%');

            Divider()
              .strokeWidth(0.5)
              .color(ColorResource.surfaceEmphasized)
              .opacity(0.3);

            // 额外边框色（高级）
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Column({ space: 2 }) {
                  Text('额外边框色')
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.textTertiary);

                  Text('（高级、可选，留空则使用主色）')
                    .fontSize(ThemeConfig.fontSizeXS - 1)
                    .fontColor(ColorResource.textTertiary)
                    .opacity(0.6);
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Button('调色盘')
                  .height(28)
                  .fontSize(ThemeConfig.fontSizeXS)
                  .backgroundColor(ColorResource.surface)
                  .fontColor(ColorResource.primaryColor)
                  .borderRadius(6)
                  .enabled(!this.isSelectedSchemaSystem())
                  .opacity(this.isSelectedSchemaSystem() ? 0.6 : 1)
                  .onClick(() => {
                    this.showColorPickerDialog('border');
                  });
              }
              .width('100%');

              Row({ space: 8 }) {
                TextInput({
                  text: (this.getSelectedSchema() as NodeSchema).style.borderColor
                    ? (this.getSelectedSchema() as NodeSchema).style.borderColor as string
                    : '',
                  placeholder: '如 #000000'
                })
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(ThemeConfig.fontSizeS)
                  .backgroundColor(ColorResource.backgroundInput)
                  .borderRadius(ThemeConfig.radiusMedium)
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => {
                    this.updateSelectedSchemaBorderColor(value);
                  });

                if ((this.getSelectedSchema() as NodeSchema).style.borderColor) {
                  Button('清除')
                    .height(40)
                    .fontSize(ThemeConfig.fontSizeXS)
                    .backgroundColor(ColorResource.surfaceSubtle)
                    .fontColor(ColorResource.textSecondary)
                    .borderRadius(ThemeConfig.radiusMedium)
                    .onClick(() => {
                      this.updateSelectedSchemaBorderColor('');
                    });
                }
              }
              .width('100%');
            }

            // 圆角半径滑块
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Text('圆角半径')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textTertiary)
                  .layoutWeight(1);

                Text(`${(this.getSelectedSchema() as NodeSchema).style.borderRadius !== undefined ? (this.getSelectedSchema() as NodeSchema).style.borderRadius : 0}px`)
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textPrimary)
                  .fontWeight(FontWeight.Medium);
              }
              .width('100%');

              Slider({
                value: (this.getSelectedSchema() as NodeSchema).style.borderRadius !== undefined ?
                  (this.getSelectedSchema() as NodeSchema).style.borderRadius : 16,
                min: 0,
                max: 32,
                step: 2,
                style: SliderStyle.InSet
              })
                .width('100%')
                .trackColor(ColorResource.backgroundSecondary)
                .selectedColor(ColorResource.primaryColor)
                .onChange((value: number) => {
                  this.updateSelectedSchemaBorderRadius(value);
                });
            }

            // 图标（可选）
            Column({ space: 8 }) {
              Row({ space: 6 }) {
                Text('图标')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textTertiary);

                Text('可选')
                  .fontSize(ThemeConfig.fontSizeXS - 1)
                  .fontColor(ColorResource.textTertiary)
                  .padding({
                    left: 4,
                    right: 4,
                    top: 2,
                    bottom: 2
                  })
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .borderRadius(3);
              }
              .width('100%');

              TextInput({
                text: (this.getSelectedSchema() as NodeSchema).style.icon ?
                  (this.getSelectedSchema() as NodeSchema).style.icon as string : '',
                placeholder: '如 ★ 或 📌'
              })
                .width('100%')
                .height(40)
                .fontSize(ThemeConfig.fontSizeM)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.updateSelectedSchemaIcon(value);
                });
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(ThemeConfig.radiusMedium)
          .margin({ top: 8 });
        }
      }
      .width('100%')


      // 字段管理折叠区
      Column({ space: 0 }) {
        Row({ space: 8 }) {
          Text('字段管理')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Text(`${(this.getSelectedSchema() as NodeSchema).fields.length}`)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(Color.White)
            .padding({
              left: 8,
              right: 8,
              top: 3,
              bottom: 3
            })
            .backgroundColor(ColorResource.primaryColor)
            .borderRadius(10);

          Text(this.showFieldsSection ? '▼' : '▶')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ColorResource.surface)
        .borderRadius(ThemeConfig.radiusMedium)
        .onClick(() => {
          this.showFieldsSection = !this.showFieldsSection;
        });

        if (this.showFieldsSection) {
          Column({ space: 12 }) {
            Button('+ 添加字段')
              .width('100%')
              .height(40)
              .fontSize(ThemeConfig.fontSizeS)
              .type(ButtonType.Normal)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .borderRadius(ThemeConfig.radiusMedium)
              .onClick(() => {
                this.addFieldToSelectedSchema();
              });

            if ((this.getSelectedSchema() as NodeSchema).fields.length === 0) {
              Column({ space: 8 }) {
                Text('暂无字段')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary)

                Text('字段可用于存储任务的自定义数据，如优先级、负责人等')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textTertiary)
                  .lineHeight(16)
                  .opacity(0.8);
              }
              .width('100%')
              .padding(16)
              .backgroundColor(ColorResource.surface)
              .borderRadius(8);
            } else {
              Column({ space: 10 }) {
                ForEach((this.getSelectedSchema() as NodeSchema).fields, (field: FieldSchema, index: number) => {
                  Column({ space: 10 }) {
                    // 标题栏
                    Row({ space: 8 }) {
                      Text(`字段 ${index + 1}`)
                        .fontSize(ThemeConfig.fontSizeS)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(ColorResource.textPrimary)
                        .layoutWeight(1);

                      Row({ space: 6 }) {
                        if (field.required) {
                          Text('必填')
                            .fontSize(ThemeConfig.fontSizeXS - 1)
                            .fontColor('#FF3B30')
                            .padding({
                              left: 4,
                              right: 4,
                              top: 2,
                              bottom: 2
                            })
                            .backgroundColor('rgba(255, 59, 48, 0.1)')
                            .borderRadius(3);
                        }

                        Button('删除')
                          .height(24)
                          .fontSize(ThemeConfig.fontSizeXS)
                          .backgroundColor(Color.Transparent)
                          .fontColor('#FF3B30')
                          .padding({ left: 8, right: 8 })
                          .onClick(() => {
                            this.deleteFieldFromSelectedSchema(field.id);
                          });
                      }
                    }
                    .width('100%');

                    Divider()
                      .strokeWidth(0.5)
                      .color(ColorResource.surfaceEmphasized)
                      .opacity(0.2);

                    // 字段标签
                    Column({ space: 6 }) {
                      Text('字段名称')
                        .fontSize(ThemeConfig.fontSizeXS)
                        .fontColor(ColorResource.textTertiary);

                      TextInput({ text: field.label, placeholder: '如：优先级、负责人' })
                        .width('100%')
                        .height(36)
                        .fontSize(ThemeConfig.fontSizeS)
                        .backgroundColor(ColorResource.backgroundInput)
                        .borderRadius(6)
                        .padding({ left: 10, right: 10 })
                        .onChange((value: string) => {
                          const updated: FieldSchema = {
                            id: field.id,
                            label: value,
                            type: field.type,
                            required: field.required,
                            defaultValue: field.defaultValue,
                            options: field.options
                          };
                          this.updateFieldInSelectedSchema(field.id, updated);
                        });
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start);

                    // 字段类型
                    Column({ space: 6 }) {
                      Text('字段类型')
                        .fontSize(ThemeConfig.fontSizeXS)
                        .fontColor(ColorResource.textTertiary);

                      Row({ space: 6 }) {
                        ForEach(['text', 'number', 'date', 'select', 'checklist'] as FieldType[], (type: FieldType) => {
                          Text(this.getFieldTypeLabel(type))
                            .fontSize(ThemeConfig.fontSizeXS)
                            .fontColor(field.type === type ? Color.White : ColorResource.textSecondary)
                            .padding({
                              left: 10,
                              right: 10,
                              top: 6,
                              bottom: 6
                            })
                            .backgroundColor(field.type === type ? ColorResource.primaryColor :
                              ColorResource.backgroundSecondary)
                            .borderRadius(6)
                            .onClick(() => {
                              const updated: FieldSchema = {
                                id: field.id,
                                label: field.label,
                                type: type,
                                required: field.required,
                                defaultValue: field.defaultValue,
                                options: field.options
                              };
                              this.updateFieldInSelectedSchema(field.id, updated);
                            });
                        });
                      }
                      .width('100%');
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start);

                    // 必填选项
                    Row({ space: 8 }) {
                      Checkbox({ name: `required_${field.id}`, group: 'fieldOptions' })
                        .select(field.required)
                        .selectedColor(ColorResource.primaryColor)
                        .onChange((value: boolean) => {
                          const updated: FieldSchema = {
                            id: field.id,
                            label: field.label,
                            type: field.type,
                            required: value,
                            defaultValue: field.defaultValue,
                            options: field.options
                          };
                          this.updateFieldInSelectedSchema(field.id, updated);
                        });

                      Text('标记为必填字段')
                        .fontSize(ThemeConfig.fontSizeS)
                        .fontColor(ColorResource.textSecondary);
                    }
                    .width('100%');

                    // 默认值（可选）
                    if (field.type === 'text' || field.type === 'number') {
                      Column({ space: 6 }) {
                        Text('默认值（可选）')
                          .fontSize(ThemeConfig.fontSizeXS)
                          .fontColor(ColorResource.textTertiary);

                        TextInput({
                          text: field.defaultValue ? String(field.defaultValue) : '',
                          placeholder: '输入默认值'
                        })
                          .width('100%')
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(6)
                          .padding({ left: 10, right: 10 })
                          .onChange((value: string) => {
                            const updated: FieldSchema = {
                              id: field.id,
                              label: field.label,
                              type: field.type,
                              required: field.required,
                              defaultValue: value.trim().length > 0 ? value : undefined,
                              options: field.options
                            };
                            this.updateFieldInSelectedSchema(field.id, updated);
                          });
                      }
                      .width('100%')
                      .alignItems(HorizontalAlign.Start);
                    }

                    // 选项列表（用于 select / checklist 预设）
                    if (field.type === 'select' || field.type === 'checklist') {
                      Column({ space: 6 }) {
                        Text('选项列表')
                          .fontSize(ThemeConfig.fontSizeXS)
                          .fontColor(ColorResource.textTertiary);

                        TextInput({
                          text: field.options && field.options.length > 0
                            ? field.options.join(', ')
                            : '',
                          placeholder: field.type === 'select'
                            ? '用逗号分隔，例如：未开始, 进行中, 阻塞, 已完成'
                            : '用逗号分隔，例如：前端, 后端, 设计'
                        })
                          .width('100%')
                          .height(36)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(6)
                          .padding({ left: 10, right: 10 })
                          .onChange((value: string) => {
                            const options = value.split(',')
                              .map(v => v.trim())
                              .filter(v => v.length > 0);
                            const updated: FieldSchema = {
                              id: field.id,
                              label: field.label,
                              type: field.type,
                              required: field.required,
                              defaultValue: field.defaultValue,
                              options: options.length > 0 ? options : undefined
                            };
                            this.updateFieldInSelectedSchema(field.id, updated);
                          });
                      }
                      .width('100%')
                      .alignItems(HorizontalAlign.Start);
                    }
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor(ColorResource.surface)
                  .borderRadius(10)
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 });
                }, (field: FieldSchema) => field.id);
              }
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(ThemeConfig.radiusMedium)
          .margin({ top: 8 });
        }
      }
      .width('100%');

      // 布局组件折叠区
      Column({ space: 0 }) {
        Row({ space: 8 }) {
          Text('布局组件')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Text(`${(this.getSelectedSchema() as NodeSchema).layout.length}`)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(Color.White)
            .padding({
              left: 8,
              right: 8,
              top: 3,
              bottom: 3
            })
            .backgroundColor(ColorResource.primaryColor)
            .borderRadius(10);

          Text(this.showLayoutSection ? '▼' : '▶')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ColorResource.surface)
        .borderRadius(ThemeConfig.radiusMedium)
        .onClick(() => {
          this.showLayoutSection = !this.showLayoutSection;
        });

        if (this.showLayoutSection) {
          Column({ space: 12 }) {
            Button('+ 添加组件')
              .width('100%')
              .height(40)
              .fontSize(ThemeConfig.fontSizeS)
              .type(ButtonType.Normal)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .borderRadius(ThemeConfig.radiusMedium)
              .onClick(() => {
                this.addComponentToSelectedSchema();
              });

            if ((this.getSelectedSchema() as NodeSchema).layout.length === 0) {
              Column({ space: 8 }) {
                Text('暂无布局组件')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary);

                Text('布局组件定义节点卡片内部的UI结构和显示方式')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textTertiary)
                  .lineHeight(16)
                  .opacity(0.8);

                Column({ space: 6 }) {
                  Text('常用组件类型：')
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.textTertiary)
                    .fontWeight(FontWeight.Medium);

                  Text('• TITLE - 标题显示')
                    .fontSize(ThemeConfig.fontSizeXS - 1)
                    .fontColor(ColorResource.textTertiary)
                    .opacity(0.7);

                  Text('• FIELD - 字段显示')
                    .fontSize(ThemeConfig.fontSizeXS - 1)
                    .fontColor(ColorResource.textTertiary)
                    .opacity(0.7);

                  Text('• PROGRESS - 进度条')
                    .fontSize(ThemeConfig.fontSizeXS - 1)
                    .fontColor(ColorResource.textTertiary)
                    .opacity(0.7);
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ top: 6 });
              }
              .width('100%')
              .padding(16)
              .backgroundColor(ColorResource.surface)
              .borderRadius(8)
              .alignItems(HorizontalAlign.Start);
            } else {
              Column({ space: 10 }) {
                ForEach((this.getSelectedSchema() as NodeSchema).layout,
                  (component: NodeComponentSchema, index: number) => {
                    Column({ space: 10 }) {
                      Row({ space: 8 }) {
                        Column({ space: 2 }) {
                          Text(`组件 ${index + 1}`)
                            .fontSize(ThemeConfig.fontSizeS)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(ColorResource.textPrimary);

                          Text(this.getComponentTypeLabel(component.type))
                            .fontSize(ThemeConfig.fontSizeXS)
                            .fontColor(ColorResource.primaryColor);
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1);

                        Button('删除')
                          .height(28)
                          .fontSize(ThemeConfig.fontSizeXS)
                          .backgroundColor(Color.Transparent)
                          .fontColor('#FF3B30')
                          .padding({ left: 8, right: 8 })
                          .onClick(() => {
                            this.deleteComponentFromSelectedSchema(component.id);
                          });
                      }
                      .width('100%');

                      Divider()
                        .strokeWidth(0.5)
                        .color(ColorResource.surfaceEmphasized)
                        .opacity(0.2);

                      // 组件类型选择
                      Column({ space: 6 }) {
                        Text('组件类型')
                          .fontSize(ThemeConfig.fontSizeXS)
                          .fontColor(ColorResource.textTertiary);

                        Row({ space: 6 }) {
                          ForEach(['TITLE', 'CUSTOM_FIELD', 'TIME_PROGRESS', 'TASK_PROGRESS',
                            'TAGS'] as NodeComponentType[], (type: NodeComponentType) => {
                            Text(this.getComponentTypeLabel(type))
                              .fontSize(ThemeConfig.fontSizeXS)
                              .fontColor(component.type === type ? Color.White : ColorResource.textSecondary)
                              .padding({
                                left: 10,
                                right: 10,
                                top: 6,
                                bottom: 6
                              })
                              .backgroundColor(component.type === type ? ColorResource.primaryColor :
                                ColorResource.backgroundSecondary)
                              .borderRadius(6)
                              .onClick(() => {
                                const updated: NodeComponentSchema = {
                                  id: component.id,
                                  type: type,
                                  fieldId: component.fieldId
                                };
                                this.updateComponentInSelectedSchema(component.id, updated);
                              });
                          });
                        }
                        .width('100%');
                      }
                      .width('100%')
                      .alignItems(HorizontalAlign.Start);

                      // 如果是CUSTOM_FIELD类型，显示字段绑定
                      if (component.type === 'CUSTOM_FIELD') {
                        Column({ space: 6 }) {
                          Text('绑定字段')
                            .fontSize(ThemeConfig.fontSizeXS)
                            .fontColor(ColorResource.textTertiary);

                          Text(component.fieldId || '未绑定')
                            .fontSize(ThemeConfig.fontSizeS)
                            .fontColor(component.fieldId ? ColorResource.textPrimary : ColorResource.textTertiary)
                            .padding({
                              left: 10,
                              right: 10,
                              top: 8,
                              bottom: 8
                            })
                            .backgroundColor(ColorResource.backgroundInput)
                            .borderRadius(6)
                            .width('100%');

                          Text('提示：在字段管理中创建字段后可绑定')
                            .fontSize(ThemeConfig.fontSizeXS - 1)
                            .fontColor(ColorResource.textTertiary)
                            .opacity(0.7)
                            .margin({ top: 2 });
                        }
                        .width('100%')
                        .alignItems(HorizontalAlign.Start);
                      }
                    }
                    .width('100%')
                    .padding(14)
                    .backgroundColor(ColorResource.surface)
                    .borderRadius(10)
                    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 });
                  }, (component: NodeComponentSchema) => component.id);
              }
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ColorResource.backgroundSecondary)
          .borderRadius(ThemeConfig.radiusMedium)
          .margin({ top: 8 });
        }
      }
      .width('100%');
    }


    // JSON 导入 / 导出区域
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('Schema JSON')
          .fontSize(ThemeConfig.fontSizeS)
          .fontWeight(ThemeConfig.fontWeightMedium)
          .fontColor(ColorResource.textSecondary);

        Blank()
          .layoutWeight(1);

        Button('刷新 JSON')
          .fontSize(ThemeConfig.fontSizeXS)
          .height(ThemeConfig.buttonHeightSmall)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .onClick(() => {
            this.refreshSchemaJson();
          });

        Button('从 JSON 导入')
          .fontSize(ThemeConfig.fontSizeXS)
          .height(ThemeConfig.buttonHeightSmall)
          .type(ButtonType.Capsule)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor(Color.White)
          .onClick(() => {
            this.handleImportFromJson();
          });
      }

      TextArea({
        text: this.schemaJson,
        placeholder: '在这里查看或粘贴节点 Schema JSON，用于分享或导入'
      })
        .width('100%')
        .height(200)
        .fontSize(ThemeConfig.fontSizeXS)
        .backgroundColor(ColorResource.backgroundInput)
        .borderRadius(ThemeConfig.radiusMedium)
        .padding({
          left: 8,
          right: 8,
          top: 6,
          bottom: 6
        })
        .onChange((value: string) => {
          this.schemaJson = value;
        });
    }
  }

  // 布局 Tab
  @Builder
  private LayoutTab() {
    Column({ space: 16 }) {
      Text('布局组件管理')
        .fontSize(ThemeConfig.fontSizeM)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorResource.textPrimary);

      Text(`当前 ${(this.getSelectedSchema() as NodeSchema).layout.length} 个组件`)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary);

      Button('+ 添加布局组件')
        .width('100%')
        .height(40)
        .onClick(() => {
          this.addComponentToSelectedSchema();
        });

      if ((this.getSelectedSchema() as NodeSchema).layout.length === 0) {
        Column({ space: 8 }) {
          Text('暂无布局组件')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
          Text('提示：布局组件定义节点的 UI 结构')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textSecondary);
        }
        .width('100%')
        .padding(20)
        .backgroundColor(ColorResource.backgroundSecondary)
        .borderRadius(8);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  // 样式 Tab
  @Builder
  private StyleTab() {
    Column({ space: 16 }) {
      Text('详细样式设置')
        .fontSize(ThemeConfig.fontSizeM)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorResource.textPrimary);

      Text('配置节点的详细外观样式')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary);

      Column({ space: 8 }) {
        Text('填充色')
          .fontSize(ThemeConfig.fontSizeS)
          .fontWeight(FontWeight.Medium);
        Text((this.getSelectedSchema() as NodeSchema).style.fillColor)
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ColorResource.textSecondary);
      }
      .width('100%')
      .padding(12)
      .backgroundColor(ColorResource.surface)
      .borderRadius(8);

      Text('提示：更多样式选项请在“属性” Tab 中编辑')
        .fontSize(ThemeConfig.fontSizeXS)
        .fontColor(ColorResource.textSecondary);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  // 规则 Tab
  @Builder
  private RulesTab() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Text('规则引擎')
          .fontSize(ThemeConfig.fontSizeM)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1);

        Text(`${(this.getSelectedSchema() as NodeSchema).rules?.length || 0}`)
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(Color.White)
          .padding({
            left: 6,
            right: 6,
            top: 2,
            bottom: 2
          })
          .backgroundColor(ColorResource.primaryColor)
          .borderRadius(8);
      }

      Text('规则引擎允许你创建动态行为，如：字段联动、条件校验等')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary)
        .lineHeight(18);

      Button('+ 添加规则')
        .width('100%')
        .height(40)
        .onClick(() => {
          this.promptAction.showToast({ message: '规则编辑器开发中，请手动编辑 JSON', duration: 2000 });
        });

      if (!(this.getSelectedSchema() as NodeSchema).rules ||
        (this.getSelectedSchema() as NodeSchema).rules!.length === 0) {
        Column({ space: 8 }) {
          Text('暂无规则')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);

          Text('示例：当"优先级"字段为"高"时，自动设置"颜色"字段为红色')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.textTertiary)
            .lineHeight(16);
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ColorResource.backgroundSecondary)
        .borderRadius(8);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  // JSON Tab
  @Builder
  private JsonTab() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Text('JSON 视图')
          .fontSize(ThemeConfig.fontSizeM)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1);

        Button('复制')
          .height(32)
          .fontSize(ThemeConfig.fontSizeXS)
          .onClick(() => {
            this.promptAction.showToast({ message: '已复制到剪贴板（模拟）', duration: 2000 });
          });
      }

      Text('只读视图，查看当前节点类型的完整 JSON 配置')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary)
        .lineHeight(18);

      TextArea({
        text: JSON.stringify(this.getSelectedSchema(), null, 2)
      })
        .width('100%')
        .height(400)
        .fontSize(ThemeConfig.fontSizeXS)
        .fontColor(ColorResource.textPrimary)
        .backgroundColor(ColorResource.backgroundSecondary)
        .borderRadius(8)
        .padding(12)
        .enabled(false);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    Column({ space: 0 }) {
      Column() {
        Row({ space: 12 }) {
          Row({ space: 6 }) {
            Text('←')
              .fontSize(20)
              .fontColor(ColorResource.primaryColor);
            Text('返回')
              .fontSize(ThemeConfig.fontSizeM)
              .fontColor(ColorResource.primaryColor);
          }
          .padding({
            left: 8,
            right: 12,
            top: 8,
            bottom: 8
          })
          .borderRadius(8)
          .onClick(() => {
            router.back();
          });

          Text('节点工作台')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1);

          Row({ space: 8 }) {
            Stack({ alignContent: Alignment.TopEnd }) {
              Button('自定义组件')
                .fontSize(ThemeConfig.fontSizeS)
                .height(36)
                .backgroundColor(ColorResource.backgroundSecondary)
                .fontColor(ColorResource.textTertiary)
                .borderRadius(8)
                .enabled(false);

              Text('即将推出')
                .fontSize(10)
                .fontColor(ColorResource.textTertiary)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(Color.White)
                .borderRadius(10)
                .border({ width: 1, color: ColorResource.surfaceEmphasized })
                .shadow({ radius: 6, color: '#22000000', offsetX: 0, offsetY: 2 })
                .opacity(0.95)
                .margin({ top: -10, right: -8 });
            }

            Button('保存')
              .fontSize(ThemeConfig.fontSizeS)
              .height(36)
              .backgroundColor(ColorResource.surface)
              .fontColor(ColorResource.primaryColor)
              .borderRadius(8)
              .onClick(() => {
                this.schemaService.saveToStorage();
                this.promptAction.showToast({ message: '已保存', duration: 2000 });
              });

            Button('导入JSON')
              .fontSize(ThemeConfig.fontSizeS)
              .height(36)
              .backgroundColor(ColorResource.backgroundSecondary)
              .fontColor(ColorResource.primaryColor)
              .borderRadius(8)
              .onClick(() => {
                this.showImportDialog();
              });

            Button('导出JSON')
              .fontSize(ThemeConfig.fontSizeS)
              .height(36)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                this.showExportDialog();
              });
          }
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ColorResource.backgroundPage);
      }
      .width('100%')
      .padding({ top: 20 });

      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.2);

      Stack() {
        // 主布局
        Row({ space: 0 }) {
          // 左侧: 节点类型列表
          Column({ space: 0 }) {
            this.SchemaList();
          }
          .width(this.getActualPanelWidth(0))
          .height('100%');

          Divider()
            .vertical(true)
            .strokeWidth(1)
            .color(ColorResource.surfaceEmphasized)
            .opacity(0.2);

          // 中左: 组件库面板
          Column({ space: 0 }) {
            ComponentLibrary({
              onComponentClick: (type: NodeComponentType) => this.handleComponentLibraryClick(type),
              onComponentDragStart: (type: NodeComponentType) => this.handleComponentDragStart(type),
              onComponentDragEnd: () => this.handleComponentDragEnd()
            })
          }
          .width(this.getActualPanelWidth(1))
          .height('100%');

          Divider()
            .vertical(true)
            .strokeWidth(1)
            .color(ColorResource.surfaceEmphasized)
            .opacity(0.2);

          // 中右: 可视化画布
          Column({ space: 0 }) {
            NodeVisualCanvas({
              schema: this.selectedSchemaObject,
              selectedComponentId: this.selectedComponentId,
              draggedLibraryType: this.draggedLibraryType,
              onComponentSelect: (componentId: string) => {
                this.handleComponentSelect(componentId);
              },
              onComponentDelete: (componentId: string) => {
                this.handleComponentDelete(componentId);
              },
              onComponentAdd: (type: NodeComponentType, index: number) => {
                this.addComponentToSelectedSchema(type, index);
              },
              onComponentReorder: (fromIndex: number, toIndex: number) => {
                this.handleComponentReorder(fromIndex, toIndex);
              }
            });
          }
          .width(this.getActualPanelWidth(2))
          .height('100%');

          Divider()
            .vertical(true)
            .strokeWidth(1)
            .color(ColorResource.surfaceEmphasized)
            .opacity(0.2);

          // 右侧: 属性编辑面板
          Column({ space: 0 }) {
            ComponentPropertyPanel({
              selectedComponent: this.selectedComponentObject,
              availableFields: this.selectedSchemaObject?.fields || [],
              schemaStyle: this.selectedSchemaObject ? this.selectedSchemaObject.style : null,
              refreshKey: this.componentRefreshKey,
              onFillColorChange: (color: string) => {
                this.updateSelectedSchemaColor(color);
              },
              onCriticalColorChange: (color: string) => {
                this.updateSelectedSchemaCriticalColor(color);
              },
              onPickFillColor: () => {
                this.showColorPickerDialog('fill');
              },
              onPickCriticalColor: () => {
                this.showColorPickerDialog('critical');
              },
              onBorderColorChange: (color: string) => {
                this.updateSelectedSchemaBorderColor(color);
              },
              onBorderRadiusChange: (radius: number) => {
                this.updateSelectedSchemaBorderRadius(radius);
              },
              onPropertyChange: (component: NodeComponentSchema) => {
                this.handleComponentPropertyChange(component);
              },
              onFieldChange: (field: FieldSchema) => {
                // 使用已有的字段更新方法，把 options 等保存回当前 schema
                this.updateFieldInSelectedSchema(field.id, field);
              }
            });
          }
          .width(this.getActualPanelWidth(3))
          .height('100%');
        }
        .width('100%')
        .height('100%');

        // 浮动面板（折叠时显示）
        ForEach([0, 1, 2, 3], (index: number) => {
          if (this.panelCollapsed[index]) {
            Column({ space: 0 }) {
              // 标题栏
              Row({ space: 8 }) {
                Text(this.getPanelTitle(index))
                  .fontSize(ThemeConfig.fontSizeM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorResource.textPrimary)
                  .layoutWeight(1);

                Button({ type: ButtonType.Normal }) {
                  Text('×')
                    .fontSize(20)
                    .fontColor(ColorResource.textSecondary);
                }
                .width(32)
                .height(32)
                .padding(0)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.togglePanelCollapse(index);
                });
              }
              .width('100%')
              .height(50)
              .padding({ left: 16, right: 12 })
              .backgroundColor(ColorResource.surface)
              .borderRadius({ topLeft: 12, topRight: 12 });

              Divider()
                .strokeWidth(1)
                .color(ColorResource.surfaceEmphasized)
                .opacity(0.2);

              // 面板内容
              Column({ space: 0 }) {
                if (index === 0) {
                  this.SchemaList();
                } else if (index === 1) {
                  ComponentLibrary({
                    onComponentClick: (type: NodeComponentType) => {
                      this.handleComponentLibraryClick(type);
                      this.togglePanelCollapse(1);
                    },
                    onComponentDragStart: (type: NodeComponentType) => {
                      this.handleComponentDragStart(type);
                    },
                    onComponentDragEnd: () => {
                      this.handleComponentDragEnd();
                    }
                  });
                } else if (index === 2) {
                  NodeVisualCanvas({
                    schema: this.getSelectedSchema(),
                    selectedComponentId: this.selectedComponentId,
                    draggedLibraryType: this.draggedLibraryType,
                    onComponentSelect: (componentId: string) => {
                      this.handleComponentSelect(componentId);
                    },
                    onComponentDelete: (componentId: string) => {
                      this.handleComponentDelete(componentId);
                    },
                    onComponentAdd: (type: NodeComponentType, index: number) => {
                      this.addComponentToSelectedSchema(type, index);
                    },
                    onComponentReorder: (fromIndex: number, toIndex: number) => {
                      this.handleComponentReorder(fromIndex, toIndex);
                    }
                  });
                } else if (index === 3) {
                  ComponentPropertyPanel({
                    selectedComponent: this.selectedComponentObject,
                    availableFields: this.selectedSchemaObject?.fields || [],
                    schemaStyle: this.selectedSchemaObject ? this.selectedSchemaObject.style : null,
                    refreshKey: this.componentRefreshKey,
                    onFillColorChange: (color: string) => {
                      this.updateSelectedSchemaColor(color);
                    },
                    onCriticalColorChange: (color: string) => {
                      this.updateSelectedSchemaCriticalColor(color);
                    },
                    onPickFillColor: () => {
                      this.showColorPickerDialog('fill');
                    },
                    onPickCriticalColor: () => {
                      this.showColorPickerDialog('critical');
                    },
                    onBorderColorChange: (color: string) => {
                      this.updateSelectedSchemaBorderColor(color);
                    },
                    onBorderRadiusChange: (radius: number) => {
                      this.updateSelectedSchemaBorderRadius(radius);
                    },
                    onPropertyChange: (component: NodeComponentSchema) => {
                      this.handleComponentPropertyChange(component);
                    },
                    onFieldChange: (field: FieldSchema) => {
                      this.updateFieldInSelectedSchema(field.id, field);
                    }
                  });
                }
              }
              .layoutWeight(1);
            }
            .width(400)
            .height('100%')
            .backgroundColor(ColorResource.surface)
            .shadow({ radius: 24, color: 'rgba(0,0,0,0.2)', offsetX: -4 })
            .position({ x: index < 2 ? 0 : '100%', y: 0 })
            .translate({ x: index < 2 ? 0 : '-100%' })
            .zIndex(10);
          }
        });
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
  }
}
