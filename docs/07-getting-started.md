# 07 · Getting Started (dev setup)

What CP0 scaffolded and how to run it. See [03 · Roadmap](03-roadmap-and-checkpoints.md) for where CP0 sits.

## Prerequisites

- Flutter 3.47+ / Dart 3.13+
- Docker (for the local Supabase stack)
- Supabase CLI (`brew install supabase/tap/supabase`)

## 1. Backend — local Supabase

The backend lives in `../Lynx-backend`. Local ports are remapped **+1000** (55321/55322/…) in `supabase/config.toml` so it won't clash with another local Supabase project on the default ports.

```bash
cd ../Lynx-backend
supabase start           # applies migrations + seeds the Lynx Center tenant
supabase status          # shows API URL + keys
# Studio: http://localhost:55323   API: http://127.0.0.1:55321
```

Migrations applied at CP0: `tenants` (+ Lynx Center seed), `persons`, `person_roles`, the RLS helper functions, and tenant-isolation policies. CP1 adds `exercises`, `tags`, `exercise_tags`. See `../Lynx-backend/docs/`.

> **After adding a new migration**, `supabase start` alone won't apply it to an existing local DB volume — run `supabase db reset` (recreates the DB from all migrations + seed).

> To push these to the **cloud** project instead: `supabase link --project-ref <ref>` then `supabase db push`. (Not done automatically — it modifies the live DB.)

## 2. App — flavors & env

Two flavors are wired (see `lib/core/config/app_flavor.dart`):

| Flavor | Entrypoint | Env file | Target |
|--------|-----------|----------|--------|
| **dev** | `lib/main_dev.dart` | `.env` | local / staging Supabase |
| **prod** | `lib/main_prod.dart` | `.env.prod` | live cloud project |

`.env` is pre-filled to point at the local stack. For the **Android emulator** change the host to `http://10.0.2.2:55321` (the iOS simulator can use `127.0.0.1`).

```bash
flutter pub get
flutter gen-l10n            # generates AppLocalizations from lib/l10n/*.arb (also runs on build)
flutter run -t lib/main_dev.dart      # dev
flutter run -t lib/main_prod.dart --release   # prod
```

> Native per-flavor bundle IDs / app names / iOS schemes are **not** set up yet — deferred to store setup (CP6). Today both flavors share one bundle id and differ only in which Supabase they talk to.

## 3. Seeing the shells

The app resolves the signed-in user to a `person` (tenant + roles) and shows:
- **client** → Train · Progress · Profile
- **staff** (owner/coach/physio) → Clients · Library · Review · Profile
- **authenticated but no linked person** → "finish setup" screen

To actually land in a shell you need a linked person. For local testing: create a user in Studio (`http://localhost:55323` → Authentication), then in SQL insert a `persons` row with that `auth_user_id` under the Lynx tenant and a `person_roles` row (e.g. `coach`). Without a link you'll (correctly) see the finish-setup screen.

## What's implemented in CP0

- Flutter app scaffolded from the Calda starter, renamed `lynx_app`.
- Lynx **light theme** (forest/cream), Bricolage Grotesque headings + Inter body (Geist wasn't available in google_fonts; Inter is the stand-in — revisit if we bundle Geist).
- **i18n EN + SL** (`lib/l10n/app_en.arb`, `app_sl.arb`).
- **Adaptive shell**: native iOS `CNTabBar` (cupertino_native) / custom Material pill on Android, role-based tabs.
- **Auth**: Google + Apple SSO + email magic link (`features/auth`), shared with the website.
- **Tenant-aware session**: `currentUserProvider` (role + `tenant_id`), `BaseRepository` scoping helper.
- Two flavors (dev/prod).

## Known follow-ups

- Providers (Google/Apple) + redirect URLs must be configured in Supabase before SSO works — see `../Lynx-backend/docs/01-security-and-rls.md`.
- Native flavor configs + real bundle IDs (CP6).
- Body font: Inter stand-in for Geist.
