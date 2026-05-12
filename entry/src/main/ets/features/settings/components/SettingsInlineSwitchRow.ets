import { HaColors } from '../../../shared/constants/HaStyle';
import { HaTheme } from '../../../shared/theme/HaTheme';
import { SettingsUiConfig } from './SettingsUiConfig';

@Component
export struct SettingsInlineSwitchRow {
  @Prop title: string = '';
  @Prop summary: string = '';
  @Prop checked: boolean = false;
  @StorageLink('appResolvedDark') appResolvedDark: boolean = false;
  onChange: (value: boolean) => void = () => {};

  build() {
    Row({ space: 16 }) {
      Column({ space: SettingsUiConfig.listSpace }) {
        Text(this.title)
          .fontSize(16)
          .fontColor(HaTheme.textPrimary(this.appResolvedDark))
          .width('100%')

        if (this.summary.length > 0) {
          Text(this.summary)
            .fontSize(14)
            .fontColor(HaTheme.textSecondary(this.appResolvedDark))
            .lineHeight(20)
            .width('100%')
        }
      }
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.checked })
        .selectedColor(HaColors.SETTINGS_ACCENT)
        .onChange((value: boolean) => {
          this.onChange(value);
        })
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .padding(SettingsUiConfig.rowPadding())
    .backgroundColor(SettingsUiConfig.transparentBackground)
    .alignItems(VerticalAlign.Center)
  }
}
