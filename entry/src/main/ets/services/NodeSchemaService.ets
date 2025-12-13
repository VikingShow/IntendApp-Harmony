// File: entry/src/main/ets/services/NodeSchemaService.ets
/**
 * 节点 Schema 服务模块
 *
 * 本模块负责管理节点类型（NodeSchema）的集中配置，
 * 为节点工作台、任务编辑器、画布渲染等提供统一的数据来源。
 *
 * 设计目标：
 * - 统一管理所有可用的节点类型定义
 * - 提供查询、增删改接口，方便节点工作台编辑
 * - 支持将 Schema 导出为 JSON 以便分享
 * - 支持从 JSON 导入 Schema 以便复用
 *
 * 注意：
 * - 为兼容 ArkTS 限制，本模块不使用 any/unknown/索引签名/交叉类型
 */

import { NodeSchema } from '../model/NodeSchema';
import { fileIo as fs } from '@kit.CoreFileKit';
import util from '@ohos.util';

interface HistoryEntry {
  id: string;
  history: NodeSchema[];
}

/**
 * 节点 Schema 服务类（单例）
 */
export class NodeSchemaService {
  /** 单例实例 */
  private static instance: NodeSchemaService;
  /** 已发布节点类型存储 Map，key 为 NodeSchema.id，value 为 NodeSchema */
  private publishedSchemas: Map<string, NodeSchema> = new Map();
  /** 草稿节点类型存储 Map，key 为 NodeSchema.id，value 为 NodeSchema */
  private draftSchemas: Map<string, NodeSchema> = new Map();
  /** 历史版本存储 Map，key 为 NodeSchema.id，value 为 NodeSchema 数组 */
  private historySchemas: Map<string, NodeSchema[]> = new Map();
  /** 存储目录路径（由 UIAbility 传入） */
  private baseDir: string | null = null;
  /** 已发布版本持久化文件路径 */
  private publishedFile: string | null = null;
  /** 草稿版本持久化文件路径 */
  private draftFile: string | null = null;
  /** 历史版本持久化文件路径 */
  private historyFile: string | null = null;

  /**
   * 获取单例实例
   */
  static getInstance(): NodeSchemaService {
    if (!NodeSchemaService.instance) {
      const service = new NodeSchemaService();
      service.initializeDefaultSchemas();
      NodeSchemaService.instance = service;
    }
    return NodeSchemaService.instance;
  }

  /**
   * 初始化持久化存储路径
   * @param baseDir 应用文件目录（如 /data/storage/el2/base/haps/entry/files）
   */
  public initializeStorage(baseDir: string): void {
    if (!baseDir || baseDir.length === 0) {
      return;
    }
    // 只在第一次设置，避免被意外覆盖
    if (!this.baseDir) {
      this.baseDir = baseDir;
      this.publishedFile = `${baseDir}/node_schemas_published.json`;
      this.draftFile = `${baseDir}/node_schemas_draft.json`;
      this.historyFile = `${baseDir}/node_schemas_history.json`;
      console.log(`[NodeSchemaService] 初始化存储路径: 发布=${this.publishedFile}, 草稿=${this.draftFile}, 历史=${this.historyFile}`);
    }
  }

  /**
   * 初始化内置节点类型
   *
   * 系统内置节点类型：
   * - standard：标准任务（蓝色）- 默认的通用任务类型
   */
  private initializeDefaultSchemas(): void {
    const now = Date.now();
    const standard: NodeSchema = {
      id: 'standard',
      version: 1,
      name: '标准任务',
      description: '默认的标准任务节点，适用于所有常规任务',
      meta: {
        author: 'system',
        createdAt: now,
        updatedAt: now,
        category: 'builtin'
      },
      style: {
        fillColor: '#409EFF',
        criticalColor: '#D0021B',
        borderRadius: 16,
        borderWidth: 2
      },
      fields: [
        {
          id: '_priority',
          label: '优先级',
          type: 'select',
          required: false,
          options: ['低', '中', '高', '紧急']
        },
        {
          id: '_status',
          label: '状态',
          type: 'select',
          required: false,
          options: ['未开始', '进行中', '阻塞', '已完成']
        },
        {
          id: '_tags',
          label: '标签',
          type: 'checklist',
          required: false,
          options: ['前端', '后端', '设计', '测试', '文档']
        },
        {
          id: '_assignee',
          label: '负责人',
          type: 'text',
          required: false
        }
      ],
      layout: [
        { id: 'title_1', type: 'TITLE' },
        { id: 'date_range_1', type: 'DATE_RANGE' },
        { id: 'time_progress_1', type: 'TIME_PROGRESS' },
        { id: 'task_progress_1', type: 'TASK_PROGRESS' }
      ],
      rules: [],
      isSystem: true,
      isDraft: false
    };

    this.publishedSchemas.set(standard.id, standard);
  }

