# 项目集 Index 页面问题修复说明

## 修复日期
2025年10月13日

## 修复的问题

### 问题1：从模板创建的项目显示为空 ❌

#### 问题描述
在项目集编辑页面（`ProjectGroupIndex`），点击"添加项目" → "从模板创建"后，无法看到模板列表，或者创建的项目没有任务内容。

#### 根本原因
**模板分类名称不匹配**：
- `ProjectGroupIndex.ets` 中使用的分类：`'开发'`、`'营销'`、`'研究'`（中文）
- `TemplateService.ets` 中实际的分类：`'development'`、`'design'`、`'marketing'`（英文）

导致 `getTemplatesByCategory()` 无法找到任何模板。

#### 修复方案 ✅
修改 `ProjectGroupIndex.ets` 中的模板分类选择逻辑：

```typescript
// 修复前：
let category = '开发';
if (result.index === 0) category = '开发';
else if (result.index === 1) category = '营销';
else if (result.index === 2) category = '研究';

// 修复后：
let category = 'development';
if (result.index === 0) category = 'development';  // 软件开发
else if (result.index === 1) category = 'design';      // UI/UX设计
else if (result.index === 2) category = 'marketing';   // 营销活动
```

#### 可用的模板
修复后，用户可以选择以下模板：
- **软件开发**：
  - 移动应用开发（包含6个任务：需求分析、UI/UX设计、前端开发、后端开发、测试、发布）
  
- **UI/UX设计**：
  - 网站设计项目（包含5个任务：需求收集、信息架构、视觉设计、前端开发、测试发布）
  
- **营销活动**：
  - 营销活动策划（包含5个任务：目标设定、策略规划、内容创作、渠道执行、效果评估）

---

### 问题2：画布中的项目节点无法拖动移动 ❌

#### 问题描述
在项目集编辑页面，画布上显示的项目节点（ProjectRef）无法通过鼠标拖动来改变位置。

#### 根本原因
**缺少事件监听**：
- `ProjectGroupService` 在节点位置更新时会发出 `'project_ref_updated'` 事件
- 但 `ProjectGroupIndex.ets` 的事件监听器中没有监听这个事件
- 导致节点位置更新后，画布没有重新渲染

#### 修复方案 ✅
在 `setupEventListeners()` 方法中添加对 `'project_ref_updated'` 事件的监听：

```typescript
/**
 * 设置事件监听器
 */
private setupEventListeners(): void {
  // 监听项目集加载事件
  this.eventBus.on('project_group_loaded', () => {
    this.updateStateFromService();
    this.drawGraph();
  });

  // 监听项目集保存事件
  this.eventBus.on('project_group_saved', () => {
    this.updateStateFromService();
    this.drawGraph();
  });

  // 监听项目引用选择事件
  this.eventBus.on('project_ref_selected', () => {
    this.updateStateFromService();
    this.drawGraph();
  });

  // ✅ 新增：监听项目引用更新事件（用于节点移动后刷新画布）
  this.eventBus.on('project_ref_updated', () => {
    this.updateStateFromService();
    this.drawGraph();
  });
}
```

#### 事件流程
1. 用户拖动画布上的项目节点
2. `CanvasController` 触发 `handleTaskMove` 回调
3. `ProjectGroupIndex` 调用 `projectGroupService.getActions().moveProjectRef()`
4. `ProjectGroupService` 更新节点位置，并发出 `'project_ref_updated'` 事件
5. `ProjectGroupIndex` 监听到事件，调用 `drawGraph()` 重新渲染画布
6. ✅ 节点位置更新成功显示

---

## 修复文件清单

### 修改的文件
- ✅ `entry/src/main/ets/pages/ProjectGroupIndex.ets`

### 修改内容
1. **第938-974行**：修复模板分类名称（中文 → 英文）
2. **第196-220行**：添加 `'project_ref_updated'` 事件监听

---

## 测试验证

### 测试步骤1：模板创建功能
1. ✅ 打开项目集编辑页面
2. ✅ 点击"添加项目"按钮
3. ✅ 选择"从模板创建"
4. ✅ 选择项目类型（软件开发/UI/UX设计/营销活动）
5. ✅ 选择具体模板
6. ✅ 验证项目创建成功，包含预定义的任务

### 测试步骤2：节点拖动功能
1. ✅ 打开项目集编辑页面
2. ✅ 在画布上拖动任意项目节点
3. ✅ 验证节点位置实时更新
4. ✅ 验证拖动结束后位置保存成功
5. ✅ 刷新页面，验证节点位置持久化

---

## 相关技术说明

### 模板分类映射
| 显示名称 | 内部分类 | TemplateService 中的值 |
|---------|---------|----------------------|
| 软件开发 | development | `'development'` |
| UI/UX设计 | design | `'design'` |
| 营销活动 | marketing | `'marketing'` |
| 其他 | other | `'other'` |

### 事件驱动架构
```
用户操作 → UI 交互 → Service 业务逻辑 → EventBus 事件通知 → UI 更新
```

关键事件：
- `'project_group_loaded'`：项目集加载完成
- `'project_group_saved'`：项目集保存完成
- `'project_ref_selected'`：项目引用被选中
- ✅ `'project_ref_updated'`：项目引用信息更新（包括位置）
- `'project_ref_deleted'`：项目引用被删除

---

## 影响范围

### 用户体验改进
- ✅ 可以正常使用模板创建功能
- ✅ 画布节点支持拖动操作
- ✅ 项目集管理功能完整可用

### 系统稳定性
- ✅ 无新增编译错误
- ✅ 无破坏性更改
- ✅ 完全向后兼容

---

## 后续优化建议

### 短期优化
1. **模板分类统一**：考虑在全局配置文件中定义模板分类常量，避免硬编码
2. **错误提示优化**：当没有可用模板时，提供更友好的提示信息

### 长期优化
1. **自定义模板**：允许用户创建和保存自定义项目模板
2. **模板预览**：选择模板前可以预览模板的任务结构
3. **批量操作**：支持批量添加多个项目到项目集

---

## 修复总结

✅ **问题1已修复**：模板分类名称统一为英文，现在可以正常加载和使用模板创建项目

✅ **问题2已修复**：添加事件监听，画布节点现在可以正常拖动和移动

🎉 项目集管理功能现已完全可用！

