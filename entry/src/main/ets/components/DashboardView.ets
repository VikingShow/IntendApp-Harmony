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
import { ThemeConfig } from '../utils/ThemeConfig';
import router from '@ohos.router';
import vibrator from '@ohos.vibrator';

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

  // aboutToAppear 会在组件首次创建和显示时调用
  aboutToAppear() {
    console.log(`[DashboardView] Component appeared for project: ${this.project.name} with ${this.project.tasks.length} tasks`);
    console.log(`[DashboardView] Total duration: ${this.getTotalDuration()} days`);
    console.log(`[DashboardView] Overall completion: ${this.getOverallCompletion()}%`);
    console.log(`[DashboardView] Critical tasks: ${this.getCriticalTasksCount()}`);
    
    // 强制触发更新
    this.updateKey++;
    
    // 触发进入动画
    this.startEnterAnimation();
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
    Column({ space: 20 }) {
      // 1. 项目标题和进入编辑按钮 - 简约设计
      Column({ space: 24 }) {
        Row() {
          Column({ space: 12 }) {
            Text(this.project.name)
              .fontSize(ThemeConfig.fontSizeXXXXXXL)
              .fontWeight(ThemeConfig.fontWeightBold)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(1)
              .fontColor(ThemeConfig.surfaceDeep)
            Text(`项目ID: ${this.project.id}`)
              .fontSize(ThemeConfig.fontSizeL)
              .fontColor(ThemeConfig.surfaceEmphasized)
              .fontWeight(ThemeConfig.fontWeightMedium)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button() {
            Row({ space: ThemeConfig.spacingS }) {
              Text('✏️')
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(Color.White)
              Text('编辑项目')
                .fontSize(ThemeConfig.fontSizeXL)
                .fontColor(Color.White)
                .fontWeight(ThemeConfig.fontWeightMedium)
            }
          }
          .accessibilityLevel('important')
          .height(ThemeConfig.buttonHeightLarge)
          .padding({ left: ThemeConfig.spacingXXL, right: ThemeConfig.spacingXXL })
          .backgroundColor(this.isEditButtonPressed ? ThemeConfig.primaryDark : ThemeConfig.primaryColor)
          .borderRadius(26)
          .shadow(ThemeConfig.shadowMedium)
          // .backdropBlur(ThemeConfig.backdropBlurMedium)
          .border({ 
            width: 2, 
            color: this.isEditButtonPressed ? ThemeConfig.primaryDark : ThemeConfig.primaryUltraLight,
            radius: 26
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
      }
      .width('100%')
      .padding(ThemeConfig.spacingXXL)
      .backgroundColor(ThemeConfig.transparent)
      .borderRadius(ThemeConfig.radiusXXLarge)
      .shadow(ThemeConfig.cardShadow)
      .border({ width: 1, color: ThemeConfig.surfaceNeutral, radius: ThemeConfig.radiusXXLarge })

      // 2. 核心指标统计 - 等高布局
      Row({ space: 16 }) {
        this.StatCard('总任务数', `${this.project.tasks.length}个`, ThemeConfig.primaryLight, ThemeConfig.primaryColor)
        this.StatCard('项目总工期', `${this.getTotalDuration()}天`, ThemeConfig.successLight, ThemeConfig.successColor)
        this.StatCard('整体完成度', `${this.getOverallCompletion()}%`, ThemeConfig.warningLight, ThemeConfig.warningColor)
        this.StatCard('关键任务数', `${this.getCriticalTasksCount()}个`, ThemeConfig.errorLight, ThemeConfig.errorColor)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .key(`stats-${this.updateKey}`)

      // 3. 即将到期的任务列表 - 简约设计
      Column({ space: 20 }) {
        Row({ space: ThemeConfig.spacingL }) {
          Text('即将到期的任务')
            .fontSize(ThemeConfig.fontSizeXXL)
            .fontWeight(ThemeConfig.fontWeightBold)
            .fontColor(ThemeConfig.surfaceDeep)
          Text('(未来7天)')
            .fontSize(ThemeConfig.fontSizeL)
            .fontColor(ThemeConfig.surfaceEmphasized)
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
          // 没有即将到期的任务 - 更友好的空状态设计
          Column({ space: ThemeConfig.spacingXXL }) {
            Column({ space: ThemeConfig.spacingM }) {
              Text('暂无即将到期的任务')
                .fontSize(ThemeConfig.fontSizeXXL)
                .fontColor(ThemeConfig.surfaceDeep)
                .fontWeight(ThemeConfig.fontWeightBold)
              Text('一切尽在掌握之中！')
                .fontSize(ThemeConfig.fontSizeL)
                .fontColor(ThemeConfig.surfaceEmphasized)
                .textAlign(TextAlign.Center)
                .lineHeight(24)
            }
          }
          .width('100%')
          .padding(ThemeConfig.spacingXXXXL)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(ThemeConfig.transparent)
          .borderRadius(ThemeConfig.radiusXLarge)
          .shadow(ThemeConfig.cardShadow)
          .border({ width: 0, color: 'transparent', radius: ThemeConfig.radiusXLarge })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(ThemeConfig.spacingXXXL)
    .backgroundColor(ThemeConfig.transparent)
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

  // 构建器：统计卡片 - 现代化设计，增强视觉吸引力
  @Builder
  StatCard(title: string, value: string, bgColor: string | Resource, textColor: string | Resource, icon?: string) {
    Column({ space: ThemeConfig.spacingM }) {
      // 图标 - 增强视觉效果
      if (icon) {
        Text(icon)
          .fontSize(ThemeConfig.fontSizeXXXXL)
          .fontColor(textColor)
          .margin({ bottom: ThemeConfig.spacingS })
          .shadow({ radius: 2, color: textColor + '30', offsetX: 0, offsetY: 2 })
      }
      
      Text(title)
        .fontSize(ThemeConfig.fontSizeM)
        .fontColor(ThemeConfig.surfaceEmphasized)
        .fontWeight(ThemeConfig.fontWeightMedium)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(value)
        .fontSize(ThemeConfig.fontSizeXXXXL)
        .fontWeight(ThemeConfig.fontWeightBold)
        .fontColor(textColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(160)
    .padding(ThemeConfig.spacingXXL)
    .backgroundColor(ThemeConfig.transparent)
    .borderRadius(ThemeConfig.radiusXLarge)
    .shadow(ThemeConfig.shadowMedium)
    .border({ width: 2, color: bgColor, radius: ThemeConfig.radiusXLarge })
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

  // 构建器：即将到期的任务卡片 - 简约设计
  @Builder
  UpcomingTaskCard(task: TaskNode) {
    Row({ space: ThemeConfig.spacingXL }) {
      // 任务信息 - 简约设计
      Column({ space: ThemeConfig.spacingS }) {
        Text(task.name)
          .fontSize(ThemeConfig.fontSizeXL)
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ThemeConfig.surfaceDeep)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: ThemeConfig.spacingM }) {
          Text(`截止于: ${task.endDate.toLocaleDateString()}`)
            .fontSize(ThemeConfig.fontSizeS)
            .fontColor(ThemeConfig.surfaceEmphasized)
          if (task.isCritical) {
            Text('关键任务')
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ThemeConfig.errorColor)
              .fontWeight(ThemeConfig.fontWeightMedium)
              .padding({ left: ThemeConfig.spacingS, right: ThemeConfig.spacingS, top: ThemeConfig.spacingXS, bottom: ThemeConfig.spacingXS })
              .backgroundColor(ThemeConfig.hoverError)
              .borderRadius(ThemeConfig.radiusSmall)
              .border({ width: 1, color: ThemeConfig.errorColor, radius: ThemeConfig.radiusSmall })
          }
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(ThemeConfig.spacingXXL)
    .backgroundColor(ThemeConfig.transparent)
    .borderRadius(ThemeConfig.radiusXLarge)
    .shadow(ThemeConfig.cardShadow)
    .border({ width: 1, color: ThemeConfig.surfaceNeutral, radius: ThemeConfig.radiusXLarge })
  }
}
