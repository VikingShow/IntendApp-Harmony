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
import { NodeSchema, TaskNodeWithSchema } from '../model/NodeSchema';
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

/**
 * 任务更新载荷类型
 * 在原有 TaskNode 基础上扩展 schema 相关字段
 */
interface TaskUpdatePayload extends Partial<TaskNode> {
  typeId?: string;
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
  @State private forceUpdateKey: number = 0;
  @State private autoSaveTimer: number | null = null;
  @State private hasUnsavedChanges: boolean = false;
  @State private debounceTimer: number | null = null;
  @State private dateTabIndex: number = 0; // 日期Tab索引：0-开始日期，1-结束日期
  @State private displayStartDate: Date = new Date(); // 用于DatePicker绑定的开始日期
  @State private displayEndDate: Date = new Date(); // 用于DatePicker绑定的结束日期
  @State private displayChecklist: ChecklistItem[] = []; // 用于清单显示的数据
  @State private displayDependencies: TaskDependencyInfo[] = []; // 用于依赖关系显示的数据
  // 任务切换动画相关状态
  @State private editorOpacity: number = 1; // 编辑器透明度
  @State private editorTranslateY: number = 0; // 编辑器垂直位移
  @State private isTransitioning: boolean = false; // 是否正在切换任务
  private lastTaskId: string | null = null; // 跟踪上次的任务ID
  private lastTaskDataHash: string = ''; // 跟踪任务数据的内容哈希，用于检测数据变化
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
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
    return `${task.id}|${task.name}|${task.startDate.getTime()}|${task.endDate.getTime()}|${checklistHash}`;
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

    taskWithSchema.typeId = typeId;
    this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
    this.forceUpdateKey++;

