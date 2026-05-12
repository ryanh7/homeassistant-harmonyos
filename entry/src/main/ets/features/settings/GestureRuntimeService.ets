import { CompanionSettingsData, GestureSettingGroup } from './CompanionSettingsData';
import { GestureActionPresenter, GestureActionValues } from './GestureActionPresenter';

export interface GestureRuntimeState {
  gestureSwipeLeftTwoAction: string;
  gestureSwipeLeftThreeAction: string;
  gestureSwipeRightTwoAction: string;
  gestureSwipeRightThreeAction: string;
  gestureSwipeUpTwoAction: string;
  gestureSwipeUpThreeAction: string;
  gestureSwipeDownTwoAction: string;
  gestureSwipeDownThreeAction: string;
}

export class GestureRuntimeService {
  static values(state: GestureRuntimeState): GestureActionValues {
    return {
      swipeLeftTwo: state.gestureSwipeLeftTwoAction,
      swipeLeftThree: state.gestureSwipeLeftThreeAction,
      swipeRightTwo: state.gestureSwipeRightTwoAction,
      swipeRightThree: state.gestureSwipeRightThreeAction,
      swipeUpTwo: state.gestureSwipeUpTwoAction,
      swipeUpThree: state.gestureSwipeUpThreeAction,
      swipeDownTwo: state.gestureSwipeDownTwoAction,
      swipeDownThree: state.gestureSwipeDownThreeAction
    };
  }

  static value(state: GestureRuntimeState, key: string): string {
    return GestureActionPresenter.value(key, GestureRuntimeService.values(state));
  }

  static setValue(state: GestureRuntimeState, key: string, value: string): void {
    const next = GestureActionPresenter.withValue(key, value, GestureRuntimeService.values(state));
    state.gestureSwipeLeftTwoAction = next.swipeLeftTwo;
    state.gestureSwipeLeftThreeAction = next.swipeLeftThree;
    state.gestureSwipeRightTwoAction = next.swipeRightTwo;
    state.gestureSwipeRightThreeAction = next.swipeRightThree;
    state.gestureSwipeUpTwoAction = next.swipeUpTwo;
    state.gestureSwipeUpThreeAction = next.swipeUpThree;
    state.gestureSwipeDownTwoAction = next.swipeDownTwo;
    state.gestureSwipeDownThreeAction = next.swipeDownThree;
  }

  static groups(state: GestureRuntimeState): GestureSettingGroup[] {
    return CompanionSettingsData.gestureGroups((key: string): string => {
      return CompanionSettingsData.gestureActionTitle(GestureRuntimeService.value(state, key));
    });
  }
}
