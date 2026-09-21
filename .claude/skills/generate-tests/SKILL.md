---
name: generate-tests
description: Generates the full test set for a feature — unit, widget, golden, and (on demand) an e2e flow test — using the template's existing test helpers
---

# Generate Tests

Given a feature (e.g. `journal`, or a path under `lib/features/<feature>/`),
scaffold the tests it needs across all four layers, matching the patterns in
`test/helpers/` and the conventions in `test/README.md`. This supersedes
`golden-test-generator` for whole-feature work; keep that skill for a quick
one-off golden on a single screen.

**Prerequisite:** the test suite must be enabled — confirm
`test/helpers/test_helpers.dart` exists. If not, tell the user to enable the
test suite (re-run setup or copy `templates/optional/test_suite/`) first.

## 1. Inventory the feature

List what actually exists under `lib/features/<feature>/`:
- **Data/logic** — `data/models/*.dart`, `data/*_repository.dart`, providers
  with real branching logic. These get **unit** tests.
- **Screens/widgets** — `presentation/*_screen.dart` and other presentation
  widgets. These get **widget** + **golden** tests.
- **The primary user flow** (e.g. create-entry, edit-profile) — one **e2e**
  test.

Skip declaration-only files (pure constants/theme/config, `*_config.dart`) —
they aren't unit-testable. Treat disabled stub services as out of scope.

## 2. Unit tests → `test/features/<feature>/data/...`

Plain `test()`/`group()`, no widgets. Cover `fromJson`/`toJson`, enum
`fromString` fallbacks, computed getters, and any repository mapping logic.
Build inputs from a `baseJson()` helper and assert field-by-field. Example
shape:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:<package>/features/<feature>/data/models/<model>.dart';

void main() {
  group('<Model>.fromJson', () {
    test('parses scalar fields', () {
      final m = <Model>.fromJson({'id': '1', 'name': 'x'});
      expect(m.id, '1');
    });
    test('falls back on unknown enum values', () { /* ... */ });
  });
}
```

## 3. Widget tests → `test/features/<feature>/presentation/<screen>_test.dart`

Use `pumpApp` from `test/helpers/test_helpers.dart`:
`pumpApp(child, {router, overrides, useScaffold})`. Seed state with Riverpod
`overrides` (override the screen's providers with notifiers pre-seeded to a
known state — the real notifier's constructor usually kicks off an API load
that fails silently in tests). Call `setUpAll(disableGoogleFontsNetwork)` and
`setUp(mockHapticFeedback)`. Assert on visible text/widgets and on
interaction results. Example:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:<package>/features/<feature>/presentation/<screen>.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(disableGoogleFontsNetwork);
  setUp(mockHapticFeedback);

  testWidgets('<Screen> renders its title', (tester) async {
    await tester.pumpWidget(pumpApp(
      const <Screen>(),
      overrides: [/* provider overrides seeded to a known state */],
      useScaffold: false, // if the screen supplies its own Scaffold
    ));
    expect(find.text('<Title>'), findsOneWidget);
  });
}
```

Mocks live in `test/helpers/mocks.dart` (`MockGoRouter`, `MockGoTrueClient`,
`MockSupabaseClient`, `FakeUri`) — extend that file rather than redefining
mocks per test. `registerFallbackValue(FakeUri())` in `setUpAll` if a mock
takes a `Uri`.

## 4. Golden tests → `test/features/<feature>/presentation/goldens/<screen>_golden_test.dart`

