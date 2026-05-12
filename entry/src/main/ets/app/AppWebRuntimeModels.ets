import { UrlGuardResult } from '../models/UrlGuardResult';

export interface AppWebRuntimeSnapshot {
  route: number;
  baseUrl: string;
  showLoginWeb: boolean;
  authUrl: string;
  loading: boolean;
  dashboardUrl: string;
  dashboardLoadedUrl: string;
  dashboardInsecureBlocked: boolean;
  dashboardMissingHomeSetup: boolean;
  dashboardBlockedReason: string;
  dashboardAuthProvided: boolean;
  pageZoomLevel: string;
  pinchToZoomEnabled: boolean;
  autoPlayVideoEnabled: boolean;
  appTheme: string;
  dark: boolean;
}

export interface AppWebRuntimeActions {
  onLoadingChange: (loading: boolean) => void;
  onUrlGuard: (url: string) => UrlGuardResult;
  onLoadUrl: (url: string) => void;
  onAuthRedirect: (url: string) => void;
  onSwipeBack: () => void;
  onDashboardBridgeReady: () => void;
  onDashboardPageReady: () => void;
  onRememberDashboardUrl: (url: string) => void;
  onDashboardLoadedUrlChange: (url: string) => void;
  onRetryDashboardSecurity: () => void;
  onOpenDashboardSecuritySettings: () => void;
  onChangeDashboardSecurityLevel: () => void;
  onConfigureDashboardHomeNetwork: () => void;
  onMessage: (message: string) => void;
}
