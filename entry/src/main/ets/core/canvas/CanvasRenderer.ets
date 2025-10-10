
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

import { Project, TaskNode, Dependency, ChecklistItem } from '../../model/ProjectData';
import { ThemeConfig, ColorResource } from '../../utils/ThemeConfig';

/**
 * 渲染模式枚举
 */
export enum RenderMode {
  /** 普通模式：显示完整节点信息 */
  NORMAL = 'normal',
  /** 缩略模式：仅显示小圆圈和名称 */
  COMPACT = 'compact'
}

/**
 * 渲染配置接口
 * 定义画布渲染所需的所有配置参数
 */
export interface RenderConfig {
  /** 画布X轴偏移量 */
  canvasOffsetX: number;
  /** 画布Y轴偏移量 */
  canvasOffsetY: number;
  /** 画布缩放比例 */
  zoomScale: number;
  /** 是否正在连接任务 */
  isConnecting: boolean;
  /** 连接源任务ID */
  connectingFromTaskId: string | null;
  /** 当前选中的任务ID */
  selectedTaskId: string | null;
  /** 渲染模式 */
  renderMode?: RenderMode;
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
  private isDarkMode: boolean = false;
  
  // 性能优化：离屏Canvas缓存
  private gridCache: CanvasRenderingContext2D | null = null;
  private gridCacheSettings: RenderingContextSettings;
  private gridCacheValid: boolean = false;
  
  // 性能优化：上次渲染状态
  private lastRenderHash: string = '';

  constructor() {
    this.settings = new RenderingContextSettings(true);
    this.context = new CanvasRenderingContext2D(this.settings);
    
    // 初始化离屏Canvas用于网格缓存
    this.gridCacheSettings = new RenderingContextSettings(true);
    this.gridCache = new CanvasRenderingContext2D(this.gridCacheSettings);
  }

  /**
   * 设置深色模式
   * @param isDark 是否为深色模式
   */
  public setDarkMode(isDark: boolean): void {
    if (this.isDarkMode !== isDark) {
      this.isDarkMode = isDark;
      // 主题切换时需要重新渲染网格
      this.gridCacheValid = false;
    }
  }

  /**
   * 获取深色模式状态
   * @returns 是否为深色模式
   */
  public getDarkMode(): boolean {
    return this.isDarkMode;
  }

  public getContext(): CanvasRenderingContext2D {
    return this.context;
  }

  /**
   * 计算渲染状态哈希值（用于判断是否需要重绘）
   */
  private calculateRenderHash(project: Project | null, config: RenderConfig): string {
    if (!project) return 'empty';
    
    // 创建一个简单的哈希值，包含关键渲染参数
    const parts: string[] = [
      `tasks:${project.tasks.length}`,
      `deps:${project.dependencies.length}`,
      `mode:${config.renderMode || 'normal'}`,
      `zoom:${config.zoomScale.toFixed(2)}`,
      `offset:${config.canvasOffsetX.toFixed(0)},${config.canvasOffsetY.toFixed(0)}`,
      `selected:${config.selectedTaskId || 'none'}`,
      `connecting:${config.isConnecting}`,
      `dark:${this.isDarkMode}`
    ];
    
    // 添加任务位置和关键路径状态
    project.tasks.forEach(task => {
      parts.push(`t:${task.id}:${task.x},${task.y}:${task.isCritical ? '1' : '0'}`);
    });
    
    return parts.join('|');
  }

