import preferences from '@ohos.data.preferences';

export class AppSettingsValueCodec {
  static booleanField(value: preferences.ValueType): boolean {
    return value === true;
  }

  static stringField(value: preferences.ValueType): string {
    return typeof value === 'string' ? value : '';
  }

  static numberField(value: preferences.ValueType, defaultValue: number): number {
    return typeof value === 'number' ? value : defaultValue;
  }

  static stringArrayField(value: preferences.ValueType): string[] {
    if (typeof value !== 'string' || value.length === 0) {
      return [];
    }
    try {
      const parsed = JSON.parse(value) as string[];
      return Array.isArray(parsed) ? parsed.filter((item: string): boolean => typeof item === 'string') : [];
    } catch (_) {
      return [];
    }
  }
}
