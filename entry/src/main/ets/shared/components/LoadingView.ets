import { HaLogo } from './HaLogo';
import { HaColors } from '../constants/HaStyle';

@Component
export struct LoadingView {
  @Prop
  logoSize: number = 64;
  @Prop
  progressSize: number = 44;
  @Prop
  progressBottom: number = 120;
  @Prop
  backgroundColorValue: string = '#FFFFFF';
  @Prop
  progressColor: string = HaColors.PRIMARY;

  build() {
    Stack() {
      HaLogo({ logoSize: this.logoSize })
        .align(Alignment.Center)

      LoadingProgress()
        .width(this.progressSize)
        .height(this.progressSize)
        .color(this.progressColor)
        .align(Alignment.Bottom)
        .margin({ bottom: this.progressBottom })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.backgroundColorValue)
  }
}
