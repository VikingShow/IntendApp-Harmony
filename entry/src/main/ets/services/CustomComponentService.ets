// File: entry/src/main/ets/services/CustomComponentService.ets

import { fileIo as fs } from '@kit.CoreFileKit';
import util from '@ohos.util';
import { CustomComponentDefinition, CustomComponentMeta, CustomComponentStyle } from '../model/CustomComponentSchema';

interface CustomComponentHistoryEntry {
  id: string;
  history: CustomComponentDefinition[];
}

export class CustomComponentService {
  private static instance: CustomComponentService;

  private baseDir: string | null = null;
  private customComponentsFile: string | null = null;

  private historyFile: string | null = null;

  private history: Map<string, CustomComponentDefinition[]> = new Map();

  private components: Map<string, CustomComponentDefinition> = new Map();

  private constructor() {}

  static getInstance(): CustomComponentService {
    if (!CustomComponentService.instance) {
      CustomComponentService.instance = new CustomComponentService();
    }
    return CustomComponentService.instance;
  }

  public initializeStorage(baseDir: string): void {
    if (!baseDir || baseDir.length === 0) {
      return;
    }
    if (!this.baseDir) {
      this.baseDir = baseDir;
      this.customComponentsFile = `${baseDir}/custom_components.json`;
      this.historyFile = `${baseDir}/custom_components_history.json`;
      this.loadFromStorage();
      console.log(`[CustomComponentService] 初始化存储路径: ${this.customComponentsFile}`);
    }
  }

  public getAll(): CustomComponentDefinition[] {
    return Array.from(this.components.values());
  }

  public getById(id: string): CustomComponentDefinition | null {
    const item = this.components.get(id);
    return item ? item : null;
  }

  public upsert(definition: CustomComponentDefinition): void {
    if (!definition || !definition.id) {
      return;
    }
    const migrated = this.migrateDefinition(definition);
    const current = this.components.get(migrated.id);
    if (current) {
      this.addHistorySnapshot(current);
    }
    this.components.set(migrated.id, migrated);
  }

  public delete(id: string): void {
    if (!id) {
      return;
    }
    const current = this.components.get(id);
    if (current) {
      this.addHistorySnapshot(current);
    }
    this.components.delete(id);
  }

  public exportToJson(): string {
    return JSON.stringify(this.getAll(), null, 2);
  }

  public importFromJson(json: string, mode: 'merge' | 'replace' = 'merge'): boolean {
    if (!json || json.trim().length === 0) {
      return false;
    }
    try {
      const parsed = JSON.parse(json) as CustomComponentDefinition[];
      if (!Array.isArray(parsed)) {
        return false;
      }

      if (mode === 'replace') {
        // 先把现有项写入历史
        this.components.forEach((v) => {
          this.addHistorySnapshot(v);
        });
        this.components.clear();
      }

      for (const def of parsed) {
        if (def && def.id && def.name && def.renderType) {
          const migrated = this.migrateDefinition(def);
          const current = this.components.get(migrated.id);
          if (current) {
            this.addHistorySnapshot(current);
          }
          this.components.set(migrated.id, migrated);
        }
      }
      return true;
    } catch (e) {
      console.error('[CustomComponentService] importFromJson error:', e);
      return false;
    }
  }

  public saveToStorage(): void {
    if (!this.customComponentsFile) {
      console.warn('[CustomComponentService] saveToStorage skipped: storage not initialized');
      return;
    }
    try {
      const jsonStr = this.exportToJson();
      const bytes: Uint8Array = new util.TextEncoder().encodeInto(jsonStr);
      const file = fs.openSync(this.customComponentsFile, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, bytes.buffer);
      fs.closeSync(file);

      this.saveHistoryToStorage();
      console.log('[CustomComponentService] 保存成功');
    } catch (e) {
      console.error('[CustomComponentService] saveToStorage error:', e);
    }
  }

