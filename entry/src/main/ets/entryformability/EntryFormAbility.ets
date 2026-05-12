import common from '@ohos.app.ability.common';
import { Want } from '@kit.AbilityKit';
import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { CardFormService } from '../features/cards/CardFormService';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    return CardFormService.addForm(this.context as common.Context, want);
  }

  onCastToNormalForm(formId: string): void {
    CardFormService.castToNormalForm(this.context as common.Context, formId);
  }

  onUpdateForm(formId: string): void {
    CardFormService.updateForm(this.context as common.Context, formId);
  }

  onFormEvent(formId: string, message: string): void {
    CardFormService.handleFormEvent(this.context as common.Context, formId, message);
  }

  onRemoveForm(formId: string): void {
    CardFormService.removeForm(this.context as common.Context, formId);
  }
}