  /**
   * 获取全部节点类型列表（草稿 + 已发布）
   */
  public getAllSchemas(): NodeSchema[] {
    const publishedArray = Array.from(this.publishedSchemas.values());
    const draftArray = Array.from(this.draftSchemas.values());
    const result: NodeSchema[] = [];
    for (const schema of publishedArray) {
      result.push(schema);
    }
    for (const schema of draftArray) {
      result.push(schema);
    }
    return result;
  }

  /**
   * 仅获取已发布的节点类型列表
   */
  public getPublishedSchemas(): NodeSchema[] {
    return Array.from(this.publishedSchemas.values());
  }

  /**
   * 仅获取草稿节点类型列表
   */
  public getDraftSchemas(): NodeSchema[] {
    return Array.from(this.draftSchemas.values());
  }

  public getDefaultSchemaId(): string {
    // 优先选 isDefault 标记的 schema（草稿优先于已发布）
    const drafts = Array.from(this.draftSchemas.values());
    for (const s of drafts) {
      if (s.isDefault) {
        return s.id;
      }
    }
    const published = Array.from(this.publishedSchemas.values());
    for (const s of published) {
      if (s.isDefault) {
        return s.id;
      }
    }

    // 兜底：standard
    if (this.publishedSchemas.has('standard') || this.draftSchemas.has('standard')) {
      return 'standard';
    }

    // 最后兜底：任意一个 schema
    const all = this.getAllSchemas();
    if (all.length > 0) {
      return all[0].id;
    }
    return 'standard';
  }

  /**
   * 按 ID 获取节点类型（优先查草稿，再查已发布）
   * @param id 节点类型 ID
   */
  public getSchemaById(id: string): NodeSchema | null {
    const draft = this.draftSchemas.get(id);
    if (draft) {
      return draft;
    }
    const published = this.publishedSchemas.get(id);
    return published ? published : null;
  }

  /**
   * 新增或更新一个节点类型（自动判断草稿/已发布）
   * @param schema 节点类型配置
   */
  public upsertSchema(schema: NodeSchema): void {
    if (!schema || !schema.id) {
      return;
    }
    // 数据完整性补全
    if (!schema.fields) schema.fields = [];
    if (!schema.layout) schema.layout = [];
    if (!schema.rules) schema.rules = [];
    if (!schema.ports) schema.ports = [];

    // 更新时间戳
    if (!schema.meta) {
      schema.meta = {};
    }
    schema.meta.updatedAt = Date.now();
    
    if (schema.isDraft) {
      this.draftSchemas.set(schema.id, schema);
    } else {
      this.publishedSchemas.set(schema.id, schema);
    }
  }

  /**
   * 删除一个节点类型（同时删除草稿和已发布）
   * @param id 节点类型 ID
   */
  public deleteSchema(id: string): void {
    if (!id) {
      return;
    }
    this.draftSchemas.delete(id);
    this.publishedSchemas.delete(id);
    this.historySchemas.delete(id);
  }

