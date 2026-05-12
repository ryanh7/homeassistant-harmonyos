import commonEventManager from '@ohos.commonEventManager';
import { NetworkNetConnection, NetworkService } from './NetworkService';

export class SystemEventService {
  private batteryEventSubscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private netConnection: NetworkNetConnection | undefined = undefined;
  private wirelessChanged: (() => void) | undefined = undefined;

  subscribeBatteryEvents(onChanged: () => void): void {
    if (this.batteryEventSubscriber) {
      return;
    }
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_BATTERY_CHANGED,
        commonEventManager.Support.COMMON_EVENT_POWER_CONNECTED,
        commonEventManager.Support.COMMON_EVENT_POWER_DISCONNECTED,
        commonEventManager.Support.COMMON_EVENT_CHARGING,
        commonEventManager.Support.COMMON_EVENT_DISCHARGING
      ]
    };
    commonEventManager.createSubscriber(subscribeInfo)
      .then((subscriber: commonEventManager.CommonEventSubscriber): Promise<void> => {
        this.batteryEventSubscriber = subscriber;
        return commonEventManager.subscribeToEvent(subscriber, (): void => {
          onChanged();
        });
      })
      .catch((): void => {});
  }

  unsubscribeBatteryEvents(): void {
    if (!this.batteryEventSubscriber) {
      return;
    }
    const subscriber = this.batteryEventSubscriber;
    this.batteryEventSubscriber = undefined;
    commonEventManager.unsubscribe(subscriber, () => {});
  }

  subscribeNetworkEvents(onChanged: () => void): void {
    if (this.netConnection || this.wirelessChanged) {
      return;
    }
    this.wirelessChanged = onChanged;
    NetworkService.subscribeWirelessEvents(onChanged);
    try {
      const netConnection = NetworkService.createNetConnection();
      netConnection.on('netAvailable', onChanged);
      netConnection.on('netLost', onChanged);
      netConnection.on('netCapabilitiesChange', onChanged);
      netConnection.register((): void => {});
      this.netConnection = netConnection;
    } catch (_) {
    }
  }

  unsubscribeNetworkEvents(): void {
    if (this.wirelessChanged) {
      NetworkService.unsubscribeWirelessEvents(this.wirelessChanged);
      this.wirelessChanged = undefined;
    }
    if (!this.netConnection) {
      return;
    }
    const netConnection = this.netConnection;
    this.netConnection = undefined;
    try {
      netConnection.unregister((): void => {});
    } catch (_) {
    }
  }

  unsubscribeAll(): void {
    this.unsubscribeBatteryEvents();
    this.unsubscribeNetworkEvents();
  }
}
