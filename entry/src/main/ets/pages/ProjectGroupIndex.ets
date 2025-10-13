// File: entry/src/main/ets/pages/ProjectGroupIndex.ets
/**
 * 项目集编辑页面模块（Program Management Index）
 *
 * 本页面是项目集管理的核心编辑界面，完全复用 Index.ets 的设计模式和代码结构。
 * 采用适配器模式，将 ProjectGroup 映射为 Project 结构，从而复用现有的画布渲染和交互逻辑。
 * 
 * 架构层级：
 * - ProjectGroupHome.ets：项目集列表页面（类似 Home.ets）
 * - ProjectGroupIndex.ets：项目集编辑页面（类似 Index.ets）← 当前页面
 *
 * 主要功能：
 * 1. 项目集可视化：使用现有的 Canvas 2D 技术绘制项目网络图
 * 2. 项目管理：支持项目的添加、删除、移动等操作
 * 3. 依赖关系：可视化创建和管理项目间的依赖关系
 * 4. 关键路径：计算和显示项目集的关键路径
 * 5. 交互操作：完全复用 Index.ets 的拖拽、点击、连接等交互
 *
 * 设计特点：
 * - 适配器模式：ProjectGroup → Project 映射
 * - 完全复用：复用 CanvasController、Sidebar、样式、交互逻辑
 * - 统一体验：与项目管理页面保持一致的用户体验
 * - 两层导航：通过 ProjectGroupHome 进入本页面
 *
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-01
 */

import { ProjectGroupService } from '../services/ProjectGroupService';
import { ProjectGroup, ProjectRef, ProjectDependency } from '../model/ProjectGroup';
import { Project, TaskNode, Dependency } from '../model/ProjectData';
import { CanvasController } from '../core/canvas/CanvasController';
import { RenderMode } from '../core/canvas/CanvasRenderer';
import { StorageService, ProjectMeta } from '../services/StorageService';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { PromptAction } from '@kit.ArkUI';
import router from '@ohos.router';
import { BreakpointSystem } from '../utils/BreakpointSystem';
import common from '@ohos.app.ability.common';
import { EventBus } from '../core/EventBus';
import { AppState } from '../core/AppState';
import { ExportService } from '../services/ExportService';
import { FileStorageService } from '../services/FileStorageService';
import { TemplateService, ProjectTemplate } from '../services/TemplateService';

/**
 * 路由参数接口
 */
interface RouterParams {
  /** 项目集ID，用于加载指定项目集 */
  groupId?: string;
}

/**
 * 按钮配置接口（用于 ActionMenu）
 */
interface ActionMenuButton {
  text: string;
  color: string | Resource;
}

