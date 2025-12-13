// File: entry/src/main/ets/services/ImportService.ets
/**
 * 导入服务模块
 * 
 * 本模块负责项目数据的多格式导入功能，支持 JSON、Excel(CSV) 等多种导入格式。
 * 提供统一的导入接口，处理文件读取、数据解析、格式验证等功能。
 * 
 * 主要功能：
 * 1. JSON 导入：从 JSON 文件导入项目数据
 * 2. Excel/CSV 导入：从 CSV 表格导入任务数据并创建项目
 * 3. 文件选择：使用系统文件选择器选择文件
 * 4. 数据验证：验证导入数据的完整性和正确性
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-01-13
 */

import { fileIo as fs } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { Project, TaskNode, ChecklistItem, Dependency } from '../model/ProjectData';
import { StorageService } from './StorageService';
import util from '@ohos.util';

/**
 * 导入格式枚举
 */
export enum ImportFormat {
  /** JSON 格式 */
  JSON = 'json',
  /** CSV 表格 */
  CSV = 'csv'
}

/**
 * 导入结果接口
 */
export interface ImportResult {
  /** 是否成功 */
  success: boolean;
  /** 导入的项目 */
  project?: Project;
  /** 错误信息 */
  error?: string;
  /** 警告信息列表 */
  warnings?: string[];
}

/**
 * 导入检查清单项接口
 */
interface ImportChecklistItem {
  id?: string;
  text: string;
  isCompleted?: boolean;
}

/**
 * 导入任务接口
 */
interface ImportTaskData {
  id?: string;
  name: string;
  startDate: string | Date;
  endDate: string | Date;
  x?: number;
  y?: number;
  isCritical?: boolean;
  checklist?: ImportChecklistItem[];
  earlyStart?: number;
  earlyFinish?: number;
  lateStart?: number;
  lateFinish?: number;
}

/**
 * 导入依赖关系接口
 */
interface ImportDependency {
  fromId: string;
  toId: string;
}

/**
 * 导入项目数据接口
 */
interface ImportProject {
  id?: string;
  name: string;
  category?: string;
  lastModified?: number;
  tasks: ImportTaskData[];
  dependencies?: ImportDependency[];
  canvasOffsetX?: number;
  canvasOffsetY?: number;
  zoomScale?: number;
}

/**
 * JSON导入数据接口（与ExportService的格式保持一致）
 */
interface ImportProjectData {
  version?: string;
  exportTime?: string;
  project: ImportProject;
}

/**
 * CSV行数据接口
 */
interface CsvRowData {
  taskId: string;
  taskName: string;
  startDate: string;
  endDate: string;
  duration: string;
  isCritical: string;
  progress: string;
  totalChecklist: string;
  completedChecklist: string;
  x: string;
  y: string;
  predecessors?: string;  // 新增：前置任务列表（用分号分隔的任务ID）
}

/**
 * 导入服务类
 * 
 * 提供项目数据的多格式导入功能，统一管理导入流程和错误处理。
 */
export class ImportService {
  private static instance: ImportService;
  private storageService: StorageService;

  private constructor(storageService: StorageService) {
    this.storageService = storageService;
  }

  /**
   * 获取单例实例
   */
  public static getInstance(storageService: StorageService): ImportService {
    if (!ImportService.instance) {
      ImportService.instance = new ImportService(storageService);
    }
    return ImportService.instance;
  }

