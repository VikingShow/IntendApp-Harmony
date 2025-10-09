// File: entry/src/main/ets/utils/ThemeConfig.ets

// 定义阴影接口
interface ShadowConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

// 颜色资源类 - 使用 Resource 类型从 color.json 读取
export class ColorResource {
  // 主色调
  static readonly primaryColor = $r('app.color.primary_color');
  static readonly primaryLight = $r('app.color.primary_light');
  static readonly primaryDark = $r('app.color.primary_dark');
  static readonly primaryUltraLight = $r('app.color.primary_ultra_light');

  // 辅助色
  static readonly secondaryColor = $r('app.color.secondary_color');
  static readonly secondaryLight = $r('app.color.secondary_light');
  static readonly secondaryDark = $r('app.color.secondary_dark');

  // 功能色
  static readonly successColor = $r('app.color.success_color');
  static readonly successLight = $r('app.color.success_light');
  static readonly warningColor = $r('app.color.warning_color');
  static readonly warningLight = $r('app.color.warning_light');
  static readonly errorColor = $r('app.color.error_color');
  static readonly errorLight = $r('app.color.error_light');
  static readonly infoColor = $r('app.color.info_color');
  static readonly infoLight = $r('app.color.info_light');

  // 表面色系统
  static readonly surface = $r('app.color.surface');
  static readonly surfaceSubtle = $r('app.color.surface_subtle');
  static readonly surfaceLight = $r('app.color.surface_light');
  static readonly surfaceNeutral = $r('app.color.surface_neutral');
  static readonly surfaceMuted = $r('app.color.surface_muted');
  static readonly surfaceStrong = $r('app.color.surface_strong');
  static readonly surfaceEmphasized = $r('app.color.surface_emphasized');
  static readonly surfaceBold = $r('app.color.surface_bold');
  static readonly surfaceDark = $r('app.color.surface_dark');
  static readonly surfaceDeep = $r('app.color.surface_deep');
  static readonly surfaceDeepest = $r('app.color.surface_deepest');

  // 背景色系统
  static readonly backgroundPrimary = $r('app.color.background_primary');
  static readonly backgroundSecondary = $r('app.color.background_secondary');
  static readonly backgroundTertiary = $r('app.color.background_tertiary');
  static readonly backgroundElevated = $r('app.color.background_elevated');
  static readonly backgroundCard = $r('app.color.background_card');
  static readonly backgroundPage = $r('app.color.background_page');
  static readonly backgroundInput = $r('app.color.background_input');

  // 覆盖层颜色
  static readonly overlayHeavy = $r('app.color.overlay_heavy');
  static readonly overlayStrong = $r('app.color.overlay_strong');
  static readonly overlayMedium = $r('app.color.overlay_medium');
  static readonly overlayRegular = $r('app.color.overlay_regular');
  static readonly overlayLight = $r('app.color.overlay_light');
  static readonly overlaySubtle = $r('app.color.overlay_subtle');

  // 阴影颜色
  static readonly shadowColorStrong = $r('app.color.shadow_color_strong');
  static readonly shadowColorMedium = $r('app.color.shadow_color_medium');
  static readonly shadowColorRegular = $r('app.color.shadow_color_regular');
  static readonly shadowColorLight = $r('app.color.shadow_color_light');
  static readonly shadowColorSubtle = $r('app.color.shadow_color_subtle');
  static readonly shadowColorFaint = $r('app.color.shadow_color_faint');

  // 悬停效果颜色
  static readonly hoverPrimary = $r('app.color.hover_primary');
  static readonly hoverPrimaryLight = $r('app.color.hover_primary_light');
  static readonly hoverSuccess = $r('app.color.hover_success');
  static readonly hoverWarning = $r('app.color.hover_warning');
  static readonly hoverError = $r('app.color.hover_error');
  static readonly hoverNeutral = $r('app.color.hover_neutral');

  // 完全透明
  static readonly transparent = $r('app.color.transparent');

