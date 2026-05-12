import { HaColors } from '../constants/HaStyle';
import { OnboardingUiConfig } from '../constants/OnboardingUiConfig';

@Component
export struct OnboardingTopBar {
  @Prop
  showBack: boolean = true;
  @Prop
  leadingIcon: Resource = $r('sys.symbol.arrow_left');
  onBack: () => void = () => {};
  onHelp: () => void = () => {};

  build() {
    Row({ space: OnboardingUiConfig.topBarSpace }) {
      if (this.showBack) {
        Stack() {
          SymbolGlyph(this.leadingIcon)
            .width(OnboardingUiConfig.topBarIconSize)
            .height(OnboardingUiConfig.topBarIconSize)
            .fontSize(OnboardingUiConfig.topBarIconSize)
            .fontColor([HaColors.TEXT_PRIMARY])
        }
        .width(OnboardingUiConfig.topBarButtonSize)
        .height(OnboardingUiConfig.topBarButtonSize)
        .borderRadius(OnboardingUiConfig.topBarButtonSize / 2)
        .onClick(() => {
          this.onBack();
        })
      } else {
        Blank()
          .width(OnboardingUiConfig.topBarButtonSize)
          .height(OnboardingUiConfig.topBarButtonSize)
      }

      Blank()
        .layoutWeight(1)

      Stack() {
        SymbolGlyph($r('sys.symbol.questionmark_circle'))
          .width(OnboardingUiConfig.topBarIconSize)
          .height(OnboardingUiConfig.topBarIconSize)
          .fontSize(OnboardingUiConfig.topBarIconSize)
          .fontColor([HaColors.TEXT_PRIMARY])
      }
      .width(OnboardingUiConfig.topBarButtonSize)
      .height(OnboardingUiConfig.topBarButtonSize)
      .borderRadius(OnboardingUiConfig.topBarButtonSize / 2)
      .onClick(() => {
        this.onHelp();
      })
    }
    .width('100%')
    .height(OnboardingUiConfig.topBarHeight)
    .alignItems(VerticalAlign.Center)
  }
}