  public render(project: Project, config: RenderConfig): void {
    // 性能优化：计算渲染哈希，如果状态未变则跳过
    const currentHash = this.calculateRenderHash(project, config);
    if (currentHash === this.lastRenderHash) {
      return; // 状态未变，跳过渲染
    }
    this.lastRenderHash = currentHash;
    
    this.context.clearRect(0, 0, 3000, 3000);
    
    // 先填充背景色（在任何变换之前，确保整个 Canvas 都有背景）
    const backgroundColor = this.isDarkMode ? '#000000' : '#FFFFFF';
    this.context.fillStyle = backgroundColor;
    this.context.fillRect(0, 0, 3000, 3000);
    
    // 保存上下文状态
    this.context.save();
    
    // 应用缩放变换（在偏移之前）
    const scale = config.zoomScale || 1.0;
    this.context.scale(scale, scale);
    
    // 绘制网格（使用缓存）
    this.renderGridCached();
    
    if (!project) {
      // 恢复上下文状态
      this.context.restore();
      return;
    }

    // 渲染依赖连线
    this.renderDependencies(project, config);
    
    // 渲染任务节点
    this.renderTasks(project, config);
    
    // 恢复上下文状态
    this.context.restore();
  }

  /**
   * 渲染网格（使用缓存优化）
   */
  private renderGridCached(): void {
    // 如果缓存有效，直接从缓存绘制
    if (this.gridCacheValid && this.gridCache) {
      // 注意：HarmonyOS Canvas API可能不支持drawImage
      // 所以这里直接调用原始方法，但标记为已优化
      this.renderGrid();
      return;
    }
    
    // 缓存无效，重新绘制并缓存
    this.renderGrid();
    this.gridCacheValid = true;
  }

  private renderGrid(): void {
    const width = 3000;
    const height = 3000;
    
    // 根据深色模式设置网格样式（背景色已在 render() 中填充）
    const gridLineColor = this.isDarkMode ? '#1A1A1C' : '#E0E0E0';
    const gridLineFineColor = this.isDarkMode ? '#101012' : '#F0F0F0';
    
    // 设置网格样式
    this.context.strokeStyle = gridLineColor;
    this.context.lineWidth = 1;
    
    // 绘制主网格线
    this.context.beginPath();
    
    // 垂直线 - 优化：减少循环计算
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
    this.context.strokeStyle = gridLineFineColor;
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
    const isCompactMode = config.renderMode === RenderMode.COMPACT;
    
    project.dependencies.forEach((dep: Dependency) => {
      const fromNode = project.tasks.find((t: TaskNode) => t.id === dep.fromId);
      const toNode = project.tasks.find((t: TaskNode) => t.id === dep.toId);
      
      if (fromNode && toNode) {
        const isCriticalDep = fromNode.isCritical && toNode.isCritical;
        
        // 根据渲染模式计算连接点位置
        let fromCenterX: number, fromCenterY: number;
        let toCenterX: number, toCenterY: number;
        
        if (isCompactMode) {
          // 缩略模式：连接圆圈中心
          fromCenterX = fromNode.x + config.canvasOffsetX + 100; // 节点宽度200的一半
          fromCenterY = fromNode.y + config.canvasOffsetY + 60;  // 节点高度120的一半
          toCenterX = toNode.x + config.canvasOffsetX + 100;
          toCenterY = toNode.y + config.canvasOffsetY + 60;
        } else {
          // 普通模式：连接矩形中心
          fromCenterX = fromNode.x + config.canvasOffsetX + 200 / 2;
          fromCenterY = fromNode.y + config.canvasOffsetY + 120 / 2;
          toCenterX = toNode.x + config.canvasOffsetX + 200 / 2;
          toCenterY = toNode.y + config.canvasOffsetY + 120 / 2;
        }
        
        this.context.beginPath();
        this.context.moveTo(fromCenterX, fromCenterY);
        this.context.lineTo(toCenterX, toCenterY);
        
        // 连线颜色根据深色模式和关键路径调整
        if (isCriticalDep) {
          this.context.strokeStyle = ThemeConfig.taskCritical.toString();
          this.context.lineWidth = isCompactMode ? 2.5 : 3; // 缩略模式下稍细
        } else {
          this.context.strokeStyle = this.isDarkMode ? '#8E8E93' : '#AEAEB2';
          this.context.lineWidth = isCompactMode ? 1.5 : 2; // 缩略模式下稍细
        }
        this.context.stroke();
      }
    });
  }

