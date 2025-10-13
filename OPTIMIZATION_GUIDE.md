# EasyFlow 性能优化指南

## 📊 性能优化概述

本文档提供 EasyFlow 应用的性能优化建议和最佳实践，帮助确保应用在各种设备上流畅运行。

---

## 🎯 性能目标

### 核心指标
| 指标 | 目标值 | 当前值 | 状态 |
|------|--------|--------|------|
| 应用启动时间 | < 3s | ⚪ 待测 | - |
| Canvas 帧率 | 60fps | ⚪ 待测 | - |
| CPM 计算（100任务） | < 100ms | ⚪ 待测 | - |
| 内存占用（空项目） | < 100MB | ⚪ 待测 | - |
| 内存占用（100任务） | < 200MB | ⚪ 待测 | - |

---

## 🚀 优化清单

### 1. Canvas 渲染优化

#### 1.1 渲染节流 ✅
**当前实现**: CanvasRenderer.ets

```typescript
// 已实现：渲染节流（16ms = 60fps）
private throttleRender() {
  const now = Date.now();
  if (now - this.lastRenderTime < 16) {
    return;
  }
  this.lastRenderTime = now;
  this.render();
}
```

**优化建议**:
- ✅ 已实现节流机制
- ⚠️ 建议添加性能监控
- ⚠️ 考虑根据设备性能动态调整帧率

#### 1.2 离屏Canvas 🔶
**优化方案**:

```typescript
// 建议实现：复杂图形预渲染
class CanvasRenderer {
  private offscreenCanvas: OffscreenCanvas | null = null;
  
  // 预渲染任务节点
  private prerenderTaskNode(task: Task): ImageBitmap {
    if (!this.offscreenCanvas) {
      this.offscreenCanvas = new OffscreenCanvas(200, 100);
    }
    
    const ctx = this.offscreenCanvas.getContext('2d');
    // 绘制任务节点
    this.drawTaskNode(ctx, task);
    
    // 返回 ImageBitmap 供重复使用
    return this.offscreenCanvas.transferToImageBitmap();
  }
  
  // 主Canvas使用预渲染图像
  private renderFromCache(ctx: CanvasRenderingContext2D, task: Task) {
    const cached = this.nodeCache.get(task.id);
    if (cached) {
      ctx.drawImage(cached, task.x, task.y);
    }
  }
}
```

**收益**:
- 减少重复绘制 30-40%
- 提升大型项目渲染速度
- 降低 CPU 使用率

#### 1.3 脏矩形优化 🔶
**优化方案**:

```typescript
// 建议实现：只重绘变化区域
class CanvasRenderer {
  private dirtyRects: Rect[] = [];
  
  markDirty(rect: Rect) {
    this.dirtyRects.push(rect);
  }
  
  render() {
    if (this.dirtyRects.length === 0) {
      return; // 无变化，不重绘
    }
    
    // 只清除和重绘脏区域
    this.dirtyRects.forEach(rect => {
      this.ctx.clearRect(rect.x, rect.y, rect.width, rect.height);
      this.renderRegion(rect);
    });
    
    this.dirtyRects = [];
  }
}
```

**收益**:
- 减少不必要的重绘 50-60%
- 静态场景几乎零开销
- 动画更流畅

#### 1.4 图层分离 🔶
**优化方案**:

```typescript
// 建议实现：静态和动态内容分层
class MultiLayerCanvas {
  private backgroundLayer: Canvas; // 背景网格（静态）
  private taskLayer: Canvas;       // 任务节点（较少变化）
  private connectionLayer: Canvas; // 连线（中等变化）
  private interactionLayer: Canvas; // 交互高亮（频繁变化）
  
  render() {
    // 背景层：只在初始化或缩放时绘制
    if (this.backgroundDirty) {
      this.renderBackground();
      this.backgroundDirty = false;
    }
    
    // 任务层：任务修改时绘制
    if (this.tasksDirty) {
      this.renderTasks();
      this.tasksDirty = false;
    }
    
    // 连线层：依赖变化时绘制
    if (this.connectionsDirty) {
      this.renderConnections();
      this.connectionsDirty = false;
    }
    
    // 交互层：每帧绘制（如拖拽、高亮）
    this.renderInteractions();
  }
}
```

**收益**:
- 减少全局重绘频率
- 提升复杂场景性能 2-3倍
- 支持更大规模项目

---

### 2. CPM 算法优化

#### 2.1 拓扑排序优化 ✅
**当前实现**: CriticalPathService.ets

```typescript
// 已实现：Kahn算法 O(V+E)
private topologicalSort(tasks: Task[], dependencies: Dependency[]): Task[] {
  // 使用队列实现，时间复杂度 O(V+E)
}
```

**状态**: ✅ 已优化

#### 2.2 结果缓存 🔶
**优化方案**:

