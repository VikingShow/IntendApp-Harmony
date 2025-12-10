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

import { TaskNode, ChecklistItem } from '../model/ProjectData';
import { CommonButton } from './CommonButton';
import { ValidationUtils } from '../utils/ValidationUtils';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { PromptAction } from '@kit.ArkUI';

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
   * 更新显示数据（日期和清单）
   */
  private updateDisplayData() {
    const task = this.localTask || this.task;
    if (task) {
      this.displayStartDate = task.startDate;
      this.displayEndDate = task.endDate;
      this.displayChecklist = task.checklist ? [...task.checklist] : [];
      console.log(`[TaskEditor] Updated display data: startDate=${task.startDate.toLocaleDateString()}, endDate=${task.endDate.toLocaleDateString()}, checklist=${this.displayChecklist.length} items`);
    }
  }

  /**
   * @Watch 回调：监听 task prop 变化
   */
  private onTaskChanged() {
    const currentTaskId = this.task?.id || null;
    const taskIdChanged = this.lastTaskId !== currentTaskId;
    
    console.log(`[TaskEditor] onTaskChanged: ${this.lastTaskId || 'null'} -> ${currentTaskId || 'null'}, changed: ${taskIdChanged}`);
    
    if (taskIdChanged && this.task) {
      // 任务ID变化，需要切换任务
      this.lastTaskId = currentTaskId;
      this.lastTaskDataHash = this.computeTaskDataHash(this.task);
      
      // 触发切换动画
      this.triggerTaskTransition(() => {
        this.localTask = this.task;
        this.forceUpdateKey++;
        this.dateTabIndex = 0;
        this.newChecklistItemText = '';
        // 更新显示数据
        this.updateDisplayData();
        console.log(`[TaskEditor] Task switched to: ${this.task?.name}, forceUpdateKey: ${this.forceUpdateKey}`);
      });
    } else if (this.task && !taskIdChanged) {
      // 同一任务，但对象引用或数据可能变化
      const currentTaskDataHash = this.computeTaskDataHash(this.task);
      if (this.lastTaskDataHash !== currentTaskDataHash) {
        console.log(`[TaskEditor] Task data updated for: ${this.task.name}`);
        this.lastTaskDataHash = currentTaskDataHash;
        this.localTask = this.task;
        this.forceUpdateKey++;
        // 更新显示数据
        this.updateDisplayData();
      }
    }
  }

  aboutToAppear() {
    // 初始化动画状态
    this.editorOpacity = 1;
    this.editorTranslateY = 0;
    const currentTaskId = this.task?.id || null;
    
    // 如果任务存在，初始化数据
    if (this.task) {
      console.log(`[TaskEditor] aboutToAppear: Initializing with task: ${currentTaskId}`);
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
    } else {
      // 任务不存在，直接设置
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

  aboutToUpdate() {
    const currentTaskId = this.task?.id || null;
    const currentTaskDataHash = this.computeTaskDataHash(this.task);
    const taskIdChanged = this.lastTaskId !== currentTaskId;
    const taskDataChanged = this.lastTaskDataHash !== currentTaskDataHash;
    const taskReferenceChanged = this.localTask !== this.task;
    
    // 情况1: 任务ID变化（切换到不同任务）
    if (taskIdChanged) {
      if (this.task) {
        console.log(`[TaskEditor] Task ID changed: ${this.lastTaskId || 'null'} -> ${currentTaskId}`);
        this.lastTaskId = currentTaskId;
        this.lastTaskDataHash = currentTaskDataHash;
        // 任务切换时触发动画
        this.triggerTaskTransition(() => {
          this.localTask = this.task;
          this.forceUpdateKey++;
          // 重置状态
          this.dateTabIndex = 0;
          this.newChecklistItemText = '';
        });
      } else {
        // 任务被清空
        console.log(`[TaskEditor] Task cleared`);
        this.lastTaskId = null;
        this.lastTaskDataHash = '';
        this.triggerTaskTransition(() => {
          this.localTask = null;
          this.forceUpdateKey++;
        });
      }
      return; // 任务ID变化时，不需要继续检查数据变化
    }
    
    // 情况2: 任务ID相同，但数据内容变化（数据更新）
    if (this.task && taskDataChanged) {
      console.log(`[TaskEditor] Task data changed (ID: ${this.task.id}), updating without animation`);
      this.lastTaskDataHash = currentTaskDataHash;
      // 数据更新时不触发动画，直接更新，提升响应速度
      this.localTask = this.task;
      this.forceUpdateKey++;
      // 注意：不重置dateTabIndex和newChecklistItemText，保持用户编辑状态
      return;
    }
    
    // 情况3: 任务ID相同，对象引用变化但数据未变化（可能是重新渲染）
    if (this.task && taskReferenceChanged && !taskDataChanged) {
      // 对象引用变化但数据相同，可能是父组件重新创建了对象
      // 直接更新引用，不触发动画和状态重置
      if (this.localTask?.id !== this.task.id) {
        // 如果localTask为空或ID不匹配，需要更新
        console.log(`[TaskEditor] Task reference changed but data same (ID: ${this.task.id}), updating reference`);
        this.localTask = this.task;
        this.forceUpdateKey++;
      }
      return;
    }
    
    // 情况4: localTask为空但task存在（初始化场景）
    if (this.task && !this.localTask) {
      console.log(`[TaskEditor] Initializing localTask with task: ${this.task.id}`);
      this.lastTaskId = currentTaskId;
      this.lastTaskDataHash = currentTaskDataHash;
      // 初始化时不触发动画
      this.localTask = this.task;
      this.forceUpdateKey++;
      this.dateTabIndex = 0;
      this.newChecklistItemText = '';
      return;
    }
    
    // 情况5: 没有变化，只更新跟踪变量
    if (this.task) {
      this.lastTaskId = currentTaskId;
      this.lastTaskDataHash = currentTaskDataHash;
    }
  }

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
      
      // 更新任务数据
      const newItem: ChecklistItem = {
        id: `item_${Date.now()}`,
        text: this.newChecklistItemText,
        isCompleted: false
      };
      
      if (this.localTask) {
        this.localTask.checklist = (this.localTask.checklist || []).concat([newItem]);
      }
      if (this.task) {
        this.task.checklist = (this.task.checklist || []).concat([newItem]);
      }
      
      // 更新显示清单
      this.displayChecklist = [...this.displayChecklist, newItem];
      
      // 更新数据哈希
      this.lastTaskDataHash = this.computeTaskDataHash(this.localTask || this.task);
      
      this.forceUpdateKey++;
      this.newChecklistItemText = '';
      
      // 然后通知父组件更新数据
      this.onAddChecklistItem(task.id, newItem.text);
    }
  }

  // 删除子任务
  private deleteChecklistItem(itemId: string) {
    const task = this.task || this.localTask;
    if (task && task.checklist) {
      console.log(`[TaskEditor] Deleting checklist item: ${itemId}`);
      
      // 更新任务数据
      const newChecklist = task.checklist.filter(item => item.id !== itemId);
      if (this.localTask) {
        this.localTask.checklist = newChecklist;
      }
      if (this.task) {
        this.task.checklist = newChecklist;
      }
      
      // 更新显示清单
      this.displayChecklist = this.displayChecklist.filter(item => item.id !== itemId);
      
      // 更新数据哈希
      this.lastTaskDataHash = this.computeTaskDataHash(this.localTask || this.task);
      
      this.forceUpdateKey++;
      
      // 然后通知父组件更新数据
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

  // 保存任务更改
  private saveTaskChanges() {
    if (this.localTask && this.hasUnsavedChanges) {
      console.log(`[TaskEditor] Auto-saving task: ${this.localTask.id}`);
      this.onUpdateTask(this.localTask.id, {
        name: this.localTask.name,
        startDate: this.localTask.startDate,
        endDate: this.localTask.endDate,
        checklist: this.localTask.checklist
      });
      this.hasUnsavedChanges = false;

      // 显示保存提示
      this.promptAction.showToast({
        message: '已自动保存',
        duration: 1000
      });

    }
  }

  build() {
    // 确保只有一个根节点 - 使用Column包裹条件渲染
    Column() {
      if (this.localTask || this.task) {
        this.buildTaskEditor(this.localTask || this.task!)
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
  buildTaskEditor(displayTask: TaskNode) {
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
              TextInput({ text: displayTask.name || '', placeholder: '请输入任务名称' })
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
                  if (displayTask) {
                    this.onUpdateTask(displayTask.id, { name: displayTask.name });
                  }
                })
                .enterKeyType(EnterKeyType.Done)
                .onSubmit(() => {
                  // 提交时保存并聚焦到下一个输入框
                  if (displayTask) {
                    this.onUpdateTask(displayTask.id, { name: displayTask.name });
                  }
                })
                .onChange((value: string) => {
                  if (displayTask) {
                    // 验证任务名称
                    const validation = ValidationUtils.validateProjectName(value);
                    if (!validation.isValid) {
                      this.promptAction.showToast({ message: validation.message });
                      return;
                    }

                    // 更新任务名称（同时更新localTask和task）
                    if (this.localTask) {
                      this.localTask.name = value;
                    }
                    if (this.task) {
                      this.task.name = value;
                    }
                    
                    // 更新数据哈希，确保aboutToUpdate能检测到变化
                    this.lastTaskDataHash = this.computeTaskDataHash(this.localTask || this.task);
                    
                    // 触发UI更新
                    this.forceUpdateKey++;
                    
                    // 触发自动保存
                    this.scheduleAutoSave();
                  }
                })
            }

             // 日期选择区域 - 使用自定义Tab切换（苹果风格）
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
                   end: new Date('2030-12-31'),
                   selected: this.displayStartDate
                 })
                   .backgroundColor(ColorResource.transparent)
                   .borderRadius(12)
                   .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                   .border({ width: 0, radius: 12 })
                   .width('100%')
                  .onDateChange((value: Date) => {
                    if (displayTask) {
                      const newStartDate = value;
                      const newEndDate = this.displayEndDate < newStartDate ? newStartDate : this.displayEndDate;
                      
                      // 更新显示数据
                      this.displayStartDate = newStartDate;
                      this.displayEndDate = newEndDate;
                      
                      // 更新任务数据
                      if (this.localTask) {
                        this.localTask.startDate = newStartDate;
                        this.localTask.endDate = newEndDate;
                      }
                      if (this.task) {
                        this.task.startDate = newStartDate;
                        this.task.endDate = newEndDate;
                      }
                      
                      // 更新数据哈希
                      this.lastTaskDataHash = this.computeTaskDataHash(this.localTask || this.task);
                      
                      this.forceUpdateKey++;
                      this.hasUnsavedChanges = true;
                      this.scheduleAutoSave();
                      
                      // 只传递需要更新的字段
                      this.onUpdateTask(displayTask.id, { 
                        startDate: newStartDate,
                        endDate: newEndDate
                      });
                    }
                  })
               } else {
                 DatePicker({
                   start: new Date('2020-01-01'),
                   end: new Date('2030-12-31'),
                   selected: this.displayEndDate
                 })
                   .backgroundColor(ColorResource.transparent)
                   .borderRadius(12)
                   .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                   .border({ width: 0, radius: 12 })
                   .width('100%')
                  .onDateChange((value: Date) => {
                    if (displayTask) {
                      const newEndDate = value;
                      const newStartDate = this.displayStartDate > newEndDate ? newEndDate : this.displayStartDate;
                      
                      // 更新显示数据
                      this.displayStartDate = newStartDate;
                      this.displayEndDate = newEndDate;
                      
                      // 更新任务数据
                      if (this.localTask) {
                        this.localTask.startDate = newStartDate;
                        this.localTask.endDate = newEndDate;
                      }
                      if (this.task) {
                        this.task.startDate = newStartDate;
                        this.task.endDate = newEndDate;
                      }
                      
                      // 更新数据哈希
                      this.lastTaskDataHash = this.computeTaskDataHash(this.localTask || this.task);
                      
                      this.forceUpdateKey++;
                      this.hasUnsavedChanges = true;
                      this.scheduleAutoSave();
                      
                      // 只传递需要更新的字段
                      this.onUpdateTask(displayTask.id, { 
                        startDate: newStartDate,
                        endDate: newEndDate
                      });
                    }
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
              if (displayTask) {
                CommonButton({
                  text: '添加日历提醒',
                  type: 'secondary',
                  buttonSize: 'small',
                  onButtonClick: () => {
                    this.onAddReminder(displayTask);
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
                ForEach(this.displayChecklist, (item: ChecklistItem) => {
                  Row({ space: 12 }) {
                    Checkbox({ name: item.id, group: 'checklist' })
                      .select(item.isCompleted)
                      .onChange((value: boolean) => {
                        if (displayTask) {
                          console.log(`[TaskEditor] Checkbox changed for item ${item.id}: ${value}`);
                          
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
                          
                          // 更新任务数据
                          if (this.localTask) {
                            this.localTask.checklist = newChecklist;
                          }
                          if (this.task) {
                            this.task.checklist = newChecklist;
                          }
                          
                          // 更新数据哈希
                          this.lastTaskDataHash = this.computeTaskDataHash(this.localTask || this.task);
                          
                          this.forceUpdateKey++;
                          
                          // 然后通知父组件更新数据
                          this.onUpdateChecklist(displayTask.id, newChecklist);
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
                }, (item: ChecklistItem) => item.id)
              }
              .key(`checklist-${displayTask.id}-${this.forceUpdateKey}`)
            }
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor(ColorResource.transparent)
          .borderRadius(ThemeConfig.radiusXLarge)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusXLarge })

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
