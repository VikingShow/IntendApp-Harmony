// File: entry/src/main/ets/services/CriticalPathService.ts

import { Dependency } from '../model/ProjectData';

// Export the interface so it can be used in other files
export interface TaskWithDuration {
  id: string;
  duration: number;
  earlyStart?: number;
  earlyFinish?: number;
  lateStart?: number;
  lateFinish?: number;
  isCritical?: boolean;
}

export class CriticalPathService {
  public calculate(tasks: TaskWithDuration[], dependencies: Dependency[]): void {
    if (tasks.length === 0) {
      return;
    }

    // 1. 初始化
    tasks.forEach(task => {
      task.earlyStart = 0;
      task.earlyFinish = 0;
      task.lateStart = 0;
      task.lateFinish = 0;
      task.isCritical = false;
    });

    // 2. 正向传递
    tasks.forEach(task => {
      const predecessors = dependencies.filter(d => d.toId === task.id);
      let maxEF = 0;
      predecessors.forEach(dep => {
        const predNode = tasks.find(t => t.id === dep.fromId);
        if (predNode && predNode.earlyFinish! > maxEF) {
          maxEF = predNode.earlyFinish!;
        }
      });
      task.earlyStart = maxEF;
      task.earlyFinish = task.earlyStart + task.duration;
    });

    // 3. 反向传递
    const maxProjectEF = Math.max(...tasks.map(t => t.earlyFinish || 0));
    const reversedTasks = [...tasks].reverse();
    reversedTasks.forEach(task => {
      const successors = dependencies.filter(d => d.fromId === task.id);
      if (successors.length === 0) {
        task.lateFinish = maxProjectEF;
      } else {
        let minLS = Infinity;
        successors.forEach(dep => {
          const succNode = tasks.find(t => t.id === dep.toId);
          if (succNode && succNode.lateStart! < minLS) {
            minLS = succNode.lateStart!;
          }
        });
        task.lateFinish = minLS;
      }
      task.lateStart = task.lateFinish - task.duration;
    });

    // 4. 计算浮动时间
    tasks.forEach(task => {
      const slack = task.lateStart! - task.earlyStart!;
      if (slack <= 0.001) {
        task.isCritical = true;
      }
    });
  }
}
