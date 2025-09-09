// File: entry/src/main/ets/services/FileStorageService.ets
import fs from '@ohos.file.fs';
import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import util from '@ohos.util';

// 项目元数据接口
export interface ProjectMeta {
  id: string;
  name: string;
  lastModified: number;
  category: string;
}

// 可存储的任务节点接口（将Date转换为字符串）
interface StorableTaskNode extends Omit<TaskNode, 'startDate' | 'endDate'> {
  startDate: string;
  endDate: string;
}

// 可存储的项目接口
interface StorableProject extends Omit<Project, 'tasks' | 'addTask'> {
  tasks: StorableTaskNode[];
  category: string;
}

// 存储统计接口
interface StorageStats {
  totalProjects: number;
  totalSize: number;
}

// 迁移结果接口
interface MigrationResult {
  success: boolean;
  migratedCount: number;
  errors: string[];
}

// 导出数据接口
interface ExportData {
  version: string;
  exportTime: string;
  project: Project;
}

// 导入数据接口
interface ImportData {
  version?: string;
  exportTime?: string;
  project: Project;
}

/**
 * 文件系统存储服务
 * 使用文件系统进行数据持久化，支持项目数据的保存、加载和删除
 */
export class FileStorageService {
  private static instance: FileStorageService;
  private baseDir: string;
  private projectsDir: string;
  private metaFile: string;

