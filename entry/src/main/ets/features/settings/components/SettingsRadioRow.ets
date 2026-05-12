import { HaColors } from '../../../shared/constants/HaStyle';
import { HaTheme } from '../../../shared/theme/HaTheme';
import { SettingsUiConfig } from './SettingsUiConfig';

@Component
export struct SettingsRadioRow {
  @Prop title: string = '';
  @Prop summary: string = '';
  @Prop selected: boolean = false;
  @Prop minHeight: number = SettingsUiConfig.rowMinHeight;
  @Prop summaryMaxLines: number = 3;
  @StorageLink('appResolvedDark') appResolvedDark: boolean = false;
  onSelect: () => void = () => {};

  build() {
    Row({ space: 18 }) {
      Stack() {
        Circle()
          .width(22)
          .height(22)
          .fill(SettingsUiConfig.transparentBackground)
          .stroke(this.selected ? HaColors.SETTINGS_ACCENT : SettingsUiConfig.optionOutlineColor)
          .strokeWidth(2)

        if (this.selected) {
          Circle()
            .width(12)
            .height(12)
            .fill(HaColors.SETTINGS_ACCENT)
        }
      }
      .width(32)
      .height(32)

      Column({ space: SettingsUiConfig.listSpace }) {
        Text(this.title)
          .fontSize(16)
          .fontColor(HaTheme.textPrimary(this.appResolvedDark))
          .lineHeight(22)
          .width('100%')

        if (this.summary.length > 0) {
          Text(this.summary)
            .fontSize(14)
            .fontColor(HaTheme.textSecondary(this.appResolvedDark))
            .lineHeight(20)
            .maxLines(this.summaryMaxLines)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .constraintSize({ minHeight: this.minHeight })
    .padding(SettingsUiConfig.rowPadding())
    .alignItems(VerticalAlign.Center)
    .backgroundColor(SettingsUiConfig.transparentBackground)
    .onClick(() => {
      this.onSelect();
    })
  }
}
