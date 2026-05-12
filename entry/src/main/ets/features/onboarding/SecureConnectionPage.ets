import { OnboardingTopBar } from '../../shared/components/OnboardingTopBar';
import { PrimaryButton } from '../../shared/components/PrimaryButton';
import { HaColors } from '../../shared/constants/HaStyle';
import { OnboardingUiConfig } from '../../shared/constants/OnboardingUiConfig';
import { Localization } from '../../shared/i18n/Localization';

@Component
export struct SecureConnectionPage {
  @Prop contentMaxWidth: number = OnboardingUiConfig.contentMaxWidth;
  @Prop haBaseUrl: string = '';
  @Prop secureConnectionChoice: string = '';
  onBack: () => void = () => {};
  onHelp: () => void = () => {};
  onChoiceChange: (value: string) => void = () => {};
  onContinue: () => void = () => {};

  @Builder
  private renderSecureOption(key: string, text: string): void {
    Row({ space: OnboardingUiConfig.optionRowSpace }) {
      Stack() {
        if (this.secureConnectionChoice === key) {
          Circle()
            .width(OnboardingUiConfig.optionRadioInnerSize)
            .height(OnboardingUiConfig.optionRadioInnerSize)
            .fill(HaColors.PRIMARY)
        }
      }
      .width(OnboardingUiConfig.optionRadioOuterSize)
      .height(OnboardingUiConfig.optionRadioOuterSize)
      .borderRadius(OnboardingUiConfig.optionRadioOuterSize / 2)
      .border({
        width: OnboardingUiConfig.optionRadioBorderWidth,
        color: this.secureConnectionChoice === key ? HaColors.PRIMARY : HaColors.TEXT_SECONDARY
      })
      Text(text)
        .fontSize(OnboardingUiConfig.formTextSize)
        .fontColor(HaColors.TEXT_PRIMARY)
        .lineHeight(OnboardingUiConfig.bodyLineHeight)
        .textAlign(TextAlign.Start)
        .layoutWeight(1)
    }
    .width('100%')
    .constraintSize({ maxWidth: this.contentMaxWidth })
    .padding({
      left: OnboardingUiConfig.optionPaddingHorizontal,
      right: OnboardingUiConfig.optionPaddingHorizontal,
      top: OnboardingUiConfig.optionPaddingVertical,
      bottom: OnboardingUiConfig.optionPaddingVertical
    })
    .backgroundColor(HaColors.SURFACE)
    .borderRadius(OnboardingUiConfig.optionRadius)
    .border({ width: 1, color: this.secureConnectionChoice === key ? HaColors.PRIMARY : HaColors.OUTLINE })
    .onClick(() => { this.onChoiceChange(key); })
  }

  @Builder
  private renderInfoNotice(): void {
    Row({ space: OnboardingUiConfig.noticeRowSpace }) {
      Image($r('app.media.ha_ic_info'))
        .width(OnboardingUiConfig.noticeIconSize)
        .height(OnboardingUiConfig.noticeIconSize)
        .objectFit(ImageFit.Contain)
      Text(Localization.t('secure_info'))
        .fontSize(OnboardingUiConfig.auxiliaryTextSize)
        .fontColor(HaColors.TEXT_SECONDARY)
        .lineHeight(OnboardingUiConfig.auxiliaryLineHeight)
        .textAlign(TextAlign.Start)
        .layoutWeight(1)
    }
    .constraintSize({ maxWidth: this.contentMaxWidth })
    .width('100%')
    .padding({
      left: OnboardingUiConfig.noticePaddingHorizontal,
      right: OnboardingUiConfig.noticePaddingHorizontal,
      top: OnboardingUiConfig.noticePaddingVertical,
      bottom: OnboardingUiConfig.noticePaddingVertical
    })
    .backgroundColor(HaColors.SURFACE_MUTED)
    .border({ width: 1, color: HaColors.OUTLINE })
    .borderRadius(OnboardingUiConfig.noticeRadius)
  }

  private bodyText(): string {
    const prefix = this.haBaseUrl.startsWith('http://') ? Localization.t('secure_http_warning') : '';
    return `${prefix}${Localization.t('secure_body_suffix')}`;
  }

  build() {
    Scroll() {
      Column({ space: OnboardingUiConfig.pageColumnSpace }) {
        OnboardingTopBar({ showBack: true, onBack: this.onBack, onHelp: this.onHelp })
        Image($r('app.media.ha_onboarding_secure'))
          .width(OnboardingUiConfig.heroIconSize)
          .height(OnboardingUiConfig.heroIconSize)
          .objectFit(ImageFit.Contain)
          .margin({ top: OnboardingUiConfig.heroTopMargin })
        Text(Localization.t('secure_title'))
          .fontSize(OnboardingUiConfig.titleSize)
          .fontWeight(FontWeight.Medium)
          .fontColor(HaColors.TEXT_PRIMARY)
          .lineHeight(OnboardingUiConfig.titleLineHeight)
          .textAlign(TextAlign.Center)
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
        Text(this.bodyText())
          .fontSize(OnboardingUiConfig.bodySize)
          .fontColor(HaColors.TEXT_SECONDARY)
          .lineHeight(OnboardingUiConfig.bodyLineHeight)
          .textAlign(TextAlign.Center)
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
        Column({ space: OnboardingUiConfig.optionColumnSpace }) {
          this.renderSecureOption('most', Localization.t('secure_option_most'))
          this.renderSecureOption('less', Localization.t('secure_option_less'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        this.renderInfoNotice()
        PrimaryButton({
          text: Localization.t('action_next'),
          enabledValue: this.secureConnectionChoice.length > 0,
          maxWidth: this.contentMaxWidth,
          action: this.onContinue
        })
      }
      .width('100%')
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
