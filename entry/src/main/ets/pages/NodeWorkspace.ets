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
import { NodeSchema, NodeComponentSchema, FieldSchema } from '../model/NodeSchema';
import { NodeSchemaService } from '../services/NodeSchemaService';
import { SchemaErrorBoundary, ErrorType } from '../utils/ErrorBoundary';
import { PromptAction } from '@kit.ArkUI';
import util from '@ohos.util';
import router from '@ohos.router';
import { ColorSelector } from '../components/ColorPicker';

interface ConflictSchema {
  id: string;
  name: string;
}

@CustomDialog
struct ImportConflictDialog {
  controller: CustomDialogController;
  conflictSchemas: ConflictSchema[] = [];
  onResolve: (resolution: 'rename' | 'newId' | 'skip') => void = () => {};

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
      .padding({ top: 24, left: 24, right: 24, bottom: 16 });

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
  @State schemaJson: string = '';
  @State showColorPicker: boolean = false;
  @State editingColorType: 'fill' | 'border' = 'fill';
  @State selectedColor: string = '#007AFF';
  @State selectedBorderColor: string = '#000000';
  @State showBasicSection: boolean = true;
  @State showStyleSection: boolean = true;
  @State showFieldsSection: boolean = false;
  @State showLayoutSection: boolean = false;
  @State filterMode: 'all' | 'published' | 'draft' = 'all';
  @State searchKeyword: string = '';
  @State previewUpdatePending: boolean = false;
  @State currentEditorTab: number = 0;
  
