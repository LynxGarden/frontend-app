# PROJECT_NAME — Flutter Project Brief for Claude

## Project Overview

**PROJECT_NAME** is ... (describe what your app does in 2-3 sentences).

**Tagline:** *Your tagline here.*

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

### Colors
TODO: Replace the placeholder colors in `lib/core/theme/app_colors.dart` with your brand colors.

```dart
// Example:
class AppColors {
  static const primary    = Color(0xFF______);  // Your primary color
  static const background = Color(0xFF______);  // Background color
  // ...
}
```

### Typography
TODO: Update font families in `lib/core/theme/app_text_styles.dart`.

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

## Features

TODO: List your app's features here so Claude knows what to build.

1. Feature 1 — description
2. Feature 2 — description
3. ...

---

## Data Models

TODO: Define your Supabase tables and corresponding Dart models here.

```dart
// Example:
// class UserProfile {
//   final String id, firstName, lastName, email;
//   final bool onboardingCompleted;
// }
```

---

## Business Rules

TODO: List key business rules that Claude should know about.

1. Rule 1
2. Rule 2

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
