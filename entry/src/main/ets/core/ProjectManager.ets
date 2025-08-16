// File: entry/src/main/ets/core/ProjectManager.ets

import { Project, TaskNode, ChecklistItem, Dependency } from '../model/ProjectData';
import { StorageService } from '../services/StorageService';
import { CriticalPathService, TaskWithDuration } from '../services/CriticalPathService';
import { TemplateService } from '../services/TemplateService';
import { EventBus, Events } from './EventBus';
import promptAction from '@ohos.promptAction';

export interface ProjectState {
  project: Project | null;
  selectedTask: TaskNode | null;
  isLoading: boolean;
  error: string | null;
}

export interface ProjectActions {
  loadProject: (projectId: string) => Promise<void>;
  createNewProject: (name?: string) => Promise<void>;
  createFromTemplate: (templateId: string, projectName: string) => Promise<void>;
  saveProject: () => Promise<void>;
  updateProjectName: (name: string) => void;
  addTask: () => void;
  updateTask: (taskId: string, updates: Partial<TaskNode>) => void;
  deleteTask: (taskId: string) => void;
  selectTask: (task: TaskNode | null) => void;
  updateChecklist: (taskId: string, checklist: ChecklistItem[]) => void;
  addChecklistItem: (taskId: string, item: ChecklistItem) => void;
  addDependency: (fromId: string, toId: string) => void;
  removeDependency: (fromId: string, toId: string) => void;
  calculateCriticalPath: () => void;
  moveTask: (taskId: string, x: number, y: number) => void;
}

export class ProjectManager {
  private static instance: ProjectManager;
  private storageService: StorageService | null = null;
  private cpmService: CriticalPathService = new CriticalPathService();
  private templateService: TemplateService = TemplateService.getInstance();
  private eventBus: EventBus = EventBus.getInstance();
  private autoSaveTimer: number | null = null;

  private state: ProjectState = {
    project: null,
    selectedTask: null,
    isLoading: false,
    error: null
  };

  private constructor() {}

  public static getInstance(): ProjectManager {
    if (!ProjectManager.instance) {
      ProjectManager.instance = new ProjectManager();
    }
    return ProjectManager.instance;
  }

  public initialize(storageService: StorageService): void {
    this.storageService = storageService;
  }

  // 获取当前状态
  public getState(): ProjectState {
    return this.state;
  }

  // 获取所有操作方法
  public getActions(): ProjectActions {
    return {
      loadProject: (projectId: string) => this.loadProject(projectId),
      createNewProject: (name?: string) => this.createNewProject(name),
      createFromTemplate: (templateId: string, projectName: string) => this.createFromTemplate(templateId, projectName),
      saveProject: () => this.saveProject(),
      updateProjectName: (name: string) => this.updateProjectName(name),
      addTask: () => this.addTask(),
      updateTask: (taskId: string, updates: Partial<TaskNode>) => this.updateTask(taskId, updates),
      deleteTask: (taskId: string) => this.deleteTask(taskId),
      selectTask: (task: TaskNode | null) => this.selectTask(task),
      updateChecklist: (taskId: string, checklist: ChecklistItem[]) => this.updateChecklist(taskId, checklist),
      addChecklistItem: (taskId: string, item: ChecklistItem) => this.addChecklistItem(taskId, item),
      addDependency: (fromId: string, toId: string) => this.addDependency(fromId, toId),
      removeDependency: (fromId: string, toId: string) => this.removeDependency(fromId, toId),
      calculateCriticalPath: () => this.calculateCriticalPath(),
      moveTask: (taskId: string, x: number, y: number) => this.moveTask(taskId, x, y)
    };
  }

  // 私有方法实现
  private async loadProject(projectId: string): Promise<void> {
    if (!this.storageService) {
      this.setError('存储服务未初始化');
      return;
    }

    this.setLoading(true);
    this.clearError();

    try {
      const project = await this.storageService.getProject(projectId);
      if (project) {
        this.state.project = project;
        this.state.selectedTask = null;
        this.calculateCriticalPath();
        this.eventBus.emit(Events.PROJECT_LOADED, project);
        promptAction.showToast({ message: `项目 "${project.name}" 已加载` });
      } else {
        this.setError(`项目 ${projectId} 不存在`);
      }
    } catch (error) {
      this.setError(`加载项目失败: ${error}`);
    } finally {
      this.setLoading(false);
    }
  }

  private async createNewProject(name: string = '新项目'): Promise<void> {
    const newProject = new Project(undefined, name);
    this.state.project = newProject;
    this.state.selectedTask = null;
    this.eventBus.emit(Events.PROJECT_LOADED, newProject);
    
    if (this.storageService) {
      await this.saveProject();
    }
  }

