# EasyFlow 全面技术指南

> 深度、跨领域、面向未来的技术知识体系

---

## 🌟 文档定位

本文档是 EasyFlow 项目的**完整技术知识库**，涵盖：

1. **现有技术栈**的深度解析
2. **算法与数据结构**的实战应用
3. **软件工程**最佳实践
4. **跨领域知识**整合（项目管理、可视化、AI等）
5. **未来功能**开发指南

---

## 📊 第一部分：图算法与网络分析

### 1.1 关键路径法（CPM）完整解析

#### 1.1.1 算法理论基础

**什么是关键路径法？**

关键路径法（Critical Path Method, CPM）是一种项目管理技术，由杜邦公司和兰德公司在1950年代联合开发。它通过分析项目网络图中的任务依赖关系，找出影响项目总工期的关键路径。

**核心概念：**

```
ES (Earliest Start)    : 最早开始时间
EF (Earliest Finish)   : 最早完成时间 = ES + Duration
LS (Latest Start)      : 最晚开始时间
LF (Latest Finish)     : 最晚完成时间 = LS + Duration
TF (Total Float)       : 总浮动时间 = LS - ES = LF - EF
FF (Free Float)        : 自由浮动时间 = min(ES of successors) - EF
```

**关键路径定义：**
- 从项目起点到终点的最长路径
- 路径上所有任务的 TF = 0
- 任何关键任务的延迟都会导致项目延期

#### 1.1.2 算法实现详解