  // 边框颜色
  static readonly borderDefault = $r('app.color.border_default');
  static readonly borderGrid = $r('app.color.border_grid');
  static readonly borderGridFine = $r('app.color.border_grid_fine');
  static readonly borderDivider = $r('app.color.border_divider');

  // 文字颜色
  static readonly textPrimary = $r('app.color.text_primary');
  static readonly textSecondary = $r('app.color.text_secondary');
  static readonly textTertiary = $r('app.color.text_tertiary');
  static readonly textSuccess = $r('app.color.text_success');
  static readonly textMuted = $r('app.color.text_muted');
  static readonly textSubdued = $r('app.color.text_subdued');
  static readonly textStrong = $r('app.color.text_strong');

  // 任务状态颜色
  static readonly taskCritical = $r('app.color.task_critical');
  static readonly taskNormal = $r('app.color.task_normal');
  static readonly taskSelected = $r('app.color.task_selected');
  static readonly taskProgress = $r('app.color.task_progress');

  // 项目类型颜色
  static readonly projectDevelopment = $r('app.color.project_development');
  static readonly projectDesign = $r('app.color.project_design');
  static readonly projectMarketing = $r('app.color.project_marketing');
  static readonly projectResearch = $r('app.color.project_research');
  static readonly projectOther = $r('app.color.project_other');

  // 画布网格线颜色
  static readonly canvasGridLine = $r('app.color.canvas_grid_line');
  static readonly canvasGridLineFine = $r('app.color.canvas_grid_line_fine');

  // 装饰性颜色
  static readonly decorativeSlate = $r('app.color.decorative_slate');
  static readonly decorativeSlateDark = $r('app.color.decorative_slate_dark');
  static readonly decorativeStone = $r('app.color.decorative_stone');
  static readonly decorativePearl = $r('app.color.decorative_pearl');
  static readonly decorativeFog = $r('app.color.decorative_fog');
  static readonly decorativeCloud = $r('app.color.decorative_cloud');
  static readonly decorativeMist = $r('app.color.decorative_mist');
  static readonly decorativeFrost = $r('app.color.decorative_frost');
  static readonly decorativeSnow = $r('app.color.decorative_snow');
  static readonly decorativeIce = $r('app.color.decorative_ice');
}

export class ThemeConfig {
  // 主色调 - 现代蓝色系，增强视觉层次（保留用于需要字符串类型的场景）
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

  // 表面色系统 - 现代灰度系统
  static readonly surface = '#FFFFFF';
  static readonly surfaceSubtle = '#F9FAFB';
  static readonly surfaceLight = '#F2F2F7';
  static readonly surfaceNeutral = '#E5E5EA';
  static readonly surfaceMuted = '#D1D1D6';
  static readonly surfaceStrong = '#C7C7CC';
  static readonly surfaceEmphasized = '#8E8E93';
  static readonly surfaceBold = '#636366';
  static readonly surfaceDark = '#48484A';
  static readonly surfaceDeep = '#3A3A3C';
  static readonly surfaceDeepest = '#1C1C1E';

  // 背景色系统
  static readonly backgroundPrimary = '#FFFFFF';
  static readonly backgroundSecondary = '#F2F2F7';
  static readonly backgroundTertiary = '#E5E5EA';
  static readonly backgroundElevated = '#FFFFFF';
  static readonly backgroundCard = '#F8FAFC';
  static readonly backgroundPage = '#FAFBFC';
  static readonly backgroundInput = '#F5F5F7';

  // 覆盖层颜色系统 - 用于半透明遮罩和浮层
  // 亮色覆盖层系列
  static readonly overlayHeavy = '#E6FFFFFF';
  static readonly overlayStrong = '#CCFFFFFF';
  static readonly overlayMedium = '#B3FFFFFF';
  static readonly overlayRegular = '#99FFFFFF';
  static readonly overlayLight = '#80FFFFFF';
  static readonly overlaySubtle = '#66FFFFFF';
  static readonly overlayFaint = '#4DFFFFFF';
  static readonly overlayVeryFaint = '#40FFFFFF';
  static readonly overlayMinimal = '#33FFFFFF';
  static readonly overlayBare = '#26FFFFFF';
  static readonly overlayBarely = '#1AFFFFFF';
  
