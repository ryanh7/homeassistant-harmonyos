import { Localization } from '../../shared/i18n/Localization';
import { CompanionSettingsData, SettingChoiceGroup } from './CompanionSettingsData';

export interface CompanionChoiceValues {
  screenOrientation: string;
  pageZoomLevel: string;
  appLanguage: string;
  appTheme: string;
  secureConnectionChoice: string;
}

export class CompanionChoicePresenter {
  static title(key: string): string {
    if (key === 'display_orientation') {
      return Localization.t('settings_orientation');
    }
    if (key === 'display_zoom') {
      return Localization.t('settings_page_zoom');
    }
    if (key === 'display_language') {
      return Localization.t('settings_language');
    }
    if (key === 'display_theme') {
      return Localization.t('settings_theme');
    }
    if (key === 'server_connection_security') {
      return Localization.t('server_connection_security');
    }
    return '';
  }

  static groups(key: string): SettingChoiceGroup[] {
    if (key === 'display_orientation') {
      return CompanionSettingsData.orientationOptions();
    }
    if (key === 'display_zoom') {
      return CompanionSettingsData.pageZoomOptions();
    }
    if (key === 'display_language') {
      return CompanionSettingsData.languageOptions();
    }
    if (key === 'display_theme') {
      return CompanionSettingsData.themeOptions();
    }
    if (key === 'server_connection_security') {
      return CompanionSettingsData.secureConnectionOptions();
    }
    return [];
  }

  static selectedValue(key: string, values: CompanionChoiceValues): string {
    if (key === 'display_orientation') {
      return values.screenOrientation;
    }
    if (key === 'display_zoom') {
      return values.pageZoomLevel;
    }
    if (key === 'display_language') {
      return values.appLanguage;
    }
    if (key === 'display_theme') {
      return values.appTheme;
    }
    if (key === 'server_connection_security') {
      return values.secureConnectionChoice;
    }
    return '';
  }
}
