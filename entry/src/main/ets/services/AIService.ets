// File: entry/src/main/ets/services/AIService.ets
/**
 * AI 生成导图 / 项目服务模块
 *
 * 使用兼容 OpenAI Chat Completions 的 HTTP 接口（默认 DeepSeek），
 * 根据用户输入的自然语言描述自动生成 EasyFlow 可用的 Project 结构。
 *
 * 由于不同厂商的 API 细节可能存在差异，本模块只依赖最基础的
 * POST /v1/chat/completions 约定，调用方需要确保 baseUrl 与 model 名称正确。
 */

import http from '@ohos.net.http';
import { Project, TaskNode, Dependency, ChecklistItem } from '../model/ProjectData';

/**
 * AI 服务配置
 */
interface AIConfig {
  apiKey: string;
  baseUrl: string;
  model: string;
}

interface AIProjectTaskSchema {
  id?: string;
  name: string;
  startOffsetDays?: number;
  durationDays?: number;
  checklist?: string[];
  x?: number;
  y?: number;
}

interface AIProjectDependencySchema {
  from: number;
  to: number;
}

/**
 * AI 生成结果接口
 */
interface AIProjectSchema {
  projectName: string;
  tasks: AIProjectTaskSchema[];
  dependencies?: AIProjectDependencySchema[];
}

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface ChatRequestBody {
  model: string;
  messages: ChatMessage[];
  temperature: number;
}

interface ChatMessageContent {
  content?: string;
}

interface ChatChoice {
  message?: ChatMessageContent;
}

interface ChatCompletionResponse {
  choices?: ChatChoice[];
}

export class AIService {
  private static instance: AIService;

  private config: AIConfig = {
    apiKey: '',
    baseUrl: 'https://api.deepseek.com',
    model: 'deepseek-chat'
  };

  private constructor() {}

  public static getInstance(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }

  /**
   * 设置 API Key 与 Base URL
   */
  public setConfig(apiKey: string, baseUrl?: string, model?: string): void {
    this.config.apiKey = apiKey;
    if (baseUrl && baseUrl.trim().length > 0) {
      this.config.baseUrl = baseUrl.trim();
    }
    if (model && model.trim().length > 0) {
      this.config.model = model.trim();
    }
  }

  public hasValidConfig(): boolean {
    return !!this.config.apiKey && this.config.apiKey.trim().length > 0;
  }

  /**
   * 根据用户自然语言描述生成项目结构
   */
  public async generateProjectFromPrompt(prompt: string): Promise<Project | null> {
    if (!this.hasValidConfig()) {
      console.error('[AIService] API key is not set');
      return null;
    }

    try {
      const rawBaseUrl: string = this.config.baseUrl;
      const normalizedBaseUrl: string = rawBaseUrl.endsWith('/')
        ? rawBaseUrl.substring(0, rawBaseUrl.length - 1)
        : rawBaseUrl;
      const url: string = `${normalizedBaseUrl}/v1/chat/completions`;
      const httpRequest = http.createHttp();

      const systemPrompt =
        '你是一名项目管理助手。请根据用户描述，返回严格 JSON，不要包含额外文本。' +
        'JSON 结构为：' +
        '{ "projectName": "字符串", ' +
        '  "tasks": [ { "name": "任务名称", "startOffsetDays": 0, "durationDays": 7, "checklist": ["子任务1","子任务2"] } ],' +
        '  "dependencies": [ { "from": 1, "to": 2 } ] }。' +
        'startOffsetDays 以今天为第 0 天，可以省略；durationDays 至少为 1。';

      const messages: ChatMessage[] = [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: prompt }
      ];

      const bodyObj: ChatRequestBody = {
        model: this.config.model,
        messages: messages,
        temperature: 0.4
      };

      const body: string = JSON.stringify(bodyObj);

      const res = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`
        },
        extraData: body,
        expectDataType: http.HttpDataType.STRING
      });

      httpRequest.destroy();

      const resultText: string = typeof res.result === 'string'
        ? res.result as string
        : JSON.stringify(res.result);

      console.log('[AIService] Raw response:', resultText);

      let content = resultText;

      // 如果是 OpenAI 兼容结构，先解析 choices[0].message.content
      try {
        const parsed: ChatCompletionResponse = JSON.parse(resultText) as ChatCompletionResponse;
        if (parsed && parsed.choices && parsed.choices.length > 0) {
          const msg = parsed.choices[0].message;
          if (msg && typeof msg.content === 'string') {
            content = msg.content;
          }
        }
      } catch (_ignore) {
        // 如果外层不是 JSON，直接当作内容文本
      }

      // 去掉可能的 Markdown 代码块标记
      content = content.trim();
      if (content.startsWith('```')) {
        const firstNewLine = content.indexOf('\n');
        const lastFence = content.lastIndexOf('```');
        if (firstNewLine !== -1 && lastFence !== -1 && lastFence > firstNewLine) {
          content = content.substring(firstNewLine + 1, lastFence).trim();
        }
      }

      const schema = JSON.parse(content) as AIProjectSchema;
      return this.schemaToProject(schema);
    } catch (error) {
      console.error('[AIService] Failed to generate project:', error);
      return null;
    }
  }

  /**
   * 将 AI 返回的 schema 转换为 EasyFlow 的 Project 结构
   */
  private schemaToProject(schema: AIProjectSchema): Project {
    const project = new Project(undefined, schema.projectName || 'AI 生成项目');

    const now = new Date();

    const tasks: TaskNode[] = [];
    schema.tasks.forEach((t, index) => {
      const offset = typeof t.startOffsetDays === 'number' ? t.startOffsetDays : 0;
      const duration = typeof t.durationDays === 'number' && t.durationDays > 0 ? t.durationDays : 7;

      const startDate = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() + offset
      );
      const endDate = new Date(
        startDate.getFullYear(),
        startDate.getMonth(),
        startDate.getDate() + duration - 1
      );

      const checklistItems: ChecklistItem[] = (t.checklist || []).map((text: string, i: number) => {
        const item: ChecklistItem = {
          id: `ai_item_${index}_${i}_${Date.now()}`,
          text: text,
          isCompleted: false
        };
        return item;
      });

      const task: TaskNode = {
        id: t.id || `ai_task_${index}_${Date.now()}`,
        name: t.name || `任务 ${index + 1}`,
        startDate,
        endDate,
        checklist: checklistItems,
        x: typeof t.x === 'number' ? t.x : 100 + index * 250,
        y: typeof t.y === 'number' ? t.y : 120 + (index % 3) * 140
      };

      tasks.push(task);
      project.addTask(task);
    });

    const deps: Dependency[] = [];
    (schema.dependencies || []).forEach((dep: AIProjectDependencySchema) => {
      const fromIndex: number = dep.from - 1;
      const toIndex: number = dep.to - 1;
      if (tasks[fromIndex] && tasks[toIndex]) {
        const dependency: Dependency = {
          fromId: tasks[fromIndex].id,
          toId: tasks[toIndex].id
        };
        deps.push(dependency);
      }
    });
    project.dependencies = deps;

    return project;
  }
}
