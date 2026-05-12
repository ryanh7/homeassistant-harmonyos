import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageDefaults } from '../app/AppStorageDefaults';
import { CardFormWantParser } from '../features/cards/CardFormWantParser';

const DOMAIN = 0x0000;
const TAG = 'HACompanionCardEdit';

export default class EntryCardEditAbility extends UIAbility {
  onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    AppStorageDefaults.register();
    this.applyWant(want);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.enableLayoutImmersive(windowStage);
    windowStage.loadContent('features/cards/edit/CardEditPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load card edit content. Cause: %{public}s', JSON.stringify(err));
      }
    });
  }

  private applyWant(want: Want): void {
    const formId = CardFormWantParser.editFormId(want) || CardFormWantParser.formId(want);
    AppStorage.setOrCreate<string>('cardEditFormId', formId);
    AppStorage.setOrCreate<string>('cardEditCardType', CardFormWantParser.cardType(want));
  }

  private enableLayoutImmersive(windowStage: window.WindowStage): void {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true).catch((): void => {});
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#172126',
        navigationBarContentColor: '#172126',
        isStatusBarLightIcon: false,
        isNavigationBarLightIcon: false
      }).catch((): void => {});
    } catch (_) {
    }
  }
}
