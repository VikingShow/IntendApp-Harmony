// File: entry/src/main/ets/pages/Home.ets
/**
 * 应用首页模块
 * 
 * 本页面是EasyFlow应用的入口页面，提供项目列表展示、项目创建、数据管理等功能。
 * 采用左右分栏布局，左侧为项目列表，右侧为项目详情或欢迎界面，实现直观的项目管理体验。
 * 
 * 主要功能：
 * 1. 项目列表：显示所有项目的概览信息和基本操作
 * 2. 项目创建：支持空白项目和模板项目的创建
 * 3. 项目详情：展示选中项目的详细信息和统计数据
 * 4. 数据管理：提供项目数据的导入导出和迁移功能
 * 5. 权限管理：处理文件系统权限和数据访问权限
 * 6. 状态管理：维护应用状态和用户操作历史
 * 
 * 技术特点：
 * - 响应式设计：基于ArkTS响应式框架实现数据的自动同步
 * - 服务集成：集成多个服务模块提供完整的功能支持
 * - 权限管理：集成HarmonyOS权限系统确保数据安全
 * - 数据迁移：支持版本升级时的数据格式迁移
 * - 错误处理：提供完善的错误处理和用户提示机制
 * 
 * 界面布局：
 * - 左侧面板：项目列表和创建操作
 * - 右侧内容：项目详情展示或欢迎界面
 * - 顶部操作：项目创建和设置操作
 * - 响应式布局：支持不同屏幕尺寸的自适应显示
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-06
 */

