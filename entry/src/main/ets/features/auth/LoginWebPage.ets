import web_webview from '@ohos.web.webview';
import { UrlGuardResult } from '../../models/UrlGuardResult';
import { NetworkService } from '../../services/NetworkService';
import { LoadingView } from '../../shared/components/LoadingView';
import { HaTheme } from '../../shared/theme/HaTheme';

@Component
export struct LoginWebPage {
  @Prop
  showLoginWeb: boolean = false;
  @Prop
  authUrl: string = '';
  @Prop
  loading: boolean = false;
  @Prop
  appResolvedDark: boolean = false;
  @Prop
  redirectPrefix: string = '';
  controller: web_webview.WebviewController = new web_webview.WebviewController();
  onLoadingChange: (loading: boolean) => void = () => {};
  onUrlGuard: (url: string) => UrlGuardResult = () => {
    return {
      intercept: false,
      rewrittenUrl: ''
    };
  };
  onLoadUrl: (url: string) => void = () => {};
  onAuthRedirect: (url: string) => void = () => {};
  onSwipeBack: () => void = () => {};

  aboutToAppear(): void {
    try {
      this.controller.setCustomUserAgent(NetworkService.ANDROID_COMPATIBLE_USER_AGENT);
    } catch (_) {
    }
  }

  private requestUrl(data: string | WebResourceRequest): string {
    if (typeof data === 'string') {
      return data;
    }
    return data.getRequestUrl();
  }

  private requestIsMainFrame(data: string | WebResourceRequest): boolean {
    if (typeof data === 'string') {
      return true;
    }
    try {
      return data.isMainFrame();
    } catch (_) {
      return true;
    }
  }

  private requestMethod(data: string | WebResourceRequest): string {
    if (typeof data === 'string') {
      return 'GET';
    }
    try {
      return data.getRequestMethod();
    } catch (_) {
      return 'GET';
    }
  }

  build() {
    Stack() {
      if (this.showLoginWeb && this.authUrl) {
        Web({ src: this.authUrl, controller: this.controller })
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .databaseAccess(true)
          .mixedMode(MixedMode.All)
          .onPageBegin(() => {
            this.onLoadingChange(true);
          })
          .onPageEnd(() => {
            this.onLoadingChange(false);
          })
          .onProgressChange((event) => {
            if (event.newProgress >= 100) {
              this.onLoadingChange(false);
            }
          })
          .onLoadIntercept((event) => {
            if (!event) {
              return false;
            }
            const data = event.data;
            const currentUrl = this.requestUrl(data);
            if (this.requestIsMainFrame(data) && this.requestMethod(data) === 'GET') {
              const guard = this.onUrlGuard(currentUrl);
              if (guard.intercept) {
                this.controller.loadUrl(guard.rewrittenUrl);
                this.onLoadUrl(guard.rewrittenUrl);
                return true;
              }
            }
            if (this.redirectPrefix.length > 0 && currentUrl.startsWith(this.redirectPrefix)) {
              this.onAuthRedirect(currentUrl);
              return true;
            }
            return false;
          })
          .width('100%')
          .height('100%')
          .padding({ top: 44, bottom: 32 })
      }

      if (this.loading || !this.showLoginWeb || !this.authUrl) {
        LoadingView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(HaTheme.background(this.appResolvedDark))
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 24 })
        .onActionEnd((event: GestureEvent) => {
          if (event.offsetX > 60 || event.offsetX < -60) {
            this.onSwipeBack();
          }
        })
    )
  }
}