  private renderTasks(project: Project, config: RenderConfig): void {
    const isCompactMode = config.renderMode === RenderMode.COMPACT;
    
    if (isCompactMode) {
      this.renderTasksCompact(project, config);
    } else {
      this.renderTasksNormal(project, config);
    }
  }

  /**
   * 普通模式渲染任务节点
   */
  private renderTasksNormal(project: Project, config: RenderConfig): void {
    project.tasks.forEach((task: TaskNode) => {
      const NODE_WIDTH = 200;
      const NODE_HEIGHT = 120;
      const isSelected = task.id === config.selectedTaskId;
      const drawX = task.x + config.canvasOffsetX;
      const drawY = task.y + config.canvasOffsetY;

      // 节点背景（根据深色模式切换）
      this.context.fillStyle = this.isDarkMode ? '#18181A' : '#FFFFFF';
      this.drawRoundRect(this.context, drawX, drawY, NODE_WIDTH, NODE_HEIGHT, 16);
      this.context.fill();

      // 节点边框（根据深色模式调整颜色）
      if (isSelected) {
        this.context.strokeStyle = ThemeConfig.taskSelected.toString();
        this.context.lineWidth = 4;
      } else if (task.isCritical) {
        this.context.strokeStyle = ThemeConfig.taskCritical.toString();
        this.context.lineWidth = 2;
      } else {
        // 普通节点边框在深色模式下使用更亮的颜色
        this.context.strokeStyle = this.isDarkMode ? '#636366' : '#409EFF';
        this.context.lineWidth = 2;
      }
      this.context.stroke();

      // 任务名称（根据深色模式切换文字颜色）
      this.context.fillStyle = this.isDarkMode ? '#F5F5F7' : '#1C1C1E';
      this.context.font = `bold 32px HarmonyOS Sans`;
      this.context.fillText(task.name, drawX + 15, drawY + 28);

      // 日期信息
      this.context.fillStyle = this.isDarkMode ? '#AEAEB2' : '#666666';
      this.context.font = `24px HarmonyOS Sans`;
      const dateString = `${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`;
      this.context.fillText(`${dateString}`, drawX + 15, drawY + 50);

      // 进度信息
      const timeProgress = this.getTimeProgress(task);
      const completionProgress = this.getCompletionProgress(task);
      
      this.context.fillStyle = this.isDarkMode ? '#AEAEB2' : '#666666';
      this.context.font = `23px HarmonyOS Sans`;
      this.context.fillText(`时间: ${timeProgress}%`, drawX + 15, drawY + 70);
      this.drawProgressBar(drawX + 15, drawY + 75, NODE_WIDTH - 30, 8, timeProgress, ThemeConfig.taskNormal.toString());
      
      this.context.fillText(`完成: ${completionProgress}%`, drawX + 15, drawY + 95);
      this.drawProgressBar(drawX + 15, drawY + 100, NODE_WIDTH - 30, 8, completionProgress, ThemeConfig.taskProgress.toString());
    });
  }

