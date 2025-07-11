// File: entry/src/main/ets/services/TemplateService.ets

import { Project, TaskNode } from '../model/ProjectData';

// 类型声明
export interface ChecklistItem {
  id: string;
  text: string;
  isCompleted: boolean;
}

export interface Dependency {
  fromId: string;
  toId: string;
}

export interface ProjectTemplate {
  id: string;
  name: string;
  description: string;
  category: string;
  tasks: TaskTemplate[];
  dependencies: DependencyTemplate[];
}

export interface TaskTemplate {
  name: string;
  startDate: Date;
  endDate: Date;
  checklist: ChecklistItemTemplate[];
  x: number;
  y: number;
}

export interface ChecklistItemTemplate {
  id: string;
  text: string;
  isCompleted: boolean;
}

export interface DependencyTemplate {
  fromId: string;
  toId: string;
}

export class TemplateService {
  private static instance: TemplateService;
  private templates: Map<string, ProjectTemplate> = new Map();

  static getInstance(): TemplateService {
    if (!TemplateService.instance) {
      TemplateService.instance = new TemplateService();
      TemplateService.instance.initializeTemplates();
    }
    return TemplateService.instance;
  }

  private initializeTemplates() {
    // 移动应用开发模板
    const mobileAppTemplate: ProjectTemplate = {
      id: 'mobile_app',
      name: '移动应用开发',
      description: '完整的移动应用开发流程，从需求分析到发布上线',
      category: 'development',
      tasks: [
        {
          name: '需求分析与用户调研',
          startDate: new Date(),
          endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '用户访谈', isCompleted: false },
            { id: 'c1_2', text: '竞品分析', isCompleted: false },
            { id: 'c1_3', text: '功能需求文档', isCompleted: false },
            { id: 'c1_4', text: '用户故事编写', isCompleted: false }
          ],
          x: 50, y: 100
        },
        {
          name: 'UI/UX设计',
          startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '信息架构设计', isCompleted: false },
            { id: 'c2_2', text: '线框图设计', isCompleted: false },
            { id: 'c2_3', text: '视觉设计', isCompleted: false },
            { id: 'c2_4', text: '交互原型制作', isCompleted: false }
          ],
          x: 300, y: 100
        },
        {
          name: '前端开发',
          startDate: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '项目架构搭建', isCompleted: false },
            { id: 'c3_2', text: '核心功能开发', isCompleted: false },
            { id: 'c3_3', text: 'UI组件开发', isCompleted: false },
            { id: 'c3_4', text: '页面集成', isCompleted: false }
          ],
          x: 550, y: 100
        },
        {
          name: '后端开发',
          startDate: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '数据库设计', isCompleted: false },
            { id: 'c4_2', text: 'API接口开发', isCompleted: false },
            { id: 'c4_3', text: '业务逻辑实现', isCompleted: false },
            { id: 'c4_4', text: '数据验证', isCompleted: false }
          ],
          x: 550, y: 250
        },
        {
          name: '测试与优化',
          startDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 63 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '单元测试', isCompleted: false },
            { id: 'c5_2', text: '集成测试', isCompleted: false },
            { id: 'c5_3', text: '用户测试', isCompleted: false },
            { id: 'c5_4', text: '性能优化', isCompleted: false }
          ],
          x: 800, y: 100
        },
        {
          name: '发布上线',
          startDate: new Date(Date.now() + 64 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 70 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c6_1', text: '应用商店审核', isCompleted: false },
            { id: 'c6_2', text: '生产环境部署', isCompleted: false },
            { id: 'c6_3', text: '监控系统配置', isCompleted: false },
            { id: 'c6_4', text: '用户反馈收集', isCompleted: false }
          ],
          x: 800, y: 250
        }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_2', toId: 'task_4' },
        { fromId: 'task_3', toId: 'task_5' },
        { fromId: 'task_4', toId: 'task_5' },
        { fromId: 'task_5', toId: 'task_6' }
      ]
    };

    // 网站设计模板
    const websiteTemplate: ProjectTemplate = {
      id: 'website_design',
      name: '网站设计项目',
      description: '企业网站或电商网站的设计与开发流程',
      category: 'design',
      tasks: [
        {
          name: '需求收集与分析',
          startDate: new Date(),
          endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '客户需求访谈', isCompleted: false },
            { id: 'c1_2', text: '目标用户分析', isCompleted: false },
            { id: 'c1_3', text: '功能需求整理', isCompleted: false }
          ],
          x: 50, y: 100
        },
        {
          name: '信息架构设计',
          startDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '网站结构规划', isCompleted: false },
            { id: 'c2_2', text: '导航设计', isCompleted: false },
            { id: 'c2_3', text: '内容组织', isCompleted: false }
          ],
          x: 250, y: 100
        },
        {
          name: '视觉设计',
          startDate: new Date(Date.now() + 13 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '品牌色彩定义', isCompleted: false },
            { id: 'c3_2', text: '页面布局设计', isCompleted: false },
            { id: 'c3_3', text: '视觉元素设计', isCompleted: false }
          ],
          x: 450, y: 100
        },
        {
          name: '前端开发',
          startDate: new Date(Date.now() + 26 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 40 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: 'HTML结构搭建', isCompleted: false },
            { id: 'c4_2', text: 'CSS样式实现', isCompleted: false },
            { id: 'c4_3', text: 'JavaScript交互', isCompleted: false }
          ],
          x: 650, y: 100
        },
        {
          name: '测试与发布',
          startDate: new Date(Date.now() + 41 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '跨浏览器测试', isCompleted: false },
            { id: 'c5_2', text: '响应式测试', isCompleted: false },
            { id: 'c5_3', text: '性能优化', isCompleted: false },
            { id: 'c5_4', text: '上线部署', isCompleted: false }
          ],
          x: 850, y: 100
        }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 营销活动模板
    const marketingTemplate: ProjectTemplate = {
      id: 'marketing_campaign',
      name: '营销活动策划',
      description: '完整的营销活动策划与执行流程',
      category: 'marketing',
      tasks: [
        {
          name: '市场调研',
          startDate: new Date(),
          endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '目标受众分析', isCompleted: false },
            { id: 'c1_2', text: '竞品分析', isCompleted: false },
            { id: 'c1_3', text: '市场趋势研究', isCompleted: false }
          ],
          x: 50, y: 100
        },
        {
          name: '策略制定',
          startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '营销目标设定', isCompleted: false },
            { id: 'c2_2', text: '传播策略设计', isCompleted: false },
            { id: 'c2_3', text: '预算规划', isCompleted: false }
          ],
          x: 250, y: 100
        },
        {
          name: '创意设计',
          startDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '创意概念开发', isCompleted: false },
            { id: 'c3_2', text: '视觉设计制作', isCompleted: false },
            { id: 'c3_3', text: '文案撰写', isCompleted: false }
          ],
          x: 450, y: 100
        },
        {
          name: '渠道投放',
          startDate: new Date(Date.now() + 26 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 40 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '媒体渠道选择', isCompleted: false },
            { id: 'c4_2', text: '投放计划执行', isCompleted: false },
            { id: 'c4_3', text: '实时监控调整', isCompleted: false }
          ],
          x: 650, y: 100
        },
        {
          name: '效果评估',
          startDate: new Date(Date.now() + 41 * 24 * 60 * 60 * 1000),
          endDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '数据收集分析', isCompleted: false },
            { id: 'c5_2', text: 'ROI计算', isCompleted: false },
            { id: 'c5_3', text: '效果报告撰写', isCompleted: false }
          ],
          x: 850, y: 100
        }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    this.templates.set(mobileAppTemplate.id, mobileAppTemplate);
    this.templates.set(websiteTemplate.id, websiteTemplate);
    this.templates.set(marketingTemplate.id, marketingTemplate);
  }

  /**
   * 获取所有模板
   */
  getAllTemplates(): ProjectTemplate[] {
    return Array.from(this.templates.values());
  }

  /**
   * 根据分类获取模板
   */
  getTemplatesByCategory(category: string): ProjectTemplate[] {
    return Array.from(this.templates.values()).filter(template => template.category === category);
  }

  /**
   * 根据ID获取模板
   */
  getTemplateById(id: string): ProjectTemplate | undefined {
    return this.templates.get(id);
  }

  /**
   * 从模板创建项目
   */
  createProjectFromTemplate(templateId: string, projectName: string): Project {
    const template = this.getTemplateById(templateId);
    if (!template) {
      throw new Error('模板不存在');
    }

    const project = new Project(undefined, projectName);
    
    // 复制任务并生成新的ID
    const taskIdMap = new Map<string, string>();
    project.tasks = template.tasks.map((task, index) => {
      const newTaskId = `task_${index + 1}`;
      taskIdMap.set(`task_${index + 1}`, newTaskId);
      
      const newTask: TaskNode = {
        id: newTaskId,
        name: task.name,
        startDate: task.startDate,
        endDate: task.endDate,
        checklist: task.checklist.map((item, itemIndex): ChecklistItem => {
          return {
            id: `c${index + 1}_${itemIndex + 1}`,
            text: item.text,
            isCompleted: item.isCompleted
          } as ChecklistItem;
        }),
        x: task.x,
        y: task.y
      } as TaskNode;
      
      return newTask;
    });

    // 更新依赖关系中的ID
    project.dependencies = template.dependencies.map((dep): Dependency => {
      return {
        fromId: taskIdMap.get(dep.fromId) || dep.fromId,
        toId: taskIdMap.get(dep.toId) || dep.toId
      } as Dependency;
    });

    return project;
  }
} 