// File: entry/src/main/ets/components/Sidebar.ets

import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { TaskEditor } from './TaskEditor';
import { NewProjectDialog } from './WelcomeView';
import { TemplateDialog } from './TemplateDialog';
import promptAction from '@ohos.promptAction';
import { TemplateService } from '../services/TemplateService';

@Component
export struct Sidebar {
  // 使用@ObjectLink来响应Project状态变化（Project是@Observed类）
  @ObjectLink project: Project | null;
  // 使用@Prop来响应TaskNode状态变化（TaskNode是接口）
  @Prop selectedTask: TaskNode | null;
  @State private selectedTaskForEditor: TaskNode | null = null;
  // 新增参数：区分首页和编辑页
  isHomePage: boolean = false;
  onCreateBlankProject: () => void = () => {};
  onCreateProjectFromTemplate: (templateId: string, projectName: string) => void = () => {};

  @State isEditingProjectName: boolean = false;
  @State tempProjectName: string = '';
  @State showNewProjectDialog: boolean = false;
  @State showTemplateDialog: boolean = false;
  @State private taskEditorKey: number = 0;

  aboutToAppear() {
    this.selectedTaskForEditor = this.selectedTask;
  }
  
  aboutToUpdate() {
    // 当selectedTask变化时，更新selectedTaskForEditor
    if (this.selectedTaskForEditor?.id !== this.selectedTask?.id) {
      this.selectedTaskForEditor = this.selectedTask;
    } else if (this.selectedTask && this.selectedTaskForEditor) {
      // 如果ID相同但内容可能不同，同步更新内容
      this.selectedTaskForEditor = this.selectedTask;
    }
  }

  onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => void = () => {};
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
    Stack() {
      // 主内容
      Column() {
        // 只有首页才显示新建项目按钮
        if (this.isHomePage) {
          Row({ space: 12 }) {
            Button() {
              Row({ space: 10 }) { // 苹果风格：更大的间距
                Text('＋')
                  .fontSize(20) // 苹果风格：更大的字体
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
                Text('新建项目')
                  .fontSize(16) // 苹果风格：更易读的字体大小
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
              }
            }
            .width('100%')
            .height(52) // 苹果风格：更高的按钮
            .backgroundColor('#007AFF') // 苹果蓝色
            .borderRadius(12) // 苹果风格：更大的圆角
            .shadow({ radius: 12, color: '#007AFF30', offsetX: 0, offsetY: 4 }) // 苹果风格：更精致的阴影
            .onClick(() => {
              console.log('点击+号');
              this.showNewProjectDialog = true;
              this.showTemplateDialog = false;
            })
          }
          .margin({ bottom: 16 })
        }
        // 只有当项目加载完成后才显示内容
        if (this.project) {
          if (this.selectedTaskForEditor === null) {
            this.ProjectView()
          } else {
            TaskEditor({
              task: this.selectedTaskForEditor,
              onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => {
                this.onUpdateTask(taskId, updates);
              },
              onUpdateChecklist: this.onUpdateChecklist,
              onAddChecklistItem: this.onAddChecklistItem,
              onDeleteTask: this.onDeleteTask,
              onStartConnecting: this.onStartConnecting,
              onBack: () => {
                this.selectedTaskForEditor = null;
              }
            })
          }
        } else {
          // 项目加载中或加载失败时显示的内容
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#007DFF')
            Text('正在加载项目...')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F7') // 苹果风格：更柔和的背景色
      .padding(24) // 苹果风格：更大的外边距

      // 弹窗遮罩层
      // 只有首页才显示新建相关弹窗
      if (this.isHomePage && this.showNewProjectDialog) {
        Column() {
          NewProjectDialog({
            onBlank: () => {
              console.log('点击新建空白图');
              this.showNewProjectDialog = false;
              this.showTemplateDialog = false;
              this.onCreateBlankProject();
            },
            onTemplate: () => {
              console.log('点击选择模板');
              this.showNewProjectDialog = false;
              this.showTemplateDialog = true;
            },
            onClose: () => {
              console.log('关闭新建方式弹窗');
              this.showNewProjectDialog = false;
              this.showTemplateDialog = false;
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.25)')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .zIndex(100)
      } else if (this.isHomePage && this.showTemplateDialog) {
        Column() {
          TemplateDialog({
            visible: true,
            onClose: () => { 
              console.log('关闭模板弹窗');
              this.showTemplateDialog = false; 
            },
            onTemplateSelected: (templateId: string, projectName: string) => {
              console.log('模板弹窗创建项目', templateId, projectName);
              this.showTemplateDialog = false;
              this.onCreateProjectFromTemplate(templateId, projectName);
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.25)')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .zIndex(100)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ProjectView() {
    if (this.project) {
      Column({ space: 16 }) {
        // --- 顶部操作栏 ---
        Row({space: 16}) {
          // 返回主页按钮
          Button() {
            Image($r('app.media.ic_back'))
              .width(20)
              .height(20)
              .fillColor('#666666')
          }
          .width(48) // 苹果风格：更大的按钮尺寸
          .height(48)
          .type(ButtonType.Circle)
          .backgroundColor('#FFFFFF')
          .borderRadius(24) // 确保圆形
          .shadow({ radius: 8, color: '#00000012', offsetX: 0, offsetY: 3 }) // 苹果风格：更精致的阴影
          .onClick(() => { this.onBack() })

          // 新建任务按钮（仅编辑页显示）
          if (!this.isHomePage) {
            Button({ type: ButtonType.Circle }) {
              Image($r('app.media.ic_add'))
                .width(20)
                .height(20)
                .fillColor(Color.White)
            }
            .width(48) // 苹果风格：更大的按钮尺寸
            .height(48)
            .backgroundColor('#34C759') // 苹果绿色
            .borderRadius(24) // 确保圆形
            .shadow({ radius: 8, color: '#34C75930', offsetX: 0, offsetY: 3 }) // 苹果风格：更精致的阴影
            .onClick(() => { this.onAddTask() })
            .margin({ left: 0, right: 0 })
          }

          // 保存项目按钮
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_save'))
              .width(20)
              .height(20)
              .fillColor(Color.White)
          }
          .width(48) // 苹果风格：更大的按钮尺寸
          .height(48)
          .backgroundColor('#007AFF') // 苹果蓝色
          .borderRadius(24) // 确保圆形
          .shadow({ radius: 8, color: '#007AFF30', offsetX: 0, offsetY: 3 }) // 苹果风格：更精致的阴影
          .onClick(() => { this.onSave() })

          // 占位拉伸
          Blank().layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 16 }) // 苹果风格：更大的间距

        // 项目标题区域
        Column({ space: 12 }) { // 苹果风格：更大的间距
          Row({ space: 12 }) {
            if (this.isEditingProjectName) {
              TextInput({ text: this.tempProjectName })
                .layoutWeight(1)
                .fontSize(22)
                .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
                .backgroundColor('#F5F5F7') // 苹果风格：更柔和的背景色
                .borderRadius(12) // 苹果风格：更大的圆角
                .padding({ left: 16, right: 16, top: 12, bottom: 12 }) // 苹果风格：更精致的内边距
                .onChange((value: string) => { this.tempProjectName = value; })
                .onSubmit(() => { this.saveProjectName(); })
            } else {
              Text(this.project.name)
                .fontSize(22)
                .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
                .layoutWeight(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .maxLines(1)
                .fontColor('#1D1D1F') // 苹果深色文字
            }
            Button() {
              Image(this.isEditingProjectName ? $r('app.media.ic_confirm') : $r('app.media.ic_edit'))
                .width(18)
                .height(18)
                .fillColor(this.isEditingProjectName ? '#28A745' : '#666666')
            }
            .width(44) // 苹果风格：适中的按钮尺寸
            .height(44)
            .type(ButtonType.Circle)
            .backgroundColor('#FFFFFF')
            .borderRadius(22) // 确保圆形
            .shadow({ radius: 6, color: '#00000012', offsetX: 0, offsetY: 2 }) // 苹果风格：更精致的阴影
            .onClick(() => {
              if (this.isEditingProjectName) {
                this.saveProjectName();
              } else {
                this.tempProjectName = this.project!.name;
                this.isEditingProjectName = true;
              }
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 项目统计卡片
          Row({ space: 20 }) { // 苹果风格：更大的间距
            Column() {
              Text(this.project.tasks.length.toString())
                .fontSize(20)
                .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
                .fontColor('#007AFF') // 苹果蓝色
              Text('总任务')
                .fontSize(13) // 苹果风格：更易读的字体大小
                .fontColor('#86868B') // 苹果次要文字颜色
            }
            .layoutWeight(1)
            .padding(16) // 苹果风格：更大的内边距
            .backgroundColor('#FFFFFF')
            .borderRadius(12) // 苹果风格：更大的圆角
            .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 }) // 苹果风格：更精致的阴影

            Column() {
              Text(this.project.tasks.filter(t => t.isCritical).length.toString())
                .fontSize(20)
                .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
                .fontColor('#FF3B30') // 苹果红色
              Text('关键任务')
                .fontSize(13) // 苹果风格：更易读的字体大小
                .fontColor('#86868B') // 苹果次要文字颜色
            }
            .layoutWeight(1)
            .padding(16) // 苹果风格：更大的内边距
            .backgroundColor('#FFFFFF')
            .borderRadius(12) // 苹果风格：更大的圆角
            .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 }) // 苹果风格：更精致的阴影
          }
          .width('100%')
        }
        .padding(20) // 苹果风格：更大的内边距
        .backgroundColor('#FFFFFF')
        .borderRadius(16) // 苹果风格：更大的圆角
        .shadow({ radius: 20, color: '#00000008', offsetX: 0, offsetY: 4 }) // 苹果风格：更精致的阴影

        // 操作按钮区域
        Column({ space: 16 }) { // 苹果风格：更大的间距
          Button() {
            Row({ space: 10 }) { // 苹果风格：更大的间距
              Text('💡')
                .fontSize(18) // 苹果风格：更大的字体
                .fontColor(Color.White)
              Text('计算关键路径')
                .fontSize(16) // 苹果风格：更易读的字体大小
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
            }
          }
          .width('100%')
          .height(52) // 苹果风格：更高的按钮
          .backgroundColor('#34C759') // 苹果绿色
          .borderRadius(12) // 苹果风格：更大的圆角
          .shadow({ radius: 12, color: '#34C75930', offsetX: 0, offsetY: 4 }) // 苹果风格：更精致的阴影
          .onClick(() => { this.onCalculate() })
        }

        // 任务列表区域
        Column({ space: 12 }) { // 苹果风格：更大的间距
          Text('任务列表')
            .fontSize(18) // 苹果风格：更大的字体
            .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
            .fontColor('#1D1D1F') // 苹果深色文字
            .width('100%')
            .textAlign(TextAlign.Start)

          if (this.project.tasks.length === 0) {
            Column({ space: 16 }) { // 苹果风格：更大的间距
              Image($r('app.media.ic_empty_box'))
                .width(64) // 苹果风格：更大的图标
                .height(64)
                .opacity(0.4) // 苹果风格：更柔和的透明度
              Text('暂无任务')
                .fontSize(15) // 苹果风格：更易读的字体大小
                .fontColor('#86868B') // 苹果次要文字颜色
              Text('点击上方按钮添加新任务')
                .fontSize(13) // 苹果风格：更易读的字体大小
                .fontColor('#86868B') // 苹果次要文字颜色
            }
            .width('100%')
            .padding(40) // 苹果风格：更大的内边距
            .justifyContent(FlexAlign.Center)
            .layoutWeight(1)
          } else {
            List({ space: 12 }) { // 苹果风格：更大的间距
              ForEach(this.project.tasks.sort((a, b) => a.startDate.getTime() - b.startDate.getTime()), (task: TaskNode) => {
                ListItem() {
                  Row({ space: 12 }) {
                    // 任务状态指示器
                    Column()
                      .width(4)
                      .height(44) // 苹果风格：更高的指示器
                      .backgroundColor(task.isCritical ? '#FF3B30' : '#007AFF') // 苹果标准颜色
                      .borderRadius(2)

                    // 任务信息
                    Column({ space: 6 }) { // 苹果风格：更大的间距
                      Text(task.name)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium) // 苹果风格：更优雅的字体权重
                        .fontColor('#1D1D1F') // 苹果深色文字
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${task.startDate.toLocaleDateString()} - ${task.endDate.toLocaleDateString()}`)
                        .fontSize(13) // 苹果风格：更易读的字体大小
                        .fontColor('#86868B') // 苹果次要文字颜色
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    // 关键任务标识
                    if (task.isCritical) {
                      Text('🔥')
                        .fontSize(16) // 苹果风格：更大的字体
                        .fontColor('#FF3B30') // 苹果红色
                    }
                  }
                  .width('100%')
                  .padding(18) // 苹果风格：更大的内边距
                  .backgroundColor(this.selectedTask?.id === task.id ? '#F0F8FF' : '#FFFFFF') // 苹果风格：更柔和的选中背景色
                  .borderRadius(12) // 苹果风格：更大的圆角
                  .shadow({ radius: 8, color: this.selectedTask?.id === task.id ? '#007AFF20' : '#0000000A', offsetX: 0, offsetY: 2 }) // 苹果风格：更精致的阴影
                  .border({ width: this.selectedTask?.id === task.id ? 2 : 0, color: '#007AFF', radius: 12 }) // 苹果风格：更精致的边框
                  .onClick(() => {
                    this.selectedTask = task;
                  })
                }
              })
            }
            .layoutWeight(1)
          }
        }
        .layoutWeight(1)
      }
      .alignItems(HorizontalAlign.Start)
    }
  }
}
