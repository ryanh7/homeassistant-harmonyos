import { HaTheme } from '../../../shared/theme/HaTheme';
import { SettingsUiConfig } from './SettingsUiConfig';

@Component
export struct SettingsBoundary {
  @StorageLink('appResolvedDark') appResolvedDark: boolean = false;

  build() {
    Row() {
      Row()
        .width('100%')
        .height(1)
        .backgroundColor(HaTheme.divider(this.appResolvedDark))
    }
      .width('100%')
      .height(1)
      .padding(SettingsUiConfig.dividerPadding())
  }
}