```typescript
/**
 * CPM 算法完整实现
 * 
 * 时间复杂度：O(V + E)
 * 空间复杂度：O(V + E)
 * 
 * V = 任务数量
 * E = 依赖关系数量
 */
export class CriticalPathService {
  /**
   * 主算法入口
   */
  public calculate(
    tasks: TaskWithDuration[],
    dependencies: Dependency[]
  ): CriticalPathResult {
    // 步骤 1：输入验证
    const validation = this.validateInput(tasks, dependencies);
    if (!validation.isValid) {
      return {
        success: false,
        error: validation.error
      };
    }
    
    // 步骤 2：循环依赖检测
    if (this.hasCircularDependency(tasks, dependencies)) {
      return {
        success: false,
        error: '存在循环依赖'
      };
    }
    
    // 步骤 3：构建图结构
    const graph = this.buildGraph(tasks, dependencies);
    
    // 步骤 4：拓扑排序
    const sortedTasks = this.topologicalSort(graph);
    
    // 步骤 5：正向传递（计算 ES 和 EF）
    this.forwardPass(sortedTasks, graph);
    
    // 步骤 6：反向传递（计算 LS 和 LF）
    this.backwardPass(sortedTasks, graph);
    
    // 步骤 7：计算浮动时间
    this.calculateSlack(sortedTasks);
    
    // 步骤 8：识别关键路径
    const criticalPath = this.identifyCriticalPath(sortedTasks, graph);
    
    return {
      success: true,
      criticalTasks: criticalPath,
      projectDuration: this.getProjectDuration(sortedTasks)
    };
  }
  
  /**
   * 步骤 1：输入验证
   */
  private validateInput(
    tasks: TaskWithDuration[],
    dependencies: Dependency[]
  ): ValidationResult {
    // 检查任务列表
    if (!tasks || tasks.length === 0) {
      return { isValid: false, error: '任务列表不能为空' };
    }
    
    // 检查任务 ID 唯一性
    const ids = new Set<string>();
    for (const task of tasks) {
      if (ids.has(task.id)) {
        return { isValid: false, error: `重复的任务ID: ${task.id}` };
      }
      ids.add(task.id);
    }
    
    // 检查工期有效性
    for (const task of tasks) {
      if (task.duration <= 0) {
        return { isValid: false, error: `任务${task.id}的工期无效` };
      }
    }
    
    // 检查依赖关系有效性
    for (const dep of dependencies) {
      if (!ids.has(dep.fromId) || !ids.has(dep.toId)) {
        return { isValid: false, error: '依赖关系引用了不存在的任务' };
      }
      if (dep.fromId === dep.toId) {
        return { isValid: false, error: '任务不能依赖自己' };
      }
    }
    
    return { isValid: true };
  }
  
  /**
   * 步骤 2：循环依赖检测（深度优先搜索）
   */
  private hasCircularDependency(
    tasks: TaskWithDuration[],
    dependencies: Dependency[]
  ): boolean {
    // 构建邻接表
    const graph = new Map<string, string[]>();
    for (const task of tasks) {
      graph.set(task.id, []);
    }
    for (const dep of dependencies) {
      graph.get(dep.fromId)!.push(dep.toId);
    }
    
    // DFS 状态
    const visiting = new Set<string>();  // 正在访问
    const visited = new Set<string>();   // 已访问
    
    // DFS 检测环
    const dfs = (taskId: string): boolean => {
      if (visiting.has(taskId)) {
        return true;  // 发现环
      }
      if (visited.has(taskId)) {
        return false; // 已检查过
      }
      
      visiting.add(taskId);
      
      for (const nextId of graph.get(taskId) || []) {
        if (dfs(nextId)) {
          return true;
        }
      }
      
      visiting.delete(taskId);
      visited.add(taskId);
      return false;
    };
    
    // 对所有任务执行 DFS
    for (const task of tasks) {
      if (!visited.has(task.id)) {
        if (dfs(task.id)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /**
   * 步骤 3：构建图结构
   */
  private buildGraph(
    tasks: TaskWithDuration[],
    dependencies: Dependency[]
  ): Map<string, GraphNode> {
    const graph = new Map<string, GraphNode>();
    
    // 初始化节点
    for (const task of tasks) {
      graph.set(task.id, {
        task: task,
        predecessors: [],
        successors: []
      });
    }
    
    // 建立边
    for (const dep of dependencies) {
      const fromNode = graph.get(dep.fromId)!;
      const toNode = graph.get(dep.toId)!;
      fromNode.successors.push(toNode);
      toNode.predecessors.push(fromNode);
    }
    
    return graph;
  }
  
  /**
   * 步骤 4：拓扑排序（Kahn 算法）
   */
  private topologicalSort(graph: Map<string, GraphNode>): TaskWithDuration[] {
    const result: TaskWithDuration[] = [];
    const inDegree = new Map<string, number>();
    
    // 计算入度
    for (const [id, node] of graph) {
      inDegree.set(id, node.predecessors.length);
    }
    
    // 找出所有入度为 0 的节点
    const queue: GraphNode[] = [];
    for (const [id, node] of graph) {
      if (inDegree.get(id) === 0) {
        queue.push(node);
      }
    }
    
    // Kahn 算法
    while (queue.length > 0) {
      const node = queue.shift()!;
      result.push(node.task);
      
      // 减少后继节点的入度
      for (const successor of node.successors) {
        const succId = successor.task.id;
        inDegree.set(succId, inDegree.get(succId)! - 1);
        
        if (inDegree.get(succId) === 0) {
          queue.push(successor);
        }
      }
    }
    
    return result;
  }
  
  /**
   * 步骤 5：正向传递（计算 ES 和 EF）
   */
  private forwardPass(
    sortedTasks: TaskWithDuration[],
    graph: Map<string, GraphNode>
  ): void {
    for (const task of sortedTasks) {
      const node = graph.get(task.id)!;
      
      // ES = max(EF of all predecessors)
      if (node.predecessors.length === 0) {
        task.earlyStart = 0;
      } else {
        task.earlyStart = Math.max(
          ...node.predecessors.map(pred => pred.task.earlyFinish || 0)
        );
      }
      
      // EF = ES + Duration
      task.earlyFinish = task.earlyStart + task.duration;
    }
  }
  
  /**
   * 步骤 6：反向传递（计算 LS 和 LF）
   */
  private backwardPass(
    sortedTasks: TaskWithDuration[],
    graph: Map<string, GraphNode>
  ): void {
    // 计算项目总工期
    const projectDuration = Math.max(
      ...sortedTasks.map(t => t.earlyFinish || 0)
    );
    
    // 反向遍历
    for (let i = sortedTasks.length - 1; i >= 0; i--) {
      const task = sortedTasks[i];
      const node = graph.get(task.id)!;
      
      // LF = min(LS of all successors)
      if (node.successors.length === 0) {
        task.lateFinish = projectDuration;
      } else {
        task.lateFinish = Math.min(
          ...node.successors.map(succ => succ.task.lateStart || Infinity)
        );
      }
      
      // LS = LF - Duration
      task.lateStart = task.lateFinish - task.duration;
    }
  }
  
  /**
   * 步骤 7：计算浮动时间
   */
  private calculateSlack(tasks: TaskWithDuration[]): void {
    for (const task of tasks) {
      // Total Float = LS - ES
      const totalFloat = (task.lateStart || 0) - (task.earlyStart || 0);
      task.isCritical = (totalFloat === 0);
    }
  }
  
  /**
   * 步骤 8：识别关键路径
   */
  private identifyCriticalPath(
    tasks: TaskWithDuration[],
    graph: Map<string, GraphNode>
  ): string[] {
    const criticalTasks = tasks.filter(t => t.isCritical);
    return criticalTasks.map(t => t.id);
  }
}

/**
 * 辅助数据结构
 */
interface GraphNode {
  task: TaskWithDuration;
  predecessors: GraphNode[];
  successors: GraphNode[];
}
```

