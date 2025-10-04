// File: entry/src/main/ets/components/DashboardView.ets
/**
 * 项目仪表板视图组件
 *
 * 本组件是项目概览页面的核心展示组件，提供项目关键信息的可视化展示。
 * 采用卡片式布局设计，展示项目统计信息、进度概览和即将到期的任务。
 *
 * 主要功能：
 * 1. 项目概览：显示项目基本信息和关键统计数据
 * 2. 进度统计：展示项目整体完成度和时间进度
 * 3. 任务概览：显示任务总数、关键任务数等统计信息
 * 4. 即将到期：列出未来7天内即将到期的任务
 * 5. 快速操作：提供进入编辑页面的快速入口
 * 6. 响应式设计：根据数据变化自动更新显示内容
 *
 * 设计特点：
 * - 卡片式布局：使用卡片组件组织不同类型的信息
 * - 数据驱动：基于项目数据动态计算和显示统计信息
 * - 响应式更新：使用@ObjectLink实现数据的响应式绑定
 * - 视觉层次：通过颜色、大小、间距建立清晰的信息层次
 * - 交互友好：提供清晰的视觉反馈和操作引导
 *
 * 统计指标：
 * - 总任务数：项目中所有任务的数量
 * - 项目总工期：从最早开始到最晚结束的总时间
 * - 整体完成度：基于检查清单完成情况的进度百分比
 * - 关键任务数：关键路径上的任务数量
 * - 即将到期：未来7天内到期的任务列表
 *
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */

import { Project, TaskNode } from '../model/ProjectData';
import router from '@ohos.router';

/**
 * 项目仪表板视图组件
 *
 * 展示项目概览信息的核心UI组件，采用响应式设计自动更新显示内容。
 * 使用@ObjectLink装饰器实现与项目数据的双向绑定，确保数据变化时自动更新界面。
 *
 * 组件特性：
 * - 响应式数据绑定：使用@ObjectLink实现数据的自动同步
 * - 统计信息计算：实时计算项目的各种统计指标
 * - 卡片式布局：使用网格布局展示不同类型的统计信息
 * - 交互式设计：提供进入编辑页面的快速操作入口
 * - 空状态处理：优雅处理无数据或加载中的状态
 *
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2024-01-01
 */
@Component
export struct DashboardView {
  /** 项目数据对象，使用@ObjectLink实现响应式绑定 */
  @ObjectLink project: Project;

  // aboutToAppear 会在组件首次创建和显示时调用
  aboutToAppear() {
    console.log(`[DashboardView] Component appeared for project: ${this.project.name} with ${this.project.tasks.length} tasks`);
  }

  // aboutToUpdate 会在 @ObjectLink project 的数据发生变化时调用
  aboutToUpdate() {
    console.log(`[DashboardView] Project data updated: ${this.project.name} with ${this.project.tasks.length} tasks`);
  }




  // --- Helper Functions to calculate stats ---
  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  private getTotalDuration(): number {
    if (!this.project || this.project.tasks.length === 0) return 0;
    const startDates = this.project.tasks.map(t => t.startDate.getTime());
    const endDates = this.project.tasks.map(t => t.endDate.getTime());
    const minStart = Math.min(...startDates);
    const maxEnd = Math.max(...endDates);
    const diffTime = maxEnd - minStart;
    const duration = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    console.log(`[DashboardView] Project "${this.project.name}" total duration: ${duration} days (from ${new Date(minStart).toLocaleDateString()} to ${new Date(maxEnd).toLocaleDateString()})`);
    return duration;
  }

  private getOverallCompletion(): number {
    if (!this.project || this.project.tasks.length === 0) return 0;
    const totalChecklistItems = this.project.tasks.reduce((sum, task) => sum + task.checklist.length, 0);
    if (totalChecklistItems === 0) return 0;
    const completedItems = this.project.tasks.reduce((sum, task) => {
      return sum + task.checklist.filter(item => item.isCompleted).length;
    }, 0);
    const completion = Math.round((completedItems / totalChecklistItems) * 100);
    console.log(`[DashboardView] Project "${this.project.name}" overall completion: ${completion}% (${completedItems}/${totalChecklistItems} checklist items completed)`);
    return completion;
  }

  private getCriticalTasksCount(): number {
    const count = this.project.tasks.filter(t => t.isCritical).length;
    console.log(`[DashboardView] Project "${this.project.name}" critical tasks count: ${count}/${this.project.tasks.length}`);
    return count;
  }

