import { wifiManager } from '@kit.ConnectivityKit';
import { HomeNetworkService, WirelessSnapshot } from './HomeNetworkService';

export class NativeWirelessProvider {
  private static callbacks: Array<() => void> = [];
  private static subscribed: boolean = false;
  private static readonly onWifiChanged = (value: number): void => {
    value;
    const listeners = NativeWirelessProvider.callbacks.slice();
    for (let i = 0; i < listeners.length; i++) {
      listeners[i]();
    }
  };

  static async currentSnapshot(): Promise<WirelessSnapshot> {
    try {
      const connected = wifiManager.isConnected();
      if (!connected) {
        return HomeNetworkService.emptyWirelessSnapshot();
      }
      const info = await wifiManager.getLinkedInfo();
      return {
        connected: connected,
        ssid: info.ssid ?? '',
        isHidden: info.isHidden ?? false,
        rssi: info.rssi ?? 0,
        signalLevel: NativeWirelessProvider.signalLevel(info.rssi ?? 0, info.band ?? 0),
        frequency: info.frequency ?? 0,
        linkSpeed: info.linkSpeed ?? 0,
        ipAddress: NativeWirelessProvider.ipAddressText(info.ipAddress ?? 0)
      };
    } catch (_) {
      return HomeNetworkService.emptyWirelessSnapshot();
    }
  }

  static subscribe(callback: () => void): void {
    NativeWirelessProvider.callbacks.push(callback);
    if (NativeWirelessProvider.subscribed) {
      return;
    }
    NativeWirelessProvider.subscribed = true;
    try {
      wifiManager.on('wifiConnectionChange', NativeWirelessProvider.onWifiChanged);
      wifiManager.on('wifiRssiChange', NativeWirelessProvider.onWifiChanged);
    } catch (_) {
    }
  }

  static unsubscribe(callback: () => void): void {
    const next: Array<() => void> = [];
    for (let i = 0; i < NativeWirelessProvider.callbacks.length; i++) {
      if (NativeWirelessProvider.callbacks[i] !== callback) {
        next.push(NativeWirelessProvider.callbacks[i]);
      }
    }
    NativeWirelessProvider.callbacks = next;
    if (NativeWirelessProvider.callbacks.length > 0 || !NativeWirelessProvider.subscribed) {
      return;
    }
    NativeWirelessProvider.subscribed = false;
    try {
      wifiManager.off('wifiConnectionChange', NativeWirelessProvider.onWifiChanged);
      wifiManager.off('wifiRssiChange', NativeWirelessProvider.onWifiChanged);
    } catch (_) {
    }
  }

  private static signalLevel(rssi: number, band: number): number {
    try {
      return wifiManager.getSignalLevel(rssi, band);
    } catch (_) {
      return 0;
    }
  }

  private static ipAddressText(value: number): string {
    if (value <= 0) {
      return '';
    }
    const a = value & 0xff;
    const b = (value >> 8) & 0xff;
    const c = (value >> 16) & 0xff;
    const d = (value >> 24) & 0xff;
    return `${a}.${b}.${c}.${d}`;
  }
}
