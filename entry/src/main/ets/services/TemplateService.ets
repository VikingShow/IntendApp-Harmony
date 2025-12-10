// File: entry/src/main/ets/services/TemplateService.ets
/**
 * 项目模板服务模块
 * 
 * 本模块提供项目模板管理功能，支持预定义的项目模板和自定义模板创建。
 * 模板系统允许用户快速创建具有标准结构和任务流程的项目，提高项目管理效率。
 * 
 * 主要功能：
 * 1. 模板管理：维护预定义的项目模板库
 * 2. 模板分类：按项目类型对模板进行分类管理
 * 3. 项目创建：基于模板快速创建新项目
 * 4. 模板扩展：支持添加新的项目模板
 * 5. 模板搜索：提供模板检索和筛选功能
 * 
 * 模板类型：
 * - 开发模板：移动应用开发、网站开发等
 * - 设计模板：UI/UX设计、平面设计等
 * - 营销模板：营销活动、推广计划等
 * - 研究模板：市场调研、产品研究等
 * - 其他模板：通用项目管理模板
 * 
 * 模板结构：
 * - 基本信息：ID、名称、描述、分类
 * - 任务定义：预定义的任务列表和检查清单
 * - 依赖关系：任务之间的逻辑依赖关系
 * - 布局信息：任务在画布上的初始位置
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode } from '../model/ProjectData';

/**
 * 检查清单项接口
 * 定义任务检查清单中的单个项目
 */
export interface ChecklistItem {
  /** 检查项唯一标识符 */
  id: string;
  /** 检查项文本描述 */
  text: string;
  /** 是否已完成 */
  isCompleted: boolean;
}

/**
 * 依赖关系接口
 * 定义任务之间的逻辑依赖关系
 */
export interface Dependency {
  /** 源任务ID */
  fromId: string;
  /** 目标任务ID */
  toId: string;
}

/**
 * 项目模板接口
 * 定义完整的项目模板结构
 */
export interface ProjectTemplate {
  /** 模板唯一标识符 */
  id: string;
  /** 模板名称 */
  name: string;
  /** 模板描述 */
  description: string;
  /** 模板分类 */
  category: string;
  /** 模板任务列表 */
  tasks: TaskTemplate[];
  /** 模板依赖关系列表 */
  dependencies: DependencyTemplate[];
}

/**
 * 任务模板接口
 * 定义模板中的单个任务结构
 */
export interface TaskTemplate {
  /** 任务名称 */
  name: string;
  /** 开始日期 */
  startDate: Date;
  /** 结束日期 */
  endDate: Date;
  /** 检查清单列表 */
  checklist: ChecklistItemTemplate[];
  /** 画布X坐标 */
  x: number;
  /** 画布Y坐标 */
  y: number;
}

/**
 * 检查清单项模板接口
 * 定义模板中检查清单项的结构
 */
export interface ChecklistItemTemplate {
  /** 检查项ID */
  id: string;
  /** 检查项文本 */
  text: string;
  /** 是否已完成 */
  isCompleted: boolean;
}

/**
 * 依赖关系模板接口
 * 定义模板中依赖关系的结构
 */
export interface DependencyTemplate {
  /** 源任务ID */
  fromId: string;
  /** 目标任务ID */
  toId: string;
}

