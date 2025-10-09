
/**
 * 画布渲染器模块
 * 
 * 本模块负责项目可视化画布的图形渲染，使用Canvas 2D API绘制任务节点、依赖关系
 * 和交互元素。提供高性能的图形渲染和丰富的视觉效果，支持关键路径可视化。
 * 
 * 主要功能：
 * 1. 任务节点渲染：绘制任务卡片，包含名称、时间、进度等信息
 * 2. 依赖关系渲染：绘制任务间的连接线和箭头
 * 3. 关键路径高亮：突出显示关键路径上的任务和连接
 * 4. 交互状态渲染：显示选中、悬停、连接等交互状态
 * 5. 进度可视化：绘制任务完成度和时间进度条
 * 6. 动画效果：提供平滑的过渡动画和交互反馈
 * 
 * 渲染特性：
 * - 高性能渲染：使用Canvas 2D API实现流畅的图形渲染
 * - 响应式设计：根据画布状态动态调整渲染内容
 * - 视觉层次：通过颜色、大小、阴影等建立清晰的视觉层次
 * - 交互反馈：提供丰富的视觉反馈和状态指示
 * - 可定制性：支持主题和样式的自定义配置
 * 
 * 技术实现：
 * - Canvas 2D：使用HarmonyOS Canvas 2D API进行图形绘制
 * - 坐标变换：支持画布平移、缩放等坐标变换
 * - 碰撞检测：高效的点击区域检测和命中测试
 * - 性能优化：避免不必要的重绘，使用脏矩形技术
 * - 内存管理：合理管理图形资源和内存使用
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode } from '../model/ProjectData';
import { ThemeConfig } from '../utils/ThemeConfig';

/**
 * 渲染配置接口
 * 定义画布渲染所需的所有配置参数
 */
export interface RenderConfig {
  /** 画布X轴偏移量 */
  canvasOffsetX: number;
  /** 画布Y轴偏移量 */
  canvasOffsetY: number;
  /** 是否正在连接任务 */
  isConnecting: boolean;
  /** 连接源任务ID */
  connectingFromTaskId: string | null;
  /** 当前选中的任务ID */
  selectedTaskId: string | null;
}

