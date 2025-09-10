// File: entry/src/main/ets/services/TemplateManager.ets

import { 
  NodeTemplate, 
  ComponentConfig, 
  LayoutConfig,
  TemplateCategory,
  ComponentDefinition
} from '../model/ComponentSystem';
import { ComponentRegistry } from './ComponentRegistry';

/**
 * 验证结果接口
 */
interface ValidationResult {
  valid: boolean;
  errors: string[];
}

/**
 * 模板管理器
 * 管理节点模板的创建、保存、加载和分类
 */
export class TemplateManager {
  private static instance: TemplateManager;
  private templates: Map<string, NodeTemplate> = new Map();
  private categories: Map<string, TemplateCategory> = new Map();
  private componentRegistry: ComponentRegistry;

  private constructor() {
    this.componentRegistry = ComponentRegistry.getInstance();
    this.initializeDefaultTemplates();
  }

  public static getInstance(): TemplateManager {
    if (!TemplateManager.instance) {
      TemplateManager.instance = new TemplateManager();
    }
    return TemplateManager.instance;
  }

  /**
   * 创建新模板
   */
  public createTemplate(
    name: string, 
    description: string, 
    category: string, 
    icon: string,
    components: ComponentConfig[],
    layout: LayoutConfig
  ): NodeTemplate {
    const template: NodeTemplate = {
      id: this.generateTemplateId(),
      name,
      description,
      category,
      icon,
      components,
      layout,
      createdAt: Date.now(),
      updatedAt: Date.now()
    };

    this.templates.set(template.id, template);
    this.addTemplateToCategory(template);
    
    console.log(`[TemplateManager] 创建模板: ${template.name} (${template.id})`);
    return template;
  }

  /**
   * 获取模板
   */
  public getTemplate(templateId: string): NodeTemplate | undefined {
    return this.templates.get(templateId);
  }

  /**
   * 获取所有模板
   */
  public getAllTemplates(): NodeTemplate[] {
    return Array.from(this.templates.values());
  }

  /**
   * 根据分类获取模板
   */
  public getTemplatesByCategory(category: string): NodeTemplate[] {
    const categoryData = this.categories.get(category);
    return categoryData ? categoryData.templates : [];
  }

  /**
   * 获取所有分类
   */
  public getAllCategories(): TemplateCategory[] {
    return Array.from(this.categories.values());
  }

  /**
   * 更新模板
   */
  public updateTemplate(templateId: string, updates: Partial<NodeTemplate>): boolean {
    const template = this.templates.get(templateId);
    if (!template) {
      console.error(`[TemplateManager] 模板不存在: ${templateId}`);
      return false;
    }

    const updatedTemplate: NodeTemplate = {
      id: template.id,
      name: updates.name || template.name,
      description: updates.description || template.description,
      category: updates.category || template.category,
      icon: updates.icon || template.icon,
      components: updates.components || template.components,
      layout: updates.layout || template.layout,
      createdAt: template.createdAt,
      updatedAt: Date.now()
    };

    this.templates.set(templateId, updatedTemplate);
    console.log(`[TemplateManager] 更新模板: ${updatedTemplate.name} (${templateId})`);
    return true;
  }

  /**
   * 删除模板
   */
  public deleteTemplate(templateId: string): boolean {
    const template = this.templates.get(templateId);
    if (!template) {
      console.error(`[TemplateManager] 模板不存在: ${templateId}`);
      return false;
    }

    this.templates.delete(templateId);
    this.removeTemplateFromCategory(template);
    
    console.log(`[TemplateManager] 删除模板: ${template.name} (${templateId})`);
    return true;
  }

