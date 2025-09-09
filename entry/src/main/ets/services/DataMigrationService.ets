// File: entry/src/main/ets/services/DataMigrationService.ets
import preferences from '@ohos.data.preferences';
import { FileStorageService, ProjectMeta } from './FileStorageService';
import { Project, TaskNode } from '../model/ProjectData';

// 迁移结果接口
interface MigrationResult {
  success: boolean;
  migratedCount: number;
  errors: string[];
}

// 迁移统计接口
interface MigrationStats {
  oldProjectCount: number;
  newProjectCount: number;
  needsMigration: boolean;
}

// 旧存储的接口定义
interface StorableTaskNode extends Omit<TaskNode, 'startDate' | 'endDate'> {
  startDate: string;
  endDate: string;
}

interface StorableProject extends Omit<Project, 'tasks' | 'addTask'> {
  tasks: StorableTaskNode[];
  category: string;
}

/**
 * 数据迁移服务
 * 负责从preferences存储迁移到文件系统存储
 */
export class DataMigrationService {
  private static instance: DataMigrationService;
  private fileStorage: FileStorageService;
  private oldStore: Promise<preferences.Preferences>;

  private constructor(filesDir: string) {
    this.fileStorage = FileStorageService.getInstance(filesDir);
    this.oldStore = preferences.getPreferences(getContext(), 'project_storage');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(filesDir: string): DataMigrationService {
    if (!DataMigrationService.instance) {
      DataMigrationService.instance = new DataMigrationService(filesDir);
    }
    return DataMigrationService.instance;
  }

  /**
   * 检查是否需要迁移数据
   */
  public async needsMigration(): Promise<boolean> {
    try {
      // 检查新存储中是否已有数据
      const newProjectList = await this.fileStorage.getProjectList();
      if (newProjectList.length > 0) {
        return false; // 新存储已有数据，不需要迁移
      }

      // 检查旧存储中是否有数据
      const oldStore = await this.oldStore;
      const projectListValue = await oldStore.get('project_list', '[]');
      const oldProjectList = JSON.parse(projectListValue.toString()) as ProjectMeta[];
      
      return oldProjectList.length > 0;
    } catch (error) {
      console.error('[DataMigrationService] 检查迁移需求失败:', error);
      return false;
    }
  }

  /**
   * 执行数据迁移
   */
  public async migrateData(): Promise<MigrationResult> {
    const result: MigrationResult = {
      success: false,
      migratedCount: 0,
      errors: []
    };

    try {
      console.log('[DataMigrationService] 开始数据迁移...');
      
      const oldStore = await this.oldStore;
      
      // 1. 迁移项目列表
      const projectListValue = await oldStore.get('project_list', '[]');
      const oldProjectList = JSON.parse(projectListValue.toString()) as ProjectMeta[];
      
      console.log(`[DataMigrationService] 发现 ${oldProjectList.length} 个项目需要迁移`);
      
      // 2. 迁移每个项目
      for (const projectMeta of oldProjectList) {
        try {
          const projectValue = await oldStore.get(projectMeta.id, '');
          if (projectValue) {
            const storableProject = JSON.parse(projectValue.toString()) as StorableProject;
            
            // 转换为完整的Project对象
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
            
            // 保存到新存储
            await this.fileStorage.saveProject(project);
            result.migratedCount++;
            
            console.log(`[DataMigrationService] 项目 ${project.name} 迁移成功`);
          }
        } catch (error) {
          const errorMsg = `迁移项目 ${projectMeta.id} 失败: ${error.message}`;
          console.error(`[DataMigrationService] ${errorMsg}`);
          result.errors.push(errorMsg);
        }
      }
      
      // 3. 清理旧数据（可选）
      if (result.errors.length === 0) {
        await this.cleanupOldData();
        console.log('[DataMigrationService] 旧数据已清理');
      }
      
      result.success = result.errors.length === 0;
      console.log(`[DataMigrationService] 数据迁移完成，成功迁移 ${result.migratedCount} 个项目`);
      
    } catch (error) {
      const errorMsg = `数据迁移过程失败: ${error.message}`;
      console.error(`[DataMigrationService] ${errorMsg}`);
      result.errors.push(errorMsg);
    }

    return result;
  }

  /**
   * 清理旧数据
   */
  private async cleanupOldData(): Promise<void> {
    try {
      const oldStore = await this.oldStore;
      
      // 获取所有项目ID
      const projectListValue = await oldStore.get('project_list', '[]');
      const oldProjectList = JSON.parse(projectListValue.toString()) as ProjectMeta[];
      
      // 删除项目数据
      for (const projectMeta of oldProjectList) {
        await oldStore.delete(projectMeta.id);
      }
      
      // 删除项目列表
      await oldStore.delete('project_list');
      await oldStore.flush();
      
      console.log('[DataMigrationService] 旧数据清理完成');
    } catch (error) {
      console.error('[DataMigrationService] 清理旧数据失败:', error);
    }
  }

  /**
   * 获取迁移统计信息
   */
  public async getMigrationStats(): Promise<MigrationStats> {
    try {
      const oldStore = await this.oldStore;
      const projectListValue = await oldStore.get('project_list', '[]');
      const oldProjectList = JSON.parse(projectListValue.toString()) as ProjectMeta[];
      
      const newProjectList = await this.fileStorage.getProjectList();
      
      const stats: MigrationStats = {
        oldProjectCount: oldProjectList.length,
        newProjectCount: newProjectList.length,
        needsMigration: await this.needsMigration()
      };
      return stats;
    } catch (error) {
      console.error('[DataMigrationService] 获取迁移统计失败:', error);
      const defaultStats: MigrationStats = {
        oldProjectCount: 0,
        newProjectCount: 0,
        needsMigration: false
      };
      return defaultStats;
    }
  }
}
