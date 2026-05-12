import common from '@ohos.app.ability.common';
import { AppRoute } from './AppRoute';
import { StorageService, StoredServerInfo } from '../services/StorageService';
import { Localization } from '../shared/i18n/Localization';
import { ServerManager } from '../services/ServerManager';

export interface AppSessionRuntimeState {
  haBaseUrl: string;
  haAccessToken: string;
  haRefreshToken: string;
  haWebhookId: string;
  haWebhookSecret: string;
  haCloudhookUrl: string;
  haRemoteUiUrl: string;
  haMobileAppDeviceId: string;
  deviceName: string;
  configSummary: string;
  dashboardUrl: string;
  dashboardBridgeReady: boolean;
  dashboardAuthProvided: boolean;
  showLoginWeb: boolean;
  step: AppRoute | number;
  message: string;
}

export class AppSessionRuntimeService {
  static currentStoredServerInfo(state: AppSessionRuntimeState): StoredServerInfo {
    return StorageService.serverInfo(
      state.haBaseUrl,
      state.haAccessToken,
      state.haRefreshToken,
      0,
      state.deviceName,
      state.haMobileAppDeviceId,
      state.haWebhookId,
      state.haWebhookSecret,
      state.haCloudhookUrl,
      state.haRemoteUiUrl
    );
  }

  static applyStoredServerInfo(
    context: common.Context,
    state: AppSessionRuntimeState,
    info: StoredServerInfo,
    onServerConnectionChanged: () => void
  ): void {
    ServerManager.applyActiveToAppStorage(info);
    ServerManager.saveActiveServerInfo(context, info).catch((): void => {});
    AppSessionRuntimeService.applyServerInfoToState(state, info);
    onServerConnectionChanged();
  }

  static applyServerInfoToState(state: AppSessionRuntimeState, info: StoredServerInfo): void {
    state.haBaseUrl = info.baseUrl;
    state.haAccessToken = info.accessToken;
    state.haRefreshToken = info.refreshToken;
    state.haWebhookId = info.webhookId;
    state.haWebhookSecret = info.webhookSecret;
    state.haCloudhookUrl = info.cloudhookUrl;
    state.haRemoteUiUrl = info.remoteUiUrl;
    state.haMobileAppDeviceId = info.mobileAppDeviceId;
    if (info.deviceName.length > 0) {
      state.deviceName = info.deviceName;
    }
  }

  static hasLogin(state: AppSessionRuntimeState): boolean {
    return StorageService.hasLogin(AppSessionRuntimeService.currentStoredServerInfo(state));
  }

  static resetLoginState(
    context: common.Context,
    state: AppSessionRuntimeState,
    onServerConnectionChanged: () => void,
    onResetTheme: () => void,
    onStopDiscovery: () => void
  ): void {
    onStopDiscovery();
    const cleared = StorageService.clearLogin(AppSessionRuntimeService.currentStoredServerInfo(state));
    AppSessionRuntimeService.applyStoredServerInfo(context, state, cleared, onServerConnectionChanged);
    state.configSummary = Localization.t('common_not_set');
    state.dashboardUrl = '';
    state.dashboardBridgeReady = false;
    state.dashboardAuthProvided = false;
    onResetTheme();
    state.showLoginWeb = false;
    state.step = AppRoute.WELCOME;
    state.message = Localization.t('app_signed_out');
  }
}
