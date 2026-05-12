import { Localization } from '../../shared/i18n/Localization';
import { CardRefreshTicker } from '../components/CardRefreshTicker';
import { ServiceCardUiConfig } from '../components/ServiceCardUiConfig';

let harmonyLightServiceCardStorage = new LocalStorage();

@Entry(harmonyLightServiceCardStorage)
@Component
struct HarmonyLightServiceCard {
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('bound') bound: boolean = false;
  @LocalStorageProp('title') title: string = Localization.t('card_light_control_title');
  @LocalStorageProp('subtitle') subtitle: string = Localization.t('card_bind_light_device');
  @LocalStorageProp('state') state: string = 'unknown';
  @LocalStorageProp('updateFrequency') updateFrequency: string = 'default';

  build() {
    Stack() {
      this.cardBackground()

      Column() {
        if (this.bound) {
          this.boundHeader()
        } else {
          this.unboundContent()
        }

        Blank()
          .layoutWeight(1)

        if (this.bound) {
          this.powerButton()
        }
      }
      .width('100%')
      .height('100%')
      .padding(ServiceCardUiConfig.pagePadding)
      .alignItems(HorizontalAlign.Start)

      CardRefreshTicker({ updateFrequency: this.updateFrequency })
        .position({ x: 6, y: 6 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private boundHeader(): void {
    Column({ space: 2 }) {
      Text(this.displayTitle())
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(ServiceCardUiConfig.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(this.displaySubtitle())
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(ServiceCardUiConfig.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private unboundContent(): void {
    Column({ space: ServiceCardUiConfig.defaultVerticalGap }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(ServiceCardUiConfig.defaultSymbolSize)
          .fontWeight(FontWeight.Medium)
          .fontColor([ServiceCardUiConfig.brand])
      }
      .width(ServiceCardUiConfig.iconButtonSize)
      .height(ServiceCardUiConfig.iconButtonSize)
      .borderRadius(ServiceCardUiConfig.iconButtonRadius)
      .backgroundColor(ServiceCardUiConfig.buttonBackground)
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryCardEditAbility',
          params: {
            formId: this.formId,
            'ohos.extra.param.key.edit_form_id': this.formId,
            cardType: 'light'
          }
        });
      })

      Text(Localization.t('card_light_control_title'))
        .fontSize(ServiceCardUiConfig.defaultTitleTextSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(ServiceCardUiConfig.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(Localization.t('card_bind_light_device'))
        .fontSize(ServiceCardUiConfig.defaultSubtitleTextSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(ServiceCardUiConfig.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private cardBackground(): void {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (!this.bound) {
        Image($r('app.media.ha_brand'))
          .width(ServiceCardUiConfig.unboundBrandWatermarkSize)
          .height(ServiceCardUiConfig.unboundBrandWatermarkSize)
          .opacity(0.08)
          .margin({ right: ServiceCardUiConfig.watermarkMargin, bottom: ServiceCardUiConfig.watermarkMargin })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private powerButton(): void {
    Row() {
      Blank()
        .layoutWeight(1)

      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.power'))
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor([this.isOn() ? ServiceCardUiConfig.brand : ServiceCardUiConfig.textSecondary])
      }
      .width(ServiceCardUiConfig.iconButtonSize)
      .height(ServiceCardUiConfig.iconButtonSize)
      .borderRadius(ServiceCardUiConfig.iconButtonRadius)
      .backgroundColor(ServiceCardUiConfig.buttonBackground)
      .onClick(() => {
        postCardAction(this, {
          action: 'message',
          params: {
            event: 'toggle_light'
          }
        });
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Bottom)
  }

  private displayTitle(): string {
    return this.title.trim().length > 0 ? this.title : Localization.t('card_light_control_title');
  }

  private displaySubtitle(): string {
    return this.subtitle.trim().length > 0 ? this.subtitle : Localization.t('state_unknown');
  }

  private isOn(): boolean {
    return this.bound && this.state === 'on';
  }
}
