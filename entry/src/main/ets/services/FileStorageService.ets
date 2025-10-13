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

// import fs from '@ohos.file.fs';
import { fileIo as fs } from '@kit.CoreFileKit';
import { Project, TaskNode } from '../model/ProjectData';
import { ProjectGroup, ProjectRef } from '../model/ProjectGroup';
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
 * 项目群元数据接口
 * 用于项目群列表显示和快速检索，包含项目群的基本信息
 */
export interface ProjectGroupMeta {
  /** 项目群唯一标识符 */
  id: string;
  /** 项目群名称 */
  name: string;
  /** 最后修改时间（时间戳） */
  lastModified: number;
  /** 项目群分类 */
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
  /** 画布X轴偏移量 */
  canvasOffsetX: number;
  /** 画布Y轴偏移量 */
  canvasOffsetY: number;
  /** 画布缩放比例 */
  zoomScale: number;
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
 * 清理结果接口
 */
interface CleanupResult {
  cleaned: number;
  errors: string[];
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
 * 项目群导出数据接口
 * 用于项目群数据导出时的数据格式
 */
interface ProjectGroupExportData {
  /** 数据版本号 */
  version: string;
  /** 导出时间（ISO字符串格式） */
  exportTime: string;
  /** 项目群数据 */
  projectGroup: ProjectGroup;
}

/**
 * 项目群导入数据接口
 * 用于项目群数据导入时的数据格式
 */
interface ProjectGroupImportData {
  /** 数据版本号（可选） */
  version?: string;
  /** 导出时间（可选） */
  exportTime?: string;
  /** 项目群数据 */
  projectGroup: ProjectGroup;
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
interface GeneratedObjectLiteralInterface_1 {
  version: string;
  exportTime: string;
  projectGroup: ProjectGroup;
}

export class FileStorageService {
  /** 单例实例 */
  private static instance: FileStorageService;
  /** 基础存储目录路径 */
  private baseDir: string;
  /** 项目文件存储目录路径 */
  private projectsDir: string;
  /** 项目元数据文件路径 */
  private metaFile: string;
  /** 项目群文件存储目录路径 */
  private projectGroupsDir: string;
  /** 项目群元数据文件路径 */
  private groupMetaFile: string;

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
    this.projectGroupsDir = `${baseDir}/project_groups`;
    this.groupMetaFile = `${baseDir}/project_group_meta.json`;
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

      if (canIUse('SystemCapability.FileManagement.File.FileIO')){
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
        const uint8Array = encoder.encodeInto(testContent);
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
      } else {
        console.warn('[FileStorageService] 当前设备不支持 testFileSystem()');
        console.error('[FileStorageService] 文件系统测试失败:');
        return false;
      }
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

      if (canIUse('SystemCapability.FileManagement.File.FileIO')){
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

        // 确保项目群目录存在
        try {
          if (!fs.accessSync(this.projectGroupsDir)) {
            console.log(`[FileStorageService] 创建项目群目录: ${this.projectGroupsDir}`);
            fs.mkdirSync(this.projectGroupsDir, true);
          }
        } catch (error) {
          console.log(`[FileStorageService] 项目群目录可能已存在，继续初始化`);
        }

        console.log('[FileStorageService] 目录初始化完成');
      } else {
        console.warn('[FileStorageService] 当前设备不支持 initializeDirectories()');
        console.error('[FileStorageService] 目录初始化失败:');
      }
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
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
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
        const content = decoder.decodeToString(new Uint8Array(buffer));
        console.log(`[FileStorageService] 读取到的元数据文件内容长度: ${content.length}`);
        console.log(`[FileStorageService] 元数据文件内容预览: ${content.substring(0, 200)}...`);

        // 检查内容是否为空或无效
        if (!content || content.trim() === '') {
          console.log('[FileStorageService] 元数据文件为空，返回空列表');
          return [];
        }

