import { AppLockPage } from './AppLockPage';

@Component
export struct AppLockRuntimeHost {
  @Prop unlocking: boolean = false;
  @Prop dark: boolean = false;

  onUnlock: () => void = () => {};

  build() {
    AppLockPage({
      unlocking: this.unlocking,
      dark: this.dark,
      onUnlock: this.onUnlock
    })
  }
}
