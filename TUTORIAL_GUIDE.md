# EasyFlow 新手引导系统使用说明

## 概述

EasyFlow 新手引导系统为用户提供了完整的功能介绍和使用指导，帮助新用户快速上手应用的各项功能。

## 功能特点

### 1. 首次启动引导
- **欢迎对话框**：首次启动应用时，会弹出欢迎对话框询问用户是否开始新手教程
- **不再提醒选项**：用户可以选择"不再提醒"，跳过后续的自动引导
- **灵活控制**：用户始终可以通过设置手动重新查看教程

### 2. 分页面引导
系统为不同页面提供针对性的引导内容：

#### Home 页面引导（5个步骤）
1. **欢迎介绍** - 应用整体介绍
2. **创建项目** - 介绍如何创建新项目（空白项目、模板、AI生成）
3. **项目列表** - 介绍项目列表的查看和管理
4. **项目操作** - 介绍项目卡片上的编辑、重命名、删除等操作
5. **导入导出** - 介绍项目的导入导出功能

#### Index 页面引导（8个步骤）
1. **页面介绍** - 编辑页面整体布局说明
2. **侧边栏开关** - 介绍如何展开/收起操作面板
3. **添加任务** - 介绍如何创建新任务
4. **任务列表** - 介绍任务列表的使用
5. **画布操作** - 介绍画布的拖动、缩放等操作
6. **工具栏** - 介绍画布工具栏的各项功能
7. **任务详情** - 介绍如何编辑任务详细信息
8. **关键路径** - 介绍关键路径的概念和作用

### 3. 引导交互
- **高亮效果**：自动高亮目标UI元素，引导用户注意力
- **位置智能**：引导提示框根据目标元素位置智能调整显示位置
- **导航控制**：
  - 上一步/下一步按钮
  - 跳过按钮（在第一步可用）
  - 完成按钮（在最后一步显示）
- **进度显示**：显示当前步骤和总步骤数

### 4. 手动访问
用户可以随时通过以下方式查看新手教程：

#### 在 Home 页面
- 点击欢迎页面右下角的 **"?"** 帮助按钮
- 在弹出的设置对话框中选择要查看的教程

#### 在 Index 页面
- 通过侧边栏的设置选项（待实现）
- 或在代码中调用 `startTutorial()` 方法

## 技术实现

### 核心组件

#### 1. TutorialService
- **位置**：`entry/src/main/ets/services/TutorialService.ets`
- **功能**：
  - 管理引导状态（已完成、不再提醒等）
  - 使用 Preferences 持久化存储用户选择
  - 提供 Home 和 Index 页面的引导步骤配置
  - 支持重置引导状态

#### 2. TutorialGuide 组件
- **位置**：`entry/src/main/ets/components/TutorialGuide.ets`
- **功能**：
  - 渲染引导浮层和高亮效果
  - 智能定位目标元素
  - 处理引导导航逻辑
  - 提供流畅的动画效果

#### 3. TutorialWelcomeDialog 组件
- **位置**：`entry/src/main/ets/components/TutorialGuide.ets`
- **功能**：
  - 首次启动欢迎对话框
  - "不再提醒"选项
  - 开始教程/稍后按钮

#### 4. TutorialSettingsDialog 组件
- **位置**：`entry/src/main/ets/components/TutorialSettings.ets`
- **功能**：
  - 手动启动各页面教程
  - 重置所有引导状态
  - 提供教程管理界面

### 集成方式

#### Home.ets 集成
```typescript
// 1. 导入组件
import { TutorialService, TutorialStep, TutorialPage } from '../services/TutorialService';
import { TutorialGuide, TutorialWelcomeDialog } from '../components/TutorialGuide';
import { TutorialSettingsDialog } from '../components/TutorialSettings';

// 2. 状态变量
private tutorialService: TutorialService = TutorialService.getInstance();
@State showTutorial: boolean = false;
@State tutorialSteps: TutorialStep[] = [];
@State currentTutorialStep: TutorialStep | null = null;
@State currentTutorialIndex: number = 0;

// 3. 在 aboutToAppear 中初始化
await this.tutorialService.initialize(context);
setTimeout(async () => {
  await this.checkAndShowTutorial();
}, 500);

// 4. 在 build 方法中渲染
if (this.showTutorial && this.currentTutorialStep) {
  TutorialGuide({
    currentStep: this.currentTutorialStep,
    currentStepIndex: this.currentTutorialIndex,
    totalSteps: this.tutorialSteps.length,
    onNext: () => this.nextTutorialStep(),
    onPrevious: () => this.previousTutorialStep(),
    onSkip: () => this.skipTutorial(),
    onFinish: () => this.finishTutorial()
  })
}
```

#### Index.ets 集成
类似 Home.ets 的集成方式，使用相同的组件和服务。

### 数据持久化

引导状态使用 HarmonyOS Preferences API 存储：

- **tutorial_completed**: 总体引导是否完成
- **never_show_tutorial**: 是否不再显示引导
- **home_tutorial_completed**: Home 页面引导是否完成
- **index_tutorial_completed**: Index 页面引导是否完成

## 自定义引导步骤

### 添加新步骤

在 `TutorialService.ets` 中修改对应的方法：

```typescript
getHomeSteps(): TutorialStep[] {
  return [
    {
      id: 'step_id',
      targetId: 'ui_element_id',  // 可选，目标UI元素的id
      title: '步骤标题',
      description: '详细描述',
      position: 'bottom',  // top, bottom, left, right, center
      highlightPadding: 8,  // 可选，高亮区域的padding
      showSkip: true  // 可选，是否显示跳过按钮
    },
    // 更多步骤...
  ];
}
```

### UI元素ID配置

为了让引导能够准确定位UI元素，需要为关键元素添加 `.id()` 属性：

```typescript
Button('创建项目')
  .id('create_project_button')
  // 其他属性...
```

**当前已配置的ID**：
- Home 页面：
  - `create_project_button` - 创建项目按钮
  - `project_list` - 项目列表
  - `first_project_card` - 第一个项目卡片

- Index 页面：需要根据实际UI添加相应的ID

## 最佳实践

### 1. 引导设计原则
- **简洁明了**：每个步骤聚焦单一功能点
- **循序渐进**：按照用户使用流程组织步骤
- **可跳过**：允许用户随时跳过或退出
- **可重复**：用户可以随时重新查看

### 2. 文案编写
- 使用简短、友好的语言
- 突出操作要点和好处
- 避免技术术语

### 3. 性能考虑
- 延迟显示引导（等待UI加载完成）
- 使用条件渲染避免不必要的组件创建
- 合理设置动画时长

## 维护和更新

### 版本更新时
1. 检查引导步骤是否需要更新
2. 确认UI元素ID是否变化
3. 测试新功能的引导流程

### 问题排查
- **引导不显示**：检查 Preferences 状态，可能需要重置
- **高亮定位不准**：检查目标元素ID是否正确
- **引导内容过时**：更新 TutorialService 中的步骤配置

## 未来改进方向

1. **添加更多交互**：支持用户在引导中直接操作
2. **智能提示**：根据用户行为智能触发相关引导
3. **多语言支持**：国际化引导内容
4. **数据统计**：记录用户引导完成率，优化引导流程
5. **视频教程**：集成视频教程作为补充

## 总结

新手引导系统已完整集成到 EasyFlow 应用中，覆盖了主要功能模块。通过友好的交互设计和灵活的控制选项，帮助用户快速掌握应用使用方法，提升用户体验。
