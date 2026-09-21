import 'package:flutter/widgets.dart';

/// Mixin for `State` classes that need to react to the app moving to/from
/// the background, without hand-rolling a `WidgetsBindingObserver` each
/// time. Override [onResumed]/[onPaused] instead of [didChangeAppLifecycleState].
///
/// Typical uses: flush a [Debouncer] on background, re-check a permission
/// (location, notifications) on resume after the user visits system Settings.
mixin AppLifecycleAwareMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
      case AppLifecycleState.paused:
        onPaused();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Called when the app returns to the foreground.
  void onResumed() {}

  /// Called when the app moves to the background.
  void onPaused() {}

  // Unused WidgetsBindingObserver members — no-ops so classes mixing this
  // in don't have to implement the whole interface.
  @override
  void didChangeAccessibilityFeatures() {}
  @override
  void didChangeLocales(List<Locale>? locales) {}
  @override
  void didChangeMetrics() {}
  @override
  void didChangePlatformBrightness() {}
  @override
  void didChangeTextScaleFactor() {}
  @override
  void didHaveMemoryPressure() {}
  @override
  Future<bool> didPopRoute() async => false;
  @override
  Future<bool> didPushRoute(String route) async => false;
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async => false;
}
