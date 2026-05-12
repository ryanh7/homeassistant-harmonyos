// Runtime localization facade for code-driven strings.
// Locale resource maps live in resources so this file stays focused on lookup and formatting.
import i18n from '@ohos.i18n';

import { EN_US } from './resources/LocalizationEnUs';
import { ZH_CN } from './resources/LocalizationZhCn';

export class Localization {
  private static appLanguage: string = 'default';

  static setAppLanguage(value: string): void {
    if (value === 'zh-Hans' || value === 'en') {
      Localization.appLanguage = value;
      return;
    }
    Localization.appLanguage = 'default';
  }

  static language(): string {
    if (Localization.appLanguage === 'zh-Hans') {
      return 'zh-Hans';
    }
    if (Localization.appLanguage === 'en') {
      return 'en';
    }
    try {
      return i18n.System.getSystemLanguage();
    } catch (_) {
      return 'zh';
    }
  }

  static isChinese(): boolean {
    return Localization.language().toLowerCase().startsWith('zh');
  }

  static t(key: string): string {
    const bundle = Localization.isChinese() ? ZH_CN : EN_US;
    return bundle.get(key) ?? ZH_CN.get(key) ?? EN_US.get(key) ?? key;
  }

  static format(key: string, name: string, value: string | number): string {
    return Localization.t(key).replace(new RegExp(`\\{${name}\\}`, 'g'), `${value}`);
  }

  static format2(
    key: string,
    firstName: string,
    firstValue: string | number,
    secondName: string,
    secondValue: string | number
  ): string {
    return Localization.format(key, firstName, firstValue)
      .replace(new RegExp(`\\{${secondName}\\}`, 'g'), `${secondValue}`);
  }

  static formatValues(key: string, values: Record<string, string | number>): string {
    let text = Localization.t(key);
    const keys = Object.keys(values);
    for (let i = 0; i < keys.length; i += 1) {
      const name = keys[i];
      text = text.replace(new RegExp(`\\{${name}\\}`, 'g'), `${values[name]}`);
    }
    return text;
  }
}
