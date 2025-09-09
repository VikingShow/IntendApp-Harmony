// File: entry/src/main/ets/components/StorageStatsView.ets
import { StorageService } from '../services/StorageService';

/**
 * 存储统计视图组件
 * 显示存储使用情况和项目统计信息
 */
@Component
export struct StorageStatsView {
  @State totalProjects: number = 0;
  @State totalSize: number = 0;
  @State isLoading: boolean = true;
  
  private storageService: StorageService | null = null;

  async aboutToAppear() {
    const context = getContext(this);
    this.storageService = StorageService.getInstance(context.filesDir);
    await this.loadStats();
  }

  async loadStats() {
    if (!this.storageService) return;
    
    try {
      this.isLoading = true;
      const stats = await this.storageService.getStorageStats();
      this.totalProjects = stats.totalProjects;
      this.totalSize = stats.totalSize;
    } catch (error) {
      console.error('[StorageStatsView] 加载统计信息失败:', error);
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
    Column({ space: 16 }) {
      // 标题
      Row({ space: 8 }) {
        Text('📊')
          .fontSize(20)
          .fontColor('#007DFF')
        Text('存储统计')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        // 加载状态
        Row({ space: 8 }) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color('#007DFF')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#6B7280')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 20, bottom: 20 })
      } else {
        // 统计信息
        Column({ space: 12 }) {
          // 项目数量
          Row() {
            Text('项目总数:')
              .fontSize(14)
              .fontColor('#6B7280')
              .layoutWeight(1)
            Text(this.totalProjects.toString())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2937')
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })

          // 存储大小
          Row() {
            Text('存储大小:')
              .fontSize(14)
              .fontColor('#6B7280')
              .layoutWeight(1)
            Text(this.formatFileSize(this.totalSize))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2937')
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })

          // 刷新按钮
          Button() {
            Row({ space: 6 }) {
              Text('🔄')
                .fontSize(14)
              Text('刷新')
                .fontSize(12)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .height(32)
          .backgroundColor('#007DFF')
          .borderRadius(6)
          .margin({ top: 8 })
          .onClick(() => {
            this.loadStats();
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8FAFC')
        .borderRadius(8)
        .border({ width: 1, color: '#E5E7EB', radius: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
  }
}
