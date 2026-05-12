import common from '@ohos.app.ability.common';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export interface WindowPreferenceOptions {
  context: common.Context;
  screenOrientation: string;
  keepScreenOnEnabled: boolean;
}

export class WindowService {
  static preferredOrientation(screenOrientation: string): window.Orientation {
    if (screenOrientation === 'portrait') {
      return window.Orientation.PORTRAIT;
    }
    if (screenOrientation === 'landscape') {
      return window.Orientation.LANDSCAPE;
    }
    return window.Orientation.UNSPECIFIED;
  }

  static requestedColorMode(appTheme: string): ConfigurationConstant.ColorMode {
    if (appTheme === 'dark') {
      return ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    if (appTheme === 'light') {
      return ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    }
    return ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  }

  static setApplicationColorMode(context: common.Context, appTheme: string): void {
    try {
      context.getApplicationContext().setColorMode(WindowService.requestedColorMode(appTheme));
    } catch (_) {
    }
  }

  static applyPreferences(options: WindowPreferenceOptions): void {
    window.getLastWindow(options.context)
      .then((mainWindow: window.Window): void => {
        mainWindow.setPreferredOrientation(WindowService.preferredOrientation(options.screenOrientation))
          .catch((): void => {});
        mainWindow.setWindowKeepScreenOn(options.keepScreenOnEnabled).catch((): void => {});
        mainWindow.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: '#172126',
          navigationBarContentColor: '#172126',
          isStatusBarLightIcon: false,
          isNavigationBarLightIcon: false
        }).catch((): void => {});
      })
      .catch((): void => {});
  }
}
