// File: entry/src/main/ets/services/ExportService.ets
/**
 * 导出服务模块
 * 
 * 本模块负责项目数据的多格式导出功能，支持 JSON、图片、Excel 等多种导出格式。
 * 提供统一的导出接口，处理文件生成、权限申请、错误处理等功能。
 * 
 * 主要功能：
 * 1. JSON 导出：将项目数据导出为 JSON 文件
 * 2. 图片导出：将画布内容导出为 PNG/JPG 图片
 * 3. Excel 导出：将任务数据导出为 CSV/Excel 表格
 * 4. 文件管理：处理文件保存、权限申请等
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-01-01
 */

import { fileIo as fs } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { Project, TaskNode } from '../model/ProjectData';
import { FileStorageService } from './FileStorageService';
import util from '@ohos.util';
import { image } from '@kit.ImageKit';
// import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';

/**
 * 导出格式枚举
 */
export enum ExportFormat {
  /** JSON 格式 */
  JSON = 'json',
  /** PNG 图片 */
  PNG = 'png',
  /** JPG 图片 */
  JPG = 'jpg',
  /** CSV 表格 */
  CSV = 'csv',
  /** Excel 表格 */
  EXCEL = 'xlsx'
}

/**
 * 导出选项接口
 */
export interface ExportOptions {
  /** 导出格式 */
  format: ExportFormat;
  /** 文件名（不含扩展名） */
  fileName: string;
  /** 是否包含时间戳 */
  includeTimestamp?: boolean;
  /** 图片质量（0-100，仅用于 JPG） */
  imageQuality?: number;
}

/**
 * 导出结果接口
 */
export interface ExportResult {
  /** 是否成功 */
  success: boolean;
  /** 文件路径 */
  filePath?: string;
  /** 文件大小（字节） */
  fileSize?: number;
  /** 错误信息 */
  error?: string;
}

/**
 * 导出任务数据接口
 */
interface ExportTaskData {
  id: string;
  name: string;
  startDate: string;
  endDate: string;
  x: number;
  y: number;
  isCritical: boolean;
  checklist: Array<Object>;
  earlyStart: number;
  earlyFinish: number;
  lateStart: number;
  lateFinish: number;
}

/**
 * 导出项目数据接口
 */
interface ExportProjectData {
  id: string;
  name: string;
  category: string;
  lastModified: number;
  tasks: ExportTaskData[];
  dependencies: Array<Object>;
  canvasOffsetX: number;
  canvasOffsetY: number;
  zoomScale: number;
}

/**
 * 完整导出数据接口
 */
interface CompleteExportData {
  version: string;
  exportTime: string;
  project: ExportProjectData;
}

/**
 * 导出服务类
 * 
 * 提供项目数据的多格式导出功能，统一管理导出流程和错误处理。
 */
export class ExportService {
  private static instance: ExportService;
  private fileStorageService: FileStorageService;
  private context: common.UIAbilityContext | null = null;

  private constructor(fileStorageService: FileStorageService) {
    this.fileStorageService = fileStorageService;
  }

  /**
   * 获取单例实例
   */
  public static getInstance(fileStorageService: FileStorageService): ExportService {
    if (!ExportService.instance) {
      ExportService.instance = new ExportService(fileStorageService);
    }
    return ExportService.instance;
  }

  /**
   * 设置应用上下文
   */
  public setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 导出项目
   * 
   * @param project 项目对象
   * @param options 导出选项
   * @param canvasPixelMap Canvas 的 PixelMap（用于图片导出）
   * @returns 导出结果
   */
  public async exportProject(
    project: Project,
    options: ExportOptions,
    canvasPixelMap?: image.PixelMap
  ): Promise<ExportResult> {
    try {
      console.log(`[ExportService] 开始导出项目: ${project.name}，格式: ${options.format}`);

      switch (options.format) {
        case ExportFormat.JSON:
          return await this.exportToJSON(project, options);
        case ExportFormat.PNG:
        case ExportFormat.JPG:
          return await this.exportToImage(project, options, canvasPixelMap);
        case ExportFormat.CSV:
        case ExportFormat.EXCEL:
          return await this.exportToExcel(project, options);
        default:
          return {
            success: false,
            error: `不支持的导出格式: ${options.format}`
          };
      }
    } catch (error) {
      console.error('[ExportService] 导出失败:', error);
      return {
        success: false,
        error: `导出失败: ${error.message || '未知错误'}`
      };
    }
  }

