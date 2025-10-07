// File: entry/src/main/ets/utils/ThemeConfig.ets

// 定义阴影接口
interface ShadowConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export class ThemeConfig {
  // 主色调 - 现代蓝色系，增强视觉层次
  static readonly primaryColor = '#007AFF';
  static readonly primaryLight = '#E3F2FD';
  static readonly primaryDark = '#0056CC';
  static readonly primaryGradient = ['#007AFF', '#0056CC'];
  static readonly primaryUltraLight = '#F0F8FF';

  // 辅助色 - 中性灰色系
  static readonly secondaryColor = '#8E8E93';
  static readonly secondaryLight = '#F2F2F7';
  static readonly secondaryDark = '#1C1C1E';

  // 功能色 - 现代色彩系统
  static readonly successColor = '#34C759';
  static readonly successLight = '#E8F5E8';
  static readonly warningColor = '#FF9500';
  static readonly warningLight = '#FFF4E6';
  static readonly errorColor = '#FF3B30';
  static readonly errorLight = '#FFEBEE';
  static readonly infoColor = '#5AC8FA';
  static readonly infoLight = '#E3F2FD';

  // 中性色 - 现代灰色系统
  static readonly white = '#FFFFFF';
  static readonly gray50 = '#F9FAFB';
  static readonly gray100 = '#F2F2F7';
  static readonly gray200 = '#E5E5EA';
  static readonly gray300 = '#D1D1D6';
  static readonly gray400 = '#C7C7CC';
  static readonly gray500 = '#8E8E93';
  static readonly gray600 = '#636366';
  static readonly gray700 = '#48484A';
  static readonly gray800 = '#3A3A3C';
  static readonly gray900 = '#1C1C1E';

  // 背景色系统
  static readonly backgroundPrimary = '#FFFFFF';
  static readonly backgroundSecondary = '#F2F2F7';
  static readonly backgroundTertiary = '#E5E5EA';
  static readonly backgroundElevated = '#FFFFFF';
  static readonly backgroundCard = '#F8FAFC';
  static readonly backgroundPage = '#FAFBFC';
  static readonly backgroundInput = '#F5F5F7';

  // 透明背景色系统 - 增强版
  // 白色透明系列
  static readonly transparentWhite90 = 'rgba(255, 255, 255, 0.9)';
  static readonly transparentWhite80 = 'rgba(255, 255, 255, 0.8)';
  static readonly transparentWhite70 = 'rgba(255, 255, 255, 0.7)';
  static readonly transparentWhite60 = 'rgba(255, 255, 255, 0.6)';
  static readonly transparentWhite50 = 'rgba(255, 255, 255, 0.5)';
  static readonly transparentWhite40 = 'rgba(255, 255, 255, 0.4)';
  static readonly transparentWhite30 = 'rgba(255, 255, 255, 0.3)';
  static readonly transparentWhite20 = 'rgba(255, 255, 255, 0.2)';
  static readonly transparentWhite10 = 'rgba(255, 255, 255, 0.1)';
  
  // 黑色透明系列
  static readonly transparentBlack50 = 'rgba(0, 0, 0, 0.5)';
  static readonly transparentBlack40 = 'rgba(0, 0, 0, 0.4)';
  static readonly transparentBlack30 = 'rgba(0, 0, 0, 0.3)';
  static readonly transparentBlack25 = 'rgba(0, 0, 0, 0.25)';
  static readonly transparentBlack20 = 'rgba(0, 0, 0, 0.2)';
  static readonly transparentBlack15 = 'rgba(0, 0, 0, 0.15)';
  static readonly transparentBlack10 = 'rgba(0, 0, 0, 0.1)';
  static readonly transparentBlack05 = 'rgba(0, 0, 0, 0.05)';
  
  // 主色调透明系列
  static readonly transparentPrimary30 = 'rgba(0, 122, 255, 0.3)';
  static readonly transparentPrimary25 = 'rgba(0, 122, 255, 0.25)';
  static readonly transparentPrimary20 = 'rgba(0, 122, 255, 0.2)';
  static readonly transparentPrimary15 = 'rgba(0, 122, 255, 0.15)';
  static readonly transparentPrimary10 = 'rgba(0, 122, 255, 0.1)';
  static readonly transparentPrimary05 = 'rgba(0, 122, 255, 0.05)';
  
  // 功能色透明系列
  static readonly transparentSuccess20 = 'rgba(52, 199, 89, 0.2)';
  static readonly transparentSuccess10 = 'rgba(52, 199, 89, 0.1)';
  static readonly transparentWarning20 = 'rgba(255, 149, 0, 0.2)';
  static readonly transparentWarning10 = 'rgba(255, 149, 0, 0.1)';
  static readonly transparentError20 = 'rgba(255, 59, 48, 0.2)';
  static readonly transparentError10 = 'rgba(255, 59, 48, 0.1)';
  
  // 灰色透明系列
  static readonly transparentGray20 = 'rgba(142, 142, 147, 0.2)';
  static readonly transparentGray10 = 'rgba(142, 142, 147, 0.1)';
  static readonly transparentGray05 = 'rgba(142, 142, 147, 0.05)';
  
  // 完全透明
  static readonly transparentNone = '#00000000';

  // 阴影系统 - 现代阴影设计，增强层次感
  static readonly shadowSmall: ShadowConfig = {
    radius: 2,
    color: '#0000000A',
    offsetX: 0,
    offsetY: 1
  };

  static readonly shadowMedium: ShadowConfig = {
    radius: 6,
    color: '#00000012',
    offsetX: 0,
    offsetY: 3
  };

