// File: entry/src/main/ets/components/DashboardView.ets
import { Project, TaskNode } from '../model/ProjectData';
import router from '@ohos.router';

@Component
export struct DashboardView {
  // 接收从HomePage传递过来的完整项目数据
  @ObjectLink project: Project;
  // 新增：用于存储计算结果的状态变量
  @State upcomingTasks: TaskNode[] = [];

  // aboutToAppear 会在组件首次创建和显示时调用
  aboutToAppear() {
    this.updateUpcomingTasks();
  }

  // aboutToUpdate 会在 @ObjectLink project 的数据发生变化时调用
  aboutToUpdate() {
    this.updateUpcomingTasks();
  }

  // 封装一个统一的更新函数
  private updateUpcomingTasks() {
    this.upcomingTasks = this.getUpcomingTasks();
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
    return Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
  }

  private getOverallCompletion(): number {
    if (!this.project || this.project.tasks.length === 0) return 0;
    const totalChecklistItems = this.project.tasks.reduce((sum, task) => sum + task.checklist.length, 0);
    if (totalChecklistItems === 0) return 0;
    const completedItems = this.project.tasks.reduce((sum, task) => {
      return sum + task.checklist.filter(item => item.isCompleted).length;
    }, 0);
    return Math.round((completedItems / totalChecklistItems) * 100);
  }

  private getCriticalTasksCount(): number {
    return this.project.tasks.filter(t => t.isCritical).length;
  }

  private getUpcomingTasks(): TaskNode[] {
    const now = new Date();
    const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    return this.project.tasks
      .filter(task => task.endDate >= now && task.endDate <= sevenDaysLater)
      .sort((a, b) => a.endDate.getTime() - b.endDate.getTime());
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

          Button({ type: ButtonType.Capsule }) {
            Row({ space: 8 }) {
              Image($r('app.media.ic_edit')).width(18).height(18).fillColor(Color.White)
              Text('进入编辑').fontSize(16).fontColor(Color.White)
            }
          }
          .backgroundColor('#007DFF')
          .onClick(() => {
            router.pushUrl({
              url: 'pages/Index',
              params: { projectId: this.project.id }
            });
          })
        }
        .width('100%')

        // 2. 核心指标统计
        GridRow({
          columns: 4,
          gutter: { x: 15, y: 15 }
        }) {
          GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
            this.StatCard('总任务数', `${this.project.tasks.length}个`, '#E0EFFF')
          }
          GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
            this.StatCard('项目总工期', `${this.getTotalDuration()}天`, '#E8F5E9')
          }
          GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
            this.StatCard('整体完成度', `${this.getOverallCompletion()}%`, '#FFF3E0')
          }
          GridCol({ span: { xs: 4, sm: 2, md: 1 } }) {
            this.StatCard('关键任务数', `${this.getCriticalTasksCount()}个`, '#FFEBEE')
          }
        }

        // 3. 即将到期的任务列表
        Column({ space: 10 }) {
          Text('即将到期的任务 (未来7天)')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Start)

          // 直接使用状态变量来渲染UI
          if (this.upcomingTasks.length > 0) {
            List({ space: 8 }) {
              ForEach(this.upcomingTasks, (task: TaskNode) => {
                ListItem() {
                  this.UpcomingTaskCard(task)
                }
              })
            }
          } else {
            Text('未来7天内没有到期的任务。')
              .fontColor(Color.Gray)
              .padding(20)
              .width('100%')
              .textAlign(TextAlign.Center)
              .backgroundColor(Color.White)
              .borderRadius(12)
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
  StatCard(title: string, value: string, bgColor: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(14)
        .fontColor(Color.Gray)
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  // 构建器：即将到期的任务卡片
  @Builder
  UpcomingTaskCard(task: TaskNode) {
    Row({ space: 15 }) {
      Text(task.name)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(`截止于: ${task.endDate.toLocaleDateString()}`)
        .fontSize(14)
        .fontColor('#FFA500') // 橙色预警
    }
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}
