---
name: verify-test-coverage
description: Flags features/screens with no corresponding test file
---

# Verify Test Coverage

Only meaningful if the test suite toggle was selected (check whether
`test/helpers/test_helpers.dart` exists — if not, this skill doesn't apply,
tell the user to consider enabling it instead).

1. Walk `lib/features/**/presentation/*_screen.dart` and for each, check
   whether a matching `test/features/**/presentation/*_screen_test.dart`
   exists. Report screens with zero test coverage. (The `*_screen.dart`
   glob misses screen-level presentation widgets with other names — e.g.
   `onboarding_step.dart`, `utility_message_scaffold.dart`; scan those too
   rather than silently skipping them.)
2. Walk `lib/core/**/*.dart` (services, providers) and flag any with no
   matching test — pure logic (`validation_helpers.dart`-style files) is
   the highest-value, lowest-effort thing to cover; flag those first.
   **Exclude** declaration-only files that aren't unit-testable:
   `app_colors.dart`, `app_spacing.dart`, `app_text_styles.dart`,
   `app_theme.dart`, `*_config.dart`, `app_flavor.dart` — don't report
   these as gaps. Also treat disabled-by-default stub services
   (`revenue_cat_service.dart`, `onesignal_service.dart` when not enabled)
   as expected-uncovered; note them separately from real gaps, not with
   equal weight.
3. Check golden test coverage: for screens with meaningful visual state
   (loading/error/success), confirm a golden test file exists under
   `test/features/**/presentation/goldens/*_golden_test.dart` using
   `multiDeviceGolden()` from `test/helpers/golden_test_helpers.dart`. Note
   the convention: the `goldens/` directory holds the committed `.png`
   baselines, while the golden *test* `.dart` files live alongside them —
   look for the `*_golden_test.dart` files, not just a `goldens/` folder.
4. Don't just count files — spot-check that existing tests actually
   exercise the current behavior (a test file existing doesn't mean it's
   not stale; if a screen's copy/behavior clearly changed since the test
   was written, flag the mismatch instead of just checking a box).
5. Report a prioritized list: pure-logic files with zero tests first
   (cheapest to add, easiest bugs to catch), then screens, then goldens.

Don't write the missing tests yourself unless asked — this skill's job is
to find gaps, not necessarily fill them (though offer to, if the user
wants it).
