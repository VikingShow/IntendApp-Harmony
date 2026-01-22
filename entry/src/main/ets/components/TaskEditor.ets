// File: entry/src/main/ets/components/TaskEditor.ets
/**
 * 任务编辑器组件模块
 * 
 * 本组件是任务详情编辑的核心界面，提供任务属性编辑、检查清单管理、
 * 依赖关系创建等完整功能。采用苹果风格设计，提供优雅的用户体验。
 * 
 * 主要功能：
 * 1. 任务属性编辑：编辑任务名称、开始时间、结束时间等基本信息
 * 2. 检查清单管理：添加、编辑、删除任务的检查清单项目
 * 3. 进度跟踪：通过检查清单完成情况跟踪任务进度
 * 4. 依赖关系：创建和管理任务间的依赖关系
 * 5. 任务操作：删除任务、返回列表等基本操作
 * 6. 数据验证：提供输入数据的有效性验证和错误提示
 * 
 * 设计特点：
 * - 苹果风格：采用苹果设计语言，提供优雅的视觉体验
 * - 响应式布局：根据内容动态调整界面布局
 * - 实时验证：提供实时的输入验证和错误提示
 * - 交互友好：提供丰富的交互反馈和状态指示
 * - 模块化设计：将不同功能模块化为独立的UI组件
 * 
 * 界面结构：
 * - 头部信息：任务基本信息和编辑状态
 * - 属性编辑：任务名称、时间等属性编辑区域
 * - 检查清单：任务检查清单的管理和编辑
 * - 操作按钮：任务相关的各种操作按钮
 * - 底部导航：返回、删除等导航操作
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { TaskNode, ChecklistItem, Dependency, Project } from '../model/ProjectData';
import { NodeSchema, TaskNodeWithSchema, FieldSchema, NodeFieldValue, NodeComponentSchema } from '../model/NodeSchema';
import { NodeSchemaService } from '../services/NodeSchemaService';
import { CommonButton } from './CommonButton';
import { ValidationUtils } from '../utils/ValidationUtils';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { PromptAction } from '@kit.ArkUI';

/**
 * 任务依赖信息接口
 */
interface TaskDependencyInfo {
  fromId: string;
  toId: string;
  fromName: string;
  toName: string;
  type: string;
}

interface ProgressCounts {
  total: number;
  done: number;
}

/**
 * 任务更新载荷类型
 * 在原有 TaskNode 基础上扩展 schema 相关字段
 */
interface TaskUpdatePayload extends Partial<TaskNode> {
  typeId?: string;
  customFields?: Map<string, NodeFieldValue>;
}

interface NodeTypeOption {
  id: string;
  name: string;
}

