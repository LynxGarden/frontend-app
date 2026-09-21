---
name: deep-link-tester
description: Walks every deep link the app declares and confirms each resolves to a real GoRoute, catching silent 404s
---

# Deep Link Tester

Deep links fail silently — an unmatched `GoRoute` just shows GoRouter's
default error screen (or does nothing) with no compile-time signal. This
skill cross-references every deep link the app *declares* against the
routes it actually *serves*.

1. **Enumerate declared deep links** from `lib/core/config/deeplink_config.dart`:
   - `DeepLinkConfig.verificationSuccessful` → path `/verification-successful`
   - `DeepLinkConfig.authCallback` → path `/auth/reset-password`
   - Any additional `Uri get ...` getters added to this file.
2. **Enumerate registered routes** by walking every `GoRoute(path: ...)`
   (including nested `routes:` — build the full path by prefixing with
   the parent path) in `lib/core/router/app_router.dart`.
3. **Match each deep link path against a registered route.** Report any
   deep link whose path has no corresponding `GoRoute` — this is the
   silent-404 case. `/auth/reset-password` should resolve to a top-level
   `GoRoute` rendering `ChangePasswordScreen`, with the router's redirect
   forcing the user there on a Supabase `passwordRecovery` event and back to
   `/home` once the password is set — if that route or the recovery redirect
   is missing (e.g. a hand-edited router), flag it. Grade severity by
   whether the link is actually *used*: a declared-but-never-called link
   (e.g. `authCallback` defined in `deeplink_config.dart` but never passed
   to a Supabase call) is a **latent** break (lower severity) vs an
   actively-used broken link.
4. **Check native platform registration** matches the same scheme/host:
   - iOS: `ios/Runner/Info.plist` (`CFBundleURLSchemes`) and, if universal
     links are used, `ios/Runner/Runner.entitlements` +
     `apple-app-site-association`.
   - Android: `android/app/src/main/AndroidManifest.xml` intent filters
     (`android:scheme`, `android:host`).
   Confirm the scheme/host values match `DeepLinkConfig.scheme`/`.host`
   per flavor. NOTE: in this template the manifest fields are build-time
   variables (`$(DEEPLINK_SCHEME)`/`$(DEEPLINK_HOST)` on iOS,
   `${deeplinkScheme}`/`${deeplinkHost}` on Android), NOT literals — that's
   correct, not a mismatch. Resolve them to their per-flavor definitions in
   `ios/Flutter/{Flavor}.xcconfig` and `android/app/build.gradle.kts`
   `productFlavors` before comparing; only flag if a resolved value
   disagrees with `DeepLinkConfig` or a flavor is missing a value (a
   manifest *hardcoded* to one flavor is the actual bug to look for).
5. **Check the incoming-link handler** — find where the app listens for
   incoming links (`app_links`/`uni_links`-style listener or Supabase's
   `onAuthStateChange` deep-link handling) and confirm it routes via
   `rootNavigatorKey`/the app's actual `GoRouter` instance, not a
   detached navigator. For password-recovery specifically, also confirm a
   Supabase `passwordRecovery` auth event is actually routed to a
   change-password screen — a valid route that nothing ever navigates to is
   still a dead end (the redirect logic may just treat the recovered
   session as authenticated and send the user to `/home`).
6. **Notification deep links** — if OneSignal is enabled, cross-check its
   `additionalData.route` values (see the `verify-onesignal` skill) against
   the same registered-routes list from step 2 — a notification route and
   a universal-link route can drift independently even though both
   ultimately call the same router.

Report a table: declared link → expected route → found/not found, plus any
scheme/host mismatches between `DeepLinkConfig` and native manifests.