  private async createFromTemplate(templateId: string, projectName: string): Promise<void> {
    const newProject = this.templateService.createProjectFromTemplate(templateId, projectName);
    this.state.project = newProject;
    this.state.selectedTask = null;
    this.eventBus.emit(Events.PROJECT_LOADED, newProject);
    
    if (this.storageService) {
      await this.saveProject();
    }
  }

  private async saveProject(): Promise<void> {
    if (!this.state.project) {
      this.setError('没有可保存的项目');
      return;
    }

    if (!this.storageService) {
      this.setError('存储服务未初始化');
      return;
    }

    try {
      this.state.project.lastModified = Date.now();
      await this.storageService.saveProject(this.state.project);
      this.eventBus.emit(Events.PROJECT_SAVED, this.state.project);
      promptAction.showToast({ message: `项目 "${this.state.project.name}" 已保存` });
    } catch (error) {
      this.setError(`保存项目失败: ${error}`);
    }
  }

  private updateProjectName(name: string): void {
    if (this.state.project) {
      this.state.project.name = name;
      this.eventBus.emit(Events.PROJECT_SAVED, this.state.project);
    }
  }

  private addTask(): void {
    if (!this.state.project) return;

    const today = new Date();
    const tomorrow = new Date();
    tomorrow.setDate(today.getDate() + 1);

    const newTask: TaskNode = {
      id: `task_${Date.now()}`,
      name: '新任务',
      startDate: today,
      endDate: tomorrow,
      checklist: [],
      x: 50,
      y: 50
    };

    this.state.project.tasks = this.state.project.tasks.concat([newTask]);
    this.calculateCriticalPath();
    this.eventBus.emit(Events.PROJECT_SAVED, this.state.project);
    promptAction.showToast({ message: '新任务已添加' });
  }

  private updateTask(taskId: string, updates: Partial<TaskNode>): void {
    if (!this.state.project) return;

    const taskIndex = this.state.project.tasks.findIndex(t => t.id === taskId);
    if (taskIndex === -1) return;

    // 更新任务属性
    const originalTask = this.state.project.tasks[taskIndex];
    const updatedTask = this.copyTaskNode(originalTask);
    
    // 手动更新属性
    if (updates.name !== undefined) updatedTask.name = updates.name;
    if (updates.startDate !== undefined) updatedTask.startDate = updates.startDate;
    if (updates.endDate !== undefined) updatedTask.endDate = updates.endDate;
    if (updates.checklist !== undefined) updatedTask.checklist = updates.checklist.slice();
    if (updates.x !== undefined) updatedTask.x = updates.x;
    if (updates.y !== undefined) updatedTask.y = updates.y;
    if (updates.isCritical !== undefined) updatedTask.isCritical = updates.isCritical;
    if (updates.earlyStart !== undefined) updatedTask.earlyStart = updates.earlyStart;
    if (updates.earlyFinish !== undefined) updatedTask.earlyFinish = updates.earlyFinish;
    if (updates.lateStart !== undefined) updatedTask.lateStart = updates.lateStart;
    if (updates.lateFinish !== undefined) updatedTask.lateFinish = updates.lateFinish;
    
    this.state.project.tasks[taskIndex] = updatedTask;

    // 更新selectedTask以保持同步
    if (this.state.selectedTask?.id === taskId) {
      this.state.selectedTask = this.copyTaskNode(updatedTask);
    }

    // 先触发任务更新事件
    this.eventBus.emit(Events.TASK_UPDATED, updatedTask);
    
    // 然后触发项目保存事件
    this.eventBus.emit(Events.PROJECT_SAVED, this.state.project);
    
    // 最后重新计算关键路径
    this.calculateCriticalPath();
    
    // 自动保存到存储
    this.autoSaveProject();
  }

  private deleteTask(taskId: string): void {
    if (!this.state.project) return;

    if (this.state.selectedTask?.id === taskId) {
      this.state.selectedTask = null;
    }

    this.state.project.tasks = this.state.project.tasks.filter(t => t.id !== taskId);
    this.state.project.dependencies = this.state.project.dependencies.filter(
      d => d.fromId !== taskId && d.toId !== taskId
    );

    this.eventBus.emit(Events.TASK_DELETED, taskId);
    this.eventBus.emit(Events.PROJECT_SAVED, this.state.project);
    this.calculateCriticalPath();
  }

  private selectTask(task: TaskNode | null): void {
    this.state.selectedTask = task;
    this.eventBus.emit(Events.TASK_SELECTED, task);
  }

