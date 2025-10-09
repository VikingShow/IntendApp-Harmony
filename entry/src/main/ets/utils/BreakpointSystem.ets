/**
 * 断点系统工具类
 * 
 * 提供多端适配的断点定义和响应式布局支持
 * 支持手机、平板、折叠屏等不同设备尺寸
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

/**
 * 设备类型枚举
 */
export enum DeviceType {
  /** 手机 - 小屏设备 */
  PHONE = 'phone',
  /** 平板竖屏 - 中等屏幕 */
  TABLET_PORTRAIT = 'tablet_portrait',
  /** 平板横屏 - 大屏设备 */
  TABLET_LANDSCAPE = 'tablet_landscape',
  /** 折叠屏展开 - 超大屏 */
  FOLDABLE = 'foldable'
}

/**
 * 断点配置接口
 */
export interface BreakpointConfig {
  /** 设备类型 */
  deviceType: DeviceType;
  /** 最小宽度（vp） */
  minWidth: number;
  /** 最大宽度（vp），可选 */
  maxWidth?: number;
  /** 侧边栏宽度比例 */
  sidebarRatio: number;
  /** 是否显示侧边栏 */
  showSidebar: boolean;
  /** 是否使用折叠式侧边栏 */
  collapsibleSidebar: boolean;
  /** 字体缩放比例 */
  fontScale: number;
  /** 间距缩放比例 */
  spacingScale: number;
  /** 列数 */
  columns: number;
}

/**
 * 断点系统类
 */
export class BreakpointSystem {
  /** 断点配置列表 */
  private static readonly BREAKPOINTS: BreakpointConfig[] = [
    {
      // 手机 - 320-599vp
      deviceType: DeviceType.PHONE,
      minWidth: 0,
      maxWidth: 599,
      sidebarRatio: 0, // 手机端不显示固定侧边栏
      showSidebar: false,
      collapsibleSidebar: true,
      fontScale: 0.9,
      spacingScale: 0.85,
      columns: 1
    },
    {
      // 平板竖屏 - 600-839vp
      deviceType: DeviceType.TABLET_PORTRAIT,
      minWidth: 600,
      maxWidth: 839,
      sidebarRatio: 0.35,
      showSidebar: true,
      collapsibleSidebar: false,
      fontScale: 1.0,
      spacingScale: 1.0,
      columns: 2
    },
    {
      // 平板横屏 - 840-1439vp
      deviceType: DeviceType.TABLET_LANDSCAPE,
      minWidth: 840,
      maxWidth: 1439,
      sidebarRatio: 0.3,
      showSidebar: true,
      collapsibleSidebar: false,
      fontScale: 1.0,
      spacingScale: 1.0,
      columns: 2
    },
    {
      // 折叠屏/2-in-1 - 1440vp+
      deviceType: DeviceType.FOLDABLE,
      minWidth: 1440,
      sidebarRatio: 0.25,
      showSidebar: true,
      collapsibleSidebar: false,
      fontScale: 1.1,
      spacingScale: 1.1,
      columns: 3
    }
  ];

  /**
   * 根据屏幕宽度获取当前断点配置
   * @param width 屏幕宽度（vp）
   * @returns 断点配置
   */
  static getCurrentBreakpoint(width: number): BreakpointConfig {
    // 从后往前查找，找到第一个满足条件的断点
    for (let i = BreakpointSystem.BREAKPOINTS.length - 1; i >= 0; i--) {
      const bp = BreakpointSystem.BREAKPOINTS[i];
      if (width >= bp.minWidth) {
        if (bp.maxWidth === undefined || width <= bp.maxWidth) {
          return bp;
        }
      }
    }
    // 默认返回手机断点
    return BreakpointSystem.BREAKPOINTS[0];
  }

  /**
   * 判断是否为手机设备
   * @param width 屏幕宽度（vp）
   * @returns 是否为手机
   */
  static isPhone(width: number): boolean {
    return BreakpointSystem.getCurrentBreakpoint(width).deviceType === DeviceType.PHONE;
  }

  /**
   * 判断是否为平板设备
   * @param width 屏幕宽度（vp）
   * @returns 是否为平板
   */
  static isTablet(width: number): boolean {
    const deviceType = BreakpointSystem.getCurrentBreakpoint(width).deviceType;
    return deviceType === DeviceType.TABLET_PORTRAIT || 
           deviceType === DeviceType.TABLET_LANDSCAPE;
  }

  /**
   * 判断是否为大屏设备（折叠屏/2-in-1）
   * @param width 屏幕宽度（vp）
   * @returns 是否为大屏设备
   */
  static isLargeScreen(width: number): boolean {
    return BreakpointSystem.getCurrentBreakpoint(width).deviceType === DeviceType.FOLDABLE;
  }

  /**
   * 获取响应式字体大小
   * @param baseSize 基础字体大小
   * @param width 屏幕宽度（vp）
   * @returns 缩放后的字体大小
   */
  static getResponsiveFontSize(baseSize: number, width: number): number {
    const config = BreakpointSystem.getCurrentBreakpoint(width);
    return baseSize * config.fontScale;
  }

  /**
   * 获取响应式间距
   * @param baseSpacing 基础间距
   * @param width 屏幕宽度（vp）
   * @returns 缩放后的间距
   */
  static getResponsiveSpacing(baseSpacing: number, width: number): number {
    const config = BreakpointSystem.getCurrentBreakpoint(width);
    return baseSpacing * config.spacingScale;
  }
}

