# Lynx — Flutter Project Brief for Claude

## Project Overview

**Lynx** is a **multi-tenant SaaS** training & physiotherapy platform. Coaches build
an exercise library and programs, assign them to clients (as independent instance
copies), and clients train in the gym — logging actuals with a first-class "last
time" history. Lynx Center (a Ljubljana gym) is tenant #1; the product is built to
be sold to other gyms. A **client record is not a user account** — staff can
operate account-less clients.

**Tagline:** *Train. Log. Progress.*

> Full docs live in the sibling **`Lynx-docs`** repo (fumadocs) and in `docs/`.
> Backend (schema/RLS/RPCs) lives in the **`Lynx-backend`** repo. **Rule #14
> below: every feature ships with its `Lynx-docs` page.**

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (SDK ^3.10.8) |
| State Management | Riverpod (code generation) |
| Backend | Supabase (auth, database, storage, edge functions) |
| Navigation | GoRouter |
| Fonts | Google Fonts — Inter (default, customize in app_text_styles.dart) |
| Environment | flutter_dotenv (.env file) |
| In-App Purchases | RevenueCat — **disabled by default** (stub in revenue_cat_service.dart) |
| Push Notifications | OneSignal — **disabled by default** (stub in onesignal_service.dart) |

---

## Brand Guidelines

### Colors — forest green on cream (a LIGHT theme). See `lib/core/theme/app_colors.dart`.

```dart
forest  #004225  // primary brand
cream   #F5F1E8  // background
ink     #14281F  // primary text
surface #FFFFFF  // cards        surfaceLight #EFEADD (warm input fill)
surfaceBorder #E4DED0 (warm hairline)   success #2E7D32  error #B3261E
```
Depth: `AppShadows.card` / `.floating` (soft warm double-shadow) + a hairline
border, **elevation 0** — the iOS-27 look. Use `AppCard` for list rows/cards and
`AppNavBar` (circular back button) for pushed detail pages.

### Typography — `lib/core/theme/app_text_styles.dart`
Bricolage Grotesque (headings) + Inter (body), via google_fonts. Tight negative
tracking on large titles.

### Border Radius & Spacing
```dart
class AppRadius  { static const sm=8.0; md=12.0; lg=18.0; xl=24.0; xxl=32.0; pill=99.0; }
class AppSpacing { static const xs=4.0; sm=8.0; md=16.0; lg=24.0; xl=32.0; xxl=48.0; }
```

---

## App Architecture

```
lib/
├── core/
│   ├── config/
│   │   └── deeplink_config.dart       # Deep link scheme + host
│   ├── notifications/
│   │   └── onesignal_service.dart     # Stub — enable when ready
│   ├── purchases/
│   │   └── revenue_cat_service.dart   # Stub — enable when ready
│   ├── router/
│   │   └── app_router.dart            # GoRouter config + auth redirect
│   ├── supabase/
│   │   └── supabase_client.dart       # SupabaseClientWrapper singleton
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart           # AppRadius + AppSpacing
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   └── utils/
│       └── validation_helpers.dart
│
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── splash_screen.dart
│   │       ├── login_screen.dart
│   │       ├── signup_screen.dart
│   │       ├── forgot_password_screen.dart
│   │       ├── check_email_screen.dart
│   │       ├── verification_successful_screen.dart
│   │       └── change_password_screen.dart
│   │
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart
│   │
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart
│
├── shared/
│   ├── models/                        # (create on demand — not scaffolded)
│   ├── providers/                     # (create on demand — not scaffolded)
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_toast.dart
│       └── password_requirements.dart
│
└── main.dart
```

---

## Navigation (GoRouter)

```
/splash                         # Auto-resolves to login or home
/login
/signup
/forgot-password
/check-email?email=...          # Email verification sent screen
/verification-successful        # Deep link landing after email confirmed
/home                           # Main screen
/settings
  /settings/change-password
```

**Navigation patterns:**
- `context.go('/path')` — replaces current route
- `context.push('/path')` — adds to stack
- `_AuthNotifier` listens to Supabase auth changes via `refreshListenable`

---

## Features (checkpoints; all CP0–CP5 delivered, CP6 = launch hardening in progress)

1. **Auth** — email **OTP** (6-digit code, no magic-link deep links) + optional
   Google/Apple SSO (gated off via `--dart-define=ENABLE_SSO=true`). `features/auth`.
2. **Exercise library** (CP1) — coach-owned, tag-faceted, link-based video. `features/exercises`.
3. **Program builder** (CP2) — programs = ordered sessions of prescribed exercises;
   templates. No calendar. `features/programs`.
4. **Assignments** (CP3) — assigning a template SNAPSHOTS an instance bound to a
   client (a copy, not a reference). `features/clients` (assign flow).
5. **Clients & invites** (CP3) — account-less client record + safety `health_flags`
   (special-category) + invite-code binding. `features/clients`.
6. **Daily loop** (CP4, the hero) — Train tab: session menu → runner (target ·
   video · **LAST TIME** · log actuals · swap · complete). `features/training`.
7. **Coach review** (CP5) — completed sessions + logged actuals per client;
   review-on-login. `features/review`.
8. **Groups** (CP5) — rosters; group-assign fans out an independent instance per
   member. `features/groups`.

Shells: **client** (Train · Progress · Profile) and **staff** (Clients · Library ·
Groups · Review · Profile), chosen by role in `features/shell/RootShell`.

---

## Data Models

Schema + RLS live in `Lynx-backend` (migrations CP-B0…B5). Every domain table
carries `tenant_id` (tenant-isolation RLS is the first predicate everywhere).
Load-bearing tables:

