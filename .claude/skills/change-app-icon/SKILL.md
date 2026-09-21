---
name: change-app-icon
description: Swap the app icon/splash asset and regenerate via flutter_launcher_icons/flutter_native_splash, without rerunning the full wizard
---

# Change App Icon

Use when the project shipped with the Calda logo placeholder (check
`flutter_launcher_icons.yaml`'s `image_path` — if it points at
`templates/branding/calda_logo.svg`, no real icon has been supplied yet)
or when the user just wants to swap in a new icon later.

1. Ask for the new icon source path (should be a square PNG, ideally
   1024×1024, transparent background handled per platform needs).
2. Update `flutter_launcher_icons.yaml`'s `image_path:` (and per-flavor
   paths if the project has flavors — check whether flavor-specific icon
   sets exist under `assets/icons/{flavor}/` or similar; if not, ask
   whether the user wants per-flavor icons or one shared icon).
3. Update `flutter_native_splash.yaml`'s `image:` the same way — ask
   whether the splash should reuse the same asset or a different one
   (logos often need a simplified/monochrome variant for splash screens).
4. Run `dart run flutter_launcher_icons` then
   `dart run flutter_native_splash:create`.
5. Confirm the generated icons look right — check
   `android/app/src/main/res/mipmap-*/ic_launcher.png` and
   `ios/Runner/Assets.xcassets/AppIcon.appiconset/` were actually updated
   (non-trivial file sizes, not blank).
6. If flavors are in use and each has a distinct `ASSET_CATALOG_APP_ICON_NAME`
   in its xcconfig, make sure the icon set name matches what's generated —
   `flutter_launcher_icons` by default writes to the single default
   `AppIcon` set unless configured per-flavor.