  /**
   * 设置默认节点类型
   * @param id 节点类型 ID
   */
  public setDefaultSchema(id: string): void {
    // 1. 取消所有其他的默认设置
    this.publishedSchemas.forEach(schema => {
      if (schema.isDefault) {
        schema.isDefault = false;
        // 触发更新
        schema.meta = schema.meta || {};
        schema.meta.updatedAt = Date.now();
      }
    });
    this.draftSchemas.forEach(schema => {
      if (schema.isDefault) {
        schema.isDefault = false;
        schema.meta = schema.meta || {};
        schema.meta.updatedAt = Date.now();
      }
    });

    // 2. 设置新的默认值
    const schema = this.getSchemaById(id);
    if (schema) {
      schema.isDefault = true;
      schema.meta = schema.meta || {};
      schema.meta.updatedAt = Date.now();
      
      // 如果在草稿和发布中都存在，都需要更新
      if (this.draftSchemas.has(id)) {
        const draft = this.draftSchemas.get(id);
        if (draft) {
          draft.isDefault = true;
          draft.meta = draft.meta || {};
          draft.meta.updatedAt = Date.now();
        }
      }
      if (this.publishedSchemas.has(id)) {
        const published = this.publishedSchemas.get(id);
        if (published) {
          published.isDefault = true;
          published.meta = published.meta || {};
          published.meta.updatedAt = Date.now();
        }
      }
      
      this.saveToStorage();
    }
  }

  /**
   * 发布草稿（将草稿移至已发布，版本号+1）
   * @param id 节点类型 ID
   * @returns 是否发布成功
   */
  public publishDraft(id: string): boolean {
    const draft = this.draftSchemas.get(id);
    if (!draft) {
      console.error(`[NodeSchemaService] publishDraft failed: draft not found for id=${id}`);
      return false;
    }

    // 存档旧的发布版本到历史
    const oldPublished = this.publishedSchemas.get(id);
    if (oldPublished) {
      let history = this.historySchemas.get(id);
      if (!history) {
        history = [];
        this.historySchemas.set(id, history);
      }
      // 避免重复添加同一版本
      if (!history.some(h => h.version === oldPublished.version)) {
        history.push(oldPublished);
        // 按版本号排序
        history.sort((a, b) => a.version - b.version);
      }
    }

    // 创建已发布版本（版本号+1）
    const published: NodeSchema = {
      id: draft.id,
      version: draft.version + 1,
      name: draft.name,
      description: draft.description,
      meta: draft.meta,
      ports: draft.ports,
      style: draft.style,
      fields: draft.fields,
      layout: draft.layout,
      rules: draft.rules,
      isSystem: draft.isSystem,
      isDraft: false,
      parentVersionId: undefined
    };

    // 移动到已发布区域
    this.publishedSchemas.set(id, published);
    this.draftSchemas.delete(id);

    console.log(`[NodeSchemaService] published schema id=${id}, version=${published.version}`);
    return true;
  }

  /**
   * 从已发布版本创建草稿
   * @param id 节点类型 ID
   * @returns 是否创建成功
   */
  public createDraftFromPublished(id: string): boolean {
    const published = this.publishedSchemas.get(id);
    if (!published) {
      console.error(`[NodeSchemaService] createDraft failed: published not found for id=${id}`);
      return false;
    }

    // 检查是否已有草稿
    if (this.draftSchemas.has(id)) {
      console.warn(`[NodeSchemaService] draft already exists for id=${id}`);
      return false;
    }

    // 创建草稿（保持版本号不变，记录父版本）
    const draft: NodeSchema = {
      id: published.id,
      version: published.version,
      name: published.name,
      description: published.description,
      meta: published.meta,
      ports: published.ports,
      style: published.style,
      fields: published.fields,
      layout: published.layout,
      rules: published.rules,
      isSystem: published.isSystem,
      isDraft: true,
      parentVersionId: `${id}_v${published.version}`
    };

    this.draftSchemas.set(id, draft);
    console.log(`[NodeSchemaService] created draft from published id=${id}`);
    return true;
  }

  /**
   * 获取节点类型的历史版本列表
   * @param id 节点类型 ID
   */
  public getHistory(id: string): NodeSchema[] {
    const history = this.historySchemas.get(id);
    return history ? [...history] : [];
  }

