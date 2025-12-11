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
import { ImportService } from '../services/ImportService';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { ResponsiveColorConfig } from '../utils/ResponsiveColorConfig';
import common from '@ohos.app.ability.common';
import { Project, TaskNode } from '../model/ProjectData';
import { DashboardView } from '../components/DashboardView';
import { WelcomeView } from '../components/WelcomeView';
import { CanvasController } from '../core/canvas/CanvasController';
import { RenderMode } from '../core/canvas/CanvasRenderer';
import vibrator from '@ohos.vibrator';
import { PromptAction } from '@kit.ArkUI';
import router from '@ohos.router';
import { ErrorHandler } from '../core/ErrorHandler';
import { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { BreakpointSystem, BreakpointConfig } from '../utils/BreakpointSystem';
import { AIService } from '../services/AIService';

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
    Column({ space: 0 }) {
      // 标题区域
      Column({ space: 4 }) {
        Text('编辑项目名称')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .padding({ top: 24, left: 24, right: 24, bottom: 16 })
      
      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)
      
      // 内容区域
      Column({ space: 8 }) {
        TextInput({ text: this.inputValue, placeholder: '请输入项目名称' })
          .width('100%')
          .height(44)
          .fontSize(16)
          .backgroundColor(ColorResource.surface)
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.inputValue = value;
          })
      }
      .width('100%')
      .padding({ top: 16, left: 24, right: 24, bottom: 20 })
      
      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)
      
      // 按钮区域
      Row({ space: 0 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .borderRadius(0)
          .onClick(() => {
            this.controller.close();
          })
        
        // 垂直分隔线
        Divider()
          .vertical(true)
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3)
          .height(48)
        
        Button('确定')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Medium)
          .borderRadius(0)
          .enabled(this.inputValue.trim().length > 0)
          .opacity(this.inputValue.trim().length > 0 ? 1 : 0.4)
          .onClick(() => {
            if (this.inputValue.trim().length > 0) {
              this.onConfirm(this.inputValue.trim());
              this.controller.close();
            }
          })
      }
      .width('100%')
    }
    .width('85%')
    .constraintSize({ maxWidth: 300 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14)
    .shadow({ 
      radius: 24, 
      color: 'rgba(0, 0, 0, 0.12)', 
      offsetX: 0, 
      offsetY: 4 
    })
  }
}

@CustomDialog
struct EditNoteDialog {
  controller: CustomDialogController;
  projectNote: string = '';
  onConfirm: (newNote: string) => void = () => {};
  @State inputValue: string = '';

  aboutToAppear() {
    this.inputValue = this.projectNote;
  }

  build() {
    Column({ space: 0 }) {
      // 标题区域
      Column({ space: 4 }) {
        Text('编辑项目备注')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .padding({ top: 24, left: 24, right: 24, bottom: 16 })
      
      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)
      
      // 内容区域
      Column({ space: 8 }) {
        TextArea({ text: this.inputValue, placeholder: '请输入项目备注（可选）' })
          .width('100%')
          .height(100)
          .fontSize(16)
          .backgroundColor(ColorResource.surface)
          .borderRadius(10)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onChange((value: string) => {
            this.inputValue = value;
          })
      }
      .width('100%')
      .padding({ top: 16, left: 24, right: 24, bottom: 20 })
      
      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)
      
      // 按钮区域
      Row({ space: 0 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .borderRadius(0)
          .onClick(() => {
            this.controller.close();
          })
        
        // 垂直分隔线
        Divider()
          .vertical(true)
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3)
          .height(48)
        
        Button('确定')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Medium)
          .borderRadius(0)
          .onClick(() => {
            this.onConfirm(this.inputValue.trim());
            this.controller.close();
          })
      }
      .width('100%')
    }
    .width('85%')
    .constraintSize({ maxWidth: 320 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14)
    .shadow({ 
      radius: 24, 
      color: 'rgba(0, 0, 0, 0.12)', 
      offsetX: 0, 
      offsetY: 4 
    })
  }
}

