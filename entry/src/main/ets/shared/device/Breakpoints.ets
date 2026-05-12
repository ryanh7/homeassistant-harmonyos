export class Breakpoints {
  static readonly PHONE_MAX_WIDTH: number = 599;
  static readonly TABLET_MIN_WIDTH: number = 600;
  static readonly LARGE_TABLET_MIN_WIDTH: number = 840;
  static readonly WEARABLE_MAX_WIDTH: number = 480;
  static readonly CAR_MIN_WIDTH: number = 960;
  static readonly CAR_MAX_HEIGHT: number = 540;
  static readonly PHONE_CONTENT_MAX_WIDTH: number = 380;
  static readonly TABLET_CONTENT_MAX_WIDTH: number = 560;
  static readonly LARGE_CONTENT_MAX_WIDTH: number = 720;
  static readonly SETTINGS_CONTENT_MAX_WIDTH: number = 720;
  static readonly SETTINGS_TWO_PANE_MIN_WIDTH: number = 840;
  static readonly SETTINGS_TWO_PANE_MAX_WIDTH: number = 1040;

  static onboardingContentMaxWidth(widthVp: number = Breakpoints.PHONE_MAX_WIDTH): number {
    if (widthVp >= Breakpoints.LARGE_TABLET_MIN_WIDTH) {
      return Breakpoints.LARGE_CONTENT_MAX_WIDTH;
    }
    if (widthVp >= Breakpoints.TABLET_MIN_WIDTH) {
      return Breakpoints.TABLET_CONTENT_MAX_WIDTH;
    }
    return Breakpoints.PHONE_CONTENT_MAX_WIDTH;
  }

  static settingsContentMaxWidth(widthVp: number = Breakpoints.PHONE_MAX_WIDTH): number {
    if (widthVp >= Breakpoints.SETTINGS_TWO_PANE_MIN_WIDTH) {
      return Breakpoints.SETTINGS_TWO_PANE_MAX_WIDTH;
    }
    if (widthVp >= Breakpoints.TABLET_MIN_WIDTH) {
      return Breakpoints.SETTINGS_CONTENT_MAX_WIDTH;
    }
    return widthVp;
  }

  static settingsTwoPane(widthVp: number = Breakpoints.PHONE_MAX_WIDTH): boolean {
    return widthVp >= Breakpoints.SETTINGS_TWO_PANE_MIN_WIDTH;
  }
}
