// File: entry/src/main/ets/components/Sidebar.ets

import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { TaskEditor } from './TaskEditor';
import promptAction from '@ohos.promptAction';

@Component
export struct Sidebar {
  // project现在可能为null，直到它被加载
  @ObjectLink project: Project | null;
  @Link selectedTask: TaskNode | null;

  @State isEditingProjectName: boolean = false;
  @State tempProjectName: string = '';

  onUpdateTask: (task: TaskNode) => void = () => {};
  onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => void = () => {};
  onAddChecklistItem: (taskId: string, text: string) => void = () => {};
  onUpdateProjectName: (newName: string) => void = () => {};
  onAddTask: () => void = () => {};
  onDeleteTask: (id: string) => void = () => {};
  onStartConnecting: () => void = () => {};
  onCalculate: () => void = () => {};
  // 新增回调
  onSave: () => void = () => {};
  onBack: () => void = () => {};

  private saveProjectName() {
    if (this.tempProjectName.trim() === '') {
      promptAction.showToast({ message: '项目名称不能为空' });
      return;
    }
    this.onUpdateProjectName(this.tempProjectName);
    this.isEditingProjectName = false;
  }

  build() {
    Column() {
      // 只有当项目加载完成后才显示内容
      if (this.project) {
        if (this.selectedTask === null) {
          this.ProjectView()
        } else {
          TaskEditor({
            task: this.selectedTask,
            onUpdateTask: this.onUpdateTask,
            onUpdateChecklist: this.onUpdateChecklist,
            onAddChecklistItem: this.onAddChecklistItem,
            onDeleteTask: this.onDeleteTask,
            onStartConnecting: this.onStartConnecting,
            onBack: () => {
              this.selectedTask = null;
            }
          })
        }
      } else {
        // 项目加载中或加载失败时显示的内容
        Column() {
          Text('正在加载项目...')
            .fontSize(18)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
    .padding(15)
  }

  @Builder
  ProjectView() {
    if (this.project) {
      Column({ space: 10 }) {
        // --- 顶部操作栏 ---
        Row({space: 10}) {
          // 返回主页按钮
          Button() { Image($r('app.media.ic_back')).width(20).height(20) }
          .width(40).height(40).type(ButtonType.Circle).backgroundColor(Color.White)
          .onClick(() => { this.onBack() })

          // FIX: The Button component with children cannot have a label parameter.
          // The text is now a Text component inside the button's child Row.
          Button({ type: ButtonType.Capsule }) {
            Row({ space: 8 }) {
              Image($r('app.media.ic_save')).width(20).height(20).fillColor(Color.White)
              Text('保存项目').fontSize(16).fontColor(Color.White)
            }
          }
          .layoutWeight(1).backgroundColor('#007DFF')
          .onClick(() => { this.onSave() })
        }
        .width('100%')

        Divider().margin({ top: 10, bottom: 10 })

        // 可编辑的项目标题
        Row({ space: 8 }) {
          if (this.isEditingProjectName) {
            TextInput({ text: this.tempProjectName })
              .layoutWeight(1).fontSize(24).fontWeight(FontWeight.Bold)
              .onChange((value: string) => { this.tempProjectName = value; })
              .onSubmit(() => { this.saveProjectName(); })
          } else {
            Text(this.project.name)
              .fontSize(24).fontWeight(FontWeight.Bold).layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).maxLines(1)
          }
          Button() { Image(this.isEditingProjectName ? $r('app.media.ic_confirm') : $r('app.media.ic_edit')).width(20).height(20).fillColor(Color.Black) }
          .width(40).height(40).type(ButtonType.Circle).backgroundColor('#EFEFEF')
          .onClick(() => {
            if (this.isEditingProjectName) {
              this.saveProjectName();
            } else {
              this.tempProjectName = this.project!.name;
              this.isEditingProjectName = true;
            }
          })
        }.width('100%').alignItems(VerticalAlign.Center).margin({ bottom: 5 })

        // 项目统计
        Text(`总任务数: ${this.project.tasks.length}`).fontSize(12).fontColor(Color.Gray).width('100%').margin({ bottom: 10 })

        // 操作按钮
        Button('＋ 添加新任务')
          .width('100%').height(45).type(ButtonType.Normal).backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => { this.onAddTask() })
        Button('💡 计算关键路径')
          .width('100%').height(45).type(ButtonType.Normal).backgroundColor('#28A745')
          .fontColor(Color.White)
          .margin({ top: 10 })
          .onClick(() => { this.onCalculate() })

        Divider().margin({ top: 15, bottom: 5 })

        // 任务列表
        if (this.project.tasks.length === 0) {
          Column() { Text('点击"添加新任务"开始').fontColor(Color.Gray) }.justifyContent(FlexAlign.Center).layoutWeight(1)
        } else {
          List({ space: 8 }) {
            ForEach(this.project.tasks.sort((a, b) => a.startDate.getTime() - b.startDate.getTime()), (task: TaskNode) => {
              ListItem() {
                Row({ space: 12 }) {
                  Column().width(5).height(30).backgroundColor(task.isCritical ? '#D0021B' : '#007DFF').borderRadius(5)
                  Column({ space: 4 }) {
                    Text(task.name).fontSize(16).fontWeight(FontWeight.Medium)
                    Text(`起止: ${task.startDate.toLocaleDateString()}`).fontSize(12).fontColor(Color.Gray)
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }
                .width('100%').padding(12).backgroundColor(this.selectedTask?.id === task.id ? '#E0EFFF' : Color.White).borderRadius(8)
                .border({ width: this.selectedTask?.id === task.id ? 2 : 0, color: '#007DFF', radius: 8 })
                .onClick(() => { 
                  this.selectedTask = task; 
                })
              }
            })
          }.layoutWeight(1)
        }
      }.alignItems(HorizontalAlign.Start)
    }
  }
}
