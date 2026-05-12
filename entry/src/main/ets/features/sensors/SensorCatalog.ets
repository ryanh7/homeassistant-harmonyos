import { Localization } from '../../shared/i18n/Localization';
import { SensorEntry, SensorGroup } from './SensorModels';

export class SensorCatalog {
  static groups(): SensorGroup[] {
    return [
      {
        title: Localization.t('sensor_group_battery'),
        sensors: [
          SensorCatalog.sensor('battery_level', Localization.t('sensor_battery_level'), 'battery'),
          SensorCatalog.sensor('battery_state', Localization.t('sensor_battery_state'), 'battery'),
          SensorCatalog.sensor('charger_type', Localization.t('sensor_charger_type'), 'battery')
        ]
      },
      {
        title: Localization.t('sensor_group_network'),
        sensors: [
          SensorCatalog.sensor('network_type', Localization.t('sensor_network_type'), 'wifi')
        ]
      },
      {
        title: Localization.t('sensor_group_location'),
        sensors: [
          SensorCatalog.sensor('accurate_location', Localization.t('sensor_accurate_location'), 'sensor'),
          SensorCatalog.sensor('zone_background', Localization.t('sensor_zone_background'), 'sensor'),
          SensorCatalog.sensor('location_background', Localization.t('sensor_location_background'), 'sensor'),
          SensorCatalog.sensor('last_update_trigger', Localization.t('sensor_last_update_trigger'), 'sensor')
        ]
      }
    ];
  }

  private static sensor(id: string, title: string, icon: string): SensorEntry {
    return {
      id,
      title,
      icon,
      enabled: false,
      summary: ''
    };
  }
}
