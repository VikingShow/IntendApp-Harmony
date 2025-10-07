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
import { ThemeConfig } from '../utils/ThemeConfig';
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
  @Prop task: TaskNode | null;
  @State newChecklistItemText: string = '';
  @State private localTask: TaskNode | null = null;
  @State private forceUpdateKey: number = 0;
  @State private autoSaveTimer: number | null = null;
  @State private hasUnsavedChanges: boolean = false;
  @State private debounceTimer: number | null = null;
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

  aboutToAppear() {
    this.localTask = this.task;
  }

  aboutToDisappear() {
    // 组件销毁时保存未保存的更改
    if (this.hasUnsavedChanges && this.localTask) {
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
    // 当task变化时，更新localTask
    if (this.localTask?.id !== this.task?.id) {
      console.log(`[TaskEditor] Task changed, updating localTask`);
      this.localTask = this.task;
    } else if (this.task && this.localTask) {
      // 如果ID相同但内容可能不同，同步更新内容
      const oldChecklistLength = this.localTask.checklist?.length || 0;
      const newChecklistLength = this.task.checklist?.length || 0;
      
      // 检查checklist长度变化
      if (oldChecklistLength !== newChecklistLength) {
        console.log(`[TaskEditor] Checklist length updated: ${oldChecklistLength} -> ${newChecklistLength}`);
        this.forceUpdateKey++;
      }
      
      // 检查checklist内容变化（勾选状态等）
      if (this.localTask.checklist && this.task.checklist && 
          this.localTask.checklist.length === this.task.checklist.length) {
        const hasContentChange = this.localTask.checklist.some((oldItem, index) => {
          const newItem = this.task!.checklist[index];
          return !newItem || oldItem.isCompleted !== newItem.isCompleted || oldItem.text !== newItem.text;
        });
        
        if (hasContentChange) {
          console.log(`[TaskEditor] Checklist content updated`);
          this.forceUpdateKey++;
        }
      }
      
      // 强制更新localTask以触发响应式更新
      this.localTask = this.task;
    }
  }

  private getDuration(): number {
    if (!this.localTask) return 0;
    const diffTime = this.localTask.endDate.getTime() - this.localTask.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  // 封装一个统一的添加函数
  private submitNewChecklistItem() {
    if (this.localTask && this.newChecklistItemText.trim() !== '') {
      // 验证清单项
      const validation = ValidationUtils.validateChecklistItem(this.newChecklistItemText);
      if (!validation.isValid) {
        this.promptAction.showToast({ message: validation.message });
        return;
      }

      console.log(`[TaskEditor] Adding new checklist item: ${this.newChecklistItemText}`);
      
      // 先更新localTask以立即反映UI变化
      const newItem: ChecklistItem = {
        id: `item_${Date.now()}`,
        text: this.newChecklistItemText,
        isCompleted: false
      };
      
      this.localTask.checklist = this.localTask.checklist.concat([newItem]);
      this.forceUpdateKey++;
      this.newChecklistItemText = '';
      
      // 然后通知父组件更新数据
      this.onAddChecklistItem(this.localTask.id, newItem.text);
    }
  }

  // 删除子任务
  private deleteChecklistItem(itemId: string) {
    if (this.localTask && this.localTask.checklist) {
      console.log(`[TaskEditor] Deleting checklist item: ${itemId}`);
      
      // 先更新localTask以立即反映UI变化
      const newChecklist = this.localTask.checklist.filter(item => item.id !== itemId);
      this.localTask.checklist = newChecklist;
      this.forceUpdateKey++;
      
      // 然后通知父组件更新数据
      this.onDeleteChecklistItem(this.localTask.id, itemId);
      
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
    // 使用localTask来确保响应式更新
    if (this.localTask) {
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 16 }) {
            Row({ space: 12 }) {
              Text('编辑任务')
                 .fontSize(ThemeConfig.fontSizeXXL)
                 .fontWeight(ThemeConfig.fontWeightMedium)
                 .fontColor(ThemeConfig.gray800)
                 .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Column({ space: 8 }) {
              Text('任务名称')
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(ThemeConfig.fontWeightMedium)
                .fontColor(ThemeConfig.gray500)
              TextInput({ text: this.localTask.name || '', placeholder: '请输入任务名称' })
                .backgroundColor('#00000000')
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                .fontSize(ThemeConfig.fontSizeL)
                .width('100%')
                .fontColor(ThemeConfig.gray800)
                .placeholderColor(ThemeConfig.gray500)
                .shadow(ThemeConfig.inputShadow)
                .border({ 
                  width: 2, 
                  color: ThemeConfig.gray200, 
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
                  if (this.localTask) {
                    // 验证任务名称
                    const validation = ValidationUtils.validateProjectName(value);
                    if (!validation.isValid) {
                      this.promptAction.showToast({ message: validation.message });
                      return;
                    }

                    // 更新本地任务名称
                    this.localTask.name = value;
                    
                    // 触发自动保存
                    this.scheduleAutoSave();
                  }
                })
            }

             // 日期选择区域
             Column({ space: 12 }) {
               // 开始日期 - 独占一行，确保有足够宽度
               Column({ space: 8 }) {
                 Text('开始日期')
                   .fontSize(13)
                   .fontWeight(FontWeight.Medium)
                   .fontColor('#86868B')
                 DatePicker({
                   start: new Date('2020-01-01'),
                   end: new Date('2030-12-31'),
                   selected: this.localTask.startDate || new Date()
                 })
                   .backgroundColor('#00000000')
                   .borderRadius(12)
                   .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                   .border({ width: 0, radius: 12 })
                   .width('100%')
                   .onDateChange((value: Date) => {
                     if (this.localTask) {
                       const newStartDate = value;
                       const newEndDate = this.localTask.endDate < newStartDate ? newStartDate : this.localTask.endDate;
                       
                       // 只传递需要更新的字段
                       this.onUpdateTask(this.localTask.id, { 
                         startDate: newStartDate,
                         endDate: newEndDate
                       });
                     }
                   })
               }

               // 结束日期 - 独占一行，确保有足够宽度
               Column({ space: 8 }) {
                 Text('结束日期')
                   .fontSize(13)
                   .fontWeight(FontWeight.Medium)
                   .fontColor('#86868B')
                 DatePicker({
                   start: new Date('2020-01-01'),
                   end: new Date('2030-12-31'),
                   selected: this.localTask.endDate || new Date()
                 })
                   .backgroundColor('#00000000')
                   .borderRadius(12)
                   .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                   .border({ width: 0, radius: 12 })
                   .width('100%')
                   .onDateChange((value: Date) => {
                     if (this.localTask) {
                       const newEndDate = value;
                       const newStartDate = this.localTask.startDate > newEndDate ? newEndDate : this.localTask.startDate;
                       
                       // 只传递需要更新的字段
                       this.onUpdateTask(this.localTask.id, { 
                         startDate: newStartDate,
                         endDate: newEndDate
                       });
                     }
                   })
               }
             }

            // 工期显示
            Row({ space: 8 }) {
              Text(`工期: ${this.getDuration()} 天`)
                .fontSize(13)
                .fontColor('#86868B')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor('#00000000')
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
                 .fontColor('#1D1D1F')
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
                .backgroundColor('#00000000')
                .borderRadius(ThemeConfig.radiusMedium)
                .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(ThemeConfig.gray800)
                .placeholderColor(ThemeConfig.gray500)
                .shadow(ThemeConfig.inputShadow)
                .border({ 
                  width: 2, 
                  color: ThemeConfig.gray200, 
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
                  .fontSize(ThemeConfig.fontSizeXL)
                  .fontColor(Color.White)
                  .fontWeight(ThemeConfig.fontWeightBold)
                  .shadow({ radius: 1, color: '#00000030', offsetX: 0, offsetY: 1 })
              }
              .width(52)
              .height(52)
              .backgroundColor(ThemeConfig.primaryColor)
              .borderRadius(ThemeConfig.radiusMedium)
              .shadow(ThemeConfig.buttonShadow)
              .border({ width: 2, color: ThemeConfig.primaryUltraLight, radius: ThemeConfig.radiusMedium })
              .onClick(() => {
                this.submitNewChecklistItem();
              })
            }

            // 子任务列表 
            if (!this.localTask || !this.localTask.checklist || this.localTask.checklist.length === 0) {
              Column({ space: 12 }) {
                Image($r('app.media.ic_empty_box'))
                  .width(32)
                  .height(32)
                  .opacity(0.4)
                Text('暂无子任务')
                  .fontSize(14)
                  .fontColor('#86868B')
              }
              .width('100%')
              .padding(24)
              .justifyContent(FlexAlign.Center)
              .key(`empty-checklist-${this.forceUpdateKey}`)
            } else if (this.localTask && this.localTask.checklist) {
              Column({ space: 8 }) {
                ForEach(this.localTask.checklist, (item: ChecklistItem) => {
                  Row({ space: 12 }) {
                    Checkbox({ name: item.id, group: 'checklist' })
                      .select(item.isCompleted)
                      .onChange((value: boolean) => {
                        if (this.localTask && this.localTask.checklist) {
                          console.log(`[TaskEditor] Checkbox changed for item ${item.id}: ${value}`);
                          
                          const newChecklist = this.localTask.checklist.map(i => {
                            if (i.id === item.id) {
                              return {
                                id: i.id,
                                text: i.text,
                                isCompleted: value
                              };
                            }
                            return i;
                          });
                          
                          // 先更新localTask以立即反映UI变化
                          this.localTask.checklist = newChecklist;
                          this.forceUpdateKey++;
                          
                          // 然后通知父组件更新数据
                          this.onUpdateChecklist(this.localTask.id, newChecklist);
                        }
                      })
                    Text(item.text)
                      .fontSize(15)
                      .fontColor(item.isCompleted ? '#86868B' : '#1D1D1F')
                      .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
                      .layoutWeight(1)
                      .textAlign(TextAlign.Start)
                    
                    // 删除按钮 - 现代化设计，增强交互反馈
                    Button() {
                      Text('×')
                        .fontSize(16)
                        .fontColor(ThemeConfig.errorColor)
                        .fontWeight(ThemeConfig.fontWeightBold)
                    }
                    .width(40)
                    .height(40)
                    .type(ButtonType.Circle)
                    .backgroundColor(ThemeConfig.errorLight)
                    .border({ width: 2, color: ThemeConfig.errorColor, radius: 20 })
                    .shadow(ThemeConfig.shadowSmall)
                    .onClick(() => {
                      this.deleteChecklistItem(item.id);
                    })
                  }
                  .width('100%')
                  .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingM })
                  .backgroundColor(item.isCompleted ? ThemeConfig.gray100 : '#00000000')
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
              .key(`checklist-${this.localTask?.id}-${this.forceUpdateKey}`)
            }
          }
          .padding(ThemeConfig.spacingXL)
          .backgroundColor('#00000000')
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
        }
        .padding(20) // 苹果风格：更大的外边距
      }
    }
  }
}