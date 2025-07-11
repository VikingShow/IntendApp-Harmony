// File: entry/src/main/ets/services/StatisticsService.ets

import { Project, TaskNode } from '../model/ProjectData';
import { StorageService, ProjectMeta } from './StorageService';

export interface ProjectStatistics {
  projectId: string;
  projectName: string;
  totalTasks: number;
  completedTasks: number;
  totalChecklistItems: number;
  completedChecklistItems: number;
  progress: number;
  checklistProgress: number;
  averageTaskDuration: number;
  overdueTasks: number;
  upcomingDeadlines: number;
  lastModified: number;
}

export interface GlobalStatistics {
  totalProjects: number;
  totalTasks: number;
  totalCompletedTasks: number;
  overallProgress: number;
  averageProjectProgress: number;
  mostActiveProject?: ProjectStatistics;
  recentActivity: ActivityData[];
  categoryDistribution: CategoryData[];
}

export interface ActivityData {
  date: string;
  completedTasks: number;
  newTasks: number;
}

export interface CategoryData {
  category: string;
  count: number;
  percentage: number;
}

export interface TimeRange {
  start: Date;
  end: Date;
}

export class StatisticsService {
  private static instance: StatisticsService;
  private storageService: StorageService | null = null;

  static getInstance(): StatisticsService {
    if (!StatisticsService.instance) {
      StatisticsService.instance = new StatisticsService();
    }
    return StatisticsService.instance;
  }

  setStorageService(storageService: StorageService): void {
    this.storageService = storageService;
  }

