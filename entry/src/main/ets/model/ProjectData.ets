// File: entry/src/main/ets/model/ProjectData.ts

/**
 * 任务节点接口
 * 新增了用于关键路径计算的可选属性
 */
export interface TaskNode {
  id: string;
  name: string;
  duration: number;
  x: number;
  y: number;

  // 新增：用于关键路径计算的属性
  earlyStart?: number;
  earlyFinish?: number;
  lateStart?: number;
  lateFinish?: number;
  isCritical?: boolean; // 标记是否为关键节点
}

/**
 * 依赖关系接口
 */
export interface Dependency {
  fromId: string;
  toId: string;
}

/**
 * 项目类
 */
@Observed
export class Project {
  name: string = '新项目';
  tasks: TaskNode[] = [];
  dependencies: Dependency[] = [];

  addTask(task: TaskNode) {
    this.tasks.push(task);
  }
}
