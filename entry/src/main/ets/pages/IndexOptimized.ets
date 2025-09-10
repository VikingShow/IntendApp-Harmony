// File: entry/src/main/ets/pages/IndexOptimized.ets

import router from '@ohos.router';
import { ProjectManager } from '../core/ProjectManager';
import { CanvasController } from '../core/CanvasController';
import { AppState } from '../core/AppState';
import { ServiceContainer } from '../core/ServiceContainer';
import { ErrorHandler } from '../core/ErrorHandler';
import { PerformanceService } from '../services/PerformanceService';
import { ProjectHeader } from '../components/ProjectHeader';
import { TaskList } from '../components/TaskList';
import { ActionButtons } from '../components/ActionButtons';
import { TaskEditor } from '../components/TaskEditor';
import { TaskNode, ChecklistItem, Project } from '../model/ProjectData';
import { EventBus, Events, EventArgs } from '../core/EventBus';
import common from '@ohos.app.ability.common';

// 定义路由参数接口
interface RouterParams {
  projectId?: string;
}

// 定义性能记录数据接口
interface ProjectIdData extends Record<string, string | number | boolean> {
  projectId: string;
}

interface TaskIdData extends Record<string, string | number | boolean> {
  taskId: string;
}

interface ProjectNameData extends Record<string, string | number | boolean> {
  newName: string;
}

@Entry
@Component
struct IndexOptimized {
  @State private projectManager: ProjectManager = ProjectManager.getInstance();
  @State private canvasController: CanvasController = new CanvasController();
  @State private appState: AppState = AppState.getInstance();
  @State private performanceService: PerformanceService = PerformanceService.getInstance();
  @State private errorHandler: ErrorHandler = ErrorHandler.getInstance();
  @State private selectedTaskForEditor: TaskNode | null = null;

  async aboutToAppear() {
    // 记录页面加载开始时间
    const loadStartTime = Date.now();
    
    try {
      // 初始化服务容器
      const context = getContext(this);
      await this.projectManager.initialize(context.filesDir);
      
      // 设置画布控制器回调
      this.canvasController.setCallbacks(
        (task) => this.projectManager.getActions().selectTask(task),
        (fromId, toId) => this.projectManager.getActions().addDependency(fromId, toId),
        (taskId, x, y) => this.projectManager.getActions().moveTask(taskId, x, y)
      );

      // 监听事件
      this.setupEventListeners();

      // 从路由参数中获取projectId
      const params = router.getParams() as RouterParams;
      const projectId = params?.projectId;

      console.log(`[IndexOptimized] aboutToAppear - projectId: ${projectId}`);

      if (projectId) {
        // 记录用户行为
        const projectIdData: ProjectIdData = { projectId: projectId };
        this.performanceService.recordUserAction('load_existing_project', 'IndexOptimized', projectIdData);
        
        // 加载现有项目
        console.log(`[IndexOptimized] Loading existing project with ID: ${projectId}`);
        await this.projectManager.getActions().loadProject(projectId);
      } else {
        // 记录用户行为
        this.performanceService.recordUserAction('create_new_project', 'IndexOptimized');
        
        // 创建新项目并填充示例数据
        console.log("[IndexOptimized] Creating new project with example data.");
        await this.createNewExampleProject();
      }

      // 记录页面加载时间
      const loadDuration = Date.now() - loadStartTime;
      this.performanceService.recordMetric('page_load_time', loadDuration, 'ms');

    } catch (error) {
      this.errorHandler.handle(error as Error, 'IndexOptimized.aboutToAppear');
    }
  }

  aboutToDisappear() {
    // 清理资源
    this.projectManager.cleanup();
    this.performanceService.recordUserAction('page_leave', 'IndexOptimized');
  }

  // 设置事件监听器
  private setupEventListeners() {
    const eventBus = EventBus.getInstance();
    
    // 监听项目加载事件
    eventBus.on(Events.PROJECT_LOADED, (...args: EventArgs[]) => {
      const project = args[0] as Project;
      this.updateStateFromManager();
      this.drawGraph();
      const projectIdData: ProjectIdData = { projectId: project.id };
      this.performanceService.recordUserAction('project_loaded', 'IndexOptimized', projectIdData);
    });
    
    // 监听项目保存事件
    eventBus.on(Events.PROJECT_SAVED, (...args: EventArgs[]) => {
      const project = args[0] as Project;
      this.updateStateFromManager();
      this.drawGraph();
      const projectIdData: ProjectIdData = { projectId: project.id };
      this.performanceService.recordUserAction('project_saved', 'IndexOptimized', projectIdData);
    });
    
    // 监听任务选择事件
    eventBus.on(Events.TASK_SELECTED, (...args: EventArgs[]) => {
      const task = args[0] as TaskNode | null;
      this.updateStateFromManager();
      this.drawGraph();
      const taskIdData: TaskIdData = { taskId: task?.id || '' };
      this.performanceService.recordUserAction('task_selected', 'IndexOptimized', taskIdData);
    });
    
    // 监听任务更新事件
    eventBus.on(Events.TASK_UPDATED, (...args: EventArgs[]) => {
      const task = args[0] as TaskNode;
      this.updateStateFromManager();
      this.drawGraph();
      const taskIdData: TaskIdData = { taskId: task.id };
      this.performanceService.recordUserAction('task_updated', 'IndexOptimized', taskIdData);
    });
    
    // 监听任务删除事件
    eventBus.on(Events.TASK_DELETED, (...args: EventArgs[]) => {
      const taskId = args[0] as string;
      this.updateStateFromManager();
      this.drawGraph();
      const taskIdData: TaskIdData = { taskId: taskId };
      this.performanceService.recordUserAction('task_deleted', 'IndexOptimized', taskIdData);
    });
    
    // 监听关键路径计算事件
    eventBus.on(Events.CRITICAL_PATH_CALCULATED, (...args: EventArgs[]) => {
      const project = args[0] as Project;
      this.updateStateFromManager();
      this.drawGraph();
      const projectIdData: ProjectIdData = { projectId: project.id };
      this.performanceService.recordUserAction('critical_path_calculated', 'IndexOptimized', projectIdData);
    });
  }