  /**
   * 导出为 JSON 格式
   */
  private async exportToJSON(project: Project, options: ExportOptions): Promise<ExportResult> {
    try {
      console.log('[ExportService] 开始导出 JSON...');

      // 1. 生成导出数据
      const exportData: CompleteExportData = {
        version: '1.0',
        exportTime: new Date().toISOString(),
        project: {
          id: project.id,
          name: project.name,
          category: project.category || '其他',
          lastModified: project.lastModified,
          tasks: project.tasks.map((task): ExportTaskData => {
            const taskData: ExportTaskData = {
              id: task.id,
              name: task.name,
              startDate: task.startDate.toISOString(),
              endDate: task.endDate.toISOString(),
              x: task.x,
              y: task.y,
              isCritical: task.isCritical ?? false,
              checklist: task.checklist || [],
              earlyStart: task.earlyStart ?? 0,
              earlyFinish: task.earlyFinish ?? 0,
              lateStart: task.lateStart ?? 0,
              lateFinish: task.lateFinish ?? 0
            };
            return taskData;
          }),
          dependencies: project.dependencies,
          canvasOffsetX: project.canvasOffsetX || 0,
          canvasOffsetY: project.canvasOffsetY || 0,
          zoomScale: project.zoomScale || 1.0
        }
      };

      const jsonString = JSON.stringify(exportData, null, 2);
      console.log(`[ExportService] JSON 数据大小: ${jsonString.length} 字符`);

      // 2. 生成文件名
      const fileName = this.generateFileName(options.fileName, 'json', options.includeTimestamp);
      console.log(`[ExportService] 文件名: ${fileName}`);

      // 3. 使用文档选择器保存文件
      const filePath = await this.saveFileWithPicker(fileName, jsonString, 'application/json');

      if (filePath) {
        console.log(`[ExportService] JSON 文件已保存: ${filePath}`);
        return {
          success: true,
          filePath: filePath,
          fileSize: jsonString.length
        };
      } else {
        return {
          success: false,
          error: '用户取消了保存操作'
        };
      }
    } catch (error) {
      console.error('[ExportService] JSON 导出失败:', error);
      return {
        success: false,
        error: `JSON 导出失败: ${error.message || '未知错误'}`
      };
    }
  }

