import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export interface TutorialStep {
  id: string;
  targetId?: string;
  title: string;
  description: string;
  position: 'top' | 'bottom' | 'left' | 'right' | 'center';
  highlightPadding?: number;
  showSkip?: boolean;
}

export enum TutorialPage {
  HOME = 'home',
  INDEX = 'index'
}

export class TutorialService {
  private static instance: TutorialService;
  private preferencesStore: preferences.Preferences | null = null;
  private context: common.UIAbilityContext | null = null;
  
  private readonly PREF_NAME = 'tutorial_preferences';
  private readonly KEY_TUTORIAL_COMPLETED = 'tutorial_completed';
  private readonly KEY_NEVER_SHOW = 'never_show_tutorial';
  private readonly KEY_HOME_COMPLETED = 'home_tutorial_completed';
  private readonly KEY_INDEX_COMPLETED = 'index_tutorial_completed';

  private constructor() {}

  static getInstance(): TutorialService {
    if (!TutorialService.instance) {
      TutorialService.instance = new TutorialService();
    }
    return TutorialService.instance;
  }

  async initialize(context: common.UIAbilityContext) {
    this.context = context;
    try {
      this.preferencesStore = await preferences.getPreferences(context, this.PREF_NAME);
      console.log('[TutorialService] Initialized successfully');
    } catch (error) {
      console.error('[TutorialService] Failed to initialize preferences:', error);
    }
  }

  async shouldShowTutorial(page: TutorialPage): Promise<boolean> {
    if (!this.preferencesStore) {
      console.warn('[TutorialService] Preferences not initialized');
      return true;
    }

    try {
      const neverShow = await this.preferencesStore.get(this.KEY_NEVER_SHOW, false) as boolean;
      if (neverShow) {
        return false;
      }

      if (page === TutorialPage.HOME) {
        return !(await this.preferencesStore.get(this.KEY_HOME_COMPLETED, false) as boolean);
      } else if (page === TutorialPage.INDEX) {
        return !(await this.preferencesStore.get(this.KEY_INDEX_COMPLETED, false) as boolean);
      }
      
      return true;
    } catch (error) {
      console.error('[TutorialService] Failed to check tutorial status:', error);
      return true;
    }
  }

  async markTutorialCompleted(page: TutorialPage) {
    if (!this.preferencesStore) {
      console.warn('[TutorialService] Preferences not initialized');
      return;
    }

    try {
      if (page === TutorialPage.HOME) {
        await this.preferencesStore.put(this.KEY_HOME_COMPLETED, true);
      } else if (page === TutorialPage.INDEX) {
        await this.preferencesStore.put(this.KEY_INDEX_COMPLETED, true);
      }
      await this.preferencesStore.flush();
      console.log(`[TutorialService] Tutorial completed for ${page}`);
    } catch (error) {
      console.error('[TutorialService] Failed to mark tutorial completed:', error);
    }
  }

  async setNeverShowAgain(value: boolean) {
    if (!this.preferencesStore) {
      console.warn('[TutorialService] Preferences not initialized');
      return;
    }

    try {
      await this.preferencesStore.put(this.KEY_NEVER_SHOW, value);
      await this.preferencesStore.flush();
      console.log(`[TutorialService] Never show again: ${value}`);
    } catch (error) {
      console.error('[TutorialService] Failed to set never show again:', error);
    }
  }

  async resetTutorial() {
    if (!this.preferencesStore) {
      console.warn('[TutorialService] Preferences not initialized');
      return;
    }

    try {
      await this.preferencesStore.put(this.KEY_NEVER_SHOW, false);
      await this.preferencesStore.put(this.KEY_HOME_COMPLETED, false);
      await this.preferencesStore.put(this.KEY_INDEX_COMPLETED, false);
      await this.preferencesStore.put(this.KEY_TUTORIAL_COMPLETED, false);
      await this.preferencesStore.flush();
      console.log('[TutorialService] Tutorial reset successfully');
    } catch (error) {
      console.error('[TutorialService] Failed to reset tutorial:', error);
    }
  }

  getHomeSteps(): TutorialStep[] {
    return [
      {
        id: 'welcome',
        title: '欢迎使用 EasyFlow',
        description: 'EasyFlow 是一款项目管理和思维导图工具，帮助您轻松规划和管理项目。让我们快速了解主要功能。',
        position: 'center',
        showSkip: true
      },
      {
        id: 'create_project',
        targetId: 'create_project_button',
        title: '创建项目',
        description: '点击这里创建新项目。您可以选择创建空白项目、使用模板，或通过 AI 生成项目。',
        position: 'bottom',
        highlightPadding: 8
      },
      {
        id: 'project_list',
        targetId: 'project_list',
        title: '项目列表',
        description: '这里显示您的所有项目。点击项目卡片可以查看详情，长按可以进行更多操作。',
        position: 'right',
        highlightPadding: 12
      },
      {
        id: 'project_card',
        targetId: 'first_project_card',
        title: '项目操作',
        description: '每个项目卡片上都有操作按钮，可以编辑、重命名、删除项目。点击卡片进入项目编辑页面。',
        position: 'right',
        highlightPadding: 8
      },
      {
        id: 'import_export',
        title: '导入导出',
        description: '在创建项目菜单中，您还可以导入已有的项目文件，或在项目详情中导出项目数据。',
        position: 'center'
      }
    ];
  }

  getIndexSteps(): TutorialStep[] {
    return [
      {
        id: 'canvas_intro',
        title: '项目编辑页面',
        description: '这是项目的可视化编辑界面。左侧是操作面板，右侧是项目画布，可以直观地展示任务关系。',
        position: 'center',
        showSkip: true
      },
      {
        id: 'sidebar_toggle',
        targetId: 'sidebar_toggle',
        title: '侧边栏开关',
        description: '点击这里可以展开或收起左侧操作面板，获得更大的画布空间。',
        position: 'right',
        highlightPadding: 8
      },
      {
        id: 'add_task',
        targetId: 'add_task_button',
        title: '添加任务',
        description: '点击这里添加新任务。每个任务可以设置名称、开始时间、结束时间、优先级等信息。',
        position: 'right',
        highlightPadding: 8
      },
      {
        id: 'task_list',
        targetId: 'task_list',
        title: '任务列表',
        description: '这里显示项目中的所有任务。点击任务可以编辑详情，拖动任务可以调整画布位置。',
        position: 'right',
        highlightPadding: 12
      },
      {
        id: 'canvas_operations',
        targetId: 'canvas_container',
        title: '画布操作',
        description: '在画布上可以拖动任务节点调整位置，点击两个任务可以创建依赖关系。支持缩放和平移画布。',
        position: 'left',
        highlightPadding: 16
      },
      {
        id: 'toolbar',
        targetId: 'canvas_toolbar',
        title: '工具栏',
        description: '这里提供画布控制功能：锁定画布、重置视图、撤销重做、导出项目等。',
        position: 'bottom',
        highlightPadding: 8
      },
      {
        id: 'task_detail',
        title: '任务详情',
        description: '选中任务后，可以在侧边栏编辑任务的详细信息，包括检查清单、备注、依赖关系等。',
        position: 'center'
      },
      {
        id: 'critical_path',
        title: '关键路径',
        description: '系统会自动计算并高亮显示项目的关键路径，帮助您了解哪些任务会影响项目进度。',
        position: 'center'
      }
    ];
  }
}
