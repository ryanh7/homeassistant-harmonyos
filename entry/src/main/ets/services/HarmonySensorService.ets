// Collects HarmonyOS device sensor snapshots and publishes them to Home Assistant mobile_app webhooks.
// This file owns sensor payload shape, preference snapshots, and foreground update behavior.
import batteryInfo from '@ohos.batteryInfo';
import { NetworkHttpMethod, NetworkNetBearType, NetworkNetCap, NetworkService } from './NetworkService';
import { Localization } from '../shared/i18n/Localization';
import { HarmonyLocationSnapshot, HarmonyLocationZone } from './HarmonyLocationService';
import {
  GetZonesWebhookBody,
  HarmonyLocationSentMode,
  HarmonySensorSyncResult,
  HttpTextResult,
  NetSnapshot,
  RegisterSensorWebhookBody,
  SensorRegistrationWebhookData,
  SensorAttributes,
  SensorDescriptor,
  SensorPreferenceSnapshot,
  SensorUpdateWebhookData,
  UpdateLocationWebhookData,
  UpdateLocationWebhookBody,
  UpdateSensorStatesWebhookBody,
  WebhookResult
} from './HarmonySensorModels';

export {
  HarmonyLocationSentMode,
  HarmonySensorSyncResult,
  SensorPreferenceSnapshot
} from './HarmonySensorModels';

const SENSOR_TEXT_UNAVAILABLE = 'unavailable';
const SENSOR_TEXT_UNKNOWN = 'UNKNOWN';

export class HarmonySensorService {
  static supportedPublicSensorIds(): string[] {
    return [
      'battery_level',
      'battery_state',
      'charger_type',
      'network_type',
      'last_update_trigger',
      'location_background',
      'zone_background',
      'accurate_location'
    ];
  }

  static isSupportedPublicSensor(sensorId: string): boolean {
    const ids = HarmonySensorService.supportedPublicSensorIds();
    for (let i = 0; i < ids.length; i++) {
      if (ids[i] === sensorId) {
        return true;
      }
    }
    return false;
  }

  static sensorSummary(sensorId: string, prefs: SensorPreferenceSnapshot): string {
    if (!HarmonySensorService.isSupportedPublicSensor(sensorId)) {
      return Localization.t('sensor_unavailable_summary');
    }
    if (sensorId === 'accurate_location') {
      return Localization.t('sensor_accurate_summary');
    }
    if (sensorId === 'zone_background') {
      return Localization.t('sensor_zone_summary');
    }
    if (sensorId === 'location_background') {
      return Localization.t('sensor_background_summary');
    }
    return '';
  }

  static isSensorEnabled(sensorId: string, prefs: SensorPreferenceSnapshot): boolean {
    switch (sensorId) {
      case 'battery_level':
        return prefs.batterySOCEnabled;
      case 'battery_state':
        return prefs.chargingStatusEnabled;
      case 'charger_type':
        return prefs.pluggedTypeEnabled;
      case 'network_type':
        return prefs.bearerTypesEnabled;
      case 'last_update_trigger':
        return prefs.lastUpdateTriggerEnabled;
      case 'location_background':
        return prefs.locationBackgroundEnabled;
      case 'zone_background':
        return prefs.zoneBackgroundEnabled;
      case 'accurate_location':
        return prefs.accurateLocationEnabled;
      default:
        return false;
    }
  }

