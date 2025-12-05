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
import { CanvasController } from '../core/canvas/CanvasController';
import { RenderMode } from '../core/canvas/CanvasRenderer';
import { Sidebar } from '../components/Sidebar';
import { StorageService } from '../services/StorageService';
import { PermissionService } from '../services/PermissionService';
import { ExportService } from '../services/ExportService';
import { FileStorageService } from '../services/FileStorageService';
import { TaskNode, Project, ChecklistItem } from '../model/ProjectData';
import { EventBus, EventArgs } from '../core/EventBus';
import common from '@ohos.app.ability.common';
import { PromptAction } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import { CommandHistory } from '../core/CommandHistory';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { AppState } from '../core/AppState';
import { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { BreakpointSystem } from '../utils/BreakpointSystem';
import { PerformanceService } from '../services/PerformanceService';
import { CalendarService } from '../services/CalendarService';

/**
 * 路由参数接口
 * 定义页面路由传递的参数结构
 */
interface RouterParams {
  /** 项目ID，用于加载指定项目 */
  projectId?: string;
  /** 渲染模式（从Dashboard传递，避免模式切换闪烁） */
  renderMode?: string;
  /** 是否为手机端（从Dashboard传递） */
  isPhone?: boolean;
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
  private exportService: ExportService | null = null;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  @State canvasLock: boolean = false;
  private commandHistory: CommandHistory = CommandHistory.getInstance();
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;
  private appState: AppState = AppState.getInstance();
  private configCallbackId: number = -1;
  @State isDarkMode: boolean = false;
  private performanceService: PerformanceService = PerformanceService.getInstance();
  private calendarService: CalendarService = CalendarService.getInstance();
  
  // 工具栏状态
  @State toolbarExpanded: boolean = false;  // 工具栏是否展开
  @State toolbarHoverIndex: number = -1;     // 当前悬停的按钮索引
  @State zoomPanelExpanded: boolean = false; // 缩放面板是否展开
  
  // 响应式布局相关状态
  @State screenWidth: number = 0;
  @State isPhone: boolean = false;
  
  // 画布渲染模式
  @State canvasRenderMode: RenderMode = RenderMode.NORMAL;
  
  // 画布缩放比例
  @State zoomScale: number = 1.0;
  
  // 画布透明度（用于避免闪烁）
  @State canvasOpacity: number = 0;
  
  // 渲染节流相关
  private isRendering: boolean = false;
  private pendingRender: boolean = false;
  private lastRenderTime: number = 0;
  private readonly RENDER_THROTTLE_MS: number = 16; // 约60fps
  
  // 滑块拖动相关
  private sliderDragging: boolean = false;
  private lastSliderPosition: number = 0;
  
  // 防抖保存定时器
  private saveTimer: number = -1;
  private readonly SAVE_DEBOUNCE_MS: number = 800; // 增加到800ms，减少保存频率
  
  // 缩放控制UI状态
  @State zoomControlExpanded: boolean = false; // 是否展开
  @State zoomControlOpacity: number = 0.3; // 透明度
  private zoomControlHideTimer: number = -1; // 自动隐藏定时器

  async aboutToAppear() {
    // 从路由参数中提前获取renderMode信息（用于避免模式切换闪烁）
    const routeParams = this.uiContext.getRouter().getParams() as RouterParams;
    const renderModeFromDashboard = routeParams?.renderMode;
    console.log(`[Index] aboutToAppear - renderMode from Dashboard: ${renderModeFromDashboard || 'not provided'}`);
    
    // 初始化屏幕尺寸和设备类型
    this.updateScreenSize();
    
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

    // 初始化导出服务
    const fileStorageService = FileStorageService.getInstance((this.uiContext.getHostContext() as common.UIAbilityContext).filesDir);
    this.exportService = ExportService.getInstance(fileStorageService);
    this.exportService.setContext(this.uiContext.getHostContext() as common.UIAbilityContext);

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
    
    // 先同步获取屏幕宽度并设置 isPhone（确保渲染模式正确）
    const windowStage = (this.uiContext.getHostContext() as common.UIAbilityContext)?.windowStage;
    if (windowStage) {
      try {
        const window = await windowStage.getMainWindow();
        const properties = window.getWindowProperties();
        const widthPx = properties.windowRect.width;
        this.screenWidth = this.uiContext.px2vp(widthPx);
        this.isPhone = BreakpointSystem.isPhone(this.screenWidth);
        console.log(`[Index] Initial screen size: ${this.screenWidth}vp, isPhone: ${this.isPhone}`);
      } catch (error) {
        console.error('[Index] Failed to get initial window size:', error);
        this.screenWidth = 840;
        this.isPhone = false;
      }
    } else {
      this.screenWidth = 840;
      this.isPhone = false;
    }
    
    // 根据设备类型设置渲染模式（手机端使用缩略模式）
    // 如果从Dashboard跳转过来，已经确定了正确的renderMode，无需切换
    const targetRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
    this.canvasRenderMode = targetRenderMode;
    this.canvasController.setRenderMode(targetRenderMode);
    console.log(`[Index] aboutToAppear - screenWidth: ${this.screenWidth}, isPhone: ${this.isPhone}, setting renderMode to: ${targetRenderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'} (from Dashboard: ${renderModeFromDashboard || 'not provided'})`);
    console.log(`[Index] aboutToAppear - canvasController.state.renderMode: ${this.canvasController.getState().renderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);

    // 初始化主题监听器
    this.setupThemeListener();

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
      // 项目加载完成后立即恢复画布位置，确保 Canvas onReady 时使用正确状态
      this.restoreCanvasPosition();
      // 延迟一帧确保状态完全生效
      await new Promise<void>(resolve => setTimeout(resolve, 0));
    } else {
      // 如果没有ID，则创建新项目并填充示例数据
      console.log("[EasyFlow] Creating new project with example data.");
      await this.createNewExampleProject();
      // 项目创建完成后立即恢复画布位置
      this.restoreCanvasPosition();
    }
  }

  aboutToDisappear() {
    // 重置画布透明度
    this.canvasOpacity = 0;
    
    // 清理防抖定时器
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
      this.saveTimer = -1;
    }
    
    // 清理缩放控制自动隐藏定时器
    if (this.zoomControlHideTimer !== -1) {
      clearTimeout(this.zoomControlHideTimer);
      this.zoomControlHideTimer = -1;
    }
    
    // 页面离开时立即保存画布位置
    this.saveCanvasPosition();
    
    // 性能监控：输出统计信息
    const stats = this.performanceService.getPerformanceStats();
    console.log('[Performance] 页面性能统计:', {
      "总指标数": stats.totalMetrics,
      "总行为数": stats.totalActions,
      "平均指标": stats.averageMetrics
    });

    // 取消主题监听
    if (this.configCallbackId !== -1) {
      try {
        const context = this.uiContext.getHostContext() as common.UIAbilityContext;
        const appContext = context.getApplicationContext();
        appContext.off('environment', this.configCallbackId);
      } catch (error) {
        console.error('[EasyFlow] Failed to unregister theme listener:', error);
      }
    }
  }

  onPageHide() {
    // 页面隐藏时确保项目数据已保存
    if (this.project && this.projectManager) {
      console.log(`[EasyFlow] Index.ets onPageHide - 确保项目数据已保存: ${this.project.name}`);
      this.projectManager.getActions().saveProject();
    }
  }

  // 设置主题监听器
  private setupThemeListener() {
    try {
      const context = this.uiContext.getHostContext() as common.UIAbilityContext;
      const appContext = context.getApplicationContext();

      // 初始获取当前模式 - 从UIAbilityContext获取配置
      const currentConfig: Configuration = context.config;
      this.updateColorMode(currentConfig);

      // 监听环境变化（包括主题变化）- 使用正确的回调接口
      this.configCallbackId = appContext.on('environment', {
        onConfigurationUpdated: (config: Configuration) => {
          this.updateColorMode(config);
        },
        onMemoryLevel: () => {
          // 内存级别变化的处理，可以为空实现
        }
      });
    } catch (error) {
      console.error('[EasyFlow] Failed to setup theme listener:', error);
    }
  }

  // 更新颜色模式
  private updateColorMode(config: Configuration) {
    const wasDarkMode = this.isDarkMode;
    this.isDarkMode = (config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);

    // 更新CanvasRenderer的深色模式状态
    this.canvasController.getRenderer().setDarkMode(this.isDarkMode);

    // 如果模式发生变化，触发画布重绘
    if (wasDarkMode !== this.isDarkMode && this.project) {
      this.drawGraph();
    }

    console.log(`[EasyFlow] Color mode updated: ${this.isDarkMode ? 'Dark' : 'Light'}`);
  }

  // 更新屏幕尺寸和设备类型
  private updateScreenSize() {
    // 使用窗口管理器获取屏幕宽度
    const windowStage = (this.uiContext.getHostContext() as common.UIAbilityContext)?.windowStage;
    if (windowStage) {
      windowStage.getMainWindow().then(window => {
        const properties = window.getWindowProperties();
        const widthPx = properties.windowRect.width;
        // 转换为vp
        this.screenWidth = this.uiContext.px2vp(widthPx);
        this.isPhone = BreakpointSystem.isPhone(this.screenWidth);
        
        console.log(`[Index] Screen size: ${this.screenWidth}vp, isPhone: ${this.isPhone}`);
      }).catch((error: Error) => {
        console.error('[Index] Failed to get window size:', error);
        // 使用默认平板宽度
        this.screenWidth = 840;
        this.isPhone = false;
      });
    } else {
      // 使用默认平板宽度
      this.screenWidth = 840;
      this.isPhone = false;
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
      // 确保渲染模式正确设置（直接基于 isPhone 判断，避免 @State 异步更新问题）
      const correctRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
      this.canvasRenderMode = correctRenderMode;
      this.canvasController.setRenderMode(correctRenderMode);
      console.log(`[Index] project_loaded - setting renderMode to: ${correctRenderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);
      // 画布位置已在 aboutToAppear 中恢复，这里只需要清除缓存并重新渲染
      this.canvasController.getRenderer().clearRenderCache();
      
      // 延迟一帧渲染，确保renderMode已经生效
      setTimeout(() => {
        this.drawGraph();
        // 渲染完成后立即显示画布
        this.canvasOpacity = 1;
        console.log(`[Index] project_loaded - Canvas rendered with correct renderMode`);
      }, 16); // 延迟一帧（约16ms）
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

  // 刷新选中任务，从project中重新获取最新数据
  private refreshSelectedTask() {
    if (this.selectedTask && this.project) {
      const taskId = this.selectedTask.id;
      const updatedTask = this.project.tasks.find(t => t.id === taskId);
      if (updatedTask) {
        // 创建新的引用以触发响应式更新（手动复制所有属性）
        this.selectedTask = {
          id: updatedTask.id,
          name: updatedTask.name,
          startDate: updatedTask.startDate,
          endDate: updatedTask.endDate,
          // 深拷贝 checklist，确保每个 ChecklistItem 都是新对象
          checklist: updatedTask.checklist.map((item): ChecklistItem => {
            return {
              id: item.id,
              text: item.text,
              isCompleted: item.isCompleted
            };
          }),
          x: updatedTask.x,
          y: updatedTask.y,
          isCritical: updatedTask.isCritical,
          earlyStart: updatedTask.earlyStart,
          earlyFinish: updatedTask.earlyFinish,
          lateStart: updatedTask.lateStart,
          lateFinish: updatedTask.lateFinish
        };
        // 同步更新AppState
        this.projectManager.getActions().selectTask(this.selectedTask);
        console.log(`[Index] refreshSelectedTask: 已刷新任务 ${taskId} 的数据`);
      }
    }
  }

  // 保存画布位置和缩放到项目中
  private saveCanvasPosition() {
    if (!this.project) return;
    
    const canvasState = this.canvasController.getState();
    // 保存到当前项目
    this.project.canvasOffsetX = canvasState.canvasOffsetX;
    this.project.canvasOffsetY = canvasState.canvasOffsetY;
    this.project.zoomScale = canvasState.zoomScale;
    
    // 触发自动保存
    this.projectManager.getActions().saveProject();
    
    console.log(`[EasyFlow] 保存画布状态到项目 ${this.project.id}: x=${canvasState.canvasOffsetX}, y=${canvasState.canvasOffsetY}, zoom=${canvasState.zoomScale}`);
  }
  
  // 防抖保存画布状态（用于连续操作如拖动）- 优化版
  private debouncedSaveCanvasPosition() {
    // 清除之前的定时器
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
    }
    
    // 立即更新项目对象中的状态（确保数据最新）
    if (this.project) {
      const canvasState = this.canvasController.getState();
      this.project.canvasOffsetX = canvasState.canvasOffsetX;
      this.project.canvasOffsetY = canvasState.canvasOffsetY;
      this.project.zoomScale = canvasState.zoomScale;
    }
    
    // 延迟保存到文件（优化：增加延迟时间，减少I/O频率）
    this.saveTimer = setTimeout(() => {
      this.saveCanvasPosition();
      this.saveTimer = -1;
    }, this.SAVE_DEBOUNCE_MS);
  }

  // 从项目恢复画布位置和缩放
  private restoreCanvasPosition() {
    if (!this.project) return;
    
    // 从当前项目读取画布状态
    const savedOffsetX = this.project.canvasOffsetX || 0;
    const savedOffsetY = this.project.canvasOffsetY || 0;
    const savedZoomScale = this.project.zoomScale || 1.0;

    // 获取 CanvasController 的状态对象
    const canvasState = this.canvasController.getState();
    
    // 设置偏移量
    this.canvasController.setCanvasOffset(savedOffsetX, savedOffsetY);
    
    // 恢复缩放比例（同时更新 CanvasController 和 UI 状态）
    canvasState.zoomScale = savedZoomScale;
    this.zoomScale = savedZoomScale;
    
    console.log(`[EasyFlow] 从项目 ${this.project.id} 恢复画布状态: x=${savedOffsetX}, y=${savedOffsetY}, zoom=${savedZoomScale}`);
    console.log(`[EasyFlow] 当前渲染模式 - this.canvasRenderMode: ${this.canvasRenderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}, canvasState.renderMode: ${canvasState.renderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);
  }

  // 创建示例项目
  async createNewExampleProject(): Promise<void> {
    await this.projectManager.getActions().createNewProject('新移动应用开发计划');

    const project: Project | null = this.projectManager.getState().project;
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

  // 渲染画布（增强节流优化 + 性能监控）
  private drawGraph(): void {
    const now = Date.now();
    
    // 节流检查：如果距离上次渲染时间太短，延迟处理
    if (this.isRendering || (now - this.lastRenderTime < this.RENDER_THROTTLE_MS)) {
      this.pendingRender = true;
      return;
    }
    
    this.isRendering = true;
    this.lastRenderTime = now;
    const startTime = Date.now();
    
    const renderConfig = this.canvasController.getActions().getRenderConfig(
      this.selectedTask?.id || null
    );

    if (this.project) {
      console.log(`[Index] drawGraph - renderMode: ${renderConfig.renderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}, zoomScale: ${renderConfig.zoomScale}`);
      this.canvasController.getRenderer().render(this.project, renderConfig);
      // 更新缩放比例显示
      this.zoomScale = this.canvasController.getState().zoomScale;
      
      // 性能监控：记录渲染时间
      const renderTime = Date.now() - startTime;
      this.performanceService.recordMetric('canvas_render', renderTime, 'ms');
    }
    
    // 使用微任务队列，确保渲染完成后再允许下一次渲染
    Promise.resolve().then(() => {
      this.isRendering = false;
      if (this.pendingRender) {
        this.pendingRender = false;
        // 延迟执行下一次渲染，避免过于频繁
        setTimeout(() => {
          this.drawGraph();
        }, this.RENDER_THROTTLE_MS);
      }
    });
  }
  
  // 放大画布
  private handleZoomIn(): void {
    this.canvasController.getActions().zoomIn();
    this.zoomScale = this.canvasController.getState().zoomScale;
    this.drawGraph();
    this.debouncedSaveCanvasPosition(); // 实时保存
    this.resetZoomControlHideTimer(); // 重置自动隐藏
    this.promptAction.showToast({
      message: `缩放: ${Math.round(this.zoomScale * 100)}%`,
      duration: 1000
    });
  }
  
  // 缩小画布
  private handleZoomOut(): void {
    this.canvasController.getActions().zoomOut();
    this.zoomScale = this.canvasController.getState().zoomScale;
    this.drawGraph();
    this.debouncedSaveCanvasPosition(); // 实时保存
    this.resetZoomControlHideTimer(); // 重置自动隐藏
    this.promptAction.showToast({
      message: `缩放: ${Math.round(this.zoomScale * 100)}%`,
      duration: 1000
    });
  }
  
  // 计算滑块手柄位置（0-180px），100%在中间（y=90）
  private getSliderHandlePosition(): number {
    // 将缩放比例映射到位置，100%在中间
    // 新面板：0px（顶部）= 300%, 60px（中间）= 100%, 120px（底部）= 30%
    const centerZoom = 1.0;  // 100%
    const maxZoom = 3.0;     // 300%
    const minZoom = 0.3;     // 30%
    const centerPos = 60;    // 中间位置（适配120高度的面板）
    const sliderHeight = 120;
    
    if (this.zoomScale >= centerZoom) {
      // 100% - 300%，映射到 90px - 0px
      const ratio = (this.zoomScale - centerZoom) / (maxZoom - centerZoom);
      return centerPos - (ratio * centerPos);
    } else {
      // 30% - 100%，映射到 180px - 90px
      const ratio = (this.zoomScale - minZoom) / (centerZoom - minZoom);
      return sliderHeight - (ratio * centerPos);
    }
  }
  
  // 处理滑块拖动
  private handleSliderDrag(offsetY: number): void {
    // 计算新位置
    let newPosition = this.lastSliderPosition + offsetY;
    newPosition = Math.max(0, Math.min(120, newPosition));  // 适配120高度
    
    // 将位置映射回缩放比例，100%在中间
    const centerZoom = 1.0;  // 100%
    const maxZoom = 3.0;     // 300%
    const minZoom = 0.3;     // 30%
    const centerPos = 60;    // 中间位置（适配120高度）
    
    let newZoom: number;
    if (newPosition <= centerPos) {
      // 0-90px -> 300%-100%
      const ratio = newPosition / centerPos;
      newZoom = maxZoom - (ratio * (maxZoom - centerZoom));
    } else {
      // 90-180px -> 100%-30%
      const ratio = (newPosition - centerPos) / centerPos;
      newZoom = centerZoom - (ratio * (centerZoom - minZoom));
    }
    
    // 保留两位小数
    newZoom = Math.round(newZoom * 100) / 100;
    
    // 设置新的缩放比例
    const canvasState = this.canvasController.getState();
    canvasState.zoomScale = newZoom;
    this.zoomScale = newZoom;
    
    // 实时重绘
    this.drawGraph();
    
    // 拖动过程中使用防抖保存
    this.debouncedSaveCanvasPosition();
    
    // 重置自动隐藏（拖动时保持展开）
    this.resetZoomControlHideTimer();
  }
  
  // 处理滑块点击
  private handleSliderClick(clickY: number): void {
    // 将点击位置映射到缩放比例，100%在中间
    const centerZoom = 1.0;  // 100%
    const maxZoom = 3.0;     // 300%
    const minZoom = 0.3;     // 30%
    const centerPos = 60;    // 中间位置（适配120高度）
    
    let newZoom: number;
    if (clickY <= centerPos) {
      // 0-60px -> 300%-100%
      const ratio = clickY / centerPos;
      newZoom = maxZoom - (ratio * (maxZoom - centerZoom));
    } else {
      // 60-120px -> 100%-30%
      const ratio = (clickY - centerPos) / centerPos;
      newZoom = centerZoom - (ratio * (centerZoom - minZoom));
    }
    
    // 设置新的缩放比例
    const canvasState = this.canvasController.getState();
    canvasState.zoomScale = Math.round(newZoom * 100) / 100;
    this.zoomScale = canvasState.zoomScale;
    
    // 重绘
    this.drawGraph();
    
    // 立即保存
    this.debouncedSaveCanvasPosition();
    
    // 重置自动隐藏
    this.resetZoomControlHideTimer();
    
    this.promptAction.showToast({
      message: `缩放: ${Math.round(this.zoomScale * 100)}%`,
      duration: 800
    });
  }
  
  // 展开缩放控制
  private showZoomControl(): void {
    this.uiContext.animateTo({
      duration: 250,
      curve: Curve.EaseOut
    }, () => {
      this.zoomControlExpanded = true;
      this.zoomControlOpacity = 1.0;
    });
    this.resetZoomControlHideTimer();
  }
  
  // 收起缩放控制
  private hideZoomControl(): void {
    this.uiContext.animateTo({
      duration: 300,
      curve: Curve.EaseIn
    }, () => {
      this.zoomControlExpanded = false;
      this.zoomControlOpacity = 0.3;
    });
  }
  
  // 重置自动隐藏定时器
  private resetZoomControlHideTimer(): void {
    // 清除旧定时器
    if (this.zoomControlHideTimer !== -1) {
      clearTimeout(this.zoomControlHideTimer);
    }
    
    // 设置3秒后自动隐藏
    this.zoomControlHideTimer = setTimeout(() => {
      this.hideZoomControl();
      this.zoomControlHideTimer = -1;
    }, 3000);
  }
  
  // 切换缩放控制展开状态
  private toggleZoomControl(): void {
    if (this.zoomControlExpanded) {
      this.hideZoomControl();
      if (this.zoomControlHideTimer !== -1) {
        clearTimeout(this.zoomControlHideTimer);
        this.zoomControlHideTimer = -1;
      }
    } else {
      this.showZoomControl();
    }
  }

  // 切换画布渲染模式
  private toggleRenderMode(): void {
    // 切换模式
    this.canvasRenderMode = this.canvasRenderMode === RenderMode.NORMAL 
      ? RenderMode.COMPACT 
      : RenderMode.NORMAL;
    
    // 更新画布控制器
    this.canvasController.setRenderMode(this.canvasRenderMode);
    
    // 重新绘制
    this.drawGraph();
    
    // 显示提示
    const modeName = this.canvasRenderMode === RenderMode.NORMAL ? '完整模式' : '缩略模式';
    this.promptAction.showToast({
      message: `已切换到${modeName}`,
      duration: 1500
    });
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

  // 画布背景构建器 - 自适应背景灰色网格
  @Builder
  CanvasBackground() {
    Stack() {
      // 背景色（支持深色模式）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ColorResource.surface)

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

  /**
   * 缩放面板组件
   */
  @Builder
  ZoomPanel() {
    if (this.isPhone) {
      // 手机端：横向布局，显示在工具栏上方
      Row({ space: 6 }) {
        // 缩小按钮
        Text('−')
          .fontSize(16)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Bold)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(14)
          .backgroundColor(ColorResource.surface)
          .border({ width: 1, color: ColorResource.primaryColor })
          .onClick(() => this.handleZoomOut())
        
        // 百分比显示
        Text(`${Math.round(this.zoomScale * 100)}%`)
          .fontSize(11)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(ColorResource.surface)
          .borderRadius(12)
          .border({ width: 1, color: ColorResource.surfaceNeutral })
        
        // 放大按钮
        Text('+')
          .fontSize(16)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Bold)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(14)
          .backgroundColor(ColorResource.surface)
          .border({ width: 1, color: ColorResource.primaryColor })
          .onClick(() => this.handleZoomIn())
        
        // 分隔线
        Column()
          .width(1)
          .height(20)
          .backgroundColor(ColorResource.surfaceNeutral)
        
        // 重置到100%按钮
        Text('1:1')
          .fontSize(11)
          .fontColor(ColorResource.infoColor)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor(ColorResource.infoLight)
          .border({ width: 1, color: ColorResource.infoColor })
          .onClick(() => {
            this.zoomScale = 1.0;
            this.canvasController.getState().zoomScale = 1.0;
            this.drawGraph();
            this.debouncedSaveCanvasPosition();
            this.promptAction.showToast({
              message: '已重置缩放：100%',
              duration: 1000
            });
          })
      }
      .height(36)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor(ColorResource.surface)
      .borderRadius(20)
      .border({ width: 2, color: ColorResource.primaryColor })
      .shadow(ThemeConfig.shadowLarge)
      .position({ x: 0, y: 0 })
      .translate({ x: 12, y: 12 })  // 从左侧打开，位于工具栏上方
      .zIndex(98)  // 低于工具栏的zIndex
      .transition({
        type: TransitionType.All,
        scale: { x: 0.8, y: 0.8 },
        opacity: 0,
        translate: { x: -30, y: -20 }  // 从左侧滑入的动画效果
      })
    } else {
      // 其他设备：垂直布局，显示在工具栏旁边
      Column({ space: 6 }) {
        // 放大按钮
        Text('+')
          .fontSize(18)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Bold)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .borderRadius(16)
          .backgroundColor(ColorResource.surface)
          .border({ width: 1, color: ColorResource.primaryColor })
          .onClick(() => this.handleZoomIn())
        
        // 滑块容器
        Stack() {
          // 轨道
          Column()
            .width(3)
            .height(120)
            .backgroundColor(ColorResource.surfaceNeutral)
            .borderRadius(1.5)
            .position({ x: 6.5, y: 0 })
          
          // 中线（100%位置）
          Line()
            .width(8)
            .height(1.5)
            .backgroundColor(ColorResource.primaryColor)
            .position({ x: 4, y: 60 })
          
          // 进度条
          Column()
            .width(3)
            .height(Math.abs(60 - this.getSliderHandlePosition()))
            .backgroundColor(ColorResource.primaryColor)
            .borderRadius(1.5)
            .position({ 
              x: 6.5, 
              y: Math.min(60, this.getSliderHandlePosition())
            })
          
          // 滑块手柄
          Column()
            .width(16)
            .height(16)
            .backgroundColor(ColorResource.surface)
            .borderRadius(8)
            .border({ width: 2, color: ColorResource.primaryColor })
            .scale({ 
              x: this.sliderDragging ? 1.1 : 1,
              y: this.sliderDragging ? 1.1 : 1
            })
            .position({ x: 0, y: this.getSliderHandlePosition() })
        }
        .width(16)
        .height(120)
        .gesture(
          PanGesture()
            .onActionStart(() => {
              this.sliderDragging = true;
              this.lastSliderPosition = this.getSliderHandlePosition();
            })
            .onActionUpdate((event: GestureEvent) => {
              this.handleSliderDrag(event.offsetY);
            })
            .onActionEnd(() => {
              this.sliderDragging = false;
            })
        )
        .onClick((event: ClickEvent) => {
          this.handleSliderClick(event.y);
        })
        
        // 百分比显示
        Text(`${Math.round(this.zoomScale * 100)}%`)
          .fontSize(11)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Bold)
          .padding(6)
          .backgroundColor(ColorResource.surface)
          .borderRadius(12)
          .border({ width: 1, color: ColorResource.surfaceNeutral })
        
        // 缩小按钮
        Text('−')
          .fontSize(20)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Bold)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .borderRadius(16)
          .backgroundColor(ColorResource.surface)
          .border({ width: 1, color: ColorResource.primaryColor })
          .onClick(() => this.handleZoomOut())
        
        // 分隔线
        Column()
          .width(24)
          .height(1)
          .backgroundColor(ColorResource.surfaceNeutral)
        
        // 重置到100%按钮
        Text('1:1')
          .fontSize(11)
          .fontColor(ColorResource.infoColor)
          .fontWeight(FontWeight.Bold)
          .width(32)
          .height(24)
          .textAlign(TextAlign.Center)
          .borderRadius(12)
          .backgroundColor(ColorResource.infoLight)
          .border({ width: 1, color: ColorResource.infoColor })
          .onClick(() => {
            this.zoomScale = 1.0;
            this.canvasController.getState().zoomScale = 1.0;
            this.drawGraph();
            this.debouncedSaveCanvasPosition();
            this.promptAction.showToast({
              message: '已重置缩放：100%',
              duration: 1000
            });
          })
      }
      .width(48)
      .padding({ top: 10, bottom: 10 })
      .backgroundColor(ColorResource.surface)
      .borderRadius(24)
      .border({ width: 2, color: ColorResource.primaryColor })
      .shadow(ThemeConfig.shadowLarge)
      .position({ x: '100%', y: 68 })  // 工具栏下方（下调位置，避免重叠）
      .translate({ x: -60, y: 0 })
      .zIndex(99)
      .transition({
        type: TransitionType.All,
        scale: { x: 0.8, y: 0.8 },
        opacity: 0,
        translate: { y: -20 }
      })
    }
  }

  /**
   * 可伸缩工具栏组件
   */
  @Builder
  CollapsibleToolbar() {
    // 手机端使用垂直布局，其他设备使用水平布局
    if (this.isPhone) {
      // 手机端：垂直布局
      Column() {
        // 收起状态：只显示展开按钮
        if (!this.toolbarExpanded) {
          Button() {
            Row({ space: 4 }) {
              Text('⚡')
                .fontSize(16)
                .fontColor(ColorResource.primaryColor)
            }
            .padding({ left: 2, right: 2 })
          }
          .width(36)
          .height(36)
          .backgroundColor(ColorResource.surface)
          .borderRadius(18)
          .border({ width: 2, color: ColorResource.primaryColor })
          .shadow(ThemeConfig.shadowLarge)
          .onClick(() => {
            this.uiContext.animateTo({
              duration: 180,
              curve: Curve.EaseInOut
            }, () => {
              this.toolbarExpanded = true;
            });
          })
        }
        
        // 展开状态：垂直排列所有工具按钮
        if (this.toolbarExpanded) {
          Column({ space: 6 }) {
            // 撤销按钮 - 内联以确保响应式更新
            Button() {
              Text('↶')
                .fontSize(18)
                .fontColor(this.canUndo ? ColorResource.errorColor : ColorResource.surfaceStrong)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.canUndo ? ColorResource.errorLight : ColorResource.surfaceLight)
            .borderRadius(18)
            .border({
              width: 1.5,
              color: this.canUndo ? ColorResource.errorColor : ColorResource.surfaceNeutral
            })
            .enabled(this.canUndo)
            .opacity(this.canUndo ? 1 : 0.5)
            .onClick(() => {
              if (this.commandHistory.undo()) {
                const commandName = this.commandHistory.getLastRedoCommandName();
                this.updateUndoRedoState();
                this.updateStateFromManager();
                // 撤销后刷新selectedTask，确保显示最新数据
                this.refreshSelectedTask();
                this.drawGraph();
                this.projectManager.getActions().calculateCriticalPath();
                this.promptAction.showToast({
                  message: commandName ? `✓ 已撤销：${commandName}` : '✓ 已撤销操作',
                  duration: 2000
                });
              } else {
                this.promptAction.showToast({
                  message: '没有可撤销的操作',
                  duration: 1500
                });
              }
            })
            
            // 重做按钮 - 内联以确保响应式更新
            Button() {
              Text('↷')
                .fontSize(18)
                .fontColor(this.canRedo ? ColorResource.primaryColor : ColorResource.surfaceStrong)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.canRedo ? ColorResource.primaryUltraLight : ColorResource.surfaceLight)
            .borderRadius(18)
            .border({
              width: 1.5,
              color: this.canRedo ? ColorResource.primaryColor : ColorResource.surfaceNeutral
            })
            .enabled(this.canRedo)
            .opacity(this.canRedo ? 1 : 0.5)
            .onClick(() => {
              if (this.commandHistory.redo()) {
                const commandName = this.commandHistory.getLastUndoCommandName();
                this.updateUndoRedoState();
                this.updateStateFromManager();
                // 重做后刷新selectedTask，确保显示最新数据
                this.refreshSelectedTask();
                this.drawGraph();
                this.projectManager.getActions().calculateCriticalPath();
                this.promptAction.showToast({
                  message: commandName ? `✓ 已重做：${commandName}` : '✓ 已重做操作',
                  duration: 2000
                });
              } else {
                this.promptAction.showToast({
                  message: '没有可重做的操作',
                  duration: 1500
                });
              }
            })
            
            // 分隔线
            Row()
              .width(24)
              .height(1)
              .backgroundColor(ColorResource.surfaceNeutral)
              .margin({ top: 2, bottom: 2 })
            
            // 锁定/解锁按钮 - 内联以确保响应式更新
            Button() {
              Text(this.canvasLock ? '🔓' : '🔒')
                .fontSize(18)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.canvasLock ? ColorResource.warningLight : ColorResource.surface)
            .borderRadius(18)
            .border({
              width: 1.5,
              color: ColorResource.warningColor
            })
            .onClick(() => {
              this.canvasController.getActions().toggleCanvasLock();
              this.canvasLock = !this.canvasLock;
            })
            
            // 重置按钮
            Button() {
              Text('🔄')
                .fontSize(18)
            }
            .width(36)
            .height(36)
            .backgroundColor(ColorResource.successLight)
            .borderRadius(18)
            .border({
              width: 1.5,
              color: ColorResource.successColor
            })
            .onClick(() => {
              this.canvasController.getActions().resetCanvas();
              this.drawGraph();
            })
            
            // 分隔线
            Row()
              .width(24)
              .height(1)
              .backgroundColor(ColorResource.surfaceNeutral)
              .margin({ top: 2, bottom: 2 })
            
            // 缩略模式切换按钮
            Button() {
              Text(this.canvasRenderMode === RenderMode.NORMAL ? '⚪' : '🔵')
                .fontSize(18)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.canvasRenderMode === RenderMode.COMPACT 
              ? ColorResource.primaryUltraLight 
              : ColorResource.infoLight)
            .borderRadius(18)
            .border({
              width: 1.5,
              color: this.canvasRenderMode === RenderMode.COMPACT 
                ? ColorResource.primaryColor 
                : ColorResource.infoColor
            })
            .onClick(() => {
              this.toggleRenderMode();
            })
            
            // 缩放按钮
            Button() {
              Text('🔍')
                .fontSize(18)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.zoomPanelExpanded 
              ? ColorResource.primaryUltraLight 
              : ColorResource.surface)
            .borderRadius(18)
            .border({
              width: 1.5,
              color: this.zoomPanelExpanded 
                ? ColorResource.primaryColor 
                : ColorResource.surfaceNeutral
            })
            .onClick(() => {
              this.uiContext.animateTo({
                duration: 180,
                curve: Curve.EaseInOut
              }, () => {
                this.zoomPanelExpanded = !this.zoomPanelExpanded;
              });
            })
            
            // 分隔线
            Row()
              .width(24)
              .height(1)
              .backgroundColor(ColorResource.surfaceNeutral)
              .margin({ top: 2, bottom: 2 })
            
            // 收起按钮
            Button() {
              Text('×')
                .fontSize(20)
                .fontColor(ColorResource.surfaceStrong)
                .fontWeight(FontWeight.Bold)
            }
            .width(36)
            .height(36)
            .backgroundColor(ColorResource.surfaceLight)
            .borderRadius(18)
            .border({ width: 1, color: ColorResource.surfaceNeutral })
            .onClick(() => {
              this.uiContext.animateTo({
                duration: 180,
                curve: Curve.EaseInOut
              }, () => {
                this.toolbarExpanded = false;
              });
            })
          }
          .padding({ top: 2, bottom: 6, left: 6, right: 6 })
          .backgroundColor(ColorResource.surface)
          .borderRadius(24)
          .border({ width: 2, color: ColorResource.primaryColor })
          .shadow(ThemeConfig.shadowLarge)
        }
      }
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.End)
      .padding({ right: 12, top: 12 })
      .position({ x: '100%', y: 0 })
      .translate({ x: '-100%', y: 0 })
    } else {
      // 其他设备：水平布局（保持原样）
      Row() {
        // 收起状态：只显示展开按钮
        if (!this.toolbarExpanded) {
          Button() {
            Row({ space: 6 }) {
              Text('⚡')
                .fontSize(18)
                .fontColor(ColorResource.primaryColor)
            }
            .padding({ left: 2, right: 2 })
          }
          .width(40)
          .height(40)
          .backgroundColor(ColorResource.surface)
          .borderRadius(20)
          .border({ width: 2, color: ColorResource.primaryColor })
          .shadow(ThemeConfig.shadowLarge)
          .onClick(() => {
            this.uiContext.animateTo({
              duration: 180,
              curve: Curve.EaseInOut
            }, () => {
              this.toolbarExpanded = true;
            });
          })
        }
        
        // 展开状态：显示所有工具按钮
        if (this.toolbarExpanded) {
          Row({ space: 8 }) {
            // 撤销按钮 - 内联以确保响应式更新
            Button() {
              Row({ space: 4 }) {
                Text('↶')
                  .fontSize(16)
                Text('撤销')
                  .fontSize(12)
                  .fontColor(this.canUndo ? ColorResource.errorColor : ColorResource.surfaceStrong)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor(this.canUndo ? ColorResource.errorLight : ColorResource.surfaceLight)
            .borderRadius(16)
            .border({
              width: 1.5,
              color: this.canUndo ? ColorResource.errorColor : ColorResource.surfaceNeutral
            })
            .enabled(this.canUndo)
            .opacity(this.canUndo ? 1 : 0.5)
            .onClick(() => {
              if (this.commandHistory.undo()) {
                const commandName = this.commandHistory.getLastRedoCommandName();
                this.updateUndoRedoState();
                this.updateStateFromManager();
                // 撤销后刷新selectedTask，确保显示最新数据
                this.refreshSelectedTask();
                this.drawGraph();
                this.projectManager.getActions().calculateCriticalPath();
                this.promptAction.showToast({
                  message: commandName ? `✓ 已撤销：${commandName}` : '✓ 已撤销操作',
                  duration: 2000
                });
              } else {
                this.promptAction.showToast({
                  message: '没有可撤销的操作',
                  duration: 1500
                });
              }
            })
            
            // 重做按钮 - 内联以确保响应式更新
            Button() {
              Row({ space: 4 }) {
                Text('↷')
                  .fontSize(16)
                Text('重做')
                  .fontSize(12)
                  .fontColor(this.canRedo ? ColorResource.primaryColor : ColorResource.surfaceStrong)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor(this.canRedo ? ColorResource.primaryUltraLight : ColorResource.surfaceLight)
            .borderRadius(16)
            .border({
              width: 1.5,
              color: this.canRedo ? ColorResource.primaryColor : ColorResource.surfaceNeutral
            })
            .enabled(this.canRedo)
            .opacity(this.canRedo ? 1 : 0.5)
            .onClick(() => {
              if (this.commandHistory.redo()) {
                const commandName = this.commandHistory.getLastUndoCommandName();
                this.updateUndoRedoState();
                this.updateStateFromManager();
                // 重做后刷新selectedTask，确保显示最新数据
                this.refreshSelectedTask();
                this.drawGraph();
                this.projectManager.getActions().calculateCriticalPath();
                this.promptAction.showToast({
                  message: commandName ? `✓ 已重做：${commandName}` : '✓ 已重做操作',
                  duration: 2000
                });
              } else {
                this.promptAction.showToast({
                  message: '没有可重做的操作',
                  duration: 1500
                });
              }
            })
            
            // 分隔线
            Column()
              .width(1)
              .height(24)
              .backgroundColor(ColorResource.surfaceNeutral)
              .margin({ left: 4, right: 4 })
            
            // 锁定/解锁按钮 - 内联以确保响应式更新
            Button() {
              Row({ space: 4 }) {
                Text(this.canvasLock ? '🔓' : '🔒')
                  .fontSize(16)
                Text(this.canvasLock ? '解锁' : '锁定')
                  .fontSize(12)
                  .fontColor(ColorResource.warningColor)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor(this.canvasLock ? ColorResource.warningLight : ColorResource.surface)
            .borderRadius(16)
            .border({
              width: 1.5,
              color: ColorResource.warningColor
            })
            .onClick(() => {
              this.canvasController.getActions().toggleCanvasLock();
              this.canvasLock = !this.canvasLock;
            })
            
            // 重置按钮
            Button() {
              Row({ space: 4 }) {
                Text('🔄')
                  .fontSize(16)
                Text('重置')
                  .fontSize(12)
                  .fontColor(ColorResource.successColor)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor(ColorResource.successLight)
            .borderRadius(16)
            .border({
              width: 1.5,
              color: ColorResource.successColor
            })
            .onClick(() => {
              this.canvasController.getActions().resetCanvas();
              this.drawGraph();
            })
            
            // 分隔线
            Column()
              .width(1)
              .height(24)
              .backgroundColor(ColorResource.surfaceNeutral)
              .margin({ left: 4, right: 4 })
            
            // 缩略模式切换按钮
            Button() {
              Row({ space: 4 }) {
                Text(this.canvasRenderMode === RenderMode.NORMAL ? '⚪' : '🔵')
                  .fontSize(16)
                Text(this.canvasRenderMode === RenderMode.NORMAL ? '缩略' : '完整')
                  .fontSize(12)
                  .fontColor(this.canvasRenderMode === RenderMode.COMPACT 
                    ? ColorResource.primaryColor 
                    : ColorResource.infoColor)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor(this.canvasRenderMode === RenderMode.COMPACT 
              ? ColorResource.primaryUltraLight 
              : ColorResource.infoLight)
            .borderRadius(16)
            .border({
              width: 1.5,
              color: this.canvasRenderMode === RenderMode.COMPACT 
                ? ColorResource.primaryColor 
                : ColorResource.infoColor
            })
            .onClick(() => {
              this.toggleRenderMode();
            })
            
            // 缩放按钮
            Button() {
              Row({ space: 4 }) {
                Text('🔍')
                  .fontSize(16)
                Text(`${Math.round(this.zoomScale * 100)}%`)
                  .fontSize(12)
                  .fontColor(ColorResource.primaryColor)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor(this.zoomPanelExpanded 
              ? ColorResource.primaryUltraLight 
              : ColorResource.surface)
            .borderRadius(16)
            .border({
              width: 1.5,
              color: this.zoomPanelExpanded 
                ? ColorResource.primaryColor 
                : ColorResource.surfaceNeutral
            })
            .onClick(() => {
              this.uiContext.animateTo({
                duration: 180,
                curve: Curve.EaseInOut
              }, () => {
                this.zoomPanelExpanded = !this.zoomPanelExpanded;
              });
            })
            
            // 分隔线
            Column()
              .width(1)
              .height(24)
              .backgroundColor(ColorResource.surfaceNeutral)
              .margin({ left: 4, right: 4 })
            
            // 收起按钮
            Button() {
              Text('×')
                .fontSize(20)
                .fontColor(ColorResource.surfaceStrong)
                .fontWeight(FontWeight.Bold)
            }
            .width(32)
            .height(32)
            .backgroundColor(ColorResource.surfaceLight)
            .borderRadius(16)
            .border({ width: 1, color: ColorResource.surfaceNeutral })
            .onClick(() => {
              this.uiContext.animateTo({
                duration: 180,
                curve: Curve.EaseInOut
              }, () => {
                this.toolbarExpanded = false;
              });
            })
          }
          .padding({ left: 12, right: 8, top: 6, bottom: 6 })
          .backgroundColor(ColorResource.surface)
          .borderRadius(24)
          .border({ width: 2, color: ColorResource.primaryColor })
          .shadow(ThemeConfig.shadowLarge)
        }
      }
      .justifyContent(FlexAlign.End)
      .padding({ right: 12, top: 12 })
      .position({ x: '100%', y: 0 })
      .translate({ x: '-100%', y: 0 })
    }
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
      .border({ width: 1, color: ColorResource.surfaceNeutral, radius: 8 })
      .onClick(() => {
        this.sidebarVisible = !this.sidebarVisible
      })

      // 侧边栏
      if (this.sidebarVisible) {
        Sidebar({
          project: this.project,
          selectedTask: this.selectedTask,
          isHomePage: false,
          exportService: this.exportService,
          onGetCanvasPixelMap: async () => {
            return await this.canvasController.getCanvasPixelMap(
              this.project ?? undefined,
              this.selectedTask?.id
            );
          },
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
            onAddReminder: async (task: TaskNode) => {
              if (!this.permissionService) {
                this.promptAction.showToast({
                  message: '权限服务未初始化，无法创建提醒',
                  duration: 2000
                });
                return;
              }

              const granted: boolean = await this.permissionService.requestReminderPermission();
              if (!granted) {
                this.promptAction.showToast({
                  message: '未获得日历提醒权限，无法创建系统提醒',
                  duration: 3000
                });
                return;
              }

              const id = await this.calendarService.addTaskReminder(task);
              if (id !== null) {
                this.promptAction.showToast({
                  message: `已为任务 "${task.name}" 创建日历提醒`,
                  duration: 2000
                });
              } else {
                this.promptAction.showToast({
                  message: '创建日历提醒失败，可能是当前设备不支持该功能',
                  duration: 3000
                });
              }
            },
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
          .opacity(this.canvasOpacity)
          .onReady(() => {
            console.log(`[Index] Canvas onReady - project exists: ${!!this.project}, isPhone: ${this.isPhone}, this.canvasRenderMode: ${this.canvasRenderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);
            // Canvas准备就绪，但只有项目加载完成后才渲染和显示
            if (this.project) {
              // 确保渲染模式正确设置（直接基于 isPhone 判断，避免 @State 异步更新问题）
              const correctRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
              this.canvasRenderMode = correctRenderMode;
              this.canvasController.setRenderMode(correctRenderMode);
              console.log(`[Index] Canvas onReady - setting renderMode to: ${correctRenderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);
              
              // 项目已加载，立即恢复画布位置
              this.restoreCanvasPosition();
              console.log(`[Index] After restore - zoomScale: ${this.canvasController.getState().zoomScale}, renderMode: ${this.canvasController.getState().renderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);
              
              // 清除渲染缓存，确保使用最新的renderMode渲染
              this.canvasController.getRenderer().clearRenderCache();
              
              // 延迟一帧渲染，确保所有状态都已经正确设置
              setTimeout(() => {
                this.drawGraph();
                // 渲染完成后立即显示画布
                this.canvasOpacity = 1;
                console.log(`[Index] Canvas now visible with correct renderMode`);
              }, 16); // 延迟一帧（约16ms）
            }
            // 如果项目还没加载，等待 project_loaded 事件触发渲染
          })
          .onTouch((event: TouchEvent) => {
            if (!this.project) {
              return;
            }

            // 检测双指操作（缩放），自动展开控制条
            if (event.touches.length === 2) {
              this.showZoomControl();
            }

            // 触摸坐标相对于Canvas，无需偏移（左侧按钮和侧边栏使用position浮动定位）
            this.canvasController.getActions().handleTouch(
              event,
              this.project,
              this.selectedTask?.id || null,
              0  // 编辑页面不需要X轴偏移
            );
            
            // 立即更新缩放比例显示（不等待渲染）
            const currentScale = this.canvasController.getState().zoomScale;
            if (Math.abs(currentScale - this.zoomScale) > 0.01) {
              this.zoomScale = currentScale;
            }
            
            this.drawGraph(); // 重新绘制图形（使用节流优化）
            
            // 触摸结束时保存画布状态（缩放和拖动）
            if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.debouncedSaveCanvasPosition();
            }
          })

        // 右上角可伸缩工具栏
        this.CollapsibleToolbar()
        
        // 缩放面板（工具栏下方弹出）
        if (this.zoomPanelExpanded) {
          this.ZoomPanel()
        }
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