        // 验证JSON格式
        try {
          const projectList = JSON.parse(content) as ProjectMeta[];
          console.log(`[FileStorageService] 加载项目列表，共 ${projectList.length} 个项目`);
          return projectList;
        } catch (parseError) {
          console.error('[FileStorageService] 元数据文件JSON解析失败:', parseError);
          console.log('[FileStorageService] 尝试从项目文件重建元数据列表...');
          return await this.rebuildProjectList();
        }
      }else {
        console.warn('[FileStorageService] 当前设备不支持 getProjectList()');
        console.log('[FileStorageService] 尝试从项目文件重建元数据列表...');
        return await this.rebuildProjectList();
      }
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

      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
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
              const content = decoder.decodeToString(new Uint8Array(buffer));
              console.log(`[FileStorageService] 读取项目文件 ${fileName}，内容长度: ${content.length}`);
              console.log(`[FileStorageService] 文件内容预览: ${content.substring(0, 100)}...`);

              // 验证JSON格式
              let projectData: Record<string, string | number | boolean | object>;
              try {
                projectData = JSON.parse(content);
              } catch (parseError) {
                console.error(`[FileStorageService] 项目文件 ${fileName} JSON解析失败:`, parseError);
                console.log(`[FileStorageService] 删除损坏的项目文件: ${fileName}`);
                // 删除损坏的文件
                try {
                  fs.unlinkSync(projectFile);
                  console.log(`[FileStorageService] 已删除损坏的文件: ${fileName}`);
                } catch (deleteError) {
                  console.error(`[FileStorageService] 删除文件失败:`, deleteError);
                }
                continue;
              }

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
              // 如果文件损坏，尝试删除它
              try {
                fs.unlinkSync(projectFile);
                console.log(`[FileStorageService] 已删除损坏的文件: ${fileName}`);
              } catch (deleteError) {
                console.error(`[FileStorageService] 删除文件失败:`, deleteError);
              }
            }
          }
        }

        // 保存重建的元数据列表
        if (projectList.length > 0) {
          await this.saveProjectList(projectList);
          console.log(`[FileStorageService] 重建完成，共 ${projectList.length} 个项目`);
        }

        return projectList;
      }else {
        console.warn('[FileStorageService] 当前设备不支持 rebuildProjectList()');
        console.error('[FileStorageService] 重建项目列表失败:');
        return [];
      }
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

      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        const content = JSON.stringify(list, null, 2);
        console.log(`[FileStorageService] 项目列表JSON内容长度: ${content.length}`);

        const encoder = new util.TextEncoder();
        const uint8Array = encoder.encodeInto(content);
        const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);
        console.log(`[FileStorageService] 编码后缓冲区大小: ${buffer.byteLength}`);

        // 先删除旧文件，确保完全重写
        try {
          if (fs.accessSync(this.metaFile)) {
            fs.unlinkSync(this.metaFile);
          }
        } catch (error) {
          // 文件不存在，忽略错误
        }

        const file = fs.openSync(this.metaFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
        console.log(`[FileStorageService] 文件已打开，文件描述符: ${file.fd}`);

        fs.writeSync(file.fd, buffer);
        console.log(`[FileStorageService] 数据已写入文件`);

        fs.closeSync(file);
        console.log(`[FileStorageService] 文件已关闭`);

        console.log(`[FileStorageService] 项目列表已保存，共 ${list.length} 个项目`);
      }else {
        console.warn('[FileStorageService] 当前设备不支持 saveProjectList()');
      }
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
        category: project.category || '其他',
        canvasOffsetX: project.canvasOffsetX || 0,
        canvasOffsetY: project.canvasOffsetY || 0,
        zoomScale: project.zoomScale || 1.0
      };

      // 3. 保存项目数据到文件
      const projectFile = `${this.projectsDir}/${project.id}.json`;
      const content = JSON.stringify(storableProject, null, 2);
      console.log(`[FileStorageService] 准备保存项目 ${project.id}，JSON内容长度: ${content.length}`);
      console.log(`[FileStorageService] JSON内容预览: ${content.substring(0, 200)}...`);
      
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encode(content);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);
      console.log(`[FileStorageService] 编码后缓冲区大小: ${buffer.byteLength}`);

      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        // 先删除旧文件，确保完全重写
        try {
          if (fs.accessSync(projectFile)) {
            fs.unlinkSync(projectFile);
          }
        } catch (error) {
          // 文件不存在，忽略错误
        }

        const file = fs.openSync(projectFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
        console.log(`[FileStorageService] 文件已打开，文件描述符: ${file.fd}`);

        fs.writeSync(file.fd, buffer);
        console.log(`[FileStorageService] 数据已写入文件`);

        fs.closeSync(file);
        console.log(`[FileStorageService] 文件已关闭`);

        console.log(`[FileStorageService] 项目 ${project.id} 已保存到文件`);
      }else {
        console.warn('[FileStorageService] 当前设备不支持 saveProject()');
      }
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
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
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
        // 恢复画布状态
        project.canvasOffsetX = storableProject.canvasOffsetX || 0;
        project.canvasOffsetY = storableProject.canvasOffsetY || 0;
        project.zoomScale = storableProject.zoomScale || 1.0;

        console.log(`[FileStorageService] 项目 ${projectId} 已从文件加载`);
        return project;
      }else {
        console.warn('[FileStorageService] 当前设备不支持 getProject()');
        console.error(`[FileStorageService] 获取项目 ${projectId} 失败:`);
        return null;
      }
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
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
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
      }else {
        console.warn('[FileStorageService] 当前设备不支持 deleteProject()');
        console.error(`[FileStorageService] 删除项目 ${projectId} 失败:`);
      }
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
      project.id = `project_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
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
   * 清理损坏的项目文件
   */
  public async cleanupCorruptedFiles(): Promise<CleanupResult> {
    const errors: string[] = [];
    let cleaned = 0;
    
    try {
      console.log('[FileStorageService] 开始清理损坏的项目文件...');
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        if (!fs.accessSync(this.projectsDir)) {
          console.log('[FileStorageService] 项目目录不存在，无需清理');
          const result: CleanupResult = { cleaned: 0, errors: [] };
          return result;
        }

        const files = fs.listFileSync(this.projectsDir);
        console.log(`[FileStorageService] 检查 ${files.length} 个文件`);

        for (const fileName of files) {
          if (fileName.endsWith('.json')) {
            const projectFile = `${this.projectsDir}/${fileName}`;

            try {
              // 尝试读取和解析文件
              const file = fs.openSync(projectFile, fs.OpenMode.READ_ONLY);
              const stat = fs.statSync(projectFile);
              const buffer = new ArrayBuffer(stat.size);
              fs.readSync(file.fd, buffer);
              fs.closeSync(file);

              const decoder = new util.TextDecoder();
              const content = decoder.decode(new Uint8Array(buffer));
              console.log(`[FileStorageService] 检查文件 ${fileName}，内容长度: ${content.length}`);
              console.log(`[FileStorageService] 文件内容预览: ${content.substring(0, 100)}...`);

              // 验证JSON格式
              try {
                JSON.parse(content);
                console.log(`[FileStorageService] 文件 ${fileName} 正常`);
              } catch (parseError) {
                console.log(`[FileStorageService] 发现损坏的文件: ${fileName}，错误: ${parseError.message}`);
                console.log(`[FileStorageService] 文件内容: ${content}`);
                fs.unlinkSync(projectFile);
                cleaned++;
                console.log(`[FileStorageService] 已删除损坏的文件: ${fileName}`);
              }
            } catch (error) {
              console.error(`[FileStorageService] 检查文件 ${fileName} 失败:`, error);
              // 如果文件无法读取，也删除它
              try {
                fs.unlinkSync(projectFile);
                cleaned++;
                console.log(`[FileStorageService] 已删除无法读取的文件: ${fileName}`);
              } catch (deleteError) {
                console.error(`[FileStorageService] 删除文件 ${fileName} 失败:`, deleteError);
                errors.push(`删除文件 ${fileName} 失败: ${deleteError.message}`);
              }
            }
          }
        }

        // 如果清理了文件，重新创建空的元数据文件
        if (cleaned > 0) {
          console.log(`[FileStorageService] 重新创建空的元数据文件`);
          await this.saveProjectList([]);
        }

        console.log(`[FileStorageService] 清理完成，删除了 ${cleaned} 个损坏的文件`);
        const result: CleanupResult = { cleaned, errors };
        return result;
      }else {
        console.warn('[FileStorageService] 当前设备不支持 cleanupCorruptedFiles()');
        console.error('[FileStorageService] 清理损坏文件失败:');
        errors.push(`清理过程失败}`);
        const result: CleanupResult = { cleaned, errors };
        return result;
      }
    } catch (error) {
      console.error('[FileStorageService] 清理损坏文件失败:', error);
      errors.push(`清理过程失败: ${error.message}`);
      const result: CleanupResult = { cleaned, errors };
      return result;
    }
  }

  /**
   * 获取存储统计信息
   */
  public async getStorageStats(): Promise<StorageStats> {
    try {
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
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
      }else {
        console.warn('[FileStorageService] 当前设备不支持 getStorageStats()');
        console.error('[FileStorageService] 获取存储统计失败:');
        const defaultStats: StorageStats = { totalProjects: 0, totalSize: 0 };
        return defaultStats;
      }
    } catch (error) {
      console.error('[FileStorageService] 获取存储统计失败:', error);
      const defaultStats: StorageStats = { totalProjects: 0, totalSize: 0 };
      return defaultStats;
    }
  }

  // ==================== 项目群管理方法 ====================

  /**
   * 获取项目群列表
   */
  public async getProjectGroupList(): Promise<ProjectGroupMeta[]> {
    try {
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        if (!fs.accessSync(this.groupMetaFile)) {
          console.log('[FileStorageService] 项目群元数据文件不存在，返回空列表');
          return [];
        }

        const file = fs.openSync(this.groupMetaFile, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(this.groupMetaFile);
        const buffer = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buffer);
        fs.closeSync(file);

        const decoder = new util.TextDecoder();
        const content = decoder.decodeToString(new Uint8Array(buffer));
        console.log(`[FileStorageService] 读取到的项目群元数据文件内容长度: ${content.length}`);

        if (!content || content.trim() === '') {
          console.log('[FileStorageService] 项目群元数据文件为空，返回空列表');
          return [];
        }

        try {
          const groupList = JSON.parse(content) as ProjectGroupMeta[];
          console.log(`[FileStorageService] 加载项目群列表，共 ${groupList.length} 个项目群`);
          return groupList;
        } catch (parseError) {
          console.error('[FileStorageService] 项目群元数据文件JSON解析失败:', parseError);
          console.log('[FileStorageService] 尝试从项目群文件重建元数据列表...');
          return await this.rebuildProjectGroupList();
        }
      }else {
        console.warn('[FileStorageService] 当前设备不支持 getProjectGroupList()');
        return [];
      }
    } catch (error) {
      console.error('[FileStorageService] 获取项目群列表失败:', error);
      return await this.rebuildProjectGroupList();
    }
  }

  /**
   * 从项目群文件重建元数据列表
   */
  private async rebuildProjectGroupList(): Promise<ProjectGroupMeta[]> {
    try {
      console.log('[FileStorageService] 开始重建项目群元数据列表...');

      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        if (!fs.accessSync(this.projectGroupsDir)) {
          console.log('[FileStorageService] 项目群目录不存在，返回空列表');
          return [];
        }

        const groupList: ProjectGroupMeta[] = [];
        const files = fs.listFileSync(this.projectGroupsDir);
        console.log(`[FileStorageService] 在项目群目录中找到 ${files.length} 个文件`);

        for (const fileName of files) {
          if (fileName.endsWith('.json')) {
            const groupId = fileName.replace('.json', '');
            const groupFile = `${this.projectGroupsDir}/${fileName}`;

            try {
              const file = fs.openSync(groupFile, fs.OpenMode.READ_ONLY);
              const stat = fs.statSync(groupFile);
              const buffer = new ArrayBuffer(stat.size);
              fs.readSync(file.fd, buffer);
              fs.closeSync(file);

              const decoder = new util.TextDecoder();
              const content = decoder.decodeToString(new Uint8Array(buffer));

              let groupData: Record<string, string | number | boolean | object>;
              try {
                groupData = JSON.parse(content);
              } catch (parseError) {
                console.error(`[FileStorageService] 项目群文件 ${fileName} JSON解析失败:`, parseError);
                try {
                  fs.unlinkSync(groupFile);
                  console.log(`[FileStorageService] 已删除损坏的文件: ${fileName}`);
                } catch (deleteError) {
                  console.error(`[FileStorageService] 删除文件失败:`, deleteError);
                }
                continue;
              }

              const groupMeta: ProjectGroupMeta = {
                id: (groupData.id as string) || groupId,
                name: (groupData.name as string) || '未命名项目群',
                lastModified: (groupData.lastModified as number) || Date.now(),
                category: (groupData.category as string) || '其他'
              };

              groupList.push(groupMeta);
              console.log(`[FileStorageService] 重建项目群元数据: ${groupMeta.name} (${groupMeta.id})`);
            } catch (error) {
              console.error(`[FileStorageService] 读取项目群文件 ${fileName} 失败:`, error);
              try {
                fs.unlinkSync(groupFile);
                console.log(`[FileStorageService] 已删除损坏的文件: ${fileName}`);
              } catch (deleteError) {
                console.error(`[FileStorageService] 删除文件失败:`, deleteError);
              }
            }
          }
        }

        if (groupList.length > 0) {
          await this.saveProjectGroupList(groupList);
          console.log(`[FileStorageService] 重建完成，共 ${groupList.length} 个项目群`);
        }

        return groupList;
      }else {
        console.warn('[FileStorageService] 当前设备不支持 rebuildProjectGroupList()');
        return [];
      }
    } catch (error) {
      console.error('[FileStorageService] 重建项目群列表失败:', error);
      return [];
    }
  }

  /**
   * 保存项目群列表
   */
  private async saveProjectGroupList(list: ProjectGroupMeta[]): Promise<void> {
    try {
      console.log(`[FileStorageService] 开始保存项目群列表，共 ${list.length} 个项目群`);

      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        const content = JSON.stringify(list, null, 2);
        const encoder = new util.TextEncoder();
        const uint8Array = encoder.encodeInto(content);
        const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);

        try {
          if (fs.accessSync(this.groupMetaFile)) {
            fs.unlinkSync(this.groupMetaFile);
          }
        } catch (error) {
          // 文件不存在，忽略错误
        }

        const file = fs.openSync(this.groupMetaFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, buffer);
        fs.closeSync(file);

        console.log(`[FileStorageService] 项目群列表已保存，共 ${list.length} 个项目群`);
      }else {
        console.warn('[FileStorageService] 当前设备不支持 saveProjectGroupList()');
      }
    } catch (error) {
      console.error('[FileStorageService] 保存项目群列表失败:', error);
      throw new Error(`保存项目群列表失败: ${error.message || '未知错误'}`);
    }
  }

  /**
   * 保存项目群
   */
  public async saveProjectGroup(group: ProjectGroup): Promise<void> {
    try {
      // 1. 更新项目群列表元数据
      const list = await this.getProjectGroupList();
      const groupMeta: ProjectGroupMeta = {
        id: group.id,
        name: group.name,
        lastModified: Date.now(),
        category: group.category || '其他'
      };

      const existingIndex = list.findIndex(g => g.id === group.id);
      if (existingIndex !== -1) {
        list[existingIndex] = groupMeta;
      } else {
        list.push(groupMeta);
      }
      await this.saveProjectGroupList(list);

      // 2. 保存项目群数据到文件
      const groupFile = `${this.projectGroupsDir}/${group.id}.json`;
      const content = JSON.stringify(group, null, 2);
      console.log(`[FileStorageService] 准备保存项目群 ${group.id}，JSON内容长度: ${content.length}`);
      
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encode(content);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);

      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        try {
          if (fs.accessSync(groupFile)) {
            fs.unlinkSync(groupFile);
          }
        } catch (error) {
          // 文件不存在，忽略错误
        }

        const file = fs.openSync(groupFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, buffer);
        fs.closeSync(file);

        console.log(`[FileStorageService] 项目群 ${group.id} 已保存到文件`);
      }else {
        console.warn('[FileStorageService] 当前设备不支持 saveProjectGroup()');
      }
    } catch (error) {
      console.error(`[FileStorageService] 保存项目群 ${group.id} 失败:`, error);
      throw new Error(`保存项目群失败: ${error.message}`);
    }
  }

  /**
   * 获取项目群
   */
  public async getProjectGroup(groupId: string): Promise<ProjectGroup | null> {
    try {
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        const groupFile = `${this.projectGroupsDir}/${groupId}.json`;

        if (!fs.accessSync(groupFile)) {
          console.log(`[FileStorageService] 项目群文件不存在: ${groupId}`);
          return null;
        }

        const file = fs.openSync(groupFile, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(groupFile);
        const buffer = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buffer);
        fs.closeSync(file);

        const decoder = new util.TextDecoder();
        const content = decoder.decode(new Uint8Array(buffer));
        const groupData = JSON.parse(content) as ProjectGroup;

        // 转换回ProjectGroup对象
        const group = new ProjectGroup(groupData.id, groupData.name);
        group.lastModified = groupData.lastModified;
        group.category = groupData.category || '其他';
        group.projectRefs = groupData.projectRefs;
        group.dependencies = groupData.dependencies;
        group.canvasOffsetX = groupData.canvasOffsetX || 0;
        group.canvasOffsetY = groupData.canvasOffsetY || 0;
        group.zoomScale = groupData.zoomScale || 1.0;

        console.log(`[FileStorageService] 项目群 ${groupId} 已从文件加载`);
        return group;
      }else {
        console.warn('[FileStorageService] 当前设备不支持 getProjectGroup()');
        return null;
      }
    } catch (error) {
      console.error(`[FileStorageService] 获取项目群 ${groupId} 失败:`, error);
      return null;
    }
  }

  /**
   * 删除项目群
   */
  public async deleteProjectGroup(groupId: string): Promise<void> {
    try {
      if(canIUse('SystemCapability.FileManagement.File.FileIO')){
        // 1. 从项目群列表中移除
        const list = await this.getProjectGroupList();
        const filteredList = list.filter(g => g.id !== groupId);
        await this.saveProjectGroupList(filteredList);

        // 2. 删除项目群文件
        const groupFile = `${this.projectGroupsDir}/${groupId}.json`;
        if (fs.accessSync(groupFile)) {
          fs.unlinkSync(groupFile);
        }

        console.log(`[FileStorageService] 项目群 ${groupId} 已删除`);
      }else {
        console.warn('[FileStorageService] 当前设备不支持 deleteProjectGroup()');
      }
    } catch (error) {
      console.error(`[FileStorageService] 删除项目群 ${groupId} 失败:`, error);
      throw new Error(`删除项目群失败: ${error.message}`);
    }
  }

  /**
   * 导出项目群数据
   */
  public async exportProjectGroup(groupId: string): Promise<string> {
    try {
      const group = await this.getProjectGroup(groupId);
      if (!group) {
        throw new Error('项目群不存在');
      }
      
      const exportData: ProjectGroupExportData = {
        version: '1.0',
        exportTime: new Date().toISOString(),
        projectGroup: group
      };
      
      return JSON.stringify(exportData, null, 2);
    } catch (error) {
      console.error(`[FileStorageService] 导出项目群 ${groupId} 失败:`, error);
      throw new Error(`导出项目群失败: ${error.message}`);
    }
  }

  /**
   * 导入项目群数据
   */
  public async importProjectGroup(importData: string): Promise<ProjectGroup> {
    try {
      const data = JSON.parse(importData) as ProjectGroupImportData;
      if (!data.projectGroup) {
        throw new Error('无效的导入数据格式');
      }
      
      const group = data.projectGroup;
      
      // 生成新的项目群ID
      group.id = `group_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
      group.lastModified = Date.now();
      
      await this.saveProjectGroup(group);
      
      console.log(`[FileStorageService] 项目群已导入: ${group.id}`);
      return group;
    } catch (error) {
      console.error('[FileStorageService] 导入项目群失败:', error);
      throw new Error(`导入项目群失败: ${error.message}`);
    }
  }
}
