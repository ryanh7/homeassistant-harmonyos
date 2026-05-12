import { Localization } from '../../shared/i18n/Localization';
import { WearMenuItem, wearMenuItem } from './WearHomePage';

export class WearService {
  static menuItems(): WearMenuItem[] {
    return [
      wearMenuItem('*', Localization.t('wear_favorites'), Localization.t('wear_favorites_summary'), true),
      wearMenuItem('H', Localization.t('wear_areas'), Localization.t('wear_areas_summary'), false),
      wearMenuItem('D', Localization.t('wear_devices'), Localization.t('wear_devices_summary'), false),
      wearMenuItem('E', Localization.t('wear_domains'), Localization.t('wear_domains_summary'), false),
      wearMenuItem('A', 'Assist', Localization.t('wear_assist_summary'), true),
      wearMenuItem('S', Localization.t('wear_settings'), Localization.t('wear_settings_summary'), true)
    ];
  }

  static pairPhoneMessage(): string {
    return Localization.t('wear_sync_login_first');
  }

  static openItemMessage(item: WearMenuItem): string {
    if (item.enabled) {
      return Localization.format('wear_entry_placeholder', 'title', item.title);
    }
    return Localization.format('wear_entry_requires_sync', 'title', item.title);
  }
}
