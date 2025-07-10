// File: entry/src/main/ets/pages/Index.ets

import { Project, TaskNode, Dependency } from '../model/ProjectData'
import { Sidebar } from '../components/Sidebar'
import { CriticalPathService } from '../services/CriticalPathService'

@Entry
@Component
struct Index {
  // --- 基础状态 ---
  @State project: Project = new Project();
  @State selectedTask: TaskNode | null = null;
  @State isConnecting: boolean = false;

  // --- 拖拽节点状态 ---
  @State isDraggingNode: boolean = false;
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;

  private cpmService: CriticalPathService = new CriticalPathService();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // --- Data Handling Functions ---
  handleUpdateProjectName(newName: string) {
    this.project.name = newName;
  }

  handleAddTask() {
    // 恢复到简单的添加逻辑
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

  handleCalculateCriticalPath() {
    this.cpmService.calculate(this.project);
    this.drawGraph();
  }

  // --- Canvas Drawing Functions ---
  drawArrowhead(fromX: number, fromY: number, toX: number, toY: number, arrowSize: number = 10) {
    if (Math.abs(fromX - toX) < 1 && Math.abs(fromY - toY) < 1) {
      return;
    }
    const angle = Math.atan2(toY - fromY, toX - fromX);
    if (isNaN(angle)) {
      return;
    }
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

    // 移除了 save/restore 和 transform
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
        this.context.strokeStyle = isCriticalDep ? '#D0021B' : '#666666';
        this.context.lineWidth = isCriticalDep ? 3 : 2;
        this.context.stroke();
        this.context.fillStyle = isCriticalDep ? '#D0021B' : '#666666';
        this.drawArrowhead(fromCenterX, fromCenterY, toCenterX, toCenterY);
      }
    });

    this.project.tasks.forEach(task => {
      const isSelected = task.id === this.selectedTask?.id;
      this.context.fillStyle = task.isCritical ? '#FADBD8' : '#AECBFA';
      this.context.beginPath();
      this.context.rect(task.x, task.y, 150, 70);
      this.context.fill();
      this.context.strokeStyle = isSelected ? '#FF8C00' : (task.isCritical ? '#D0021B' : '#4A90E2');
      this.context.lineWidth = isSelected ? 4 : 2;
      this.context.stroke();
      this.context.fillStyle = '#000000';
      this.context.font = `bold 18px HarmonyOS Sans`;
      this.context.fillText(task.name, task.x + 15, task.y + 30);
      this.context.font = `16px HarmonyOS Sans`;
      this.context.fillText(`工期: ${task.duration} 天`, task.x + 15, task.y + 55);
    });

    // FIX: 优化连接模式的提示，不再是黑色长条
    if (this.isConnecting) {
      const text = '请选择一个目标任务以创建依赖';
      this.context.font = 'bold 20px HarmonyOS Sans';
      const textMetrics = this.context.measureText(text);
      const boxWidth = textMetrics.width + 40;
      const boxHeight = 50;
      const boxX = (2000 - boxWidth) / 2; // 假设画布逻辑宽度为2000用于居中
      const boxY = 20;

      // 绘制带圆角的背景框
      this.context.fillStyle = 'rgba(0, 0, 0, 0.75)';
      this.context.beginPath();
      this.context.moveTo(boxX + 10, boxY);
      this.context.lineTo(boxX + boxWidth - 10, boxY);
      this.context.quadraticCurveTo(boxX + boxWidth, boxY, boxX + boxWidth, boxY + 10);
      this.context.lineTo(boxX + boxWidth, boxY + boxHeight - 10);
      this.context.quadraticCurveTo(boxX + boxWidth, boxY + boxHeight, boxX + boxWidth - 10, boxY + boxHeight);
      this.context.lineTo(boxX + 10, boxY + boxHeight);
      this.context.quadraticCurveTo(boxX, boxY + boxHeight, boxX, boxY + boxHeight - 10);
      this.context.lineTo(boxX, boxY + 10);
      this.context.quadraticCurveTo(boxX, boxY, boxX + 10, boxY);
      this.context.closePath();
      this.context.fill();

      // 绘制提示文字
      this.context.fillStyle = '#FFFFFF';
      this.context.textAlign = 'center';
      this.context.fillText(text, boxX + boxWidth / 2, boxY + 32);
      this.context.textAlign = 'start'; // 恢复默认对齐方式
    }
  }

  build() {
    Row() {
      Sidebar({
        project: this.project,
        selectedTask: $selectedTask,
        onUpdateProjectName: (newName) => { this.handleUpdateProjectName(newName) },
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
        // 恢复到简单的 onTouch 手势处理
        .onTouch((event: TouchEvent) => {
          if (!event.touches || event.touches.length === 0) return;
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
                  this.handleCalculateCriticalPath();
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
                this.isDraggingNode = true;
                this.dragOffsetX = touchX - hitNode.x;
                this.dragOffsetY = touchY - hitNode.y;
              }
              this.drawGraph();
              break;
            case TouchType.Move:
              if (this.isDraggingNode && this.selectedTask) {
                this.selectedTask.x = touchX - this.dragOffsetX;
                this.selectedTask.y = touchY - this.dragOffsetY;
                this.drawGraph();
              }
              break;
            case TouchType.Up:
              this.isDraggingNode = false;
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
        this.handleCalculateCriticalPath();
      }
    })
  }
}
