# 贡献指南 / Contributing Guide

感谢您对 EasyFlow 项目的关注！我们欢迎任何形式的贡献。

## 📋 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发流程](#开发流程)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [测试要求](#测试要求)

## 🤝 行为准则

本项目采用 [Contributor Covenant](https://www.contributor-covenant.org/) 行为准则。参与本项目即表示您同意遵守其条款。

### 我们的承诺
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 专注于对社区最有利的事情
- 对其他社区成员表示同理心

## 🎯 如何贡献

### 报告 Bug
1. 检查 [Issues](https://github.com/your-username/EasyFlow/issues) 是否已有类似问题
2. 如果没有，创建新 Issue
3. 使用清晰的标题和详细的描述
4. 提供复现步骤
5. 包含设备信息、HarmonyOS 版本等

**Bug 报告模板**：
```markdown
**问题描述**
简要描述问题

**复现步骤**
1. 打开应用
2. 点击...
3. 看到错误

**期望行为**
应该发生什么

**实际行为**
实际发生了什么

**环境信息**
- 设备：华为 Mate 60 Pro
- HarmonyOS 版本：4.0.0
- 应用版本：1.0.0

**截图**
如果适用，添加截图
```

### 功能建议
1. 检查是否已有类似建议
2. 描述功能的使用场景
3. 说明为什么这个功能有价值
4. 如果可能，提供设计方案

**功能建议模板**：
```markdown
**功能描述**
简要说明建议的功能

**使用场景**
这个功能解决什么问题？

**解决方案**
你期望的实现方式

**替代方案**
考虑过的其他方案

**其他信息**
任何其他相关信息
```

### 提交代码
1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/AmazingFeature`）
3. 提交更改（`git commit -m 'feat: add amazing feature'`）
4. 推送到分支（`git push origin feature/AmazingFeature`）
5. 创建 Pull Request

## 🔧 开发流程

### 1. 环境准备
```bash
# 克隆仓库
git clone https://github.com/your-username/EasyFlow.git
cd EasyFlow

# 安装依赖
npm install

# 使用 DevEco Studio 打开项目
# File -> Open -> 选择项目目录
```

### 2. 分支策略
- `main`: 稳定的生产版本
- `develop`: 开发分支
- `feature/*`: 新功能开发
- `bugfix/*`: Bug 修复
- `hotfix/*`: 紧急修复
- `release/*`: 发布准备

### 3. 开发步骤
1. 从 `develop` 创建功能分支
2. 开发并测试功能
3. 提交代码并推送
4. 创建 PR 到 `develop`
5. 代码审查
6. 合并到 `develop`

### 4. 发布流程
1. 从 `develop` 创建 `release/x.x.x` 分支
2. 更新版本号和文档
3. 测试验证
4. 合并到 `main` 和 `develop`
5. 打标签 `vx.x.x`

## 📝 代码规范

### ArkTS 代码风格

#### 命名规范
```typescript
// ✅ 类名：PascalCase
class ProjectManager { }

// ✅ 方法名：camelCase
calculateCriticalPath() { }

// ✅ 常量：UPPER_SNAKE_CASE
const MAX_ZOOM_SCALE = 3.0

// ✅ 私有变量：下划线前缀
private _projectList: Project[] = []

// ✅ 接口：PascalCase，I 前缀（可选）
interface ICommand { }
```

#### 文件组织
```typescript
// 1. 导入语句（按类型分组）
// 系统 API
import router from '@ohos.router'
import preferences from '@ohos.data.preferences'

// 本地模块
import { ProjectManager } from '../core/ProjectManager'
import { Task } from '../model/ProjectData'

// 2. 类型定义
interface TaskOptions {
  name: string
  duration: number
}

// 3. 类实现
export class TaskService {
  // 私有属性
  private _tasks: Task[] = []
  
  // 公共属性
  public taskCount: number = 0
  
  // 构造函数
  constructor() { }
  
  // 公共方法
  public addTask(task: Task): void { }
  
  // 私有方法
  private validateTask(task: Task): boolean { }
}
```

#### 注释规范
```typescript
/**
 * 计算项目关键路径
 * 
 * 使用 CPM 算法，通过正向和反向传递计算每个任务的时间参数，
 * 识别总浮动时间为 0 的关键路径。
 * 
 * @param tasks 任务列表，必须包含依赖关系
 * @returns 关键路径上的任务 ID 数组
 * @throws {Error} 如果存在循环依赖
 * 
 * @example
 * ```typescript
 * const service = new CriticalPathService()
 * const criticalPath = service.calculate(tasks)
 * console.log(`关键任务数：${criticalPath.length}`)
 * ```
 */
calculateCriticalPath(tasks: Task[]): string[] {
  // 实现代码...
}
```

### UI 组件规范

```typescript
@Component
export struct TaskCard {
  // Props（使用装饰器）
  @ObjectLink task: Task
  @State private isExpanded: boolean = false
  
  // 生命周期
  aboutToAppear() {
    // 初始化逻辑
  }
  
  // 构建方法
  build() {
    Column() {
      // UI 代码，保持简洁
      // 复杂逻辑抽取到方法中
    }
  }
  
  // 辅助方法
  private handleClick(): void {
    // 事件处理
  }
}
```

## 📊 提交规范

### Commit Message 格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具相关
- `revert`: 回滚

### Scope 范围
- `cpm`: CPM 算法
- `canvas`: Canvas 渲染
- `ui`: UI 组件
- `service`: 服务层
- `data`: 数据模型
- `import`: 导入功能
- `export`: 导出功能

### 示例
```bash
# 新功能
feat(cpm): 添加浮动时间计算

实现 TF = LS - ES 的计算逻辑
- 添加关键任务识别
- 更新 Canvas 渲染显示 TF 值

Closes #123

# Bug 修复
fix(canvas): 修复缩放时节点位置偏移

在缩放操作时，节点位置计算错误导致显示偏移
现已修正坐标转换逻辑

Fixes #456

# 文档更新
docs(readme): 更新安装说明

添加 DevEco Studio 版本要求说明
```

## 🧪 测试要求

### 单元测试
```typescript
import { describe, it, expect } from '@ohos/hypium'
import { CriticalPathService } from '../main/ets/services/CriticalPathService'

describe('CriticalPathService', () => {
  it('应该正确计算简单项目的关键路径', () => {
    const service = new CriticalPathService()
    const tasks = [
      { id: '1', name: 'A', duration: 3, dependencies: [] },
      { id: '2', name: 'B', duration: 2, dependencies: ['1'] },
      { id: '3', name: 'C', duration: 4, dependencies: ['1'] }
    ]
    const result = service.calculate(tasks)
    expect(result.criticalPath).toContain('1')
    expect(result.criticalPath).toContain('3')
  })
  
  it('应该检测循环依赖', () => {
    const service = new CriticalPathService()
    const tasks = [
      { id: '1', dependencies: ['2'] },
      { id: '2', dependencies: ['1'] }
    ]
    expect(() => service.calculate(tasks)).toThrow()
  })
})
```

### 测试覆盖率要求
- 核心算法（CPM、拓扑排序）：> 90%
- 业务逻辑（ProjectManager、Services）：> 80%
- UI 组件：> 60%
- 整体：> 70%

### 运行测试
```bash
# 运行所有测试
npm test

# 运行特定测试
npm test -- --test-file CriticalPathService.test.ets

# 生成覆盖率报告
npm run test:coverage
```

## 📋 Pull Request 检查清单

提交 PR 前，请确保：

- [ ] 代码遵循项目规范
- [ ] 添加了必要的注释
- [ ] 更新了相关文档
- [ ] 添加了测试用例
- [ ] 所有测试通过
- [ ] 提交信息符合规范
- [ ] PR 描述清晰

## ❓ 常见问题

### Q: 如何运行项目？
A: 使用 DevEco Studio 打开项目，连接设备或模拟器，点击 Run。

### Q: 提交前需要做什么？
A: 确保代码符合规范，测试通过，提交信息清晰。

### Q: PR 多久会被审查？
A: 通常在 1-3 个工作日内。

### Q: 可以直接提交到 main 分支吗？
A: 不可以。请提交到 develop 分支。

## 📞 联系方式

- **Issue**: [GitHub Issues](https://github.com/your-username/EasyFlow/issues)
- **Discussion**: [GitHub Discussions](https://github.com/your-username/EasyFlow/discussions)
- **Email**: your-email@example.com

---

再次感谢您的贡献！🎉

