---
name: verify-supabase-auth
description: Audits this template's Supabase auth wiring — redirect URLs, repository pattern, RLS-safe access
---

# Verify Supabase Auth

Narrow, template-specific audit — complements the official Supabase agent
skills (`npx skills add supabase/agent-skills`), which handle general
schema/migration/edge-function work but don't know this repo's conventions.

Check:

1. **Repository pattern** — grep `lib/features/**/presentation/**/*.dart`
   for direct `SupabaseClientWrapper.db(` or `.auth.` calls. UI/presentation
   files should never call Supabase directly — only repositories in
   `data/` folders should. Flag any violation.
2. **Deep link consistency** — `lib/core/config/deeplink_config.dart`'s
   `scheme`/`host` defaults should match what's declared in
   `ios/Runner/Info.plist` (`CFBundleURLSchemes`/`CFBundleURLName`) and
   `android/app/src/main/AndroidManifest.xml` (the deep-link
   `<data android:scheme=... android:host=...>` intent filter). If flavors
   are in use, check each flavor's xcconfig/manifest-placeholder values
   instead.
3. **Redirect URLs** — read `TODO.md`'s Supabase section for the exact
   redirect URLs expected (`{scheme}://{host}/verification-successful` and
   `/auth/reset-password`); these can't be verified against the dashboard
   from code, but confirm the scheme/host used in the doc matches the
   actual `deeplink_config.dart` values (catches drift after a rename).
4. **Explicit column selection** — grep repositories for `.select()` with
   no arguments or `.select('*')`; this repo's house rule is always
   `.select('col1, col2')`.
5. **Auth screens present vs. router** — if `lib/features/auth/` exists,
   confirm every screen file has a matching `GoRoute` in
   `lib/core/router/app_router.dart`, and that the redirect logic's
   `publicRoutes` list includes all of them.
6. **Bundle-ID / applicationId sanity** — confirm Android's `applicationId`
   (in `android/app/build.gradle.kts`) contains no invalid characters (e.g.
   a stray hyphen — a real bug this template's own wizard had before its
   rewrite) and that `namespace` matches `applicationId` unless flavors
   intentionally suffix one and not the other.

Report each check as pass/fail with the specific file/line for any failure.
