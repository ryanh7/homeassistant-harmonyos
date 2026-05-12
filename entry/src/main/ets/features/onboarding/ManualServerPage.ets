import { OnboardingTopBar } from '../../shared/components/OnboardingTopBar';
import { PrimaryButton } from '../../shared/components/PrimaryButton';
import { HaColors } from '../../shared/constants/HaStyle';
import { OnboardingUiConfig } from '../../shared/constants/OnboardingUiConfig';
import { Localization } from '../../shared/i18n/Localization';
import { HaTheme } from '../../shared/theme/HaTheme';
import { SettingsUiConfig } from '../settings/components/SettingsUiConfig';

@Component
export struct ManualServerPage {
  @Prop contentMaxWidth: number = OnboardingUiConfig.contentMaxWidth;
  @Prop manualAddress: string = '';
  @Prop addressInvalid: boolean = false;
  @State private inputFocused: boolean = true;
  onBack: () => void = () => {};
  onHelp: () => void = () => {};
  onAddressChange: (value: string) => void = () => {};
  onConnect: () => void = () => {};
  onSwipeBack: () => void = () => {};

  private inputBorderColor(): string {
    if (this.addressInvalid) {
      return HaColors.ERROR_BORDER;
    }
    return this.inputFocused ? HaColors.PRIMARY_BORDER : HaTheme.outline(false);
  }

  build() {
    Scroll() {
      Column({ space: OnboardingUiConfig.pageColumnSpace }) {
        OnboardingTopBar({ showBack: true, onBack: this.onBack, onHelp: this.onHelp })
        Image($r('app.media.ha_onboarding_manual'))
          .width(OnboardingUiConfig.heroIconSize)
          .height(OnboardingUiConfig.heroIconSize)
          .objectFit(ImageFit.Contain)
          .margin({ top: OnboardingUiConfig.heroTopMargin })
        Text(Localization.t('manual_server_title'))
          .fontSize(OnboardingUiConfig.titleSize)
          .fontWeight(FontWeight.Medium)
          .fontColor(HaColors.TEXT_PRIMARY)
          .lineHeight(OnboardingUiConfig.titleLineHeight)
          .textAlign(TextAlign.Center)
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
        Column({ space: OnboardingUiConfig.optionColumnSpace }) {
          TextInput({ placeholder: 'http://homeassistant.local:8123', text: this.manualAddress })
            .id('manualServerUrlInput')
            .onChange((v: string) => { this.onAddressChange(v); })
            .onFocus(() => { this.inputFocused = true; })
            .onBlur(() => { this.inputFocused = false; })
            .type(InputType.Normal)
            .height(SettingsUiConfig.formInputHeight)
            .fontSize(OnboardingUiConfig.formTextSize)
            .fontColor(HaTheme.textPrimary(false))
            .backgroundColor(HaTheme.surface(false))
            .borderRadius(SettingsUiConfig.formInputRadius)
            .border({ width: SettingsUiConfig.formInputBorderWidth, color: this.inputBorderColor() })
            .caretColor(HaColors.PRIMARY_BORDER)
            .selectedBackgroundColor(HaColors.BRAND)
            .enableKeyboardOnFocus(true)
            .defaultFocus(true)
            .width('100%')
            .cancelButton({ style: CancelButtonStyle.CONSTANT })
          if (this.addressInvalid) {
            Text(Localization.t('manual_server_invalid'))
              .fontSize(OnboardingUiConfig.auxiliaryTextSize)
              .fontColor(HaColors.ERROR)
              .lineHeight(OnboardingUiConfig.auxiliaryLineHeight)
              .width('100%')
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth })
        Blank().layoutWeight(1)
        PrimaryButton({
          text: Localization.t('discovery_connect'),
          enabledValue: this.manualAddress.trim().length > 0,
          maxWidth: this.contentMaxWidth,
          action: this.onConnect
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
      .onAppear(() => {
        setTimeout((): void => {
          focusControl.requestFocus('manualServerUrlInput');
        }, 250);
      })
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(HaColors.SURFACE)
    .gesture(PanGesture({ direction: PanDirection.Horizontal, distance: 24 })
      .onActionEnd((event: GestureEvent) => {
        if (event.offsetX > 60 || event.offsetX < -60) {
          this.onSwipeBack();
        }
      }))
  }
}
