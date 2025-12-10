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

import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { ResponsiveColorConfig } from '../utils/ResponsiveColorConfig';
import router from '@ohos.router';
import vibrator from '@ohos.vibrator';
import { BreakpointSystem, BreakpointConfig } from '../utils/BreakpointSystem';
import { CanvasRenderer, RenderMode } from '../core/canvas/CanvasRenderer';
import { StorageService } from '../services/StorageService';
import { CalendarService } from '../services/CalendarService';
import { PromptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';


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
  /** 是否为深色模式 */
  @Prop isDarkMode: boolean = false;
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
  @State private taskFilter: string = 'ALL'; // ALL | CRITICAL | THIS_WEEK | OVERDUE
  @State private taskSort: string = 'START'; // START | END | PROGRESS
  @State private taskViewMode: string = 'LIST'; // LIST | TIMELINE
  /** 是否为浮动卡片模式（手机端） */
  @Prop isFloatingCard: boolean = false;
  /** 画布渲染器（使用单例避免重复创建）*/
  private canvasRenderer: CanvasRenderer | null = null;
  /** Canvas是否已就绪 */
  private canvasReady: boolean = false;
  private storageService: StorageService | null = null;
  private calendarService: CalendarService = CalendarService.getInstance();
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  /** 列表/时间轴的重建键，用于切换视图或筛选时回到顶部 */
  @State private allTasksScrollKey: number = 0;

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
    console.log(`[DashboardView] Canvas state: offset=(${this.project.canvasOffsetX}, ${this.project.canvasOffsetY}), zoom=${this.project.zoomScale}`);
    console.log(`[DashboardView] Total duration: ${this.getTotalDuration()} days`);
    console.log(`[DashboardView] Overall completion: ${this.getOverallCompletion()}%`);
    console.log(`[DashboardView] Critical tasks: ${this.getCriticalTasksCount()}`);

    // 强制触发更新
    this.updateKey++;

    // 触发进入动画
    this.startEnterAnimation();

    // 重新渲染画布背景（仅在Canvas已就绪时）
    if (this.canvasReady && this.showCanvasBackground && this.project.tasks.length > 0) {
      console.log('[DashboardView] Re-rendering canvas background due to project update');
      // 延迟一帧以确保画布准备就绪
      setTimeout(() => {
        this.renderCanvasBackground();
      }, 50);
    }
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

  // 获取所有任务（按开始时间排序），用于 Dashboard 中的任务总览列表
  private getAllTasksSorted(): TaskNode[] {
    if (!this.project || this.project.tasks.length === 0) {
      return [];
    }
    const now = new Date();
    let tasks = this.project.tasks.slice();

    // 根据筛选条件过滤任务
    if (this.taskFilter === 'CRITICAL') {
      tasks = tasks.filter(task => task.isCritical);
    } else if (this.taskFilter === 'THIS_WEEK') {
      tasks = tasks.filter(task => this.isTaskInThisWeek(task));
    } else if (this.taskFilter === 'OVERDUE') {
      tasks = tasks.filter(task => task.endDate < now && !this.isTaskCompleted(task));
    } else if (this.taskFilter === 'HEALTH_NORMAL') {
      tasks = tasks.filter(task => this.getTaskHealthLabel(task) === '正常');
    } else if (this.taskFilter === 'HEALTH_RISK') {
      tasks = tasks.filter(task => this.getTaskHealthLabel(task) === '有风险');
    } else if (this.taskFilter === 'HEALTH_LATE') {
      tasks = tasks.filter(task => this.getTaskHealthLabel(task) === '严重滞后');
    } else if (this.taskFilter === 'NO_CHECKLIST') {
      tasks = tasks.filter(task => !task.checklist || task.checklist.length === 0);
    } else if (this.taskFilter === 'OPEN_CHECKLIST') {
      tasks = tasks.filter(task => task.checklist && task.checklist.some(item => !item.isCompleted));
    }

    // 根据排序方式排序任务
    if (this.taskSort === 'END') {
      tasks.sort((a, b) => a.endDate.getTime() - b.endDate.getTime());
    } else if (this.taskSort === 'PROGRESS') {
      tasks.sort((a, b) => this.getTaskCompletionPercent(b) - this.getTaskCompletionPercent(a));
    } else {
      // 默认按开始时间排序
      tasks.sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
    }

    console.log(`[DashboardView] Project "${this.project.name}" all tasks filtered=${this.taskFilter}, sort=${this.taskSort}, count=${tasks.length}`);
    return tasks;
  }

  // 当前视图下所有任务数量（受筛选和排序影响）
  private getAllTasksCount(): number {
    return this.getAllTasksSorted().length;
  }

  // 在点击健康/遗漏标签时切换筛选；再次点击同一标签则清除筛选
  private toggleTaskFilter(filter: string): void {
    if (this.taskFilter === filter) {
      this.taskFilter = 'ALL';
    } else {
      this.taskFilter = filter;
    }
  }

  // 带 Toast 提示的筛选切换（用于任务健康）
  private handleHealthFilterClick(filter: string, label: string): void {
    const isSame: boolean = this.taskFilter === filter;
    this.toggleTaskFilter(filter);
    this.taskViewMode = 'LIST';
    this.resetAllTasksScroll();
    const message: string = isSame ? '已恢复显示全部任务' : `已切换到“${label}”视图`;
    this.promptAction.showToast({
      message,
      duration: 2000
    });
  }

  // 带 Toast 提示的筛选切换（用于遗漏提醒）
  private handleOmissionFilterClick(filter: string, label: string): void {
    const isSame: boolean = this.taskFilter === filter;
    this.toggleTaskFilter(filter);
    this.taskViewMode = 'LIST';
    this.resetAllTasksScroll();
    const message: string = isSame ? '已恢复显示全部任务' : `已切换到“${label}”视图`;
    this.promptAction.showToast({
      message,
      duration: 2000
    });
  }

  // 当前筛选状态标签文本
  private getCurrentFilterLabel(): string {
    switch (this.taskFilter) {
      case 'CRITICAL':
        return '当前视图：关键任务';
      case 'THIS_WEEK':
        return '当前视图：本周到期任务';
      case 'OVERDUE':
        return '当前视图：已逾期任务';
      case 'HEALTH_NORMAL':
        return '当前视图：健康任务';
      case 'HEALTH_RISK':
        return '当前视图：有风险任务';
      case 'HEALTH_LATE':
        return '当前视图：严重滞后任务';
      case 'NO_CHECKLIST':
        return '当前视图：未拆解任务';
      case 'OPEN_CHECKLIST':
        return '当前视图：仍有未完成检查项的任务';
      default:
        return '';
    }
  }

  // 计算单个任务的完成度（基于 checklist）
  private getTaskCompletionPercent(task: TaskNode): number {
    if (!task || !task.checklist || task.checklist.length === 0) {
      return 0;
    }
    const completed = task.checklist.filter(item => item.isCompleted).length;
    return Math.round((completed / task.checklist.length) * 100);
  }

  // 判断任务是否已完成（基于 checklist）
  private isTaskCompleted(task: TaskNode): boolean {
    if (!task || !task.checklist || task.checklist.length === 0) {
      return false;
    }
    return task.checklist.every(item => item.isCompleted);
  }

  // 获取已完成任务数量
  private getCompletedTasksCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    const count = this.project.tasks.filter(task => this.isTaskCompleted(task)).length;
    console.log(`[DashboardView] Project "${this.project.name}" completed tasks: ${count}`);
    return count;
  }

  // 获取未完成任务数量
  private getPendingTasksCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    const pending = this.project.tasks.length - this.getCompletedTasksCount();
    return Math.max(0, pending);
  }

  // 判断任务是否在本周到期（按结束时间）
  private isTaskInThisWeek(task: TaskNode): boolean {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const dayOfWeek = today.getDay(); // 0 (Sunday) - 6 (Saturday)
    const diffToMonday = (dayOfWeek + 6) % 7;
    const monday = new Date(today.getTime() - diffToMonday * 24 * 60 * 60 * 1000);
    const nextMonday = new Date(monday.getTime() + 7 * 24 * 60 * 60 * 1000);
    return task.endDate >= monday && task.endDate < nextMonday;
  }

  // 获取本周到期任务列表
  private getTasksThisWeek(): TaskNode[] {
    if (!this.project || this.project.tasks.length === 0) {
      return [];
    }
    const tasks = this.project.tasks.filter(task => this.isTaskInThisWeek(task));
    console.log(`[DashboardView] Project "${this.project.name}" tasks due this week: ${tasks.length}`);
    return tasks;
  }

  // 获取本周到期任务数量
  private getTasksThisWeekCount(): number {
    return this.getTasksThisWeek().length;
  }

  // 获取已逾期任务数量（截止时间已过且未完成）
  private getOverdueTasksCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    const now = new Date();
    const overdue = this.project.tasks.filter(task => task.endDate < now && !this.isTaskCompleted(task)).length;
    console.log(`[DashboardView] Project "${this.project.name}" overdue tasks: ${overdue}`);
    return overdue;
  }

  // 计算项目时间进度（0-100%，基于最早开始和最晚结束时间）
  private getProjectTimeProgress(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    const now = Date.now();
    const startDates = this.project.tasks.map(t => t.startDate.getTime());
    const endDates = this.project.tasks.map(t => t.endDate.getTime());
    const minStart = Math.min(...startDates);
    const maxEnd = Math.max(...endDates);
    if (maxEnd <= minStart) {
      return now >= maxEnd ? 100 : 0;
    }
    const raw = Math.round(((now - minStart) / (maxEnd - minStart)) * 100);
    const clamped = Math.max(0, Math.min(100, raw));
    console.log(`[DashboardView] Project "${this.project.name}" time progress: ${clamped}%`);
    return clamped;
  }

  // 任务列表/时间轴的统一滚动高度，保证两种视图体验一致
  private getAllTasksScrollHeight(): number {
    // 时间轴视图仍然使用统一高度，列表视图已改为使用 layoutWeight + Scroll 自适应剩余空间
    const taskCount: number = this.getAllTasksSorted().length;
    if (taskCount <= 0) {
      return 0;
    }

    const spacing: number = ThemeConfig.spacingS;
    const baseItemHeight: number = this.isFloatingCard ? 32 : (this.isPhone ? 34 : 36);
    const maxVisibleItems: number = this.isPhone ? 4 : 5;
    const visibleItems: number = Math.min(taskCount, maxVisibleItems);
    const contentHeight: number = visibleItems * baseItemHeight + (visibleItems - 1) * spacing;
    const fallbackTimeline: number = this.isFloatingCard ? 320 : (this.isPhone ? 380 : 520);
    return Math.min(contentHeight, fallbackTimeline);
  }

  // 切换视图或筛选时重置滚动位置，避免停留在底部导致看不到列表
  private resetAllTasksScroll(): void {
    try {
      this.allTasksScrollKey++;
    } catch (error) {
      console.warn('[DashboardView] Failed to reset task scroller', error);
    }
  }

  // 计算任务时间进度（0-100%，用于健康状态判断）
  private getTaskTimeProgressPercent(task: TaskNode): number {
    const now = Date.now();
    const start = task.startDate.getTime();
    const end = task.endDate.getTime();
    if (end <= start) {
      return now >= end ? 100 : 0;
    }
    const raw = Math.round(((now - start) / (end - start)) * 100);
    return Math.max(0, Math.min(100, raw));
  }

  private getScheduleDiff(): number {
    const completion = this.getOverallCompletion();
    const timeProgress = this.getProjectTimeProgress();
    return completion - timeProgress;
  }

  private getScheduleStatusLabel(): string {
    const diff = this.getScheduleDiff();
    if (diff <= -20) {
      return '进度严重滞后，请检查关键任务';
    }
    if (diff <= -10) {
      return `进度落后 ${Math.abs(diff)}%，需要加快进度`;
    }
    if (diff >= 15) {
      return `进度明显领先 ${diff}%`;
    }
    if (diff >= 5) {
      return `进度略有领先 ${diff}%`;
    }
    return '进度基本正常';
  }

  private getScheduleStatusColor(): string | Resource {
    const diff = this.getScheduleDiff();
    if (diff <= -20) {
      return ColorResource.errorColor;
    }
    if (diff <= -10) {
      return ColorResource.warningColor;
    }
    if (diff >= 10) {
      return ColorResource.successColor;
    }
    return ColorResource.surfaceEmphasized;
  }

  // 获取任务健康状态标签
  private getTaskHealthLabel(task: TaskNode): string {
    const completion = this.getTaskCompletionPercent(task);
    const timeProgress = this.getTaskTimeProgressPercent(task);
    const diff = completion - timeProgress;
    if (diff >= -10) {
      return '正常';
    }
    if (diff >= -30) {
      return '有风险';
    }
    return '严重滞后';
  }

  // 获取任务健康状态文本颜色
  private getTaskHealthTextColor(task: TaskNode): string | Resource {
    const label = this.getTaskHealthLabel(task);
    if (label === '正常') {
      return ColorResource.successColor;
    }
    if (label === '有风险') {
      return ColorResource.warningColor;
    }
    return ColorResource.errorColor;
  }

  // 获取任务健康状态背景色
  private getTaskHealthBackgroundColor(task: TaskNode): string | Resource {
    const label = this.getTaskHealthLabel(task);
    if (label === '正常') {
      return ThemeConfig.hoverSuccessLight;
    }
    if (label === '有风险') {
      return ThemeConfig.hoverWarningLight;
    }
    return ThemeConfig.hoverErrorLight;
  }

  private getHealthyTasksCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    return this.project.tasks.filter(task => this.getTaskHealthLabel(task) === '正常').length;
  }

  private getRiskTasksCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    return this.project.tasks.filter(task => this.getTaskHealthLabel(task) === '有风险').length;
  }

  private getLateTasksCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    return this.project.tasks.filter(task => this.getTaskHealthLabel(task) === '严重滞后').length;
  }

  // 统计尚未拆解（没有检查项）的任务数量
  private getTasksWithoutChecklistCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    return this.project.tasks.filter(task => !task.checklist || task.checklist.length === 0).length;
  }

  // 统计所有未完成的检查项数量
  private getOpenChecklistItemsCount(): number {
    if (!this.project || this.project.tasks.length === 0) {
      return 0;
    }
    return this.project.tasks.reduce((sum, task) => {
      if (!task.checklist || task.checklist.length === 0) {
        return sum;
      }
      const openItems = task.checklist.filter(item => !item.isCompleted).length;
      return sum + openItems;
    }, 0);
  }

  // 获取检查项进度文本，例如 "3/5" 或 "未拆解"
  private getChecklistProgressText(task: TaskNode): string {
    if (!task.checklist || task.checklist.length === 0) {
      return '未拆解';
    }
    const total = task.checklist.length;
    const completed = task.checklist.filter(item => item.isCompleted).length;
    return `${completed}/${total}`;
  }

  // 获取第一个需要补充检查项的任务（未拆解优先，其次是有未完成检查项）
  private getFirstTaskNeedingChecklist(): TaskNode | null {
    if (!this.project || !this.project.tasks || this.project.tasks.length === 0) {
      return null;
    }
    const noChecklist = this.project.tasks.find(task => !task.checklist || task.checklist.length === 0);
    if (noChecklist) {
      return noChecklist;
    }
    const openChecklist =
      this.project.tasks.find(task => task.checklist && task.checklist.some(item => !item.isCompleted));
    return openChecklist || null;
  }

  // 从 Dashboard 直接跳转到第一个需要补充检查项的任务编辑页
  private goToFirstTaskNeedingDetails(): void {
    const target = this.getFirstTaskNeedingChecklist();
    if (!target) {
      // 没有需要补充的任务时给出友好提示，避免用户误以为点击无效
      this.promptAction.showToast({
        message: '当前没有需要补充检查项的任务',
        duration: 2000
      });
      return;
    }
    this.handleOpenTaskInEditor(target);
  }

  // 获取任务结束日期标签，用于时间轴视图
  private getTaskEndDateLabel(task: TaskNode): string {
    const end = task.endDate;
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
    const dayAfterTomorrow = new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000);

    if (end >= today && end < tomorrow) {
      return '今天';
    }
    if (end >= tomorrow && end < dayAfterTomorrow) {
      return '明天';
    }
    return end.toLocaleDateString();
  }

  // 今日/本周重点任务（优先：今天到期 -> 严重滞后 -> 有风险），最多3条
  private getFocusTasks(): TaskNode[] {
    if (!this.project || this.project.tasks.length === 0) {
      return [];
    }
    const tasks = this.project.tasks.slice();
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);

    const result: TaskNode[] = [];
    const pushIfNotExists = (task: TaskNode): void => {
      if (!result.some(t => t.id === task.id)) {
        result.push(task);
      }
    };

    // 今天到期的任务
    tasks
      .filter(task => task.endDate >= today && task.endDate < tomorrow)
      .sort((a, b) => a.endDate.getTime() - b.endDate.getTime())
      .forEach(task => pushIfNotExists(task));

    // 严重滞后任务
    tasks
      .filter(task => this.getTaskHealthLabel(task) === '严重滞后')
      .sort((a, b) => a.endDate.getTime() - b.endDate.getTime())
      .forEach(task => pushIfNotExists(task));

    // 有风险任务
    tasks
      .filter(task => this.getTaskHealthLabel(task) === '有风险')
      .sort((a, b) => a.endDate.getTime() - b.endDate.getTime())
      .forEach(task => pushIfNotExists(task));

    return result.slice(0, 3);
  }

  private async handleMarkTaskCompleted(task: TaskNode) {
    if (!task || !task.checklist || task.checklist.length === 0) {
      this.promptAction.showToast({ message: '请先在编辑页为任务添加检查项', duration: 2000 });
      return;
    }
    const target = this.project.tasks.find(t => t.id === task.id);
    if (!target) {
      return;
    }
    target.checklist = target.checklist.map((item: ChecklistItem): ChecklistItem => {
      const updatedItem: ChecklistItem = {
        id: item.id,
        text: item.text,
        isCompleted: true
      };
      return updatedItem;
    });
    try {
      if (!this.storageService) {
        const hostContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
        this.storageService = StorageService.getInstance(hostContext.filesDir);
      }
      if (this.storageService) {
        await this.storageService.saveProject(this.project);
      }
      this.updateKey++;
      this.promptAction.showToast({ message: '任务已标记为完成', duration: 2000 });
    } catch (error) {
      console.error('[DashboardView] handleMarkTaskCompleted error:', error);
      this.promptAction.showToast({ message: '标记完成失败', duration: 2000 });
    }
  }

  private async handleAddTaskReminder(task: TaskNode) {
    try {
      const eventId = await this.calendarService.addTaskReminder(task);
      if (eventId !== null) {
        this.promptAction.showToast({ message: '已在日历中创建日程提醒', duration: 2000 });
      } else {
        this.promptAction.showToast({ message: '创建日程失败', duration: 2000 });
      }
    } catch (error) {
      console.error('[DashboardView] handleAddTaskReminder error:', error);
      this.promptAction.showToast({ message: '创建日程失败', duration: 2000 });
    }
  }

  private handleOpenTaskInEditor(task: TaskNode) {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/Index',
      params: {
        projectId: this.project.id,
        selectedTaskId: task.id,
        isPhone: this.isPhone,
        renderMode: this.isPhone ? 'COMPACT' : 'NORMAL'
      },
      animation: {
        type: 'fade',
        duration: 300
      }
    } as router.RouterOptions);
  }

  // 获取Canvas上下文（单例模式）
  private getCanvasContext(): CanvasRenderingContext2D {
    if (!this.canvasRenderer) {
      console.log('[DashboardView] Creating new canvas renderer');
      this.canvasRenderer = new CanvasRenderer();
    }
    return this.canvasRenderer.getContext();
  }

  // 渲染画布背景（与编辑页完全一致的画布状态）
  private renderCanvasBackground() {
    if (!this.showCanvasBackground || this.project.tasks.length === 0 || !this.canvasReady) {
      return;
    }

    // 确保渲染器已初始化
    if (!this.canvasRenderer) {
      console.warn('[DashboardView] Canvas renderer not initialized');
      return;
    }

    this.canvasRenderer.setDarkMode(this.isDarkMode);
    this.canvasRenderer.render(this.project, {
      canvasOffsetX: this.project.canvasOffsetX || 0,
      canvasOffsetY: this.project.canvasOffsetY || 0,
      zoomScale: this.project.zoomScale || 1.0, // ✅ 使用相同的缩放比例（不再缩小50%）
      isConnecting: false,
      connectingFromTaskId: null,
      selectedTaskId: null,
      renderMode: this.isPhone ? RenderMode.COMPACT : RenderMode.NORMAL // 根据设备类型选择
    });

    console.log(`[DashboardView] Canvas background rendered - Mode: ${this.isPhone ? 'COMPACT' :
      'NORMAL'}, Zoom: ${this.project.zoomScale || 1.0}, Offset: (${this.project.canvasOffsetX ||
      0}, ${this.project.canvasOffsetY || 0})`);
  }

  // 计算用于“四边进度框”的归一化进度（0.0 ~ 1.0）
  private getFrameProgress(): number {
    const completion: number = this.getOverallCompletion();
    const clampedCompletion: number = Math.max(0, Math.min(100, completion));
    return clampedCompletion / 100;
  }

  private getFrameTopWidth(): string {
    const progress: number = this.getFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, progress / segmentSize);
    return `${ratio * 100}%`;
  }

  private getFrameRightHeight(): string {
    const progress: number = this.getFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, Math.max(0, (progress - segmentSize) / segmentSize));
    return `${ratio * 100}%`;
  }

  private getFrameBottomWidth(): string {
    const progress: number = this.getFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, Math.max(0, (progress - 2 * segmentSize) / segmentSize));
    return `${ratio * 100}%`;
  }

  private getFrameLeftHeight(): string {
    const progress: number = this.getFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, Math.max(0, (progress - 3 * segmentSize) / segmentSize));
    return `${ratio * 100}%`;
  }

  private getFrameCornerRadius(): number {
    // 与统计卡片的圆角策略保持一致
    return this.isFloatingCard ? 8 : ThemeConfig.radiusLarge;
  }

  private getTimeFrameProgress(): number {
    const completion: number = this.getProjectTimeProgress();
    const clampedCompletion: number = Math.max(0, Math.min(100, completion));
    return clampedCompletion / 100;
  }

  private getTimeFrameTopWidth(): string {
    const progress: number = this.getTimeFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, progress / segmentSize);
    return `${ratio * 100}%`;
  }

  private getTimeFrameRightHeight(): string {
    const progress: number = this.getTimeFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, Math.max(0, (progress - segmentSize) / segmentSize));
    return `${ratio * 100}%`;
  }

  private getTimeFrameBottomWidth(): string {
    const progress: number = this.getTimeFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, Math.max(0, (progress - 2 * segmentSize) / segmentSize));
    return `${ratio * 100}%`;
  }

  private getTimeFrameLeftHeight(): string {
    const progress: number = this.getTimeFrameProgress();
    const segmentSize: number = 0.25;
    const ratio: number = Math.min(1, Math.max(0, (progress - 3 * segmentSize) / segmentSize));
    return `${ratio * 100}%`;
  }

  // 手机 / 浮动卡片模式下，用“四条边”来表达项目整体完成度的进度框
  @Builder
  ProgressFrameBorder() {
    Stack() {
      // 外层：整体完成度进度（任务进度）
      Column({ space: 0 }) {
        // 顶部边：从左到右填充
        Row() {
          Row()
            .width(this.getFrameTopWidth())
            .height('100%')
            .backgroundColor(ColorResource.taskProgress)
            .borderRadius(this.getFrameCornerRadius());
        }
        .width('100%')
        .height(2)
        .backgroundColor(ColorResource.surfaceNeutral)
        .borderRadius(ThemeConfig.radiusLarge);

        // 中间部分：左右两条竖边
        Row() {
          // 左侧边：从下往上填充
          Column() {
            Blank()
              .layoutWeight(1);
            Column()
              .width('100%')
              .height(this.getFrameLeftHeight())
              .backgroundColor(ColorResource.taskProgress);
          }
          .width(2)
          .height('100%')
          .backgroundColor(ColorResource.surfaceNeutral)
          .borderRadius(this.getFrameCornerRadius());

          Blank()
            .layoutWeight(1);

          // 右侧边：从上往下填充
          Column() {
            Column()
              .width('100%')
              .height(this.getFrameRightHeight())
              .backgroundColor(ColorResource.taskProgress);
            Blank()
              .layoutWeight(1);
          }
          .width(2)
          .height('100%')
          .backgroundColor(ColorResource.surfaceNeutral)
          .borderRadius(this.getFrameCornerRadius());
        }
        .width('100%')
        .layoutWeight(1);

        // 底部边：从右到左填充
        Row() {
          Blank()
            .layoutWeight(1);
          Row()
            .width(this.getFrameBottomWidth())
            .height('100%')
            .backgroundColor(ColorResource.taskProgress)
            .borderRadius(this.getFrameCornerRadius());
        }
        .width('100%')
        .height(2)
        .backgroundColor(ColorResource.surfaceNeutral)
        .borderRadius(this.getFrameCornerRadius());
      }
      .width('100%')
      .height('100%');

      // 内层：时间进度（比外层略内缩）
      Column({ space: 0 }) {
        // 顶部边：从左到右填充
        Row() {
          Row()
            .width(this.getTimeFrameTopWidth())
            .height('100%')
            .backgroundColor(ColorResource.infoColor)
            .borderRadius(this.getFrameCornerRadius());
        }
        .width('100%')
        .height(2)
            .backgroundColor(Color.Transparent);

        // 中间部分：左右两条竖边
        Row() {
          // 左侧边：从下往上填充
          Column() {
            Blank()
              .layoutWeight(1);
            Column()
              .width('100%')
              .height(this.getTimeFrameLeftHeight())
              .backgroundColor(ColorResource.infoColor);
          }
          .width(2)
          .height('100%')
          .backgroundColor(Color.Transparent);

          Blank()
            .layoutWeight(1);

          // 右侧边：从上往下填充
          Column() {
            Column()
              .width('100%')
              .height(this.getTimeFrameRightHeight())
              .backgroundColor(ColorResource.infoColor);
            Blank()
              .layoutWeight(1);
          }
          .width(2)
          .height('100%')
            .backgroundColor(Color.Transparent);
        }
        .width('100%')
        .layoutWeight(1);

        // 底部边：从右到左填充
        Row() {
          Blank()
            .layoutWeight(1);
          Row()
            .width(this.getTimeFrameBottomWidth())
            .height('100%')
            .backgroundColor(ColorResource.infoColor)
            .borderRadius(this.getFrameCornerRadius());
        }
        .width('100%')
        .height(2)
        .backgroundColor(Color.Transparent);
      }
      .width('100%')
      .height('100%')
      .padding({ left: 5, right: 5, top: 5, bottom: 5 });
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.getFrameCornerRadius())
    .clip(true);
  }

  build() {
    Column({ space: BreakpointSystem.getResponsiveSpacing(10, this.screenWidth) }) {
      // 1. 项目标题和进入编辑按钮 - 紧凑单行布局（大屏） / 手机与浮动卡片共用标题区域
      Column({ space: BreakpointSystem.getResponsiveSpacing(6, this.screenWidth) }) {
        if (!this.isFloatingCard && !this.isPhone) {
          Row({ space: ThemeConfig.spacingS }) {
            // 左侧：项目名称 + ID 同行展示
            Row({ space: ThemeConfig.spacingS }) {
              Text(this.project.name)
                .fontSize(BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXXL, this.screenWidth))
                .fontWeight(ThemeConfig.fontWeightBold)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .maxLines(1)
                .fontColor(ColorResource.surfaceDeep)

              Text(`ID: ${this.project.id}`)
                .fontSize(BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeS, this.screenWidth))
                .fontColor(ColorResource.surfaceEmphasized)
                .fontWeight(ThemeConfig.fontWeightMedium)
                .opacity(0.9)
            }
            .layoutWeight(1)
            .alignItems(VerticalAlign.Center)

            // 右侧：编辑按钮（统一为圆形按钮样式）
            Button() {
              Image($r('app.media.ic_edit'))
                .width(18)
                .height(18)
            }
            .accessibilityLevel('important')
            .width(40)
            .height(40)
            .type(ButtonType.Circle)
            .backgroundColor(this.isEditButtonPressed ? ColorResource.primaryDark : ColorResource.primaryColor)
            .borderRadius(20)
            .shadow(ThemeConfig.shadowMedium)
            .border({
              width: 2,
              color: this.isEditButtonPressed ? ColorResource.primaryDark : ColorResource.primaryUltraLight,
              radius: 20
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
                params: {
                  projectId: this.project.id,
                  // 传递当前的renderMode，避免Index页面切换模式导致闪烁
                  isPhone: this.isPhone,
                  renderMode: this.isPhone ? 'COMPACT' : 'NORMAL'
                },
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
            // 浮动卡片模式或手机端：项目名称与 ID 被进度方框包裹
            Stack() {
              // 背景：四边进度框
              if (this.project.tasks.length > 0) {
                this.ProgressFrameBorder();
              }

              // 前景：标题文本
              Column({ space: ThemeConfig.spacingXS }) {
                Text(this.project.name)
                  .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeL :
                    (this.isPhone ? ThemeConfig.fontSizeXXL :
                    BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXXL, this.screenWidth)))
                  .fontWeight(ThemeConfig.fontWeightBold)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .maxLines(2)
                  .fontColor(ColorResource.surfaceDeep)
                  .textAlign(TextAlign.Center)

                Text(`ID: ${this.project.id}`)
                  .fontSize(this.isFloatingCard ? 10 : ThemeConfig.fontSizeXS)
                  .fontColor(ColorResource.surfaceEmphasized)
                  .fontWeight(ThemeConfig.fontWeightMedium)
                  .opacity(0.8)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .height('100%')
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .padding({
                left: ThemeConfig.spacingM,
                right: ThemeConfig.spacingM,
                top: ThemeConfig.spacingS,
                bottom: ThemeConfig.spacingS
              })
            }
            .width('100%')
            .height(72)
          }
      }
      .width('100%')
      // 非浮动卡片模式下，进一步减少上下留白，使标题区域更紧凑
      .padding(this.isFloatingCard ? {
        left: 16,
        right: 16,
        top: 10,
        bottom: 10
      } : {
        left: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth),
        right: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingL, this.screenWidth),
        top: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingS, this.screenWidth),
        bottom: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXS, this.screenWidth)
      })
      .backgroundColor(this.isFloatingCard ? Color.Transparent : ColorResource.transparent)
      .borderRadius(this.isFloatingCard ? 0 : ThemeConfig.radiusLarge)
      .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.cardShadow)
      .border(this.isFloatingCard ? { width: 0 } : {
        width: 1,
        color: (this.isPhone && this.project.tasks.length > 0)
          ? this.getScheduleStatusColor()
          : ColorResource.surfaceNeutral,
        radius: ThemeConfig.radiusLarge
      })

        // 2. 核心指标统计 - 响应式布局
          if (this.isPhone || this.isFloatingCard) {
            // 手机端 / 浮动卡片：6 个指标拆成两页，每页展示 3 个，自动轮播
            Swiper() {
              // 第 1 页：规模与时间
              Row({ space: 6 }) {
                this.StatCard('总任务数', `${this.project.tasks.length} 个`, ColorResource.primaryLight,
                  ColorResource.primaryColor)
                this.StatCard('本周到期', `${this.getTasksThisWeekCount()} 个`, ColorResource.infoLight,
                  ColorResource.infoColor)
                this.StatCard('整体完成度', `${this.getOverallCompletion()}%`, ColorResource.warningLight,
                  ColorResource.warningColor)
              }

              // 第 2 页：风险与关键程度
              Row({ space: 6 }) {
                this.StatCard('已逾期任务', `${this.getOverdueTasksCount()} 个`, ColorResource.errorLight,
                  ColorResource.errorColor)
                this.StatCard('已完成任务', `${this.getCompletedTasksCount()} 个`, ColorResource.successLight,
                  ColorResource.successColor)
                this.StatCard('关键任务', `${this.getCriticalTasksCount()} 个`, ColorResource.infoLight,
                  ColorResource.infoColor)
              }
            }
            .width('100%')
            .height(130)
            .autoPlay(true)
            .interval(3500)
            .loop(true)
            .key(`stats-${this.updateKey}`)
          } else {
          // 平板/大屏：单行展示更多统计项
          Row({ space: 6 }) {
            this.StatCard('总任务数', `${this.project.tasks.length} 个`, ColorResource.primaryLight,
              ColorResource.primaryColor)
            this.StatCard('本周到期', `${this.getTasksThisWeekCount()} 个`, ColorResource.infoLight,
              ColorResource.infoColor)
            this.StatCard('整体完成度', `${this.getOverallCompletion()}%`, ColorResource.warningLight,
              ColorResource.warningColor)
            this.StatCard('已逾期任务', `${this.getOverdueTasksCount()} 个`, ColorResource.errorLight,
              ColorResource.errorColor)
            this.StatCard('已完成任务', `${this.getCompletedTasksCount()} 个`, ColorResource.successLight,
              ColorResource.successColor)
            this.StatCard('关键任务', `${this.getCriticalTasksCount()} 个`, ColorResource.infoLight,
              ColorResource.infoColor)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .key(`stats-${this.updateKey}`)
        }
      // 2. 统计卡片之后，项目进度条（仅平板 / 大屏完整视图展示；
      // 手机端和浮动卡片改为通过标题区域外边框体现进度）
      if (!this.isPhone && !this.isFloatingCard && this.project.tasks.length > 0) {
        Column({ space: ThemeConfig.spacingXS }) {
          Row({ space: ThemeConfig.spacingS }) {
            // 左侧：标题
            Text('项目进度')
              .fontSize(this.isPhone ? ThemeConfig.fontSizeM : ThemeConfig.fontSizeM)
              .fontWeight(ThemeConfig.fontWeightBold)
              .fontColor(ColorResource.surfaceDeep)

            // 中间：图例（占据中间空间）
            Row({ space: ThemeConfig.spacingM }) {
              // 完成度图例
              Row({ space: 4 }) {
                Text('●')
                  .fontSize(10)
                  .fontColor(ColorResource.taskProgress)
                Text(`完成度 ${this.getOverallCompletion()}%`)
                  .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.surfaceEmphasized)
              }
              .alignItems(VerticalAlign.Center)

              // 时间进度图例
              Row({ space: 4 }) {
                Text('●')
                  .fontSize(10)
                  .fontColor(ColorResource.infoColor)
                Text(`时间进度 ${this.getProjectTimeProgress()}%`)
                  .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                  .fontColor(ColorResource.surfaceEmphasized)
              }
              .alignItems(VerticalAlign.Center)

              Text(`工期 ${this.getTotalDuration()} 天`)
                .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                .fontColor(ColorResource.surfaceEmphasized)
            }
            .layoutWeight(1) // 占满中间，把状态挤到右侧
            .alignItems(VerticalAlign.Center)

            // 右侧：整体状态（领先 / 落后 / 正常）
            Text(this.getScheduleStatusLabel())
              .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
              .fontColor(this.getScheduleStatusColor())
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 完成度进度条
          Row() {
            Row()
              .width(`${this.getOverallCompletion()}%`)
              .height('100%')
              .backgroundColor(ColorResource.taskProgress)
              .borderRadius(3)
          }
          .width('100%')
          .height(6)
          .backgroundColor(ColorResource.surfaceNeutral)
          .borderRadius(3)

          // 时间进度进度条
          Row() {
            Row()
              .width(`${this.getProjectTimeProgress()}%`)
              .height('100%')
              .backgroundColor(ColorResource.infoColor)
              .borderRadius(3)
          }
          .width('100%')
          .height(6)
          .backgroundColor(ColorResource.surfaceNeutral)
          .borderRadius(3)

            // 任务健康与遗漏提醒：帮助用户实现「一思不漏」
            // 手机版和浮动卡片为避免信息过载暂时隐藏，仅在大屏完整视图显示
            if (!this.isPhone && !this.isFloatingCard && this.project.tasks.length > 0) {
            Row({ space: ThemeConfig.spacingXL }) {
              // 左侧：任务健康
              Column({ space: ThemeConfig.spacingXS }) {
                Row({ space: ThemeConfig.spacingS }) {
                  Text('任务健康')
                    .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                    .fontWeight(ThemeConfig.fontWeightMedium)
                    .fontColor(ColorResource.surfaceDeep)

                  Row({ space: ThemeConfig.spacingS }) {
                    // 正常
                    Row({ space: 4 }) {
                      Text('●')
                        .fontSize(10)
                        .fontColor(ColorResource.successColor)
                      Text(`正常 ${this.getHealthyTasksCount()} 个`)
                        .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                        .fontColor(ColorResource.surfaceEmphasized)
                        .onClick(() => {
                          this.handleHealthFilterClick('HEALTH_NORMAL', '健康任务');
                        })
                    }
                    .alignItems(VerticalAlign.Center)

                    // 有风险
                    Row({ space: 4 }) {
                      Text('●')
                        .fontSize(10)
                        .fontColor(ColorResource.warningColor)
                      Text(this.getRiskTasksCount() > 0 ? `有风险 ${this.getRiskTasksCount()} 个` : '有风险 0 个（很好）')
                        .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                        .fontColor(this.getRiskTasksCount() > 0 ? ColorResource.surfaceEmphasized : ColorResource.successColor)
                        .onClick(() => {
                          this.handleHealthFilterClick('HEALTH_RISK', '有风险任务');
                        })
                    }
                    .alignItems(VerticalAlign.Center)

                    // 严重滞后
                    Row({ space: 4 }) {
                      Text('●')
                        .fontSize(10)
                        .fontColor(ColorResource.errorColor)
                      Text(this.getLateTasksCount() > 0 ? `严重滞后 ${this.getLateTasksCount()} 个` : '严重滞后 0 个（很好）')
                        .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                        .fontColor(this.getLateTasksCount() > 0 ? ColorResource.surfaceEmphasized : ColorResource.successColor)
                        .onClick(() => {
                          this.handleHealthFilterClick('HEALTH_LATE', '严重滞后任务');
                        })
                    }
                    .alignItems(VerticalAlign.Center)
                  }
                }
                .width('100%')
              }
              .layoutWeight(1)

                // 右侧：遗漏提醒（标题 + 数量 + 去补充同一行）
                if (this.getTasksWithoutChecklistCount() > 0 || this.getOpenChecklistItemsCount() > 0) {
                  Row({ space: ThemeConfig.spacingS }) {
                    // 标题
                    Text('遗漏提醒')
                      .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                      .fontWeight(ThemeConfig.fontWeightMedium)
                      .fontColor(ColorResource.surfaceDeep)

                    // 数量信息
                    if (this.getTasksWithoutChecklistCount() > 0) {
                      Text(`未拆解任务 ${this.getTasksWithoutChecklistCount()} 个`)
                        .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                        .fontColor(ColorResource.warningColor)
                        .onClick(() => {
                          this.handleOmissionFilterClick('NO_CHECKLIST', '未拆解任务');
                        })
                    }

                    if (this.getOpenChecklistItemsCount() > 0) {
                      Text(`未完成检查项 ${this.getOpenChecklistItemsCount()} 项`)
                        .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                        .fontColor(ColorResource.warningColor)
                        .onClick(() => {
                          this.handleOmissionFilterClick('OPEN_CHECKLIST', '未完成检查项');
                        })
                    }

                    // 同一行的「去补充」按钮
                    Text('去补充')
                      .fontSize(this.isPhone ? ThemeConfig.fontSizeXS : ThemeConfig.fontSizeS)
                      .fontColor(ColorResource.primaryColor)
                      .fontWeight(ThemeConfig.fontWeightMedium)
                      .padding({
                        left: ThemeConfig.spacingXS,
                        right: ThemeConfig.spacingXS,
                        top: 2,
                        bottom: 2
                      })
                      .backgroundColor(ColorResource.primaryLight)
                      .borderRadius(ThemeConfig.radiusSmall)
                      .onClick(() => {
                        this.taskViewMode = 'LIST';
                        if (this.getTasksWithoutChecklistCount() > 0) {
                          this.taskFilter = 'NO_CHECKLIST';
                          this.promptAction.showToast({
                            message: '已切换到“未拆解任务”视图',
                            duration: 2000
                          });
                        } else if (this.getOpenChecklistItemsCount() > 0) {
                          this.taskFilter = 'OPEN_CHECKLIST';
                          this.promptAction.showToast({
                            message: '已切换到“未完成检查项”视图',
                            duration: 2000
                          });
                        }
                        this.goToFirstTaskNeedingDetails();
                      })
                  }
                  .layoutWeight(1)
                  .justifyContent(FlexAlign.End)
                  .alignItems(VerticalAlign.Center)
                }
            }
          }
        }
        .width('100%')
        .padding({
          top: ThemeConfig.spacingS,
          bottom: ThemeConfig.spacingS,
          left: ThemeConfig.spacingS,
          right: ThemeConfig.spacingS
        })
        .backgroundColor(ResponsiveColorConfig.getTaskCardBackgroundColor(this.isFloatingCard, this.isDarkMode))
        .borderRadius(this.isFloatingCard ? 6 : ThemeConfig.radiusLarge)
      }

        // 今日 / 本周重点 + 即将到期
        // 大屏非浮动卡片时左右并排；手机或浮动卡片使用下方的纵向布局，避免过于局促
        if (!this.isPhone && !this.isFloatingCard && this.getFocusTasks().length > 0 && this.getUpcomingTasks().length > 0) {
          Row({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth) }) {
            Column({ space: this.isPhone ? 4 : 6 }) {
            Row({ space: ThemeConfig.spacingM }) {
              Text('今日 / 本周重点')
                .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeS :
                  (this.isPhone ? ThemeConfig.fontSizeM : ThemeConfig.fontSizeL))
                .fontWeight(ThemeConfig.fontWeightBold)
                .fontColor(ColorResource.surfaceDeep)

              Text(`(${this.getFocusTasks().length} 项)`)
                .fontSize(this.isFloatingCard ? 10 :
                  (this.isPhone ? 11 : ThemeConfig.fontSizeS))
                .fontColor(ColorResource.surfaceEmphasized)
                .fontWeight(ThemeConfig.fontWeightMedium)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
  
              Swiper() {
                ForEach(this.getFocusTasks(), (task: TaskNode) => {
                    this.FocusTaskItem(task)
                  })
                }
                .width('100%')
                .height(this.isFloatingCard ? 80 : 100)
                .autoPlay(true)
                .interval(4000)
                .loop(true)
          }
            .width('100%')
            .layoutWeight(1)
  
            Column({ space: this.isPhone ? 4 : 6 }) {
            Row({ space: ThemeConfig.spacingM }) {
              Text('即将到期')
                .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeS :
                  (this.isPhone ? ThemeConfig.fontSizeM : ThemeConfig.fontSizeL))
                .fontWeight(ThemeConfig.fontWeightBold)
                .fontColor(ColorResource.surfaceDeep)
              Text('(未来7天)')
                .fontSize(this.isFloatingCard ? 10 :
                  (this.isPhone ? 11 : ThemeConfig.fontSizeS))
                .fontColor(ColorResource.surfaceEmphasized)
                .fontWeight(ThemeConfig.fontWeightMedium)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
  
                if (this.getUpcomingTasks().length > 0) {
                  Swiper() {
                    ForEach(this.getUpcomingTasks(), (task: TaskNode) => {
                      this.UpcomingTaskCard(task)
                    })
                  }
                  .width('100%')
                  .height(this.isFloatingCard ? 90 : 110)
                  .autoPlay(true)
                  .interval(4000)
                  .loop(true)
            } else {
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
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
      }

      // 3.2 所有任务总览列表 / 时间轴视图
      if (this.project.tasks.length > 0) {
        Column({ space: this.isPhone ? 8 : 12 }) {
          Row({ space: ThemeConfig.spacingM }) {
            Row({ space: ThemeConfig.spacingS }) {
              Text('所有任务')
                .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeS :
                  (this.isPhone ? ThemeConfig.fontSizeM : ThemeConfig.fontSizeL))
                .fontWeight(ThemeConfig.fontWeightBold)
                .fontColor(ColorResource.surfaceDeep)
              Text(`(${this.getAllTasksCount()} 个)`)
                .fontSize(this.isFloatingCard ? 10 :
                  (this.isPhone ? 11 : ThemeConfig.fontSizeS))
                .fontColor(ColorResource.surfaceEmphasized)
                .fontWeight(ThemeConfig.fontWeightMedium)

              if (this.taskFilter !== 'ALL') {
                Text(this.getCurrentFilterLabel())
                  .fontSize(this.isFloatingCard ? 9 :
                    (this.isPhone ? 10 : ThemeConfig.fontSizeXS))
                  .fontColor(ColorResource.primaryColor)
                  .padding({
                    left: ThemeConfig.spacingXS,
                    right: ThemeConfig.spacingXS,
                    top: 2,
                    bottom: 2
                  })
                  .backgroundColor(ColorResource.primaryLight)
                  .borderRadius(ThemeConfig.radiusSmall)
                  .onClick(() => {
                    this.taskFilter = 'ALL';
                  })
              }

              // 排序：与标题放在同一行
              Text('排序：')
                .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeXS :
                  (this.isPhone ? ThemeConfig.fontSizeS : ThemeConfig.fontSizeS))
                .fontColor(ColorResource.surfaceEmphasized)

              this.SortChip('开始时间', 'START')
              this.SortChip('结束时间', 'END')
              this.SortChip('完成度', 'PROGRESS')
            }
            .layoutWeight(1)
            .alignItems(VerticalAlign.Center)

            // 视图切换：列表 / 时间轴（仅在非浮动大屏显示）。
            if (!this.isFloatingCard) {
              Row({ space: ThemeConfig.spacingXS }) {
                Text('列表')
                  .fontSize(this.isFloatingCard ? 10 : ThemeConfig.fontSizeXS)
                  .fontColor(this.taskViewMode === 'LIST' ? ColorResource.primaryColor : ColorResource.surfaceEmphasized)
                  .padding({
                    left: 6,
                    right: 6,
                    top: 2,
                    bottom: 2
                  })
                  .backgroundColor(this.taskViewMode === 'LIST' ? ColorResource.primaryLight :
                    ColorResource.surfaceSubtle)
                  .borderRadius(ThemeConfig.radiusSmall)
                  .onClick(() => {
                    this.taskViewMode = 'LIST';
                    this.resetAllTasksScroll();
                  })

                Text('时间轴')
                  .fontSize(this.isFloatingCard ? 10 : ThemeConfig.fontSizeXS)
                  .fontColor(this.taskViewMode === 'TIMELINE' ? ColorResource.primaryColor :
                    ColorResource.surfaceEmphasized)
                  .padding({
                    left: 6,
                    right: 6,
                    top: 2,
                    bottom: 2
                  })
                  .backgroundColor(this.taskViewMode === 'TIMELINE' ? ColorResource.primaryLight :
                    ColorResource.surfaceSubtle)
                  .borderRadius(ThemeConfig.radiusSmall)
                  .onClick(() => {
                    this.taskViewMode = 'TIMELINE';
                    this.resetAllTasksScroll();
                  })
              }
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (!this.isFloatingCard && this.taskViewMode === 'LIST') {
            // 列表视图：使用 Scroll 占据剩余高度，内部内容自然决定滚动范围
            Column({ space: ThemeConfig.spacingS }) {
              Scroll() {
                Column({ space: ThemeConfig.spacingS }) {
                  ForEach(this.getAllTasksSorted(), (task: TaskNode) => {
                    this.AllTaskListItem(task)
                  })
                }
              }
              .width('100%')
              .edgeEffect(EdgeEffect.Spring)
              .scrollBar(BarState.Off)
              .scrollable(ScrollDirection.Vertical)
              .key(`all-tasks-scroll-${this.allTasksScrollKey}`)
            }
            .width('100%')
            .layoutWeight(1)
            .padding({
              top: 0, // 顶部去掉内边距，避免滚动区域上方出现空白
              bottom: ThemeConfig.spacingS,
              left: ThemeConfig.spacingS,
              right: ThemeConfig.spacingS
            })
            .backgroundColor(ResponsiveColorConfig.getTaskCardBackgroundColor(this.isFloatingCard, this.isDarkMode))
            .borderRadius(this.isFloatingCard ? 6 : ThemeConfig.radiusLarge)
            .clip(true)
          } else {
            // 时间轴视图：按结束日期简要展示（容器内滚动）
            Column({ space: ThemeConfig.spacingS }) {
              Scroll() {
                Column({ space: ThemeConfig.spacingS }) {
                  ForEach(this.getAllTasksSorted(), (task: TaskNode) => {
                    Row({ space: ThemeConfig.spacingS }) {
                      // 日期标签
                      Text(this.getTaskEndDateLabel(task))
                        .fontSize(this.isFloatingCard ? 10 : ThemeConfig.fontSizeXS)
                        .fontColor(ColorResource.surfaceEmphasized)
                        .width(80)

                      // 时间轴上的节点
                      Row({ space: ThemeConfig.spacingS }) {
                        Text('●')
                          .fontSize(10)
                          .fontColor(this.getTaskHealthTextColor(task))

                        Column({ space: 2 }) {
                          Text(task.name)
                            .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeS : ThemeConfig.fontSizeM)
                            .fontWeight(ThemeConfig.fontWeightMedium)
                            .fontColor(ColorResource.surfaceDeep)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Text(`进度 ${this.getTaskCompletionPercent(task)}% · 检查项 ${this.getChecklistProgressText(task)}`)
                            .fontSize(this.isFloatingCard ? 10 : ThemeConfig.fontSizeXS)
                            .fontColor(ColorResource.surfaceEmphasized)
                        }
                      }
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 4, bottom: 4 })
                    .onClick(() => {
                      this.handleOpenTaskInEditor(task);
                    })
                  })
                }
              }
              .width('100%')
              .edgeEffect(EdgeEffect.Spring)
              .scrollBar(BarState.Off)
              .scrollable(ScrollDirection.Vertical)
              .key(`all-tasks-scroll-${this.allTasksScrollKey}`)
            }
            .width('100%')
            .layoutWeight(1)
            .padding({
              top: 0, // 顶部去掉内边距，避免滚动区域上方出现空白
              bottom: ThemeConfig.spacingS,
              left: ThemeConfig.spacingS,
              right: ThemeConfig.spacingS
            })
            .backgroundColor(ResponsiveColorConfig.getTaskCardBackgroundColor(this.isFloatingCard, this.isDarkMode))
            .borderRadius(this.isFloatingCard ? 6 : ThemeConfig.radiusLarge)
            .clip(true)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .alignItems(HorizontalAlign.Start)
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
    // 统计卡片整体高度和内边距略收紧，让上半区更紧凑
    .height(this.isFloatingCard ? 68 : (this.isPhone ? 90 : 100))
    .padding(this.isFloatingCard ? 8 : BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth))
    .backgroundColor(ResponsiveColorConfig.getStatCardBackgroundColor(this.isFloatingCard, this.isDarkMode))
    .borderRadius(this.isFloatingCard ? 8 : ThemeConfig.radiusLarge)
    .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.shadowMedium)
    .border(this.isFloatingCard ?
      { width: 1, color: ResponsiveColorConfig.getStatCardBorderColor(this.isFloatingCard, this.isDarkMode, bgColor), radius: 8 } :
      { width: 2, color: bgColor, radius: ThemeConfig.radiusLarge })
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

  @Builder
  FilterChip(label: string, value: string) {
    Text(label)
      .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeXS :
      BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
      .fontColor(this.taskFilter === value ? ColorResource.primaryColor : ColorResource.surfaceEmphasized)
      .padding({ left: ThemeConfig.spacingXS, right: ThemeConfig.spacingXS, top: 4, bottom: 4 })
      .backgroundColor(this.taskFilter === value ? ColorResource.primaryLight : ColorResource.surfaceSubtle)
      .borderRadius(ThemeConfig.radiusSmall)
      .border({
        width: 1,
        color: this.taskFilter === value ? ColorResource.primaryColor : ColorResource.surfaceNeutral,
        radius: ThemeConfig.radiusSmall
      })
      .onClick(() => {
        this.taskFilter = value;
        this.resetAllTasksScroll();
      })
  }

  @Builder
  SortChip(label: string, value: string) {
    Text(label)
      .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeXS :
      BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
      .fontColor(this.taskSort === value ? ColorResource.primaryColor : ColorResource.surfaceEmphasized)
      .padding({ left: ThemeConfig.spacingXS, right: ThemeConfig.spacingXS, top: 4, bottom: 4 })
      .backgroundColor(this.taskSort === value ? ColorResource.primaryLight : ColorResource.surfaceSubtle)
      .borderRadius(ThemeConfig.radiusSmall)
      .border({
        width: 1,
        color: this.taskSort === value ? ColorResource.primaryColor : ColorResource.surfaceNeutral,
        radius: ThemeConfig.radiusSmall
      })
      .onClick(() => {
        this.taskSort = value;
        this.resetAllTasksScroll();
      })
  }


  // 构建器：任务总览列表项
  @Builder
  AllTaskListItem(task: TaskNode) {
    Row({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingS, this.screenWidth) }) {
      Column({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXS, this.screenWidth) }) {
        // 任务名称
        Text(task.name)
          .fontSize(this.isFloatingCard ? ThemeConfig.fontSizeS : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeL, this.screenWidth))
          .fontWeight(ThemeConfig.fontWeightBold)
          .fontColor(ColorResource.surfaceDeep)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 时间区间 + 完成度 + 检查项进度 + 健康状态
        Row({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingXS, this.screenWidth) }) {
          Text(`${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()}`)
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(ColorResource.surfaceEmphasized)

          Text(`完成度: ${this.getTaskCompletionPercent(task)}%`)
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(ColorResource.surfaceEmphasized)

          Text(this.getChecklistProgressText(task))
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(ColorResource.surfaceEmphasized)

          // 健康状态标签放在同一行，便于扫描
          Text(this.getTaskHealthLabel(task))
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(this.getTaskHealthTextColor(task))
            .fontWeight(ThemeConfig.fontWeightMedium)
            .padding({ left: ThemeConfig.spacingXS, right: ThemeConfig.spacingXS, top: 2, bottom: 2 })
            .backgroundColor(this.getTaskHealthBackgroundColor(task))
            .borderRadius(ThemeConfig.radiusSmall)

          // 关键任务标签也放在同一行
          if (task.isCritical) {
            Text('关键任务')
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
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧小图标操作区
      Row({ space: ThemeConfig.spacingXS }) {
        // 标记完成
        Text('✓')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.surfaceDeep)
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .backgroundColor(ColorResource.surfaceSubtle)
          .borderRadius(ThemeConfig.radiusSmall)
          .onClick(() => {
            this.handleMarkTaskCompleted(task);
          })

        // 添加日程
        Text('⏰')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.surfaceDeep)
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .backgroundColor(ColorResource.surfaceSubtle)
          .borderRadius(ThemeConfig.radiusSmall)
          .onClick(() => {
            this.handleAddTaskReminder(task);
          })

        // 打开编辑页
        Text('↗')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ColorResource.primaryColor)
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .backgroundColor(ColorResource.primaryLight)
          .borderRadius(ThemeConfig.radiusSmall)
          .onClick(() => {
            this.handleOpenTaskInEditor(task);
          })
      }
    }
    .width('100%')
    .padding(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth))
    .backgroundColor(ResponsiveColorConfig.getTaskCardBackgroundColor(this.isFloatingCard, this.isDarkMode))
    .borderRadius(this.isFloatingCard ? 6 : ThemeConfig.radiusLarge)
    .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.cardShadow)
    .border(this.isFloatingCard ?
      { width: 1, color: ResponsiveColorConfig.getTaskCardBorderColor(this.isFloatingCard, this.isDarkMode), radius: 6 } :
      { width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusLarge })
  }

  // 构建器：即将到期的任务卡片 - 紧凑设计
  @Builder
  UpcomingTaskCard(task: TaskNode) {
    Row({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth) }) {
      // 任务信息 - 紧凑设计（与 FocusTaskItem 保持一致）
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

          // 健康状态标签，与今日/本周重点一致
          Text(this.getTaskHealthLabel(task))
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(this.getTaskHealthTextColor(task))

          Text(this.getChecklistProgressText(task))
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

      // 与今日/本周重点一致的“打开编辑”箭头
      Text('↗')
        .fontSize(ThemeConfig.fontSizeM)
        .fontColor(ColorResource.primaryColor)
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .backgroundColor(ColorResource.primaryLight)
        .borderRadius(ThemeConfig.radiusSmall)
    }
    .width('100%')
    .padding(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth))
    .backgroundColor(ResponsiveColorConfig.getTaskCardBackgroundColor(this.isFloatingCard, this.isDarkMode))
    .borderRadius(this.isFloatingCard ? 6 : ThemeConfig.radiusLarge)
    .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.cardShadow)
    .border(this.isFloatingCard ?
      { width: 1, color: ResponsiveColorConfig.getTaskCardBorderColor(this.isFloatingCard, this.isDarkMode), radius: 6 } :
      { width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusLarge })
    .onClick(() => {
      this.handleOpenTaskInEditor(task);
    })
  }

  // 构建器：今日/本周重点任务列表项
  @Builder
  FocusTaskItem(task: TaskNode) {
    Row({ space: BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth) }) {
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

          Text(this.getTaskHealthLabel(task))
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(this.getTaskHealthTextColor(task))

          Text(this.getChecklistProgressText(task))
            .fontSize(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveFontSize(ThemeConfig.fontSizeXS, this.screenWidth))
            .fontColor(ColorResource.surfaceEmphasized)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('↗')
        .fontSize(ThemeConfig.fontSizeM)
        .fontColor(ColorResource.primaryColor)
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .backgroundColor(ColorResource.primaryLight)
        .borderRadius(ThemeConfig.radiusSmall)
    }
    .width('100%')
    .padding(this.isFloatingCard ? 10 : BreakpointSystem.getResponsiveSpacing(ThemeConfig.spacingM, this.screenWidth))
    .backgroundColor(ResponsiveColorConfig.getTaskCardBackgroundColor(this.isFloatingCard, this.isDarkMode))
    .borderRadius(this.isFloatingCard ? 6 : ThemeConfig.radiusLarge)
    .shadow(this.isFloatingCard ? { radius: 0, color: Color.Transparent } : ThemeConfig.cardShadow)
    .border(this.isFloatingCard ?
      { width: 1, color: ResponsiveColorConfig.getTaskCardBorderColor(this.isFloatingCard, this.isDarkMode), radius: 6 } :
      { width: 1, color: ColorResource.surfaceNeutral, radius: ThemeConfig.radiusLarge })
    .onClick(() => {
      this.handleOpenTaskInEditor(task);
    })
  }
}

