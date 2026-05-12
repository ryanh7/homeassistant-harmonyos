import { Breakpoints } from './Breakpoints';

export enum DeviceFormFactor {
  PHONE,
  TABLET,
  WEARABLE,
  CAR,
  UNKNOWN
}

export interface DeviceProfileInfo {
  widthVp: number;
  heightVp: number;
  formFactor: DeviceFormFactor;
  contentMaxWidth: number;
  settingsMaxWidth: number;
  settingsTwoPane: boolean;
}

export class DeviceProfile {
  static fromSize(widthVp: number, heightVp: number): DeviceProfileInfo {
    let formFactor = DeviceFormFactor.PHONE;
    if (DeviceProfile.isCarLike(widthVp, heightVp)) {
      formFactor = DeviceFormFactor.CAR;
    } else if (DeviceProfile.isWearableLike(widthVp, heightVp)) {
      formFactor = DeviceFormFactor.WEARABLE;
    } else if (widthVp >= Breakpoints.TABLET_MIN_WIDTH) {
      formFactor = DeviceFormFactor.TABLET;
    }

    return {
      widthVp,
      heightVp,
      formFactor,
      contentMaxWidth: Breakpoints.onboardingContentMaxWidth(widthVp),
      settingsMaxWidth: Breakpoints.settingsContentMaxWidth(widthVp),
      settingsTwoPane: Breakpoints.settingsTwoPane(widthVp)
    };
  }

  private static isWearableLike(widthVp: number, heightVp: number): boolean {
    return widthVp > 0 &&
      heightVp > 0 &&
      widthVp <= Breakpoints.WEARABLE_MAX_WIDTH &&
      heightVp <= Breakpoints.WEARABLE_MAX_WIDTH;
  }

  private static isCarLike(widthVp: number, heightVp: number): boolean {
    return widthVp >= Breakpoints.CAR_MIN_WIDTH &&
      heightVp > 0 &&
      heightVp <= Breakpoints.CAR_MAX_HEIGHT;
  }

  static formFactorName(formFactor: DeviceFormFactor): string {
    if (formFactor === DeviceFormFactor.TABLET) {
      return 'tablet';
    }
    if (formFactor === DeviceFormFactor.WEARABLE) {
      return 'wearable';
    }
    if (formFactor === DeviceFormFactor.CAR) {
      return 'car';
    }
    if (formFactor === DeviceFormFactor.UNKNOWN) {
      return 'unknown';
    }
    return 'phone';
  }
}