```typescript
// 建议实现：缓存计算结果
class CriticalPathService {
  private cache: Map<string, CPMResult> = new Map();
  private projectHash: string = '';
  
  calculate(tasks: Task[], dependencies: Dependency[]): CPMResult {
    // 计算项目哈希
    const hash = this.computeHash(tasks, dependencies);
    
    // 如果数据未变化，返回缓存
    if (hash === this.projectHash && this.cache.has(hash)) {
      return this.cache.get(hash)!;
    }
    
    // 重新计算
    const result = this.performCalculation(tasks, dependencies);
    
    // 更新缓存
    this.projectHash = hash;
    this.cache.set(hash, result);
    
    return result;
  }
  
  private computeHash(tasks: Task[], dependencies: Dependency[]): string {
    // 只基于任务ID、工期和依赖计算哈希
    return JSON.stringify({
      tasks: tasks.map(t => ({ id: t.id, duration: t.duration })),
      deps: dependencies
    });
  }
}
```

**收益**:
- 避免重复计算
- 响应速度提升 10-100倍
- UI 操作更流畅

#### 2.3 增量计算 🔶
**优化方案**:

```typescript
// 建议实现：只重新计算受影响的任务
class IncrementalCPM {
  updateTaskDuration(taskId: string, newDuration: number) {
    // 1. 找到受影响的任务（后继任务）
    const affected = this.findAffectedTasks(taskId);
    
    // 2. 只重新计算这些任务
    this.recalculateTasks(affected);
    
    // 3. 更新关键路径（可能只需部分更新）
    this.updateCriticalPath(affected);
  }
}
```

**收益**:
- 单次修改响应时间从 O(V+E) 降到 O(k)，k为受影响任务数
- 大型项目性能提升 5-10倍

---

### 3. 数据处理优化

#### 3.1 序列化优化 🔶
**优化方案**:

```typescript
// 当前实现：JSON.stringify/parse
export class ExportService {
  exportToJSON(project: Project): string {
    return JSON.stringify(project);
  }
}

// 优化建议：增量序列化和压缩
export class OptimizedExportService {
  exportToJSON(project: Project): string {
    // 1. 只序列化必要字段
    const minimal = this.minimizeProject(project);
    
    // 2. 压缩数据（可选）
    const compressed = this.compress(JSON.stringify(minimal));
    
    return compressed;
  }
  
  private minimizeProject(project: Project): object {
    return {
      id: project.id,
      name: project.name,
      tasks: project.tasks.map(t => ({
        id: t.id,
        name: t.name,
        duration: t.duration,
        // 省略计算字段（ES/LS/TF）
      })),
      dependencies: project.dependencies
    };
  }
}
```

**收益**:
- 导出文件大小减少 30-50%
- 导出速度提升 20-30%
- 网络传输更快（未来云同步）

#### 3.2 批量操作优化 🔶
**优化方案**:

```typescript
// 当前：逐个操作
tasks.forEach(task => {
  projectManager.addTask(projectId, task);
  projectManager.recalculateCPM(); // 每次都重算！
});

// 优化：批量操作，最后统一计算
class ProjectManager {
  addTasksBatch(projectId: string, tasks: Task[]) {
    tasks.forEach(task => {
      this.addTaskWithoutRecalc(task);
    });
    
    // 所有任务添加完后，统一计算一次
    this.recalculateCPM();
  }
}
```

**收益**:
- 批量导入速度提升 10-20倍
- 减少不必要的计算

---

### 4. 内存优化

#### 4.1 对象池 🔶
**优化方案**:

```typescript
// 建议实现：复用对象减少 GC
class ObjectPool<T> {
  private pool: T[] = [];
  private createFn: () => T;
  
  constructor(createFn: () => T, initialSize: number = 10) {
    this.createFn = createFn;
    for (let i = 0; i < initialSize; i++) {
      this.pool.push(createFn());
    }
  }
  
  acquire(): T {
    return this.pool.pop() || this.createFn();
  }
  
  release(obj: T) {
    this.pool.push(obj);
  }
}

// 使用示例
const pointPool = new ObjectPool(() => ({ x: 0, y: 0 }), 100);

function calculatePath() {
  const point = pointPool.acquire();
  // 使用 point...
  pointPool.release(point); // 归还对象
}
```

**收益**:
- 减少对象创建 50-70%
- 降低 GC 压力
- 提升帧率稳定性

#### 4.2 及时释放 ✅
**最佳实践**:

```typescript
// 组件卸载时清理资源
@Component
struct TaskEditor {
  private subscription: Subscription | null = null;
  
  aboutToAppear() {
    this.subscription = eventBus.subscribe(...);
  }
  
  aboutToDisappear() {
    // ✅ 及时释放
    this.subscription?.unsubscribe();
    this.subscription = null;
  }
}
```

#### 4.3 大对象压缩 🔶
**优化方案**:

```typescript
// 不必要的大对象
interface Task {
  id: string;
  name: string;
  longDescription: string; // 可能很长
  customData: object;      // 可能很大
  // ...
}

// 优化：按需加载
interface Task {
  id: string;
  name: string;
  descriptionRef: string;  // 引用ID
  customDataRef: string;   // 引用ID
}

// 详情数据单独存储，按需加载
class TaskDetailStore {
  private details: Map<string, TaskDetail> = new Map();
  
  getDetail(taskId: string): TaskDetail | null {
    return this.details.get(taskId) || null;
  }
}
```

