import 'package:flutter/widgets.dart';

/// Stub RevenueCat service.
///
/// Replace this with real RevenueCat SDK calls when ready:
/// 1. Uncomment `purchases_flutter` in pubspec.yaml
/// 2. Replace methods below with actual SDK calls
/// 3. Set your RevenueCat API key in .env
///
/// Every gate returns `true` so the app is fully usable without a subscription.
class RevenueCatService {
  RevenueCatService._();

  /// No-op — RevenueCat SDK not loaded.
  static Future<void> init() async {
    // TODO: Initialize Purchases.configure(PurchasesConfiguration('YOUR_API_KEY'))
  }

  /// Always grants access while RevenueCat is disabled.
  static Future<bool> hasAccess() async => true;

  /// No-op — paywall cannot be shown without the SDK.
  static Future<void> showPaywall(BuildContext context) async {}

  /// No-op — nothing to restore.
  static Future<void> restore() async {}
}
