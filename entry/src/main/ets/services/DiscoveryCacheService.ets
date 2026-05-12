import common from '@ohos.app.ability.common';
import { HaServerItem } from '../models/HaServerItem';
import { DiscoveryService } from './DiscoveryService';

export class DiscoveryCacheService {
  private static readonly CACHE_TTL_MS: number = 60000;
  private static cachedServers: HaServerItem[] = [];
  private static cachedAt: number = 0;
  private static inFlight: Promise<HaServerItem[]> | undefined = undefined;

  static warm(context: common.Context): void {
    DiscoveryCacheService.discoverMdns(context).catch((): void => {});
  }

  static async discoverMdns(context: common.Context, timeoutMs: number = 4500): Promise<HaServerItem[]> {
    if (DiscoveryCacheService.isFresh()) {
      return DiscoveryCacheService.copyServers(DiscoveryCacheService.cachedServers);
    }
    if (DiscoveryCacheService.inFlight) {
      return DiscoveryCacheService.inFlight;
    }

    DiscoveryCacheService.inFlight = DiscoveryService.discoverByMdns(context, timeoutMs)
      .then((servers: HaServerItem[]): HaServerItem[] => {
        DiscoveryCacheService.cachedServers = DiscoveryCacheService.copyServers(servers);
        DiscoveryCacheService.cachedAt = Date.now();
        return DiscoveryCacheService.copyServers(DiscoveryCacheService.cachedServers);
      })
      .catch((): HaServerItem[] => {
        return [];
      })
      .finally((): void => {
        DiscoveryCacheService.inFlight = undefined;
      });
    return DiscoveryCacheService.inFlight;
  }

  static snapshot(): HaServerItem[] {
    if (!DiscoveryCacheService.isFresh()) {
      return [];
    }
    return DiscoveryCacheService.copyServers(DiscoveryCacheService.cachedServers);
  }

  private static isFresh(): boolean {
    return DiscoveryCacheService.cachedAt > 0 && Date.now() - DiscoveryCacheService.cachedAt < DiscoveryCacheService.CACHE_TTL_MS;
  }

  private static copyServers(servers: HaServerItem[]): HaServerItem[] {
    return servers.map((server: HaServerItem): HaServerItem => {
      return {
        name: server.name,
        url: server.url,
        key: server.key,
        source: server.source,
        status: server.status
      };
    });
  }
}