  /**
   * 将指定版本恢复为草稿
   * @param id 节点类型 ID
   * @param version 目标版本号
   * @returns 是否成功（如果已有草稿会失败，返回 false）
   */
  public restoreToDraft(id: string, version: number): boolean {
    // 1. 查找目标版本
    let targetSchema: NodeSchema | undefined;
    
    // 检查已发布版本
    const published = this.publishedSchemas.get(id);
    if (published && published.version === version) {
      targetSchema = published;
    } else {
      // 检查历史版本
      const history = this.historySchemas.get(id);
      if (history) {
        targetSchema = history.find(s => s.version === version);
      }
    }

    if (!targetSchema) {
      console.error(`[NodeSchemaService] restoreToDraft failed: version ${version} not found for id=${id}`);
      return false;
    }

    // 2. 检查是否已有草稿
    if (this.draftSchemas.has(id)) {
      console.warn(`[NodeSchemaService] restoreToDraft failed: draft already exists for id=${id}`);
      return false;
    }

    // 3. 创建草稿
    // 草稿的版本号应该基于当前最新已发布版本，以确保下次发布时版本号连续
    // 如果没有已发布版本（理论上不应发生，因为restore是从历史来的），则使用目标版本
    const baseVersion = published ? published.version : targetSchema.version;

    const draft: NodeSchema = {
      id: targetSchema.id,
      version: baseVersion, // 保持与当前发布版本一致，下次发布自动+1
      name: targetSchema.name,
      description: targetSchema.description,
      meta: {
        author: targetSchema.meta?.author,
        createdAt: targetSchema.meta?.createdAt,
        updatedAt: Date.now(),
        tags: targetSchema.meta?.tags,
        category: targetSchema.meta?.category,
        notes: targetSchema.meta?.notes
      },
      ports: targetSchema.ports ? targetSchema.ports.slice() : [],
      style: JSON.parse(JSON.stringify(targetSchema.style)),
      fields: targetSchema.fields ? JSON.parse(JSON.stringify(targetSchema.fields)) : [],
      layout: targetSchema.layout ? JSON.parse(JSON.stringify(targetSchema.layout)) : [],
      rules: targetSchema.rules ? JSON.parse(JSON.stringify(targetSchema.rules)) : [],
      isSystem: targetSchema.isSystem,
      isDraft: true,
      isDefault: targetSchema.isDefault,
      parentVersionId: `${id}_v${targetSchema.version}_restored`
    };

    this.draftSchemas.set(id, draft);
    console.log(`[NodeSchemaService] restored draft from version ${version} for id=${id}`);
    return true;
  }

  /**
   * 导出当前所有节点类型为 JSON 字符串
   * 用于分享 / 备份 / 导出
   */
  public exportSchemasToJson(): string {
    const list = this.getAllSchemas();
    return JSON.stringify(list, null, 2);
  }

  /**
   * 导出单个节点类型为 JSON 字符串
   * @param id 节点类型 ID
   */
  public exportSchemaToJson(id: string): string | null {
    const schema = this.getSchemaById(id);
    if (!schema) {
      return null;
    }
    return JSON.stringify(schema, null, 2);
  }

  /**
   * 从 JSON 字符串导入节点类型集合
   *
   * 导入策略：
   * - 要求 JSON 为 NodeSchema 数组
   * - 基本校验：必须包含 id/name/style 字段
   * - 导入成功后会覆盖当前内存中的所有 Schema（包括草稿和已发布）
   *
   * @param json JSON 字符串
   * @returns 是否导入成功
   */
  public importSchemasFromJson(json: string): boolean {
    try {
      const parsed: NodeSchema[] = JSON.parse(json) as NodeSchema[];
      if (!Array.isArray(parsed)) {
        console.error('[NodeSchemaService] import failed: root is not array');
        return false;
      }

      // 基本结构校验
      for (let i = 0; i < parsed.length; i++) {
        const item: NodeSchema = parsed[i];
        if (!item || !item.id || !item.name || !item.style) {
          console.error('[NodeSchemaService] import failed: invalid schema at index', i);
          return false;
        }
        // 校验 style.fillColor 存在
        if (!item.style.fillColor) {
          console.error('[NodeSchemaService] import failed: missing fillColor at index', i);
          return false;
        }
        // 确保 version 字段存在
        if (item.version === undefined || item.version === null) {
          item.version = 1;
        }
      }

      // 覆盖当前配置（分离草稿和已发布）
      this.draftSchemas.clear();
      this.publishedSchemas.clear();
      parsed.forEach((schema: NodeSchema) => {
        // 数据完整性补全
        if (!schema.fields) schema.fields = [];
        if (!schema.layout) schema.layout = [];
        if (!schema.rules) schema.rules = [];
        if (!schema.ports) schema.ports = [];

        if (schema.isDraft) {
          this.draftSchemas.set(schema.id, schema);
        } else {
          this.publishedSchemas.set(schema.id, schema);
        }
      });

      console.log(`[NodeSchemaService] import succeeded, total ${parsed.length} schemas`);
      return true;
    } catch (error) {
      console.error('[NodeSchemaService] importSchemasFromJson error:', error);
      return false;
    }
  }

