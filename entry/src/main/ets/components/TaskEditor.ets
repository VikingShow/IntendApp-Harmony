// File: entry/src/main/ets/components/TaskEditor.ets

import { TaskNode } from '../model/ProjectData';

@Component
export struct TaskEditor {
  task: TaskNode | null = null;

  onUpdateTask: (id: string, name: string, duration: number) => void = () => {};
  onDeleteTask: (id: string) => void = () => {};
  onBack: () => void = () => {};
  // 新增：创建连接的回调函数
  onStartConnecting: () => void = () => {};

  build() {
    if (this.task) {
      Column({ space: 15 }) {
        Text(`编辑: ${this.task.name}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Text('任务名称').width('100%').fontColor(Color.Gray)
        TextInput({ text: this.task.name })
          .onChange((value: string) => {
            if (this.task) {
              this.onUpdateTask(this.task.id, value, this.task.duration);
            }
          })

        Text('工期 (天)').width('100%').fontColor(Color.Gray)
        TextInput({ text: this.task.duration.toString() })
          .type(InputType.Number)
          .onChange((value: string) => {
            if (this.task) {
              const duration = parseInt(value) || 0;
              this.onUpdateTask(this.task.id, this.task.name, duration);
            }
          })

        // 新增：创建依赖的按钮
        Button('🔗 创建依赖从此任务开始')
          .width('100%')
          .type(ButtonType.Normal)
          .margin({ top: 20 })
          .onClick(() => {
            this.onStartConnecting();
          })

        Blank()

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
          .margin({ top: 10 })
          .onClick(() => {
            this.onBack();
          })
      }
      .alignItems(HorizontalAlign.Start)
      .height('100%')
    }
  }
}
