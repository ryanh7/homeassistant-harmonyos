import {
  HarmonyLocationHistoryEntry,
  HarmonyLocationService,
  HarmonyLocationSnapshot,
  HarmonyLocationZone
} from '../../services/HarmonyLocationService';

export interface LocationDiagnosticsInput {
  historyJson: string;
  snapshot: HarmonyLocationSnapshot | undefined;
  zoneName: string;
  trigger: string;
  sentMode: string;
  geofenceStatus: string;
  result: string;
}

export interface LocationDiagnosticsResult {
  summary: string;
  historyJson: string;
  historyChanged: boolean;
}

export class LocationSensorCoordinator {
  private static readonly MAX_HISTORY_SIZE = 50;

  static currentZoneName(snapshot: HarmonyLocationSnapshot, zones: HarmonyLocationZone[]): string {
    const zone = HarmonyLocationService.findContainingZone(snapshot, zones);
    return zone ? zone.name : '';
  }

  static appendHistory(
    historyJson: string,
    snapshot: HarmonyLocationSnapshot,
    trigger: string,
    zoneName: string,
    result: string
  ): string {
    const normalizedZone = zoneName.length > 0 ? zoneName : 'not_home';
    const entry = HarmonyLocationService.historyEntry(snapshot, trigger, normalizedZone, result);
    const history = LocationSensorCoordinator.readHistory(historyJson);
    history.push(entry);
    while (history.length > LocationSensorCoordinator.MAX_HISTORY_SIZE) {
      history.shift();
    }
    return LocationSensorCoordinator.writeHistory(history);
  }

  static recordDiagnostics(input: LocationDiagnosticsInput): LocationDiagnosticsResult {
    const snapshot = input.snapshot;
    const zoneName = input.zoneName.length > 0 ? input.zoneName : 'not_home';
    const locationText = snapshot
      ? `${snapshot.latitude.toFixed(6)},${snapshot.longitude.toFixed(6)} +/-${Math.round(snapshot.accuracy)}m`
      : 'no_location';
    const summary = `${new Date().toISOString()} | ${input.trigger} | ${input.sentMode} | ${zoneName} | ${locationText} | ${input.geofenceStatus} | ${input.result}`;
    if (!snapshot) {
      return {
        summary,
        historyJson: input.historyJson,
        historyChanged: false
      };
    }
    return {
      summary,
      historyJson: LocationSensorCoordinator.replaceLatestHistoryResult(input.historyJson, input.result),
      historyChanged: true
    };
  }

  static shouldRecordDiagnostics(reason: string, locationSummary: string): boolean {
    if (locationSummary === 'not_requested') {
      return false;
    }
    return LocationSensorCoordinator.isLocationReason(reason) ||
      locationSummary.startsWith('update_location') ||
      locationSummary.startsWith('location_');
  }

  static shouldSendLocationUpdate(reason: string): boolean {
    return LocationSensorCoordinator.isLocationReason(reason) ||
      reason === 'sensor_preferences_changed' ||
      reason === 'device_registered';
  }

  static isLocationReason(reason: string): boolean {
    return reason.indexOf('location') >= 0 ||
      reason.indexOf('zone') >= 0 ||
      reason.indexOf('geofence') >= 0 ||
      reason === 'app_foreground' ||
      reason === 'dashboard_opened';
  }

  private static replaceLatestHistoryResult(historyJson: string, result: string): string {
    const history = LocationSensorCoordinator.readHistory(historyJson);
    if (history.length === 0) {
      return historyJson;
    }
    const lastIndex = history.length - 1;
    const latest = history[lastIndex];
    history[lastIndex] = {
      timeStamp: latest.timeStamp,
      latitude: latest.latitude,
      longitude: latest.longitude,
      accuracy: latest.accuracy,
      trigger: latest.trigger,
      zoneName: latest.zoneName,
      result
    };
    return LocationSensorCoordinator.writeHistory(history);
  }

  private static readHistory(historyJson: string): HarmonyLocationHistoryEntry[] {
    try {
      const parsed = JSON.parse(historyJson) as HarmonyLocationHistoryEntry[];
      if (Array.isArray(parsed)) {
        return parsed;
      }
    } catch (_) {
    }
    return [];
  }

  private static writeHistory(history: HarmonyLocationHistoryEntry[]): string {
    try {
      return JSON.stringify(history);
    } catch (_) {
      return '[]';
    }
  }
}