import { StorageService, ProjectMeta } from '../services/StorageService';
import { LoadingService } from '../services/LoadingService';
import { TemplateService, ProjectTemplate } from '../services/TemplateService';
import { PermissionService } from '../services/PermissionService';
import { DataMigrationService } from '../services/DataMigrationService';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import common from '@ohos.app.ability.common';
import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { DashboardView } from '../components/DashboardView';
import { WelcomeView } from '../components/WelcomeView';
import { CanvasController } from '../core/canvas/CanvasController';
import { RenderMode } from '../core/canvas/CanvasRenderer';
import vibrator from '@ohos.vibrator';
import { PromptAction } from '@kit.ArkUI';
import router from '@ohos.router';
import { ErrorHandler } from '../core/ErrorHandler';
import { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { BreakpointSystem, DeviceType, BreakpointConfig } from '../utils/BreakpointSystem';

/**
 * ActionMenu按钮接口
 * 定义操作菜单按钮的数据结构
 */
interface ActionMenuButton {
  /** 按钮文本 */
  text: string;
  /** 按钮颜色 */
  color: string | Resource;
}

/**
 * 任务依赖关系接口
 * 定义任务的前置和后续依赖
 */
interface TaskDependencies {
  /** 前置任务列表 */
  predecessors: string[];
  /** 后续任务列表 */
  successors: string[];
}

/**
 * 节点详情对话框
 */
@CustomDialog
struct TaskNodeDetailDialog {
  controller: CustomDialogController;
  task: TaskNode | null = null;
  project: Project | null = null; // 添加项目参数以获取依赖关系
  isDarkMode: boolean = false;
  onEdit: () => void = () => {};
  onDelete: () => void = () => {};

  build() {
    Column({ space: 0 }) {
      // 顶部标题栏
      Row({ space: 12 }) {
        Text(this.task?.name || '任务详情')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .layoutWeight(1)
        
        // 关闭按钮
        Button({ type: ButtonType.Circle }) {
          Text('×')
            .fontSize(24)
            .fontColor(ColorResource.textSecondary)
        }
        .width(36)
        .height(36)
        .backgroundColor(ColorResource.surface)
        .onClick(() => {
          this.controller.close();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(ColorResource.surface)

      // 内容区域
      Column({ space: 16 }) {
        if (this.task) {
          // 关键路径标签
          if (this.task.isCritical) {
            Row({ space: 6 }) {
              Circle({ width: 8, height: 8 })
                .fill(ThemeConfig.taskCritical)
              Text('关键路径')
                .fontSize(14)
                .fontColor(ThemeConfig.taskCritical)
            }
            .padding({ left: 4, right: 12, top: 4, bottom: 4 })
            .backgroundColor(this.isDarkMode ? 'rgba(255, 107, 107, 0.15)' : 'rgba(255, 69, 58, 0.1)')
            .borderRadius(12)
          }

          // 时间信息
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              Text('📅')
                .fontSize(16)
              Text('时间范围')
                .fontSize(14)
                .fontColor(ColorResource.textSecondary)
            }
            
            Text(`${this.task.startDate.toLocaleDateString()} - ${this.task.endDate.toLocaleDateString()}`)
              .fontSize(15)
              .fontColor(ColorResource.textPrimary)
              .margin({ left: 24 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 进度信息
          Column({ space: 12 }) {
            // 时间进度
            Row({ space: 8 }) {
              Text('⏱️')
                .fontSize(16)
              Text('时间进度')
                .fontSize(14)
                .fontColor(ColorResource.textSecondary)
              
              Text(`${this.getTimeProgress()}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.primaryColor)
            }
            .width('100%')
            
            Progress({ value: this.getTimeProgress(), total: 100, type: ProgressType.Linear })
              .width('100%')
              .color(ColorResource.primaryColor)
              .style({ strokeWidth: 6 })
            
            // 完成进度
            Row({ space: 8 }) {
              Text('✅')
                .fontSize(16)
              Text('完成进度')
                .fontSize(14)
                .fontColor(ColorResource.textSecondary)
              
              Text(`${this.getCompletionProgress()}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeConfig.taskProgress)
            }
            .width('100%')
            
            Progress({ value: this.getCompletionProgress(), total: 100, type: ProgressType.Linear })
              .width('100%')
              .color(ThemeConfig.taskProgress)
              .style({ strokeWidth: 6 })
          }
          .width('100%')

          // 依赖关系信息
          if (this.project && this.task) {
            this.DependenciesSection()
          }

          // 检查清单
          if (this.task.checklist && this.task.checklist.length > 0) {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Text('📋')
                  .fontSize(16)
                Text(`检查清单 (${this.getCompletedCount()}/${this.task.checklist.length})`)
                  .fontSize(14)
                  .fontColor(ColorResource.textSecondary)
              }
              
              List({ space: 6 }) {
                ForEach(this.task.checklist.slice(0, 3), (item: ChecklistItem) => {
                  ListItem() {
                    Row({ space: 8 }) {
                      Text(item.isCompleted ? '☑' : '☐')
                        .fontSize(16)
                        .fontColor(item.isCompleted ? ThemeConfig.taskProgress : ColorResource.textTertiary)
                      Text(item.text)
                        .fontSize(14)
                        .fontColor(item.isCompleted ? ColorResource.textSecondary : ColorResource.textPrimary)
                        .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                })
                
                if (this.task.checklist.length > 3) {
                  ListItem() {
                    Text(`+${this.task.checklist.length - 3} 项...`)
                      .fontSize(13)
                      .fontColor(ColorResource.textTertiary)
                      .margin({ left: 24 })
                  }
                }
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }
      }
      .width('100%')
      .padding(20)
      .layoutWeight(1)

      // 底部操作按钮
      Row({ space: 12 }) {
        Button('编辑任务')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(ColorResource.primaryColor)
          .layoutWeight(1)
          .height(48)
          .borderRadius(12)
          .onClick(() => {
            this.controller.close();
            this.onEdit();
          })
        
        Button('删除')
          .fontSize(16)
          .fontColor(this.isDarkMode ? '#FF6B6B' : '#FF453A')
          .backgroundColor(ColorResource.surface)
          .layoutWeight(1)
          .height(48)
          .borderRadius(12)
          .onClick(() => {
            this.controller.close();
            this.onDelete();
          })
      }
      .width('100%')
      .padding(20)
      .backgroundColor(ColorResource.surface)
      .borderRadius({ bottomLeft: 16, bottomRight: 16 })
    }
    .width('90%')
    .constraintSize({ maxWidth: 540 }) // 限制最大宽度，避免在平板上过宽
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(16)
  }

  // 计算时间进度
  private getTimeProgress(): number {
    if (!this.task) return 0;
    const now = new Date().getTime();
    const start = this.task.startDate.getTime();
    const end = this.task.endDate.getTime();
    if (now < start) return 0;
    if (now > end) return 100;
    const totalDuration = end - start;
    if (totalDuration <= 0) return 100;
    const elapsed = now - start;
    return Math.round((elapsed / totalDuration) * 100);
  }

  // 计算完成进度
  private getCompletionProgress(): number {
    if (!this.task || !this.task.checklist) return 0;
    if (this.task.checklist.length === 0) return 0;
    const completedCount = this.task.checklist.filter(item => item.isCompleted).length;
    return Math.round((completedCount / this.task.checklist.length) * 100);
  }

  // 获取已完成数量
  private getCompletedCount(): number {
    if (!this.task || !this.task.checklist) return 0;
    return this.task.checklist.filter(item => item.isCompleted).length;
  }

  // 获取依赖关系（前置任务和后续任务）
  private getDependencies(): TaskDependencies {
    if (!this.project || !this.task) {
      let emptyResult: TaskDependencies = { predecessors: [], successors: [] };
      return emptyResult;
    }

    let predecessors: string[] = [];
    let successors: string[] = [];

    // 遍历所有依赖关系
    this.project.dependencies.forEach(dep => {
      if (dep.toId === this.task!.id) {
        // 找到指向当前任务的依赖（前置任务）
        const fromTask = this.project!.tasks.find(t => t.id === dep.fromId);
        if (fromTask) {
          predecessors.push(fromTask.name);
        }
      } else if (dep.fromId === this.task!.id) {
        // 找到从当前任务出发的依赖（后续任务）
        const toTask = this.project!.tasks.find(t => t.id === dep.toId);
        if (toTask) {
          successors.push(toTask.name);
        }
      }
    });

    let result: TaskDependencies = { predecessors: predecessors, successors: successors };
    return result;
  }

  // 依赖关系显示组件
  @Builder
  DependenciesSection() {
    if (this.getDependencies().predecessors.length > 0 || this.getDependencies().successors.length > 0) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('🔗')
            .fontSize(16)
          Text('依赖关系')
            .fontSize(14)
            .fontColor(ColorResource.textSecondary)
        }
        
        // 前置任务
        if (this.getDependencies().predecessors.length > 0) {
          Column({ space: 4 }) {
            Text('前置任务:')
              .fontSize(13)
              .fontColor(ColorResource.textTertiary)
              .margin({ left: 24 })
            
            ForEach(this.getDependencies().predecessors.slice(0, 3), (taskName: string) => {
              Text(`• ${taskName}`)
                .fontSize(13)
                .fontColor(ColorResource.textPrimary)
                .margin({ left: 32 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            })
            
            if (this.getDependencies().predecessors.length > 3) {
              Text(`+${this.getDependencies().predecessors.length - 3} 项...`)
                .fontSize(12)
                .fontColor(ColorResource.textTertiary)
                .margin({ left: 32 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        
        // 后续任务
        if (this.getDependencies().successors.length > 0) {
          Column({ space: 4 }) {
            Text('后续任务:')
              .fontSize(13)
              .fontColor(ColorResource.textTertiary)
              .margin({ left: 24, top: this.getDependencies().predecessors.length > 0 ? 8 : 0 })
            
            ForEach(this.getDependencies().successors.slice(0, 3), (taskName: string) => {
              Text(`• ${taskName}`)
                .fontSize(13)
                .fontColor(ColorResource.textPrimary)
                .margin({ left: 32 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            })
            
            if (this.getDependencies().successors.length > 3) {
              Text(`+${this.getDependencies().successors.length - 3} 项...`)
                .fontSize(12)
                .fontColor(ColorResource.textTertiary)
                .margin({ left: 32 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }
}

/**
 * 重命名项目对话框
 */
@CustomDialog
struct RenameProjectDialog {
  controller: CustomDialogController;
  projectName: string = '';
  onConfirm: (newName: string) => void = () => {};
  @State inputValue: string = '';

  aboutToAppear() {
    this.inputValue = this.projectName;
  }

  build() {
    Column({ space: 20 }) {
      Text('编辑项目名称')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorResource.textPrimary)
      
      TextInput({ text: this.inputValue, placeholder: '请输入项目名称' })
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor(ColorResource.surface)
        .borderRadius(8)
        .onChange((value: string) => {
          this.inputValue = value;
        })
      
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .backgroundColor(ColorResource.surface)
          .fontColor(ColorResource.textSecondary)
          .onClick(() => {
            this.controller.close();
          })
        
        Button('确定')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .backgroundColor(ColorResource.primaryColor)
          .fontColor('#FFFFFF')
          .enabled(this.inputValue.trim().length > 0)
          .onClick(() => {
            if (this.inputValue.trim().length > 0) {
              this.onConfirm(this.inputValue.trim());
              this.controller.close();
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .padding(24)
    .width('85%')
    .constraintSize({ maxWidth: 480 }) // 限制最大宽度，避免在平板上过宽
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(16)
  }
}


@Entry
@Component
struct HomePage {
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

  @State projectList: ProjectMeta[] = [];
  @State selectedProjectDetail: Project | null = null;
  @State selectedProjectId: string | null = null;
  @State componentKey: number = 0;
  @State dashboardKey: number = 0;
  @State dashboardTimestamp: number = 0;
  @State isLoading: boolean = false;
  @State selectedTemplate: ProjectTemplate | null = null;
  @State projectName: string = '';
  @State selectedCategory: string = 'development';
  @State emptyProject: Project | null = null;
  @State emptyTask: TaskNode | null = null;
  
  // 动画相关状态
  @State contentOpacity: number = 1;
  @State contentScale: number = 1;
  @State contentTranslateY: number = 0;
  @State isTransitioning: boolean = false;
  @State selectedProjectCardScale: number = 1;
  @State hoveredProjectId: string | null = null;
  
  // 新增项目按钮长按效果状态
  @State isLongPressing: boolean = false;
  @State buttonScale: number = 1;
  @State buttonOpacity: number = 1;
  @State progressAngle: number = 0;
  @State longPressTimer: number | null = null;
  
  // 删除按钮交互效果状态
  @State deleteButtonScale: number = 1;
  @State deleteButtonOpacity: number = 1;
  @State hoveredDeleteId: string | null = null;
  
  // 项目卡片交互状态
  @State pressedProjectId: string | null = null;

  // 画布背景相关状态
  private canvasController: CanvasController = new CanvasController();
  @State showCanvasBackground: boolean = false;

  // 主题相关状态
  private configCallbackId: number = -1;
  @State isDarkMode: boolean = false;

  // 响应式布局相关状态
  @State screenWidth: number = 0;
  @State currentBreakpoint: BreakpointConfig = BreakpointSystem.getCurrentBreakpoint(0);
  @State showSidebarDrawer: boolean = false; // 手机端侧边栏抽屉状态
  @State isPhone: boolean = false;
  @State isTablet: boolean = false;
  
  // 手机端视图模式
  @State phoneViewMode: 'welcome' | 'list' | 'detail' = 'welcome'; // welcome=欢迎页, list=项目列表, detail=项目详情
  @State swipeOffset: number = 0; // 滑动偏移量
  @State showDashboardCard: boolean = false; // 是否显示Dashboard卡片
  @State arrowAnimationOffset: number = 0; // 箭头动画偏移量
  @State pageTranslateY: number = 0; // 页面Y轴偏移（用于滑动动画）
  @State pageOpacity: number = 1; // 页面透明度
  
  // 侧边栏抽屉动画状态
  @State drawerTranslateX: number = -100; // 抽屉位移百分比
  @State drawerOpacity: number = 0; // 遮罩透明度
  @State menuButtonScale: number = 1; // 菜单按钮缩放
  
  // 重命名对话框
  private renameDialogController: CustomDialogController | null = null;
  @State renameProjectId: string = '';
  @State renameProjectName: string = '';
  
  // 节点详情对话框
  private taskDetailDialogController: CustomDialogController | null = null;
  @State selectedTaskForDetail: TaskNode | null = null;
  
  // 画布渲染模式（手机端默认使用缩略模式）
  @State canvasRenderMode: RenderMode = RenderMode.NORMAL;

  private storageService: StorageService | null = null;
  private loadingService: LoadingService = LoadingService.getInstance();
  private templateService: TemplateService = TemplateService.getInstance();
  private permissionService: PermissionService | null = null;
  private migrationService: DataMigrationService | null = null;
  private errorHandler: ErrorHandler | null = null;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  async aboutToAppear() {
    // 初始化屏幕尺寸
    this.updateScreenSize();

    // 初始化权限服务
    this.permissionService = PermissionService.getInstance(this.uiContext.getHostContext() as common.UIAbilityContext);
    
    // 申请文件系统权限
    console.log('[Home] 开始申请文件系统权限...');
    const hasPermission = await this.permissionService.requestFileSystemPermission();
    console.log(`[Home] 文件系统权限申请结果: ${hasPermission}`);
    
    if (!hasPermission) {
      console.warn('[Home] 文件系统权限申请失败，但继续初始化存储服务');
      this.promptAction.showToast({
        message: '文件系统权限申请失败，部分功能可能受限' 
      });
      // 不直接返回，继续初始化，让用户尝试使用
    }

    // 初始化存储服务
    this.storageService = StorageService.getInstance((this.uiContext.getHostContext() as common.UIAbilityContext).filesDir);
    
    // 测试文件系统操作
    console.log('[Home] 开始测试文件系统操作...');
    const fileSystemTestResult = await this.storageService.testFileSystem();
    console.log(`[Home] 文件系统测试结果: ${fileSystemTestResult}`);
    
    if (!fileSystemTestResult) {
      this.promptAction.showToast({
        message: '文件系统测试失败，请检查权限设置' 
      });
    }
    // 注入uiContext
    this.errorHandler?.setContext(this.uiContext);
    // 初始化数据迁移服务
    this.migrationService = DataMigrationService.getInstance((this.uiContext.getHostContext() as common.UIAbilityContext).filesDir);
    // 注入uiContext
    // this.migrationService.setContext(this.uiContext);

    // 检查并执行数据迁移
    await this.checkAndMigrateData();
    
    // 注册加载状态监听器
    this.loadingService.addListener((key: string, loading: boolean) => {
      if (key === 'project_loading') {
        this.isLoading = loading;
      }
    });

    // 初始化画布控制器
    this.canvasController.setContext(this.uiContext);
    
    // 初始化画布控制器回调（在页面初始化时就设置）
    this.initializeCanvasCallbacks();
    
    // 根据屏幕尺寸设置初始渲染模式
    this.canvasRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
    this.canvasController.setRenderMode(this.canvasRenderMode);

    // 初始化主题监听器
    this.setupThemeListener();

    // 清理损坏的项目文件（在加载项目之前）
    await this.cleanupCorruptedFiles();
    
    await this.loadProjects();
  }

  onPageShow() {
    this.loadProjects();
    // 初始化画布控制器回调
    this.initializeCanvasCallbacks();
    // 如果有选中的项目，重新加载其详细数据以确保显示最新内容
    if (this.selectedProjectId) {
      this.onSelectProject(this.selectedProjectId);
    }
    // 重新检测屏幕尺寸（可能发生旋转）
    this.updateScreenSize();
  }

  aboutToDisappear() {
    // 取消主题监听
    if (this.configCallbackId !== -1) {
      try {
        const context = this.uiContext.getHostContext() as common.UIAbilityContext;
        const appContext = context.getApplicationContext();
        appContext.off('environment', this.configCallbackId);
      } catch (error) {
        console.error('[Home] Failed to unregister theme listener:', error);
      }
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
      console.error('[Home] Failed to setup theme listener:', error);
    }
  }

  // 更新颜色模式
  private updateColorMode(config: Configuration) {
    const wasDarkMode = this.isDarkMode;
    this.isDarkMode = (config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);

    // 更新CanvasRenderer的深色模式状态
    this.canvasController.getRenderer().setDarkMode(this.isDarkMode);

    // 如果模式发生变化且显示画布背景，触发画布重绘
    if (wasDarkMode !== this.isDarkMode && this.showCanvasBackground && this.selectedProjectDetail) {
      this.renderProjectCanvas();
    }

    console.log(`[Home] Color mode updated: ${this.isDarkMode ? 'Dark' : 'Light'}`);
  }

  // 更新屏幕尺寸和断点配置
  private updateScreenSize() {
    // 获取屏幕宽度（vp）
    const display = this.uiContext.getHostContext()?.resourceManager;
    // 使用窗口管理器获取屏幕宽度
    const windowStage = (this.uiContext.getHostContext() as common.UIAbilityContext)?.windowStage;
    if (windowStage) {
      windowStage.getMainWindow().then(window => {
        const properties = window.getWindowProperties();
        const widthPx = properties.windowRect.width;
        // 转换为vp
        this.screenWidth = this.uiContext.px2vp(widthPx);
        this.updateBreakpoint();
      }).catch((error: Error) => {
        console.error('[Home] Failed to get window size:', error);
        // 使用默认平板宽度
        this.screenWidth = 840;
        this.updateBreakpoint();
      });
    } else {
      // 使用默认平板宽度
      this.screenWidth = 840;
      this.updateBreakpoint();
    }
  }

  // 更新断点配置
  private updateBreakpoint() {
    const previousIsPhone = this.isPhone;
    
    this.currentBreakpoint = BreakpointSystem.getCurrentBreakpoint(this.screenWidth);
    this.isPhone = BreakpointSystem.isPhone(this.screenWidth);
    this.isTablet = BreakpointSystem.isTablet(this.screenWidth);
    
    // 手机端使用缩略模式，平板/大屏使用普通模式
    this.canvasRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
    
    // 更新画布控制器的渲染模式
    if (this.canvasController) {
      this.canvasController.setRenderMode(this.canvasRenderMode);
    }
    
    console.log(`[Home] Screen size updated: ${this.screenWidth}vp, Device type: ${this.currentBreakpoint.deviceType}, Render mode: ${this.canvasRenderMode}`);
    
    // 如果从非手机变为手机，关闭侧边栏抽屉
    if (this.isPhone && !previousIsPhone) {
      this.showSidebarDrawer = false;
      this.drawerTranslateX = -100;
      this.drawerOpacity = 0;
    }
    
    // 如果从手机变为非手机，也确保关闭抽屉
    if (!this.isPhone && previousIsPhone && this.showSidebarDrawer) {
      this.showSidebarDrawer = false;
      this.drawerTranslateX = -100;
      this.drawerOpacity = 0;
    }
  }

  // 打开侧边栏抽屉（仅手机端）
  private openSidebarDrawer() {
    if (this.isPhone && !this.showSidebarDrawer) {
      this.showSidebarDrawer = true;
      
      // 添加触觉反馈
      try {
        vibrator.startVibration({
          type: 'time',
          duration: 30
        }, {
          id: 0,
          usage: 'alarm'
        });
      } catch (error) {
        console.log('[Home] Haptic feedback not available:', error);
      }
      
      // 延迟执行动画，确保DOM已更新
      setTimeout(() => {
        this.drawerTranslateX = 0;
        this.drawerOpacity = 1;
      }, 50);
    }
  }
  
  // 关闭侧边栏抽屉（仅手机端）
  private closeSidebarDrawer() {
    if (this.isPhone && this.showSidebarDrawer) {
      // 先执行动画
      this.drawerTranslateX = -100;
      this.drawerOpacity = 0;
      
      // 动画结束后隐藏抽屉
      setTimeout(() => {
        this.showSidebarDrawer = false;
      }, 300);
    }
  }
  
  // 切换侧边栏抽屉（仅手机端）
  private toggleSidebarDrawer() {
    if (this.showSidebarDrawer) {
      this.closeSidebarDrawer();
    } else {
      this.openSidebarDrawer();
    }
  }

  // 检查并执行数据迁移
  async checkAndMigrateData() {
    if (!this.migrationService) {
      console.error('[Home] 数据迁移服务未初始化');
      return;
    }
    
    try {
      console.log('[Home] 开始检查数据迁移需求...');
      const needsMigration = await this.migrationService.needsMigration();
      console.log(`[Home] 数据迁移需求检查结果: ${needsMigration}`);
      
      if (needsMigration) {
        console.log('[Home] 检测到需要数据迁移');
        this.promptAction.showToast({
          message: '正在迁移数据到新的存储系统...',
          duration: 2000
        });
        
        console.log('[Home] 开始执行数据迁移...');
        const result = await this.migrationService.migrateData();
        console.log(`[Home] 数据迁移完成，结果: ${JSON.stringify(result)}`);
        
        if (result.success) {
          console.log(`[Home] 数据迁移成功，迁移了 ${result.migratedCount} 个项目`);
          this.promptAction.showToast({
            message: `数据迁移成功，已迁移 ${result.migratedCount} 个项目`,
            duration: 3000
          });
        } else {
          console.error('[Home] 数据迁移失败:', result.errors);
          console.error(`[Home] 迁移错误详情: ${JSON.stringify(result.errors)}`);
          this.promptAction.showToast({
            message: `数据迁移部分失败，${result.errors.length} 个项目迁移失败`,
            duration: 3000
          });
        }
      } else {
        console.log('[Home] 无需数据迁移');
      }
    } catch (error) {
      console.error('[Home] 数据迁移检查失败:', error);
      console.error(`[Home] 迁移错误详情: ${JSON.stringify(error)}`);
      this.promptAction.showToast({
        message: '数据迁移检查失败，请查看日志',
        duration: 3000
      });
    }
  }

  // 清理损坏的项目文件
  async cleanupCorruptedFiles() {
    if (!this.storageService) {
      console.error('[Home] 存储服务未初始化');
      return;
    }
    
    try {
      console.log('[Home] 开始清理损坏的项目文件...');
      const result = await this.storageService.cleanupCorruptedFiles();
      console.log(`[Home] 清理完成，删除了 ${result.cleaned} 个损坏的文件`);
      
      if (result.cleaned > 0) {
        console.log(`[Home] 清理了 ${result.cleaned} 个损坏的项目文件`);
        this.promptAction.showToast({
          message: `已清理 ${result.cleaned} 个损坏的项目文件`,
          duration: 2000
        });
      } else {
        console.log('[Home] 没有发现损坏的项目文件');
      }
      
      if (result.errors.length > 0) {
        console.error('[Home] 清理过程中的错误:', result.errors);
        this.promptAction.showToast({
          message: `清理过程中遇到 ${result.errors.length} 个错误，请查看日志`,
          duration: 3000
        });
      }
    } catch (error) {
      console.error('[Home] 清理损坏文件失败:', error);
      this.promptAction.showToast({
        message: '清理损坏文件失败，请查看日志',
        duration: 3000
      });
    }
  }

  async loadProjects() {
    if (!this.storageService) {
      console.error('[Home] 存储服务未初始化');
      return;
    }
    
    try {
      console.log('[Home] 开始加载项目列表...');
      this.loadingService.setLoading('project_loading', true);
      
      const list = await this.storageService.getProjectList();
      console.log(`[Home] 加载到 ${list.length} 个项目`);
      console.log('[Home] 项目列表详情:', JSON.stringify(list, null, 2));
      
      this.projectList = list.sort((a, b) => b.lastModified - a.lastModified);
      console.log(`[Home] 项目列表排序完成，共 ${this.projectList.length} 个项目`);
      console.log('[Home] 排序后的项目列表:', JSON.stringify(this.projectList, null, 2));
      
      if (this.selectedProjectId) {
        console.log(`[Home] 恢复选中的项目: ${this.selectedProjectId}`);
        // 检查项目是否仍然存在于列表中
        const projectExists = this.projectList.some(p => p.id === this.selectedProjectId);
        if (projectExists) {
          await this.onSelectProject(this.selectedProjectId);
        } else {
          console.log(`[Home] 选中的项目 ${this.selectedProjectId} 不再存在，清空选择`);
          this.selectedProjectId = null;
          this.selectedProjectDetail = null;
          this.showCanvasBackground = false;
        }
      }
      
      console.log('[Home] 项目列表加载完成');
    } catch (error) {
      console.error('[Home] 加载项目列表失败:', error);
      console.error(`[Home] 错误详情: ${JSON.stringify(error)}`);
      
      // 更友好的错误提示
      const errorMessage = this.getUserFriendlyErrorMessage(error as Error);
      this.promptAction.showToast({
        message: errorMessage,
        duration: 4000
      });
      
      // 显示重试选项
      this.showRetryOption();
    } finally {
      this.loadingService.setLoading('project_loading', false);
    }
  }

  async onSelectProject(projectId: string) {
    if (this.storageService) {
      console.log(`[Home] Selecting project: ${projectId}`);
      
      // 如果正在切换中，忽略新的选择请求
      if (this.isTransitioning) {
        console.log(`[Home] Already transitioning, ignoring project selection: ${projectId}`);
        return;
      }
      
      // 如果是同一个项目，不需要重新加载
      if (this.selectedProjectId === projectId && this.selectedProjectDetail) {
        console.log(`[Home] Same project already selected: ${projectId}`);
        return;
      }
      
      this.isTransitioning = true;
      this.selectedProjectId = projectId;
      
      // 开始内容淡出动画
      this.startContentFadeOut();
      
      try {
        // 加载新项目数据
        const loadedProject = await this.storageService.getProject(projectId);
        console.log(`[Home] Project loaded: ${loadedProject?.name} with ${loadedProject?.tasks.length} tasks`);
        
        if (loadedProject) {
          // 等待淡出动画完成后再更新内容
          setTimeout(() => {
            this.updateProjectContent(loadedProject);
            // 显示画布背景
            this.showCanvasBackground = true;
            // 延迟渲染画布以确保组件已更新
            setTimeout(() => {
              this.renderProjectCanvas();
            }, 100);
          }, 200); // 与淡出动画时长匹配
        } else {
          console.error(`[Home] Project not found: ${projectId}`);
          this.promptAction.showToast({ message: '项目不存在或已删除' });
          this.selectedProjectId = null;
          this.showCanvasBackground = false;
          this.isTransitioning = false;
          this.startContentFadeIn();
        }
      } catch (error) {
        console.error(`[Home] Error loading project ${projectId}:`, error);
        this.promptAction.showToast({ message: '加载项目失败' });
        this.handleError(error as Error, "onSelectProject");
        this.selectedProjectId = null;
        this.showCanvasBackground = false;
        this.isTransitioning = false;
        this.startContentFadeIn();
      }
    }
  }

  // 开始内容淡出动画
  private startContentFadeOut() {
    this.contentOpacity = 0;
    this.contentScale = 0.95;
    this.isLoading = true;
    
    // 添加轻微的向上移动效果
    this.contentTranslateY = -10;
  }

  // 更新项目内容
  private updateProjectContent(loadedProject: Project) {
    // 清空旧数据
    this.selectedProjectDetail = null;
    this.dashboardKey = 0;
    this.dashboardTimestamp = 0;
    
    // 设置新数据
    this.selectedProjectDetail = loadedProject;
    this.componentKey++;
    this.dashboardKey = 1;
    this.dashboardTimestamp = Date.now();
    
    console.log(`[Home] Project data updated, component key: ${this.componentKey}, dashboard key: ${this.dashboardKey}, timestamp: ${this.dashboardTimestamp}`);
    console.log(`[Home] Selected project detail: ${this.selectedProjectDetail.name} with ${this.selectedProjectDetail.tasks.length} tasks`);
    
    // 开始内容淡入动画
    this.startContentFadeIn();
    
    // 显示切换提示
    this.promptAction.showToast({ message: `已切换到项目: ${loadedProject.name}` });
  }

  // 开始内容淡入动画
  private startContentFadeIn() {
    this.isLoading = false;
    this.contentOpacity = 1;
    this.contentScale = 1;
    this.contentTranslateY = 0;
    
    // 动画完成后重置过渡状态
    setTimeout(() => {
      this.isTransitioning = false;
    }, 300);
  }

  // 开始长按效果
  private startLongPressEffect() {
    this.isLongPressing = true;
    this.buttonScale = 0.9;
    this.buttonOpacity = 0.8;
    this.progressAngle = 0;
    
    // 开始进度环动画
    this.startProgressAnimation();
  }

  // 结束长按效果
  private endLongPressEffect() {
    this.isLongPressing = false;
    this.buttonScale = 1;
    this.buttonOpacity = 1;
    this.progressAngle = 0;
    
    // 清除定时器
    if (this.longPressTimer !== null) {
      clearInterval(this.longPressTimer);
      this.longPressTimer = null;
    }
  }

  // 开始进度环动画
  private startProgressAnimation() {
    const duration = 1000; // 1秒完成长按
    const interval = 16; // 60fps
    const totalSteps = duration / interval;
    let currentStep = 0;
    
    this.longPressTimer = setInterval(() => {
      currentStep++;
      this.progressAngle = (currentStep / totalSteps) * 360;
      
      if (currentStep >= totalSteps) {
        // 进度完成，触发长按动作
        this.createBlankProject();
        this.endLongPressEffect();
      }
    }, interval);
  }

  // 删除按钮按下效果
  private startDeleteButtonPress() {
    this.deleteButtonScale = 0.9;
    this.deleteButtonOpacity = 0.8;
  }

  // 删除按钮释放效果
  private endDeleteButtonPress() {
    this.deleteButtonScale = 1;
    this.deleteButtonOpacity = 1;
  }

  // 从模板创建项目
  async createProjectFromTemplate(templateId: string, projectName: string) {
    if (!this.storageService) {
      this.handleError(new Error("存储服务未初始化"), "createProjectFromTemplate");
      return;
    }

    // 添加创建确认对话框
   this.uiContext.showAlertDialog({
      title: '确认创建项目',
      message: `确定要创建项目 "${projectName}" 吗？`,
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消创建
        }
      },
      secondaryButton: {
        value: '创建',
        fontColor: ColorResource.primaryColor,
        action: async () => {
          try {
            console.log(`[Home] Creating project from template: ${templateId}`);

            // 显示创建进度
            this.promptAction.showToast({
              message: '正在创建项目...',
              duration: 1000
            });

            // 从模板创建项目
            const newProject = this.templateService.createProjectFromTemplate(templateId, projectName);
            
            // 保存项目
            console.log(`[Home] 准备保存项目: ${JSON.stringify(newProject, null, 2)}`);
            if (this.storageService) {
              await this.storageService.saveProject(newProject);
            }
            console.log(`[Home] Project created from template: ${newProject.id}`);
            
            // 成功提示
            this.promptAction.showToast({
              message: `项目 "${newProject.name}" 创建成功！`,
              duration: 2000
            });

            // 立即更新项目列表
            console.log('[Home] 开始刷新项目列表...');
            await this.loadProjects();
            console.log(`[Home] 项目列表刷新完成，当前项目数量: ${this.projectList.length}`);
            
            // 设置新创建的项目为选中状态
            this.selectedProjectId = newProject.id;
            this.selectedProjectDetail = newProject;
            console.log(`[Home] 设置选中项目: ${newProject.id}`);
            // 延迟导航，让用户看到成功提示
            setTimeout(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/Index',
                params: { projectId: newProject.id },
                animation: {
                  type: 'fade',
                  duration: 300
                }
              } as router.RouterOptions);
            }, 500);
          } catch (error) {
            this.promptAction.showToast({
              message: '创建项目失败，请重试',
              duration: 2000
            });
            console.error('[Home] Create project error:', error);
            this.handleError(error as Error, "createProjectFromTemplate");
          }
        }
      }
    });
  }

  // 统一的错误处理
  private handleError(error: Error, context: string) {
    console.error(`[${context}] Error:`, error);
    this.promptAction.showToast({ message: `操作失败: ${error.message}` });
  }

  // 获取用户友好的错误信息
  private getUserFriendlyErrorMessage(error: Error): string {
    const errorMessage = error.message.toLowerCase();
    
    if (errorMessage.includes('permission') || errorMessage.includes('权限')) {
      return '权限不足，请检查文件访问权限';
    } else if (errorMessage.includes('network') || errorMessage.includes('网络')) {
      return '网络连接异常，请检查网络设置';
    } else if (errorMessage.includes('storage') || errorMessage.includes('存储')) {
      return '存储空间不足，请清理空间后重试';
    } else if (errorMessage.includes('file') || errorMessage.includes('文件')) {
      return '文件操作失败，请检查文件是否被占用';
    } else {
      return '操作失败，请稍后重试';
    }
  }

  // 显示重试选项
  private showRetryOption() {
    // 这里可以添加重试按钮或自动重试逻辑
    setTimeout(() => {
      console.log('[Home] 自动重试加载项目列表...');
      this.loadProjects();
    }, 2000);
  }

  async deleteProject(projectId: string) {
    // 添加删除确认对话框
    this.uiContext.showAlertDialog({
      title: '确认删除',
      message: '确定要删除这个项目吗？删除后无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消删除
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: ColorResource.errorColor,
        action: async () => {
          if (this.storageService) {
            try {
              await this.storageService.deleteProject(projectId);
              this.promptAction.showToast({ message: '项目已删除' });
              if (this.selectedProjectId === projectId) {
                this.selectedProjectId = null;
                this.selectedProjectDetail = null;
                this.showCanvasBackground = false;
              }
              await this.loadProjects();
            } catch (error) {
              this.promptAction.showToast({ message: '删除失败，请重试' });
              console.error('[Home] Delete project error:', error);
            }
          }
        }
      }
    });
  }


  // 显示创建项目选项的原生弹窗
  showCreateProjectOptions() {
    this.promptAction.showActionMenu({
      title: '创建新项目',
      buttons: [
        {
          text: '空白项目',
          color: ColorResource.primaryColor
        },
        {
          text: '选择模板',
          color: ColorResource.primaryColor
        }
      ]
    }).then((result) => {
      if (result.index === 0) {
        // 空白项目
        this.showBlankProjectDialog();
      } else if (result.index === 1) {
        // 选择模板
        this.showTemplateSelectionDialog();
      }
    }).catch((error: Error) => {
      console.error('ActionMenu error:', error);
    });
  }

  // 显示空白项目创建对话框
  showBlankProjectDialog() {
    this.uiContext.showAlertDialog({
      title: '创建空白项目',
      message: '确定要创建一个新的空白项目吗？',
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消操作
        }
      },
      secondaryButton: {
        value: '创建',
        action: () => {
          // 直接创建空白项目，使用默认名称
          this.projectName = '新项目';
          this.createBlankProjectWithName();
        }
      }
    });
  }

  // 显示模板选择对话框
  showTemplateSelectionDialog() {
    this.promptAction.showActionMenu({
      title: '选择模板分类',
      buttons: [
        {
          text: '开发模板',
          color: ColorResource.primaryColor
        },
        {
          text: '设计模板',
          color: ColorResource.projectDesign
        },
        {
          text: '营销模板',
          color: ColorResource.projectMarketing
        }
      ]
    }).then((result) => {
      if (result.index === 0) {
        // 开发模板
        this.selectedCategory = 'development';
        this.showTemplateListDialog();
      } else if (result.index === 1) {
        // 设计模板
        this.selectedCategory = 'design';
        this.showTemplateListDialog();
      } else if (result.index === 2) {
        // 营销模板
        this.selectedCategory = 'marketing';
        this.showTemplateListDialog();
      }
    }).catch((error: Error) => {
      console.error('Category selection error:', error);
    });
  }

  // 显示模板列表对话框
  showTemplateListDialog() {
    const templates = this.getTemplatesByCategory();
    if (templates.length === 0) {
      this.promptAction.showToast({ message: '该分类下没有可用模板' });
      return;
    }

    // 简化处理：只显示前3个模板，避免动态数组问题
    const maxTemplates = Math.min(templates.length, 3);
    const templateButtons: ActionMenuButton[] = [];
    
    for (let i = 0; i < maxTemplates; i++) {
      const template = templates[i];
      const button: ActionMenuButton = {
        text: `${template.name} (${template.tasks.length}个任务)`,
        color: ColorResource.primaryColor
      };
      templateButtons.push(button);
    }


    // 使用固定长度的元组类型
    if (templateButtons.length === 1) {
      this.promptAction.showActionMenu({
        title: '选择模板',
        buttons: [templateButtons[0]]
      }).then((result) => {
        if (result.index === 0) {
          this.selectedTemplate = templates[0];
          this.projectName = templates[0].name;
          this.createProjectFromTemplate(templates[0].id, this.projectName);
        }
      }).catch((error: Error) => {
        console.error('Template selection error:', error);
      });
    } else if (templateButtons.length === 2) {
      this.promptAction.showActionMenu({
        title: '选择模板',
        buttons: [templateButtons[0], templateButtons[1]]
      }).then((result) => {
        if (result.index < maxTemplates) {
          this.selectedTemplate = templates[result.index];
          this.projectName = templates[result.index].name;
          this.createProjectFromTemplate(templates[result.index].id, this.projectName);
        }
      }).catch((error: Error) => {
        console.error('Template selection error:', error);
      });
    } else if (templateButtons.length === 3) {
      this.promptAction.showActionMenu({
        title: '选择模板',
        buttons: [templateButtons[0], templateButtons[1], templateButtons[2]]
      }).then((result) => {
        if (result.index < maxTemplates) {
          this.selectedTemplate = templates[result.index];
          this.projectName = templates[result.index].name;
          this.createProjectFromTemplate(templates[result.index].id, this.projectName);
        }
      }).catch((error: Error) => {
        console.error('Template selection error:', error);
      });
    } else if (templateButtons.length === 4) {
      this.promptAction.showActionMenu({
        title: '选择模板',
        buttons: [templateButtons[0], templateButtons[1], templateButtons[2], templateButtons[3]]
      }).then((result) => {
        if (result.index < maxTemplates) {
          this.selectedTemplate = templates[result.index];
          this.projectName = templates[result.index].name;
          this.createProjectFromTemplate(templates[result.index].id, this.projectName);
        }
      }).catch((error: Error) => {
        console.error('Template selection error:', error);
      });
    }
  }





  // // 获取分类名称
  // private getCategoryName(category: string): string {
  //   switch (category) {
  //     case 'development': return '开发';
  //     case 'design': return '设计';
  //     case 'marketing': return '营销';
  //     case 'research': return '研究';
  //     case 'other': return '其他';
  //     default: return '其他';
  //   }
  // }
  //
  // // 获取分类图标
  // private getCategoryIcon(category: string): string {
  //   switch (category) {
  //     case 'development': return '💻';
  //     case 'design': return '🎨';
  //     case 'marketing': return '📢';
  //     case 'research': return '🔬';
  //     case 'other': return '📋';
  //     default: return '📋';
  //   }
  // }
  //
  // // 获取分类颜色
  // private getCategoryColor(category: string): string {
  //   switch (category) {
  //     case 'development': return '#3B82F6';
  //     case 'design': return ThemeConfig.projectDesign;
  //     case 'marketing': return ThemeConfig.projectMarketing;
  //     case 'research': return '#10B981';
  //     case 'other': return '#6B7280';
  //     default: return '#6B7280';
  //   }
  // }

  // 获取当前分类的模板
  private getTemplatesByCategory(): ProjectTemplate[] {
    const templates = this.templateService.getTemplatesByCategory(this.selectedCategory);
    // 获取空白模板
    const blank = this.templateService.getTemplateById('blank');
    if (blank) {
      return [blank, ...templates];
    }
    return templates;
  }


  // 创建带名称的空白项目
  private async createBlankProjectWithName() {
    if (!this.storageService) {
      this.handleError(new Error("存储服务未初始化"), "createBlankProjectWithName");
      return;
    }

    try {
      console.log(`[Home] Creating blank project with name: ${this.projectName}`);

      // 显示创建进度
      this.promptAction.showToast({
        message: '正在创建项目...',
        duration: 1000
      });

      // 创建空白项目
      const newProject = this.templateService.createProjectFromTemplate('blank', this.projectName.trim());
      
      // 保存项目
      console.log(`[Home] 准备保存空白项目: ${JSON.stringify(newProject, null, 2)}`);
      if (this.storageService) {
        await this.storageService.saveProject(newProject);
      }
      console.log(`[Home] Blank project created: ${newProject.id}`);
      
      // 成功提示
      this.promptAction.showToast({
        message: `项目 "${newProject.name}" 创建成功！`,
        duration: 2000
      });

      // 立即更新项目列表
      console.log('[Home] 开始刷新项目列表...');
      await this.loadProjects();
      console.log(`[Home] 项目列表刷新完成，当前项目数量: ${this.projectList.length}`);
      
      // 设置新创建的项目为选中状态
      this.selectedProjectId = newProject.id;
      this.selectedProjectDetail = newProject;
      console.log(`[Home] 设置选中项目: ${newProject.id}`);

      // 延迟导航，让用户看到成功提示
      setTimeout(() => {
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/Index',
          params: { projectId: newProject.id }
        });
      }, 500);
    } catch (error) {
      this.promptAction.showToast({
        message: '创建项目失败，请重试',
        duration: 2000
      });
      console.error('[Home] Create blank project error:', error);
      this.handleError(error as Error, "createBlankProjectWithName");
    }
  }

  // 快速创建空白项目
  async createBlankProject() {
    if (!this.storageService) {
      this.handleError(new Error("存储服务未初始化"), "createBlankProject");
      return;
    }

    // 添加创建确认对话框
    this.uiContext.showAlertDialog({
      title: '创建空白项目',
      message: '确定要创建一个新的空白项目吗？',
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消创建
        }
      },
      secondaryButton: {
        value: '创建',
        fontColor: ColorResource.primaryColor,
        action: async () => {
          try {
            console.log(`[Home] Creating blank project`);

            // 显示创建进度
            this.promptAction.showToast({
              message: '正在创建项目...',
              duration: 1000
            });

            // 创建空白项目
            const newProject = this.templateService.createProjectFromTemplate('blank', '新项目');
            
            // 保存项目
            console.log(`[Home] 准备保存空白项目: ${JSON.stringify(newProject, null, 2)}`);
            if (this.storageService) {
              await this.storageService.saveProject(newProject);
            }
            console.log(`[Home] Blank project created: ${newProject.id}`);
            
            // 成功提示
            this.promptAction.showToast({
              message: `项目 "${newProject.name}" 创建成功！`,
              duration: 2000
            });

            // 立即更新项目列表
            console.log('[Home] 开始刷新项目列表...');
            await this.loadProjects();
            console.log(`[Home] 项目列表刷新完成，当前项目数量: ${this.projectList.length}`);
            
            // 设置新创建的项目为选中状态
            this.selectedProjectId = newProject.id;
            this.selectedProjectDetail = newProject;
            console.log(`[Home] 设置选中项目: ${newProject.id}`);
            // 延迟导航，让用户看到成功提示
            setTimeout(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/Index',
                params: { projectId: newProject.id },
                animation: {
                  type: 'fade',
                  duration: 300
                }
              } as router.RouterOptions);
            }, 500);
          } catch (error) {
            this.promptAction.showToast({
              message: '创建项目失败，请重试',
              duration: 2000
            });
            console.error('[Home] Create blank project error:', error);
            this.handleError(error as Error, "createBlankProject");
          }
        }
      }
    });
  }




  build() {
    Stack() {
      // 画布背景 - 当选中项目时显示
      if (this.showCanvasBackground && this.selectedProjectDetail) {
        this.CanvasBackground()
      }
      
      // 主界面 - 根据设备类型使用不同布局
      if (this.isPhone) {
        // 手机端：单栏布局
        this.PhoneLayout()
      } else {
        // 平板和大屏：两栏布局
        this.TabletLayout()
      }

      // 手机端不再需要侧边栏抽屉和菜单按钮（改用底部导航）
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.transparent)
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      // bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
  }

  // 手机端布局
  @Builder
  PhoneLayout() {
    Stack() {
      // 主内容层
      Stack() {
        // 欢迎页（始终存在，通过opacity控制显示）
        if (this.phoneViewMode === 'welcome') {
          this.PhoneWelcomePage()
        }
        
        // 项目列表（从下方滑入）
        if (this.phoneViewMode === 'list') {
          this.PhoneProjectList()
        }
      }
      .width('100%')
      .height('100%')
      
      // Dashboard卡片层（浮动在中间，包含画布背景）
      if (this.showDashboardCard && this.selectedProjectDetail) {
        this.PhoneDashboardCard()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 平板/大屏布局
  @Builder
  TabletLayout() {
    Row() {
      // 左侧边栏容器
      if (this.currentBreakpoint.showSidebar) {
        Column() {
          this.Sidebar()
        }
        .layoutWeight(1)
      }
      
      // 右侧内容区
      Column() {
        this.ContentArea()
      }
      .layoutWeight(2)
      .margin({ left: ThemeConfig.spacingS })
    }
    .width('100%')
    .height('100%')
  }

  // 内容区域（共用）
  @Builder
  ContentArea() {
    Column() {
      if (this.isLoading) {
        // 简约加载状态设计
        Column({ space: ThemeConfig.spacingXXL }) {
          // 加载图标容器
          Stack() {
            // 背景圆形
            Circle()
              .width(120)
              .height(120)
              .fill(ColorResource.overlaySubtle)
              .backdropBlur(ThemeConfig.backdropBlurMedium)
              .shadow(ThemeConfig.shadowLarge)
            
            // 加载进度
            LoadingProgress()
              .width(80)
              .height(80)
              .color(ColorResource.primaryColor)
          }
          .width(120)
          .height(120)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(ColorResource.transparent)
      } else if (this.selectedProjectDetail) {
        // 使用条件渲染强制重新创建组件
        if (this.dashboardKey > 0) {
          DashboardView({ 
            project: this.selectedProjectDetail,
            showCanvasBackground: this.showCanvasBackground,
            isDarkMode: this.isDarkMode
          })
            .key(`dashboard-${this.selectedProjectId}-${this.dashboardKey}-${this.dashboardTimestamp}`)
        }
      } else {
        WelcomeView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.showCanvasBackground ? ColorResource.overlayMedium : ColorResource.backgroundSecondary)
    .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
    .opacity(this.contentOpacity)
    .scale({ x: this.contentScale, y: this.contentScale })
    .translate({ x: 0, y: this.contentTranslateY })
    .animation({
      duration: ThemeConfig.animationNormal,
      curve: ThemeConfig.animationEaseInOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .borderRadius(this.isPhone ? 0 : { topLeft: ThemeConfig.radiusLarge, bottomLeft: ThemeConfig.radiusLarge })
  }

  // 手机端菜单按钮
  @Builder
  MenuButton() {
    Button() {
      Text('☰')
        .fontSize(ThemeConfig.fontSizeXXL)
        .fontColor(Color.White)
        .fontWeight(ThemeConfig.fontWeightBold)
    }
    .width(56)
    .height(56)
    .type(ButtonType.Circle)
    .backgroundColor(ColorResource.primaryColor)
    .shadow(ThemeConfig.shadowLarge)
    .position({ x: 16, y: 16 })
    .zIndex(100)
    .scale({ x: this.menuButtonScale, y: this.menuButtonScale })
    .animation({
      duration: ThemeConfig.animationFast,
      curve: Curve.Sharp,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .onClick(() => {
      // 添加触觉反馈
      try {
        vibrator.startVibration({
          type: 'time',
          duration: 50
        }, {
          id: 0,
          usage: 'alarm'
        });
      } catch (error) {
        console.log('[Home] Haptic feedback not available:', error);
      }
      this.toggleSidebarDrawer();
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.menuButtonScale = 0.9;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.menuButtonScale = 1;
      }
    })
  }

  // 手机端侧边栏抽屉
  @Builder
  SidebarDrawer() {
    Stack() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(`rgba(0, 0, 0, ${0.5 * this.drawerOpacity})`)
        .opacity(this.drawerOpacity)
        .animation({
          duration: 300,
          curve: Curve.EaseOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
        .onClick(() => {
          this.closeSidebarDrawer();
        })
      
      // 侧边栏内容
      Row() {
        Column({ space: 0 }) {
          // 侧边栏内容（复制自 Sidebar Builder）
          // 顶部区域 - 项目列表标题和新建按钮
          Row() {
            // 项目列表标题
            Column() {
              Text('项目列表')
                .fontSize(ThemeConfig.fontSizeXXL)
                .fontWeight(ThemeConfig.fontWeightBold)
                .fontColor(ColorResource.surfaceDeep)
              Text(`(${this.projectList.length})`)
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ColorResource.surfaceEmphasized)
                .fontWeight(ThemeConfig.fontWeightMedium)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 新建项目按钮
            Stack() {
              // 进度环背景
              if (this.isLongPressing) {
                Circle()
                  .width(60)
                  .height(60)
                  .stroke(ColorResource.primaryUltraLight)
                  .strokeWidth(4)
                  .fill(Color.Transparent)
              }
              
              // 进度环
              if (this.isLongPressing && this.progressAngle > 0) {
                Circle()
                  .width(60)
                  .height(60)
                  .stroke(ColorResource.primaryColor)
                  .strokeWidth(4)
                  .fill(Color.Transparent)
                  .strokeDashArray([this.progressAngle * 3.14 * 60 / 360, 3.14 * 60])
                  .strokeDashOffset(0)
                  .rotate({ angle: -90 })
                  .animation({
                    duration: 50,
                    curve: Curve.Linear,
                    iterations: 1,
                    playMode: PlayMode.Normal
                  })
              }
              
              // 按钮主体
              Button() {
                Text('+')
                  .fontSize(ThemeConfig.fontSizeXXXXL)
                  .fontColor(Color.White)
                  .fontWeight(ThemeConfig.fontWeightBold)
              }
              .accessibilityLevel('important')
              .width(60)
              .height(60)
              .type(ButtonType.Circle)
              .backgroundColor(this.isLongPressing ? ColorResource.primaryDark : ColorResource.primaryColor)
              .shadow(ThemeConfig.shadowMedium)
              .border({ 
                width: 2, 
                color: this.isLongPressing ? ColorResource.primaryDark : ColorResource.primaryUltraLight, 
                radius: 30 
              })
              .scale({ x: this.buttonScale, y: this.buttonScale })
              .opacity(this.buttonOpacity)
              .animation({
                duration: ThemeConfig.animationFast,
                curve: ThemeConfig.animationEaseInOut,
                iterations: 1,
                playMode: PlayMode.Normal
              })
              .onClick(() => {
                this.showCreateProjectOptions();
              })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.startLongPressEffect();
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.endLongPressEffect();
                }
              })
            }
            .width(60)
            .height(60)
          }
          .width('100%')
          .padding({ top: 20, bottom: 16, left: 20, right: 20 })
          .backgroundColor(ColorResource.transparent)
          .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
          .border({ width: { bottom: 1 }, color: ColorResource.borderDivider })

          // 项目列表内容区域
          if (this.projectList.length === 0) {
            // 空状态
            Column({ space: 16 }) {
              Column({ space: 6 }) {
                Text('暂无项目')
                  .fontSize(16)
                  .fontColor(ColorResource.textMuted)
                  .fontWeight(FontWeight.Bold)
                Text('点击"+"按钮创建项目')
                  .fontSize(13)
                  .fontColor(ColorResource.textSubdued)
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .padding(24)
            .justifyContent(FlexAlign.Center)
            .layoutWeight(1)
          } else if (this.projectList.length > 0) {
            List({ space: ThemeConfig.spacingS }) {
              ForEach(this.projectList, (meta: ProjectMeta) => {
                ListItem() {
                  Column({ space: ThemeConfig.spacingS }) {
                    Text(meta.name)
                      .fontSize(ThemeConfig.fontSizeM)
                      .fontWeight(ThemeConfig.fontWeightBold)
                      .fontColor(ColorResource.surfaceDeep)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                      .lineHeight(ThemeConfig.fontSizeM * 1.4)
                    Text(`修改于: ${new Date(meta.lastModified).toLocaleDateString()}`)
                      .fontSize(ThemeConfig.fontSizeXS)
                      .fontColor(ColorResource.surfaceEmphasized)
                      .fontWeight(ThemeConfig.fontWeightMedium)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('100%')
                  .padding({ 
                    top: ThemeConfig.spacingM,
                    bottom: ThemeConfig.spacingM,
                    left: ThemeConfig.spacingL,
                    right: ThemeConfig.spacingL
                  })
                  .backgroundColor(this.selectedProjectId === meta.id ? 
                                 ColorResource.primaryUltraLight : ColorResource.surface)
                  .borderRadius(ThemeConfig.radiusLarge)
                  .shadow(this.selectedProjectId === meta.id ? ThemeConfig.shadowHover : ThemeConfig.cardShadow)
                  .border({ 
                    width: this.selectedProjectId === meta.id ? 2 : 1, 
                    color: this.selectedProjectId === meta.id ? ColorResource.primaryColor : ColorResource.surfaceNeutral, 
                    radius: ThemeConfig.radiusLarge 
                  })
                  .margin({ bottom: ThemeConfig.spacingS })
                }
                .onClick(() => {
                  // 添加触觉反馈
                  try {
                    vibrator.startVibration({
                      type: 'time',
                      duration: 40
                    }, {
                      id: 0,
                      usage: 'alarm'
                    });
                  } catch (error) {
                    console.log('[Home] Haptic feedback not available:', error);
                  }
                  
                  this.onSelectProject(meta.id);
                  // 手机端选择项目后关闭抽屉
                  this.closeSidebarDrawer();
                })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.pressedProjectId = meta.id;
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.pressedProjectId = null;
                  }
                })
                .scale({ 
                  x: this.pressedProjectId === meta.id ? 0.97 : 1,
                  y: this.pressedProjectId === meta.id ? 0.97 : 1
                })
                .animation({
                  duration: ThemeConfig.animationFast,
                  curve: Curve.Sharp,
                  iterations: 1,
                  playMode: PlayMode.Normal
                })
              })
            }
            .height('100%')
            .width('100%')
            .layoutWeight(1)
            .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingS })
          }
        }
        .width('80%')
        .constraintSize({ maxWidth: 360 })
        .height('100%')
        .backgroundColor(ColorResource.backgroundPage)
        .shadow(ThemeConfig.shadowXLarge)
        .translate({ x: `${this.drawerTranslateX}%`, y: 0 })
        .animation({
          duration: 300,
          curve: Curve.Sharp,
          iterations: 1,
          playMode: PlayMode.Normal
        })
        .gesture(
          // 添加滑动手势支持
          PanGesture({ direction: PanDirection.Left })
            .onActionStart(() => {
              console.log('[Home] Swipe gesture started');
            })
            .onActionUpdate((event: GestureEvent) => {
              // 如果向左滑动超过50，开始收起抽屉
              if (event && event.offsetX < -50) {
                const progress = Math.min(Math.abs(event.offsetX) / 200, 1);
                this.drawerTranslateX = -progress * 100;
                this.drawerOpacity = 1 - progress;
              }
            })
            .onActionEnd((event: GestureEvent) => {
              // 如果滑动距离超过100，则关闭抽屉
              if (event && event.offsetX < -100) {
                this.closeSidebarDrawer();
              } else {
                // 否则回弹
                this.drawerTranslateX = 0;
                this.drawerOpacity = 1;
              }
            })
        )
        
        Blank()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(1000)
  }

  @Builder
  Sidebar() {
    Column({ space: 0 }) {
      // 顶部区域 - 项目列表标题和新建按钮
      Row() {
        // 项目列表标题
        Column() {
          Text('项目列表')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.surfaceDeep)
          Text(`(${this.projectList.length})`)
            .fontSize(ThemeConfig.fontSizeM)
            .fontColor(ColorResource.surfaceEmphasized)
            .fontWeight(ThemeConfig.fontWeightMedium)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 新建项目按钮 - 现代化设计，增强视觉吸引力
        Stack() {
          // 进度环背景 - 更柔和的颜色
          if (this.isLongPressing) {
            Circle()
              .width(60)
              .height(60)
              .stroke(ColorResource.primaryUltraLight)
              .strokeWidth(4)
              .fill(Color.Transparent)
          }
          
          // 进度环 - 更流畅的动画
          if (this.isLongPressing && this.progressAngle > 0) {
            Circle()
              .width(60)
              .height(60)
              .stroke(ColorResource.primaryColor)
              .strokeWidth(4)
              .fill(Color.Transparent)
              .strokeDashArray([this.progressAngle * 3.14 * 60 / 360, 3.14 * 60])
              .strokeDashOffset(0)
              .rotate({ angle: -90 })
              .animation({
                duration: 50,
                curve: Curve.Linear,
                iterations: 1,
                playMode: PlayMode.Normal
              })
          }
          
          // 按钮主体 - 增强渐变效果
          Button() {
            Text('+')
              .fontSize(this.isPhone ? ThemeConfig.fontSizeXXXXXL : ThemeConfig.fontSizeXXXXL)
              .fontColor(Color.White)
              .fontWeight(ThemeConfig.fontWeightBold)
          }
          .accessibilityLevel('important')
          .width(this.isPhone ? 52 : 60)
          .height(this.isPhone ? 52 : 60)
          .type(ButtonType.Circle)
          .backgroundColor(this.isLongPressing ? ColorResource.primaryDark : ColorResource.primaryColor)
          .shadow(ThemeConfig.shadowMedium)
          // .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
          .border({ 
            width: 2, 
            color: this.isLongPressing ? ColorResource.primaryDark : ColorResource.primaryUltraLight, 
            radius: 30 
          })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .opacity(this.buttonOpacity)
          .animation({
            duration: ThemeConfig.animationFast,
            curve: ThemeConfig.animationEaseInOut,
            iterations: 1,
            playMode: PlayMode.Normal
          })
          .onClick(() => {
            this.showCreateProjectOptions();
          })
          .gesture(
            LongPressGesture({ repeat: false })
              .onAction(() => {
                // 长按快速创建空白项目（由进度动画触发）
              })
          )
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              // 按下时开始长按效果
              this.startLongPressEffect();
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              // 抬起或取消时结束长按效果
              this.endLongPressEffect();
            }
          })
          .gesture(
            TapGesture({ count: 1 })
              .onAction(() => {
                // 添加触觉反馈
                this.showCreateProjectOptions();
              })
          )
        }
        .width(60)
        .height(60)
      }
      .width('100%')
      .padding({ top: 20, bottom: 16, left: 20, right: 20 })
      .backgroundColor(ColorResource.transparent)
      .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
      .border({ width: { bottom: 1 }, color: ColorResource.borderDivider })

      // 当前项目信息区域 - 简约设计
      if (this.selectedProjectDetail) {
        Row({ space: 16 }) {
          Column({ space: 2 }) {
            Text('当前项目')
              .fontSize(11)
              .fontColor(ColorResource.textMuted)
              .fontWeight(FontWeight.Medium)
            Text(this.selectedProjectDetail.name)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorResource.textStrong)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorResource.transparent)
        .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
        .border({ width: { bottom: 1 }, color: ColorResource.borderDivider })
      }

      // 项目列表内容区域
      if (this.projectList.length === 0) {
        // 空状态 - 简约设计
        Column({ space: this.isPhone ? 16 : 20 }) {
          Column({ space: this.isPhone ? 6 : 8 }) {
            Text('空空如也')
              .fontSize(this.isPhone ? 16 : 18)
              .fontColor(ColorResource.textMuted)
              .fontWeight(FontWeight.Bold)
            Text(this.isPhone ? '点击"+"按钮创建项目' : '点击右上角"+"按钮\n创建您的第一个项目')
              .fontSize(this.isPhone ? 13 : 14)
              .fontColor(ColorResource.textSubdued)
              .textAlign(TextAlign.Center)
              .lineHeight(this.isPhone ? 18 : 20)
          }
        }
        .width('100%')
        .padding(this.isPhone ? 24 : 32)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ColorResource.transparent)
        .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
        .borderRadius(ThemeConfig.radiusLarge)
        .margin(ThemeConfig.spacingM)
        .layoutWeight(1)
      } else {
        // 项目列表
        if (this.projectList.length > 0) {
          List({ space: ThemeConfig.spacingS }) {
            ForEach(this.projectList, (meta: ProjectMeta) => {
              ListItem() {
              Row() {
                // 主要内容区域
                Column({ space: ThemeConfig.spacingS }) {
                  Text(meta.name)
                    .fontSize(ThemeConfig.fontSizeM)
                    .fontWeight(ThemeConfig.fontWeightBold)
                    .fontColor(ColorResource.surfaceDeep)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .lineHeight(ThemeConfig.fontSizeM * 1.4)
                  Text(`修改于: ${new Date(meta.lastModified).toLocaleDateString()}`)
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.surfaceEmphasized)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .padding({ 
                  top: ThemeConfig.spacingM,
                  bottom: ThemeConfig.spacingM,
                  left: ThemeConfig.spacingL
                })

                // 三点菜单按钮
                Button() {
                  Text('⋯')
                    .fontSize(ThemeConfig.fontSizeXL)
                    .fontColor(ColorResource.surfaceEmphasized)
                    .rotate({ angle: 90 })
                }
                .width(40)
                .height(40)
                .type(ButtonType.Circle)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  // 显示菜单（编辑、删除）
                  this.showProjectMenu(meta.id);
                })
                .hitTestBehavior(HitTestMode.Block)
              }
              .width('100%')
              .backgroundColor(this.selectedProjectId === meta.id ? 
                               (this.showCanvasBackground ? ColorResource.hoverPrimaryLight : ColorResource.primaryUltraLight) :
                               this.hoveredProjectId === meta.id ? 
                               (this.showCanvasBackground ? ColorResource.overlayRegular : ColorResource.surfaceSubtle) : 
                               (this.showCanvasBackground ? ColorResource.overlayMedium : ColorResource.surface))
              .borderRadius(ThemeConfig.radiusLarge)
              .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
              .shadow(this.selectedProjectId === meta.id ? ThemeConfig.shadowHover : 
                     this.hoveredProjectId === meta.id ? ThemeConfig.shadowMedium : ThemeConfig.cardShadow)
              .border({ 
                width: this.selectedProjectId === meta.id ? 2 : 1, 
                color: this.selectedProjectId === meta.id ? ColorResource.primaryColor : ColorResource.surfaceNeutral, 
                radius: ThemeConfig.radiusLarge 
              })
              .margin({ bottom: ThemeConfig.spacingS })
            }
            .accessibilityLevel('important')
            .onClick(() => {
              console.log(`[Home] Project card clicked: ${meta.id}`);
              
              // 添加触觉反馈
              try {
                vibrator.startVibration({
                  type: 'time',
                  duration: 50
                }, {
                  id: 0,
                  usage: 'alarm'
                });
              } catch (error) {
                console.log('[Home] Haptic feedback not available:', error);
              }
              
              this.onSelectProject(meta.id);
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.hoveredProjectId = meta.id;
                this.pressedProjectId = meta.id;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.hoveredProjectId = null;
                this.pressedProjectId = null;
              }
            })
            .scale({ 
              x: this.pressedProjectId === meta.id ? 0.97 : 1,
              y: this.pressedProjectId === meta.id ? 0.97 : 1
            })
            .animation({
              duration: ThemeConfig.animationFast,
              curve: Curve.Sharp,
              iterations: 1,
              playMode: PlayMode.Normal
            })
          })
        }
        .height('100%')
        .width('100%')
        .layoutWeight(1)
        .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingS })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.showCanvasBackground ? ColorResource.transparent : ColorResource.backgroundPage)
    .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
    .border({ width: { right: 1 }, color: ColorResource.borderDivider })
    .layoutWeight(1)
  }

  // 画布背景构建器
  @Builder
  CanvasBackground() {
    Canvas(this.canvasController.getRenderer().getContext())
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .position({ x: 0, y: 0 })
      .zIndex(-1) // 确保在背景层
      .onReady(() => {
        if (this.selectedProjectDetail) {
          this.renderProjectCanvas();
        }
      })
      .onTouch((event: TouchEvent) => {
        // 处理画布触摸事件
        if (!this.selectedProjectDetail) {
          return;
        }

        this.canvasController.getActions().handleTouch(
          event,
          this.selectedProjectDetail,
          null // Home页面不需要选中任务高亮
        );
        
        // 重新渲染画布
        this.renderProjectCanvas();
      })
  }

  // 渲染项目画布
  private renderProjectCanvas() {
    if (!this.selectedProjectDetail) return;
    
    const renderer = this.canvasController.getRenderer();
    const config = this.canvasController.getActions().getRenderConfig(null);
    
    // 渲染画布内容
    renderer.render(this.selectedProjectDetail, config);
  }

  // 初始化画布控制器回调（在项目加载后调用）
  private initializeCanvasCallbacks() {
    if (!this.canvasController) return;

    // 设置画布控制器回调
    this.canvasController.setCallbacks(
      // onTaskSelect
      (task: TaskNode | null) => {
        console.log('[Home] Task selected:', task?.name || 'None');
      },
      // onDependencyCreate
      (fromId: string, toId: string) => {
        console.log('[Home] Dependency create:', fromId, '->', toId);
      },
      // onTaskMove（拖拽结束时保存位置）
      (taskId: string, x: number, y: number) => {
        console.log('[Home] Task move complete:', taskId, x, y);
        this.handleTaskMove(taskId, x, y);
      },
      // onTaskMoveImmediate（拖拽过程中实时更新位置）
      (taskId: string, x: number, y: number) => {
        this.handleTaskMoveImmediate(taskId, x, y);
      },
      // onTaskClick (用于缩略模式显示详情)
      (task: TaskNode) => {
        console.log('[Home] Task clicked in compact mode:', task.name);
        this.showTaskDetailDialog(task);
      }
    );
  }

  // 处理任务立即移动（拖拽过程中）
  private handleTaskMoveImmediate(taskId: string, x: number, y: number) {
    if (!this.selectedProjectDetail) return;
    
    // 查找并更新任务位置
    const task = this.selectedProjectDetail.tasks.find(t => t.id === taskId);
    if (task) {
      task.x = x;
      task.y = y;
      
      // 更新时间戳以触发响应式更新
      this.selectedProjectDetail.lastModified = Date.now();
      
      // 重新渲染画布（确保所有画布都更新）
      this.renderProjectCanvas();
    }
  }

  // 处理任务移动完成（拖拽结束时保存）
  private async handleTaskMove(taskId: string, x: number, y: number) {
    if (!this.selectedProjectDetail || !this.storageService) return;
    
    // 查找并更新任务位置
    const task = this.selectedProjectDetail.tasks.find(t => t.id === taskId);
    if (task) {
      task.x = x;
      task.y = y;
      
      // 更新项目时间戳
      this.selectedProjectDetail.lastModified = Date.now();
      
      // 保存到存储
      try {
        await this.storageService.saveProject(this.selectedProjectDetail);
        console.log('[Home] Task position saved:', taskId, x, y);
        
        // 显示成功提示
        this.promptAction.showToast({
          message: '位置已保存',
          duration: 1500
        });
      } catch (error) {
        console.error('[Home] Failed to save task position:', error);
        this.promptAction.showToast({
          message: '保存失败，请重试',
          duration: 2000
        });
      }
      
      // 重新渲染画布
      this.renderProjectCanvas();
    }
  }

  // 计算项目总任务数
  private getProjectTotalTasks(project: Project | null): number {
    if (!project) return 0;
    return project.tasks.length;
  }

  // 计算项目已完成任务数
  private getProjectCompletedTasks(project: Project | null): number {
    if (!project) return 0;
    return project.tasks.filter(task => 
      task.checklist.length > 0 && task.checklist.every(item => item.isCompleted)
    ).length;
  }

  // 计算项目关键任务数
  private getProjectCriticalTasks(project: Project | null): number {
    if (!project) return 0;
    return project.tasks.filter(task => task.isCritical).length;
  }

  // 显示项目菜单
  private showProjectMenu(projectId: string) {
    const project = this.projectList.find(p => p.id === projectId);
    if (!project) return;

    // 触觉反馈
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 30
      }, {
        id: 0,
        usage: 'alarm'
      });
    } catch (error) {
      console.log('[Home] Haptic feedback not available:', error);
    }

    // 显示操作菜单
    this.promptAction.showDialog({
      title: project.name,
      message: '选择操作',
      buttons: [
        {
          text: '编辑名称',
          color: ColorResource.primaryColor
        },
        {
          text: '删除项目',
          color: ColorResource.errorColor
        },
        {
          text: '取消',
          color: ColorResource.surfaceEmphasized
        }
      ]
    }, (error, data) => {
      if (error) {
        console.error('[Home] Show menu error:', error);
        return;
      }
      
      if (data.index === 0) {
        // 编辑名称
        this.showRenameProjectDialog(projectId);
      } else if (data.index === 1) {
        // 删除项目
        this.deleteProject(projectId);
      }
    });
  }

  // 显示重命名对话框
  private showRenameProjectDialog(projectId: string) {
    const project = this.projectList.find(p => p.id === projectId);
    if (!project) return;

    // 先关闭之前的对话框（如果存在）
    if (this.renameDialogController) {
      this.renameDialogController.close();
      this.renameDialogController = null;
    }

    this.renameProjectId = projectId;
    this.renameProjectName = project.name;

    // 创建并打开对话框
    this.renameDialogController = new CustomDialogController({
      builder: RenameProjectDialog({
        projectName: this.renameProjectName,
        onConfirm: (newName: string) => {
          this.handleRenameProject(this.renameProjectId, newName);
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.renameDialogController.open();
  }

  // 显示节点详情对话框（缩略模式下点击节点时触发）
  private showTaskDetailDialog(task: TaskNode) {
    // 先关闭之前的对话框（如果存在）
    if (this.taskDetailDialogController) {
      this.taskDetailDialogController.close();
      this.taskDetailDialogController = null;
    }

    this.selectedTaskForDetail = task;

    // 创建并打开对话框
    this.taskDetailDialogController = new CustomDialogController({
      builder: TaskNodeDetailDialog({
        task: this.selectedTaskForDetail,
        project: this.selectedProjectDetail, // 传递项目数据以显示依赖关系
        isDarkMode: this.isDarkMode,
        onEdit: () => {
          this.handleEditTask(task);
        },
        onDelete: () => {
          this.handleDeleteTask(task);
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.taskDetailDialogController.open();
  }

  // 编辑任务（从节点详情对话框触发）
  private handleEditTask(task: TaskNode) {
    if (!this.selectedProjectId) return;
    
    // 跳转到Index页面，并传递任务ID以便编辑
    router.pushUrl({
      url: 'pages/Index',
      params: {
        projectId: this.selectedProjectId,
        taskId: task.id
      }
    }).catch((error: Error) => {
      console.error('[Home] Failed to navigate to Index:', error);
      this.promptAction.showToast({
        message: '跳转失败',
        duration: 2000
      });
    });
  }

  // 删除任务（从节点详情对话框触发）
  private handleDeleteTask(task: TaskNode) {
    // Home 页面是只读视图，不支持删除任务
    // 引导用户跳转到 Index 页面进行编辑
    this.promptAction.showToast({
      message: '请在项目编辑页面删除任务',
      duration: 2000
    });
    
    // 跳转到 Index 页面
    if (!this.selectedProjectId) return;
    
    router.pushUrl({
      url: 'pages/Index',
      params: {
        projectId: this.selectedProjectId,
        taskId: task.id
      }
    }).catch((error: Error) => {
      console.error('[Home] Failed to navigate to Index:', error);
    });
  }

  // 处理项目重命名
  private async handleRenameProject(projectId: string, newName: string) {
    try {
      if (!this.storageService) return;

      // 获取完整的项目数据
      const project = await this.storageService.getProject(projectId);
      if (!project) {
        this.promptAction.showToast({
          message: '项目不存在',
          duration: 2000
        });
        return;
      }

      // 更新项目名称和时间戳
      project.name = newName;
      project.lastModified = Date.now();

      // 保存到存储
      await this.storageService.saveProject(project);

      // 更新本地项目列表
      const projectIndex = this.projectList.findIndex(p => p.id === projectId);
      if (projectIndex !== -1) {
        this.projectList[projectIndex].name = newName;
        this.projectList[projectIndex].lastModified = Date.now();
      }

      // 如果是当前选中的项目，也更新详情数据
      if (this.selectedProjectDetail && this.selectedProjectDetail.id === projectId) {
        this.selectedProjectDetail.name = newName;
        this.selectedProjectDetail.lastModified = Date.now();
      }

      // 显示成功提示
      this.promptAction.showToast({
        message: `项目已重命名为"${newName}"`,
        duration: 2000
      });

      // 强制刷新UI
      this.componentKey++;
    } catch (error) {
      console.error('[Home] Rename project error:', error);
      this.promptAction.showToast({
        message: '重命名失败，请重试',
        duration: 2000
      });
    }
  }

  // 手机端 - 欢迎页
  @Builder
  PhoneWelcomePage() {
    Stack() {
      // 欢迎内容
      WelcomeView()
      
      // 上滑提示
      Column({ space: ThemeConfig.spacingS }) {
        // 向上箭头动画
        Text('↑')
          .fontSize(ThemeConfig.fontSizeXXL)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(ThemeConfig.fontWeightBold)
          .translate({ x: 0, y: this.arrowAnimationOffset })
          .animation({
            duration: 1000,
            curve: Curve.EaseInOut,
            iterations: -1, // 无限循环
            playMode: PlayMode.Alternate
          })
          .onAppear(() => {
            // 启动动画
            this.arrowAnimationOffset = -10;
          })
        
        Text('上滑查看项目列表')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.surfaceEmphasized)
          .fontWeight(ThemeConfig.fontWeightMedium)
      }
      .width('100%')
      .position({ x: 0, y: '100%' })
      .translate({ x: 0, y: -100 })
      .alignItems(HorizontalAlign.Center)
      .opacity(this.pageTranslateY < 0 ? 1 + this.pageTranslateY / 200 : 1) // 上滑时淡出
    }
    .width('100%')
    .height('100%')
    .translate({ x: 0, y: this.pageTranslateY })
    .animation({
      duration: 350,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .gesture(
      PanGesture({ direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent) => {
          console.log('[Home] Welcome page swipe start');
        })
        .onActionUpdate((event: GestureEvent) => {
          // 向上滑动时offsetY为负数，只允许向上滑动
          // 添加阻尼效果，让拖动感觉更自然
          if (event.offsetY < 0) {
            const damping = 0.6; // 阻尼系数
            this.pageTranslateY = event.offsetY * damping;
          }
        })
        .onActionEnd((event: GestureEvent) => {
          // 向上滑动超过阈值，切换到项目列表
          // 因为有0.6的阻尼，所以用户需要滑动约-250才能达到-150的阈值
          if (event.offsetY < -250) {
            // 触觉反馈
            try {
              vibrator.startVibration({
                type: 'time',
                duration: 40
              }, {
                id: 0,
                usage: 'alarm'
              });
            } catch (error) {
              console.log('[Home] Haptic feedback not available:', error);
            }
            
            // 动画过渡到项目列表
            this.pageTranslateY = -1000; // 向上滑出
            setTimeout(() => {
              this.phoneViewMode = 'list';
              this.pageTranslateY = 0; // 重置位置
            }, 300);
          } else {
            // 回弹
            this.pageTranslateY = 0;
          }
        })
    )
  }

  // 手机端 - 项目列表视图
  @Builder
  PhoneProjectList() {
    Column() {
      // 下滑返回提示（半透明顶部指示器）
      if (this.pageTranslateY > 20) {
        Row({ space: 8 }) {
          Text('↓')
            .fontSize(ThemeConfig.fontSizeL)
            .fontColor(ColorResource.primaryColor)
          Text('松开返回首页')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.surfaceEmphasized)
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ColorResource.surface)
        .backdropBlur(10)
        .position({ x: 0, y: 0 })
        .zIndex(1000)
        .opacity(Math.min(this.pageTranslateY / 100, 0.98))
        .shadow({ radius: 8, color: this.isDarkMode ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
      }
      
      // 顶部标题栏
      Row({ space: 16 }) {
        Text('我的项目')
          .fontSize(ThemeConfig.fontSizeXXL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.surfaceDeep)
          .layoutWeight(1)
        
        // 添加按钮
        Stack() {
          // 进度环背景
          if (this.isLongPressing) {
            Circle()
              .width(52)
              .height(52)
              .stroke(ColorResource.primaryUltraLight)
              .strokeWidth(4)
              .fill(Color.Transparent)
          }
          
          // 进度环
          if (this.isLongPressing && this.progressAngle > 0) {
            Circle()
              .width(52)
              .height(52)
              .stroke(ColorResource.primaryColor)
              .strokeWidth(4)
              .fill(Color.Transparent)
              .strokeDashArray([this.progressAngle * 3.14 * 52 / 360, 3.14 * 52])
              .strokeDashOffset(0)
              .rotate({ angle: -90 })
              .animation({
                duration: 50,
                curve: Curve.Linear,
                iterations: 1,
                playMode: PlayMode.Normal
              })
          }
          
          // 按钮主体
          Button() {
            Text('+')
              .fontSize(ThemeConfig.fontSizeXXXXXL)
              .fontColor(Color.White)
              .fontWeight(ThemeConfig.fontWeightBold)
          }
          .accessibilityLevel('important')
          .width(52)
          .height(52)
          .type(ButtonType.Circle)
          .backgroundColor(this.isLongPressing ? ColorResource.primaryDark : ColorResource.primaryColor)
          .shadow(ThemeConfig.shadowMedium)
          .border({ 
            width: 2, 
            color: this.isLongPressing ? ColorResource.primaryDark : ColorResource.primaryUltraLight, 
            radius: 26
          })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .opacity(this.buttonOpacity)
          .animation({
            duration: ThemeConfig.animationFast,
            curve: ThemeConfig.animationEaseInOut,
            iterations: 1,
            playMode: PlayMode.Normal
          })
          .onClick(() => {
            this.showCreateProjectOptions();
          })
          .gesture(
            LongPressGesture({ repeat: false })
              .onAction(() => {
                // 长按快速创建空白项目
              })
          )
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.startLongPressEffect();
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.endLongPressEffect();
            }
          })
        }
        .width(52)
        .height(52)
      }
      .width('100%')
      .padding({ top: 20, bottom: 16, left: 20, right: 20 })
      .backgroundColor(ColorResource.surface)
      .border({ width: { bottom: 1 }, color: ColorResource.borderDivider })

      // 项目列表内容区域
      if (this.projectList.length === 0) {
        // 空状态
        Column({ space: 20 }) {
          Column({ space: 8 }) {
            Text('空空如也')
              .fontSize(16)
              .fontColor(ColorResource.textMuted)
              .fontWeight(ThemeConfig.fontWeightBold)
            Text('点击右上角"+"按钮\n创建您的第一个项目')
              .fontSize(13)
              .fontColor(ColorResource.textSubdued)
              .textAlign(TextAlign.Center)
              .lineHeight(18)
          }
        }
        .width('100%')
        .padding(24)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ColorResource.backgroundPage)
        .borderRadius(ThemeConfig.radiusLarge)
        .margin(ThemeConfig.spacingM)
        .layoutWeight(1)
      } else {
        // 项目卡片列表
        List({ space: ThemeConfig.spacingS }) {
          ForEach(this.projectList, (meta: ProjectMeta) => {
            ListItem() {
              Row() {
                // 主要内容区域
                Column({ space: ThemeConfig.spacingS }) {
                  Text(meta.name)
                    .fontSize(ThemeConfig.fontSizeM)
                    .fontWeight(ThemeConfig.fontWeightBold)
                    .fontColor(ColorResource.surfaceDeep)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .lineHeight(ThemeConfig.fontSizeM * 1.4)
                  Text(`修改于: ${new Date(meta.lastModified).toLocaleDateString()}`)
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.surfaceEmphasized)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .padding({ 
                  top: ThemeConfig.spacingM,
                  bottom: ThemeConfig.spacingM,
                  left: ThemeConfig.spacingL
                })

                // 三点菜单按钮
                Button() {
                  Text('⋯')
                    .fontSize(ThemeConfig.fontSizeXL)
                    .fontColor(ColorResource.surfaceEmphasized)
                    .rotate({ angle: 90 })
                }
                .width(40)
                .height(40)
                .type(ButtonType.Circle)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  // 显示菜单（编辑、删除）
                  this.showProjectMenu(meta.id);
                })
                .hitTestBehavior(HitTestMode.Block)
              }
              .width('100%')
              .backgroundColor(
                this.selectedProjectId === meta.id ? 
                ColorResource.primaryUltraLight :
                this.hoveredProjectId === meta.id ? 
                ColorResource.surfaceSubtle : 
                ColorResource.surface
              )
              .borderRadius(ThemeConfig.radiusLarge)
              .shadow(this.selectedProjectId === meta.id ? ThemeConfig.shadowHover : 
                     this.hoveredProjectId === meta.id ? ThemeConfig.shadowMedium : ThemeConfig.cardShadow)
              .border({ 
                width: this.selectedProjectId === meta.id ? 2 : 1, 
                color: this.selectedProjectId === meta.id ? ColorResource.primaryColor : ColorResource.surfaceNeutral, 
                radius: ThemeConfig.radiusLarge
              })
              .margin({ bottom: ThemeConfig.spacingS })
            }
            .accessibilityLevel('important')
            .onClick(() => {
              console.log(`[Home] Phone project card clicked: ${meta.id}`);
              
              // 触觉反馈
              try {
                vibrator.startVibration({
                  type: 'time',
                  duration: 40
                }, {
                  id: 0,
                  usage: 'alarm'
                });
              } catch (error) {
                console.log('[Home] Haptic feedback not available:', error);
              }
              
              // 选中项目并显示Dashboard卡片
              this.onSelectProject(meta.id);
              
              // 等待项目数据加载完成后再显示卡片
              setTimeout(() => {
                this.showCanvasBackground = true;
                this.showDashboardCard = true;
                
                // 再次延迟确保Canvas已创建
                setTimeout(() => {
                  this.renderProjectCanvas();
                }, 150);
              }, 300);
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.hoveredProjectId = meta.id;
                this.pressedProjectId = meta.id;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.hoveredProjectId = null;
                this.pressedProjectId = null;
              }
            })
            .scale({ 
              x: this.pressedProjectId === meta.id ? 0.97 : 1,
              y: this.pressedProjectId === meta.id ? 0.97 : 1
            })
            .animation({
              duration: ThemeConfig.animationFast,
              curve: Curve.Sharp,
              iterations: 1,
              playMode: PlayMode.Normal
            })
          })
        }
        .height('100%')
        .width('100%')
        .layoutWeight(1)
        .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingS })
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
    .translate({ x: 0, y: this.pageTranslateY })
    .animation({
      duration: 350,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .gesture(
      PanGesture({ direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent) => {
          console.log('[Home] Project list swipe start');
        })
        .onActionUpdate((event: GestureEvent) => {
          // 向下滑动时offsetY为正数，只允许向下滑动
          // 添加阻尼效果，让拖动感觉更自然
          if (event.offsetY > 0) {
            const damping = 0.6; // 阻尼系数
            this.pageTranslateY = event.offsetY * damping;
          }
        })
        .onActionEnd((event: GestureEvent) => {
          // 向下滑动超过阈值，返回首页
          // 因为有0.6的阻尼，所以用户需要滑动约250才能达到150的阈值
          if (event.offsetY > 250) {
            // 触觉反馈
            try {
              vibrator.startVibration({
                type: 'time',
                duration: 40
              }, {
                id: 0,
                usage: 'alarm'
              });
            } catch (error) {
              console.log('[Home] Haptic feedback not available:', error);
            }
            
            // 动画过渡到首页
            this.pageTranslateY = 1000; // 向下滑出
            setTimeout(() => {
              this.phoneViewMode = 'welcome';
              this.pageTranslateY = 0; // 重置位置
            }, 300);
          } else {
            // 回弹
            this.pageTranslateY = 0;
          }
        })
    )
  }

  // 手机端 - Dashboard浮动卡片
  @Builder
  PhoneDashboardCard() {
    Stack() {
      // 遮罩层（可点击关闭）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.3)')
        .onClick(() => {
          // 关闭Dashboard卡片
          this.showDashboardCard = false;
          this.showCanvasBackground = false;
        })
      
      // Dashboard卡片（包含画布背景）
      Stack() {
        // 画布背景层（只在卡片范围内显示）
        if (this.selectedProjectDetail) {
          Canvas(this.canvasController.getRenderer().getContext())
            .width('100%')
            .height('100%')
            .backgroundColor(Color.Transparent)
            .borderRadius(ThemeConfig.radiusXLarge)
            .onReady(() => {
              // Canvas准备就绪后立即渲染
              if (this.selectedProjectDetail) {
                this.renderProjectCanvas();
              }
            })
            .onTouch((event: TouchEvent) => {
              // 处理画布触摸事件（缩略模式下点击节点显示详情）
              if (!this.selectedProjectDetail) {
                return;
              }

              this.canvasController.getActions().handleTouch(
                event,
                this.selectedProjectDetail,
                null
              );
              
              // 重新渲染画布
              this.renderProjectCanvas();
            })
        }
        
        // 半透明遮罩层（降低画布对比度，让Dashboard内容更清晰）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.isDarkMode ? 'rgba(0, 0, 0, 0.5)' : 'rgba(255, 255, 255, 0.4)')
          .backdropBlur(40)
          .borderRadius(ThemeConfig.radiusXLarge)
          .hitTestBehavior(HitTestMode.Transparent) // 允许触摸事件穿透到画布
        
        // Dashboard内容层
        Column() {
          // 顶部操作栏
          Row() {
            // 关闭按钮
            Button() {
              Text('×')
                .fontSize(ThemeConfig.fontSizeXXL)
                .fontColor(ColorResource.surfaceDeep)
            }
            .width(40)
            .height(40)
            .type(ButtonType.Circle)
            .backgroundColor(this.isDarkMode ? 'rgba(50, 50, 50, 0.9)' : 'rgba(255, 255, 255, 0.9)')
            .shadow(ThemeConfig.shadowSmall)
            .onClick(() => {
              try {
                vibrator.startVibration({
                  type: 'time',
                  duration: 30
                }, {
                  id: 0,
                  usage: 'alarm'
                });
              } catch (error) {
                console.log('[Home] Haptic feedback not available:', error);
              }
              this.showDashboardCard = false;
              this.showCanvasBackground = false;
            })

            Blank()

            // 编辑按钮
            Button() {
              Text('✎')
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(Color.White)
            }
            .width(40)
            .height(40)
            .type(ButtonType.Circle)
            .backgroundColor(ColorResource.primaryColor)
            .onClick(() => {
              try {
                vibrator.startVibration({
                  type: 'time',
                  duration: 40
                }, {
                  id: 0,
                  usage: 'alarm'
                });
              } catch (error) {
                console.log('[Home] Haptic feedback not available:', error);
              }
              
              if (this.selectedProjectId) {
                this.getUIContext().getRouter().pushUrl({
                  url: 'pages/Index',
                  params: { projectId: this.selectedProjectId },
                  animation: {
                    type: 'fade',
                    duration: 300
                  }
                } as router.RouterOptions);
              }
            })
          }
          .width('100%')
          .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, top: ThemeConfig.spacingM, bottom: ThemeConfig.spacingS })

          // Dashboard内容（可滚动）
          Scroll() {
            if (this.selectedProjectDetail) {
              DashboardView({ 
                project: this.selectedProjectDetail,
                showCanvasBackground: false,
                isFloatingCard: true,
                isDarkMode: this.isDarkMode
              })
                .key(`dashboard-card-${this.selectedProjectId}-${this.dashboardKey}-${this.dashboardTimestamp}`)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          .backgroundColor(Color.Transparent)
          .hitTestBehavior(HitTestMode.Default) // 滚动区域正常处理触摸事件
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Default) // Dashboard内容层正常处理触摸事件
      }
      .width('90%')
      .height('75%')
      .backgroundColor(this.isDarkMode ? 'rgba(30, 30, 30, 0.3)' : 'rgba(255, 255, 255, 0.2)')
      .backdropBlur(20)
      .borderRadius(ThemeConfig.radiusXLarge)
      .shadow({ radius: 40, color: this.isDarkMode ? 'rgba(0, 0, 0, 0.5)' : 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 8 })
      .border({
        width: 1.5,
        color: this.isDarkMode ? 'rgba(80, 80, 80, 0.6)' : 'rgba(255, 255, 255, 0.6)',
        radius: ThemeConfig.radiusXLarge
      })
      .clip(true)
      .scale({ x: this.contentScale, y: this.contentScale })
      .opacity(this.contentOpacity)
      .animation({
        duration: ThemeConfig.animationNormal,
        curve: Curve.Friction,
        iterations: 1,
        playMode: PlayMode.Normal
      })
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }
}
