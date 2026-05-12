// Top-level ArkUI component for the app.
// It owns the root AppRuntimeHost instance and wires it into the visible app surface.
import { AppBackDispatcher } from './AppBackDispatcher';
import { AppRuntimeHost } from './AppRuntimeHost';

@Component
export struct AppShell {
  backDispatcher: AppBackDispatcher | undefined = undefined;

  build() {
    AppRuntimeHost({
      backDispatcher: this.backDispatcher
    })
  }
}
