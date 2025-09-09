// File: entry/src/main/ets/components/ActionButtons.ets

/**
 * 操作按钮组件
 * 提供项目相关的操作按钮
 */
@Component
export struct ActionButtons {
  onAddTask: () => void = () => {};
  onCalculate: () => void = () => {};
  onSave: () => void = () => {};
  onBack: () => void = () => {};
  onStartConnecting: () => void = () => {};

  build() {
    Column({ space: 16 }) {
      // 主要操作按钮
      Row({ space: 16 }) {
        // 返回按钮
        Button() {
          Image($r('app.media.ic_back'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(48)
        .height(48)
        .type(ButtonType.Circle)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 8, color: '#00000012', offsetX: 0, offsetY: 3 })
        .onClick(() => { this.onBack() })

        // 添加任务按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_add'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(48)
        .height(48)
        .backgroundColor('#34C759')
        .borderRadius(24)
        .shadow({ radius: 8, color: '#34C75930', offsetX: 0, offsetY: 3 })
        .onClick(() => { this.onAddTask() })

        // 保存按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_save'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(48)
        .height(48)
        .backgroundColor('#007AFF')
        .borderRadius(24)
        .shadow({ radius: 8, color: '#007AFF30', offsetX: 0, offsetY: 3 })
        .onClick(() => { this.onSave() })

        // 占位拉伸
        Blank().layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 功能按钮
      Column({ space: 12 }) {
        // 计算关键路径按钮
        Button() {
          Row({ space: 10 }) {
            Text('💡')
              .fontSize(18)
              .fontColor(Color.White)
            Text('计算关键路径')
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
        .height(52)
        .backgroundColor('#34C759')
        .borderRadius(12)
        .shadow({ radius: 12, color: '#34C75930', offsetX: 0, offsetY: 4 })
        .onClick(() => { this.onCalculate() })

        // 创建依赖按钮
        Button() {
          Row({ space: 10 }) {
            Text('🔗')
              .fontSize(18)
              .fontColor(Color.White)
            Text('创建依赖关系')
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
        .height(52)
        .backgroundColor('#FF9500')
        .borderRadius(12)
        .shadow({ radius: 12, color: '#FF950030', offsetX: 0, offsetY: 4 })
        .onClick(() => { this.onStartConnecting() })
      }
      .width('100%')
    }
    .width('100%')
  }
}
