// File: entry/src/main/ets/components/Sidebar.ets
/**
 * 侧边栏组件模块
 * 
 * 本组件是EasyFlow应用的主要导航和操作界面，提供项目管理和任务编辑的核心功能。
 * 采用响应式设计，根据当前状态动态显示不同的内容和操作选项。
 * 
 * 主要功能：
 * 1. 项目管理：显示项目信息、统计数据和基本操作
 * 2. 任务编辑：提供任务详情编辑和检查清单管理
 * 3. 项目创建：支持空白项目和模板项目的创建
 * 4. 任务操作：添加、删除、选择、连接任务等操作
 * 5. 状态切换：在项目概览和任务编辑之间切换
 * 6. 模板选择：提供项目模板的选择和预览功能
 * 
 * 设计特点：
 * - 响应式布局：根据屏幕尺寸和内容动态调整布局
 * - 状态驱动：根据当前状态显示不同的界面内容
 * - 模块化设计：将不同功能模块化为独立的子组件
 * - 交互友好：提供直观的操作反馈和状态指示
 * - 可扩展性：支持新功能的添加和现有功能的扩展
 * 
 * 界面模式：
 * - 首页模式：显示项目列表和创建选项
 * - 项目模式：显示项目概览和基本操作
 * - 编辑模式：显示任务编辑器和详细操作
 * - 模板模式：显示模板选择和预览界面
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { TaskEditor } from './TaskEditor';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { ResponsiveColorConfig } from '../utils/ResponsiveColorConfig';
import { BreakpointSystem } from '../utils/BreakpointSystem';
import { PromptAction } from '@kit.ArkUI';
import { ExportService, ExportFormat, ExportOptions } from '../services/ExportService';
import { image } from '@kit.ImageKit';

/**
 * 侧边栏组件
 * 
 * 实现应用主要导航和操作界面的核心组件，提供项目管理和任务编辑的完整功能。
 * 采用状态驱动设计，根据当前状态动态显示不同的界面内容。
 * 
 * 组件特性：
 * - 响应式数据绑定：使用@ObjectLink和@Prop实现数据的自动同步
 * - 状态管理：根据当前状态显示不同的界面模式
 * - 模块化设计：将功能分解为独立的子组件
 * - 交互反馈：提供丰富的用户操作反馈
 * - 可配置性：支持不同场景下的界面配置
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
@Component
export struct Sidebar {
  /** 项目数据对象，使用@ObjectLink实现响应式绑定 */
  @ObjectLink project: Project | null;
  /** 当前选中的任务，使用@Prop实现属性传递 */
  @Prop selectedTask: TaskNode | null;
  @State private selectedTaskForEditor: TaskNode | null = null;
  // 新增参数：区分首页和编辑页
  isHomePage: boolean = false;
  onCreateBlankProject: () => void = () => {};
  onCreateProjectFromTemplate: (templateId: string, projectName: string) => void = () => {};
  onDeleteTask: (taskId: string) => void = () => {};
  onGetCanvasPixelMap: (() => Promise<image.PixelMap | null>) | null = null; // 获取 Canvas 截图的回调
  exportService: ExportService | null = null; // 导出服务实例

  @State isEditingProjectName: boolean = false;
  @State tempProjectName: string = '';
  @State showNewProjectDialog: boolean = false;
  @State showTemplateDialog: boolean = false;
  // @State private taskEditorKey: number = 0;
  @State private screenWidth: number = 0;
  @State private currentTabIndex: number = 0; // 当前选中的Tab索引

  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  aboutToAppear() {
    this.selectedTaskForEditor = this.selectedTask;
    this.updateScreenSize();
  }

  private updateScreenSize() {
    try {
      const uiContext = this.getUIContext();
      // 使用默认值避免类型问题
      this.screenWidth = 840;
    } catch (error) {
      console.error('[Sidebar] Error getting screen size:', error);
      this.screenWidth = 840;
    }
  }

  // 删除任务方法
  private deleteTask(task: TaskNode) {
    this.uiContext.showAlertDialog({
      title: '确认删除任务',
      message: `确定要删除任务"${task.name}"吗？删除后无法恢复。`,
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消删除
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: ColorResource.errorColor,
        action: () => {
          this.onDeleteTask(task.id);
          this.promptAction.showToast({ message: '任务已删除' });
          // 如果删除的是当前选中的任务，切换到总览Tab
          if (this.selectedTaskForEditor?.id === task.id) {
            this.selectedTaskForEditor = null;
            this.currentTabIndex = 0;
          }
        }
      }
    });
  }
  
  /**
   * 导出为 JSON 格式
   * 将项目数据导出为标准 JSON 文件，包含所有任务和依赖关系
   */
  private async exportToJSON() {
    if (!this.project) {
      this.promptAction.showToast({ 
        message: '当前没有可导出的项目',
        duration: 2000 
      });
      return;
    }
    
    if (!this.exportService) {
      this.promptAction.showToast({ 
        message: '导出服务未初始化',
        duration: 2000 
      });
      return;
    }
    
    // 显示导出中提示
    this.promptAction.showToast({ 
      message: '正在导出 JSON...',
      duration: 1000 
    });
    
    const options: ExportOptions = {
      format: ExportFormat.JSON,
      fileName: this.project.name,
      includeTimestamp: true
    };
    
    const result = await this.exportService.exportProject(this.project, options);
    
    if (result.success) {
      this.promptAction.showToast({ 
        message: `JSON 导出成功！文件已保存`,
        duration: 3000 
      });
      console.log('[Sidebar] JSON 导出成功:', result.filePath);
    } else {
      this.promptAction.showToast({ 
        message: `导出失败: ${result.error || '未知错误'}`,
        duration: 3000 
      });
      console.error('[Sidebar] JSON 导出失败:', result.error);
    }
  }
  
  /**
   * 导出为图片格式
   * 将画布内容导出为 PNG/JPG 图片
   */
  private async exportToImage() {
    if (!this.project) {
      this.promptAction.showToast({ 
        message: '当前没有可导出的项目',
        duration: 2000 
      });
      return;
    }
    
    if (!this.exportService) {
      this.promptAction.showToast({ 
        message: '导出服务未初始化',
        duration: 2000 
      });
      return;
    }
    
    if (!this.onGetCanvasPixelMap) {
      this.promptAction.showToast({ 
        message: '无法获取画布数据',
        duration: 2000 
      });
      return;
    }
    
    // 显示导出中提示
    this.promptAction.showToast({ 
      message: '正在导出图片...',
      duration: 1000 
    });
    
    // 获取 Canvas 截图
    const pixelMap = await this.onGetCanvasPixelMap();
    if (!pixelMap) {
      this.promptAction.showToast({ 
        message: '获取画布截图失败',
        duration: 3000 
      });
      return;
    }
    
    const options: ExportOptions = {
      format: ExportFormat.PNG,
      fileName: `${this.project.name}`,
      includeTimestamp: true,
      imageQuality: 95
    };
    
    const result = await this.exportService.exportProject(this.project, options, pixelMap);
    
    if (result.success) {
      this.promptAction.showToast({ 
        message: `图片导出成功！文件已保存`,
        duration: 3000 
      });
      console.log('[Sidebar] 图片导出成功:', result.filePath);
    } else {
      this.promptAction.showToast({ 
        message: `导出失败: ${result.error || '未知错误'}`,
        duration: 3000 
      });
      console.error('[Sidebar] 图片导出失败:', result.error);
    }
  }
  
  /**
   * 导出为 Excel 格式
   * 将任务数据导出为 Excel 电子表格，便于数据分析
   */
  private async exportToExcel() {
    if (!this.project) {
      this.promptAction.showToast({ 
        message: '当前没有可导出的项目',
        duration: 2000 
      });
      return;
    }
    
    if (!this.exportService) {
      this.promptAction.showToast({ 
        message: '导出服务未初始化',
        duration: 2000 
      });
      return;
    }
    
    // 显示导出中提示
    this.promptAction.showToast({ 
      message: '正在导出 Excel...',
      duration: 1000 
    });
    
    const options: ExportOptions = {
      format: ExportFormat.CSV,
      fileName: `${this.project.name}_任务列表`,
      includeTimestamp: true
    };
    
    const result = await this.exportService.exportProject(this.project, options);
    
    if (result.success) {
      this.promptAction.showToast({ 
        message: `Excel(CSV) 导出成功！\n文件已保存`,
        duration: 3000 
      });
      console.log('[Sidebar] Excel 导出成功:', result.filePath);
    } else {
      this.promptAction.showToast({ 
        message: `导出失败: ${result.error || '未知错误'}`,
        duration: 3000 
      });
      console.error('[Sidebar] Excel 导出失败:', result.error);
    }
  }
  
  aboutToUpdate() {
    // 当selectedTask变化时，更新selectedTaskForEditor并切换到任务编辑Tab
    if (this.selectedTaskForEditor?.id !== this.selectedTask?.id) {
      console.log(`[Sidebar] selectedTask changed, updating selectedTaskForEditor`);
      this.selectedTaskForEditor = this.selectedTask;
      // 如果有选中任务，切换到任务编辑Tab（索引1）
      if (this.selectedTask) {
        this.currentTabIndex = 1;
      }
    } else if (this.selectedTask && this.selectedTaskForEditor) {
      // 如果ID相同但内容可能不同，同步更新内容
      this.selectedTaskForEditor = this.selectedTask;
    }
    
    // 当project中的任务数据更新时，同步更新selectedTaskForEditor
    if (this.project && this.selectedTaskForEditor) {
      const updatedTask = this.project.tasks.find(t => t.id === this.selectedTaskForEditor?.id);
      if (updatedTask) {
        const oldChecklistLength = this.selectedTaskForEditor.checklist?.length || 0;
        const newChecklistLength = updatedTask.checklist?.length || 0;
        
        if (oldChecklistLength !== newChecklistLength) {
          console.log(`[Sidebar] Task ${updatedTask.id} checklist updated: ${oldChecklistLength} -> ${newChecklistLength}`);
        }
        
        // 直接更新selectedTaskForEditor，确保数据同步
        this.selectedTaskForEditor = updatedTask;
      }
    }
  }

  onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => void = () => {};
  onUpdateChecklist: (taskId: string, checklist: ChecklistItem[]) => void = () => {};
  onAddChecklistItem: (taskId: string, text: string) => void = () => {};
  onDeleteChecklistItem: (taskId: string, itemId: string) => void = () => {};
  onUpdateProjectName: (newName: string) => void = () => {};
  onAddTask: () => void = () => {};
  onStartConnecting: () => void = () => {};
  // 新增回调
  onSave: () => void = () => {};
  onBack: () => void = () => {};
  onAddReminder: (task: TaskNode) => void = () => {};

  private saveProjectName() {
    if (this.tempProjectName.trim() === '') {
      this.promptAction.showToast({ message: '项目名称不能为空' });
      return;
    }
    this.onUpdateProjectName(this.tempProjectName);
    this.isEditingProjectName = false;
  }

  build() {
    Stack() {
      // 主内容
      Column() {
        // 只有当项目加载完成后才显示内容
        if (this.project) {
          // 使用Tabs组件整合总览和任务编辑
          Tabs({ barPosition: BarPosition.Start, index: this.currentTabIndex }) {
            // Tab 1: 总览（项目概览）
            TabContent() {
              this.ProjectView()
            }
            .tabBar('总览')

            // Tab 2: 任务编辑（动态显示任务名称）
            TabContent() {
              if (this.selectedTaskForEditor) {
                TaskEditor({
                  task: this.selectedTaskForEditor,
                  onUpdateTask: (taskId: string, updates: Partial<TaskNode>) => {
                    this.onUpdateTask(taskId, updates);
                  },
                  onUpdateChecklist: this.onUpdateChecklist,
                  onAddChecklistItem: this.onAddChecklistItem,
                  onDeleteChecklistItem: this.onDeleteChecklistItem,
                  onDeleteTask: this.onDeleteTask,
                  onStartConnecting: this.onStartConnecting,
                  onAddReminder: (task: TaskNode) => {
                    // 由父页面通过 onUpdateTask / 外部服务真正创建提醒
                    // 这里仅保留回调链路，具体实现放在页面层
                    console.log('[Sidebar] onAddReminder triggered for task', task.id); 
                    this.onAddReminder(task);
                  },
                  onBack: () => {
                    this.selectedTaskForEditor = null;
                    this.currentTabIndex = 0; // 返回总览Tab
                  }
                })
              } else {
                // 没有选中任务时显示提示
                Column({ space: ThemeConfig.spacingXL }) {
                  Image($r('app.media.ic_empty_box'))
                    .width(64)
                    .height(64)
                    .opacity(0.4)
                  Text('请选择一个任务进行编辑')
                    .fontSize(ThemeConfig.fontSizeL)
                    .fontColor(ColorResource.textTertiary)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }
            }
            .tabBar(this.selectedTaskForEditor?.name || '编辑任务')
          }
          .onChange((index: number) => {
            this.currentTabIndex = index;
            // 如果切换到总览Tab，清除选中的任务
            if (index === 0) {
              this.selectedTaskForEditor = null;
            }
          })
          .width('100%')
          .height('100%')
        } else {
          // 项目加载中或加载失败时显示的内容 - 现代化毛玻璃设计
          Column({ space: ThemeConfig.spacingXL }) {
            // 加载图标容器 - 毛玻璃效果
            Stack() {
              // 背景圆形
              Circle()
                .width(80)
                .height(80)
                .fill(ColorResource.overlaySubtle)
                .backdropBlur(ThemeConfig.backdropBlurMedium)
                .shadow(ThemeConfig.shadowMedium)
                .border({ width: 2, color: ColorResource.primaryUltraLight, radius: 40 })
              
              // 加载进度
            LoadingProgress()
              .width(50)
              .height(50)
              .color(ColorResource.primaryColor)
            }
            .width(80)
            .height(80)
            
            // 加载文本容器 - 毛玻璃效果
            Column({ space: ThemeConfig.spacingS }) {
              Text('正在加载项目...')
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(ColorResource.surfaceDeep)
                .fontWeight(ThemeConfig.fontWeightBold)
                .shadow({ radius: ThemeConfig.shadowSmall.radius, color: ColorResource.shadowColorSubtle, offsetX: ThemeConfig.shadowSmall.offsetX, offsetY: ThemeConfig.shadowSmall.offsetY })

              Text('请稍候')
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ColorResource.surfaceBold)
                .fontWeight(ThemeConfig.fontWeightMedium)
                .textAlign(TextAlign.Center)
            }
            .padding(ThemeConfig.spacingL)
            .backgroundColor(ColorResource.overlaySubtle)
            .backdropBlur(ThemeConfig.backdropBlurSmall)
            .borderRadius(ThemeConfig.radiusLarge)
            .shadow(ThemeConfig.shadowSmall)
            .border({ width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusLarge })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ResponsiveColorConfig.getSidebarBackgroundColor(this.screenWidth))
      .padding(ThemeConfig.spacingXXL)
      .shadow(ThemeConfig.shadowMedium)
      .border({ width: { right: 1 }, color: ColorResource.surfaceNeutral })
      .backdropBlur(ResponsiveColorConfig.getSidebarBackdropBlur(this.screenWidth))
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 导出菜单 Builder
   * 使用 bindMenu 实现的现代化下拉菜单，提供多种导出格式选项
   * 
   * 特性：
   * - 原生下拉菜单组件，自动处理定位和点击外部关闭
   * - 使用图标和说明文字提升用户体验
   * - 分组显示不同类型的导出选项
   * - 响应式布局，自动适应屏幕尺寸
   */
  @Builder
  ExportMenu() {
    Menu() {
      // JSON 导出选项 - 数据格式
      MenuItem({ 
        content: '导出为 JSON',
        labelInfo: '项目数据文件'
      })
        .onChange(() => {
          this.exportToJSON();
        })
      
      // 视觉导出选项组
        // 图片导出选项
        MenuItem({ 
          content: '导出为图片',
          labelInfo: 'PNG/JPG 格式'
        })
          .onChange(() => {
            this.exportToImage();
          })

      // 数据导出选项组
        // Excel 导出选项
        MenuItem({ 
          content: '导出为 Excel',
          labelInfo: '电子表格格式'
        })
          .onChange(() => {
            this.exportToExcel();
          })
    }
  }

  @Builder
  ProjectView() {
    if (this.project) {
      Column({ space: 16 }) {
        // --- 顶部操作栏 ---
        Row({space: 16}) {
          // 返回主页按钮 - 现代化设计
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
          .onClick(() => { this.onBack() })

          // 新建任务按钮（仅编辑页显示）- 现代化设计
          if (!this.isHomePage) {
            Button({ type: ButtonType.Circle }) {
              Text('+')
                .fontSize(ThemeConfig.fontSizeXL)
                .fontColor(Color.White)
                .fontWeight(ThemeConfig.fontWeightBold)
            }
            .width(52)
            .height(52)
            .backgroundColor(ColorResource.successColor)
            .borderRadius(26)
            .shadow(ThemeConfig.shadowMedium)
            .border({ width: 2, color: ColorResource.successLight, radius: 26 })
            .onClick(() => { this.onAddTask() })
            .margin({ left: 12 })
          }

          // 保存项目按钮 - 现代化设计
          Button({ type: ButtonType.Circle }) {
            Text('💾')
              .fontSize(ThemeConfig.fontSizeL)
              .fontColor(Color.White)
          }
          .width(52)
          .height(52)
          .backgroundColor(ColorResource.primaryColor)
          .borderRadius(26)
          .shadow(ThemeConfig.shadowMedium)
          .border({ width: 2, color: ColorResource.primaryUltraLight, radius: 26 })
          .onClick(() => { this.onSave() })
          .margin({ left: 12 })
          
          // 导出按钮 - 使用 bindMenu 实现下拉菜单
          Button({ type: ButtonType.Circle }) {
            Text('📤')
              .fontSize(ThemeConfig.fontSizeL)
              .fontColor(Color.White)
          }
          .width(52)
          .height(52)
          .backgroundColor(ColorResource.successColor)
          .borderRadius(26)
          .shadow(ThemeConfig.shadowMedium)
          .border({ width: 2, color: ColorResource.successLight, radius: 26 })
          .margin({ left: 12 })
          .bindMenu(this.ExportMenu())

          // 占位拉伸
          Blank().layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 项目标题区域
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            if (this.isEditingProjectName) {
              TextInput({ text: this.tempProjectName })
                .layoutWeight(1)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(ColorResource.backgroundInput)
                .borderRadius(12)
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .onChange((value: string) => { this.tempProjectName = value; })
                .onSubmit(() => { this.saveProjectName(); })
            } else {
              Text(this.project.name)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .maxLines(1)
                .fontColor(ColorResource.textPrimary)
            }
            Button() {
              Image(this.isEditingProjectName ? $r('app.media.ic_confirm') : $r("app.media.ic_edit"))
                .width(18)
                .height(18)
                .fillColor(this.isEditingProjectName ? ColorResource.textSuccess : ColorResource.textSecondary)
            }
            .width(44)
            .height(44)
            .type(ButtonType.Circle)
            .backgroundColor($r('sys.color.comp_background_list_card'))
            .borderRadius(22)
            .shadow({ radius: ThemeConfig.shadowMedium.radius, color: ThemeConfig.shadowMedium.color, offsetX: ThemeConfig.shadowMedium.offsetX, offsetY: ThemeConfig.shadowMedium.offsetY })
            .onClick(() => {
              if (this.isEditingProjectName) {
                this.saveProjectName();
              } else {
                this.tempProjectName = this.project!.name;
                this.isEditingProjectName = true;
              }
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 项目统计卡片
          Row({ space: 20 }) {
            Column() {
              Text(this.project.tasks.length.toString())
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.primaryColor)
              Text('总任务')
                .fontSize(13)
                .fontColor(ColorResource.textTertiary)
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor(ColorResource.transparent)
            .borderRadius(12)

            Column() {
              Text(this.project.tasks.filter(t => t.isCritical).length.toString())
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorResource.errorColor)
              Text('关键任务')
                .fontSize(13)
                .fontColor(ColorResource.textTertiary)
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor(ColorResource.transparent)
            .borderRadius(12)
          }
          .width('100%')
        }
        .padding(ThemeConfig.spacingXL)
        .backgroundColor(ColorResource.overlayRegular)
        .borderRadius(ThemeConfig.radiusXLarge)
        .shadow(ThemeConfig.cardShadow)
        .border({ width: 0, color: ColorResource.transparent, radius: ThemeConfig.radiusXLarge })
        .backdropBlur(ThemeConfig.backdropBlurMedium)

        // 操作按钮区域
        Column({ space: 16 }) {
        }

        // 任务列表区域
        Column({ space: 12 }) {
          Text('任务列表')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorResource.textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start)

          if (this.project.tasks.length === 0) {
            Column({ space: 16 }) {
              Image($r('app.media.ic_empty_box'))
                .width(64)
                .height(64)
                .opacity(0.4)
              Text('暂无任务')
                .fontSize(15)
                .fontColor(ColorResource.textTertiary)
              Text('点击上方按钮添加新任务')
                .fontSize(13)
                .fontColor(ColorResource.textTertiary)
            }
            .width('100%')
            .padding(40)
            .justifyContent(FlexAlign.Center)
            .layoutWeight(1)
          } else {
            List({ space: 12 }) {
              ForEach(this.project.tasks.sort((a, b) => a.startDate.getTime() - b.startDate.getTime()), (task: TaskNode) => {
                ListItem() {
                  Row({ space: 12 }) {
                    // 任务状态指示器
                    Column()
                      .width(4)
                      .height(44)
                      .backgroundColor(task.isCritical ? ColorResource.errorColor : ColorResource.primaryColor)
                      .borderRadius(2)

                    // 任务信息
                    Column({ space: 6 }) {
                      Text(task.name)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(ColorResource.textPrimary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${task.startDate.toLocaleDateString()} - ${task.endDate.toLocaleDateString()}`)
                        .fontSize(13)
                        .fontColor(ColorResource.textTertiary)
                      
                      // 子任务信息
                      if (task.checklist && task.checklist.length > 0) {
                        Row({ space: 8 }) {
                          Text(`${task.checklist.filter(item => item.isCompleted).length}/${task.checklist.length} 已完成`)
                            .fontSize(12)
                            .fontColor(ColorResource.textTertiary)
                        }
                        .width('100%')
                        .alignItems(VerticalAlign.Center)
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    // 删除按钮 - 只在任务被选中时显示
                    if (this.selectedTask?.id === task.id) {
                      Button() {
                        Text('×')
                          .fontSize(ThemeConfig.fontSizeL)
                          .fontColor(ColorResource.errorColor)
                          .fontWeight(ThemeConfig.fontWeightBold)
                      }
                      .width(36)
                      .height(36)
                      .backgroundColor(ColorResource.errorLight)
                      .borderRadius(ThemeConfig.radiusMedium)
                      .shadow(ThemeConfig.shadowSmall)
                      .border({ 
                        width: 2, 
                        color: ColorResource.errorColor, 
                        radius: ThemeConfig.radiusMedium 
                      })
                      .onClick(() => {
                        this.deleteTask(task);
                      })
                    }

                  }
                  .width('100%')
                  .padding(ThemeConfig.spacingXL)
                  .backgroundColor(this.selectedTask?.id === task.id ? ColorResource.hoverPrimaryLight : ColorResource.overlayLight)
                  .borderRadius(ThemeConfig.radiusMedium)
                  .shadow(this.selectedTask?.id === task.id ? ThemeConfig.shadowMedium : ThemeConfig.shadowSmall)
                  .border({ 
                    width: this.selectedTask?.id === task.id ? 2 : 0, 
                    color: this.selectedTask?.id === task.id ? ColorResource.primaryColor : ColorResource.transparent, 
                    radius: ThemeConfig.radiusMedium 
                  })
                  .backdropBlur(ThemeConfig.backdropBlurSmall)
                  .margin({ bottom: ThemeConfig.spacingS })
                  .onClick(() => {
                    this.selectedTask = task;
                    this.currentTabIndex = 1; // 切换到任务编辑Tab
                  })
                  .onTouch((event: TouchEvent) => {
                    if (event.type === TouchType.Down) {
                      // 添加按下效果
                    }
                  })
                  .gesture(
                    TapGesture({ count: 1 })
                      .onAction(() => {
                        this.selectedTask = task;
                        this.currentTabIndex = 1; // 切换到任务编辑Tab
                      })
                  )
                }
              })
            }
            .height('100%')
            .width('100%')
            .layoutWeight(1)
          }
        }
        .layoutWeight(1)
      }
      .alignItems(HorizontalAlign.Start)
    }
  }
}