  // 更新状态的方法
  private updateStateFromManager() {
    const state = this.projectManager.getState();
    this.appState.setProject(state.project);
    this.appState.setSelectedTask(state.selectedTask);
    
    // 更新编辑器任务
    if (this.selectedTaskForEditor?.id !== state.selectedTask?.id) {
      this.selectedTaskForEditor = state.selectedTask;
    }
  }

  // 创建示例项目
  async createNewExampleProject(): Promise<void> {
    const startTime = Date.now();
    
    try {
      await this.projectManager.getActions().createNewProject('新移动应用开发计划');
      
      const project = this.appState.project;
      if (!project) return;

      const today = new Date();

      const task1: TaskNode = {
        id: 'task_1', name: '需求分析与原型设计',
        startDate: today,
        endDate: new Date(today.getTime() + 4 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '收集用户反馈', isCompleted: true },
          { id: 'c1_2', text: '绘制线框图', isCompleted: true },
          { id: 'c1_3', text: '制作交互原型', isCompleted: false },
        ],
        x: 50, y: 150
      };

      const task2: TaskNode = {
        id: 'task_2', name: 'UI/UX视觉设计',
        startDate: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
        endDate: new Date(today.getTime() + 9 * 24 * 60 * 60 * 1000),
        checklist: [],
        x: 350, y: 50
      };

      const task3: TaskNode = {
        id: 'task_3', name: '前端开发',
        startDate: new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000),
        endDate: new Date(today.getTime() + 19 * 24 * 60 * 60 * 1000),
        checklist: [],
        x: 650, y: 150
      };

      const task4: TaskNode = {
        id: 'task_4', name: '后端开发',
        startDate: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
        endDate: new Date(today.getTime() + 16 * 24 * 60 * 60 * 1000),
        checklist: [],
        x: 350, y: 250
      };

