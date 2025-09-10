// File: entry/src/main/ets/components/StorageStatsDialog.ets
import { StorageService } from '../services/StorageService';

/**
 * 存储统计对话框组件
 * 以弹窗形式显示存储使用情况和项目统计信息
 */
@Component
export struct StorageStatsDialog {
  @Prop visible: boolean = false;
  onClose: () => void = () => {};
  
  @State totalProjects: number = 0;
  @State totalSize: number = 0;
  @State isLoading: boolean = true;
  
  private storageService: StorageService | null = null;

  async aboutToAppear() {
    if (this.visible) {
      const context = getContext(this);
      this.storageService = StorageService.getInstance(context.filesDir);
      await this.loadStats();
    }
  }

  async onVisibleChange() {
    if (this.visible && this.storageService) {
      await this.loadStats();
    }
  }

  async loadStats() {
    if (!this.storageService) return;
    
    try {
      this.isLoading = true;
      const stats = await this.storageService.getStorageStats();
      this.totalProjects = stats.totalProjects;
      this.totalSize = stats.totalSize;
    } catch (error) {
      console.error('[StorageStatsDialog] 加载统计信息失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 格式化文件大小
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  build() {
    if (this.visible) {
      Column() {
        // 背景遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onClose();
          })

        // 对话框内容
        Column({ space: 20 }) {
          // 标题栏
          Row() {
            Text('📊')
              .fontSize(24)
              .fontColor('#007DFF')
            Text('存储统计')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2937')
              .layoutWeight(1)
            Button() {
              Text('✕')
                .fontSize(18)
                .fontColor('#6B7280')
            }
            .width(32)
            .height(32)
            .backgroundColor(Color.Transparent)
            .borderRadius(16)
            .onClick(() => {
              this.onClose();
            })
          }
          .width('100%')
          .padding({ top: 20, left: 20, right: 20 })

          if (this.isLoading) {
            // 加载状态
            Column({ space: 16 }) {
              LoadingProgress()
                .width(32)
                .height(32)
                .color('#007DFF')
              Text('加载中...')
                .fontSize(16)
                .fontColor('#6B7280')
            }
            .width('100%')
            .padding({ top: 40, bottom: 40 })
            .justifyContent(FlexAlign.Center)
          } else {
            // 统计信息
            Column({ space: 20 }) {
              // 项目数量卡片
              Row() {
                Column({ space: 8 }) {
                  Text('📁')
                    .fontSize(32)
                    .fontColor('#007DFF')
                  Text('项目总数')
                    .fontSize(14)
                    .fontColor('#6B7280')
                  Text(this.totalProjects.toString())
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1F2937')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
                .padding(20)
                .backgroundColor('#F8FAFC')
                .borderRadius(12)
                .border({ width: 1, color: '#E5E7EB', radius: 12 })

                // 存储大小卡片
                Column({ space: 8 }) {
                  Text('💾')
                    .fontSize(32)
                    .fontColor('#10B981')
                  Text('存储大小')
                    .fontSize(14)
                    .fontColor('#6B7280')
                  Text(this.formatFileSize(this.totalSize))
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1F2937')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
                .padding(20)
                .backgroundColor('#F0FDF4')
                .borderRadius(12)
                .border({ width: 1, color: '#BBF7D0', radius: 12 })
              }
              .width('100%')

              // 刷新按钮
              Button() {
                Row({ space: 8 }) {
                  Text('🔄')
                    .fontSize(16)
                  Text('刷新统计')
                    .fontSize(16)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
                }
              }
              .width('100%')
              .height(44)
              .backgroundColor('#007DFF')
              .borderRadius(8)
              .onClick(() => {
                this.loadStats();
              })
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 20 })
          }
        }
        .width('90%')
        .constraintSize({ maxWidth: 400 })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 20, color: '#00000020', offsetX: 0, offsetY: 10 })
        .position({ x: '5%', y: '20%' })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }
  }
}