  /**
   * 导出为图片格式
   */
  private async exportToImage(
    project: Project,
    options: ExportOptions,
    canvasPixelMap?: image.PixelMap
  ): Promise<ExportResult> {
    try {
      console.log('[ExportService] 开始导出图片...');

      if (!canvasPixelMap) {
        return {
          success: false,
          error: '缺少 Canvas 数据，无法导出图片'
        };
      }

      // 1. 直接使用Canvas导出的图片（已经是正确尺寸，无需裁剪）
      const processedPixelMap = canvasPixelMap;
      
      // 获取图片信息用于日志
      const imageInfo = await processedPixelMap.getImageInfo();
      console.log(`[ExportService] 导出图片尺寸: ${imageInfo.size.width}x${imageInfo.size.height}`);

      // 2. 生成文件名
      const extension = options.format === ExportFormat.PNG ? 'png' : 'jpg';
      const fileName = this.generateFileName(options.fileName, extension, options.includeTimestamp);
      console.log(`[ExportService] 图片文件名: ${fileName}`);

      // 3. 将 PixelMap 打包为图片数据
      const imagePackerApi = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: options.format === ExportFormat.PNG ? 'image/png' : 'image/jpeg',
        quality: options.imageQuality || 95
      };

      const imageData = await imagePackerApi.packing(processedPixelMap, packOptions);
      console.log(`[ExportService] 图片数据大小: ${imageData.byteLength} 字节`);

      // 4. 保存到相册或使用文档选择器
      const filePath = await this.saveImageFile(fileName, imageData);

      if (filePath) {
        console.log(`[ExportService] 图片已保存: ${filePath}`);
        return {
          success: true,
          filePath: filePath,
          fileSize: imageData.byteLength
        };
      } else {
        return {
          success: false,
          error: '保存图片失败'
        };
      }
    } catch (error) {
      console.error('[ExportService] 图片导出失败:', error);
      return {
        success: false,
        error: `图片导出失败: ${error.message || '未知错误'}`
      };
    }
  }

  /**
   * 导出为 Excel/CSV 格式
   */
  private async exportToExcel(project: Project, options: ExportOptions): Promise<ExportResult> {
    try {
      console.log('[ExportService] 开始导出 Excel/CSV...');

      // 1. 生成 CSV 数据
      const csvData = this.generateCSV(project);
      console.log(`[ExportService] CSV 数据大小: ${csvData.length} 字符`);

      // 2. 生成文件名
      const fileName = this.generateFileName(
        options.fileName,
        'csv',
        options.includeTimestamp
      );
      console.log(`[ExportService] CSV 文件名: ${fileName}`);

      // 3. 保存文件
      const filePath = await this.saveFileWithPicker(fileName, csvData, 'text/csv');

      if (filePath) {
        console.log(`[ExportService] CSV 文件已保存: ${filePath}`);
        return {
          success: true,
          filePath: filePath,
          fileSize: csvData.length
        };
      } else {
        return {
          success: false,
          error: '用户取消了保存操作'
        };
      }
    } catch (error) {
      console.error('[ExportService] Excel/CSV 导出失败:', error);
      return {
        success: false,
        error: `Excel/CSV 导出失败: ${error.message || '未知错误'}`
      };
    }
  }

  /**
   * 生成 CSV 数据
   */
  private generateCSV(project: Project): string {
    // CSV 表头
    const headers = [
      '任务ID',
      '任务名称',
      '开始日期',
      '结束日期',
      '持续天数',
      '是否关键路径',
      '完成进度',
      '子任务总数',
      '已完成子任务',
      'X坐标',
      'Y坐标',
      '前置任务'  // 新增：依赖关系列
    ];

    // 构建 CSV 行
    const rows: string[] = [headers.join(',')];

    project.tasks.forEach(task => {
      const duration = this.calculateDuration(task);
      const totalChecklist = task.checklist?.length || 0;
      const completedChecklist = task.checklist?.filter(item => item.isCompleted).length || 0;
      const progress = totalChecklist > 0 ? Math.round((completedChecklist / totalChecklist) * 100) : 0;

      // 查找所有指向该任务的前置任务（fromId -> toId，这个任务是toId）
      const predecessors = project.dependencies
        .filter(dep => dep.toId === task.id)
        .map(dep => dep.fromId);
      
      // 将前置任务ID列表用分号分隔
      const predecessorStr = predecessors.length > 0 ? predecessors.join(';') : '';

      const row = [
        this.escapeCsvValue(task.id),
        this.escapeCsvValue(task.name),
        this.formatDate(task.startDate),
        this.formatDate(task.endDate),
        duration.toString(),
        task.isCritical ? '是' : '否',
        `${progress}%`,
        totalChecklist.toString(),
        completedChecklist.toString(),
        task.x.toString(),
        task.y.toString(),
        this.escapeCsvValue(predecessorStr)  // 新增：前置任务列表
      ];

      rows.push(row.join(','));
    });

    // 添加项目统计信息
    rows.push('');
    rows.push('项目统计');
    rows.push(`项目名称,${this.escapeCsvValue(project.name)}`);
    rows.push(`任务总数,${project.tasks.length}`);
    rows.push(`关键任务数,${project.tasks.filter(t => t.isCritical).length}`);
    rows.push(`依赖关系数,${project.dependencies.length}`);
    rows.push(`导出时间,${new Date().toLocaleString()}`);

    return rows.join('\n');
  }

  /**
   * 转义 CSV 值
   */
  private escapeCsvValue(value: string): string {
    // 如果包含逗号、引号或换行符，需要用引号包裹并转义内部引号
    if (value.includes(',') || value.includes('"') || value.includes('\n')) {
      return `"${value.replace(/"/g, '""')}"`;
    }
    return value;
  }

  /**
   * 计算任务持续天数
   */
  private calculateDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return date.toLocaleDateString('zh-CN');
  }

  /**
   * 生成文件名
   */
  private generateFileName(baseName: string, extension: string, includeTimestamp: boolean = true): string {
    let fileName = baseName.replace(/[<>:"/\\|?*]/g, '_'); // 移除非法字符
    
    if (includeTimestamp) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      fileName = `${fileName}_${timestamp}`;
    }
    
    return `${fileName}.${extension}`;
  }

  /**
   * 使用文档选择器保存文件
   */
  private async saveFileWithPicker(fileName: string, content: string, mimeType: string): Promise<string | null> {
    try {
      if (canIUse('SystemCapability.FileManagement.UserFileService')) {


        // 创建文档保存选择器
        const documentSaveOptions = new picker.DocumentSaveOptions();
        documentSaveOptions.newFileNames = [fileName];

        const documentPicker = new picker.DocumentViewPicker();
        const uris = await documentPicker.save(documentSaveOptions);

        if (!uris || uris.length === 0) {
          console.log('[ExportService] 用户取消了文件保存');
          return null;
        }

        const uri = uris[0];
        console.log(`[ExportService] 保存文件到: ${uri}`);
        if(canIUse('SystemCapability.FileManagement.File.FileIO')){
          // 将内容写入文件
          const file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
          const encoder = new util.TextEncoder();
          const uint8Array = encoder.encodeInto(content);
          const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);

          fs.writeSync(file.fd, buffer);
          fs.closeSync(file);
        }else {
          console.warn('[ExportService] 设备不支持文件选择器');
          return null;
        }

        console.log('[ExportService] 文件写入完成');
        return uri;
      }else {
        console.warn('[ExportService] 设备不支持文件选择器');
        return null;
      }
    } catch (error) {
      console.error('[ExportService] 文件保存失败:', error);
      return null;
    }
  }

  /**
   * 保存图片文件
   */
  private async saveImageFile(fileName: string, imageData: ArrayBuffer): Promise<string | null> {
    try {
      // 方案1：保存到相册（需要权限）
      // 方案2：使用文档选择器（推荐）
      
      if (canIUse('SystemCapability.FileManagement.UserFileService')) {


        // 使用文档选择器保存图片
        const documentSaveOptions = new picker.DocumentSaveOptions();
        documentSaveOptions.newFileNames = [fileName];

        const documentPicker = new picker.DocumentViewPicker();
        const uris = await documentPicker.save(documentSaveOptions);

        if (!uris || uris.length === 0) {
          console.log('[ExportService] 用户取消了图片保存');
          return null;
        }

        const uri = uris[0];
        console.log(`[ExportService] 保存图片到: ${uri}`);

        if(canIUse('SystemCapability.FileManagement.File.FileIO')){ // 写入图片数据
          const file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
          fs.writeSync(file.fd, imageData);
          fs.closeSync(file);
        }else {
          console.warn('[ExportService] 设备不支持文件选择器');
          return null;
        }

        console.log('[ExportService] 图片写入完成');
        return uri;
      }else{
        console.warn('[ExportService] 设备不支持文件选择器');
        return null;
      }
    } catch (error) {
      console.error('[ExportService] 图片保存失败:', error);
      return null;
    }
  }

  /**
   * 获取支持的导出格式列表
   */
  public getSupportedFormats(): ExportFormat[] {
    return [
      ExportFormat.JSON,
      ExportFormat.PNG,
      ExportFormat.JPG,
      ExportFormat.CSV
    ];
  }

  /**
   * 检查格式是否支持
   */
  public isFormatSupported(format: ExportFormat): boolean {
    return this.getSupportedFormats().includes(format);
  }
}