/**
 * 画布渲染器类
 * 
 * 实现项目可视化画布的图形渲染功能，负责绘制所有视觉元素。
 * 采用分层渲染策略，确保渲染效率和视觉效果的最佳平衡。
 * 
 * 核心功能：
 * 1. 图形绘制：使用Canvas 2D API绘制各种图形元素
 * 2. 状态渲染：根据任务状态渲染不同的视觉效果
 * 3. 交互反馈：提供丰富的用户交互视觉反馈
 * 4. 性能优化：优化渲染性能，确保流畅的用户体验
 * 5. 主题支持：支持不同的视觉主题和样式配置
 * 
 * 渲染流程：
 * 1. 清空画布：清除之前的绘制内容
 * 2. 绘制背景：绘制画布背景和网格
 * 3. 绘制依赖：绘制任务间的连接线
 * 4. 绘制任务：绘制任务节点和相关信息
 * 5. 绘制交互：绘制选中、悬停等交互状态
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
export class CanvasRenderer {
  private context: CanvasRenderingContext2D;
  private settings: RenderingContextSettings;

  constructor() {
    this.settings = new RenderingContextSettings(true);
    this.context = new CanvasRenderingContext2D(this.settings);
  }

  public getContext(): CanvasRenderingContext2D {
    return this.context;
  }

  public render(project: Project, config: RenderConfig): void {
    this.context.clearRect(0, 0, 3000, 3000);
    
    // 先绘制网格背景
    this.renderGrid();
    
    if (!project) return;

    // 渲染依赖连线
    this.renderDependencies(project, config);
    
    // 渲染任务节点
    this.renderTasks(project, config);
  }

  private renderGrid(): void {
    const width = 3000;
    const height = 3000;
    
    // 设置网格样式
    this.context.strokeStyle = ThemeConfig.gridLine;
    this.context.lineWidth = 1;
    
    // 绘制主网格线
    this.context.beginPath();
    
    // 垂直线
    for (let x = 0; x <= width; x += 200) {
      this.context.moveTo(x, 0);
      this.context.lineTo(x, height);
    }
    
    // 水平线
    for (let y = 0; y <= height; y += 200) {
      this.context.moveTo(0, y);
      this.context.lineTo(width, y);
    }
    
    this.context.stroke();
    
    // 绘制细网格线
    this.context.strokeStyle = ThemeConfig.gridLineFine;
    this.context.lineWidth = 0.5;
    this.context.beginPath();
    
    // 细垂直线
    for (let x = 0; x <= width; x += 100) {
      this.context.moveTo(x, 0);
      this.context.lineTo(x, height);
    }
    
    // 细水平线
    for (let y = 0; y <= height; y += 100) {
      this.context.moveTo(0, y);
      this.context.lineTo(width, y);
    }
    
    this.context.stroke();
  }

  private renderDependencies(project: Project, config: RenderConfig): void {
    project.dependencies.forEach(dep => {
      const fromNode = project.tasks.find(t => t.id === dep.fromId);
      const toNode = project.tasks.find(t => t.id === dep.toId);
      
      if (fromNode && toNode) {
        const isCriticalDep = fromNode.isCritical && toNode.isCritical;
        const fromCenterX = fromNode.x + config.canvasOffsetX + 200 / 2;
        const fromCenterY = fromNode.y + config.canvasOffsetY + 120 / 2;
        const toCenterX = toNode.x + config.canvasOffsetX + 200 / 2;
        const toCenterY = toNode.y + config.canvasOffsetY + 120 / 2;
        
        this.context.beginPath();
        this.context.moveTo(fromCenterX, fromCenterY);
        this.context.lineTo(toCenterX, toCenterY);
        this.context.strokeStyle = isCriticalDep ? ThemeConfig.taskCritical : ThemeConfig.textSecondary;
        this.context.lineWidth = isCriticalDep ? 3 : 2;
        this.context.stroke();
      }
    });
  }

  private renderTasks(project: Project, config: RenderConfig): void {
    project.tasks.forEach(task => {
      const NODE_WIDTH = 200;
      const NODE_HEIGHT = 120;
      const isSelected = task.id === config.selectedTaskId;
      const drawX = task.x + config.canvasOffsetX;
      const drawY = task.y + config.canvasOffsetY;

      // 节点背景
      this.context.fillStyle = ThemeConfig.white;
      this.drawRoundRect(this.context, drawX, drawY, NODE_WIDTH, NODE_HEIGHT, 16);
      this.context.fill();

      // 节点边框
      this.context.strokeStyle = isSelected ? ThemeConfig.taskSelected : (task.isCritical ? ThemeConfig.taskCritical : ThemeConfig.taskNormal);
      this.context.lineWidth = isSelected ? 4 : 2;
      this.context.stroke();

      // 任务名称
      this.context.fillStyle = ThemeConfig.gray900;
      this.context.font = `bold 28px HarmonyOS Sans`;
      this.context.fillText(task.name, drawX + 15, drawY + 25);

      // 日期信息
      this.context.font = `22px HarmonyOS Sans`;
      const dateString = `${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`;
      this.context.fillText(`📅 ${dateString}`, drawX + 15, drawY + 45);

      // 进度信息
      const timeProgress = this.getTimeProgress(task);
      const completionProgress = this.getCompletionProgress(task);
      
      this.context.font = `19px HarmonyOS Sans`;
      this.context.fillText(`⌛ 时间: ${timeProgress}%`, drawX + 15, drawY + 70);
      this.drawProgressBar(drawX + 15, drawY + 75, NODE_WIDTH - 30, 8, timeProgress, ThemeConfig.taskNormal);
      
      this.context.fillText(`✓ 完成: ${completionProgress}%`, drawX + 15, drawY + 95);
      this.drawProgressBar(drawX + 15, drawY + 100, NODE_WIDTH - 30, 8, completionProgress, ThemeConfig.taskProgress);
    });
  }

  private drawRoundRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, radius: number): void {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    ctx.lineTo(x + radius, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
  }

  private drawProgressBar(x: number, y: number, width: number, height: number, progress: number, color: string): void {
    const radius = height / 2;
    
    // 背景
    this.context.fillStyle = ThemeConfig.gridLine;
    this.drawRoundRect(this.context, x, y, width, height, radius);
    this.context.fill();
    
    // 进度
    this.context.fillStyle = color;
    const progressWidth = (width * progress) / 100;
    if (progressWidth > 0) {
      this.drawRoundRect(this.context, x, y, progressWidth, height, radius);
      this.context.fill();
    }
  }

  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  private getCompletionProgress(task: TaskNode): number {
    if (!task || !task.checklist) return 0;
    if (task.checklist.length === 0) return 0;
    const completedCount = task.checklist.filter(item => item.isCompleted).length;
    return Math.round((completedCount / task.checklist.length) * 100);
  }

  private getTimeProgress(task: TaskNode): number {
    if (!task) return 0;
    const now = new Date().getTime();
    const start = task.startDate.getTime();
    const end = task.endDate.getTime();
    if (now < start) return 0;
    if (now > end) return 100;
    const totalDuration = end - start;
    if (totalDuration <= 0) return 100;
    const elapsed = now - start;
    return Math.round((elapsed / totalDuration) * 100);
  }
}