  private updateChecklist(taskId: string, checklist: ChecklistItem[]): void {
    if (!this.state.project) return;

    const updatedTask = this.state.project.tasks.find(t => t.id === taskId);
    if (updatedTask) {
      updatedTask.checklist = checklist.slice();
      
      if (this.state.selectedTask?.id === taskId) {
        this.state.selectedTask = this.copyTaskNode(updatedTask);
      }
      
      // 触发事件和自动保存
      this.eventBus.emit(Events.TASK_UPDATED, updatedTask);
      this.eventBus.emit(Events.PROJECT_SAVED, this.state.project);
      this.autoSaveProject();
    }
  }

  private addChecklistItem(taskId: string, item: ChecklistItem): void {
    if (!this.state.project) return;

    const task = this.state.project.tasks.find(t => t.id === taskId);
    if (task) {
      task.checklist = task.checklist.concat([item]);
      
      if (this.state.selectedTask?.id === taskId) {
        this.state.selectedTask = this.copyTaskNode(task);
      }
      
      // 触发事件和自动保存
      this.eventBus.emit(Events.TASK_UPDATED, task);
      this.eventBus.emit(Events.PROJECT_SAVED, this.state.project);
      this.autoSaveProject();
    }
  }

  private addDependency(fromId: string, toId: string): void {
    if (!this.state.project) return;

    const exists = this.state.project.dependencies.some(
      d => d.fromId === fromId && d.toId === toId
    );

    if (!exists) {
      const newDependency: Dependency = {
        fromId: fromId,
        toId: toId
      };
      this.state.project.dependencies = this.state.project.dependencies.concat([newDependency]);
      this.calculateCriticalPath();
      promptAction.showToast({ message: '依赖已创建' });
    } else {
      promptAction.showToast({ message: '该依赖已存在' });
    }
  }

  private removeDependency(fromId: string, toId: string): void {
    if (!this.state.project) return;

    this.state.project.dependencies = this.state.project.dependencies.filter(
      d => !(d.fromId === fromId && d.toId === toId)
    );
    this.calculateCriticalPath();
  }

  private calculateCriticalPath(): void {
    if (!this.state.project) return;

    const tasksWithDuration: TaskWithDuration[] = this.state.project.tasks.map(
      (t: TaskNode): TaskWithDuration => ({
        id: t.id,
        duration: this.getDuration(t),
        isCritical: t.isCritical,
        earlyStart: t.earlyStart,
        earlyFinish: t.earlyFinish,
        lateStart: t.lateStart,
        lateFinish: t.lateFinish
      })
    );

    this.cpmService.calculate(tasksWithDuration, this.state.project.dependencies);

    // 更新任务的关键路径信息
    tasksWithDuration.forEach(calculatedTask => {
      const originalTask = this.state.project!.tasks.find(t => t.id === calculatedTask.id);
      if (originalTask) {
        originalTask.isCritical = calculatedTask.isCritical;
        originalTask.earlyStart = calculatedTask.earlyStart;
        originalTask.earlyFinish = calculatedTask.earlyFinish;
        originalTask.lateStart = calculatedTask.lateStart;
        originalTask.lateFinish = calculatedTask.lateFinish;
      }
    });

    this.eventBus.emit(Events.CRITICAL_PATH_CALCULATED, this.state.project);
  }

  private moveTask(taskId: string, x: number, y: number): void {
    if (!this.state.project) return;

    const task = this.state.project.tasks.find(t => t.id === taskId);
    if (task) {
      task.x = x;
      task.y = y;
      
      if (this.state.selectedTask?.id === taskId) {
        this.state.selectedTask = this.copyTaskNode(task);
      }
    }
  }

  // 辅助方法：复制TaskNode对象
  private copyTaskNode(task: TaskNode): TaskNode {
    return {
      id: task.id,
      name: task.name,
      startDate: task.startDate,
      endDate: task.endDate,
      checklist: task.checklist.slice(),
      x: task.x,
      y: task.y,
      isCritical: task.isCritical,
      earlyStart: task.earlyStart,
      earlyFinish: task.earlyFinish,
      lateStart: task.lateStart,
      lateFinish: task.lateFinish
    };
  }

  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  // 自动保存项目到存储（带防抖）
  private autoSaveProject(): void {
    // 清除之前的定时器
    if (this.autoSaveTimer !== null) {
      clearTimeout(this.autoSaveTimer);
    }
    
    // 设置新的定时器，延迟500ms后保存
    this.autoSaveTimer = setTimeout(async () => {
      if (this.state.project && this.storageService) {
        try {
          await this.storageService.saveProject(this.state.project);
          console.log('[ProjectManager] 项目已自动保存');
        } catch (error) {
          console.error('[ProjectManager] 自动保存失败:', error);
          this.setError('自动保存失败');
        }
      }
      this.autoSaveTimer = null;
    }, 500);
  }

  private setLoading(loading: boolean): void {
    this.state.isLoading = loading;
  }

  private setError(error: string): void {
    this.state.error = error;
  }

  private clearError(): void {
    this.state.error = null;
  }
}
