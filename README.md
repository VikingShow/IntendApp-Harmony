# EasyFlow - 一思不漏

<div align="center">
  <img src="AppScope/resources/base/media/app_foreground.png" alt="EasyFlow Logo" width="120" height="120">
  
  **三思而后行，一思则不漏**
  
  *专业的HarmonyOS项目管理应用 · 融合关键路径法与可视化网络图*
  
  [![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0+-blue.svg)](https://developer.harmonyos.com/)
  [![ArkTS](https://img.shields.io/badge/ArkTS-Latest-green.svg)](https://developer.harmonyos.com/cn/develop/arkts/)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
  [![Version](https://img.shields.io/badge/Version-1.2.0-orange.svg)](https://github.com/your-username/EasyFlow/releases)
  [![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com/your-username/EasyFlow/actions)
</div>

---

## 💡 软件理念

> **三思而后行，一思则不漏**

在项目管理的世界里，**思考**是成功的基石。EasyFlow的名字与理念源于这样的信念：

- **三思而后行**：做任何事情之前，都应当深思熟虑、周密计划。项目管理不是盲目执行，而是科学规划。通过关键路径法（CPM）算法，EasyFlow帮助您看清每一个任务的依赖关系，识别影响全局的关键路径，让您在行动前就能洞察全局。

- **一思则不漏**：当您使用EasyFlow完整思考一遍项目流程，所有任务、依赖、时间节点都将清晰呈现，不会遗漏任何关键环节。从任务分解到检查清单，从AI智能生成到日历提醒，EasyFlow确保您的每一个想法都能落地执行。

EasyFlow不仅仅是一个工具，更是一种**以终为始**的项目思维方式。无论是开发软件、策划活动，还是管理个人目标，EasyFlow都能帮助您：

🎯 **看清全局** — 可视化网络图让复杂项目一目了然  
⏱️ **把控节奏** — 关键路径分析精准识别时间瓶颈  
✅ **不漏细节** — 任务清单与提醒确保万无一失  
🤖 **智能高效** — AI助手让项目规划事半功倍  

---

## 📋 项目简介

**EasyFlow（一思不漏）** 是一款专为HarmonyOS平台开发的专业项目管理应用，采用关键路径法（CPM）算法实现科学的项目进度管理。应用提供交互式Canvas可视化网络图、智能关键路径分析、**AI智能生成项目**、**系统日历集成**、**新手引导系统**、**节点工作台（自定义节点类型）**、**规则引擎**、多格式数据导入导出、项目模板系统等专业功能，通过现代化的移动端UI设计和流畅的交互体验，让复杂的项目管理变得简单高效。

### 🎯 核心价值

- **🔬 科学算法**：完整实现关键路径法（CPM）算法，自动计算最早/最晚开始时间、浮动时间，精确识别关键路径
- **🤖 AI智能助手**：接入DeepSeek等AI大模型，通过自然语言描述自动生成项目结构，一键创建完整项目导图
- **🎨 可视化**：基于Canvas 2D的交互式项目网络图，支持普通/缩略双模式渲染，提供拖拽、缩放、平移等流畅操作
- **📊 智能分析**：实时计算项目工期、关键任务数、完成进度，提供多维度数据统计和即将到期任务提醒
- **📅 日历集成**：与HarmonyOS系统日历无缝集成，自动同步任务到日历并创建智能提醒
- **✅ 任务清单**：每个任务支持子任务检查清单，细化任务分解，精准跟踪进度
- **🎓 新手引导**：内置分步引导系统，帮助新用户快速上手，零学习成本
- **💾 数据管理**：支持JSON/PNG/CSV多格式导入导出，完善的数据迁移和备份机制，确保数据安全
- **🔧 节点工作台**：可视化设计自定义节点类型，配置字段、样式和布局，支持版本管理和导入导出
- **⚙️ 规则引擎**：事件驱动的规则系统，支持字段联动、条件校验、动态显隐等高级功能
- **📱 响应式设计**：完美适配手机、平板、折叠屏等多种设备，提供一致的用户体验

---

## ✨ 核心功能

### 1. 📊 Canvas可视化网络图
**基于Canvas 2D的专业项目网络图渲染引擎**

- **双模式渲染**：
  - **普通模式**：显示完整任务信息（名称、工期、ES/LS/TF）和依赖连线
  - **缩略模式**：双层进度环设计，外环显示任务完成度，内环显示时间进度，节省空间同时展示关键信息
  
- **流畅交互**：
  - 拖拽任务节点调整布局位置，实时保存
  - 双指缩放查看细节（0.3x - 3x）
  - 双指平移浏览大型项目
  - 点击任务快速编辑，点击连线删除依赖关系
  
- **智能布局**：
  - 自动按任务层级横向排列，同层任务纵向均匀分布
  - 虚拟依赖自动插入，确保网络图逻辑正确
  - 支持手动调整和自动重置布局

- **视觉效果**：
  - 关键路径任务红色高亮，不同状态任务颜色区分
  - 动态贝塞尔曲线连接依赖关系
  - 即将到期任务标记提醒（7天内）

### 2. 🧮 关键路径法（CPM）算法引擎
**完整实现CPM算法的核心计算服务**

- **精确计算**（CriticalPathService）：
  - **ES（Earliest Start）**：最早开始时间，正向遍历计算
  - **EF（Earliest Finish）**：最早完成时间 = ES + 工期
  - **LS（Latest Start）**：最晚开始时间，反向遍历计算
  - **LF（Latest Finish）**：最晚完成时间
  - **TF（Total Float）**：总浮动时间 = LS - ES，表示任务可延迟时间
  
- **关键路径识别**：
  - 自动识别TF = 0的任务为关键任务
  - 追踪从起点到终点的完整关键路径
  - 可视化高亮显示所有关键路径
  
- **智能分析**：
  - 拓扑排序确保依赖关系正确
  - 循环依赖检测和报错
  - 虚拟起点/终点自动处理
  - 项目总工期自动计算

### 3. 📝 完善的任务管理系统
**基于命令模式的任务CRUD操作，支持撤销/重做**

- **任务属性**：
  - 基本信息：名称、描述、备注
  - 时间管理：开始日期、结束日期、ES/LS/TF（自动计算）
  - **检查清单**：每个任务支持添加多个子任务项，勾选完成后自动计算进度
  - 完成度：根据检查清单自动计算或手动设置
  
- **依赖关系**：
  - 可视化添加/删除前置任务
  - 支持多个前置任务（AND关系）
  - 依赖连线双向绑定
  - 自动检测循环依赖
  
- **操作功能**：
  - 侧边栏任务编辑器快速编辑
  - 支持撤销/重做（基于CommandHistory）
  - 任务复制、删除批量操作

### 4. 📈 多维度数据统计仪表板
**实时计算项目关键指标，提供决策支持**

- **项目概览**（DashboardView）：
  - **总工期**：基于CPM算法计算的项目完成时间
  - **总任务数**：项目中所有任务的数量
  - **关键任务数**：TF = 0的关键路径任务数量
  - **完成进度**：已完成任务数/总任务数的百分比
  
- **进度统计**：
  - 未开始/进行中/已完成任务数量统计
  - 高/中/低优先级任务分布
  - 即将到期任务列表（7天内到期任务提醒）
  - 项目健康度评估

### 5. 💾 多格式数据导入导出
**支持JSON、PNG、CSV三种格式，数据互通无阻**

- **JSON格式**（ExportService/ImportService）：
  - 完整导出项目数据（任务、依赖、布局）
  - 支持导入本地JSON文件和URI选择的文件
  - 数据版本控制和自动迁移（DataMigrationService）
  
- **PNG图片导出**：
  - 基于OffscreenCanvas的高质量渲染
  - 自动计算画布尺寸，确保完整显示
  - 支持分享到其他应用
  
- **CSV格式**：
  - 导出任务列表为Excel兼容格式
  - 包含所有任务属性和CPM计算结果
  - 支持导入CSV创建新项目
  
- **数据安全**：
  - 自动备份机制，数据完整性校验
  - 导入时错误处理和友好提示
  - 权限管理（PermissionService）

### 6. 🎯 项目模板系统
**快速启动常见项目类型，提高工作效率**

- **内置模板**（TemplateService）：
  - 软件开发项目（需求分析 → 设计 → 开发 → 测试 → 发布）
  - 产品发布流程
  - 营销活动计划
  - 空白项目模板
  
- **模板内容**：
  - 预定义任务结构和依赖关系
  - 标准工期设置和最佳实践布局

### 7. 🎨 响应式UI与主题系统
**完美适配多设备，提供一致的用户体验**

- **响应式布局**（BreakpointSystem）：
  - **手机（sm）**：< 600vp，紧凑布局，底部工具栏
  - **平板（md）**：600-840vp，双栏布局
  - **折叠屏（lg）**：> 840vp，三栏布局
  - 动态调整组件大小和间距
  
- **颜色系统**（ResponsiveColorConfig）：
  - 浅色/深色主题自动适配
  - 语义化颜色命名（primary/success/warning/error）
  - 任务状态颜色（未开始/进行中/已完成/关键任务）
  - Canvas颜色独立配置
  
- **交互动画**：
  - 页面转场动画，组件展开/收起动画
  - 按钮点击反馈，列表滚动优化

### 8. 🤖 AI智能生成项目
**接入AI大模型，通过自然语言一键生成项目结构**

- **智能生成**（AIService）：
  - 支持DeepSeek、OpenAI等兼容模型
  - 自然语言描述生成任务结构
  - 自动创建任务依赖关系
  - 为每个任务生成子任务检查清单
  
- **使用方式**：
  - 在首页点击创建项目
  - 选择“AI生成导图”
  - 输入你自己的API Key（数据不上传，本地存储）
  - 描述项目需求（如：“开发一款待办应用的完整项目计划”）
  - AI自动生成完整的项目导图

- **安全性**：
  - API Key本地存储，不上传服务器
  - 支持自定义Base URL
  - 完全控制数据隐私

### 9. 📅 系统日历集成
**与HarmonyOS系统日历深度集成，智能同步任务**

- **日历同步**（CalendarService）：
  - 自动创建系统日历账户（EasyFlowCalendar）
  - 一键将任务添加到系统日历
  - 自动设置任务提醒（开始前10分钟）
  - 支持查看和管理已同步的任务
  
- **提醒功能**：
  - 系统级通知提醒
  - 支持多种提醒时间设置
  - 与系统日历应用完美配合
  
- **使用场景**：
  - 重要任务同步到系统日历
  - 在系统日历中查看所有任务
  - 利用系统提醒避免遗漏重要任务

### 10. 🎓 新手引导系统
**内置分步引导，帮助用户快速上手**

- **互动引导**（TutorialService）：
  - 首页引导：介绍项目创建、列表管理、导入导出
  - 编辑页引导：介绍画布操作、任务管理、关键路径
  - 高亮目标组件，分步详细讲解
- **智能管理**：
  - 自动检测首次启动
  - 记录引导完成状态
  - 支持"不再提醒"设置
  - 可随时手动重启引导
  
- **用户友好**：
  - 美观的视觉设计
  - 清晰的步骤指示
  - 零学习成本，快速上手

### 11. 🔧 节点工作台（Node Workspace）
**可视化设计自定义节点类型，打造专属项目管理体验**

- **节点Schema管理**（NodeSchemaService）：
  - 自定义节点类型的名称、说明、图标
  - 配置填充色、边框色、文字色等样式属性
  - 支持系统内置节点类型（标准任务）
  - 用户自定义节点类型无限扩展
  
- **字段配置**：
  - 支持多种字段类型：文本、数字、日期、选择器、开关等
  - 自定义字段验证规则（必填、范围、格式等）
  - 字段默认值和占位符设置
  - 字段排序和分组管理
  
- **可视化布局设计**：
  - 拖拽式组件排布
  - 实时预览节点效果
  - 支持行列布局配置
  
- **版本管理**：
  - 草稿/已发布双版本机制
  - 历史版本记录和回滚
  - 版本差异对比查看
  
- **导入导出**：
  - 导出节点Schema为JSON
  - 从JSON导入节点类型
  - 便于团队共享和复用

### 12. ⚙️ 规则引擎（Rule Engine）
**事件驱动的智能规则系统，实现表单联动和数据验证**

- **规则配置**（RuleEngineService）：
  - 基于事件触发：节点加载、字段变化、表单提交等
  - 条件判断：支持等于、不等于、包含、大于、小于等操作符
  - 多条件组合：AND/OR逻辑组合
  
- **动作执行**：
  - **setVisible**：动态显示/隐藏字段
  - **setEnabled**：动态启用/禁用字段
  - **setValue**：自动设置字段值
  - **validate**：触发字段验证
  
- **安全保护**：
  - 最大迭代次数限制（防止无限循环）
  - 规则执行日志记录
  - 错误捕获和友好提示

### 13. ⚡ 性能优化与错误处理
**确保应用流畅运行，提供稳定可靠的用户体验**

- **性能优化**（PerformanceService）：
  - Canvas渲染节流（16ms，60fps）
  - 防抖/节流优化频繁操作
  - 计算结果缓存
  
- **错误处理**（ErrorHandler）：
  - 全局异常捕获
  - 用户友好的错误提示
  - 错误日志记录
  
- **加载状态**（LoadingService）：
  - 统一的Loading管理
  - 操作进度提示

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

### 🤖 使用AI生成功能

1. **准备API Key**：
   - 获取DeepSeek API Key：https://platform.deepseek.com/
   - 或使用其他兼容OpenAI格式的API

2. **创建项目**：
   - 在首页点击右上角“+”按钮
   - 选择“AI生成导图”
   - 输入你的API Key（本地存储，下次无需再输）
   - 输入项目描述，例如：
     - “开发一款在线商城的完整项目计划”
     - “策划一场产品发布会的任务清单”
     - “写一本小说的创作流程”
   - 点击“生成导图”，AI会自动生成项目结构

3. **修改和优化**：
   - AI生成的项目可以直接使用
   - 也可以根据实际情况调整任务和依赖关系
   - AI会为每个任务生成子任务检查清单

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
├── AppScope/                         # 应用级配置
│   ├── app.json5                    # 应用配置（bundleName、版本信息等）
│   └── resources/                   # 应用级资源（图标、启动图等）
│
├── entry/                           # 主模块
│   ├── src/main/
│   │   ├── ets/                    # ArkTS源代码
│   │   │   │
│   │   │   ├── components/         # UI组件层
│   │   │   │   ├── CommonButton.ets        # 通用按钮组件
│   │   │   │   ├── DashboardView.ets       # 项目仪表板（统计数据展示）
│   │   │   │   ├── Sidebar.ets             # 侧边栏（项目管理、任务列表）
│   │   │   │   ├── TaskEditor.ets          # 任务编辑器
│   │   │   │   ├── WelcomeView.ets         # 欢迎页面
│   │   │   │   ├── TutorialGuide.ets       # 新手引导组件
│   │   │   │   ├── ColorPicker.ets         # 颜色选择器
│   │   │   │   ├── ComponentLibrary.ets    # 组件库（节点工作台）
│   │   │   │   ├── ComponentPropertyPanel.ets # 组件属性面板
│   │   │   │   ├── NodeVisualCanvas.ets    # 节点可视化画布
│   │   │   │   └── ProjectPreviewDialog.ets # 项目预览对话框
│   │   │   │
│   │   │   ├── core/               # 核心业务逻辑层
│   │   │   │   ├── AppState.ets            # 全局应用状态管理
│   │   │   │   ├── CommandHistory.ets      # 命令历史（撤销/重做）
│   │   │   │   ├── ErrorHandler.ets        # 全局错误处理器
│   │   │   │   ├── EventBus.ets            # 事件总线
│   │   │   │   ├── ProjectManager.ets      # 项目管理核心服务
│   │   │   │   ├── ServiceContainer.ets    # 服务容器（依赖注入）
│   │   │   │   ├── canvas/                 # Canvas渲染模块
│   │   │   │   │   ├── CanvasController.ets  # 画布交互控制器
│   │   │   │   │   └── CanvasRenderer.ets    # 画布渲染器
│   │   │   │   └── commands/               # 命令模式实现
│   │   │   │       ├── Command.ets           # 命令接口
│   │   │   │       ├── AddTaskCommand.ets    # 添加任务命令
│   │   │   │       ├── DeleteTaskCommand.ets # 删除任务命令
│   │   │   │       ├── UpdateTaskCommand.ets # 更新任务命令
│   │   │   │       ├── MoveTaskCommand.ets   # 移动任务命令
│   │   │   │       ├── AddDependencyCommand.ets    # 添加依赖命令
│   │   │   │       └── DeleteDependencyCommand.ets # 删除依赖命令
│   │   │   │
│   │   │   ├── model/              # 数据模型层
│   │   │   │   ├── ProjectData.ets         # 项目数据模型（Task、Project等）
│   │   │   │   └── NodeSchema.ets          # 节点Schema数据模型（字段、样式、规则等）
│   │   │   │
│   │   │   ├── pages/              # 页面层
│   │   │   │   ├── Home.ets                # 首页（项目列表）
│   │   │   │   ├── Index.ets               # 编辑页（可视化编辑器）
│   │   │   │   └── NodeWorkspace.ets       # 节点工作台（自定义节点类型设计）
│   │   │   │
│   │   │   ├── services/           # 业务服务层
│   │   │   │   ├── AIService.ets           # AI智能生成服务
│   │   │   │   ├── CalendarService.ets     # 系统日历集成服务
│   │   │   │   ├── CriticalPathService.ets # CPM算法服务
│   │   │   │   ├── CustomComponentService.ets # 自定义组件服务
│   │   │   │   ├── DataMigrationService.ets # 数据迁移服务
│   │   │   │   ├── ExportService.ets       # 导出服务（JSON/PNG/CSV）
│   │   │   │   ├── FileStorageService.ets  # 文件存储服务
│   │   │   │   ├── ImportService.ets       # 导入服务
│   │   │   │   ├── LoadingService.ets      # 加载状态管理
│   │   │   │   ├── NodeSchemaService.ets   # 节点Schema管理服务
│   │   │   │   ├── PerformanceService.ets  # 性能监控服务
│   │   │   │   ├── PermissionService.ets   # 权限管理服务
│   │   │   │   ├── RuleEngineService.ets   # 规则引擎服务
│   │   │   │   ├── StorageService.ets      # 数据持久化服务
│   │   │   │   ├── TemplateService.ets     # 项目模板服务
│   │   │   │   └── TutorialService.ets     # 新手引导服务
│   │   │   │
│   │   │   ├── utils/              # 工具类层
│   │   │   │   ├── BreakpointSystem.ets    # 响应式断点系统
│   │   │   │   ├── ResponsiveColorConfig.ets # 响应式颜色配置
│   │   │   │   ├── ThemeConfig.ets         # 主题配置
│   │   │   │   └── ValidationUtils.ets     # 数据验证工具
│   │   │   │
│   │   │   ├── entryability/       # Ability入口
│   │   │   │   └── EntryAbility.ets        # 应用主入口
│   │   │   │
│   │   │   └── entrybackupability/ # 备份Ability
│   │   │       └── EntryBackupAbility.ets  # 数据备份入口
│   │   │
│   │   ├── resources/              # 资源文件
│   │   │   ├── base/               # 基础资源
│   │   │   │   ├── element/        # 元素资源（字符串、颜色等）
│   │   │   │   ├── media/          # 媒体资源（图片、图标）
│   │   │   │   └── profile/        # 配置文件
│   │   │   └── dark/               # 深色主题资源
│   │   │
│   │   └── module.json5            # 模块配置文件
│   │
│   ├── build-profile.json5         # 构建配置
│   ├── hvigorfile.ts               # 构建脚本
│   └── oh-package.json5            # 模块依赖
│
├── hvigor/                         # Hvigor构建工具配置
│   └── hvigor-config.json5         # 构建工具配置
│
├── oh_modules/                     # 依赖包（类似node_modules）
├── oh-package.json5                # 项目依赖配置
├── oh-package-lock.json5           # 依赖锁定文件
├── hvigorfile.ts                   # 项目级构建脚本
└── README.md                       # 项目说明文档
```

---

## 🎯 核心组件说明

### 📱 主要页面

#### Home.ets - 项目列表首页
- 显示所有项目的卡片列表
- 展示每个项目的基本信息（名称、任务数、完成进度）
- 支持新建项目（空白/模板）
- 支持项目导入（JSON/CSV）
- 支持项目删除和编辑

#### Index.ets - 可视化编辑页
- Canvas 2D渲染的项目网络图（约1880行核心代码）
- 双指手势交互（缩放、平移、拖拽）
- 集成Sidebar和DashboardView
- 提供顶部工具栏（撤销/重做、导出、设置等）
- 响应式布局适配不同设备

### 🧩 核心组件

#### DashboardView.ets - 数据仪表板
- **统计卡片**：总工期、总任务数、关键任务数、完成进度
- **即将到期任务列表**：7天内到期任务提醒，点击可聚焦
- **进度可视化**：环形进度图和百分比显示
- **响应式布局**：自动适配不同屏幕尺寸
- **实时更新**：基于@ObjectLink响应式数据绑定

#### Sidebar.ets - 多功能侧边栏
- **项目信息**：项目名称编辑、分类选择
- **任务列表**：所有任务的树形展示，显示依赖关系
- **任务编辑**：集成TaskEditor，快速编辑任务属性
- **新增任务**：快速创建新任务节点
- **布局控制**：自动布局、重置布局按钮
- **可伸缩设计**：支持展开/收起，节省屏幕空间

#### TaskEditor.ets - 任务属性编辑器
- **基本属性**：名称、描述、工期、截止日期
- **状态管理**：未开始/进行中/已完成，优先级选择
- **进度管理**：完成度滑块（0-100%）
- **依赖管理**：前置任务列表，支持添加/删除
- **CPM数据展示**：ES、LS、TF自动计算结果显示
- **实时同步**：编辑后立即更新画布和统计数据

#### WelcomeView.ets - 欢迎页
- 新项目引导界面
- 提供快速开始提示
- 展示应用主要功能

#### CommonButton.ets - 通用按钮组件
- 统一的按钮样式和交互
- 支持主要/次要/危险等类型
- 响应式尺寸适配

### 🔧 核心服务

#### ProjectManager.ets - 项目管理核心
- **项目CRUD**：创建、读取、更新、删除项目
- **任务CRUD**：统一的任务管理接口
- **依赖管理**：添加/删除任务依赖关系
- **状态同步**：协调各组件的数据一致性
- **事件分发**：通过EventBus发布项目变更事件
- **单例模式**：全局唯一实例，确保数据一致性

#### CriticalPathService.ets - CPM算法引擎
- **拓扑排序**：检测依赖关系有向无环图（DAG）
- **正向传递**：计算ES和EF
- **反向传递**：计算LS和LF
- **浮动时间**：计算TF = LS - ES
- **关键路径**：识别TF = 0的任务链
- **虚拟节点**：自动处理起点和终点
- **性能优化**：时间复杂度O(V+E)

#### CanvasController.ets - 画布交互控制器
- **手势识别**：单指拖拽、双指缩放/平移
- **节点选择**：点击选中任务节点
- **连线交互**：点击连线删除依赖
- **缩放限制**：0.3x - 3x范围控制
- **防抖节流**：优化频繁操作性能
- **坐标转换**：屏幕坐标 ↔ 画布坐标

#### CanvasRenderer.ets - 画布渲染引擎
- **双模式渲染**：普通模式 / 缩略模式
- **任务节点**：圆形/圆环节点，颜色区分状态
- **依赖连线**：贝塞尔曲线，箭头指向
- **文本渲染**：任务名称、CPM数据
- **高亮效果**：关键路径红色高亮
- **性能优化**：离屏Canvas、渲染节流

#### StorageService.ets - 数据持久化
- **本地存储**：基于@ohos.data.preferences
- **自动保存**：项目修改后自动保存
- **数据加载**：应用启动时加载所有项目
- **异常处理**：存储失败时的错误处理

#### ExportService.ets - 数据导出
- **JSON导出**：完整项目数据序列化
- **PNG导出**：基于OffscreenCanvas渲染图片
- **CSV导出**：任务列表转Excel格式
- **文件保存**：通过文件选择器保存
- **分享功能**：支持分享到其他应用

#### ImportService.ets - 数据导入
- **JSON导入**：解析项目JSON文件
- **CSV导入**：解析任务列表CSV
- **URI处理**：支持通过文档选择器导入
- **数据校验**：导入时验证数据完整性
- **错误提示**：友好的错误信息展示

#### TemplateService.ets - 项目模板
- **模板定义**：预定义项目模板
- **模板应用**：基于模板创建项目
- **模板管理**：增删改查模板

#### 其他服务
- **DataMigrationService** - 数据版本迁移
- **LoadingService** - 全局加载状态管理
- **PerformanceService** - 性能监控和优化
- **PermissionService** - 权限请求管理
- **ErrorHandler** - 全局错误处理
- **EventBus** - 事件总线，组件间通信
- **CommandHistory** - 命令历史，撤销/重做
- **ServiceContainer** - 服务容器，依赖注入

---

## 📖 使用指南

### 🆕 创建项目

#### 方式一：空白项目
1. 打开应用，进入首页（Home页面）
2. 点击右上角的**"+"**按钮
3. 选择**"空白项目"**选项
4. 输入项目名称（例如："网站改版项目"）
5. 选择项目分类（开发/设计/营销/其他）
6. 点击**"创建"**按钮
7. 系统自动跳转到项目编辑页，此时项目为空，可以开始添加任务

#### 方式二：从模板创建
1. 点击右上角的**"+"**按钮
2. 选择**"选择模板"**选项
3. 在模板列表中选择适合的模板：
   - **软件开发项目**：包含需求分析、设计、开发、测试、发布等标准任务
   - **产品发布流程**：包含产品规划、开发、测试、上线等流程
   - **营销活动计划**：包含策划、设计、执行、分析等阶段
4. 点击**"使用模板"**
5. 系统自动创建项目并填充预设任务和依赖关系
6. 根据实际需求修改任务信息和工期

#### 方式三：导入现有项目
1. 点击右上角的**"+"**按钮
2. 选择**"导入项目"**选项
3. 选择文件类型：
   - **JSON格式**：完整导入项目数据（推荐）
   - **CSV格式**：导入任务列表，需要手动建立依赖关系
4. 通过文件选择器选择文件
5. 系统自动解析并创建项目

### ✏️ 任务管理

#### 添加任务
1. **方式一：通过侧边栏**
   - 打开侧边栏（点击左上角菜单按钮）
   - 点击**“添加任务”**按钮
   - 在弹出的编辑器中填写任务信息
   - 添加子任务检查清单（可选）
   - 点击**“保存”**

2. **方式二：通过Canvas**
   - 双击画布空白区域
   - 系统自动创建新任务节点
   - 任务会出现在画布中央

3. **方式三：使用AI生成**
   - 创建项目时选择“AI生成导图”
   - AI会自动生成完整的任务结构

#### 编辑任务
1. **打开任务编辑器**：
   - 方式一：点击Canvas上的任务节点
   - 方式二：在侧边栏任务列表中点击任务

2. **编辑基本信息**：
   - **任务名称**：简洁明确的任务描述（必填）
   - **任务描述**：详细说明任务内容和要求（可选）
   - **工期**：任务预计需要的天数（必填，影响CPM计算）
   - **截止日期**：任务的最后期限（可选，7天内到期会有提醒）

3. **设置任务状态**：
   - **未开始**：默认状态，灰色显示
   - **进行中**：蓝色显示
   - **已完成**：绿色显示，完成度自动设为100%

4. **设置优先级**：
   - **高**：重要紧急的任务
   - **中**：正常优先级（默认）
   - **低**：可以延后的任务

5. **管理检查清单**：
   - 点击“添加检查项”按钮
   - 输入子任务名称
   - 勾选完成的子任务
   - 任务完成度会自动根据检查清单计算

6. **同步到系统日历**：
   - 在任务编辑器中点击“添加到日历”
   - 任务会自动同步到HarmonyOS系统日历
   - 系统会在任务开始前10分钟提醒你

6. **查看CPM数据**（自动计算，只读）：
   - **ES（最早开始）**：任务最早可以开始的时间
   - **LS（最晚开始）**：任务最晚必须开始的时间
   - **TF（浮动时间）**：任务可以延迟的天数
   - **关键任务**：TF = 0的任务，显示为红色

#### 删除任务
1. 选中要删除的任务
2. 点击任务编辑器底部的**"删除任务"**按钮
3. 确认删除操作
4. 系统自动删除相关依赖关系并重新计算关键路径

#### 移动任务位置
1. 在Canvas上长按任务节点
2. 拖动到目标位置
3. 松开手指，位置自动保存
4. 可以随时点击**"自动布局"**恢复标准布局

### 🔗 管理依赖关系

#### 添加依赖关系
1. **方式一：通过任务编辑器**
   - 打开目标任务（后继任务）
   - 在**"前置任务"**区域点击**"添加依赖"**
   - 从任务列表中选择前置任务
   - 点击确认，系统自动绘制连线

2. **方式二：通过Canvas连线**（如果实现）
   - 点击源任务节点
   - 点击**"开始连接"**按钮
   - 点击目标任务节点
   - 系统自动建立依赖关系

**依赖关系规则**：
- 一个任务可以有多个前置任务（AND关系）
- 任务的ES = max(前置任务的EF)
- 不能创建循环依赖（系统会自动检测并提示）
- 添加依赖后会自动重新计算关键路径

#### 删除依赖关系
1. **方式一：通过任务编辑器**
   - 打开任务
   - 在前置任务列表中找到要删除的依赖
   - 点击删除按钮（×）

2. **方式二：通过Canvas**
   - 点击连线（依赖关系线）
   - 确认删除操作
   - 系统自动重新计算关键路径

### 📊 查看项目数据

#### 数据仪表板（DashboardView）
在编辑页顶部或侧边栏可以看到：

1. **项目统计卡片**：
   - **总工期**：基于CPM算法计算的项目完成时间
   - **总任务数**：项目中的所有任务数量
   - **关键任务数**：影响项目工期的关键任务数量
   - **完成进度**：已完成任务占比

2. **即将到期任务**：
   - 显示7天内到期的任务列表
   - 点击任务可快速定位到Canvas中的节点
   - 任务按到期时间排序

3. **进度可视化**：
   - 环形进度图显示项目整体完成度
   - 颜色区分：绿色（已完成）、蓝色（进行中）、灰色（未开始）

#### 识别关键路径
- **红色节点**：关键任务（TF = 0），这些任务的延迟会直接影响项目工期
- **红色连线**：关键路径上的依赖关系
- **灰色/蓝色/绿色节点**：非关键任务，有一定的浮动时间

**优化建议**：
- 优先关注关键任务，确保按时完成
- 合理利用非关键任务的浮动时间
- 通过调整依赖关系或减少关键任务工期来缩短项目总工期

### 🎨 Canvas交互操作

#### 基本操作
- **单指拖拽**：移动任务节点位置
- **双指缩放**：放大/缩小查看细节（0.3x - 3x）
- **双指平移**：移动画布视图
- **单击节点**：打开任务编辑器
- **单击连线**：删除依赖关系

#### 视图模式切换
1. **普通模式**（默认）：
   - 显示完整任务信息（名称、工期、ES/LS/TF）
   - 显示依赖连线和箭头
   - 适合详细查看和编辑

2. **缩略模式**：
   - 双层进度环设计
   - 外环：任务完成度（0-100%）
   - 内环：时间进度（当前时间相对于截止日期）
   - 适合快速浏览大型项目

切换方式：点击右上角的**"视图模式"**按钮

#### 布局管理
- **自动布局**：按任务层级和依赖关系自动排列
- **重置布局**：恢复到初始布局状态
- **手动调整**：拖拽节点到任意位置，系统自动保存

### 💾 数据导入导出

#### 导出项目

1. **导出为JSON**（推荐）：
   - 点击顶部工具栏的**"导出"**按钮
   - 选择**"导出为JSON"**
   - 选择保存位置
   - 文件包含完整项目数据（任务、依赖、布局、设置等）
   - 可用于备份或跨设备同步

2. **导出为PNG图片**：
   - 点击**"导出"** → **"导出为图片"**
   - 系统自动渲染高清项目网络图
   - 选择保存位置或分享到其他应用
   - 适合报告、演示、文档插图

3. **导出为CSV**：
   - 点击**"导出"** → **"导出为CSV"**
   - 导出任务列表，包含所有属性和CPM计算结果
   - 可用Excel、WPS等软件打开
   - 适合数据分析和报表制作

#### 导入项目

1. **从JSON导入**：
   - 首页点击**"+"** → **"导入项目"**
   - 选择JSON文件
   - 系统自动解析并创建项目
   - 保留原有的布局和所有设置

2. **从CSV导入**：
   - 选择CSV文件（需包含任务名称、工期等必要字段）
   - 系统创建任务列表
   - 需要手动建立依赖关系

### 🔄 撤销与重做

**操作方式**：
- **撤销**：点击顶部工具栏的**"撤销"**按钮（或快捷操作）
- **重做**：点击**"重做"**按钮

**支持的操作**：
- 添加/删除任务
- 修改任务属性
- 添加/删除依赖关系
- 移动任务位置

**限制**：
- 命令历史保存最近20步操作
- 保存项目后清空历史记录

### 🔧 项目设置

在侧边栏或设置菜单中可以配置：

1. **项目信息**：
   - 修改项目名称
   - 更改项目分类
   - 设置项目描述

2. **显示设置**：
   - 切换视图模式（普通/缩略）
   - 调整画布缩放级别
   - 显示/隐藏统计信息

3. **数据管理**：
   - 导出项目备份
   - 清空项目数据
   - 删除项目

---

## ❓ 常见问题

### 基础使用

#### Q: 如何切换不同的项目？
**A**: 点击左上角返回按钮回到首页，然后点击任意项目卡片即可进入该项目的编辑页。

#### Q: 如何删除项目？
**A**: 在首页长按项目卡片，在弹出菜单中选择"删除项目"，确认后删除。**注意：删除操作不可恢复，建议先导出备份。**

#### Q: 项目数据会丢失吗？
**A**: 不会。应用采用HarmonyOS Preferences API进行本地持久化存储，所有修改自动保存。建议定期导出JSON备份，以防设备故障或应用卸载。

#### Q: 支持哪些设备？
**A**: 支持所有运行HarmonyOS 4.0+的设备，包括：
- 手机（< 600vp）：紧凑布局
- 平板（600-840vp）：双栏布局
- 折叠屏/大屏（> 840vp）：三栏布局

#### Q: 应用支持多语言吗？
**A**: 当前版本主要支持中文。国际化支持计划在后续版本中添加。

### 关键路径与CPM算法

#### Q: 什么是关键路径？
**A**: 关键路径是项目网络图中从起点到终点的最长路径，决定了项目的最短完成时间。关键路径上的任务（TF = 0）如果延迟，会直接导致项目延期。

#### Q: 关键路径是如何计算的？
**A**: 应用使用关键路径法（CPM）算法：
1. **拓扑排序**：确保依赖关系为有向无环图（DAG）
2. **正向传递**：计算最早开始时间（ES）和最早完成时间（EF）
   - ES[j] = max(EF[i]) for all i → j
3. **反向传递**：计算最晚开始时间（LS）和最晚完成时间（LF）
   - LF[i] = min(LS[j]) for all i → j
4. **浮动时间**：TF[i] = LS[i] - ES[i]
5. **关键任务**：识别TF = 0的任务

#### Q: ES、LS、TF分别是什么意思？
**A**:
- **ES（Earliest Start）**：任务最早可以开始的时间（天）
- **LS（Latest Start）**：任务最晚必须开始的时间（天），超过此时间会导致项目延期
- **TF（Total Float）**：总浮动时间 = LS - ES，表示任务可以延迟的天数而不影响项目工期

#### Q: 如何缩短项目工期？
**A**: 优化策略：
1. **减少关键任务工期**：关键任务（红色）的优化直接缩短项目工期
2. **调整依赖关系**：合理安排任务并行执行，减少串行依赖
3. **资源优化**：将非关键任务的资源调配给关键任务
4. **快速跟踪**：分析是否可以将某些串行任务改为并行

#### Q: 为什么有些任务没有浮动时间？
**A**: TF = 0的任务位于关键路径上，这些任务的任何延迟都会直接影响项目总工期，因此没有浮动时间。非关键任务有一定的缓冲时间（TF > 0）。

#### Q: 添加依赖关系后，为什么有些任务变红了？
**A**: 系统重新计算了关键路径，这些变红的任务成为了新的关键任务。这是正常现象，说明依赖关系的变化影响了项目的关键路径。

### 任务管理

#### Q: 如何批量添加任务？
**A**: 当前版本支持：
1. **逐个添加**：通过侧边栏或双击Canvas添加
2. **从CSV导入**：批量导入任务列表
3. **使用模板**：选择模板快速创建预设任务

#### Q: 任务可以有多个前置任务吗？
**A**: 可以。一个任务可以有多个前置任务（AND关系），所有前置任务完成后才能开始。任务的ES = max(所有前置任务的EF)。

#### Q: 如何创建里程碑任务？
**A**: 创建一个工期为0的任务即可作为里程碑。里程碑通常用于标记项目的重要节点（如"需求评审完成"、"测试通过"等）。

#### Q: 如何复制任务？
**A**: 当前版本暂不支持任务复制。可以手动创建新任务并填写相同信息，或者通过导出JSON、修改数据、重新导入的方式实现。

#### Q: 删除任务后，相关的依赖关系会怎样？
**A**: 系统会自动删除与该任务相关的所有依赖关系，并重新计算关键路径。删除关键任务可能会改变项目的关键路径。

### 数据导入导出

#### Q: 导出的JSON文件包含哪些信息？
**A**: 完整的项目数据，包括：
- 项目基本信息（名称、分类、创建时间）
- 所有任务的详细信息
- 任务依赖关系
- 任务在Canvas上的位置
- 项目设置和配置

#### Q: 导出的PNG图片质量如何？
**A**: 应用使用OffscreenCanvas高质量渲染，自动计算最佳画布尺寸，确保所有任务和连线完整显示。图片适合打印和报告使用。

#### Q: CSV格式导入时需要哪些字段？
**A**: 必要字段：
- **任务名称**（必填）
- **工期**（必填，单位：天）

可选字段：
- 任务描述、截止日期、优先级、状态、完成度等

#### Q: 如何在不同设备间同步项目？
**A**: 
1. 在设备A上导出项目为JSON文件
2. 通过云盘、邮件等方式传输到设备B
3. 在设备B上导入JSON文件
4. 建议使用云盘的自动同步功能

#### Q: 导入文件失败怎么办？
**A**: 检查：
1. 文件格式是否正确（JSON/CSV）
2. JSON文件是否符合项目数据结构
3. CSV文件是否包含必要字段
4. 文件是否损坏或编码错误

查看错误提示信息，根据提示修正文件后重试。

### Canvas操作

#### Q: 如何快速定位某个任务？
**A**: 
1. 在DashboardView的"即将到期任务"列表中点击任务
2. 在侧边栏任务列表中点击任务
3. 系统会自动将Canvas视图移动到该任务位置并高亮显示

#### Q: 画布太大，如何查看全貌？
**A**: 
1. 使用双指缩小手势缩小视图（最小0.3x）
2. 切换到缩略模式查看
3. 点击"重置布局"重新排列任务

#### Q: 不小心移动了任务位置，如何恢复？
**A**: 
1. 点击"撤销"按钮恢复上一步操作
2. 点击"自动布局"重新排列所有任务
3. 从备份的JSON文件重新导入项目

#### Q: 为什么有些连线看不清？
**A**: 可能原因：
1. 缩放比例太小：放大视图查看
2. 任务重叠：调整任务位置或使用自动布局
3. 颜色对比度：切换深色/浅色主题

### 性能与优化

#### Q: 支持多大规模的项目？
**A**: 应用经过性能优化，支持：
- 任务数：200+
- 依赖关系：500+
- Canvas渲染：60fps流畅交互

更大规模的项目可能会影响性能，建议拆分为多个子项目。

#### Q: 应用运行卡顿怎么办？
**A**: 优化建议：
1. 减少任务数量，拆分大型项目
2. 切换到缩略模式减少渲染负担
3. 关闭不必要的动画效果
4. 清理设备缓存和内存

#### Q: Canvas缩放或拖拽不流畅？
**A**: 应用已实现渲染节流（16ms）和手势优化。如仍不流畅：
1. 检查设备性能
2. 关闭后台应用释放内存
3. 重启应用

### 高级功能

#### Q: 如何自定义项目模板？
**A**: 当前版本需要修改代码：
1. 打开 `entry/src/main/ets/services/TemplateService.ets`
2. 在 `getTemplates()` 方法中添加新模板
3. 定义模板的任务和依赖关系
4. 重新编译应用

未来版本计划支持界面化的模板管理。

#### Q: 支持团队协作吗？
**A**: 当前版本是单用户应用，可通过导出/导入JSON文件实现简单的协作：
1. 团队成员A编辑项目并导出JSON
2. 发送给成员B
3. 成员B导入JSON继续编辑
4. 重复以上流程

云协作功能计划在后续版本中添加。

#### Q: 能否导出甘特图？
**A**: 当前版本不支持甘特图导出，主要提供项目网络图（AON图）。甘特图功能在规划中。

#### Q: 支持资源分配和成本管理吗？
**A**: 当前版本专注于进度管理（CPM算法），暂不支持资源和成本管理。这些功能在未来版本的路线图中。

---

## 🛠️ 技术栈

### 核心技术
- **ArkTS** - HarmonyOS原生开发语言，基于TypeScript扩展，提供类型安全和面向对象编程
- **ArkUI** - 声明式UI框架，支持响应式数据绑定（@State/@Observed/@ObjectLink）和组件化开发
- **Canvas 2D API** - 高性能图形渲染引擎，实现流畅的60fps可视化交互
- **Hvigor 4.0+** - HarmonyOS官方构建工具，支持模块化构建和依赖管理

### HarmonyOS API 使用

#### 核心API
- **@ohos.router** - 页面路由导航，支持页面间参数传递和转场动画
- **@ohos.data.preferences** - 轻量级键值存储，用于项目数据持久化
- **@ohos.file.fs** - 文件系统操作，用于JSON/CSV文件的读写
- **@ohos.file.picker** - 文件选择器，用于导入导出文件
- **@ohos.app.ability.common** - 应用上下文管理，统一管理应用生命周期

#### UI交互API
- **@ohos.promptAction** - 用户提示操作（Toast、Dialog、ActionSheet）
- **@ohos.vibrator** - 触觉反馈，增强用户操作体验
- **@ohos.multimedia.image** - 图片处理，用于PNG导出

#### 高级特性
- **@ohos.uri** - URI处理，用于文件导入
- **@ohos.file.fileAccess** - 文件访问框架
- **@ohos.abilityAccessCtrl** - 权限管理

### 架构设计

#### 分层架构
```
┌─────────────────────────────────────┐
│   表现层 (Presentation Layer)       │
│   - Pages (Home, Index)             │
│   - Components (Sidebar, Dashboard) │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│   业务层 (Business Layer)           │
│   - ProjectManager (项目管理)       │
│   - CriticalPathService (CPM算法)   │
│   - CanvasController (交互控制)     │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│   服务层 (Service Layer)            │
│   - StorageService (数据持久化)     │
│   - ExportService/ImportService     │
│   - TemplateService (模板管理)      │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│   数据层 (Data Layer)               │
│   - ProjectData (数据模型)          │
│   - Preferences (本地存储)          │
└─────────────────────────────────────┘
```

#### 核心架构模式
- **服务容器（ServiceContainer）** - 统一的服务管理和依赖注入，降低模块间耦合度
- **响应式数据** - 基于@Observed/@ObjectLink的数据绑定，实现自动UI更新
  ```typescript
  @Observed class Project { }
  @ObjectLink project: Project  // 自动响应数据变化
  ```
- **事件总线（EventBus）** - 松耦合的组件间通信机制，支持异步事件处理
- **命令模式（CommandHistory）** - 支持操作撤销和重做，提供良好的用户体验
  ```typescript
  executeCommand(new AddTaskCommand(task))  // 可撤销
  undo()  // 撤销上一步
  redo()  // 重做
  ```

### 算法实现

#### 关键路径法（CPM）算法
```typescript
// 时间复杂度：O(V+E)
// V = 任务数，E = 依赖关系数

1. 拓扑排序：确保依赖关系为有向无环图（DAG）
2. 正向传递：计算ES和EF
   ES[j] = max(EF[i]) for all i → j
   EF[j] = ES[j] + Duration[j]
3. 反向传递：计算LS和LF
   LF[i] = min(LS[j]) for all i → j
   LS[i] = LF[i] - Duration[i]
4. 浮动时间：TF[i] = LS[i] - ES[i]
5. 关键路径：识别TF = 0的任务链
```

#### 其他算法
- **拓扑排序** - Kahn算法，O(V+E)时间复杂度
- **循环检测** - 深度优先搜索（DFS），检测依赖关系中的循环引用
- **自动布局** - 基于层级的树形布局算法
- **碰撞检测** - 点与圆/矩形的碰撞检测，用于节点和连线的点击判断

### 设计模式

#### 创建型模式
- **单例模式（Singleton）** - AppState、ProjectManager、ServiceContainer等全局唯一实例
  ```typescript
  static getInstance(): ProjectManager { ... }
  ```

#### 结构型模式
- **服务容器（Service Container）** - 依赖注入容器，统一管理服务实例
- **适配器模式（Adapter）** - 数据导入导出格式适配

#### 行为型模式
- **命令模式（Command）** - 封装操作为命令对象，支持撤销/重做
  ```typescript
  interface Command {
    execute(): void
    undo(): void
  }
  ```
- **观察者模式（Observer）** - EventBus事件发布订阅，响应式数据绑定
- **策略模式（Strategy）** - 多种渲染模式（普通/缩略）、多种导出格式（JSON/PNG/CSV）
- **状态模式（State）** - 任务状态（未开始/进行中/已完成）

### 性能优化技术

#### Canvas渲染优化
- **离屏Canvas（OffscreenCanvas）** - 预渲染复杂图形
- **渲染节流（Throttle）** - 限制渲染频率为16ms（60fps）
- **脏矩形（Dirty Rectangle）** - 仅重绘变化区域
- **图层分离** - 分离静态和动态内容

#### 数据处理优化
- **防抖（Debounce）** - 优化输入框等频繁触发的操作
- **节流（Throttle）** - 优化滚动、缩放等连续操作
- **计算缓存** - 缓存CPM算法计算结果
- **懒加载** - 延迟加载非关键资源

#### 内存优化
- **对象池** - 复用Canvas上下文等对象
- **及时释放** - 清理不再使用的引用
- **数据压缩** - 优化存储数据大小

---

## 🔧 开发者指南

### 本地开发环境搭建

1. **安装DevEco Studio**
   - 下载地址：https://developer.harmonyos.com/cn/develop/deveco-studio/
   - 推荐版本：4.0+（最新稳定版）
   - 安装HarmonyOS SDK API 10+

2. **配置开发环境**
   ```bash
   # 克隆项目
   git clone https://github.com/your-username/EasyFlow.git
   cd EasyFlow
   
   # 安装依赖（DevEco Studio会自动处理）
   # 或手动安装
   npm install
   ```

3. **运行项目**
   - 打开DevEco Studio
   - 导入项目（File → Open → 选择项目目录）
   - 等待依赖同步完成
   - 连接HarmonyOS设备或启动模拟器
   - 点击Run按钮或按 Shift+F10

### 项目开发规范

#### 代码风格
- **命名规范**：
  - 类名：PascalCase（如：`ProjectManager`）
  - 方法名：camelCase（如：`calculateCriticalPath`）
  - 常量：UPPER_SNAKE_CASE（如：`MAX_ZOOM_SCALE`）
  - 私有变量：以 `_` 开头（如：`_projectList`）

- **文件组织**：
  - 每个文件只包含一个主要类或组件
  - 相关的类型定义放在同一文件
  - 导入语句按类型分组（系统API → 本地模块）

- **注释规范**：
  ```typescript
  /**
   * 计算项目关键路径
   * @param tasks 任务列表
   * @returns 关键路径上的任务ID数组
   */
  calculateCriticalPath(tasks: Task[]): string[] {
    // 实现代码...
  }
  ```

#### Git工作流

1. **分支管理**：
   - `main`：稳定的生产版本
   - `develop`：开发分支
   - `feature/*`：新功能开发
   - `bugfix/*`：Bug修复
   - `hotfix/*`：紧急修复

2. **提交信息规范**：
   ```
   <type>(<scope>): <subject>
   
   <body>
   
   <footer>
   ```
   
   类型（type）：
   - `feat`: 新功能
   - `fix`: Bug修复
   - `docs`: 文档更新
   - `style`: 代码格式调整
   - `refactor`: 代码重构
   - `perf`: 性能优化
   - `test`: 测试相关
   - `chore`: 构建/工具相关
   
   示例：
   ```
   feat(cpm): 添加浮动时间计算功能
   
   - 实现TF = LS - ES的计算逻辑
   - 添加关键任务识别
   - 更新Canvas渲染显示TF值
   
   Closes #123
   ```

#### 测试规范

1. **单元测试**：
   - 位置：`entry/src/test/`
   - 框架：HarmonyOS Test Framework
   - 覆盖率要求：核心算法 > 80%

2. **测试示例**：
   ```typescript
   import { describe, it, expect } from '@ohos/hypium'
   import { CriticalPathService } from '../main/ets/services/CriticalPathService'
   
   describe('CriticalPathService', () => {
     it('应该正确计算简单项目的关键路径', () => {
       const service = new CriticalPathService()
       const tasks = [/* 测试数据 */]
       const result = service.calculate(tasks)
       expect(result.criticalPath.length).assertEqual(3)
     })
   })
   ```

### 调试技巧

#### 1. Console日志调试
```typescript
import hilog from '@ohos.hilog'

const TAG = 'EasyFlow'
hilog.info(0x0000, TAG, 'Project created: %{public}s', projectName)
hilog.error(0x0000, TAG, 'Failed to save: %{public}s', error.message)
```

#### 2. Canvas调试
```typescript
// 启用调试模式显示坐标、边界框等
const DEBUG_MODE = true

if (DEBUG_MODE) {
  // 绘制节点边界框
  ctx.strokeRect(node.x, node.y, node.width, node.height)
  // 显示坐标
  ctx.fillText(`(${node.x}, ${node.y})`, node.x, node.y - 10)
}
```

#### 3. 性能分析
```typescript
const startTime = Date.now()
// 执行操作
const duration = Date.now() - startTime
hilog.info(0x0000, 'Performance', 'Operation took %{public}d ms', duration)
```

### 常见开发问题

#### Q: Canvas不显示内容？
**A**: 检查：
1. Canvas组件是否正确初始化
2. CanvasRenderingContext2D是否获取成功
3. 坐标是否超出画布范围
4. 是否在正确的生命周期调用绘制方法

#### Q: 响应式数据不更新？
**A**: 确保：
1. 使用 `@Observed` 装饰器标记数据类
2. 使用 `@ObjectLink` 或 `@State` 接收数据
3. 修改数据时触发了setter（使用 `this.data = newData` 而不是直接修改属性）

#### Q: 路由跳转失败？
**A**: 检查：
1. 页面路径是否在 `main_pages.json` 中注册
2. 路由参数是否正确传递
3. 是否在UIAbility的生命周期中调用

#### Q: 文件读写失败？
**A**: 确认：
1. 是否申请了必要的权限
2. 文件路径是否正确（使用应用沙箱路径）
3. 是否处理了异步操作
4. 错误信息提示

---

## 🚀 版本历史与未来路线图

### v1.2.0（当前版本）
**发布时间：2025年Q2**

- [x] **AI智能生成**：接入DeepSeek等大模型，自然语言生成项目结构
- [x] **系统日历集成**：与HarmonyOS日历无缝同步任务提醒
- [x] **新手引导系统**：分步骤引导新用户快速上手
- [x] **节点工作台**：可视化设计自定义节点类型
- [x] **规则引擎**：事件驱动的字段联动和验证系统
- [x] **检查清单**：每个任务支持子任务检查项
- [x] **自定义字段**：通过节点Schema扩展任务属性

### v1.3（规划中）
**预计发布时间：2025年Q3**

- [ ] **甘特图视图**：添加时间轴甘特图，直观显示任务时间安排
- [ ] **任务复制/粘贴**：快速复制任务和依赖关系
- [ ] **批量编辑**：选中多个任务进行批量修改
- [ ] **搜索功能**：全局搜索任务、项目
- [ ] **标签系统**：为任务添加自定义标签
- [ ] **资源管理**：支持团队成员、设备等资源的分配和管理

### v1.4（规划中）
**预计发布时间：2025年Q4**

- [ ] **云同步**：支持云端存储和多设备自动同步
- [ ] **团队协作**：多人实时协作编辑项目
- [ ] **评论功能**：任务评论和讨论
- [ ] **版本历史**：项目变更历史记录和回滚
- [ ] **附件支持**：为任务添加文档、图片等附件

### v2.0（概念阶段）
**预计发布时间：2026年**

- [ ] **AI增强**：
  - 智能工期预测
  - 风险识别和预警
  - 资源优化建议
  - 自动生成项目报告

- [ ] **高级分析**：
  - 挣值管理（EVM）
  - 蒙特卡洛模拟
  - 风险矩阵分析
  - 多项目组合管理

- [ ] **多端支持**：
  - Web端
  - PC端（Windows/macOS）
  - 手表端简化版

### 社区建议功能

欢迎在 [Discussions](https://github.com/your-username/EasyFlow/discussions) 中提出您的想法！

热门建议：
- 自定义颜色主题
- 导出为Microsoft Project格式
- 看板视图（Kanban Board）
- 工时记录功能
- 项目对比分析
- 成本管理与预算跟踪

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
