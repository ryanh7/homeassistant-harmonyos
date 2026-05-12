import common from '@ohos.app.ability.common';
import { HaServerItem } from '../../models/HaServerItem';
import { DiscoveryService } from '../../services/DiscoveryService';
import { DiscoveryCacheService } from '../../services/DiscoveryCacheService';
import { StoredServerInfo } from '../../services/StorageService';
import { DiscoveryCoordinator } from './DiscoveryCoordinator';

export interface DiscoveryRuntimeInput {
  context: common.Context;
  addingServerFromSettings: boolean;
  addServerSnapshot: StoredServerInfo;
  baseUrl: string;
  manualAddress: string;
}

export interface DiscoveryRuntimeCallbacks {
  onServerFound: (server: HaServerItem) => void;
  onServerStatus: (server: HaServerItem) => void;
}

export class DiscoveryRuntimeService {
  static async discover(input: DiscoveryRuntimeInput, callbacks: DiscoveryRuntimeCallbacks): Promise<void> {
    const servers: HaServerItem[] = [];
    await DiscoveryRuntimeService.discoverMdns(input.context, input, servers, callbacks);
    DiscoveryRuntimeService.appendCandidates(input, servers, callbacks);
    await DiscoveryRuntimeService.probeServers(servers, callbacks);
  }

  private static async discoverMdns(
    context: common.Context,
    input: DiscoveryRuntimeInput,
    servers: HaServerItem[],
    callbacks: DiscoveryRuntimeCallbacks
  ): Promise<void> {
    try {
      const mdnsServers = await DiscoveryCacheService.discoverMdns(context, 4500);
      for (let i = 0; i < mdnsServers.length; i++) {
        DiscoveryRuntimeService.appendServer(
          servers,
          mdnsServers[i].url,
          mdnsServers[i].source,
          mdnsServers[i].name,
          input,
          callbacks
        );
      }
    } catch (_) {
    }
  }

  private static appendCandidates(
    input: DiscoveryRuntimeInput,
    servers: HaServerItem[],
    callbacks: DiscoveryRuntimeCallbacks
  ): void {
    const candidates = DiscoveryCoordinator.buildDiscoveryCandidates(
      input.addingServerFromSettings,
      input.baseUrl,
      input.manualAddress
    );
    for (let i = 0; i < candidates.length; i++) {
      DiscoveryRuntimeService.appendServer(servers, candidates[i], 'Home Assistant', 'Home Assistant', input, callbacks);
    }
  }

  private static appendServer(
    servers: HaServerItem[],
    url: string,
    source: string,
    name: string,
    input: DiscoveryRuntimeInput,
    callbacks: DiscoveryRuntimeCallbacks
  ): void {
    if (DiscoveryCoordinator.shouldHideExistingServer(
      url,
      DiscoveryCoordinator.existingServerKeysForDiscovery(
        input.addingServerFromSettings,
        input.addServerSnapshot,
        input.baseUrl
      )
    )) {
      return;
    }
    if (DiscoveryCoordinator.hasDiscoveredServer(servers, url)) {
      return;
    }

    const server = DiscoveryCoordinator.createDiscoveredServer(url, source, name);
    servers.push(server);
    callbacks.onServerFound(server);
  }

  private static async probeServers(
    servers: HaServerItem[],
    callbacks: DiscoveryRuntimeCallbacks
  ): Promise<void> {
    for (let i = 0; i < servers.length; i++) {
      const checking = DiscoveryCoordinator.checking(servers[i]);
      servers[i] = checking;
      callbacks.onServerStatus(checking);
      const available = await DiscoveryService.probeHaServer(checking.url);
      const checked = DiscoveryCoordinator.checked(checking, available);
      servers[i] = checked;
      callbacks.onServerStatus(checked);
    }
  }
}
