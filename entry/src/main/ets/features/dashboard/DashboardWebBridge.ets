// Dashboard-specific WebView bridge for Home Assistant frontend messages.
// Keep frontend response payloads aligned with Home Assistant companion app expectations.
import { AppVersionService } from '../../services/AppVersionService';

export class DashboardWebBridge {
  static parsePayload(payload: Object | string): Record<string, Object | string | number | boolean> {
    if (typeof payload === 'string') {
      try {
        return JSON.parse(payload) as Record<string, Object | string | number | boolean>;
      } catch (_) {
        return {};
      }
    }
    return payload as Record<string, Object | string | number | boolean>;
  }

  static callbackName(payload: Object | string): string {
    const parsed = DashboardWebBridge.parsePayload(payload);
    const raw = parsed['callback'];
    return typeof raw === 'string' ? raw : '';
  }

  static forceRefresh(payload: Object | string): boolean {
    const parsed = DashboardWebBridge.parsePayload(payload);
    const raw = parsed['force'];
    return raw === true || raw === 'true' || raw === '1';
  }

  static externalBusType(payload: Object | string): string {
    const parsed = DashboardWebBridge.parsePayload(payload);
    const raw = parsed['type'];
    return typeof raw === 'string' ? raw : '';
  }

  static externalBusId(payload: Object | string): number {
    const parsed = DashboardWebBridge.parsePayload(payload);
    const raw = parsed['id'];
    if (typeof raw === 'number') {
      return raw;
    }
    if (typeof raw === 'string') {
      const id = Number(raw);
      return Number.isFinite(id) ? id : -1;
    }
    return -1;
  }

  static externalBusPayload(payload: Object | string): Record<string, Object | string | number | boolean> {
    const parsed = DashboardWebBridge.parsePayload(payload);
    const raw = parsed['payload'];
    if (raw && typeof raw === 'object') {
      return raw as Record<string, Object | string | number | boolean>;
    }
    return {};
  }

  static externalBusStringPayload(payload: Object | string, key: string): string {
    const parsed = DashboardWebBridge.externalBusPayload(payload);
    let raw = parsed[key];
    if (typeof raw !== 'string') {
      const topLevel = DashboardWebBridge.parsePayload(payload);
      raw = topLevel[key];
    }
    return typeof raw === 'string' ? raw : '';
  }

  static externalBusBooleanPayload(payload: Object | string, key: string, defaultValue: boolean): boolean {
    const parsed = DashboardWebBridge.externalBusPayload(payload);
    const raw = parsed[key];
    if (typeof raw === 'boolean') {
      return raw;
    }
    if (typeof raw === 'string') {
      return raw === 'true' || raw === '1';
    }
    return defaultValue;
  }

  static buildExternalAuthCallbackScript(callback: string, success: boolean, token: string = ''): string {
    const safeCallback = DashboardWebBridge.jsQuoted(callback);
    const safeToken = DashboardWebBridge.jsQuoted(token);
    return success
      ? `(function(){var fn=window['${safeCallback}'];if(typeof fn==='function'){fn(true,{access_token:'${safeToken}',expires_in:1800});}})();`
      : `(function(){var fn=window['${safeCallback}'];if(typeof fn==='function'){fn(false);}})();`;
  }

  static buildConfigResponseScript(messageId: number): string {
    const id = messageId >= 0 ? messageId : 0;
    const json = `{"type":"result","id":${id},"success":true,"result":{"hasSettingsScreen":true,"canWriteTag":false,"hasExoPlayer":true,"canCommissionMatter":false,"canImportThreadCredentials":false,"hasAssist":true,"hasBarCodeScanner":0,"canSetupImprov":false,"downloadFileSupported":false,"appVersion":${AppVersionService.versionNameJson()},"hasEntityAddTo":false,"hasAssistSettings":true},"error":null}`;
    return `(function(){if(typeof externalBus==='function'){externalBus(${json});}else if(typeof window.externalBus==='function'){window.externalBus(${json});}})();`;
  }

  private static jsQuoted(value: string): string {
    return value.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r/g, '').replace(/\n/g, '\\n');
  }
}
