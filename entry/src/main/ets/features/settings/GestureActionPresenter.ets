export interface GestureActionValues {
  swipeLeftTwo: string;
  swipeLeftThree: string;
  swipeRightTwo: string;
  swipeRightThree: string;
  swipeUpTwo: string;
  swipeUpThree: string;
  swipeDownTwo: string;
  swipeDownThree: string;
}

export class GestureActionPresenter {
  static value(key: string, values: GestureActionValues): string {
    if (key === 'swipe_left_two') {
      return values.swipeLeftTwo;
    }
    if (key === 'swipe_left_three') {
      return values.swipeLeftThree;
    }
    if (key === 'swipe_right_two') {
      return values.swipeRightTwo;
    }
    if (key === 'swipe_right_three') {
      return values.swipeRightThree;
    }
    if (key === 'swipe_up_two') {
      return values.swipeUpTwo;
    }
    if (key === 'swipe_up_three') {
      return values.swipeUpThree;
    }
    if (key === 'swipe_down_two') {
      return values.swipeDownTwo;
    }
    if (key === 'swipe_down_three') {
      return values.swipeDownThree;
    }
    return 'none';
  }

  static withValue(key: string, value: string, values: GestureActionValues): GestureActionValues {
    return {
      swipeLeftTwo: key === 'swipe_left_two' ? value : values.swipeLeftTwo,
      swipeLeftThree: key === 'swipe_left_three' ? value : values.swipeLeftThree,
      swipeRightTwo: key === 'swipe_right_two' ? value : values.swipeRightTwo,
      swipeRightThree: key === 'swipe_right_three' ? value : values.swipeRightThree,
      swipeUpTwo: key === 'swipe_up_two' ? value : values.swipeUpTwo,
      swipeUpThree: key === 'swipe_up_three' ? value : values.swipeUpThree,
      swipeDownTwo: key === 'swipe_down_two' ? value : values.swipeDownTwo,
      swipeDownThree: key === 'swipe_down_three' ? value : values.swipeDownThree
    };
  }
}
