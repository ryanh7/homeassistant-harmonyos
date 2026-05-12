import common from '@ohos.app.ability.common';
import { HaConnectionPolicyService } from '../../services/HaConnectionPolicyService';
import { HaApiService, HaEntityCatalogItem } from '../../services/HaApiService';
import { ServerAuthRepository } from '../../services/ServerAuthRepository';
import {
  CardDataStore,
  HaAreaCatalogRecord,
  HaCatalogMetaRecord,
  HaEntityCatalogRecord
} from './CardDataStore';

export class CardCatalogSyncService {
  private static readonly CATALOG_TTL_MS: number = 6 * 60 * 60 * 1000;

  static async syncIfExpired(context: common.Context, serverInstanceId: string): Promise<boolean> {
    const normalized = serverInstanceId.trim();
    if (normalized.length === 0) {
      return false;
    }
    const meta = await CardDataStore.loadCatalogMeta(context, normalized);
    if (meta.expiresAt > Date.now()) {
      return true;
    }
    return CardCatalogSyncService.forceSyncServer(context, normalized);
  }

  static async forceSyncServer(context: common.Context, serverInstanceId: string): Promise<boolean> {
    const normalized = serverInstanceId.trim();
    const policy = await HaConnectionPolicyService.resolveServerBaseUrl(context, normalized);
    if (!policy.allowed || policy.baseUrl.length === 0) {
      return false;
    }
    const session = await ServerAuthRepository.loadFreshWithBaseUrl(context, normalized, policy.baseUrl);
    if (session.accessToken.length > 0) {
      session.baseUrl = policy.baseUrl;
    }
    if (normalized.length === 0 || session.baseUrl.length === 0 || session.accessToken.length === 0) {
      return false;
    }
    const result = await HaApiService.fetchEntityCatalog(session.baseUrl, session.accessToken);
    if (result.failureSummary.length > 0) {
      await CardDataStore.saveCatalogMeta(context, CardCatalogSyncService.meta(normalized, 0, 0, result.failureSummary));
      return false;
    }
    const areaIds: string[] = [];
    const areaNames: Record<string, string> = {};
    for (let i = 0; i < result.entities.length; i++) {
      const entity = result.entities[i];
      await CardDataStore.upsertEntityCatalog(context, CardCatalogSyncService.entity(normalized, entity));
      if (entity.areaId.length > 0 && areaNames[entity.areaId] === undefined) {
        areaIds.push(entity.areaId);
        areaNames[entity.areaId] = entity.areaName.length > 0 ? entity.areaName : entity.areaId;
      }
    }
    for (let i = 0; i < areaIds.length; i++) {
      await CardDataStore.upsertAreaCatalog(context, CardCatalogSyncService.area(normalized, areaIds[i], areaNames[areaIds[i]]));
    }
    await CardDataStore.saveCatalogMeta(context, CardCatalogSyncService.meta(normalized, result.entities.length, areaIds.length, ''));
    return true;
  }

  private static entity(serverInstanceId: string, source: HaEntityCatalogItem): HaEntityCatalogRecord {
    return {
      serverInstanceId,
      entityId: source.entityId,
      domain: source.domain,
      entityName: source.name,
      areaId: source.areaId,
      areaName: source.areaName,
      deviceId: source.deviceId,
      deviceName: source.deviceName,
      entityCategory: source.entityCategory,
      deviceClass: source.deviceClass,
      unitOfMeasurement: source.unitOfMeasurement,
      icon: source.icon,
      state: source.state,
      updatedAt: Date.now()
    };
  }

  private static area(serverInstanceId: string, areaId: string, areaName: string): HaAreaCatalogRecord {
    return {
      serverInstanceId,
      areaId,
      areaName,
      updatedAt: Date.now()
    };
  }

  private static meta(serverInstanceId: string, entityCount: number, areaCount: number, lastError: string): HaCatalogMetaRecord {
    const now = Date.now();
    return {
      serverInstanceId,
      syncedAt: now,
      expiresAt: lastError.length > 0 ? now : now + CardCatalogSyncService.CATALOG_TTL_MS,
      entityCount,
      areaCount,
      schemaVersion: 1,
      lastError
    };
  }
}
