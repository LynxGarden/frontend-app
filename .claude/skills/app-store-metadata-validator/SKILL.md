---
name: app-store-metadata-validator
description: Checks screenshot dimensions, character limits, and required fields against current App Store Connect / Play Console requirements before a listing submission
---

# App Store Metadata Validator

Store submission requirements (dimensions, character limits) change over
time and shouldn't be trusted from training data alone — always
`WebSearch` for the current official limits before validating rather than
relying on memorized numbers, then apply them here.

1. **Locate the metadata.** This template does no fastlane scaffolding by
   default, so check, in order:
   - `ios/fastlane/metadata/` and `android/fastlane/metadata/android/`
     (fastlane `deliver`/`supply` convention) if fastlane is set up.
   - A project-local docs/assets folder the team uses for listing content
     (ask the user where screenshots/copy live if neither fastlane path
     exists).
   - If nothing is tracked in-repo, this skill can only validate
     copy/screenshots the user pastes or points to directly — say so
     rather than silently skipping checks.
2. **Text field limits** (verify current values via WebSearch, these are
   from App Store Connect / Play Console as of recent history and may
   have shifted):
   - iOS: app name (30 chars), subtitle (30), promotional text (170),
     description (4000), keywords (100, comma-separated, no spaces
     needed), what's new (4000).
   - Android: app name/title (30), short description (80), full
     description (4000).
   Flag any field over its limit, and flag near-limit fields (>90%) as a
   caution since re-wrapping during copy edits easily pushes it over.
3. **Screenshot requirements** — confirm at least the required device
   classes have screenshots present (WebSearch current required sizes,
   e.g. iPhone 6.9"/6.5" display and iPad 13"/12.9" for iOS; phone,
   7-inch and 10-inch tablet for Android if tablet support is declared).
   Check actual pixel dimensions of provided image files match the
   required resolution exactly — App Store Connect rejects mismatched
   dimensions outright.
   - Cross-check against this repo's `test/helpers/device_sizes.dart` —
     if the golden-test device set doesn't include the store-required
     screenshot dimensions, that's a separate gap worth flagging but
     don't conflate golden-test sizes with store screenshot requirements;
     they serve different purposes.
4. **Required fields present** — category, age rating / content rating
   questionnaire (see `TODO.md`'s App Store / Play Store checklist items),
   privacy policy URL, support URL. Flag any left blank or still a
   placeholder value.
5. **Privacy label consistency** — cross-check the data types declared in
   `TODO.md`'s "Play Data Safety" section (email, crash logs, device
   identifiers, push tokens, location if applicable) against what's
   actually entered in the store listing draft, if accessible. A
   mismatch here is a common rejection/compliance reason, not just
   cosmetic.
6. **Localization completeness** — if the project ships more than one
   locale (`app_en.arb` + others, via an l10n audit skill if one is
   available), confirm store metadata has a corresponding translated entry
   per locale rather than falling back to English everywhere.

On a fresh template there's typically **no store metadata tracked in-repo**
(no `ios/fastlane/metadata/`, `android/fastlane/metadata/`, or screenshots
under `assets/`/`docs/`). That's the expected first-run state — say so
explicitly and validate against content the user pastes (or re-run after
fastlane/store copy is added), rather than reporting a spurious pass.

Character/dimension limits change — prefer `WebSearch` for the current App
Store Connect / Play Console numbers; if WebSearch is unavailable, state the
limits are from training data and flag them as needing manual confirmation.

Report a pass/fail table per field/asset, flagging anything over a limit,
missing, still a placeholder, or with mismatched dimensions.
