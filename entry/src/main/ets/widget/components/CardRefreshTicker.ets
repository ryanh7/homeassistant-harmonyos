import { CARD_TICK_REFRESH_EVENT } from '../../features/cards/CardRuntimeEvents';

@Component
export struct CardRefreshTicker {
  @Prop updateFrequency: string = 'default';

  build() {
    if (this.shouldTick()) {
      TextClock()
        .format('mm')
        .fontSize(1)
        .fontColor('#00000000')
        .backgroundColor('#00000000')
        .width(1)
        .height(1)
        .opacity(0)
        .onDateChange((): void => {
          if (this.shouldPostTick()) {
            this.postTick();
          }
        })
    }
  }

  private shouldTick(): boolean {
    return this.updateFrequency === 'fast' || this.updateFrequency === 'normal';
  }

  private shouldPostTick(): boolean {
    if (this.updateFrequency === 'fast') {
      return true;
    }
    return new Date().getMinutes() % 3 === 0;
  }

  private postTick(): void {
    postCardAction(this, {
      action: 'message',
      params: {
        event: CARD_TICK_REFRESH_EVENT
      }
    });
  }
}