#### 1.1.3 算法优化技巧

**优化 1：缓存计算结果**
```typescript
class OptimizedCPMService {
  private cache = new Map<string, CriticalPathResult>();
  
  calculate(tasks: TaskWithDuration[], dependencies: Dependency[]): CriticalPathResult {
    // 计算数据哈希
    const hash = this.computeHash(tasks, dependencies);
    
    // 检查缓存
    if (this.cache.has(hash)) {
      return this.cache.get(hash)!;
    }
    
    // 执行计算
    const result = this.performCalculation(tasks, dependencies);
    
    // 缓存结果
    this.cache.set(hash, result);
    
    return result;
  }
  
  private computeHash(tasks: TaskWithDuration[], dependencies: Dependency[]): string {
    // 只基于任务ID、工期和依赖关系计算哈希
    const data = {
      tasks: tasks.map(t => ({ id: t.id, duration: t.duration })),
      deps: dependencies.sort((a, b) => a.fromId.localeCompare(b.fromId))
    };
    return JSON.stringify(data);
  }
}
```

**优化 2：增量更新**
```typescript
class IncrementalCPM {
  /**
   * 只更新受影响的任务
   */
  updateTaskDuration(
    taskId: string,
    newDuration: number,
    graph: Map<string, GraphNode>
  ): void {
    const node = graph.get(taskId)!;
    node.task.duration = newDuration;
    
    // 找出受影响的任务（所有后继任务）
    const affectedTasks = this.findAffectedTasks(node);
    
    // 只重新计算这些任务
    this.recalculateAffectedTasks(affectedTasks);
  }
  
  private findAffectedTasks(node: GraphNode): GraphNode[] {
    const affected = new Set<GraphNode>();
    const queue = [node];
    
    while (queue.length > 0) {
      const current = queue.shift()!;
      affected.add(current);
      
      for (const successor of current.successors) {
        if (!affected.has(successor)) {
          queue.push(successor);
        }
      }
    }
    
    return Array.from(affected);
  }
}
```

### 1.2 图算法扩展

#### 1.2.1 最短路径算法（Dijkstra）

```typescript
/**
 * Dijkstra 算法：计算最短路径
 * 
 * 应用场景：
 * - 计算任务之间的最短时间路径
 * - 资源分配优化
 * - 成本最小化
 */
class ShortestPathService {
  /**
   * Dijkstra 算法实现
   */
  findShortestPath(
    graph: Map<string, GraphNode>,
    startId: string,
    endId: string
  ): { path: string[], distance: number } {
    const distances = new Map<string, number>();
    const previous = new Map<string, string | null>();
    const unvisited = new Set<string>();
    
    // 初始化
    for (const [id] of graph) {
      distances.set(id, Infinity);
      previous.set(id, null);
      unvisited.add(id);
    }
    distances.set(startId, 0);
    
    while (unvisited.size > 0) {
      // 找出未访问节点中距离最小的
      let minNode: string | null = null;
      let minDistance = Infinity;
      
      for (const id of unvisited) {
        const dist = distances.get(id)!;
        if (dist < minDistance) {
          minDistance = dist;
          minNode = id;
        }
      }
      
      if (minNode === null || minNode === endId) break;
      
      unvisited.delete(minNode);
      
      // 更新邻居距离
      const node = graph.get(minNode)!;
      for (const successor of node.successors) {
        const alt = distances.get(minNode)! + successor.task.duration;
        if (alt < distances.get(successor.task.id)!) {
          distances.set(successor.task.id, alt);
          previous.set(successor.task.id, minNode);
        }
      }
    }
    
    // 重建路径
    const path: string[] = [];
    let current: string | null = endId;
    
    while (current !== null) {
      path.unshift(current);
      current = previous.get(current)!;
    }
    
    return {
      path: path,
      distance: distances.get(endId)!
    };
  }
}
```

