import { HaColors } from '../constants/HaStyle';
import { OnboardingUiConfig } from '../constants/OnboardingUiConfig';

@Component
export struct PrimaryButton {
  @Prop
  text: string = '';
  @Prop
  filled: boolean = true;
  @Prop
  enabledValue: boolean = true;
  @Prop
  maxWidth: number = 380;
  @Prop
  heightValue: number = OnboardingUiConfig.buttonHeight;
  action: () => void = () => {};

  build() {
    Button(this.text)
      .width('100%')
      .constraintSize({ maxWidth: this.maxWidth })
      .height(this.heightValue)
      .fontSize(OnboardingUiConfig.buttonTextSize)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.enabledValue ? (this.filled ? HaColors.SURFACE : HaColors.PRIMARY) : (this.filled ? HaColors.DISABLED_ON_LOUD : HaColors.DISABLED_ON_QUIET))
      .backgroundColor(this.filled ? (this.enabledValue ? HaColors.PRIMARY : HaColors.DISABLED_FILL_LOUD) : '#00000000')
      .borderRadius(OnboardingUiConfig.buttonRadius)
      .opacity(1)
      .stateEffect(this.enabledValue)
      .enabled(true)
      .onClick(() => {
        if (this.enabledValue) {
          this.action();
        }
      })
  }
}
