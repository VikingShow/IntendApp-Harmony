// File: entry/src/main/ets/pages/Index.ets

import { Project, TaskNode, Dependency, ChecklistItem } from '../model/ProjectData'
import { Sidebar } from '../components/Sidebar'
import { CriticalPathService, TaskWithDuration } from '../services/CriticalPathService'

@Entry
@Component
struct Index {
  @State project: Project = new Project();
  @State selectedTask: TaskNode | null = null;
  @State isConnecting: boolean = false;
  @State isDraggingNode: boolean = false;
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;

  private cpmService: CriticalPathService = new CriticalPathService();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  private getCompletionProgress(task: TaskNode): number {
    if (task.checklist.length === 0) return 0;
    const completedCount = task.checklist.filter(item => item.isCompleted).length;
    return Math.round((completedCount / task.checklist.length) * 100);
  }

  private getTimeProgress(task: TaskNode): number {
    const now = new Date().getTime();
    const start = task.startDate.getTime();
    const end = task.endDate.getTime();
    if (now < start) return 0;
    if (now > end) return 100;
    const totalDuration = end - start;
    if (totalDuration <= 0) return 100;
    const elapsed = now - start;
    return Math.round((elapsed / totalDuration) * 100);
  }

  private drawProgressBar(x: number, y: number, width: number, height: number, progress: number, color: string) {
    this.context.fillStyle = '#E0E0E0';
    this.context.fillRect(x, y, width, height);
    this.context.fillStyle = color;
    const progressWidth = (width * progress) / 100;
    this.context.fillRect(x, y, progressWidth, height);
  }

  handleUpdateProjectName(newName: string) {
    this.project.name = newName;
  }

  handleAddTask() {
    const today = new Date();
    const tomorrow = new Date();
    tomorrow.setDate(today.getDate() + 1);
    const newTask: TaskNode = {
      id: `task_${Date.now()}`,
      name: '新任务',
      startDate: today,
      endDate: tomorrow,
      checklist: [],
      x: 50,
      y: 50
    };
    this.project.addTask(newTask);
    this.handleCalculateCriticalPath();
  }

  handleUpdateTask(updatedTask: TaskNode) {
    this.project.tasks = this.project.tasks.map(task => {
      if (task.id === updatedTask.id) {
        return updatedTask;
      }
      return task;
    });

    if (this.selectedTask && this.selectedTask.id === updatedTask.id) {
      this.selectedTask = updatedTask;
    }
    this.handleCalculateCriticalPath();
  }

  handleUpdateChecklist(taskId: string, checklist: ChecklistItem[]) {
    const newTasks = this.project.tasks.map(task => {
      if (task.id === taskId) {
        // FIX: Replaced object spread with explicit property assignment
        const updatedTask: TaskNode = {
          id: task.id,
          name: task.name,
          startDate: task.startDate,
          endDate: task.endDate,
          checklist: [...checklist],
          x: task.x,
          y: task.y,
          isCritical: task.isCritical,
          earlyStart: task.earlyStart,
          earlyFinish: task.earlyFinish,
          lateStart: task.lateStart,
          lateFinish: task.lateFinish
        };
        if (this.selectedTask?.id === taskId) {
          this.selectedTask = updatedTask;
        }
        return updatedTask;
      }
      return task;
    });
    this.project.tasks = newTasks;
    this.drawGraph();
  }

  handleAddChecklistItem(taskId: string, text: string) {
    const newTasks = this.project.tasks.map(task => {
      if (task.id === taskId) {
        const newItem: ChecklistItem = {
          id: `item_${Date.now()}`,
          text: text,
          isCompleted: false
        };
        const newChecklist = [...task.checklist, newItem];
        // FIX: Replaced object spread with explicit property assignment
        const updatedTask: TaskNode = {
          id: task.id,
          name: task.name,
          startDate: task.startDate,
          endDate: task.endDate,
          checklist: newChecklist,
          x: task.x,
          y: task.y,
          isCritical: task.isCritical,
          earlyStart: task.earlyStart,
          earlyFinish: task.earlyFinish,
          lateStart: task.lateStart,
          lateFinish: task.lateFinish
        };

        if (this.selectedTask?.id === taskId) {
          this.selectedTask = updatedTask;
        }
        return updatedTask;
      }
      return task;
    });
    this.project.tasks = newTasks;
    this.drawGraph();
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
    const tasksWithDuration: TaskWithDuration[] = this.project.tasks.map((t: TaskNode): TaskWithDuration => {
      return {
        id: t.id,
        duration: this.getDuration(t),
        isCritical: t.isCritical,
        earlyStart: t.earlyStart,
        earlyFinish: t.earlyFinish,
        lateStart: t.lateStart,
        lateFinish: t.lateFinish
      };
    });
    this.cpmService.calculate(tasksWithDuration, this.project.dependencies);
    tasksWithDuration.forEach(calculatedTask => {
      const originalTask = this.project.tasks.find(t => t.id === calculatedTask.id);
      if (originalTask) {
        originalTask.isCritical = calculatedTask.isCritical;
      }
    });
    this.drawGraph();
  }

