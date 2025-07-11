// File: entry/src/main/ets/pages/Index.ets

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Project, TaskNode, Dependency, ChecklistItem } from '../model/ProjectData';
import { Sidebar } from '../components/Sidebar';
import { CriticalPathService, TaskWithDuration } from '../services/CriticalPathService';
import { StorageService } from '../services/StorageService';
import common from '@ohos.app.ability.common';
import { TemplateService } from '../services/TemplateService';

// FIX: Define an interface for the router parameters to avoid type errors.
interface RouterParams {
  projectId?: string;
}

@Entry
@Component
struct Index {
  // 项目数据现在可能为空，直到我们从存储中加载它
  @State project: Project | null = null;
  @State selectedTask: TaskNode | null = null;
  @State isConnecting: boolean = false;
  @State isDraggingNode: boolean = false;
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;
  @State sidebarVisible: boolean = true;
  @State canvasOffsetX: number = 0;
  @State canvasOffsetY: number = 0;
  @State isDraggingCanvas: boolean = false;
  @State lastTouchX: number = 0;
  @State lastTouchY: number = 0;
  @State isCanvasLocked: boolean = false;

  private storageService: StorageService | null = null;
  private cpmService: CriticalPathService = new CriticalPathService();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  async aboutToAppear() {
    // 初始化存储服务
    const context = getContext(this);
    this.storageService = StorageService.getInstance(context.filesDir);
    // --- 修正：进入页面时强制初始化画布偏移 ---
    this.canvasOffsetX = 0;
    this.canvasOffsetY = 0;

    // 从路由参数中获取projectId
    const params = router.getParams() as RouterParams;
    const projectId = params?.projectId;

    console.log(`[EasyFlow] Index.ets aboutToAppear - projectId: ${projectId}`);

    if (projectId) {
      // 如果有ID，则加载现有项目
      console.log(`[EasyFlow] Loading existing project with ID: ${projectId}`);
      const loadedProject = await this.storageService.getProject(projectId);
      if (loadedProject) {
        this.project = loadedProject;
        console.log(`[EasyFlow] Project loaded successfully with ${loadedProject.tasks.length} tasks`);
        this.handleCalculateCriticalPath();
      } else {
        promptAction.showToast({ message: `加载项目失败: ${projectId}` });
        this.project = new Project(); // 加载失败则创建一个新项目
      }
    } else {
      // 如果没有ID，则创建新项目并填充示例数据
      console.log("[EasyFlow] Creating new project with example data.");
      await this.createNewExampleProject();
    }
  }

  // --- 新增：创建示例项目的方法 ---
  async createNewExampleProject() {
    const newProject = new Project(undefined, '新移动应用开发计划');
    const today = new Date();

    const task1: TaskNode = {
      id: 'task_1', name: '需求分析与原型设计',
      startDate: today,
      endDate: new Date(today.getTime() + 4 * 24 * 60 * 60 * 1000),
      checklist: [
        { id: 'c1_1', text: '收集用户反馈', isCompleted: true },
        { id: 'c1_2', text: '绘制线框图', isCompleted: true },
        { id: 'c1_3', text: '制作交互原型', isCompleted: false },
      ],
      x: 50, y: 150
    };

    const task2: TaskNode = {
      id: 'task_2', name: 'UI/UX视觉设计',
      startDate: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 9 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 350, y: 50
    };

    const task3: TaskNode = {
      id: 'task_3', name: '前端开发',
      startDate: new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 19 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 650, y: 150
    };

    const task4: TaskNode = {
      id: 'task_4', name: '后端开发',
      startDate: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 16 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 350, y: 250
    };

    const task5: TaskNode = {
      id: 'task_5', name: '测试与部署',
      startDate: new Date(today.getTime() + 20 * 24 * 60 * 60 * 1000),
      endDate: new Date(today.getTime() + 24 * 24 * 60 * 60 * 1000),
      checklist: [],
      x: 950, y: 150
    };

    newProject.tasks = [task1, task2, task3, task4, task5];
    newProject.dependencies = [
      { fromId: 'task_1', toId: 'task_2' },
      { fromId: 'task_1', toId: 'task_4' },
      { fromId: 'task_2', toId: 'task_3' },
      { fromId: 'task_4', toId: 'task_3' },
      { fromId: 'task_3', toId: 'task_5' }
    ];

    this.project = newProject;

    // 保存新项目到存储
    if (this.storageService) {
      await this.storageService.saveProject(newProject);
      console.log(`[EasyFlow] New project saved with ID: ${newProject.id}`);
    }

    this.handleCalculateCriticalPath();
  }


