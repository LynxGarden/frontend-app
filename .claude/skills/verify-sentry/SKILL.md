---
name: verify-sentry
description: Checks Sentry DSN wiring, init guarding, and that no PII is logged
---

# Verify Sentry

Narrow, code-level audit specific to this template's bootstrap pattern —
complements the official Sentry Claude plugin (`claude.com/plugins/sentry`),
which does PR-level code review, not project-specific wiring checks.

Check:

1. **DSN sourced from env, not hardcoded** — `lib/bootstrap.dart` should
   read `dotenv.env['SENTRY_DSN']`, never a literal DSN string committed
   to a tracked file.
2. **Init ordering** — `dotenv.load()` must happen *before*
   `SentryFlutter.init(...)` runs its options callback (the callback reads
   `dotenv.env['SENTRY_DSN']` synchronously) — if someone reordered these
   during a manual edit, Sentry silently gets a null DSN. Check
   `lib/bootstrap.dart`'s `bootstrap()` function order directly.
3. **AppLogger wired** — `AppLogger.breadcrumbReporter` should be assigned
   inside the `SentryFlutter.init` options callback so errors funneled
   through `lib/core/utils/app_logger.dart`'s global handlers actually
   reach Sentry, not just local `debugPrint`.
4. **No PII in captured context** — grep any `Sentry.configureScope`,
   `Sentry.captureMessage`, or manual breadcrumb calls for user email,
   phone number, or other PII passed as tags/extra without scrubbing.
5. **Sample rate sanity** — `options.tracesSampleRate` shouldn't be `1.0`
   in a real production app (quota-burning) unless deliberately chosen;
   flag if it looks like a copy-paste default that was never revisited.
6. **`sentry-setup` skill vs. official plugin** — if the user asks for
   ongoing Sentry work (PR review, error triage), recommend installing the
   official plugin instead of duplicating that here; this skill and
   `sentry-setup` only cover this template's own wiring/DSN provisioning.

Report each check as pass/fail with file/line references.