  /**
   * 复制模板
   */
  public cloneTemplate(templateId: string, newName: string): NodeTemplate | null {
    const originalTemplate = this.templates.get(templateId);
    if (!originalTemplate) {
      console.error(`[TemplateManager] 模板不存在: ${templateId}`);
      return null;
    }

    // 深拷贝组件配置
    const clonedComponents: ComponentConfig[] = originalTemplate.components.map(comp => {
      const clonedComp: ComponentConfig = {
        id: this.generateComponentId(),
        componentId: comp.componentId,
        properties: comp.properties,
        style: comp.style,
        position: comp.position,
        visible: comp.visible
      };
      return clonedComp;
    });

    const clonedTemplate = this.createTemplate(
      newName,
      `${originalTemplate.description} (副本)`,
      originalTemplate.category,
      originalTemplate.icon,
      clonedComponents,
      originalTemplate.layout
    );

    console.log(`[TemplateManager] 复制模板: ${originalTemplate.name} -> ${newName}`);
    return clonedTemplate;
  }

  /**
   * 验证模板
   */
  public validateTemplate(template: NodeTemplate): ValidationResult {
    const errors: string[] = [];

    // 验证基本信息
    if (!template.name || template.name.trim().length === 0) {
      errors.push('模板名称不能为空');
    }

    if (!template.description || template.description.trim().length === 0) {
      errors.push('模板描述不能为空');
    }

    if (!template.category || template.category.trim().length === 0) {
      errors.push('模板分类不能为空');
    }

    // 验证组件配置
    if (!template.components || template.components.length === 0) {
      errors.push('模板必须包含至少一个组件');
    }

    for (const component of template.components) {
      const componentDef = this.componentRegistry.getComponent(component.componentId);
      if (!componentDef) {
        errors.push(`组件不存在: ${component.componentId}`);
      }
    }

    // 验证布局配置
    if (!template.layout) {
      errors.push('布局配置不能为空');
    } else {
      if (template.layout.columns < 1 || template.layout.columns > 12) {
        errors.push('列数必须在1-12之间');
      }
      if (template.layout.rows < 1 || template.layout.rows > 20) {
        errors.push('行数必须在1-20之间');
      }
    }

    const result: ValidationResult = {
      valid: errors.length === 0,
      errors: errors
    };
    return result;
  }

  /**
   * 初始化默认模板
   */
  private initializeDefaultTemplates(): void {
    this.createDefaultCategories();
    this.createDefaultTemplates();
  }

  /**
   * 创建默认分类
   */
  private createDefaultCategories(): void {
    const basicCategory: TemplateCategory = {
      id: 'basic',
      name: '基础模板',
      icon: '📋',
      description: '基础的任务管理模板',
      templates: []
    };

    const studyCategory: TemplateCategory = {
      id: 'study',
      name: '学习规划',
      icon: '📚',
      description: '学习相关的任务模板',
      templates: []
    };

    const travelCategory: TemplateCategory = {
      id: 'travel',
      name: '旅游攻略',
      icon: '✈️',
      description: '旅游规划相关的模板',
      templates: []
    };

    const workCategory: TemplateCategory = {
      id: 'work',
      name: '工作管理',
      icon: '💼',
      description: '工作项目相关的模板',
      templates: []
    };

    const lifeCategory: TemplateCategory = {
      id: 'life',
      name: '生活管理',
      icon: '🏠',
      description: '日常生活相关的模板',
      templates: []
    };

    this.categories.set('basic', basicCategory);
    this.categories.set('study', studyCategory);
    this.categories.set('travel', travelCategory);
    this.categories.set('work', workCategory);
    this.categories.set('life', lifeCategory);
  }

  /**
   * 创建默认模板
   */
  private createDefaultTemplates(): void {
    // 基础任务模板
    this.createBasicTaskTemplate();
    
    // 学习计划模板
    this.createStudyPlanTemplate();
    
    // 旅游攻略模板
    this.createTravelPlanTemplate();
    
    // 工作项目模板
    this.createWorkProjectTemplate();
    
    // 生活管理模板
    this.createLifeManagementTemplate();
  }

