// File: entry/src/main/ets/pages/Index.ets

import { Project, TaskNode, Dependency } from '../model/ProjectData'
import { Sidebar } from '../components/Sidebar'
// 1. 导入我们新建的服务
import { CriticalPathService } from '../services/CriticalPathService'

@Entry
@Component
struct Index {
  @State project: Project = new Project();
  @State selectedTask: TaskNode | null = null;
  @State isDragging: boolean = false;
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;
  @State isConnecting: boolean = false;

  // 2. 实例化服务
  private cpmService: CriticalPathService = new CriticalPathService();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // --- Data Handling Functions ---

  handleAddTask() {
    // 每次数据变动后，都重新计算关键路径
    const newTask: TaskNode = { id: `task_${Date.now()}`, name: '新任务', duration: 1, x: 50, y: 50 };
    this.project.addTask(newTask);
    this.handleCalculateCriticalPath();
  }

  handleUpdateTask(id: string, name: string, duration: number) {
    const task = this.project.tasks.find(t => t.id === id);
    if (task) {
      task.name = name;
      task.duration = duration;
      this.handleCalculateCriticalPath();
    }
  }

  handleDeleteTask(id: string) {
    if (this.selectedTask?.id === id) { this.selectedTask = null; }
    this.project.tasks = this.project.tasks.filter(t => t.id !== id);
    this.project.dependencies = this.project.dependencies.filter(d => d.fromId !== id && d.toId !== id);
    this.handleCalculateCriticalPath();
  }

  handleStartConnecting() {
    if (this.selectedTask) {
      this.isConnecting = true;
      this.drawGraph();
    }
  }

  // 3. 新增：计算关键路径的主函数
  handleCalculateCriticalPath() {
    this.cpmService.calculate(this.project);
    this.drawGraph(); // 计算完成后立即重绘画布以显示结果
  }

  // --- Canvas Drawing Functions ---

  drawArrowhead(fromX: number, fromY: number, toX: number, toY: number, arrowSize: number = 10) {
    const angle = Math.atan2(toY - fromY, toX - fromX);
    this.context.save();
    this.context.beginPath();
    this.context.translate(toX, toY);
    this.context.rotate(angle);
    this.context.moveTo(0, 0);
    this.context.lineTo(-arrowSize, -arrowSize / 2);
    this.context.lineTo(-arrowSize, arrowSize / 2);
    this.context.closePath();
    this.context.restore();
    this.context.fill();
  }

  drawGraph() {
    this.context.clearRect(0, 0, 3000, 3000);

    // 4. 绘制依赖连线时，检查是否为关键路径
    this.project.dependencies.forEach(dep => {
      const fromNode = this.project.tasks.find(t => t.id === dep.fromId);
      const toNode = this.project.tasks.find(t => t.id === dep.toId);
      if (fromNode && toNode) {
        const isCriticalDep = fromNode.isCritical && toNode.isCritical;
        const fromCenterX = fromNode.x + 150 / 2;
        const fromCenterY = fromNode.y + 70 / 2;
        const toCenterX = toNode.x + 150 / 2;
        const toCenterY = toNode.y + 70 / 2;
        this.context.beginPath();
        this.context.moveTo(fromCenterX, fromCenterY);
        this.context.lineTo(toCenterX, toCenterY);
        this.context.strokeStyle = isCriticalDep ? '#D0021B' : '#666666'; // 关键依赖为红色
        this.context.lineWidth = isCriticalDep ? 3 : 2;
        this.context.stroke();
        this.context.fillStyle = isCriticalDep ? '#D0021B' : '#666666';
        this.drawArrowhead(fromCenterX, fromCenterY, toCenterX, toCenterY);
      }
    });

    // 5. 绘制任务节点时，检查是否为关键节点
    this.project.tasks.forEach(task => {
      this.context.fillStyle = task.isCritical ? '#FADBD8' : '#AECBFA'; // 关键节点用淡红色背景
      this.context.beginPath();
      this.context.rect(task.x, task.y, 150, 70);
      this.context.fill();

      const isSelected = task.id === this.selectedTask?.id;
      this.context.strokeStyle = isSelected ? '#FF8C00' : (task.isCritical ? '#D0021B' : '#4A90E2');
      this.context.lineWidth = isSelected ? 4 : 2;
      this.context.stroke();

      this.context.fillStyle = '#000000';
      this.context.font = 'bold 18px HarmonyOS Sans';
      this.context.fillText(task.name, task.x + 15, task.y + 30);
      this.context.font = '16px HarmonyOS Sans';
      this.context.fillText(`工期: ${task.duration} 天`, task.x + 15, task.y + 55);
    });

    if (this.isConnecting) {
      this.context.fillStyle = 'rgba(0, 0, 0, 0.7)';
      this.context.font = 'bold 24px HarmonyOS Sans';
      this.context.textAlign = 'center';
      this.context.fillText('请选择一个目标任务以创建依赖', 1000, 40);
      this.context.textAlign = 'start';
    }
  }

