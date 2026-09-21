import 'package:shared_preferences/shared_preferences.dart';

/// Small `shared_preferences` wrapper for non-sensitive flags/preferences
/// (e.g. "has the user seen onboarding", cached UI toggles). For
/// tokens/anything sensitive, use [SecureStorageService] instead — never
/// this class.
class LocalStorageService {
  LocalStorageService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('LocalStorageService.init() must be called before use.');
    }
    return prefs;
  }

  static bool getBool(String key, {bool defaultValue = false}) =>
      _instance.getBool(key) ?? defaultValue;

  static Future<void> setBool(String key, bool value) => _instance.setBool(key, value);

  static String? getString(String key) => _instance.getString(key);

  static Future<void> setString(String key, String value) => _instance.setString(key, value);

  static Future<void> remove(String key) => _instance.remove(key);
}