**收益**:
- 内存占用减少 30-50%
- 大型项目加载更快

---

### 5. UI 优化

#### 5.1 虚拟滚动 🔶
**优化方案**:

```typescript
// 大量任务列表使用虚拟滚动
@Component
struct VirtualTaskList {
  @State visibleTasks: Task[] = [];
  private allTasks: Task[] = [];
  
  private onScroll(offset: number) {
    // 只渲染可见区域的任务
    const startIndex = Math.floor(offset / ITEM_HEIGHT);
    const endIndex = startIndex + VISIBLE_COUNT;
    this.visibleTasks = this.allTasks.slice(startIndex, endIndex);
  }
  
  build() {
    List() {
      ForEach(this.visibleTasks, (task: Task) => {
        ListItem() {
          TaskCard({ task })
        }
      })
    }
    .onScroll(this.onScroll.bind(this))
  }
}
```

**收益**:
- 大列表渲染速度提升 10-100倍
- 内存占用降低 80-90%

#### 5.2 防抖和节流 ✅
**当前实现**: 已在多处使用

```typescript
// ✅ 输入防抖
private searchDebounced = debounce((keyword: string) => {
  this.performSearch(keyword);
}, 300);

// ✅ 滚动节流
private onScrollThrottled = throttle(() => {
  this.updateVisibleItems();
}, 16);
```

**状态**: ✅ 已优化

#### 5.3 懒加载 🔶
**优化方案**:

```typescript
// 图片懒加载
@Component
struct LazyImage {
  @State loaded: boolean = false;
  @Prop src: string;
  
  aboutToAppear() {
    // 延迟加载
    setTimeout(() => {
      this.loaded = true;
    }, 100);
  }
  
  build() {
    if (this.loaded) {
      Image(this.src)
    } else {
      // 占位符
      Text('加载中...')
    }
  }
}
```

---

### 6. 数据库优化

#### 6.1 索引优化 ⚪
**未来优化**（如果使用数据库）:

```sql
-- 为常用查询添加索引
CREATE INDEX idx_project_updated ON projects(updated_at DESC);
CREATE INDEX idx_task_project ON tasks(project_id);
CREATE INDEX idx_task_status ON tasks(status);
```

#### 6.2 批量写入 ⚪
**未来优化**:

```typescript
// 事务批量写入
db.transaction(() => {
  tasks.forEach(task => {
    db.insert('tasks', task);
  });
});
```

---

## 📊 性能监控

### 1. 性能监控代码

```typescript
// 性能监控服务
export class PerformanceMonitor {
  private metrics: Map<string, number[]> = new Map();
  
  // 记录操作耗时
  measure(name: string, fn: () => void) {
    const start = performance.now();
    fn();
    const duration = performance.now() - start;
    
    if (!this.metrics.has(name)) {
      this.metrics.set(name, []);
    }
    this.metrics.get(name)!.push(duration);
    
    // 如果超过阈值，记录警告
    if (duration > 100) {
      console.warn(`Performance warning: ${name} took ${duration}ms`);
    }
  }
  
  // 获取统计数据
  getStats(name: string) {
    const values = this.metrics.get(name) || [];
    return {
      count: values.length,
      avg: values.reduce((a, b) => a + b, 0) / values.length,
      max: Math.max(...values),
      min: Math.min(...values)
    };
  }
}

// 使用示例
const monitor = new PerformanceMonitor();

monitor.measure('CPM计算', () => {
  cpmService.calculate(tasks, dependencies);
});

monitor.measure('Canvas渲染', () => {
  canvasRenderer.render(project);
});
```

### 2. 关键指标记录

```typescript
// 在关键位置添加监控
class ProjectManager {
  addTask(projectId: string, task: Task) {
    performanceMonitor.measure('添加任务', () => {
      this.performAddTask(projectId, task);
    });
  }
  
  recalculateCPM() {
    performanceMonitor.measure('CPM重算', () => {
      this.performCPMCalculation();
    });
  }
}
```

---

## ✅ 优化优先级

### 第一优先级（本周完成）
1. ✅ Canvas 渲染节流（已完成）
2. 🔶 CPM 结果缓存
3. 🔶 批量操作优化
4. 🔶 性能监控添加

### 第二优先级（下周完成）
1. 🔶 离屏Canvas
2. 🔶 脏矩形优化
3. 🔶 虚拟滚动
4. 🔶 对象池

### 第三优先级（未来版本）
1. ⚪ 图层分离
2. ⚪ 增量计算
3. ⚪ 数据压缩
4. ⚪ 按需加载

---

## 📝 性能测试清单

- [ ] 应用启动时间 < 3s
- [ ] Canvas 60fps 流畅渲染
- [ ] 100任务CPM计算 < 100ms
- [ ] 100任务导出 < 500ms
- [ ] 100任务导入 < 1s
- [ ] 内存占用合理（< 200MB）
- [ ] 无内存泄漏
- [ ] 大项目无卡顿

---

**更新日期**: 2024-10-13
**版本**: 1.0

