// File: entry/src/main/ets/services/ComponentRegistry.ets

import { 
  ComponentDefinition, 
  ComponentType, 
  ComponentCategory,
  ComponentConfig,
  ComponentRenderContext,
  ComponentRenderResult,
  PropertyOption
} from '../model/ComponentSystem';

/**
 * 组件注册表
 * 管理所有可用的组件定义
 */
export class ComponentRegistry {
  private static instance: ComponentRegistry;
  private components: Map<string, ComponentDefinition> = new Map();
  private renderers: Map<string, (context: ComponentRenderContext) => ComponentRenderResult> = new Map();

  private constructor() {
    this.registerDefaultComponents();
  }

  public static getInstance(): ComponentRegistry {
    if (!ComponentRegistry.instance) {
      ComponentRegistry.instance = new ComponentRegistry();
    }
    return ComponentRegistry.instance;
  }

  /**
   * 注册组件定义
   */
  public registerComponent(definition: ComponentDefinition): void {
    this.components.set(definition.id, definition);
    console.log(`[ComponentRegistry] 注册组件: ${definition.name} (${definition.id})`);
  }

  /**
   * 注册组件渲染器
   */
  public registerRenderer(componentId: string, renderer: (context: ComponentRenderContext) => ComponentRenderResult): void {
    this.renderers.set(componentId, renderer);
    console.log(`[ComponentRegistry] 注册渲染器: ${componentId}`);
  }

  /**
   * 获取组件定义
   */
  public getComponent(componentId: string): ComponentDefinition | undefined {
    return this.components.get(componentId);
  }

  /**
   * 获取所有组件
   */
  public getAllComponents(): ComponentDefinition[] {
    return Array.from(this.components.values());
  }

  /**
   * 根据分类获取组件
   */
  public getComponentsByCategory(category: ComponentCategory): ComponentDefinition[] {
    return this.getAllComponents().filter(comp => comp.category === category);
  }

  /**
   * 渲染组件
   */
  public renderComponent(context: ComponentRenderContext): ComponentRenderResult | null {
    const renderer = this.renderers.get(context.componentConfig.componentId);
    if (!renderer) {
      console.error(`[ComponentRegistry] 未找到渲染器: ${context.componentConfig.componentId}`);
      return null;
    }

    try {
      return renderer(context);
    } catch (error) {
      console.error(`[ComponentRegistry] 渲染组件失败:`, error);
      return null;
    }
  }

  /**
   * 注册默认组件
   */
  private registerDefaultComponents(): void {
    // 注册基础组件
    this.registerTextComponent();
    this.registerTimeComponent();
    this.registerProgressComponent();
    this.registerStatusComponent();
    this.registerTagComponent();
  }

  /**
   * 注册文本组件
   */
  private registerTextComponent(): void {
    const textOptions: PropertyOption[] = [
      { label: '正常', value: 'normal' },
      { label: '中等', value: 'medium' },
      { label: '粗体', value: 'bold' }
    ];

    const definition: ComponentDefinition = {
      id: 'text_component',
      type: ComponentType.TEXT,
      name: '文本',
      description: '显示文本内容',
      icon: '📝',
      category: ComponentCategory.BASIC,
      configSchema: {
        properties: [
          {
            key: 'text',
            name: '文本内容',
            type: 'string',
            required: true,
            defaultValue: '文本内容',
            placeholder: '请输入文本内容'
          },
          {
            key: 'maxLength',
            name: '最大长度',
            type: 'number',
            required: false,
            defaultValue: 100,
            min: 1,
            max: 500
          }
        ],
        style: [
          {
            key: 'fontSize',
            name: '字体大小',
            type: 'number',
            defaultValue: 16,
            min: 10,
            max: 32
          },
          {
            key: 'fontColor',
            name: '字体颜色',
            type: 'color',
            defaultValue: '#333333'
          },
          {
            key: 'fontWeight',
            name: '字体粗细',
            type: 'select',
            defaultValue: 'normal',
            options: textOptions
          }
        ]
      },
      defaultProperties: {
        text: '文本内容',
        maxLength: 100
      },
      defaultStyle: {
        fontSize: 16,
        fontColor: '#333333',
        fontWeight: 'normal'
      }
    };

    this.registerComponent(definition);
  }

  /**
   * 注册时间组件
   */
  private registerTimeComponent(): void {
    const timeOptions: PropertyOption[] = [
      { label: '年-月-日 时:分', value: 'YYYY-MM-DD HH:mm' },
      { label: '月-日 时:分', value: 'MM-DD HH:mm' },
      { label: '时:分', value: 'HH:mm' }
    ];

    const definition: ComponentDefinition = {
      id: 'time_component',
      type: ComponentType.TIME,
      name: '时间',
      description: '显示时间信息',
      icon: '⏰',
      category: ComponentCategory.BASIC,
      configSchema: {
        properties: [
          {
            key: 'showStartTime',
            name: '显示开始时间',
            type: 'boolean',
            required: false,
            defaultValue: true
          },
          {
            key: 'showEndTime',
            name: '显示结束时间',
            type: 'boolean',
            required: false,
            defaultValue: true
          },
          {
            key: 'showDuration',
            name: '显示持续时间',
            type: 'boolean',
            required: false,
            defaultValue: true
          },
          {
            key: 'timeFormat',
            name: '时间格式',
            type: 'select',
            required: false,
            defaultValue: 'YYYY-MM-DD HH:mm',
            options: timeOptions
          }
        ],
        style: [
          {
            key: 'fontSize',
            name: '字体大小',
            type: 'number',
            defaultValue: 14,
            min: 10,
            max: 24
          },
          {
            key: 'fontColor',
            name: '字体颜色',
            type: 'color',
            defaultValue: '#666666'
          }
        ]
      },
      defaultProperties: {
        showStartTime: true,
        showEndTime: true,
        showDuration: true,
        timeFormat: 'YYYY-MM-DD HH:mm'
      },
      defaultStyle: {
        fontSize: 14,
        fontColor: '#666666'
      }
    };

    this.registerComponent(definition);
  }

