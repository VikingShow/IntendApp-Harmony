// File: entry/src/main/ets/core/EventBus.ets

// 定义具体的事件参数类型
export type EventArgs = string | number | boolean | object | null;

export type EventHandler = (...args: EventArgs[]) => void;

export class EventBus {
  private static instance: EventBus;
  private handlers: Map<string, EventHandler[]> = new Map();

  private constructor() {}

  public static getInstance(): EventBus {
    if (!EventBus.instance) {
      EventBus.instance = new EventBus();
    }
    return EventBus.instance;
  }

  // 订阅事件
  public on(event: string, handler: EventHandler): void {
    if (!this.handlers.has(event)) {
      this.handlers.set(event, []);
    }
    this.handlers.get(event)!.push(handler);
  }

  // 取消订阅
  public off(event: string, handler: EventHandler): void {
    if (this.handlers.has(event)) {
      const handlers = this.handlers.get(event)!;
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
      }
    }
  }

  // 发布事件
  public emit(event: string, ...args: EventArgs[]): void {
    if (this.handlers.has(event)) {
      const handlers = this.handlers.get(event)!;
      handlers.forEach(handler => {
        try {
          handler(...args);
        } catch (error) {
          console.error(`Error in event handler for ${event}:`, error);
        }
      });
    }
  }

  // 清除所有事件监听器
  public clear(): void {
    this.handlers.clear();
  }

  // 清除特定事件的所有监听器
  public clearEvent(event: string): void {
    this.handlers.delete(event);
  }
}

// 预定义的事件类型
export enum Events {
  TASK_SELECTED = 'task_selected',
  TASK_UPDATED = 'task_updated',
  TASK_DELETED = 'task_deleted',
  PROJECT_LOADED = 'project_loaded',
  PROJECT_SAVED = 'project_saved',
  CANVAS_RENDER = 'canvas_render',
  START_CONNECTING = 'start_connecting',
  STOP_CONNECTING = 'stop_connecting',
  CRITICAL_PATH_CALCULATED = 'critical_path_calculated'
}