  static async syncPublicSensors(
    baseUrl: string,
    webhookId: string,
    cloudhookUrl: string,
    prefs: SensorPreferenceSnapshot,
    lastLocation: HarmonyLocationSnapshot | undefined,
    locationEnabledStatus: boolean,
    currentZoneName: string,
    locationSentMode: HarmonyLocationSentMode,
    sendLocationUpdate: boolean
  ): Promise<HarmonySensorSyncResult> {
    const normalizedBaseUrl = HarmonySensorService.normalizeBaseUrl(baseUrl);
    const trimmedWebhookId = webhookId.trim();
    if (normalizedBaseUrl.length === 0 || trimmedWebhookId.length === 0) {
      return {
        registeredCount: 0,
        updatedCount: 0,
        locationUpdated: false,
        locationSummary: 'missing_webhook'
      };
    }

    const descriptors = HarmonySensorService.buildSensorDescriptors(
      prefs,
      lastLocation,
      locationEnabledStatus,
      locationSentMode
    );
    const webhookUrls = HarmonySensorService.webhookUrls(normalizedBaseUrl, trimmedWebhookId, cloudhookUrl);
    let registeredCount = 0;
    let updatedCount = 0;

    for (let i = 0; i < descriptors.length; i++) {
      const descriptor = descriptors[i];
      await HarmonySensorService.postWebhookWithFallback(
        webhookUrls,
        HarmonySensorService.registerSensorBody(descriptor),
        true
      );
      registeredCount += 1;
    }

    const enabledSensors = descriptors.filter((item: SensorDescriptor) => item.enabled);
    if (enabledSensors.length > 0) {
      await HarmonySensorService.postWebhookWithFallback(
        webhookUrls,
        HarmonySensorService.updateSensorStatesBody(enabledSensors),
        false
      );
      updatedCount = enabledSensors.length;
    }

    let locationUpdated = false;
    let locationSummary = 'not_requested';
    if (sendLocationUpdate &&
      locationEnabledStatus &&
      lastLocation &&
      (prefs.locationBackgroundEnabled || prefs.zoneBackgroundEnabled || prefs.accurateLocationEnabled) &&
      locationSentMode !== 'never') {
      const locationBody = HarmonySensorService.updateLocationBody(
        lastLocation,
        currentZoneName,
        locationSentMode
      );
      if (locationBody) {
        const locationResult = await HarmonySensorService.postWebhookWithFallback(webhookUrls, locationBody, false);
        locationUpdated = locationResult.responseCode >= 200 && locationResult.responseCode < 300;
        locationSummary = `update_location:${locationResult.responseCode}:${NetworkService.shortText(locationResult.body)}`;
      } else {
        locationSummary = 'update_location_skipped_no_location';
      }
    } else if (locationSentMode === 'never') {
      locationSummary = 'location_never';
    } else if (sendLocationUpdate && !locationEnabledStatus) {
      locationSummary = 'location_disabled';
    } else if (sendLocationUpdate && !lastLocation) {
      locationSummary = 'update_location_skipped_no_location';
    }

    return {
      registeredCount,
      updatedCount,
      locationUpdated,
      locationSummary
    };
  }

  static async fetchZones(
    baseUrl: string,
    webhookId: string,
    cloudhookUrl: string
  ): Promise<HarmonyLocationZone[]> {
    const normalizedBaseUrl = HarmonySensorService.normalizeBaseUrl(baseUrl);
    const trimmedWebhookId = webhookId.trim();
    if (normalizedBaseUrl.length === 0 || trimmedWebhookId.length === 0) {
      return [];
    }
    const webhookUrls = HarmonySensorService.webhookUrls(normalizedBaseUrl, trimmedWebhookId, cloudhookUrl);
    const body: GetZonesWebhookBody = {
      type: 'get_zones'
    };
    for (let i = 0; i < webhookUrls.length; i++) {
      const result = await HarmonySensorService.postWebhookForText(webhookUrls[i], body);
      if (result.responseCode >= 200 && result.responseCode < 300) {
        return HarmonySensorService.parseZones(result.body);
      }
    }
    return [];
  }

  static async clearDeviceTrackerLocation(
    baseUrl: string,
    webhookId: string,
    cloudhookUrl: string
  ): Promise<WebhookResult> {
    const normalizedBaseUrl = HarmonySensorService.normalizeBaseUrl(baseUrl);
    const trimmedWebhookId = webhookId.trim();
    if (normalizedBaseUrl.length === 0 || trimmedWebhookId.length === 0) {
      return {
        responseCode: 0,
        body: '',
        failureSummary: 'missing_webhook'
      };
    }
    const body: UpdateLocationWebhookBody = {
      type: 'update_location',
      data: {}
    };
    return HarmonySensorService.postWebhookWithFallback(
      HarmonySensorService.webhookUrls(normalizedBaseUrl, trimmedWebhookId, cloudhookUrl),
      body,
      false
    );
  }