Use `multiDeviceGolden(tester, name, builder)` from
`test/helpers/golden_test_helpers.dart` — it loops `kAllDevices` and asserts
`goldens/<name>_<device>.png`. Wrap the builder in `pumpAppForGolden` (plain
`ThemeData`, avoids Google Fonts network). One `testWidgets` per screen state
worth capturing (default / error / empty). Example:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:<package>/features/<feature>/presentation/<screen>.dart';
import '../../../../helpers/golden_test_helpers.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('<screen> default golden', (tester) async {
    await multiDeviceGolden(
      tester,
      '<screen>_default',
      () => pumpAppForGolden(const <Screen>()),
    );
  });
}
```

Generate the baselines with
`flutter test --update-goldens test/features/<feature>/presentation/goldens/`
and tell the user to eyeball the PNGs before committing. `flutter_test_config.dart`
handles font loading automatically.

## 5. E2E test → `integration_test/<feature>/<flow>_flow_test.dart`

E2E runs the **real app against a real backend** (no mocks) via the
`integration_test` package. The template ships no e2e harness by default, so:

**If `integration_test/helpers/e2e_bootstrap.dart` does NOT exist, scaffold
the harness first (one time):**

1. Add to `pubspec.yaml` `dev_dependencies`:
   ```yaml
   integration_test:
     sdk: flutter
   ```
2. Create `integration_test/helpers/e2e_bootstrap.dart`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:integration_test/integration_test.dart';
   import 'package:<package>/bootstrap.dart';

   /// Call once in main() before any group/testWidgets.
   void ensureIntegrationTestBinding() =>
       IntegrationTestWidgetsFlutterBinding.ensureInitialized();

   /// Launches the real app against .env.e2e via the same bootstrap() the
   /// flavor entrypoints use, so the real init sequence runs.
   Future<void> launchApp(WidgetTester tester) async {
     await bootstrap(envFile: '.env.e2e');
     await tester.pumpAndSettle(const Duration(seconds: 2));
   }

   /// Polls real frames until [finder] matches or [timeout] elapses — use
   /// this instead of pumpAndSettle after async/backend work that doesn't
   /// itself schedule frames (splash redirect delay, network calls).
   Future<void> waitFor(
     WidgetTester tester,
     Finder finder, {
     Duration timeout = const Duration(seconds: 20),
     Duration pollInterval = const Duration(milliseconds: 250),
   }) async {
     final deadline = DateTime.now().add(timeout);
     while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
       await tester.pump(pollInterval);
     }
     await tester.pump();
   }

   /// Navigate via GoRouter directly (avoids native tab-bar tap mechanics).
   Future<void> goTo(WidgetTester tester, String path) async {
     final context = tester.element(find.byType(Scaffold).first);
     GoRouter.of(context).go(path);
     await tester.pumpAndSettle();
   }
   ```
   (add `import 'package:go_router/go_router.dart';` for `goTo`.)
3. Create `integration_test/helpers/seeded_login.dart` — signs in as a
   persistent, already-confirmed e2e account read from `.env.e2e`
   (`E2E_TEST_EMAIL`/`E2E_TEST_PASSWORD`) via
   `SupabaseClientWrapper.auth.signInWithPassword`, then `waitFor` a
   home-screen finder. Use in flows that need an authed session but aren't
   testing login itself.
4. Add `.env.e2e` to `.gitignore` (copy of `.env.staging` + `E2E_TEST_EMAIL`
   / `E2E_TEST_PASSWORD`; add `REVENUECAT_TEST_MODE=true` so the paywall is
   bypassed). List these vars in a short `integration_test/README.md`. NEVER
   commit `.env.e2e`.
5. Add `.env.e2e` to `pubspec.yaml` assets (flutter_dotenv loads it from the
   bundle) if running on device.

**Then write the flow test** (`ensureIntegrationTestBinding()` in `main()`,
`launchApp(tester)`, drive the real UI with `waitFor`/finders, assert the
landing screen). Prefer `waitFor(tester, find.text('...'))` over fixed
`pumpAndSettle` guesses. Run with
`flutter test integration_test/<feature>/ --flavor staging -t <entrypoint>`
on a booted simulator/device.

## 6. Wrap up

- Run `flutter test` (unit/widget/golden) and confirm green; report any that
  need real assertions filled in (don't ship always-passing stubs).
- Don't over-generate: one meaningful test per model/screen/flow beats a
  dozen trivial `expect(true, true)` shells.
- Cross-check with `verify-test-coverage` afterward to confirm nothing's
  missed.
