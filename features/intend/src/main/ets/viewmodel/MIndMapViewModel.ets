import { MindMapNode, Position } from '../model/MindMapNode';
import { v4 as uuidv4 } from 'uuid';
import promptAction from '@ohos.promptAction';

// 使用ES6的Map来存储节点，可以极大地优化查找性能（O(1)复杂度）
type NodeMap = Map<string, MindMapNode>;

@Observed // 声明这是一个可观察类，其属性的变化可以被UI感知到
export class MindMapViewModel {
  // 使用Map存储所有节点，键是节点ID，值是节点对象
  public nodes: NodeMap = new Map();
  // 根节点的ID
  public rootId: string | null = null;
  // 画布的全局偏移量，拖动画布时改变此值
  public canvasOffset: Position = { x: 50, y: 250 };
  // 画布的全局缩放比例
  public zoomScale: number = 1.0;
  // 当前选中的节点的ID
  public selectedNodeId: string | null = null;

  // 用于检测双击事件的辅助变量
  public lastTapTime: number = 0;
  private readonly DOUBLE_TAP_INTERVAL = 300; // 双击时间间隔 (毫秒)

  constructor() {
    this.init();
  }

  // 初始化，创建根节点
  init(): void {
    const rootNode = new MindMapNode(uuidv4(), '核心主题', { x: 300, y: 300 });
    this.nodes.set(rootNode.id, rootNode);
    this.rootId = rootNode.id;
  }

  // 添加子节点
  addChildNode(): void {
    if (!this.selectedNodeId) {
      promptAction.showToast({ message: '请先选择一个节点' });
      return;
    }
    const parentNode = this.nodes.get(this.selectedNodeId);
    if (!parentNode) return;

    // 计算新节点的合适位置，避免重叠
    const childrenCount = parentNode.childrenIds.length;
    const newPosition: Position = {
      x: parentNode.position.x + 250,
      y: parentNode.position.y + (childrenCount * 120) - (parentNode.childrenIds.length > 0 ? 60 : 0)
    };

    const newNode = new MindMapNode(uuidv4(), '新分支', newPosition, parentNode.id);
    parentNode.childrenIds.push(newNode.id);
    this.nodes.set(newNode.id, newNode);

    // 关键：创建一个新的Map副本以触发UI刷新。直接修改Map内部不会被ArkUI框架检测到。
    this.nodes = new Map(this.nodes);
    this.selectedNodeId = newNode.id; // 选中新创建的节点
  }

  // 更新节点信息（文本和时间）
  updateNode(nodeId: string, text: string, time: Date | null): void {
    const nodeToUpdate = this.nodes.get(nodeId);
    if (nodeToUpdate) {
      nodeToUpdate.text = text;
      nodeToUpdate.customTime = time;
      this.nodes = new Map(this.nodes); // 同样需要创建新Map来触发刷新
      promptAction.showToast({ message: '节点已更新' });
    }
  }

  // 拖动画布（平移）
  panCanvas(dx: number, dy: number): void {
    this.canvasOffset.x += dx;
    this.canvasOffset.y += dy;
  }

  // 缩放画布
  zoomCanvas(scale: number, centerX: number, centerY: number): void {
    // 核心算法：以鼠标/手指中心为锚点进行缩放
    // 1. 计算缩放前，锚点在画布坐标系中的位置
    const pointX = (centerX - this.canvasOffset.x) / this.zoomScale;
    const pointY = (centerY - this.canvasOffset.y) / this.zoomScale;

    // 2. 更新缩放比例，并限制在合理范围
    this.zoomScale *= scale;
    this.zoomScale = Math.max(0.2, Math.min(this.zoomScale, 3.0));

    // 3. 缩放后，反向计算新的画布偏移量，确保锚点在屏幕上的位置不变
    this.canvasOffset.x = centerX - pointX * this.zoomScale;
    this.canvasOffset.y = centerY - pointY * this.zoomScale;
  }

  // 移动单个节点
  moveNode(nodeId: string, dx: number, dy: number): void {
    const node = this.nodes.get(nodeId);
    if (node) {
      // 拖动节点时，需要将屏幕上的移动距离根据缩放比例换算回画布坐标系的距离
      node.position.x += dx / this.zoomScale;
      node.position.y += dy / this.zoomScale;
      this.nodes = new Map(this.nodes); // 触发刷新
    }
  }

  // 处理画布的点击事件，用于选中或取消选中节点
  handleCanvasTap(event: TapGestureEvent): void {
    const tapX = event.localX;
    const tapY = event.localY;

    // 将屏幕点击坐标转换为画布内的绝对坐标
    const canvasX = (tapX - this.canvasOffset.x) / this.zoomScale;
    const canvasY = (tapY - this.canvasOffset.y) / this.zoomScale;

    let tappedNodeId: string | null = null;
    // 倒序遍历，以优先选中渲染在最上层的节点
    const nodesArray = Array.from(this.nodes.values()).reverse();
    for (const node of nodesArray) {
      const nodeRectWidth = 150;
      const nodeRectHeight = 40;
      if (canvasX >= node.position.x && canvasX <= node.position.x + nodeRectWidth &&
        canvasY >= node.position.y && canvasY <= node.position.y + nodeRectHeight) {
        tappedNodeId = node.id;
        break;
      }
    }

    if (tappedNodeId) {
      this.selectedNodeId = tappedNodeId;
    } else {
      this.selectedNodeId = null; // 点击空白区域，取消选择
    }
  }
}