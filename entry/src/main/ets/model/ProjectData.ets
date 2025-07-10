// File: entry/src/main/ets/model/ProjectData.ts

/**
 * 子任务清单项目接口
 */
export interface ChecklistItem {
  id: string;
  text: string;
  isCompleted: boolean;
}

/**
 * 任务节点接口 (V2.0)
 * 引入了明确的起止日期、子任务清单和进度属性
 */
export interface TaskNode {
  id: string;
  name: string;
  startDate: Date;    // 新增：开始日期
  endDate: Date;      // 新增：结束日期
  checklist: ChecklistItem[]; // 新增：子任务清单

  x: number;
  y: number;

  // 关键路径计算属性
  earlyStart?: number;
  earlyFinish?: number;
  lateStart?: number;
  lateFinish?: number;
  isCritical?: boolean;
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
