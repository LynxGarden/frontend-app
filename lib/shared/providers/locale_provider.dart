import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/storage/local_storage_service.dart';

/// The app's UI language override. `null` = follow the device locale.
///
/// Persisted in [LocalStorageService] (non-sensitive), read at startup and fed
/// into `MaterialApp.locale`. The Settings language picker updates it.
class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    try {
      final code = LocalStorageService.getString(_key);
      return (code == null || code.isEmpty) ? null : Locale(code);
    } catch (_) {
      // Storage not initialised (e.g. tests) → follow the device locale.
      return null;
    }
  }

  /// Sets (or clears, when [locale] is null) the language override.
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await LocalStorageService.remove(_key);
    } else {
      await LocalStorageService.setString(_key, locale.languageCode);
    }
    state = locale;
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
