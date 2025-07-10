// File: entry/src/main/ets/services/CriticalPathService.ts

import { Project, TaskNode, Dependency } from '../model/ProjectData';

/**
 * 封装了关键路径方法 (CPM) 的计算逻辑
 */
export class CriticalPathService {
  public calculate(project: Project): void {
    if (project.tasks.length === 0) {
      return;
    }

    // 1. 初始化所有节点的计算属性
    project.tasks.forEach(task => {
      task.earlyStart = 0;
      task.earlyFinish = 0;
      task.lateStart = 0;
      task.lateFinish = 0;
      task.isCritical = false;
    });

    // 2. 正向传递，计算最早开始/结束时间
    this.forwardPass(project);

    // 3. 反向传递，计算最晚开始/结束时间
    this.backwardPass(project);

    // 4. 计算浮动时间并确定关键节点
    this.calculateSlack(project);
  }

  private forwardPass(project: Project): void {
    // 简单的拓扑排序：按ID顺序处理，假设ID是按创建顺序的
    // 在实际复杂项目中，需要一个真正的拓扑排序算法
    project.tasks.forEach(task => {
      const predecessors = project.dependencies.filter(d => d.toId === task.id);
      let maxEF = 0;
      predecessors.forEach(dep => {
        const predNode = project.tasks.find(t => t.id === dep.fromId);
        if (predNode && predNode.earlyFinish! > maxEF) {
          maxEF = predNode.earlyFinish!;
        }
      });
      task.earlyStart = maxEF;
      task.earlyFinish = task.earlyStart + task.duration;
    });
  }

  private backwardPass(project: Project): void {
    // 找到项目的最晚完成时间，即所有任务中最大的EF
    const maxProjectEF = Math.max(...project.tasks.map(t => t.earlyFinish || 0));

    // 从后向前遍历任务
    const reversedTasks = [...project.tasks].reverse();
    reversedTasks.forEach(task => {
      const successors = project.dependencies.filter(d => d.fromId === task.id);
      if (successors.length === 0) {
        // 如果是结束节点，其最晚完成时间等于项目的最晚完成时间
        task.lateFinish = maxProjectEF;
      } else {
        let minLS = Infinity;
        successors.forEach(dep => {
          const succNode = project.tasks.find(t => t.id === dep.toId);
          if (succNode && succNode.lateStart! < minLS) {
            minLS = succNode.lateStart!;
          }
        });
        task.lateFinish = minLS;
      }
      task.lateStart = task.lateFinish - task.duration;
    });
  }

  private calculateSlack(project: Project): void {
    project.tasks.forEach(task => {
      const slack = task.lateStart! - task.earlyStart!;
      // 浮动时间为0（或一个很小的数，以防浮点数误差）的节点是关键节点
      if (slack <= 0.001) {
        task.isCritical = true;
      }
    });
  }
}
