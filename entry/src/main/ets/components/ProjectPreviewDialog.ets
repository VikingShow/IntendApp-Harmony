import { Project, TaskNode } from '../model/ProjectData';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';
import { CanvasRenderer, RenderMode } from '../core/canvas/CanvasRenderer';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import { picker } from '@kit.CoreFileKit';
import { PromptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import fileIo from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

export enum CardType {
  TOTAL_TASKS = 'TOTAL_TASKS',
  THIS_WEEK = 'THIS_WEEK',
  OVERALL_COMPLETION = 'OVERALL_COMPLETION',
  OVERDUE = 'OVERDUE',
  COMPLETED = 'COMPLETED',
  PENDING = 'PENDING',
  CRITICAL = 'CRITICAL',
  NO_CHECKLIST = 'NO_CHECKLIST',
  OPEN_CHECKLIST = 'OPEN_CHECKLIST'
}

@CustomDialog
export struct ProjectPreviewDialog {
  controller: CustomDialogController;
  project: Project = new Project();
  cardType: CardType = CardType.TOTAL_TASKS;
  isDarkMode: boolean = false;
  
  @State private canvasReady: boolean = false;
  @State private blinkingTaskIds: string[] = [];
  @State private blinkOpacity: number = 1;
  @State private isExporting: boolean = false;
  @State private showExportMenu: boolean = false;
  @State private showNodeNames: boolean = true;
  @State private autoZoomScale: number = 1.0;
  @State private autoOffsetX: number = 0;
  @State private autoOffsetY: number = 0;
  @State private currentZoomScale: number = 1.0;
  @State private currentOffsetX: number = 0;
  @State private currentOffsetY: number = 0;
  @State private isDragging: boolean = false;
  private lastTouchX: number = 0;
  private lastTouchY: number = 0;
  
  private canvasRenderer: CanvasRenderer = new CanvasRenderer();
  private blinkTimer: number = -1;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  aboutToAppear() {
    this.canvasRenderer.setDarkMode(this.isDarkMode);
    this.calculateBlinkingTasks();
    this.calculateAutoFit();
    this.currentZoomScale = this.autoZoomScale;
    this.currentOffsetX = this.autoOffsetX;
    this.currentOffsetY = this.autoOffsetY;
    this.startBlinkAnimation();
  }

  aboutToDisappear() {
    this.stopBlinkAnimation();
  }

  private calculateBlinkingTasks(): void {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
    const monday = this.getMonday(today);
    const nextMonday = new Date(monday.getTime() + 7 * 24 * 60 * 60 * 1000);

    this.blinkingTaskIds = [];

    switch (this.cardType) {
      case CardType.TOTAL_TASKS:
        this.blinkingTaskIds = this.project.tasks.map(t => t.id);
        break;
      case CardType.THIS_WEEK:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => t.endDate >= monday && t.endDate < nextMonday)
          .map(t => t.id);
        break;
      case CardType.OVERALL_COMPLETION:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => this.getTaskCompletionPercent(t) > 0)
          .map(t => t.id);
        break;
      case CardType.OVERDUE:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => t.endDate < now && !this.isTaskCompleted(t))
          .map(t => t.id);
        break;
      case CardType.COMPLETED:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => this.isTaskCompleted(t))
          .map(t => t.id);
        break;
      case CardType.PENDING:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => !this.isTaskCompleted(t))
          .map(t => t.id);
        break;
      case CardType.CRITICAL:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => t.isCritical)
          .map(t => t.id);
        break;
      case CardType.NO_CHECKLIST:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => !t.checklist || t.checklist.length === 0)
          .map(t => t.id);
        break;
      case CardType.OPEN_CHECKLIST:
        this.blinkingTaskIds = this.project.tasks
          .filter(t => t.checklist && t.checklist.some(item => !item.isCompleted))
          .map(t => t.id);
        break;
    }

    console.log(`[ProjectPreviewDialog] Blinking tasks for ${this.cardType}: ${this.blinkingTaskIds.length}`);
  }

  private getMonday(date: Date): Date {
    const day = date.getDay();
    const diff = (day + 6) % 7;
    return new Date(date.getTime() - diff * 24 * 60 * 60 * 1000);
  }

  private getTaskCompletionPercent(task: TaskNode): number {
    if (!task.checklist || task.checklist.length === 0) return 0;
    const completed = task.checklist.filter(item => item.isCompleted).length;
    return Math.round((completed / task.checklist.length) * 100);
  }

  private isTaskCompleted(task: TaskNode): boolean {
    if (!task.checklist || task.checklist.length === 0) return false;
    return task.checklist.every(item => item.isCompleted);
  }

  private startBlinkAnimation(): void {
    this.stopBlinkAnimation();
    
    let time = 0;
    this.blinkTimer = setInterval(() => {
      time += 0.08;
      this.blinkOpacity = 0.4 + 0.6 * (Math.sin(time * 2) * 0.5 + 0.5);
      
      if (this.canvasReady) {
        this.renderCanvas();
      }
    }, 80);
  }

  private stopBlinkAnimation(): void {
    if (this.blinkTimer !== -1) {
      clearInterval(this.blinkTimer);
      this.blinkTimer = -1;
    }
  }

  private calculateAutoFit(): void {
    if (this.project.tasks.length === 0) {
      this.autoZoomScale = 1.0;
      this.autoOffsetX = 0;
      this.autoOffsetY = 0;
      return;
    }

    const COMPACT_OFFSET = 100;
    const COMPACT_NODE_SIZE = 120;
    const PADDING = 150;

    const minX = Math.min(...this.project.tasks.map(t => t.x));
    const maxX = Math.max(...this.project.tasks.map(t => t.x));
    const minY = Math.min(...this.project.tasks.map(t => t.y));
    const maxY = Math.max(...this.project.tasks.map(t => t.y));

    const contentWidth = (maxX - minX) + COMPACT_NODE_SIZE + COMPACT_OFFSET * 2 + PADDING * 2;
    const contentHeight = (maxY - minY) + COMPACT_NODE_SIZE + PADDING * 2;
    const canvasWidth = 3000;
    const canvasHeight = 3000;

    const scaleX = canvasWidth / contentWidth;
    const scaleY = canvasHeight / contentHeight;
    this.autoZoomScale = Math.min(scaleX, scaleY, 2.0) * 0.85;

    const contentCenterX = (minX + maxX) / 2 + COMPACT_OFFSET;
    const contentCenterY = (minY + maxY) / 2 + 60;
    const canvasCenterX = canvasWidth / (2 * this.autoZoomScale);
    const canvasCenterY = canvasHeight / (2 * this.autoZoomScale);
    
    this.autoOffsetX = canvasCenterX - contentCenterX;
    this.autoOffsetY = canvasCenterY - contentCenterY;

    console.log(`[ProjectPreviewDialog] Auto fit: scale=${this.autoZoomScale.toFixed(2)}, offset=(${this.autoOffsetX.toFixed(0)}, ${this.autoOffsetY.toFixed(0)})`);
  }

  private renderCanvas(): void {
    if (!this.canvasReady) return;

    this.canvasRenderer.render(this.project, {
      canvasOffsetX: this.currentOffsetX,
      canvasOffsetY: this.currentOffsetY,
      zoomScale: this.currentZoomScale,
      isConnecting: false,
      connectingFromTaskId: null,
      selectedTaskId: null,
      renderMode: RenderMode.COMPACT,
      blinkingTaskIds: this.blinkingTaskIds,
      blinkOpacity: this.blinkOpacity
    });

    if (this.showNodeNames) {
      this.renderNodeNames();
    }
  }


  private renderNodeNames(): void {
    const ctx = this.canvasRenderer.getContext();
    const scale = this.currentZoomScale;
    const offsetX = this.currentOffsetX;
    const offsetY = this.currentOffsetY;

    ctx.save();
    ctx.scale(scale, scale);

    this.project.tasks.forEach(task => {
      const x = task.x + offsetX;
      const y = task.y + offsetY + 50;

      ctx.globalAlpha = 0.9;
      ctx.font = '500 14px sans-serif';
      ctx.fillStyle = this.isDarkMode ? '#E0E0E0' : '#424242';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(task.name, x, y);
    });

    ctx.restore();
  }

  private resetView(): void {
    this.currentZoomScale = this.autoZoomScale;
    this.currentOffsetX = this.autoOffsetX;
    this.currentOffsetY = this.autoOffsetY;
    if (this.canvasReady) {
      this.renderCanvas();
    }
  }

  private handleZoomIn(): void {
    this.currentZoomScale = Math.min(this.currentZoomScale * 1.2, 3.0);
    if (this.canvasReady) {
      this.renderCanvas();
    }
  }

  private handleZoomOut(): void {
    this.currentZoomScale = Math.max(this.currentZoomScale / 1.2, 0.1);
    if (this.canvasReady) {
      this.renderCanvas();
    }
  }

  private handleCanvasTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      if (event.touches.length === 1) {
        this.isDragging = true;
        this.lastTouchX = event.touches[0].x;
        this.lastTouchY = event.touches[0].y;
      }
    } else if (event.type === TouchType.Move) {
      if (this.isDragging && event.touches.length === 1) {
        const deltaX = event.touches[0].x - this.lastTouchX;
        const deltaY = event.touches[0].y - this.lastTouchY;
        
        this.currentOffsetX += deltaX / this.currentZoomScale;
        this.currentOffsetY += deltaY / this.currentZoomScale;
        
        this.lastTouchX = event.touches[0].x;
        this.lastTouchY = event.touches[0].y;
        
        if (this.canvasReady) {
          this.renderCanvas();
        }
      }
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.isDragging = false;
    }
  }

  private getCardTitle(): string {
    switch (this.cardType) {
      case CardType.TOTAL_TASKS: return '总任务';
      case CardType.THIS_WEEK: return '本周到期';
      case CardType.OVERALL_COMPLETION: return '整体完成度';
      case CardType.OVERDUE: return '已逾期任务';
      case CardType.COMPLETED: return '已完成任务';
      case CardType.PENDING: return '进行中任务';
      case CardType.CRITICAL: return '关键任务';
      case CardType.NO_CHECKLIST: return '未拆解任务';
      case CardType.OPEN_CHECKLIST: return '待办检查项';
      default: return '项目预览';
    }
  }

  private async exportStaticImage(): Promise<void> {
    if (this.isExporting) return;
    
    this.isExporting = true;
    this.promptAction.showToast({ message: '正在生成图片...', duration: 1500 });

    try {
      this.stopBlinkAnimation();
      this.blinkOpacity = 1;
      this.renderCanvas();
      this.canvasRenderer.drawWatermark(3000, 3000);

      const pixelMap = await this.canvasRenderer.getContext().getPixelMap(0, 0, 3000, 3000);
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
      const imageData = await imagePackerApi.packing(pixelMap, packOpts);

      const context = this.uiContext.getHostContext() as common.UIAbilityContext;
      const fileName = `EasyFlow_${this.project.name}_${Date.now()}.png`;
      const filePath = `${context.cacheDir}/${fileName}`;
      
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.writeSync(file.fd, imageData);
      fileIo.closeSync(file);

      const documentPicker = new picker.DocumentViewPicker();
      const documentSaveOptions: picker.DocumentSaveOptions = {
        newFileNames: [fileName]
      };
      const documentSaveResult = await documentPicker.save(documentSaveOptions);
      
      if (documentSaveResult && documentSaveResult.length > 0) {
        const destUri = documentSaveResult[0];
        const destFile = fileIo.openSync(destUri, fileIo.OpenMode.READ_WRITE);
        const srcFile = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
        const buffer = new ArrayBuffer(imageData.byteLength);
        fileIo.readSync(srcFile.fd, buffer);
        fileIo.writeSync(destFile.fd, buffer);
        fileIo.closeSync(srcFile);
        fileIo.closeSync(destFile);
        
        this.promptAction.showToast({ message: '图片已保存', duration: 2000 });
      }

      fileIo.unlinkSync(filePath);
      this.startBlinkAnimation();
    } catch (error) {
      console.error('[ProjectPreviewDialog] Export static image error:', error);
      this.promptAction.showToast({ message: `导出失败: ${error}`, duration: 2000 });
      this.startBlinkAnimation();
    } finally {
      this.isExporting = false;
    }
  }

  private async exportLivePhoto(): Promise<void> {
    if (this.isExporting) return;
    
    this.isExporting = true;
    this.promptAction.showToast({ message: '正在生成动态图片...', duration: 2000 });

    try {
      this.promptAction.showToast({ message: 'HarmonyOS暂不支持实况照片，将保存为静态图片', duration: 2000 });
      
      this.stopBlinkAnimation();
      this.blinkOpacity = 1;
      this.renderCanvas();
      this.canvasRenderer.drawWatermark(3000, 3000);

      const pixelMap = await this.canvasRenderer.getContext().getPixelMap(0, 0, 3000, 3000);
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
      const imageData = await imagePackerApi.packing(pixelMap, packOpts);

      const context = this.uiContext.getHostContext() as common.UIAbilityContext;
      const fileName = `EasyFlow_Live_${this.project.name}_${Date.now()}.png`;
      const filePath = `${context.cacheDir}/${fileName}`;
      
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.writeSync(file.fd, imageData);
      fileIo.closeSync(file);

      const documentPicker = new picker.DocumentViewPicker();
      const documentSaveOptions: picker.DocumentSaveOptions = {
        newFileNames: [fileName]
      };
      const documentSaveResult = await documentPicker.save(documentSaveOptions);
      
      if (documentSaveResult && documentSaveResult.length > 0) {
        const destUri = documentSaveResult[0];
        const destFile = fileIo.openSync(destUri, fileIo.OpenMode.READ_WRITE);
        const srcFile = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
        const buffer = new ArrayBuffer(imageData.byteLength);
        fileIo.readSync(srcFile.fd, buffer);
        fileIo.writeSync(destFile.fd, buffer);
        fileIo.closeSync(srcFile);
        fileIo.closeSync(destFile);
        
        this.promptAction.showToast({ message: '图片已保存', duration: 2000 });
      }

      fileIo.unlinkSync(filePath);
      this.startBlinkAnimation();
    } catch (error) {
      console.error('[ProjectPreviewDialog] Export live photo error:', error);
      this.promptAction.showToast({ message: `导出失败: ${error}`, duration: 2000 });
      this.startBlinkAnimation();
    } finally {
      this.isExporting = false;
    }
  }

  build() {
    Column({ space: 0 }) {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Text(this.getCardTitle())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorResource.textPrimary)
            .layoutWeight(1)

          Button() {
            Text('✕')
              .fontSize(20)
              .fontColor(ColorResource.textSecondary)
          }
          .width(32)
          .height(32)
          .type(ButtonType.Circle)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.controller.close();
          })
        }
        .width('100%')

        Row({ space: 16 }) {
          Text(`闪烁节点：${this.blinkingTaskIds.length} 个`)
            .fontSize(13)
            .fontColor(ColorResource.textSecondary)
            .layoutWeight(1)

          Row({ space: 6 }) {
            Text('显示名称')
              .fontSize(13)
              .fontColor(ColorResource.textSecondary)
            
            Toggle({ type: ToggleType.Switch, isOn: this.showNodeNames })
              .width(40)
              .height(24)
              .selectedColor(ColorResource.primaryColor)
              .onChange((isOn: boolean) => {
                this.showNodeNames = isOn;
                if (this.canvasReady) {
                  this.renderCanvas();
                }
              })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 12 })

      Divider()
        .strokeWidth(1)
        .color(ColorResource.borderDivider)

      Stack() {
        Canvas(this.canvasRenderer.getContext())
          .width('100%')
          .height(400)
          .backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
          .onReady(() => {
            this.canvasReady = true;
            this.renderCanvas();
          })
          .onTouch((event: TouchEvent) => {
            this.handleCanvasTouch(event);
          })

        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Button() {
              Text('↻')
                .fontSize(18)
                .fontColor(Color.White)
            }
            .width(40)
            .height(40)
            .type(ButtonType.Circle)
            .backgroundColor('rgba(0, 0, 0, 0.6)')
            .onClick(() => {
              this.resetView();
            })

            Column({ space: 4 }) {
              Button() {
                Text('+')
                  .fontSize(20)
                  .fontColor(Color.White)
              }
              .width(40)
              .height(40)
              .type(ButtonType.Circle)
              .backgroundColor('rgba(0, 0, 0, 0.6)')
              .onClick(() => {
                this.handleZoomIn();
              })

              Button() {
                Text('−')
                  .fontSize(20)
                  .fontColor(Color.White)
              }
              .width(40)
              .height(40)
              .type(ButtonType.Circle)
              .backgroundColor('rgba(0, 0, 0, 0.6)')
              .onClick(() => {
                this.handleZoomOut();
              })
            }
          }

          Text(`${Math.round(this.currentZoomScale * 100)}%`)
            .fontSize(12)
            .fontColor(Color.White)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(0, 0, 0, 0.6)')
            .borderRadius(12)
        }
        .padding(12)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(400)
      .alignContent(Alignment.TopStart)

      Divider()
        .strokeWidth(1)
        .color(ColorResource.borderDivider)

      Row({ space: 12 }) {
        Button('保存图片')
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(ColorResource.primaryColor)
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .enabled(!this.isExporting)
          .onClick(() => {
            this.exportStaticImage();
          })

        Button('保存实况')
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(ColorResource.successColor)
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .enabled(!this.isExporting)
          .onClick(() => {
            this.exportLivePhoto();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
    }
    .width('90%')
    .constraintSize({ maxWidth: 500 })
    .backgroundColor(ColorResource.backgroundPage)
    .borderRadius(16)
    .shadow({
      radius: 32,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 8
    })
  }
}
