// File: entry/src/main/ets/components/InlineCanvasIcon.ets
/**
 * Inline canvas icons used in NodeWorkspace previews.
 * Kept consistent with the main CanvasRenderer inline icons.
 */

import { ThemeConfig } from '../utils/ThemeConfig';

export type InlineCanvasIconKind = 'calendar' | 'clock' | 'select' | 'checklist' | 'tag' | 'user' | 'pencil';

@Component
export struct InlineCanvasIcon {
  @Prop kind: InlineCanvasIconKind;
  @Prop iconSize: number = 10;
  @Prop iconColor: string = ThemeConfig.textSecondary;
  @Prop holeColor: string = ThemeConfig.backgroundCard;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private drawRoundRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number,
    radius: number): void {
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

  private drawCalendarIcon(x: number, y: number, size: number, color: string): void {
    const ctx = this.ctx;
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.5;
    const r = Math.max(2, Math.floor(size / 6));
    this.drawRoundRect(ctx, x, y, size, size, r);
    ctx.stroke();

    const headerH = Math.max(3, Math.floor(size * 0.32));
    ctx.beginPath();
    ctx.moveTo(x, y + headerH);
    ctx.lineTo(x + size, y + headerH);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(x + size * 0.28, y);
    ctx.lineTo(x + size * 0.28, y + headerH * 0.6);
    ctx.moveTo(x + size * 0.72, y);
    ctx.lineTo(x + size * 0.72, y + headerH * 0.6);
    ctx.stroke();

    const cellY = y + headerH + Math.max(1, Math.floor(size * 0.18));
    const cellSize = Math.max(2, Math.floor(size * 0.22));
    const gap = Math.max(1, Math.floor(size * 0.12));
    const startX = x + Math.max(2, Math.floor(size * 0.18));
    ctx.fillStyle = color;
    ctx.fillRect(startX, cellY, cellSize, cellSize);
    ctx.fillRect(startX + cellSize + gap, cellY, cellSize, cellSize);
    ctx.fillRect(startX + (cellSize + gap) * 2, cellY, cellSize, cellSize);
    ctx.restore();
  }

  private drawClockIcon(x: number, y: number, size: number, color: string): void {
    const ctx = this.ctx;
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.5;
    const r = size / 2;
    const cx = x + r;
    const cy = y + r;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx, cy - r * 0.55);
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + r * 0.5, cy);
    ctx.stroke();
    ctx.restore();
  }

  private drawSelectIcon(x: number, y: number, size: number, color: string): void {
    const ctx = this.ctx;
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const r = size / 2;
    const cx = x + r;
    const cy = y + r;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(x + size * 0.22, y + size * 0.56);
    ctx.lineTo(x + size * 0.42, y + size * 0.74);
    ctx.lineTo(x + size * 0.78, y + size * 0.28);
    ctx.stroke();
    ctx.restore();
  }

  // Reverted (stroke) checklist icon to match the preferred earlier style.
  private drawChecklistIcon(x: number, y: number, size: number, color: string): void {
    const ctx = this.ctx;
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.5;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const leftW = Math.max(4, Math.floor(size * 0.44));
    const lineX = x + leftW + 2;
    const lineW = Math.max(4, size - leftW - 2);

    ctx.beginPath();
    ctx.moveTo(lineX, y + size * 0.35);
    ctx.lineTo(lineX + lineW, y + size * 0.35);
    ctx.moveTo(lineX, y + size * 0.70);
    ctx.lineTo(lineX + lineW, y + size * 0.70);
    ctx.stroke();

    const checkW = leftW;
    const drawCheck = (baseY: number) => {
      ctx.beginPath();
      ctx.moveTo(x + checkW * 0.10, baseY + checkW * 0.55);
      ctx.lineTo(x + checkW * 0.32, baseY + checkW * 0.78);
      ctx.lineTo(x + checkW * 0.72, baseY + checkW * 0.22);
      ctx.stroke();
    };
    drawCheck(y + size * 0.08);
    drawCheck(y + size * 0.55);
    ctx.restore();
  }

  private drawTagIcon(x: number, y: number, size: number, color: string): void {
    const ctx = this.ctx;
    ctx.save();
    ctx.fillStyle = color;

    const cx = x + size / 2;
    const cy = y + size / 2;
    ctx.translate(cx, cy);
    ctx.rotate(-Math.PI / 4);
    ctx.translate(-cx, -cy);

    const s = size * 0.92;
    const ox = cx - s / 2;
    const oy = cy - s / 2;
    const left = ox;
    const top = oy + s * 0.18;
    const right = ox + s;
    const bottom = oy + s * 0.82;
    const notch = ox + s * 0.36;
    const midY = oy + s / 2;

    ctx.beginPath();
    ctx.moveTo(notch, top);
    ctx.lineTo(right, top);
    ctx.lineTo(right, bottom);
    ctx.lineTo(notch, bottom);
    ctx.lineTo(left, midY);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = this.holeColor;
    ctx.beginPath();
    ctx.arc(notch + s * 0.18, midY, Math.max(1.2, s * 0.10), 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  private drawUserIcon(x: number, y: number, size: number, color: string): void {
    const ctx = this.ctx;
    ctx.save();
    ctx.fillStyle = color;

    const cx = x + size / 2;
    const headR = size * 0.24;
    const headY = y + size * 0.34;
    ctx.beginPath();
    ctx.arc(cx, headY, headR, 0, Math.PI * 2);
    ctx.fill();

    const bodyR = size * 0.56;
    const bodyCY = y + size * 1.08;
    ctx.beginPath();
    ctx.arc(cx, bodyCY, bodyR, Math.PI, 0);
    ctx.lineTo(cx + bodyR, y + size);
    ctx.lineTo(cx - bodyR, y + size);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  private drawPencilIcon(x: number, y: number, size: number, color: string): void {
    const ctx = this.ctx;
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    ctx.beginPath();
    ctx.moveTo(x + size * 0.22, y + size * 0.78);
    ctx.lineTo(x + size * 0.78, y + size * 0.22);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(x + size * 0.68, y + size * 0.16);
    ctx.lineTo(x + size * 0.86, y + size * 0.34);
    ctx.stroke();
    ctx.restore();
  }

  private redraw(): void {
    const outer = Math.max(1, Math.floor(this.iconSize));
    this.ctx.clearRect(0, 0, outer, outer);

    // Canvas 会裁剪绘制区域；描边类图标如果贴边绘制，会被裁掉一部分。
    // 这里给图标留出内边距，确保完整显示。
    const inset = Math.max(0.8, Math.min(1.6, outer * 0.12));
    const size = Math.max(1, outer - inset * 2);
    const x = inset;
    const y = inset;
    const color = this.iconColor;

    if (this.kind === 'calendar') this.drawCalendarIcon(x, y, size, color);
    if (this.kind === 'clock') this.drawClockIcon(x, y, size, color);
    if (this.kind === 'select') this.drawSelectIcon(x, y, size, color);
    if (this.kind === 'checklist') this.drawChecklistIcon(x, y, size, color);
    if (this.kind === 'tag') this.drawTagIcon(x, y, size, color);
    if (this.kind === 'user') this.drawUserIcon(x, y, size, color);
    if (this.kind === 'pencil') this.drawPencilIcon(x, y, size, color);
  }

  build() {
    Canvas(this.ctx)
      .width(this.iconSize)
      .height(this.iconSize)
      .backgroundColor(Color.Transparent)
      .onReady(() => {
        this.redraw();
      });
  }
}
