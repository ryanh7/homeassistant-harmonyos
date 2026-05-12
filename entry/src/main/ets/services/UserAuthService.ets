import { userAuth } from '@kit.UserAuthenticationKit';
import common from '@ohos.app.ability.common';
import { Localization } from '../shared/i18n/Localization';

export interface UserAuthCheckResult {
  available: boolean;
  message: string;
}

export interface UserAuthPromptResult {
  success: boolean;
  message: string;
  retryable?: boolean;
}

interface UserAuthPlan {
  authTypes: userAuth.UserAuthType[];
  authTrustLevel: userAuth.AuthTrustLevel;
}

export class UserAuthService {
  static lastError: string = '';
  private static currentInstance: userAuth.UserAuthInstance | undefined = undefined;

  private static errorMessage(error: Error | Object | string | number): string {
    if (typeof error === 'string' || typeof error === 'number') {
      return String(error);
    }
    const record = error as Record<string, Object | string | number | boolean>;
    const code = record['code'];
    const message = record['message'];
    const codeText = typeof code === 'number' || typeof code === 'string' ? String(code) : '';
    const messageText = typeof message === 'string' ? message : '';
    if (codeText.length > 0 && messageText.length > 0) {
      return `${codeText}: ${messageText}`;
    }
    if (codeText.length > 0) {
      return codeText;
    }
    if (messageText.length > 0) {
      return messageText;
    }
    try {
      return JSON.stringify(error);
    } catch (_) {
      return 'Unknown authentication error';
    }
  }

  private static availableAuthTypes(authTrustLevel: userAuth.AuthTrustLevel): userAuth.UserAuthType[] {
    const candidates: userAuth.UserAuthType[] = [
      userAuth.UserAuthType.FACE,
      userAuth.UserAuthType.FINGERPRINT,
      userAuth.UserAuthType.PIN
    ];
    const result: userAuth.UserAuthType[] = [];
    let i = 0;
    while (i < candidates.length) {
      try {
        userAuth.getAvailableStatus(candidates[i], authTrustLevel);
        result.push(candidates[i]);
      } catch (_) {
      }
      i += 1;
    }
    return result;
  }

  private static authenticationPlans(): UserAuthPlan[] {
    const trustLevels: userAuth.AuthTrustLevel[] = [
      userAuth.AuthTrustLevel.ATL1,
      userAuth.AuthTrustLevel.ATL2
    ];
    const plans: UserAuthPlan[] = [];
    let i = 0;
    while (i < trustLevels.length) {
      const availableTypes = UserAuthService.availableAuthTypes(trustLevels[i]);
      if (availableTypes.length > 0) {
        plans.push({
          authTypes: availableTypes,
          authTrustLevel: trustLevels[i]
        });
        let j = 0;
        while (j < availableTypes.length) {
          plans.push({
            authTypes: [availableTypes[j]],
            authTrustLevel: trustLevels[i]
          });
          j += 1;
        }
      }
      i += 1;
    }
    return plans;
  }

  private static authenticationPlan(): UserAuthPlan {
    const plans = UserAuthService.authenticationPlans();
    if (plans.length > 0) {
      return plans[0];
    }
    return {
      authTypes: [],
      authTrustLevel: userAuth.AuthTrustLevel.ATL1
    };
  }

  private static runAuthenticationPlan(
    plan: UserAuthPlan,
    title: string,
    uiContext: common.Context | undefined
  ): Promise<UserAuthPromptResult> {
    return new Promise<UserAuthPromptResult>((resolve: (value: UserAuthPromptResult) => void) => {
      try {
        const authParam: userAuth.AuthParam = {
          challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
          authType: plan.authTypes,
          authTrustLevel: plan.authTrustLevel
        };
        const widgetParam: userAuth.WidgetParam = {
          title,
          uiContext
        };
        const instance = userAuth.getUserAuthInstance(authParam, widgetParam);
        UserAuthService.currentInstance = instance;
        const callback: userAuth.IAuthCallback = {
          onResult(result: userAuth.UserAuthResult): void {
            try {
              instance.off('result', callback);
            } catch (_) {
            }
            UserAuthService.currentInstance = undefined;
            const tokenLength = result.token ? result.token.length : 0;
            const success = result.result === userAuth.UserAuthResultCode.SUCCESS || tokenLength > 0;
            UserAuthService.lastError = success ? '' : `Authentication result: ${result.result}`;
            const retryable = !success && result.result === 0 && tokenLength === 0;
            resolve({ success, message: UserAuthService.lastError, retryable });
          }
        };
        instance.on('result', callback);
        instance.start();
      } catch (error) {
        UserAuthService.currentInstance = undefined;
        const message = UserAuthService.errorMessage(error as Error | Object | string | number);
        UserAuthService.lastError = message;
        resolve({ success: false, message });
      }
    });
  }

  private static runAuthenticationPlans(
    plans: UserAuthPlan[],
    index: number,
    title: string,
    uiContext: common.Context | undefined
  ): Promise<UserAuthPromptResult> {
    if (index >= plans.length) {
      const message = UserAuthService.lastError.length > 0 ? UserAuthService.lastError : 'Authentication failed.';
      const result: UserAuthPromptResult = { success: false, message };
      return Promise.resolve(result);
    }
    return UserAuthService.runAuthenticationPlan(plans[index], title, uiContext)
      .then((result: UserAuthPromptResult): Promise<UserAuthPromptResult> => {
        if (result.success || result.retryable !== true || index >= plans.length - 1) {
          return Promise.resolve(result);
        }
        return UserAuthService.runAuthenticationPlans(plans, index + 1, title, uiContext);
      });
  }

  static isAvailable(): boolean {
    return UserAuthService.authenticationPlan().authTypes.length > 0;
  }

  static checkAvailability(): UserAuthCheckResult {
    const plan = UserAuthService.authenticationPlan();
    if (plan.authTypes.length > 0) {
      return { available: true, message: '' };
    }
    return {
      available: false,
      message: Localization.t('auth_no_local_authenticator')
    };
  }

  static authenticate(title: string = 'Unlock Home Assistant', uiContext?: common.Context): Promise<UserAuthPromptResult> {
    const plans = UserAuthService.authenticationPlans();
    if (plans.length === 0) {
      const message = Localization.t('auth_no_local_authenticator');
      UserAuthService.lastError = message;
      const result: UserAuthPromptResult = { success: false, message };
      return Promise.resolve(result);
    }
    return UserAuthService.runAuthenticationPlans(plans, 0, title, uiContext);
  }
}
