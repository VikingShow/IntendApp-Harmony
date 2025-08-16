// File: entry/src/main/ets/components/TaskEditor.ets

import { TaskNode, ChecklistItem } from '../model/ProjectData';
import { CommonButton } from './CommonButton';
import { ValidationUtils } from '../utils/ValidationUtils';
import promptAction from '@ohos.promptAction';

@Component
export struct TaskEditor {
  @Prop task: TaskNode | null;
  @State newChecklistItemText: string = '';
  @State private localTask: TaskNode | null = null;
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

  aboutToAppear() {
    this.localTask = this.task;
  }

  aboutToUpdate() {
    // 当task变化时，更新localTask
    if (this.localTask?.id !== this.task?.id) {
      this.localTask = this.task;
    } else if (this.task && this.localTask) {
      // 如果ID相同但内容可能不同，同步更新内容
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
        promptAction.showToast({ message: validation.message });
        return;
      }

      this.onAddChecklistItem(this.localTask.id, this.newChecklistItemText);
      this.newChecklistItemText = '';
    }
  }

  build() {
    // 使用localTask来确保响应式更新
    if (this.localTask) {
      // 苹果风格：使用更大的间距和更优雅的布局
      Scroll() {
        Column({ space: 20 }) {
          // --- 头部信息卡片 - 苹果风格：更大的圆角、更精致的阴影 ---
          Column({ space: 16 }) {
            // 标题区域 - 苹果风格：更优雅的字体权重和颜色
            Row({ space: 12 }) {
                             Text('编辑任务')
                 .fontSize(20)
                 .fontWeight(FontWeight.Medium)
                 .fontColor('#1D1D1F') // 苹果深色文字
                 .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 任务名称输入 - 苹果风格：更精致的输入框设计
            Column({ space: 8 }) {
              Text('任务名称')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#86868B') // 苹果次要文字颜色
              TextInput({ text: this.localTask.name || '' })
                .backgroundColor('#F5F5F7') // 苹果浅灰背景
                .borderRadius(12) // 苹果风格圆角
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .fontSize(16)
                .width('100%')
                .fontColor('#1D1D1F')
                .placeholderColor('#86868B')
                .onChange((value: string) => {
                  if (this.localTask) {
                    // 验证任务名称
                    const validation = ValidationUtils.validateProjectName(value);
                    if (!validation.isValid) {
                      promptAction.showToast({ message: validation.message });
                      return;
                    }

                    // 只传递需要更新的字段，而不是整个TaskNode对象
                    this.onUpdateTask(this.localTask.id, { name: value });
                  }
                })
            }

                         // 日期选择区域 - 苹果风格：更优雅的日期选择器，优化宽度显示
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
                   .backgroundColor('#F5F5F7')
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
                   .backgroundColor('#F5F5F7')
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

            // 工期显示 - 苹果风格：更优雅的信息展示
            Row({ space: 8 }) {
              Text(`工期: ${this.getDuration()} 天`)
                .fontSize(13)
                .fontColor('#86868B')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
          .padding(20) // 苹果风格：更大的内边距
          .backgroundColor('#FFFFFF')
          .borderRadius(16) // 苹果风格：更大的圆角
          .shadow({
            radius: 20,
            color: '#00000008', // 苹果风格：更柔和的阴影
            offsetX: 0,
            offsetY: 4
          })

          // --- 任务清单卡片 - 苹果风格：更精致的清单设计 ---
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

            // 添加新子任务 - 苹果风格：更优雅的输入设计
            Row({ space: 12 }) {
              TextInput({ 
                placeholder: '添加一个子任务...', 
                text: this.newChecklistItemText 
              })
                .layoutWeight(1)
                .backgroundColor('#F5F5F7')
                .borderRadius(12)
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .fontSize(15)
                .fontColor('#1D1D1F')
                .placeholderColor('#86868B')
                .onChange((value: string) => {
                  this.newChecklistItemText = value;
                })
                .onSubmit(() => {
                  this.submitNewChecklistItem();
                })
              Button() {
                                 Text('+')
                   .fontSize(18)
                   .fontColor(Color.White)
                   .fontWeight(FontWeight.Medium)
              }
              .width(44) // 苹果风格：更大的按钮尺寸
              .height(44)
              .backgroundColor('#007AFF') // 苹果蓝色
              .borderRadius(12)
              .shadow({
                radius: 8,
                color: '#007AFF30',
                offsetX: 0,
                offsetY: 2
              })
              .onClick(() => {
                this.submitNewChecklistItem();
              })
            }

            // 子任务列表 - 苹果风格：更精致的列表项设计
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
            } else if (this.localTask && this.localTask.checklist) {
              Column({ space: 8 }) {
                ForEach(this.localTask.checklist, (item: ChecklistItem) => {
                  Row({ space: 12 }) {
                    Checkbox({ name: item.id, group: 'checklist' })
                      .select(item.isCompleted)
                      .onChange((value: boolean) => {
                        if (this.localTask && this.localTask.checklist) {
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
                          this.onUpdateChecklist(this.localTask.id, newChecklist);
                        }
                      })
                    Text(item.text)
                      .fontSize(15)
                      .fontColor(item.isCompleted ? '#86868B' : '#1D1D1F')
                      .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
                      .layoutWeight(1)
                      .textAlign(TextAlign.Start)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                  .backgroundColor(item.isCompleted ? '#F5F5F7' : '#FFFFFF')
                  .borderRadius(12)
                  .border({ 
                    width: 1, 
                    color: item.isCompleted ? '#E5E5E7' : '#E5E5E7', 
                    radius: 12 
                  })
                }, (item: ChecklistItem) => item.id)
              }
            }
          }
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 20,
            color: '#00000008',
            offsetX: 0,
            offsetY: 4
          })

          // --- 底部操作按钮 - 苹果风格：更优雅的按钮设计 ---
          Column({ space: 12 }) {
            CommonButton({
              text: '创建依赖从此任务开始',
              icon: '🔗',
              type: 'primary',
              onButtonClick: () => {
                this.onStartConnecting()
              }
            })

            CommonButton({
              text: '删除此任务',
              icon: '🗑️',
              type: 'danger',
              onButtonClick: () => {
                if (this.localTask) {
                  // 添加删除确认对话框
                  AlertDialog.show({
                    title: '确认删除任务',
                    message: `确定要删除任务"${this.localTask.name}"吗？删除后无法恢复。`,
                    primaryButton: {
                      value: '取消',
                      action: () => {
                        // 取消删除
                      }
                    },
                    secondaryButton: {
                      value: '删除',
                      fontColor: '#FF3B30', // 苹果红色
                      action: () => {
                        if (this.localTask) {
                          this.onDeleteTask(this.localTask.id);
                        }
                      }
                    }
                  });
                }
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