  public loadFromStorage(): void {
    if (!this.customComponentsFile) {
      return;
    }
    try {
      this.loadHistoryFromStorage();
      const file = fs.openSync(this.customComponentsFile, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(this.customComponentsFile);
      const size = Number(stat.size);
      if (size <= 0) {
        fs.closeSync(file);
        return;
      }

      const buf = new ArrayBuffer(size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);

      const content: string = new util.TextDecoder().decodeToString(new Uint8Array(buf));
      if (!content || content.trim().length === 0) {
        return;
      }
      const parsed = JSON.parse(content) as CustomComponentDefinition[];
      if (!Array.isArray(parsed)) {
        return;
      }
      this.components.clear();
      for (const def of parsed) {
        if (def && def.id && def.name && def.renderType) {
          const migrated = this.migrateDefinition(def);
          this.components.set(migrated.id, migrated);
        }
      }
      console.log(`[CustomComponentService] 加载成功: ${this.components.size} 项`);
    } catch (e) {
      console.error('[CustomComponentService] loadFromStorage error:', e);
    }
  }

  public getHistory(id: string): CustomComponentDefinition[] {
    const list = this.history.get(id);
    return list ? list : [];
  }

  public rollbackToVersion(id: string, versionIndexFromLatest: number): boolean {
    const list = this.history.get(id);
    if (!list || list.length === 0) {
      return false;
    }
    const idx = Math.max(0, Math.min(list.length - 1, versionIndexFromLatest));
    const target = list[list.length - 1 - idx];
    if (!target) {
      return false;
    }
    this.upsert(target);
    return true;
  }

  private migrateDefinition(def: CustomComponentDefinition): CustomComponentDefinition {
    const now = Date.now();
    const version = typeof def.version === 'number' ? def.version : 1;
    const meta = def.meta ? def.meta : this.createDefaultMeta(now);
    if (!meta.createdAt) {
      meta.createdAt = now;
    }
    meta.updatedAt = now;

    const migrated: CustomComponentDefinition = {
      id: def.id,
      name: def.name,
      renderType: def.renderType,
      description: def.description,
      version: version,
      meta: meta,
      valueType: def.valueType ? def.valueType : 'text',
      textTemplate: def.textTemplate !== undefined ? def.textTemplate : '{value}',
      layout: def.layout,
      enums: def.enums ? def.enums : [],
      min: def.min !== undefined ? def.min : 0,
      max: def.max !== undefined ? def.max : 100,
      unit: def.unit !== undefined ? def.unit : '',
      style: def.style ? def.style : this.createDefaultStyle(),
      styleRules: def.styleRules ? def.styleRules : [],
      events: def.events ? def.events : []
    };
    return migrated;
  }

  private createDefaultMeta(now: number): CustomComponentMeta {
    return {
      author: undefined,
      createdAt: now,
      updatedAt: now,
      tags: []
    };
  }

  private createDefaultStyle(): CustomComponentStyle {
    return {
      borderRadius: 8,
      paddingX: 8,
      paddingY: 4
    };
  }

  private addHistorySnapshot(def: CustomComponentDefinition): void {
    const id = def.id;
    const list = this.history.get(id) ? (this.history.get(id) as CustomComponentDefinition[]) : [];
    const copied: CustomComponentDefinition = JSON.parse(JSON.stringify(def)) as CustomComponentDefinition;
    list.push(copied);
    // 只保留最近 20 条
    const maxKeep = 20;
    while (list.length > maxKeep) {
      list.shift();
    }
    this.history.set(id, list);
  }

  private saveHistoryToStorage(): void {
    if (!this.historyFile) {
      return;
    }
    try {
      const entries: CustomComponentHistoryEntry[] = [];
      this.history.forEach((value, key) => {
        entries.push({ id: key, history: value });
      });
      const jsonStr = JSON.stringify(entries, null, 2);
      const bytes: Uint8Array = new util.TextEncoder().encodeInto(jsonStr);
      const file = fs.openSync(this.historyFile, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, bytes.buffer);
      fs.closeSync(file);
    } catch (e) {
      console.error('[CustomComponentService] saveHistoryToStorage error:', e);
    }
  }

  private loadHistoryFromStorage(): void {
    if (!this.historyFile) {
      return;
    }
    try {
      const file = fs.openSync(this.historyFile, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(this.historyFile);
      const size = Number(stat.size);
      if (size <= 0) {
        fs.closeSync(file);
        return;
      }
      const buf = new ArrayBuffer(size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);

      const content: string = new util.TextDecoder().decodeToString(new Uint8Array(buf));
      if (!content || content.trim().length === 0) {
        return;
      }
      const parsed = JSON.parse(content) as CustomComponentHistoryEntry[];
      if (!Array.isArray(parsed)) {
        return;
      }
      this.history.clear();
      for (const entry of parsed) {
        if (entry && entry.id && Array.isArray(entry.history)) {
          this.history.set(entry.id, entry.history);
        }
      }
    } catch (e) {
      // 历史文件不存在/格式错误都不应该影响主流程
      console.warn('[CustomComponentService] loadHistoryFromStorage skipped:', e);
    }
  }
}
