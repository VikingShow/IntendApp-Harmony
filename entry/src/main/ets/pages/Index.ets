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
  
  // 响应式布局相关状态
  @State screenWidth: number = 0;
  @State isPhone: boolean = false;
  
  // 画布渲染模式
  @State canvasRenderMode: RenderMode = RenderMode.NORMAL;
  
  // 画布缩放比例
  @State zoomScale: number = 1.0;
  
  // 渲染节流相关
  private isRendering: boolean = false;
  private pendingRender: boolean = false;
  
  // 滑块拖动相关
  private sliderDragging: boolean = false;
  private lastSliderPosition: number = 0;
  
  // 防抖保存定时器
  private saveTimer: number = -1;
  
  // 缩放控制UI状态
  @State zoomControlExpanded: boolean = false; // 是否展开
  @State zoomControlOpacity: number = 0.3; // 透明度
  private zoomControlHideTimer: number = -1; // 自动隐藏定时器

  async aboutToAppear() {
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
    
    // 根据设备类型设置渲染模式（手机端使用缩略模式）
    this.canvasRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
    this.canvasController.setRenderMode(this.canvasRenderMode);

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
    } else {
      // 如果没有ID，则创建新项目并填充示例数据
      console.log("[EasyFlow] Creating new project with example data.");
      await this.createNewExampleProject();
    }

    // 项目加载完成后恢复画布位置
    this.restoreCanvasPosition();
  }

  aboutToDisappear() {
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
  
  // 防抖保存画布状态（用于连续操作如拖动）
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
    
    // 延迟500ms后保存到文件
    this.saveTimer = setTimeout(() => {
      this.saveCanvasPosition();
      this.saveTimer = -1;
    }, 500);
  }

  // 从项目恢复画布位置和缩放
  private restoreCanvasPosition() {
    if (!this.project) return;
    
    // 从当前项目读取画布状态
    const savedOffsetX = this.project.canvasOffsetX || 0;
    const savedOffsetY = this.project.canvasOffsetY || 0;
    const savedZoomScale = this.project.zoomScale || 1.0;

    // 设置到CanvasController
    this.canvasController.setCanvasOffset(savedOffsetX, savedOffsetY);
    
    // 恢复缩放比例
    const canvasState = this.canvasController.getState();
    canvasState.zoomScale = savedZoomScale;
    this.zoomScale = savedZoomScale;
    
    console.log(`[EasyFlow] 从项目 ${this.project.id} 恢复画布状态: x=${savedOffsetX}, y=${savedOffsetY}, zoom=${savedZoomScale}`);
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

  // 渲染画布（添加节流优化）
  private drawGraph(): void {
    if (this.isRendering) {
      this.pendingRender = true;
      return;
    }
    
    this.isRendering = true;
    
    const renderConfig = this.canvasController.getActions().getRenderConfig(
      this.selectedTask?.id || null
    );

    if (this.project) {
      this.canvasController.getRenderer().render(this.project, renderConfig);
      // 更新缩放比例显示
      this.zoomScale = this.canvasController.getState().zoomScale;
    }
    
    // 使用微任务队列，确保渲染完成后再允许下一次渲染
    Promise.resolve().then(() => {
      this.isRendering = false;
      if (this.pendingRender) {
        this.pendingRender = false;
        this.drawGraph();
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
  
  // 重置缩放
  private handleResetZoom(): void {
    this.canvasController.getActions().resetZoom();
    this.zoomScale = this.canvasController.getState().zoomScale;
    this.drawGraph();
    this.debouncedSaveCanvasPosition(); // 实时保存
    this.promptAction.showToast({
      message: '已重置缩放',
      duration: 1000
    });
  }
  
  // 计算滑块手柄位置（0-180px），100%在中间（y=90）
  private getSliderHandlePosition(): number {
    // 将缩放比例映射到位置，100%在中间
    // 0px（顶部）= 300%
    // 90px（中间）= 100%
    // 180px（底部）= 30%
    const centerZoom = 1.0;  // 100%
    const maxZoom = 3.0;     // 300%
    const minZoom = 0.3;     // 30%
    const centerPos = 90;    // 中间位置
    const sliderHeight = 180;
    
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
  
  // 计算滑块填充高度（暂时不用）
  private getSliderFillHeight(): number {
    return 0;
  }
  
  // 处理滑块拖动
  private handleSliderDrag(offsetY: number): void {
    // 计算新位置
    let newPosition = this.lastSliderPosition + offsetY;
    newPosition = Math.max(0, Math.min(180, newPosition));
    
    // 将位置映射回缩放比例，100%在中间
    const centerZoom = 1.0;  // 100%
    const maxZoom = 3.0;     // 300%
    const minZoom = 0.3;     // 30%
    const centerPos = 90;    // 中间位置
    
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
    const centerPos = 90;    // 中间位置
    
    let newZoom: number;
    if (clickY <= centerPos) {
      // 0-90px -> 300%-100%
      const ratio = clickY / centerPos;
      newZoom = maxZoom - (ratio * (maxZoom - centerZoom));
    } else {
      // 90-180px -> 100%-30%
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
        
        // 右侧中间 - 极简缩放控制
        Column({ space: 8 }) {
          // 收起状态：极简图标
          if (!this.zoomControlExpanded) {
            Text(`${Math.round(this.zoomScale * 100)}%`)
              .fontSize(12)
              .fontColor(ColorResource.primaryColor)
              .fontWeight(FontWeight.Bold)
              .padding(8)
              .backgroundColor(ColorResource.surface)
              .borderRadius(16)
              .border({ width: 1, color: ColorResource.primaryColor })
              .onClick(() => this.toggleZoomControl())
              .opacity(this.zoomControlOpacity)
          }
          
          // 展开状态：极简面板
          if (this.zoomControlExpanded) {
            Column({ space: 6 }) {
              // 放大
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
          
              // 滑块
              Stack() {
                // 轨道 - 居中
                Column()
                  .width(3)
                  .height(180)
                  .backgroundColor(ColorResource.surfaceNeutral)
                  .borderRadius(1.5)
                  .position({ x: 6.5, y: 0 })
                
                // 中线 - 居中并向左延伸
                Line()
                  .width(8)
                  .height(1.5)
                  .backgroundColor(ColorResource.primaryColor)
                  .position({ x: 4, y: 90 })
                
                // 进度 - 居中
                Column()
                  .width(3)
                  .height(Math.abs(90 - this.getSliderHandlePosition()))
                  .backgroundColor(ColorResource.primaryColor)
                  .borderRadius(1.5)
                  .position({ 
                    x: 6.5, 
                    y: Math.min(90, this.getSliderHandlePosition())
                  })
                
                // 手柄 - 居中
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
              .height(180)
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
            
              // 百分比
              Text(`${Math.round(this.zoomScale * 100)}%`)
                .fontSize(11)
                .fontColor(ColorResource.primaryColor)
                .fontWeight(FontWeight.Bold)
                .padding(6)
                .backgroundColor(ColorResource.surface)
                .borderRadius(12)
                .border({ width: 1, color: ColorResource.surfaceNeutral })
            
              // 缩小
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
            }
            .width(48)
            .height(310)
            .backgroundColor(ColorResource.surface)
            .borderRadius(24)
            .padding({ top: 10, bottom: 10 })
            .border({ width: 1, color: ColorResource.surfaceNeutral })
            .opacity(this.zoomControlExpanded ? 1 : 0)
          }
        }
        .position({ x: '100%', y: '50%' })
        .translate({ x: -60, y: -135 })
        .zIndex(100)
        
        // 右下角 - 渲染模式切换按钮
        Button() {
          Column({ space: 4 }) {
            Text(this.canvasRenderMode === RenderMode.NORMAL ? '⚪' : '🔵')
              .fontSize(20)
            // Text(this.canvasRenderMode === RenderMode.NORMAL ? '缩略' : '完整')
            //   .fontSize(11)
            //   .fontColor(ColorResource.textPrimary)
            //   .fontWeight(ThemeConfig.fontWeightMedium)
          }
        }
        .width(65)
        .height(65)
        .backgroundColor(ColorResource.surface)
        .borderRadius(ThemeConfig.radiusLarge)
        .border({ 
          width: 2, 
          color: this.canvasRenderMode === RenderMode.COMPACT 
            ? ColorResource.primaryColor 
            : ColorResource.surfaceNeutral, 
          radius: ThemeConfig.radiusLarge 
        })
        .shadow({
          radius: 12,
          color: this.isDarkMode ? ColorResource.shadowColorMedium : ColorResource.shadowColorFaint,
          offsetX: 0,
          offsetY: 4
        })
        .position({ x: '100%', y: '100%' })
        .translate({ x: -85, y: -85 })
        .zIndex(100)
        .onClick(() => {
          // 触发震动反馈
          try {
            vibrator.startVibration({
              type: 'time',
              duration: 15
            }, {
              usage: 'touch'
            });
          } catch (error) {
            console.error('[Index] Vibration error:', error);
          }
          
          this.toggleRenderMode();
        })
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