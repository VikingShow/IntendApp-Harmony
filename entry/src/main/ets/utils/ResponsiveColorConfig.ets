/**
 * 响应式颜色配置工具类
 * 
 * 提供基于设备类型和屏幕尺寸的响应式颜色管理方案。
 * 专为手机端和不同屏幕尺寸的设备优化颜色显示效果。
 * 
 * 主要功能：
 * 1. 响应式颜色选择：根据设备类型自动选择合适的颜色
 * 2. 浮动卡片模式：为手机端浮动卡片提供特殊的颜色配置
 * 3. 深色模式适配：自动处理深色模式下的颜色显示
 * 4. 透明度调整：根据屏幕尺寸动态调整颜色透明度
 * 5. 对比度优化：确保在不同背景下的文字可读性
 * 
 * 使用场景：
 * - 手机端浮动卡片背景色
 * - 响应式布局的颜色适配
 * - 不同屏幕尺寸下的颜色优化
 * - 深色模式和浅色模式的自动切换
 * 
 * @author EasyFlow开发团队
 * @version 1.0.0
 * @since 2025-10
 */

import { ColorResource } from './ThemeConfig';
import { BreakpointSystem, DeviceType } from './BreakpointSystem';

/**
 * 浮动卡片颜色配置接口
 */
export interface FloatingCardColorConfig {
  /** 背景颜色 */
  backgroundColor: string | Resource;
  /** 边框颜色 */
  borderColor: string | Resource;
  /** 文字主色 */
  textPrimaryColor: string | Resource;
  /** 文字次色 */
  textSecondaryColor: string | Resource;
  /** 毛玻璃模糊度 */
  backdropBlur: number;
  /** 透明度 */
  opacity: number;
}

/**
 * RGB颜色值接口
 */
interface RGBColor {
  /** 红色分量 (0-255) */
  r: number;
  /** 绿色分量 (0-255) */
  g: number;
  /** 蓝色分量 (0-255) */
  b: number;
}

/**
 * 响应式颜色配置工具类
 */
export class ResponsiveColorConfig {
  /**
   * 获取浮动卡片的颜色配置
   * @param isDarkMode 是否为深色模式
   * @param screenWidth 屏幕宽度（vp）
   * @returns 浮动卡片颜色配置
   */
  static getFloatingCardColors(isDarkMode: boolean, screenWidth: number = 0): FloatingCardColorConfig {
    const isPhone = BreakpointSystem.isPhone(screenWidth);
    
    if (isPhone) {
      // 手机端：使用更高透明度的毛玻璃效果
      return {
        backgroundColor: isDarkMode ? 'rgba(28, 28, 30, 0.85)' : 'rgba(255, 255, 255, 0.85)',
        borderColor: isDarkMode ? 'rgba(80, 80, 80, 0.7)' : 'rgba(210, 215, 220, 0.75)',
        textPrimaryColor: isDarkMode ? 'rgba(255, 255, 255, 0.95)' : 'rgba(29, 29, 31, 0.95)',
        textSecondaryColor: isDarkMode ? 'rgba(174, 174, 178, 0.85)' : 'rgba(102, 102, 102, 0.85)',
        backdropBlur: 20,
        opacity: 0.95
      };
    } else {
      // 平板/大屏：使用更透明的毛玻璃效果，营造轻盈视觉
      return {
        backgroundColor: isDarkMode ? 'rgba(28, 28, 32, 0.45)' : 'rgba(255, 255, 255, 0.75)',
        borderColor: isDarkMode ? 'rgba(90, 90, 95, 0.35)' : 'rgba(215, 220, 225, 0.7)',
        textPrimaryColor: ColorResource.textPrimary,
        textSecondaryColor: ColorResource.textSecondary,
        backdropBlur: 20,
        opacity: 0.9
      };
    }
  }

  /**
   * 获取卡片背景色（响应式）
   * @param isFloating 是否为浮动卡片模式
   * @param isDarkMode 是否为深色模式
   * @param screenWidth 屏幕宽度（vp）
   * @returns 背景颜色
   */
  static getCardBackgroundColor(
    isFloating: boolean, 
    isDarkMode: boolean, 
    screenWidth: number = 0
  ): string | Resource {
    if (isFloating) {
      const config = ResponsiveColorConfig.getFloatingCardColors(isDarkMode, screenWidth);
      return config.backgroundColor;
    }
    return ColorResource.backgroundCard;
  }

