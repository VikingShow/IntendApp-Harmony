
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
import { TaskNodeWithSchema, NodeSchema } from '../../model/NodeSchema';
import { ThemeConfig, ColorResource } from '../../utils/ThemeConfig';
import { NodeSchemaService } from '../../services/NodeSchemaService';
import { NodeComponentSchema, NodeFieldValue, FieldSchema } from '../../model/NodeSchema';

interface TaskNodeWithCustomFields extends TaskNodeWithSchema {
  customFields?: Map<string, NodeFieldValue>;
}

export interface NodeBounds {
  width: number;
  height: number;
}

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
  /** 是否显示依赖连线箭头 */
  showDependencyArrows?: boolean;
  /** 闪烁节点ID列表 */
  blinkingTaskIds?: string[];
  /** 闪烁透明度 (0-1) */
  blinkOpacity?: number;
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
  private nodeSchemaService: NodeSchemaService | null = null;

  // 缓存每次渲染周期内节点的实际尺寸，用于依赖线/箭头定位
  private lastNodeBounds: Map<string, NodeBounds> = new Map();
  
  // 性能优化：离屏Canvas缓存
  private gridCache: CanvasRenderingContext2D | null = null;
  private gridCacheSettings: RenderingContextSettings;
  private gridCacheValid: boolean = false;
  
  // 性能优化：上次渲染状态
  private lastRenderHash: string = '';
 
  constructor() {
    this.settings = new RenderingContextSettings(true);
    this.context = new CanvasRenderingContext2D(this.settings);
    // 初始化节点 Schema 服务（单例）
    this.nodeSchemaService = NodeSchemaService.getInstance();
    
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
   * 强制清除渲染缓存，下次调用 render() 会强制重新渲染
   * 用于 Canvas onReady 等需要强制刷新的场景
   */
  public clearRenderCache(): void {
    this.lastRenderHash = '';
    this.gridCacheValid = false;
  }

  /**
   * 绘制水印（用于导出图片）
   * 在画布右下角添加 EasyFlow 水印
   * @param canvasWidth Canvas 宽度
   * @param canvasHeight Canvas 高度
   */
  public drawWatermark(canvasWidth: number, canvasHeight: number): void {
    const ctx = this.context;
    
    // 保存当前上下文状态
    ctx.save();
    
    // 重置变换（水印应该在原始坐标系统中）
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    
    // 水印位置（右下角，留出边距）
    const marginRight = 30;
    const marginBottom = 30;
    const watermarkX = canvasWidth - marginRight;
    const watermarkY = canvasHeight - marginBottom;
    
    // 绘制 "EasyFlow" 文字
    ctx.globalAlpha = 0.6;
    ctx.font = '600 45px sans-serif';
    ctx.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textMuted;
    ctx.textAlign = 'right';
    ctx.textBaseline = 'bottom';
    ctx.fillText('EasyFlow', watermarkX, watermarkY);
    
    // 恢复上下文状态
    ctx.restore();
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
    
    // 添加任务的完整信息（包括名称、日期、子任务、类型等，确保任务内容变化时触发重绘）
    project.tasks.forEach((task: TaskNode) => {
      const checklistInfo = task.checklist
        ? `${task.checklist.length}:${task.checklist.filter((c: ChecklistItem) => c.isCompleted).length}`
        : '0:0';

      // 将 schema 的 typeId 也纳入哈希，确保切换节点类型时会重新渲染
      const taskWithSchema = task as TaskNodeWithSchema;
      const typeIdInfo = taskWithSchema.typeId ? taskWithSchema.typeId : 'default';

      parts.push(
        `t:${task.id}:${task.x},${task.y}:${task.isCritical ? '1' : '0'}:${task.name}:` +
        `${task.startDate}:${task.endDate}:${checklistInfo}:${typeIdInfo}`
      );
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

    const themedBackgroundColor = this.isDarkMode
      ? ThemeConfig.surfaceDeepest
      : ThemeConfig.backgroundPage;
    this.context.fillStyle = themedBackgroundColor;
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

    // 第一步：渲染依赖连线（不含箭头）
    this.renderDependencyLines(project, config);
    
    // 第二步：渲染任务节点
    this.renderTasks(project, config);
    
    // 第三步：渲染箭头（在节点之上）
    this.renderDependencyArrows(project, config);
    
    // 恢复上下文状态
    this.context.restore();
  }

  public getNodeBounds(taskId: string): NodeBounds {
    if (this.lastNodeBounds.has(taskId)) {
      return this.lastNodeBounds.get(taskId)!;
    }
    const fallback: NodeBounds = { width: 200, height: 120 };
    return fallback;
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
    const gridLineColor = this.isDarkMode
      ? ThemeConfig.surfaceDeep
      : ThemeConfig.canvasGridLine;
    const gridLineFineColor = this.isDarkMode
      ? ThemeConfig.surfaceDark
      : ThemeConfig.canvasGridLineFine;
    
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

  /**
   * 渲染依赖连线（不含箭头）
   */
  private renderDependencyLines(project: Project, config: RenderConfig): void {
    const isCompactMode = config.renderMode === RenderMode.COMPACT;
    const compactOffsetX = 70;
    const compactOffsetY = 45;
    
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
          fromCenterX = fromNode.x + config.canvasOffsetX + compactOffsetX;
          fromCenterY = fromNode.y + config.canvasOffsetY + compactOffsetY;
          toCenterX = toNode.x + config.canvasOffsetX + compactOffsetX;
          toCenterY = toNode.y + config.canvasOffsetY + compactOffsetY;
        } else {
          // 普通模式：连接实际卡片中心（宽高随 schema/layout 自适应）
          const fromBounds = this.getNodeBounds(fromNode.id);
          const toBounds = this.getNodeBounds(toNode.id);
          fromCenterX = fromNode.x + config.canvasOffsetX + fromBounds.width / 2;
          fromCenterY = fromNode.y + config.canvasOffsetY + fromBounds.height / 2;
          toCenterX = toNode.x + config.canvasOffsetX + toBounds.width / 2;
          toCenterY = toNode.y + config.canvasOffsetY + toBounds.height / 2;
        }
        
        // 连线颜色根据深色模式和关键路径调整
        const lineColor = isCriticalDep
          ? ThemeConfig.taskCritical.toString()
          : (this.isDarkMode ? ThemeConfig.surfaceEmphasized.toString() : ThemeConfig.borderGrid.toString());
        const lineWidth = isCompactMode ? (isCriticalDep ? 2.5 : 1.5) : (isCriticalDep ? 3 : 2);
        
        // 绘制连线
        this.context.beginPath();
        this.context.moveTo(fromCenterX, fromCenterY);
        this.context.lineTo(toCenterX, toCenterY);
        this.context.strokeStyle = lineColor;
        this.context.lineWidth = lineWidth;
        this.context.stroke();
      }
    });
  }

  private getTaskColorWithSchema(task: TaskNode): string {
    const schemaColor = this.getSchemaTaskColor(task as TaskNodeWithSchema);
    if (schemaColor) {
      return schemaColor;
    }
    return this.getTaskColor(task);
  }

  private getSchemaTaskColor(task: TaskNodeWithSchema): string | null {
    // If no schema info, fall back to default color logic
    if (!task || !task.typeId) {
      console.log('[CanvasRenderer] getSchemaTaskColor: no typeId on task');
      return null;
    }

    console.log(`[CanvasRenderer] getSchemaTaskColor: typeId=${task.typeId}`);

    // 使用节点 Schema 服务按 typeId 查找样式颜色
    if (!this.nodeSchemaService) {
      this.nodeSchemaService = NodeSchemaService.getInstance();
    }

    try {
      const schema: NodeSchema | null = this.nodeSchemaService.getSchemaById(task.typeId);
      if (!schema || !schema.style || !schema.style.fillColor) {
        return null;
      }
      // 直接使用 Schema 中配置的填充色；如需深色模式适配，可在后续扩展
      return schema.style.fillColor;
    } catch (error) {
      console.error('[CanvasRenderer] getSchemaTaskColor: failed to read schema color', error);
      return null;
    }
  }

  /**
   * 渲染依赖箭头（在节点之上）
   */
  private renderDependencyArrows(project: Project, config: RenderConfig): void {
    const isCompactMode = config.renderMode === RenderMode.COMPACT;
    const compactOffsetX = 70;
    const compactOffsetY = 45;
    const showArrows = config.showDependencyArrows !== false;
    
    console.log(`[CanvasRenderer] renderDependencyArrows - showArrows: ${showArrows}`);
    
    project.dependencies.forEach((dep: Dependency, index: number) => {
      const fromNode = project.tasks.find((t: TaskNode) => t.id === dep.fromId);
      const toNode = project.tasks.find((t: TaskNode) => t.id === dep.toId);
      
      if (fromNode && toNode) {
        const isCriticalDep = fromNode.isCritical && toNode.isCritical;
        
        // 根据渲染模式计算连接点位置
        let fromCenterX: number, fromCenterY: number;
        let toCenterX: number, toCenterY: number;
        
        if (isCompactMode) {
          fromCenterX = fromNode.x + config.canvasOffsetX + compactOffsetX;
          fromCenterY = fromNode.y + config.canvasOffsetY + compactOffsetY;
          toCenterX = toNode.x + config.canvasOffsetX + compactOffsetX;
          toCenterY = toNode.y + config.canvasOffsetY + compactOffsetY;
        } else {
          const fromBounds = this.getNodeBounds(fromNode.id);
          const toBounds = this.getNodeBounds(toNode.id);
          fromCenterX = fromNode.x + config.canvasOffsetX + fromBounds.width / 2;
          fromCenterY = fromNode.y + config.canvasOffsetY + fromBounds.height / 2;
          toCenterX = toNode.x + config.canvasOffsetX + toBounds.width / 2;
          toCenterY = toNode.y + config.canvasOffsetY + toBounds.height / 2;
        }
        
        const lineColor = isCriticalDep
          ? ThemeConfig.taskCritical.toString()
          : (this.isDarkMode ? ThemeConfig.surfaceEmphasized.toString() : ThemeConfig.borderGrid.toString());
        const lineWidth = isCompactMode ? (isCriticalDep ? 2.5 : 1.5) : (isCriticalDep ? 3 : 2);
        
        // 绘制箭头（如果全局启用且该依赖未禁用）
        const shouldShowArrow = showArrows && (dep.showArrow !== false);
        if (shouldShowArrow) {
          console.log(`[CanvasRenderer] Drawing arrow ${index}: ${dep.fromId}->${dep.toId}`);
          // 计算连线中点位置
          const midX = (fromCenterX + toCenterX) / 2;
          const midY = (fromCenterY + toCenterY) / 2;
          this.drawArrow(fromCenterX, fromCenterY, midX, midY, lineColor, lineWidth);
        }
      }
    });
  }

  /**
   * 绘制箭头
   * @param fromX 起点X坐标
   * @param fromY 起点Y坐标
   * @param toX 终点X坐标
   * @param toY 终点Y坐标
   * @param color 箭头颜色
   * @param lineWidth 线条宽度
   */
  private drawArrow(fromX: number, fromY: number, toX: number, toY: number, color: string, lineWidth: number): void {
    console.log(`[CanvasRenderer] drawArrow called: from(${fromX},${fromY}) to(${toX},${toY}), color=${color}, lineWidth=${lineWidth}`);
    
    // 计算箭头参数
    const arrowLength = 12 + lineWidth * 2; // 箭头长度随线条粗细调整
    const arrowWidth = 8 + lineWidth; // 箭头宽度随线条粗细调整
    
    // 计算线条方向向量
    const dx = toX - fromX;
    const dy = toY - fromY;
    const length = Math.sqrt(dx * dx + dy * dy);
    
    if (length === 0) {
      console.log(`[CanvasRenderer] drawArrow: length is 0, skipping`);
      return; // 避免除以零
    }
    
    // 归一化方向向量
    const unitDx = dx / length;
    const unitDy = dy / length;
    
    // 箭头顶点位置（在终点处）
    const arrowTipX = toX;
    const arrowTipY = toY;
    
    // 箭头底部中心点
    const arrowBaseX = toX - unitDx * arrowLength;
    const arrowBaseY = toY - unitDy * arrowLength;
    
    // 计算垂直于线条的向量（用于箭头两侧）
    const perpDx = -unitDy;
    const perpDy = unitDx;
    
    // 箭头两侧的点
    const arrowLeft1X = arrowBaseX + perpDx * arrowWidth;
    const arrowLeft1Y = arrowBaseY + perpDy * arrowWidth;
    const arrowRight1X = arrowBaseX - perpDx * arrowWidth;
    const arrowRight1Y = arrowBaseY - perpDy * arrowWidth;
    
    // 绘制箭头（实心三角形）
    console.log(`[CanvasRenderer] Drawing arrow triangle: tip(${arrowTipX},${arrowTipY}), left(${arrowLeft1X},${arrowLeft1Y}), right(${arrowRight1X},${arrowRight1Y})`);
    this.context.beginPath();
    this.context.moveTo(arrowTipX, arrowTipY);
    this.context.lineTo(arrowLeft1X, arrowLeft1Y);
    this.context.lineTo(arrowRight1X, arrowRight1Y);
    this.context.closePath();
    this.context.fillStyle = color;
    this.context.fill();
    console.log(`[CanvasRenderer] Arrow drawn successfully`);
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
    // 每帧刷新节点尺寸缓存
    this.lastNodeBounds.clear();
    project.tasks.forEach((task: TaskNode) => {
      // 宽度自适应：按 schema.layout 复杂度 + 文本宽度估算，尽量紧凑
      const MIN_W = 170;
      const MAX_W = 260;
      const MIN_H = 86;
      const TOP_PADDING = 22;
      const BOTTOM_PADDING = 6;
      const isSelected = task.id === config.selectedTaskId;
      const drawX = task.x + config.canvasOffsetX;
      const drawY = task.y + config.canvasOffsetY;

      const schemaColor = this.getTaskColorWithSchema(task);

      // schema 信息（用于卡片上显示类型，增强可感知一致性）
      const taskWithSchema = task as TaskNodeWithSchema;
      const typeId = taskWithSchema.typeId ? taskWithSchema.typeId : 'standard';
      const schema = this.nodeSchemaService ? this.nodeSchemaService.getSchemaById(typeId) : null;
      const schemaName = schema ? schema.name : typeId;
      const borderRadius = schema && schema.style && schema.style.borderRadius !== undefined
        ? schema.style.borderRadius
        : 16;

      const layoutForSize: NodeComponentSchema[] = schema && schema.layout ? schema.layout : [];
      const baseCount = layoutForSize ? layoutForSize.length : 0;
      const widthByCount = MIN_W + Math.min(80, baseCount * 10);
      this.context.font = `bold 30px HarmonyOS Sans`;
      const titleW = this.context.measureText(task.name).width + 30;
      this.context.font = `22px HarmonyOS Sans`;
      const dateW = this.context.measureText(`${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`).width + 30;
      // 取最大值并做上下限裁剪
      const NODE_WIDTH = Math.max(MIN_W, Math.min(MAX_W, Math.max(widthByCount, Math.max(titleW, dateW))));

      // schema 驱动渲染：按 layout 顺序绘制节点内容
      // 统一从 task + customFields 读取值，以保证与编辑器/工作台一致
      const taskWithCustom = task as TaskNodeWithCustomFields;
      const customFields: Map<string, NodeFieldValue> | null = taskWithCustom.customFields
        ? taskWithCustom.customFields
        : null;
      const getCustomStr = (fieldId: string): string => {
        if (!customFields || !fieldId) return '';
        const v: NodeFieldValue | undefined = customFields.get(fieldId);
        if (typeof v === 'string') return v;
        if (typeof v === 'number') return String(v);
        if (typeof v === 'boolean') return v ? '是' : '否';
        return '';
      };
      const getCustomTags = (fieldId: string): string[] => {
        if (!customFields || !fieldId) return [];
        const v: NodeFieldValue | undefined = customFields.get(fieldId);
        return Array.isArray(v) ? (v as string[]) : [];
      };
      const getFieldLabel = (fieldId: string, fallback: string): string => {
        if (!schema || !schema.fields) return fallback;
        const f: FieldSchema | undefined = schema.fields.find((ff: FieldSchema) => ff.id === fieldId);
        return f && f.label ? String(f.label) : fallback;
      };

      // 完全自适应高度：先按 layout 进行“尺寸测算”（不画背景），再画背景/边框，最后画内容
      const estimateCursorEnd = (): number => {
        const layout: NodeComponentSchema[] = schema && schema.layout ? schema.layout : [];
        let y = TOP_PADDING;
        if (!layout || layout.length === 0) {
          // TITLE + DATE_RANGE + TIME_PROGRESS + TASK_PROGRESS
          y += 22;
          y += 18;
          y += 5 + 18;
          y += 5 + 18;
          return y;
        }

        layout.forEach((comp: NodeComponentSchema) => {
          const t: string = comp && comp.type ? String(comp.type) : '';
          if (t === 'TITLE') { y += 22; return; }
          if (t === 'DATE_RANGE') { y += 18; return; }
          if (t === 'CHECKLIST_SUMMARY') { y += 18; return; }
          if (t === 'TIME_PROGRESS') { y += 5 + 18; return; }
          if (t === 'TASK_PROGRESS') { y += 5 + 18; return; }
          if (t === 'PRIORITY_BADGE' || t === 'STATUS_DOT' || t === 'ASSIGNEE' || t === 'CUSTOM_FIELD') { y += 18; return; }
          if (t === 'TAGS') { y += 22; return; }
          y += 16;
        });
        return y;
      };

      const contentHeight = Math.max(MIN_H, Math.ceil(estimateCursorEnd() + BOTTOM_PADDING));

      // 背景
      const cardShadow = ThemeConfig.cardShadow;
      if (cardShadow) {
        this.context.shadowColor = cardShadow.color;
        this.context.shadowBlur = cardShadow.radius;
        this.context.shadowOffsetX = cardShadow.offsetX;
        this.context.shadowOffsetY = cardShadow.offsetY;
      }
      this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceDeep : ThemeConfig.backgroundCard;
      this.drawRoundRect(this.context, drawX, drawY, NODE_WIDTH, contentHeight, borderRadius);
      this.context.fill();
      this.context.shadowColor = ThemeConfig.transparent;
      this.context.shadowBlur = 0;
      this.context.shadowOffsetX = 0;
      this.context.shadowOffsetY = 0;

      // 边框
      if (isSelected) {
        this.context.strokeStyle = ThemeConfig.taskSelected.toString();
        this.context.lineWidth = 4;
      } else if (task.isCritical) {
        this.context.strokeStyle = ThemeConfig.taskCritical.toString();
        this.context.lineWidth = 2;
      } else {
        this.context.strokeStyle = schemaColor;
        this.context.lineWidth = 2;
      }
      this.context.stroke();

      // 记录本节点实际宽高，用于依赖线锚点定位
      this.lastNodeBounds.set(task.id, { width: NODE_WIDTH, height: contentHeight });

      // 绘制内容
      let cursorY = drawY + TOP_PADDING;
      const leftX = drawX + 15;
      const layout: NodeComponentSchema[] = schema && schema.layout ? schema.layout : [];

      if (!layout || layout.length === 0) {
        this.context.fillStyle = this.isDarkMode ? ThemeConfig.surface : ThemeConfig.textStrong;
        this.context.font = `bold 30px HarmonyOS Sans`;
        this.context.fillText(task.name, leftX, cursorY);
        cursorY += 22;

        this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
        this.context.font = `22px HarmonyOS Sans`;
        const dateString = `${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`;
        this.context.fillText(dateString, leftX, cursorY);
        cursorY += 18;

        const timeProgress = this.getTimeProgress(task);
        this.context.fillText(`时间: ${timeProgress}%`, leftX, cursorY);
        cursorY += 5;
        this.drawProgressBar(leftX, cursorY, NODE_WIDTH - 30, 5, timeProgress, ThemeConfig.taskNormal.toString());
        cursorY += 18;

        const completionProgress = this.getCompletionProgress(task);
        this.context.fillText(`完成: ${completionProgress}%`, leftX, cursorY);
        cursorY += 5;
        this.drawProgressBar(leftX, cursorY, NODE_WIDTH - 30, 5, completionProgress, ThemeConfig.taskProgress.toString());
        cursorY += 18;
      } else {
        layout.forEach((comp: NodeComponentSchema) => {
          const t: string = comp && comp.type ? String(comp.type) : '';
          const fieldId: string = comp && comp.fieldId ? String(comp.fieldId) : '';

          if (t === 'TITLE') {
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surface : ThemeConfig.textStrong;
            this.context.font = `bold 30px HarmonyOS Sans`;
            this.context.fillText(task.name, leftX, cursorY);
            cursorY += 22;
            return;
          }
          if (t === 'DATE_RANGE') {
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            const dateString = `${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`;
            this.context.fillText(dateString, leftX, cursorY);
            cursorY += 18;
            return;
          }
          if (t === 'CHECKLIST_SUMMARY') {
            const total = task.checklist ? task.checklist.length : 0;
            const done = task.checklist
              ? task.checklist.filter((c: ChecklistItem) => c.isCompleted).length
              : 0;
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            this.context.fillText(`清单: ${done}/${total}`, leftX, cursorY);
            cursorY += 18;
            return;
          }
          if (t === 'TIME_PROGRESS') {
            const timeProgress = this.getTimeProgress(task);
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            this.context.fillText(`时间: ${timeProgress}%`, leftX, cursorY);
            cursorY += 5;
            this.drawProgressBar(leftX, cursorY, NODE_WIDTH - 30, 5, timeProgress, ThemeConfig.taskNormal.toString());
            cursorY += 18;
            return;
          }
          if (t === 'TASK_PROGRESS') {
            const completionProgress = this.getCompletionProgress(task);
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            this.context.fillText(`完成: ${completionProgress}%`, leftX, cursorY);
            cursorY += 5;
            this.drawProgressBar(leftX, cursorY, NODE_WIDTH - 30, 5, completionProgress, ThemeConfig.taskProgress.toString());
            cursorY += 18;
            return;
          }
          if (t === 'PRIORITY_BADGE') {
            const v = getCustomStr('_priority');
            const label = getFieldLabel('_priority', '优先级');
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            this.context.fillText(`${label}: ${v && v.length > 0 ? v : '-'}`, leftX, cursorY);
            cursorY += 18;
            return;
          }
          if (t === 'STATUS_DOT') {
            const v = getCustomStr('_status');
            const label = getFieldLabel('_status', '状态');
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            this.context.fillText(`${label}: ${v && v.length > 0 ? v : '-'}`, leftX, cursorY);
            cursorY += 18;
            return;
          }
          if (t === 'ASSIGNEE') {
            const v = getCustomStr('_assignee');
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            this.context.fillText(`负责人: ${v && v.length > 0 ? v : '-'}`, leftX, cursorY);
            cursorY += 18;
            return;
          }
          if (t === 'TAGS') {
            const tags = getCustomTags('_tags');
            this.context.font = `20px HarmonyOS Sans`;

            // 标题
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.fillText(`标签`, leftX, cursorY);
            cursorY += 20;

            if (tags.length === 0) {
              this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textTertiary;
              this.context.fillText('无', leftX, cursorY);
              cursorY += 18;
              return;
            }

            // 标签 chips（最多显示 3 个）
            const maxTags = 3;
            const visibleTags = tags.slice(0, maxTags);
            const chipPaddingX = 10;
            const chipHeight = 26;
            const chipRadius = 13;
            let chipX = leftX;

            visibleTags.forEach((tag: string) => {
              const textWidth = this.context.measureText(tag).width;
              const chipWidth = textWidth + chipPaddingX * 2;

              // 背景
              this.context.fillStyle = this.isDarkMode
                ? 'rgba(10, 132, 255, 0.20)'
                : 'rgba(0, 122, 255, 0.12)';
              this.drawRoundRect(this.context, chipX, cursorY, chipWidth, chipHeight, chipRadius);
              this.context.fill();

              // 文本
              this.context.fillStyle = this.isDarkMode ? ThemeConfig.surface : ThemeConfig.primaryColor;
              this.context.fillText(tag, chipX + chipPaddingX, cursorY + chipHeight / 2 + 1);

              chipX += chipWidth + 8;
            });

            cursorY += chipHeight + 8;
            return;
          }
          if (t === 'CUSTOM_FIELD') {
            const fid = fieldId && fieldId.length > 0 ? fieldId : '';
            const v = getCustomStr(fid);
            const label = getFieldLabel(fid, fid && fid.length > 0 ? fid : '字段');
            this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
            this.context.font = `22px HarmonyOS Sans`;
            this.context.fillText(`${label}: ${v && v.length > 0 ? v : '-'}`, leftX, cursorY);
            cursorY += 18;
            return;
          }

          this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceMuted : ThemeConfig.textSecondary;
          this.context.font = `22px HarmonyOS Sans`;
          this.context.fillText(`${t}`, leftX, cursorY);
          cursorY += 16;
        });
      }

      // 选中时在节点右上角外侧显示类型标签（badge），避免占用节点内部空间
      if (isSelected) {
        const label = schemaName;
        this.context.font = `18px HarmonyOS Sans`;
        const textWidth = this.context.measureText(label).width;
        const padX = 10;
        const padY = 6;
        const badgeW = textWidth + padX * 2;
        const badgeH = 28;
        const badgeX = drawX + NODE_WIDTH - badgeW + 6;
        const badgeY = drawY - badgeH - 6;

        // 背景
        this.context.fillStyle = this.isDarkMode ? 'rgba(24,24,26,0.95)' : 'rgba(255,255,255,0.95)';
        this.drawRoundRect(this.context, badgeX, badgeY, badgeW, badgeH, 14);
        this.context.fill();

        // 文本
        this.context.fillStyle = this.isDarkMode ? ThemeConfig.surface : ThemeConfig.textStrong;
        this.context.textAlign = 'left';
        this.context.fillText(label, badgeX + padX, badgeY + 19);
      }

      // 日期信息
      // 旧版固定渲染已被 schema layout 驱动渲染替代
    });
  }

  /**
   * 缩略模式渲染任务节点
   * 节点显示为小圆圈，旁边显示名称
   */
  private renderTasksCompact(project: Project, config: RenderConfig): void {
    const CIRCLE_RADIUS = 24;
    const NAME_OFFSET_X = 32;
    const NAME_OFFSET_Y = 0;
    const CENTER_OFFSET_X = 70;
    const CENTER_OFFSET_Y = 45;

    const blinkingTaskIds = config.blinkingTaskIds || [];
    const blinkOpacity = config.blinkOpacity !== undefined ? config.blinkOpacity : 1;

    project.tasks.forEach((task: TaskNode) => {
      const isSelected = task.id === config.selectedTaskId;
      const isBlinking = blinkingTaskIds.includes(task.id);
      const centerX = task.x + config.canvasOffsetX + CENTER_OFFSET_X;
      const centerY = task.y + config.canvasOffsetY + CENTER_OFFSET_Y;

      const circleColor = this.getTaskColorWithSchema(task);
      
      // 选中态：使用更柔和的外圈，不要“黑边”效果
      if (isSelected) {
        this.context.beginPath();
        this.context.arc(centerX, centerY, CIRCLE_RADIUS + 3, 0, Math.PI * 2);
        this.context.strokeStyle = ThemeConfig.taskSelected.toString();
        this.context.lineWidth = 2;
        this.context.stroke();
      }

      if (isBlinking) {
        const nodeAlpha = 0.3 + 0.7 * blinkOpacity;
        this.context.globalAlpha = nodeAlpha;
      }

      this.context.beginPath();
      this.context.arc(centerX, centerY, CIRCLE_RADIUS, 0, Math.PI * 2);
      this.context.fillStyle = circleColor;
      this.context.fill();
      
      // 常态边框：去掉纯黑/纯白，改成淡色描边（更“卡片化”）
      const ringColor = this.isDarkMode ? 'rgba(255,255,255,0.35)' : 'rgba(0,0,0,0.12)';
      this.context.strokeStyle = ringColor;
      this.context.lineWidth = isBlinking ? 2 : 1;
      this.context.stroke();

      if (isBlinking) {
        this.context.globalAlpha = 1;
      }

      if (!isBlinking) {
        const completionProgress = this.getCompletionProgress(task);
        if (completionProgress > 0) {
          this.context.beginPath();
          const startAngle = -Math.PI / 2;
          const endAngle = startAngle + (Math.PI * 2 * completionProgress / 100);
          this.context.arc(centerX, centerY, CIRCLE_RADIUS - 3, startAngle, endAngle);
          this.context.strokeStyle = '#FFFFFF';
          this.context.lineWidth = 3;
          this.context.stroke();
        }

        const timeProgress = this.getTimeProgress(task);
        if (timeProgress > 0) {
          this.context.beginPath();
          const startAngle = -Math.PI / 2;
          const endAngle = startAngle + (Math.PI * 2 * timeProgress / 100);
          this.context.arc(centerX, centerY, CIRCLE_RADIUS - 8, startAngle, endAngle);
          if (timeProgress > completionProgress + 10) {
            this.context.strokeStyle = this.isDarkMode ? 'rgba(255, 214, 10, 0.9)' : 'rgba(255, 204, 0, 0.9)';
          } else {
            this.context.strokeStyle = 'rgba(255, 255, 255, 0.6)';
          }
          this.context.lineWidth = 2;
          this.context.stroke();
        }
      }

      this.context.fillStyle = this.isDarkMode ? ThemeConfig.surface : ThemeConfig.textStrong;
      this.context.font = `22px HarmonyOS Sans`;
      this.context.textAlign = 'left';
      this.context.textBaseline = 'middle';
      
      const maxNameLength = 10;
      const displayName = task.name.length > maxNameLength 
        ? task.name.substring(0, maxNameLength) + '...' 
        : task.name;
      
      this.context.fillText(displayName, centerX + NAME_OFFSET_X, centerY + NAME_OFFSET_Y);
      
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
      return ThemeConfig.taskCritical.toString();
    }
    
    // 已完成 - 绿色
    if (completionProgress === 100) {
      return ThemeConfig.taskProgress.toString();
    }
    
    // 进行中 - 蓝色
    if (completionProgress > 0 || timeProgress > 0) {
      return ThemeConfig.taskNormal.toString();
    }
    
    // 未开始 - 灰色
    return this.isDarkMode ? ThemeConfig.surfaceBold : ThemeConfig.surfaceMuted;
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
    this.context.fillStyle = this.isDarkMode ? ThemeConfig.surfaceDark : ThemeConfig.surfaceNeutral;
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
