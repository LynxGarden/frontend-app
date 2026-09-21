---
name: add-flavor
description: Add a new flavor to a project after initial setup, without rerunning the whole wizard
---

# Add Flavor

Use this when the project already has flavors (or has none yet) and the
user wants to add one more (e.g. adding a `qa` flavor to an existing
`staging`/`prod` setup) without rerunning `dart run bin/setup.dart` and
losing other answers.

This is the post-hoc version of the wizard's flavor generation. **The
authoritative reference is `bin/src/ios_flavors.dart` + `bin/src/flavors.dart`
in the template repo** — mirror exactly what they generate (including the
non-obvious correctness fixes below); read them if unsure. After editing,
run the `verify-flavors` skill and a simulator build to confirm.

1. **Android** (`android/app/build.gradle.kts`): add a `create("{flavor}")`
   block inside `productFlavors { ... }` (add the `flavorDimensions`/
   `productFlavors` wrapper if this is the first flavor) with
   `applicationIdSuffix` or full `applicationId`, `resValue("string",
   "app_name", ...)`, and `manifestPlaceholders["deeplinkScheme"/"deeplinkHost"]`.
   Then **confirm `AndroidManifest.xml` actually consumes** them
   (`${deeplinkScheme}`/`${deeplinkHost}` in the intent-filter, `@string/app_name`
   for the label) — placeholders do nothing if the manifest hardcodes values.
2. **iOS** — hand-editing `project.pbxproj` is the highest-risk step. Generate:
   - `ios/Flutter/{Flavor}.xcconfig` (`PRODUCT_BUNDLE_IDENTIFIER`,
     `BUNDLE_DISPLAY_NAME`, `DEEPLINK_SCHEME`, `DEEPLINK_HOST`,
     `ASSET_CATALOG_APP_ICON_NAME`).
   - `{Flavor}-Debug/-Release/-Profile.xcconfig` wrappers. Each must
     `#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.{buildtype}-{flavor}.xcconfig"`
     then `#include "Generated.xcconfig"` then `#include "{Flavor}.xcconfig"`
     — NOT via `Debug.xcconfig` (so the per-flavor Pods xcconfig links; see
     the Podfile step). Use **valid 24-char hex** object IDs.
   - New `XCBuildConfiguration` entries named `Debug-{flavor}`/`Release-{flavor}`/
     `Profile-{flavor}` at **three** levels and appended to **all three**
     `XCConfigurationList`s: project-level, **Runner target**, AND
     **RunnerTests target** (do NOT skip RunnerTests — a missing config
     there makes CocoaPods abort with "only 1 unique SWIFT_VERSION per
     target"). Project-level configs: **do NOT set `SUPPORTED_PLATFORMS`**
     (that pins device-only and breaks simulator builds — `SDKROOT = iphoneos`
     alone is right). Target configs point `baseConfigurationReference` at
     the flavor xcconfig fileref.
   - Add each new xcconfig **PBXFileReference to the Flutter PBXGroup**
     (they use `sourceTree = "<group>"`; an orphaned fileref makes CocoaPods
     crash with "undefined method 'source_tree'" during `pod install`).
   - A shared scheme `xcshareddata/xcschemes/{flavor}.xcscheme`, cloned from
     `Runner.xcscheme` with every `buildConfiguration` renamed to `-{flavor}`.
   - **Verify**: `plutil -lint ios/Runner.xcodeproj/project.pbxproj` (OK),
     `xcodebuild -list` (lists the new configs + scheme), and
     `xcodebuild -showBuildSettings -scheme {flavor} -configuration Debug-{flavor} -sdk iphonesimulator`
     (resolves the bundle id AND works for the simulator).
3. **Podfile** (`ios/Podfile`): add the flavor's three configs to the
   `project 'Runner', { ... }` build-type map (`'Debug-{flavor}' => :debug`,
   `'Profile-{flavor}' => :release`, `'Release-{flavor}' => :release`) so
   CocoaPods generates the per-flavor `Pods-Runner.*.xcconfig` the wrappers
   include.
4. **Dart entrypoint**: create `lib/main_{flavor}.dart` matching the existing
   entrypoints' style — if `main_staging.dart` calls `bootstrap(envFile: ...)`,
   do the same (`bootstrap(envFile: '.env.{flavor}')`); otherwise clone
   whatever pattern the other `main_*.dart`/`main.dart` uses. Don't assume
   `bootstrap()` exists.
5. **Env**: create a `.env.{flavor}` scaffold with the same keys as the other
   `.env.*` files, AND register it under `flutter: assets:` in `pubspec.yaml`
   (flutter_dotenv loads it from the bundle — an unregistered file throws at
   launch).
6. **`lib/core/config/app_flavor.dart`**: add an `is{Flavor}` getter and the
   flavor to the valid-values list. Create the file if it's somehow missing.
7. Add a `.vscode/launch.json` run config and a `scripts/run-{flavor}.sh`
   wrapper (with the `--flavor`/`-t`/`--dart-define` args like the others).
8. If Codemagic is set up, add `ios-{flavor}`/`android-{flavor}` workflows to
   `codemagic.yaml` mirroring the existing ones, plus a Codemagic env var
   group + keystore (manual dashboard step — note it in `TODO.md`).
9. For a production-intent flavor name (`prod`/`production`/`release`/`live`/
   `main`), default the bundle ID/scheme/host to the *undecorated* values
   (base bundle id, plain scheme/host) — matching the wizard — not
   `{base}.{flavor}` / `{scheme}-{flavor}`.
