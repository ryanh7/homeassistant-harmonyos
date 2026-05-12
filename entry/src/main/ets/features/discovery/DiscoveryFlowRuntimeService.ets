import common from '@ohos.app.ability.common';
import { AppRoute } from '../../app/AppRoute';
import { HaServerItem } from '../../models/HaServerItem';
import { StorageService, StoredServerInfo } from '../../services/StorageService';
import { UrlService } from '../../services/UrlService';
import { Localization } from '../../shared/i18n/Localization';
import { DiscoveryRuntimeService } from './DiscoveryRuntimeService';

export interface DiscoveryFlowRuntimeState {
  discovering: boolean;
  message: string;
  discoveredServers: HaServerItem[];
  discoverySheetPresented: boolean;
  addingServerFromSettings: boolean;
  addServerSnapshot: StoredServerInfo;
  haBaseUrl: string;
  manualAddress: string;
  step: number;
  onboardingBackTarget: number;
  showLoginWeb: boolean;
  loading: boolean;
  authUrl: string;
  oauthState: string;
  handledAuthCode: string;
  dashboardBridgeReady: boolean;
  dashboardAuthProvided: boolean;
  discoveryAnimationRunning: boolean;
  discoveryAnimationToken: number;
  discoverySpinAngle: number;
  discoveryPulseScale: number;
}

export interface DiscoveryFlowRuntimeCallbacks {
  context: () => common.Context;
  setDiscoverySheetVisible: (visible: boolean) => void;
  currentServerInfo: () => StoredServerInfo;
  applyServerInfo: (info: StoredServerInfo) => void;
  startOfficialLogin: () => void;
}

export class DiscoveryFlowRuntimeService {
  static async discover(state: DiscoveryFlowRuntimeState, callbacks: DiscoveryFlowRuntimeCallbacks): Promise<void> {
    state.discovering = true;
    state.message = '';
    state.discoveredServers = [];
    state.discoverySheetPresented = false;
    callbacks.setDiscoverySheetVisible(false);
    await DiscoveryRuntimeService.discover({
      context: callbacks.context(),
      addingServerFromSettings: state.addingServerFromSettings,
      addServerSnapshot: state.addServerSnapshot,
      baseUrl: state.haBaseUrl,
      manualAddress: state.manualAddress
    }, {
      onServerFound: (server: HaServerItem): void => {
        state.discoveredServers.push(server);
        if (state.step === AppRoute.DISCOVERY && !state.discoverySheetPresented) {
          state.discoverySheetPresented = true;
          callbacks.setDiscoverySheetVisible(true);
        }
      },
      onServerStatus: (server: HaServerItem): void => {
        const next: HaServerItem[] = [];
        for (let i = 0; i < state.discoveredServers.length; i++) {
          next.push(state.discoveredServers[i].key === server.key ? server : state.discoveredServers[i]);
        }
        state.discoveredServers = next;
      }
    });
    state.discovering = false;
    state.message = '';
  }

  static selectServer(state: DiscoveryFlowRuntimeState, callbacks: DiscoveryFlowRuntimeCallbacks, url: string): void {
    callbacks.setDiscoverySheetVisible(false);
    DiscoveryFlowRuntimeService.stopAnimation(state);
    callbacks.applyServerInfo(
      StorageService.applyServer(callbacks.currentServerInfo(), UrlService.normalizeBaseUrl(url))
    );
    state.step = AppRoute.LOGIN;
    callbacks.startOfficialLogin();
  }

  static connectManualAddress(state: DiscoveryFlowRuntimeState, callbacks: DiscoveryFlowRuntimeCallbacks): void {
    const normalized = UrlService.normalizeBaseUrl(state.manualAddress);
    if (!normalized) {
      state.message = Localization.t('manual_server_enter_address');
      return;
    }
    DiscoveryFlowRuntimeService.selectServer(state, callbacks, normalized);
  }

  static startFlow(
    state: DiscoveryFlowRuntimeState,
    callbacks: DiscoveryFlowRuntimeCallbacks,
    backTarget: AppRoute = AppRoute.WELCOME
  ): void {
    state.step = AppRoute.DISCOVERY;
    state.onboardingBackTarget = backTarget;
    state.discoveredServers = [];
    state.discoverySheetPresented = false;
    callbacks.setDiscoverySheetVisible(false);
    DiscoveryFlowRuntimeService.discover(state, callbacks).catch((): void => {
      state.message = '';
      state.discovering = false;
    });
  }

  static startAnimation(state: DiscoveryFlowRuntimeState): void {
    if (state.discoveryAnimationRunning) {
      return;
    }
    state.discoveryAnimationRunning = true;
    const token = state.discoveryAnimationToken + 1;
    state.discoveryAnimationToken = token;
    state.discoverySpinAngle = 0;
    state.discoveryPulseScale = 1;
    setTimeout((): void => {
      if (state.discoveryAnimationToken === token && state.step === AppRoute.DISCOVERY) {
        state.discoverySpinAngle = 360;
        state.discoveryPulseScale = 1.15;
      }
    }, 16);
  }

  static stopAnimation(state: DiscoveryFlowRuntimeState): void {
    state.discoveryAnimationRunning = false;
    state.discoveryAnimationToken += 1;
    state.discoverySpinAngle = 0;
    state.discoveryPulseScale = 1;
  }

  static startAddServerFromSettings(state: DiscoveryFlowRuntimeState, callbacks: DiscoveryFlowRuntimeCallbacks): void {
    state.addServerSnapshot = callbacks.currentServerInfo();
    state.addingServerFromSettings = true;
    state.onboardingBackTarget = AppRoute.COMPANION_SETTINGS;
    state.message = '';
    state.authUrl = '';
    state.showLoginWeb = false;
    state.dashboardBridgeReady = false;
    state.dashboardAuthProvided = false;
    DiscoveryFlowRuntimeService.startFlow(state, callbacks, AppRoute.COMPANION_SETTINGS);
  }

  static cancelAddServerFromSettings(state: DiscoveryFlowRuntimeState, callbacks: DiscoveryFlowRuntimeCallbacks): void {
    DiscoveryFlowRuntimeService.stopAnimation(state);
    callbacks.setDiscoverySheetVisible(false);
    callbacks.applyServerInfo(state.addServerSnapshot);
    state.addingServerFromSettings = false;
    state.onboardingBackTarget = AppRoute.WELCOME;
    state.authUrl = '';
    state.oauthState = '';
    state.handledAuthCode = '';
    state.showLoginWeb = false;
    state.loading = false;
    state.message = '';
    state.step = AppRoute.COMPANION_SETTINGS;
  }
}
