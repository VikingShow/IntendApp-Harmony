
/**
 * 画布控制器模块
 * 
 * 本模块负责管理项目可视化画布的交互逻辑，处理用户的手势操作和画布状态管理。
 * 提供拖拽、缩放、选择、连接等交互功能，是用户与项目可视化界面交互的核心组件。
 * 
 * 主要功能：
 * 1. 手势识别：处理触摸、拖拽、点击等用户手势
 * 2. 任务操作：支持任务的拖拽移动、选择、连接等操作
 * 3. 画布控制：管理画布的平移、缩放、锁定等状态
 * 4. 依赖创建：处理任务间依赖关系的可视化创建
 * 5. 状态管理：维护画布的交互状态和用户操作历史
 * 6. 事件分发：将用户操作转换为相应的业务事件
 * 
 * 交互模式：
 * - 选择模式：点击选择任务节点
 * - 拖拽模式：拖拽移动任务节点位置
 * - 连接模式：创建任务间的依赖关系
 * - 平移模式：拖拽画布进行视图平移
 * - 锁定模式：禁用所有交互操作
 * 
 * 技术特点：
 * - 手势识别：精确识别用户意图和操作类型
 * - 碰撞检测：高效的点击区域检测算法
 * - 状态机：清晰的状态转换和模式切换
 * - 事件驱动：通过回调函数与业务逻辑解耦
 * - 性能优化：避免不必要的重绘和计算
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode } from '../../model/ProjectData';
import { CanvasRenderer, RenderConfig, RenderMode, NodeBounds } from './CanvasRenderer';
import { image } from '@kit.ImageKit';

/**
 * 依赖命中信息接口
 */
interface DependencyHit {
  fromId: string;
  toId: string;
}

/**
 * 内容边界接口
 * 定义画布内容的边界框
 */
interface ContentBounds {
  /** 最小X坐标 */
  minX: number;
  /** 最小Y坐标 */
  minY: number;
  /** 最大X坐标 */
  maxX: number;
  /** 最大Y坐标 */
  maxY: number;
}

/**
 * 画布状态接口
 * 定义画布控制器的所有状态信息
 */
export interface CanvasState {
  /** 画布X轴偏移量 */
  canvasOffsetX: number;
  /** 画布Y轴偏移量 */
  canvasOffsetY: number;
  /** 画布缩放比例 */
  zoomScale: number;
  /** 是否正在拖拽画布 */
  isDraggingCanvas: boolean;
  /** 是否正在拖拽节点 */
  isDraggingNode: boolean;
  /** 是否正在连接任务 */
  isConnecting: boolean;
  /** 连接源任务ID */
  connectingFromTaskId: string | null;
  /** 画布是否锁定 */
  isCanvasLocked: boolean;
  /** 上次触摸X坐标 */
  lastTouchX: number;
  /** 上次触摸Y坐标 */
  lastTouchY: number;
  /** 拖拽X轴偏移量 */
  dragOffsetX: number;
  /** 拖拽Y轴偏移量 */
  dragOffsetY: number;
  /** 当前选中的任务 */
  selectedTask: TaskNode | null;
  /** 拖拽开始时的任务X坐标（用于撤销/重做） */
  dragStartX: number;
  /** 拖拽开始时的任务Y坐标（用于撤销/重做） */
  dragStartY: number;
  /** 渲染模式 */
  renderMode: RenderMode;
}

/**
 * 画布操作接口
 * 定义画布控制器的所有操作方法
 */
export interface CanvasActions {
  /** 处理触摸事件 */
  handleTouch: (event: TouchEvent, project: Project, selectedTaskId: string | null, touchOffsetX?: number) => void;
  /** 重置画布 */
  resetCanvas: () => void;
  /** 切换画布锁定状态 */
  toggleCanvasLock: () => void;
  /** 开始连接任务 */
  startConnecting: (taskId: string) => void;
  /** 停止连接任务 */
  stopConnecting: () => void;
  /** 获取渲染配置 */
  getRenderConfig: (selectedTaskId: string | null, showDependencyArrows?: boolean) => RenderConfig;
  /** 放大画布 */
  zoomIn: () => void;
  /** 缩小画布 */
  zoomOut: () => void;
  /** 重置缩放 */
  resetZoom: () => void;
}

