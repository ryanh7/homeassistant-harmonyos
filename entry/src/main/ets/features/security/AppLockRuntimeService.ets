import common from '@ohos.app.ability.common';
import { Localization } from '../../shared/i18n/Localization';
import { UserAuthPromptResult, UserAuthService } from '../../services/UserAuthService';

export class AppLockRuntimeService {
  static shouldLock(enabled: boolean, signedIn: boolean): boolean {
    return enabled && signedIn;
  }

  static async authenticateUnlock(context: common.Context): Promise<UserAuthPromptResult> {
    return UserAuthService.authenticate(Localization.t('app_lock_auth_unlock_title'), context);
  }

  static async authenticateEnable(context: common.Context): Promise<UserAuthPromptResult> {
    return UserAuthService.authenticate(Localization.t('app_lock_auth_enable_title'), context);
  }
}
