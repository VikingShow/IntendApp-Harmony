# EasyFlow - 一思不漏

<div align="center">
  <img src="AppScope/resources/base/media/app_foreground.png" alt="EasyFlow Logo" width="120" height="120">
  
  **融合备忘录时间维度与思维导图逻辑维度的专业项目管理应用**
  
  [![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0+-blue.svg)](https://developer.harmonyos.com/)
  [![ArkTS](https://img.shields.io/badge/ArkTS-Latest-green.svg)](https://developer.harmonyos.com/cn/develop/arkts/)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
</div>

## 项目简介

**EasyFlow（一思不漏）** 是一款专为HarmonyOS平台开发的专业项目管理应用，巧妙融合了备忘录的时间维度任务管理和思维导图的逻辑维度任务管理理念。应用集成了关键路径法（CPM）算法、可视化进度网络图、智能统计分析等核心功能，通过将传统项目管理的科学性与现代移动端交互的便捷性完美结合，让复杂的项目管理变得简单直观，真正做到"一思不漏"。

---

## ✨ 核心功能

### 🎯 智能关键路径分析
- **关键路径法（CPM）算法**：自动计算项目关键路径，识别影响进度的关键任务
- **任务依赖关系管理**：支持复杂任务依赖关系，智能检测循环依赖
- **项目工期优化**：通过关键路径分析，帮助用户合理分配资源和时间

### 🎨 可视化项目管理
- **交互式进度网络图**：采用Canvas 2D渲染技术，直观展示任务节点和依赖关系
- **拖拽式任务编辑**：支持拖拽操作的任务创建、编辑和位置调整
- **实时进度跟踪**：动态显示项目完成度和任务状态，包含时间进度条和完成度进度条

### 📊 智能统计分析
- **多维度数据统计**：项目进度、任务完成率、时间分布等多角度分析
- **历史数据追踪**：记录项目历史数据，支持趋势分析和改进建议
- **分类管理**：支持多项目并行管理，提供全局统计视图

### 🚀 模板化项目管理
- **预设项目模板**：内置移动应用开发、网站设计、营销活动策划等模板
- **自定义模板**：支持用户创建和保存个性化项目模板
- **模板分享**：支持模板导入导出，便于团队协作

### 🔒 数据安全与备份
- **本地数据存储**：采用HarmonyOS文件系统API，确保数据安全
- **数据导入导出**：支持项目数据的备份和迁移
- **权限管理**：完善的权限申请机制，保护用户隐私

---

## 🚀 快速开始

### 环境要求

- [DevEco Studio](https://developer.harmonyos.com/cn/develop/deveco-studio/) 4.0+（建议最新版）
- HarmonyOS SDK API 10+
- 支持HarmonyOS的设备或模拟器

### 安装与运行

1. **克隆项目**
   ```bash
   git clone https://github.com/your-username/EasyFlow.git
   cd EasyFlow
   ```

2. **使用 DevEco Studio 打开项目**
   - 启动 DevEco Studio
   - 选择 "Open" 并选择项目根目录
   - 等待项目同步完成

3. **配置设备**
   - 连接HarmonyOS设备或启动模拟器
   - 确保设备已开启开发者模式和USB调试

4. **构建与运行**
   - 点击工具栏的 "Run" 按钮
   - 或使用快捷键 `Shift + F10`
   - 应用将自动安装到设备并启动

### 构建配置

项目采用 Hvigor 构建系统，主要配置文件：
- `hvigorfile.ts` - 构建脚本配置
- `build-profile.json5` - 构建参数配置
- `oh-package.json5` - 项目依赖配置

---

## 📁 项目结构

```
EasyFlow/
├── AppScope/                   # 应用级配置
│   ├── app.json5              # 应用配置
│   └── resources/             # 应用级资源
├── entry/                     # 主模块
│   ├── src/main/
│   │   ├── ets/              # 主要业务代码
│   │   │   ├── components/   # UI组件
│   │   │   │   ├── ActionButtons.ets
│   │   │   │   ├── DashboardView.ets
│   │   │   │   ├── Sidebar.ets
│   │   │   │   ├── TaskEditor.ets
│   │   │   │   └── ...
│   │   │   ├── core/         # 核心业务逻辑
│   │   │   │   ├── AppState.ets
│   │   │   │   ├── CanvasController.ets
│   │   │   │   ├── CanvasRenderer.ets
│   │   │   │   ├── ProjectManager.ets
│   │   │   │   └── ...
│   │   │   ├── model/        # 数据模型
│   │   │   │   └── ProjectData.ets
│   │   │   ├── pages/        # 页面
│   │   │   │   ├── Home.ets
│   │   │   │   └── Index.ets
│   │   │   ├── services/     # 业务服务
│   │   │   │   ├── CriticalPathService.ets
│   │   │   │   ├── StorageService.ets
│   │   │   │   ├── TemplateService.ets
│   │   │   │   └── ...
│   │   │   └── utils/        # 工具类
│   │   ├── resources/        # 资源文件
│   │   └── module.json5      # 模块配置
│   ├── build-profile.json5   # 构建配置
│   └── hvigorfile.ts         # 构建脚本
├── hvigor/                   # 构建工具配置
├── oh-package.json5         # 项目依赖
└── README.md               # 项目说明
```

---

## 🎯 核心组件说明

### 📱 主要页面
- **Home.ets** - 项目列表首页，展示所有项目概览和统计信息
- **Index.ets** - 项目详情页，提供可视化任务编辑和关键路径分析

### 🧩 核心组件
- **DashboardView** - 项目概览仪表板，显示项目统计和即将到期任务
- **Sidebar** - 侧边栏，提供任务管理、项目设置等功能
- **TaskEditor** - 任务编辑器，支持任务属性和检查清单编辑
- **TemplateDialog** - 模板选择对话框，快速创建项目
- **LoadingView** - 加载状态组件，提供友好的加载提示

### 🔧 核心服务
- **ProjectManager** - 项目管理核心服务，统一管理项目状态和操作
- **CriticalPathService** - 关键路径计算服务，实现CPM算法
- **CanvasController** - 画布控制器，处理用户交互和手势操作
- **CanvasRenderer** - 画布渲染器，负责可视化网络图的绘制
- **StorageService** - 存储服务，管理项目数据的持久化
- **TemplateService** - 模板服务，提供项目模板管理功能

---

## 📖 使用指南

### 🆕 创建项目
1. 在首页点击右上角的"+"按钮
2. 选择"空白项目"或从模板创建
3. 输入项目名称，选择项目分类
4. 点击"创建"完成项目创建

### ✏️ 编辑任务
1. 进入项目详情页
2. 点击任务节点进行编辑
3. 设置任务名称、开始时间、结束时间
4. 添加检查清单项目
5. 通过拖拽调整任务位置

### 🔗 建立依赖关系
1. 选中源任务节点
2. 点击"开始连接"按钮
3. 点击目标任务节点
4. 系统自动建立依赖关系并计算关键路径

### 📊 查看统计信息
1. 在首页查看项目概览统计
2. 进入项目详情页查看详细进度
3. 关键任务会以红色边框标识
4. 进度条显示时间和完成度

### 💾 数据管理
1. 项目数据自动保存到本地
2. 支持项目数据导出备份
3. 支持从备份文件恢复项目
4. 数据迁移服务确保版本升级兼容性

---

## ❓ 常见问题

### 🔄 项目切换
**Q: 如何切换不同的项目？**
A: 在首页点击项目列表中的项目卡片即可切换到该项目。

### 🎨 模板自定义
**Q: 如何添加自定义项目模板？**
A: 可以在 `entry/src/main/ets/services/TemplateService.ets` 文件中添加新的模板定义。

### 💾 数据安全
**Q: 项目数据会丢失吗？**
A: 应用采用本地持久化存储，支持自动保存和手动备份，数据安全性有保障。

### 📱 设备支持
**Q: 支持哪些设备？**
A: 支持HarmonyOS手机、平板、2合1设备等多种终端，提供一致的用户体验。

### 🔧 关键路径计算
**Q: 关键路径是如何计算的？**
A: 应用使用关键路径法（CPM）算法，通过正向传递和反向传递计算每个任务的时间参数，自动识别关键路径。

### 📊 进度统计
**Q: 项目进度是如何计算的？**
A: 基于任务检查清单的完成情况计算整体进度，同时显示时间进度和完成度进度。

---

## 🛠️ 技术栈

### 核心技术
- **ArkTS** - HarmonyOS原生开发语言
- **ArkUI** - 声明式UI框架
- **Canvas 2D** - 可视化图形渲染
- **Hvigor** - HarmonyOS官方构建工具

### HarmonyOS API
- **@ohos.router** - 页面路由导航
- **@ohos.file.fs** - 文件系统操作
- **@ohos.app.ability.common** - 应用上下文管理
- **@ohos.promptAction** - 用户提示操作

### 架构设计
- **分层架构** - 表现层、业务层、数据层分离
- **服务容器** - 统一的服务管理和依赖注入
- **响应式数据** - 基于@Observed的数据绑定
- **事件总线** - 组件间通信机制

### 算法实现
- **关键路径法（CPM）** - 项目进度管理算法
- **拓扑排序** - 任务依赖关系处理
- **循环检测** - 依赖关系验证算法

---

## 🤝 贡献指南

我们欢迎所有形式的贡献！无论是功能建议、Bug报告还是代码贡献。

### 如何贡献
1. **Fork** 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 **Pull Request**

### 报告问题
如果您发现了Bug或有功能建议，请通过 [Issues](https://github.com/your-username/EasyFlow/issues) 提交。

### 开发规范
- 遵循ArkTS编码规范
- 添加适当的注释和文档
- 确保代码通过所有测试
- 更新相关文档

---


<div align="center">
  <p>如果这个项目对您有帮助，请给我们一个 ⭐️</p>
  <p>让项目管理变得简单，让工作效率更高！</p>
</div>