  private deleteDialogController: CustomDialogController | null = null;
  private importConflictDialogController: CustomDialogController | null = null;
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
      const newSchemas = this.schemaService.getAllSchemas();
      // 使用错误边界验证和应用更新
      this.schemas = this.errorBoundary.safeApplyUpdate(newSchemas, this.schemas);
      if (!this.selectedSchemaId && this.schemas.length > 0) {
        this.selectedSchemaId = this.schemas[0].id;
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
      const importedSchemas = JSON.parse(jsonStr) as NodeSchema[];
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
      const importedSchemas = JSON.parse(this.schemaJson) as NodeSchema[];
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

  private showDeleteConfirmDialog(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    if (schema.isSystem) {
      this.promptAction.showToast({ message: '内置节点类型无法删除' });
      return;
    }

    if (this.deleteDialogController) {
      this.deleteDialogController.close();
      this.deleteDialogController = null;
    }

    this.deleteDialogController = new CustomDialogController({
      builder: DeleteConfirmDialog({
        schemaName: schema.name,
        onConfirm: () => {
          this.deleteSelectedSchema();
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.deleteDialogController.open();
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
        borderColor: schema.style.borderColor,
        borderRadius: schema.style.borderRadius,
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
        borderColor: color.trim().length > 0 ? color.trim() : undefined,
        borderRadius: schema.style.borderRadius,
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
    this.refreshSchemaJson();
    this.scheduleAutoSave();
  }

  private updateSelectedSchemaBorderRadius(radius: string): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    
    const numValue = parseInt(radius);
    if (isNaN(numValue) || numValue < 0) {
      this.promptAction.showToast({ message: '圆角半径必须为非负整数' });
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
        borderColor: schema.style.borderColor,
        borderRadius: numValue,
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
    this.refreshSchemaJson();
    this.scheduleAutoSave();
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
        borderColor: schema.style.borderColor,
        borderRadius: schema.style.borderRadius,
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
    
    const updatedFields = schema.fields.map(f => f.id === fieldId ? updatedField : f);
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

  private addComponentToSelectedSchema(): void {
    const schema = this.getSelectedSchema();
    if (!schema) {
      return;
    }
    
    const newComponent: NodeComponentSchema = {
      id: `component_${Date.now()}`,
      type: 'TITLE'
    };
    
    const updatedLayout: NodeComponentSchema[] = [];
    for (const component of schema.layout) {
      updatedLayout.push(component);
    }
    updatedLayout.push(newComponent);
    
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
    this.schemaService.saveToStorage();
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
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
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
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(this.filterMode === 'all' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.filterMode = 'all';
            });
          
          Text('已发布')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.filterMode === 'published' ? Color.White : ColorResource.textSecondary)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(this.filterMode === 'published' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.filterMode = 'published';
            });
          
          Text('草稿')
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(this.filterMode === 'draft' ? Color.White : ColorResource.textSecondary)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(this.filterMode === 'draft' ? ColorResource.primaryColor : ColorResource.backgroundSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.filterMode = 'draft';
            });
        }
        .width('100%');
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 16, bottom: 8 });

      Scroll() {
        Column({ space: 4 }) {
          if (this.getFilteredSchemas().length === 0) {
            Text('暂无类型')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textTertiary)
              .padding({ top: 8, bottom: 20, left: 16 });
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
                      .fontColor(this.selectedSchemaId === schema.id ? ColorResource.primaryColor : ColorResource.textPrimary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1);
                    
                    if (schema.isDraft) {
                      Text('草稿')
                        .fontSize(ThemeConfig.fontSizeXS - 1)
                        .fontColor('#FF9500')
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .backgroundColor('rgba(255, 149, 0, 0.1)')
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
              }
              .width('100%')
              .padding({ top: 8, bottom: 8, left: 12, right: 12 })
              .backgroundColor(
                this.selectedSchemaId === schema.id
                  ? ColorResource.backgroundElevated
                  : Color.Transparent
              )
              .borderRadius(6)
              .onClick(() => {
                this.selectedSchemaId = schema.id;
              });
            }, (schema: NodeSchema) => schema.id);
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 12, right: 12, top: 0, bottom: 16 });
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.Top);
    }
    .width('20%')
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
            .padding({ left: 6, right: 6, top: 3, bottom: 3 })
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
                  Text(`${(this.getSelectedSchema() as NodeSchema).style.borderRadius || 16}px`)
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
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorResource.backgroundSecondary)
                  .borderRadius(4);
              }
              
              if ((this.getSelectedSchema() as NodeSchema).isDraft) {
                Text('草稿状态')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor('#FF9500')
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor('rgba(255, 149, 0, 0.1)')
                  .borderRadius(4);
              } else {
                Text('已发布')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor('#34C759')
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor('rgba(52, 199, 89, 0.1)')
                  .borderRadius(4);
              }
              
              Text(`v${(this.getSelectedSchema() as NodeSchema).version}`)
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(ColorResource.textSecondary)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
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
            this.showDeleteConfirmDialog();
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

        
        // Tabs 导航栏（固定在顶部）
        if (this.getSelectedSchema()) {
          this.EditorTabBar();
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 });
      
      // 可滚动的内容区域
      if (this.getSelectedSchema()) {
        Scroll() {
          Column({ space: 16 }) {
            this.EditorTabContent();
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 20 });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
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
    .width('40%')
    .height('100%');
  }

  // Tabs 导航栏
  @Builder
  private EditorTabBar() {
    Row({ space: 4 }) {
      this.TabItem('属性', 0);
      this.TabItem('布局', 1);
      this.TabItem('样式', 2);
      this.TabItem('规则', 3);
      this.TabItem('JSON', 4);
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
    if (this.currentEditorTab === 0) {
      this.AttributesTab();
    } else if (this.currentEditorTab === 1) {
      this.LayoutTab();
    } else if (this.currentEditorTab === 2) {
      this.StyleTab();
    } else if (this.currentEditorTab === 3) {
      this.RulesTab();
    } else if (this.currentEditorTab === 4) {
      this.JsonTab();
    }
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
                    text: (this.getSelectedSchema() as NodeSchema).description ? (this.getSelectedSchema() as NodeSchema).description as string : '',
                    placeholder: '输入节点类型的详细说明'
                  })
                    .width('100%')
                    .height(60)
                    .fontSize(ThemeConfig.fontSizeS)
                    .backgroundColor(ColorResource.backgroundInput)
                    .borderRadius(ThemeConfig.radiusMedium)
                    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
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
                  Text('普通任务颜色')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorResource.textPrimary)
                    .width('100%');
                  
                  Row({ space: 8 }) {
                    ForEach(['#007AFF', '#34C759', '#5AC8FA', '#5856D6', '#8E8E93', '#FF9500'], (color: string) => {
                      Stack() {
                        Circle()
                          .width(36)
                          .height(36)
                          .fill(color);
                        
                        if ((this.getSelectedSchema() as NodeSchema).style.fillColor === color) {
                          Text('✓')
                            .fontSize(20)
                            .fontColor(Color.White)
                            .fontWeight(FontWeight.Bold);
                        }
                      }
                      .onClick(() => {
                        (this.getSelectedSchema() as NodeSchema).style.fillColor = color;
                        this.schemaService.upsertSchema(this.getSelectedSchema() as NodeSchema);
                        this.reloadSchemas();
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
                  .width('100%');
                  
                  Row({ space: 8 }) {
                    ForEach(['#FF3B30', '#FF9500', '#FF2D55', '#AF52DE', '#BF5AF2', '#FF6B00'], (color: string) => {
                      Stack() {
                        Circle()
                          .width(36)
                          .height(36)
                          .fill(color);
                        
                        if ((this.getSelectedSchema() as NodeSchema).style.criticalColor === color) {
                          Text('✓')
                            .fontSize(20)
                            .fontColor(Color.White)
                            .fontWeight(FontWeight.Bold);
                        }
                      }
                      .onClick(() => {
                        if (!(this.getSelectedSchema() as NodeSchema).style.criticalColor) {
                          (this.getSelectedSchema() as NodeSchema).style.criticalColor = color;
                        } else {
                          (this.getSelectedSchema() as NodeSchema).style.criticalColor = color;
                        }
                        this.schemaService.upsertSchema(this.getSelectedSchema() as NodeSchema);
                        this.reloadSchemas();
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
                  Row({ space: 4 }) {
                    Text('额外边框色')
                      .fontSize(ThemeConfig.fontSizeXS)
                      .fontColor(ColorResource.textTertiary);
                    
                    Text('（高级、可选）')
                      .fontSize(ThemeConfig.fontSizeXS - 1)
                      .fontColor(ColorResource.textTertiary)
                      .opacity(0.6);
                  }
                  .width('100%');

                  TextInput({ 
                    text: (this.getSelectedSchema() as NodeSchema).style.borderColor 
                      ? (this.getSelectedSchema() as NodeSchema).style.borderColor as string 
                      : '', 
                    placeholder: '如 #000000，留空则使用主色' 
                  })
                    .width('100%')
                    .height(40)
                    .fontSize(ThemeConfig.fontSizeS)
                    .backgroundColor(ColorResource.backgroundInput)
                    .borderRadius(ThemeConfig.radiusMedium)
                    .padding({ left: 12, right: 12 })
                    .onChange((value: string) => {
                      this.updateSelectedSchemaBorderColor(value);
                    });
                }

                // 圆角半径滑块
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text('圆角半径')
                      .fontSize(ThemeConfig.fontSizeXS)
                      .fontColor(ColorResource.textTertiary)
                      .layoutWeight(1);
                    
                    Text(`${(this.getSelectedSchema() as NodeSchema).style.borderRadius || 16}px`)
                      .fontSize(ThemeConfig.fontSizeS)
                      .fontColor(ColorResource.textPrimary)
                      .fontWeight(FontWeight.Medium);
                  }
                  .width('100%');

                  Slider({
                    value: (this.getSelectedSchema() as NodeSchema).style.borderRadius || 16,
                    min: 0,
                    max: 32,
                    step: 2,
                    style: SliderStyle.InSet
                  })
                    .width('100%')
                    .trackColor(ColorResource.backgroundSecondary)
                    .selectedColor(ColorResource.primaryColor)
                    .onChange((value: number) => {
                      this.updateSelectedSchemaBorderRadius(value.toString());
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
                      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                      .backgroundColor(ColorResource.backgroundSecondary)
                      .borderRadius(3);
                  }
                  .width('100%');

                  TextInput({ 
                    text: (this.getSelectedSchema() as NodeSchema).style.icon ? (this.getSelectedSchema() as NodeSchema).style.icon as string : '', 
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
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
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
                Text('暂无字段，点击"添加字段"创建')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textTertiary)
                  .padding({ top: 8, bottom: 8 });
              } else {
                Column({ space: 8 }) {
                  ForEach((this.getSelectedSchema() as NodeSchema).fields, (field: FieldSchema) => {
                    Column({ space: 6 }) {
                      Row({ space: 8 }) {
                        Text('字段标签')
                          .fontSize(ThemeConfig.fontSizeXS)
                          .fontColor(ColorResource.textTertiary)
                          .width(60);
                        
                        TextInput({ text: field.label, placeholder: '字段名称' })
                          .layoutWeight(1)
                          .height(ThemeConfig.inputHeightSmall)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .borderRadius(ThemeConfig.radiusSmall)
                          .padding({ left: 8, right: 8 })
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

                      Row({ space: 8 }) {
                        Text('字段类型')
                          .fontSize(ThemeConfig.fontSizeXS)
                          .fontColor(ColorResource.textTertiary)
                          .width(60);
                        
                        Button(field.type)
                          .layoutWeight(1)
                          .height(ThemeConfig.inputHeightSmall)
                          .fontSize(ThemeConfig.fontSizeS)
                          .backgroundColor(ColorResource.backgroundInput)
                          .fontColor(ColorResource.textPrimary)
                          .borderRadius(ThemeConfig.radiusSmall);
                        
                        Button('删除')
                          .height(ThemeConfig.inputHeightSmall)
                          .fontSize(ThemeConfig.fontSizeXS)
                          .backgroundColor(ColorResource.surfaceSubtle)
                          .fontColor('#FF3B30')
                          .borderRadius(ThemeConfig.radiusSmall)
                          .onClick(() => {
                            this.deleteFieldFromSelectedSchema(field.id);
                          });
                      }
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                    .backgroundColor(ColorResource.backgroundSecondary)
                    .borderRadius(ThemeConfig.radiusMedium);
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
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
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
                Text('暂无布局组件，点击"添加组件"创建')
                  .fontSize(ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.textTertiary)
                  .padding({ top: 8, bottom: 8 });
              } else {
                Column({ space: 8 }) {
                  ForEach((this.getSelectedSchema() as NodeSchema).layout, (component: NodeComponentSchema) => {
                    Row({ space: 8 }) {
                      Text(component.type)
                        .fontSize(ThemeConfig.fontSizeS)
                        .fontColor(ColorResource.textPrimary)
                        .layoutWeight(1);
                      
                      Button('删除')
                        .height(ThemeConfig.inputHeightSmall)
                        .fontSize(ThemeConfig.fontSizeXS)
                        .backgroundColor(ColorResource.surfaceSubtle)
                        .fontColor('#FF3B30')
                        .borderRadius(ThemeConfig.radiusSmall)
                        .onClick(() => {
                          this.deleteComponentFromSelectedSchema(component.id);
                        });
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                    .backgroundColor(ColorResource.backgroundSecondary)
                    .borderRadius(ThemeConfig.radiusMedium);
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
            .padding({ left: 8, right: 8, top: 6, bottom: 6 })
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
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
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
    
    if (!(this.getSelectedSchema() as NodeSchema).rules || (this.getSelectedSchema() as NodeSchema).rules!.length === 0) {
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
  .padding(12)
  .backgroundColor(ColorResource.surface)
  .borderRadius(8);
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
        .padding({ left: 8, right: 12, top: 8, bottom: 8 })
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
          .padding({ left: 8, right: 12, top: 8, bottom: 8 })
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
            
            Button('导出JSON')
              .fontSize(ThemeConfig.fontSizeS)
              .height(36)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                this.refreshSchemaJson();
                this.promptAction.showToast({ message: 'JSON已刷新', duration: 2000 });
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

      Row({ space: 0 }) {
        this.SchemaList();
        
        Divider()
          .vertical(true)
          .strokeWidth(1)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.2);
        
        this.PreviewPanel();
        
        Divider()
          .vertical(true)
          .strokeWidth(1)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.2);
        
        this.EditorPanel();
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
  }
}
