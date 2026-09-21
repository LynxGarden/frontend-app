/// Stub OneSignal service.
///
/// Replace this with real OneSignal SDK calls when ready:
/// 1. Uncomment `onesignal_flutter` in pubspec.yaml
/// 2. Replace methods below with actual SDK calls
/// 3. Set your OneSignal App ID in .env
class OneSignalService {
  OneSignalService._();

  /// No-op — OneSignal SDK not loaded.
  static Future<void> init() async {
    // TODO: OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!)
  }

  /// No-op — prompt for push notification permission.
  static Future<void> requestPermission() async {
    // TODO: OneSignal.Notifications.requestPermission(true)
  }

  /// No-op — set the external user ID for targeting.
  static Future<void> setUserId(String userId) async {
    // TODO: OneSignal.login(userId)
  }

  /// No-op — clear user on logout.
  static Future<void> clearUser() async {
    // TODO: OneSignal.logout()
  }
}
