import { AuthService, AuthTokenResult, RefreshTokenResult } from '../../services/AuthService';
import { HaApiService, HaConfigFetchResult } from '../../services/HaApiService';
import { StorageService } from '../../services/StorageService';
import { UrlService } from '../../services/UrlService';
import { Localization } from '../../shared/i18n/Localization';

export interface AuthRefreshRuntimeResult {
  success: boolean;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface HaConfigRuntimeResult {
  summary: string;
  refreshed: boolean;
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresAt: number;
}

export enum AuthRedirectKind {
  IGNORE = 'ignore',
  ACCEPT = 'accept',
  ERROR = 'error'
}

export interface AuthRedirectDecision {
  kind: AuthRedirectKind;
  code: string;
  message: string;
}

export class AuthRuntimeService {
  static buildAuthorizeUrl(baseUrl: string, state: string): string {
    return AuthService.buildAuthorizeUrl(baseUrl, state);
  }

  static appRedirectUri(baseUrl: string): string {
    return AuthService.getAppRedirectUri(baseUrl);
  }

  static parseRedirect(
    url: string,
    baseUrl: string,
    expectedState: string,
    handledCode: string
  ): AuthRedirectDecision {
    const callbackPrefix = AuthRuntimeService.appRedirectUri(baseUrl);
    if (!url.startsWith(callbackPrefix)) {
      return AuthRuntimeService.redirectDecision(AuthRedirectKind.IGNORE);
    }

    const code = UrlService.parseQueryParam(url, 'code');
    const state = UrlService.parseQueryParam(url, 'state');
    if (!code) {
      return AuthRuntimeService.redirectDecision(AuthRedirectKind.ERROR, '', Localization.t('auth_missing_code'));
    }
    if (handledCode === code) {
      return AuthRuntimeService.redirectDecision(AuthRedirectKind.IGNORE);
    }
    if (expectedState.length > 0 && state !== expectedState) {
      return AuthRuntimeService.redirectDecision(AuthRedirectKind.ERROR, '', Localization.t('auth_state_mismatch'));
    }
    return AuthRuntimeService.redirectDecision(AuthRedirectKind.ACCEPT, code);
  }

  static async exchangeCodeForToken(baseUrl: string, code: string): Promise<AuthTokenResult> {
    return AuthService.exchangeCodeForToken(baseUrl, code);
  }

  static async refreshAccessToken(baseUrl: string, refreshToken: string): Promise<AuthRefreshRuntimeResult> {
    const result: RefreshTokenResult = await AuthService.refreshAccessToken(baseUrl, refreshToken);
    return {
      success: result.success,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresIn: result.expiresIn
    };
  }

  static async revokeSession(baseUrl: string, refreshToken: string): Promise<void> {
    await AuthService.revokeSession(baseUrl, refreshToken);
  }

  static async fetchConfigWithRefresh(
    baseUrl: string,
    accessToken: string,
    refreshToken: string
  ): Promise<HaConfigRuntimeResult> {
    if (refreshToken.trim().length > 0) {
      const refreshed = await AuthRuntimeService.refreshAccessToken(baseUrl, refreshToken);
      if (!refreshed.success || refreshed.accessToken.trim().length === 0) {
        return AuthRuntimeService.configResult({
          responseCode: 401,
          config: {
            locationName: '',
            version: '',
            timezone: '',
            temperatureUnit: ''
          },
          failureSummary: Localization.format('auth_token_failed', 'error', 'refresh failed')
        }, false, '', '');
      }
      const result = await HaApiService.fetchConfig(baseUrl, refreshed.accessToken);
      return AuthRuntimeService.configResult(result, true, refreshed.accessToken, refreshed.refreshToken, refreshed.expiresIn);
    }
    let result: HaConfigFetchResult = await HaApiService.fetchConfig(baseUrl, accessToken);
    if (result.responseCode === 401) {
      const refreshed = await AuthRuntimeService.refreshAccessToken(baseUrl, refreshToken);
      if (refreshed.success) {
        result = await HaApiService.fetchConfig(baseUrl, refreshed.accessToken);
        return AuthRuntimeService.configResult(result, true, refreshed.accessToken, refreshed.refreshToken, refreshed.expiresIn);
      }
    }
    return AuthRuntimeService.configResult(result, false, '', '');
  }

  private static configResult(
    result: HaConfigFetchResult,
    refreshed: boolean,
    accessToken: string,
    refreshToken: string,
    expiresIn: number = 0
  ): HaConfigRuntimeResult {
    if (result.responseCode >= 200 && result.responseCode < 300) {
      return {
        summary: HaApiService.formatConfigSummary(result.config),
        refreshed,
        accessToken,
        refreshToken,
        accessTokenExpiresAt: StorageService.accessTokenExpiresAt(expiresIn)
      };
    }
    return {
      summary: result.failureSummary,
      refreshed,
      accessToken,
      refreshToken,
      accessTokenExpiresAt: StorageService.accessTokenExpiresAt(expiresIn)
    };
  }

  private static redirectDecision(
    kind: AuthRedirectKind,
    code: string = '',
    message: string = ''
  ): AuthRedirectDecision {
    return {
      kind,
      code,
      message
    };
  }
}