  private static buildSensorDescriptors(
    prefs: SensorPreferenceSnapshot,
    lastLocation: HarmonyLocationSnapshot | undefined,
    locationEnabledStatus: boolean,
    locationSentMode: HarmonyLocationSentMode
  ): SensorDescriptor[] {
    const netSnapshot = HarmonySensorService.getNetworkSnapshot();
    const batterySOC = HarmonySensorService.batteryLevelValue();
    const batteryState = HarmonySensorService.batteryStateValue();
    const pluggedType = HarmonySensorService.chargerTypeValue();
    const locationAttributes = HarmonySensorService.locationAttributes(lastLocation, locationSentMode);
    const lastUpdateTrigger = AppStorage.get<string>('lastUpdateTrigger') ?? 'unknown';

    return [
      {
        id: 'battery_level',
        name: 'Battery level',
        type: 'sensor',
        icon: HarmonySensorService.batteryLevelIcon(batterySOC, batteryState, pluggedType),
        state: batterySOC,
        attributes: {},
        enabled: prefs.batterySOCEnabled,
        deviceClass: 'battery',
        unitOfMeasurement: '%',
        stateClass: 'measurement',
        entityCategory: 'diagnostic'
      },
      {
        id: 'battery_state',
        name: 'Battery state',
        type: 'sensor',
        icon: HarmonySensorService.batteryStateIcon(batteryState),
        state: batteryState,
        attributes: HarmonySensorService.batteryStateAttributes(),
        enabled: prefs.chargingStatusEnabled,
        deviceClass: 'enum',
        entityCategory: 'diagnostic'
      },
      {
        id: 'charger_type',
        name: 'Charger type',
        type: 'sensor',
        icon: HarmonySensorService.chargerTypeIcon(pluggedType),
        state: HarmonySensorService.nonEmptyText(pluggedType),
        attributes: HarmonySensorService.chargerTypeAttributes(),
        enabled: prefs.pluggedTypeEnabled,
        deviceClass: 'enum',
        entityCategory: 'diagnostic'
      },
      {
        id: 'network_type',
        name: 'Network type',
        type: 'sensor',
        icon: HarmonySensorService.networkTypeIcon(netSnapshot.networkType),
        state: HarmonySensorService.nonEmptyText(netSnapshot.networkType),
        attributes: HarmonySensorService.networkTypeAttributes(netSnapshot.metered),
        enabled: prefs.bearerTypesEnabled,
        deviceClass: 'enum',
        entityCategory: 'diagnostic'
      },
      {
        id: 'last_update_trigger',
        name: 'Last update trigger',
        type: 'sensor',
        icon: 'mdi:update',
        state: HarmonySensorService.nonEmptyText(lastUpdateTrigger),
        attributes: {},
        enabled: prefs.lastUpdateTriggerEnabled,
        entityCategory: 'diagnostic'
      },
      {
        id: 'location_background',
        name: 'Background location',
        type: 'binary_sensor',
        icon: 'mdi:map-marker-multiple',
        state: prefs.locationBackgroundEnabled && locationEnabledStatus,
        attributes: locationAttributes,
        enabled: prefs.locationBackgroundEnabled,
        entityCategory: 'diagnostic'
      },
      {
        id: 'accurate_location',
        name: 'Single accurate location',
        type: 'binary_sensor',
        icon: 'mdi:crosshairs-gps',
        state: prefs.accurateLocationEnabled,
        attributes: locationAttributes,
        enabled: prefs.accurateLocationEnabled,
        entityCategory: 'diagnostic'
      }
    ];
  }

  private static locationAttributes(
    lastLocation: HarmonyLocationSnapshot | undefined,
    locationSentMode: HarmonyLocationSentMode
  ): SensorAttributes {
    if (!lastLocation) {
      return {
        accuracy: null,
        timeStamp: null,
        gps_accuracy: null,
        location_sent: 'none'
      };
    }
    return {
      accuracy: lastLocation.accuracy,
      timeStamp: lastLocation.timeStamp,
      gps_accuracy: Math.round(lastLocation.accuracy),
      location_sent: locationSentMode
    };
  }

  private static updateLocationBody(
    lastLocation: HarmonyLocationSnapshot | undefined,
    currentZoneName: string,
    locationSentMode: HarmonyLocationSentMode
  ): UpdateLocationWebhookBody | undefined {
    const data: UpdateLocationWebhookData = {};
    if (locationSentMode === 'zone') {
      data.location_name = currentZoneName.length > 0 ? currentZoneName : 'not_home';
      return {
        type: 'update_location',
        data
      };
    }
    if (!lastLocation) {
      return undefined;
    }
    const batterySOC = HarmonySensorService.batteryLevelValue();
    data.gps = [lastLocation.latitude, lastLocation.longitude];
    data.gps_accuracy = Math.max(Math.round(lastLocation.accuracy), 1);
    if (batterySOC > 0) {
      data.battery = batterySOC;
    }
    if (typeof lastLocation.speed === 'number' && lastLocation.speed > 0) {
      data.speed = Math.round(lastLocation.speed);
    }
    if (typeof lastLocation.altitude === 'number' && lastLocation.altitude > 0) {
      data.altitude = Math.round(lastLocation.altitude);
    }
    if (typeof lastLocation.direction === 'number' && lastLocation.direction > 0) {
      data.course = Math.round(lastLocation.direction);
    }
    if (typeof lastLocation.altitudeAccuracy === 'number' && lastLocation.altitudeAccuracy > 0) {
      data.vertical_accuracy = Math.round(lastLocation.altitudeAccuracy);
    }
    return {
      type: 'update_location',
      data
    };
  }

