# 01 · Architecture

The app is built on the **Calda Flutter starter** (`/Users/matevzmiskec/CaldaProjects/flutter-starter/calda-flutter-starter`). We inherit its conventions rather than inventing new ones. This doc records the stack, the layering, and the rules we commit to.

## Stack

| Concern | Choice | Source / notes |
|---------|--------|----------------|
| Framework | Flutter (Dart SDK `^3.10.x`) | from starter |
| State management | **Riverpod** (`flutter_riverpod` + `riverpod_annotation`, `riverpod_generator`) | from starter; `ProviderScope` at root |
| Routing | **go_router** (`^13.x`), `routerProvider = Provider<GoRouter>` | from starter |
| Backend | **Supabase** (`supabase_flutter ^2.x`) — Postgres, Auth, Storage, Edge Functions | from starter; schema in `Lynx-backend` |
| Models | Hand-written immutable classes with `fromJson`/`toJson` (no freezed/json_serializable) | starter convention |
| Fonts | `google_fonts` | swap to brand fonts — see [02](02-navigation-and-ui.md) |
| i18n | `flutter_localizations` + `.arb` + `flutter gen-l10n` | **enable from the start** (off by default in starter); ship **`en` + `sl`**, tenant default locale from `tenants.locale_default` |
| Native iOS tab bar | `cupertino_native` (`CNTabBar`, SF Symbols) | pattern from kaddy — see [02](02-navigation-and-ui.md) |
| Media | `cached_network_image`, `image_picker` | from starter; video player added at CP1 |
| Secure storage | `flutter_secure_storage` (tokens) + `shared_preferences` (flags) | from starter |

**Deliberately deferred:** RevenueCat, OneSignal, Stripe, PowerSync (offline), Sentry, Mapbox — all available as optional modules in the starter but **not** part of v1.

## Layering — feature-first with a shared core

Mirrors the starter's structure. Supabase is **never** called from a widget.

```
lib/
  core/                 # cross-cutting infra (mostly inherited from starter)
    config/             # deeplink config, env
    router/             # app_router.dart — go_router + auth redirect
    supabase/           # SupabaseClientWrapper (init + accessors)
    theme/              # app_colors / app_text_styles / app_spacing / app_theme  ← rebrand to Lynx
    storage/            # secure + local storage services
    utils/              # AppException, helpers
    l10n/               # generated localizations (NEW — enable)
  features/
    auth/               # inherited from starter (login/signup/reset/verify)
    exercises/          # exercise library (coach)
      data/             # models/ + exercise_repository.dart
      presentation/     # screens + widgets
      providers/        # Riverpod providers
    programs/           # program builder + template library (coach)
    assignments/        # assign template → per-client instance (coach)
    training/           # client daily loop (client)
    review/             # coach review of completed sessions (coach)
    groups/             # rosters (coach)
    clients/            # client record: profile + safety flags (coach/physio)
    profile/            # client's own profile & history (client)
  shared/
    widgets/            # app_button, app_text_field, app_nav_bar, app_toast, skeleton_loader… (inherited)
    models/             # cross-feature models (e.g. Person, Role)
    providers/          # cross-feature providers (e.g. currentUserProvider)
  main.dart
```

