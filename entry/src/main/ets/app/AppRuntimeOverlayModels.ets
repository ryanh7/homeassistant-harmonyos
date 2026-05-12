import { DeviceProfileInfo } from '../shared/device/DeviceProfile';
import { SensorGroup } from '../features/sensors/SensorModels';

export interface AppRuntimeOverlaySnapshot {
  route: number;
  baseUrl: string;
  accessToken: string;
  refreshToken: string;
  assistStartListeningSignal: number;
  assistStartListeningRequested: boolean;
  profile: DeviceProfileInfo;
  sensorGroups: SensorGroup[];
  sensorUpdateFrequency: string;
  contentMaxWidth: number;
  switchRevision: number;
}

export interface AppRuntimeOverlayActions {
  onRoute: (route: number) => void;
  onBackToNativeTarget: () => void;
  onSwipeBack: () => void;
  onCloseAssist: () => void;
  onSensorHelp: () => void;
  onSensorSearch: () => void;
  onSensorFilter: () => void;
  onToggleSensor: (id: string) => void;
  onSelectSensorFrequency: (value: string) => void;
}
