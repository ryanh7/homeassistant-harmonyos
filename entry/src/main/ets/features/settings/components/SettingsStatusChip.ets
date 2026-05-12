import { HaColors } from '../../../shared/constants/HaStyle';
import { HaTheme } from '../../../shared/theme/HaTheme';

@Component
export struct SettingsStatusChip {
  @Prop text: string = '';
  @Prop tone: string = 'neutral';
  @StorageLink('appResolvedDark') appResolvedDark: boolean = false;

  private textColor(): string {
    if (this.tone === 'accent') {
      return HaColors.ON_PRIMARY;
    }
    if (this.tone === 'positive') {
      return HaTheme.statusText(this.appResolvedDark, true);
    }
    if (this.tone === 'warning') {
      return HaTheme.warningText(this.appResolvedDark);
    }
    return HaTheme.textSecondary(this.appResolvedDark);
  }

  private fillColor(): string {
    if (this.tone === 'accent') {
      return HaColors.SETTINGS_ACCENT;
    }
    if (this.tone === 'positive') {
      return HaTheme.statusBackground(this.appResolvedDark, true);
    }
    if (this.tone === 'warning') {
      return HaTheme.warningBackground(this.appResolvedDark);
    }
    return HaTheme.statusBackground(this.appResolvedDark);
  }

  build() {
    Text(this.text)
      .fontSize(12)
      .fontColor(this.textColor())
      .fontWeight(this.tone === 'accent' ? FontWeight.Medium : FontWeight.Regular)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor(this.fillColor())
      .borderRadius(8)
  }
}