  /**
   * 导入项目（自动检测格式）
   * 
   * @returns 导入结果
   */
  public async importProject(): Promise<ImportResult> {
    try {
      console.log('[ImportService] 开始选择导入文件...');

      // 1. 显示文件选择器
      const fileUri = await this.selectFile();
      if (!fileUri) {
        return {
          success: false,
          error: '未选择文件'
        };
      }

      console.log(`[ImportService] 已选择文件: ${fileUri}`);

      // 2. 读取文件内容
      const fileContent = await this.readFile(fileUri);
      if (!fileContent) {
        return {
          success: false,
          error: '读取文件失败。请确保文件存在且应用有访问权限。\n提示：某些系统文件夹可能无法访问，请将文件复制到 Documents 或 Downloads 文件夹后重试。'
        };
      }

      console.log(`[ImportService] 文件内容长度: ${fileContent.length} 字符`);

      // 3. 检测文件格式并导入
      const format = this.detectFileFormat(fileUri, fileContent);
      console.log(`[ImportService] 检测到文件格式: ${format}`);

      switch (format) {
        case ImportFormat.JSON:
          return await this.importFromJSON(fileContent);
        case ImportFormat.CSV:
          return await this.importFromCSV(fileContent);
        default:
          return {
            success: false,
            error: '不支持的文件格式，请选择 JSON 或 CSV 文件'
          };
      }
    } catch (error) {
      console.error('[ImportService] 导入失败:', error);
      return {
        success: false,
        error: `导入失败: ${error.message || '未知错误'}`
      };
    }
  }

  /**
   * 显示文件选择器
   */
  private async selectFile(): Promise<string | null> {
    try {
      if (canIUse('SystemCapability.FileManagement.UserFileService')) {
        // 创建文档选择器
        const documentSelectOptions = new picker.DocumentSelectOptions();
        documentSelectOptions.maxSelectNumber = 1; // 只选择一个文件

        const documentPicker = new picker.DocumentViewPicker();
        const result = await documentPicker.select(documentSelectOptions);

        if (!result || result.length === 0) {
          console.log('[ImportService] 用户取消了文件选择');
          return null;
        }
        return result[0];
      }else {
        console.warn('[ImportService] 设备不支持文件选择器');
        return null;
      }
    } catch (error) {
      console.error('[ImportService] 文件选择失败:', error);
      return null;
    }
  }

  /**
   * 读取文件内容
   */
  private async readFile(fileUri: string): Promise<string | null> {
    try {
      console.log(`[ImportService] 开始读取文件: ${fileUri}`);
      
      if (canIUse('SystemCapability.FileManagement.File.FileIO')) {
        // 打开文件
        console.log('[ImportService] 正在打开文件...');
        const file = fs.openSync(fileUri, fs.OpenMode.READ_ONLY);
        console.log(`[ImportService] 文件已打开，文件描述符: ${file.fd}`);

        // 分块读取文件内容（避免预先知道文件大小）
        console.log('[ImportService] 正在读取文件内容...');
        const chunkSize = 1024 * 1024; // 每次读取 1MB
        const chunks: Uint8Array[] = [];
        let totalSize = 0;

        try {
          while (true) {
            const buffer = new ArrayBuffer(chunkSize);
            const bytesRead = fs.readSync(file.fd, buffer);

            if (bytesRead <= 0) {
              break; // 读取完成
            }

            // 只保存实际读取的字节
            const chunk = new Uint8Array(buffer, 0, bytesRead);
            chunks.push(chunk);
            totalSize += bytesRead;

            console.log(`[ImportService] 已读取 ${bytesRead} 字节，总计 ${totalSize} 字节`);

            if (bytesRead < chunkSize) {
              break; // 读取到文件末尾
            }
          }
        } finally {
          fs.closeSync(file);
        }

        console.log(`[ImportService] 文件内容读取完成，总大小: ${totalSize} 字节`);

        // 合并所有块
        const fullBuffer = new Uint8Array(totalSize);
        let offset = 0;
        for (const chunk of chunks) {
          fullBuffer.set(chunk, offset);
          offset += chunk.length;
        }

        // 解码为字符串
        const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
        const content = decoder.decodeToString(fullBuffer);
        console.log(`[ImportService] 文件内容解码完成，长度: ${content.length} 字符`);

        return content;
      }else {
        console.warn('[ImportService] 设备不支持文件IO');
        return null;
      }
    } catch (error) {
      console.error('[ImportService] 读取文件失败:', error);
      console.error(`[ImportService] 错误详情: ${JSON.stringify(error)}`);
      if (error instanceof Error) {
        console.error(`[ImportService] 错误消息: ${error.message}`);
      }
      // 尝试获取错误代码（如果存在）
      try {
        const errorObj = error as Record<string, Object>;
        if (errorObj?.code !== undefined) {
          console.error(`[ImportService] 错误代码: ${errorObj.code}`);
        }
      } catch {
        // 忽略类型转换错误
      }
      return null;
    }
  }
  /**
   * 检测文件格式
   */
  private detectFileFormat(fileUri: string, content: string): ImportFormat | null {
    // 先尝试通过文件扩展名判断
    const lowerUri = fileUri.toLowerCase();
    if (lowerUri.endsWith('.json')) {
      return ImportFormat.JSON;
    } else if (lowerUri.endsWith('.csv')) {
      return ImportFormat.CSV;
    }

    // 如果没有扩展名，尝试通过内容判断
    const trimmedContent = content.trim();
    
    // JSON格式检测
    if (trimmedContent.startsWith('{') || trimmedContent.startsWith('[')) {
      return ImportFormat.JSON;
    }

    // CSV格式检测（检查是否有逗号分隔的列）
    if (trimmedContent.includes(',') && trimmedContent.includes('\n')) {
      return ImportFormat.CSV;
    }

    return null;
  }