  /**
   * 获取卡片边框色（响应式）
   * @param isFloating 是否为浮动卡片模式
   * @param isDarkMode 是否为深色模式
   * @param screenWidth 屏幕宽度（vp）
   * @returns 边框颜色
   */
  static getCardBorderColor(
    isFloating: boolean, 
    isDarkMode: boolean, 
    screenWidth: number = 0
  ): string | Resource {
    if (isFloating) {
      const config = ResponsiveColorConfig.getFloatingCardColors(isDarkMode, screenWidth);
      return config.borderColor;
    }
    return ColorResource.borderDefault;
  }

  /**
   * 获取统计卡片背景色（响应式）
   * @param isFloating 是否为浮动卡片模式
   * @param isDarkMode 是否为深色模式
   * @param baseColor 基础颜色
   * @returns 背景颜色
   */
  static getStatCardBackgroundColor(
    isFloating: boolean,
    isDarkMode: boolean,
    baseColor?: string | Resource
  ): string | Resource {
    if (isFloating) {
      // 浅色模式：使用纯白色背景，保持透明度
      // 深色模式：使用深灰色背景，提升透明度以获得更轻盈的视觉效果
      return isDarkMode ? 'rgba(40, 40, 45, 0.25)' : 'rgba(255, 255, 255, 0.6)';
    }
    // 平板端非浮动模式：深色模式下也使用轻度透明背景
    return isDarkMode ? 'rgba(35, 35, 40, 0.15)' : ColorResource.transparent;
  }

  /**
   * 获取统计卡片边框色（响应式）
   * @param isFloating 是否为浮动卡片模式
   * @param isDarkMode 是否为深色模式
   * @param baseColor 基础颜色（用于非浮动模式）
   * @returns 边框颜色
   */
  static getStatCardBorderColor(
    isFloating: boolean,
    isDarkMode: boolean,
    baseColor: string | Resource
  ): string | Resource {
    if (isFloating) {
      // 浅色模式：使用浅灰色边框，更柔和
      // 深色模式：使用灰色边框，降低不透明度以配合更透明的背景
      return isDarkMode ? 'rgba(90, 90, 95, 0.4)' : 'rgba(220, 225, 230, 0.8)';
    }
    // 平板端非浮动模式：深色模式下使用更柔和的边框
    return isDarkMode ? 'rgba(80, 80, 85, 0.25)' : baseColor;
  }

  /**
   * 获取任务卡片背景色（响应式）
   * @param isFloating 是否为浮动卡片模式
   * @param isDarkMode 是否为深色模式
   * @returns 背景颜色
   */
  static getTaskCardBackgroundColor(
    isFloating: boolean,
    isDarkMode: boolean
  ): string | Resource {
    if (isFloating) {
      // 浅色模式：使用纯白色背景，保持透明度
      // 深色模式：使用深灰色背景，提升透明度以获得更轻盈的视觉效果
      return isDarkMode ? 'rgba(35, 35, 40, 0.20)' : 'rgba(255, 255, 255, 0.35)';
    }
    // 平板端非浮动模式：深色模式下也使用轻度透明背景
    return isDarkMode ? 'rgba(30, 30, 35, 0.12)' : ColorResource.transparent;
  }

  /**
   * 获取任务卡片边框色（响应式）
   * @param isFloating 是否为浮动卡片模式
   * @param isDarkMode 是否为深色模式
   * @returns 边框颜色
   */
  static getTaskCardBorderColor(
    isFloating: boolean,
    isDarkMode: boolean
  ): string | Resource {
    if (isFloating) {
      // 浅色模式：使用浅灰色边框，更柔和
      // 深色模式：使用深灰色边框，降低不透明度以配合更透明的背景
      return isDarkMode ? 'rgba(70, 70, 75, 0.35)' : 'rgba(215, 220, 225, 0.7)';
    }
    // 平板端非浮动模式：深色模式下使用更柔和的边框
    return isDarkMode ? 'rgba(65, 65, 70, 0.20)' : ColorResource.surfaceNeutral;
  }

  /**
   * 获取毛玻璃模糊度（响应式）
   * @param isFloating 是否为浮动卡片模式
   * @param screenWidth 屏幕宽度（vp）
   * @returns 模糊半径
   */
  static getBackdropBlur(isFloating: boolean, screenWidth: number = 0): number {
    if (!isFloating) {
      return 0;
    }
    
    const isPhone = BreakpointSystem.isPhone(screenWidth);
    return isPhone ? 20 : 15;
  }