/**
 * 画布控制器类
 * 
 * 实现画布交互逻辑的核心控制器，负责处理用户手势和画布状态管理。
 * 采用状态机模式管理不同的交互模式，提供流畅的用户体验。
 * 
 * 核心功能：
 * 1. 手势处理：识别和处理各种用户手势操作
 * 2. 状态管理：维护画布的交互状态和模式
 * 3. 事件分发：将用户操作转换为业务事件
 * 4. 渲染协调：与CanvasRenderer协调进行画面更新
 * 5. 性能优化：优化交互响应和渲染性能
 * 
 * 设计模式：
 * - 状态机模式：管理不同的交互状态
 * - 观察者模式：通过回调函数通知状态变化
 * - 命令模式：将用户操作封装为命令
 * - 策略模式：根据状态选择不同的处理策略
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
export class CanvasController {
  private renderer: CanvasRenderer;
  private state: CanvasState = {
    canvasOffsetX: 0,
    canvasOffsetY: 0,
    zoomScale: 1.0,
    isDraggingCanvas: false,
    isDraggingNode: false,
    isConnecting: false,
    connectingFromTaskId: null,
    isCanvasLocked: false,
    lastTouchX: 0,
    lastTouchY: 0,
    dragOffsetX: 0,
    dragOffsetY: 0,
    selectedTask: null,
    dragStartX: 0,
    dragStartY: 0,
    renderMode: RenderMode.NORMAL
  };
  
  // 缩放相关常量
  private readonly MIN_ZOOM: number = 0.3;
  private readonly MAX_ZOOM: number = 3.0;
  private readonly ZOOM_STEP: number = 0.2;

  // 追踪触摸开始的位置（用于区分点击和拖拽）
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  
  // 双指缩放相关状态
  private isPinching: boolean = false;
  private lastPinchDistance: number = 0;
  private pinchStartScale: number = 1.0;
  private pinchCenterX: number = 0;
  private pinchCenterY: number = 0;

  private onTaskSelect: ((task: TaskNode | null) => void) | null = null;
  private onDependencyCreate: ((fromId: string, toId: string) => void) | null = null;
  private onTaskMove: ((taskId: string, x: number, y: number) => void) | null = null;
  private onTaskMoveImmediate: ((taskId: string, x: number, y: number) => void) | null = null;
  private onTaskClick: ((task: TaskNode) => void) | null = null; // 节点点击回调（用于缩略模式显示详情）
  private onDependencyClick: ((fromId: string, toId: string, x: number, y: number) => void) | null = null; // 依赖线点击回调
  private uiContext: UIContext | null = null;

  public setContext(ctx: UIContext) {
    this.uiContext = ctx;
  }

  constructor() {
    this.renderer = new CanvasRenderer();
  }

  /**
   * 获取渲染器实例
   * @returns CanvasRenderer实例
   */
  public getRenderer(): CanvasRenderer {
    return this.renderer;
  }

  public setCallbacks(
    onTaskSelect: (task: TaskNode | null) => void,
    onDependencyCreate: (fromId: string, toId: string) => void,
    onTaskMove: (taskId: string, x: number, y: number) => void,
    onTaskMoveImmediate?: (taskId: string, x: number, y: number) => void,
    onTaskClick?: (task: TaskNode) => void,
    onDependencyClick?: (fromId: string, toId: string, x: number, y: number) => void
  ): void {
    this.onTaskSelect = onTaskSelect;
    this.onDependencyCreate = onDependencyCreate;
    this.onTaskMove = onTaskMove;
    this.onTaskMoveImmediate = onTaskMoveImmediate || null;
    this.onTaskClick = onTaskClick || null;
    this.onDependencyClick = onDependencyClick || null;
  }

  /**
   * 设置渲染模式
   */
  public setRenderMode(mode: RenderMode): void {
    this.state.renderMode = mode;
  }

  public getState(): CanvasState {
    return this.state;
  }

  public setCanvasOffset(x: number, y: number): void {
    this.state.canvasOffsetX = x;
    this.state.canvasOffsetY = y;
  }

  public getNodeBounds(taskId: string): NodeBounds {
    return this.renderer.getNodeBounds(taskId);
  }

  public getActions(): CanvasActions {
    return {
      handleTouch: (event: TouchEvent, project: Project, selectedTaskId: string | null, touchOffsetX?: number) => this.handleTouch(event, project, selectedTaskId, touchOffsetX),
      resetCanvas: () => this.resetCanvas(),
      toggleCanvasLock: () => this.toggleCanvasLock(),
      startConnecting: (taskId: string) => this.startConnecting(taskId),
      stopConnecting: () => this.stopConnecting(),
      getRenderConfig: (selectedTaskId: string | null, showDependencyArrows?: boolean) => this.getRenderConfig(selectedTaskId, showDependencyArrows),
      zoomIn: () => this.zoomIn(),
      zoomOut: () => this.zoomOut(),
      resetZoom: () => this.resetZoom()
    };
  }

  private handleTouch(event: TouchEvent, project: Project, selectedTaskId: string | null, touchOffsetX: number = 0): void {
    if (this.state.isCanvasLocked) return;

    const touchCount = event.touches.length;
    
    // 双指操作 - 缩放
    if (touchCount === 2) {
      this.handlePinchGesture(event, touchOffsetX);
      return;
    }
    
    // 单指操作 - 拖拽
    if (touchCount === 1) {
      // 如果之前在进行双指操作，重置状态
      if (this.isPinching) {
        this.isPinching = false;
        this.lastPinchDistance = 0;
        return;
      }
      
      // touchOffsetX 用于处理左侧按钮栏等偏移（编辑页面需要，Home页面不需要）
      const screenTouchX = event.touches[0].x - touchOffsetX;
      const screenTouchY = event.touches[0].y;
      
      // 将屏幕坐标转换为画布坐标（考虑缩放）
      const realTouchX = screenTouchX / this.state.zoomScale;
      const realTouchY = screenTouchY / this.state.zoomScale;

      let hitNode: TaskNode | null = null;
      let hitDependency: DependencyHit | null = null;
      
      // 根据渲染模式进行不同的命中检测
      if (this.state.renderMode === RenderMode.COMPACT) {
        hitNode = this.hitTestCompact(realTouchX, realTouchY, project);
      } else {
        hitNode = this.hitTestNormal(realTouchX, realTouchY, project);
      }
      
      // 如果没有命中节点，检测是否命中依赖线
      if (!hitNode) {
        hitDependency = this.hitTestDependency(realTouchX, realTouchY, project);
      }

      switch (event.type) {
        case TouchType.Down:
          this.handleTouchDown(realTouchX, realTouchY, hitNode, hitDependency);
          break;
        case TouchType.Move:
          this.handleTouchMove(realTouchX, realTouchY);
          break;
        case TouchType.Up:
          this.handleTouchUp(realTouchX, realTouchY);
          break;
      }
    }
  }
  
  /**
   * 处理双指捏合缩放手势（优化版）
   */
  private handlePinchGesture(event: TouchEvent, touchOffsetX: number): void {
    const touch1X = event.touches[0].x - touchOffsetX;
    const touch1Y = event.touches[0].y;
    const touch2X = event.touches[1].x - touchOffsetX;
    const touch2Y = event.touches[1].y;
    
    // 计算捏合中心点（屏幕坐标）- 提前计算，避免重复
    const centerX = (touch1X + touch2X) * 0.5;
    const centerY = (touch1Y + touch2Y) * 0.5;
    
    // 计算两个触摸点之间的距离
    const distance = this.calculateDistance(touch1X, touch1Y, touch2X, touch2Y);
    
    switch (event.type) {
      case TouchType.Down:
        // 开始双指操作
        this.isPinching = true;
        this.lastPinchDistance = distance;
        this.pinchStartScale = this.state.zoomScale;
        this.pinchCenterX = centerX;
        this.pinchCenterY = centerY;
        
        // 取消任何正在进行的单指操作
        this.state.isDraggingCanvas = false;
        this.state.isDraggingNode = false;
        break;
        
      case TouchType.Move:
        if (this.isPinching && this.lastPinchDistance > 0) {
          // 计算缩放比例变化（增加灵敏度系数）
          const scaleFactor = distance / this.lastPinchDistance;
          
          // 计算新的缩放比例
          let newScale = this.state.zoomScale * scaleFactor;
          
          // 限制在合理范围内
          const clampedScale = Math.max(this.MIN_ZOOM, Math.min(newScale, this.MAX_ZOOM));
          
          // 如果缩放比例变化太小，跳过以减少抖动
          const scaleChange = Math.abs(clampedScale - this.state.zoomScale);
          if (scaleChange < 0.001) {
            break;
          }
          
          // 优化的缩放中心算法（使用固定中心点）
          const oldScale = this.state.zoomScale;
          
          // 计算偏移调整量
          const offsetAdjustX = centerX / clampedScale - centerX / oldScale;
          const offsetAdjustY = centerY / clampedScale - centerY / oldScale;
          
          // 应用新的缩放比例和偏移
          this.state.zoomScale = clampedScale;
          this.state.canvasOffsetX += offsetAdjustX;
          this.state.canvasOffsetY += offsetAdjustY;
          
          // 更新上次距离
          this.lastPinchDistance = distance;
        }
        break;
        
      case TouchType.Up:
      case TouchType.Cancel:
        // 结束双指操作
        this.isPinching = false;
        this.lastPinchDistance = 0;
        break;
    }
  }
  
  /**
   * 计算两点之间的距离
   */
  private calculateDistance(x1: number, y1: number, x2: number, y2: number): number {
    const dx = x2 - x1;
    const dy = y2 - y1;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * 普通模式命中检测（矩形区域）
   */
  private hitTestNormal(touchX: number, touchY: number, project: Project): TaskNode | null {
    const HIT_PADDING = 8;
    
    for (let i = project.tasks.length - 1; i >= 0; i--) {
      const task: TaskNode = project.tasks[i];
      const nodeLeft = task.x + this.state.canvasOffsetX - HIT_PADDING;
      const nodeTop = task.y + this.state.canvasOffsetY - HIT_PADDING;
      const nodeRight = nodeLeft + 200 + HIT_PADDING * 2;
      const nodeBottom = nodeTop + 120 + HIT_PADDING * 2;
      
      if (touchX >= nodeLeft && touchX <= nodeRight &&
          touchY >= nodeTop && touchY <= nodeBottom) {
        return task;
      }
    }
    
    return null;
  }

  /**
   * 依赖线命中检测
   * 检测触摸点是否在某条依赖线附近
   */
  private hitTestDependency(touchX: number, touchY: number, project: Project): DependencyHit | null {
    const HIT_TOLERANCE = 10; // 点击容差（像素）
    
    for (const dep of project.dependencies) {
      const fromNode = project.tasks.find(t => t.id === dep.fromId);
      const toNode = project.tasks.find(t => t.id === dep.toId);
      
      if (fromNode && toNode) {
        // 计算线段的起点和终点
        let fromX: number, fromY: number, toX: number, toY: number;
        
        if (this.state.renderMode === RenderMode.COMPACT) {
          fromX = fromNode.x + this.state.canvasOffsetX + 100;
          fromY = fromNode.y + this.state.canvasOffsetY + 60;
          toX = toNode.x + this.state.canvasOffsetX + 100;
          toY = toNode.y + this.state.canvasOffsetY + 60;
        } else {
          fromX = fromNode.x + this.state.canvasOffsetX + 100;
          fromY = fromNode.y + this.state.canvasOffsetY + 60;
          toX = toNode.x + this.state.canvasOffsetX + 100;
          toY = toNode.y + this.state.canvasOffsetY + 60;
        }
        
        // 计算点到线段的距离
        const distance = this.pointToLineDistance(touchX, touchY, fromX, fromY, toX, toY);
        
        if (distance <= HIT_TOLERANCE) {
          const hit: DependencyHit = { fromId: dep.fromId, toId: dep.toId };
          return hit;
        }
      }
    }
    
    return null;
  }
  
  /**
   * 计算点到线段的距离
   */
  private pointToLineDistance(px: number, py: number, x1: number, y1: number, x2: number, y2: number): number {
    const dx = x2 - x1;
    const dy = y2 - y1;
    const lengthSquared = dx * dx + dy * dy;
    
    if (lengthSquared === 0) {
      // 线段退化为点
      const dpx = px - x1;
      const dpy = py - y1;
      return Math.sqrt(dpx * dpx + dpy * dpy);
    }
    
    // 计算投影参数 t
    let t = ((px - x1) * dx + (py - y1) * dy) / lengthSquared;
    t = Math.max(0, Math.min(1, t)); // 限制在 [0, 1] 范围内
    
    // 计算线段上最近的点
    const nearestX = x1 + t * dx;
    const nearestY = y1 + t * dy;
    
    // 计算距离
    const distX = px - nearestX;
    const distY = py - nearestY;
    return Math.sqrt(distX * distX + distY * distY);
  }

  /**
   * 缩略模式命中检测（圆形区域）
   */
  private hitTestCompact(touchX: number, touchY: number, project: Project): TaskNode | null {
    const CIRCLE_RADIUS = 24; // 与渲染器中的圆圈半径保持一致
    const HIT_TOLERANCE = 12; // 适当的点击容差，方便点击小圆圈
    
    for (let i = project.tasks.length - 1; i >= 0; i--) {
      const task: TaskNode = project.tasks[i];
      // 圆圈中心点（需要与渲染器保持一致）
      const centerX: number = task.x + this.state.canvasOffsetX + 100;
      const centerY: number = task.y + this.state.canvasOffsetY + 60;
      
      // 计算触摸点到圆心的距离
      const dx = touchX - centerX;
      const dy = touchY - centerY;
      const distance = Math.sqrt(dx * dx + dy * dy);
      
      // 点击在圆圈范围内（含容差）- 总半径约36px
      if (distance <= CIRCLE_RADIUS + HIT_TOLERANCE) {
        return task;
      }
    }
    
    return null;
  }

  private handleTouchDown(touchX: number, touchY: number, hitNode: TaskNode | null, hitDependency?: DependencyHit | null): void {
    // 记录触摸开始位置（用于区分点击和拖拽）
    this.touchStartX = touchX;
    this.touchStartY = touchY;
    
    if (this.state.isConnecting && this.state.connectingFromTaskId) {
      this.handleConnectingTouchDown(hitNode);
      return;
    }
    
    // 如果点击了依赖线
    if (hitDependency && this.onDependencyClick) {
      this.onDependencyClick(hitDependency.fromId, hitDependency.toId, touchX, touchY);
      return;
    }

    if (hitNode) {
      this.state.selectedTask = hitNode;
      
      // 所有模式下都启用节点拖拽
      this.state.isDraggingNode = true;
      this.state.isDraggingCanvas = false;
      this.state.dragOffsetX = touchX - (hitNode.x + this.state.canvasOffsetX);
      this.state.dragOffsetY = touchY - (hitNode.y + this.state.canvasOffsetY);
      
      // 记录拖拽开始时的位置（用于撤销/重做）
      this.state.dragStartX = hitNode.x;
      this.state.dragStartY = hitNode.y;
      
      if (this.onTaskSelect) {
        this.onTaskSelect(hitNode);
      }
    } else {
      this.state.isDraggingCanvas = true;
      this.state.isDraggingNode = false;
      this.state.lastTouchX = touchX;
      this.state.lastTouchY = touchY;
      
      if (this.onTaskSelect) {
        this.onTaskSelect(null);
      }
    }
  }

  private handleConnectingTouchDown(hitNode: TaskNode | null): void {
    if(this.uiContext) {
      const promptAction = this.uiContext.getPromptAction();
      if (!hitNode || !this.state.connectingFromTaskId) {
        promptAction.showToast({ message: '请点击目标任务节点' });
        this.stopConnecting();
        return;
      }

      if (this.state.connectingFromTaskId === hitNode.id) {
        promptAction.showToast({ message: '不能依赖自己' });
        this.stopConnecting();
        return;
      }

      if (this.onDependencyCreate) {
        this.onDependencyCreate(this.state.connectingFromTaskId, hitNode.id);
      }
    }
    this.stopConnecting();
  }

  private handleTouchMove(touchX: number, touchY: number): void {
    if (this.state.isDraggingNode && this.state.selectedTask) {
      const newX = touchX - this.state.dragOffsetX - this.state.canvasOffsetX;
      const newY = touchY - this.state.dragOffsetY - this.state.canvasOffsetY;
      
      // 移动过程中立即更新任务位置（不创建命令）
      if (this.onTaskMoveImmediate) {
        this.onTaskMoveImmediate(this.state.selectedTask.id, newX, newY);
      }
    } else if (this.state.isDraggingCanvas) {
      this.state.canvasOffsetX += touchX - this.state.lastTouchX;
      this.state.canvasOffsetY += touchY - this.state.lastTouchY;
      this.state.lastTouchX = touchX;
      this.state.lastTouchY = touchY;
    }
  }

  private handleTouchUp(touchX: number, touchY: number): void {
    // 如果正在拖拽节点，在抬起时创建命令（记录整个拖拽过程）
    if (this.state.isDraggingNode && this.state.selectedTask) {
      const finalX: number = this.state.selectedTask.x;
      const finalY: number = this.state.selectedTask.y;
      
      // 基于触摸点的移动距离来判断是点击还是拖拽（更准确）
      const touchMoveX = Math.abs(touchX - this.touchStartX);
      const touchMoveY = Math.abs(touchY - this.touchStartY);
      const CLICK_THRESHOLD = 10; // 触摸点移动距离小于10像素认为是点击
      
      const isClick = (touchMoveX < CLICK_THRESHOLD && touchMoveY < CLICK_THRESHOLD);
      
      console.log(`[CanvasController] Touch up - touchMove: (${touchMoveX}, ${touchMoveY}), isClick: ${isClick}, renderMode: ${this.state.renderMode}`);
      
      // 只有拖拽（位置真的改变了）才创建命令
      if (!isClick) {
        if (this.onTaskMove) {
          this.onTaskMove(this.state.selectedTask.id, finalX, finalY);
        }
      }
      // 缩略模式下的点击不再触发特殊操作，因为取消了节点详情对话框
    }
    
    this.state.isDraggingCanvas = false;
    this.state.isDraggingNode = false;
  }

  private resetCanvas(): void {
    this.state.canvasOffsetX = 0;
    this.state.canvasOffsetY = 0;
  }

  private toggleCanvasLock(): void {
    this.state.isCanvasLocked = !(this.state.isCanvasLocked);
  }

  private startConnecting(taskId: string): void {
    this.state.isConnecting = true;
    this.state.connectingFromTaskId = taskId;
  }

  private stopConnecting(): void {
    this.state.isConnecting = false;
    this.state.connectingFromTaskId = null;
  }

  private getRenderConfig(selectedTaskId: string | null, showDependencyArrows?: boolean): RenderConfig {
    return {
      canvasOffsetX: this.state.canvasOffsetX,
      canvasOffsetY: this.state.canvasOffsetY,
      zoomScale: this.state.zoomScale,
      isConnecting: this.state.isConnecting,
      connectingFromTaskId: this.state.connectingFromTaskId,
      selectedTaskId: selectedTaskId,
      renderMode: this.state.renderMode,
      showDependencyArrows: showDependencyArrows
    };
  }
  
  /**
   * 放大画布
   */
  private zoomIn(): void {
    const newScale = Math.min(this.state.zoomScale + this.ZOOM_STEP, this.MAX_ZOOM);
    this.state.zoomScale = Math.round(newScale * 10) / 10; // 保留一位小数
  }
  
  /**
   * 缩小画布
   */
  private zoomOut(): void {
    const newScale = Math.max(this.state.zoomScale - this.ZOOM_STEP, this.MIN_ZOOM);
    this.state.zoomScale = Math.round(newScale * 10) / 10; // 保留一位小数
  }
  
  /**
   * 重置缩放
   */
  private resetZoom(): void {
    this.state.zoomScale = 1.0;
  }

  /**
   * 计算项目内容的边界框（Canvas 坐标，包含所有可见节点）
   */
  private calculateContentBounds(project: Project): ContentBounds {
    if (!project || project.tasks.length === 0) {
      const bounds: ContentBounds = { minX: 0, minY: 0, maxX: 800, maxY: 600 };
      return bounds;
    }

    let minX = Infinity;
    let minY = Infinity;
    let maxX = -Infinity;
    let maxY = -Infinity;

    const NODE_WIDTH = 200;
    const NODE_HEIGHT = 120;
    const PADDING = 150; // 增加边距到 150px，确保有足够空间

    console.log(`[CanvasController] ========== 开始计算边界 ==========`);
    console.log(`[CanvasController] canvasOffset: X=${this.state.canvasOffsetX}, Y=${this.state.canvasOffsetY}`);
    console.log(`[CanvasController] 任务数量: ${project.tasks.length}`);

    // 遍历所有任务，计算在 Canvas 上的坐标
    project.tasks.forEach((task, index) => {
      // Canvas 坐标 = 任务坐标 + offset
      const canvasX = task.x + this.state.canvasOffsetX;
      const canvasY = task.y + this.state.canvasOffsetY;
      const canvasRight = canvasX + NODE_WIDTH;
      const canvasBottom = canvasY + NODE_HEIGHT;
      
      console.log(`[CanvasController] 任务${index} "${task.name}":`);
      console.log(`  原始坐标: (${task.x}, ${task.y})`);
      console.log(`  Canvas坐标: (${canvasX}, ${canvasY}) -> (${canvasRight}, ${canvasBottom})`);
      
      // 只考虑在 Canvas 可见范围内的节点（至少部分可见）
      // 完全在 Canvas 外的节点不应该影响边界计算
      const isVisible = canvasRight > 0 && canvasX < 3000 && canvasBottom > 0 && canvasY < 3000;
      
      if (isVisible) {
        minX = Math.min(minX, canvasX);
        minY = Math.min(minY, canvasY);
        maxX = Math.max(maxX, canvasRight);
        maxY = Math.max(maxY, canvasBottom);
        console.log(`  ✓ 可见，更新边界`);
      } else {
        console.log(`  ✗ 不可见，跳过`);
      }
    });

    console.log(`[CanvasController] 可见节点边界: minX=${minX}, minY=${minY}, maxX=${maxX}, maxY=${maxY}`);

    // 如果没有可见节点，返回默认边界
    if (minX === Infinity || minY === Infinity) {
      console.warn(`[CanvasController] 没有可见节点，使用默认边界`);
      const bounds: ContentBounds = { minX: 0, minY: 0, maxX: 3000, maxY: 3000 };
      return bounds;
    }

    // 添加边距
    minX = minX - PADDING;
    minY = minY - PADDING;
    maxX = maxX + PADDING;
    maxY = maxY + PADDING;

    console.log(`[CanvasController] 添加边距后: minX=${minX}, minY=${minY}, maxX=${maxX}, maxY=${maxY}`);

    // 限制在 Canvas 范围内（0-3000）
    minX = Math.max(0, minX);
    minY = Math.max(0, minY);
    maxX = Math.min(3000, maxX);
    maxY = Math.min(3000, maxY);

    // 最终检查
    if (minX >= maxX) {
      console.warn(`[CanvasController] ⚠️ minX >= maxX (${minX} >= ${maxX})，使用整个Canvas`);
      minX = 0;
      maxX = 3000;
    }
    if (minY >= maxY) {
      console.warn(`[CanvasController] ⚠️ minY >= maxY (${minY} >= ${maxY})，使用整个Canvas`);
      minY = 0;
      maxY = 3000;
    }

    const bounds: ContentBounds = { minX, minY, maxX, maxY };
    console.log(`[CanvasController] ========== 最终导出边界 ==========`);
    console.log(`[CanvasController] 边界: (${bounds.minX}, ${bounds.minY}) -> (${bounds.maxX}, ${bounds.maxY})`);
    console.log(`[CanvasController] 尺寸: ${bounds.maxX - bounds.minX} x ${bounds.maxY - bounds.minY}`);
    return bounds;
  }

  /**
   * 获取 Canvas 的 PixelMap（用于导出图片）
   * 保持当前深色/浅色模式，根据Canvas实际尺寸导出
   * 导出的图片会包含 EasyFlow 水印
   * 
   * @param project 项目数据
   * @param selectedTaskId 当前选中的任务ID
   * @returns Promise<PixelMap | null> Canvas 的像素图
   */
  public async getCanvasPixelMap(project?: Project, selectedTaskId?: string): Promise<image.PixelMap | null> {
    try {
      const context = this.renderer.getContext();
      
      if (!context) {
        console.error('[CanvasController] 无法获取 Canvas 上下文');
        return null;
      }

      // 获取Canvas的实际像素尺寸
      const canvasWidth = context.width;
      const canvasHeight = context.height;
      
      console.log(`[CanvasController] 当前模式: ${this.renderer.getDarkMode() ? '深色' : '浅色'}`);
      console.log(`[CanvasController] Canvas 实际尺寸: ${canvasWidth}x${canvasHeight}`);

      // 绘制水印（在获取 PixelMap 之前）
      this.renderer.drawWatermark(canvasWidth, canvasHeight);
      console.log('[CanvasController] ✅ 已添加水印');

      // 根据Canvas实际尺寸导出（避免黑色区域）
      const pixelMap = await context.getPixelMap(0, 0, canvasWidth, canvasHeight);
      
      console.log('[CanvasController] ✅ 成功获取 Canvas PixelMap');
      
      // 重新渲染以清除水印（恢复正常显示）
      if (project) {
        const config = this.getRenderConfig(selectedTaskId || null);
        this.renderer.render(project, config);
        console.log('[CanvasController] ✅ 已清除水印，恢复正常显示');
      }
      
      return pixelMap;
    } catch (error) {
      console.error('[CanvasController] 获取 PixelMap 失败:', error);
      return null;
    }
  }
}