  /**
   * 从 JSON 导入
   */
  private async importFromJSON(jsonContent: string): Promise<ImportResult> {
    try {
      console.log('[ImportService] 开始解析 JSON 数据...');

      // 1. 解析 JSON
      const data: ImportProjectData = JSON.parse(jsonContent) as ImportProjectData;

      // 2. 验证数据格式
      if (!data.project) {
        return {
          success: false,
          error: 'JSON 格式错误：缺少 project 字段'
        };
      }

      // 3. 转换数据
      const project = this.convertJSONToProject(data);

      // 4. 保存项目
      await this.storageService.saveProject(project);

      console.log(`[ImportService] JSON 导入成功: ${project.id}`);
      return {
        success: true,
        project: project
      };
    } catch (error) {
      console.error('[ImportService] JSON 导入失败:', error);
      return {
        success: false,
        error: `JSON 导入失败: ${error.message || '数据格式错误'}`
      };
    }
  }

  /**
   * 从 CSV 导入
   */
  private async importFromCSV(csvContent: string): Promise<ImportResult> {
    try {
      console.log('[ImportService] 开始解析 CSV 数据...');

      // 1. 解析 CSV
      const rows = this.parseCSV(csvContent);
      if (rows.length === 0) {
        return {
          success: false,
          error: 'CSV 文件为空或格式错误'
        };
      }

      console.log(`[ImportService] 解析到 ${rows.length} 行数据`);

      // 2. 转换数据
      const project = this.convertCSVToProject(rows);

      // 3. 保存项目
      await this.storageService.saveProject(project);

      console.log(`[ImportService] CSV 导入成功: ${project.id}`);
      return {
        success: true,
        project: project,
        warnings: [`已导入 ${project.tasks.length} 个任务`]
      };
    } catch (error) {
      console.error('[ImportService] CSV 导入失败:', error);
      return {
        success: false,
        error: `CSV 导入失败: ${error.message || '数据格式错误'}`
      };
    }
  }

