import { AppRoute } from '../../app/AppRoute';
import { StorageService, StoredServerInfo } from '../../services/StorageService';
import { UrlService } from '../../services/UrlService';
import { Localization } from '../../shared/i18n/Localization';
import {
  AuthRedirectDecision,
  AuthRedirectKind,
  AuthRefreshRuntimeResult,
  AuthRuntimeService,
  HaConfigRuntimeResult
} from './AuthRuntimeService';

export interface AuthFlowRuntimeState {
  haBaseUrl: string;
  haAccessToken: string;
  haRefreshToken: string;
  configSummary: string;
  step: number;
  dashboardUrl: string;
  authUrl: string;
  showLoginWeb: boolean;
  dashboardBridgeReady: boolean;
  dashboardAuthProvided: boolean;
  oauthState: string;
  handledAuthCode: string;
  loading: boolean;
  message: string;
}

export interface AuthFlowRuntimeCallbacks {
  currentServerInfo: () => StoredServerInfo;
  applyServerInfo: (info: StoredServerInfo) => void;
  stringifyError: (err: Error | string | number | boolean | Object | ArrayBuffer) => string;
}

export class AuthFlowRuntimeService {
  private static baseUrlFromAuthorizeUrl(authUrl: string): string {
    const marker = '/auth/authorize';
    const markerIndex = authUrl.indexOf(marker);
    if (markerIndex < 0) {
      return '';
    }
    return UrlService.normalizeBaseUrl(authUrl.slice(0, markerIndex));
  }

  private static loginBaseUrl(state: AuthFlowRuntimeState): string {
    const baseUrl = UrlService.normalizeBaseUrl(state.haBaseUrl);
    if (baseUrl.length > 0) {
      return baseUrl;
    }
    const recovered = AuthFlowRuntimeService.baseUrlFromAuthorizeUrl(state.authUrl);
    if (recovered.length > 0) {
      state.haBaseUrl = recovered;
    }
    return recovered;
  }

  static async exchangeCodeForToken(
    state: AuthFlowRuntimeState,
    callbacks: AuthFlowRuntimeCallbacks,
    baseUrl: string,
    code: string
  ): Promise<void> {
    const tokenResult = await AuthRuntimeService.exchangeCodeForToken(baseUrl, code);
    callbacks.applyServerInfo(
      StorageService.applyLogin(
        callbacks.currentServerInfo(),
        baseUrl,
        tokenResult.accessToken,
        tokenResult.refreshToken,
        StorageService.accessTokenExpiresAt(tokenResult.expiresIn)
      )
    );
    state.step = AppRoute.NAME_DEVICE;
    state.dashboardUrl = UrlService.buildDashboardUrl(baseUrl);
    state.authUrl = '';
    state.showLoginWeb = false;
    state.dashboardBridgeReady = false;
    state.dashboardAuthProvided = false;
    state.message = '';
    try {
      await AuthFlowRuntimeService.fetchHaConfig(state, callbacks);
    } catch (e) {
      state.configSummary = Localization.format('app_config_fetch_exception', 'error',
        callbacks.stringifyError(e as Error | string | number | boolean | Object | ArrayBuffer));
    }
  }

  static async refreshAccessToken(
    state: AuthFlowRuntimeState,
    callbacks: AuthFlowRuntimeCallbacks,
    baseUrl: string
  ): Promise<boolean> {
    const result: AuthRefreshRuntimeResult = await AuthRuntimeService.refreshAccessToken(baseUrl, state.haRefreshToken);
    if (!result.success) {
      return false;
    }
    callbacks.applyServerInfo(
      StorageService.applyRefresh(
        callbacks.currentServerInfo(),
        result.accessToken,
        result.refreshToken,
        StorageService.accessTokenExpiresAt(result.expiresIn)
      )
    );
    return true;
  }

  static async fetchHaConfig(
    state: AuthFlowRuntimeState,
    callbacks: AuthFlowRuntimeCallbacks,
    connectionBaseUrl: string = ''
  ): Promise<void> {
    const baseUrl = UrlService.normalizeBaseUrl(
      connectionBaseUrl.trim().length > 0 ? connectionBaseUrl : state.haBaseUrl
    );
    const token = state.haAccessToken.trim();
    if (!baseUrl || !token) {
      state.configSummary = Localization.t('common_not_set');
      return;
    }

    const result: HaConfigRuntimeResult = await AuthRuntimeService.fetchConfigWithRefresh(baseUrl, token, state.haRefreshToken);
    if (result.refreshed) {
      callbacks.applyServerInfo(
        StorageService.applyRefresh(callbacks.currentServerInfo(), result.accessToken, result.refreshToken, result.accessTokenExpiresAt)
      );
    }
    state.configSummary = result.summary;
  }

  static startOfficialLogin(state: AuthFlowRuntimeState): void {
    const baseUrl = UrlService.normalizeBaseUrl(state.haBaseUrl);
    if (!baseUrl) {
      state.message = Localization.t('auth_enter_server_first');
      return;
    }

    const oauthState = `${Date.now()}`;
    state.oauthState = oauthState;
    state.handledAuthCode = '';
    state.authUrl = AuthRuntimeService.buildAuthorizeUrl(baseUrl, oauthState);
    state.showLoginWeb = true;
    state.loading = true;
    state.message = '';
  }

  static handleAuthRedirect(
    state: AuthFlowRuntimeState,
    callbacks: AuthFlowRuntimeCallbacks,
    url: string
  ): void {
    const baseUrl = AuthFlowRuntimeService.loginBaseUrl(state);
    if (!baseUrl) {
      state.message = Localization.t('auth_enter_server_first');
      return;
    }
    const decision: AuthRedirectDecision = AuthRuntimeService.parseRedirect(
      url,
      baseUrl,
      state.oauthState,
      state.handledAuthCode
    );
    if (decision.kind === AuthRedirectKind.IGNORE) {
      return;
    }
    if (decision.kind === AuthRedirectKind.ERROR) {
      state.message = decision.message;
      return;
    }

    state.handledAuthCode = decision.code;
    state.showLoginWeb = false;
    state.loading = true;
    state.message = '';

    AuthFlowRuntimeService.exchangeCodeForToken(state, callbacks, baseUrl, decision.code)
      .catch((error: Error) => {
        const failure = Localization.format('auth_token_failed', 'error', error.message);
        state.step = AppRoute.LOGIN;
        AuthFlowRuntimeService.startOfficialLogin(state);
        state.message = failure;
      })
      .finally(() => {
        state.loading = false;
      });
  }
}
