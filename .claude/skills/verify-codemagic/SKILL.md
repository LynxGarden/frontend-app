---
name: verify-codemagic
description: Validates codemagic.yaml against the project's declared flavors/integrations, catching drift
---

# Verify Codemagic

No official Codemagic Claude skill/plugin exists (only unofficial
community MCP servers, which don't audit code) — this stays fully in
scope for this template.

Check `codemagic.yaml` against the actual project state:

1. **Flavor coverage** — every flavor in `lib/core/config/app_flavor.dart`
   (or the `.env.*` files / `main_*.dart` entrypoints) should have a
   matching `ios-{flavor}`/`android-{flavor}` workflow. Flag any flavor
   missing a workflow, or any workflow referencing a flavor that no longer
   exists (stale after a rename/removal).
2. **Env var groups match enabled integrations** — cross-check the
   `echo "X=$X"` lines in each `write_env_*` script anchor against the keys
   in `.env.example` / `.env.<flavor>` and the uncommented integration deps
   in `pubspec.yaml` (e.g. if RevenueCat is enabled, both
   `REVENUECAT_IOS_API_KEY` and `REVENUECAT_ANDROID_API_KEY` should be
   written; if Sentry was added after the fact, `SENTRY_DSN` should too).
   **Exception:** `REVENUECAT_TEST_MODE` is a runtime bypass flag that must
   NOT be written by CI (its absence in prod = test mode off, the desired
   behavior) — don't flag it as a missing key.
3. **Google Play publishing block present** — every `android-*` workflow
   should have a `publishing.google_play` block with
   `credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` and a `track:` — flag
   if missing (this was the exact manual-AAB-upload pain point this
   template's Codemagic support was built to close).
4. **App Store Connect publishing block present** — every `ios-*` workflow
   should have `publishing.app_store_connect` with `submit_to_testflight: true`.
5. **Bundle-ID / applicationId drift** — the `BUNDLE_ID` var in each
   `ios-*` workflow and the keystore reference in each `android-*`
   workflow should match the actual bundle ID for that flavor (check
   `ios/Flutter/{Flavor}.xcconfig` and `android/app/build.gradle.kts`'s
   `productFlavors` block) — this exact class of bug (a stray hyphen in an
   Android `applicationId`) is what motivated rebuilding this template's
   wizard in the first place.
6. **Test workflow exists if the test suite is present** — if `test/` has
   real tests (not just the removed stock counter test), `codemagic.yaml`
   should have a `test:` workflow running `flutter test`.
7. **Shorebird consistency** — if `shorebird.yaml` exists, every flavor
   should have both a release and (if `shorebird.yaml`'s app IDs are real,
   not placeholders) a `shorebird-patch-{flavor}-{platform}` workflow. If
   the app IDs are still the wizard placeholders, note (do not fail) that
   release/patch workflows will error until `shorebird init` is run — that's
   the expected pre-init state.

Report each check as pass/fail with the specific YAML key path for any failure.