  private static registerSensorBody(descriptor: SensorDescriptor): RegisterSensorWebhookBody {
    const data: SensorRegistrationWebhookData = {
      unique_id: descriptor.id,
      state: descriptor.enabled ? descriptor.state : null,
      type: descriptor.type,
      icon: descriptor.icon,
      attributes: descriptor.attributes,
      name: descriptor.name,
      disabled: !descriptor.enabled
    };
    if (descriptor.deviceClass) {
      data.device_class = descriptor.deviceClass;
    }
    if (descriptor.unitOfMeasurement) {
      data.unit_of_measurement = descriptor.unitOfMeasurement;
    }
    if (descriptor.stateClass) {
      data.state_class = descriptor.stateClass;
    }
    if (descriptor.entityCategory) {
      data.entity_category = descriptor.entityCategory;
    }
    return {
      type: 'register_sensor',
      data
    };
  }

  private static updateSensorStatesBody(descriptors: SensorDescriptor[]): UpdateSensorStatesWebhookBody {
    const items: SensorUpdateWebhookData[] = descriptors.map((descriptor: SensorDescriptor): SensorUpdateWebhookData => {
      return {
        unique_id: descriptor.id,
        state: descriptor.state,
        type: descriptor.type,
        icon: descriptor.icon,
        attributes: descriptor.attributes
      };
    });

    return {
      type: 'update_sensor_states',
      data: items
    };
  }

  private static webhookUrls(baseUrl: string, webhookId: string, cloudhookUrl: string): string[] {
    const urls: string[] = [];
    const trimmedCloudhook = cloudhookUrl.trim();
    if (trimmedCloudhook.length > 0) {
      urls.push(trimmedCloudhook);
    }
    urls.push(`${baseUrl}/api/webhook/${webhookId}`);
    return urls;
  }

  private static async postWebhookWithFallback(
    urls: string[],
    body: RegisterSensorWebhookBody | UpdateSensorStatesWebhookBody | UpdateLocationWebhookBody,
    allowConflict: boolean
  ): Promise<WebhookResult> {
    let lastError = 'sensor sync failed';
    let lastResult: WebhookResult = {
      responseCode: 0,
      body: '',
      failureSummary: lastError
    };
    for (let i = 0; i < urls.length; i++) {
      const result = await HarmonySensorService.postWebhook(urls[i], body);
      lastResult = result;
      if ((result.responseCode >= 200 && result.responseCode < 300) || (allowConflict && result.responseCode === 409)) {
        return result;
      }
      lastError = result.failureSummary;
    }
    throw new Error(`${lastError}: ${NetworkService.shortText(lastResult.body)}`);
  }

  private static async postWebhook(
    url: string,
    body: RegisterSensorWebhookBody | UpdateSensorStatesWebhookBody | UpdateLocationWebhookBody | GetZonesWebhookBody
  ): Promise<WebhookResult> {
    try {
      const resp = await NetworkService.requestText(url, {
        method: NetworkHttpMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(body),
        connectTimeout: 15000,
        readTimeout: 15000
      });
      return {
        responseCode: resp.responseCode,
        body: resp.body,
        failureSummary: `sensor sync failed: HTTP ${resp.responseCode}`
      };
    } catch (err) {
      return {
        responseCode: 0,
        body: '',
        failureSummary: `sensor sync failed: ${NetworkService.errorText(err)}`
      };
    }  }

  private static async postWebhookForText(
    url: string,
    body: GetZonesWebhookBody
  ): Promise<HttpTextResult> {
    try {
      const resp = await NetworkService.requestText(url, {
        method: NetworkHttpMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(body),
        connectTimeout: 15000,
        readTimeout: 15000
      });
      return {
        responseCode: resp.responseCode,
        body: resp.body,
        failureSummary: `get_zones failed: HTTP ${resp.responseCode}`
      };
    } catch (err) {
      return {
        responseCode: 0,
        body: '',
        failureSummary: `get_zones failed: ${NetworkService.errorText(err)}`
      };
    }  }

