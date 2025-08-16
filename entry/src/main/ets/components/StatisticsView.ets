// File: entry/src/main/ets/components/StatisticsView.ets

import { StatisticsService, GlobalStatistics, ProjectStatistics } from '../services/StatisticsService';
import { CommonButton } from './CommonButton';
import { ThemeConfig } from '../utils/ThemeConfig';
import { LoadingView } from './LoadingView';

interface StatCardOptions {
  title: string;
  value: string;
  icon: string;
  color: ResourceColor;
}

interface ActivityItem {
  date: string;
  completedTasks: number;
  newTasks: number;
}

interface CategoryItem {
  category: string;
  count: number;
  percentage: number;
}

@Component
export struct StatisticsView {
  @State globalStats: GlobalStatistics | null = null;
  @State isLoading: boolean = false;
  @State selectedTimeRange: string = 'all';

  onProjectSelect: (projectId: string) => void = () => {};
  onClose: () => void = () => {};

  private statisticsService: StatisticsService = StatisticsService.getInstance();

  async aboutToAppear() {
    await this.loadStatistics();
  }

  async loadStatistics() {
    this.isLoading = true;
    try {
      this.globalStats = await this.statisticsService.getGlobalStatistics();
      console.log('【统计日志】globalStats:', JSON.stringify(this.globalStats));
    } catch (error) {
      console.error('加载统计数据失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 头部
      this.Header()

      if (this.isLoading) {
        this.LoadingState()
      } else if (this.globalStats) {
        // 去除调试用的JSON展示，只保留美观的统计UI
        Scroll() {
          Column({ space: ThemeConfig.spacingL }) {
            // 概览卡片
            this.OverviewCards()

            // 最近活动
            this.RecentActivity()

            // 分类分布
            this.CategoryDistribution()

            // 最活跃项目
            if (this.globalStats.mostActiveProject) {
              this.MostActiveProject()
            }
          }
          .padding(ThemeConfig.spacingL)
        }
        .layoutWeight(1)
      } else {
        this.EmptyState()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeConfig.white)
  }

  @Builder
  Header() {
    Row({ space: ThemeConfig.spacingM }) {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_back'))
          .width(20)
          .height(20)
          .fillColor(ThemeConfig.gray600)
      }
      .width(40)
      .height(40)
      .backgroundColor(ThemeConfig.gray100)
      .onClick(() => {
        this.onClose();
      })

      Text('项目统计')
        .fontSize(ThemeConfig.fontSizeXXL)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeConfig.gray800)
        .layoutWeight(1)

      Button() {
        Text('刷新')
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ThemeConfig.primaryColor)
      }
      .height(32)
      .layoutWeight(48)
      .backgroundColor(ThemeConfig.primaryLight)
      .borderRadius(ThemeConfig.radiusSmall)
      .onClick(() => {
        this.loadStatistics();
      })
    }
    .width('100%')
    .padding(ThemeConfig.spacingL)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  OverviewCards() {
    Grid() {
      // 总项目数
      GridItem() {
        Column({ space: ThemeConfig.spacingS }) {
          Row({ space: ThemeConfig.spacingS }) {
            Text('📁')
              .fontSize(ThemeConfig.fontSizeL)
            Text('总项目数')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ThemeConfig.gray600)
          }
          .alignItems(VerticalAlign.Center)
          Text(this.globalStats ? this.globalStats.totalProjects.toString() : '0')
            .fontSize(ThemeConfig.fontSizeXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeConfig.primaryColor)
        }
        .width('100%')
        .padding(ThemeConfig.spacingM)
        .backgroundColor(ThemeConfig.white)
        .borderRadius(ThemeConfig.radiusMedium)
        .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
        .shadow({ radius: 2, color: ThemeConfig.gray200, offsetX: 0, offsetY: 1 })
      }

      // 总任务数
      GridItem() {
        Column({ space: ThemeConfig.spacingS }) {
          Row({ space: ThemeConfig.spacingS }) {
            Text('📋')
              .fontSize(ThemeConfig.fontSizeL)
            Text('总任务数')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ThemeConfig.gray600)
          }
          .alignItems(VerticalAlign.Center)

          Text(this.globalStats ? this.globalStats.totalTasks.toString() : '0')
            .fontSize(ThemeConfig.fontSizeXL)
            .fontWeight(FontWeight.Bold)
            .fontColor('#10B981')
        }
        .width('100%')
        .padding(ThemeConfig.spacingM)
        .backgroundColor(ThemeConfig.white)
        .borderRadius(ThemeConfig.radiusMedium)
        .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
        .shadow({ radius: 2, color: ThemeConfig.gray200, offsetX: 0, offsetY: 1 })
      }

