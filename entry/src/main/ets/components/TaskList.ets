// File: entry/src/main/ets/components/TaskList.ets

import { Project, TaskNode } from '../model/ProjectData';

/**
 * 任务列表组件
 * 显示项目中的任务列表，支持排序和筛选
 */
@Component
export struct TaskList {
  @ObjectLink project: Project;
  @Prop selectedTask: TaskNode | null;
  @State sortBy: 'startDate' | 'endDate' | 'name' | 'critical' = 'startDate';
  @State sortOrder: 'asc' | 'desc' = 'asc';
  @State filterCritical: boolean = false;

  onTaskSelect: (task: TaskNode) => void = () => {};

  /**
   * 获取排序后的任务列表
   */
  private getSortedTasks(): TaskNode[] {
    let tasks = [...this.project.tasks];

    // 筛选关键任务
    if (this.filterCritical) {
      tasks = tasks.filter(task => task.isCritical);
    }

    // 排序
    tasks.sort((a, b) => {
      let comparison = 0;
      
      switch (this.sortBy) {
        case 'startDate':
          comparison = a.startDate.getTime() - b.startDate.getTime();
          break;
        case 'endDate':
          comparison = a.endDate.getTime() - b.endDate.getTime();
          break;
        case 'name':
          comparison = a.name.localeCompare(b.name);
          break;
        case 'critical':
          comparison = (a.isCritical ? 1 : 0) - (b.isCritical ? 1 : 0);
          break;
      }

      return this.sortOrder === 'asc' ? comparison : -comparison;
    });

    return tasks;
  }

  /**
   * 切换排序方式
   */
  private toggleSort(sortBy: 'startDate' | 'endDate' | 'name' | 'critical'): void {
    if (this.sortBy === sortBy) {
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortBy = sortBy;
      this.sortOrder = 'asc';
    }
  }

  /**
   * 获取任务完成进度
   */
  private getTaskProgress(task: TaskNode): number {
    if (!task.checklist || task.checklist.length === 0) {
      return 0;
    }
    const completedCount = task.checklist.filter(item => item.isCompleted).length;
    return Math.round((completedCount / task.checklist.length) * 100);
  }

  /**
   * 获取任务工期
   */
  private getTaskDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  /**
   * 获取任务状态颜色
   */
  private getTaskStatusColor(task: TaskNode): string {
    const now = new Date();
    if (task.endDate < now) {
      return '#FF3B30'; // 已过期 - 红色
    } else if (task.startDate <= now && task.endDate >= now) {
      return '#FF9500'; // 进行中 - 橙色
    } else {
      return '#007AFF'; // 未开始 - 蓝色
    }
  }

  /**
   * 获取任务状态文本
   */
  private getTaskStatusText(task: TaskNode): string {
    const now = new Date();
    if (task.endDate < now) {
      return '已过期';
    } else if (task.startDate <= now && task.endDate >= now) {
      return '进行中';
    } else {
      return '未开始';
    }
  }

