// File: entry/src/main/ets/services/SearchService.ets

import { Project, TaskNode } from '../model/ProjectData';
import { StorageService, ProjectMeta } from './StorageService';

export interface SearchResult {
  project: Project;
  meta: ProjectMeta;
  matchedTasks: TaskNode[];
  relevanceScore: number;
}

export interface SearchOptions {
  keyword: string;
  includeCompleted: boolean;
  includeIncomplete: boolean;
  dateRange?: DateRange;
}

export interface DateRange {
  start: Date;
  end: Date;
}

export class SearchService {
  private static instance: SearchService;
  private storageService: StorageService | null = null;

  static getInstance(): SearchService {
    if (!SearchService.instance) {
      SearchService.instance = new SearchService();
    }
    return SearchService.instance;
  }

  setStorageService(storageService: StorageService): void {
    this.storageService = storageService;
  }

  /**
   * 搜索项目
   */
  async searchProjects(options: SearchOptions): Promise<SearchResult[]> {
    if (!this.storageService) {
      throw new Error('存储服务未初始化');
    }

    const projectList = await this.storageService.getProjectList();
    const results: SearchResult[] = [];

    for (const meta of projectList) {
      try {
        const project = await this.storageService.getProject(meta.id);
        if (!project) continue;

        const searchResult = this.searchInProject(project, meta, options);
        if (searchResult) {
          results.push(searchResult);
        }
      } catch (error) {
        console.error(`搜索项目 ${meta.id} 失败:`, error);
      }
    }

    // 按相关性排序
    return results.sort((a, b) => b.relevanceScore - a.relevanceScore);
  }

  /**
   * 在单个项目中搜索
   */
  private searchInProject(
    project: Project, 
    meta: ProjectMeta, 
    options: SearchOptions
  ): SearchResult | null {
    const keyword = options.keyword.toLowerCase();
    const matchedTasks: TaskNode[] = [];
    let relevanceScore = 0;

    // 搜索项目名称
    if (project.name.toLowerCase().includes(keyword)) {
      relevanceScore += 10;
    }

    // 搜索任务
    for (const task of project.tasks) {
      let taskScore = 0;
      let isMatched = false;

      // 搜索任务名称
      if (task.name.toLowerCase().includes(keyword)) {
        taskScore += 5;
        isMatched = true;
      }

      // 搜索检查清单
      for (const item of task.checklist) {
        if (item.text.toLowerCase().includes(keyword)) {
          taskScore += 2;
          isMatched = true;
        }
      }

      // 检查完成状态过滤
      const isCompleted = task.checklist.every(item => item.isCompleted);
      if (isCompleted && !options.includeCompleted) continue;
      if (!isCompleted && !options.includeIncomplete) continue;

      // 检查日期范围
      if (options.dateRange) {
        const taskStart = task.startDate.getTime();
        const taskEnd = task.endDate.getTime();
        const rangeStart = options.dateRange.start.getTime();
        const rangeEnd = options.dateRange.end.getTime();

        if (taskEnd < rangeStart || taskStart > rangeEnd) continue;
      }

      if (isMatched) {
        matchedTasks.push(task);
        relevanceScore += taskScore;
      }
    }

    // 如果没有匹配的任务，但项目名称匹配，仍然返回结果
    if (matchedTasks.length === 0 && relevanceScore === 0) {
      return null;
    }

    const searchResult: SearchResult = {
      project,
      meta,
      matchedTasks,
      relevanceScore
    };

    return searchResult;
  }

  /**
   * 获取热门搜索关键词
   */
  async getPopularKeywords(): Promise<string[]> {
    if (!this.storageService) {
      return [];
    }

    const projectList = await this.storageService.getProjectList();
    const keywordCount = new Map<string, number>();

    for (const meta of projectList) {
      try {
        const project = await this.storageService.getProject(meta.id);
        if (!project) continue;

        // 提取项目名称中的关键词
        const words = project.name.split(/[\s,，。.、]+/);
        for (const word of words) {
          if (word.length >= 2) {
            const count = keywordCount.get(word) || 0;
            keywordCount.set(word, count + 1);
          }
        }

        // 提取任务名称中的关键词
        for (const task of project.tasks) {
          const taskWords = task.name.split(/[\s,，。.、]+/);
          for (const word of taskWords) {
            if (word.length >= 2) {
              const count = keywordCount.get(word) || 0;
              keywordCount.set(word, count + 1);
            }
          }
        }
      } catch (error) {
        console.error(`获取项目 ${meta.id} 关键词失败:`, error);
      }
    }

    // 返回出现次数最多的关键词
    return Array.from(keywordCount.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map((entry) => {
        const keyword = entry[0];
        return keyword;
      });
  }

  /**
   * 获取搜索建议
   */
  async getSearchSuggestions(partialKeyword: string): Promise<string[]> {
    if (!this.storageService || partialKeyword.length < 1) {
      return [];
    }

    const projectList = await this.storageService.getProjectList();
    const suggestions = new Set<string>();

    for (const meta of projectList) {
      try {
        const project = await this.storageService.getProject(meta.id);
        if (!project) continue;

        // 从项目名称中提取建议
        if (project.name.toLowerCase().includes(partialKeyword.toLowerCase())) {
          suggestions.add(project.name);
        }

        // 从任务名称中提取建议
        for (const task of project.tasks) {
          if (task.name.toLowerCase().includes(partialKeyword.toLowerCase())) {
            suggestions.add(task.name);
          }
        }
      } catch (error) {
        console.error(`获取项目 ${meta.id} 搜索建议失败:`, error);
      }
    }

    return Array.from(suggestions).slice(0, 5);
  }
} 