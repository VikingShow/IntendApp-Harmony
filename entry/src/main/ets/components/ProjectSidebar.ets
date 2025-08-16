
import { ProjectManager } from '../core/ProjectManager';
import { TaskEditor } from './TaskEditor';
import { NewProjectDialog } from './WelcomeView';
import { TemplateDialog } from './TemplateDialog';
import { TaskNode } from '../model/ProjectData';
import promptAction from '@ohos.promptAction';

@Component
export struct ProjectSidebar {
  @State private selectedTaskForEditor: TaskNode | null = null;
  @State isEditingProjectName: boolean = false;
  @State tempProjectName: string = '';
  @State showNewProjectDialog: boolean = false;
  @State showTemplateDialog: boolean = false;
  @State private taskEditorKey: number = 0;

  // 项目管理器
  private projectManager: ProjectManager = ProjectManager.getInstance();

  // 页面类型标识
  isHomePage: boolean = false;

  aboutToAppear() {
    this.selectedTaskForEditor = this.projectManager.getState().selectedTask;
  }

  aboutToUpdate() {
    this.selectedTaskForEditor = this.projectManager.getState().selectedTask;
  }

  private saveProjectName() {
    if (this.tempProjectName.trim() === '') {
      promptAction.showToast({ message: '项目名称不能为空' });
      return;
    }
    this.projectManager.getActions().updateProjectName(this.tempProjectName);
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
              Row({ space: 8 }) {
                Text('＋')
                  .fontSize(18)
                  .fontColor(Color.White)
                Text('新建项目')
                  .fontSize(15)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .shadow({ radius: 6, color: '#007DFF30', offsetX: 0, offsetY: 3 })
            .onClick(() => {
              console.log('点击+号');
              this.showNewProjectDialog = true;
              this.showTemplateDialog = false;
            })
          }
          .margin({ bottom: 16 })
        }

