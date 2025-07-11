// File: entry/src/main/ets/components/TaskEditor.ets

import { TaskNode, ChecklistItem } from '../model/ProjectData';

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
      this.onAddChecklistItem(this.task.id, this.newChecklistItemText);
      this.newChecklistItemText = '';
    }
  }

  build() {
    if (this.task) {
      // FIX: 将根布局改为Scroll，以确保整个编辑器在内容溢出时可以滚动
      Scroll() {
        Column({ space: 15 }) {
          // --- 头部信息 ---
          Column({ space: 10 }) {
            Text(`编辑: ${this.task.name}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .textAlign(TextAlign.Start)

            TextInput({ text: this.task.name })
              .onChange((value: string) => {
                if (this.task) {
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

            Row({ space: 10 }) {
              Column() {
                Text('开始日期').fontSize(14).fontColor(Color.Gray)
                DatePicker({
                  start: new Date('2020-01-01'),
                  end: new Date('2030-12-31'),
                  selected: this.task.startDate
                })
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

              Column() {
                Text('结束日期').fontSize(14).fontColor(Color.Gray)
                DatePicker({
                  start: new Date('2020-01-01'),
                  end: new Date('2030-12-31'),
                  selected: this.task.endDate
                })
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

            Text(`工期: ${this.getDuration()} 天`)
              .fontSize(12)
              .fontColor(Color.Gray)
              .width('100%')
              .textAlign(TextAlign.End)
          }

          Divider().margin({ top: 10, bottom: 10 })

          // --- 任务清单 ---
          Text('任务清单')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          Row({ space: 8 }) {
            TextInput({ placeholder: '添加一个子任务...', text: this.newChecklistItemText })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.newChecklistItemText = value;
              })
              .onSubmit(() => {
                this.submitNewChecklistItem();
              })
            Button('+')
              .width(40).height(40)
              .onClick(() => {
                this.submitNewChecklistItem();
              })
          }.margin({ bottom: 10 })

          // 子任务列表
          Column({ space: 5 }) {
            // FIX: 为ForEach增加key生成器，确保列表能可靠更新
            ForEach(this.task.checklist, (item: ChecklistItem) => {
              Row({ space: 10 }) {
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
                  .fontColor(item.isCompleted ? Color.Gray : Color.Black)
                  .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
              }
              .padding({ top: 5, bottom: 5 })
            }, (item: ChecklistItem) => item.id) // key生成器
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')


          // --- 底部操作按钮 ---
          Column({ space: 10 }) {
            Button('🔗 创建依赖从此任务开始')
              .width('100%')
              .type(ButtonType.Normal)
              .onClick(() => { this.onStartConnecting() })

            Button('删除此任务')
              .width('100%')
              .type(ButtonType.Capsule)
              .backgroundColor(Color.Red)
              .onClick(() => {
                if (this.task) {
                  this.onDeleteTask(this.task.id);
                }
              })

            Button('返回列表')
              .width('100%')
              .type(ButtonType.Normal)
              .onClick(() => { this.onBack() })
          }.margin({ top: 20 })
        }
        .padding({ bottom: 20 }) // 为滚动内容增加底部内边距
      }
    }
  }
}