  /**
   * 将 JSON 数据转换为 Project 对象
   */
  private convertJSONToProject(data: ImportProjectData): Project {
    const projectData = data.project;

    // 创建新项目（生成新的ID）
    const project = new Project(
      `project_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`,
      projectData.name || '导入的项目'
    );

    project.category = projectData.category || '其他';
    project.lastModified = Date.now();

    // 转换任务列表
    project.tasks = projectData.tasks.map((taskData, index): TaskNode => {
      const checklistItems: ChecklistItem[] = (taskData.checklist || []).map((item, itemIndex): ChecklistItem => {
        return {
          id: `checklist_${Date.now()}_${index}_${itemIndex}`,
          text: item.text || '',
          isCompleted: item.isCompleted ?? false
        };
      });

      const task: TaskNode = {
        id: `task_${Date.now()}_${index}`,
        name: taskData.name || '未命名任务',
        startDate: typeof taskData.startDate === 'string' ? 
                   new Date(taskData.startDate) : 
                   new Date(taskData.startDate),
        endDate: typeof taskData.endDate === 'string' ? 
                 new Date(taskData.endDate) : 
                 new Date(taskData.endDate),
        x: taskData.x ?? 100 + (index % 3) * 250,
        y: taskData.y ?? 100 + Math.floor(index / 3) * 150,
        checklist: checklistItems,
        earlyStart: taskData.earlyStart ?? 0,
        earlyFinish: taskData.earlyFinish ?? 0,
        lateStart: taskData.lateStart ?? 0,
        lateFinish: taskData.lateFinish ?? 0,
        isCritical: taskData.isCritical ?? false
      };
      return task;
    });

    // 转换依赖关系（需要重新映射ID）
    const oldIdToNewId = new Map<string, string>();
    projectData.tasks.forEach((taskData, index) => {
      if (taskData.id) {
        oldIdToNewId.set(taskData.id, project.tasks[index].id);
      }
    });

    const validDependencies: Dependency[] = [];
    (projectData.dependencies || []).forEach((dep) => {
      const fromId = oldIdToNewId.get(dep.fromId) || dep.fromId;
      const toId = oldIdToNewId.get(dep.toId) || dep.toId;
      
      // 只保留有效的依赖关系
      const fromExists = project.tasks.some(t => t.id === fromId);
      const toExists = project.tasks.some(t => t.id === toId);
      
      if (fromExists && toExists) {
        const dependency: Dependency = { fromId, toId };
        validDependencies.push(dependency);
      }
    });
    
    project.dependencies = validDependencies;

    // 恢复画布状态
    project.canvasOffsetX = projectData.canvasOffsetX ?? 0;
    project.canvasOffsetY = projectData.canvasOffsetY ?? 0;
    project.zoomScale = projectData.zoomScale ?? 1.0;

    console.log(`[ImportService] JSON转换完成: ${project.tasks.length} 个任务, ${project.dependencies.length} 个依赖关系`);
    return project;
  }

  /**
   * 解析 CSV 内容
   */
  private parseCSV(content: string): CsvRowData[] {
    const lines = content.split('\n').map(line => line.trim()).filter(line => line.length > 0);
    
    if (lines.length < 2) {
      throw new Error('CSV 文件至少需要包含表头和一行数据');
    }

    // 跳过表头
    const dataLines = lines.slice(1);
    const rows: CsvRowData[] = [];

    for (const line of dataLines) {
      // 跳过空行和统计信息行
      if (line.startsWith('项目统计') || line.startsWith('项目名称') || 
          line.startsWith('任务总数') || line.startsWith('关键任务数') || 
          line.startsWith('依赖关系数') || line.startsWith('导出时间')) {
        break; // 遇到统计信息就停止解析
      }

      const columns = this.parseCsvLine(line);
      
      // 需要至少11列数据（兼容旧格式），12列为新格式（包含前置任务）
      if (columns.length >= 11) {
        rows.push({
          taskId: columns[0],
          taskName: columns[1],
          startDate: columns[2],
          endDate: columns[3],
          duration: columns[4],
          isCritical: columns[5],
          progress: columns[6],
          totalChecklist: columns[7],
          completedChecklist: columns[8],
          x: columns[9],
          y: columns[10],
          predecessors: columns.length >= 12 ? columns[11] : undefined  // 新增：前置任务列（可选）
        });
      }
    }

    return rows;
  }