  // --- Helper Functions ---
  private getDuration(task: TaskNode): number {
    const diffTime = task.endDate.getTime() - task.startDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  private getCompletionProgress(task: TaskNode): number {
    if (!task || !task.checklist) return 0;
    if (task.checklist.length === 0) return 0;
    const completedCount = task.checklist.filter(item => item.isCompleted).length;
    return Math.round((completedCount / task.checklist.length) * 100);
  }

  private getTimeProgress(task: TaskNode): number {
    if (!task) return 0;
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

  // --- Data Handling Functions ---
  handleUpdateProjectName(newName: string) {
    if (this.project) this.project.name = newName;
  }

  handleAddTask() {
    if (!this.project) return;
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
    this.project.tasks = [...this.project.tasks, newTask];
    this.handleCalculateCriticalPath();
    promptAction.showToast({ message: '新任务已添加' });
  }

  handleUpdateTask(updatedTask: TaskNode) {
    if (!this.project) return;
    this.project.tasks = this.project.tasks.map(task => task.id === updatedTask.id ? updatedTask : task);
    if (this.selectedTask?.id === updatedTask.id) this.selectedTask = updatedTask;
    this.handleCalculateCriticalPath();
  }

  // FIX: Using a more robust immutable update pattern to ensure UI refresh.
  handleUpdateChecklist(taskId: string, checklist: ChecklistItem[]) {
    if (!this.project) return;
    let updatedTask: TaskNode | null = null;
    const newTasks = this.project.tasks.map(task => {
      if (task.id === taskId) {
        updatedTask = {
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
        return updatedTask;
      }
      return task;
    });
    this.project.tasks = newTasks;
    // Crucially, update the selectedTask state variable as well.
    if (this.selectedTask?.id === taskId && updatedTask) {
      this.selectedTask = updatedTask;
    }
    this.drawGraph();
  }

  // FIX: Using a more robust immutable update pattern to ensure UI refresh.
  handleAddChecklistItem(taskId: string, text: string) {
    if (!this.project) return;
    let updatedTask: TaskNode | null = null;
    const newTasks = this.project.tasks.map(task => {
      if (task.id === taskId) {
        const newItem: ChecklistItem = { id: `item_${Date.now()}`, text, isCompleted: false };
        const newChecklist = [...task.checklist, newItem];
        updatedTask = {
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
        return updatedTask;
      }
      return task;
    });
    this.project.tasks = newTasks;
    // Crucially, update the selectedTask state variable as well.
    if (this.selectedTask?.id === taskId && updatedTask) {
      this.selectedTask = updatedTask;
    }
    this.drawGraph();
  }

  handleDeleteTask(id: string) {
    if (!this.project) return;
    if (this.selectedTask?.id === id) this.selectedTask = null;
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
    if (!this.project) return;
    const tasksWithDuration: TaskWithDuration[] = this.project.tasks.map((t: TaskNode): TaskWithDuration => ({
      id: t.id,
      duration: this.getDuration(t),
      isCritical: t.isCritical,
      earlyStart: t.earlyStart,
      earlyFinish: t.earlyFinish,
      lateStart: t.lateStart,
      lateFinish: t.lateFinish
    }));
    this.cpmService.calculate(tasksWithDuration, this.project.dependencies);
    tasksWithDuration.forEach(calculatedTask => {
      const originalTask = this.project!.tasks.find(t => t.id === calculatedTask.id);
      if (originalTask) originalTask.isCritical = calculatedTask.isCritical;
    });
    this.drawGraph();
  }

  async handleSaveProject() {
    if (!this.project) {
      promptAction.showToast({ message: '没有可保存的项目' });
      return;
    }
    if (!this.storageService) {
      promptAction.showToast({ message: '存储服务未初始化' });
      return;
    }

    this.project.lastModified = Date.now();
    await this.storageService.saveProject(this.project);
    promptAction.showToast({ message: `项目 "${this.project.name}" 已保存` });
  }

  handleBackToHome() {
    router.back();
  }

  drawGraph() {
    this.context.clearRect(0, 0, 3000, 3000);
    if (!this.project) return;

    this.project.dependencies.forEach(dep => {
      const fromNode = this.project!.tasks.find(t => t.id === dep.fromId);
      const toNode = this.project!.tasks.find(t => t.id === dep.toId);
      if (fromNode && toNode) {
        const isCriticalDep = fromNode.isCritical && toNode.isCritical;
        // --- 修正：连线渲染加canvasOffset ---
        const fromCenterX = fromNode.x + this.canvasOffsetX + 200 / 2;
        const fromCenterY = fromNode.y + this.canvasOffsetY + 120 / 2;
        const toCenterX = toNode.x + this.canvasOffsetX + 200 / 2;
        const toCenterY = toNode.y + this.canvasOffsetY + 120 / 2;
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
      // --- 修正：节点渲染全部加canvasOffset ---
      const drawX = task.x + this.canvasOffsetX;
      const drawY = task.y + this.canvasOffsetY;
      this.context.fillStyle = task.isCritical ? '#FADBD8' : '#AECBFA';
      this.context.beginPath();
      this.context.rect(drawX, drawY, NODE_WIDTH, NODE_HEIGHT);
      this.context.fill();
      this.context.strokeStyle = isSelected ? '#FF8C00' : (task.isCritical ? '#D0021B' : '#4A90E2');
      this.context.lineWidth = isSelected ? 4 : 2;
      this.context.stroke();
      this.context.fillStyle = '#000000';
      this.context.font = `bold 16px HarmonyOS Sans`;
      this.context.fillText(task.name, drawX + 15, drawY + 25);
      this.context.font = `14px HarmonyOS Sans`;
      const dateString = `${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`;
      this.context.fillText(`📅 ${dateString}`, drawX + 15, drawY + 45);
      const timeProgress = this.getTimeProgress(task);
      const completionProgress = this.getCompletionProgress(task);
      this.context.font = `12px HarmonyOS Sans`;
      this.context.fillText(`⌛ 时间: ${timeProgress}%`, drawX + 15, drawY + 70);
      this.drawProgressBar(drawX + 15, drawY + 75, NODE_WIDTH - 30, 8, timeProgress, '#4A90E2');
      this.context.fillText(`✓ 完成: ${completionProgress}%`, drawX + 15, drawY + 95);
      this.drawProgressBar(drawX + 15, drawY + 100, NODE_WIDTH - 30, 8, completionProgress, '#2ECC71');
    });
  }

  private drawProgressBar(x: number, y: number, width: number, height: number, progress: number, color: string) {
    this.context.fillStyle = '#E0E0E0';
    this.context.fillRect(x, y, width, height);
    this.context.fillStyle = color;
    const progressWidth = (width * progress) / 100;
    this.context.fillRect(x, y, progressWidth, height);
  }

  build() {
    Row() {
      // 展开/收起按钮始终在最左侧
      Button() {
        Text(this.sidebarVisible ? '<' : '>')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(48)
      .backgroundColor('#F3F4F6')
      .borderRadius(8)
      .margin({ left: 0, right: 0, top: 24, bottom: 24 })
      .zIndex(100)
      .onClick(() => { this.sidebarVisible = !this.sidebarVisible })

      // 侧边栏
      if (this.sidebarVisible) {
        Sidebar({
          project: this.project,
          selectedTask: this.selectedTask,
          isHomePage: false,
          onUpdateProjectName: (newName) => { this.handleUpdateProjectName(newName) },
          onAddTask: () => { this.handleAddTask() },
          onUpdateTask: (task) => { this.handleUpdateTask(task as TaskNode) },
          onUpdateChecklist: (taskId, checklist) => { this.handleUpdateChecklist(taskId, checklist as ChecklistItem[]) },
          onAddChecklistItem: (taskId, text) => { this.handleAddChecklistItem(taskId, text) },
          onDeleteTask: (id) => { this.handleDeleteTask(id) },
          onStartConnecting: () => { this.handleStartConnecting() },
          onCalculate: () => { this.handleCalculateCriticalPath() },
          onSave: () => { this.handleSaveProject() },
          onBack: () => { this.handleBackToHome() },
          onCreateBlankProject: () => {
            this.project = new Project(undefined, '新项目');
            this.selectedTask = null;
          },
          onCreateProjectFromTemplate: (templateId: string, projectName: string) => {
            const templateService = TemplateService.getInstance();
            this.project = templateService.createProjectFromTemplate(templateId, projectName);
            this.selectedTask = null;
          }
        })
        .width(340)
      }
      // 画布
      Stack() {
        Canvas(this.context)
          .height('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 16, right: 16, bottom: 16, left: 0 }) // 左侧不留空，紧贴Sidebar或按钮
          .shadow({ radius: 8, color: '#0000000A', offsetX: 0, offsetY: 2 })
          .onReady(() => { this.drawGraph(); })
          .onTouch((event: TouchEvent) => {
            if (!this.project) return;
            if (this.isCanvasLocked) return;
            const buttonWidth = 32;
            // 只用第一个触点，始终只减去左侧按钮宽度
            const realTouchX = event.touches[0].x - buttonWidth;
            const realTouchY = event.touches[0].y;
            let hitNode: TaskNode | null = null;
            // 命中检测区域适当扩大
            const HIT_PADDING = 8;
            // --- 优化：无论Sidebar展开与否，命中检测和拖拽都可用 ---
            for (let i = this.project.tasks.length - 1; i >= 0; i--) {
              const task = this.project.tasks[i];
              const nodeLeft = task.x + this.canvasOffsetX - HIT_PADDING;
              const nodeTop = task.y + this.canvasOffsetY - HIT_PADDING;
              const nodeRight = nodeLeft + 200 + HIT_PADDING * 2;
              const nodeBottom = nodeTop + 120 + HIT_PADDING * 2;
              if (realTouchX >= nodeLeft && realTouchX <= nodeRight &&
                  realTouchY >= nodeTop && realTouchY <= nodeBottom) {
                hitNode = task;
                break;
              }
            }
            switch (event.type) {
              case TouchType.Down:
                if (hitNode) {
                  this.selectedTask = hitNode;
                  this.isDraggingNode = true;
                  this.isDraggingCanvas = false;
                  this.dragOffsetX = realTouchX - (hitNode.x + this.canvasOffsetX);
                  this.dragOffsetY = realTouchY - (hitNode.y + this.canvasOffsetY);
                } else {
                  this.isDraggingCanvas = true;
                  this.isDraggingNode = false;
                  this.lastTouchX = realTouchX;
                  this.lastTouchY = realTouchY;
                }
                this.drawGraph();
                break;
              case TouchType.Move:
                if (this.isDraggingNode && this.selectedTask) {
                  this.selectedTask.x = realTouchX - this.dragOffsetX - this.canvasOffsetX;
                  this.selectedTask.y = realTouchY - this.dragOffsetY - this.canvasOffsetY;
                  this.drawGraph();
                } else if (this.isDraggingCanvas) {
                  this.canvasOffsetX += realTouchX - this.lastTouchX;
                  this.canvasOffsetY += realTouchY - this.lastTouchY;
                  this.lastTouchX = realTouchX;
                  this.lastTouchY = realTouchY;
                  this.drawGraph();
                }
                break;
              case TouchType.Up:
                this.isDraggingCanvas = false;
                this.isDraggingNode = false;
                break;
            }
          })
        // 右上角复原/锁定按钮
        Column() {
          Row() {
            Button() {
              Text(this.isCanvasLocked ? '解锁画布' : '锁定画布')
                .fontSize(13)
                .fontColor('#007DFF')
            }
            .width(80)
            .height(32)
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .margin({ right: 12, top: 12 })
            .onClick(() => { this.isCanvasLocked = !this.isCanvasLocked })
            Button() {
              Text('复原')
                .fontSize(13)
                .fontColor('#10B981')
            }
            .width(60)
            .height(32)
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .margin({ right: 12, top: 12 })
            .onClick(() => { this.canvasOffsetX = 0; this.canvasOffsetY = 0; this.drawGraph(); })
          }
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .position({ x: 0, y: 0 })
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}