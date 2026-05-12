import asset from '@ohos.security.asset';

export class SystemAssetStore {
  static async saveString(alias: string, value: string): Promise<void> {
    const normalizedAlias = alias.trim();
    if (normalizedAlias.length === 0) {
      return;
    }
    if (value.trim().length === 0) {
      await SystemAssetStore.remove(normalizedAlias);
      return;
    }
    const attributes: asset.AssetMap = SystemAssetStore.baseAttributes(normalizedAlias);
    attributes.set(asset.Tag.SECRET, SystemAssetStore.encode(value));
    attributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
    try {
      await asset.add(attributes);
    } catch (error) {
      throw SystemAssetStore.errorFrom(error);
    }
  }

  static async loadString(alias: string): Promise<string> {
    return SystemAssetStore.loadStringSync(alias);
  }

  static loadStringSync(alias: string): string {
    const normalizedAlias = alias.trim();
    if (normalizedAlias.length === 0) {
      return '';
    }
    const query: asset.AssetMap = SystemAssetStore.baseAttributes(normalizedAlias);
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    query.set(asset.Tag.RETURN_LIMIT, 1);
    try {
      const results = asset.querySync(query);
      if (results.length === 0) {
        return '';
      }
      const secret = results[0].get(asset.Tag.SECRET);
      if (secret instanceof Uint8Array) {
        return SystemAssetStore.decode(secret);
      }
    } catch (_) {
    }
    return '';
  }

  static async remove(alias: string): Promise<void> {
    const normalizedAlias = alias.trim();
    if (normalizedAlias.length === 0) {
      return;
    }
    try {
      await asset.remove(SystemAssetStore.baseAttributes(normalizedAlias));
    } catch (_) {
    }
  }

  private static baseAttributes(alias: string): asset.AssetMap {
    const attributes: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    attributes.set(asset.Tag.ALIAS, SystemAssetStore.encode(alias));
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    attributes.set(asset.Tag.AUTH_TYPE, asset.AuthType.NONE);
    attributes.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
    return attributes;
  }

  private static encode(value: string): Uint8Array {
    const bytes = new Uint8Array(value.length);
    for (let i = 0; i < value.length; i++) {
      bytes[i] = value.charCodeAt(i) & 0xFF;
    }
    return bytes;
  }

  private static decode(value: Uint8Array): string {
    let result = '';
    for (let i = 0; i < value.length; i++) {
      result += String.fromCharCode(value[i]);
    }
    return result;
  }

  private static errorFrom(error: Error): Error {
    return error;
  }
}