  /**
   * 注册进度组件
   */
  private registerProgressComponent(): void {
    const definition: ComponentDefinition = {
      id: 'progress_component',
      type: ComponentType.PROGRESS,
      name: '进度',
      description: '显示进度信息',
      icon: '📊',
      category: ComponentCategory.BASIC,
      configSchema: {
        properties: [
          {
            key: 'showPercentage',
            name: '显示百分比',
            type: 'boolean',
            required: false,
            defaultValue: true
          },
          {
            key: 'showText',
            name: '显示文字',
            type: 'boolean',
            required: false,
            defaultValue: true
          },
          {
            key: 'progressText',
            name: '进度文字',
            type: 'string',
            required: false,
            defaultValue: '进度',
            placeholder: '请输入进度文字'
          }
        ],
        style: [
          {
            key: 'progressColor',
            name: '进度条颜色',
            type: 'color',
            defaultValue: '#007DFF'
          },
          {
            key: 'backgroundColor',
            name: '背景颜色',
            type: 'color',
            defaultValue: '#F0F0F0'
          },
          {
            key: 'height',
            name: '进度条高度',
            type: 'number',
            defaultValue: 8,
            min: 4,
            max: 20
          }
        ]
      },
      defaultProperties: {
        showPercentage: true,
        showText: true,
        progressText: '进度'
      },
      defaultStyle: {
        progressColor: '#007DFF',
        backgroundColor: '#F0F0F0',
        height: 8
      }
    };

    this.registerComponent(definition);
  }

  /**
   * 注册状态组件
   */
  private registerStatusComponent(): void {
    const statusOptions: PropertyOption[] = [
      { label: '进行中', value: 'progress' },
      { label: '已完成', value: 'completed' },
      { label: '已暂停', value: 'paused' },
      { label: '已取消', value: 'cancelled' }
    ];

    const definition: ComponentDefinition = {
      id: 'status_component',
      type: ComponentType.STATUS,
      name: '状态',
      description: '显示状态信息',
      icon: '🔘',
      category: ComponentCategory.BASIC,
      configSchema: {
        properties: [
          {
            key: 'statusType',
            name: '状态类型',
            type: 'select',
            required: true,
            defaultValue: 'progress',
            options: statusOptions
          },
          {
            key: 'showIcon',
            name: '显示图标',
            type: 'boolean',
            required: false,
            defaultValue: true
          },
          {
            key: 'showText',
            name: '显示文字',
            type: 'boolean',
            required: false,
            defaultValue: true
          }
        ],
        style: [
          {
            key: 'fontSize',
            name: '字体大小',
            type: 'number',
            defaultValue: 14,
            min: 10,
            max: 20
          }
        ]
      },
      defaultProperties: {
        statusType: 'progress',
        showIcon: true,
        showText: true
      },
      defaultStyle: {
        fontSize: 14
      }
    };

    this.registerComponent(definition);
  }

  /**
   * 注册标签组件
   */
  private registerTagComponent(): void {
    const definition: ComponentDefinition = {
      id: 'tag_component',
      type: ComponentType.TAG,
      name: '标签',
      description: '显示标签信息',
      icon: '🏷️',
      category: ComponentCategory.BASIC,
      configSchema: {
        properties: [
          {
            key: 'tags',
            name: '标签列表',
            type: 'string',
            required: true,
            defaultValue: '重要,紧急',
            placeholder: '用逗号分隔多个标签'
          },
          {
            key: 'maxTags',
            name: '最大标签数',
            type: 'number',
            required: false,
            defaultValue: 5,
            min: 1,
            max: 10
          }
        ],
        style: [
          {
            key: 'tagColor',
            name: '标签颜色',
            type: 'color',
            defaultValue: '#007DFF'
          },
          {
            key: 'textColor',
            name: '文字颜色',
            type: 'color',
            defaultValue: '#FFFFFF'
          },
          {
            key: 'fontSize',
            name: '字体大小',
            type: 'number',
            defaultValue: 12,
            min: 10,
            max: 16
          }
        ]
      },
      defaultProperties: {
        tags: '重要,紧急',
        maxTags: 5
      },
      defaultStyle: {
        tagColor: '#007DFF',
        textColor: '#FFFFFF',
        fontSize: 12
      }
    };

    this.registerComponent(definition);
  }
}