#### 1.2.2 网络流算法（最大流）

```typescript
/**
 * Ford-Fulkerson 算法：计算最大流
 * 
 * 应用场景：
 * - 资源分配优化
 * - 任务并行度分析
 * - 瓶颈识别
 */
class MaxFlowService {
  /**
   * 计算最大流
   */
  fordFulkerson(
    graph: FlowGraph,
    source: string,
    sink: string
  ): number {
    let maxFlow = 0;
    
    // 深度优先搜索找增广路径
    while (true) {
      const path = this.findAugmentingPath(graph, source, sink);
      
      if (path.length === 0) {
        break; // 没有增广路径
      }
      
      // 计算路径最小容量
      let minCapacity = Infinity;
      for (let i = 0; i < path.length - 1; i++) {
        const capacity = graph.getCapacity(path[i], path[i + 1]);
        minCapacity = Math.min(minCapacity, capacity);
      }
      
      // 更新流量
      for (let i = 0; i < path.length - 1; i++) {
        graph.addFlow(path[i], path[i + 1], minCapacity);
      }
      
      maxFlow += minCapacity;
    }
    
    return maxFlow;
  }
  
  /**
   * DFS 寻找增广路径
   */
  private findAugmentingPath(
    graph: FlowGraph,
    source: string,
    sink: string
  ): string[] {
    const visited = new Set<string>();
    const path: string[] = [];
    
    const dfs = (node: string): boolean => {
      if (node === sink) {
        path.push(node);
        return true;
      }
      
      visited.add(node);
      
      for (const neighbor of graph.getNeighbors(node)) {
        if (!visited.has(neighbor) && graph.getCapacity(node, neighbor) > 0) {
          if (dfs(neighbor)) {
            path.unshift(node);
            return true;
          }
        }
      }
      
      return false;
    };
    
    dfs(source);
    return path;
  }
}
```

---

## 📊 第二部分：数据可视化技术

### 2.1 Canvas 2D 高级渲染

#### 2.1.1 离屏Canvas优化

```typescript
/**
 * 离屏 Canvas：预渲染复杂图形
 * 
 * 优势：
 * - 减少重复绘制
 * - 提升渲染性能
 * - 支持图形缓存
 */
class OffscreenCanvasRenderer {
  private offscreenCanvas: CanvasRenderingContext2D | null = null;
  private cache = new Map<string, ImageBitmap>();
  
  /**
   * 预渲染任务节点
   */
  async prerenderTaskNode(task: TaskNode): Promise<ImageBitmap> {
    // 检查缓存
    if (this.cache.has(task.id)) {
      return this.cache.get(task.id)!;
    }
    
    // 创建离屏Canvas
    const offscreen = new OffscreenCanvas(200, 100);
    const ctx = offscreen.getContext('2d') as OffscreenCanvasRenderingContext2D;
    
    // 绘制节点
    this.drawTaskNode(ctx, task);
    
    // 转换为 ImageBitmap
    const bitmap = await offscreen.transferToImageBitmap();
    
    // 缓存
    this.cache.set(task.id, bitmap);
    
    return bitmap;
  }
  
  /**
   * 使用预渲染的图形
   */
  renderFromCache(ctx: CanvasRenderingContext2D, task: TaskNode): void {
    const bitmap = this.cache.get(task.id);
    if (bitmap) {
      ctx.drawImage(bitmap, task.x, task.y);
    } else {
      // 如果缓存不存在，直接绘制
      this.drawTaskNode(ctx, task);
    }
  }
  
  /**
   * 清除缓存
   */
  clearCache(taskId?: string): void {
    if (taskId) {
      this.cache.delete(taskId);
    } else {
      this.cache.clear();
    }
  }
}
```