        // 只有当项目加载完成后才显示内容
        if (this.projectManager.getState().project) {
          if (this.selectedTaskForEditor === null) {
            this.ProjectView()
          } else {
            TaskEditor({
              task: this.selectedTaskForEditor,
              onUpdateTask: (task) => this.projectManager.getActions().updateTask(task),
              onUpdateChecklist: (taskId, checklist) => this.projectManager.getActions().updateChecklist(taskId, checklist),
              onAddChecklistItem: (taskId, text) => this.projectManager.getActions().addChecklistItem(taskId, text),
              onDeleteTask: (id) => this.projectManager.getActions().deleteTask(id),
              onStartConnecting: () => {
                // 这里需要通知父组件开始连接模式
                // 可以通过事件总线或其他方式实现
              },
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
      .backgroundColor('#F8FAFC')
      .padding(20)

      // 弹窗遮罩层
      // 只有首页才显示新建相关弹窗
      if (this.isHomePage && this.showNewProjectDialog) {
        Column() {
          NewProjectDialog({
            onBlank: () => {
              console.log('点击新建空白图');
              this.showNewProjectDialog = false;
              this.showTemplateDialog = false;
              this.projectManager.getActions().createNewProject();
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
              this.projectManager.getActions().createFromTemplate(templateId, projectName);
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
    const project = this.projectManager.getState().project;
    const selectedTask = this.projectManager.getState().selectedTask;
    
    if (!project) return;

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
        .width(44)
        .height(44)
        .type(ButtonType.Circle)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 4, color: '#00000010', offsetX: 0, offsetY: 2 })
        .onClick(() => { router.back() })

        // 新建任务按钮（仅编辑页显示）
        if (!this.isHomePage) {
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_add'))
              .width(20)
              .height(20)
              .fillColor(Color.White)
          }
          .width(44)
          .height(44)
          .backgroundColor('#10B981')
          .shadow({ radius: 4, color: '#10B98130', offsetX: 0, offsetY: 2 })
          .onClick(() => { this.projectManager.getActions().addTask() })
          .margin({ left: 0, right: 0 })
        }

        // 保存项目按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_save'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(44)
        .height(44)
        .backgroundColor('#007DFF')
        .shadow({ radius: 4, color: '#007DFF30', offsetX: 0, offsetY: 2 })
        .onClick(() => { this.projectManager.getActions().saveProject() })

        // 占位拉伸
        Blank().layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 项目标题区域
      Column({ space: 8 }) {
        Row({ space: 12 }) {
          if (this.isEditingProjectName) {
            TextInput({ text: this.tempProjectName })
              .layoutWeight(1)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .padding(12)
              .onChange((value: string) => { this.tempProjectName = value; })
              .onSubmit(() => { this.saveProjectName(); })
          } else {
            Text(project.name)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(1)
              .fontColor('#1F2937')
          }
          Button() {
            Image(this.isEditingProjectName ? $r('app.media.ic_confirm') : $r('app.media.ic_edit'))
              .width(18)
              .height(18)
              .fillColor(this.isEditingProjectName ? '#28A745' : '#666666')
          }
          .width(40)
          .height(40)
          .type(ButtonType.Circle)
          .backgroundColor('#FFFFFF')
          .shadow({ radius: 4, color: '#00000010', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            if (this.isEditingProjectName) {
              this.saveProjectName();
            } else {
              this.tempProjectName = project.name;
              this.isEditingProjectName = true;
            }
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 项目统计卡片
        Row({ space: 16 }) {
          Column() {
            Text(project.tasks.length.toString())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('总任务')
              .fontSize(12)
              .fontColor('#6B7280')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 })

          Column() {
            Text(project.tasks.filter(t => t.isCritical).length.toString())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D0021B')
            Text('关键任务')
              .fontSize(12)
              .fontColor('#6B7280')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 })
        }
        .width('100%')
      }
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

      // 操作按钮区域
      Column({ space: 12 }) {
        Button() {
          Row({ space: 8 }) {
            Text('💡')
              .fontSize(16)
              .fontColor(Color.White)
            Text('计算关键路径')
              .fontSize(15)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
        .height(48)
        .backgroundColor('#28A745')
        .borderRadius(8)
        .shadow({ radius: 6, color: '#28A74530', offsetX: 0, offsetY: 3 })
        .onClick(() => { this.projectManager.getActions().calculateCriticalPath() })
      }

      // 任务列表区域
      Column({ space: 8 }) {
        Text('任务列表')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .width('100%')
          .textAlign(TextAlign.Start)

        if (project.tasks.length === 0) {
          Column({ space: 12 }) {
            Image($r('app.media.ic_empty_box'))
              .width(60)
              .height(60)
              .opacity(0.5)
            Text('暂无任务')
              .fontSize(14)
              .fontColor('#9CA3AF')
            Text('点击上方按钮添加新任务')
              .fontSize(12)
              .fontColor('#9CA3AF')
          }
          .width('100%')
          .padding(32)
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
        } else {
          List({ space: 8 }) {
            ForEach(project.tasks.sort((a, b) => a.startDate.getTime() - b.startDate.getTime()), (task: TaskNode) => {
              ListItem() {
                Row({ space: 12 }) {
                  // 任务状态指示器
                  Column()
                    .width(4)
                    .height(40)
                    .backgroundColor(task.isCritical ? '#D0021B' : '#007DFF')
                    .borderRadius(2)

                  // 任务信息
                  Column({ space: 4 }) {
                    Text(task.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1F2937')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${task.startDate.toLocaleDateString()} - ${task.endDate.toLocaleDateString()}`)
                      .fontSize(12)
                      .fontColor('#6B7280')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  // 关键任务标识
                  if (task.isCritical) {
                    Text('🔥')
                      .fontSize(14)
                      .fontColor('#D0021B')
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor(selectedTask?.id === task.id ? '#EFF6FF' : '#FFFFFF')
                .borderRadius(10)
                .shadow({ radius: 4, color: selectedTask?.id === task.id ? '#007DFF20' : '#00000008', offsetX: 0, offsetY: 1 })
                .border({ width: selectedTask?.id === task.id ? 2 : 0, color: '#007DFF', radius: 10 })
                .onClick(() => {
                  this.projectManager.getActions().selectTask(task);
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


