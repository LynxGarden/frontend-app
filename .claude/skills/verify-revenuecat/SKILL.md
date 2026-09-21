---
name: verify-revenuecat
description: Audits entitlement/offering wiring against what RevenueCatService.hasEntitlement() actually checks
---

# Verify RevenueCat

The official RevenueCat AI Toolkit plugin covers dashboard ops (products,
entitlements, offerings config) — it can't see this template's client code.
This skill audits the wiring in `lib/core/purchases/revenue_cat_service.dart`
and its call sites.

1. **Init guarded** — `RevenueCatService.init()` should run inside a
   try/catch during bootstrap, not crash the app when
   `REVENUECAT_IOS_API_KEY`/`REVENUECAT_ANDROID_API_KEY` is unset. Confirm
   it throws a clear `StateError` (not a bare `!` force-unwrap) per this
   repo's fail-fast convention.
2. **Test-mode bypass is dev-only** — `RevenueCatService` treats simulators/
   emulators and `REVENUECAT_TEST_MODE=true` as always-entitled. Confirm
   `REVENUECAT_TEST_MODE` is never set to `true` in a prod-flavor `.env`
   file or a Codemagic prod env group — that would ship a build that
   bypasses paywalls for real users.
3. **Entitlement identifier consistency** — `hasEntitlement(String
   entitlementId)` takes a raw string. Grep every call site
   (`RevenueCatService.hasEntitlement(...)`) and confirm the same
   identifier string is used everywhere (e.g. `'premium'`) — a typo'd or
   inconsistent identifier silently fails every check since it just
   returns `false`, not an error. Flag if the identifier isn't defined
   as a single shared constant.
4. **Gating uses the check, not a cached flag** — confirm screens/routes
   that should be gated actually call `hasEntitlement()` (or an
   `AppGate`-style wrapper around it) rather than a one-shot value fetched
   once at splash and never refreshed after a purchase or restore
   completes.
5. **Paywall wiring** — if `lib/features/paywall/presentation/paywall_screen.dart`
   exists, confirm:
   - `getOfferings()` result is actually rendered (not just restore) —
     the shipped placeholder only wires "Restore purchases"; flag if a
     real project never added a purchase button calling
     `purchasePackage()`.
   - The entitlement identifier referenced in this screen's copy/logic
     matches the one used by the gating check in step 3.
6. **Post-purchase refresh** — after `purchasePackage()` or `restore()`
   succeeds, confirm the app re-checks entitlement state (e.g. invalidates
   a Riverpod provider wrapping `hasEntitlement()`) rather than requiring
   an app restart to unlock content.
7. **Backend contract documented** — if this project also uses RevenueCat
   webhooks server-side, confirm `TODO.md` (or equivalent) documents the
   webhook contract; flag silently if this project has no backend
   involvement (client-only entitlement checks are a valid, common setup).

Report each check as pass/fail with file/line references.
