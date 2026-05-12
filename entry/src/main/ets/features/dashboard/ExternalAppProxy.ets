export class ExternalAppProxy {
  private getAuthHandler: (payload: Object | string) => void;
  private revokeAuthHandler: (payload: Object | string) => void;
  private externalBusHandler: (payload: Object | string) => void;

  constructor(
    getAuthHandler: (payload: Object | string) => void,
    revokeAuthHandler: (payload: Object | string) => void,
    externalBusHandler: (payload: Object | string) => void
  ) {
    this.getAuthHandler = getAuthHandler;
    this.revokeAuthHandler = revokeAuthHandler;
    this.externalBusHandler = externalBusHandler;
  }

  getExternalAuth(payload: Object | string): void {
    this.getAuthHandler(payload);
  }

  revokeExternalAuth(payload: Object | string): void {
    this.revokeAuthHandler(payload);
  }

  externalBus(payload: Object | string): void {
    this.externalBusHandler(payload);
  }
}