  /**
   * 验证 JSON 字符串并返回错误信息
   * @param json JSON 字符串
   * @returns 错误信息，如果为空字符串则表示验证通过
   */
  public validateSchemaJson(json: string): string {
    try {
      const parsed: NodeSchema[] = JSON.parse(json) as NodeSchema[];
      if (!Array.isArray(parsed)) {
        return 'JSON 必须是数组格式';
      }

      if (parsed.length === 0) {
        return '数组不能为空';
      }

      for (let i = 0; i < parsed.length; i++) {
        const item: NodeSchema = parsed[i];
        if (!item) {
          return `第 ${i + 1} 项为空`;
        }
        if (!item.id || typeof item.id !== 'string') {
          return `第 ${i + 1} 项缺少有效的 id 字段`;
        }
        if (!item.name || typeof item.name !== 'string') {
          return `第 ${i + 1} 项缺少有效的 name 字段`;
        }
        if (!item.style || typeof item.style !== 'object') {
          return `第 ${i + 1} 项缺少 style 对象`;
        }
        if (!item.style.fillColor || typeof item.style.fillColor !== 'string') {
          return `第 ${i + 1} 项缺少 style.fillColor 字段`;
        }
      }

      return '';
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      return `JSON 解析失败: ${errMsg}`;
    }
  }

  /**
   * 从文件中加载节点 Schema 配置（草稿和已发布分别加载）
   */
  public async loadFromStorage(): Promise<void> {
    if (!this.publishedFile || !this.draftFile) {
      console.warn('[NodeSchemaService] loadFromStorage skipped: file paths not set');
      return;
    }

    try {
      if (!canIUse('SystemCapability.FileManagement.File.FileIO')) {
        console.warn('[NodeSchemaService] File IO not supported, skip loadFromStorage');
        return;
      }

      // 加载已发布版本
      await this.loadFileToMap(this.publishedFile, this.publishedSchemas, 'published');
      
      // 加载草稿版本
      await this.loadFileToMap(this.draftFile, this.draftSchemas, 'draft');

      // 加载历史版本
      await this.loadHistoryFile();

      console.log('[NodeSchemaService] loadFromStorage completed');
    } catch (error) {
      console.error('[NodeSchemaService] loadFromStorage error:', error);
    }
  }