  // 暗色阴影系列 - 用于阴影和暗色遮罩
  static readonly shadowColorStrong = '#80000000';
  static readonly shadowColorMedium = '#66000000';
  static readonly shadowColorRegular = '#4D000000';
  static readonly shadowColorLight = '#40000000';
  static readonly shadowColorSubtle = '#33000000';
  static readonly shadowColorFaint = '#26000000';
  static readonly shadowColorMinimal = '#1A000000';
  static readonly shadowColorBare = '#0D000000';
  
  // 悬停效果颜色 - 主色调系列
  static readonly hoverPrimary = '#4D007AFF';
  static readonly hoverPrimaryLight = '#40007AFF';
  static readonly hoverPrimarySubtle = '#33007AFF';
  static readonly hoverPrimaryFaint = '#26007AFF';
  static readonly hoverPrimaryMinimal = '#1A007AFF';
  static readonly hoverPrimaryBare = '#0D007AFF';
  
  // 悬停效果颜色 - 功能色系列
  static readonly hoverSuccess = '#3334C759';
  static readonly hoverSuccessLight = '#1A34C759';
  static readonly hoverWarning = '#33FF9500';
  static readonly hoverWarningLight = '#1AFF9500';
  static readonly hoverError = '#33FF3B30';
  static readonly hoverErrorLight = '#1AFF3B30';
  
  // 悬停效果颜色 - 中性色系列
  static readonly hoverNeutral = '#338E8E93';
  static readonly hoverNeutralLight = '#1A8E8E93';
  static readonly hoverNeutralFaint = '#0D8E8E93';
  
  // 完全透明
  static readonly transparent = '#00000000';

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
  static readonly fontSizeXXXXXXXL = 50;
  static readonly fontSizeXXXXXXXXL = 60;
  static readonly fontSizeXXXXXXXXXL = 70;

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
  static readonly borderDefault = '#E2E8F0';
  static readonly borderGrid = '#E0E0E0';
  static readonly borderGridFine = '#F0F0F0';
  static readonly borderDivider = '#E2E8F0';

  // 文字颜色系统
  static readonly textPrimary = '#1D1D1F';
  static readonly textSecondary = '#666666';
  static readonly textTertiary = '#86868B';
  static readonly textSuccess = '#28A745';
  static readonly textMuted = '#64748B';
  static readonly textSubdued = '#94A3B8';
  static readonly textStrong = '#1E293B';
  
  // 任务状态颜色
  static readonly taskCritical = '#D0021B';
  static readonly taskNormal = '#4A90E2';
  static readonly taskSelected = '#FF8C00';
  static readonly taskProgress = '#2ECC71';
  
  // 项目类型颜色
  static readonly projectDevelopment = '#3B82F6';
  static readonly projectDesign = '#8B5CF6';
  static readonly projectMarketing = '#F59E0B';
  static readonly projectResearch = '#10B981';
  static readonly projectOther = '#6B7280';
  
  // 画布网格线颜色
  static readonly canvasGridLine = '#E0E0E0';
  static readonly canvasGridLineFine = '#F0F0F0';
  
  // 装饰性颜色 - 用于背景装饰元素
  static readonly decorativeSlate = '#E2E8F0';
  static readonly decorativeSlateDark = '#CBD5E1';
  static readonly decorativeStone = '#D1D5DB';
  static readonly decorativePearl = '#E5E7EB';
  static readonly decorativeFog = '#F3F4F6';
  static readonly decorativeCloud = '#F1F5F9';
  static readonly decorativeMist = '#F8FAFC';
  static readonly decorativeFrost = '#F9FAFB';
  static readonly decorativeSnow = '#FAFBFC';
  static readonly decorativeIce = '#FCFCFD';

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