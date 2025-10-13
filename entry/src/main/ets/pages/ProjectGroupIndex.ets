// File: entry/src/main/ets/pages/ProjectGroupIndex.ets
/**
 * 项目群编辑页面模块
 *
 * 本页面是项目群管理的核心编辑界面，完全复用 Index.ets 的设计模式和代码结构。
 * 采用适配器模式，将 ProjectGroup 映射为 Project 结构，从而复用现有的画布渲染和交互逻辑。
 * 
 * 架构层级：
 * - ProjectGroupHome.ets：项目群列表页面（类似 Home.ets）
 * - ProjectGroupIndex.ets：项目群编辑页面（类似 Index.ets）← 当前页面
 *
 * 主要功能：
 * 1. 项目群可视化：使用现有的 Canvas 2D 技术绘制项目网络图
 * 2. 项目管理：支持项目的添加、删除、移动等操作
 * 3. 依赖关系：可视化创建和管理项目间的依赖关系
 * 4. 关键路径：计算和显示项目群的关键路径
 * 5. 交互操作：完全复用 Index.ets 的拖拽、点击、连接等交互
 *
 * 设计特点：
 * - 适配器模式：ProjectGroup → Project 映射
 * - 完全复用：复用 CanvasController、样式、交互逻辑
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
import { BreakpointSystem } from '../utils/BreakpointSystem';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { EventBus } from '../core/EventBus';
import { AppState } from '../core/AppState';

/**
 * 路由参数接口
 */
interface RouterParams {
  /** 项目群ID，用于加载指定项目群 */
  groupId?: string;
}

@Entry
@Component
struct ProjectGroupView {
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
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private eventBus: EventBus = EventBus.getInstance();
  private appState: AppState = AppState.getInstance();

  async aboutToAppear() {
    console.log('[ProjectGroupView] aboutToAppear');
    
    // 初始化屏幕尺寸
    this.updateScreenSize();
    
    // 初始化存储服务
    this.storageService = StorageService.getInstance(
      (this.uiContext.getHostContext() as common.UIAbilityContext).filesDir
    );

    // 初始化项目群服务
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
      // 加载现有项目群
      console.log(`[ProjectGroupView] Loading project group: ${groupId}`);
      await this.projectGroupService.getActions().loadProjectGroup(groupId);
      this.updateStateFromService();
    } else {
      // 创建新项目群
      console.log('[ProjectGroupView] Creating new project group');
      await this.createNewProjectGroup();
    }