- `tenants`; `persons` (the spine — `auth_user_id` nullable = account-less), `person_roles`.
- `exercises` / `tags` / `exercise_tags` (coach-owned library).
- `programs` / `sessions` / `session_exercises` (template side).
- `assignments` / `assignment_sessions` / `assignment_exercises` (per-client
  SNAPSHOT instance; `assignment_exercises` copies `exercise_name`/`video_url`,
  keeps `exercise_id` for "last time", `swapped_from_exercise_id` for swap history).
- `logged_entries` (generic actuals; index `(person_id, exercise_id, logged_at desc)`
  powers "last time"), `health_flags` (special-category), `invites`.
- `groups` / `group_members`; `assignments.group_id` (group-assign provenance).

SECURITY DEFINER RPCs (clients can't write staff-only rows): `assign_template`,
`assign_template_to_group`, `redeem_invite`, `complete_session`,
`swap_assignment_exercise`. Dart models mirror these under each
`features/<x>/data/models/`.

---

## Business Rules

1. **Tenant isolation first.** Every domain row has `tenant_id`; RLS filters on it
   before any role/ownership check. No end-user role crosses tenants.
2. **Client record ≠ user account.** The domain identity is a `person`; it may be
   account-less (staff operate it). Accounts bind to a person via an invite code.
3. **Instances, not references.** Assigning a program snapshots a per-client copy;
   editing it never touches the template or another client's copy.
4. **"Last time" is first-class**, keyed on `(person_id, exercise_id)` and preserved
   across program changes and swaps.
5. **Staff-write-only assignment rows.** Clients trigger `complete_session` /
   `swap_assignment_exercise` via SECURITY DEFINER RPCs, never direct writes.
6. **Group-assign = fan-out.** Shared prescription at assign time, independent
   per-athlete logging & history.
7. **Online-only in v1** (clear messaging when offline). **Bilingual EN + SL.**
8. **Health data is special-category (GDPR)** — no real health data in prod until
   consent + the data-sharing agreement (with Urban's physio practice) are in place.

---

## Claude Code Instructions

1. **Design system always** — `AppColors.*`, `AppTextStyles.*`, `AppSpacing.*`, `AppRadius.*`
2. **Riverpod for shared state** — `FutureProvider` for async data, `StreamProvider` for realtime. `setState` is fine for UI-only transient state
3. **Repository pattern** — Supabase never called from UI. Access via `SupabaseClientWrapper.db('table')`, `SupabaseClientWrapper.auth`, `SupabaseClientWrapper.functions`
4. **File naming** — snake_case files, PascalCase classes, camelCase variables
5. **Mounted checks** — always check `if (mounted)` before `setState` after async gaps
6. **Haptic feedback** — `HapticFeedback.lightImpact()` on taps, `selectionClick()` on selection changes (chips, pickers, tabs), `heavyImpact()` for a big-win moment
7. **Error handling** — repositories throw `AppException` (`lib/core/utils/app_exception.dart`) with a friendly message; the UI layer catches and shows it via `AppToast.show()` — never leak raw backend errors
8. **Opacity** — use `.withValues(alpha: x)` not `.withOpacity(x)` (Flutter 3.10+ API)
9. **Explicit column selection** — Supabase queries always `.select('col1, col2')`, never `.select()`/`*`
10. **Fail-fast env vars** — every service `init()` throws a clear `StateError('Missing X env var...')` on a missing required var, never a bare `!` force-unwrap
11. **Secure vs. local storage** — tokens/sensitive values go through `SecureStorageService`, never `LocalStorageService`/`shared_preferences`
12. **Code generation** — run `dart run build_runner build` after adding/editing Riverpod-annotated providers or Freezed models
13. **No backend/SQL work in this repo** — schema/migration/edge-function changes go through the official Supabase agent skills (`npx skills add supabase/agent-skills`), not through Claude editing this codebase directly
14. **Docs are part of every feature (fumadocs)** — no feature is "done" until its fumadocs page exists and is current. Whenever you build or change a feature, add/update the matching fumadocs MDX page (frontend feature, screen, flow, or backend table/RPC/RLS) in the same change set as the code — never as a follow-up. This applies retroactively too: backfill docs for anything already built but undocumented. Keep the fumadocs pages the single source of truth for how a feature works; the `fumadocs-doc-sync` skill flags drift and the `docs-deploy` skill publishes.

## UI Styling Patterns & Conventions

Reusable snippets — reach for these before writing a new one-off pattern.

```dart
// Skeleton loading placeholder
SkeletonLoader(child: SkeletonBox(width: 120, height: 16))

// Toast (overlay-based — not a SnackBar)
AppToast.show(context, title: 'Saved', subtitle: 'Your changes were saved.');

// Keyboard-dismiss wrapper for a form screen
KeyboardDismisser(child: Scaffold(...))

// Detail-page nav bar
Scaffold(appBar: AppNavBar(title: 'Details'), body: ...)

// Selectable chip
AppChip(label: 'Filter', selected: isSelected, onTap: () => ...)
```

Bottom sheets: use `showModalBottomSheet` with `backgroundColor: AppColors.surface`
and `shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)))`
— match the design system's radius tokens, don't hardcode a different value per sheet.

---

## Figma Design

TODO: If you have a Figma design, connect it via Figma MCP:
1. Install the Figma MCP server (see README.md for instructions)
2. Add your Figma file URL here so Claude can reference it

Figma URL: (paste your Figma file URL here)