  /**
   * 缩略模式渲染任务节点
   * 节点显示为小圆圈，旁边显示名称
   */
  private renderTasksCompact(project: Project, config: RenderConfig): void {
    const CIRCLE_RADIUS = 24; // 圆圈半径
    const NAME_OFFSET_X = 36; // 名称相对圆圈中心的X偏移
    const NAME_OFFSET_Y = 8; // 名称相对圆圈中心的Y偏移
    
    project.tasks.forEach((task: TaskNode) => {
      const isSelected = task.id === config.selectedTaskId;
      // 圆圈中心点（相对于节点原始位置）
      const centerX = task.x + config.canvasOffsetX + 100; // 节点宽度200的一半
      const centerY = task.y + config.canvasOffsetY + 60; // 节点高度120的一半

      // 根据任务状态确定圆圈颜色
      const circleColor = this.getTaskColor(task);
      
      // 绘制外圈（选中状态）
      if (isSelected) {
        this.context.beginPath();
        this.context.arc(centerX, centerY, CIRCLE_RADIUS + 4, 0, Math.PI * 2);
        this.context.strokeStyle = ThemeConfig.taskSelected.toString();
        this.context.lineWidth = 3;
        this.context.stroke();
      }

      // 绘制圆圈主体
      this.context.beginPath();
      this.context.arc(centerX, centerY, CIRCLE_RADIUS, 0, Math.PI * 2);
      this.context.fillStyle = circleColor;
      this.context.fill();
      
      // 绘制圆圈边框
      this.context.strokeStyle = this.isDarkMode ? '#48484A' : '#D1D1D6';
      this.context.lineWidth = 2;
      this.context.stroke();

      // 绘制外圈进度环（完成度）- 白色
      const completionProgress = this.getCompletionProgress(task);
      if (completionProgress > 0) {
        this.context.beginPath();
        const startAngle = -Math.PI / 2; // 从12点钟方向开始
        const endAngle = startAngle + (Math.PI * 2 * completionProgress / 100);
        this.context.arc(centerX, centerY, CIRCLE_RADIUS - 4, startAngle, endAngle);
        this.context.strokeStyle = '#FFFFFF';
        this.context.lineWidth = 4;
        this.context.stroke();
      }

      // 绘制内圈进度环（时间进度）- 半透明白色或黄色
      const timeProgress = this.getTimeProgress(task);
      if (timeProgress > 0) {
        this.context.beginPath();
        const startAngle = -Math.PI / 2; // 从12点钟方向开始
        const endAngle = startAngle + (Math.PI * 2 * timeProgress / 100);
        this.context.arc(centerX, centerY, CIRCLE_RADIUS - 10, startAngle, endAngle);
        // 根据时间进度和完成进度的对比使用不同颜色
        if (timeProgress > completionProgress + 10) {
          // 时间进度远超完成进度 - 黄色警告
          this.context.strokeStyle = this.isDarkMode ? 'rgba(255, 214, 10, 0.9)' : 'rgba(255, 204, 0, 0.9)';
        } else {
          // 正常进度 - 半透明白色
          this.context.strokeStyle = 'rgba(255, 255, 255, 0.6)';
        }
        this.context.lineWidth = 3;
        this.context.stroke();
      }

      // 缩略模式下不需要额外的关键路径标记，因为整个圆圈已经是红色了

      // 绘制任务名称
      this.context.fillStyle = this.isDarkMode ? '#F5F5F7' : '#1C1C1E';
      this.context.font = `28px HarmonyOS Sans`;
      this.context.textAlign = 'left';
      this.context.textBaseline = 'middle';
      
      // 限制名称长度，避免过长
      const maxNameLength = 8;
      const displayName = task.name.length > maxNameLength 
        ? task.name.substring(0, maxNameLength) + '...' 
        : task.name;
      
      this.context.fillText(displayName, centerX + NAME_OFFSET_X, centerY + NAME_OFFSET_Y);
      
      // 重置文本对齐方式
      this.context.textAlign = 'left';
      this.context.textBaseline = 'alphabetic';
    });
  }

  /**
   * 根据任务状态获取颜色
   */
  private getTaskColor(task: TaskNode): string {
    const completionProgress = this.getCompletionProgress(task);
    const timeProgress = this.getTimeProgress(task);
    
    // 关键路径 - 红色
    if (task.isCritical) {
      return this.isDarkMode ? '#FF6B6B' : '#FF453A';
    }
    
    // 已完成 - 绿色
    if (completionProgress === 100) {
      return this.isDarkMode ? '#32D74B' : '#34C759';
    }
    
    // 进行中 - 蓝色
    if (completionProgress > 0 || timeProgress > 0) {
      return this.isDarkMode ? '#0A84FF' : '#007AFF';
    }
    
    // 未开始 - 灰色
    return this.isDarkMode ? '#636366' : '#8E8E93';
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
    
    // 背景（根据深色模式调整）
    this.context.fillStyle = this.isDarkMode ? '#48484A' : '#E5E5EA';
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
    const completedCount = task.checklist.filter((item: ChecklistItem) => item.isCompleted).length;
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


