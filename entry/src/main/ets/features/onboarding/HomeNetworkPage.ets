import { OnboardingTopBar } from '../../shared/components/OnboardingTopBar';
import { PrimaryButton } from '../../shared/components/PrimaryButton';
import { HaColors } from '../../shared/constants/HaStyle';
import { OnboardingUiConfig } from '../../shared/constants/OnboardingUiConfig';
import { Localization } from '../../shared/i18n/Localization';
import { HaTheme } from '../../shared/theme/HaTheme';
import { NetworkService } from '../../services/NetworkService';
import { SettingsUiConfig } from '../settings/components/SettingsUiConfig';

@Component
export struct HomeNetworkPage {
  @Prop contentMaxWidth: number = OnboardingUiConfig.contentMaxWidth;
  @Prop homeNetworkName: string = '';
  @State currentWifiSsid: string = '';
  @State currentWifiConnected: boolean = false;
  onBack: () => void = () => {};
  onHelp: () => void = () => {};
  onHomeNetworkNameChange: (value: string) => void = () => {};
  onContinue: () => void = () => {};

  aboutToAppear(): void {
    this.refreshCurrentWifi();
  }

  private refreshCurrentWifi(): void {
    NetworkService.wirelessSnapshot()
      .then((snapshot): void => {
        this.currentWifiConnected = snapshot.connected;
        this.currentWifiSsid = snapshot.ssid;
      })
      .catch((): void => {
        this.currentWifiConnected = false;
        this.currentWifiSsid = '';
      });
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
        Text(Localization.t('home_network_title'))
          .fontSize(OnboardingUiConfig.titleSize)
          .fontWeight(FontWeight.Medium)
          .fontColor(HaColors.TEXT_PRIMARY)
          .lineHeight(OnboardingUiConfig.titleLineHeight)
          .textAlign(TextAlign.Center)
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
        Text(Localization.t('home_network_body'))
          .fontSize(OnboardingUiConfig.bodySize)
          .fontColor(HaColors.TEXT_SECONDARY)
          .lineHeight(OnboardingUiConfig.bodyLineHeight)
          .textAlign(TextAlign.Center)
          .constraintSize({ maxWidth: this.contentMaxWidth })
          .width('100%')
        TextInput({ placeholder: Localization.t('home_network_placeholder'), text: this.homeNetworkName })
          .onChange((v: string) => { this.onHomeNetworkNameChange(v); })
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
        Row({ space: OnboardingUiConfig.noticeRowSpace }) {
          Column({ space: 2 }) {
            Text(Localization.t('home_network_current_wifi'))
              .fontSize(OnboardingUiConfig.auxiliaryTextSize)
              .fontColor(HaColors.TEXT_SECONDARY)
              .width('100%')
            Text(this.currentWifiConnected && this.currentWifiSsid.length > 0
              ? this.currentWifiSsid
              : Localization.t('home_network_wifi_not_connected'))
              .fontSize(OnboardingUiConfig.formTextSize)
              .fontColor(HaColors.TEXT_PRIMARY)
              .width('100%')
          }
          .layoutWeight(1)

          Button(Localization.t('home_network_use_current_wifi'))
            .height(40)
            .fontSize(OnboardingUiConfig.auxiliaryTextSize)
            .fontColor(this.currentWifiConnected && this.currentWifiSsid.length > 0 ? HaColors.PRIMARY : HaColors.TEXT_SECONDARY)
            .backgroundColor(HaColors.SURFACE)
            .borderRadius(8)
            .enabled(this.currentWifiConnected && this.currentWifiSsid.length > 0)
            .onClick(() => {
              this.onHomeNetworkNameChange(this.currentWifiSsid);
            })
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
        Row({ space: OnboardingUiConfig.noticeRowSpace }) {
          Image($r('app.media.ha_ic_info'))
            .width(OnboardingUiConfig.noticeIconSize)
            .height(OnboardingUiConfig.noticeIconSize)
            .objectFit(ImageFit.Contain)
          Text(Localization.t('home_network_notice'))
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
        Blank().layoutWeight(1)
        PrimaryButton({
          text: Localization.t('action_next'),
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
