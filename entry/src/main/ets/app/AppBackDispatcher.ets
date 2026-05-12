export type BackHandler = () => boolean;

export class AppBackDispatcher {
  private handler: BackHandler | undefined = undefined;

  register(handler: BackHandler): void {
    this.handler = handler;
  }

  clear(): void {
    this.handler = undefined;
  }

  handleBack(): boolean {
    if (this.handler) {
      return this.handler();
    }
    return false;
  }
}
