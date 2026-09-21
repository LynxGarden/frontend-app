import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around `flutter_secure_storage` for tokens/sensitive
/// values (Keychain on iOS, EncryptedSharedPreferences on Android).
///
/// Deliberately separate from [LocalStorageService] — that one is for
/// plain, non-sensitive flags/preferences. Nothing sensitive should ever
/// go through `shared_preferences` in plaintext.
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> deleteAll() => _storage.deleteAll();
}
