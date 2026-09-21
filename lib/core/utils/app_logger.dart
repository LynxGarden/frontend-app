import 'package:flutter/foundation.dart';

/// Central logger + global error backstop.
///
/// Call [AppLogger.init] once from `bootstrap.dart`/`main.dart` before
/// `runApp()`. It wires `FlutterError.onError` and
/// `PlatformDispatcher.onError` so uncaught errors are always logged
/// instead of silently disappearing — neither reference app this template
/// was built from has a global backstop; every call site does its own
/// try/catch with no fallback.
///
/// If Sentry is enabled (see `sentry_setup`), `bootstrap.dart` assigns
/// [breadcrumbReporter] so every logged error is also forwarded as a
/// Sentry event — this file has no direct dependency on `sentry_flutter`
/// so it works standalone when Sentry isn't selected.
class AppLogger {
  AppLogger._();

  /// Set by bootstrap.dart when Sentry is enabled. Left null otherwise.
  static void Function(Object error, StackTrace stackTrace, {String? hint})? breadcrumbReporter;

  /// Wires the global error handlers and runs [body] (which should call
  /// `runApp(...)`). Call this as the very last thing in `main()`/`bootstrap()`.
  ///
  /// Deliberately does NOT use `runZonedGuarded` — that requires `runApp`
  /// to execute in the same zone as `WidgetsFlutterBinding.ensureInitialized()`,
  /// which is called earlier in `bootstrap()` in the root zone; wrapping
  /// just `runApp` in a child zone here caused a real
  /// "Zone mismatch" warning at runtime. `FlutterError.onError` +
  /// `PlatformDispatcher.onError` alone catch the same uncaught
  /// framework/async errors without that footgun.
  static void runGuarded(void Function() body) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      error(details.exceptionAsString(), error: details.exception, stackTrace: details.stack);
    };

    PlatformDispatcher.instance.onError = (error_, stack) {
      error('Uncaught platform error', error: error_, stackTrace: stack);
      return true;
    };

    body();
  }

  static void debug(String message) {
    if (kDebugMode) debugPrint('[debug] $message');
  }

  static void info(String message) {
    debugPrint('[info] $message');
  }

  static void warning(String message) {
    debugPrint('[warn] $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[error] $message${error != null ? ' — $error' : ''}');
    if (stackTrace != null && kDebugMode) debugPrint(stackTrace.toString());
    if (error != null) {
      breadcrumbReporter?.call(error, stackTrace ?? StackTrace.current, hint: message);
    }
  }
}
