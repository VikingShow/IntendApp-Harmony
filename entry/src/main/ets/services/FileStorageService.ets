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
   * 测试文件系统操作
   */
  public async testFileSystem(): Promise<boolean> {
    try {
      console.log('[FileStorageService] 开始测试文件系统操作...');
      console.log(`[FileStorageService] 基础目录: ${this.baseDir}`);
      console.log(`[FileStorageService] 项目目录: ${this.projectsDir}`);
      console.log(`[FileStorageService] 元数据文件: ${this.metaFile}`);
      
      // 测试目录访问
      try {
        const baseDirExists = fs.accessSync(this.baseDir);
        console.log(`[FileStorageService] 基础目录访问结果: ${baseDirExists}`);
      } catch (error) {
        console.log(`[FileStorageService] 基础目录不存在，需要创建`);
      }
      
      // 测试文件写入
      const testFile = `${this.baseDir}/test.txt`;
      const testContent = "Hello World";
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encode(testContent);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);
      
      console.log(`[FileStorageService] 测试文件路径: ${testFile}`);
      console.log(`[FileStorageService] 测试内容: ${testContent}`);
      console.log(`[FileStorageService] 编码后缓冲区大小: ${buffer.byteLength}`);
      
      const file = fs.openSync(testFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      console.log(`[FileStorageService] 测试文件已打开，文件描述符: ${file.fd}`);
      
      fs.writeSync(file.fd, buffer);
      console.log(`[FileStorageService] 测试数据已写入`);
      
      fs.closeSync(file);
      console.log(`[FileStorageService] 测试文件已关闭`);
      
      // 测试文件读取
      const readFile = fs.openSync(testFile, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(testFile);
      const readBuffer = new ArrayBuffer(stat.size);
      fs.readSync(readFile.fd, readBuffer);
      fs.closeSync(readFile);
      
      const decoder = new util.TextDecoder();
      const readContent = decoder.decode(new Uint8Array(readBuffer));
      console.log(`[FileStorageService] 读取的测试内容: ${readContent}`);
      
      // 清理测试文件
      fs.unlinkSync(testFile);
      console.log(`[FileStorageService] 测试文件已删除`);
      
      console.log('[FileStorageService] 文件系统测试成功！');
      return true;
    } catch (error) {
      console.error('[FileStorageService] 文件系统测试失败:', error);
      console.error(`[FileStorageService] 错误详情: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 初始化目录结构
   */
  private async initializeDirectories(): Promise<void> {
    try {
      console.log(`[FileStorageService] 开始初始化目录结构，基础目录: ${this.baseDir}`);
      
      // 确保基础目录存在
      try {
        if (!fs.accessSync(this.baseDir)) {
          console.log(`[FileStorageService] 创建基础目录: ${this.baseDir}`);
          fs.mkdirSync(this.baseDir, true);
        }
      } catch (error) {
        console.log(`[FileStorageService] 基础目录可能已存在，继续创建项目目录`);
      }
      
      // 确保项目目录存在
      try {
        if (!fs.accessSync(this.projectsDir)) {
          console.log(`[FileStorageService] 创建项目目录: ${this.projectsDir}`);
          fs.mkdirSync(this.projectsDir, true);
        }
      } catch (error) {
        console.log(`[FileStorageService] 项目目录可能已存在，继续初始化`);
      }
      
      console.log('[FileStorageService] 目录初始化完成');
    } catch (error) {
      console.error('[FileStorageService] 目录初始化失败:', error);
      throw new Error(`目录初始化失败: ${error.message || '未知错误'}`);
    }
  }

  /**
   * 获取项目列表
   */
  public async getProjectList(): Promise<ProjectMeta[]> {
    try {
      if (!fs.accessSync(this.metaFile)) {
        console.log('[FileStorageService] 元数据文件不存在，返回空列表');
        return [];
      }

      const file = fs.openSync(this.metaFile, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(this.metaFile);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      const decoder = new util.TextDecoder();
      const content = decoder.decode(new Uint8Array(buffer));
      console.log(`[FileStorageService] 读取到的元数据文件内容: ${content}`);
      
      // 检查内容是否为空或无效
      if (!content || content.trim() === '') {
        console.log('[FileStorageService] 元数据文件为空，返回空列表');
        return [];
      }
      
      const projectList = JSON.parse(content) as ProjectMeta[];
      console.log(`[FileStorageService] 加载项目列表，共 ${projectList.length} 个项目`);
      return projectList;
    } catch (error) {
      console.error('[FileStorageService] 获取项目列表失败:', error);
      console.log('[FileStorageService] 尝试从项目文件重建元数据列表...');
      
      // 如果元数据文件损坏，尝试从项目文件重建
      return await this.rebuildProjectList();
    }
  }

  /**
   * 从项目文件重建元数据列表
   */
  private async rebuildProjectList(): Promise<ProjectMeta[]> {
    try {
      console.log('[FileStorageService] 开始重建项目元数据列表...');
      
      // 检查项目目录是否存在
      if (!fs.accessSync(this.projectsDir)) {
        console.log('[FileStorageService] 项目目录不存在，返回空列表');
        return [];
      }
      
      const projectList: ProjectMeta[] = [];
      
      // 遍历项目目录中的所有JSON文件
      const files = fs.listFileSync(this.projectsDir);
      console.log(`[FileStorageService] 在项目目录中找到 ${files.length} 个文件`);
      
      for (const fileName of files) {
        if (fileName.endsWith('.json')) {
          const projectId = fileName.replace('.json', '');
          const projectFile = `${this.projectsDir}/${fileName}`;
          
          try {
            // 读取项目文件
            const file = fs.openSync(projectFile, fs.OpenMode.READ_ONLY);
            const stat = fs.statSync(projectFile);
            const buffer = new ArrayBuffer(stat.size);
            fs.readSync(file.fd, buffer);
            fs.closeSync(file);
            
            const decoder = new util.TextDecoder();
            const content = decoder.decode(new Uint8Array(buffer));
            const projectData = JSON.parse(content) as Record<string, string | number | boolean | object>;
            
            // 创建项目元数据
            const projectMeta: ProjectMeta = {
              id: (projectData.id as string) || projectId,
              name: (projectData.name as string) || '未命名项目',
              lastModified: (projectData.lastModified as number) || Date.now(),
              category: (projectData.category as string) || '其他'
            };
            
            projectList.push(projectMeta);
            console.log(`[FileStorageService] 重建项目元数据: ${projectMeta.name} (${projectMeta.id})`);
          } catch (error) {
            console.error(`[FileStorageService] 读取项目文件 ${fileName} 失败:`, error);
          }
        }
      }
      
      // 保存重建的元数据列表
      if (projectList.length > 0) {
        await this.saveProjectList(projectList);
        console.log(`[FileStorageService] 重建完成，共 ${projectList.length} 个项目`);
      }
      
      return projectList;
    } catch (error) {
      console.error('[FileStorageService] 重建项目列表失败:', error);
      return [];
    }
  }

  /**
   * 保存项目列表
   */
  private async saveProjectList(list: ProjectMeta[]): Promise<void> {
    try {
      console.log(`[FileStorageService] 开始保存项目列表，共 ${list.length} 个项目`);
      console.log(`[FileStorageService] 保存路径: ${this.metaFile}`);
      
      const content = JSON.stringify(list, null, 2);
      console.log(`[FileStorageService] 项目列表JSON内容长度: ${content.length}`);
      
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encode(content);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);
      console.log(`[FileStorageService] 编码后缓冲区大小: ${buffer.byteLength}`);
      
      const file = fs.openSync(this.metaFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      console.log(`[FileStorageService] 文件已打开，文件描述符: ${file.fd}`);
      
      fs.writeSync(file.fd, buffer);
      console.log(`[FileStorageService] 数据已写入文件`);
      
      fs.closeSync(file);
      console.log(`[FileStorageService] 文件已关闭`);
      
      console.log(`[FileStorageService] 项目列表已保存，共 ${list.length} 个项目`);
    } catch (error) {
      console.error('[FileStorageService] 保存项目列表失败:', error);
      console.error(`[FileStorageService] 错误详情: ${JSON.stringify(error)}`);
      throw new Error(`保存项目列表失败: ${error.message || '未知错误'}`);
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
      const uint8Array = encoder.encode(content);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);
      
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
      const content = decoder.decode(new Uint8Array(buffer));
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
