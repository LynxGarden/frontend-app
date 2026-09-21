---
name: onboarding-flow-editor
description: Helps replace the placeholder onboarding steps (templates/optional/onboarding/) with real content/screens
---

# Onboarding Flow Editor

The onboarding template ships a working shell (progress dots, slide
transition, skip handling, `LocalStorageService`-backed completion flag)
with three placeholder steps. This skill helps swap in real content
without breaking the shell mechanics.

1. **Confirm the template is actually wired in**, not just present under
   `templates/optional/onboarding/` — check whether
   `lib/features/onboarding/` exists in the app's real `lib/` tree (i.e.
   the optional module was applied) and that `OnboardingScreen` is
   reachable from the router/splash flow (check `lib/core/router/app_router.dart`
   and wherever `onboardingSeenKey` is checked, typically in the splash
   screen's redirect logic). If it's not wired in yet, wire it in first
   and confirm with the user before editing content.
2. **Ask what the steps should communicate** — don't invent product copy.
   Get from the user: how many steps, what each should convey (value
   prop, permission priming, feature highlight), and whether steps need
   an illustration/image or are text-only.
3. **Edit `OnboardingStep` instances**, not the shell. The `_steps` list in
   `onboarding_screen.dart` is the only thing that should change for
   content updates — leave `OnboardingScreen`'s progress/transition/skip
   logic untouched unless the user explicitly wants shell behavior
   changed (e.g. removing the skip button, which has UX tradeoffs worth
   flagging — skip is generally good practice for onboarding).
4. **Per-step visuals** — if a step needs more than title+body text
   (illustration, animation, custom layout), don't cram it into
   `OnboardingStep.build()`'s generic column; either extend
   `OnboardingStep` with an optional `Widget Function(BuildContext)?
   builder` override, or replace it with bespoke per-step widgets if the
   steps diverge enough that a shared shape stops helping — the file's
   own doc comment already anticipates this.
5. **Permission-priming step ordering** — if a step exists to prime for a
   system permission (notifications, location, camera), the actual OS
   permission prompt must fire *after* this step, from a real user action
   on the following screen/step — not automatically when the priming step
   is shown. Cross-check this against `OneSignalService.requestPermission()`
   call sites if push notifications are enabled (see `verify-onesignal`).
6. **Design system compliance** — new step content must use
   `AppColors`/`AppTextStyles`/`AppSpacing`, and any new images belong
   under the project's existing asset convention (check `pubspec.yaml`'s
   `assets:` section and `assets/` folder structure) — don't hardcode a
   new asset path pattern.
7. **Re-verify the completion flag** — confirm `_finish()`'s
   `LocalStorageService.setBool(onboardingSeenKey, true)` call still runs
   exactly once, on both "Skip" and completing the last step, so the
   splash redirect never re-shows onboarding after first completion.

If the user wants A/B-testable or remotely-configurable onboarding content
instead of hardcoded steps, flag that as a larger architecture change
(remote config integration) rather than something to bolt onto this shell
silently.
