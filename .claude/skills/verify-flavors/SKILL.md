---
name: verify-flavors
description: Cross-checks Android/iOS/Dart flavor definitions are consistent with each other
---

# Verify Flavors

Flavors span three independent config systems (Gradle, Xcode, Dart) that
can silently drift from each other after manual edits. Cross-check:

1. **Name set matches everywhere** — the flavor names in
   `android/app/build.gradle.kts`'s `productFlavors { create("...") }`
   blocks, the scheme files under
   `ios/Runner.xcodeproj/xcshareddata/xcschemes/*.xcscheme` (excluding
   `Runner.xcscheme` itself), the `lib/main_*.dart` entrypoint filenames,
   and `.env.*` files should all name the exact same set of flavors.
   Flag any flavor present in one system but missing from another.
2. **Bundle ID consistency** — for each flavor, the `applicationIdSuffix`/
   `applicationId` in Gradle should correspond to the
   `PRODUCT_BUNDLE_IDENTIFIER` in that flavor's `ios/Flutter/{Flavor}.xcconfig`
   (same suffix pattern, e.g. both end in `.staging`) unless there's a
   deliberate reason they differ (note it if so, don't just flag it).
3. **Deep link scheme/host consistency** — Gradle's
   `manifestPlaceholders["deeplinkScheme"/"deeplinkHost"]` should match the
   `DEEPLINK_SCHEME`/`DEEPLINK_HOST` values in the matching iOS xcconfig,
   and both should match what's passed via `--dart-define` in
   `codemagic.yaml`/`scripts/run-{flavor}.sh`/`.vscode/launch.json`.
4. **pbxproj build config completeness** — for each flavor, confirm three
   `XCBuildConfiguration` entries exist (`Debug-{flavor}`,
   `Release-{flavor}`, `Profile-{flavor}`) at both the project level and
   the `Runner` target level in `project.pbxproj`, and that both are
   present in their respective `XCConfigurationList`s. Verify with:
   `xcodebuild -list -project ios/Runner.xcodeproj` — every flavor's three
   configs should appear in the "Build Configurations" list, and every
   flavor's scheme should appear in "Schemes".
5. **`app_flavor.dart` getters** — if `lib/core/config/app_flavor.dart` has
   per-flavor convenience getters (`isStaging`, `isProd`, etc.), confirm
   they match the actual flavor names — a renamed flavor with a stale
   getter name is a silent bug.

Report each check as pass/fail with the specific file for any mismatch.
