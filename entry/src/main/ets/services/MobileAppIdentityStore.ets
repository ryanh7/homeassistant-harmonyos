import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';

export class MobileAppIdentityStore {
  private static readonly PREFERENCES_NAME: string = 'ha_mobile_app_identity';
  private static readonly DEVICE_ID: string = 'mobile_app_device_id';
  private static readonly CREATED_AT: string = 'created_at';
  private static readonly REGISTRATION_APP_ID_PREFIX: string = 'registration_app_id_';

  static async getOrCreateDeviceId(context: common.Context, candidate: string = ''): Promise<string> {
    const pref = await MobileAppIdentityStore.getPreferences(context);
    const current = MobileAppIdentityStore.stringField(await MobileAppIdentityStore.getValue(pref, MobileAppIdentityStore.DEVICE_ID, '')).trim();
    if (current.length > 0) {
      return current;
    }
    const next = candidate.trim().length > 0 ? candidate.trim() : MobileAppIdentityStore.createDeviceId();
    await MobileAppIdentityStore.putValue(pref, MobileAppIdentityStore.DEVICE_ID, next);
    await MobileAppIdentityStore.putValue(pref, MobileAppIdentityStore.CREATED_AT, Date.now());
    await MobileAppIdentityStore.flush(pref);
    return next;
  }

  static async getRegistrationAppId(context: common.Context, serverInstanceId: string): Promise<string> {
    const pref = await MobileAppIdentityStore.getPreferences(context);
    return MobileAppIdentityStore.stringField(await MobileAppIdentityStore.getValue(
      pref,
      MobileAppIdentityStore.registrationAppIdKey(serverInstanceId),
      ''
    ));
  }

  static async setRegistrationAppId(context: common.Context, serverInstanceId: string, appId: string): Promise<void> {
    const pref = await MobileAppIdentityStore.getPreferences(context);
    await MobileAppIdentityStore.putValue(pref, MobileAppIdentityStore.registrationAppIdKey(serverInstanceId), appId);
    await MobileAppIdentityStore.flush(pref);
  }

  private static async getPreferences(context: common.Context): Promise<preferences.Preferences> {
    try {
      return await preferences.getPreferences(context, MobileAppIdentityStore.PREFERENCES_NAME);
    } catch (error) {
      throw MobileAppIdentityStore.errorFrom(error);
    }
  }

  private static async getValue(
    pref: preferences.Preferences,
    key: string,
    defaultValue: preferences.ValueType
  ): Promise<preferences.ValueType> {
    try {
      return await pref.get(key, defaultValue);
    } catch (error) {
      throw MobileAppIdentityStore.errorFrom(error);
    }
  }

  private static async putValue(
    pref: preferences.Preferences,
    key: string,
    value: preferences.ValueType
  ): Promise<void> {
    try {
      await pref.put(key, value);
    } catch (error) {
      throw MobileAppIdentityStore.errorFrom(error);
    }
  }

  private static async flush(pref: preferences.Preferences): Promise<void> {
    try {
      await pref.flush();
    } catch (error) {
      throw MobileAppIdentityStore.errorFrom(error);
    }
  }

  private static createDeviceId(): string {
    return `ha-harmony-${Date.now().toString(36)}-${Math.floor(Math.random() * 2147483647).toString(36)}`;
  }

  private static registrationAppIdKey(serverInstanceId: string): string {
    const normalized = serverInstanceId.trim().replace(/[^A-Za-z0-9_-]/g, '_');
    return `${MobileAppIdentityStore.REGISTRATION_APP_ID_PREFIX}${normalized}`;
  }

  private static stringField(value: preferences.ValueType): string {
    return typeof value === 'string' ? value : '';
  }

  private static errorFrom(error: Error): Error {
    return error;
  }
}
