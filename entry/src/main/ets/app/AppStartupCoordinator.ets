// Decides the first route after process startup.
// Keep onboarding, signed-in, and app-lock entry policy centralized here.
import { AppRoute } from './AppRoute';
import { Localization } from '../shared/i18n/Localization';

export interface StartupRestoreInput {
  baseUrl: string;
  accessToken: string;
  appLocked: boolean;
  dashboardUrl: string;
}

export interface StartupRestoreDecision {
  shouldRestoreDashboard: boolean;
  route: AppRoute;
  dashboardUrl: string;
  authUrl: string;
  showLoginWeb: boolean;
  dashboardBridgeReady: boolean;
  dashboardAuthProvided: boolean;
  message: string;
}

export interface AppForegroundInput {
  route: AppRoute;
  shouldLock: boolean;
  ignoringLockTransitions: boolean;
}

export interface AppForegroundDecision {
  shouldLock: boolean;
  shouldApplyWindowPreferences: boolean;
  shouldApplyDashboardPreferences: boolean;
  message: string;
}

export class AppStartupCoordinator {
  static restoreOnAppear(input: StartupRestoreInput): StartupRestoreDecision {
    const hasLogin = input.accessToken.trim().length > 0 && input.baseUrl.trim().length > 0;
    if (!hasLogin) {
      return {
        shouldRestoreDashboard: false,
        route: AppRoute.WELCOME,
        dashboardUrl: input.dashboardUrl,
        authUrl: '',
        showLoginWeb: false,
        dashboardBridgeReady: false,
        dashboardAuthProvided: false,
        message: ''
      };
    }
    return {
      shouldRestoreDashboard: true,
      route: AppRoute.DASHBOARD,
      dashboardUrl: input.dashboardUrl,
      authUrl: '',
      showLoginWeb: false,
      dashboardBridgeReady: false,
      dashboardAuthProvided: false,
      message: input.appLocked ? Localization.t('app_lock_message') : ''
    };
  }

  static foreground(input: AppForegroundInput): AppForegroundDecision {
    if (input.ignoringLockTransitions) {
      return {
        shouldLock: false,
        shouldApplyWindowPreferences: false,
        shouldApplyDashboardPreferences: false,
        message: ''
      };
    }
    if (input.shouldLock) {
      return {
        shouldLock: true,
        shouldApplyWindowPreferences: false,
        shouldApplyDashboardPreferences: false,
        message: Localization.t('app_lock_message')
      };
    }
    return {
      shouldLock: false,
      shouldApplyWindowPreferences: true,
      shouldApplyDashboardPreferences: true,
      message: ''
    };
  }
}
