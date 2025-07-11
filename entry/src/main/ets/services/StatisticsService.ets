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
    const projectStats: ProjectStatistics[] = [];
    let totalTasks = 0;
    let totalCompletedTasks = 0;

    for (const meta of projectList) {
      try {
        const stats = await this.getProjectStatistics(meta.id);
        if (stats) {
          projectStats.push(stats);
          totalTasks += stats.totalTasks;
          totalCompletedTasks += stats.completedTasks;
        }
      } catch (error) {
        console.error(`获取项目 ${meta.id} 统计失败:`, error);
      }
    }

    const mostActiveProject = projectStats.length > 0 
      ? projectStats.reduce((max, current) => 
          current.lastModified > max.lastModified ? current : max
        )
      : undefined;

    // 计算最近活动（简化版本）
    const recentActivity = this.calculateRecentActivity(projectStats);

    // 计算分类分布（简化版本）
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

  /**
   * 计算最近活动
   */
  private calculateRecentActivity(projectStats: ProjectStatistics[]): ActivityData[] {
    const now = new Date();
    const recentActivity: ActivityData[] = [];

    for (let i = 6; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];

      // 简化计算，实际应用中需要更精确的数据
      const completedTasks = projectStats.reduce((sum, stats) => {
        // 模拟基于最后修改时间的完成情况
        const daysSinceModified = Math.ceil((now.getTime() - stats.lastModified) / (1000 * 60 * 60 * 24));
        return sum + (daysSinceModified === i ? Math.floor(stats.completedTasks * 0.1) : 0);
      }, 0);

      const activityData: ActivityData = {
        date: dateStr,
        completedTasks: completedTasks,
        newTasks: Math.floor(Math.random() * 2) // 模拟数据
      };
      recentActivity.push(activityData);
    }

    return recentActivity;
  }

  /**
   * 计算分类分布
   */
  private calculateCategoryDistribution(projectList: ProjectMeta[]): CategoryData[] {
    const categories = ['开发', '设计', '营销', '研究', '其他'];
    const distribution: CategoryData[] = [];
    
    for (const category of categories) {
      const categoryData: CategoryData = {
        category: category,
        count: Math.floor(Math.random() * 10) + 1, // 模拟数据
        percentage: 0
      };
      distribution.push(categoryData);
    }

    const total = distribution.reduce((sum, item) => sum + item.count, 0);
    distribution.forEach(item => {
      item.percentage = Math.round((item.count / total) * 100);
    });

    return distribution;
  }
} 