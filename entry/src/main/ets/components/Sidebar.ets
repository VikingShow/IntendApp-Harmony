// File: entry/src/main/ets/components/Sidebar.ets

import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { TaskEditor } from './TaskEditor';

@Component
export struct Sidebar {
  @ObjectLink project: Project;
  @Link selectedTask: TaskNode | null;

  @State isEditingProjectName: boolean = false;
  @State tempProjectName: string = '';

  // FIX: Replaced 'any[]' with explicit type 'ChecklistItem[]'
  onUpdateTask: (task: TaskNode) => void = () => {};
  onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => void = () => {};
  onAddChecklistItem: (taskId: string, text: string) => void = () => {};

  onUpdateProjectName: (newName: string) => void = () => {};
  onAddTask: () => void = () => {};
  onDeleteTask: (id: string) => void = () => {};
  onStartConnecting: () => void = () => {};
  onCalculate: () => void = () => {};

  private saveProjectName() {
    if (this.tempProjectName.trim() !== '') {
      this.onUpdateProjectName(this.tempProjectName);
    }
    this.isEditingProjectName = false;
  }

  build() {
    Column() {
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
    .padding(15)
  }

  @Builder
  ProjectView() {
    Column({ space: 10 }) {
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
        Button() {
          Image(this.isEditingProjectName ? $r('app.media.ic_confirm') : $r('app.media.ic_edit'))
            .width(20).height(20).fillColor(Color.Black)
        }
        .width(40).height(40).type(ButtonType.Circle).backgroundColor('#EFEFEF')
        .onClick(() => {
          if (this.isEditingProjectName) {
            this.saveProjectName();
          } else {
            this.tempProjectName = this.project.name;
            this.isEditingProjectName = true;
          }
        })
      }.width('100%').alignItems(VerticalAlign.Center).margin({ bottom: 5 })

      // 项目统计
      Text(`总任务数: ${this.project.tasks.length}`).fontSize(12).fontColor(Color.Gray).width('100%').margin({ bottom: 10 })

      // 操作按钮
      Button({ type: ButtonType.Capsule, stateEffect: true }) {
        Row({ space: 8 }) { Image($r('app.media.ic_add')).width(18).height(18).fillColor(Color.White); Text('添加新任务').fontSize(16) }
      }.width('100%').height(45).backgroundColor('#007DFF').onClick(() => { this.onAddTask() })
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Row({ space: 8 }) { Image($r('app.media.ic_calculate')).width(18).height(18).fillColor(Color.Black); Text('计算关键路径').fontSize(16) }
      }.width('100%').height(45).margin({ top: 10 }).backgroundColor('#EFEFEF').fontColor(Color.Black).onClick(() => { this.onCalculate() })

      Divider().margin({ top: 15, bottom: 5 })

      // 任务列表
      if (this.project.tasks.length === 0) {
        this.EmptyState()
      } else {
        List({ space: 8 }) {
          // 按开始日期排序
          ForEach(this.project.tasks.sort((a, b) => a.startDate.getTime() - b.startDate.getTime()), (task: TaskNode) => {
            ListItem() {
              Row({ space: 12 }) {
                Column().width(5).height(30).backgroundColor(task.isCritical ? '#D0021B' : '#007DFF').borderRadius(5)
                Column({ space: 4 }) {
                  Text(task.name).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(`起止: ${task.startDate.toLocaleDateString()}`).fontSize(12).fontColor(Color.Gray)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              // FIX: Corrected syntax error (unterminated string literal)
              .width('100%').padding(12).backgroundColor(this.selectedTask?.id === task.id ? '#E0EFFF' : Color.White).borderRadius(8)
              .border({ width: this.selectedTask?.id === task.id ? 2 : 0, color: '#007DFF', radius: 8 })
              .onClick(() => { this.selectedTask = task; })
            }
          })
        }.layoutWeight(1)
      }
    }.alignItems(HorizontalAlign.Start)
  }

  @Builder
  EmptyState() {
    Column({ space: 16 }) {
      Image($r('app.media.ic_empty_box')).width(80).height(80).opacity(0.5)
      Text('项目中还没有任务').fontSize(16).fontColor(Color.Gray)
      Text('点击上方 "添加新任务" 来开始吧！').fontSize(14).fontColor(Color.Gray)
    }.width('100%').justifyContent(FlexAlign.Center).layoutWeight(1)
  }
}