  private getUpcomingTasks(): TaskNode[] {
    const now = new Date();
    const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const upcoming = this.project.tasks
      .filter(task => task.endDate >= now && task.endDate <= sevenDaysLater)
      .sort((a, b) => a.endDate.getTime() - b.endDate.getTime());
    console.log(`[DashboardView] Project "${this.project.name}" upcoming tasks: ${upcoming.length} tasks in next 7 days`);
    return upcoming;
  }

  build() {
    // build() 方法现在是纯粹的UI描述，不再包含业务逻辑计算
    Column({ space: 20 }) {
      // 1. 项目标题和进入编辑按钮 - 简约设计
      Column({ space: 24 }) {
        Row() {
          Column({ space: 12 }) {
            Text(this.project.name)
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(1)
              .fontColor('#1E293B')
            Text(`项目ID: ${this.project.id}`)
              .fontSize(15)
              .fontColor('#64748B')
              .fontWeight(FontWeight.Medium)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button() {
            Row({ space: 10 }) {
              Text('编辑')
                .fontSize(17)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
          }
          .height(56)
          .padding({ left: 28, right: 28 })
          .backgroundColor('#007DFF')
          .borderRadius(20)
          .shadow({ radius: 6, color: '#007DFF20', offsetX: 0, offsetY: 3 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/Index',
              params: { projectId: this.project.id }
            } as router.RouterOptions);
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(28)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .shadow({ radius: 6, color: '#00000006', offsetX: 0, offsetY: 3 })
      .border({ width: 1, color: '#E2E8F0', radius: 24 })

      // 2. 核心指标统计
      GridRow({
        columns: 4,
        gutter: { x: 16, y: 16 }
      }) {
        GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
          this.StatCard('总任务数', `${this.project.tasks.length}个`, '#EFF6FF', '#007DFF')
        }
        GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
          this.StatCard('项目总工期', `${this.getTotalDuration()}天`, '#F0FDF4', '#16A34A')
        }
        GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
          this.StatCard('整体完成度', `${this.getOverallCompletion()}%`, '#FEF3C7', '#D97706')
        }
        GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
          this.StatCard('关键任务数', `${this.getCriticalTasksCount()}个`, '#FEF2F2', '#DC2626')
        }
      }

      // 3. 即将到期的任务列表 - 简约设计
      Column({ space: 20 }) {
        Row({ space: 16 }) {
          Text('即将到期的任务')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1E293B')
          Text('(未来7天)')
            .fontSize(15)
            .fontColor('#64748B')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 直接计算即将到期的任务
        if (this.getUpcomingTasks().length > 0) {
          List({ space: 8 }) {
            ForEach(this.getUpcomingTasks(), (task: TaskNode) => {
              ListItem() {
                this.UpcomingTaskCard(task)
              }
            })
          }
        } else {
          // 没有即将到期的任务 - 简约设计
          Column({ space: 24 }) {
            Column({ space: 12 }) {
              Text('暂无即将到期的任务')
                .fontSize(20)
                .fontColor('#1E293B')
                .fontWeight(FontWeight.Bold)
              Text('很好！所有任务都在计划时间内')
                .fontSize(15)
                .fontColor('#64748B')
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .padding(48)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .shadow({ radius: 6, color: '#00000006', offsetX: 0, offsetY: 3 })
          .border({ width: 1, color: '#E2E8F0', radius: 20 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(30)
    .backgroundColor('#F9FAFB')
  }

  // 构建器：统计卡片 - 简约设计
  @Builder
  StatCard(title: string, value: string, bgColor: string, textColor: string) {
    Column({ space: 16 }) {
      Text(title)
        .fontSize(15)
        .fontColor('#64748B')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
      Text(value)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(textColor)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(28)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 6, color: '#00000006', offsetX: 0, offsetY: 3 })
    .border({ width: 1, color: '#E2E8F0', radius: 20 })
    .alignItems(HorizontalAlign.Center)
  }

  // 构建器：即将到期的任务卡片 - 简约设计
  @Builder
  UpcomingTaskCard(task: TaskNode) {
    Row({ space: 20 }) {
      // 任务信息 - 简约设计
      Column({ space: 8 }) {
        Text(task.name)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E293B')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 12 }) {
          Text(`截止于: ${task.endDate.toLocaleDateString()}`)
            .fontSize(13)
            .fontColor('#64748B')
          if (task.isCritical) {
            Text('关键任务')
              .fontSize(11)
              .fontColor('#DC2626')
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#FEF2F2')
              .borderRadius(6)
              .border({ width: 1, color: '#FECACA', radius: 6 })
          }
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 6, color: '#00000006', offsetX: 0, offsetY: 3 })
    .border({ width: 1, color: '#E2E8F0', radius: 20 })
  }
}
