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
import { ThemeConfig } from '../utils/ThemeConfig';
import { PromptAction } from '@kit.ArkUI';

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
  onDeleteTask: (taskId: string) => void = () => {};

  @State isEditingProjectName: boolean = false;
  @State tempProjectName: string = '';
  @State showNewProjectDialog: boolean = false;
  @State showTemplateDialog: boolean = false;
  // @State private taskEditorKey: number = 0;

  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  aboutToAppear() {
    this.selectedTaskForEditor = this.selectedTask;
  }

  // 删除任务方法
  private deleteTask(task: TaskNode) {
    this.uiContext.showAlertDialog({
      title: '确认删除任务',
      message: `确定要删除任务"${task.name}"吗？删除后无法恢复。`,
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消删除
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: ThemeConfig.errorColor,
        action: () => {
          this.onDeleteTask(task.id);
          this.promptAction.showToast({ message: '任务已删除' });
        }
      }
    });
  }
  
  aboutToUpdate() {
    // 当selectedTask变化时，更新selectedTaskForEditor
    if (this.selectedTaskForEditor?.id !== this.selectedTask?.id) {
      console.log(`[Sidebar] selectedTask changed, updating selectedTaskForEditor`);
      this.selectedTaskForEditor = this.selectedTask;
    } else if (this.selectedTask && this.selectedTaskForEditor) {
      // 如果ID相同但内容可能不同，同步更新内容
      this.selectedTaskForEditor = this.selectedTask;
    }
    
    // 当project中的任务数据更新时，同步更新selectedTaskForEditor
    if (this.project && this.selectedTaskForEditor) {
      const updatedTask = this.project.tasks.find(t => t.id === this.selectedTaskForEditor?.id);
      if (updatedTask) {
        const oldChecklistLength = this.selectedTaskForEditor.checklist?.length || 0;
        const newChecklistLength = updatedTask.checklist?.length || 0;
        
        if (oldChecklistLength !== newChecklistLength) {
          console.log(`[Sidebar] Task ${updatedTask.id} checklist updated: ${oldChecklistLength} -> ${newChecklistLength}`);
        }
        
        // 直接更新selectedTaskForEditor，确保数据同步
        this.selectedTaskForEditor = updatedTask;
      }
    }
  }

  onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => void = () => {};
  onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => void = () => {};
  onAddChecklistItem: (taskId: string, text: string) => void = () => {};
  onDeleteChecklistItem: (taskId: string, itemId: string) => void = () => {};
  onUpdateProjectName: (newName: string) => void = () => {};
  onAddTask: () => void = () => {};
  onStartConnecting: () => void = () => {};
  // 新增回调
  onSave: () => void = () => {};
  onBack: () => void = () => {};

  private saveProjectName() {
    if (this.tempProjectName.trim() === '') {
      this.promptAction.showToast({ message: '项目名称不能为空' });
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
              Row({ space: ThemeConfig.spacingS }) {
                Text('＋')
                  .fontSize(ThemeConfig.fontSizeXXL)
                  .fontColor(Color.White)
                  .fontWeight(ThemeConfig.fontWeightMedium)
                Text('新建项目')
                  .fontSize(ThemeConfig.fontSizeL)
                  .fontColor(Color.White)
                  .fontWeight(ThemeConfig.fontWeightMedium)
              }
            }
            .width('100%')
            .height(ThemeConfig.buttonHeightLarge)
            .backgroundColor(ThemeConfig.primaryColor)
            .borderRadius(ThemeConfig.radiusMedium)
            .shadow(ThemeConfig.buttonShadow)
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
              onDeleteChecklistItem: this.onDeleteChecklistItem,
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
              .color($r('sys.color.brand'))
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
      .backgroundColor('rgba(255, 255, 255, 0.7)')
      .padding(ThemeConfig.spacingXXL)
      .shadow(ThemeConfig.shadowMedium)
      .border({ width: { right: 1 }, color: ThemeConfig.gray200 })
      .backdropBlur(20)

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
          // 返回主页按钮 - 现代化设计
          Button() {
            Text('←')
              .fontSize(ThemeConfig.fontSizeXL)
              .fontColor(ThemeConfig.gray600)
              .fontWeight(ThemeConfig.fontWeightBold)
          }
          .width(52)
          .height(52)
          .type(ButtonType.Circle)
          .backgroundColor(ThemeConfig.gray100)
          .borderRadius(26)
          .shadow(ThemeConfig.shadowMedium)
          .border({ width: 2, color: ThemeConfig.gray200, radius: 26 })
          .onClick(() => { this.onBack() })

          // 新建任务按钮（仅编辑页显示）- 现代化设计
          if (!this.isHomePage) {
            Button({ type: ButtonType.Circle }) {
              Text('+')
                .fontSize(ThemeConfig.fontSizeXL)
                .fontColor(Color.White)
                .fontWeight(ThemeConfig.fontWeightBold)
                .shadow({ radius: 1, color: '#00000030', offsetX: 0, offsetY: 1 })
            }
            .width(52)
            .height(52)
            .backgroundColor(ThemeConfig.successColor)
            .borderRadius(26)
            .shadow(ThemeConfig.shadowMedium)
            .border({ width: 2, color: ThemeConfig.successLight, radius: 26 })
            .onClick(() => { this.onAddTask() })
            .margin({ left: 0, right: 0 })
          }

          // 保存项目按钮 - 现代化设计
          Button({ type: ButtonType.Circle }) {
            Text('💾')
              .fontSize(ThemeConfig.fontSizeL)
              .fontColor(Color.White)
          }
          .width(52)
          .height(52)
          .backgroundColor(ThemeConfig.primaryColor)
          .borderRadius(26)
          .shadow(ThemeConfig.shadowMedium)
          .border({ width: 2, color: ThemeConfig.primaryUltraLight, radius: 26 })
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
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
            .backgroundColor('#00000000')
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
            .backgroundColor('#00000000')
            .borderRadius(12)
            .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })
          }
          .width('100%')
        }
        .padding(ThemeConfig.spacingXL)
        .backgroundColor('rgba(255, 255, 255, 0.6)')
        .borderRadius(ThemeConfig.radiusXLarge)
        .shadow(ThemeConfig.cardShadow)
        .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusXLarge })
        .backdropBlur(10)

        // 操作按钮区域
        Column({ space: 16 }) {
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
                      
                      // 子任务信息
                      if (task.checklist && task.checklist.length > 0) {
                        Row({ space: 8 }) {
                          Text(`${task.checklist.filter(item => item.isCompleted).length}/${task.checklist.length} 已完成`)
                            .fontSize(12)
                            .fontColor('#86868B')
                        }
                        .width('100%')
                        .alignItems(VerticalAlign.Center)
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    // 删除按钮 - 现代化设计
                    Button() {
                      Text('×')
                        .fontSize(ThemeConfig.fontSizeL)
                        .fontColor(ThemeConfig.errorColor)
                        .fontWeight(ThemeConfig.fontWeightBold)
                    }
                    .width(36)
                    .height(36)
                    .backgroundColor(ThemeConfig.errorLight)
                    .borderRadius(ThemeConfig.radiusMedium)
                    .shadow(ThemeConfig.shadowSmall)
                    .border({ 
                      width: 2, 
                      color: ThemeConfig.errorColor, 
                      radius: ThemeConfig.radiusMedium 
                    })
                    .onClick(() => {
                      this.deleteTask(task);
                    })

                  }
                  .width('100%')
                  .padding(ThemeConfig.spacingXL)
                  .backgroundColor(this.selectedTask?.id === task.id ? 'rgba(0, 122, 255, 0.2)' : 'rgba(255, 255, 255, 0.5)')
                  .borderRadius(ThemeConfig.radiusMedium)
                  .shadow(this.selectedTask?.id === task.id ? ThemeConfig.shadowMedium : ThemeConfig.shadowSmall)
                  .border({ 
                    width: this.selectedTask?.id === task.id ? 2 : 0, 
                    color: this.selectedTask?.id === task.id ? ThemeConfig.primaryColor : 'transparent', 
                    radius: ThemeConfig.radiusMedium 
                  })
                  .backdropBlur(5)
                  .margin({ bottom: ThemeConfig.spacingS })
                  .onClick(() => {
                    this.selectedTask = task;
                  })
                  .onTouch((event: TouchEvent) => {
                    if (event.type === TouchType.Down) {
                      // 添加按下效果
                    }
                  })
                  .gesture(
                    TapGesture({ count: 1 })
                      .onAction(() => {
                        this.selectedTask = task;
                      })
                  )
                }
              })
            }
            .height('100%')
            .width('100%')
            .layoutWeight(1)
          }
        }
        .layoutWeight(1)
      }
      .alignItems(HorizontalAlign.Start)
    }
  }
}
