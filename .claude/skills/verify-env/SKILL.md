---
name: verify-env
description: Audits .env / .env.<flavor> files for missing keys, wrong values (dashboard vs API URLs, test-mode in prod), asset registration, and staging/prod drift
---

# Verify Env

Environment misconfiguration is the single most bug-prone surface in a
freshly-generated project — a filled-but-wrong `.env` looks fine but breaks at
runtime or (worse) silently ships wrong behavior. This skill cross-checks the
`.env` files against the code that reads them, the pubspec, and each other.

Read every `.env`, `.env.<flavor>` (and `.env.example`), then check:

1. **Every read key is present** — grep `lib/` for every read form —
   `dotenv.env['X']`, `dotenv.get('X')`, `dotenv.maybeGet('X')` — each key
   read in code must exist in each `.env.<flavor>` (empty is OK — that's a
   "fill me in" TODO — but a key read in code and *absent* from the file is a
   silent `null`). Conversely, flag keys present in `.env` that nothing reads
   (dead config).

2. **Key names match the code** — the classic mismatch: the wizard writes
   `SUPABASE_PUBLISHABLE_KEY` but code reads `SUPABASE_ANON_KEY` (or vice
   versa). Confirm `supabase_client.dart` reads `SUPABASE_PUBLISHABLE_KEY`,
   RevenueCat reads `REVENUECAT_IOS_API_KEY`/`REVENUECAT_ANDROID_API_KEY`,
   etc. — the name in the file must be the exact name in `dotenv.env['...']`.

3. **`SUPABASE_URL` is the API URL, not the dashboard URL** — flag any
   `SUPABASE_URL` of the form `https://supabase.com/dashboard/project/<ref>`.
   It must be the API endpoint `https://<ref>.supabase.co`. (The dashboard URL
   belongs in `supabase.config.json` / CLAUDE.md as context, not here.)

4. **Test-mode / bypass flags are off in production** — `REVENUECAT_TEST_MODE`
   (and any similar bypass) must NOT be `true` in a prod-named env file
   (`prod`/`production`/`release`/`live`/`main`) — `true` there makes
   `hasEntitlement()` return true for every real user. `true` in staging is
   fine.

5. **Every loaded env file exists and is a declared pubspec asset** —
   `flutter_dotenv` v5 loads from the asset bundle. Trace the exact
   `fileName` passed to each `dotenv.load(...)` (follow `main_*.dart` →
   `bootstrap(envFile: ...)`), and confirm each resolves to a file that BOTH
   exists AND is listed under `flutter/assets` in `pubspec.yaml`. A missing
   entry throws at `dotenv.load()` on launch (boots the "Setup Required"
   screen). Also flag the default entrypoint: `main.dart` → `bootstrap()`
   with no arg loads a bare `.env` — if that file is neither present nor a
   registered asset, running the default entrypoint fails. And flag a stale
   bare `.env` asset entry left behind when flavors are used.

6. **Staging vs prod drift, and unconfigured placeholders** — two distinct
   findings: (a) a value still equal to the `.env.example` placeholder =
   **unconfigured** (blocker for that flavor); (b) a real value that's
   byte-identical across `staging` and `prod` where it should differ
   (`SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` pointing prod at the staging
   project) = **drift** (warning — reusing one project across flavors can be
   intentional pre-launch, so report it, don't hard-fail).

7. **Nothing sensitive is committed** — confirm `.gitignore` covers `.env`
   and `.env.*` (with `!.env.example`), and that `git ls-files` shows only
   `.env.example` tracked — never a real `.env.<flavor>`.

Report per-file, most-severe first (wrong key name / dashboard URL / test-mode
in prod / missing asset = blockers; drift / dead keys = warnings). Composes
with `verify-supabase-auth`, `verify-revenuecat`, and `audit-todo`.
