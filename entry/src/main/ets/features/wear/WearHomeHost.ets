import { WearHomePage, WearMenuItem } from './WearHomePage';

@Component
export struct WearHomeHost {
  @Prop isSignedIn: boolean = false;
  @Prop serverName: string = '';
  @Prop serverUrl: string = '';
  @Prop items: WearMenuItem[] = [];

  onPairPhone: () => void = () => {};
  onOpenItem: (item: WearMenuItem) => void = () => {};
  onSwipeBack: () => void = () => {};

  build() {
    WearHomePage({
      isSignedIn: this.isSignedIn,
      serverName: this.serverName,
      serverUrl: this.serverUrl,
      items: this.items,
      onPairPhone: this.onPairPhone,
      onOpenItem: this.onOpenItem,
      onSwipeBack: this.onSwipeBack
    })
  }
}
