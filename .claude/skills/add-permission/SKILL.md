---
name: add-permission
description: Adds an iOS/Android runtime permission (Info.plist usage string + AndroidManifest uses-permission + any package) the way the setup wizard does, without duplicating existing declarations
---

# Add Permission

Wires a platform permission into an already-generated project the same way
`bin/src/permissions.dart` does at setup time. Use this when the app needs
a capability that wasn't selected in the wizard (microphone, contacts,
Face ID, calendar, …).

The wizard only ships toggles for photo/camera, location, and contacts —
this skill covers those **and everything else** as a one-off edit. For
checking that declarations match actual code usage, use the
`verify-permissions` skill instead (this one adds; that one audits).

## How to add one

For the requested permission:

1. **iOS** — append the usage-description key(s) to
   `ios/Runner/Info.plist`, immediately before the closing
   `</dict>\n</plist>`. **Skip if the key already exists** (grep first).
   Write a concrete, user-facing reason string — App Store review rejects
   vague ones like "This app needs access." Say *why*.
2. **Android** — add the `<uses-permission .../>` line just before
   `<application` in `android/app/src/main/AndroidManifest.xml`. **Skip if
   already present.** The manifest is shared across flavors, so add it once.
3. **Package** — if the permission implies a plugin that isn't in
   `pubspec.yaml` yet (e.g. `local_auth`, `flutter_contacts`), add it and
   run `flutter pub get`. Some permissions need no package (e.g. ATT via
   `app_tracking_transparency`, contacts via `flutter_contacts`).
4. **Flavors note** — `Info.plist` and `AndroidManifest.xml` are shared by
   all flavors, so a permission is declared once and applies everywhere.
   Nothing per-flavor to do.
5. **Data Safety / App Privacy** — a new permission almost always means new
   data collection. Add it to the "Play Data Safety" / Apple App Privacy
   items in `TODO.md` / `TODO_PRODUCTION.md` so the store forms stay
   truthful.
6. Run `verify-permissions` afterward to confirm the declaration matches
   real usage and nothing is left dangling.

Match the existing style in `permissions.dart`: tab-indented plist keys,
four-space-indented manifest lines, idempotent (never double-add).

## Reference

| Permission | iOS key(s) | Android `uses-permission` | Typical package |
|---|---|---|---|
| Camera + Photos | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` | `CAMERA` | `image_picker` |
| Save to Photos | `NSPhotoLibraryAddUsageDescription` | `WRITE_EXTERNAL_STORAGE` (legacy) | `image_gallery_saver` |
| Location (in use) | `NSLocationWhenInUseUsageDescription` | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | `geolocator` |
| Location (background) | `NSLocationAlwaysAndWhenInUseUsageDescription` | `ACCESS_BACKGROUND_LOCATION` | `geolocator` |
| Contacts | `NSContactsUsageDescription` | `READ_CONTACTS` | `flutter_contacts` |
| Microphone | `NSMicrophoneUsageDescription` | `RECORD_AUDIO` | `record` / `speech_to_text` |
| Speech recognition | `NSSpeechRecognitionUsageDescription` | (uses `RECORD_AUDIO`) | `speech_to_text` |
| Face ID / biometrics | `NSFaceIDUsageDescription` | `USE_BIOMETRIC` | `local_auth` |
| Calendar | `NSCalendarsUsageDescription` | `READ_CALENDAR`, `WRITE_CALENDAR` | `device_calendar` |
| Reminders (iOS) | `NSRemindersUsageDescription` | — | `device_calendar` |
| Bluetooth | `NSBluetoothAlwaysUsageDescription` | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` | `flutter_blue_plus` |
| Motion & fitness | `NSMotionUsageDescription` | `ACTIVITY_RECOGNITION` | `pedometer` |
| App Tracking Transparency | `NSUserTrackingUsageDescription` | `com.google.android.gms.permission.AD_ID` | `app_tracking_transparency` |
| Local network (iOS) | `NSLocalNetworkUsageDescription` | — | — |
| Notifications (Android 13+) | — | `POST_NOTIFICATIONS` | (often handled by OneSignal) |

If OneSignal is enabled, check its integration before adding
`POST_NOTIFICATIONS` — it may already declare it.
