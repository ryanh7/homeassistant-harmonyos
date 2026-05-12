import { HaServerItem } from '../../models/HaServerItem';
import { StoredServerInfo } from '../../services/StorageService';
import { DiscoveryService } from '../../services/DiscoveryService';
import { UrlService } from '../../services/UrlService';
import { Localization } from '../../shared/i18n/Localization';

export class DiscoveryCoordinator {
  static buildDiscoveryCandidates(addingServerFromSettings: boolean, baseUrl: string, manualAddress: string): string[] {
    return DiscoveryService.buildDiscoveryCandidates(addingServerFromSettings ? '' : baseUrl, manualAddress);
  }

  static existingServerKeysForDiscovery(
    addingServerFromSettings: boolean,
    addServerSnapshot: StoredServerInfo,
    currentBaseUrl: string
  ): string[] {
    const keys: string[] = [];
    if (!addingServerFromSettings) {
      return keys;
    }
    DiscoveryCoordinator.appendExistingServerKey(keys, addServerSnapshot.baseUrl);
    if (keys.length === 0) {
      DiscoveryCoordinator.appendExistingServerKey(keys, currentBaseUrl);
    }
    return keys;
  }

  static shouldHideExistingServer(url: string, existingKeys: string[]): boolean {
    const candidateKey = DiscoveryCoordinator.discoveryIdentityKey(url);
    if (candidateKey.length === 0) {
      return false;
    }
    for (let i = 0; i < existingKeys.length; i++) {
      if (existingKeys[i] === candidateKey) {
        return true;
      }
    }
    return false;
  }

  static hasDiscoveredServer(servers: HaServerItem[], url: string): boolean {
    const candidateKey = UrlService.endpointKey(url);
    for (let i = 0; i < servers.length; i++) {
      if (servers[i].key === candidateKey) {
        return true;
      }
    }
    return false;
  }

  static createDiscoveredServer(url: string, source: string, name: string): HaServerItem {
    return {
      name,
      url,
      key: UrlService.endpointKey(url),
      source,
      status: Localization.t('discovery_status_searching')
    };
  }

  static withStatus(item: HaServerItem, status: string): HaServerItem {
    return {
      name: item.name,
      url: item.url,
      key: item.key,
      source: item.source,
      status
    };
  }

  static checking(item: HaServerItem): HaServerItem {
    return DiscoveryCoordinator.withStatus(item, Localization.t('discovery_status_checking'));
  }

  static checked(item: HaServerItem, available: boolean): HaServerItem {
    return DiscoveryCoordinator.withStatus(item,
      available ? Localization.t('discovery_status_online') : Localization.t('common_unavailable'));
  }

  private static discoveryIdentityKey(url: string): string {
    return UrlService.normalizeBaseUrl(url).toLowerCase();
  }

  private static appendExistingServerKey(keys: string[], url: string): void {
    const key = DiscoveryCoordinator.discoveryIdentityKey(url);
    if (key.length === 0) {
      return;
    }
    for (let i = 0; i < keys.length; i++) {
      if (keys[i] === key) {
        return;
      }
    }
    keys.push(key);
  }
}
