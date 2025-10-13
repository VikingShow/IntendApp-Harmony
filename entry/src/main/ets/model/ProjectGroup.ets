// File: entry/src/main/ets/model/ProjectGroup.ets
/**
 * 项目群数据模型模块
 * 
 * 本模块定义了项目群管理的核心数据模型，用于管理多个项目的组织和关系。
 * 采用三层架构设计：项目群 → 项目 → 任务，实现层级化的项目管理。
 * 
 * 主要实体：
 * 1. ProjectGroup：项目群实体，包含项目群基本信息和项目引用列表
 * 2. ProjectRef：项目引用，用于在画布上显示项目节点
 * 3. ProjectDependency：项目间依赖关系，定义项目间的逻辑依赖
 * 
 * 设计特点：
 * - 响应式设计：使用@Observed装饰器支持响应式数据绑定
 * - 引用分离：ProjectRef只存储引用信息，详细数据通过ID加载
 * - 可扩展性：预留扩展字段，支持功能扩展
 * - 序列化支持：支持JSON序列化和反序列化
 * - 复用架构：完全复用Project的设计模式
 * 
 * 数据关系：
 * - ProjectGroup 1:N ProjectRef：一个项目群包含多个项目引用
 * - ProjectRef N:N ProjectRef：项目间通过ProjectDependency建立依赖关系
 * - ProjectRef → Project：通过ID关联到实际的项目数据
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-01
 */

/**
 * 项目引用接口
 * 定义项目群中的单个项目引用，类似于Project中的TaskNode
 * 只存储引用信息和画布位置，不存储项目详细数据
 */
export interface ProjectRef {
  /** 项目唯一标识符（关联到实际的Project.id） */
  id: string;
  /** 项目名称（冗余字段，便于在画布上直接显示，避免频繁查询） */
  name: string;
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
  /** 是否为关键项目（关键路径计算参数） */
  isCritical?: boolean;
}

/**
 * 项目间依赖关系接口
 * 定义项目群中项目之间的逻辑依赖关系
 */
export interface ProjectDependency {
  /** 源项目ID */
  fromId: string;
  /** 目标项目ID */
  toId: string;
}

/**
 * 项目群实体类
 * 
 * 表示一个完整的项目群，包含项目群基本信息和所有相关项目引用。
 * 使用@Observed装饰器实现响应式数据绑定，当数据发生变化时自动触发UI更新。
 * 
 * 核心属性：
 * - 基本信息：ID、名称、分类、修改时间
 * - 项目引用列表：项目群包含的所有项目引用
 * - 依赖关系：项目间的逻辑依赖关系
 * - 画布状态：每个项目群单独保存画布偏移和缩放
 * 
 * 主要功能：
 * 1. 项目管理：添加、删除、更新项目引用
 * 2. 依赖管理：建立和删除项目间依赖关系
 * 3. 数据验证：提供数据有效性检查
 * 4. 序列化支持：支持JSON格式的序列化和反序列化
 * 5. 响应式更新：数据变化时自动触发UI更新
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-01
 */
@Observed
export class ProjectGroup {
  /** 项目群唯一标识符 */
  id: string;
  /** 项目群名称 */
  name: string = '新项目群';
  /** 最后修改时间（时间戳） */
  lastModified: number;
  /** 项目群分类（预留字段，可用于分类管理） */
  category: string = '其他';

  /** 项目引用列表（类似Project中的tasks） */
  projectRefs: ProjectRef[] = [];
  /** 项目间依赖关系列表 */
  dependencies: ProjectDependency[] = [];
  
  /** 画布状态 - 每个项目群单独保存 */
  canvasOffsetX: number = 0;
  canvasOffsetY: number = 0;
  zoomScale: number = 1.0;

  /**
   * 构造函数
   * 创建新项目群时自动生成ID和初始化时间
   * 
   * @param id 项目群ID，如果不提供则自动生成
   * @param name 项目群名称，如果不提供则使用默认名称
   */
  constructor(id?: string, name?: string) {
    this.id = id || `group_${Date.now()}`;
    this.name = name || '新项目群';
    this.lastModified = Date.now();
  }

  /**
   * 添加项目引用
   * 向项目群中添加新的项目引用节点
   * 
   * @param projectRef 要添加的项目引用
   */
  addProjectRef(projectRef: ProjectRef): void {
    this.projectRefs.push(projectRef);
  }

  /**
   * 移除项目引用
   * 从项目群中移除指定的项目引用
   * 
   * @param projectId 要移除的项目ID
   */
  removeProjectRef(projectId: string): void {
    this.projectRefs = this.projectRefs.filter(ref => ref.id !== projectId);
    // 同时移除相关的依赖关系
    this.dependencies = this.dependencies.filter(
      dep => dep.fromId !== projectId && dep.toId !== projectId
    );
  }

  /**
   * 添加项目间依赖关系
   * 
   * @param fromId 源项目ID
   * @param toId 目标项目ID
   */
  addDependency(fromId: string, toId: string): void {
    // 检查依赖是否已存在
    const exists = this.dependencies.some(
      dep => dep.fromId === fromId && dep.toId === toId
    );
    if (!exists) {
      this.dependencies.push({ fromId, toId });
    }
  }

  /**
   * 移除项目间依赖关系
   * 
   * @param fromId 源项目ID
   * @param toId 目标项目ID
   */
  removeDependency(fromId: string, toId: string): void {
    this.dependencies = this.dependencies.filter(
      dep => !(dep.fromId === fromId && dep.toId === toId)
    );
  }

  /**
   * 更新项目引用位置
   * 
   * @param projectId 项目ID
   * @param x 新的X坐标
   * @param y 新的Y坐标
   */
  updateProjectRefPosition(projectId: string, x: number, y: number): void {
    const projectRef = this.projectRefs.find(ref => ref.id === projectId);
    if (projectRef) {
      projectRef.x = x;
      projectRef.y = y;
    }
  }

  /**
   * 更新项目引用名称（冗余字段同步更新）
   * 
   * @param projectId 项目ID
   * @param name 新名称
   */
  updateProjectRefName(projectId: string, name: string): void {
    const projectRef = this.projectRefs.find(ref => ref.id === projectId);
    if (projectRef) {
      projectRef.name = name;
    }
  }
}