  /**
   * 获取单个项目统计
   */
  async getProjectStatistics(projectId: string): Promise<ProjectStatistics | null> {
    if (!this.storageService) {
      throw new Error('存储服务未初始化');
    }

    const project = await this.storageService.getProject(projectId);
    if (!project) {
      return null;
    }

    const completedTasks = project.tasks.filter(task => 
      task.checklist.every(item => item.isCompleted)
    ).length;

    const totalChecklistItems = project.tasks.reduce((sum, task) => 
      sum + task.checklist.length, 0
    );
    const completedChecklistItems = project.tasks.reduce((sum, task) => 
      sum + task.checklist.filter(item => item.isCompleted).length, 0
    );

    const now = new Date();
    const overdueTasks = project.tasks.filter(task => 
      task.endDate < now && !task.checklist.every(item => item.isCompleted)
    ).length;

    const upcomingDeadlines = project.tasks.filter(task => {
      const daysUntilDeadline = Math.ceil((task.endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      return daysUntilDeadline <= 7 && daysUntilDeadline > 0 && !task.checklist.every(item => item.isCompleted);
    }).length;

    const averageTaskDuration = project.tasks.length > 0 
      ? project.tasks.reduce((sum, task) => {
          const duration = Math.ceil((task.endDate.getTime() - task.startDate.getTime()) / (1000 * 60 * 60 * 24));
          return sum + duration;
        }, 0) / project.tasks.length
      : 0;

    return {
      projectId: project.id,
      projectName: project.name,
      totalTasks: project.tasks.length,
      completedTasks: completedTasks,
      totalChecklistItems: totalChecklistItems,
      completedChecklistItems: completedChecklistItems,
      progress: project.tasks.length > 0 ? (completedTasks / project.tasks.length) * 100 : 0,
      checklistProgress: totalChecklistItems > 0 ? (completedChecklistItems / totalChecklistItems) * 100 : 0,
      averageTaskDuration: Math.round(averageTaskDuration),
      overdueTasks: overdueTasks,
      upcomingDeadlines: upcomingDeadlines,
      lastModified: project.lastModified
    };
  }

  /**
   * 获取全局统计
   */
  async getGlobalStatistics(): Promise<GlobalStatistics> {
    if (!this.storageService) {
      throw new Error('存储服务未初始化');
    }

    const projectList = await this.storageService.getProjectList();
    const allProjects: Project[] = [];
    for (const meta of projectList) {
      const project = await this.storageService.getProject(meta.id);
      if (project) allProjects.push(project);
    }
    const projectStats: ProjectStatistics[] = [];
    let totalTasks = 0;
    let totalCompletedTasks = 0;

    for (const project of allProjects) {
      const stats = await this.getProjectStatistics(project.id);
      if (stats) {
        projectStats.push(stats);
        totalTasks += stats.totalTasks;
        totalCompletedTasks += stats.completedTasks;
      }
    }

    const mostActiveProject = projectStats.length > 0 
      ? projectStats.reduce((max, current) => 
          current.lastModified > max.lastModified ? current : max
        )
      : undefined;

    // 真实最近活动
    const recentActivity = this.calculateRecentActivity(allProjects);
    const categoryDistribution = this.calculateCategoryDistribution(projectList);

    return {
      totalProjects: projectList.length,
      totalTasks: totalTasks,
      totalCompletedTasks: totalCompletedTasks,
      overallProgress: totalTasks > 0 ? (totalCompletedTasks / totalTasks) * 100 : 0,
      averageProjectProgress: projectStats.length > 0 
        ? projectStats.reduce((sum, stats) => sum + stats.progress, 0) / projectStats.length 
        : 0,
      mostActiveProject: mostActiveProject,
      recentActivity: recentActivity,
      categoryDistribution: categoryDistribution
    };
  }

  /**
   * 获取时间范围内的统计
   */
  async getStatisticsByTimeRange(timeRange: TimeRange): Promise<ProjectStatistics[]> {
    if (!this.storageService) {
      throw new Error('存储服务未初始化');
    }

    const projectList = await this.storageService.getProjectList();
    const results: ProjectStatistics[] = [];

    for (const meta of projectList) {
      try {
        const project = await this.storageService.getProject(meta.id);
        if (!project) continue;

        // 检查项目是否在时间范围内有活动
        const hasActivityInRange = project.tasks.some(task => {
          const taskStart = task.startDate.getTime();
          const taskEnd = task.endDate.getTime();
          const rangeStart = timeRange.start.getTime();
          const rangeEnd = timeRange.end.getTime();

          return (taskStart >= rangeStart && taskStart <= rangeEnd) ||
                 (taskEnd >= rangeStart && taskEnd <= rangeEnd) ||
                 (taskStart <= rangeStart && taskEnd >= rangeEnd);
        });

        if (hasActivityInRange) {
          const stats = await this.getProjectStatistics(meta.id);
          if (stats) {
            results.push(stats);
          }
        }
      } catch (error) {
        console.error(`获取项目 ${meta.id} 时间范围统计失败:`, error);
      }
    }

    return results;
  }

  /**
   * 获取生产力趋势
   */
  async getProductivityTrend(days: number = 30): Promise<ActivityData[]> {
    if (!this.storageService) {
      return [];
    }

    const trend: ActivityData[] = [];
    const now = new Date();

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];

      // 这里简化处理，实际应用中需要更复杂的数据分析
      const activityData: ActivityData = {
        date: dateStr,
        completedTasks: Math.floor(Math.random() * 5), // 模拟数据
        newTasks: Math.floor(Math.random() * 3)
      };
      trend.push(activityData);
    }

    return trend;
  }

  // 真实最近活动统计
  private calculateRecentActivity(allProjects: Project[]): ActivityData[] {
    const now = new Date();
    const recentActivity: ActivityData[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];
      let completedTasks = 0;
      let newTasks = 0;
      for (const project of allProjects) {
        for (const task of project.tasks) {
          // 新增
          if (task.startDate.toISOString().split('T')[0] === dateStr) newTasks++;
          // 完成
          if (
            task.checklist.length > 0 &&
            task.checklist.every(item => item.isCompleted) &&
            task.endDate.toISOString().split('T')[0] === dateStr
          ) completedTasks++;
        }
      }
      recentActivity.push({ date: dateStr, completedTasks, newTasks });
    }
    return recentActivity;
  }

  /**
   * 计算分类分布
   */
  private calculateCategoryDistribution(projectList: ProjectMeta[]): CategoryData[] {
    const categoryMap = new Map<string, number>();
    for (const meta of projectList) {
      const category = meta.category || '其他';
      categoryMap.set(category, (categoryMap.get(category) || 0) + 1);
    }
    const total = projectList.length;
    return Array.from(categoryMap.entries()).map(entry => {
      const category = entry[0];
      const count = entry[1];
      const item: CategoryData = {
        category: category,
        count: count,
        percentage: total > 0 ? Math.round((count / total) * 100) : 0
      };
      return item;
    });
  }
} 