  /**
   * 解析 CSV 行（处理引号和逗号）
   */
  private parseCsvLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      
      if (char === '"') {
        if (inQuotes && line[i + 1] === '"') {
          // 转义的引号
          current += '"';
          i++; // 跳过下一个引号
        } else {
          // 切换引号状态
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        // 列分隔符
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    // 添加最后一列
    result.push(current.trim());

    return result;
  }

  /**
   * 将 CSV 数据转换为 Project 对象
   */
  private convertCSVToProject(rows: CsvRowData[]): Project {
    // 创建新项目
    const project = new Project(
      `project_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`,
      `CSV导入项目_${new Date().toLocaleDateString()}`
    );

    project.category = '其他';
    project.lastModified = Date.now();

    // 建立原始ID到新ID的映射
    const oldIdToNewId = new Map<string, string>();

    // 转换任务列表
    project.tasks = rows.map((row, index) => {
      // 解析日期
      const startDate = this.parseDate(row.startDate);
      const endDate = this.parseDate(row.endDate);

      // 解析坐标
      const x = parseFloat(row.x) || (100 + (index % 3) * 250);
      const y = parseFloat(row.y) || (100 + Math.floor(index / 3) * 150);

      // 解析检查清单
      const totalChecklist = parseInt(row.totalChecklist) || 0;
      const completedChecklist = parseInt(row.completedChecklist) || 0;
      const checklist: ChecklistItem[] = [];
      
      for (let i = 0; i < totalChecklist; i++) {
        checklist.push({
          id: `checklist_${Date.now()}_${index}_${i}`,
          text: `子任务 ${i + 1}`,
          isCompleted: i < completedChecklist
        });
      }

      // 解析关键路径标志
      const isCritical = row.isCritical === '是' || row.isCritical.toLowerCase() === 'true';

      // 生成新的任务ID
      const newTaskId = `task_${Date.now()}_${index}`;
      
      // 记录原始ID到新ID的映射
      if (row.taskId) {
        oldIdToNewId.set(row.taskId, newTaskId);
      }

      const task: TaskNode = {
        id: newTaskId,
        name: row.taskName || '未命名任务',
        startDate: startDate,
        endDate: endDate,
        x: x,
        y: y,
        checklist: checklist,
        earlyStart: 0,
        earlyFinish: 0,
        lateStart: 0,
        lateFinish: 0,
        isCritical: isCritical
      };

      return task;
    });

    // 重建依赖关系
    project.dependencies = [];
    
    rows.forEach((row, index) => {
      // 如果该行包含前置任务信息
      if (row.predecessors && row.predecessors.trim().length > 0) {
        const currentTaskId = project.tasks[index].id;
        
        // 前置任务ID列表（用分号分隔）
        const predecessorIds = row.predecessors.split(';')
          .map(id => id.trim())
          .filter(id => id.length > 0);
        
        // 为每个前置任务创建依赖关系
        predecessorIds.forEach(oldPredecessorId => {
          // 将旧ID映射到新ID
          const newPredecessorId = oldIdToNewId.get(oldPredecessorId);
          
          if (newPredecessorId) {
            // 创建依赖关系：前置任务 -> 当前任务
            const dependency: Dependency = {
              fromId: newPredecessorId,
              toId: currentTaskId
            };
            
            project.dependencies.push(dependency);
            console.log(`[ImportService] 创建依赖关系: ${newPredecessorId} -> ${currentTaskId}`);
          } else {
            console.warn(`[ImportService] 警告：找不到前置任务ID映射: ${oldPredecessorId}`);
          }
        });
      }
    });

    console.log(`[ImportService] CSV转换完成: ${project.tasks.length} 个任务, ${project.dependencies.length} 个依赖关系`);
    return project;
  }

  /**
   * 解析日期字符串
   */
  private parseDate(dateString: string): Date {
    try {
      // 尝试多种日期格式
      const date = new Date(dateString);
      if (!isNaN(date.getTime())) {
        return date;
      }

      // 尝试中文日期格式 (YYYY/M/D 或 YYYY-M-D)
      const parts = dateString.split(/[\/\-\.]/);
      if (parts.length === 3) {
        const year = parseInt(parts[0]);
        const month = parseInt(parts[1]) - 1; // 月份从0开始
        const day = parseInt(parts[2]);
        return new Date(year, month, day);
      }

      // 如果都失败了，返回当前日期
      console.warn(`[ImportService] 无法解析日期: ${dateString}，使用当前日期`);
      return new Date();
    } catch (error) {
      console.error(`[ImportService] 日期解析错误: ${dateString}`, error);
      return new Date();
    }
  }

  /**
   * 获取支持的导入格式列表
   */
  public getSupportedFormats(): ImportFormat[] {
    return [
      ImportFormat.JSON,
      ImportFormat.CSV
    ];
  }

  /**
   * 检查格式是否支持
   */
  public isFormatSupported(format: ImportFormat): boolean {
    return this.getSupportedFormats().includes(format);
  }
}

