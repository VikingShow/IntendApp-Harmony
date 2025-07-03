export interface Position {
  x: number;
  y: number;
}

export class MindMapNode {
  id: string;
  text: string;
  parentId: string | null = null;
  childrenIds: string[] = [];
  position: Position;
  customTime: Date | null = null;

  // 构造函数，用于创建新的节点实例
  constructor(id: string, text: string, position: Position, parentId: string | null = null) {
    this.id = id;
    this.text = text;
    this.position = position;
    this.parentId = parentId;
  }
}