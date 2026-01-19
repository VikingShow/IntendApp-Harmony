// File: entry/src/main/ets/pages/NodeWorkspace_TabsContent.ets
/**
 * NodeWorkspace Tabs 内容的辅助代码片段
 * 用于补充主文件中的 Tab 实现
 */

// 布局 Tab 示例代码
/*
@Builder
private LayoutTab() {
  Column({ space: 16 }) {
    Text('布局组件管理')
      .fontSize(ThemeConfig.fontSizeM)
      .fontWeight(FontWeight.Medium)
      .fontColor(ColorResource.textPrimary);
    
    Button('+ 添加布局组件')
      .width('100%')
      .height(40)
      .onClick(() => {
        this.addComponentToSelectedSchema();
      });
    
    // 组件列表
    if ((this.getSelectedSchema() as NodeSchema).layout.length === 0) {
      Text('暂无布局组件')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ColorResource.textTertiary);
    } else {
      ForEach((this.getSelectedSchema() as NodeSchema).layout, (component: NodeComponentSchema) => {
        // 组件卡片
        Column({ space: 8 }) {
          Text(`组件 ID: ${component.id}`)
            .fontSize(ThemeConfig.fontSizeS);
          
          Button('删除')
            .onClick(() => {
              this.deleteComponentFromSelectedSchema(component.id);
            });
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorResource.surface)
        .borderRadius(8);
      });
    }
  }
  .width('100%')
  .padding(16);
}
*/

// 样式 Tab 示例代码
/*
@Builder
private StyleTab() {
  Column({ space: 16 }) {
    Text('详细样式设置')
      .fontSize(ThemeConfig.fontSizeM)
      .fontWeight(FontWeight.Medium);
    
    // 填充色、边框色、圆角等
    // 可复用现有的样式设置 UI
  }
  .width('100%')
  .padding(16);
}
*/

// 规则 Tab 示例代码
/*
@Builder
private RulesTab() {
  Column({ space: 16 }) {
    Row({ space: 8 }) {
      Text('规则引擎')
        .fontSize(ThemeConfig.fontSizeM)
        .fontWeight(FontWeight.Medium);
      
      Text(`${(this.getSelectedSchema() as NodeSchema).rules?.length || 0}`)
        .fontSize(ThemeConfig.fontSizeXS)
        .fontColor(Color.White)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor(ColorResource.primaryColor)
        .borderRadius(8);
    }
    
    Text('规则引擎允许你创建动态行为，如：字段联动、条件校验等')
      .fontSize(ThemeConfig.fontSizeS)
      .fontColor(ColorResource.textSecondary)
      .lineHeight(18);
    
    Button('+ 添加规则')
      .width('100%')
      .height(40)
      .onClick(() => {
        // TODO: 实现添加规则对话框
        this.promptAction.showToast({ message: '规则编辑器开发中' });
      });
    
    if (!(this.getSelectedSchema() as NodeSchema).rules || (this.getSelectedSchema() as NodeSchema).rules!.length === 0) {
      Column({ space: 8 }) {
        Text('暂无规则')
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ColorResource.textTertiary);
        
        Text('示例规则：当"优先级"字段为"高"时，自动设置"颜色"字段为红色')
          .fontSize(ThemeConfig.fontSizeXS)
          .fontColor(ColorResource.textTertiary)
          .lineHeight(16);
      }
      .width('100%')
      .padding(16)
      .backgroundColor(ColorResource.backgroundSecondary)
      .borderRadius(8);
    } else {
      // 规则列表
      Column({ space: 8 }) {
        ForEach((this.getSelectedSchema() as NodeSchema).rules!, (rule: NodeRule) => {
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              Text(rule.name)
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1);
              
              Text(rule.enabled === false ? '禁用' : '启用')
                .fontSize(ThemeConfig.fontSizeXS)
                .fontColor(rule.enabled === false ? ColorResource.textTertiary : '#34C759');
            }
            
            Text(`事件: ${rule.event}`)
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textSecondary);
            
            Text(`条件: ${rule.conditions.length} 个`)
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textSecondary);
            
            Text(`动作: ${rule.actions.length} 个`)
              .fontSize(ThemeConfig.fontSizeXS)
              .fontColor(ColorResource.textSecondary);
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorResource.surface)
          .borderRadius(8);
        });
      }
    }
  }
  .width('100%')
  .padding(16);
}
*/

// JSON Tab 示例代码
/*
@Builder
private JsonTab() {
  Column({ space: 16 }) {
    Row({ space: 8 }) {
      Text('{ } JSON 视图')
        .fontSize(ThemeConfig.fontSizeM)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1);
      
      Button('复制')
        .height(32)
        .fontSize(ThemeConfig.fontSizeXS)
        .onClick(() => {
          // TODO: 复制到剪贴板
          this.promptAction.showToast({ message: '已复制' });
        });
    }
    
    Text('只读视图，查看当前节点类型的完整 JSON 配置')
      .fontSize(ThemeConfig.fontSizeS)
      .fontColor(ColorResource.textSecondary)
      .lineHeight(18);
    
    TextArea({
      text: JSON.stringify(this.getSelectedSchema(), null, 2),
      placeholder: ''
    })
      .width('100%')
      .height(400)
      .fontSize(ThemeConfig.fontSizeXS)
      .fontColor(ColorResource.textPrimary)
      .backgroundColor(ColorResource.backgroundSecondary)
      .borderRadius(8)
      .padding(12)
      .enabled(false); // 只读
  }
  .width('100%')
  .padding(16);
}
*/