/**
 * 项目模板服务类
 * 
 * 实现项目模板的管理和创建功能，采用单例模式设计。
 * 负责维护预定义模板库、提供模板检索服务、基于模板创建项目等功能。
 * 
 * 核心功能：
 * 1. 模板库管理：维护内置和自定义的项目模板
 * 2. 模板检索：按分类、关键词等条件检索模板
 * 3. 项目创建：基于模板快速创建新项目
 * 4. 模板扩展：支持动态添加新的项目模板
 * 5. 数据转换：处理模板数据与项目数据之间的转换
 * 
 * 设计特点：
 * - 使用Map结构存储模板，提高检索效率
 * - 支持模板分类和标签管理
 * - 提供模板预览和详细信息查看
 * - 支持模板的导入导出功能
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
export class TemplateService {
  /** 单例实例 */
  private static instance: TemplateService;
  /** 模板存储Map，key为模板ID，value为模板对象 */
  private templates: Map<string, ProjectTemplate> = new Map();

  /**
   * 获取单例实例
   * 如果实例不存在则创建并初始化模板库
   * 
   * @returns TemplateService 模板服务实例
   * @public
   */
  static getInstance(): TemplateService {
    if (!TemplateService.instance) {
      TemplateService.instance = new TemplateService();
      TemplateService.instance.initializeTemplates();
    }
    return TemplateService.instance;
  }

  private initializeTemplates() {
    // 空白项目模板
    const blankTemplate: ProjectTemplate = {
      id: 'blank',
      name: '空白项目',
      description: '不包含任何任务的空白项目',
      category: 'other',
      tasks: [],
      dependencies: []
    };
    this.templates.set(blankTemplate.id, blankTemplate);
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

    // 后端API开发模板
    const backendApiTemplate: ProjectTemplate = {
      id: 'backend_api',
      name: '后端API开发',
      description: 'RESTful API后端服务开发完整流程',
      category: 'development',
      tasks: [
        { name: 'API设计与规划', startDate: new Date(), endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: 'API需求分析', isCompleted: false },
            { id: 'c1_2', text: '数据模型设计', isCompleted: false },
            { id: 'c1_3', text: 'API端点规划', isCompleted: false },
            { id: 'c1_4', text: '认证方案设计', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '数据库设计', startDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: 'ER图设计', isCompleted: false },
            { id: 'c2_2', text: '表结构设计', isCompleted: false },
            { id: 'c2_3', text: '索引优化', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '核心功能开发', startDate: new Date(Date.now() + 13 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '用户认证模块', isCompleted: false },
            { id: 'c3_2', text: 'CRUD接口实现', isCompleted: false },
            { id: 'c3_3', text: '业务逻辑层', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '安全与性能', startDate: new Date(Date.now() + 31 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 40 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: 'JWT认证实现', isCompleted: false },
            { id: 'c4_2', text: '权限控制', isCompleted: false },
            { id: 'c4_3', text: '接口限流', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '部署上线', startDate: new Date(Date.now() + 41 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: 'Docker容器化', isCompleted: false },
            { id: 'c5_2', text: 'CI/CD配置', isCompleted: false },
            { id: 'c5_3', text: '生产环境部署', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 微信小程序开发模板
    const miniProgramTemplate: ProjectTemplate = {
      id: 'mini_program',
      name: '微信小程序开发',
      description: '微信小程序从设计到上线的完整开发流程',
      category: 'development',
      tasks: [
        { name: '需求与设计', startDate: new Date(), endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '功能需求梳理', isCompleted: false },
            { id: 'c1_2', text: '页面流程设计', isCompleted: false },
            { id: 'c1_3', text: 'UI设计稿', isCompleted: false },
            { id: 'c1_4', text: '小程序注册', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '前端开发', startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '项目初始化', isCompleted: false },
            { id: 'c2_2', text: '页面开发', isCompleted: false },
            { id: 'c2_3', text: '组件封装', isCompleted: false },
            { id: 'c2_4', text: '微信API对接', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '后端对接', startDate: new Date(Date.now() + 26 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '接口联调', isCompleted: false },
            { id: 'c3_2', text: '数据缓存', isCompleted: false },
            { id: 'c3_3', text: '用户登录', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '测试优化', startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '功能测试', isCompleted: false },
            { id: 'c4_2', text: '兼容性测试', isCompleted: false },
            { id: 'c4_3', text: '性能优化', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '提审上线', startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '小程序信息完善', isCompleted: false },
            { id: 'c5_2', text: '提交审核', isCompleted: false },
            { id: 'c5_3', text: '审核通过发布', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // UI/UX设计项目模板
    const uiuxDesignTemplate: ProjectTemplate = {
      id: 'uiux_design',
      name: 'UI/UX设计项目',
      description: '产品界面与用户体验设计完整流程',
      category: 'design',
      tasks: [
        { name: '用户研究', startDate: new Date(), endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '用户访谈', isCompleted: false },
            { id: 'c1_2', text: '用户画像建立', isCompleted: false },
            { id: 'c1_3', text: '痛点分析', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '交互设计', startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '信息架构', isCompleted: false },
            { id: 'c2_2', text: '用户流程图', isCompleted: false },
            { id: 'c2_3', text: '低保真原型', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '视觉设计', startDate: new Date(Date.now() + 19 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 32 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '风格探索', isCompleted: false },
            { id: 'c3_2', text: '色彩系统', isCompleted: false },
            { id: 'c3_3', text: '图标设计', isCompleted: false },
            { id: 'c3_4', text: '界面设计', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '原型制作', startDate: new Date(Date.now() + 33 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 40 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '高保真原型', isCompleted: false },
            { id: 'c4_2', text: '交互动效', isCompleted: false },
            { id: 'c4_3', text: '原型测试', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '设计交付', startDate: new Date(Date.now() + 41 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '设计标注', isCompleted: false },
            { id: 'c5_2', text: '切图输出', isCompleted: false },
            { id: 'c5_3', text: '设计文档', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 内容营销模板
    const contentMarketingTemplate: ProjectTemplate = {
      id: 'content_marketing',
      name: '内容营销计划',
      description: '系统化的内容营销策划与执行',
      category: 'marketing',
      tasks: [
        { name: '内容策略', startDate: new Date(), endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '受众分析', isCompleted: false },
            { id: 'c1_2', text: '内容定位', isCompleted: false },
            { id: 'c1_3', text: '主题规划', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '内容创作', startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '文章撰写', isCompleted: false },
            { id: 'c2_2', text: '视频制作', isCompleted: false },
            { id: 'c2_3', text: '图文设计', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '内容发布', startDate: new Date(Date.now() + 29 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '发布计划制定', isCompleted: false },
            { id: 'c3_2', text: '多平台发布', isCompleted: false },
            { id: 'c3_3', text: 'SEO优化', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '用户互动', startDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 63 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '评论管理', isCompleted: false },
            { id: 'c4_2', text: '用户反馈收集', isCompleted: false },
            { id: 'c4_3', text: '社群运营', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '效果分析', startDate: new Date(Date.now() + 64 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 70 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '数据统计', isCompleted: false },
            { id: 'c5_2', text: '转化分析', isCompleted: false },
            { id: 'c5_3', text: '优化方案', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 市场调研模板
    const marketResearchTemplate: ProjectTemplate = {
      id: 'market_research',
      name: '市场调研项目',
      description: '系统化的市场调研与分析流程',
      category: 'research',
      tasks: [
        { name: '调研规划', startDate: new Date(), endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '调研目标确定', isCompleted: false },
            { id: 'c1_2', text: '调研方法选择', isCompleted: false },
            { id: 'c1_3', text: '问卷设计', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '数据收集', startDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '问卷发放', isCompleted: false },
            { id: 'c2_2', text: '用户访谈', isCompleted: false },
            { id: 'c2_3', text: '数据录入', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '数据分析', startDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '描述性统计', isCompleted: false },
            { id: 'c3_2', text: '相关性分析', isCompleted: false },
            { id: 'c3_3', text: '数据可视化', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '洞察提炼', startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '关键发现总结', isCompleted: false },
            { id: 'c4_2', text: '用户画像构建', isCompleted: false },
            { id: 'c4_3', text: '市场机会识别', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '报告撰写', startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '报告框架搭建', isCompleted: false },
            { id: 'c5_2', text: '内容撰写', isCompleted: false },
            { id: 'c5_3', text: '建议输出', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 视频制作模板
    const videoProductionTemplate: ProjectTemplate = {
      id: 'video_production',
      name: '视频内容制作',
      description: '短视频或宣传片的完整制作流程',
      category: 'content',
      tasks: [
        { name: '前期策划', startDate: new Date(), endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '创意构思', isCompleted: false },
            { id: 'c1_2', text: '脚本撰写', isCompleted: false },
            { id: 'c1_3', text: '分镜头设计', isCompleted: false },
            { id: 'c1_4', text: '拍摄计划', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '拍摄准备', startDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '场地勘景', isCompleted: false },
            { id: 'c2_2', text: '演员选角', isCompleted: false },
            { id: 'c2_3', text: '设备准备', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '拍摄执行', startDate: new Date(Date.now() + 11 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '现场拍摄', isCompleted: false },
            { id: 'c3_2', text: '素材整理', isCompleted: false },
            { id: 'c3_3', text: '补拍镜头', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '后期制作', startDate: new Date(Date.now() + 19 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 32 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '剪辑', isCompleted: false },
            { id: 'c4_2', text: '调色', isCompleted: false },
            { id: 'c4_3', text: '配音配乐', isCompleted: false },
            { id: 'c4_4', text: '特效制作', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '发布推广', startDate: new Date(Date.now() + 33 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '视频导出', isCompleted: false },
            { id: 'c5_2', text: '平台发布', isCompleted: false },
            { id: 'c5_3', text: '推广投放', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 线下活动策划模板
    const offlineEventTemplate: ProjectTemplate = {
      id: 'offline_event',
      name: '线下活动策划',
      description: '会议、展览、发布会等线下活动组织',
      category: 'event',
      tasks: [
        { name: '活动策划', startDate: new Date(), endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '活动主题确定', isCompleted: false },
            { id: 'c1_2', text: '目标受众分析', isCompleted: false },
            { id: 'c1_3', text: '活动流程设计', isCompleted: false },
            { id: 'c1_4', text: '预算规划', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '场地筹备', startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '场地选择', isCompleted: false },
            { id: 'c2_2', text: '场地布置方案', isCompleted: false },
            { id: 'c2_3', text: '设备租赁', isCompleted: false },
            { id: 'c2_4', text: '物料制作', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '嘉宾邀请', startDate: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '嘉宾名单确定', isCompleted: false },
            { id: 'c3_2', text: '邀请函发送', isCompleted: false },
            { id: 'c3_3', text: '报名统计', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '活动执行', startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '现场布置', isCompleted: false },
            { id: 'c4_2', text: '签到接待', isCompleted: false },
            { id: 'c4_3', text: '活动主持', isCompleted: false },
            { id: 'c4_4', text: '现场拍摄', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '活动复盘', startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '数据统计', isCompleted: false },
            { id: 'c5_2', text: '效果评估', isCompleted: false },
            { id: 'c5_3', text: '总结报告', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 产品发布会模板
    const productLaunchTemplate: ProjectTemplate = {
      id: 'product_launch',
      name: '产品发布会',
      description: '新产品上市发布会的完整策划与执行',
      category: 'event',
      tasks: [
        { name: '发布策略', startDate: new Date(), endDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '产品卖点提炼', isCompleted: false },
            { id: 'c1_2', text: '发布主题确定', isCompleted: false },
            { id: 'c1_3', text: '传播策略制定', isCompleted: false },
            { id: 'c1_4', text: '媒体名单', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '内容准备', startDate: new Date(Date.now() + 11 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '演讲稿撰写', isCompleted: false },
            { id: 'c2_2', text: 'PPT设计', isCompleted: false },
            { id: 'c2_3', text: '宣传视频制作', isCompleted: false },
            { id: 'c2_4', text: '新闻稿撰写', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '场地布置', startDate: new Date(Date.now() + 26 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '舞台搭建', isCompleted: false },
            { id: 'c3_2', text: '灯光音响', isCompleted: false },
            { id: 'c3_3', text: '产品展示区', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '发布会执行', startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '彩排演练', isCompleted: false },
            { id: 'c4_2', text: '媒体接待', isCompleted: false },
            { id: 'c4_3', text: '发布会举行', isCompleted: false },
            { id: 'c4_4', text: '直播推流', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '后续传播', startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 56 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '新闻稿发布', isCompleted: false },
            { id: 'c5_2', text: '社交媒体推广', isCompleted: false },
            { id: 'c5_3', text: '媒体报道跟踪', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 在线课程开发模板
    const onlineCourseTemplate: ProjectTemplate = {
      id: 'online_course',
      name: '在线课程开发',
      description: '在线教育课程的设计与制作',
      category: 'content',
      tasks: [
        { name: '课程设计', startDate: new Date(), endDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '学习目标确定', isCompleted: false },
            { id: 'c1_2', text: '课程大纲编写', isCompleted: false },
            { id: 'c1_3', text: '知识点拆解', isCompleted: false },
            { id: 'c1_4', text: '教学方法设计', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '内容制作', startDate: new Date(Date.now() + 11 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '课件制作', isCompleted: false },
            { id: 'c2_2', text: '视频录制', isCompleted: false },
            { id: 'c2_3', text: '习题设计', isCompleted: false },
            { id: 'c2_4', text: '案例准备', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '后期制作', startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: '视频剪辑', isCompleted: false },
            { id: 'c3_2', text: '字幕添加', isCompleted: false },
            { id: 'c3_3', text: '特效制作', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '平台上线', startDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 56 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '课程上传', isCompleted: false },
            { id: 'c4_2', text: '课程页面设计', isCompleted: false },
            { id: 'c4_3', text: '测试验收', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '运营推广', startDate: new Date(Date.now() + 57 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 70 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '宣传文案', isCompleted: false },
            { id: 'c5_2', text: '推广投放', isCompleted: false },
            { id: 'c5_3', text: '学员服务', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 电商店铺运营模板
    const ecommerceTemplate: ProjectTemplate = {
      id: 'ecommerce_operation',
      name: '电商店铺运营',
      description: '电商平台店铺的运营与推广',
      category: 'marketing',
      tasks: [
        { name: '店铺搭建', startDate: new Date(), endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c1_1', text: '店铺注册', isCompleted: false },
            { id: 'c1_2', text: '店铺装修', isCompleted: false },
            { id: 'c1_3', text: '商品上架', isCompleted: false },
            { id: 'c1_4', text: '物流配置', isCompleted: false }
          ], x: 50, y: 100 },
        { name: '产品运营', startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c2_1', text: '商品详情页优化', isCompleted: false },
            { id: 'c2_2', text: '产品拍摄', isCompleted: false },
            { id: 'c2_3', text: '价格策略', isCompleted: false }
          ], x: 300, y: 100 },
        { name: '流量获取', startDate: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c3_1', text: 'SEO优化', isCompleted: false },
            { id: 'c3_2', text: '直通车推广', isCompleted: false },
            { id: 'c3_3', text: '活动报名', isCompleted: false },
            { id: 'c3_4', text: '达人合作', isCompleted: false }
          ], x: 550, y: 100 },
        { name: '客户服务', startDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 70 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c4_1', text: '客服培训', isCompleted: false },
            { id: 'c4_2', text: '售后处理', isCompleted: false },
            { id: 'c4_3', text: '评价管理', isCompleted: false }
          ], x: 800, y: 100 },
        { name: '数据分析', startDate: new Date(Date.now() + 71 * 24 * 60 * 60 * 1000), endDate: new Date(Date.now() + 77 * 24 * 60 * 60 * 1000),
          checklist: [
            { id: 'c5_1', text: '销售数据分析', isCompleted: false },
            { id: 'c5_2', text: '用户行为分析', isCompleted: false },
            { id: 'c5_3', text: '优化策略制定', isCompleted: false }
          ], x: 1050, y: 100 }
      ],
      dependencies: [
        { fromId: 'task_1', toId: 'task_2' },
        { fromId: 'task_2', toId: 'task_3' },
        { fromId: 'task_3', toId: 'task_4' },
        { fromId: 'task_4', toId: 'task_5' }
      ]
    };

    // 注册所有新模板
    this.templates.set(backendApiTemplate.id, backendApiTemplate);
    this.templates.set(miniProgramTemplate.id, miniProgramTemplate);
    this.templates.set(uiuxDesignTemplate.id, uiuxDesignTemplate);
    this.templates.set(contentMarketingTemplate.id, contentMarketingTemplate);
    this.templates.set(marketResearchTemplate.id, marketResearchTemplate);
    this.templates.set(videoProductionTemplate.id, videoProductionTemplate);
    this.templates.set(offlineEventTemplate.id, offlineEventTemplate);
    this.templates.set(productLaunchTemplate.id, productLaunchTemplate);
    this.templates.set(onlineCourseTemplate.id, onlineCourseTemplate);
    this.templates.set(ecommerceTemplate.id, ecommerceTemplate);
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
    project.category = template.category; // 设置项目分类
    
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