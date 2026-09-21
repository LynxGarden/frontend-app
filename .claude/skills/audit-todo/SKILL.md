---
name: audit-todo
description: Reads TODO.md/TODO_PRODUCTION.md and verifies unchecked items against the actual code, updating status
---

# Audit TODO

The orchestrator skill for this template's generated checklists. Use when
the user asks "what's left to do", "check the TODO list", "audit setup",
or similar.

1. Read `TODO.md` and `TODO_PRODUCTION.md` (whichever the user means, or
   both if unspecified).
2. For each section (one per selected integration), identify unchecked
   (`[ ]`) items that are actually **code-verifiable** — not everything is
   (dashboard/console steps like "create the App Store Connect app record"
   can't be checked from code; skip those, they're inherently manual).
3. For each code-verifiable item, spawn a targeted check:
   - "Add redirect URLs in Supabase Dashboard" → not verifiable, skip.
   - "Confirm the `@thecalda.com` bypass matches your internal domain" →
     grep `lib/core/gate/app_gate.dart` for the actual domain string.
   - "Set `ONESIGNAL_APP_ID` in .env.*" → check the `.env.*` files aren't
     empty for that key. Don't stop at non-empty: also flag a filled value
     that's byte-identical across `staging`/`prod` (a copy-paste, e.g. a
     prod `.env` reusing the staging Supabase URL/key → prod would talk to
     the staging backend) or equal to the `.env.example` placeholder. A
     filled-but-wrong value is a footgun a non-empty check silently passes.
   - "Confirm ..." items (e.g. the `@thecalda.com` bypass domain) → report
     as "present, default value — verify manually," and leave unticked;
     correctness needs user judgment, not a code check.
   - Any item referencing a specific file/pattern → read that file and
     confirm the pattern is actually present, using the same checks the
     relevant `verify-*` skill would run.
   - Sanity-check literal values embedded in the checklist itself (deep-link
     schemes/hosts, bundle IDs, redirect URLs) against `CLAUDE.md`'s flavor
     config / `deeplink_config.dart` — even for "dashboard" items the doc
     *text* can be wrong (e.g. a prod checklist printing staging deep-link
     URLs), and a pure code-vs-checkbox audit is blind to that.
4. Report a clear pass/fail per checked item, and for failures, say
   specifically what's missing and where.
5. If asked to update the doc, tick off (`[x]`) items you've confirmed are
   done in code — never tick off a dashboard-only item you can't verify,
   and never untick an item without explaining why.

This skill composes with the per-integration `verify-*` skills — for a
deep check on one integration, prefer calling that skill directly; use
`audit-todo` for a broad sweep across everything selected.
