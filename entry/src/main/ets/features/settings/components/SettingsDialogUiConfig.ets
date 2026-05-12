import { SettingsPadding, SettingsUiConfig } from './SettingsUiConfig';

export class SettingsDialogUiConfig {
  static readonly transparentBackground: string = SettingsUiConfig.transparentBackground;
  static readonly dialogBackground: string = SettingsUiConfig.titleBarBackground;
  static readonly dialogMaskColor: string = SettingsUiConfig.dialogMaskColor;
  static readonly dialogCornerRadius: number = 8;
  static readonly dialogOpenDuration: number = 220;
  static readonly dialogCloseDuration: number = 180;
  static readonly dialogButtonHeight: number = 40;
  static readonly dialogButtonRadius: number = 8;
  static readonly dialogInputHeight: number = 52;
  static readonly dialogInputRadius: number = 4;
  static readonly dialogInputBorderWidth: number = 1;

  static dialogPadding(): SettingsPadding {
    return { left: 24, right: 24, top: 24, bottom: 16 };
  }

  static dialogWidth(): Dimension {
    return '86%';
  }
}
