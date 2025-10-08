# EasyFlow - 一思不漏

<div align="center">
  <img src="AppScope/resources/base/media/app_foreground.png" alt="EasyFlow Logo" width="120" height="120">
  
  **融合备忘录时间维度与思维导图逻辑维度的专业项目管理应用**
  
  [![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0+-blue.svg)](https://developer.harmonyos.com/)
  [![ArkTS](https://img.shields.io/badge/ArkTS-Latest-green.svg)](https://developer.harmonyos.com/cn/develop/arkts/)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
  [![Version](https://img.shields.io/badge/Version-1.0.0-orange.svg)](https://github.com/your-username/EasyFlow/releases)
  [![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com/your-username/EasyFlow/actions)
</div>

## 📋 项目简介

**EasyFlow（一思不漏）** 是一款专为HarmonyOS平台开发的专业项目管理应用，巧妙融合了备忘录的时间维度任务管理和思维导图的逻辑维度任务管理理念。应用集成了关键路径法（CPM）算法、可视化进度网络图、智能统计分析等核心功能，通过将传统项目管理的科学性与现代移动端交互的便捷性完美结合，让复杂的项目管理变得简单直观，真正做到"一思不漏"。

### 🎯 核心价值
- **科学管理**：基于关键路径法（CPM）的专业项目管理算法
- **直观可视**：Canvas 2D渲染的交互式项目网络图
- **智能分析**：自动识别关键任务和项目风险点
- **高效协作**：支持多项目并行管理和团队协作
- **数据安全**：本地存储，支持数据备份和迁移

---

## ✨ 核心功能

### 🎯 智能关键路径分析
- **关键路径法（CPM）算法**：自主研发的关键路径计算引擎，自动识别影响项目进度的关键任务
- **任务依赖关系管理**：支持复杂任务依赖关系，智能检测循环依赖，确保项目逻辑正确性
- **项目工期优化**：通过关键路径分析，帮助用户合理分配资源和时间，提高项目执行效率
- **浮动时间计算**：精确计算任务浮动时间，为项目调度提供科学依据

### 🎨 可视化项目管理
- **交互式进度网络图**：采用Canvas 2D渲染技术，直观展示任务节点和依赖关系
- **拖拽式任务编辑**：支持拖拽操作的任务创建、编辑和位置调整，操作简单直观
- **实时进度跟踪**：动态显示项目完成度和任务状态，包含时间进度条和完成度进度条
- **关键任务高亮**：自动标识关键路径上的任务，帮助用户聚焦重要工作

### 📊 智能统计分析
- **多维度数据统计**：项目进度、任务完成率、时间分布等多角度分析
- **历史数据追踪**：记录项目历史数据，支持趋势分析和改进建议
- **分类管理**：支持多项目并行管理，提供全局统计视图
- **性能监控**：实时监控项目执行效率，提供优化建议

### 🚀 模板化项目管理
- **预设项目模板**：内置移动应用开发、网站设计、营销活动策划等专业模板
- **自定义模板**：支持用户创建和保存个性化项目模板
- **模板分享**：支持模板导入导出，便于团队协作和知识传承
- **快速启动**：基于模板快速创建项目，大幅提升项目启动效率

### 🔒 数据安全与备份
- **本地数据存储**：采用HarmonyOS文件系统API，确保数据安全性和隐私保护
- **数据导入导出**：支持项目数据的备份和迁移，防止数据丢失
- **权限管理**：完善的权限申请机制，保护用户隐私和数据安全
- **版本兼容**：支持数据格式升级和版本迁移，确保长期使用

---

## 🚀 快速开始

### 📋 环境要求

- **开发工具**：[DevEco Studio](https://developer.harmonyos.com/cn/develop/deveco-studio/) 4.0+（建议最新版）
- **SDK版本**：HarmonyOS SDK API 10+
- **运行环境**：支持HarmonyOS的设备或模拟器
- **系统要求**：HarmonyOS 4.0+ 或更高版本

### 📥 安装与运行

1. **克隆项目**
   ```bash
   git clone https://github.com/your-username/EasyFlow.git
   cd EasyFlow
   ```

2. **使用 DevEco Studio 打开项目**
   - 启动 DevEco Studio
   - 选择 "Open" 并选择项目根目录
   - 等待项目同步完成（首次同步可能需要几分钟）

3. **配置设备**
   - 连接HarmonyOS设备或启动模拟器
   - 确保设备已开启开发者模式和USB调试
   - 在DevEco Studio中配置设备连接

4. **构建与运行**
   - 点击工具栏的 "Run" 按钮
   - 或使用快捷键 `Shift + F10`
   - 应用将自动安装到设备并启动

### ⚙️ 构建配置

项目采用 Hvigor 构建系统，主要配置文件：
- `hvigorfile.ts` - 构建脚本配置
- `build-profile.json5` - 构建参数配置
- `oh-package.json5` - 项目依赖配置

### 🔧 开发环境配置

1. **安装依赖**
   ```bash
   # 安装项目依赖
   npm install
   
   # 或使用yarn
   yarn install
   ```

2. **配置模拟器**
   - 在DevEco Studio中创建HarmonyOS模拟器
   - 推荐使用API 10+的模拟器版本
   - 确保模拟器有足够的存储空间

3. **调试配置**
   - 启用开发者选项
   - 开启USB调试模式
   - 配置网络代理（如需要）

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
1. **快速创建**：在首页点击右上角的"+"按钮，选择"空白项目"
2. **模板创建**：选择"选择模板"，从预设模板中快速创建项目
3. **项目配置**：输入项目名称，选择项目分类（开发/设计/营销等）
4. **确认创建**：点击"创建"按钮完成项目创建

### ✏️ 编辑任务
1. **进入编辑**：进入项目详情页，点击任务节点进行编辑
2. **基本信息**：设置任务名称、开始时间、结束时间
3. **检查清单**：添加详细的检查清单项目，细化任务内容
4. **位置调整**：通过拖拽操作调整任务在画布上的位置
5. **保存更改**：系统自动保存所有修改

### 🔗 建立依赖关系
1. **选择源任务**：点击要建立依赖关系的源任务节点
2. **开始连接**：点击"开始连接"按钮进入连接模式
3. **选择目标**：点击目标任务节点完成依赖关系建立
4. **自动计算**：系统自动计算关键路径并更新项目状态

### 📊 查看统计信息
1. **项目概览**：在首页查看所有项目的概览统计信息
2. **详细进度**：进入项目详情页查看详细进度和任务状态
3. **关键任务**：关键路径上的任务会以特殊样式标识
4. **进度可视化**：进度条显示时间进度和完成度进度

### 💾 数据管理
1. **自动保存**：项目数据自动保存到本地存储
2. **数据备份**：支持项目数据导出备份，防止数据丢失
3. **数据恢复**：支持从备份文件恢复项目数据
4. **版本迁移**：数据迁移服务确保版本升级时的兼容性

### 🎨 高级功能
1. **撤销重做**：支持操作的撤销和重做，提供良好的用户体验
2. **多项目管理**：支持同时管理多个项目，提供全局视图
3. **模板自定义**：可以创建和保存自定义项目模板
4. **数据导入导出**：支持项目数据的导入导出，便于团队协作

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
- **ArkTS** - HarmonyOS原生开发语言，提供类型安全的开发体验
- **ArkUI** - 声明式UI框架，支持响应式数据绑定和组件化开发
- **Canvas 2D** - 高性能图形渲染引擎，实现流畅的可视化交互
- **Hvigor** - HarmonyOS官方构建工具，支持模块化构建和依赖管理

### HarmonyOS API
- **@ohos.router** - 页面路由导航，支持页面间参数传递和动画效果
- **@ohos.file.fs** - 文件系统操作，提供安全的数据持久化能力
- **@ohos.app.ability.common** - 应用上下文管理，统一管理应用生命周期
- **@ohos.promptAction** - 用户提示操作，提供友好的用户交互体验
- **@ohos.vibrator** - 触觉反馈，增强用户操作体验

### 架构设计
- **分层架构** - 表现层、业务层、数据层清晰分离，提高代码可维护性
- **服务容器** - 统一的服务管理和依赖注入，降低模块间耦合度
- **响应式数据** - 基于@Observed/@ObjectLink的数据绑定，实现自动UI更新
- **事件总线** - 松耦合的组件间通信机制，支持异步事件处理
- **命令模式** - 支持操作撤销和重做，提供良好的用户体验

### 算法实现
- **关键路径法（CPM）** - 完整的项目进度管理算法，时间复杂度O(V+E)
- **拓扑排序** - 任务依赖关系处理，确保项目逻辑正确性
- **循环检测** - 深度优先搜索算法，检测依赖关系中的循环引用
- **浮动时间计算** - 精确计算任务可延迟时间，为项目调度提供依据

### 设计模式
- **单例模式** - 全局状态和服务管理，确保数据一致性
- **观察者模式** - 响应式数据绑定和事件通知机制
- **命令模式** - 操作封装和撤销重做功能
- **策略模式** - 多种交互模式和渲染策略切换
- **工厂模式** - 服务实例创建和模板对象生成

---

## 🤝 贡献指南

我们欢迎所有形式的贡献！无论是功能建议、Bug报告还是代码贡献。您的参与将帮助EasyFlow变得更好。

### 📝 如何贡献
1. **Fork** 本仓库到您的GitHub账户
2. **克隆** 您的Fork到本地开发环境
   ```bash
   git clone https://github.com/your-username/EasyFlow.git
   cd EasyFlow
   ```
3. **创建特性分支** (`git checkout -b feature/AmazingFeature`)
4. **提交更改** (`git commit -m 'Add some AmazingFeature'`)
5. **推送分支** (`git push origin feature/AmazingFeature`)
6. **创建 Pull Request** 并详细描述您的更改

### 🐛 报告问题
如果您发现了Bug或有功能建议，请通过以下方式提交：
- 使用 [Issues](https://github.com/your-username/EasyFlow/issues) 提交Bug报告
- 使用 [Discussions](https://github.com/your-username/EasyFlow/discussions) 进行功能讨论
- 提供详细的复现步骤和环境信息

### 📋 开发规范
- **代码规范**：遵循ArkTS编码规范和项目代码风格
- **注释文档**：为新增功能添加适当的注释和文档
- **测试覆盖**：确保代码通过所有测试用例
- **文档更新**：更新相关文档和README文件
- **提交信息**：使用清晰的提交信息描述更改内容

### 🎯 贡献类型
- **功能开发**：新功能实现和现有功能优化
- **Bug修复**：问题修复和性能优化
- **文档完善**：README、API文档、使用指南等
- **测试用例**：单元测试、集成测试、UI测试
- **设计优化**：UI/UX改进和用户体验提升

### 📞 联系我们
- **邮箱**：your-email@example.com
- **QQ群**：123456789
- **微信群**：扫描二维码加入

---


## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

```
MIT License

Copyright (c) 2024 EasyFlow Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 致谢

感谢所有为EasyFlow项目做出贡献的开发者和用户！

### 特别感谢
- **HarmonyOS开发团队** - 提供优秀的开发平台和工具
- **开源社区** - 为项目提供灵感和技术支持
- **所有贡献者** - 感谢每一位为项目贡献代码、文档和建议的开发者
- **用户反馈** - 感谢所有用户的宝贵建议和反馈

### 相关项目
- [HarmonyOS官方文档](https://developer.harmonyos.com/)
- [ArkTS语言规范](https://developer.harmonyos.com/cn/develop/arkts/)
- [ArkUI框架](https://developer.harmonyos.com/cn/develop/arkui/)

---

<div align="center">
  <p>如果这个项目对您有帮助，请给我们一个 ⭐️</p>
  <p>让项目管理变得简单，让工作效率更高！</p>
  
  <p>
    <a href="https://github.com/your-username/EasyFlow">GitHub</a> •
    <a href="https://github.com/your-username/EasyFlow/issues">Issues</a> •
    <a href="https://github.com/your-username/EasyFlow/discussions">Discussions</a>
  </p>
</div>
