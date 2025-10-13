// File: entry/src/main/ets/pages/ProjectGroupHome.ets
/**
 * 项目集首页模块（Program Management Home）
 * 
 * 本页面是项目集管理的入口页面，完全复用 Home.ets 的设计模式。
 * 采用左右分栏布局：左侧为项目集列表，右侧为项目集仪表板或欢迎界面。
 * 
 * 术语说明：
 * - Program（项目集）：多个相关项目的协同管理，以实现共同战略目标
 * - Project（项目）：单个项目的管理
 * 
 * 主要功能：
 * 1. 项目集列表：显示所有项目集的概览信息
 * 2. 项目集仪表板：展示关键绩效指标（KPI）和健康状态
 * 3. 项目集创建：支持创建新项目集
 * 4. 项目集操作：编辑、删除、导入导出项目集
 * 5. 响应式设计：支持不同屏幕尺寸的自适应显示
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-01
 */

import { StorageService, ProjectGroupMeta } from '../services/StorageService';
import { ProjectGroup, ProjectRef } from '../model/ProjectGroup';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import common from '@ohos.app.ability.common';
import { PromptAction } from '@kit.ArkUI';
import router from '@ohos.router';
import { BreakpointSystem } from '../utils/BreakpointSystem';

/**
 * 重命名项目集对话框
 */
@CustomDialog
struct RenameProgramDialog {
  controller: CustomDialogController;
  programName: string = '';
  onConfirm: (newName: string) => void = () => {};
  @State inputValue: string = '';

  aboutToAppear() {
    this.inputValue = this.programName;
  }

  build() {
    Column({ space: 0 }) {
      Column({ space: 4 }) {
        Text('编辑项目集名称')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorResource.textPrimary)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .padding({ top: 24, left: 24, right: 24, bottom: 16 })
      
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)
      
      Column({ space: 8 }) {
        TextInput({ text: this.inputValue, placeholder: '请输入项目集名称' })
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
      
      Divider()
        .strokeWidth(0.5)
        .color(ColorResource.surfaceEmphasized)
        .opacity(0.3)
      
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
            if (this.inputValue.trim()) {
              this.onConfirm(this.inputValue.trim());
              this.controller.close();
            }
          })
      }
      .width('100%')
    }
    .backgroundColor(ColorResource.surface)
    .borderRadius(16)
  }
}

/**
 * 项目集首页主组件
 */
@Entry
@Component
struct ProjectGroupHome {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;

  @State programList: ProjectGroupMeta[] = [];
  @State selectedProgramId: string = '';
  @State selectedProgramDetail: ProjectGroup | null = null;
  @State isLoading: boolean = false;
  
  // 内容区动画状态（复用 Home.ets 的动画）
  @State contentOpacity: number = 0;
  @State contentScale: number = 0.95;
  @State contentTranslateY: number = 20;
  
  // 响应式布局
  @State screenWidth: number = 0;
  @State isPhone: boolean = false;
  
  private storageService: StorageService | null = null;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  
  // 重命名对话框控制器
  private renameDialogController: CustomDialogController | null = null;

  async aboutToAppear() {
    console.log('[ProjectGroupHome] aboutToAppear');
    
    // 初始化屏幕尺寸
    this.updateScreenSize();
    
    // 初始化存储服务
    this.storageService = StorageService.getInstance(
      (this.uiContext.getHostContext() as common.UIAbilityContext).filesDir
    );
    
    // 加载项目集列表
    await this.loadProgramList();
    
    // 启动进入动画
    setTimeout(() => {
      this.contentOpacity = 1;
      this.contentScale = 1;
      this.contentTranslateY = 0;
    }, 100);
  }

  private updateScreenSize(): void {
    try {
      this.screenWidth = 840;
      this.isPhone = false;
    } catch (error) {
      console.error('[ProjectGroupHome] Error getting screen size:', error);
      this.screenWidth = 840;
      this.isPhone = false;
    }
  }

  private async loadProgramList(): Promise<void> {
    if (!this.storageService) return;
    
    this.isLoading = true;
    try {
      this.programList = await this.storageService.getProjectGroupList();
      console.log(`[ProjectGroupHome] Loaded ${this.programList.length} programs`);
    } catch (error) {
      console.error('[ProjectGroupHome] Failed to load program list:', error);
      this.promptAction.showToast({ message: '加载项目集列表失败' });
    } finally {
      this.isLoading = false;
    }
  }

