import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ThemeConfig, ColorResource } from '../utils/ThemeConfig';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Home', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      // windowStage.getMainWindowSync().setWindowBackgroundColor('#d5d5d5');
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    let windowClass: window.Window = windowStage.getMainWindowSync();
    AppStorage.setOrCreate('windowClass', windowClass);

    let isLayoutFullScreen = true;
    windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(() => {
      console.info('Succeeded in setting the window layout to full-screen mode.');
    }).catch((err: BusinessError) => {
      console.error(`Failed to set the window layout to full-screen mode. Code is ${err.code}, message is ${err.message}`);
    });

    windowStage.getMainWindow((err: BusinessError, data) => {
      const errCode: number = err.code;
      if (errCode) {
        console.error(`Failed to obtain the main window. Cause code: ${err.code}, message: ${err.message}`);
        return;
      }
      windowClass = data;
      AppStorage.setOrCreate('windowClass', windowClass);
      this.updateSystemBar(windowClass);
    });

    const type = window.AvoidAreaType.TYPE_SYSTEM; // 以状态栏避让为例
    const avoidArea = windowClass.getWindowAvoidArea(type);
    let topRectHeight = avoidArea.topRect.height; // 获取状态栏区域高度
    AppStorage.setOrCreate('topRectHeight', topRectHeight);

    windowClass.on('avoidAreaChange', (data) => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
        let topRectHeight = data.area.topRect.height;
        AppStorage.setOrCreate('topRectHeight', topRectHeight);
      } else if (data.type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        let bottomRectHeight = data.area.bottomRect.height;
        AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);
      }
    });
  }

  private updateSystemBar(windowClass: window.Window, config?: Configuration): void {
    const currentConfig: Configuration | undefined = config ?? this.context.config;
    const isDarkMode: boolean = !!currentConfig &&
      currentConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;

    const statusBarContentColor: string = isDarkMode ? '#FFFFFFFF' : '#FF000000';

    let systemBarProperties: window.SystemBarProperties = {
      statusBarColor: ThemeConfig.transparent.toString(),
      navigationBarColor: ThemeConfig.transparent.toString(),
      statusBarContentColor: statusBarContentColor
    };
    try {
      let promise = windowClass.setWindowSystemBarProperties(systemBarProperties);
      promise.then(() => {
        console.info('Succeeded in setting the system bar properties.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the system bar properties. Cause code: ${err.code}, message: ${err.message}`);
      });
    } catch (exception) {
      console.error(`Failed to set the system bar properties. Cause code: ${exception.code}, message: ${exception.message}`);
    }
  }

  onConfigurationUpdate(config: Configuration): void {
    super.onConfigurationUpdate(config);
    const windowClass = AppStorage.get<window.Window>('windowClass');
    if (!windowClass) {
      console.warn('Window class not ready, skip updating system bar.');
      return;
    }
    this.updateSystemBar(windowClass, config);
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