    // 通过 onUpdateTask 通知父组件，扩展更新载荷类型以兼容 typeId
    const updates: TaskUpdatePayload = { typeId: typeId };
    this.onUpdateTask(this.localTask.id, updates);
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
      this.forceUpdateKey++;
      this.updateDisplayData();
    } else if (!this.task) {
      // 任务被清空
      this.lastTaskId = null;
      this.lastTaskDataHash = '';
      this.localTask = null;
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

  private getDuration(): number {
    const task = this.localTask || this.task;
    if (!task) return 0;
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  // 封装一个统一的添加函数
  private submitNewChecklistItem() {
    const task = this.task || this.localTask;
    if (task && this.newChecklistItemText.trim() !== '') {
      // 验证清单项
      const validation = ValidationUtils.validateChecklistItem(this.newChecklistItemText);
      if (!validation.isValid) {
        this.promptAction.showToast({ message: validation.message });
        return;
      }

      console.log(`[TaskEditor] Adding new checklist item: ${this.newChecklistItemText}`);
      
      // 创建新的清单项
      const newItem: ChecklistItem = {
        id: `item_${Date.now()}`,
        text: this.newChecklistItemText,
        isCompleted: false
      };
      
      // 只更新 localTask 用于本地显示（不修改 @Prop task）
      if (this.localTask) {
        this.localTask.checklist = (this.localTask.checklist || []).concat([newItem]);
      }
      
      // 更新显示清单
      this.displayChecklist = [...this.displayChecklist, newItem];
      
      // 更新数据哈希
      this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
      
      this.forceUpdateKey++;
      this.newChecklistItemText = '';
      
      // 立即通知父组件更新数据（让数据从父组件流回来）
      this.onAddChecklistItem(task.id, newItem.text);
    }
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
              Text('←')
                .fontSize(ThemeConfig.fontSizeXL)
                .fontColor(ColorResource.surfaceBold)
                .fontWeight(ThemeConfig.fontWeightBold)
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

            // 创建依赖按钮（从当前任务开始）
            Button({ type: ButtonType.Circle }) {
              Text('链')
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(Color.White)
                .fontWeight(ThemeConfig.fontWeightBold)
            }
            .width(52)
            .height(52)
            .backgroundColor(ColorResource.primaryColor)
            .borderRadius(26)
            .shadow(ThemeConfig.shadowMedium)
            .border({ width: 2, color: ColorResource.primaryUltraLight, radius: 26 })
            .margin({ left: 12 })
            .onClick(() => {
              this.onStartConnecting();
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

            Column({ space: 8 }) {
              Text('任务名称')
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(ThemeConfig.fontWeightMedium)
                .fontColor(ColorResource.surfaceEmphasized)
              TextInput({ text: this.localTask?.name || '', placeholder: '请输入任务名称' })
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
                .onFocus(() => {
                  // 聚焦时的视觉反馈
                  console.log('[TaskEditor] Task name input focused');
                })
                .onBlur(() => {
                  // 失焦时保存数据
                  if (this.localTask) {
                    this.onUpdateTask(this.localTask.id, { name: this.localTask.name });
                  }
                })
                .enterKeyType(EnterKeyType.Done)
                .onSubmit(() => {
                  // 提交时保存并聚焦到下一个输入框
                  if (this.localTask) {
                    this.onUpdateTask(this.localTask.id, { name: this.localTask.name });
                  }
                })
                .onChange((value: string) => {
                  // 验证任务名称
                  const validation = ValidationUtils.validateProjectName(value);
                  if (!validation.isValid) {
                    this.promptAction.showToast({ message: validation.message });
                    return;
                  }

                  // 只更新 localTask 用于本地显示（不修改 @Prop task）
                  if (this.localTask) {
                    this.localTask.name = value;
                    
                    // 更新数据哈希
                    this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
                    
                    // 触发UI更新
                    this.forceUpdateKey++;
                    
                    // 立即通知父组件更新数据（使用 this.localTask.id 而不是闭包中的 displayTask.id）
                    this.onUpdateTask(this.localTask.id, { name: value });
                  }
                })
            }

             // 日期选择区域 - 使用自定义Tab切换（苹果风格）
             // 节点类型选择
             Column({ space: 8 }) {
               Text('节点类型')
                 .fontSize(ThemeConfig.fontSizeS)
                 .fontWeight(ThemeConfig.fontWeightMedium)
                 .fontColor(ColorResource.surfaceEmphasized)
               Row({ space: 8 }) {
                 ForEach(this.getAvailableNodeSchemas(), (schema: NodeSchema) => {
                   Text(schema.name)
                     .fontSize(ThemeConfig.fontSizeS)
                     .fontWeight(schema.id === this.getCurrentNodeTypeId() ? ThemeConfig.fontWeightMedium : FontWeight.Normal)
                     .fontColor(schema.id === this.getCurrentNodeTypeId() ? ColorResource.primaryColor : ColorResource.textSecondary)
                     .padding({
                       left: ThemeConfig.spacingM,
                       right: ThemeConfig.spacingM,
                       top: ThemeConfig.spacingXS,
                       bottom: ThemeConfig.spacingXS
                     })
                     .backgroundColor(schema.id === this.getCurrentNodeTypeId() ? ColorResource.primaryUltraLight : ColorResource.surfaceLight)
                     .borderRadius(ThemeConfig.radiusMedium)
                     .border({
                       width: 1,
                       color: schema.id === this.getCurrentNodeTypeId() ? ColorResource.primaryColor : ColorResource.surfaceNeutral,
                       radius: ThemeConfig.radiusMedium
                     })
                     .onClick(() => {
                       this.onNodeTypeSelected(schema.id);
                     })
                  }, (schema: NodeSchema, index: number) => `task-editor-node-schema-${schema.id}-${index}`)
                }
              }

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
                   end: this.displayEndDate, // 限制开始日期不能晚于结束日期
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
                    
                    // 更新显示数据
                    this.displayStartDate = newStartDate;
                    
                    // 更新 localTask
                    this.localTask.startDate = newStartDate;
                    this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
                    this.forceUpdateKey++;
                    
                    // 通知父组件
                    this.onUpdateTask(this.localTask.id, { 
                      startDate: newStartDate
                    });
                  })
               } else {
                 DatePicker({
                   start: this.displayStartDate, // 限制结束日期不能早于开始日期
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
                    
                    // 更新显示数据
                    this.displayEndDate = newEndDate;
                    
                    // 更新 localTask
                    this.localTask.endDate = newEndDate;
                    this.lastTaskDataHash = this.computeTaskDataHash(this.localTask);
                    this.forceUpdateKey++;
                    
                    // 通知父组件
                    this.onUpdateTask(this.localTask.id, { 
                      endDate: newEndDate
                    });
                  })
               }
             }
             .width('100%')

            // 工期显示与日历提醒
            Row({ space: 8 }) {
              Text(`工期: ${this.getDuration()} 天`)
                .fontSize(13)
                .fontColor(ColorResource.textTertiary)
                .fontWeight(FontWeight.Medium)
              if (this.localTask) {
                CommonButton({
                  text: '添加日历提醒',
                  type: 'secondary',
                  buttonSize: 'small',
                  onButtonClick: () => {
                    this.onAddReminder(this.localTask!);
                  }
                })
                  .width(140)
              }
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
                  .onSubmit(() => {
                    this.submitNewChecklistItem();
                  })
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
