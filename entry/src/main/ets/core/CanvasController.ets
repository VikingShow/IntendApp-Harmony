
import { Project, TaskNode } from '../model/ProjectData';
import { CanvasRenderer, RenderConfig } from './CanvasRenderer';
import promptAction from '@ohos.promptAction';

export interface CanvasState {
  canvasOffsetX: number;
  canvasOffsetY: number;
  isDraggingCanvas: boolean;
  isDraggingNode: boolean;
  isConnecting: boolean;
  connectingFromTaskId: string | null;
  isCanvasLocked: boolean;
  lastTouchX: number;
  lastTouchY: number;
  dragOffsetX: number;
  dragOffsetY: number;
  selectedTask: TaskNode | null;
}

export interface CanvasActions {
  handleTouch: (event: TouchEvent, project: Project, selectedTaskId: string | null) => void;
  resetCanvas: () => void;
  toggleCanvasLock: () => void;
  startConnecting: (taskId: string) => void;
  stopConnecting: () => void;
  getRenderConfig: (selectedTaskId: string | null) => RenderConfig;
}

export class CanvasController {
  private renderer: CanvasRenderer;
  private state: CanvasState = {
    canvasOffsetX: 0,
    canvasOffsetY: 0,
    isDraggingCanvas: false,
    isDraggingNode: false,
    isConnecting: false,
    connectingFromTaskId: null,
    isCanvasLocked: false,
    lastTouchX: 0,
    lastTouchY: 0,
    dragOffsetX: 0,
    dragOffsetY: 0,
    selectedTask: null
  };

  private onTaskSelect: ((task: TaskNode | null) => void) | null = null;
  private onDependencyCreate: ((fromId: string, toId: string) => void) | null = null;
  private onTaskMove: ((taskId: string, x: number, y: number) => void) | null = null;

  constructor() {
    this.renderer = new CanvasRenderer();
  }

  public setCallbacks(
    onTaskSelect: (task: TaskNode | null) => void,
    onDependencyCreate: (fromId: string, toId: string) => void,
    onTaskMove: (taskId: string, x: number, y: number) => void
  ): void {
    this.onTaskSelect = onTaskSelect;
    this.onDependencyCreate = onDependencyCreate;
    this.onTaskMove = onTaskMove;
  }

  public getRenderer(): CanvasRenderer {
    return this.renderer;
  }

  public getState(): CanvasState {
    return this.state;
  }

  public getActions(): CanvasActions {
    return {
      handleTouch: this.handleTouch.bind(this),
      resetCanvas: this.resetCanvas.bind(this),
      toggleCanvasLock: this.toggleCanvasLock.bind(this),
      startConnecting: this.startConnecting.bind(this),
      stopConnecting: this.stopConnecting.bind(this),
      getRenderConfig: this.getRenderConfig.bind(this)
    };
  }

  private handleTouch(event: TouchEvent, project: Project, selectedTaskId: string | null): void {
    if (this.state.isCanvasLocked) return;

    const buttonWidth = 32;
    const realTouchX = event.touches[0].x - buttonWidth;
    const realTouchY = event.touches[0].y;

    let hitNode: TaskNode | null = null;
    const HIT_PADDING = 8;

    // 命中检测
    for (let i = project.tasks.length - 1; i >= 0; i--) {
      const task = project.tasks[i];
      const nodeLeft = task.x + this.state.canvasOffsetX - HIT_PADDING;
      const nodeTop = task.y + this.state.canvasOffsetY - HIT_PADDING;
      const nodeRight = nodeLeft + 200 + HIT_PADDING * 2;
      const nodeBottom = nodeTop + 120 + HIT_PADDING * 2;
      
      if (realTouchX >= nodeLeft && realTouchX <= nodeRight &&
          realTouchY >= nodeTop && realTouchY <= nodeBottom) {
        hitNode = task;
        break;
      }
    }

    switch (event.type) {
      case TouchType.Down:
        this.handleTouchDown(realTouchX, realTouchY, hitNode);
        break;
      case TouchType.Move:
        this.handleTouchMove(realTouchX, realTouchY);
        break;
      case TouchType.Up:
        this.handleTouchUp();
        break;
    }
  }

  private handleTouchDown(touchX: number, touchY: number, hitNode: TaskNode | null): void {
    if (this.state.isConnecting && this.state.connectingFromTaskId) {
      this.handleConnectingTouchDown(hitNode);
      return;
    }

    if (hitNode) {
      this.state.selectedTask = hitNode;
      this.state.isDraggingNode = true;
      this.state.isDraggingCanvas = false;
      this.state.dragOffsetX = touchX - (hitNode.x + this.state.canvasOffsetX);
      this.state.dragOffsetY = touchY - (hitNode.y + this.state.canvasOffsetY);
      
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
    
    this.stopConnecting();
  }

  private handleTouchMove(touchX: number, touchY: number): void {
    if (this.state.isDraggingNode && this.state.selectedTask) {
      const newX = touchX - this.state.dragOffsetX - this.state.canvasOffsetX;
      const newY = touchY - this.state.dragOffsetY - this.state.canvasOffsetY;
      
      if (this.onTaskMove) {
        this.onTaskMove(this.state.selectedTask.id, newX, newY);
      }
    } else if (this.state.isDraggingCanvas) {
      this.state.canvasOffsetX += touchX - this.state.lastTouchX;
      this.state.canvasOffsetY += touchY - this.state.lastTouchY;
      this.state.lastTouchX = touchX;
      this.state.lastTouchY = touchY;
    }
  }

  private handleTouchUp(): void {
    this.state.isDraggingCanvas = false;
    this.state.isDraggingNode = false;
  }

  private resetCanvas(): void {
    this.state.canvasOffsetX = 0;
    this.state.canvasOffsetY = 0;
  }

  private toggleCanvasLock(): void {
    this.state.isCanvasLocked = !this.state.isCanvasLocked;
  }

  private startConnecting(taskId: string): void {
    this.state.isConnecting = true;
    this.state.connectingFromTaskId = taskId;
  }

  private stopConnecting(): void {
    this.state.isConnecting = false;
    this.state.connectingFromTaskId = null;
  }

  private getRenderConfig(selectedTaskId: string | null): RenderConfig {
    return {
      canvasOffsetX: this.state.canvasOffsetX,
      canvasOffsetY: this.state.canvasOffsetY,
      isConnecting: this.state.isConnecting,
      connectingFromTaskId: this.state.connectingFromTaskId,
      selectedTaskId: selectedTaskId
    };
  }
}