  /**
   * 从文件加载到指定 Map
   */
  private async loadFileToMap(
    filePath: string,
    targetMap: Map<string, NodeSchema>,
    label: string
  ): Promise<void> {
    try {
      if (!fs.accessSync(filePath)) {
        console.log(`[NodeSchemaService] ${label} file not found: ${filePath}`);
        return;
      }
    } catch (error) {
      console.log(`[NodeSchemaService] ${label} file access error`);
      return;
    }

    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(filePath);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      const decoder = new util.TextDecoder();
      const content = decoder.decodeToString(new Uint8Array(buffer));

      if (!content || content.trim().length === 0) {
        console.log(`[NodeSchemaService] ${label} file is empty`);
        return;
      }

      const parsed: NodeSchema[] = JSON.parse(content) as NodeSchema[];
      if (!Array.isArray(parsed)) {
        console.error(`[NodeSchemaService] ${label} file format error: not array`);
        return;
      }

      targetMap.clear();
      parsed.forEach((schema: NodeSchema) => {
        if (schema.version === undefined) {
          schema.version = 1;
        }
        // 数据完整性补全
        if (!schema.fields) schema.fields = [];
        if (!schema.layout) schema.layout = [];
        if (!schema.rules) schema.rules = [];
        if (!schema.ports) schema.ports = [];

        targetMap.set(schema.id, schema);
      });

      console.log(`[NodeSchemaService] loaded ${parsed.length} ${label} schemas`);
    } catch (error) {
      console.error(`[NodeSchemaService] loadFileToMap error for ${label}:`, error);
    }
  }

  /**
   * 将当前节点 Schema 配置保存到文件（草稿和已发布分别保存）
   */
  public async saveToStorage(): Promise<void> {
    if (!this.publishedFile || !this.draftFile) {
      console.warn('[NodeSchemaService] saveToStorage skipped: file paths not set');
      return;
    }

    try {
      if (!canIUse('SystemCapability.FileManagement.File.FileIO')) {
        console.warn('[NodeSchemaService] File IO not supported, skip saveToStorage');
        return;
      }

      // 保存已发布版本
      await this.saveMapToFile(this.publishedSchemas, this.publishedFile, 'published');
      
      // 保存草稿版本
      await this.saveMapToFile(this.draftSchemas, this.draftFile, 'draft');

      // 保存历史版本
      await this.saveHistoryFile();

      console.log('[NodeSchemaService] saveToStorage completed');
    } catch (error) {
      console.error('[NodeSchemaService] saveToStorage error:', error);
    }
  }

  /**
   * 加载历史版本文件 (Map<string, NodeSchema[]>)
   */
  private async loadHistoryFile(): Promise<void> {
    if (!this.historyFile) return;
    try {
      if (!fs.accessSync(this.historyFile)) return;
      
      const file = fs.openSync(this.historyFile, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(this.historyFile);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      const decoder = new util.TextDecoder();
      const content = decoder.decodeToString(new Uint8Array(buffer));
      if (!content || !content.trim()) return;

      const parsed = JSON.parse(content) as object;
      // 历史文件的结构是: Record<string, NodeSchema[]>
      // 或者 Array 形式? 为了方便，我们存为 [ {id: '...', history: [...]}, ... ] 或直接 Map 转 Object
      // 这里采用 Map 转 Array of entries 的方式存储: [ [id, [schemas]], ... ]
      
      if (Array.isArray(parsed)) {
        this.historySchemas.clear();
        const parsedArray = parsed as object[];
        parsedArray.forEach((item: object) => {
          // 兼容两种存储格式
          // 1. [ [id, [schemas]], ... ]
          if (Array.isArray(item) && item.length === 2 && typeof item[0] === 'string' && Array.isArray(item[1])) {
             this.historySchemas.set(item[0] as string, item[1] as NodeSchema[]);
          } 
          // 2. { id: string, history: NodeSchema[] }
          else {
             const record = item as Record<string, Object>;
             if (record['id'] && record['history']) {
               const entry = item as HistoryEntry;
               this.historySchemas.set(entry.id, entry.history);
             }
          }
        });
        console.log(`[NodeSchemaService] loaded history for ${this.historySchemas.size} schemas`);
      }
    } catch (error) {
      console.error('[NodeSchemaService] loadHistoryFile error:', error);
    }
  }

  /**
   * 保存历史版本文件
   */
  private async saveHistoryFile(): Promise<void> {
    if (!this.historyFile) return;
    try {
      // 转换为数组以便存储: [ {id: '...', history: [...]}, ... ]
      const storageArray: HistoryEntry[] = [];
      this.historySchemas.forEach((history, id) => {
        storageArray.push({ id, history });
      });

      const content = JSON.stringify(storageArray, null, 2);
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encodeInto(content);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);

      try {
        if (fs.accessSync(this.historyFile)) {
          fs.unlinkSync(this.historyFile);
        }
      } catch (e) {}

      const file = fs.openSync(this.historyFile, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);
    } catch (error) {
      console.error('[NodeSchemaService] saveHistoryFile error:', error);
    }
  }

  /**
   * 将 Map 保存到文件
   */
  private async saveMapToFile(
    sourceMap: Map<string, NodeSchema>,
    filePath: string,
    label: string
  ): Promise<void> {
    try {
      const list = Array.from(sourceMap.values());
      const content = JSON.stringify(list, null, 2);
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encodeInto(content);
      const buffer = uint8Array.buffer.slice(uint8Array.byteOffset, uint8Array.byteOffset + uint8Array.byteLength);

      // 先删除旧文件，确保完全重写
      try {
        if (fs.accessSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch (error) {
        // 文件不存在，忽略错误
      }

      const file = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);

      console.log(`[NodeSchemaService] saved ${list.length} ${label} schemas`);
    } catch (error) {
      console.error(`[NodeSchemaService] saveMapToFile error for ${label}:`, error);
    }
  }
}
