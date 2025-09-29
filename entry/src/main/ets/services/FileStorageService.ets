// File: entry/src/main/ets/services/FileStorageService.ets
/**
 * 文件系统存储服务模块
 * 
 * 本模块负责项目数据的持久化存储，使用HarmonyOS文件系统API实现数据的保存、加载和管理。
 * 采用JSON格式存储项目数据，支持项目列表管理、单个项目操作、数据导入导出等功能。
 * 
 * 主要功能：
 * 1. 项目数据持久化：将项目对象序列化为JSON并保存到文件系统
 * 2. 项目列表管理：维护项目元数据列表，支持快速检索和排序
 * 3. 数据导入导出：支持项目数据的备份和迁移
 * 4. 存储统计：提供存储空间使用情况的统计信息
 * 5. 数据迁移：支持版本升级时的数据格式迁移
 * 
 * 存储结构：
 * - 基础目录：应用文件目录
 * - 项目目录：/projects/ 存储所有项目文件
 * - 元数据文件：project_meta.json 存储项目列表信息
 * - 项目文件：{projectId}.json 存储具体项目数据
 * 
 * 数据格式：
 * - 项目元数据：包含ID、名称、修改时间、分类等基本信息
 * - 项目数据：完整的项目对象，包含任务、依赖关系等详细信息
 * - 日期处理：将Date对象转换为ISO字符串进行存储
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import fs from '@ohos.file.fs';
import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';
import util from '@ohos.util';

/**
 * 项目元数据接口
 * 用于项目列表显示和快速检索，包含项目的基本信息
 */
export interface ProjectMeta {
  /** 项目唯一标识符 */
  id: string;
  /** 项目名称 */
  name: string;
  /** 最后修改时间（时间戳） */
  lastModified: number;
  /** 项目分类 */
  category: string;
}

/**
 * 可存储的任务节点接口
 * 将Date对象转换为字符串格式，便于JSON序列化存储
 */
interface StorableTaskNode extends Omit<TaskNode, 'startDate' | 'endDate'> {
  /** 开始日期（ISO字符串格式） */
  startDate: string;
  /** 结束日期（ISO字符串格式） */
  endDate: string;
}

/**
 * 可存储的项目接口
 * 将Project对象转换为适合文件存储的格式
 */
interface StorableProject extends Omit<Project, 'tasks' | 'addTask'> {
  /** 任务列表（使用可存储格式） */
  tasks: StorableTaskNode[];
  /** 项目分类 */
  category: string;
}

/**
 * 存储统计信息接口
 * 提供存储空间使用情况的统计信息
 */
interface StorageStats {
  /** 项目总数 */
  totalProjects: number;
  /** 总存储大小（字节） */
  totalSize: number;
}

/**
 * 数据迁移结果接口
 * 用于返回数据迁移操作的结果信息
 */
interface MigrationResult {
  /** 迁移是否成功 */
  success: boolean;
  /** 成功迁移的项目数量 */
  migratedCount: number;
  /** 迁移过程中的错误信息列表 */
  errors: string[];
}

/**
 * 导出数据接口
 * 用于项目数据导出时的数据格式
 */
interface ExportData {
  /** 数据版本号 */
  version: string;
  /** 导出时间（ISO字符串格式） */
  exportTime: string;
  /** 项目数据 */
  project: Project;
}

/**
 * 导入数据接口
 * 用于项目数据导入时的数据格式
 */
interface ImportData {
  /** 数据版本号（可选） */
  version?: string;
  /** 导出时间（可选） */
  exportTime?: string;
  /** 项目数据 */
  project: Project;
}

/**
 * 文件系统存储服务类
 * 
 * 实现项目数据的文件系统存储功能，采用单例模式设计。
 * 负责项目数据的持久化、检索、更新和删除操作，以及存储空间管理。
 * 
 * 核心功能：
 * 1. 项目数据管理：保存、加载、更新、删除项目数据
 * 2. 元数据管理：维护项目列表和基本信息
 * 3. 数据转换：处理Date对象与字符串之间的转换
 * 4. 错误处理：提供完善的错误处理和恢复机制
 * 5. 性能优化：使用缓存和批量操作提高性能
 * 
 * 存储策略：
 * - 采用JSON格式存储，便于阅读和调试
 * - 分离元数据和详细数据，提高检索效率
 * - 支持数据迁移和版本兼容性
 * - 提供数据备份和恢复功能
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
export class FileStorageService {
  /** 单例实例 */
  private static instance: FileStorageService;
  /** 基础存储目录路径 */
  private baseDir: string;
  /** 项目文件存储目录路径 */
  private projectsDir: string;
  /** 项目元数据文件路径 */
  private metaFile: string;

  /**
   * 私有构造函数
   * 初始化存储目录结构和文件路径
   * 
   * @param baseDir 基础存储目录路径
   * @private
   */
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
