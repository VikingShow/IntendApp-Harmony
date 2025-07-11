// File: entry/src/main/ets/model/ProjectData.ts

export interface ChecklistItem {
  id: string;
  text: string;
  isCompleted: boolean;
}

export interface TaskNode {
  id: string;
  name: string;
  startDate: Date;
  endDate: Date;
  checklist: ChecklistItem[];
  x: number;
  y: number;
  earlyStart?: number;
  earlyFinish?: number;
  lateStart?: number;
  lateFinish?: number;
  isCritical?: boolean;
}

export interface Dependency {
  fromId: string;
  toId: string;
}

@Observed
export class Project {
  id: string; // 新增：项目的唯一ID
  name: string = '新项目';
  lastModified: number; // 新增：最后修改时间的时间戳
  category: string = '其他'; // 新增：项目分类

  tasks: TaskNode[] = [];
  dependencies: Dependency[] = [];

  // 构造函数，用于创建新项目时自动生成ID和时间
  constructor(id?: string, name?: string) {
    this.id = id || `project_${Date.now()}`;
    this.name = name || '新项目';
    this.lastModified = Date.now();
  }

  addTask(task: TaskNode) {
    this.tasks.push(task);
  }
}
