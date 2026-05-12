import common from '@ohos.app.ability.common';
import { Want } from '@kit.AbilityKit';
import { formBindingData } from '@kit.FormKit';
import { CardFormWantParser } from './CardFormWantParser';
import { CardRuntimeRepository } from './CardRuntimeRepository';

export class CardFormService {
  static addForm(context: common.Context, want: Want): formBindingData.FormBindingData {
    return CardRuntimeRepository.addForm(
      context,
      CardFormWantParser.formId(want),
      CardFormWantParser.formName(want),
      CardFormWantParser.formDimension(want)
    );
  }

  static castToNormalForm(_context: common.Context, _formId: string): void {
  }

  static updateForm(context: common.Context, formId: string): void {
    CardRuntimeRepository.updateForm(context, formId).catch((): void => {});
  }

  static handleFormEvent(context: common.Context, formId: string, message: string): void {
    CardRuntimeRepository.handleEvent(context, formId, message);
  }

  static removeForm(context: common.Context, formId: string): void {
    CardRuntimeRepository.removeForm(context, formId).catch((): void => {});
  }

  static async refreshRegisteredForms(context: common.Context): Promise<void> {
    await CardRuntimeRepository.refreshRegisteredForms(context);
  }

  static async hasRegisteredForms(context: common.Context): Promise<boolean> {
    return CardRuntimeRepository.hasRegisteredForms(context);
  }
}
