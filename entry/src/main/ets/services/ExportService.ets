// File: entry/src/main/ets/services/ExportService.ets

import { Project, TaskNode } from '../model/ProjectData';
import { StorageService } from './StorageService';

export interface ExportData {
  project: Project;
  exportTime: string;
  version: string;
  totalTasks: number;
  completedTasks: number;
  progress: number;
}

export interface ProjectReportSummary {
  totalTasks: number;
  completedTasks: number;
  totalChecklistItems: number;
  completedChecklistItems: number;
  progress: number;
  checklistProgress: number;
}

export interface ProjectReport {
  projectName: string;
  exportTime: string;
  summary: ProjectReportSummary;
  tasks: TaskReport[];
}

export interface AllProjectsExportData {
  projects: ExportData[];
  exportTime: string;
  version: string;
  totalProjects: number;
}

export interface TaskReport {
  name: string;
  startDate: string;
  endDate: string;
  duration: number;
  checklistItems: number;
  completedChecklistItems: number;
  isCompleted: boolean;
}

export class ExportService {
  private static instance: ExportService;
  private storageService: StorageService | null = null;

  static getInstance(): ExportService {
    if (!ExportService.instance) {
      ExportService.instance = new ExportService();
    }
    return ExportService.instance;
  }

  setStorageService(storageService: StorageService): void {
    this.storageService = storageService;
  }

  /**
   * 导出单个项目数据
   */
  async exportProject(projectId: string): Promise<string> {
    if (!this.storageService) {
      throw new Error('存储服务未初始化');
    }

    const project = await this.storageService.getProject(projectId);
    if (!project) {
      throw new Error('项目不存在');
    }

    const completedTasks = project.tasks.filter(task => 
      task.checklist.every(item => item.isCompleted)
    ).length;

    const exportData: ExportData = {
      project: project,
      exportTime: new Date().toISOString(),
      version: '1.0.0',
      totalTasks: project.tasks.length,
      completedTasks: completedTasks,
      progress: project.tasks.length > 0 ? (completedTasks / project.tasks.length) * 100 : 0
    };

    return JSON.stringify(exportData, null, 2);
  }

  /**
   * 导出所有项目数据
   */
  async exportAllProjects(): Promise<string> {
    if (!this.storageService) {
      throw new Error('存储服务未初始化');
    }

    const projectList = await this.storageService.getProjectList();
    const allProjects: ExportData[] = [];

    for (const meta of projectList) {
      try {
        const project = await this.storageService.getProject(meta.id);
        if (project) {
          const completedTasks = project.tasks.filter(task => 
            task.checklist.every(item => item.isCompleted)
          ).length;

          const exportData: ExportData = {
            project: project,
            exportTime: new Date().toISOString(),
            version: '1.0.0',
            totalTasks: project.tasks.length,
            completedTasks: completedTasks,
            progress: project.tasks.length > 0 ? (completedTasks / project.tasks.length) * 100 : 0
          };
          allProjects.push(exportData);
        }
      } catch (error) {
        console.error(`导出项目 ${meta.id} 失败:`, error);
      }
    }

    const exportData: AllProjectsExportData = {
      projects: allProjects,
      exportTime: new Date().toISOString(),
      version: '1.0.0',
      totalProjects: allProjects.length
    };

    return JSON.stringify(exportData, null, 2);
  }

  /**
   * 生成项目报告
   */
  async generateProjectReport(projectId: string): Promise<string> {
    if (!this.storageService) {
      throw new Error('存储服务未初始化');
    }

    const project = await this.storageService.getProject(projectId);
    if (!project) {
      throw new Error('项目不存在');
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

    const summary: ProjectReportSummary = {
      totalTasks: project.tasks.length,
      completedTasks: completedTasks,
      totalChecklistItems: totalChecklistItems,
      completedChecklistItems: completedChecklistItems,
      progress: project.tasks.length > 0 ? (completedTasks / project.tasks.length) * 100 : 0,
      checklistProgress: totalChecklistItems > 0 ? (completedChecklistItems / totalChecklistItems) * 100 : 0
    };

    const report: ProjectReport = {
      projectName: project.name,
      exportTime: new Date().toLocaleString('zh-CN'),
      summary: summary,
      tasks: project.tasks.map(task => {
        const taskReport: TaskReport = {
          name: task.name,
          startDate: task.startDate.toLocaleDateString('zh-CN'),
          endDate: task.endDate.toLocaleDateString('zh-CN'),
          duration: Math.ceil((task.endDate.getTime() - task.startDate.getTime()) / (1000 * 60 * 60 * 24)) + 1,
          checklistItems: task.checklist.length,
          completedChecklistItems: task.checklist.filter(item => item.isCompleted).length,
          isCompleted: task.checklist.every(item => item.isCompleted)
        };
        return taskReport;
      })
    };

    return JSON.stringify(report, null, 2);
  }
} 