// File: entry/src/main/ets/utils/ThemeConfig.ets

// 定义阴影接口
interface ShadowConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export class ThemeConfig {
  // 主色调
  static readonly primaryColor = '#007DFF';
  static readonly primaryLight = '#EFF6FF';
  static readonly primaryDark = '#0056B3';

  // 辅助色
  static readonly secondaryColor = '#6B7280';
  static readonly secondaryLight = '#F9FAFB';
  static readonly secondaryDark = '#374151';

  // 功能色
  static readonly successColor = '#10B981';
  static readonly warningColor = '#F59E0B';
  static readonly errorColor = '#EF4444';
  static readonly infoColor = '#3B82F6';

  // 中性色
  static readonly white = '#FFFFFF';
  static readonly gray50 = '#F9FAFB';
  static readonly gray100 = '#F3F4F6';
  static readonly gray200 = '#E5E7EB';
  static readonly gray300 = '#D1D5DB';
  static readonly gray400 = '#9CA3AF';
  static readonly gray500 = '#6B7280';
  static readonly gray600 = '#4B5563';
  static readonly gray700 = '#374151';
  static readonly gray800 = '#1F2937';
  static readonly gray900 = '#111827';

  // 阴影
  static readonly shadowSmall: ShadowConfig = {
    radius: 4,
    color: '#00000008',
    offsetX: 0,
    offsetY: 1
  };

  static readonly shadowMedium: ShadowConfig = {
    radius: 6,
    color: '#00000012',
    offsetX: 0,
    offsetY: 2
  };

  static readonly shadowLarge: ShadowConfig = {
    radius: 8,
    color: '#00000016',
    offsetX: 0,
    offsetY: 4
  };

  // 圆角
  static readonly radiusSmall = 4;
  static readonly radiusMedium = 8;
  static readonly radiusLarge = 12;
  static readonly radiusXLarge = 16;

  // 间距
  static readonly spacingXS = 4;
  static readonly spacingS = 8;
  static readonly spacingM = 12;
  static readonly spacingL = 16;
  static readonly spacingXL = 20;
  static readonly spacingXXL = 24;
  static readonly spacingXXXL = 32;

  // 字体大小
  static readonly fontSizeXS = 10;
  static readonly fontSizeS = 12;
  static readonly fontSizeM = 14;
  static readonly fontSizeL = 16;
  static readonly fontSizeXL = 18;
  static readonly fontSizeXXL = 20;
  static readonly fontSizeXXXL = 24;

  // 动画时长
  static readonly animationFast = 150;
  static readonly animationNormal = 300;
  static readonly animationSlow = 500;

  // 获取状态颜色
  static getStatusColor(status: 'success' | 'warning' | 'error' | 'info'): string {
    switch (status) {
      case 'success': return ThemeConfig.successColor;
      case 'warning': return ThemeConfig.warningColor;
      case 'error': return ThemeConfig.errorColor;
      case 'info': return ThemeConfig.infoColor;
      default: return ThemeConfig.infoColor;
    }
  }

  // 获取状态背景色
  static getStatusBackgroundColor(status: 'success' | 'warning' | 'error' | 'info'): string {
    switch (status) {
      case 'success': return '#ECFDF5';
      case 'warning': return '#FFFBEB';
      case 'error': return '#FEF2F2';
      case 'info': return '#EFF6FF';
      default: return '#EFF6FF';
    }
  }

  // 获取状态边框色
  static getStatusBorderColor(status: 'success' | 'warning' | 'error' | 'info'): string {
    switch (status) {
      case 'success': return '#D1FAE5';
      case 'warning': return '#FED7AA';
      case 'error': return '#FECACA';
      case 'info': return '#DBEAFE';
      default: return '#DBEAFE';
    }
  }
} 