  drawGraph() {
    this.context.clearRect(0, 0, 3000, 3000);

    this.project.dependencies.forEach(dep => {
      const fromNode = this.project.tasks.find(t => t.id === dep.fromId);
      const toNode = this.project.tasks.find(t => t.id === dep.toId);
      if (fromNode && toNode) {
        const isCriticalDep = fromNode.isCritical && toNode.isCritical;
        const fromCenterX = fromNode.x + 200 / 2;
        const fromCenterY = fromNode.y + 120 / 2;
        const toCenterX = toNode.x + 200 / 2;
        const toCenterY = toNode.y + 120 / 2;
        this.context.beginPath();
        this.context.moveTo(fromCenterX, fromCenterY);
        this.context.lineTo(toCenterX, toCenterY);
        this.context.strokeStyle = isCriticalDep ? '#D0021B' : '#666666';
        this.context.lineWidth = isCriticalDep ? 3 : 2;
        this.context.stroke();
      }
    });

    this.project.tasks.forEach(task => {
      const NODE_WIDTH = 200;
      const NODE_HEIGHT = 120;
      const isSelected = task.id === this.selectedTask?.id;

      this.context.fillStyle = task.isCritical ? '#FADBD8' : '#AECBFA';
      this.context.beginPath();
      this.context.rect(task.x, task.y, NODE_WIDTH, NODE_HEIGHT);
      this.context.fill();
      this.context.strokeStyle = isSelected ? '#FF8C00' : (task.isCritical ? '#D0021B' : '#4A90E2');
      this.context.lineWidth = isSelected ? 4 : 2;
      this.context.stroke();

      this.context.fillStyle = '#000000';
      this.context.font = `bold 16px HarmonyOS Sans`;
      this.context.fillText(task.name, task.x + 15, task.y + 25);

      this.context.font = `14px HarmonyOS Sans`;
      const dateString = `${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`;
      this.context.fillText(`📅 ${dateString}`, task.x + 15, task.y + 45);

      const timeProgress = this.getTimeProgress(task);
      const completionProgress = this.getCompletionProgress(task);
      this.context.font = `12px HarmonyOS Sans`;
      this.context.fillText(`⌛ 时间: ${timeProgress}%`, task.x + 15, task.y + 70);
      this.drawProgressBar(task.x + 15, task.y + 75, NODE_WIDTH - 30, 8, timeProgress, '#4A90E2');
      this.context.fillText(`✓ 完成: ${completionProgress}%`, task.x + 15, task.y + 95);
      this.drawProgressBar(task.x + 15, task.y + 100, NODE_WIDTH - 30, 8, completionProgress, '#2ECC71');
    });

    if (this.isConnecting) {
      const text = '请选择一个目标任务以创建依赖';
      this.context.font = 'bold 20px HarmonyOS Sans';
      const textMetrics = this.context.measureText(text);
      const boxWidth = textMetrics.width + 40;
      const boxHeight = 50;
      const boxX = (2000 - boxWidth) / 2;
      const boxY = 20;
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
      this.context.fillStyle = '#FFFFFF';
      this.context.textAlign = 'center';
      this.context.fillText(text, boxX + boxWidth / 2, boxY + 32);
      this.context.textAlign = 'start';
    }
  }

  build() {
    Row() {
      Sidebar({
        project: this.project,
        selectedTask: $selectedTask,
        onUpdateProjectName: (newName) => { this.handleUpdateProjectName(newName) },
        onAddTask: () => { this.handleAddTask() },
        onUpdateTask: (task) => { this.handleUpdateTask(task as TaskNode) },
        onUpdateChecklist: (taskId, checklist) => { this.handleUpdateChecklist(taskId, checklist as ChecklistItem[]) },
        onAddChecklistItem: (taskId, text) => { this.handleAddChecklistItem(taskId, text) },
        onDeleteTask: (id) => { this.handleDeleteTask(id) },
        onStartConnecting: () => { this.handleStartConnecting() },
        onCalculate: () => { this.handleCalculateCriticalPath() }
      })
        .layoutWeight(2)

      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .layoutWeight(4)
        .onReady(() => { this.drawGraph(); })
        .onTouch((event: TouchEvent) => {
          if (!event.touches || event.touches.length === 0) return;
          const touchX = event.touches[0].x;
          const touchY = event.touches[0].y;

          let hitNode: TaskNode | null = null;
          for (let i = this.project.tasks.length - 1; i >= 0; i--) {
            const task = this.project.tasks[i];
            if (touchX >= task.x && touchX <= task.x + 200 && touchY >= task.y && touchY <= task.y + 120) {
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
        this.handleAddTask();
      }
    })
  }
}