  /**
   * 获取删除按钮颜色（深色模式适配）
   * @param isDarkMode 是否为深色模式
   * @returns 颜色字符串
   */
  static getDeleteButtonColor(isDarkMode: boolean): string {
    return isDarkMode ? '#FF6B6B' : '#FF453A';
  }

  /**
   * 获取关键路径标签背景色（深色模式适配）
   * @param isDarkMode 是否为深色模式
   * @returns 颜色字符串
   */
  static getCriticalPathBadgeColor(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(255, 107, 107, 0.12)' : 'rgba(255, 69, 58, 0.08)';
  }

  /**
   * 获取浮动面板背景色（深色模式适配）
   * @param isDarkMode 是否为深色模式
   * @returns 颜色字符串
   */
  static getFloatingPanelBackgroundColor(isDarkMode: boolean): string {
    // 浅色模式：使用纯白色，保持透明度
    // 深色模式：使用半透明黑色
    return isDarkMode ? 'rgba(0, 0, 0, 0.35)' : 'rgba(255, 255, 255, 0.5)';
  }

  /**
   * 获取透明遮罩颜色（深色模式适配）
   * @param isDarkMode 是否为深色模式
   * @param opacity 透明度 (0-1)
   * @returns 颜色字符串
   */
  static getOverlayColor(isDarkMode: boolean, opacity: number = 0.5): string {
    const alphaHex = Math.round(opacity * 255).toString(16).padStart(2, '0');
    // 浅色模式使用白色遮罩，深色模式使用黑色遮罩
    return isDarkMode ? `#${alphaHex}000000` : `#${alphaHex}FFFFFF`;
  }

  /**
   * 获取网格线颜色（深色模式适配）
   * @param isDarkMode 是否为深色模式
   * @param isFine 是否为细线
   * @returns 颜色字符串
   */
  static getGridLineColor(isDarkMode: boolean, isFine: boolean = false): string {
    if (isDarkMode) {
      return isFine ? 'rgba(255, 255, 255, 0.03)' : 'rgba(255, 255, 255, 0.06)';
    } else {
      return isFine ? 'rgba(0, 0, 0, 0.03)' : 'rgba(0, 0, 0, 0.06)';
    }
  }

  /**
   * 获取侧边栏背景色（响应式）
   * @param screenWidth 屏幕宽度（vp）
   * @returns 颜色
   */
  static getSidebarBackgroundColor(screenWidth: number = 0): string | Resource {
    const isPhone = BreakpointSystem.isPhone(screenWidth);
    // 手机端使用更强的毛玻璃效果
    return isPhone ? ColorResource.overlayStrong : ColorResource.overlayMedium;
  }

  /**
   * 获取侧边栏毛玻璃模糊度（响应式）
   * @param screenWidth 屏幕宽度（vp）
   * @returns 模糊半径
   */
  static getSidebarBackdropBlur(screenWidth: number = 0): number {
    const isPhone = BreakpointSystem.isPhone(screenWidth);
    // 手机端使用更强的模糊效果
    return isPhone ? 25 : 20;
  }

  /**
   * 根据背景色自动选择合适的文字颜色
   * @param backgroundColor 背景颜色（十六进制字符串）
   * @returns 文字颜色资源
   */
  static getContrastTextColor(backgroundColor: string): Resource {
    // 简单的亮度计算，实际应用中可以使用更复杂的算法
    // 这里假设传入的是十六进制颜色值
    const rgb = ResponsiveColorConfig.hexToRgb(backgroundColor);
    if (!rgb) {
      return ColorResource.textPrimary;
    }
    
    // 计算相对亮度
    const luminance = (0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b) / 255;
    
    // 根据亮度选择文字颜色
    return luminance > 0.5 ? ColorResource.textPrimary : ColorResource.surface;
  }

  /**
   * 将十六进制颜色转换为RGB
   * @param hex 十六进制颜色值
   * @returns RGB对象
   */
  private static hexToRgb(hex: string): RGBColor | null {
    // 移除 # 号
    hex = hex.replace('#', '');
    
    // 处理 RGBA 格式
    if (hex.length === 8) {
      hex = hex.substring(2); // 移除透明度部分
    }
    
    if (hex.length !== 6) {
      return null;
    }
    
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    
    const result: RGBColor = { r: r, g: g, b: b };
    return result;
  }
}

