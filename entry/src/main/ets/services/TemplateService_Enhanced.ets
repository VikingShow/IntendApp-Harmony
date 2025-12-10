// Enhanced Template Definitions - Part 1
// This file contains additional template definitions to be integrated into TemplateService

export const enhancedTemplates = [
  // 后端API开发
  {
    id: 'backend_api',
    name: '后端API开发',
    description: 'RESTful API后端服务开发完整流程',
    category: 'development',
    tasks: [
      {
        name: 'API设计与规划',
        startDate: new Date(),
        endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: 'API需求分析', isCompleted: false },
          { id: 'c1_2', text: '数据模型设计', isCompleted: false },
          { id: 'c1_3', text: 'API端点规划', isCompleted: false },
          { id: 'c1_4', text: '认证方案设计', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '数据库设计',
        startDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: 'ER图设计', isCompleted: false },
          { id: 'c2_2', text: '表结构设计', isCompleted: false },
          { id: 'c2_3', text: '索引优化', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '核心功能开发',
        startDate: new Date(Date.now() + 13 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '用户认证模块', isCompleted: false },
          { id: 'c3_2', text: 'CRUD接口实现', isCompleted: false },
          { id: 'c3_3', text: '业务逻辑层', isCompleted: false },
          { id: 'c3_4', text: '数据验证', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '安全与性能',
        startDate: new Date(Date.now() + 31 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 40 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: 'JWT认证实现', isCompleted: false },
          { id: 'c4_2', text: '权限控制', isCompleted: false },
          { id: 'c4_3', text: '接口限流', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '部署上线',
        startDate: new Date(Date.now() + 41 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: 'Docker容器化', isCompleted: false },
          { id: 'c5_2', text: 'CI/CD配置', isCompleted: false },
          { id: 'c5_3', text: '生产环境部署', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 微信小程序开发
  {
    id: 'mini_program',
    name: '微信小程序开发',
    description: '微信小程序从设计到上线的完整开发流程',
    category: 'development',
    tasks: [
      {
        name: '需求与设计',
        startDate: new Date(),
        endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '功能需求梳理', isCompleted: false },
          { id: 'c1_2', text: '页面流程设计', isCompleted: false },
          { id: 'c1_3', text: 'UI设计稿', isCompleted: false },
          { id: 'c1_4', text: '小程序注册', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '前端开发',
        startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '项目初始化', isCompleted: false },
          { id: 'c2_2', text: '页面开发', isCompleted: false },
          { id: 'c2_3', text: '组件封装', isCompleted: false },
          { id: 'c2_4', text: '微信API对接', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '后端对接',
        startDate: new Date(Date.now() + 26 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '接口联调', isCompleted: false },
          { id: 'c3_2', text: '数据缓存', isCompleted: false },
          { id: 'c3_3', text: '用户登录', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '测试优化',
        startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '功能测试', isCompleted: false },
          { id: 'c4_2', text: '兼容性测试', isCompleted: false },
          { id: 'c4_3', text: '性能优化', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '提审上线',
        startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '小程序信息完善', isCompleted: false },
          { id: 'c5_2', text: '提交审核', isCompleted: false },
          { id: 'c5_3', text: '审核通过发布', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // UI/UX设计项目
  {
    id: 'uiux_design',
    name: 'UI/UX设计项目',
    description: '产品界面与用户体验设计完整流程',
    category: 'design',
    tasks: [
      {
        name: '用户研究',
        startDate: new Date(),
        endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '用户访谈', isCompleted: false },
          { id: 'c1_2', text: '用户画像建立', isCompleted: false },
          { id: 'c1_3', text: '痛点分析', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '交互设计',
        startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '信息架构', isCompleted: false },
          { id: 'c2_2', text: '用户流程图', isCompleted: false },
          { id: 'c2_3', text: '低保真原型', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '视觉设计',
        startDate: new Date(Date.now() + 19 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 32 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '风格探索', isCompleted: false },
          { id: 'c3_2', text: '色彩系统', isCompleted: false },
          { id: 'c3_3', text: '图标设计', isCompleted: false },
          { id: 'c3_4', text: '界面设计', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '原型制作',
        startDate: new Date(Date.now() + 33 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 40 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '高保真原型', isCompleted: false },
          { id: 'c4_2', text: '交互动效', isCompleted: false },
          { id: 'c4_3', text: '原型测试', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '设计交付',
        startDate: new Date(Date.now() + 41 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '设计标注', isCompleted: false },
          { id: 'c5_2', text: '切图输出', isCompleted: false },
          { id: 'c5_3', text: '设计文档', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 内容营销
  {
    id: 'content_marketing',
    name: '内容营销计划',
    description: '系统化的内容营销策划与执行',
    category: 'marketing',
    tasks: [
      {
        name: '内容策略',
        startDate: new Date(),
        endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '受众分析', isCompleted: false },
          { id: 'c1_2', text: '内容定位', isCompleted: false },
          { id: 'c1_3', text: '主题规划', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '内容创作',
        startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '文章撰写', isCompleted: false },
          { id: 'c2_2', text: '视频制作', isCompleted: false },
          { id: 'c2_3', text: '图文设计', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '内容发布',
        startDate: new Date(Date.now() + 29 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '发布计划制定', isCompleted: false },
          { id: 'c3_2', text: '多平台发布', isCompleted: false },
          { id: 'c3_3', text: 'SEO优化', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '用户互动',
        startDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 63 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '评论管理', isCompleted: false },
          { id: 'c4_2', text: '用户反馈收集', isCompleted: false },
          { id: 'c4_3', text: '社群运营', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '效果分析',
        startDate: new Date(Date.now() + 64 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 70 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '数据统计', isCompleted: false },
          { id: 'c5_2', text: '转化分析', isCompleted: false },
          { id: 'c5_3', text: '优化方案', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 市场调研
  {
    id: 'market_research',
    name: '市场调研项目',
    description: '系统化的市场调研与分析流程',
    category: 'research',
    tasks: [
      {
        name: '调研规划',
        startDate: new Date(),
        endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '调研目标确定', isCompleted: false },
          { id: 'c1_2', text: '调研方法选择', isCompleted: false },
          { id: 'c1_3', text: '问卷设计', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '数据收集',
        startDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '问卷发放', isCompleted: false },
          { id: 'c2_2', text: '用户访谈', isCompleted: false },
          { id: 'c2_3', text: '数据录入', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '数据分析',
        startDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '描述性统计', isCompleted: false },
          { id: 'c3_2', text: '相关性分析', isCompleted: false },
          { id: 'c3_3', text: '数据可视化', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '洞察提炼',
        startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '关键发现总结', isCompleted: false },
          { id: 'c4_2', text: '用户画像构建', isCompleted: false },
          { id: 'c4_3', text: '市场机会识别', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '报告撰写',
        startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '报告框架搭建', isCompleted: false },
          { id: 'c5_2', text: '内容撰写', isCompleted: false },
          { id: 'c5_3', text: '建议输出', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 视频制作
  {
    id: 'video_production',
    name: '视频内容制作',
    description: '短视频或宣传片的完整制作流程',
    category: 'content',
    tasks: [
      {
        name: '前期策划',
        startDate: new Date(),
        endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '创意构思', isCompleted: false },
          { id: 'c1_2', text: '脚本撰写', isCompleted: false },
          { id: 'c1_3', text: '分镜头设计', isCompleted: false },
          { id: 'c1_4', text: '拍摄计划', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '拍摄准备',
        startDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '场地勘景', isCompleted: false },
          { id: 'c2_2', text: '演员选角', isCompleted: false },
          { id: 'c2_3', text: '设备准备', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '拍摄执行',
        startDate: new Date(Date.now() + 11 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '现场拍摄', isCompleted: false },
          { id: 'c3_2', text: '素材整理', isCompleted: false },
          { id: 'c3_3', text: '补拍镜头', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '后期制作',
        startDate: new Date(Date.now() + 19 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 32 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '剪辑', isCompleted: false },
          { id: 'c4_2', text: '调色', isCompleted: false },
          { id: 'c4_3', text: '配音配乐', isCompleted: false },
          { id: 'c4_4', text: '特效制作', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '发布推广',
        startDate: new Date(Date.now() + 33 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '视频导出', isCompleted: false },
          { id: 'c5_2', text: '平台发布', isCompleted: false },
          { id: 'c5_3', text: '推广投放', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 线下活动策划
  {
    id: 'offline_event',
    name: '线下活动策划',
    description: '会议、展览、发布会等线下活动组织',
    category: 'event',
    tasks: [
      {
        name: '活动策划',
        startDate: new Date(),
        endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '活动主题确定', isCompleted: false },
          { id: 'c1_2', text: '目标受众分析', isCompleted: false },
          { id: 'c1_3', text: '活动流程设计', isCompleted: false },
          { id: 'c1_4', text: '预算规划', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '场地筹备',
        startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '场地选择', isCompleted: false },
          { id: 'c2_2', text: '场地布置方案', isCompleted: false },
          { id: 'c2_3', text: '设备租赁', isCompleted: false },
          { id: 'c2_4', text: '物料制作', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '嘉宾邀请',
        startDate: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '嘉宾名单确定', isCompleted: false },
          { id: 'c3_2', text: '邀请函发送', isCompleted: false },
          { id: 'c3_3', text: '报名统计', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '活动执行',
        startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '现场布置', isCompleted: false },
          { id: 'c4_2', text: '签到接待', isCompleted: false },
          { id: 'c4_3', text: '活动主持', isCompleted: false },
          { id: 'c4_4', text: '现场拍摄', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '活动复盘',
        startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '数据统计', isCompleted: false },
          { id: 'c5_2', text: '效果评估', isCompleted: false },
          { id: 'c5_3', text: '总结报告', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
          { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 产品发布会
  {
    id: 'product_launch',
    name: '产品发布会',
    description: '新产品上市发布会的完整策划与执行',
    category: 'event',
    tasks: [
      {
        name: '发布策略',
        startDate: new Date(),
        endDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '产品卖点提炼', isCompleted: false },
          { id: 'c1_2', text: '发布主题确定', isCompleted: false },
          { id: 'c1_3', text: '传播策略制定', isCompleted: false },
          { id: 'c1_4', text: '媒体名单', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '内容准备',
        startDate: new Date(Date.now() + 11 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '演讲稿撰写', isCompleted: false },
          { id: 'c2_2', text: 'PPT设计', isCompleted: false },
          { id: 'c2_3', text: '宣传视频制作', isCompleted: false },
          { id: 'c2_4', text: '新闻稿撰写', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '场地布置',
        startDate: new Date(Date.now() + 26 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '舞台搭建', isCompleted: false },
          { id: 'c3_2', text: '灯光音响', isCompleted: false },
          { id: 'c3_3', text: '产品展示区', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '发布会执行',
        startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '彩排演练', isCompleted: false },
          { id: 'c4_2', text: '媒体接待', isCompleted: false },
          { id: 'c4_3', text: '发布会举行', isCompleted: false },
          { id: 'c4_4', text: '直播推流', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '后续传播',
        startDate: new Date(Date.now() + 43 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 56 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '新闻稿发布', isCompleted: false },
          { id: 'c5_2', text: '社交媒体推广', isCompleted: false },
          { id: 'c5_3', text: '媒体报道跟踪', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 在线课程开发
  {
    id: 'online_course',
    name: '在线课程开发',
    description: '在线教育课程的设计与制作',
    category: 'content',
    tasks: [
      {
        name: '课程设计',
        startDate: new Date(),
        endDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '学习目标确定', isCompleted: false },
          { id: 'c1_2', text: '课程大纲编写', isCompleted: false },
          { id: 'c1_3', text: '知识点拆解', isCompleted: false },
          { id: 'c1_4', text: '教学方法设计', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '内容制作',
        startDate: new Date(Date.now() + 11 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '课件制作', isCompleted: false },
          { id: 'c2_2', text: '视频录制', isCompleted: false },
          { id: 'c2_3', text: '习题设计', isCompleted: false },
          { id: 'c2_4', text: '案例准备', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '后期制作',
        startDate: new Date(Date.now() + 36 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: '视频剪辑', isCompleted: false },
          { id: 'c3_2', text: '字幕添加', isCompleted: false },
          { id: 'c3_3', text: '特效制作', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '平台上线',
        startDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 56 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '课程上传', isCompleted: false },
          { id: 'c4_2', text: '课程页面设计', isCompleted: false },
          { id: 'c4_3', text: '测试验收', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '运营推广',
        startDate: new Date(Date.now() + 57 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 70 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '宣传文案', isCompleted: false },
          { id: 'c5_2', text: '推广投放', isCompleted: false },
          { id: 'c5_3', text: '学员服务', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  },

  // 电商店铺运营
  {
    id: 'ecommerce_operation',
    name: '电商店铺运营',
    description: '电商平台店铺的运营与推广',
    category: 'marketing',
    tasks: [
      {
        name: '店铺搭建',
        startDate: new Date(),
        endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c1_1', text: '店铺注册', isCompleted: false },
          { id: 'c1_2', text: '店铺装修', isCompleted: false },
          { id: 'c1_3', text: '商品上架', isCompleted: false },
          { id: 'c1_4', text: '物流配置', isCompleted: false }
        ],
        x: 50, y: 100
      },
      {
        name: '产品运营',
        startDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c2_1', text: '商品详情页优化', isCompleted: false },
          { id: 'c2_2', text: '产品拍摄', isCompleted: false },
          { id: 'c2_3', text: '价格策略', isCompleted: false }
        ],
        x: 300, y: 100
      },
      {
        name: '流量获取',
        startDate: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 49 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c3_1', text: 'SEO优化', isCompleted: false },
          { id: 'c3_2', text: '直通车推广', isCompleted: false },
          { id: 'c3_3', text: '活动报名', isCompleted: false },
          { id: 'c3_4', text: '达人合作', isCompleted: false }
        ],
        x: 550, y: 100
      },
      {
        name: '客户服务',
        startDate: new Date(Date.now() + 50 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 70 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c4_1', text: '客服培训', isCompleted: false },
          { id: 'c4_2', text: '售后处理', isCompleted: false },
          { id: 'c4_3', text: '评价管理', isCompleted: false }
        ],
        x: 800, y: 100
      },
      {
        name: '数据分析',
        startDate: new Date(Date.now() + 71 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 77 * 24 * 60 * 60 * 1000),
        checklist: [
          { id: 'c5_1', text: '销售数据分析', isCompleted: false },
          { id: 'c5_2', text: '用户行为分析', isCompleted: false },
          { id: 'c5_3', text: '优化策略制定', isCompleted: false }
        ],
        x: 1050, y: 100
      }
    ],
    dependencies: [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_4' },
      { fromId: 'task_4', toId: 'task_5' }
    ]
  }
];