  build() {
    Row() {
      // 6. 将计算函数传递给侧边栏
      Sidebar({
        project: this.project,
        selectedTask: $selectedTask,
        onAddTask: () => { this.handleAddTask() },
        onUpdateTask: (id, name, duration) => { this.handleUpdateTask(id, name, duration) },
        onDeleteTask: (id) => { this.handleDeleteTask(id) },
        onStartConnecting: () => { this.handleStartConnecting() },
        onCalculate: () => { this.handleCalculateCriticalPath() }
      })
        .layoutWeight(1)

      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .layoutWeight(3)
        .onReady(() => { this.drawGraph(); })
        .onTouch((event: TouchEvent) => {
          const touchX = event.touches[0].x;
          const touchY = event.touches[0].y;
          let hitNode: TaskNode | null = null;
          for (let i = this.project.tasks.length - 1; i >= 0; i--) {
            const task = this.project.tasks[i];
            if (touchX >= task.x && touchX <= task.x + 150 && touchY >= task.y && touchY <= task.y + 70) {
              hitNode = task;
              break;
            }
          }
          if (this.isConnecting) {
            if (event.type === TouchType.Down) {
              if (hitNode && this.selectedTask && hitNode.id !== this.selectedTask.id) {
                const depExists = this.project.dependencies.some(d => d.fromId === this.selectedTask!.id && d.toId === hitNode!.id);
                if (!depExists) {
                  this.project.dependencies.push({ fromId: this.selectedTask.id, toId: hitNode.id });
                  this.handleCalculateCriticalPath(); // 创建依赖后重新计算
                }
              }
              this.isConnecting = false;
              this.drawGraph();
            }
            return;
          }
          switch (event.type) {
            case TouchType.Down:
              this.selectedTask = hitNode;
              if (hitNode) {
                this.isDragging = true;
                this.dragOffsetX = touchX - hitNode.x;
                this.dragOffsetY = touchY - hitNode.y;
              }
              this.drawGraph();
              break;
            case TouchType.Move:
              if (this.isDragging && this.selectedTask) {
                this.selectedTask.x = touchX - this.dragOffsetX;
                this.selectedTask.y = touchY - this.dragOffsetY;
                this.drawGraph();
              }
              break;
            case TouchType.Up:
              this.isDragging = false;
              break;
          }
        })
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      if (this.project.tasks.length === 0) {
        this.project.addTask({ id: 'task1', name: '规划与设计', duration: 3, x: 100, y: 150 });
        this.project.addTask({ id: 'task2', name: '开发阶段', duration: 5, x: 350, y: 250 });
        this.project.dependencies.push({ fromId: 'task1', toId: 'task2' });
        this.handleCalculateCriticalPath(); // 初始加载时计算一次
      }
    })
  }
}
