import { UrlService } from '../../services/UrlService';
import { WearHomeHost } from './WearHomeHost';
import { WearMenuItem } from './WearHomePage';
import { WearService } from './WearService';

@Component
export struct WearRuntimeHost {
  @Prop isSignedIn: boolean = false;
  @Prop serverName: string = '';
  @Prop serverUrl: string = '';

  onMessage: (message: string) => void = () => {};
  onSwipeBack: () => void = () => {};

  build() {
    WearHomeHost({
      isSignedIn: this.isSignedIn,
      serverName: this.serverName,
      serverUrl: UrlService.normalizeBaseUrl(this.serverUrl),
      items: WearService.menuItems(),
      onPairPhone: (): void => {
        this.onMessage(WearService.pairPhoneMessage());
      },
      onOpenItem: (item: WearMenuItem): void => {
        this.onMessage(WearService.openItemMessage(item));
      },
      onSwipeBack: this.onSwipeBack
    })
  }
}