  build() {
    Column({ space: 16 }) {
      // 标题和筛选区域
      Row({ space: 12 }) {
        Text('任务列表')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1D1D1F')
          .layoutWeight(1)

        // 关键任务筛选按钮
        Button() {
          Text('🔥')
            .fontSize(16)
            .fontColor(this.filterCritical ? '#FFFFFF' : '#FF3B30')
        }
        .width(40)
        .height(40)
        .type(ButtonType.Circle)
        .backgroundColor(this.filterCritical ? '#FF3B30' : '#FEF2F2')
        .border({ 
          width: 1, 
          color: this.filterCritical ? '#FF3B30' : '#FECACA', 
          radius: 20 
        })
        .onClick(() => {
          this.filterCritical = !this.filterCritical;
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 排序选项
      Row({ space: 8 }) {
        this.SortButton('startDate')
        this.SortButton('endDate')
        this.SortButton('name')
        this.SortButton('critical')
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 任务列表
      if (this.getSortedTasks().length === 0) {
        Column({ space: 16 }) {
          Image($r('app.media.ic_empty_box'))
            .width(64)
            .height(64)
            .opacity(0.4)
          Text('暂无任务')
            .fontSize(15)
            .fontColor('#86868B')
          Text(this.filterCritical ? '没有关键任务' : '点击上方按钮添加新任务')
            .fontSize(13)
            .fontColor('#86868B')
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      } else {
        List({ space: 12 }) {
          ForEach(this.getSortedTasks(), (task: TaskNode) => {
            ListItem() {
              Row({ space: 12 }) {
                // 任务状态指示器
                Column()
                  .width(4)
                  .height(44)
                  .backgroundColor(this.getTaskStatusColor(task))
                  .borderRadius(2)

                // 任务信息
                Column({ space: 6 }) {
                  Row({ space: 8 }) {
                    Text(task.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1D1D1F')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)

                    // 任务状态
                    Text(this.getTaskStatusText(task))
                      .fontSize(12)
                      .fontColor(this.getTaskStatusColor(task))
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')

                  // 日期信息
                  Text(`${task.startDate.toLocaleDateString()} - ${task.endDate.toLocaleDateString()} (${this.getTaskDuration(task)}天)`)
                    .fontSize(13)
                    .fontColor('#86868B')

                  // 进度信息
                  if (task.checklist && task.checklist.length > 0) {
                    Row({ space: 8 }) {
                      Text(`进度: ${this.getTaskProgress(task)}%`)
                        .fontSize(12)
                        .fontColor('#007AFF')
                        .fontWeight(FontWeight.Medium)

                      Progress({ 
                        value: this.getTaskProgress(task), 
                        total: 100, 
                        type: ProgressType.Linear 
                      })
                        .width(80)
                        .height(4)
                        .color('#007AFF')
                        .backgroundColor('#E5E5E7')
                        .borderRadius(2)
                    }
                    .width('100%')
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(18)
              .backgroundColor(this.selectedTask?.id === task.id ? '#F0F8FF' : '#FFFFFF')
              .borderRadius(12)
              .shadow({ 
                radius: 8, 
                color: this.selectedTask?.id === task.id ? '#007AFF20' : '#0000000A', 
                offsetX: 0, 
                offsetY: 2 
              })
              .border({ 
                width: this.selectedTask?.id === task.id ? 2 : 0, 
                color: '#007AFF', 
                radius: 12 
              })
              .onClick(() => {
                this.onTaskSelect(task);
              })
            }
          })
        }
        .height('100%')
        .width('100%')
        .layoutWeight(1)
      }
    }
    .layoutWeight(1)
  }

  /**
   * 获取排序按钮文本
   */
  private getSortButtonText(sortType: 'startDate' | 'endDate' | 'name' | 'critical'): string {
    let text: string = '';
    switch (sortType) {
      case 'startDate':
        text = '开始时间';
        break;
      case 'endDate':
        text = '结束时间';
        break;
      case 'name':
        text = '任务名称';
        break;
      case 'critical':
        text = '关键任务';
        break;
    }
    
    const order = this.sortBy === sortType ? (this.sortOrder === 'asc' ? '↑' : '↓') : '';
    return `${text}${order}`;
  }

  /**
   * 排序按钮构建器
   */
  @Builder
  SortButton(sortType: 'startDate' | 'endDate' | 'name' | 'critical') {
    Button() {
      Text(this.getSortButtonText(sortType))
        .fontSize(12)
        .fontColor(this.sortBy === sortType ? '#FFFFFF' : '#666666')
    }
    .width(60)
    .height(32)
    .backgroundColor(this.sortBy === sortType ? '#007AFF' : '#F5F5F7')
    .borderRadius(8)
    .onClick(() => {
      this.toggleSort(sortType);
    })
  }
}
