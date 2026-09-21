---
name: add-screen
description: Scaffold a single screen + route entry, lighter than add-feature
---

# Add Screen

Use this instead of `add-feature` when the user wants a single screen added
to an *existing* feature (or a standalone screen with no data layer), not a
whole new feature module.

1. Create `lib/features/{feature}/presentation/{screen_name}_screen.dart` as
   a `ConsumerWidget`, following the pattern of existing screens in that
   feature (check `lib/features/home/presentation/home_screen.dart` or
   `lib/features/settings/presentation/settings_screen.dart` for the house
   style if the feature has no screens yet).
2. Use the design system (`AppColors`, `AppTextStyles`, `AppSpacing`) and
   existing shared widgets from `lib/shared/widgets/` — don't recreate
   `AppNavBar`, `AppChip`, `KeyboardDismisser`, `SkeletonLoader`, etc.
3. Add the route to `lib/core/router/app_router.dart`: import the screen,
   add a `GoRoute` in the appropriate section (before the
   `// TODO: Add more routes as needed.` marker for top-level app routes,
   or nested under an existing parent route if it's a sub-screen).
4. If the screen needs auth, it's covered automatically by the existing
   redirect logic in `app_router.dart` — don't add a second auth check.
5. Ask the user what the screen shows and whether it needs a route
   parameter before scaffolding.