  private constructor(baseDir: string) {
    this.baseDir = baseDir;
    this.projectsDir = `${baseDir}/projects`;
    this.metaFile = `${baseDir}/project_meta.json`;
    this.initializeDirectories();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(baseDir: string): FileStorageService {
    if (!FileStorageService.instance) {
      FileStorageService.instance = new FileStorageService(baseDir);
    }
    return FileStorageService.instance;
  }

  /**
   * 初始化目录结构
   */
  private async initializeDirectories(): Promise<void> {
    try {
      // 确保基础目录存在
      if (!fs.accessSync(this.baseDir)) {
        fs.mkdirSync(this.baseDir, true);
      }
      
      // 确保项目目录存在
      if (!fs.accessSync(this.projectsDir)) {
        fs.mkdirSync(this.projectsDir, true);
      }
      
      console.log('[FileStorageService] 目录初始化完成');
    } catch (error) {
      console.error('[FileStorageService] 目录初始化失败:', error);
    }
  }

  /**
   * 获取项目列表
   */
  public async getProjectList(): Promise<ProjectMeta[]> {
    try {
      if (!fs.accessSync(this.metaFile)) {
        return [];
      }

      const file = fs.openSync(this.metaFile, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(this.metaFile);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      const decoder = new util.TextDecoder();
      const content = decoder.decodeWithStream(new Uint8Array(buffer));
      const projectList = JSON.parse(content) as ProjectMeta[];
      
      console.log(`[FileStorageService] 加载项目列表，共 ${projectList.length} 个项目`);
      return projectList;
    } catch (error) {
      console.error('[FileStorageService] 获取项目列表失败:', error);
      return [];
    }
  }

  /**
   * 保存项目列表
   */
  private async saveProjectList(list: ProjectMeta[]): Promise<void> {
    try {
      const content = JSON.stringify(list, null, 2);
      const encoder = new util.TextEncoder();
      const buffer = encoder.encodeInto(content);
      
      const file = fs.openSync(this.metaFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);
      
      console.log(`[FileStorageService] 项目列表已保存，共 ${list.length} 个项目`);
    } catch (error) {
      console.error('[FileStorageService] 保存项目列表失败:', error);
      throw new Error(`保存项目列表失败: ${error.message}`);
    }
  }

  /**
   * 保存项目
   */
  public async saveProject(project: Project): Promise<void> {
    try {
      // 1. 更新项目列表元数据
      const list = await this.getProjectList();
      const projectMeta: ProjectMeta = {
        id: project.id,
        name: project.name,
        lastModified: Date.now(),
        category: project.category || '其他'
      };

      const existingIndex = list.findIndex(p => p.id === project.id);
      if (existingIndex !== -1) {
        list[existingIndex] = projectMeta;
      } else {
        list.push(projectMeta);
      }
      await this.saveProjectList(list);

      // 2. 准备可存储的项目数据
      const storableProject: StorableProject = {
        id: project.id,
        name: project.name,
        lastModified: project.lastModified,
        dependencies: project.dependencies,
        tasks: project.tasks.map((task: TaskNode): StorableTaskNode => {
          return {
            id: task.id,
            name: task.name,
            checklist: task.checklist,
            x: task.x,
            y: task.y,
            earlyStart: task.earlyStart,
            earlyFinish: task.earlyFinish,
            lateStart: task.lateStart,
            lateFinish: task.lateFinish,
            isCritical: task.isCritical,
            startDate: task.startDate.toISOString(),
            endDate: task.endDate.toISOString(),
          };
        }),
        category: project.category || '其他'
      };

      // 3. 保存项目数据到文件
      const projectFile = `${this.projectsDir}/${project.id}.json`;
      const content = JSON.stringify(storableProject, null, 2);
      const encoder = new util.TextEncoder();
      const buffer = encoder.encodeInto(content);
      
      const file = fs.openSync(projectFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);
      
      console.log(`[FileStorageService] 项目 ${project.id} 已保存到文件`);
    } catch (error) {
      console.error(`[FileStorageService] 保存项目 ${project.id} 失败:`, error);
      throw new Error(`保存项目失败: ${error.message}`);
    }
  }

  /**
   * 获取项目
   */
  public async getProject(projectId: string): Promise<Project | null> {
    try {
      const projectFile = `${this.projectsDir}/${projectId}.json`;
      
      if (!fs.accessSync(projectFile)) {
        console.log(`[FileStorageService] 项目文件不存在: ${projectId}`);
        return null;
      }

      const file = fs.openSync(projectFile, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(projectFile);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      const decoder = new util.TextDecoder();
      const content = decoder.decodeWithStream(new Uint8Array(buffer));
      const storableProject = JSON.parse(content) as StorableProject;

      // 转换回完整的Project对象
      const project = new Project(storableProject.id, storableProject.name);
      project.lastModified = storableProject.lastModified;
      project.dependencies = storableProject.dependencies;
      project.tasks = storableProject.tasks.map((task: StorableTaskNode): TaskNode => {
        return {
          id: task.id,
          name: task.name,
          checklist: task.checklist,
          x: task.x,
          y: task.y,
          earlyStart: task.earlyStart,
          earlyFinish: task.earlyFinish,
          lateStart: task.lateStart,
          lateFinish: task.lateFinish,
          isCritical: task.isCritical,
          startDate: new Date(task.startDate),
          endDate: new Date(task.endDate),
        };
      });
      project.category = storableProject.category || '其他';
      
      console.log(`[FileStorageService] 项目 ${projectId} 已从文件加载`);
      return project;
    } catch (error) {
      console.error(`[FileStorageService] 获取项目 ${projectId} 失败:`, error);
      return null;
    }
  }

  /**
   * 删除项目
   */
  public async deleteProject(projectId: string): Promise<void> {
    try {
      // 1. 从项目列表中移除
      const list = await this.getProjectList();
      const filteredList = list.filter(p => p.id !== projectId);
      await this.saveProjectList(filteredList);

      // 2. 删除项目文件
      const projectFile = `${this.projectsDir}/${projectId}.json`;
      if (fs.accessSync(projectFile)) {
        fs.unlinkSync(projectFile);
      }
      
      console.log(`[FileStorageService] 项目 ${projectId} 已删除`);
    } catch (error) {
      console.error(`[FileStorageService] 删除项目 ${projectId} 失败:`, error);
      throw new Error(`删除项目失败: ${error.message}`);
    }
  }

  /**
   * 导出项目数据
   */
  public async exportProject(projectId: string): Promise<string> {
    try {
      const project = await this.getProject(projectId);
      if (!project) {
        throw new Error('项目不存在');
      }
      
      const exportData: ExportData = {
        version: '1.0',
        exportTime: new Date().toISOString(),
        project: project
      };
      
      return JSON.stringify(exportData, null, 2);
    } catch (error) {
      console.error(`[FileStorageService] 导出项目 ${projectId} 失败:`, error);
      throw new Error(`导出项目失败: ${error.message}`);
    }
  }

  /**
   * 导入项目数据
   */
  public async importProject(importData: string): Promise<Project> {
    try {
      const data = JSON.parse(importData) as ImportData;
      if (!data.project) {
        throw new Error('无效的导入数据格式');
      }
      
      const project = data.project as Project;
      
      // 生成新的项目ID
      project.id = `project_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      project.lastModified = Date.now();
      
      await this.saveProject(project);
      
      console.log(`[FileStorageService] 项目已导入: ${project.id}`);
      return project;
    } catch (error) {
      console.error('[FileStorageService] 导入项目失败:', error);
      throw new Error(`导入项目失败: ${error.message}`);
    }
  }

  /**
   * 获取存储统计信息
   */
  public async getStorageStats(): Promise<StorageStats> {
    try {
      const list = await this.getProjectList();
      let totalSize = 0;
      
      for (const meta of list) {
        const projectFile = `${this.projectsDir}/${meta.id}.json`;
        if (fs.accessSync(projectFile)) {
          const stat = fs.statSync(projectFile);
          totalSize += stat.size;
        }
      }
      
      const stats: StorageStats = {
        totalProjects: list.length,
        totalSize: totalSize
      };
      return stats;
    } catch (error) {
      console.error('[FileStorageService] 获取存储统计失败:', error);
      const defaultStats: StorageStats = { totalProjects: 0, totalSize: 0 };
      return defaultStats;
    }
  }
}