@CustomDialog
struct AIGenerateDialog {
  controller: CustomDialogController;
  apiKey: string = '';
  baseUrl: string = 'https://api.deepseek.com';
  onConfirm: (apiKey: string, baseUrl: string, prompt: string) => void = () => {};
  @State inputApiKey: string = '';
  @State inputBaseUrl: string = '';
  @State inputPrompt: string = '';

  aboutToAppear() {
    this.inputApiKey = this.apiKey;
    this.inputBaseUrl = this.baseUrl;
  }

  build() {
    Column({ space: 0 }) {
      // 标题区域
      Column({ space: 4 }) {
        Text('AI 生成导图')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .textAlign(TextAlign.Center)
          .width('100%')
        Text('使用你自己的 AI Key 生成项目导图')
          .fontSize(12)
          .fontColor(ColorResource.textSecondary)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .padding({ top: 24, left: 24, right: 24, bottom: 16 })

      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)

      // 内容区域
      Column({ space: 12 }) {
        // API Key
        Column({ space: 6 }) {
          Text('API Key（必填）')
            .fontSize(12)
            .fontColor(ColorResource.textSecondary)
          TextInput({ text: this.inputApiKey, placeholder: '请输入 AI API Key（例如 DeepSeek Key）' })
            .width('100%')
            .height(44)
            .fontSize(16)
            .backgroundColor(ColorResource.surface)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              this.inputApiKey = value;
            })
        }

        // Base URL
        Column({ space: 6 }) {
          Text('Base URL（可选）')
            .fontSize(12)
            .fontColor(ColorResource.textSecondary)
          TextInput({ text: this.inputBaseUrl, placeholder: '默认为 https://api.deepseek.com' })
            .width('100%')
            .height(44)
            .fontSize(14)
            .backgroundColor(ColorResource.surface)
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              this.inputBaseUrl = value;
            })
        }

        // Prompt 描述
        Column({ space: 6 }) {
          Text('导图描述（必填）')
            .fontSize(12)
            .fontColor(ColorResource.textSecondary)
          TextInput({ text: this.inputPrompt, placeholder: '请描述你要生成的项目/思维导图，例如：开发一款待办应用的完整项目计划' })
            .width('100%')
            .height(80)
            .fontSize(14)
            .backgroundColor(ColorResource.surface)
            .borderRadius(10)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onChange((value: string) => {
              this.inputPrompt = value;
            })
        }
      }
      .width('100%')
      .padding({ top: 16, left: 24, right: 24, bottom: 20 })

      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)

      // 按钮区域
      Row({ space: 0 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .borderRadius(0)
          .onClick(() => {
            this.controller.close();
          })

        // 垂直分隔线
        Divider()
          .vertical(true)
          .strokeWidth(0.5)
          .color(ColorResource.surfaceEmphasized)
          .opacity(0.3)
          .height(48)

        Button('生成导图')
          .layoutWeight(1)
          .height(48)
          .fontSize(17)
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor(ColorResource.primaryColor)
          .fontWeight(FontWeight.Medium)
          .borderRadius(0)
          .enabled(this.inputApiKey.trim().length > 0 && this.inputPrompt.trim().length > 0)
          .opacity(this.inputApiKey.trim().length > 0 && this.inputPrompt.trim().length > 0 ? 1 : 0.4)
          .onClick(() => {
            const key = this.inputApiKey.trim();
            const base =
              this.inputBaseUrl.trim().length > 0
                ? this.inputBaseUrl.trim()
                : this.baseUrl;
            const prompt = this.inputPrompt.trim();
            if (key.length > 0 && prompt.length > 0) {
              this.onConfirm(key, base, prompt);
              this.controller.close();
            }
          })
      }
      .width('100%')
    }
    .width('85%')
    .constraintSize({ maxWidth: 320 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(14)
    .shadow({
      radius: 24,
      color: 'rgba(0, 0, 0, 0.12)',
      offsetX: 0,
      offsetY: 4
    })
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
  @State canvasOpacity: number = 1; // 画布透明度（用于平滑过渡）

  // 主题相关状态
  private configCallbackId: number = -1;
  @State isDarkMode: boolean = false;

  // 响应式布局相关状态
  @State screenWidth: number = 0;
  @State currentBreakpoint: BreakpointConfig = BreakpointSystem.getCurrentBreakpoint(0);
  @State isPhone: boolean = false;
  @State isTablet: boolean = false;
  
  // 手机端视图模式
  @State phoneViewMode: 'welcome' | 'list' | 'detail' = 'welcome'; // welcome=欢迎页, list=项目列表, detail=项目详情
  @State swipeOffset: number = 0; // 滑动偏移量
  @State showDashboardCard: boolean = false; // 是否显示Dashboard卡片
  @State arrowAnimationOffset: number = 0; // 箭头动画偏移量
  @State pageTranslateY: number = 0; // 页面Y轴偏移（用于滑动动画）
  @State pageOpacity: number = 1; // 页面透明度
  
  // 重命名对话框
  private renameDialogController: CustomDialogController | null = null;
  @State renameProjectId: string = '';
  @State renameProjectName: string = '';
  @State selectedTaskForDetail: TaskNode | null = null;
  
  // 备注编辑对话框
  private editNoteDialogController: CustomDialogController | null = null;
  @State editNoteProjectId: string = '';
  @State editNoteProjectNote: string = '';
  
  // 画布渲染模式（手机端默认使用缩略模式）
  @State canvasRenderMode: RenderMode = RenderMode.NORMAL;

  // AI相关
  @State aiApiKey: string = '';
  @State aiBaseUrl: string = 'https://api.deepseek.com';


  private storageService: StorageService | null = null;
  private loadingService: LoadingService = LoadingService.getInstance();
  private templateService: TemplateService = TemplateService.getInstance();
  private permissionService: PermissionService | null = null;
  private migrationService: DataMigrationService | null = null;
  private importService: ImportService | null = null;
  private errorHandler: ErrorHandler | null = null;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private aiService: AIService = AIService.getInstance();


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
    
    // 初始化导入服务
    this.importService = ImportService.getInstance(this.storageService);

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
    
    // 先同步获取屏幕宽度并设置 isPhone（确保渲染模式正确）
    const windowStage = (this.uiContext.getHostContext() as common.UIAbilityContext)?.windowStage;
    if (windowStage) {
      try {
        const window = await windowStage.getMainWindow();
        const properties = window.getWindowProperties();
        const widthPx = properties.windowRect.width;
        this.screenWidth = this.uiContext.px2vp(widthPx);
        this.isPhone = BreakpointSystem.isPhone(this.screenWidth);
        console.log(`[Home] Initial screen size: ${this.screenWidth}vp, isPhone: ${this.isPhone}`);
      } catch (error) {
        console.error('[Home] Failed to get initial window size:', error);
        this.screenWidth = 840;
        this.isPhone = false;
      }
    } else {
      this.screenWidth = 840;
      this.isPhone = false;
    }
    
    // 根据屏幕尺寸设置初始渲染模式
    this.canvasRenderMode = this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL;
    this.canvasController.setRenderMode(this.canvasRenderMode);
    console.log(`[Home] Initial canvas render mode: ${this.canvasRenderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);

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
    // 如果有选中的项目，静默刷新其数据（不触发动画，避免闪烁）
    if (this.selectedProjectId) {
      console.log(`[Home] onPageShow - 静默刷新项目 ${this.selectedProjectId}`);
      this.silentRefreshProject(this.selectedProjectId);
    }
    // 重新检测屏幕尺寸（可能发生旋转）
    this.updateScreenSize();
  }

  private aiDialogController: CustomDialogController | null = null;

  private showAIGenerateDialog() {
    if (this.aiDialogController) {
      this.aiDialogController.close();
      this.aiDialogController = null;
    }

    this.aiDialogController = new CustomDialogController({
      builder: AIGenerateDialog({
        apiKey: this.aiApiKey,
        baseUrl: this.aiBaseUrl,
        onConfirm: async (apiKey: string, baseUrl: string, prompt: string) => {
          this.aiApiKey = apiKey.trim();
          this.aiBaseUrl = baseUrl.trim().length > 0 ? baseUrl.trim() : 'https://api.deepseek.com';
          await this.createProjectWithAI(prompt);
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.aiDialogController.open();
  }

  private async createProjectWithAI(prompt: string) {
    if (!this.storageService) {
      this.promptAction.showToast({ message: '存储服务未初始化' });
      return;
    }
    if (!prompt || prompt.trim().length === 0) {
      this.promptAction.showToast({ message: '请先输入你想生成的项目描述' });
      return;
    }

    this.aiService.setConfig(this.aiApiKey, this.aiBaseUrl);

    this.promptAction.showToast({ message: '正在调用 AI 生成导图...', duration: 1500 });

    const project = await this.aiService.generateProjectFromPrompt(prompt);
    if (!project) {
      this.promptAction.showToast({ message: 'AI 生成失败，请检查 API Key / BaseURL 后重试', duration: 3000 });
      return;
    }

    await this.storageService.saveProject(project);
    this.promptAction.showToast({ message: `项目 "${project.name}" 已创建`, duration: 2000 });

    await this.loadProjects();
    this.selectedProjectId = project.id;
    this.selectedProjectDetail = project;

    setTimeout(() => {
      this.uiContext.getRouter().pushUrl({
        url: 'pages/Index',
        params: { projectId: project.id }
      });
    }, 500);
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

  private showOmissionReminderIfNeeded(project: Project) {
    if (!project || !project.tasks || project.tasks.length === 0) {
      return;
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);

    let noChecklistCount = 0;
    let dueTodayWithoutChecklistCount = 0;

    project.tasks.forEach(task => {
      const noChecklist = !task.checklist || task.checklist.length === 0;
      if (noChecklist) {
        noChecklistCount++;
        if (task.endDate >= today && task.endDate < tomorrow) {
          dueTodayWithoutChecklistCount++;
        }
      }
    });

    if (noChecklistCount === 0 && dueTodayWithoutChecklistCount === 0) {
      return;
    }

    let message = '';
    if (noChecklistCount > 0) {
      message += `还有 ${noChecklistCount} 个任务没有拆解`;
    }
    if (dueTodayWithoutChecklistCount > 0) {
      if (message.length > 0) message += '，';
      message += `其中 ${dueTodayWithoutChecklistCount} 个今天到期`;
    }
    message += '，建议补充检查项，避免遗漏。';

    this.promptAction.showToast({
      message,
      duration: 4000
    });
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

  // 静默刷新项目数据（用于从编辑页返回，避免闪烁）
  async silentRefreshProject(projectId: string) {
    if (!this.storageService) return;
    
    try {
      console.log(`[Home] Silently refreshing project: ${projectId}`);
      
      // 短暂降低画布透明度（准备更新）
      this.canvasOpacity = 0.7;
      
      // 重新加载项目数据
      const loadedProject = await this.storageService.getProject(projectId);
      
      if (loadedProject) {
        // 静默更新项目数据（不清空，不触发动画）
        this.selectedProjectDetail = loadedProject;
        // 强制刷新 Dashboard 组件（key 变化会重建）
        this.dashboardKey++;
        this.dashboardTimestamp = Date.now();
        // 在这里调用提醒
        this.showOmissionReminderIfNeeded(loadedProject);


        console.log(`[Home] Project data silently updated: ${loadedProject.name}, Canvas state - Zoom: ${loadedProject.zoomScale}, Offset: (${loadedProject.canvasOffsetX}, ${loadedProject.canvasOffsetY})`);
        
        // 立即重新渲染画布
        this.renderProjectCanvas();
        
        // 延迟50ms后恢复透明度，让渲染完成
        setTimeout(() => {
          this.canvasOpacity = 1;
        }, 50);
      } else {
        console.error(`[Home] Project not found during silent refresh: ${projectId}`);
        this.canvasOpacity = 1; // 恢复透明度
      }
    } catch (error) {
      console.error(`[Home] Error during silent refresh:`, error);
      this.canvasOpacity = 1; // 恢复透明度
    }
  }

  async onSelectProject(projectId: string, forceReload: boolean = false) {
    if (this.storageService) {
      console.log(`[Home] Selecting project: ${projectId}, forceReload: ${forceReload}`);
      
      // 如果正在切换中，忽略新的选择请求
      if (this.isTransitioning) {
        console.log(`[Home] Already transitioning, ignoring project selection: ${projectId}`);
        return;
      }
      
      // 如果是同一个项目且不强制刷新，不需要重新加载
      if (!forceReload && this.selectedProjectId === projectId && this.selectedProjectDetail) {
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
              // 清除渲染缓存，确保强制重新渲染
              this.canvasController.getRenderer().clearRenderCache();
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
            
            // 设置新创建的项目为选中状态并启用画布背景
            this.selectedProjectId = newProject.id;
            this.selectedProjectDetail = newProject;
            this.showCanvasBackground = true;
            console.log(`[Home] 设置选中项目: ${newProject.id}, 已启用画布背景`);
            
            // 延迟渲染画布以确保组件已更新
            setTimeout(() => {
              this.canvasController.getRenderer().clearRenderCache();
              this.renderProjectCanvas();
            }, 100);
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
        },
        {
          text: '导入项目',
          color: ColorResource.projectDevelopment
        }
      ]
    }).then((result) => {
      if (result.index === 0) {
        // 空白项目
        this.showBlankProjectDialog();
      } else if (result.index === 1) {
        // 选择模板
        this.showTemplateSelectionDialog();
      } else if (result.index === 2) {
        // 导入项目
        this.importProject();
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
        },
        {
          text: '研究模板',
          color: ColorResource.projectResearch
        },
        {
          text: '内容模板',
          color: ColorResource.projectContent
        },
        {
          text: '活动模板',
          color: ColorResource.projectEvent
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
      } else if (result.index === 3) {
        // 研究模板
        this.selectedCategory = 'research';
        this.showTemplateListDialog();
      } else if (result.index === 4) {
        // 内容模板
        this.selectedCategory = 'content';
        this.showTemplateListDialog();
      } else if (result.index === 5) {
        // 活动模板
        this.selectedCategory = 'event';
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
      
      // 设置新创建的项目为选中状态并启用画布背景
      this.selectedProjectId = newProject.id;
      this.selectedProjectDetail = newProject;
      this.showCanvasBackground = true;
      console.log(`[Home] 设置选中项目: ${newProject.id}, 已启用画布背景`);
      
      // 延迟渲染画布以确保组件已更新
      setTimeout(() => {
        this.canvasController.getRenderer().clearRenderCache();
        this.renderProjectCanvas();
      }, 100);

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
            
            // 设置新创建的项目为选中状态并启用画布背景
            this.selectedProjectId = newProject.id;
            this.selectedProjectDetail = newProject;
            this.showCanvasBackground = true;
            console.log(`[Home] 设置选中项目: ${newProject.id}, 已启用画布背景`);
            
            // 延迟渲染画布以确保组件已更新
            setTimeout(() => {
              this.canvasController.getRenderer().clearRenderCache();
              this.renderProjectCanvas();
            }, 100);
            
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

  // 导入项目
  async importProject() {
    if (!this.importService) {
      this.handleError(new Error("导入服务未初始化"), "importProject");
      return;
    }

    try {
      console.log('[Home] 开始导入项目...');

      // 显示导入进度提示
      this.promptAction.showToast({
        message: '正在选择文件...',
        duration: 1000
      });

      // 执行导入
      const result = await this.importService.importProject();

      if (result.success && result.project) {
        console.log(`[Home] 项目导入成功: ${result.project.id}`);

        // 显示成功提示
        let message = `项目 "${result.project.name}" 导入成功！`;
        if (result.warnings && result.warnings.length > 0) {
          message += `\n${result.warnings.join('\n')}`;
        }
        this.promptAction.showToast({
          message: message,
          duration: 3000
        });

        // 刷新项目列表
        console.log('[Home] 开始刷新项目列表...');
        await this.loadProjects();
        console.log(`[Home] 项目列表刷新完成，当前项目数量: ${this.projectList.length}`);

        // 设置新导入的项目为选中状态
        this.selectedProjectId = result.project.id;
        this.selectedProjectDetail = result.project;
        console.log(`[Home] 设置选中项目: ${result.project.id}`);

        // 延迟导航到编辑页面
        setTimeout(() => {
          if (result.project) {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/Index',
              params: { projectId: result.project.id },
              animation: {
                type: 'fade',
                duration: 300
              }
            } as router.RouterOptions);
          }
        }, 500);
      } else {
        // 导入失败或取消
        if (result.error) {
          console.error('[Home] 项目导入失败:', result.error);
          this.promptAction.showToast({
            message: result.error,
            duration: 3000
          });
        } else {
          console.log('[Home] 用户取消了导入操作');
        }
      }
    } catch (error) {
      console.error('[Home] 导入项目失败:', error);
      this.promptAction.showToast({
        message: '导入项目失败，请重试',
        duration: 2000
      });
      this.handleError(error as Error, "importProject");
    }
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
                  Row({ space: ThemeConfig.spacingXS }) {
                    Text(meta.name)
                      .fontSize(ThemeConfig.fontSizeM)
                      .fontWeight(ThemeConfig.fontWeightBold)
                      .fontColor(ColorResource.surfaceDeep)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                      .lineHeight(ThemeConfig.fontSizeM * 1.4)
                      .onAppear(() => {
                        console.log(`[Home-Tablet] Project: ${meta.name}, Note: "${meta.note || 'undefined'}", Has note: ${!!(meta.note && meta.note.length > 0)}`);
                      })
                    
                    if (meta.note && meta.note.length > 0) {
                      Text(meta.note)
                        .fontSize(ThemeConfig.fontSizeXS)
                        .fontColor(ColorResource.primaryColor)
                        .fontWeight(ThemeConfig.fontWeightMedium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .padding({ 
                          left: ThemeConfig.spacingS, 
                          right: ThemeConfig.spacingS,
                          top: 2,
                          bottom: 2
                        })
                        .backgroundColor(ColorResource.primaryUltraLight)
                        .borderRadius(ThemeConfig.radiusMedium)
                        .border({ 
                          width: 1, 
                          color: ColorResource.primaryLight 
                        })
                        .constraintSize({ maxWidth: 150 })
                        .opacity(0.9)
                    }
                  }
                  .width('100%')
                  
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
        .backgroundColor(ColorResource.transparent)
        .backdropBlur(ThemeConfig.backdropBlurXLarge)
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
      .opacity(this.canvasOpacity) // 平滑过渡透明度
      .animation({
        duration: 150,
        curve: Curve.EaseInOut
      })
      .onReady(() => {
        if (this.selectedProjectDetail) {
          // 清除渲染缓存，确保Canvas准备好时强制重新渲染
          this.canvasController.getRenderer().clearRenderCache();
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
          null, // Home页面不需要选中任务高亮
          0     // Home页面画布全屏，无需X轴偏移
        );
        
        // 重新渲染画布
        this.renderProjectCanvas();
      })
  }

  // 渲染项目画布（使用项目保存的画布状态）
  private renderProjectCanvas() {
    if (!this.selectedProjectDetail) return;
    
    const renderer = this.canvasController.getRenderer();
    renderer.setDarkMode(this.isDarkMode);
    
    // 使用当前的渲染模式（手机端为缩略模式，和编辑页保持一致）
    renderer.render(this.selectedProjectDetail, {
      canvasOffsetX: this.selectedProjectDetail.canvasOffsetX || 0,
      canvasOffsetY: this.selectedProjectDetail.canvasOffsetY || 0,
      zoomScale: this.selectedProjectDetail.zoomScale || 1.0,
      isConnecting: false,
      connectingFromTaskId: null,
      selectedTaskId: null,
      renderMode: this.canvasRenderMode
    });
    
    console.log(`[Home] Canvas rendered - Zoom: ${this.selectedProjectDetail.zoomScale || 1.0}, Offset: (${this.selectedProjectDetail.canvasOffsetX || 0}, ${this.selectedProjectDetail.canvasOffsetY || 0}), Mode: ${this.canvasRenderMode === RenderMode.COMPACT ? 'COMPACT' : 'NORMAL'}`);
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
      }
      // 不再需要 onTaskClick 回调，因为取消了节点详情对话框
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
          text: '编辑备注',
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
        // 编辑备注
        this.showEditNoteDialog(projectId);
      } else if (data.index === 2) {
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

  // 显示备注编辑对话框
  private showEditNoteDialog(projectId: string) {
    const project = this.projectList.find(p => p.id === projectId);
    if (!project) return;

    // 先关闭之前的对话框（如果存在）
    if (this.editNoteDialogController) {
      this.editNoteDialogController.close();
      this.editNoteDialogController = null;
    }

    this.editNoteProjectId = projectId;
    this.editNoteProjectNote = project.note || '';

    // 创建并打开对话框
    this.editNoteDialogController = new CustomDialogController({
      builder: EditNoteDialog({
        projectNote: this.editNoteProjectNote,
        onConfirm: (newNote: string) => {
          this.handleEditNote(this.editNoteProjectId, newNote);
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.editNoteDialogController.open();
  }

  // 处理备注编辑
  private async handleEditNote(projectId: string, newNote: string) {
    try {
      if (!this.storageService) return;

      console.log(`[Home] handleEditNote called: projectId=${projectId}, newNote="${newNote}"`);

      // 获取完整的项目数据
      const project = await this.storageService.getProject(projectId);
      if (!project) {
        this.promptAction.showToast({
          message: '项目不存在',
          duration: 2000
        });
        return;
      }

      console.log(`[Home] Project loaded: ${project.name}, current note: ${project.note || 'undefined'}`);

      // 更新项目备注和时间戳
      project.note = newNote.length > 0 ? newNote : undefined;
      project.lastModified = Date.now();

      console.log(`[Home] Updated project note to: ${project.note || 'undefined'}`);

      // 保存到存储
      await this.storageService.saveProject(project);

      console.log(`[Home] Project saved to storage`);

      // 更新本地项目列表 - 创建新数组引用以触发响应式更新
      const projectIndex = this.projectList.findIndex(p => p.id === projectId);
      if (projectIndex !== -1) {
        // 创建新的项目元数据对象（手动复制属性）
        const oldMeta = this.projectList[projectIndex];
        const updatedMeta: ProjectMeta = {
          id: oldMeta.id,
          name: oldMeta.name,
          category: oldMeta.category,
          note: project.note,
          lastModified: Date.now()
        };
        
        // 创建新数组并替换元素，触发响应式更新
        const newList: ProjectMeta[] = [];
        for (let i = 0; i < this.projectList.length; i++) {
          if (i === projectIndex) {
            newList.push(updatedMeta);
          } else {
            newList.push(this.projectList[i]);
          }
        }
        this.projectList = newList;
        
        console.log(`[Home] Updated projectList[${projectIndex}].note to: ${updatedMeta.note || 'undefined'}`);
      } else {
        console.error(`[Home] Project not found in projectList: ${projectId}`);
      }

      // 如果是当前选中的项目，也更新详情数据
      if (this.selectedProjectDetail && this.selectedProjectDetail.id === projectId) {
        this.selectedProjectDetail.note = project.note;
        this.selectedProjectDetail.lastModified = Date.now();
      }

      // 显示成功提示
      this.promptAction.showToast({
        message: newNote.length > 0 ? '备注已更新' : '备注已清除',
        duration: 2000
      });

      // 强制刷新UI
      this.componentKey++;
    } catch (error) {
      console.error('[Home] Edit note error:', error);
      this.promptAction.showToast({
        message: '备注编辑失败，请重试',
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
        .shadow({ 
          radius: 8, 
          color: this.isDarkMode ? ColorResource.shadowColorRegular : ColorResource.shadowColorFaint, 
          offsetY: 2 
        })
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
                  Row({ space: ThemeConfig.spacingXS }) {
                    Text(meta.name)
                      .fontSize(ThemeConfig.fontSizeM)
                      .fontWeight(ThemeConfig.fontWeightBold)
                      .fontColor(ColorResource.surfaceDeep)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                      .lineHeight(ThemeConfig.fontSizeM * 1.4)
                    
                    if (meta.note && meta.note.length > 0) {
                      Text(meta.note)
                        .fontSize(ThemeConfig.fontSizeXS)
                        .fontColor(ColorResource.primaryColor)
                        .fontWeight(ThemeConfig.fontWeightMedium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .padding({ 
                          left: ThemeConfig.spacingS, 
                          right: ThemeConfig.spacingS,
                          top: 2,
                          bottom: 2
                        })
                        .backgroundColor(ColorResource.primaryUltraLight)
                        .borderRadius(ThemeConfig.radiusMedium)
                        .border({ 
                          width: 1, 
                          color: ColorResource.primaryLight 
                        })
                        .constraintSize({ maxWidth: 150 })
                        .opacity(0.9)
                    }
                  }
                  .width('100%')
                  
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
              
              // 选中项目并预加载Canvas
              this.onSelectProject(meta.id);
              
              // 等待项目数据加载完成（缩短延迟）
              setTimeout(() => {
                // 预渲染Canvas（透明状态，用户看不到）
                if (this.selectedProjectDetail) {
                  this.canvasController.getRenderer().clearRenderCache();
                  this.renderProjectCanvas();
                }
                
                // Canvas预渲染完成后立即显示背景和卡片（减少延迟）
                setTimeout(() => {
                  this.showCanvasBackground = true;
                  this.showDashboardCard = true;
                }, 50);
              }, 150);
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
      // 全屏画布背景层（始终存在，通过透明度控制显示，预加载避免闪烁）
      Canvas(this.canvasController.getRenderer().getContext())
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .opacity(this.showCanvasBackground && this.selectedProjectDetail ? 1 : 0)
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })
        .onReady(() => {
          // Canvas准备就绪后立即渲染（如果有选中的项目），不延迟避免闪烁
          if (this.selectedProjectDetail) {
            this.canvasController.getRenderer().clearRenderCache();
            this.renderProjectCanvas();
          }
        })
        .onTouch((event: TouchEvent) => {
          // 处理画布触摸事件
          if (!this.selectedProjectDetail || !this.showCanvasBackground) {
            return;
          }

          this.canvasController.getActions().handleTouch(
            event,
            this.selectedProjectDetail,
            null, // Home页面不需要选中任务高亮
            0     // 手机端Dashboard画布全屏，无需X轴偏移
          );
          
          // 重新渲染画布
          this.renderProjectCanvas();
        })
      
      // 透明遮罩层（点击关闭，不影响Canvas显示）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 点击空白区域关闭Dashboard卡片
          this.showDashboardCard = false;
          this.showCanvasBackground = false;
        })
      
      // Dashboard内容卡片
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
          .backgroundColor(ResponsiveColorConfig.getCardBackgroundColor(true, this.isDarkMode, this.screenWidth))
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
            Image($r('app.media.ic_edit'))
              .width(18)
              .height(18)
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
              showCanvasBackground: true,
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
      .width('90%')
      .height('75%')
      .backgroundColor(ResponsiveColorConfig.getOverlayColor(this.isDarkMode, 0.3))
      .backdropBlur(20)
      .borderRadius(ThemeConfig.radiusXLarge)
      .shadow({ 
        radius: 40, 
        color: this.isDarkMode ? ColorResource.shadowColorStrong : ColorResource.shadowColorFaint, 
        offsetX: 0, 
        offsetY: 8 
      })
      .border({
        width: 1.5,
        color: ResponsiveColorConfig.getCardBorderColor(true, this.isDarkMode, this.screenWidth),
        radius: ThemeConfig.radiusXLarge
      })
      .clip(true)
      .scale({ x: this.contentScale, y: this.contentScale })
      .opacity(this.contentOpacity)
      .hitTestBehavior(HitTestMode.Default) // Dashboard内容层正常处理触摸事件
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
