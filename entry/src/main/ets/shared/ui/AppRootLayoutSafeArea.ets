export class AppRootLayoutSafeArea {
  static nonSafeAreaTypes(): Array<LayoutSafeAreaType> {
    return [LayoutSafeAreaType.SYSTEM];
  }

  static ignoredTopEdges(): Array<LayoutSafeAreaEdge> {
    // Keep the entry root immersive at the status bar; bottom remains system-managed.
    return [LayoutSafeAreaEdge.TOP];
  }
}