  private async handleSelectProgram(programId: string): Promise<void> {
    this.selectedProgramId = programId;
    
    if (!this.storageService) return;
    
    try {
      const program = await this.storageService.getProjectGroup(programId);
      this.selectedProgramDetail = program;
    } catch (error) {
      console.error('[ProjectGroupHome] Failed to load program detail:', error);
      this.promptAction.showToast({ message: '加载项目集详情失败' });
    }
  }

  private async handleCreateProgram(): Promise<void> {
    this.uiContext.getRouter().pushUrl({
      url: 'pages/ProjectGroupIndex'
    } as router.RouterOptions);
  }

  private handleOpenProgram(programId: string): void {
    this.uiContext.getRouter().pushUrl({
      url: 'pages/ProjectGroupIndex',
      params: { groupId: programId }
    } as router.RouterOptions);
  }

  private async handleDeleteProgram(program: ProjectGroupMeta): Promise<void> {
    this.uiContext.showAlertDialog({
      title: '确认删除',
      message: `确定要删除项目集 "${program.name}" 吗？此操作不可恢复！`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: ColorResource.errorColor,
        action: async () => {
          if (!this.storageService) return;
          
          try {
            await this.storageService.deleteProjectGroup(program.id);
            await this.loadProgramList();
            this.promptAction.showToast({ message: '项目集已删除' });
            
            if (this.selectedProgramId === program.id) {
              this.selectedProgramId = '';
              this.selectedProgramDetail = null;
            }
          } catch (error) {
            console.error('[ProjectGroupHome] Failed to delete program:', error);
            this.promptAction.showToast({ message: '删除项目集失败' });
          }
        }
      }
    });
  }

  private handleRenameProgram(program: ProjectGroupMeta): void {
    this.renameDialogController = new CustomDialogController({
      builder: RenameProgramDialog({
        programName: program.name,
        onConfirm: async (newName: string) => {
          if (!this.storageService) return;
          
          try {
            const projectGroup = await this.storageService.getProjectGroup(program.id);
            if (projectGroup) {
              projectGroup.name = newName;
              await this.storageService.saveProjectGroup(projectGroup);
              await this.loadProgramList();
              
              if (this.selectedProgramId === program.id) {
                this.selectedProgramDetail = projectGroup;
              }
              
              this.promptAction.showToast({ message: '项目集已重命名' });
            }
          } catch (error) {
            console.error('[ProjectGroupHome] Failed to rename program:', error);
            this.promptAction.showToast({ message: '重命名失败' });
          }
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.renameDialogController.open();
  }

  private handleBackToHome(): void {
    this.uiContext.getRouter().back();
  }

  build() {
    Row() {
      // 左侧：项目集列表（复用 Home.ets 的设计，layoutWeight=1）
      Column() {
        this.Sidebar()
      }
      .layoutWeight(1)
      
      // 右侧：项目集仪表板或欢迎界面（复用 Home.ets 的设计，layoutWeight=2）
      Column() {
        this.ContentArea()
      }
      .layoutWeight(2)
      .margin({ left: ThemeConfig.spacingS })
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight)
    })
  }

  // 左侧边栏（项目集列表）
  @Builder
  Sidebar() {
    Column({ space: 0 }) {
      // 顶部标题
      Row({ space: ThemeConfig.spacingM }) {
        Button() {
          Text('←')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontColor(ColorResource.primaryColor)
        }
        .width(40)
        .height(40)
        .type(ButtonType.Circle)
        .backgroundColor(ColorResource.surface)
        .onClick(() => this.handleBackToHome())

        Text('项目集')
          .fontSize(ThemeConfig.fontSizeXXXL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.textPrimary)
          .layoutWeight(1)

        Button() {
          Text('+')
            .fontSize(ThemeConfig.fontSizeXXXL)
            .fontColor(Color.White)
        }
        .width(50)
        .height(50)
        .type(ButtonType.Circle)
        .backgroundColor(ColorResource.primaryColor)
        .onClick(() => this.handleCreateProgram())
      }
      .width('100%')
      .padding(ThemeConfig.spacingL)
      .backgroundColor(ColorResource.surface)

      // 项目集列表
      if (this.isLoading) {
        Column({ space: ThemeConfig.spacingXL }) {
          Stack() {
            Circle()
              .width(100)
              .height(100)
              .fill(ColorResource.overlaySubtle)
              .backdropBlur(ThemeConfig.backdropBlurMedium)
              .shadow(ThemeConfig.shadowLarge)
            
            LoadingProgress()
              .width(60)
              .height(60)
              .color(ColorResource.primaryColor)
          }
          .width(100)
          .height(100)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.programList.length === 0) {
        Column({ space: ThemeConfig.spacingL }) {
          Text('📁')
            .fontSize(60)
          
          Text('还没有项目集')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary)
          
          Text('点击右上角 + 按钮创建')
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ColorResource.textSecondary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(ThemeConfig.spacingXL)
      } else {
        List({ space: ThemeConfig.spacingS }) {
          ForEach(this.programList, (program: ProjectGroupMeta) => {
            ListItem() {
              Row({ space: ThemeConfig.spacingM }) {
                Text('📂')
                  .fontSize(ThemeConfig.fontSizeXXL)

                Column({ space: 4 }) {
                  Text(program.name)
                    .fontSize(ThemeConfig.fontSizeM)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                    .fontColor(this.selectedProgramId === program.id 
                      ? ColorResource.primaryColor 
                      : ColorResource.textPrimary)
                  
                  Text(new Date(program.lastModified).toLocaleDateString())
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.textSecondary)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(ThemeConfig.spacingM)
              .backgroundColor(this.selectedProgramId === program.id 
                ? ColorResource.primaryUltraLight 
                : ColorResource.surface)
              .borderRadius(ThemeConfig.radiusMedium)
              .border({
                width: this.selectedProgramId === program.id ? 2 : 0,
                color: ColorResource.primaryColor
              })
              .onClick(() => this.handleSelectProgram(program.id))
              .gesture(
                LongPressGesture()
                  .onAction(() => {
                    this.showProgramContextMenu(program);
                  })
              )
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding(ThemeConfig.spacingM)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
  }

  // 内容区域（复用 Home.ets 的设计）
  @Builder
  ContentArea() {
    Column() {
      if (this.isLoading) {
        // 加载状态（复用 Home.ets 的设计）
        Column({ space: ThemeConfig.spacingXXL }) {
          Stack() {
            Circle()
              .width(120)
              .height(120)
              .fill(ColorResource.overlaySubtle)
              .backdropBlur(ThemeConfig.backdropBlurMedium)
              .shadow(ThemeConfig.shadowLarge)
            
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
      } else if (this.selectedProgramDetail) {
        // 项目集仪表板
        this.ProgramDashboard()
      } else {
        // 欢迎页
        this.WelcomeView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorResource.backgroundSecondary)
    .opacity(this.contentOpacity)
    .scale({ x: this.contentScale, y: this.contentScale })
    .translate({ x: 0, y: this.contentTranslateY })
    .animation({
      duration: ThemeConfig.animationNormal,
      curve: ThemeConfig.animationEaseInOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .borderRadius({ topLeft: ThemeConfig.radiusLarge, bottomLeft: ThemeConfig.radiusLarge })
  }

  // 项目集仪表板（Program Dashboard - 专业设计）
  @Builder
  ProgramDashboard() {
    Scroll() {
      Column({ space: ThemeConfig.spacingXL }) {
        // 标题和快速操作
        Row({ space: ThemeConfig.spacingM }) {
          Column({ space: 4 }) {
            Text(this.selectedProgramDetail?.name || '')
              .fontSize(ThemeConfig.fontSizeXXXL)
              .fontWeight(ThemeConfig.fontWeightBold)
              .fontColor(ColorResource.textPrimary)
            
            Text('项目集概览')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ColorResource.textSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('编辑项目集')
            .height(44)
            .padding({ left: 20, right: 20 })
            .backgroundColor(ColorResource.primaryColor)
            .fontColor(Color.White)
            .borderRadius(ThemeConfig.radiusMedium)
            .onClick(() => {
              if (this.selectedProgramDetail) {
                this.handleOpenProgram(this.selectedProgramDetail.id);
              }
            })
        }
        .width('100%')
        .padding(ThemeConfig.spacingL)

        // 关键指标卡片（2列布局）
        GridRow({ columns: 2, gutter: ThemeConfig.spacingM }) {
          GridCol({ span: 1 }) {
            this.MetricCard('📊', '项目数量', 
              `${this.selectedProgramDetail?.projectRefs.length || 0}`,
              '个项目', ColorResource.primaryColor)
          }
          GridCol({ span: 1 }) {
            this.MetricCard('🔗', '依赖关系', 
              `${this.selectedProgramDetail?.dependencies.length || 0}`,
              '条依赖', ColorResource.infoColor)
          }
        }
        .width('100%')
        .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL })

        // 健康状态评估
        Column({ space: ThemeConfig.spacingM }) {
          Text('整体健康状态')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary)

          Row({ space: ThemeConfig.spacingL }) {
            this.HealthIndicator('进度', this.calculateProgress(), ColorResource.successColor)
            this.HealthIndicator('风险', this.calculateRisk(), ColorResource.warningColor)
            this.HealthIndicator('协同', this.calculateCollaboration(), ColorResource.infoColor)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        }
        .width('100%')
        .padding(ThemeConfig.spacingL)
        .backgroundColor(ColorResource.surface)
        .borderRadius(ThemeConfig.radiusLarge)
        .shadow(ThemeConfig.cardShadow)
        .margin({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL })

        // 项目列表
        Column({ space: ThemeConfig.spacingM }) {
          Text('包含的项目')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary)

          if (this.selectedProgramDetail && this.selectedProgramDetail.projectRefs.length > 0) {
            ForEach(this.selectedProgramDetail.projectRefs, (ref: ProjectRef) => {
              Row({ space: ThemeConfig.spacingM }) {
                Column() {
                  Text('📄')
                    .fontSize(ThemeConfig.fontSizeXXL)
                }
                .width(50)
                .height(50)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(ColorResource.primaryUltraLight)
                .borderRadius(ThemeConfig.radiusMedium)
                
                Column({ space: 4 }) {
                  Text(ref.name)
                    .fontSize(ThemeConfig.fontSizeM)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                    .fontColor(ColorResource.textPrimary)
                  
                  Text(ref.isCritical ? '关键项目' : '常规项目')
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ref.isCritical ? ColorResource.errorColor : ColorResource.textSecondary)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('→')
                  .fontSize(ThemeConfig.fontSizeL)
                  .fontColor(ColorResource.textMuted)
              }
              .width('100%')
              .padding(ThemeConfig.spacingM)
              .backgroundColor(ColorResource.surface)
              .borderRadius(ThemeConfig.radiusMedium)
              .shadow(ThemeConfig.cardShadow)
            })
          } else {
            Column({ space: ThemeConfig.spacingM }) {
              Text('📭')
                .fontSize(60)
              Text('暂无项目')
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ColorResource.textMuted)
            }
            .width('100%')
            .padding(ThemeConfig.spacingXL)
            .backgroundColor(ColorResource.surface)
            .borderRadius(ThemeConfig.radiusMedium)
          }
        }
        .width('100%')
        .padding(ThemeConfig.spacingL)

        // 操作按钮区
        Row({ space: ThemeConfig.spacingM }) {
          Button('重命名')
            .layoutWeight(1)
            .height(50)
            .fontSize(ThemeConfig.fontSizeL)
            .backgroundColor(ColorResource.infoLight)
            .fontColor(ColorResource.infoColor)
            .onClick(() => {
              const program = this.programList.find(p => p.id === this.selectedProgramId);
              if (program) {
                this.handleRenameProgram(program);
              }
            })

          Button('删除')
            .layoutWeight(1)
            .height(50)
            .fontSize(ThemeConfig.fontSizeL)
            .backgroundColor(ColorResource.errorLight)
            .fontColor(ColorResource.errorColor)
            .onClick(() => {
              const program = this.programList.find(p => p.id === this.selectedProgramId);
              if (program) {
                this.handleDeleteProgram(program);
              }
            })
        }
        .width('100%')
        .padding({ left: ThemeConfig.spacingL, right: ThemeConfig.spacingL, bottom: ThemeConfig.spacingL })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .align(Alignment.TopStart)
  }

  // 指标卡片
  @Builder
  MetricCard(icon: string, title: string, value: string, unit: string, color: ResourceColor) {
    Column({ space: ThemeConfig.spacingM }) {
      Row({ space: ThemeConfig.spacingS }) {
        Text(icon)
          .fontSize(ThemeConfig.fontSizeXL)
        
        Text(title)
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ColorResource.textSecondary)
          .layoutWeight(1)
      }
      .width('100%')
      
      Row({ space: 4 }) {
        Text(value)
          .fontSize(40)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(color)
        
        Text(unit)
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.textSecondary)
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .padding(ThemeConfig.spacingL)
    .backgroundColor(ColorResource.surface)
    .borderRadius(ThemeConfig.radiusLarge)
    .shadow(ThemeConfig.cardShadow)
    .alignItems(HorizontalAlign.Start)
  }

  // 健康指标
  @Builder
  HealthIndicator(label: string, percentage: number, color: ResourceColor) {
    Column({ space: ThemeConfig.spacingS }) {
      Text(`${percentage}%`)
        .fontSize(ThemeConfig.fontSizeXXL)
        .fontWeight(ThemeConfig.fontWeightBold)
        .fontColor(color)
      
      Text(label)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary)
      
      Progress({ value: percentage, total: 100, type: ProgressType.Ring })
        .width(60)
        .height(60)
        .color(color)
        .backgroundColor(ColorResource.surfaceLight)
    }
    .alignItems(HorizontalAlign.Center)
  }

  // 欢迎界面
  @Builder
  WelcomeView() {
    Column({ space: ThemeConfig.spacingXXL }) {
      Text('📂')
        .fontSize(100)
      
      Text('欢迎使用项目集管理')
        .fontSize(ThemeConfig.fontSizeXXXL)
        .fontWeight(ThemeConfig.fontWeightBold)
        .fontColor(ColorResource.textPrimary)
      
      Column({ space: ThemeConfig.spacingM }) {
        Text('项目集（Program）是多个相关项目的协同管理')
          .fontSize(ThemeConfig.fontSizeL)
          .fontColor(ColorResource.textSecondary)
          .textAlign(TextAlign.Center)
        
        Text('在左侧选择一个项目集\n或创建新的项目集')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.textMuted)
          .textAlign(TextAlign.Center)
          .lineHeight(ThemeConfig.fontSizeM * 1.5)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(ThemeConfig.spacingXXL)
  }

  // 显示项目集上下文菜单
  private showProgramContextMenu(program: ProjectGroupMeta): void {
    this.uiContext.showAlertDialog({
      title: program.name,
      message: '请选择操作',
      primaryButton: {
        value: '重命名',
        action: () => {
          this.handleRenameProgram(program);
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: ColorResource.errorColor,
        action: () => {
          this.handleDeleteProgram(program);
        }
      }
    });
  }

  // 计算进度（示例算法）
  private calculateProgress(): number {
    if (!this.selectedProgramDetail) return 0;
    const total = this.selectedProgramDetail.projectRefs.length;
    if (total === 0) return 0;
    // 简化算法：假设有关键路径数据的项目为已完成
    const completed = this.selectedProgramDetail.projectRefs.filter(ref => ref.isCritical).length;
    return Math.round((completed / total) * 100);
  }

  // 计算风险（示例算法）
  private calculateRisk(): number {
    if (!this.selectedProgramDetail) return 0;
    const criticalCount = this.selectedProgramDetail.projectRefs.filter(ref => ref.isCritical).length;
    const total = this.selectedProgramDetail.projectRefs.length;
    if (total === 0) return 0;
    // 关键项目越多，风险越高
    return Math.min(100, Math.round((criticalCount / total) * 100));
  }

  // 计算协同度（示例算法）
  private calculateCollaboration(): number {
    if (!this.selectedProgramDetail) return 0;
    const projectCount = this.selectedProgramDetail.projectRefs.length;
    const dependencyCount = this.selectedProgramDetail.dependencies.length;
    if (projectCount === 0) return 0;
    // 依赖关系越多，协同度越高
    const maxDependencies = projectCount * (projectCount - 1);
    if (maxDependencies === 0) return 0;
    return Math.min(100, Math.round((dependencyCount / maxDependencies) * 100 * 10));
  }
}
