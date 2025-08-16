// File: entry/src/main/ets/components/DashboardView.ets
import { Project, TaskNode } from '../model/ProjectData';
import router from '@ohos.router';

@Component
export struct DashboardView {
  // 接收从HomePage传递过来的完整项目数据
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
    Scroll() {
      Column({ space: 20 }) {
        // 1. 项目标题和进入编辑按钮
        Row() {
          Text(this.project.name)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
            .fontColor('#1F2937')

          Button({ type: ButtonType.Capsule }) {
            Row({ space: 8 }) {
              Image($r('app.media.ic_edit'))
                .width(20)
                .height(20)
                .fillColor(Color.White)
              Text('进入编辑')
                .fontSize(17)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
          }
          .height(48)
          .width(120)
          .backgroundColor('#007DFF')
          .shadow({ radius: 6, color: '#007DFF30', offsetX: 0, offsetY: 3 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/Index',
              params: { projectId: this.project.id }
            } as router.RouterOptions);
          })
        }
        .width('100%')

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

        // 调试信息
        Text(`当前项目: ${this.project.name} (ID: ${this.project.id})`)
          .fontSize(12)
          .fontColor('#6B7280')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })

        // 3. 即将到期的任务列表
        Column({ space: 12 }) {
          Row({ space: 8 }) {
            Text('即将到期的任务 (未来7天)')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2937')
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
            Column({ space: 8 }) {
              Image($r('app.media.ic_empty_box'))
                .width(40)
                .height(40)
                .opacity(0.5)
              Text('未来7天内没有到期的任务')
                .fontSize(14)
                .fontColor('#9CA3AF')
            }
            .width('100%')
            .padding(24)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .padding(30)
      .width('100%')
    }
  }

  // 构建器：统计卡片
  @Builder
  StatCard(title: string, value: string, bgColor: string, textColor: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(14)
        .fontColor('#6B7280')
        .fontWeight(FontWeight.Medium)
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(textColor)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(bgColor)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 })
  }

  // 构建器：即将到期的任务卡片
  @Builder
  UpcomingTaskCard(task: TaskNode) {
    Row({ space: 12 }) {
      // 任务状态指示器
      Column()
        .width(4)
        .height(40)
        .backgroundColor(task.isCritical ? '#DC2626' : '#F59E0B')
        .borderRadius(2)

      // 任务信息
      Column({ space: 4 }) {
        Text(task.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`截止于: ${task.endDate.toLocaleDateString()}`)
          .fontSize(12)
          .fontColor('#F59E0B')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 关键任务标识
      if (task.isCritical) {
        Text('🔥')
          .fontSize(14)
          .fontColor('#DC2626')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 })
    .border({ width: 1, color: '#FEF3C7', radius: 10 })
  }
}
