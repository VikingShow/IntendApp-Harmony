// File: entry/src/main/ets/components/TaskEditor.ets

import { TaskNode, ChecklistItem } from '../model/ProjectData';
import { CommonButton } from './CommonButton';
import { ValidationUtils } from '../utils/ValidationUtils';
import promptAction from '@ohos.promptAction';

@Component
export struct TaskEditor {
  task: TaskNode | null = null;

  @State newChecklistItemText: string = '';

  onUpdateTask: (task: TaskNode) => void = () => {};
  onDeleteTask: (id: string) => void = () => {};
  onBack: () => void = () => {};
  onStartConnecting: () => void = () => {};
  onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => void = () => {};
  onAddChecklistItem: (taskId: string, text: string) => void = () => {};

  private getDuration(): number {
    if (!this.task) return 0;
    const diffTime = this.task.endDate.getTime() - this.task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  // 封装一个统一的添加函数
  private submitNewChecklistItem() {
    if (this.task && this.newChecklistItemText.trim() !== '') {
      // 验证清单项
      const validation = ValidationUtils.validateChecklistItem(this.newChecklistItemText);
      if (!validation.isValid) {
        promptAction.showToast({ message: validation.message });
        return;
      }
      
      this.onAddChecklistItem(this.task.id, this.newChecklistItemText);
      this.newChecklistItemText = '';
    }
  }

  build() {
    if (this.task) {
      // FIX: 将根布局改为Scroll，以确保整个编辑器在内容溢出时可以滚动
      Scroll() {
        Column({ space: 20 }) {
          // --- 头部信息卡片 ---
          Column({ space: 16 }) {
            // 标题区域
            Row({ space: 12 }) {
              Text('📝')
                .fontSize(24)
                .fontColor('#007DFF')
              Text('编辑任务')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F2937')
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 任务名称输入
            Column({ space: 8 }) {
              Text('任务名称')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#374151')
              TextInput({ text: this.task?.name || '' })
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .padding(12)
                .fontSize(16)
                .onChange((value: string) => {
                  if (this.task) {
                    // 验证任务名称
                    const validation = ValidationUtils.validateProjectName(value);
                    if (!validation.isValid) {
                      promptAction.showToast({ message: validation.message });
                      return;
                    }
                    
                    const updatedTask: TaskNode = {
                      id: this.task.id,
                      name: value,
                      startDate: this.task.startDate,
                      endDate: this.task.endDate,
                      checklist: this.task.checklist,
                      x: this.task.x,
                      y: this.task.y,
                      isCritical: this.task.isCritical,
                      earlyStart: this.task.earlyStart,
                      earlyFinish: this.task.earlyFinish,
                      lateStart: this.task.lateStart,
                      lateFinish: this.task.lateFinish
                    };
                    this.onUpdateTask(updatedTask);
                  }
                })
            }

            // 日期选择区域
            Row({ space: 12 }) {
              Column({ space: 8 }) {
                Text('开始日期')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#374151')
                DatePicker({
                  start: new Date('2020-01-01'),
                  end: new Date('2030-12-31'),
                  selected: this.task?.startDate || new Date()
                })
                  .backgroundColor('#F9FAFB')
                  .borderRadius(8)
                  .padding(12)
                  .border({ width: 1, color: '#E5E7EB', radius: 8 })
                  .onDateChange((value: Date) => {
                    if (this.task) {
                      const newStartDate = value;
                      const newEndDate = this.task.endDate < newStartDate ? newStartDate : this.task.endDate;
                      const updatedTask: TaskNode = {
                        id: this.task.id,
                        name: this.task.name,
                        startDate: newStartDate,
                        endDate: newEndDate,
                        checklist: this.task.checklist,
                        x: this.task.x,
                        y: this.task.y,
                        isCritical: this.task.isCritical,
                        earlyStart: this.task.earlyStart,
                        earlyFinish: this.task.earlyFinish,
                        lateStart: this.task.lateStart,
                        lateFinish: this.task.lateFinish
                      };
                      this.onUpdateTask(updatedTask);
                    }
                  })
              }.layoutWeight(1)

              Column({ space: 8 }) {
                Text('结束日期')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#374151')
                DatePicker({
                  start: new Date('2020-01-01'),
                  end: new Date('2030-12-31'),
                  selected: this.task?.endDate || new Date()
                })
                  .backgroundColor('#F9FAFB')
                  .borderRadius(8)
                  .padding(12)
                  .border({ width: 1, color: '#E5E7EB', radius: 8 })
                  .onDateChange((value: Date) => {
                    if (this.task) {
                      const newEndDate = value;
                      const newStartDate = this.task.startDate > newEndDate ? newEndDate : this.task.startDate;
                      const updatedTask: TaskNode = {
                        id: this.task.id,
                        name: this.task.name,
                        startDate: newStartDate,
                        endDate: newEndDate,
                        checklist: this.task.checklist,
                        x: this.task.x,
                        y: this.task.y,
                        isCritical: this.task.isCritical,
                        earlyStart: this.task.earlyStart,
                        earlyFinish: this.task.earlyFinish,
                        lateStart: this.task.lateStart,
                        lateFinish: this.task.lateFinish
                      };
                      this.onUpdateTask(updatedTask);
                    }
                  })
              }.layoutWeight(1)
            }

            // 工期显示
            Row({ space: 8 }) {
              Text('⏱️')
                .fontSize(16)
                .fontColor('#6B7280')
              Text(`工期: ${this.getDuration()} 天`)
                .fontSize(14)
                .fontColor('#6B7280')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

          // --- 任务清单卡片 ---
          Column({ space: 16 }) {
            // 清单标题
            Row({ space: 8 }) {
              Text('📋')
                .fontSize(18)
                .fontColor('#007DFF')
              Text('任务清单')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F2937')
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 添加新子任务
            Row({ space: 12 }) {
              TextInput({ placeholder: '添加一个子任务...', text: this.newChecklistItemText })
                .layoutWeight(1)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .padding(12)
                .fontSize(14)
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
                  .fontWeight(FontWeight.Bold)
              }
              .width(44)
              .height(44)
              .backgroundColor('#007DFF')
              .borderRadius(8)
              .shadow({ radius: 4, color: '#007DFF30', offsetX: 0, offsetY: 2 })
              .onClick(() => {
                this.submitNewChecklistItem();
              })
            }

            // 子任务列表
            if (!this.task || this.task.checklist.length === 0) {
              Column({ space: 8 }) {
                Image($r('app.media.ic_empty_box'))
                  .width(40)
                  .height(40)
                  .opacity(0.5)
                Text('暂无子任务')
                  .fontSize(14)
                  .fontColor('#9CA3AF')
              }
              .width('100%')
              .padding(20)
              .justifyContent(FlexAlign.Center)
            } else if (this.task) {
              Column({ space: 8 }) {
                ForEach(this.task.checklist, (item: ChecklistItem) => {
                  Row({ space: 12 }) {
                    Checkbox({ name: item.id, group: 'checklist' })
                      .select(item.isCompleted)
                      .onChange((value: boolean) => {
                        if (this.task) {
                          const newChecklist = this.task.checklist.map(i => {
                            if (i.id === item.id) {
                              return {
                                id: i.id,
                                text: i.text,
                                isCompleted: value
                              };
                            }
                            return i;
                          });
                          this.onUpdateChecklist(this.task.id, newChecklist);
                        }
                      })
                    Text(item.text)
                      .fontSize(14)
                      .fontColor(item.isCompleted ? '#9CA3AF' : '#374151')
                      .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
                      .layoutWeight(1)
                      .textAlign(TextAlign.Start)
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(item.isCompleted ? '#F9FAFB' : '#FFFFFF')
                  .borderRadius(8)
                  .border({ width: 1, color: item.isCompleted ? '#E5E7EB' : '#D1D5DB', radius: 8 })
                }, (item: ChecklistItem) => item.id)
              }
            }
          }
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

          // --- 底部操作按钮 ---
          Column({ space: 12 }) {
            CommonButton({
              text: '创建依赖从此任务开始',
              icon: '🔗',
              type: 'primary',
              onButtonClick: () => { this.onStartConnecting() }
            })

            CommonButton({
              text: '删除此任务',
              icon: '🗑️',
              type: 'danger',
              onButtonClick: () => {
                if (this.task) {
                  // 添加删除确认对话框
                  AlertDialog.show({
                    title: '确认删除任务',
                    message: `确定要删除任务"${this.task.name}"吗？删除后无法恢复。`,
                    primaryButton: {
                      value: '取消',
                      action: () => {
                        // 取消删除
                      }
                    },
                    secondaryButton: {
                      value: '删除',
                      fontColor: '#EF4444',
                      action: () => {
                        if (this.task) {
                          this.onDeleteTask(this.task.id);
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
              onButtonClick: () => { this.onBack() }
            })
          }
        }
        .padding(20)
      }
    }
  }
}