**Per-feature layer convention** (from the starter's `add-repository` / `add-feature` skills):

- `presentation/` — screens & widgets (`ConsumerWidget` / `ConsumerStatefulWidget`).
- `data/models/` — immutable domain models with `fromJson`/`toJson`.
- `data/<name>_repository.dart` — the **only** place that touches Supabase; static methods wrapping `SupabaseClientWrapper.db('table')`.
- `providers/` — Riverpod providers exposing repository calls to the UI.

## Data-access rules (inherited, non-negotiable)

1. **Repository pattern.** Widgets talk to providers; providers call repositories; repositories call Supabase. No `Supabase.instance` in a widget.
2. **Explicit columns always.** `.select('id, name, video_url')` — never `.select('*')`.
3. **Wrap errors.** Repositories catch and rethrow as `AppException` (`core/utils/app_exception.dart`) with a friendly `message`; the UI surfaces it via `AppToast`.
4. **Fail-fast env.** `SupabaseClientWrapper.init()` throws a descriptive error if `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` are missing; `main.dart` renders a setup page instead of crashing.
5. **Design-token styling.** Use `AppColors` / `AppSpacing` / `AppTextStyles` — never hardcode hex or magic numbers. Use `.withValues(alpha:)` (not deprecated `.withOpacity`).
6. **`mounted` checks** after every `await` before touching `context`.

## Provider conventions

| Use | Provider type |
|-----|---------------|
| Async read (e.g. list of exercises) | `FutureProvider` (family for parameterized reads) |
| Realtime (e.g. live review — later) | `StreamProvider` |
| UI-only transient state | `setState` in a `ConsumerStatefulWidget` |
| Auth / current user | `ChangeNotifier` bridged into go_router `refreshListenable`, plus a `currentUserProvider` |

Run `dart run build_runner build --delete-conflicting-outputs` after adding `@riverpod` providers.

## Roles & auth flow

Auth is **shared with the website** — one Supabase project, one set of users, the same sign-in methods on every surface.

- **Sign-in methods:** email **magic link** (passwordless, `signInWithOtp`), **Google SSO**, **Apple SSO** (`signInWithOAuth`), plus the starter's email/password screens kept as a fallback. On iOS, use native Sign in with Apple; Apple SSO is **required by App Store review** whenever Google SSO is offered. Provider setup is in the [backend security doc](../../Lynx-backend/docs/01-security-and-rls.md#auth-configuration--external-identity-sso).
- A user's **role** (owner/admin, coach, physio, client) and **tenant** live on their linked `person`/profile row, read once at startup into `currentUserProvider` (which also exposes `tenantId`).
- go_router's `redirect` (extended from the starter's `_AuthNotifier` pattern) gates:
  - unauthenticated → auth stack (login with SSO + magic link; deep-link callback handling).
  - authenticated **but no linked `person` yet** → a "finish setup / accept invite" holding screen (a brand-new SSO user has no tenant until linked; RLS returns nothing).
  - authenticated **client** → client shell (training tabs).
  - authenticated **coach/physio/admin** → staff shell (library / programs / clients / review tabs).
- **Account-less clients** never authenticate. They exist purely as DB records operated by staff; the app renders their program/history inside the staff "clients" feature. See [backend data-model](../../Lynx-backend/docs/00-data-model.md).

## Multi-tenancy in the app

The backend is [multi-tenant](../../Lynx-backend/docs/00-data-model.md#multi-tenancy-saas); the app cooperates with that model:

- `currentUserProvider` resolves the signed-in user's `tenant_id` at startup; feature providers read it.
- Repositories **always** scope reads/writes to the current tenant (`.eq('tenant_id', tenantId)`) and stamp `tenant_id` on inserts — belt-and-braces on top of RLS, which enforces isolation regardless.
- No screen ever lets a user pick or see another tenant. (Cross-tenant operator tooling, if ever needed, is a separate service-role admin surface, not this app.)

## The account-less client — architectural note

This is the model decision that "touches everything." Concretely:

- The unit of identity in the domain is a **`person`** (client record), which *may* be linked to an `auth.users` account, or may not.
- All training data (assignments, logged entries, history) references `person_id`, **never** `auth.uid()` directly.
- A logging action can originate from the client themselves *or* from a coach acting on the person's behalf; both write the same `logged_entries` rows attributed to the same `person_id`.
- RLS resolves "which persons can I see/act on" via the staff's role + assignment, not via ownership of the account. Detail in [backend security doc](../../Lynx-backend/docs/01-security-and-rls.md).

## Configuration & flavors

- Env via `flutter_dotenv` (`.env`, `.env.staging`, `.env.prod`) — from the starter. Set `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, deeplink scheme/host.
- Bundle IDs, app name, brand colors/fonts, and deeplink host are set by running the starter's `bin/setup.dart` wizard on first init (see [CP0](03-roadmap-and-checkpoints.md)). Rename `calda_starter` → `lynx_app`.
- Remove the starter's maintenance-gate `@thecalda.com` bypass and any Calda-specific stubs.

## Testing

- Optional `test_suite` module from the starter (mocktail + golden_toolkit). For v1 we target: repository unit tests for the training-engine data layer, and golden tests for the daily-loop screens. Wired at [CP6](03-roadmap-and-checkpoints.md).
