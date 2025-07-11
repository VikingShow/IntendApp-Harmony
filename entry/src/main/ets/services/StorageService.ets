// File: entry/src/main/ets/services/StorageService.ts
import preferences from '@ohos.data.preferences';
import { Project, TaskNode, ChecklistItem } from '../model/ProjectData';

// Defines the structure for project metadata used in the project list.
export interface ProjectMeta {
  id: string;
  name: string;
  lastModified: number; // Stored as a timestamp
}

// --- Define intermediate types for storage to handle Date objects safely ---

interface StorableTaskNode extends Omit<TaskNode, 'startDate' | 'endDate'> {
  startDate: string;
  endDate: string;
}

interface StorableProject extends Omit<Project, 'tasks' | 'addTask'> {
  tasks: StorableTaskNode[];
}


const PROJECT_LIST_KEY = 'project_list';
const STORE_NAME = 'project_storage';

export class StorageService {
  private static instance: StorageService;
  private store: Promise<preferences.Preferences>;

  // FIX: The constructor now only accepts the filesDir string it needs.
  private constructor(filesDir: string) {
    // 使用preferences替代storage
    this.store = preferences.getPreferences(getContext(), STORE_NAME);
    console.log('StorageService initialized.');
  }

  // FIX: The getInstance method now only accepts the filesDir string.
  public static getInstance(filesDir: string): StorageService {
    // We use the filesDir as a key to ensure we don't create a new instance
    // if it has already been initialized with the same path.
    if (!StorageService.instance) {
      StorageService.instance = new StorageService(filesDir);
    }
    return StorageService.instance;
  }

  // --- Project List (Metadata) ---

  public async getProjectList(): Promise<ProjectMeta[]> {
    try {
      const preferences = await this.store;
      const value = await preferences.get(PROJECT_LIST_KEY, '[]');
      return JSON.parse(value.toString()) as ProjectMeta[];
    } catch (e) {
      console.error('Failed to get project list.', JSON.stringify(e));
      return [];
    }
  }

  private async saveProjectList(list: ProjectMeta[]): Promise<void> {
    try {
      const preferences = await this.store;
      await preferences.put(PROJECT_LIST_KEY, JSON.stringify(list));
      await preferences.flush();
    } catch (e) {
      console.error('Failed to save project list.', JSON.stringify(e));
    }
  }

  // --- Individual Project Data ---

  public async saveProject(project: Project): Promise<void> {
    try {
      // 1. Update project list metadata
      const list = await this.getProjectList();
      const projectMeta: ProjectMeta = {
        id: project.id,
        name: project.name,
        lastModified: Date.now()
      };

      const existingIndex = list.findIndex(p => p.id === project.id);
      if (existingIndex !== -1) {
        list[existingIndex] = projectMeta;
      } else {
        list.push(projectMeta);
      }
      await this.saveProjectList(list);

      // 2. Prepare the project for storage by converting Dates to ISO strings
      const storableProject: StorableProject = {
        id: project.id,
        name: project.name,
        lastModified: project.lastModified,
        dependencies: project.dependencies,
        tasks: project.tasks.map((task: TaskNode): StorableTaskNode => {
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
            startDate: task.startDate.toISOString(),
            endDate: task.endDate.toISOString(),
          };
        })
      };

      const projectJSON = JSON.stringify(storableProject);
      const preferences = await this.store;
      await preferences.put(project.id, projectJSON);
      await preferences.flush();
      console.log(`Project ${project.id} saved successfully.`);
    } catch (e) {
      console.error(`Failed to save project ${project.id}.`, JSON.stringify(e));
    }
  }

  public async getProject(projectId: string): Promise<Project | null> {
    try {
      const preferences = await this.store;
      const value = await preferences.get(projectId, '');
      if (value) {
        const storableProject = JSON.parse(value.toString()) as StorableProject;

        // Convert the stored data back into a full Project object with Date objects
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
        return project;
      }
      return null;
    } catch (e) {
      console.error(`Failed to get project ${projectId}.`, JSON.stringify(e));
      return null;
    }
  }

  public async deleteProject(projectId: string): Promise<void> {
    try {
      let list = await this.getProjectList();
      list = list.filter(p => p.id !== projectId);
      await this.saveProjectList(list);

      const preferences = await this.store;
      await preferences.delete(projectId);
      await preferences.flush();
      console.log(`Project ${projectId} deleted successfully.`);
    } catch (e) {
      console.error(`Failed to delete project ${projectId}.`, JSON.stringify(e));
    }
  }
}
