// File: entry/src/main/ets/pages/ProjectGroupHome.ets
/**
 * 项目群首页模块
 * 
 * 本页面是项目群管理的入口页面，完全复用 Home.ets 的设计模式。
 * 采用左右分栏布局：左侧为项目群列表，右侧为项目群详情或欢迎界面。
 * 
 * 主要功能：
 * 1. 项目群列表：显示所有项目群的概览信息
 * 2. 项目群详情：展示选中项目群的统计信息（Dashboard）
 * 3. 项目群创建：支持创建新项目群
 * 4. 项目群操作：编辑、删除、导入导出项目群
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
 * 重命名项目群对话框
 */
@CustomDialog
struct RenameProjectGroupDialog {
  controller: CustomDialogController;
  projectGroupName: string = '';
  onConfirm: (newName: string) => void = () => {};
  @State inputValue: string = '';

  aboutToAppear() {
    this.inputValue = this.projectGroupName;
  }

  build() {
    Column({ space: 0 }) {
      Column({ space: 4 }) {
        Text('编辑项目群名称')
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
        TextInput({ text: this.inputValue, placeholder: '请输入项目群名称' })
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
 * 项目群首页主组件
 */
@Entry
@Component
struct ProjectGroupHome {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;

  @State projectGroupList: ProjectGroupMeta[] = [];
  @State selectedProjectGroupId: string = '';
  @State selectedProjectGroupDetail: ProjectGroup | null = null;
  @State isLoading: boolean = false;
  
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
    
    // 加载项目群列表
    await this.loadProjectGroupList();
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

  private async loadProjectGroupList(): Promise<void> {
    if (!this.storageService) return;
    
    this.isLoading = true;
    try {
      this.projectGroupList = await this.storageService.getProjectGroupList();
      console.log(`[ProjectGroupHome] Loaded ${this.projectGroupList.length} project groups`);
    } catch (error) {
      console.error('[ProjectGroupHome] Failed to load project group list:', error);
      this.promptAction.showToast({ message: '加载项目群列表失败' });
    } finally {
      this.isLoading = false;
    }
  }

  private async handleSelectProjectGroup(groupId: string): Promise<void> {
    this.selectedProjectGroupId = groupId;
    
    if (!this.storageService) return;
    
    try {
      const projectGroup = await this.storageService.getProjectGroup(groupId);
      this.selectedProjectGroupDetail = projectGroup;
    } catch (error) {
      console.error('[ProjectGroupHome] Failed to load project group detail:', error);
      this.promptAction.showToast({ message: '加载项目群详情失败' });
    }
  }

  private async handleCreateProjectGroup(): Promise<void> {
    this.uiContext.getRouter().pushUrl({
      url: 'pages/ProjectGroupIndex'
    } as router.RouterOptions);
  }

  private handleOpenProjectGroup(groupId: string): void {
    this.uiContext.getRouter().pushUrl({
      url: 'pages/ProjectGroupIndex',
      params: { groupId: groupId }
    } as router.RouterOptions);
  }

  private async handleDeleteProjectGroup(group: ProjectGroupMeta): Promise<void> {
    this.uiContext.showAlertDialog({
      title: '确认删除',
      message: `确定要删除项目群 "${group.name}" 吗？此操作不可恢复！`,
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
            await this.storageService.deleteProjectGroup(group.id);
            await this.loadProjectGroupList();
            this.promptAction.showToast({ message: '项目群已删除' });
            
            if (this.selectedProjectGroupId === group.id) {
              this.selectedProjectGroupId = '';
              this.selectedProjectGroupDetail = null;
            }
          } catch (error) {
            console.error('[ProjectGroupHome] Failed to delete project group:', error);
            this.promptAction.showToast({ message: '删除项目群失败' });
          }
        }
      }
    });
  }

  private handleRenameProjectGroup(group: ProjectGroupMeta): void {
    this.renameDialogController = new CustomDialogController({
      builder: RenameProjectGroupDialog({
        projectGroupName: group.name,
        onConfirm: async (newName: string) => {
          if (!this.storageService) return;
          
          try {
            const projectGroup = await this.storageService.getProjectGroup(group.id);
            if (projectGroup) {
              projectGroup.name = newName;
              await this.storageService.saveProjectGroup(projectGroup);
              await this.loadProjectGroupList();
              
              if (this.selectedProjectGroupId === group.id) {
                this.selectedProjectGroupDetail = projectGroup;
              }
              
              this.promptAction.showToast({ message: '项目群已重命名' });
            }
          } catch (error) {
            console.error('[ProjectGroupHome] Failed to rename project group:', error);
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
      // 左侧：项目群列表（复用 Home.ets 的 Sidebar 设计）
      this.Sidebar()

      // 右侧：项目群详情或欢迎界面（复用 Home.ets 的 Dashboard 设计）
      Column() {
        if (this.selectedProjectGroupDetail) {
          this.ProjectGroupDashboard()
        } else {
          this.WelcomeView()
        }
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .backgroundColor(ColorResource.backgroundSecondary)
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight)
    })
  }

  // 左侧边栏（项目群列表）
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

        Text('项目群')
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
        .onClick(() => this.handleCreateProjectGroup())
      }
      .width('100%')
      .padding(ThemeConfig.spacingL)
      .backgroundColor(ColorResource.surface)

      // 项目群列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color(ColorResource.primaryColor)
          
          Text('加载中...')
            .fontSize(ThemeConfig.fontSizeM)
            .fontColor(ColorResource.textSecondary)
            .margin({ top: ThemeConfig.spacingM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.projectGroupList.length === 0) {
        Column({ space: ThemeConfig.spacingL }) {
          Text('📁')
            .fontSize(60)
          
          Text('还没有项目群')
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
          ForEach(this.projectGroupList, (group: ProjectGroupMeta) => {
            ListItem() {
              Row({ space: ThemeConfig.spacingM }) {
                Text('📂')
                  .fontSize(ThemeConfig.fontSizeXXL)

                Column({ space: 4 }) {
                  Text(group.name)
                    .fontSize(ThemeConfig.fontSizeM)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                    .fontColor(this.selectedProjectGroupId === group.id 
                      ? ColorResource.primaryColor 
                      : ColorResource.textPrimary)
                  
                  Text(new Date(group.lastModified).toLocaleDateString())
                    .fontSize(ThemeConfig.fontSizeXS)
                    .fontColor(ColorResource.textSecondary)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(ThemeConfig.spacingM)
              .backgroundColor(this.selectedProjectGroupId === group.id 
                ? ColorResource.primaryUltraLight 
                : ColorResource.surface)
              .borderRadius(ThemeConfig.radiusMedium)
              .border({
                width: this.selectedProjectGroupId === group.id ? 2 : 0,
                color: ColorResource.primaryColor
              })
              .onClick(() => this.handleSelectProjectGroup(group.id))
              .gesture(
                LongPressGesture()
                  .onAction(() => {
                    this.showProjectGroupContextMenu(group);
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
    .width(380)
    .height('100%')
    .backgroundColor(ColorResource.backgroundPage)
    .shadow(ThemeConfig.shadowMedium)
  }

  // 项目群详情面板（Dashboard）
  @Builder
  ProjectGroupDashboard() {
    Scroll() {
      Column({ space: ThemeConfig.spacingXL }) {
        // 标题
        Text(this.selectedProjectGroupDetail?.name || '')
          .fontSize(ThemeConfig.fontSizeXXXL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.textPrimary)
          .width('100%')

        // 统计卡片
        GridRow({ columns: 2, gutter: ThemeConfig.spacingM }) {
          GridCol({ span: 1 }) {
            this.StatCard('项目数量', 
              `${this.selectedProjectGroupDetail?.projectRefs.length || 0}`,
              '个')
          }
          GridCol({ span: 1 }) {
            this.StatCard('依赖关系', 
              `${this.selectedProjectGroupDetail?.dependencies.length || 0}`,
              '条')
          }
        }
        .width('100%')

        // 项目列表
        Column({ space: ThemeConfig.spacingM }) {
          Text('包含的项目')
            .fontSize(ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.textPrimary)

          if (this.selectedProjectGroupDetail && this.selectedProjectGroupDetail.projectRefs.length > 0) {
            ForEach(this.selectedProjectGroupDetail.projectRefs, (ref: ProjectRef) => {
              Row({ space: ThemeConfig.spacingM }) {
                Text('📄')
                  .fontSize(ThemeConfig.fontSizeL)
                
                Text(ref.name)
                  .fontSize(ThemeConfig.fontSizeM)
                  .fontColor(ColorResource.textPrimary)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(ThemeConfig.spacingM)
              .backgroundColor(ColorResource.surface)
              .borderRadius(ThemeConfig.radiusMedium)
            })
          } else {
            Text('暂无项目')
              .fontSize(ThemeConfig.fontSizeM)
              .fontColor(ColorResource.textMuted)
              .padding(ThemeConfig.spacingL)
          }
        }
        .width('100%')

        // 操作按钮
        Row({ space: ThemeConfig.spacingM }) {
          Button('编辑项目群')
            .layoutWeight(1)
            .height(50)
            .fontSize(ThemeConfig.fontSizeL)
            .backgroundColor(ColorResource.primaryColor)
            .fontColor(Color.White)
            .onClick(() => {
              if (this.selectedProjectGroupDetail) {
                this.handleOpenProjectGroup(this.selectedProjectGroupDetail.id);
              }
            })

          Button('重命名')
            .layoutWeight(1)
            .height(50)
            .fontSize(ThemeConfig.fontSizeL)
            .backgroundColor(ColorResource.infoLight)
            .fontColor(ColorResource.infoColor)
            .onClick(() => {
              const group = this.projectGroupList.find(g => g.id === this.selectedProjectGroupId);
              if (group) {
                this.handleRenameProjectGroup(group);
              }
            })

          Button('删除')
            .layoutWeight(1)
            .height(50)
            .fontSize(ThemeConfig.fontSizeL)
            .backgroundColor(ColorResource.errorLight)
            .fontColor(ColorResource.errorColor)
            .onClick(() => {
              const group = this.projectGroupList.find(g => g.id === this.selectedProjectGroupId);
              if (group) {
                this.handleDeleteProjectGroup(group);
              }
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(ThemeConfig.spacingXXL)
    }
    .width('100%')
    .height('100%')
  }

  // 统计卡片
  @Builder
  StatCard(title: string, value: string, unit: string) {
    Column({ space: ThemeConfig.spacingS }) {
      Text(title)
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textSecondary)
      
      Row({ space: 4 }) {
        Text(value)
          .fontSize(ThemeConfig.fontSizeXXXL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.primaryColor)
        
        Text(unit)
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.textSecondary)
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(ThemeConfig.spacingL)
    .backgroundColor(ColorResource.surface)
    .borderRadius(ThemeConfig.radiusLarge)
    .shadow(ThemeConfig.cardShadow)
    .alignItems(HorizontalAlign.Start)
  }

  // 欢迎界面
  @Builder
  WelcomeView() {
    Column({ space: ThemeConfig.spacingXXL }) {
      Text('📂')
        .fontSize(100)
      
      Text('欢迎使用项目群管理')
        .fontSize(ThemeConfig.fontSizeXXXL)
        .fontWeight(ThemeConfig.fontWeightBold)
        .fontColor(ColorResource.textPrimary)
      
      Text('在左侧选择一个项目群\n或创建新的项目群')
        .fontSize(ThemeConfig.fontSizeL)
        .fontColor(ColorResource.textSecondary)
        .textAlign(TextAlign.Center)
        .lineHeight(ThemeConfig.fontSizeL * 1.5)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 显示项目群上下文菜单
  private showProjectGroupContextMenu(group: ProjectGroupMeta): void {
    this.uiContext.showAlertDialog({
      title: group.name,
      message: '请选择操作',
      primaryButton: {
        value: '重命名',
        action: () => {
          this.handleRenameProjectGroup(group);
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: ColorResource.errorColor,
        action: () => {
          this.handleDeleteProjectGroup(group);
        }
      }
    });
  }
}
