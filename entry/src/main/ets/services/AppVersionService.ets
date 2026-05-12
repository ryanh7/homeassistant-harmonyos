// Single runtime source for the app version shown to users and Home Assistant.
// Reads the bundled HarmonyOS version and falls back to the current development version.
import bundleManager from '@ohos.bundle.bundleManager';

export interface AppVersionInfo {
  versionName: string;
  versionCode: number;
}

export class AppVersionService {
  private static readonly FALLBACK_VERSION_NAME: string = '0.0.0-dev';
  private static readonly FALLBACK_VERSION_CODE: number = 1;

  static versionInfo(): AppVersionInfo {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const versionName = typeof info.versionName === 'string' && info.versionName.trim().length > 0
        ? info.versionName.trim()
        : AppVersionService.FALLBACK_VERSION_NAME;
      const versionCode = typeof info.versionCode === 'number'
        ? info.versionCode
        : AppVersionService.FALLBACK_VERSION_CODE;
      return { versionName, versionCode };
    } catch (_) {
      return {
        versionName: AppVersionService.FALLBACK_VERSION_NAME,
        versionCode: AppVersionService.FALLBACK_VERSION_CODE
      };
    }
  }

  static versionName(): string {
    return AppVersionService.versionInfo().versionName;
  }

  static versionLabel(): string {
    const info = AppVersionService.versionInfo();
    return `${info.versionName} (${info.versionCode})`;
  }

  static versionNameJson(): string {
    return JSON.stringify(AppVersionService.versionName()) as string;
  }
}