#### 2.1.2 脏矩形渲染

```typescript
/**
 * 脏矩形技术：只重绘变化区域
 */
class DirtyRectRenderer {
  private dirtyRects: Rect[] = [];
  
  /**
   * 标记脏区域
   */
  markDirty(rect: Rect): void {
    this.dirtyRects.push(rect);
  }
  
  /**
   * 智能渲染：只重绘脏区域
   */
  render(ctx: CanvasRenderingContext2D, project: Project): void {
    if (this.dirtyRects.length === 0) {
      return; // 无变化，跳过渲染
    }
    
    // 合并重叠的脏矩形
    const mergedRects = this.mergeRects(this.dirtyRects);
    
    // 只重绘脏区域
    for (const rect of mergedRects) {
      // 清除区域
      ctx.clearRect(rect.x, rect.y, rect.width, rect.height);
      
      // 重绘该区域内的内容
      this.renderRegion(ctx, project, rect);
    }
    
    // 清空脏矩形列表
    this.dirtyRects = [];
  }
  
  /**
   * 合并重叠矩形
   */
  private mergeRects(rects: Rect[]): Rect[] {
    // 简化实现：直接返回包围盒
    if (rects.length === 0) return [];
    
    let minX = Infinity, minY = Infinity;
    let maxX = -Infinity, maxY = -Infinity;
    
    for (const rect of rects) {
      minX = Math.min(minX, rect.x);
      minY = Math.min(minY, rect.y);
      maxX = Math.max(maxX, rect.x + rect.width);
      maxY = Math.max(maxY, rect.y + rect.height);
    }
    
    return [{
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY
    }];
  }
  
  /**
   * 渲染指定区域
   */
  private renderRegion(
    ctx: CanvasRenderingContext2D,
    project: Project,
    region: Rect
  ): void {
    // 只渲染在该区域内的任务
    for (const task of project.tasks) {
      if (this.isInRegion(task, region)) {
        this.drawTaskNode(ctx, task);
      }
    }
    
    // 渲染依赖连线
    for (const dep of project.dependencies) {
      if (this.isDependencyInRegion(dep, project, region)) {
        this.drawDependency(ctx, dep, project);
      }
    }
  }
  
  /**
   * 检查任务是否在区域内
   */
  private isInRegion(task: TaskNode, region: Rect): boolean {
    return !(
      task.x + 200 < region.x ||
      task.x > region.x + region.width ||
      task.y + 100 < region.y ||
      task.y > region.y + region.height
    );
  }
}

interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}
```

### 2.2 数据可视化理论

#### 2.2.1 视觉编码原理

```
视觉通道优先级（从高到低）：

1. 位置（Position）       - 最准确
2. 长度（Length）         - 准确
3. 角度（Angle）          - 中等
4. 方向（Direction）      - 中等
5. 面积（Area）           - 低
6. 体积（Volume）         - 最不准确
7. 颜色饱和度（Saturation）
8. 颜色色相（Hue）        - 分类用
```

**应用示例：**
```typescript
/**
 * 任务状态的视觉编码
 */
class TaskVisualEncoding {
  /**
   * 位置编码：任务在画布上的位置表示依赖关系
   */
  encodePosition(task: TaskNode): { x: number, y: number } {
    // 横向：表示时间进度
    // 纵向：表示并行任务
    return {
      x: task.earlyStart * 50,  // 时间轴
      y: task.layer * 120        // 层级
    };
  }
  
  /**
   * 颜色编码：表示任务状态
   */
  encodeColor(task: TaskNode): string {
    if (task.isCritical) {
      return '#F56C6C';  // 关键任务：红色
    }
    
    const progress = this.calculateProgress(task);
    if (progress >= 100) {
      return '#67C23A';  // 已完成：绿色
    } else if (progress > 0) {
      return '#409EFF';  // 进行中：蓝色
    } else {
      return '#909399';  // 未开始：灰色
    }
  }
  
  /**
   * 大小编码：表示任务重要性
   */
  encodeSize(task: TaskNode): { width: number, height: number } {
    const importance = this.calculateImportance(task);
    return {
      width: 150 + importance * 50,
      height: 80 + importance * 20
    };
  }
}
```

