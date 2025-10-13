// File: entry/src/main/ets/services/StorageService.ets
import { FileStorageService, ProjectMeta, ProjectGroupMeta } from './FileStorageService';
import { Project } from '../model/ProjectData';
import { ProjectGroup } from '../model/ProjectGroup';

/**
 * 清理结果接口
 */
interface CleanupResult {
  cleaned: number;
  errors: string[];
}

/**
 * 存储服务适配器
 * 提供统一的存储接口，内部使用FileStorageService进行文件系统存储
 */
export class StorageService {
  private static instance: StorageService;
  private fileStorage: FileStorageService;

  private constructor(filesDir: string) {
    this.fileStorage = FileStorageService.getInstance(filesDir);
    console.log('[StorageService] 已初始化，使用文件系统存储');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(filesDir: string): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService(filesDir);
    }
    return StorageService.instance;
  }

  /**
   * 获取项目列表
   */
  public async getProjectList(): Promise<ProjectMeta[]> {
    return await this.fileStorage.getProjectList();
  }

  /**
   * 保存项目
   */
  public async saveProject(project: Project): Promise<void> {
    return await this.fileStorage.saveProject(project);
  }

  /**
   * 获取项目
   */
  public async getProject(projectId: string): Promise<Project | null> {
    return await this.fileStorage.getProject(projectId);
  }

  /**
   * 删除项目
   */
  public async deleteProject(projectId: string): Promise<void> {
    return await this.fileStorage.deleteProject(projectId);
  }

  /**
   * 导出项目数据
   */
  public async exportProject(projectId: string): Promise<string> {
    return await this.fileStorage.exportProject(projectId);
  }

  /**
   * 导入项目数据
   */
  public async importProject(importData: string): Promise<Project> {
    return await this.fileStorage.importProject(importData);
  }

  /**
   * 获取存储统计信息
   */
  public async getStorageStats(): Promise<StorageStats> {
    return await this.fileStorage.getStorageStats();
  }

  /**
   * 测试文件系统操作
   */
  public async testFileSystem(): Promise<boolean> {
    return await this.fileStorage.testFileSystem();
  }

  /**
   * 清理损坏的项目文件
   */
  public async cleanupCorruptedFiles(): Promise<CleanupResult> {
    return await this.fileStorage.cleanupCorruptedFiles();
  }

  // ==================== 项目群管理方法 ====================

  /**
   * 获取项目群列表
   */
  public async getProjectGroupList(): Promise<ProjectGroupMeta[]> {
    return await this.fileStorage.getProjectGroupList();
  }

  /**
   * 保存项目群
   */
  public async saveProjectGroup(group: ProjectGroup): Promise<void> {
    return await this.fileStorage.saveProjectGroup(group);
  }

  /**
   * 获取项目群
   */
  public async getProjectGroup(groupId: string): Promise<ProjectGroup | null> {
    return await this.fileStorage.getProjectGroup(groupId);
  }

  /**
   * 删除项目群
   */
  public async deleteProjectGroup(groupId: string): Promise<void> {
    return await this.fileStorage.deleteProjectGroup(groupId);
  }

  /**
   * 导出项目群数据
   */
  public async exportProjectGroup(groupId: string): Promise<string> {
    return await this.fileStorage.exportProjectGroup(groupId);
  }

  /**
   * 导入项目群数据
   */
  public async importProjectGroup(importData: string): Promise<ProjectGroup> {
    return await this.fileStorage.importProjectGroup(importData);
  }
}

// 导出接口供其他模块使用
export { ProjectMeta, ProjectGroupMeta } from './FileStorageService';

// 定义StorageStats接口
interface StorageStats {
  totalProjects: number;
  totalSize: number;
}