
import { Project, TaskNode } from '../model/ProjectData';

export interface RenderConfig {
  canvasOffsetX: number;
  canvasOffsetY: number;
  isConnecting: boolean;
  connectingFromTaskId: string | null;
  selectedTaskId: string | null;
}

export class CanvasRenderer {
  private context: CanvasRenderingContext2D;
  private settings: RenderingContextSettings;

  constructor() {
    this.settings = new RenderingContextSettings(true);
    this.context = new CanvasRenderingContext2D(this.settings);
  }

  public getContext(): CanvasRenderingContext2D {
    return this.context;
  }

  public render(project: Project, config: RenderConfig): void {
    this.context.clearRect(0, 0, 3000, 3000);
    
    if (!project) return;

    // 渲染依赖连线
    this.renderDependencies(project, config);
    
    // 渲染任务节点
    this.renderTasks(project, config);
  }

  private renderDependencies(project: Project, config: RenderConfig): void {
    project.dependencies.forEach(dep => {
      const fromNode = project.tasks.find(t => t.id === dep.fromId);
      const toNode = project.tasks.find(t => t.id === dep.toId);
      
      if (fromNode && toNode) {
        const isCriticalDep = fromNode.isCritical && toNode.isCritical;
        const fromCenterX = fromNode.x + config.canvasOffsetX + 200 / 2;
        const fromCenterY = fromNode.y + config.canvasOffsetY + 120 / 2;
        const toCenterX = toNode.x + config.canvasOffsetX + 200 / 2;
        const toCenterY = toNode.y + config.canvasOffsetY + 120 / 2;
        
        this.context.beginPath();
        this.context.moveTo(fromCenterX, fromCenterY);
        this.context.lineTo(toCenterX, toCenterY);
        this.context.strokeStyle = isCriticalDep ? '#D0021B' : '#666666';
        this.context.lineWidth = isCriticalDep ? 3 : 2;
        this.context.stroke();
      }
    });
  }

  private renderTasks(project: Project, config: RenderConfig): void {
    project.tasks.forEach(task => {
      const NODE_WIDTH = 200;
      const NODE_HEIGHT = 120;
      const isSelected = task.id === config.selectedTaskId;
      const drawX = task.x + config.canvasOffsetX;
      const drawY = task.y + config.canvasOffsetY;

      // 节点背景
      this.context.fillStyle = '#FFFFFF';
      this.drawRoundRect(this.context, drawX, drawY, NODE_WIDTH, NODE_HEIGHT, 16);
      this.context.fill();

      // 节点边框
      this.context.strokeStyle = isSelected ? '#FF8C00' : (task.isCritical ? '#D0021B' : '#4A90E2');
      this.context.lineWidth = isSelected ? 4 : 2;
      this.context.stroke();

      // 任务名称
      this.context.fillStyle = '#000000';
      this.context.font = `bold 28px HarmonyOS Sans`;
      this.context.fillText(task.name, drawX + 15, drawY + 25);

      // 日期信息
      this.context.font = `22px HarmonyOS Sans`;
      const dateString = `${task.startDate.toLocaleDateString()} ~ ${task.endDate.toLocaleDateString()} (${this.getDuration(task)}天)`;
      this.context.fillText(`📅 ${dateString}`, drawX + 15, drawY + 45);

      // 进度信息
      const timeProgress = this.getTimeProgress(task);
      const completionProgress = this.getCompletionProgress(task);
      
      this.context.font = `19px HarmonyOS Sans`;
      this.context.fillText(`⌛ 时间: ${timeProgress}%`, drawX + 15, drawY + 70);
      this.drawProgressBar(drawX + 15, drawY + 75, NODE_WIDTH - 30, 8, timeProgress, '#4A90E2');
      
      this.context.fillText(`✓ 完成: ${completionProgress}%`, drawX + 15, drawY + 95);
      this.drawProgressBar(drawX + 15, drawY + 100, NODE_WIDTH - 30, 8, completionProgress, '#2ECC71');
    });
  }

  private drawRoundRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, radius: number): void {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    ctx.lineTo(x + radius, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
  }

  private drawProgressBar(x: number, y: number, width: number, height: number, progress: number, color: string): void {
    const radius = height / 2;
    
    // 背景
    this.context.fillStyle = '#E0E0E0';
    this.drawRoundRect(this.context, x, y, width, height, radius);
    this.context.fill();
    
    // 进度
    this.context.fillStyle = color;
    const progressWidth = (width * progress) / 100;
    if (progressWidth > 0) {
      this.drawRoundRect(this.context, x, y, progressWidth, height, radius);
      this.context.fill();
    }
  }

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
}


