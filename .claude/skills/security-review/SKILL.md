---
name: security-review
description: Flutter/Dart-specific security pass — secrets, insecure storage, tracked .env files, over-broad permissions, sensitive logging
---

# Security Review

Complements the repo-wide `/security-review` slash command, scoped to this
template's own patterns. Check:

1. **Hardcoded secrets** — grep `lib/` for API-key-shaped literal strings.
   Distinguish credential *values* from key-*name* string constants: only
   flag strings with real credential shape/entropy or known secret prefixes
   (`eyJ` JWT, `sk_`/`sk_live_`, `sb_secret_`, `-----BEGIN` private-key
   headers). A `shared_preferences` key-name constant like
   `const _fooKey = 'last_synced_timezone'` is NOT a secret — don't flag it.
   Publishable/SDK keys are client-safe by design (`sb_publishable_`, `pk_`,
   RevenueCat `appl_`/`goog_`) — don't flag those either, and exclude
   `.env.example` placeholders. All real secrets should come from
   `dotenv.env[...]`, never a literal.
2. **Tracked `.env` files** — run `git status`/`git ls-files` and confirm
   no `.env`, `.env.staging`, `.env.prod`, etc. are actually tracked in
   git (check `.gitignore` covers `.env*` but not `.env.example`). A
   tracked `.env` with real credentials is the single most damaging thing
   this check can catch.
3. **Any plaintext credential/token file committed to the repo** — beyond
   `.env*`, check for any tracked file whose *content* looks like a live
   credential (a JWT, a private key, an API token) regardless of
   filename/extension. This is a real anti-pattern found during this
   template's own research phase — a reference app had a tracked
   `apple_sign_in_jwts.txt` containing live Apple Sign-In client-secret
   JWTs with their expiry dates in plaintext. If Sign-in-with-Apple (or
   any credential needing periodic manual rotation) is used, that
   rotation info belongs in `TODO.md`/`TODO_PRODUCTION.md` as prose
   instructions, never as a file containing the actual live secret.
4. **Insecure local storage** — grep for `shared_preferences`/
   `LocalStorageService` usage storing anything that looks like a token,
   session identifier, or PII. Sensitive values must go through
   `SecureStorageService` (`lib/core/storage/secure_storage_service.dart`)
   instead.
5. **Over-broad platform permissions** — cross-check with
   `verify-permissions`; a permission declared but never used is
   unnecessary privacy exposure, not just dead config. Do the grep here too,
   don't just defer: for each declared permission, grep `lib/` for the API
   that backs it (geolocator→location, image_picker/camera→camera & photos,
   a contacts package→contacts). A permission with no backing API call is
   the over-broad finding. (Note: the `contacts` wizard toggle is
   permission-only by design — flag it as "declared, wire or remove," not as
   a leak.)
6. **Sensitive data in logs** — grep for `debugPrint`/`AppLogger.*` calls
   that pass a full user object, email, or token rather than an ID or
   redacted summary — logs can end up in crash reports (Sentry) or device
   logs.
7. **Certificate pinning** — if the app talks to a custom backend beyond
   Supabase (`lib/core/api/api_client.dart` present), note whether
   certificate pinning is in place; flag as a gap if not, but don't treat
   its absence as a hard failure — it's a judgment call depending on
   threat model.

Report each finding with file/line and a concrete fix, ranked by severity
(tracked secrets and committed credential files first, everything else after).
