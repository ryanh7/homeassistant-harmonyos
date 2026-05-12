import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';

type SnapshotValue = string | number | boolean;

export class CardFormSnapshotStore {
  private static readonly STORE_NAME: string = 'ha_card_form_snapshots';
  private static readonly KEY_PREFIX: string = 'form_';

  static load(context: common.Context, formId: string): Record<string, SnapshotValue> | undefined {
    const key = CardFormSnapshotStore.key(formId);
    if (key.length === 0) {
      return undefined;
    }
    try {
      const store = preferences.getPreferencesSync(context, { name: CardFormSnapshotStore.STORE_NAME });
      const raw = store.getSync(key, '') as string;
      if (raw.length === 0) {
        return undefined;
      }
      return CardFormSnapshotStore.parse(raw);
    } catch (_) {
      return undefined;
    }
  }

  static save(context: common.Context, formId: string, data: Object): void {
    const key = CardFormSnapshotStore.key(formId);
    if (key.length === 0) {
      return;
    }
    try {
      const store = preferences.getPreferencesSync(context, { name: CardFormSnapshotStore.STORE_NAME });
      store.putSync(key, JSON.stringify(CardFormSnapshotStore.sanitize(data)));
      store.flushSync();
    } catch (_) {
    }
  }

  static clear(context: common.Context, formId: string): void {
    const key = CardFormSnapshotStore.key(formId);
    if (key.length === 0) {
      return;
    }
    try {
      const store = preferences.getPreferencesSync(context, { name: CardFormSnapshotStore.STORE_NAME });
      store.deleteSync(key);
      store.flushSync();
    } catch (_) {
    }
  }

  private static key(formId: string): string {
    const normalized = formId.trim();
    return normalized.length > 0 ? `${CardFormSnapshotStore.KEY_PREFIX}${normalized}` : '';
  }

  private static sanitize(data: Object): Record<string, SnapshotValue> {
    const source = data as Record<string, Object>;
    const snapshot: Record<string, SnapshotValue> = {};
    Object.keys(source).forEach((key: string): void => {
      const value = source[key];
      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
        snapshot[key] = value;
      }
    });
    return snapshot;
  }

  private static parse(raw: string): Record<string, SnapshotValue> | undefined {
    try {
      const source = JSON.parse(raw) as Record<string, Object>;
      return CardFormSnapshotStore.sanitize(source);
    } catch (_) {
      return undefined;
    }
  }
}