#### 2.2.2 甘特图实现

```typescript
/**
 * 甘特图渲染器
 * 
 * 甘特图特点：
 * - 横轴：时间
 * - 纵轴：任务
 * - 条形：任务工期
 */
class GanttChartRenderer {
  private ctx: CanvasRenderingContext2D;
  private config: GanttConfig;
  
  constructor(ctx: CanvasRenderingContext2D) {
    this.ctx = ctx;
    this.config = {
      rowHeight: 40,
      dayWidth: 20,
      headerHeight: 60,
      leftMargin: 200
    };
  }
  
  /**
   * 渲染甘特图
   */
  render(project: Project): void {
    // 1. 绘制时间轴
    this.renderTimeAxis(project);
    
    // 2. 绘制任务条
    this.renderTaskBars(project);
    
    // 3. 绘制依赖关系
    this.renderDependencyLines(project);
    
    // 4. 绘制今天线
    this.renderTodayLine();
  }
  
  /**
   * 绘制时间轴
   */
  private renderTimeAxis(project: Project): void {
    const startDate = this.getProjectStartDate(project);
    const endDate = this.getProjectEndDate(project);
    const days = this.getDaysBetween(startDate, endDate);
    
    this.ctx.save();
    
    // 背景
    this.ctx.fillStyle = '#F5F7FA';
    this.ctx.fillRect(
      this.config.leftMargin,
      0,
      days * this.config.dayWidth,
      this.config.headerHeight
    );
    
    // 绘制日期
    this.ctx.font = '12px Arial';
    this.ctx.fillStyle = '#606266';
    
    let currentDate = new Date(startDate);
    let x = this.config.leftMargin;
    
    while (currentDate <= endDate) {
      // 月份分隔线
      if (currentDate.getDate() === 1) {
        this.ctx.strokeStyle = '#DCDFE6';
        this.ctx.beginPath();
        this.ctx.moveTo(x, 0);
        this.ctx.lineTo(x, this.config.headerHeight);
        this.ctx.stroke();
        
        // 月份标签
        const monthLabel = this.formatMonth(currentDate);
        this.ctx.fillText(monthLabel, x + 5, 20);
      }
      
      // 日期标签
      const dayLabel = currentDate.getDate().toString();
      this.ctx.fillText(dayLabel, x + 5, 45);
      
      // 下一天
      currentDate.setDate(currentDate.getDate() + 1);
      x += this.config.dayWidth;
    }
    
    this.ctx.restore();
  }
  
  /**
   * 绘制任务条
   */
  private renderTaskBars(project: Project): void {
    const startDate = this.getProjectStartDate(project);
    
    project.tasks.forEach((task, index) => {
      const y = this.config.headerHeight + index * this.config.rowHeight + 5;
      
      // 计算任务条位置
      const taskStart = this.getDaysBetween(startDate, task.startDate);
      const taskDuration = this.getDaysBetween(task.startDate, task.endDate);
      
      const x = this.config.leftMargin + taskStart * this.config.dayWidth;
      const width = taskDuration * this.config.dayWidth;
      const height = this.config.rowHeight - 10;
      
      // 绘制任务条
      this.ctx.save();
      
      // 背景
      this.ctx.fillStyle = task.isCritical ? '#FEF0F0' : '#ECF5FF';
      this.ctx.fillRect(x, y, width, height);
      
      // 边框
      this.ctx.strokeStyle = task.isCritical ? '#F56C6C' : '#409EFF';
      this.ctx.lineWidth = 2;
      this.ctx.strokeRect(x, y, width, height);
      
      // 进度条
      const progress = this.calculateProgress(task);
      const progressWidth = width * (progress / 100);
      
      this.ctx.fillStyle = task.isCritical ? '#F56C6C' : '#409EFF';
      this.ctx.fillRect(x, y, progressWidth, height);
      
      // 任务名称
      this.ctx.fillStyle = '#FFFFFF';
      this.ctx.font = '12px Arial';
      this.ctx.fillText(task.name, x + 5, y + height / 2 + 4);
      
      this.ctx.restore();
    });
  }
  
  /**
   * 绘制依赖连线
   */
  private renderDependencyLines(project: Project): void {
    const taskPositions = new Map<string, { x: number, y: number }>();
    
    // 记录任务位置
    project.tasks.forEach((task, index) => {
      const startDate = this.getProjectStartDate(project);
      const taskStart = this.getDaysBetween(startDate, task.startDate);
      const taskDuration = this.getDaysBetween(task.startDate, task.endDate);
      
      taskPositions.set(task.id, {
        x: this.config.leftMargin + (taskStart + taskDuration) * this.config.dayWidth,
        y: this.config.headerHeight + index * this.config.rowHeight + this.config.rowHeight / 2
      });
    });
    
    // 绘制连线
    this.ctx.save();
    this.ctx.strokeStyle = '#909399';
    this.ctx.lineWidth = 1;
    
    for (const dep of project.dependencies) {
      const from = taskPositions.get(dep.fromId);
      const to = taskPositions.get(dep.toId);
      
      if (from && to) {
        this.ctx.beginPath();
        this.ctx.moveTo(from.x, from.y);
        this.ctx.lineTo(to.x, to.y);
        this.ctx.stroke();
        
        // 绘制箭头
        this.drawArrow(this.ctx, from, to);
      }
    }
    
    this.ctx.restore();
  }
  
  /**
   * 绘制今天线
   */
  private renderTodayLine(): void {
    const today = new Date();
    const startDate = this.getProjectStartDate(this.project);
    const daysFromStart = this.getDaysBetween(startDate, today);
    
    const x = this.config.leftMargin + daysFromStart * this.config.dayWidth;
    
    this.ctx.save();
    this.ctx.strokeStyle = '#E6A23C';
    this.ctx.lineWidth = 2;
    this.ctx.setLineDash([5, 5]);
    
    this.ctx.beginPath();
    this.ctx.moveTo(x, 0);
    this.ctx.lineTo(x, this.ctx.canvas.height);
    this.ctx.stroke();
    
    this.ctx.restore();
  }
}

interface GanttConfig {
  rowHeight: number;
  dayWidth: number;
  headerHeight: number;
  leftMargin: number;
}
```

