export class CardEventGate {
  private static readonly busyKeys: Set<string> = new Set();
  private static readonly lastFinishedAt: Map<string, number> = new Map();
  private static readonly DROP_WINDOW_MS = 500;

  static tryBegin(key: string): boolean {
    const normalized = key.trim();
    if (normalized.length === 0) {
      return false;
    }
    if (CardEventGate.busyKeys.has(normalized)) {
      return false;
    }
    const lastAt = CardEventGate.lastFinishedAt.get(normalized) ?? 0;
    if (Date.now() - lastAt < CardEventGate.DROP_WINDOW_MS) {
      return false;
    }
    CardEventGate.busyKeys.add(normalized);
    return true;
  }

  static finish(key: string): void {
    const normalized = key.trim();
    if (normalized.length === 0) {
      return;
    }
    CardEventGate.busyKeys.delete(normalized);
    CardEventGate.lastFinishedAt.set(normalized, Date.now());
  }
}