      const task5: TaskNode = {
        id: 'task_5', name: '测试与部署',
        startDate: new Date(today.getTime() + 20 * 24 * 60 * 60 * 1000),
        endDate: new Date(today.getTime() + 24 * 24 * 60 * 60 * 1000),
        checklist: [],
        x: 950, y: 150
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

      // 记录创建项目时间
      const duration = Date.now() - startTime;
      this.performanceService.recordMetric('create_example_project_time', duration, 'ms');

    } catch (error) {
      this.errorHandler.handle(error as Error, 'IndexOptimized.createNewExampleProject');
    }
  }

  // 渲染画布
  private drawGraph(): void {
    const renderStartTime = Date.now();
    
    try {
      const renderConfig = this.canvasController.getActions().getRenderConfig(
        this.appState.selectedTask?.id || null
      );
      
      if (this.appState.project) {
        this.canvasController.getRenderer().render(this.appState.project, renderConfig);
      }

      // 记录渲染时间
      const renderDuration = Date.now() - renderStartTime;
      this.performanceService.recordMetric('canvas_render_time', renderDuration, 'ms');

    } catch (error) {
      this.errorHandler.handle(error as Error, 'IndexOptimized.drawGraph');
    }
  }

  // 处理开始连接
  private handleStartConnecting(): void {
    if (this.appState.selectedTask) {
      this.canvasController.getActions().startConnecting(this.appState.selectedTask.id);
      this.drawGraph();
      const taskIdData: TaskIdData = { taskId: this.appState.selectedTask.id };
      this.performanceService.recordUserAction('start_connecting', 'IndexOptimized', taskIdData);
    }
  }

  // 处理返回主页
  private handleBackToHome(): void {
    this.performanceService.recordUserAction('back_to_home', 'IndexOptimized');
    router.back();
  }

  build() {
    Row() {
      // 展开/收起按钮
      Button() {
        Text(this.appState.sidebarVisible ? '<' : '>')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(48)
      .backgroundColor('#F3F4F6')
      .borderRadius(8)
      .margin({ left: 0, right: 0, top: 24, bottom: 24 })
      .zIndex(100)
      .onClick(() => { 
        this.appState.toggleSidebar();
        this.performanceService.recordUserAction('toggle_sidebar', 'IndexOptimized');
      })

      // 侧边栏
      if (this.appState.sidebarVisible) {
        Column() {
          if (this.appState.project) {
            if (this.selectedTaskForEditor === null) {
              // 项目视图
              Column({ space: 16 }) {
                // 项目头部
                ProjectHeader({
                  project: this.appState.project,
                  onUpdateProjectName: (newName) => {
                    this.projectManager.getActions().updateProjectName(newName);
                    const projectNameData: ProjectNameData = { newName: newName };
                    this.performanceService.recordUserAction('update_project_name', 'IndexOptimized', projectNameData);
                  }
                })

                // 操作按钮
                ActionButtons({
                  onAddTask: () => {
                    this.projectManager.getActions().addTask();
                    this.performanceService.recordUserAction('add_task', 'IndexOptimized');
                  },
                  onCalculate: () => {
                    this.projectManager.getActions().calculateCriticalPath();
                    this.performanceService.recordUserAction('calculate_critical_path', 'IndexOptimized');
                  },
                  onSave: () => {
                    this.projectManager.getActions().saveProject();
                    this.performanceService.recordUserAction('save_project', 'IndexOptimized');
                  },
                  onBack: () => this.handleBackToHome(),
                  onStartConnecting: () => this.handleStartConnecting()
                })

                // 任务列表
                TaskList({
                  project: this.appState.project,
                  selectedTask: this.appState.selectedTask,
                  onTaskSelect: (task) => {
                    this.projectManager.getActions().selectTask(task);
                    const taskIdData: TaskIdData = { taskId: task.id };
                    this.performanceService.recordUserAction('select_task', 'IndexOptimized', taskIdData);
                  }
                })
              }
              .layoutWeight(1)
            } else {
              // 任务编辑器
              TaskEditor({
                task: this.selectedTaskForEditor,
                onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => {
                  this.projectManager.getActions().updateTask(taskId, updates);
                  const taskIdData: TaskIdData = { taskId: taskId };
                  this.performanceService.recordUserAction('update_task', 'IndexOptimized', taskIdData);
                },
                onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => {
                  this.projectManager.getActions().updateChecklist(taskId, checklist);
                  const taskIdData: TaskIdData = { taskId: taskId };
                  this.performanceService.recordUserAction('update_checklist', 'IndexOptimized', taskIdData);
                },
                onAddChecklistItem: (taskId: string, text: string) => {
                  const newItem: ChecklistItem = {
                    id: `item_${Date.now()}`,
                    text: text,
                    isCompleted: false
                  };
                  this.projectManager.getActions().addChecklistItem(taskId, newItem);
                  const taskIdData: TaskIdData = { taskId: taskId };
                  this.performanceService.recordUserAction('add_checklist_item', 'IndexOptimized', taskIdData);
                },
                onDeleteTask: (id: string) => {
                  this.projectManager.getActions().deleteTask(id);
                  const taskIdData: TaskIdData = { taskId: id };
                  this.performanceService.recordUserAction('delete_task', 'IndexOptimized', taskIdData);
                },
                onStartConnecting: () => this.handleStartConnecting(),
                onBack: () => {
                  this.selectedTaskForEditor = null;
                  this.performanceService.recordUserAction('back_to_task_list', 'IndexOptimized');
                }
              })
            }
          } else {
            // 加载中状态
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
        .width(380)
        .height('100%')
        .backgroundColor('#F5F5F7')
        .padding(24)
      }

      // 画布
      Stack() {
        Canvas(this.canvasController.getRenderer().getContext())
          .height('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 16, right: 16, bottom: 16, left: 0 })
          .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })
          .onReady(() => { this.drawGraph(); })
          .onTouch((event: TouchEvent) => {
            if (!this.appState.project) return;
            
            this.canvasController.getActions().handleTouch(
              event, 
              this.appState.project, 
              this.appState.selectedTask?.id || null
            );
            this.drawGraph();
          })

        // 右上角控制按钮
        Column() {
          Row() {
            Button() {
              Text(this.appState.isCanvasLocked ? '解锁画布' : '锁定画布')
                .fontSize(13)
                .fontColor('#007DFF')
            }
            .width(80)
            .height(32)
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .margin({ right: 12, top: 12 })
            .onClick(() => { 
              this.appState.toggleCanvasLock();
              this.performanceService.recordUserAction('toggle_canvas_lock', 'IndexOptimized');
            })

            Button() {
              Text('复原')
                .fontSize(13)
                .fontColor('#10B981')
            }
            .width(60)
            .height(32)
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .margin({ right: 12, top: 12 })
            .onClick(() => { 
              this.appState.resetCanvas();
              this.drawGraph();
              this.performanceService.recordUserAction('reset_canvas', 'IndexOptimized');
            })
          }
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .position({ x: 0, y: 0 })
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
