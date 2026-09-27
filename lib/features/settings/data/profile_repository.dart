import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';

/// Writes to the signed-in user's `users_data` row (name, DOB, avatar,
/// onboarding) and manages uploaded avatar photos in the private `avatars`
/// bucket. All writes go through RLS (self or staff).
class ProfileRepository {
  const ProfileRepository._();

  static const _avatarBucket = 'avatars';

  /// Updates profile fields. Only non-null args are written; pass
  /// [markOnboarded] to flip `onboarding_complete`.
  static Future<void> updateProfile({
    required String personId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    bool markOnboarded = false,
  }) async {
    final patch = <String, dynamic>{};
    if (firstName != null) patch['first_name'] = firstName.trim();
    if (lastName != null) patch['last_name'] = lastName.trim();
    if (dateOfBirth != null) {
      patch['date_of_birth'] =
          dateOfBirth.toIso8601String().split('T').first; // YYYY-MM-DD
    }
    if (gender != null) patch['gender'] = gender;
    if (markOnboarded) patch['onboarding_complete'] = true;
    if (patch.isEmpty) return;
    try {
      await SupabaseClientWrapper.db('users_data')
          .update(patch)
          .eq('id', personId);
    } catch (e) {
      throw AppException('Could not save your profile.', cause: e);
    }
  }

  /// Sets (or clears, when both null) the avatar. `kind` is 'dicebear' | 'photo'.
  static Future<void> setAvatar({
    required String personId,
    required String? kind,
    required String? value,
  }) async {
    try {
      await SupabaseClientWrapper.db('users_data')
          .update({'avatar_kind': kind, 'avatar_value': value})
          .eq('id', personId);
    } catch (e) {
      throw AppException('Could not update your avatar.', cause: e);
    }
  }

  /// Uploads a photo to `{tenant}/{person}/avatar_<ts>.<ext>` and returns the
  /// storage path (store as `avatar_value` with kind 'photo').
  static Future<String> uploadAvatarPhoto({
    required String tenantId,
    required String personId,
    required File file,
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final ts = DateTime.now().microsecondsSinceEpoch;
      final path = '$tenantId/$personId/avatar_$ts.$ext';
      await SupabaseClientWrapper.storage.from(_avatarBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return path;
    } catch (e) {
      throw AppException('Could not upload the photo.', cause: e);
    }
  }

  /// Short-lived signed URL for a photo avatar (private bucket).
  static Future<String> avatarPhotoSignedUrl(String storagePath,
      {int expiresInSeconds = 3600}) async {
    try {
      return await SupabaseClientWrapper.storage
          .from(_avatarBucket)
          .createSignedUrl(storagePath, expiresInSeconds);
    } catch (e) {
      throw AppException('Could not load the photo.', cause: e);
    }
  }
}
