import { AppRoute } from './AppRoute';

export interface AppAuthState {
  baseUrl: string;
  accessToken: string;
  refreshToken: string;
}

export interface DashboardState {
  url: string;
  currentUrl: string;
  bridgeReady: boolean;
  authProvided: boolean;
}

export class AppStateDefaults {
  static initialRoute(): AppRoute {
    return AppRoute.WELCOME;
  }

  static auth(): AppAuthState {
    return {
      baseUrl: '',
      accessToken: '',
      refreshToken: ''
    };
  }

  static dashboard(): DashboardState {
    return {
      url: '',
      currentUrl: '',
      bridgeReady: false,
      authProvided: false
    };
  }
}
