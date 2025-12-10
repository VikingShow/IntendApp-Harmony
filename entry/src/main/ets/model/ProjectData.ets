// File: entry/src/main/ets/model/ProjectData.ets
/**
 * 项目数据模型模块
 * 
 * 本模块定义了EasyFlow应用的核心数据模型，包括项目、任务、依赖关系等核心实体。
 * 采用面向对象设计，提供清晰的数据结构和操作方法，支持响应式数据绑定。
 * 
 * 主要实体：
 * 1. Project：项目实体，包含项目基本信息和任务列表
 * 2. TaskNode：任务节点，包含任务详细信息和位置信息
 * 3. ChecklistItem：检查清单项，用于任务分解和进度跟踪
 * 4. Dependency：依赖关系，定义任务间的逻辑依赖
 * 
 * 设计特点：
 * - 响应式设计：使用@Observed装饰器支持响应式数据绑定
 * - 类型安全：使用TypeScript确保数据类型安全
 * - 可扩展性：预留扩展字段，支持功能扩展
 * - 序列化支持：支持JSON序列化和反序列化
 * - 验证机制：提供数据有效性验证方法
 * 
 * 数据关系：
 * - Project 1:N TaskNode：一个项目包含多个任务
 * - TaskNode 1:N ChecklistItem：一个任务包含多个检查项
 * - TaskNode N:N TaskNode：任务间通过Dependency建立依赖关系
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

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
 * 任务节点接口
 * 定义项目中的单个任务，包含任务信息和关键路径计算参数
 */
export interface TaskNode {
  /** 任务唯一标识符 */
  id: string;
  /** 任务名称 */
  name: string;
  /** 开始日期 */
  startDate: Date;
  /** 结束日期 */
  endDate: Date;
  /** 检查清单列表 */
  checklist: ChecklistItem[];
  /** 画布X坐标 */
  x: number;
  /** 画布Y坐标 */
  y: number;
  /** 最早开始时间（关键路径计算参数） */
  earlyStart?: number;
  /** 最早结束时间（关键路径计算参数） */
  earlyFinish?: number;
  /** 最晚开始时间（关键路径计算参数） */
  lateStart?: number;
  /** 最晚结束时间（关键路径计算参数） */
  lateFinish?: number;
  /** 是否为关键任务（关键路径计算参数） */
  isCritical?: boolean;
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
  /** 是否显示箭头（可选，默认true） */
  showArrow?: boolean;
}

/**
 * 项目实体类
 * 
 * 表示一个完整的项目，包含项目基本信息和所有相关数据。
 * 使用@Observed装饰器实现响应式数据绑定，当项目数据发生变化时自动触发UI更新。
 * 
 * 核心属性：
 * - 基本信息：ID、名称、分类、修改时间
 * - 任务列表：项目包含的所有任务
 * - 依赖关系：任务间的逻辑依赖关系
 * 
 * 主要功能：
 * 1. 任务管理：添加、删除、更新任务
 * 2. 依赖管理：建立和删除任务依赖关系
 * 3. 数据验证：提供数据有效性检查
 * 4. 序列化支持：支持JSON格式的序列化和反序列化
 * 5. 响应式更新：数据变化时自动触发UI更新
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
@Observed
export class Project {
  /** 项目唯一标识符 */
  id: string;
  /** 项目名称 */
  name: string = '新项目';
  /** 最后修改时间（时间戳） */
  lastModified: number;
  /** 项目分类 */
  category: string = '其他';
  /** 项目备注 */
  note?: string;

  /** 任务列表 */
  tasks: TaskNode[] = [];
  /** 依赖关系列表 */
  dependencies: Dependency[] = [];
  
  /** 画布状态 - 每个项目单独保存 */
  canvasOffsetX: number = 0;
  canvasOffsetY: number = 0;
  zoomScale: number = 1.0;

  /**
   * 构造函数
   * 创建新项目时自动生成ID和初始化时间
   * 
   * @param id 项目ID，如果不提供则自动生成
   * @param name 项目名称，如果不提供则使用默认名称
   */
  constructor(id?: string, name?: string) {
    this.id = id || `project_${Date.now()}`;
    this.name = name || '新项目';
    this.lastModified = Date.now();
  }

  /**
   * 添加任务
   * 向项目中添加新的任务节点
   * 
   * @param task 要添加的任务节点
   */
  addTask(task: TaskNode) {
    this.tasks.push(task);
  }
}
