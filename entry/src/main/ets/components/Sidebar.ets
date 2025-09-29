// File: entry/src/main/ets/components/Sidebar.ets
/**
 * 侧边栏组件模块
 * 
 * 本组件是EasyFlow应用的主要导航和操作界面，提供项目管理和任务编辑的核心功能。
 * 采用响应式设计，根据当前状态动态显示不同的内容和操作选项。
 * 
 * 主要功能：
 * 1. 项目管理：显示项目信息、统计数据和基本操作
 * 2. 任务编辑：提供任务详情编辑和检查清单管理
 * 3. 项目创建：支持空白项目和模板项目的创建
 * 4. 任务操作：添加、删除、选择、连接任务等操作
 * 5. 状态切换：在项目概览和任务编辑之间切换
 * 6. 模板选择：提供项目模板的选择和预览功能
 * 
 * 设计特点：
 * - 响应式布局：根据屏幕尺寸和内容动态调整布局
 * - 状态驱动：根据当前状态显示不同的界面内容
 * - 模块化设计：将不同功能模块化为独立的子组件
 * - 交互友好：提供直观的操作反馈和状态指示
 * - 可扩展性：支持新功能的添加和现有功能的扩展
 * 
 * 界面模式：
 * - 首页模式：显示项目列表和创建选项
 * - 项目模式：显示项目概览和基本操作
 * - 编辑模式：显示任务编辑器和详细操作
 * - 模板模式：显示模板选择和预览界面
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { TaskEditor } from './TaskEditor';
import { NewProjectDialog } from './WelcomeView';
import { TemplateDialog } from './TemplateDialog';
import promptAction from '@ohos.promptAction';
import { TemplateService } from '../services/TemplateService';

/**
 * 侧边栏组件
 * 
 * 实现应用主要导航和操作界面的核心组件，提供项目管理和任务编辑的完整功能。
 * 采用状态驱动设计，根据当前状态动态显示不同的界面内容。
 * 
 * 组件特性：
 * - 响应式数据绑定：使用@ObjectLink和@Prop实现数据的自动同步
 * - 状态管理：根据当前状态显示不同的界面模式
 * - 模块化设计：将功能分解为独立的子组件
 * - 交互反馈：提供丰富的用户操作反馈
 * - 可配置性：支持不同场景下的界面配置
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
@Component
export struct Sidebar {
  /** 项目数据对象，使用@ObjectLink实现响应式绑定 */
  @ObjectLink project: Project | null;
  /** 当前选中的任务，使用@Prop实现属性传递 */
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
              Row({ space: 10 }) {
                Text('＋')
                  .fontSize(20)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium)
                Text('新建项目')
                  .fontSize(16)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .width('100%')
            .height(52)
            .backgroundColor('#007AFF')
            .borderRadius(12)
            .shadow({ radius: 12, color: '#007AFF30', offsetX: 0, offsetY: 4 })
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
      .backgroundColor('#F5F5F7')
      .padding(24)

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
          .width(48)
          .height(48)
          .type(ButtonType.Circle)
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .shadow({ radius: 8, color: '#00000012', offsetX: 0, offsetY: 3 })
          .onClick(() => { this.onBack() })

          // 新建任务按钮（仅编辑页显示）
          if (!this.isHomePage) {
            Button({ type: ButtonType.Circle }) {
              Image($r('app.media.ic_add'))
                .width(20)
                .height(20)
                .fillColor(Color.White)
            }
            .width(48)
            .height(48)
            .backgroundColor('#34C759')
            .borderRadius(24)
            .shadow({ radius: 8, color: '#34C75930', offsetX: 0, offsetY: 3 })
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
          .width(48)
          .height(48)
          .backgroundColor('#007AFF')
          .borderRadius(24) // 确保圆形
          .shadow({ radius: 8, color: '#007AFF30', offsetX: 0, offsetY: 3 })
          .onClick(() => { this.onSave() })

          // 占位拉伸
          Blank().layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 项目标题区域
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            if (this.isEditingProjectName) {
              TextInput({ text: this.tempProjectName })
                .layoutWeight(1)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#F5F5F7')
                .borderRadius(12)
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .onChange((value: string) => { this.tempProjectName = value; })
                .onSubmit(() => { this.saveProjectName(); })
            } else {
              Text(this.project.name)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .maxLines(1)
                .fontColor('#1D1D1F')
            }
            Button() {
              Image(this.isEditingProjectName ? $r('app.media.ic_confirm') : $r('app.media.ic_edit'))
                .width(18)
                .height(18)
                .fillColor(this.isEditingProjectName ? '#28A745' : '#666666')
            }
            .width(44)
            .height(44)
            .type(ButtonType.Circle)
            .backgroundColor('#FFFFFF')
            .borderRadius(22)
            .shadow({ radius: 6, color: '#00000012', offsetX: 0, offsetY: 2 })
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
          Row({ space: 20 }) {
            Column() {
              Text(this.project.tasks.length.toString())
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor('#007AFF')
              Text('总任务')
                .fontSize(13)
                .fontColor('#86868B')
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })

            Column() {
              Text(this.project.tasks.filter(t => t.isCritical).length.toString())
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FF3B30')
              Text('关键任务')
                .fontSize(13)
                .fontColor('#86868B')
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })
          }
          .width('100%')
        }
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 20, color: '#00000008', offsetX: 0, offsetY: 4 })

        // 操作按钮区域
        Column({ space: 16 }) {
          Button() {
            Row({ space: 10 }) {
              Text('💡')
                .fontSize(18)
                .fontColor(Color.White)
              Text('计算关键路径')
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
          }
          .width('100%')
          .height(52)
          .backgroundColor('#34C759')
          .borderRadius(12)
          .shadow({ radius: 12, color: '#34C75930', offsetX: 0, offsetY: 4 })
          .onClick(() => { this.onCalculate() })
        }

        // 任务列表区域
        Column({ space: 12 }) {
          Text('任务列表')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1D1D1F')
            .width('100%')
            .textAlign(TextAlign.Start)

          if (this.project.tasks.length === 0) {
            Column({ space: 16 }) {
              Image($r('app.media.ic_empty_box'))
                .width(64)
                .height(64)
                .opacity(0.4)
              Text('暂无任务')
                .fontSize(15)
                .fontColor('#86868B')
              Text('点击上方按钮添加新任务')
                .fontSize(13)
                .fontColor('#86868B')
            }
            .width('100%')
            .padding(40)
            .justifyContent(FlexAlign.Center)
            .layoutWeight(1)
          } else {
            List({ space: 12 }) {
              ForEach(this.project.tasks.sort((a, b) => a.startDate.getTime() - b.startDate.getTime()), (task: TaskNode) => {
                ListItem() {
                  Row({ space: 12 }) {
                    // 任务状态指示器
                    Column()
                      .width(4)
                      .height(44)
                      .backgroundColor(task.isCritical ? '#FF3B30' : '#007AFF')
                      .borderRadius(2)

                    // 任务信息
                    Column({ space: 6 }) {
                      Text(task.name)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1D1D1F')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${task.startDate.toLocaleDateString()} - ${task.endDate.toLocaleDateString()}`)
                        .fontSize(13)
                        .fontColor('#86868B')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    // 关键任务标识
                    if (task.isCritical) {
                      Text('🔥')
                        .fontSize(16)
                        .fontColor('#FF3B30')
                    }
                  }
                  .width('100%')
                  .padding(18)
                  .backgroundColor(this.selectedTask?.id === task.id ? '#F0F8FF' : '#FFFFFF')
                  .borderRadius(12)
                  .shadow({ radius: 8, color: this.selectedTask?.id === task.id ? '#007AFF20' : '#0000000A', offsetX: 0, offsetY: 2 })
                  .border({ width: this.selectedTask?.id === task.id ? 2 : 0, color: '#007AFF', radius: 12 })
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
