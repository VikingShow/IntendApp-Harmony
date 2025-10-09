// File: entry/src/main/ets/pages/Index.ets
/**
 * 项目编辑页面模块
 *
 * 本页面是EasyFlow应用的核心编辑界面，提供项目可视化编辑和任务管理的完整功能。
 * 采用左右分栏布局，左侧为操作面板，右侧为可视化画布，实现直观的项目管理体验。
 *
 * 主要功能：
 * 1. 项目可视化：使用Canvas 2D技术绘制项目网络图和任务节点
 * 2. 任务管理：支持任务的创建、编辑、删除、移动等操作
 * 3. 依赖关系：可视化创建和管理任务间的依赖关系
 * 4. 关键路径：实时计算和显示项目的关键路径
 * 5. 交互操作：支持拖拽、点击、连接等丰富的交互操作
 * 6. 状态管理：维护项目状态和用户操作历史
 *
 * 技术特点：
 * - Canvas 2D渲染：使用HarmonyOS Canvas 2D API实现高性能图形渲染
 * - 响应式设计：基于ArkTS响应式框架实现数据的自动同步
 * - 事件驱动：使用事件总线实现组件间的松耦合通信
 * - 状态管理：通过ProjectManager统一管理项目状态
 * - 权限管理：集成HarmonyOS权限系统确保数据安全
 *
 * 界面布局：
 * - 左侧面板：Sidebar组件，提供项目操作和任务编辑功能
 * - 右侧画布：Canvas组件，显示项目可视化网络图
 * - 顶部控制：画布控制按钮，提供锁定、重置等功能
 * - 响应式布局：支持侧边栏的展开和收起
 *
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-06
 */

import { ProjectManager } from '../core/ProjectManager';
import { CanvasController } from '../core/CanvasController';
import { Sidebar } from '../components/Sidebar';
import { StorageService } from '../services/StorageService';
import { PermissionService } from '../services/PermissionService';
import { TaskNode, Project, ChecklistItem } from '../model/ProjectData';
import { EventBus, EventArgs } from '../core/EventBus';
import common from '@ohos.app.ability.common';
import { PromptAction } from '@kit.ArkUI';
import { CommandHistory } from '../core/CommandHistory';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { AppState } from '../core/AppState';

/**
 * 路由参数接口
 * 定义页面路由传递的参数结构
 */
interface RouterParams {
  /** 项目ID，用于加载指定项目 */
  projectId?: string;
}

