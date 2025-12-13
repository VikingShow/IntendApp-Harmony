// File: entry/src/main/ets/services/CustomComponentService.ets

import { fileIo as fs } from '@kit.CoreFileKit';
import util from '@ohos.util';
import { CustomComponentDefinition } from '../model/CustomComponentSchema';

export class CustomComponentService {
  private static instance: CustomComponentService;

  private baseDir: string | null = null;
  private customComponentsFile: string | null = null;

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
    this.components.set(definition.id, definition);
  }

  public delete(id: string): void {
    if (!id) {
      return;
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
        this.components.clear();
      }

      for (const def of parsed) {
        if (def && def.id && def.name && def.renderType) {
          this.components.set(def.id, def);
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
          this.components.set(def.id, def);
        }
      }
      console.log(`[CustomComponentService] 加载成功: ${this.components.size} 项`);
    } catch (e) {
      console.error('[CustomComponentService] loadFromStorage error:', e);
    }
  }
}