  /**
   * 创建基础任务模板
   */
  private createBasicTaskTemplate(): void {
    const components: ComponentConfig[] = [
      {
        id: this.generateComponentId(),
        componentId: 'text_component',
        properties: { text: '任务名称', maxLength: 50 },
        style: { fontSize: 18, fontColor: '#333333', fontWeight: 'bold' },
        position: { row: 0, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'time_component',
        properties: { 
          showStartTime: true, 
          showEndTime: true, 
          showDuration: true,
          timeFormat: 'YYYY-MM-DD HH:mm'
        },
        style: { fontSize: 14, fontColor: '#666666' },
        position: { row: 1, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'progress_component',
        properties: { 
          showPercentage: true, 
          showText: true,
          progressText: '完成进度'
        },
        style: { progressColor: '#007DFF', backgroundColor: '#F0F0F0', height: 8 },
        position: { row: 2, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'status_component',
        properties: { 
          statusType: 'progress',
          showIcon: true,
          showText: true
        },
        style: { fontSize: 14 },
        position: { row: 3, column: 0, span: 1 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'tag_component',
        properties: { 
          tags: '重要,紧急',
          maxTags: 3
        },
        style: { tagColor: '#007DFF', textColor: '#FFFFFF', fontSize: 12 },
        position: { row: 3, column: 1, span: 1 },
        visible: true
      }
    ];

    const layout: LayoutConfig = {
      columns: 2,
      rows: 4,
      gap: 8,
      padding: 12
    };

    this.createTemplate(
      '基础任务',
      '包含任务名称、时间、进度、状态和标签的基础模板',
      'basic',
      '📋',
      components,
      layout
    );
  }

  /**
   * 创建学习计划模板
   */
  private createStudyPlanTemplate(): void {
    const components: ComponentConfig[] = [
      {
        id: this.generateComponentId(),
        componentId: 'text_component',
        properties: { text: '课程名称', maxLength: 50 },
        style: { fontSize: 18, fontColor: '#333333', fontWeight: 'bold' },
        position: { row: 0, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'time_component',
        properties: { 
          showStartTime: true, 
          showEndTime: true, 
          showDuration: true,
          timeFormat: 'YYYY-MM-DD HH:mm'
        },
        style: { fontSize: 14, fontColor: '#666666' },
        position: { row: 1, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'progress_component',
        properties: { 
          showPercentage: true, 
          showText: true,
          progressText: '学习进度'
        },
        style: { progressColor: '#10B981', backgroundColor: '#F0F0F0', height: 8 },
        position: { row: 2, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'tag_component',
        properties: { 
          tags: '必修,选修,考试',
          maxTags: 3
        },
        style: { tagColor: '#10B981', textColor: '#FFFFFF', fontSize: 12 },
        position: { row: 3, column: 0, span: 2 },
        visible: true
      }
    ];

    const layout: LayoutConfig = {
      columns: 2,
      rows: 4,
      gap: 8,
      padding: 12
    };

    this.createTemplate(
      '学习计划',
      '适用于课程学习、考试复习等学习场景',
      'study',
      '📚',
      components,
      layout
    );
  }

  /**
   * 创建旅游攻略模板
   */
  private createTravelPlanTemplate(): void {
    const components: ComponentConfig[] = [
      {
        id: this.generateComponentId(),
        componentId: 'text_component',
        properties: { text: '目的地', maxLength: 50 },
        style: { fontSize: 18, fontColor: '#333333', fontWeight: 'bold' },
        position: { row: 0, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'time_component',
        properties: { 
          showStartTime: true, 
          showEndTime: true, 
          showDuration: true,
          timeFormat: 'YYYY-MM-DD'
        },
        style: { fontSize: 14, fontColor: '#666666' },
        position: { row: 1, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'tag_component',
        properties: { 
          tags: '国内,国外,自由行,跟团',
          maxTags: 4
        },
        style: { tagColor: '#F59E0B', textColor: '#FFFFFF', fontSize: 12 },
        position: { row: 2, column: 0, span: 2 },
        visible: true
      }
    ];

    const layout: LayoutConfig = {
      columns: 2,
      rows: 3,
      gap: 8,
      padding: 12
    };

    this.createTemplate(
      '旅游攻略',
      '适用于旅游规划、行程安排等场景',
      'travel',
      '✈️',
      components,
      layout
    );
  }

  /**
   * 创建工作项目模板
   */
  private createWorkProjectTemplate(): void {
    const components: ComponentConfig[] = [
      {
        id: this.generateComponentId(),
        componentId: 'text_component',
        properties: { text: '项目名称', maxLength: 50 },
        style: { fontSize: 18, fontColor: '#333333', fontWeight: 'bold' },
        position: { row: 0, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'time_component',
        properties: { 
          showStartTime: true, 
          showEndTime: true, 
          showDuration: true,
          timeFormat: 'YYYY-MM-DD'
        },
        style: { fontSize: 14, fontColor: '#666666' },
        position: { row: 1, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'progress_component',
        properties: { 
          showPercentage: true, 
          showText: true,
          progressText: '项目进度'
        },
        style: { progressColor: '#8B5CF6', backgroundColor: '#F0F0F0', height: 8 },
        position: { row: 2, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'status_component',
        properties: { 
          statusType: 'progress',
          showIcon: true,
          showText: true
        },
        style: { fontSize: 14 },
        position: { row: 3, column: 0, span: 1 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'tag_component',
        properties: { 
          tags: '高优先级,紧急,重要',
          maxTags: 3
        },
        style: { tagColor: '#8B5CF6', textColor: '#FFFFFF', fontSize: 12 },
        position: { row: 3, column: 1, span: 1 },
        visible: true
      }
    ];

    const layout: LayoutConfig = {
      columns: 2,
      rows: 4,
      gap: 8,
      padding: 12
    };

    this.createTemplate(
      '工作项目',
      '适用于工作项目管理、任务跟踪等场景',
      'work',
      '💼',
      components,
      layout
    );
  }

  /**
   * 创建生活管理模板
   */
  private createLifeManagementTemplate(): void {
    const components: ComponentConfig[] = [
      {
        id: this.generateComponentId(),
        componentId: 'text_component',
        properties: { text: '生活事项', maxLength: 50 },
        style: { fontSize: 18, fontColor: '#333333', fontWeight: 'bold' },
        position: { row: 0, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'time_component',
        properties: { 
          showStartTime: true, 
          showEndTime: false, 
          showDuration: true,
          timeFormat: 'YYYY-MM-DD HH:mm'
        },
        style: { fontSize: 14, fontColor: '#666666' },
        position: { row: 1, column: 0, span: 2 },
        visible: true
      },
      {
        id: this.generateComponentId(),
        componentId: 'tag_component',
        properties: { 
          tags: '日常,重要,提醒',
          maxTags: 3
        },
        style: { tagColor: '#EC4899', textColor: '#FFFFFF', fontSize: 12 },
        position: { row: 2, column: 0, span: 2 },
        visible: true
      }
    ];

    const layout: LayoutConfig = {
      columns: 2,
      rows: 3,
      gap: 8,
      padding: 12
    };

    this.createTemplate(
      '生活管理',
      '适用于日常生活管理、习惯养成等场景',
      'life',
      '🏠',
      components,
      layout
    );
  }

  /**
   * 添加模板到分类
   */
  private addTemplateToCategory(template: NodeTemplate): void {
    const category = this.categories.get(template.category);
    if (category) {
      category.templates.push(template);
    }
  }

  /**
   * 从分类中移除模板
   */
  private removeTemplateFromCategory(template: NodeTemplate): void {
    const category = this.categories.get(template.category);
    if (category) {
      const index = category.templates.findIndex(t => t.id === template.id);
      if (index !== -1) {
        category.templates.splice(index, 1);
      }
    }
  }

  /**
   * 生成模板ID
   */
  private generateTemplateId(): string {
    return `template_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 生成组件ID
   */
  private generateComponentId(): string {
    return `comp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}