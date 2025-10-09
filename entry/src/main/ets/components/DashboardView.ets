// File: entry/src/main/ets/components/DashboardView.ets
/**
 * 项目仪表板视图组件
 *
 * 本组件是项目概览页面的核心展示组件，提供项目关键信息的可视化展示。
 * 采用卡片式布局设计，展示项目统计信息、进度概览和即将到期的任务。
 *
 * 主要功能：
 * 1. 项目概览：显示项目基本信息和关键统计数据
 * 2. 进度统计：展示项目整体完成度和时间进度
 * 3. 任务概览：显示任务总数、关键任务数等统计信息
 * 4. 即将到期：列出未来7天内即将到期的任务
 * 5. 快速操作：提供进入编辑页面的快速入口
 * 6. 响应式设计：根据数据变化自动更新显示内容
 *
 * 设计特点：
 * - 卡片式布局：使用卡片组件组织不同类型的信息
 * - 数据驱动：基于项目数据动态计算和显示统计信息
 * - 响应式更新：使用@ObjectLink实现数据的响应式绑定
 * - 视觉层次：通过颜色、大小、间距建立清晰的信息层次
 * - 交互友好：提供清晰的视觉反馈和操作引导
 *
 * 统计指标：
 * - 总任务数：项目中所有任务的数量
 * - 项目总工期：从最早开始到最晚结束的总时间
 * - 整体完成度：基于检查清单完成情况的进度百分比
 * - 关键任务数：关键路径上的任务数量
 * - 即将到期：未来7天内到期的任务列表
 *
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode } from '../model/ProjectData';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import router from '@ohos.router';
import vibrator from '@ohos.vibrator';
import { BreakpointSystem, BreakpointConfig } from '../utils/BreakpointSystem';

/**
 * 项目仪表板视图组件
 *
 * 展示项目概览信息的核心UI组件，采用响应式设计自动更新显示内容。
 * 使用@ObjectLink装饰器实现与项目数据的双向绑定，确保数据变化时自动更新界面。
 *
 * 组件特性：
 * - 响应式数据绑定：使用@ObjectLink实现数据的自动同步
 * - 统计信息计算：实时计算项目的各种统计指标
 * - 卡片式布局：使用网格布局展示不同类型的统计信息
 * - 交互式设计：提供进入编辑页面的快速操作入口
 * - 空状态处理：优雅处理无数据或加载中的状态
 *
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
@Component
export struct DashboardView {
  /** 项目数据对象，使用@Prop实现属性传递 */
  @Prop project: Project;
  /** 是否显示画布背景，用于控制毛玻璃效果 */
  @Prop showCanvasBackground: boolean = false;
  /** 强制更新键，用于触发组件重新渲染 */
  @State private updateKey: number = 0;
  /** 透明度状态，用于过渡动画 */
  @State private fadeOpacity: number = 0;
  /** 缩放状态，用于进入动画 */
  @State private scaleValue: number = 0.9;
  /** 位移状态，用于进入动画 */
  @State private translateY: number = 20;
  /** 编辑按钮交互效果状态 */
  @State private editButtonScale: number = 1;
  @State private editButtonOpacity: number = 1;
  @State private isEditButtonPressed: boolean = false;
  /** 响应式布局状态 */
  @State private screenWidth: number = 0;
  @State private currentBreakpoint: BreakpointConfig = BreakpointSystem.getCurrentBreakpoint(0);
  @State private isPhone: boolean = false;
  /** 是否为浮动卡片模式（手机端） */
  @Prop isFloatingCard: boolean = false;

  // aboutToAppear 会在组件首次创建和显示时调用
  aboutToAppear() {
    console.log(`[DashboardView] Component appeared for project: ${this.project.name} with ${this.project.tasks.length} tasks`);
    console.log(`[DashboardView] Total duration: ${this.getTotalDuration()} days`);
    console.log(`[DashboardView] Overall completion: ${this.getOverallCompletion()}%`);
    console.log(`[DashboardView] Critical tasks: ${this.getCriticalTasksCount()}`);
    
    // 初始化屏幕尺寸
    this.updateScreenSize();
    
    // 强制触发更新
    this.updateKey++;
    
    // 触发进入动画
    this.startEnterAnimation();
  }

  // 更新屏幕尺寸和断点配置
  private updateScreenSize() {
    try {
      const uiContext = this.getUIContext();
      // 使用默认值避免类型问题
      this.screenWidth = 840;
      this.currentBreakpoint = BreakpointSystem.getCurrentBreakpoint(this.screenWidth);
      this.isPhone = false;
    } catch (error) {
      console.error('[DashboardView] Error getting screen size:', error);
      this.screenWidth = 840;
      this.currentBreakpoint = BreakpointSystem.getCurrentBreakpoint(this.screenWidth);
      this.isPhone = false;
    }
  }

  // aboutToUpdate 会在 @Prop project 的数据发生变化时调用
  aboutToUpdate() {
    console.log(`[DashboardView] Project data updated: ${this.project.name} with ${this.project.tasks.length} tasks`);
    console.log(`[DashboardView] Total duration: ${this.getTotalDuration()} days`);
    console.log(`[DashboardView] Overall completion: ${this.getOverallCompletion()}%`);
    console.log(`[DashboardView] Critical tasks: ${this.getCriticalTasksCount()}`);
    
    // 强制触发更新
    this.updateKey++;
    
    // 触发进入动画
    this.startEnterAnimation();
  }

  // 监听project变化，确保数据更新时重新计算
  onPageShow() {
    console.log(`[DashboardView] onPageShow - Project: ${this.project.name} with ${this.project.tasks.length} tasks`);
    console.log(`[DashboardView] Total duration: ${this.getTotalDuration()} days`);
    console.log(`[DashboardView] Overall completion: ${this.getOverallCompletion()}%`);
    console.log(`[DashboardView] Critical tasks: ${this.getCriticalTasksCount()}`);
    
    // 强制触发更新
    this.updateKey++;
  }

  // 开始进入动画
  private startEnterAnimation() {
    // 重置动画状态
    this.fadeOpacity = 0;
    this.scaleValue = 0.9;
    this.translateY = 20;
    
    // 延迟执行动画，确保组件已渲染
    setTimeout(() => {
      this.fadeOpacity = 1;
      this.scaleValue = 1;
      this.translateY = 0;
    }, 50);
  }

  // 编辑按钮按下效果
  private startEditButtonPress() {
    this.isEditButtonPressed = true;
    this.editButtonScale = 0.95;
    this.editButtonOpacity = 0.9;
  }

  // 编辑按钮释放效果
  private endEditButtonPress() {
    this.isEditButtonPressed = false;
    this.editButtonScale = 1;
    this.editButtonOpacity = 1;
  }




  // --- Helper Functions to calculate stats ---
  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  private getTotalDuration(): number {
    if (!this.project || this.project.tasks.length === 0) return 0;
    const startDates = this.project.tasks.map(t => t.startDate.getTime());
    const endDates = this.project.tasks.map(t => t.endDate.getTime());
    const minStart = Math.min(...startDates);
    const maxEnd = Math.max(...endDates);
    const diffTime = maxEnd - minStart;
    const duration = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    console.log(`[DashboardView] Project "${this.project.name}" total duration: ${duration} days (from ${new Date(minStart).toLocaleDateString()} to ${new Date(maxEnd).toLocaleDateString()})`);
    return duration;
  }

  private getOverallCompletion(): number {
    if (!this.project || this.project.tasks.length === 0) return 0;
    const totalChecklistItems = this.project.tasks.reduce((sum, task) => sum + task.checklist.length, 0);
    if (totalChecklistItems === 0) return 0;
    const completedItems = this.project.tasks.reduce((sum, task) => {
      return sum + task.checklist.filter(item => item.isCompleted).length;
    }, 0);
    const completion = Math.round((completedItems / totalChecklistItems) * 100);
    console.log(`[DashboardView] Project "${this.project.name}" overall completion: ${completion}% (${completedItems}/${totalChecklistItems} checklist items completed)`);
    return completion;
  }

  private getCriticalTasksCount(): number {
    const count = this.project.tasks.filter(t => t.isCritical).length;
    console.log(`[DashboardView] Project "${this.project.name}" critical tasks count: ${count}/${this.project.tasks.length}`);
    return count;
  }

  private getUpcomingTasks(): TaskNode[] {
    const now = new Date();
    const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const upcoming = this.project.tasks
      .filter(task => task.endDate >= now && task.endDate <= sevenDaysLater)
      .sort((a, b) => a.endDate.getTime() - b.endDate.getTime());
    console.log(`[DashboardView] Project "${this.project.name}" upcoming tasks: ${upcoming.length} tasks in next 7 days`);
    return upcoming;
  }

  build() {
    // build() 方法现在是纯粹的UI描述，不再包含业务逻辑计算
    Column({ space: BreakpointSystem.getResponsiveSpacing(16, this.screenWidth) }) {
      // 1. 项目标题和进入编辑按钮 - 优化布局
      Column({ space: BreakpointSystem.getResponsiveSpacing(12, this.screenWidth) }) {
        // 项目名称单独一行，确保不被遮挡
        Text(this.project.name)
          .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeL : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXXL, this.screenWidth))
          .fontWeight(ThemeConfig.fontWeightBold)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
          .fontColor(ColorResource.surfaceDeep)
          .width('100%')
          .lineHeight((this.isFloatingCard ? ThemeConfig.fontSizeL : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXXL, this.screenWidth)) * 1.3)
        
        // 项目ID和编辑按钮在一行（浮动卡片模式不显示编辑按钮）
        if (!this.isFloatingCard) {
          Row({ space: ThemeConfig.spacingM }) {
            Text(`ID: ${this.project.id}`)
              .fontSize(BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeS, this.screenWidth))
              .fontColor(ColorResource.surfaceEmphasized)
              .fontWeight(ThemeConfig.fontWeightMedium)
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(1)

            Button() {
              Row({ space: ThemeConfig.spacingS }) {
                Text('编辑项目')
                  .fontSize(BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeM, this.screenWidth))
                  .fontColor(Color.White)
                  .fontWeight(ThemeConfig.fontWeightMedium)
              }
            }
            .accessibilityLevel('important')
            .height(this.isPhone ? 36 : 40)
            .padding({ 
              left: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth), 
              right: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth) 
            })
            .backgroundColor(this.isEditButtonPressed ? ColorResource.primaryDark : ColorResource.primaryColor)
            .borderRadius(this.isPhone ? 18 : 20)
            .shadow(ThemeConfig.shadowMedium)
            .border({ 
              width: 2, 
              color: this.isEditButtonPressed ? ColorResource.primaryDark : ColorResource.primaryUltraLight,
              radius: this.isPhone ? 18 : 20
            })
            .scale({ x: this.editButtonScale, y: this.editButtonScale })
            .opacity(this.editButtonOpacity)
            .animation({
              duration: ThemeConfig.animationFast,
              curve: ThemeConfig.animationEaseInOut,
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
                console.log('[DashboardView] Haptic feedback not available:', error);
              }
              
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/Index',
                params: { projectId: this.project.id },
                animation: {
                  type: 'fade',
                  duration: 300
                }
              } as router.RouterOptions);
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.startEditButtonPress();
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.endEditButtonPress();
              }
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        } else {
          // 浮动卡片模式：只显示ID
          Text(`ID: ${this.project.id}`)
            .fontSize(ThemeConfig.fontSizeXS)
            .fontColor(ColorResource.surfaceEmphasized)
            .fontWeight(ThemeConfig.fontWeightMedium)
            .opacity(0.8)
        }
      }
      .width('100%')
      .padding(this.isFloatingCard ? { left: 16, right: 16, top: 12, bottom: 12 } : BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth))
      .backgroundColor(this.isFloatingCard ? Color.Transparent : ColorResource.transparent)
      .borderRadius(this.isFloatingCard ? 0 : ThemeConfig.radiusLarge)
      .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.cardShadow)
      .border(this.isFloatingCard ? { width: 0 } : { width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusLarge })

      // 2. 核心指标统计 - 响应式布局
      if (this.isPhone) {
        // 手机端：2x2 网格布局
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            this.StatCard('总任务数', `${this.project.tasks.length}个`, ColorResource.primaryLight, ColorResource.primaryColor)
            this.StatCard('项目总工期', `${this.getTotalDuration()}天`, ColorResource.successLight, ColorResource.successColor)
          }
          .width('100%')
          Row({ space: 12 }) {
            this.StatCard('整体完成度', `${this.getOverallCompletion()}%`, ColorResource.warningLight, ColorResource.warningColor)
            this.StatCard('关键任务数', `${this.getCriticalTasksCount()}个`, ColorResource.errorLight, ColorResource.errorColor)
          }
          .width('100%')
        }
        .width('100%')
        .key(`stats-${this.updateKey}`)
      } else {
        // 平板/大屏：单行布局
        Row({ space: 12 }) {
          this.StatCard('总任务数', `${this.project.tasks.length}个`, ColorResource.primaryLight, ColorResource.primaryColor)
          this.StatCard('项目总工期', `${this.getTotalDuration()}天`, ColorResource.successLight, ColorResource.successColor)
          this.StatCard('整体完成度', `${this.getOverallCompletion()}%`, ColorResource.warningLight, ColorResource.warningColor)
          this.StatCard('关键任务数', `${this.getCriticalTasksCount()}个`, ColorResource.errorLight, ColorResource.errorColor)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .key(`stats-${this.updateKey}`)
      }

      // 3. 即将到期的任务列表 - 紧凑设计
      Column({ space: 12 }) {
        Row({ space: ThemeConfig.spacingM }) {
          Text('即将到期')
            .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeM : ThemeConfig.fontSizeL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ColorResource.surfaceDeep)
          Text('(未来7天)')
            .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
            .fontColor(ColorResource.surfaceEmphasized)
            .fontWeight(ThemeConfig.fontWeightMedium)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 直接计算即将到期的任务
        if (this.getUpcomingTasks().length > 0) {
          List({ space: ThemeConfig.spacingS }) {
            ForEach(this.getUpcomingTasks(), (task: TaskNode) => {
              ListItem() {
                this.UpcomingTaskCard(task)
              }
            })
          }
          .height('100%')
          .width('100%')
        } else {
          // 没有即将到期的任务 - 紧凑的空状态设计
          Column({ space: ThemeConfig.spacingM }) {
            Column({ space: ThemeConfig.spacingS }) {
              Text('暂无即将到期的任务')
                .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeS : ThemeConfig.fontSizeM)
                .fontColor(ColorResource.surfaceDeep)
                .fontWeight(ThemeConfig.fontWeightBold)
              Text('一切尽在掌握之中！')
                .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                .fontColor(ColorResource.surfaceEmphasized)
                .textAlign(TextAlign.Center)
                .lineHeight(20)
            }
          }
          .width('100%')
          .padding(ThemeConfig.spacingXL)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(ColorResource.transparent)
          .borderRadius(ThemeConfig.radiusLarge)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusLarge })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth))
    .backgroundColor(ColorResource.transparent)
    .backdropBlur(this.showCanvasBackground ? ThemeConfig.backdropBlurXLarge : ThemeConfig.backdropBlurNone)
    .opacity(this.fadeOpacity)
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .translate({ x: 0, y: this.translateY })
    .animation({
      duration: 400,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
  }

  // 构建器：统计卡片 - 紧凑设计
  @Builder
  StatCard(title: string, value: string, bgColor: string | Resource, textColor: string | Resource, icon?: string) {
    Column({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingS, this.screenWidth) }) {
      // 图标 - 增强视觉效果
      if (icon) {
        Text(icon)
          .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeL : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXL, this.screenWidth))
          .fontColor(textColor)
          .margin({ bottom: ThemeConfig.spacingXS })
      }
      
      Text(title)
        .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeXS : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeS, this.screenWidth))
        .fontColor(ColorResource.surfaceEmphasized)
        .fontWeight(ThemeConfig.fontWeightMedium)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(value)
        .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeL : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXXL, this.screenWidth))
        .fontWeight(ThemeConfig.fontWeightBold)
        .fontColor(textColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(this.isFloatingCard ? 70 : (this.isPhone ? 100 : 120))
    .padding(this.isFloatingCard ? 8 : BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth))
    .backgroundColor(this.isFloatingCard ? 'rgba(255, 255, 255, 0.6)' : ColorResource.transparent)
    .borderRadius(this.isFloatingCard ? 8 : ThemeConfig.radiusLarge)
    .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.shadowMedium)
    .border(this.isFloatingCard ? { width: 1, color: 'rgba(255, 255, 255, 0.7)', radius: 8 } : { width: 2, color: bgColor, radius: ThemeConfig.radiusLarge })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .opacity(this.fadeOpacity)
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .translate({ x: 0, y: this.translateY })
    .animation({
      duration: ThemeConfig.animationSlow,
      curve: ThemeConfig.animationEaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
  }

  // 构建器：即将到期的任务卡片 - 紧凑设计
  @Builder
  UpcomingTaskCard(task: TaskNode) {
    Row({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth) }) {
      // 任务信息 - 紧凑设计
      Column({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXS, this.screenWidth) }) {
        Text(task.name)
          .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeS : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeM, this.screenWidth))
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.surfaceDeep)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingS, this.screenWidth) }) {
          Text(`截止: ${task.endDate.toLocaleDateString()}`)
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(ColorResource.surfaceEmphasized)
          if (task.isCritical) {
            Text('关键')
              .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
              .fontColor(ColorResource.errorColor)
              .fontWeight(ThemeConfig.fontWeightMedium)
              .padding({ 
                left: ThemeConfig.spacingXS, 
                right: ThemeConfig.spacingXS, 
                top: 2, 
                bottom: 2 
              })
              .backgroundColor(ColorResource.hoverError)
              .borderRadius(ThemeConfig.radiusSmall)
              .border({ width: 1, color: ColorResource.errorColor, radius: ThemeConfig.radiusSmall })
          }
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth))
    .backgroundColor(this.isFloatingCard ? 'rgba(255, 255, 255, 0.5)' : ColorResource.transparent)
    .borderRadius(this.isFloatingCard ? 6 : ThemeConfig.radiusLarge)
    .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.cardShadow)
    .border(this.isFloatingCard ? { width: 1, color: 'rgba(255, 255, 255, 0.6)', radius: 6 } : { width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusLarge })
  }
}
