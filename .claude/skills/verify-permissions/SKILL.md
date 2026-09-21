---
name: verify-permissions
description: Diffs actually-used platform APIs against declared Info.plist/AndroidManifest permission strings
---

# Verify Permissions

Checks that platform permission declarations match what the app's Dart
code actually uses — catches both "used but not declared" (crashes/store
rejection) and "declared but not used" (unnecessary privacy exposure,
Play Data Safety over-disclosure).

1. **Camera/photo library** — if `image_picker` is used anywhere in
   `lib/` (grep `ImagePicker(` or `image_upload_service.dart`), confirm
   `ios/Runner/Info.plist` has `NSCameraUsageDescription` +
   `NSPhotoLibraryUsageDescription`, and
   `android/app/src/main/AndroidManifest.xml` has
   `android.permission.CAMERA`. If declared but `image_picker` isn't
   actually used anywhere, flag the declaration as removable.
2. **Location** — if `geolocator`/`geocoding` are used
   (`lib/core/location/location_service.dart`), confirm
   `NSLocationWhenInUseUsageDescription` (iOS) and
   `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` (Android) are present.
3. **Push notifications** — if OneSignal is present, Android doesn't need
   an explicit permission declaration pre-Android 13, but Android 13+
   requires `POST_NOTIFICATIONS` — check it's present if `targetSdk >= 33`.
4. **Network/internet** — Android's `INTERNET` permission is implied by
   Flutter's own manifest merge in most setups; only flag if genuinely
   missing (rare).
5. **Unused permissions** — for every permission string found in
   `Info.plist`/`AndroidManifest.xml`, confirm there's a corresponding
   package/API actually used in `lib/`. Flag anything declared but dead —
   it inflates the Play Data Safety form and Apple's App Privacy
   questionnaire for no reason.
6. Cross-check against `TODO.md`'s "Play Data Safety" section — the data
   types listed there should match what's actually collected per this
   audit, not just what was selected in the wizard (code can diverge from
   wizard-time answers after manual edits).

Report each check as pass/fail with the specific plist/manifest key or
missing declaration.
