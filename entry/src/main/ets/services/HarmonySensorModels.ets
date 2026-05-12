export interface SensorPreferenceSnapshot {
  batterySOCEnabled: boolean;
  chargingStatusEnabled: boolean;
  pluggedTypeEnabled: boolean;
  bearerTypesEnabled: boolean;
  lastUpdateTriggerEnabled: boolean;
  locationBackgroundEnabled: boolean;
  zoneBackgroundEnabled: boolean;
  accurateLocationEnabled: boolean;
}

export interface HarmonySensorSyncResult {
  registeredCount: number;
  updatedCount: number;
  locationUpdated: boolean;
  locationSummary: string;
}

export type HarmonyLocationSentMode = 'exact' | 'zone' | 'never';

export type SensorStateValue = string | number | boolean | null;

export interface SensorAttributes {
  latitude?: number | null;
  longitude?: number | null;
  accuracy?: number | null;
  timeStamp?: number | null;
  options?: string[];
  metered?: boolean;
  last_update_trigger?: string;
  location_sent?: string;
  gps_accuracy?: number | null;
}

export interface SensorDescriptor {
  id: string;
  name: string;
  type: string;
  icon: string;
  state: SensorStateValue;
  attributes: SensorAttributes;
  enabled: boolean;
  deviceClass?: string;
  unitOfMeasurement?: string;
  stateClass?: string;
  entityCategory?: string;
}

export interface NetSnapshot {
  networkType: string;
  metered: boolean;
}

export interface SensorRegistrationWebhookData {
  unique_id: string;
  state: SensorStateValue;
  type: string;
  icon: string;
  attributes: SensorAttributes;
  name: string;
  disabled: boolean;
  device_class?: string;
  unit_of_measurement?: string;
  state_class?: string;
  entity_category?: string;
}

export interface RegisterSensorWebhookBody {
  type: string;
  data: SensorRegistrationWebhookData;
}

export interface SensorUpdateWebhookData {
  unique_id: string;
  state: SensorStateValue;
  type: string;
  icon: string;
  attributes: SensorAttributes;
}

export interface UpdateSensorStatesWebhookBody {
  type: string;
  data: SensorUpdateWebhookData[];
}

export interface UpdateLocationWebhookData {
  gps?: number[];
  gps_accuracy?: number;
  location_name?: string;
  battery?: number;
  speed?: number;
  altitude?: number;
  course?: number;
  vertical_accuracy?: number;
}

export interface UpdateLocationWebhookBody {
  type: string;
  data: UpdateLocationWebhookData;
}

export interface GetZonesWebhookBody {
  type: string;
}

export interface HttpTextResult {
  responseCode: number;
  body: string;
  failureSummary: string;
}

export interface WebhookResult {
  responseCode: number;
  body: string;
  failureSummary: string;
}
