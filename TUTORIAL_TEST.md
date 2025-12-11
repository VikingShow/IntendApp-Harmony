# 新手引导测试指南

## 问题诊断

如果引导显示但没有内容，可能的原因：

### 1. 检查控制台日志
运行应用后，查看控制台是否有以下日志：
```
[Home] Tutorial started, steps count: 5
[Home] First step: {...}
[TutorialGuide] aboutToAppear, currentStep: {...}
```

### 2. 测试引导功能

#### 方法1：手动触发（推荐）
1. 启动应用
2. 在欢迎页面，点击右下角的 **"?"** 帮助按钮
3. 在弹出的对话框中，点击 **"开始"** 按钮（主页引导）
4. 应该看到引导浮层，显示：
   - 标题："欢迎使用 EasyFlow"
   - 描述："EasyFlow 是一款项目管理和思维导图工具..."
   - 按钮："跳过"、"下一步"

#### 方法2：重置引导状态
1. 打开应用设置
2. 清除应用数据或重新安装
3. 首次启动时应该自动弹出欢迎对话框

#### 方法3：使用设置对话框
1. 点击欢迎页右下角的 "?" 按钮
2. 在设置对话框中点击"重置所有引导"
3. 重启应用，应该显示首次引导

## 快速验证

在 Home.ets 的 `checkAndShowTutorial` 方法中，临时修改为强制显示：

```typescript
private async checkAndShowTutorial() {
  // 临时强制显示，用于测试
  this.startTutorial();
  return;
  
  const shouldShow = await this.tutorialService.shouldShowTutorial(TutorialPage.HOME);
  console.log(`[Home] Should show tutorial: ${shouldShow}`);
  
  if (shouldShow) {
    this.showTutorialWelcomeDialog();
  }
}
```

## 预期效果

### 引导浮层应该显示：
- 深色半透明背景遮罩
- 白色提示框（居中或在目标元素附近）
- 标题文字（白色，20号字体）
- 描述文字（半透明白色，15号字体）
- 进度指示："1 / 5"
- 导航按钮

### 如果仍然没有内容
检查以下几点：
1. `currentStep` 是否为 null
2. `showTutorial` 是否为 true
3. TutorialGuide 组件是否正确渲染
4. 文字颜色是否与背景冲突（都是白色或都是黑色）

## 调试建议

在 TutorialGuide.ets 的 build 方法中添加测试文本：

```typescript
build() {
  Stack({ alignContent: Alignment.TopStart }) {
    if (!this.currentStep) {
      Column()
        .width(0)
        .height(0)
    } else {
      // 添加测试背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255, 0, 0, 0.5)') // 红色半透明，容易看到
        .onClick(() => {})

      // 测试固定文本
      Text('测试文本 - 如果能看到这个说明组件已显示')
        .fontSize(30)
        .fontColor(Color.Yellow)
        .position({ x: 100, y: 100 })
      
      // 原有内容...
    }
  }
}
```