  private static parseZones(body: string): HarmonyLocationZone[] {
    const parsed = JSON.parse(body) as Object[];
    const zones: HarmonyLocationZone[] = [];
    for (let i = 0; i < parsed.length; i++) {
      const raw = parsed[i] as Record<string, Object | string | number | boolean | null>;
      const rawEntityId = raw['entity_id'] !== undefined ? raw['entity_id'] : raw['entityId'];
      const rawAttributes = raw['attributes'];
      if (typeof rawEntityId !== 'string' || !rawAttributes || typeof rawAttributes !== 'object') {
        continue;
      }
      const attributes = rawAttributes as Record<string, Object | string | number | boolean | null>;
      const rawLatitude = attributes['latitude'];
      const rawLongitude = attributes['longitude'];
      const rawRadius = attributes['radius'];
      if (typeof rawLatitude !== 'number' || typeof rawLongitude !== 'number' || typeof rawRadius !== 'number') {
        continue;
      }
      const friendlyName = attributes['friendly_name'];
      const entityZoneName = HarmonySensorService.zoneNameFromEntityId(rawEntityId);
      const zone: HarmonyLocationZone = {
        entityId: rawEntityId,
        name: entityZoneName.length > 0
          ? entityZoneName
          : (typeof friendlyName === 'string' && friendlyName.length > 0 ? friendlyName : rawEntityId),
        latitude: rawLatitude,
        longitude: rawLongitude,
        radius: rawRadius
      };
      zones.push(zone);
    }
    return zones;
  }

  private static zoneNameFromEntityId(entityId: string): string {
    const zonePrefix = 'zone.';
    if (entityId.startsWith(zonePrefix) && entityId.length > zonePrefix.length) {
      return entityId.slice(zonePrefix.length);
    }
    return '';
  }

  private static getNetworkSnapshot(): NetSnapshot {
    try {
      const capabilities = NetworkService.defaultNetCapabilities();
      const bearerTypes = capabilities && capabilities.bearerTypes ? capabilities.bearerTypes : [];
      return {
        networkType: HarmonySensorService.networkTypeValue(bearerTypes),
        metered: HarmonySensorService.networkIsMetered(capabilities.networkCap)
      };
    } catch (_) {
      return {
        networkType: SENSOR_TEXT_UNAVAILABLE,
        metered: false
      };
    }
  }

  private static hasNotMeteredCap(networkCap: NetworkNetCap[] | undefined): boolean {
    if (!networkCap) {
      return false;
    }
    for (let i = 0; i < networkCap.length; i++) {
      if (NetworkService.isNotMeteredCap(networkCap[i])) {
        return true;
      }
    }
    return false;
  }

  private static networkIsMetered(networkCap: NetworkNetCap[] | undefined): boolean {
    return !HarmonySensorService.hasNotMeteredCap(networkCap);
  }

  private static hasCellularBearer(bearerTypes: NetworkNetBearType[]): boolean {
    for (let i = 0; i < bearerTypes.length; i++) {
      if (NetworkService.isCellularBearer(bearerTypes[i])) {
        return true;
      }
    }
    return false;
  }

  private static hasEthernetBearer(bearerTypes: NetworkNetBearType[]): boolean {
    for (let i = 0; i < bearerTypes.length; i++) {
      if (NetworkService.isEthernetBearer(bearerTypes[i])) {
        return true;
      }
    }
    return false;
  }

  private static hasVpnBearer(bearerTypes: NetworkNetBearType[]): boolean {
    for (let i = 0; i < bearerTypes.length; i++) {
      if (NetworkService.isVpnBearer(bearerTypes[i])) {
        return true;
      }
    }
    return false;
  }

  private static hasWifiBearer(bearerTypes: NetworkNetBearType[]): boolean {
    for (let i = 0; i < bearerTypes.length; i++) {
      if (NetworkService.isWifiBearer(bearerTypes[i])) {
        return true;
      }
    }
    return false;
  }

