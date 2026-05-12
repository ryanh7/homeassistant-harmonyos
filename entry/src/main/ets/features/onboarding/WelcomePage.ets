import { HaLogo } from '../../shared/components/HaLogo';
import { PrimaryButton } from '../../shared/components/PrimaryButton';
import { HaColors } from '../../shared/constants/HaStyle';
import { OnboardingUiConfig } from '../../shared/constants/OnboardingUiConfig';
import { Localization } from '../../shared/i18n/Localization';

@Component
export struct WelcomePage {
  @Prop
  contentMaxWidth: number = OnboardingUiConfig.contentMaxWidth;
  onConnect: () => void = () => {};
  onLearnMore: () => void = () => {};

  build() {
    Scroll() {
      Column({ space: OnboardingUiConfig.pageColumnSpace }) {
        Blank()
          .layoutWeight(0.28)

        HaLogo({ logoSize: 120 })

        Column({ space: OnboardingUiConfig.welcomeTextSpace }) {
          Text(Localization.t('onboarding_welcome_title'))
            .fontSize(OnboardingUiConfig.titleSize)
            .fontWeight(FontWeight.Medium)
            .fontColor(HaColors.TEXT_PRIMARY)
            .lineHeight(OnboardingUiConfig.titleLineHeight)
            .textAlign(TextAlign.Center)
            .constraintSize({ maxWidth: this.contentMaxWidth })
            .width('100%')

          Text(Localization.t('onboarding_welcome_body'))
            .fontSize(OnboardingUiConfig.bodySize)
            .fontColor(HaColors.TEXT_SECONDARY)
            .lineHeight(OnboardingUiConfig.bodyLineHeight)
            .textAlign(TextAlign.Center)
            .constraintSize({ maxWidth: this.contentMaxWidth })
            .width('100%')
        }
        .width('100%')

        Blank()
          .layoutWeight(0.72)

        PrimaryButton({
          text: Localization.t('onboarding_connect'),
          maxWidth: this.contentMaxWidth,
          action: this.onConnect
        })

        PrimaryButton({
          text: Localization.t('onboarding_learn_more'),
          filled: false,
          maxWidth: this.contentMaxWidth,
          action: this.onLearnMore
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
