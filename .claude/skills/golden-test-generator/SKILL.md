---
name: golden-test-generator
description: Scaffolds a *_golden_test.dart for a given screen using the existing multiDeviceGolden() helper
---

# Golden Test Generator

For a single screen's golden test. To generate a whole feature's test set
(unit + widget + golden + e2e) at once, use `generate-tests` instead.

Only applicable if the test suite toggle was selected — check that
`test/helpers/golden_test_helpers.dart` and `test/helpers/device_sizes.dart`
exist; if not, tell the user to enable the test-suite template first
rather than hand-rolling a parallel helper.

When the user asks for a golden test for a screen (e.g.
`lib/features/settings/presentation/settings_screen.dart`):

1. **Mirror the path** — create
   `test/features/{feature}/presentation/goldens/{screen}_golden_test.dart`,
   matching the existing `test/features/**/presentation/` convention used
   by other tests in this repo.
2. **Identify the screen's meaningful visual states** by reading the
   widget: loading (skeleton via `SkeletonLoader`), empty, error (shown
   via `AppToast`/inline error text), and success/populated. Not every
   screen has all four — a static screen like `SettingsScreen` may only
   need one state; don't fabricate states that don't exist in the code.
3. **Provide real data, not empty widgets** — for `ConsumerWidget`s backed
   by Riverpod providers, override the relevant provider per test case
   (`ProviderScope(overrides: [...])`) with fixture data for each state
   rather than letting it hit a real/loading provider. Check
   `test/helpers/test_helpers.dart` for existing fixture/override
   patterns before inventing new ones.
4. **Wrap in `multiDeviceGolden`** per the existing helper contract:
   ```dart
   testWidgets('SettingsScreen - populated', (tester) async {
     await multiDeviceGolden(tester, 'settings_screen_populated', () {
       return ProviderScope(
         overrides: [/* ... */],
         child: const MaterialApp(home: SettingsScreen()),
       );
     });
   });
   ```
   One `testWidgets` block per visual state, each with its own
   `multiDeviceGolden` name — this fans out across `kAllDevices`
   automatically, don't loop over devices manually.
5. **Naming** — golden file names follow `{name}_{device}.png` per the
   helper's own convention (e.g. `settings_screen_populated_iphone_se.png`)
   and land under `goldens/` next to the test file; don't override the
   path convention.
6. **First run generates, doesn't verify** — remind the user golden files
   must be generated once with `flutter test --update-goldens` before the
   test can pass on CI, and that generated images should be reviewed
   (not blindly committed) since a wrong "golden" locks in a bug.
7. **Don't duplicate coverage** — if `verify-test-coverage` (or a manual
   check) shows this screen already has a golden test, extend it with
   the missing state rather than creating a second file.

After scaffolding, run `flutter test --update-goldens <path>` if the user
wants goldens generated immediately, and tell them to visually review the
output images before committing.