  private static networkTypeValue(bearerTypes: NetworkNetBearType[]): string {
    if (HarmonySensorService.hasCellularBearer(bearerTypes)) {
      return 'cellular';
    }
    if (HarmonySensorService.hasEthernetBearer(bearerTypes)) {
      return 'ethernet';
    }
    if (HarmonySensorService.hasVpnBearer(bearerTypes)) {
      return 'vpn';
    }
    if (HarmonySensorService.hasWifiBearer(bearerTypes)) {
      return 'wifi';
    }
    return SENSOR_TEXT_UNKNOWN;
  }

  private static networkTypeAttributes(metered: boolean): SensorAttributes {
    return {
      metered,
      options: ['bluetooth', 'cellular', 'ethernet', 'lowpan', 'usb', 'vpn', 'wifi', 'wifi_aware']
    };
  }

  private static networkTypeIcon(networkType: string): string {
    switch (networkType) {
      case 'cellular':
        return 'mdi:signal-cellular-3';
      case 'ethernet':
        return 'mdi:ethernet';
      case 'usb':
        return 'mdi:usb';
      case 'wifi':
      case 'wifi_aware':
        return 'mdi:wifi';
      default:
        return 'mdi:network';
    }
  }

  private static batteryLevelValue(): number {
    const value = typeof batteryInfo.batterySOC === 'number' ? batteryInfo.batterySOC : 0;
    if (value < 0) {
      return 0;
    }
    if (value > 100) {
      return 100;
    }
    return Math.round(value);
  }

  private static batteryStateValue(): string {
    switch (batteryInfo.chargingStatus) {
      case batteryInfo.BatteryChargeState.ENABLE:
        return 'charging';
      case batteryInfo.BatteryChargeState.DISABLE:
        return 'not_charging';
      case batteryInfo.BatteryChargeState.FULL:
        return 'full';
      default:
        return SENSOR_TEXT_UNKNOWN;
    }
  }

  private static batteryStateAttributes(): SensorAttributes {
    return {
      options: ['charging', 'discharging', 'full', 'not_charging']
    };
  }

  private static batteryStateIcon(batteryState: string): string {
    switch (batteryState) {
      case 'charging':
        return 'mdi:battery-plus';
      case 'discharging':
        return 'mdi:battery-minus';
      case 'full':
        return 'mdi:battery-charging';
      case 'not_charging':
        return 'mdi:battery';
      default:
        return 'mdi:battery-unknown';
    }
  }

  private static chargerTypeValue(): string {
    switch (batteryInfo.pluggedType) {
      case batteryInfo.BatteryPluggedType.AC:
        return 'ac';
      case batteryInfo.BatteryPluggedType.USB:
        return 'usb';
      case batteryInfo.BatteryPluggedType.WIRELESS:
        return 'wireless';
      default:
        return 'none';
    }
  }

  private static chargerTypeAttributes(): SensorAttributes {
    return {
      options: ['ac', 'usb', 'wireless', 'dock', 'none']
    };
  }

  private static chargerTypeIcon(chargerType: string): string {
    switch (chargerType) {
      case 'ac':
        return 'mdi:power-plug';
      case 'usb':
        return 'mdi:usb-port';
      case 'wireless':
        return 'mdi:battery-charging-wireless';
      default:
        return 'mdi:battery';
    }
  }

  private static batteryLevelIcon(level: number, batteryState: string, chargerType: string): string {
    const baseIcon = batteryState === 'charging' || batteryState === 'full'
      ? (chargerType === 'wireless' ? 'mdi:battery-charging-wireless' : 'mdi:battery-charging')
      : 'mdi:battery';
    if (level <= 9) {
      return `${baseIcon}-outline`;
    }
    if (level >= 100) {
      return baseIcon;
    }
    const bucket = Math.floor(level / 10) * 10;
    return `${baseIcon}-${bucket}`;
  }

  private static nonEmptyText(value: string): string {
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : SENSOR_TEXT_UNAVAILABLE;
  }

  private static normalizeBaseUrl(input: string): string {
    const trimmed = input.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.slice(0, trimmed.length - 1);
    }
    return trimmed;
  }

  private static stringifyError(err: Object | string | number | boolean): string {
    if (err instanceof Error) {
      return err.message;
    }
    try {
      return JSON.stringify(err);
    } catch (_) {
      return String(err);
    }
  }

  private static shortText(input: string, maxLen: number = 120): string {
    const normalized = input.replace(/\s+/g, ' ').trim();
    if (normalized.length <= maxLen) {
      return normalized;
    }
    return `${normalized.slice(0, maxLen)}...`;
  }
}
