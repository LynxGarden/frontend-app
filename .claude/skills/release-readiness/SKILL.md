---
name: release-readiness
description: One-shot go/no-go pre-release audit — chains the relevant verify-* / audit skills for a target flavor and aggregates blockers vs warnings
---

# Release Readiness

A single "is this flavor ready to ship?" pass that runs the applicable audits
and aggregates one verdict, instead of remembering to run sixteen skills by
hand. Ask which flavor is being shipped (default: the production flavor) and
scope value checks to that flavor's `.env.<flavor>`.

## What to run

Run only the checks relevant to what's actually enabled (detect from
`pubspec.yaml` deps + `lib/` + `codemagic.yaml`). For each, apply the logic of
the named skill (don't just call it blindly — gather its evidence):

Always:
- **verify-env** (for the target flavor) — wrong key names, dashboard URLs,
  **test-mode flags set in prod** (a hard blocker), missing pubspec asset.
  SEVERITY: only `SUPABASE_URL`+`SUPABASE_PUBLISHABLE_KEY` are hard-required
  (empty = blocker). Empty OneSignal / Sentry / RevenueCat keys on a fresh
  project are 🟡 warnings (each init guards on empty and skips), NOT blockers.
  `REVENUECAT_TEST_MODE=false` in prod is the *correct* value (staging=true is
  expected) — never flag it. Also flag prod reusing the staging Supabase
  project (identical URL+key across flavors) as a warning — verify-env's
  drift check catches this, but call it out explicitly for a release.
- **verify-flavors** — bundle IDs / deep links / configs consistent across
  Android/iOS/Dart.
- **verify-permissions** + **verify-privacy-manifest** — declared permissions
  match used APIs; iOS PrivacyInfo + Play Data Safety consistent.
- **security-review** — no committed secrets/tracked `.env`, no PII logging.
- **audit-todo** (`TODO_PRODUCTION.md`) — code-verifiable items done; flag
  wrong literals in the checklist itself.
- **check-dependencies** — discontinued packages, unbounded `any` constraints,
  dead deps.
- **deep-link-tester** — every declared deep link resolves to a real route.
  SEVERITY: a link the app actually *sends* (via `emailRedirectTo`/`redirectTo`)
  with no matching route = blocker; a declared-but-unused config path with no
  route = warning.
- **claude-md-freshness-check** — (informational) doc vs code drift.

Per enabled integration:
- Supabase/auth → **verify-supabase-auth**
- OneSignal → **verify-onesignal**
- RevenueCat → **verify-revenuecat** (test-mode in prod = blocker)
- Sentry → **verify-sentry** (real DSN present for a real release)
- Stripe → **verify-stripe**
- Codemagic → **verify-codemagic**
- Shorebird → **verify-shorebird** — placeholder app IDs are the expected
  pre-`shorebird init` state, but remain a hard blocker for any Codemagic
  prod run that invokes `shorebird release`.
- Maintenance gate → **verify-maintenance-gate**
- Test suite → **verify-test-coverage**

Also confirm the app **builds** for the target flavor (`flutter build ios
--flavor <f> -t lib/main_<f>.dart --no-codesign` and/or the Android
equivalent) — a green audit on a project that doesn't compile isn't ready.

## Output

One ranked report:
- **🔴 Blockers** — ship-stoppers: test-mode/bypass on in prod, placeholder
  Shorebird IDs, missing/empty required env (Supabase URL+key), a deep link
  with no route, a tracked secret, a permission that'll get the listing
  rejected, build failure.
- **🟡 Warnings** — should-fix-soon: staging/prod value drift, dead deps,
  doc drift, coverage gaps, over-declared permissions.
- **✅ Passed** — list what's clean so the report reads as a real checklist.

End with a one-line verdict: **GO** (no blockers) or **NO-GO** (n blockers).
Cite file:line for every blocker. Don't fix anything here — this reports;
point the user at the specific skill to fix each finding.
