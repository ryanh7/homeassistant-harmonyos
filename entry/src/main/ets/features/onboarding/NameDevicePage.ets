import { OnboardingTopBar } from '../../shared/components/OnboardingTopBar';
import { PrimaryButton } from '../../shared/components/PrimaryButton';
import { HaColors } from '../../shared/constants/HaStyle';
import { OnboardingUiConfig } from '../../shared/constants/OnboardingUiConfig';
import { Localization } from '../../shared/i18n/Localization';
import { HaTheme } from '../../shared/theme/HaTheme';
import { SettingsUiConfig } from '../settings/components/SettingsUiConfig';

@Component
export struct NameDevicePage {
  @Prop contentMaxWidth: number = OnboardingUiConfig.contentMaxWidth;
  @Prop deviceName: string = '';
  onBack: () => void = () => {};
  onHelp: () => void = () => {};
  onDeviceNameChange: (value: string) => void = () => {};
  onContinue: () => void = () => {};

  build() {
    Scroll() {
      Column({ space: OnboardingUiConfig.pageColumnSpace }) {
        OnboardingTopBar({ showBack: true, onBack: this.onBack, onHelp: this.onHelp })
        Image($r('app.media.ha_onboarding_name'))
          .width(OnboardingUiConfig.heroIconSize)
          .height(OnboardingUiConfig.heroIconSize)
          .objectFit(ImageFit.Contain)
          .margin({ top: OnboardingUiConfig.heroTopMargin })
        Text(Localization.t('name_device_title'))
          .fontSize(OnboardingUiConfig.titleSize)
          .fontWeight(FontWeight.Medium)
          .fontColor(HaColors.TEXT_PRIMARY)
          .lineHeight(OnboardingUiConfig.titleLineHeight)
          .textAlign(TextAlign.Center)
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
        Text(Localization.t('name_device_body'))
          .fontSize(OnboardingUiConfig.bodySize)
          .fontColor(HaColors.TEXT_SECONDARY)
          .lineHeight(OnboardingUiConfig.bodyLineHeight)
          .textAlign(TextAlign.Center)
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
        TextInput({ text: this.deviceName })
          .onChange((v: string) => { this.onDeviceNameChange(v); })
          .type(InputType.Normal)
          .height(SettingsUiConfig.formInputHeight)
          .fontSize(OnboardingUiConfig.formTextSize)
          .fontColor(HaTheme.textPrimary(false))
          .backgroundColor(HaTheme.surface(false))
          .borderRadius(SettingsUiConfig.formInputRadius)
          .border({ width: SettingsUiConfig.formInputBorderWidth, color: HaTheme.outline(false) })
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
          .cancelButton({ style: CancelButtonStyle.CONSTANT })
        Blank().layoutWeight(1)
        PrimaryButton({
          text: Localization.t('action_save'),
          enabledValue: this.deviceName.trim().length > 0,
          maxWidth: this.contentMaxWidth,
          action: this.onContinue
        })
      }
      .width('100%')
      .height('100%')
      .padding({
        left: OnboardingUiConfig.pagePadding,
        right: OnboardingUiConfig.pagePadding,
        top: OnboardingUiConfig.pageTopPadding,
        bottom: OnboardingUiConfig.pageBottomPadding
      })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(HaColors.SURFACE)
  }
}
