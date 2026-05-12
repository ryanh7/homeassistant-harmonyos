import { HaLogo } from '../../shared/components/HaLogo';
import { HaColors } from '../../shared/constants/HaStyle';
import { Localization } from '../../shared/i18n/Localization';

export interface WearMenuItem {
  icon: string;
  title: string;
  summary: string;
  enabled: boolean;
}

export function wearMenuItem(icon: string, title: string, summary: string, enabled: boolean = true): WearMenuItem {
  return {
    icon,
    title,
    summary,
    enabled
  };
}

@Component
export struct WearHomePage {
  @Prop
  isSignedIn: boolean = false;
  @Prop
  serverName: string = 'Home Assistant';
  @Prop
  serverUrl: string = '';
  @Prop
  items: WearMenuItem[] = [];
  onPairPhone: () => void = () => {};
  onOpenItem: (item: WearMenuItem) => void = () => {};
  onSwipeBack: () => void = () => {};

  @Builder
  private renderHeader(): void {
    Column({ space: 8 }) {
      HaLogo({ logoSize: 38 })

      Text('Home Assistant')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.isSignedIn ? this.serverName : Localization.t('wear_home_title'))
        .fontSize(12)
        .fontColor('#B6C2C8')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.isSignedIn && this.serverUrl.length > 0) {
        Text(this.serverUrl)
          .fontSize(10)
          .fontColor('#7E8B92')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private renderPairing(): void {
    Column({ space: 10 }) {
      Text(Localization.t('wear_login_required'))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)

      Text(Localization.t('wear_intro'))
        .fontSize(12)
        .fontColor('#B6C2C8')
        .lineHeight(17)
        .textAlign(TextAlign.Center)
        .width('100%')

      Button(Localization.t('wear_phone_setup'))
        .height(40)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#001F2A')
        .backgroundColor(HaColors.PRIMARY)
        .borderRadius(20)
        .onClick(() => {
          this.onPairPhone();
        })
    }
    .width('100%')
  }

  @Builder
  private renderMenuItem(item: WearMenuItem): void {
    Row({ space: 10 }) {
      Text(item.icon)
        .fontSize(15)
        .fontColor(item.enabled ? HaColors.PRIMARY : '#738087')
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.enabled ? '#123B47' : '#1F2528')
        .borderRadius(12)

      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(14)
          .fontColor(item.enabled ? '#FFFFFF' : '#9AA6AC')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (item.summary.length > 0) {
          Text(item.summary)
            .fontSize(10)
            .fontColor('#8A979E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 9, bottom: 9 })
    .backgroundColor('#151A1D')
    .borderRadius(18)
    .opacity(item.enabled ? 1 : 0.72)
    .onClick(() => {
      this.onOpenItem(item);
    })
  }

  @Builder
  private renderMenu(): void {
    Column({ space: 7 }) {
      ForEach(this.items, (item: WearMenuItem) => {
        this.renderMenuItem(item);
      }, (item: WearMenuItem) => item.title)
    }
    .width('100%')
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          this.renderHeader()

          if (this.isSignedIn) {
            this.renderMenu()
          } else {
            this.renderPairing()
          }
        }
        .width('100%')
        .padding({ left: 28, right: 28, top: 34, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 18 })
        .onActionEnd((event: GestureEvent) => {
          if (event.offsetX > 44 || event.offsetX < -44) {
            this.onSwipeBack();
          }
        })
    )
  }
}