@Entry
@Component
struct ProjectGroupIndex {
  // 页面转场动画配置
  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0.0)
    PageTransitionExit({ duration: 300, curve: Curve.EaseInOut })
      .opacity(0.0)
  }

  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  
  @State sidebarVisible: boolean = true;
  @State projectGroup: ProjectGroup | null = null;
  @State selectedProjectRef: ProjectRef | null = null;
  @State projectList: ProjectMeta[] = []; // 可添加的项目列表
  
  // 画布相关状态
  private canvasController: CanvasController = new CanvasController();
  @State canvasLock: boolean = false;
  @State canvasRenderMode: RenderMode = RenderMode.NORMAL;
  @State zoomScale: number = 1.0;
  @State canvasOpacity: number = 0;
  
  // 工具栏状态
  @State toolbarExpanded: boolean = false;
  @State zoomPanelExpanded: boolean = false;
  
  // 响应式布局
  @State screenWidth: number = 0;
  @State isPhone: boolean = false;
  
  private projectGroupService: ProjectGroupService = ProjectGroupService.getInstance();
  private storageService: StorageService | null = null;
  private exportService: ExportService | null = null;
  private templateService: TemplateService = TemplateService.getInstance();
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private eventBus: EventBus = EventBus.getInstance();
  private appState: AppState = AppState.getInstance();

  async aboutToAppear() {
    console.log('[ProjectGroupIndex] aboutToAppear');
    
    // 初始化屏幕尺寸
    this.updateScreenSize();
    
    // 初始化存储服务
    this.storageService = StorageService.getInstance(
      (this.uiContext.getHostContext() as common.UIAbilityContext).filesDir
    );

    // 初始化导出服务
    const fileStorageService = FileStorageService.getInstance(
      (this.uiContext.getHostContext() as common.UIAbilityContext).filesDir
    );
    this.exportService = ExportService.getInstance(fileStorageService);
    this.exportService.setContext(this.uiContext.getHostContext() as common.UIAbilityContext);

    // 初始化项目集服务
    await this.projectGroupService.initialize(
      (this.uiContext.getHostContext() as common.UIAbilityContext).filesDir
    );
    this.projectGroupService.setContext(this.uiContext);

    // 设置画布控制器回调
    this.canvasController.setCallbacks(
      (task) => this.handleTaskSelect(task),
      (fromId, toId) => this.handleDependencyCreate(fromId, toId),
      (taskId, x, y) => this.handleTaskMove(taskId, x, y),
      (taskId, x, y) => this.handleTaskMoveImmediate(taskId, x, y)
    );
    this.canvasController.setContext(this.uiContext);

    // 根据设备类型设置渲染模式
    const targetRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
    this.canvasRenderMode = targetRenderMode;
    this.canvasController.setRenderMode(targetRenderMode);

    // 监听事件
    this.setupEventListeners();

    // 加载可用项目列表
    await this.loadProjectList();

    // 从路由参数中获取groupId
    const params = this.uiContext.getRouter().getParams() as RouterParams;
    const groupId = params?.groupId;

    if (groupId) {
      // 加载现有项目集
      console.log(`[ProjectGroupIndex] Loading project group: ${groupId}`);
      await this.projectGroupService.getActions().loadProjectGroup(groupId);
      this.updateStateFromService();
    } else {
      // 创建新项目集
      console.log('[ProjectGroupIndex] Creating new project group');
      await this.createNewProjectGroup();
    }

    // 延迟显示画布（避免闪烁）
    setTimeout(() => {
      this.canvasOpacity = 1;
    }, 100);
  }

  aboutToDisappear() {
    this.canvasOpacity = 0;
    // 保存项目集
    if (this.projectGroup) {
      this.projectGroupService.getActions().saveProjectGroup();
    }
  }

  /**
   * 更新屏幕尺寸
   */
  private updateScreenSize() {
    try {
      this.screenWidth = 840;
      this.isPhone = false;
    } catch (error) {
      console.error('[ProjectGroupIndex] Error getting screen size:', error);
      this.screenWidth = 840;
      this.isPhone = false;
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听项目集加载事件
    this.eventBus.on('project_group_loaded', () => {
      this.updateStateFromService();
      this.drawGraph();
    });

    // 监听项目集保存事件
    this.eventBus.on('project_group_saved', () => {
      this.updateStateFromService();
      this.drawGraph();
    });

    // 监听项目引用选择事件
    this.eventBus.on('project_ref_selected', () => {
      this.updateStateFromService();
      this.drawGraph();
    });
  }

  /**
   * 从服务更新状态
   */
  private updateStateFromService(): void {
    const state = this.projectGroupService.getState();
    this.projectGroup = state.projectGroup;
    this.selectedProjectRef = state.selectedProjectRef;
  }

  /**
   * 加载项目列表（用于添加到项目集）
   */
  private async loadProjectList(): Promise<void> {
    if (this.storageService) {
      try {
        this.projectList = await this.storageService.getProjectList();
        console.log(`[ProjectGroupIndex] Loaded ${this.projectList.length} projects`);
      } catch (error) {
        console.error('[ProjectGroupIndex] Failed to load project list:', error);
      }
    }
  }

  /**
   * 创建新项目集
   */
  private async createNewProjectGroup(): Promise<void> {
    await this.projectGroupService.getActions().createNewProjectGroup('新项目集');
    this.updateStateFromService();
    this.drawGraph();
  }

  /**
   * 将 ProjectGroup 转换为 Project（适配器模式）
   * 这样就可以复用现有的 CanvasController 渲染逻辑
   */
  private convertProjectGroupToProject(projectGroup: ProjectGroup): Project {
    const project = new Project(projectGroup.id, projectGroup.name);
    
    // 将 ProjectRef 转换为 TaskNode
    project.tasks = projectGroup.projectRefs.map((ref: ProjectRef): TaskNode => {
      const task: TaskNode = {
        id: ref.id,
        name: ref.name,
        x: ref.x,
        y: ref.y,
        startDate: new Date(),
        endDate: new Date(),
        checklist: [],
        isCritical: ref.isCritical || false,
        earlyStart: ref.earlyStart || 0,
        earlyFinish: ref.earlyFinish || 0,
        lateStart: ref.lateStart || 0,
        lateFinish: ref.lateFinish || 0
      };
      return task;
    });

    // 将 ProjectDependency 转换为 Dependency
    project.dependencies = projectGroup.dependencies.map((dep: ProjectDependency): Dependency => {
      const dependency: Dependency = {
        fromId: dep.fromId,
        toId: dep.toId
      };
      return dependency;
    });

    // 同步画布状态
    project.canvasOffsetX = projectGroup.canvasOffsetX || 0;
    project.canvasOffsetY = projectGroup.canvasOffsetY || 0;
    project.zoomScale = projectGroup.zoomScale || 1.0;

    return project;
  }

  /**
   * 渲染画布（复用 Index.ets 的 drawGraph 模式）
   */
  private drawGraph(): void {
    if (!this.projectGroup) return;
    
    // 转换为 Project 并渲染
    const adaptedProject = this.convertProjectGroupToProject(this.projectGroup);
    const renderConfig = this.canvasController.getActions().getRenderConfig(
      this.selectedProjectRef?.id || null
    );
    this.canvasController.getRenderer().render(adaptedProject, renderConfig);
    this.zoomScale = this.canvasController.getState().zoomScale;
  }

  /**
   * 画布 onReady 回调
   */
  private handleCanvasReady(): void {
    console.log('[ProjectGroupIndex] Canvas ready');
    // 延迟渲染，确保所有组件已经初始化
    setTimeout(() => {
    this.drawGraph();
      // 确保画布透明度为1
      if (this.canvasOpacity < 1) {
        this.canvasOpacity = 1;
      }
    }, 50);
  }

  /**
   * 任务选择回调（实际是项目引用选择）
   */
  private handleTaskSelect(task: TaskNode | null): void {
    if (!task) {
      this.projectGroupService.getActions().selectProjectRef(null);
      return;
    }

    // 查找对应的 ProjectRef
    const projectRef = this.projectGroup?.projectRefs.find(ref => ref.id === task.id);
    if (projectRef) {
      this.projectGroupService.getActions().selectProjectRef(projectRef);
    }
  }

  /**
   * 依赖创建回调
   */
  private handleDependencyCreate(fromId: string, toId: string): void {
    this.projectGroupService.getActions().addDependency(fromId, toId);
  }

  /**
   * 任务移动回调（拖拽结束）
   */
  private handleTaskMove(taskId: string, x: number, y: number): void {
    this.projectGroupService.getActions().moveProjectRef(taskId, x, y);
  }

  /**
   * 任务移动即时回调（拖拽中）
   */
  private handleTaskMoveImmediate(taskId: string, x: number, y: number): void {
    this.projectGroupService.getActions().moveProjectRefImmediate(taskId, x, y);
  }

  /**
   * 返回项目集列表
   */
  private handleBackToHome(): void {
    this.uiContext.getRouter().back();
  }

  /**
   * 开始连接模式
   */
  private handleStartConnecting(): void {
    if (!this.selectedProjectRef) {
      this.promptAction.showToast({ message: '请先选择一个项目' });
      return;
    }
    this.canvasController.getActions().startConnecting(this.selectedProjectRef.id);
    this.promptAction.showToast({ message: '连接模式：点击目标项目创建依赖' });
  }

  /**
   * 切换画布锁定
   */
  private toggleCanvasLock(): void {
    this.canvasLock = !this.canvasLock;
    this.canvasController.getActions().toggleCanvasLock();
  }

  /**
   * 重置画布位置
   */
  private resetCanvas(): void {
    if (!this.projectGroup) return;
    
    this.canvasController.getActions().resetCanvas();
    this.projectGroup.canvasOffsetX = 0;
    this.projectGroup.canvasOffsetY = 0;
    this.drawGraph();
    this.promptAction.showToast({ message: '画布已重置' });
  }

  /**
   * 切换渲染模式
   */
  private toggleRenderMode(): void {
    this.canvasRenderMode = this.canvasRenderMode === RenderMode.NORMAL 
      ? RenderMode.COMPACT 
      : RenderMode.NORMAL;
    this.canvasController.setRenderMode(this.canvasRenderMode);
    this.drawGraph();
  }

  /**
   * 设置缩放比例
   */
  private setZoomScale(scale: number): void {
    this.zoomScale = Math.max(0.5, Math.min(2.0, scale));
    if (this.projectGroup) {
      this.projectGroup.zoomScale = this.zoomScale;
    }
    this.drawGraph();
  }

  build() {
    Stack() {
      // 画布区域（全屏）
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
          .onReady(() => this.handleCanvasReady())
          .onTouch((event: TouchEvent) => {
            if (!this.projectGroup) return;
            const adaptedProject = this.convertProjectGroupToProject(this.projectGroup);
            this.canvasController.getActions().handleTouch(
              event, 
              adaptedProject, 
              this.selectedProjectRef?.id || null
            );
            this.drawGraph();
          })
      }
      .width('100%')
      .height('100%')

      // 侧边栏（覆盖在画布上）
      if (this.sidebarVisible && this.projectGroup) {
        this.ProjectGroupSidebar()
      }

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

      // 顶部工具栏
      this.TopToolbar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight)
    })
  }

  // 画布背景构建器 - 自适应背景灰色网格（完全复用 Index.ets 的设计）
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
  }

  // 项目集专用侧边栏
  @Builder
  ProjectGroupSidebar() {
    Column({ space: 16 }) {
      // --- 顶部操作栏 ---
      Row({ space: 16 }) {
        // 返回按钮
        Button() {
          Text('←')
            .fontSize(ThemeConfig.fontSizeXL)
            .fontColor(ColorResource.surfaceBold)
            .fontWeight(ThemeConfig.fontWeightBold)
        }
        .width(52)
        .height(52)
        .type(ButtonType.Circle)
        .backgroundColor(ColorResource.surfaceLight)
        .borderRadius(26)
        .shadow(ThemeConfig.shadowMedium)
        .border({ width: 2, color: ColorResource.surfaceNeutral, radius: 26 })
        .onClick(() => this.handleBackToHome())

        // 新增项目按钮（项目集特色）
        Button({ type: ButtonType.Circle }) {
          Text('+')
              .fontSize(ThemeConfig.fontSizeXL)
            .fontColor(Color.White)
              .fontWeight(ThemeConfig.fontWeightBold)
        }
        .width(52)
        .height(52)
        .backgroundColor(ColorResource.primaryColor)
        .borderRadius(26)
        .shadow(ThemeConfig.shadowLarge)
        .border({ width: 2, color: ColorResource.primaryDark, radius: 26 })
        .onClick(() => this.handleAddProject())

        // 保存按钮
        Button() {
          Text('💾')
            .fontSize(20)
        }
        .width(52)
        .height(52)
        .type(ButtonType.Circle)
        .backgroundColor(ColorResource.successLight)
        .borderRadius(26)
        .shadow(ThemeConfig.shadowMedium)
        .border({ width: 2, color: ColorResource.successColor, radius: 26 })
        .onClick(() => {
          this.projectGroupService.getActions().saveProjectGroup();
          this.promptAction.showToast({ message: '项目集已保存' });
        })

        // 导出按钮
        Button() {
          Text('📤')
            .fontSize(20)
        }
        .width(52)
        .height(52)
        .type(ButtonType.Circle)
        .backgroundColor(ColorResource.infoLight)
        .borderRadius(26)
        .shadow(ThemeConfig.shadowMedium)
        .border({ width: 2, color: ColorResource.infoColor, radius: 26 })
        .bindMenu(this.ExportMenu())
          }
          .width('100%')
      .padding({ top: 8 })

      // --- 项目集信息 ---
      Column({ space: 12 }) {
        // 项目集名称
        Row() {
          Text(this.projectGroup?.name || '未命名项目集')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorResource.textPrimary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })

        // 统计信息卡片
        Row({ space: 12 }) {
          // 项目数量
          Column({ space: 4 }) {
            Text(`${this.projectGroup?.projectRefs.length || 0}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorResource.primaryColor)
            Text('项目数')
              .fontSize(12)
              .fontColor(ColorResource.textSecondary)
          }
              .layoutWeight(1)
          .padding(12)
          .backgroundColor(ColorResource.primaryUltraLight)
          .borderRadius(12)
          .border({ width: 1, color: ColorResource.primaryLight })

          // 依赖数量
          Column({ space: 4 }) {
            Text(`${this.projectGroup?.dependencies.length || 0}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorResource.infoColor)
            Text('依赖关系')
              .fontSize(12)
              .fontColor(ColorResource.textSecondary)
          }
              .layoutWeight(1)
          .padding(12)
          .backgroundColor(ColorResource.infoLight)
          .borderRadius(12)
          .border({ width: 1, color: ColorResource.infoColor })
          }
          .width('100%')
        }
        .width('100%')
      .padding(16)
      .backgroundColor(ColorResource.surfaceLight)
      .borderRadius(ThemeConfig.radiusLarge)
      .border({ width: 1, color: ColorResource.surfaceNeutral })

      // --- 项目列表 ---
      Column({ space: 8 }) {
        // 列表标题
        Row() {
          Text('📋 项目列表')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
          
          Blank()

          // 连接模式按钮
          Button() {
            Text('🔗')
              .fontSize(14)
          }
          .width(32)
          .height(32)
          .type(ButtonType.Circle)
          .backgroundColor(ColorResource.surfaceLight)
          .border({ width: 1, color: ColorResource.surfaceNeutral })
          .onClick(() => this.handleStartConnecting())
        }
        .width('100%')
        .padding({ bottom: 8 })

        // 项目列表滚动区域
          if (this.projectGroup && this.projectGroup.projectRefs.length > 0) {
          List({ space: 8 }) {
              ForEach(this.projectGroup.projectRefs, (projectRef: ProjectRef) => {
                ListItem() {
                this.ProjectRefItem(projectRef)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
        } else {
          Column({ space: 12 }) {
            Text('📦')
              .fontSize(48)
              .opacity(0.3)
            Text('暂无项目')
              .fontSize(16)
              .fontColor(ColorResource.textTertiary)
            Text('点击上方 + 按钮添加项目')
              .fontSize(13)
              .fontColor(ColorResource.textTertiary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(40)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding(16)
      .backgroundColor(ColorResource.surface)
      .borderRadius(ThemeConfig.radiusLarge)
      .border({ width: 1, color: ColorResource.surfaceNeutral })
    }
    .width(380)
    .height('100%')
    .backgroundColor(ColorResource.overlayStrong)
    .padding(ThemeConfig.spacingXXL)
    .shadow(ThemeConfig.shadowMedium)
    .border({ width: { right: 1 }, color: ColorResource.surfaceNeutral })
    .backdropBlur(ThemeConfig.backdropBlurMedium)
    .position({ x: 0, y: 0 })
    .zIndex(150)
  }

  // 项目引用项组件
  @Builder
  ProjectRefItem(projectRef: ProjectRef) {
    Row({ space: 12 }) {
      // 项目图标
      Text('📁')
        .fontSize(24)

      // 项目信息
                    Column({ space: 4 }) {
                      Text(projectRef.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedProjectRef?.id === projectRef.id 
            ? ColorResource.primaryColor 
            : ColorResource.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 关键路径标识
        if (projectRef.isCritical) {
          Text('⭐ 关键路径')
            .fontSize(11)
            .fontColor(ColorResource.warningColor)
            .fontWeight(FontWeight.Medium)
        }
      }
                    .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 删除按钮
      Button() {
        Text('×')
          .fontSize(18)
          .fontColor(ColorResource.errorColor)
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .type(ButtonType.Circle)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.handleDeleteProjectRef(projectRef))
                  }
                  .width('100%')
    .padding(12)
                  .backgroundColor(this.selectedProjectRef?.id === projectRef.id 
                    ? ColorResource.primaryUltraLight 
      : ColorResource.surfaceLight)
    .borderRadius(12)
                  .border({
      width: 2,
                    color: this.selectedProjectRef?.id === projectRef.id 
                      ? ColorResource.primaryColor 
        : ColorResource.surfaceNeutral
                  })
                  .onClick(() => {
                    this.projectGroupService.getActions().selectProjectRef(projectRef);
      this.drawGraph();
    })
  }

  // 导出菜单
  @Builder
  ExportMenu() {
    Menu() {
      MenuItem({ 
        content: '导出为 JSON',
        labelInfo: '项目集数据文件'
      })
        .onChange(() => {
          this.promptAction.showToast({ message: '导出功能开发中' });
        })

      MenuItem({ 
        content: '导出为图片',
        labelInfo: 'PNG/JPG 格式'
      })
        .onChange(async () => {
          if (this.projectGroup) {
            const adaptedProject = this.convertProjectGroupToProject(this.projectGroup);
            const pixelMap = await this.canvasController.getCanvasPixelMap(
              adaptedProject,
              this.selectedProjectRef?.id
            );
            if (pixelMap && this.exportService) {
              this.promptAction.showToast({ message: '正在导出图片...' });
            }
          }
        })
    }
  }

  // 添加项目到项目集
  private handleAddProject(): void {
    if (!this.projectGroup) return;

    // 显示项目创建/选择菜单
    this.promptAction.showActionMenu({
      title: '添加项目到项目集',
      buttons: [
        {
          text: '创建空白项目',
          color: ColorResource.primaryColor
        },
        {
          text: '从模板创建',
          color: ColorResource.primaryColor
        },
        {
          text: '选择已有项目',
          color: ColorResource.infoColor
        }
      ]
    }).then((result) => {
      if (result.index === 0) {
        // 创建空白项目
        this.createBlankProjectForGroup();
      } else if (result.index === 1) {
        // 从模板创建
        this.createProjectFromTemplateForGroup();
      } else if (result.index === 2) {
        // 选择已有项目
        this.selectExistingProjectForGroup();
      }
    }).catch((error: Error) => {
      console.error('[ProjectGroupIndex] ActionMenu error:', error);
    });
  }

  /**
   * 创建空白项目并添加到项目集
   */
  private async createBlankProjectForGroup(): Promise<void> {
    if (!this.projectGroup || !this.storageService) return;

    try {
      this.promptAction.showToast({
        message: '正在创建项目...',
        duration: 1000
      });

      // 创建空白项目
      const newProject = this.templateService.createProjectFromTemplate('blank', '新项目');
      
      // 保存项目
      await this.storageService.saveProject(newProject);
      
      // 添加到项目集
      this.projectGroupService.getActions().addProjectRef(
        newProject.id,
        newProject.name,
        100,
        100
      );

      // 刷新项目列表
      await this.loadProjectList();
      
      this.promptAction.showToast({
        message: `项目 "${newProject.name}" 已创建并添加到项目集`,
        duration: 2000
      });

      this.drawGraph();
    } catch (error) {
      console.error('[ProjectGroupIndex] Create blank project error:', error);
      this.promptAction.showToast({
        message: '创建项目失败',
        duration: 2000
      });
    }
  }

  /**
   * 从模板创建项目并添加到项目集
   */
  private createProjectFromTemplateForGroup(): void {
    // 显示模板分类选择
    this.promptAction.showActionMenu({
      title: '选择项目类型',
      buttons: [
        {
          text: '软件开发',
          color: ColorResource.projectDevelopment
        },
        {
          text: '营销活动',
          color: ColorResource.projectMarketing
        },
        {
          text: '研究分析',
          color: ColorResource.projectResearch
        }
      ]
    }).then((result) => {
      let category = '开发';
      if (result.index === 0) category = '开发';
      else if (result.index === 1) category = '营销';
      else if (result.index === 2) category = '研究';

      // 获取该分类的模板
      const templates = this.templateService.getTemplatesByCategory(category);
      if (templates.length === 0) {
        this.promptAction.showToast({ message: '该分类下没有可用模板' });
        return;
      }

      // 显示模板列表
      this.showTemplateListForGroup(templates);
    }).catch((error: Error) => {
      console.error('[ProjectGroupIndex] Template category error:', error);
    });
  }

  /**
   * 显示模板列表并创建项目
   */
  private showTemplateListForGroup(templates: ProjectTemplate[]): void {
    const maxTemplates = Math.min(templates.length, 3);
    const buttons: ActionMenuButton[] = templates.slice(0, maxTemplates).map((t: ProjectTemplate): ActionMenuButton => ({
      text: `${t.name} (${t.tasks.length}个任务)`,
      color: ColorResource.primaryColor
    }));

    if (buttons.length === 0) return;

    this.promptAction.showActionMenu({
      title: '选择模板',
      buttons: buttons.length === 1 ? [buttons[0]] :
              buttons.length === 2 ? [buttons[0], buttons[1]] :
              [buttons[0], buttons[1], buttons[2]]
    }).then(async (result) => {
      if (result.index < maxTemplates && this.projectGroup && this.storageService) {
        const template: ProjectTemplate = templates[result.index];
        
        try {
          this.promptAction.showToast({
            message: '正在创建项目...',
            duration: 1000
          });

          // 从模板创建项目
          const newProject = this.templateService.createProjectFromTemplate(template.id, template.name);
          
          // 保存项目
          await this.storageService.saveProject(newProject);
          
          // 添加到项目集
          this.projectGroupService.getActions().addProjectRef(
            newProject.id,
            newProject.name,
            100,
            100
          );

          // 刷新项目列表
          await this.loadProjectList();
          
          this.promptAction.showToast({
            message: `项目 "${newProject.name}" 已创建并添加到项目集`,
            duration: 2000
          });

          this.drawGraph();
        } catch (error) {
          console.error('[ProjectGroupIndex] Create project from template error:', error);
          this.promptAction.showToast({
            message: '创建项目失败',
            duration: 2000
          });
        }
      }
    }).catch((error: Error) => {
      console.error('[ProjectGroupIndex] Template selection error:', error);
    });
  }

  /**
   * 选择已有项目添加到项目集
   */
  private selectExistingProjectForGroup(): void {
    if (!this.projectGroup) return;

    // 过滤出未添加的项目
    const availableProjects = this.projectList.filter((p: ProjectMeta) => 
      !this.projectGroup!.projectRefs.some((ref: ProjectRef) => ref.id === p.id)
    );

    if (availableProjects.length === 0) {
      this.promptAction.showToast({
        message: '没有可添加的项目，所有项目都已在项目集中',
        duration: 2000
      });
      return;
    }

    // 显示项目列表
    const maxProjects = Math.min(availableProjects.length, 5);
    const buttons: ActionMenuButton[] = availableProjects.slice(0, maxProjects).map((p: ProjectMeta): ActionMenuButton => ({
      text: `${p.name} (${new Date(p.lastModified).toLocaleDateString()})`,
      color: ColorResource.infoColor
    }));

    this.promptAction.showActionMenu({
      title: '选择要添加的项目',
      buttons: buttons.length === 1 ? [buttons[0]] :
              buttons.length === 2 ? [buttons[0], buttons[1]] :
              buttons.length === 3 ? [buttons[0], buttons[1], buttons[2]] :
              buttons.length === 4 ? [buttons[0], buttons[1], buttons[2], buttons[3]] :
              [buttons[0], buttons[1], buttons[2], buttons[3], buttons[4]]
    }).then((result) => {
      if (result.index < maxProjects) {
        const selectedProject: ProjectMeta = availableProjects[result.index];
        
        // 添加项目引用到项目集
        this.projectGroupService.getActions().addProjectRef(
          selectedProject.id,
          selectedProject.name,
          100 + result.index * 50,
          100 + result.index * 50
        );

        this.promptAction.showToast({
          message: `已添加项目 "${selectedProject.name}"`,
          duration: 2000
        });

        this.drawGraph();
      }
    }).catch((error: Error) => {
      console.error('[ProjectGroupIndex] Project selection error:', error);
    });
  }

  // 删除项目引用
  private handleDeleteProjectRef(projectRef: ProjectRef): void {
    this.uiContext.showAlertDialog({
      title: '确认移除项目',
      message: `确定要从项目集中移除"${projectRef.name}"吗？\n\n注意：这只会移除引用，不会删除实际项目。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '移除',
        fontColor: ColorResource.errorColor,
        action: () => {
          this.projectGroupService.getActions().deleteProjectRef(projectRef.id);
          this.drawGraph();
          this.promptAction.showToast({ message: '已移除项目' });
        }
      }
    });
  }

  // 顶部工具栏（复用 Index.ets 的设计）
  @Builder
  TopToolbar() {
    Column() {
      if (this.toolbarExpanded) {
        // 展开的工具栏
        Row({ space: 8 }) {
          // 锁定/解锁按钮
          Button() {
            Row({ space: 4 }) {
              Text(this.canvasLock ? '🔒' : '🔓')
                .fontSize(16)
              Text(this.canvasLock ? '已锁定' : '已解锁')
                .fontSize(12)
                .fontColor(this.canvasLock ? ColorResource.warningColor : ColorResource.successColor)
                .fontWeight(FontWeight.Medium)
            }
          }
          .height(32)
          .padding({ left: 10, right: 10 })
          .backgroundColor(this.canvasLock ? ColorResource.warningLight : ColorResource.successLight)
          .borderRadius(16)
          .border({
            width: 1.5,
            color: this.canvasLock ? ColorResource.warningColor : ColorResource.successColor
          })
          .onClick(() => this.toggleCanvasLock())

          // 重置按钮
          Button() {
            Row({ space: 4 }) {
              Text('🔄')
                .fontSize(16)
              Text('重置')
                .fontSize(12)
                .fontColor(ColorResource.infoColor)
                .fontWeight(FontWeight.Medium)
            }
          }
          .height(32)
          .padding({ left: 10, right: 10 })
          .backgroundColor(ColorResource.infoLight)
          .borderRadius(16)
          .border({ width: 1.5, color: ColorResource.infoColor })
          .onClick(() => this.resetCanvas())

          // 分隔线
          Column()
            .width(1)
            .height(24)
            .backgroundColor(ColorResource.surfaceNeutral)
            .margin({ left: 4, right: 4 })

          // 渲染模式切换
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
          .onClick(() => this.toggleRenderMode())

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
      } else {
        // 收起的工具栏（汉堡按钮）
        Button() {
          Text('☰')
            .fontSize(20)
            .fontColor(ColorResource.primaryColor)
            .fontWeight(FontWeight.Bold)
        }
        .width(40)
        .height(40)
        .type(ButtonType.Circle)
        .backgroundColor(ColorResource.surface)
        .border({ width: 2, color: ColorResource.primaryColor })
        .shadow(ThemeConfig.shadowMedium)
        .onClick(() => {
          this.uiContext.animateTo({
            duration: 180,
            curve: Curve.EaseInOut
          }, () => {
            this.toolbarExpanded = true;
          });
        })
      }
    }
    .justifyContent(FlexAlign.End)
    .padding({ right: 12, top: 12 })
    .position({ x: '100%', y: 0 })
    .translate({ x: '-100%', y: 0 })
    .zIndex(100)
  }
}
