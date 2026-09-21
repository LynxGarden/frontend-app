---
name: claude-md-freshness-check
description: Diffs CLAUDE.md's documented architecture/routes/features against the actual lib/ tree and flags drift
---

# CLAUDE.md Freshness Check

`CLAUDE.md` is hand-maintained prose describing the app; the codebase moves
faster than the doc gets updated. This skill finds where they've diverged —
a common failure mode is the doc describing v1 while the code is on v3.

1. **Architecture tree drift** — walk the actual `lib/` directory tree and
   diff it against the `## App Architecture` code block in `CLAUDE.md`.
   Flag:
   - Directories/files listed in `CLAUDE.md` but absent from the tree
     (removed OR never created — e.g. `shared/models/`, `shared/providers/`
     are in the template tree but not created until you add them). Detect
     empty directories too, not just files.
   - Feature directories under `lib/features/` that exist in code but
     aren't mentioned anywhere in the doc's tree or `## Features` section.
     Label each as either a **template optional module** (onboarding,
     paywall, utility — enabled via the wizard, documented elsewhere) or a
     **custom feature** (something genuinely new), rather than universally
     asserting "someone shipped something Claude has no context on."
   - Services under `lib/core/` (new `*_service.dart` files) missing from
     the tree.
2. **Route drift** — walk every `GoRoute(path: ...)` in
   `lib/core/router/app_router.dart` (including nested routes) and diff
   against the `## Navigation (GoRouter)` route list in `CLAUDE.md`. Flag
   routes present in one but not the other, in both directions.
3. **Feature list drift** — for each directory under `lib/features/`,
   confirm it's referenced in the `## Features` section. A feature
   existing in code with zero mention in the doc is the highest-value
   finding here — it means someone shipped something Claude has no
   context on for future work.
4. **Tech stack drift** — check the `## Tech Stack` table against
   `pubspec.yaml` dynamically: flag any non-commented dependency whose name
   isn't referenced anywhere in `CLAUDE.md` (don't rely on a hardcoded
   package list — enabled optional modules like `connectivity_plus`,
   `geolocator`, `package_info_plus`, `flutter_timezone`, `sentry_flutter`
   back real code and are easy to miss), and any listed technology whose
   package is no longer a dependency.
5. **Placeholder TODOs left unfilled** — only flag unfilled placeholder
   text (`TODO: Replace the placeholder colors...`, `**Tagline:** *Your
   tagline here.*`, `Feature 1 — description`, etc.) if the project has
   moved beyond a fresh template — concretely, if `lib/features/` contains a
   directory beyond the template set {auth, home, settings, onboarding,
   paywall, utility} OR `lib/shared/models/` has real classes. On an
   otherwise-untouched template, report placeholders as "expected
   fresh-template state," NOT as stale drift — otherwise every placeholder
   becomes a false positive.
6. **Business rules / data models sections** — if `lib/shared/models/`
   has real model classes but `## Data Models` in `CLAUDE.md` still shows
   only the commented-out example, flag it.

Report drift as a prioritized list (routes and features first — these
most directly cause Claude to make wrong assumptions in future sessions),
then offer to draft the updated sections rather than auto-editing
`CLAUDE.md` without confirmation.
