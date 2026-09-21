---
name: verify-maintenance-gate
description: Confirms AppGate/NoConnectionGate are mounted and the configured table name matches across code + docs
---

# Verify Maintenance Gate

Check:

1. **Actually mounted (and nested in the right order)** —
   `lib/bootstrap.dart`'s `MaterialApp.router` `builder:` should wrap `child`
   in `AppGate(...)` (if the maintenance toggle was selected) and/or
   `NoConnectionGate(...)` (if the no-connection toggle was selected). A
   generated service file existing in `lib/core/gate/` or
   `lib/core/connectivity/` with nothing actually referencing it in the
   widget tree is a real, easy-to-miss bug — check the wiring, not just file
   existence. When BOTH are present, read the nesting carefully:
   `NoConnectionGate(child: AppGate(child: child!))` means NoConnectionGate
   is **outermost** — the recommended order (see `no_connection_gate.dart`'s
   doc), so AppGate's Supabase config fetch doesn't run while offline. Report
   the actual outermost widget by parsing the expression, not by guessing;
   flag if AppGate is outermost instead.
2. **Table name consistency** — the string literal passed to
   `SupabaseClientWrapper.db('...')` in
   `lib/core/config/app_config_provider.dart` should exactly match the
   table name documented in `TODO.md`'s maintenance-gate section. If the
   user renamed the table in Supabase but not in code (or vice versa), flag
   it.
3. **Bypass domain still correct** — `lib/core/gate/app_gate.dart`'s
   `email.endsWith('@thecalda.com')` (or whatever domain the user changed
   it to) should match the actual internal team's domain for this project
   — ask if unsure, don't assume `@thecalda.com` is always right for every
   client project built from this template.
4. **Post-login-only is intentional, not a bug** — the gate only applies
   once `SupabaseClientWrapper.auth.currentUser` resolves; logged-out users
   always bypass it. This is deliberate (matches the reference
   implementation this pattern was ported from) — don't "fix" it into a
   pre-login check unless the user explicitly asks for that tradeoff.
5. **Fail-open confirmed** — `appConfigProvider`'s catch block should
   return `AppConfig.defaults` (not rethrow) so a missing table or network
   blip doesn't lock everyone out of the app.
6. **No-connection auto-recovery** — if `NoConnectionGate` is present,
   confirm it's watching a `StreamProvider` (not a one-shot `FutureProvider`)
   so it actually dismisses itself when connectivity returns, rather than
   requiring an app restart.

Report each check as pass/fail with file/line references.