  static readonly shadowLarge: ShadowConfig = {
    radius: 12,
    color: '#00000018',
    offsetX: 0,
    offsetY: 6
  };

  static readonly shadowXLarge: ShadowConfig = {
    radius: 20,
    color: '#00000025',
    offsetX: 0,
    offsetY: 10
  };

  // 新增：悬浮阴影效果
  static readonly shadowHover: ShadowConfig = {
    radius: 16,
    color: '#00000020',
    offsetX: 0,
    offsetY: 8
  };

  // 卡片阴影 - 增强立体感
  static readonly cardShadow: ShadowConfig = {
    radius: 8,
    color: '#00000010',
    offsetX: 0,
    offsetY: 4
  };

  // 按钮阴影 - 增强交互感
  static readonly buttonShadow: ShadowConfig = {
    radius: 6,
    color: '#00000015',
    offsetX: 0,
    offsetY: 3
  };

  // 新增：输入框阴影
  static readonly inputShadow: ShadowConfig = {
    radius: 4,
    color: '#00000008',
    offsetX: 0,
    offsetY: 2
  };

  // 文字阴影系统
  static readonly textShadowSmall: ShadowConfig = {
    radius: 1,
    color: '#00000010',
    offsetX: 0,
    offsetY: 1
  };

  static readonly textShadowMedium: ShadowConfig = {
    radius: 1,
    color: '#00000030',
    offsetX: 0,
    offsetY: 1
  };

  static readonly textShadowLarge: ShadowConfig = {
    radius: 2,
    color: '#00000030',
    offsetX: 0,
    offsetY: 1
  };

  // 组件阴影系统
  static readonly componentShadowSmall: ShadowConfig = {
    radius: 6,
    color: '#00000012',
    offsetX: 0,
    offsetY: 2
  };

  static readonly componentShadowMedium: ShadowConfig = {
    radius: 8,
    color: '#0000000A',
    offsetX: 0,
    offsetY: 2
  };

  static readonly componentShadowLarge: ShadowConfig = {
    radius: 16,
    color: '#00000020',
    offsetX: 0,
    offsetY: 8
  };

  // 圆角系统 - 现代圆角设计
  static readonly radiusSmall = 6;
  static readonly radiusMedium = 12;
  static readonly radiusLarge = 16;
  static readonly radiusXLarge = 20;
  static readonly radiusXXLarge = 24;
  static readonly radiusRound = 50;

  // 间距系统 - 8px网格系统
  static readonly spacingXS = 4;
  static readonly spacingS = 8;
  static readonly spacingM = 12;
  static readonly spacingL = 16;
  static readonly spacingXL = 20;
  static readonly spacingXXL = 24;
  static readonly spacingXXXL = 32;
  static readonly spacingXXXXL = 40;
  static readonly spacingXXXXXL = 48;

  // 字体系统 - 现代字体层级
  static readonly fontSizeXS = 10;
  static readonly fontSizeS = 12;
  static readonly fontSizeM = 14;
  static readonly fontSizeL = 16;
  static readonly fontSizeXL = 18;
  static readonly fontSizeXXL = 20;
  static readonly fontSizeXXXL = 24;
  static readonly fontSizeXXXXL = 28;
  static readonly fontSizeXXXXXL = 32;
  static readonly fontSizeXXXXXXL = 40;

  // 字体权重
  static readonly fontWeightLight = FontWeight.Lighter;
  static readonly fontWeightRegular = FontWeight.Normal;
  static readonly fontWeightMedium = FontWeight.Medium;
  static readonly fontWeightSemiBold = FontWeight.Medium;
  static readonly fontWeightBold = FontWeight.Bold;

  // 毛玻璃效果系统 - 增强版
  static readonly backdropBlurNone = 0;
  static readonly backdropBlurTiny = 2;
  static readonly backdropBlurSmall = 5;
  static readonly backdropBlurMedium = 10;
  static readonly backdropBlurLarge = 15;
  static readonly backdropBlurXLarge = 20;
  static readonly backdropBlurXXLarge = 25;
  static readonly backdropBlurXXXLarge = 30;

  // 边框颜色系统
  static readonly borderLight = '#E2E8F0';
  static readonly borderGrid = '#E0E0E0';
  static readonly borderGridFine = '#F0F0F0';

  // 文字颜色系统
  static readonly textSecondary = '#666666';
  static readonly textPrimary = '#1D1D1F';
  static readonly textDescription = '#86868B';
  static readonly textSuccess = '#28A745';

  // 动画系统 - 现代动画时长
  static readonly animationFast = 150;
  static readonly animationNormal = 300;
  static readonly animationSlow = 500;
  static readonly animationSlower = 800;

  // 动画曲线
  static readonly animationEaseIn = Curve.EaseIn;
  static readonly animationEaseOut = Curve.EaseOut;
  static readonly animationEaseInOut = Curve.EaseInOut;
  static readonly animationSpring = Curve.EaseInOut;

  // 组件尺寸
  static readonly buttonHeightSmall = 32;
  static readonly buttonHeightMedium = 44;
  static readonly buttonHeightLarge = 52;
  static readonly buttonHeightXLarge = 60;

  static readonly inputHeightSmall = 36;
  static readonly inputHeightMedium = 44;
  static readonly inputHeightLarge = 52;

  static readonly cardPaddingSmall = 12;
  static readonly cardPaddingMedium = 16;
  static readonly cardPaddingLarge = 20;
  static readonly cardPaddingXLarge = 24;

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