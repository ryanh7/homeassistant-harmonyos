import { HaColors } from '../../shared/constants/HaStyle';
import { HaTheme } from '../../shared/theme/HaTheme';
import { SettingChoiceGroup, SettingChoiceOption } from './CompanionSettingsData';
import { SettingsRadioRow } from './components/SettingsRadioRow';

@CustomDialog
@Component
export struct CompanionChoiceDialog {
  controller: CustomDialogController;
  @Prop
  title: string = '';
  @Prop
  selectedValue: string = '';
  @Prop
  groups: SettingChoiceGroup[] = [];
  @Prop
  dark: boolean = false;
  onSelect: (value: string) => void = () => {};
  onClose: () => void = () => {};

  @Builder
  private optionRow(option: SettingChoiceOption): void {
    SettingsRadioRow({
      title: option.title,
      summary: option.summary,
      selected: this.selectedValue === option.value,
      minHeight: 56,
      onSelect: (): void => {
        this.onSelect(option.value);
      }
    })
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .fontColor(HaTheme.textPrimary(this.dark))
        .width('100%')
        .padding({ left: 24, right: 24, top: 24, bottom: 8 })

      Scroll() {
        Column() {
          ForEach(this.groups, (group: SettingChoiceGroup) => {
            if (group.title.length > 0) {
              Text(group.title)
                .fontSize(13)
                .fontColor(HaColors.SETTINGS_ACCENT)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .padding({ left: 20, right: 20, top: 18, bottom: 8 })
            }

            ForEach(group.options, (option: SettingChoiceOption) => {
              this.optionRow(option);
            }, (option: SettingChoiceOption) => option.value)
          }, (group: SettingChoiceGroup) => group.title)

          Row()
            .width('100%')
            .height(8)
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxHeight: 360 })
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .backgroundColor(HaTheme.surface(this.dark))
  }
}
