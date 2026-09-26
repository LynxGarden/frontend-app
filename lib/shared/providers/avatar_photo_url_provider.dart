import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/settings/data/profile_repository.dart';

/// Resolves a private avatar photo storage path into a short-lived signed URL,
/// cached per-path for the session (family). Invalidate after changing a photo.
final avatarPhotoUrlProvider =
    FutureProvider.family<String, String>((ref, storagePath) async {
  return ProfileRepository.avatarPhotoSignedUrl(storagePath);
});