---

*（文档继续，包含更多章节...）*

## 🚀 第三部分：未来功能开发

### 3.1 云同步与实时协作

#### 3.1.1 WebSocket 实时通信

```typescript
/**
 * WebSocket 客户端：实时数据同步
 */
class RealtimeSync {
  private ws: WebSocket | null = null;
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 5;
  
  /**
   * 连接 WebSocket 服务器
   */
  connect(url: string): void {
    this.ws = new WebSocket(url);
    
    this.ws.onopen = () => {
      console.log('[RealtimeSync] Connected');
      this.reconnectAttempts = 0;
      this.sendAuth();
    };
    
    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      this.handleMessage(message);
    };
    
    this.ws.onerror = (error) => {
      console.error('[RealtimeSync] Error:', error);
    };
    
    this.ws.onclose = () => {
      console.log('[RealtimeSync] Disconnected');
      this.attemptReconnect();
    };
  }
  
  /**
   * 发送消息
   */
  send(type: string, data: any): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type, data }));
    }
  }
  
  /**
   * 处理接收到的消息
   */
  private handleMessage(message: any): void {
    switch (message.type) {
      case 'project_updated':
        this.handleProjectUpdate(message.data);
        break;
      case 'task_added':
        this.handleTaskAdded(message.data);
        break;
      case 'task_updated':
        this.handleTaskUpdated(message.data);
        break;
      // 更多消息类型...
    }
  }
  
  /**
   * 自动重连
   */
  private attemptReconnect(): void {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
      
      console.log(`[RealtimeSync] Reconnecting in ${delay}ms...`);
      setTimeout(() => this.connect(this.url), delay);
    }
  }
}
```

---

**本文档持续更新中，将涵盖所有技术领域...**