@Entry
@Component
struct Index {
  // 页面转场动画配置
  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0.0)
    PageTransitionExit({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0.0)
  }
  // @StorageProp('bottomRectHeight')
  // bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  @State sidebarVisible: boolean = false;
  // 使用@State来响应ProjectManager的状态变化
  @State project: Project | null = null;
  @State selectedTask: TaskNode | null = null;
  private canvasController: CanvasController = new CanvasController();
  private projectManager: ProjectManager = ProjectManager.getInstance();
  private storageService: StorageService | null = null;
  private permissionService: PermissionService | null = null;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  @State canvasLock: boolean = false;
  private commandHistory: CommandHistory = CommandHistory.getInstance();
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;
  private appState: AppState = AppState.getInstance();

  async aboutToAppear() {
    // 初始化权限服务
    this.permissionService = PermissionService.getInstance(this.uiContext.getHostContext() as common.UIAbilityContext);
    // 注入uiContext
    this.permissionService.setContext(this.uiContext);

    // 申请文件系统权限
    const hasPermission = await this.permissionService.requestFileSystemPermission();
    if (!hasPermission) {
      this.promptAction.showToast({
        message: '需要文件系统权限才能保存项目数据，请重新启动应用并授权'
      });
      return;
    }

    // 初始化存储服务
    this.storageService =
      StorageService.getInstance((this.uiContext.getHostContext() as common.UIAbilityContext).filesDir);

    // 初始化项目管理器
    await this.projectManager.initialize((this.uiContext.getHostContext() as common.UIAbilityContext).filesDir);
    // 注入uiContext
    this.projectManager.setContext(this.uiContext);

    // 设置画布控制器回调
    this.canvasController.setCallbacks(
      (task) => this.projectManager.getActions().selectTask(task),
      (fromId, toId) => this.projectManager.getActions().addDependency(fromId, toId),
      (taskId, x, y) => {
        // TouchUp 时调用：创建命令，支持撤销/重做
        this.projectManager.getActions().moveTask(taskId, x, y);
        this.updateUndoRedoState(); // 移动后更新撤销/重做按钮状态
      },
      (taskId, x, y) => {
        // TouchMove 时调用：立即更新位置，不创建命令
        this.projectManager.getActions().moveTaskImmediate(taskId, x, y);
      }
    );
    // 注入uiContext
    this.canvasController.setContext(this.uiContext);

    // 监听ProjectManager状态变化
    this.setupEventListeners();
    this.updateStateFromManager();

    // 初始化撤销/重做按钮状态
    this.updateUndoRedoState();

    // 从路由参数中获取projectId
    const params = this.uiContext.getRouter().getParams() as RouterParams;
    const projectId = params?.projectId;

    console.log(`[EasyFlow] Index.ets aboutToAppear - projectId: ${projectId}`);

    if (projectId) {
      // 如果有ID，则加载现有项目
      console.log(`[EasyFlow] Loading existing project with ID: ${projectId}`);
      await this.projectManager.getActions().loadProject(projectId);
    } else {
      // 如果没有ID，则创建新项目并填充示例数据
      console.log("[EasyFlow] Creating new project with example data.");
      await this.createNewExampleProject();
    }

    // 项目加载完成后恢复画布位置
    this.restoreCanvasPosition();
  }

  aboutToDisappear() {
    // 页面离开时保存画布位置
    this.saveCanvasPosition();
  }

  onPageHide() {
    // 页面隐藏时确保项目数据已保存
    if (this.project && this.projectManager) {
      console.log(`[EasyFlow] Index.ets onPageHide - 确保项目数据已保存: ${this.project.name}`);
      this.projectManager.getActions().saveProject();
    }
  }

  // 设置事件监听器
  private setupEventListeners() {
    const eventBus = EventBus.getInstance();

    // 监听项目加载事件
    eventBus.on('project_loaded', (...args: EventArgs[]) => {
      const project = args[0] as Project;
      this.updateStateFromManager();
      this.updateUndoRedoState();
      this.drawGraph();
      // 项目加载完成后恢复画布位置
      this.restoreCanvasPosition();
    });

    // 监听项目保存事件
    eventBus.on('project_saved', (...args: EventArgs[]) => {
      const project = args[0] as Project;
      this.updateStateFromManager();
      this.updateUndoRedoState();
      this.drawGraph();
    });

    // 监听任务选择事件
    eventBus.on('task_selected', (...args: EventArgs[]) => {
      const task = args[0] as TaskNode | null;
      this.updateStateFromManager();
      this.drawGraph();
    });

    // 监听任务更新事件
    eventBus.on('task_updated', (...args: EventArgs[]) => {
      const task = args[0] as TaskNode;
      this.updateStateFromManager();
      this.updateUndoRedoState();
      this.drawGraph();
    });

    // 监听任务删除事件
    eventBus.on('task_deleted', (...args: EventArgs[]) => {
      const taskId = args[0] as string;
      this.updateStateFromManager();
      this.updateUndoRedoState();
      this.drawGraph();
    });

    // 监听关键路径计算事件
    eventBus.on('critical_path_calculated', (...args: EventArgs[]) => {
      const project = args[0] as Project;
      this.updateStateFromManager();
      this.drawGraph();
    });
  }

  // 更新状态的方法
  private updateStateFromManager() {
    const state = this.projectManager.getState();
    // 直接赋值，依赖@State的响应式机制
    this.project = state.project;
    this.selectedTask = state.selectedTask;
  }

  // 保存画布位置
  private saveCanvasPosition() {
    const canvasState = this.canvasController.getState();
    this.appState.setCanvasOffset(canvasState.canvasOffsetX, canvasState.canvasOffsetY);
    console.log(`[EasyFlow] 保存画布位置: x=${canvasState.canvasOffsetX}, y=${canvasState.canvasOffsetY}`);
  }

  // 恢复画布位置
  private restoreCanvasPosition() {
    const savedOffsetX = this.appState.canvasOffsetX;
    const savedOffsetY = this.appState.canvasOffsetY;

    // 设置到CanvasController
    this.canvasController.setCanvasOffset(savedOffsetX, savedOffsetY);
    console.log(`[EasyFlow] 恢复画布位置: x=${savedOffsetX}, y=${savedOffsetY}`);
  }

  // 创建示例项目
  async createNewExampleProject(): Promise<void> {
    await this.projectManager.getActions().createNewProject('新移动应用开发计划');

    const project = this.projectManager.getState().project;
    if (!project) {
      return;
    }

    const today = new Date();

    const task1: TaskNode = {
      id: 'task_1',
      name: '需求分析与原型设计',
      startDate: today,
      endDate: new Date(today.getTime() + 4 * 24 * 60 * 60 * 1000),
      checklist: [
        { id: 'c1_1', text: '收集用户反馈', isCompleted: true },
        { id: 'c1_2', text: '绘制线框图', isCompleted: true },
        { id: 'c1_3', text: '制作交互原型', isCompleted: false },
      ],
      x: 50,
      y: 150
    };

    const task2: TaskNode = {
      id: 'task_2',
      name: 'UI/UX视觉设计',
      startDate: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 9 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 350,
      y: 50
    };

    const task3: TaskNode = {
      id: 'task_3',
      name: '前端开发',
      startDate: new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 19 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 650,
      y: 150
    };

    const task4: TaskNode = {
      id: 'task_4',
      name: '后端开发',
      startDate: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 16 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 350,
      y: 250
    };

    const task5: TaskNode = {
      id: 'task_5',
      name: '测试与部署',
      startDate: new Date(today.getTime() + 20 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 24 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 950,
      y: 150
    };

    project.tasks = [task1, task2, task3, task4, task5];
    project.dependencies = [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_1', toId: 'task_4' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_4', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_5' }
    ];

    this.projectManager.getActions().calculateCriticalPath();
    await this.projectManager.getActions().saveProject();
    this.updateStateFromManager();
  }

  // 渲染画布
  private drawGraph(): void {
    const renderConfig = this.canvasController.getActions().getRenderConfig(
      this.selectedTask?.id || null
    );

    if (this.project) {
      this.canvasController.getRenderer().render(this.project, renderConfig);
    }
  }

  // 处理开始连接
  private handleStartConnecting(): void {
    if (this.selectedTask) {
      this.canvasController.getActions().startConnecting(this.selectedTask.id);
      this.drawGraph();
    }
  }

  // 处理返回主页
  private handleBackToHome(): void {
    this.uiContext.getRouter().back();
  }

  // 更新撤销/重做按钮状态
  private updateUndoRedoState(): void {
    this.canUndo = this.commandHistory.canUndo();
    this.canRedo = this.commandHistory.canRedo();
  }

  // 画布背景构建器 - 白色背景灰色网格
  @Builder
  CanvasBackground() {
    Stack() {
      // 白色背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)

      // 网格线层
      Column() {
        // 主要网格线 - 粗线
        Stack() {
          // 垂直线
          ForEach(Array.from({ length: 8 }), (verticalItem: number, index: number) => {
            Line()
              .startPoint([index * 200, 0])
              .endPoint([index * 200, '100%'])
              .stroke(ColorResource.canvasGridLine)
              .strokeWidth(1)
          })

          // 水平线
          ForEach(Array.from({ length: 6 }), (horizontalItem: number, index: number) => {
            Line()
              .startPoint([0, index * 200])
              .endPoint(['100%', index * 200])
              .stroke(ColorResource.canvasGridLine)
              .strokeWidth(1)
          })
        }
        .width('100%')
        .height('100%')

        // 细网格线 - 细线
        Stack() {
          // 细垂直线
          ForEach(Array.from({ length: 16 }), (thinVerticalItem: number, index: number) => {
            Line()
              .startPoint([index * 100, 0])
              .endPoint([index * 100, '100%'])
              .stroke(ColorResource.canvasGridLineFine)
              .strokeWidth(0.5)
          })

          // 细水平线
          ForEach(Array.from({ length: 12 }), (thinHorizontalItem: number, index: number) => {
            Line()
              .startPoint([0, index * 100])
              .endPoint(['100%', index * 100])
              .stroke(ColorResource.canvasGridLineFine)
              .strokeWidth(0.5)
          })
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .borderRadius(12)
    .margin({
      top: 16,
      right: 16,
      bottom: 16,
      left: 0
    })
    .shadow({
      radius: 8,
      color: ColorResource.shadowColorSubtle,
      offsetX: 0,
      offsetY: 2
    })
  }

  build() {
    Stack() {
      // 展开/收起按钮 - 固定在左侧中间
      Button() {
        Text(this.sidebarVisible ? '<' : '>')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorResource.surfaceDark)
      }
      .width(32)
      .height(48)
      .backgroundColor(ColorResource.overlayStrong)
      .borderRadius(8)
      .position({ x: 16, y: '50%' })
      .translate({ x: 0, y: -24 })
      .zIndex(200)
      .backdropBlur(ThemeConfig.backdropBlurMedium)
      .border({ width: 1, color: ColorResource.shadowColorSubtle, radius: 8 })
      .onClick(() => {
        this.sidebarVisible = !this.sidebarVisible
      })

      // 侧边栏
      if (this.sidebarVisible) {
        Sidebar({
          project: this.project,
          selectedTask: this.selectedTask,
          isHomePage: false,
          onUpdateProjectName: (newName) => {
            this.projectManager.getActions().updateProjectName(newName);
          },
          onAddTask: () => {
            this.projectManager.getActions().addTask();
          },
          onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => {
            this.projectManager.getActions().updateTask(taskId, updates);
          },
          onUpdateChecklist: (taskId, checklist) => {
            this.projectManager.getActions().updateChecklist(taskId, checklist);
          },
          onAddChecklistItem: (taskId, text) => {
            const newItem: ChecklistItem = {
              id: `item_${Date.now()}`,
              text: text,
              isCompleted: false
            };
            this.projectManager.getActions().addChecklistItem(taskId, newItem);
          },
          onDeleteChecklistItem: (taskId, itemId) => {
            this.projectManager.getActions().deleteChecklistItem(taskId, itemId);
          },
          onDeleteTask: (id) => {
            this.projectManager.getActions().deleteTask(id);
          },
          onStartConnecting: () => this.handleStartConnecting(),
          onSave: () => this.projectManager.getActions().saveProject(),
          onBack: () => this.handleBackToHome(),
          onCreateBlankProject: () => this.projectManager.getActions().createNewProject(),
          onCreateProjectFromTemplate: (templateId, projectName) =>
          this.projectManager.getActions().createFromTemplate(templateId, projectName)
        })
          .width(380)
          .height('100%')
          .position({ x: 0, y: 0 })
          .zIndex(150)
      }

      // 画布
      Stack() {
        // 画布背景 - 格子纹效果
        this.CanvasBackground()

        Canvas(this.canvasController.getRenderer().getContext())
          .height('100%')
          .width('100%')
          .backgroundColor(Color.Transparent)
          .borderRadius(12)
          .margin({
            top: 16,
            right: 16,
            bottom: 16,
            left: 16
          })
          .onReady(() => {
            this.drawGraph(); // 绘制图形（包含网格）
            // Canvas准备就绪后恢复画布位置
            setTimeout(() => {
              this.restoreCanvasPosition();
            }, 100);
          })
          .onTouch((event: TouchEvent) => {
            if (!this.project) {
              return;
            }

            this.canvasController.getActions().handleTouch(
              event,
              this.project,
              this.selectedTask?.id || null
            );
            this.drawGraph(); // 重新绘制图形（包含网格）
          })

        // 右上角控制按钮
        Column() {
          Row() {
            // 撤销按钮 - 现代化设计
            Button() {
              Text('↶ 撤销')
                .fontSize(13)
                .fontColor(this.canUndo ? ColorResource.errorColor : ColorResource.surfaceStrong)
                .fontWeight(ThemeConfig.fontWeightMedium)
            }
            .width(75)
            .height(36)
            .backgroundColor(this.canUndo ? ColorResource.errorLight : ColorResource.surfaceLight)
            .borderRadius(ThemeConfig.radiusMedium)
            .border({
              width: 2,
              color: this.canUndo ? ColorResource.errorColor : ColorResource.surfaceNeutral,
              radius: ThemeConfig.radiusMedium
            })
            .shadow(ThemeConfig.shadowMedium)
            .margin({ right: 12, top: 12 })
            .enabled(this.canUndo)
            .opacity(this.canUndo ? 1 : 0.6)
            .onClick(() => {
              if (this.commandHistory.undo()) {
                // 更新按钮状态
                this.updateUndoRedoState();
                // 刷新状态和画布
                this.updateStateFromManager();
                this.drawGraph();
                // 重新计算关键路径
                this.projectManager.getActions().calculateCriticalPath();
                // 显示提示
                const commandName = this.commandHistory.getLastRedoCommandName();
                this.promptAction.showToast({
                  message: commandName ? `已撤销: ${commandName}` : '已撤销',
                  duration: 1500
                });
              }
            })

            // 重做按钮 - 现代化设计
            Button() {
              Text('↷ 重做')
                .fontSize(13)
                .fontColor(this.canRedo ? ColorResource.primaryColor : ColorResource.surfaceStrong)
                .fontWeight(ThemeConfig.fontWeightMedium)
            }
            .width(75)
            .height(36)
            .backgroundColor(this.canRedo ? ColorResource.primaryUltraLight : ColorResource.surfaceLight)
            .borderRadius(ThemeConfig.radiusMedium)
            .border({
              width: 2,
              color: this.canRedo ? ColorResource.primaryColor : ColorResource.surfaceNeutral,
              radius: ThemeConfig.radiusMedium
            })
            .shadow(ThemeConfig.shadowMedium)
            .margin({ right: 12, top: 12 })
            .enabled(this.canRedo)
            .opacity(this.canRedo ? 1 : 0.6)
            .onClick(() => {
              if (this.commandHistory.redo()) {
                // 更新按钮状态
                this.updateUndoRedoState();
                // 刷新状态和画布
                this.updateStateFromManager();
                this.drawGraph();
                // 重新计算关键路径
                this.projectManager.getActions().calculateCriticalPath();
                // 显示提示
                const commandName = this.commandHistory.getLastUndoCommandName();
                this.promptAction.showToast({
                  message: commandName ? `已重做: ${commandName}` : '已重做',
                  duration: 1500
                });
              }
            })

            Button() {
              Text(this.canvasLock ? '🔓 解锁' : '🔒 锁定')
                .fontSize(13)
                .fontColor(ColorResource.primaryColor)
                .fontWeight(ThemeConfig.fontWeightMedium)
            }
            .width(75)
            .height(36)
            .backgroundColor(ColorResource.primaryUltraLight)
            .borderRadius(ThemeConfig.radiusMedium)
            .border({ width: 2, color: ColorResource.primaryColor, radius: ThemeConfig.radiusMedium })
            .shadow(ThemeConfig.shadowMedium)
            .margin({ right: 12, top: 12 })
            .onClick(() => {
              this.canvasController.getActions().toggleCanvasLock();
              this.canvasLock = !this.canvasLock
              // this.canvasController.getState().isCanvasLocked = !(this.canvasController.getState().isCanvasLocked);
            })

            Button() {
              Text('🔄 复原')
                .fontSize(13)
                .fontColor(ColorResource.successColor)
                .fontWeight(ThemeConfig.fontWeightMedium)
            }
            .width(70)
            .height(36)
            .backgroundColor(ColorResource.successLight)
            .borderRadius(ThemeConfig.radiusMedium)
            .border({ width: 2, color: ColorResource.successColor, radius: ThemeConfig.radiusMedium })
            .shadow(ThemeConfig.shadowMedium)
            .margin({ right: 12, top: 12 })
            .onClick(() => {
              this.canvasController.getActions().resetCanvas();
              this.drawGraph();
            })
          }
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .position({ x: 0, y: 0 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      // bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
  }
}