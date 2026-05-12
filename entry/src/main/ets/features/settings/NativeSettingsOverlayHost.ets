import { AppRoute } from '../../app/AppRoute';
import { DeviceFormFactor, DeviceProfileInfo } from '../../shared/device/DeviceProfile';
import { NotificationSettingsPage } from '../notifications/NotificationSettingsPage';

class DefaultDeviceProfileInfo implements DeviceProfileInfo {
  widthVp: number = 0;
  heightVp: number = 0;
  formFactor: DeviceFormFactor = DeviceFormFactor.PHONE;
  contentMaxWidth: number = 0;
  settingsMaxWidth: number = 0;
  settingsTwoPane: boolean = false;
}

@Component
export struct NativeSettingsOverlayHost {
  @Prop route: number = AppRoute.NOTIFICATION_SETTINGS;
  @Prop profile: DeviceProfileInfo = new DefaultDeviceProfileInfo();

  onBack: () => void = () => {};
  onOpenNotificationHistory: () => void = () => {};
  onSwipeBack: () => void = () => {};

  build() {
    if (this.route === AppRoute.NOTIFICATION_SETTINGS) {
      NotificationSettingsPage({
        onBack: this.onBack,
        onOpenHistory: this.onOpenNotificationHistory,
        onSwipeBack: this.onSwipeBack
      })
    }
  }
}