/**
 * 任务编辑器组件
 * 
 * 实现任务详情编辑的核心UI组件，提供完整的任务管理功能。
 * 采用苹果风格设计，确保用户界面的一致性和易用性。
 * 
 * 组件特性：
 * - 响应式数据绑定：使用@Prop实现数据的自动同步
 * - 实时验证：提供输入数据的实时验证和错误提示
 * - 模块化设计：将功能分解为独立的UI模块
 * - 交互反馈：提供丰富的用户操作反馈
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
@Component
export struct TaskEditor {
  /** 当前编辑的任务对象 */
  @Prop @Watch('onTaskChanged') task: TaskNode | null;
  @State newChecklistItemText: string = '';
  @State private localTask: TaskNode | null = null; // 内部编辑状态（因为@Prop是只读的）
  @State private taskNameDraft: string = '';
  @State private taskNameInputKey: number = 0;
  @State private forceUpdateKey: number = 0;
  @State private autoSaveTimer: number | null = null;
  @State private hasUnsavedChanges: boolean = false;
  @State private debounceTimer: number | null = null;
  @State private dateTabIndex: number = 0; // 日期Tab索引：0-开始日期，1-结束日期
  @State private displayStartDate: Date = new Date(); // 用于DatePicker绑定的开始日期
  @State private displayEndDate: Date = new Date(); // 用于DatePicker绑定的结束日期
  @State private displayChecklist: ChecklistItem[] = []; // 用于清单显示的数据
  @State private displayDependencies: TaskDependencyInfo[] = []; // 用于依赖关系显示的数据
  @State private tagDraftTextByFieldId: Map<string, string> = new Map<string, string>();
  // 任务切换动画相关状态
  @State private editorOpacity: number = 1; // 编辑器透明度
  @State private editorTranslateY: number = 0; // 编辑器垂直位移
  @State private isTransitioning: boolean = false; // 是否正在切换任务
  private lastTaskId: string | null = null; // 跟踪上次的任务ID
  private lastTaskDataHash: string = ''; // 跟踪任务数据的内容哈希，用于检测数据变化
  // 防重复提交子任务的节流信息
  private lastAddedChecklistText: string = '';
  private lastAddedChecklistTime: number = 0;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  @State private showNodeTypeDropdown: boolean = false;

  private getCurrentSchema(): NodeSchema | null {
    const service = NodeSchemaService.getInstance();
    const typeId = this.getCurrentNodeTypeId();
    return service.getSchemaById(typeId);
  }

  private getOrCreateCustomFieldsMap(task: TaskNodeWithSchema): Map<string, NodeFieldValue> {
    if (task.customFields) {
      return task.customFields;
    }
    task.customFields = new Map<string, NodeFieldValue>();
    return task.customFields;
  }

  private getCustomFieldValue(task: TaskNodeWithSchema, fieldId: string): NodeFieldValue {
    const map = this.getOrCreateCustomFieldsMap(task);
    if (map.has(fieldId)) {
      return map.get(fieldId) as NodeFieldValue;
    }
    return null;
  }

  private setCustomFieldValue(task: TaskNodeWithSchema, fieldId: string, value: NodeFieldValue): void {
    const map = this.getOrCreateCustomFieldsMap(task);
    map.set(fieldId, value);
  }

  private updateCustomFieldIfChanged(task: TaskNodeWithSchema, fieldId: string, value: NodeFieldValue): boolean {
    const map = this.getOrCreateCustomFieldsMap(task);
    const current = map.has(fieldId) ? (map.get(fieldId) as NodeFieldValue) : null;
    if (current === value) {
      return false;
    }
    map.set(fieldId, value);
    return true;
  }

  private commitCustomFields(task: TaskNodeWithSchema): void {
    const updates: TaskUpdatePayload = { customFields: this.getOrCreateCustomFieldsMap(task) };
    this.onUpdateTask((this.localTask as TaskNode)!.id, updates as Partial<TaskNode>);
  }

  private getCustomFieldText(task: TaskNodeWithSchema, fieldId: string): string {
    const v = this.getCustomFieldValue(task, fieldId);
    if (v === null || v === undefined) {
      return '';
    }
    if (typeof v === 'string') {
      return v;
    }
    if (typeof v === 'number' || typeof v === 'boolean') {
      return String(v);
    }
    if (v instanceof Date) {
      return v.toISOString();
    }
    // string[]
    return Array.isArray(v) ? v.join(',') : '';
  }

  private parseFieldValue(field: FieldSchema | null, raw: string): NodeFieldValue {
    if (!field) {
      return raw;
    }
    if (field.type === 'number') {
      const n = Number(raw);
      return Number.isNaN(n) ? null : n;
    }
    if (field.type === 'boolean') {
      return raw === 'true';
    }
    if (field.type === 'date') {
      const d = new Date(raw);
      return isNaN(d.getTime()) ? null : d;
    }
    if (field.type === 'select') {
      return raw;
    }
    if (field.type === 'checklist') {
      const parts = raw.split(',').map(s => s.trim()).filter(s => s.length > 0);
      return parts;
    }
    return raw;
  }

  private getTagDraft(fieldId: string): string {
    if (this.tagDraftTextByFieldId.has(fieldId)) {
      return this.tagDraftTextByFieldId.get(fieldId) as string;
    }
    return '';
  }

  private setTagDraft(fieldId: string, value: string): void {
    this.tagDraftTextByFieldId.set(fieldId, value);
    // 注意：不要在这里更新 forceUpdateKey，否则会导致输入框失去焦点
  }

  private getTagsValue(task: TaskNodeWithSchema, fieldId: string): string[] {
    const v = this.getCustomFieldValue(task, fieldId);
    if (Array.isArray(v)) {
      return v as string[];
    }
    if (typeof v === 'string') {
      const parts = v.split(',').map(s => s.trim()).filter(s => s.length > 0);
      return parts;
    }
    return [];
  }

  private setTagsValue(task: TaskNodeWithSchema, fieldId: string, tags: string[]): void {
    // 去重 + 去空
    const normalized = tags.map(t => t.trim()).filter(t => t.length > 0);
    const unique: string[] = [];
    normalized.forEach((t: string) => {
      if (!unique.includes(t)) {
        unique.push(t);
      }
    });
    this.setCustomFieldValue(task, fieldId, unique);
  }

  private addTag(task: TaskNodeWithSchema, fieldId: string, tag: string): void {
    const current = this.getTagsValue(task, fieldId);
    const trimmed = tag.trim();
    if (trimmed.length === 0) {
      return;
    }
    const next = current.includes(trimmed) ? current : current.concat([trimmed]);
    this.setTagsValue(task, fieldId, next);
  }

  private removeTag(task: TaskNodeWithSchema, fieldId: string, tag: string): void {
    const current = this.getTagsValue(task, fieldId);
    const next = current.filter(t => t !== tag);
    this.setTagsValue(task, fieldId, next);
  }

  private getProgressCounts(): ProgressCounts {
    const total = this.displayChecklist.length;
    const done = this.displayChecklist.filter((i: ChecklistItem) => i.isCompleted).length;
    return { total, done };
  }

  private getCompletionProgress(task: TaskNode): number {
    const total = task.checklist ? task.checklist.length : 0;
    if (total <= 0) {
      return 0;
    }
    const done = task.checklist.filter((i: ChecklistItem) => i.isCompleted).length;
    return Math.round(done * 100 / total);
  }

  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  private getTimeProgress(task: TaskNode): number {
    const totalDays = this.getDuration(task);
    if (totalDays <= 0) {
      return 0;
    }
    const now = Date.now();
    const start = task.startDate.getTime();
    const end = task.endDate.getTime();
    if (now <= start) {
      return 0;
    }
    if (now >= end) {
      return 100;
    }
    const ratio = (now - start) / (end - start);
    return Math.max(0, Math.min(100, Math.round(ratio * 100)));
  }

  private getFieldIdForComponent(component: NodeComponentSchema): string {
    return component.fieldId && component.fieldId.length > 0
      ? component.fieldId
      : this.getReservedFieldIdByComponentType(component.type);
  }

  private getSelectDisplayValue(fieldId: string, boundField: FieldSchema): string {
    if (!this.localTask) {
      return '请选择';
    }
    const task = this.localTask as TaskNodeWithSchema;
    const v = this.getCustomFieldValue(task, fieldId);
    if (typeof v === 'string' && v.length > 0) {
      return v;
    }
    return '请选择';
  }

  private isTagSelected(fieldId: string, tag: string): boolean {
    if (!this.localTask) {
      return false;
    }
    const tags = this.getTagsValue(this.localTask as TaskNodeWithSchema, fieldId);
    return tags.includes(tag);
  }

  private getBoundFieldForComponent(component: NodeComponentSchema): FieldSchema | null {
    return this.getComponentBoundField(this.getCurrentSchema(), component);
  }

  private getFieldIdForComponentSafe(component: NodeComponentSchema): string {
    const id = this.getFieldIdForComponent(component);
    return id ? id : '';
  }

  @Builder
  private renderTagsChipsEditor(fieldId: string, boundField: FieldSchema | null) {
    if (!this.localTask) {
      Text('未选择任务')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textTertiary);
    } else {
      Column({ space: 10 }) {
        if (boundField && boundField.options && boundField.options.length > 0) {
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              Text('推荐')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ColorResource.textSecondary)
                .layoutWeight(1);
              Button('清空全部')
                .height(28)
                .padding({ left: 10, right: 10 })
                .backgroundColor(ColorResource.backgroundSecondary)
                .fontColor(ColorResource.textSecondary)
                .borderRadius(14)
                .onClick(() => {
                  if (!this.localTask) return;
                  const tt = this.localTask as TaskNodeWithSchema;
                  if (this.getTagsValue(tt, fieldId).length === 0) {
                    return;
                  }
                  this.setTagsValue(tt, fieldId, []);
                  this.forceUpdateKey++;
                  this.commitCustomFields(tt);
                });
            }
            .width('100%');

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              ForEach(boundField.options, (opt: string, index: number) => {
                Button() {
                  Text(opt)
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(this.isTagSelected(fieldId, opt) ? Color.White : ColorResource.primaryColor);
                }
                .height(30)
                .padding({ left: 10, right: 10 })
                .backgroundColor(this.isTagSelected(fieldId, opt) ? ColorResource.primaryColor : ColorResource.primaryUltraLight)
                .borderRadius(15)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  if (!this.localTask) return;
                  const tt = this.localTask as TaskNodeWithSchema;
                  const current = this.getTagsValue(tt, fieldId);
                  if (current.includes(opt)) {
                    this.removeTag(tt, fieldId, opt);
                  } else {
                    this.addTag(tt, fieldId, opt);
                  }
                  this.forceUpdateKey++;
                  this.commitCustomFields(tt);
                });
              }, (opt: string, index: number) => `${fieldId}-opt-${opt}-${index}-${this.forceUpdateKey}`)
            }
            .width('100%');
          }
          .padding(10)
          .backgroundColor(ColorResource.surfaceLight)
          .borderRadius(12)
          .border({ width: 1, color: ColorResource.surfaceNeutral, radius: 12 });
        }

        if (this.getTagsValue(this.localTask as TaskNodeWithSchema, fieldId).length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            ForEach(this.getTagsValue(this.localTask as TaskNodeWithSchema, fieldId), (t: string, index: number) => {
              Row({ space: 6 }) {
                Text(t)
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.primaryColor);
                Button() {
                  Text('×')
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontColor(ColorResource.textSecondary);
                }
                .width(22)
                .height(22)
                .type(ButtonType.Circle)
                .backgroundColor(ColorResource.backgroundSecondary)
                .borderRadius(11)
                .onClick(() => {
                  if (!this.localTask) return;
                  const tt = this.localTask as TaskNodeWithSchema;
                  this.removeTag(tt, fieldId, t);
                  this.forceUpdateKey++;
                  this.commitCustomFields(tt);
                })
              }
              .padding({ left: 10, right: 8, top: 6, bottom: 6 })
              .backgroundColor(ColorResource.primaryUltraLight)
              .borderRadius(16)
              .margin({ right: 8, bottom: 8 });
            }, (t: string, index: number) => `${fieldId}-tag-${t}-${index}-${this.forceUpdateKey}`)
          }
          .width('100%');
        } else {
          Text('还没有标签，添加一个吧')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textTertiary);
        }

        Row({ space: 10 }) {
          TextInput({
            text: this.getTagDraft(fieldId),
            placeholder: '输入标签（回车添加）'
          })
            .layoutWeight(1)
            .backgroundColor(ColorResource.transparent)
            .borderRadius(ThemeConfig.radiusMedium)
            .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
            .fontSize(ThemeConfig.fontSizeM)
            .fontColor(ColorResource.surfaceDeep)
            .placeholderColor(ColorResource.surfaceEmphasized)
            .shadow(ThemeConfig.inputShadow)
            .border({ width: 2, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusMedium })
            .enterKeyType(EnterKeyType.Done)
            .onChange((v: string) => {
              this.setTagDraft(fieldId, v);
            })
            .onSubmit(() => {
              if (!this.localTask) return;
              const tt = this.localTask as TaskNodeWithSchema;
              const draft = this.getTagDraft(fieldId);
              this.addTag(tt, fieldId, draft);
              this.setTagDraft(fieldId, '');
              this.forceUpdateKey++;
              this.commitCustomFields(tt);
            });

          Button('添加')
            .height(40)
            .padding({ left: 12, right: 12 })
            .backgroundColor(ColorResource.primaryColor)
            .fontColor(Color.White)
            .borderRadius(12)
            .onClick(() => {
              if (!this.localTask) return;
              const tt = this.localTask as TaskNodeWithSchema;
              const draft = this.getTagDraft(fieldId);
              this.addTag(tt, fieldId, draft);
              this.setTagDraft(fieldId, '');
              this.forceUpdateKey++;
              this.commitCustomFields(tt);
            });
        }
        .width('100%');
      }
      .width('100%');
    }
  }

  private getEditorLayoutWithRequiredDateRange(): NodeComponentSchema[] {
    const schema = this.getCurrentSchema();
    const layout: NodeComponentSchema[] = (schema && schema.layout) ? schema.layout : [];
    const hasDateRange = layout.some((c: NodeComponentSchema) => c && c.type === 'DATE_RANGE');
    if (hasDateRange) {
      return layout;
    }
    const requiredDateRange: NodeComponentSchema = { id: '__required_date_range__', type: 'DATE_RANGE' };
    return [requiredDateRange, ...layout];
  }

  private getReservedFieldIdByComponentType(type: string): string {
    // 对于没有 TaskNode 原生字段支持的组件，使用约定字段存到 customFields
    // 这些字段可以在 NodeWorkspace 中由用户自己创建并绑定到 CUSTOM_FIELD；但这里给默认 fallback
    if (type === 'PRIORITY_BADGE') return '_priority';
    if (type === 'ASSIGNEE') return '_assignee';
    if (type === 'TAGS') return '_tags';
    if (type === 'STATUS_DOT') return '_status';
    return '';
  }

  private getComponentBoundField(schema: NodeSchema | null, component: NodeComponentSchema): FieldSchema | null {
    const fieldId = component.fieldId && component.fieldId.length > 0
      ? component.fieldId
      : this.getReservedFieldIdByComponentType(component.type);
    if (!fieldId || fieldId.length === 0) {
      return null;
    }
    if (!schema || !schema.fields) {
      return this.getFallbackFieldSchemaByReservedId(fieldId, component.type);
    }
    const found = schema.fields.find((f: FieldSchema) => f.id === fieldId);
    if (found) {
      return found;
    }
    return this.getFallbackFieldSchemaByReservedId(fieldId, component.type);
  }

  private getFieldSchemaById(schema: NodeSchema | null, fieldId: string): FieldSchema | null {
    if (!schema || !schema.fields) {
      return null;
    }
    const f = schema.fields.find(ff => ff.id === fieldId);
    return f ? f : null;
  }

  private getCustomFieldLabel(component: NodeComponentSchema): string {
    const schema = this.getCurrentSchema();
    const boundField = this.getComponentBoundField(schema, component);
    const fallbackFieldId = component.fieldId && component.fieldId.length > 0
      ? component.fieldId
      : this.getReservedFieldIdByComponentType(component.type);
    if (boundField) {
      return boundField.label;
    }
    return fallbackFieldId.length > 0 ? fallbackFieldId : '未绑定字段';
  }

  private getComponentTypeCn(type: string): string {
    if (type === 'TITLE') return '任务名称';
    if (type === 'DATE_RANGE') return '日期范围';
    if (type === 'TIME_PROGRESS') return '时间进度';
    if (type === 'TASK_PROGRESS') return '完成进度';
    if (type === 'CHECKLIST_SUMMARY') return '清单统计';
    if (type === 'PRIORITY_BADGE') return '优先级';
    if (type === 'ASSIGNEE') return '负责人';
    if (type === 'TAGS') return '标签';
    if (type === 'STATUS_DOT') return '状态';
    if (type === 'CUSTOM_FIELD') return '自定义字段';
    return type;
  }

  private getEditorSectionTitle(component: NodeComponentSchema): string {
    // 优先使用绑定字段的 label
    const schema = this.getCurrentSchema();
    const boundField = this.getComponentBoundField(schema, component);
    if (boundField && boundField.label && boundField.label.length > 0) {
      return boundField.label;
    }
    // 其次用组件类型中文名
    return this.getComponentTypeCn(component.type);
  }

  private getSelectPlaceholderText(component: NodeComponentSchema): string {
    if (component.type === 'PRIORITY_BADGE') return '请选择优先级';
    if (component.type === 'STATUS_DOT') return '请选择状态';
    return '请选择';
  }

  private commitTaskNameDraft(blurAfter: boolean = false): void {
    if (!this.localTask) {
      return;
    }
    const nextName = this.taskNameDraft.trim();
    const validation = ValidationUtils.validateTaskName(nextName);
    if (!validation.isValid) {
      this.promptAction.showToast({ message: validation.message });
      return;
    }
    if (this.localTask.name === nextName) {
      if (blurAfter) {
        this.taskNameInputKey++;
      }
      return;
    }

    this.taskNameDraft = nextName;
    this.localTask.name = nextName;
    this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
    this.onUpdateTask(this.localTask.id, { name: nextName });

    if (blurAfter) {
      this.taskNameInputKey++;
    }
  }

  @Builder
  private renderTitleEditor() {
    Column({ space: 8 }) {
      Text('任务名称')
        .fontSize(ThemeConfig.fontSizeS)
        .fontWeight(ThemeConfig.fontWeightMedium)
        .fontColor(ColorResource.surfaceEmphasized)
      TextInput({ text: this.taskNameDraft, placeholder: '请输入任务名称' })
        .key(`task-name-input-${this.taskNameInputKey}`)
        .backgroundColor(ColorResource.transparent)
        .borderRadius(ThemeConfig.radiusMedium)
        .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
        .fontSize(ThemeConfig.fontSizeL)
        .width('100%')
        .fontColor(ColorResource.surfaceDeep)
        .placeholderColor(ColorResource.surfaceEmphasized)
        .shadow(ThemeConfig.inputShadow)
        .border({
          width: 2,
          color: ColorResource.surfaceNeutral,
          radius: ThemeConfig.radiusMedium
        })
        .onBlur(() => {
          this.commitTaskNameDraft(false);
        })
        .enterKeyType(EnterKeyType.Done)
        .onSubmit(() => {
          this.commitTaskNameDraft(true);
        })
        .onChange((value: string) => {
          this.taskNameDraft = value;
        })
    }
  }

  @Builder
  private renderDateRangeEditor() {
    Column({ space: 0 }) {
      // Tab切换按钮栏
      Row({ space: 0 }) {
        // 开始日期Tab
        Column() {
          Text('开始日期')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(this.dateTabIndex === 0 ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.dateTabIndex === 0 ? ColorResource.primaryColor : ColorResource.textSecondary)
            .padding({ top: 12, bottom: 12, left: 16, right: 16 })
        }
        .layoutWeight(1)
        .backgroundColor(
          this.dateTabIndex === 0 ? ColorResource.primaryUltraLight : ColorResource.transparent
        )
        .borderRadius({ topLeft: ThemeConfig.radiusMedium, topRight: 0, bottomLeft: 0, bottomRight: 0 })
        .border({
          width: { bottom: this.dateTabIndex === 0 ? 2 : 0 },
          color: this.dateTabIndex === 0 ? ColorResource.primaryColor : ColorResource.transparent
        })
        .onClick(() => {
          this.dateTabIndex = 0;
        })

        // 结束日期Tab
        Column() {
          Text('结束日期')
            .fontSize(ThemeConfig.fontSizeM)
            .fontWeight(this.dateTabIndex === 1 ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.dateTabIndex === 1 ? ColorResource.primaryColor : ColorResource.textSecondary)
            .padding({ top: 12, bottom: 12, left: 16, right: 16 })
        }
        .layoutWeight(1)
        .backgroundColor(
          this.dateTabIndex === 1 ? ColorResource.primaryUltraLight : ColorResource.transparent
        )
        .borderRadius({ topLeft: 0, topRight: ThemeConfig.radiusMedium, bottomLeft: 0, bottomRight: 0 })
        .border({
          width: { bottom: this.dateTabIndex === 1 ? 2 : 0 },
          color: this.dateTabIndex === 1 ? ColorResource.primaryColor : ColorResource.transparent
        })
        .onClick(() => {
          this.dateTabIndex = 1;
        })
      }
      .width('100%')
      .backgroundColor(ColorResource.surfaceLight)
      .borderRadius({
        topLeft: ThemeConfig.radiusMedium,
        topRight: ThemeConfig.radiusMedium,
        bottomLeft: 0,
        bottomRight: 0
      })
      .border({
        width: { bottom: 1 },
        color: ColorResource.surfaceNeutral
      })
      .shadow(ThemeConfig.shadowSmall)

      // 日期选择器内容
      if (this.dateTabIndex === 0) {
        DatePicker({
          start: new Date('2020-01-01'),
          end: this.displayEndDate,
          selected: this.displayStartDate
        })
          .backgroundColor(ColorResource.transparent)
          .borderRadius(12)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .border({ width: 0, radius: 12 })
          .width('100%')
          .onDateChange((value: Date) => {
            if (!this.localTask) return;
            const newStartDate = value;
            this.displayStartDate = newStartDate;
            this.localTask.startDate = newStartDate;
            this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
            this.forceUpdateKey++;
            this.onUpdateTask(this.localTask.id, {
              startDate: newStartDate
            });
          })
      } else {
        DatePicker({
          start: this.displayStartDate,
          end: new Date('2030-12-31'),
          selected: this.displayEndDate
        })
          .backgroundColor(ColorResource.transparent)
          .borderRadius(12)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .border({ width: 0, radius: 12 })
          .width('100%')
          .onDateChange((value: Date) => {
            if (!this.localTask) return;
            const newEndDate = value;
            this.displayEndDate = newEndDate;
            this.localTask.endDate = newEndDate;
            this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
            this.forceUpdateKey++;
            this.onUpdateTask(this.localTask.id, {
              endDate: newEndDate
            });
          })
      }
    }
  }

  @Builder
  private renderCustomFieldEditor(component: NodeComponentSchema) {
    Column({ space: 8 }) {
      Text(this.getEditorSectionTitle(component))
        .fontSize(ThemeConfig.fontSizeS)
        .fontWeight(ThemeConfig.fontWeightMedium)
        .fontColor(ColorResource.surfaceEmphasized)

      if (this.getFieldIdForComponentSafe(component).length === 0) {
        Text('该组件未绑定字段，无法编辑')
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ColorResource.textTertiary)
      } else {
        Column() {
          // boolean
          if (this.getBoundFieldForComponent(component) && this.getBoundFieldForComponent(component)!.type === 'boolean') {
            Row({ space: 8 }) {
            Toggle({
              type: ToggleType.Switch,
              isOn: (() => {
                const t = this.localTask as TaskNodeWithSchema | null;
                if (!t) return false;
                const v = this.getCustomFieldValue(t, this.getFieldIdForComponentSafe(component));
                return v === true;
              })()
            })
              .onChange((isOn: boolean) => {
                if (!this.localTask) return;
                const task = this.localTask as TaskNodeWithSchema;
                if (!this.updateCustomFieldIfChanged(task, this.getFieldIdForComponentSafe(component), isOn)) {
                  return;
                }
                this.forceUpdateKey++;
                this.commitCustomFields(task);
              });
            Text((() => {
              const t = this.localTask as TaskNodeWithSchema | null;
              if (!t) return '否';
              const v = this.getCustomFieldValue(t, this.getFieldIdForComponentSafe(component));
              return v === true ? '是' : '否';
            })())
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textSecondary);
          }
          .width('100%')
          } else if (this.getBoundFieldForComponent(component)
            && this.getBoundFieldForComponent(component)!.type === 'select'
            && this.getBoundFieldForComponent(component)!.options
            && this.getBoundFieldForComponent(component)!.options!.length > 0) {
          // select（使用 bindMenu，避免 Select API 在 ArkTS 下的重载限制）
          Button() {
            Row({ space: 8 }) {
              Text((() => {
                const v = this.getSelectDisplayValue(this.getFieldIdForComponentSafe(component), this.getBoundFieldForComponent(component)!);
                if (v === '请选择') {
                  return this.getSelectPlaceholderText(component);
                }
                return v;
              })())
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor((() => {
                  const v = this.getSelectDisplayValue(this.getFieldIdForComponentSafe(component), this.getBoundFieldForComponent(component)!);
                  return v === '请选择' ? ColorResource.textTertiary : ColorResource.surfaceDeep;
                })())
                .layoutWeight(1);
              Text('▾')
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ColorResource.textSecondary);
            }
          }
          .width('100%')
          .height(44)
          .padding({ left: 12, right: 12 })
          .backgroundColor(ColorResource.transparent)
          .borderRadius(ThemeConfig.radiusMedium)
          .border({ width: 2, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusMedium })
          .bindMenu(this.SelectMenu(this.getFieldIdForComponentSafe(component), this.getBoundFieldForComponent(component)!))
          } else if (this.getBoundFieldForComponent(component) && this.getBoundFieldForComponent(component)!.type === 'checklist') {
          this.renderTagsChipsEditor(this.getFieldIdForComponentSafe(component), this.getBoundFieldForComponent(component));
        } else {
          // 默认 text/number/date/checklist(string[])
          TextInput({
            text: (() => {
              const t = this.localTask as TaskNodeWithSchema | null;
              if (!t) return '';
              return this.getCustomFieldText(t, this.getFieldIdForComponentSafe(component));
            })(),
            placeholder: (() => {
              if (component.type === 'ASSIGNEE') return '请输入负责人';
              if (component.type === 'CUSTOM_FIELD') return '请输入内容';
              return '请输入';
            })()
          })
            .backgroundColor(ColorResource.transparent)
            .borderRadius(ThemeConfig.radiusMedium)
            .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
            .fontSize(ThemeConfig.fontSizeL)
            .width('100%')
            .fontColor(ColorResource.surfaceDeep)
            .placeholderColor(ColorResource.surfaceEmphasized)
            .shadow(ThemeConfig.inputShadow)
            .border({
              width: 2,
              color: ColorResource.surfaceNeutral,
              radius: ThemeConfig.radiusMedium
            })
            .onChange((value: string) => {
              if (!this.localTask) {
                return;
              }
              const task = this.localTask as TaskNodeWithSchema;
              const parsed = this.parseFieldValue(this.getBoundFieldForComponent(component), value);
              if (!this.updateCustomFieldIfChanged(task, this.getFieldIdForComponentSafe(component), parsed)) {
                return;
              }
              this.forceUpdateKey++;
              this.commitCustomFields(task);
            })
          }
        }
        .width('100%')
      }
    }
  }

  @Builder
  private SelectMenu(fieldId: string, boundField: FieldSchema) {
    Menu() {
      ForEach(boundField.options ? boundField.options : [], (opt: string, index: number) => {
        MenuItem({ content: opt })
          .onChange(() => {
            if (!this.localTask) return;
            const task = this.localTask as TaskNodeWithSchema;
            if (!this.updateCustomFieldIfChanged(task, fieldId, opt)) {
              return;
            }
            this.forceUpdateKey++;
            this.commitCustomFields(task);
          });
      }, (opt: string, index: number) => `${fieldId}-sel-${opt}-${index}`)
    }
  }

  @Builder
  private renderChecklistSummaryEditor() {
    Row({ space: 8 }) {
      Text(`清单: ${this.getProgressCounts().done}/${this.getProgressCounts().total}`)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary);
      if (this.localTask) {
        CommonButton({
          text: '编辑清单',
          type: 'secondary',
          buttonSize: 'small',
          onButtonClick: () => {
            this.promptAction.showToast({ message: '请在下方「任务清单」区域编辑' });
          }
        });
      }
    }
    .width('100%')
  }

  @Builder
  private renderTaskProgressEditor() {
    Column({ space: 6 }) {
      Text(`完成进度: ${this.localTask ? this.getCompletionProgress(this.localTask) : 0}%`)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary);
      Progress({ value: this.localTask ? this.getCompletionProgress(this.localTask) : 0, total: 100 })
        .width('100%');
      Text('进度由清单完成情况自动计算')
        .fontSize(ThemeConfig.fontSizeXS)
        .fontColor(ColorResource.textTertiary);
    }
    .width('100%')
  }

  @Builder
  private renderTimeProgressEditor() {
    Column({ space: 6 }) {
      Text(`时间进度: ${this.localTask ? this.getTimeProgress(this.localTask) : 0}%`)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary);
      Progress({ value: this.localTask ? this.getTimeProgress(this.localTask) : 0, total: 100 })
        .width('100%');
      Text('时间进度由起止时间自动计算')
        .fontSize(ThemeConfig.fontSizeXS)
        .fontColor(ColorResource.textTertiary);
    }
    .width('100%')
  }

  @Builder
  private renderPriorityBadgeEditor(component: NodeComponentSchema) {
    // 默认绑定 _priority；推荐在 schema.fields 里声明同 id 的 select 字段以提供 options
    this.renderCustomFieldEditor(component);
  }

  @Builder
  private renderAssigneeEditor(component: NodeComponentSchema) {
    this.renderCustomFieldEditor(component);
  }

  // 获取 TAGS 组件的有效字段定义
  private getEffectiveTagsField(component: NodeComponentSchema): FieldSchema {
    const boundField = this.getBoundFieldForComponent(component);
    if (boundField) {
      return boundField;
    }
    // 默认的 _tags 字段定义
    return {
      id: '_tags',
      label: '标签',
      type: 'checklist',
      required: false,
      options: ['前端', '后端', '设计', '测试', '文档']
    } as FieldSchema;
  }

  // 获取 TAGS 组件的字段ID
  private getEffectiveTagsFieldId(component: NodeComponentSchema): string {
    const fieldId = this.getFieldIdForComponentSafe(component);
    return fieldId.length > 0 ? fieldId : '_tags';
  }

  @Builder
  private renderTagsEditor(component: NodeComponentSchema) {
    // TAGS 组件直接使用标签编辑器，不走 renderCustomFieldEditor
    Column({ space: 8 }) {
      Text(this.getEditorSectionTitle(component))
        .fontSize(ThemeConfig.fontSizeS)
        .fontWeight(ThemeConfig.fontWeightMedium)
        .fontColor(ColorResource.surfaceEmphasized)
      
      this.renderTagsChipsEditor(this.getEffectiveTagsFieldId(component), this.getEffectiveTagsField(component));
    }
    .width('100%')
    .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM });
  }

  @Builder
  private renderStatusDotEditor(component: NodeComponentSchema) {
    this.renderCustomFieldEditor(component);
  }

  @Builder
  private renderComponentEditor(component: NodeComponentSchema) {
    if (component.type === 'TITLE') {
      this.renderTitleEditor();
    } else if (component.type === 'DATE_RANGE') {
      this.renderDateRangeEditor();
    } else if (component.type === 'CHECKLIST_SUMMARY') {
      this.renderChecklistSummaryEditor();
    } else if (component.type === 'TASK_PROGRESS') {
      this.renderTaskProgressEditor();
    } else if (component.type === 'TIME_PROGRESS') {
      this.renderTimeProgressEditor();
    } else if (component.type === 'PRIORITY_BADGE') {
      this.renderPriorityBadgeEditor(component);
    } else if (component.type === 'ASSIGNEE') {
      this.renderAssigneeEditor(component);
    } else if (component.type === 'TAGS') {
      this.renderTagsEditor(component);
    } else if (component.type === 'STATUS_DOT') {
      this.renderStatusDotEditor(component);
    } else if (component.type === 'CUSTOM_FIELD') {
      this.renderCustomFieldEditor(component);
    } else {
      Text(`暂不支持编辑：${component.type}`)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textTertiary)
        .width('100%');
    }
  }
  onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => void = () => {
  };
  onDeleteTask: (id: string) => void = () => {
  };
  onBack: () => void = () => {
  };
  onStartConnecting: () => void = () => {
  };
  onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => void = () => {
  };
  onAddChecklistItem: (taskId: string, text: string) => void = () => {
  };
  onDeleteChecklistItem: (taskId: string, itemId: string) => void = () => {
  };
  // 为当前任务添加日历提醒的回调（由父组件实现具体逻辑）
  onAddReminder: (task: TaskNode) => void = () => {
  };
  // 切换箭头显示的回调
  onToggleArrows: () => void = () => {
  };
  // 删除依赖关系的回调
  onDeleteDependency: (fromId: string, toId: string) => void = () => {
  };
  // 箭头显示状态（由父组件传入）
  @Prop showDependencyArrows: boolean = true;
  // 当前项目（用于获取依赖关系）
  @ObjectLink project: Project | null;

  /**
   * 计算任务数据的哈希值，用于检测数据内容变化
   * 即使对象引用相同，如果内容变化也能检测到
   */
  private computeTaskDataHash(task: TaskNode | null): string {
    if (!task) return '';
    // 使用关键字段计算哈希
    let checklistHash = '';
    if (task.checklist) {
      const checklistItems: ChecklistItem[] = task.checklist.map((item: ChecklistItem) => {
        const mappedItem: ChecklistItem = {
          id: item.id,
          text: item.text,
          isCompleted: item.isCompleted
        };
        return mappedItem;
      });
      checklistHash = JSON.stringify(checklistItems);
    }
    const t = task as TaskNodeWithSchema;
    const typeIdInfo = t && t.typeId ? t.typeId : 'standard';
    return `${task.id}|${task.name}|${task.startDate.getTime()}|${task.endDate.getTime()}|${checklistHash}|${typeIdInfo}`;
  }

  private getFallbackFieldSchemaByReservedId(fieldId: string, componentType: string): FieldSchema | null {
    if (!fieldId || fieldId.length === 0) {
      return null;
    }

    // 尝试从当前 schema 的 fields 中获取最新的选项配置
    const schema = this.getCurrentSchema();
    if (schema && schema.fields) {
      const schemaField = schema.fields.find((f: FieldSchema) => f.id === fieldId);
      if (schemaField) {
        return schemaField;
      }
    }

    // 如果 schema 中没有，则使用默认值
    if (fieldId === '_priority') {
      return {
        id: '_priority',
        label: '优先级',
        type: 'select',
        required: false,
        options: ['低', '中', '高', '紧急']
      } as FieldSchema;
    }
    if (fieldId === '_status') {
      return {
        id: '_status',
        label: '状态',
        type: 'select',
        required: false,
        options: ['未开始', '进行中', '阻塞', '已完成']
      } as FieldSchema;
    }
    if (fieldId === '_tags') {
      return {
        id: '_tags',
        label: componentType === 'TAGS' ? '标签' : '标签',
        type: 'checklist',
        required: false,
        options: ['前端', '后端', '设计', '测试', '文档']
      } as FieldSchema;
    }
    if (fieldId === '_assignee') {
      return {
        id: '_assignee',
        label: '负责人',
        type: 'text',
        required: false
      } as FieldSchema;
    }
    return null;
  }

  /**
   * 更新显示数据（日期、清单和依赖关系）
   */
  private updateDisplayData() {
    const task = this.localTask || this.task;
    if (task) {
      this.displayStartDate = task.startDate;
      this.displayEndDate = task.endDate;
      this.displayChecklist = task.checklist ? [...task.checklist] : [];
      this.displayDependencies = this.getTaskDependencies(task.id);
      console.log(`[TaskEditor] Updated display data: startDate=${task.startDate.toLocaleDateString()}, endDate=${task.endDate.toLocaleDateString()}, checklist=${this.displayChecklist.length} items, dependencies=${this.displayDependencies.length} items`);
    }
  }

  /**
   * 获取可用的节点类型 Schema 列表
   * 当前为内置静态定义，后续会接入节点工作台与持久化
   */
  private getAvailableNodeSchemas(): NodeSchema[] {
    const service = NodeSchemaService.getInstance();
    const schemas = service.getAllSchemas();
    if (schemas && schemas.length > 0) {
      return schemas;
    }

    // 兜底：服务里没有数据时，返回默认标准任务类型
    return [
      {
        id: 'standard',
        version: 1,
        name: '标准任务',
        description: '默认的标准任务节点',
        style: {
          fillColor: '#409EFF'
        },
        fields: [],
        layout: [
          { id: 'title_1', type: 'TITLE' },
          { id: 'date_range_1', type: 'DATE_RANGE' },
          { id: 'time_progress_1', type: 'TIME_PROGRESS' },
          { id: 'task_progress_1', type: 'TASK_PROGRESS' }
        ],
        rules: [],
        isSystem: true,
        isDraft: false
      }
    ];
  }

  /**
   * 获取当前任务的节点类型 ID
   */
  private getCurrentNodeTypeId(): string {
    const task = (this.localTask || this.task) as TaskNodeWithSchema | null;
    if (task && task.typeId) {
      return task.typeId;
    }
    // 默认类型
    return 'standard';
  }

  private getCurrentNodeTypeLabel(): string {
    const currentTypeId: string = this.getCurrentNodeTypeId();
    const service = NodeSchemaService.getInstance();
    const currentSchema: NodeSchema | null = service.getSchemaById(currentTypeId);
    return currentSchema ? currentSchema.name : currentTypeId;
  }

  /**
   * 处理节点类型选择
   */
  private onNodeTypeSelected(typeId: string): void {
    if (!this.localTask) {
      return;
    }
    const taskWithSchema = this.localTask as TaskNodeWithSchema;
    if (taskWithSchema.typeId === typeId) {
      return;
    }

    const service = NodeSchemaService.getInstance();
    const oldTypeId = taskWithSchema.typeId ? taskWithSchema.typeId : 'standard';
    const oldSchema = service.getSchemaById(oldTypeId);
    const newSchema = service.getSchemaById(typeId);

    // 激进策略：只针对 customFields 做删除/初始化；TaskNode 原生字段不删
    const oldFields: FieldSchema[] = oldSchema ? oldSchema.fields : [];
    const newFields: FieldSchema[] = newSchema ? newSchema.fields : [];
    const oldFieldIds: string[] = oldFields.map(f => f.id);
    const newFieldIds: string[] = newFields.map(f => f.id);

    const deletedFieldIds: string[] = oldFieldIds.filter(id => !newFieldIds.includes(id));
    const addedFieldIds: string[] = newFieldIds.filter(id => !oldFieldIds.includes(id));

    const deletedFieldLabels: string[] = [];
    deletedFieldIds.forEach((id: string) => {
      const f = oldFields.find(ff => ff.id === id);
      deletedFieldLabels.push(f ? f.label : id);
    });

    const applySwitch = () => {
      // 迁移 customFields（激进删除）
      const currentCustom = taskWithSchema.customFields ? taskWithSchema.customFields : new Map<string, NodeFieldValue>();
      const nextCustom = new Map<string, NodeFieldValue>();

      // 保留交集
      newFields.forEach((field: FieldSchema) => {
        if (currentCustom.has(field.id)) {
          nextCustom.set(field.id, currentCustom.get(field.id) as NodeFieldValue);
        }
      });

      // 初始化新增字段默认值
      addedFieldIds.forEach((id: string) => {
        const f = newFields.find(ff => ff.id === id);
        if (f) {
          if (f.defaultValue !== undefined) {
            nextCustom.set(f.id, f.defaultValue);
          } else {
            // 最保守兜底：不强行造类型值，保持 null
            nextCustom.set(f.id, null);
          }
        }
      });

      // 写回
      taskWithSchema.customFields = nextCustom;

      taskWithSchema.typeId = typeId;
      this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
      this.forceUpdateKey++;
      // 通过 onUpdateTask 通知父组件，扩展更新载荷类型以兼容 typeId
      const updates: TaskUpdatePayload = { typeId: typeId };
      this.onUpdateTask(this.localTask!.id, updates);
    };

    // 仅提示会被删除的自定义字段
    if (deletedFieldLabels.length > 0) {
      AlertDialog.show({
        title: '切换节点类型',
        message:
          `从「${oldSchema ? oldSchema.name : oldTypeId}」切换到「${newSchema ? newSchema.name : typeId}」将删除以下自定义字段：\n` +
          deletedFieldLabels.map(s => `- ${s}`).join('\n') +
          '\n\nTaskNode 的基础信息（名称/时间/清单等）不会被删除。是否继续？',
        primaryButton: {
          value: '继续切换',
          action: () => {
            applySwitch();
          }
        },
        secondaryButton: {
          value: '取消',
          action: () => {}
        }
      });
      return;
    }

    applySwitch();
  }

  /**
   * @Watch 回调：监听 task prop 变化
   */
  private onTaskChanged() {
    const currentTaskId = this.task?.id || null;
    const taskIdChanged = this.lastTaskId !== currentTaskId;
    
    console.log(`[TaskEditor] onTaskChanged: ${this.lastTaskId || 'null'} -> ${currentTaskId || 'null'}, changed: ${taskIdChanged}`);
    
    if (taskIdChanged && this.task) {
      // 任务ID变化，切换任务
      this.lastTaskId = currentTaskId;
      this.lastTaskDataHash = this.computeTaskDataHash(this.task);
      
      // 触发切换动画
      this.triggerTaskTransition(() => {
        this.localTask = this.task;
        this.taskNameDraft = this.task?.name || '';
        this.forceUpdateKey++;
        this.dateTabIndex = 0;
        this.newChecklistItemText = '';
        this.updateDisplayData();
        console.log(`[TaskEditor] Task switched to: ${this.task?.name}`);
      });
    } else if (this.task && !taskIdChanged) {
      // 同一任务，强制更新 localTask 以确保数据同步
      console.log(`[TaskEditor] Same task, force updating localTask: ${this.task.name}`);
      this.lastTaskDataHash = this.computeTaskDataHash(this.task);
      this.localTask = this.task;
      this.taskNameDraft = this.task?.name || '';
      this.forceUpdateKey++;
      this.updateDisplayData();
    } else if (!this.task) {
      // 任务被清空
      this.lastTaskId = null;
      this.lastTaskDataHash = '';
      this.localTask = null;
      this.taskNameDraft = '';
    }
  }

  aboutToAppear() {
    // 初始化动画状态
    this.editorOpacity = 1;
    this.editorTranslateY = 0;
    const currentTaskId = this.task?.id || null;
    
    // 如果任务存在，初始化数据
    if (this.task) {
      console.log(`[TaskEditor] ===== aboutToAppear START =====`);
      console.log(`[TaskEditor] Task ID: ${currentTaskId}, Name: ${this.task.name}`);
      console.log(`[TaskEditor] Task checklist length: ${this.task.checklist?.length || 0}`);
      if (this.task.checklist && this.task.checklist.length > 0) {
        console.log(`[TaskEditor] Checklist items:`, this.task.checklist.map(item => `${item.text}(${item.isCompleted})`).join(', '));
      }
      
      this.lastTaskId = currentTaskId;
      this.lastTaskDataHash = this.computeTaskDataHash(this.task);
      // 直接设置数据，不触发动画（首次加载不需要动画）
      this.localTask = this.task;
      this.taskNameDraft = this.task?.name || '';
      this.forceUpdateKey++;
      // 重置状态
      this.dateTabIndex = 0;
      this.newChecklistItemText = '';
      // 初始化显示数据
      this.updateDisplayData();
      console.log(`[TaskEditor] After updateDisplayData, displayChecklist length: ${this.displayChecklist.length}`);
      console.log(`[TaskEditor] ===== aboutToAppear END =====`);
    } else {
      // 任务不存在，直接设置
      console.log(`[TaskEditor] aboutToAppear: No task provided`);
      this.lastTaskId = null;
      this.lastTaskDataHash = '';
      this.localTask = null;
      this.taskNameDraft = '';
    }
  }

  aboutToDisappear() {
    // 组件销毁时保存未保存的更改
    if (this.hasUnsavedChanges && this.task) {
      this.saveTaskChanges();
    }
    // 清理定时器
    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer);
    }
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
  }

  // 移除 aboutToUpdate，避免与 @Watch 冲突
  // 所有数据同步由 onTaskChanged 处理

  // 触发任务切换动画
  // 优化：只在任务ID真正变化时触发动画，数据更新时不触发
  // 简化动画逻辑，避免渲染事务警告
  private triggerTaskTransition(callback: () => void) {
    if (this.isTransitioning) {
      // 如果正在切换，直接执行回调，避免动画叠加
      callback();
      return;
    }
    
    this.isTransitioning = true;
    
    // 第一步：淡出并向上滑动
    // 直接更新状态，让ArkUI的动画系统处理
    this.editorOpacity = 0;
    this.editorTranslateY = -20;
    
    // 等待动画完成后更新数据并淡入
    // 使用较短的延迟，确保状态更新在下一帧渲染
    setTimeout(() => {
      callback();
      
      // 第二步：淡入并恢复位置
      // 使用微延迟确保状态更新在正确的渲染帧
      setTimeout(() => {
        this.editorOpacity = 1;
        this.editorTranslateY = 0;
        
        // 动画完成后重置状态
        setTimeout(() => {
          this.isTransitioning = false;
        }, ThemeConfig.animationNormal);
      }, 10); // 小延迟确保状态更新在下一帧
    }, ThemeConfig.animationNormal);
  }

  // 封装一个统一的添加函数
  private submitNewChecklistItem() {
    // 优先使用本地副本，确保不会直接修改 @Prop task
    const baseTask = this.localTask || this.task;
    const rawText = this.newChecklistItemText;
    const text = rawText.trim();

    if (!baseTask || text === '') {
      return;
    }

    // 验证清单项
    const validation = ValidationUtils.validateChecklistItem(text);
    if (!validation.isValid) {
      this.promptAction.showToast({ message: validation.message });
      return;
    }

    // 防止极短时间内重复提交相同文本导致的双重新增
    const now = Date.now();
    if (text === this.lastAddedChecklistText && now - this.lastAddedChecklistTime < 500) {
      console.log('[TaskEditor] Duplicate checklist submit ignored:', text);
      return;
    }
    this.lastAddedChecklistText = text;
    this.lastAddedChecklistTime = now;

    console.log(`[TaskEditor] Adding new checklist item: ${text}`);

    // 确保 localTask 存在并作为可变副本使用
    if (!this.localTask && this.task) {
      this.localTask = this.task;
    }
    const targetTask = this.localTask || baseTask;

    // 创建新的清单项
    const newItem: ChecklistItem = {
      id: `item_${Date.now()}`,
      text: text,
      isCompleted: false
    };

    // 更新本地任务与显示清单
    const currentChecklist = targetTask.checklist || [];
    const newChecklist: ChecklistItem[] = currentChecklist.concat([newItem]);
    targetTask.checklist = newChecklist;
    this.displayChecklist = [...newChecklist];

    // 更新数据哈希与刷新 key
    this.lastTaskDataHash = this.computeTaskDataHash(targetTask);
    this.forceUpdateKey++;

    // 清空输入框
    this.newChecklistItemText = '';

    // 通知父组件使用完整 checklist 进行更新（单一路径，避免重复）
    this.onUpdateChecklist(targetTask.id, newChecklist);
  }

  // 删除子任务
  private deleteChecklistItem(itemId: string) {
    const task = this.task || this.localTask;
    if (task && task.checklist) {
      console.log(`[TaskEditor] Deleting checklist item: ${itemId}`);
      
      // 创建新的清单数组
      const newChecklist = task.checklist.filter(item => item.id !== itemId);
      
      // 只更新 localTask 用于本地显示（不修改 @Prop task）
      if (this.localTask) {
        this.localTask.checklist = newChecklist;
      }
      
      // 更新显示清单
      this.displayChecklist = this.displayChecklist.filter(item => item.id !== itemId);
      
      // 更新数据哈希
      this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
      
      this.forceUpdateKey++;
      
      // 立即通知父组件更新数据（让数据从父组件流回来）
      this.onDeleteChecklistItem(task.id, itemId);
      
      this.promptAction.showToast({ message: '子任务已删除' });
    }
  }

  // 防抖的自动保存任务更改
  private scheduleAutoSave() {
    this.hasUnsavedChanges = true;
    
    // 清除之前的防抖定时器
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    
    // 设置防抖定时器（500ms后触发自动保存）
    this.debounceTimer = setTimeout(() => {
      this.performAutoSave();
    }, 500);
  }

  // 执行自动保存
  private performAutoSave() {
    // 清除之前的自动保存定时器
    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer);
    }
    
    // 设置新的自动保存定时器（1秒后保存）
    this.autoSaveTimer = setTimeout(() => {
      this.saveTaskChanges();
    }, 1000);
  }

  /**
   * 获取任务的所有依赖关系（入度和出度）
   */
  private getTaskDependencies(taskId: string): TaskDependencyInfo[] {
    if (!this.project) return [];
    
    const dependencies: TaskDependencyInfo[] = [];
    
    // 查找所有相关的依赖关系
    this.project.dependencies.forEach((dep: Dependency) => {
      if (dep.fromId === taskId || dep.toId === taskId) {
        const fromTask = this.project!.tasks.find(t => t.id === dep.fromId);
        const toTask = this.project!.tasks.find(t => t.id === dep.toId);
        
        if (fromTask && toTask) {
          const depInfo: TaskDependencyInfo = {
            fromId: dep.fromId,
            toId: dep.toId,
            fromName: fromTask.name,
            toName: toTask.name,
            type: dep.toId === taskId ? 'incoming' : 'outgoing'
          };
          dependencies.push(depInfo);
        }
      }
    });
    
    return dependencies;
  }

  // 保存任务更改（现在主要用于清理状态，实际保存已在各个 onChange 中立即触发）
  private saveTaskChanges() {
    if (this.hasUnsavedChanges) {
      console.log(`[TaskEditor] Clearing unsaved changes flag`);
      this.hasUnsavedChanges = false;
    }
  }

  build() {
    // 确保只有一个根节点 - 使用Column包裹条件渲染
    Column() {
      if (this.localTask || this.task) {
        this.buildTaskEditor()
      } else {
        Column() {
          Text('未选择任务')
            .fontSize(ThemeConfig.fontSizeL)
            .fontColor(ColorResource.textTertiary)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTaskEditor() {
    Scroll() {
        Column({ space: 20 }) { /* TOP ACTION ROW START */
          Row({ space: 12 }) {
            // 返回列表按钮
            Button() {
              Image($r('app.media.ic_back'))
                .width(22)
                .height(22)
                .fillColor(ColorResource.surfaceBold)
            }
            .width(52)
            .height(52)
            .type(ButtonType.Circle)
            .backgroundColor(ColorResource.surfaceLight)
            .borderRadius(26)
            .shadow(ThemeConfig.shadowMedium)
            .border({ width: 2, color: ColorResource.surfaceNeutral, radius: 26 })
            .onClick(() => {
              this.onBack();
            })
          }
          .width('100%')

           Column({ space: 16 }) {
            Row({ space: 12 }) {
              Text('编辑任务')
                 .fontSize(ThemeConfig.fontSizeXXL)
                 .fontWeight(ThemeConfig.fontWeightMedium)
                 .fontColor(ColorResource.surfaceDeep)
                 .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 日期选择区域 - 使用自定义Tab切换（苹果风格）
            // 节点类型选择（下拉）
            Column({ space: 8 }) {
              Text('节点类型')
                 .fontSize(ThemeConfig.fontSizeS)
                 .fontWeight(ThemeConfig.fontWeightMedium)
                 .fontColor(ColorResource.surfaceEmphasized)
              Column() {
                Row({ space: 8 }) {
                  // 当前节点类型标签在 getCurrentNodeTypeLabel 中计算

                  Text(this.getCurrentNodeTypeLabel())
                    .fontSize(ThemeConfig.fontSizeS)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                    .fontColor(ColorResource.surfaceDeep)
                    .layoutWeight(1)
                  Text(this.showNodeTypeDropdown ? '▲' : '▼')
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.textSecondary)
                }
                .padding({
                  left: ThemeConfig.spacingM,
                  right: ThemeConfig.spacingM,
                  top: ThemeConfig.spacingXS,
                  bottom: ThemeConfig.spacingXS
                })
                .backgroundColor(ColorResource.surfaceLight)
                .borderRadius(ThemeConfig.radiusMedium)
                .border({
                  width: 1,
                  color: ColorResource.surfaceNeutral,
                  radius: ThemeConfig.radiusMedium
                })
                .onClick(() => {
                  this.showNodeTypeDropdown = !this.showNodeTypeDropdown;
                })

                if (this.showNodeTypeDropdown) {
                  Column({ space: 4 }) {
                    ForEach(this.getAvailableNodeSchemas(), (schema: NodeSchema) => {
                      Row() {
                        Text(schema.name)
                          .fontSize(ThemeConfig.fontSizeS)
                          .fontWeight(schema.id === this.getCurrentNodeTypeId() ? ThemeConfig.fontWeightMedium : FontWeight.Normal)
                          .fontColor(schema.id === this.getCurrentNodeTypeId() ? ColorResource.primaryColor : ColorResource.textSecondary)
                      }
                      .padding({
                        left: ThemeConfig.spacingM,
                        right: ThemeConfig.spacingM,
                        top: ThemeConfig.spacingXS,
                        bottom: ThemeConfig.spacingXS
                      })
                      .backgroundColor(schema.id === this.getCurrentNodeTypeId() ? ColorResource.primaryUltraLight : ColorResource.surfaceLight)
                      .borderRadius(ThemeConfig.radiusMedium)
                      .onClick(() => {
                        this.onNodeTypeSelected(schema.id);
                        this.showNodeTypeDropdown = false;
                      })
                    }, (schema: NodeSchema, index: number) => `task-editor-node-schema-dropdown-${schema.id}-${index}`)
                  }
                  .margin({ top: ThemeConfig.spacingXS })
                  .backgroundColor(ColorResource.surfaceLight)
                  .borderRadius(ThemeConfig.radiusMedium)
                  .border({
                    width: 1,
                    color: ColorResource.surfaceNeutral,
                    radius: ThemeConfig.radiusMedium
                  })
                }
              }
            }

             // 动态编辑区域（按 schema.layout 渲染）
             Column({ space: 14 }) {
               ForEach(
                 (this.getEditorLayoutWithRequiredDateRange() && this.getEditorLayoutWithRequiredDateRange().length > 0)
                   ? this.getEditorLayoutWithRequiredDateRange()
                   : [],
                 (component: NodeComponentSchema, index: number) => {
                   Column({ space: 8 }) {
                     this.renderComponentEditor(component);
                   }
                   .width('100%')
                   .padding(12)
                   .backgroundColor(ColorResource.transparent)
                   .borderRadius(ThemeConfig.radiusMedium)
                   .border({ width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusMedium })
                 },
                 (component: NodeComponentSchema, index: number) => `task-editor-layout-${component.id}-${index}-${this.forceUpdateKey}`
               )

               Text('当前节点类型没有可编辑的布局')
                 .fontSize(ThemeConfig.fontSizeS)
                 .fontColor(ColorResource.textTertiary)
                 .width('100%')
                 .opacity((this.getEditorLayoutWithRequiredDateRange() && this.getEditorLayoutWithRequiredDateRange().length > 0) ? 0 : 1)
                 .height((this.getEditorLayoutWithRequiredDateRange() && this.getEditorLayoutWithRequiredDateRange().length > 0) ? 0 : undefined);
             }
             .width('100%')

            // 工期显示与日历提醒
            Row({ space: 8 }) {
              Text(`工期: ${this.localTask ? this.getDuration(this.localTask) : 0} 天`)
                .fontSize(13)
                .fontColor(ColorResource.textTertiary)
                .fontWeight(FontWeight.Medium)
              CommonButton({
                text: '添加日历提醒',
                type: 'secondary',
                buttonSize: 'small',
                onButtonClick: () => {
                  this.onAddReminder(this.localTask!);
                }
              })
                .width(140)
                .opacity(this.localTask ? 1 : 0)
                .height(this.localTask ? undefined : 0)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor(ColorResource.transparent)
          .borderRadius(ThemeConfig.radiusXLarge)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusXLarge })

          // --- 任务清单卡片  ---
          Column({ space: 16 }) {
            // 清单标题
            Row({ space: 8 }) {
              Text('任务清单')
                 .fontSize(18)
                 .fontWeight(FontWeight.Medium)
                 .fontColor(ColorResource.textPrimary)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 添加新子任务
            Row({ space: 12 }) {
              TextInput({ 
                placeholder: '添加一个子任务...', 
                text: this.newChecklistItemText 
              })
                .layoutWeight(1)
                .backgroundColor(ColorResource.transparent)
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(ColorResource.surfaceDeep)
                .placeholderColor(ColorResource.surfaceEmphasized)
                .shadow(ThemeConfig.inputShadow)
                .border({ 
                  width: 2, 
                  color: ColorResource.surfaceNeutral, 
                  radius: ThemeConfig.radiusMedium 
                })
                  .enterKeyType(EnterKeyType.Go)
                  .onFocus(() => {
                    console.log('[TaskEditor] Checklist input focused');
                  })
                  .onChange((value: string) => {
                    this.newChecklistItemText = value;
                  })
                  .onSubmit(() => {
                    this.submitNewChecklistItem();
                  })
                  Button() {
                    Text('+')
                      .fontSize(ThemeConfig.fontSizeL)
                      .fontColor(ColorResource.primaryColor)
                      .fontWeight(ThemeConfig.fontWeightBold)
                  }
                  .width(40)
                  .height(40)
                  .type(ButtonType.Circle)
                  .backgroundColor(ColorResource.primaryLight)
                  .borderRadius(20)
                  .shadow(ThemeConfig.shadowMedium)
                  .border({ width: 2, color: ColorResource.primaryColor, radius: 20 })
                  .onClick(() => {
                    this.submitNewChecklistItem();
                  })
            }

            // 子任务列表 
            if (!this.displayChecklist || this.displayChecklist.length === 0) {
              Column({ space: 12 }) {
                Image($r('app.media.ic_empty_box'))
                  .width(32)
                  .height(32)
                  .fillColor(ColorResource.textTertiary)
                  .opacity(0.5)
                Text('暂无子任务')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textTertiary)
              }
              .width('100%')
              .padding(24)
              .justifyContent(FlexAlign.Center)
              .key(`empty-checklist-${this.forceUpdateKey}`)
            } else {
              Column({ space: 8 }) {
                ForEach(this.displayChecklist, (item: ChecklistItem, index: number) => {
                  Row({ space: 12 }) {
                    Checkbox({ name: item.id, group: 'checklist' })
                      .select(item.isCompleted)
                      .onChange((value: boolean) => {
                        if (this.localTask) {
                          console.log(`[TaskEditor] Checkbox changed for task ${this.localTask.id}, item ${item.id}: ${value}`);
                          
                          const newChecklist = this.displayChecklist.map(i => {
                            if (i.id === item.id) {
                              return {
                                id: i.id,
                                text: i.text,
                                isCompleted: value
                              };
                            }
                            return i;
                          });
                          
                          // 更新显示清单
                          this.displayChecklist = newChecklist;
                          
                          // 更新localTask
                          this.localTask.checklist = newChecklist;
                          
                          // 更新数据哈希
                          this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
                          
                          // 通知父组件更新数据 - 使用localTask.id确保更新正确的任务
                          this.onUpdateChecklist(this.localTask.id, newChecklist);
                        }
                      })
                    Text(item.text)
                      .fontSize(15)
                      .fontColor(item.isCompleted ? ColorResource.textTertiary : ColorResource.textPrimary)
                      .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
                      .layoutWeight(1)
                      .textAlign(TextAlign.Start)
                    
                    // 删除按钮 - 现代化设计，增强交互反馈
                    Button() {
                      Text('×')
                        .fontSize(16)
                        .fontColor(ColorResource.errorColor)
                        .fontWeight(ThemeConfig.fontWeightBold)
                    }
                    .width(40)
                    .height(40)
                    .type(ButtonType.Circle)
                    .backgroundColor(ColorResource.errorLight)
                    .border({ width: 2, color: ColorResource.errorColor, radius: 20 })
                    .shadow(ThemeConfig.shadowMedium)
                    .onClick(() => {
                      this.deleteChecklistItem(item.id);
                    })
                  }
                  .width('100%')
                  .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                  .backgroundColor(item.isCompleted ? ColorResource.surfaceLight : ColorResource.transparent)
                  .borderRadius(ThemeConfig.radiusMedium)
                  .shadow(item.isCompleted ? ThemeConfig.shadowSmall : ThemeConfig.shadowSmall)
                  .border({ 
                    width: 0, 
                    color: 'transparent', 
                    radius: ThemeConfig.radiusMedium 
                  })
                  .margin({ bottom: ThemeConfig.spacingXS })
                }, (item: ChecklistItem, index: number) => `checklist-item-${this.forceUpdateKey}-${item.id}-${index}`)
              }
              .key(`checklist-container-${this.forceUpdateKey}`)
            }
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor(ColorResource.transparent)
          .borderRadius(ThemeConfig.radiusXLarge)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusXLarge })

          // --- 设置和依赖管理卡片 ---
          Column({ space: 16 }) {
            // 设置标题
            Row({ space: 8 }) {
              Text('设置与依赖')
                 .fontSize(18)
                 .fontWeight(FontWeight.Medium)
                 .fontColor(ColorResource.textPrimary)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 箭头显示开关
            Row({ space: 12 }) {
              Text('显示依赖连线箭头')
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ColorResource.textPrimary)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.showDependencyArrows })
                .selectedColor(ColorResource.primaryColor)
                .onChange((isOn: boolean) => {
                  this.onToggleArrows();
                })
            }
            .width('100%')
            .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
            .backgroundColor(ColorResource.overlaySubtle)
            .borderRadius(ThemeConfig.radiusMedium)
            .backdropBlur(ThemeConfig.backdropBlurSmall)
            .shadow(ThemeConfig.shadowSmall)
            .border({ width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusMedium })

            // 依赖关系管理
            if (this.localTask && this.displayDependencies.length > 0) {
              Column({ space: 8 }) {
                Text('依赖关系')
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.textSecondary)
                  .width('100%')
                
                ForEach(this.displayDependencies, (dep: TaskDependencyInfo) => {
                  Row({ space: 12 }) {
                    Column({ space: 4 }) {
                      if (dep.type === 'incoming') {
                        Text(`← 依赖于: ${dep.fromName}`)
                          .fontSize(ThemeConfig.fontSizeS)
                          .fontColor(ColorResource.textPrimary)
                      } else {
                        Text(`→ 被依赖: ${dep.toName}`)
                          .fontSize(ThemeConfig.fontSizeS)
                          .fontColor(ColorResource.textPrimary)
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    
                    Button() {
                      Text('×')
                        .fontSize(16)
                        .fontColor(ColorResource.errorColor)
                        .fontWeight(ThemeConfig.fontWeightBold)
                    }
                    .width(32)
                    .height(32)
                    .type(ButtonType.Circle)
                    .backgroundColor(ColorResource.errorLight)
                    .border({ width: 1, color: ColorResource.errorColor, radius: 16 })
                    .onClick(() => {
                      this.onDeleteDependency(dep.fromId, dep.toId);
                    })
                  }
                  .width('100%')
                  .padding({ left: ThemeConfig.spacingM, right: ThemeConfig.spacingM, top: ThemeConfig.spacingS, bottom: ThemeConfig.spacingS })
                  .backgroundColor(ColorResource.overlaySubtle)
                  .backdropBlur(ThemeConfig.backdropBlurSmall)
                  .borderRadius(ThemeConfig.radiusSmall)
                  .border({ width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusSmall })
                }, (dep: TaskDependencyInfo) => `${dep.fromId}-${dep.toId}`)
              }
              .width('100%')
              .key(`dependencies-${this.localTask?.id}-${this.forceUpdateKey}`)
            }
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor(ColorResource.overlaySubtle)
          .borderRadius(ThemeConfig.radiusXLarge)
          .backdropBlur(ThemeConfig.backdropBlurMedium)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusXLarge })

          // --- 底部操作按钮 - 苹果风格：更优雅的按钮设计 ---
          Column({ space: 12 }) {
            CommonButton({
              text: '创建依赖从此任务开始',
              type: 'primary',
              onButtonClick: () => {
                this.onStartConnecting()
              }
            })


            CommonButton({
              text: '返回列表',
              icon: '←',
              type: 'secondary',
              onButtonClick: () => {
                this.onBack()
              }
            })
          }
          .padding(20)
          .opacity(0)
          .height(0)
        }
        .padding(20) // 苹果风格：更大的外边距
        .opacity(this.editorOpacity)
        .translate({ x: 0, y: this.editorTranslateY })
        .animation({
          duration: ThemeConfig.animationNormal,
          curve: Curve.EaseInOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
      }
    }

}