      // 完成进度
      GridItem() {
        Column({ space: ThemeConfig.spacingS }) {
          Row({ space: ThemeConfig.spacingS }) {
            Text('📈')
              .fontSize(ThemeConfig.fontSizeL)
            Text('整体进度')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ThemeConfig.gray600)
          }
          .alignItems(VerticalAlign.Center)

          Text(this.globalStats ? `${Math.round(this.globalStats.overallProgress)}%` : '0%')
            .fontSize(ThemeConfig.fontSizeXL)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F59E0B')
        }
        .width('100%')
        .padding(ThemeConfig.spacingM)
        .backgroundColor(ThemeConfig.white)
        .borderRadius(ThemeConfig.radiusMedium)
        .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
        .shadow({ radius: 2, color: ThemeConfig.gray200, offsetX: 0, offsetY: 1 })
      }

      // 平均进度
      GridItem() {
        Column({ space: ThemeConfig.spacingS }) {
          Row({ space: ThemeConfig.spacingS }) {
            Text('🎯')
              .fontSize(ThemeConfig.fontSizeL)
            Text('平均进度')
              .fontSize(ThemeConfig.fontSizeS)
              .fontColor(ThemeConfig.gray600)
          }
          .alignItems(VerticalAlign.Center)

          Text(this.globalStats ? `${Math.round(this.globalStats.averageProjectProgress)}%` : '0%')
            .fontSize(ThemeConfig.fontSizeXL)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8B5CF6')
        }
        .width('100%')
        .padding(ThemeConfig.spacingM)
        .backgroundColor(ThemeConfig.white)
        .borderRadius(ThemeConfig.radiusMedium)
        .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
        .shadow({ radius: 2, color: ThemeConfig.gray200, offsetX: 0, offsetY: 1 })
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(ThemeConfig.spacingM)
    .rowsGap(ThemeConfig.spacingM)
  }

  @Builder
  StatCardContent(options: StatCardOptions) {
    Column({ space: ThemeConfig.spacingS }) {
      Row({ space: ThemeConfig.spacingS }) {
        Text(options.icon)
          .fontSize(ThemeConfig.fontSizeL)
        Text(options.title)
          .fontSize(ThemeConfig.fontSizeS)
          .fontColor(ThemeConfig.gray600)
      }
      .alignItems(VerticalAlign.Center)

      Text(options.value)
        .fontSize(ThemeConfig.fontSizeXL)
        .fontWeight(FontWeight.Bold)
        .fontColor(options.color)
    }
    .width('100%')
    .padding(ThemeConfig.spacingM)
    .backgroundColor(ThemeConfig.white)
    .borderRadius(ThemeConfig.radiusMedium)
    .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
    .shadow({ radius: 2, color: ThemeConfig.gray200, offsetX: 0, offsetY: 1 })
  }

  @Builder
  RecentActivity() {
    Column({ space: ThemeConfig.spacingM }) {
      Text('最近7天活动')
        .fontSize(ThemeConfig.fontSizeL)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeConfig.gray800)

      Column({ space: ThemeConfig.spacingS }) {
        if (this.globalStats) {
          ForEach(this.globalStats.recentActivity, (activity: ActivityItem) => {
            Row({ space: ThemeConfig.spacingM }) {
              Text(activity.date)
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray600)
                .width(80)

              Row({ space: ThemeConfig.spacingS }) {
                Text('✅')
                  .fontSize(ThemeConfig.fontSizeS)
                Text(`${activity.completedTasks} 完成`)
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ThemeConfig.gray700)
              }

              Row({ space: ThemeConfig.spacingS }) {
                Text('➕')
                  .fontSize(ThemeConfig.fontSizeS)
                Text(`${activity.newTasks} 新增`)
                  .fontSize(ThemeConfig.fontSizeS)
                  .fontColor(ThemeConfig.gray700)
              }
            }
            .width('100%')
            .padding(ThemeConfig.spacingS)
            .backgroundColor(ThemeConfig.gray50)
            .borderRadius(ThemeConfig.radiusSmall)
          })
        }
      }
    }
    .width('100%')
    .padding(ThemeConfig.spacingM)
    .backgroundColor(ThemeConfig.white)
    .borderRadius(ThemeConfig.radiusMedium)
    .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
  }

  @Builder
  CategoryDistribution() {
    Column({ space: ThemeConfig.spacingM }) {
      Text('项目分类分布')
        .fontSize(ThemeConfig.fontSizeL)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeConfig.gray800)

      Column({ space: ThemeConfig.spacingS }) {
        if (this.globalStats) {
          ForEach(this.globalStats.categoryDistribution, (category: CategoryItem) => {
            Row({ space: ThemeConfig.spacingM }) {
              Text(category.category)
                .fontSize(ThemeConfig.fontSizeM)
                .fontColor(ThemeConfig.gray800)
                .layoutWeight(1)

              Text(`${category.count} 个项目`)
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray600)

              Text(`${category.percentage}%`)
                .fontSize(ThemeConfig.fontSizeS)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeConfig.primaryColor)
            }
            .width('100%')
            .padding(ThemeConfig.spacingS)
            .backgroundColor(ThemeConfig.gray50)
            .borderRadius(ThemeConfig.radiusSmall)
          })
        }
      }
    }
    .width('100%')
    .padding(ThemeConfig.spacingM)
    .backgroundColor(ThemeConfig.white)
    .borderRadius(ThemeConfig.radiusMedium)
    .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
  }

  @Builder
  MostActiveProject() {
    Column({ space: ThemeConfig.spacingM }) {
      Text('最活跃项目')
        .fontSize(ThemeConfig.fontSizeL)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeConfig.gray800)

      Column({ space: ThemeConfig.spacingS }) {
        if (this.globalStats && this.globalStats.mostActiveProject) {
          Row({ space: ThemeConfig.spacingM }) {
            Text('📁')
              .fontSize(ThemeConfig.fontSizeL)
              .fontColor(ThemeConfig.primaryColor)
            
            Column({ space: ThemeConfig.spacingXS }) {
              Text(this.globalStats.mostActiveProject.projectName)
                .fontSize(ThemeConfig.fontSizeM)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeConfig.gray800)
              
              Text(`进度: ${Math.round(this.globalStats.mostActiveProject.progress)}%`)
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray600)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button() {
              Text('查看')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(Color.White)
            }
            .height(28)
            .backgroundColor(ThemeConfig.primaryColor)
            .borderRadius(ThemeConfig.radiusSmall)
            .onClick(() => {
              if (this.globalStats && this.globalStats.mostActiveProject) {
                this.onProjectSelect(this.globalStats.mostActiveProject.projectId);
              }
            })
          }

          Row({ space: ThemeConfig.spacingL }) {
            Column({ space: ThemeConfig.spacingXS }) {
              Text('任务')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray600)
              Text(`${this.globalStats.mostActiveProject.completedTasks}/${this.globalStats.mostActiveProject.totalTasks}`)
                .fontSize(ThemeConfig.fontSizeM)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeConfig.gray800)
            }

            Column({ space: ThemeConfig.spacingXS }) {
              Text('检查项')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray600)
              Text(`${this.globalStats.mostActiveProject.completedChecklistItems}/${this.globalStats.mostActiveProject.totalChecklistItems}`)
                .fontSize(ThemeConfig.fontSizeM)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeConfig.gray800)
            }

            Column({ space: ThemeConfig.spacingXS }) {
              Text('逾期')
                .fontSize(ThemeConfig.fontSizeS)
                .fontColor(ThemeConfig.gray600)
              Text(this.globalStats.mostActiveProject.overdueTasks.toString())
                .fontSize(ThemeConfig.fontSizeM)
                .fontWeight(FontWeight.Medium)
                .fontColor('#EF4444')
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
      }
    }
    .width('100%')
    .padding(ThemeConfig.spacingM)
    .backgroundColor(ThemeConfig.white)
    .borderRadius(ThemeConfig.radiusMedium)
    .border({ width: 1, color: ThemeConfig.gray200, radius: ThemeConfig.radiusMedium })
  }

  @Builder
  LoadingState() {
    Column({ space: ThemeConfig.spacingM }) {
      Column({ space: ThemeConfig.spacingS }) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(ThemeConfig.primaryColor)
        
        Text('加载统计数据...')
          .fontSize(ThemeConfig.fontSizeM)
          .fontColor(ThemeConfig.gray600)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  EmptyState() {
    Column({ space: ThemeConfig.spacingM }) {
      Image($r('app.media.ic_empty_box'))
        .width(80)
        .height(80)
        .opacity(0.6)
      
      Text('暂无统计数据')
        .fontSize(ThemeConfig.fontSizeL)
        .fontColor(ThemeConfig.gray600)
        .fontWeight(FontWeight.Medium)
      
      Text('创建一些项目后即可查看统计信息')
        .fontSize(ThemeConfig.fontSizeS)
        .fontColor(ThemeConfig.gray500)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
} 