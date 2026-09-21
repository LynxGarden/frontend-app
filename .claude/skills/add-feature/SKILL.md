---
name: add-feature
description: Scaffold a new feature module with the standard folder structure
---

# Add Feature

When the user asks to add a new feature, create the standard folder structure:

```
lib/features/{feature_name}/
├── data/
│   └── {feature_name}_repository.dart
├── domain/
│   └── (models go here — immutable class + `fromJson`, parse only the
│       columns the repository selects; see the `add-repository` skill)
└── presentation/
    ├── {feature_name}_screen.dart
    └── widgets/
```

Then:
1. Create the repository with basic CRUD methods — but check which backend-access
   pattern this project actually has before assuming direct Supabase queries:
   - If `lib/core/api/api_client.dart` exists (the custom-API toggle was selected),
     the repository should call `ApiClient.get/post/put/patch/delete(...)` against
     backend endpoints (e.g. `ApiClient.get('/tasks')`), not query a table directly.
     Ask the user for the endpoint path(s) if they aren't obvious.
   - Otherwise, if Supabase is present, use
     `SupabaseClientWrapper.db('table_name')` — explicit `.select('col1, col2')`,
     never `.select()`/`*`, per this repo's house rule.
   - If a project has both (e.g. Supabase for auth/storage, a custom API for
     business-logic endpoints), ask the user which one this particular feature's
     data lives behind — don't guess.
   - If neither exists yet, ask the user before scaffolding anything — don't
     default to inventing a Supabase table or an endpoint that isn't there.
2. Create the main screen as a `ConsumerWidget`/`ConsumerStatefulWidget`, using the design system (`AppColors`, `AppTextStyles`, `AppSpacing`) and existing shared widgets (`AppButton`, `AppChip`, `AppNavBar`, `SkeletonLoader`, etc. — check `lib/shared/widgets/` before writing a new one). For the data layer, expose the repository through a Riverpod provider (plain `FutureProvider`/`StreamProvider`/`Provider` by default — only use `@riverpod` code-gen if the project already does, since that needs a build_runner step). The screen watches the provider; it never touches the repository or Supabase directly.
3. Add a route in `lib/core/router/app_router.dart` (before the `// TODO: Add more routes as needed.` marker for a top-level route, or nested under a parent). Then **add a navigation entry point** to it from an existing screen (a tile/button/menu item on `home_screen.dart` or `settings_screen.dart`) — a route with nothing linking to it is unreachable; don't leave the feature stranded.
4. If this repo has flavors (check `lib/core/config/app_flavor.dart` — if it has real getters beyond `name`, flavors are on), nothing feature-specific changes; flavors only affect build/env config, not feature code.
5. Repository errors should throw `AppException` (`lib/core/utils/app_exception.dart`) with a friendly message; the UI layer catches and shows it via `AppToast.show()` — never leak raw backend errors.
6. If Riverpod code-generation annotations or Freezed models are added, remind the user to run `dart run build_runner build`.

Ask the user what the feature does and what data it needs before scaffolding.
