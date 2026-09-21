import 'package:flutter/foundation.dart';

/// Central place for configuring app deep links.
///
/// These values are used when calling Supabase Auth methods that send emails
/// (sign-up confirmation, password reset). Supabase will redirect the user to
/// these URLs after completing the verification flow.
///
/// Override at build time if needed:
///   flutter run --dart-define=APP_DEEPLINK_SCHEME=myapp
///   flutter run --dart-define=APP_DEEPLINK_HOST=myapp.com
///
/// Defaults are Lynx placeholders; set the real host per flavor before store
/// builds (CP6). The scheme must match the iOS URL type / Android intent
/// filter and be listed in Supabase → Authentication → URL Configuration.
class DeepLinkConfig {
  static const String scheme = String.fromEnvironment(
    'APP_DEEPLINK_SCHEME',
    defaultValue: 'lynx',
  );
  static const String host = String.fromEnvironment(
    'APP_DEEPLINK_HOST',
    defaultValue: 'app.lynxgarden.si',
  );

  /// Deep link used after email verification completes.
  static Uri get verificationSuccessful =>
      Uri(scheme: scheme, host: host, path: '/verification-successful');

  /// Deep link used for password reset / recovery flows.
  static Uri get authCallback =>
      Uri(scheme: scheme, host: host, path: '/auth/reset-password');

  /// Redirect target for OAuth (Google/Apple) and email magic links. Supabase
  /// returns to this deep link; the app then resolves the session on /splash.
  static Uri get signInCallback =>
      Uri(scheme: scheme, host: 'login-callback');

  static void debugPrintSummary() {
    if (!kDebugMode) return;
    debugPrint(
      'DeepLinkConfig: scheme=$scheme host=$host '
      'verificationSuccessful=$verificationSuccessful '
      'authCallback=$authCallback',
    );
  }
}