    // 延迟显示画布（避免闪烁）
    setTimeout(() => {
      this.canvasOpacity = 1;
    }, 100);
  }

  aboutToDisappear() {
    this.canvasOpacity = 0;
    // 保存项目群
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
      console.error('[ProjectGroupView] Error getting screen size:', error);
      this.screenWidth = 840;
      this.isPhone = false;
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听项目群加载事件
    this.eventBus.on('project_group_loaded', () => {
      this.updateStateFromService();
      this.drawGraph();
    });

    // 监听项目群保存事件
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
   * 加载项目列表（用于添加到项目群）
   */
  private async loadProjectList(): Promise<void> {
    if (this.storageService) {
      try {
        this.projectList = await this.storageService.getProjectList();
        console.log(`[ProjectGroupView] Loaded ${this.projectList.length} projects`);
      } catch (error) {
        console.error('[ProjectGroupView] Failed to load project list:', error);
      }
    }
  }

  /**
   * 创建新项目群
   */
  private async createNewProjectGroup(): Promise<void> {
    await this.projectGroupService.getActions().createNewProjectGroup('新项目群');
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
    console.log('[ProjectGroupView] Canvas ready');
    this.drawGraph();
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
   * 返回主页
   */
  private handleBackToHome(): void {
    this.uiContext.getRouter().back();
  }

  /**
   * 保存项目群
   */
  private async handleSave(): Promise<void> {
    await this.projectGroupService.getActions().saveProjectGroup();
    this.promptAction.showToast({ message: '项目群已保存' });
  }

  /**
   * 添加项目到项目群
   */
  private handleAddProject(projectId: string, projectName: string): void {
    const x = 200 + Math.random() * 100;
    const y = 150 + Math.random() * 100;
    this.projectGroupService.getActions().addProjectRef(projectId, projectName);
    this.updateStateFromService();
    this.drawGraph();
  }

  /**
   * 删除项目引用
   */
  private handleDeleteProjectRef(): void {
    if (!this.selectedProjectRef) return;

    this.uiContext.showAlertDialog({
      title: '确认删除',
      message: '确定要从项目群中移除这个项目吗？（不会删除项目本身）',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '移除',
        fontColor: ColorResource.errorColor,
        action: () => {
          if (this.selectedProjectRef) {
            this.projectGroupService.getActions().deleteProjectRef(this.selectedProjectRef.id);
            this.updateStateFromService();
            this.drawGraph();
            this.promptAction.showToast({ message: '项目已移除' });
          }
        }
      }
    });
  }

  /**
   * 打开选中的项目
   */
  private handleOpenProject(): void {
    if (!this.selectedProjectRef) return;

    this.uiContext.getRouter().pushUrl({
      url: 'pages/Index',
      params: { projectId: this.selectedProjectRef.id }
    } as router.RouterOptions);
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
        this.SidebarContent()
      }

      // 画布区域
      this.CanvasArea()
      
      // 顶部工具栏（复用 Index.ets 的设计）
      this.TopToolbar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight)
    })
  }

  // 侧边栏内容
  @Builder
  SidebarContent() {
    Column({ space: 0 }) {
      // 顶部 - 项目群信息
      Column({ space: ThemeConfig.spacingM }) {
        Row({ space: ThemeConfig.spacingM }) {
          Text('项目群管理')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.surfaceDeep)
            .layoutWeight(1)
          
          Button('返回')
            .height(36)
            .padding({ left: 16, right: 16 })
            .backgroundColor(ColorResource.surfaceLight)
            .fontColor(ColorResource.surfaceDeep)
            .onClick(() => this.handleBackToHome())
        }
        .width('100%')

        if (this.projectGroup) {
          TextInput({ text: this.projectGroup.name })
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightMedium)
            .backgroundColor(ColorResource.surface)
            .onChange((value: string) => {
              this.projectGroupService.getActions().updateProjectGroupName(value);
            })
        }
      }
      .width('100%')
      .padding(ThemeConfig.spacingL)
      .backgroundColor(ColorResource.surface)
      .border({ width: { bottom: 1 }, color: ColorResource.borderDivider })

      // 选中项目的详情（类似任务编辑器）
      if (this.selectedProjectRef) {
        Column({ space: ThemeConfig.spacingM }) {
          Text('项目详情')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.surfaceDeep)

          Column({ space: ThemeConfig.spacingS }) {
            Text(this.selectedProjectRef.name)
              .fontSize(ThemeConfig.fontSizeXL)
              .fontWeight(ThemeConfig.fontWeightBold)
              .fontColor(ColorResource.primaryColor)
            
            Text(`ID: ${this.selectedProjectRef.id}`)
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textMuted)
          }
          .width('100%')
          .padding(ThemeConfig.spacingM)
          .backgroundColor(ColorResource.surface)
          .borderRadius(ThemeConfig.radiusMedium)

          // 操作按钮
          Row({ space: ThemeConfig.spacingM }) {
            Button('打开项目')
              .layoutWeight(1)
              .backgroundColor(ColorResource.primaryColor)
              .fontColor(Color.White)
              .onClick(() => this.handleOpenProject())

            Button('移除')
              .layoutWeight(1)
              .backgroundColor(ColorResource.errorLight)
              .fontColor(ColorResource.errorColor)
              .onClick(() => this.handleDeleteProjectRef())
          }
          .width('100%')
        }
        .width('100%')
        .padding(ThemeConfig.spacingL)
        .layoutWeight(1)
      } else {
        // 项目群中的项目列表
        Column({ space: ThemeConfig.spacingM }) {
          Text('项目群中的项目')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.surfaceDeep)

          if (this.projectGroup && this.projectGroup.projectRefs.length > 0) {
            List({ space: ThemeConfig.spacingS }) {
              ForEach(this.projectGroup.projectRefs, (projectRef: ProjectRef) => {
                ListItem() {
                  Row({ space: ThemeConfig.spacingM }) {
                    Column({ space: 4 }) {
                      Text(projectRef.name)
                        .fontSize(ThemeConfig.fontSizeM)
                        .fontWeight(ThemeConfig.fontWeightMedium)
                        .fontColor(ColorResource.surfaceDeep)
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding(ThemeConfig.spacingM)
                  .backgroundColor(this.selectedProjectRef?.id === projectRef.id 
                    ? ColorResource.primaryUltraLight 
                    : ColorResource.surface)
                  .borderRadius(ThemeConfig.radiusMedium)
                  .border({
                    width: this.selectedProjectRef?.id === projectRef.id ? 2 : 1,
                    color: this.selectedProjectRef?.id === projectRef.id 
                      ? ColorResource.primaryColor 
                      : ColorResource.borderDivider
                  })
                  .onClick(() => {
                    this.projectGroupService.getActions().selectProjectRef(projectRef);
                  })
                }
              })
            }
            .layoutWeight(1)
          } else {
            Column({ space: ThemeConfig.spacingM }) {
              Text('项目群为空')
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ColorResource.textMuted)
              Text('从下方选择项目添加到项目群')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ColorResource.textSubdued)
            }
            .width('100%')
            .padding(ThemeConfig.spacingXL)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .padding(ThemeConfig.spacingL)
        .layoutWeight(1)
      }

      // 可添加的项目列表
      Column({ space: ThemeConfig.spacingM }) {
        Text('添加项目')
          .fontSize(ThemeConfig.fontSizeL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.surfaceDeep)

        if (this.projectList.length > 0) {
          List({ space: ThemeConfig.spacingS }) {
            ForEach(this.projectList, (project: ProjectMeta) => {
              ListItem() {
                Row({ space: ThemeConfig.spacingM }) {
                  Column({ space: 4 }) {
                    Text(project.name)
                      .fontSize(ThemeConfig.fontSizeM)
                      .fontWeight(ThemeConfig.fontWeightMedium)
                      .fontColor(ColorResource.surfaceDeep)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Button('+')
                    .width(32)
                    .height(32)
                    .type(ButtonType.Circle)
                    .backgroundColor(ColorResource.primaryColor)
                    .fontColor(Color.White)
                    .onClick(() => this.handleAddProject(project.id, project.name))
                }
                .width('100%')
                .padding(ThemeConfig.spacingM)
                .backgroundColor(ColorResource.surfaceLight)
                .borderRadius(ThemeConfig.radiusMedium)
              }
            })
          }
          .height(200)
        }
      }
      .width('100%')
      .padding(ThemeConfig.spacingL)
      .backgroundColor(ColorResource.surface)
      .border({ width: { top: 1 }, color: ColorResource.borderDivider })
    }
    .width(380)
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(150)
    .backgroundColor(ColorResource.backgroundPage)
    .shadow(ThemeConfig.shadowLarge)
  }

  // 画布区域（完全复用 Index.ets 的设计）
  @Builder
  CanvasArea() {
    Stack() {
      // 画布背景 - 格子纹效果
      this.CanvasBackground()

      // 画布
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
    .margin({ left: this.sidebarVisible ? 380 : 0 })
  }

  // 画布背景构建器 - 自适应背景灰色网格（复用 Index.ets 的设计）
  @Builder
  CanvasBackground() {
    Stack() {
      // 背景色
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ColorResource.surface)

      // 网格线层
      Column() {
        // 主要网格线
        Stack() {
          // 垂直线
          ForEach(Array.from({ length: 8 }), (_: number, index: number) => {
            Line()
              .startPoint([index * 200, 0])
              .endPoint([index * 200, 1600])
              .stroke(ColorResource.surfaceEmphasized)
              .strokeWidth(1)
              .opacity(0.3)
          })
          
          // 水平线
          ForEach(Array.from({ length: 8 }), (_: number, index: number) => {
            Line()
              .startPoint([0, index * 200])
              .endPoint([1600, index * 200])
              .stroke(ColorResource.surfaceEmphasized)
              .strokeWidth(1)
              .opacity(0.3)
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
