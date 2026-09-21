---
name: setup-guide
description: Show the setup checklist for a new project created from the Calda starter template
---

# Setup Guide

When the user asks for the setup guide or checklist:

**The authoritative checklist is the wizard-generated `TODO.md` (and
`TODO_PRODUCTION.md` for standing up production).** They're scoped to exactly
the integrations/flavors this project selected and stay flavor-aware — always
read and surface those first if they exist. This skill is the pre-wizard /
quick-orientation version; don't let it contradict the generated TODOs.

## Post-clone quick start

1. **Run the wizard:** `dart run bin/setup.dart` — it renames the project,
   wires flavors, and generates `TODO.md`/`TODO_PRODUCTION.md`.
2. `flutter pub get`
3. `dart run flutter_launcher_icons && dart run flutter_native_splash:create`
4. Run the app — **mind flavors**: if the project uses flavors, a bare
   `flutter run` fails. Use the generated wrapper `./scripts/run-staging.sh`,
   or `flutter run --flavor staging -t lib/main_staging.dart` (+ the
   `--dart-define`s shown in `CLAUDE.md`'s Flavors section). Only a no-flavor
   project uses a bare `flutter run`.

## Things the wizard doesn't do (manual)

- [ ] **Supabase:** create the project(s); copy the URL (the API URL
  `https://<ref>.supabase.co`, NOT the dashboard URL) and the **publishable
  key** (Project Settings → API Keys — not the legacy anon key) into the
  matching env file — `.env.<flavor>` per flavor (e.g. `.env.staging`,
  `.env.prod`), or `.env` for a no-flavor project.
- [ ] **Deep links:** the values live in `lib/core/config/deeplink_config.dart`
  (Dart fallback) and, for flavored projects, in `ios/Flutter/<Flavor>.xcconfig`
  (`DEEPLINK_SCHEME`/`DEEPLINK_HOST`) and `android/app/build.gradle.kts`
  `productFlavors` `manifestPlaceholders`. Do **not** hand-edit
  `ios/Runner/Info.plist` or `AndroidManifest.xml` — they already reference
  these via `$(DEEPLINK_SCHEME)` / `${deeplinkScheme}`.
- [ ] Register the Supabase Auth redirect URLs (see `TODO.md` — it prints the
  exact per-flavor `scheme://host/verification-successful` and
  `/auth/reset-password`).
- [ ] **Bundle ID:** set in Project basics of the wizard; for flavored
  projects it's per-flavor in `android/app/build.gradle.kts` (`applicationId`
  + `applicationIdSuffix` in `productFlavors`) and `ios/Flutter/<Flavor>.xcconfig`
  (`PRODUCT_BUNDLE_IDENTIFIER`). Re-run the wizard rather than hand-editing if
  it's wrong.
- [ ] Fill out `CLAUDE.md` with the app's real overview/features.
- [ ] **Fonts:** the template uses `google_fonts` (`GoogleFonts.inter` in
  `lib/core/theme/app_text_styles.dart`) — to change the font, swap that call.
  To bundle a custom font instead, add a `fonts:` section to `pubspec.yaml`
  pointing at `assets/fonts/` (there is no `assets/.fonts/` dir by default).
- [ ] Optional integrations (RevenueCat, Stripe, OneSignal, Sentry, PowerSync,
  Codemagic/Shorebird, etc.) are all chosen in the wizard; their remaining
  manual dashboard steps are in `TODO.md`.
- [ ] Connect the Figma MCP for design-to-code (see `CLAUDE.md`'s Figma
  section), then use the `figma-theme-sync` skill.

This repo does no backend/SQL work — use the official Supabase agent skills
(`npx skills add supabase/agent-skills`) for schema/migrations.
