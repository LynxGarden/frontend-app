---
name: verify-stripe
description: Audits the client-side Payment Sheet wiring and flags if the /create-payment-intent backend contract isn't documented
---

# Verify Stripe

The official Stripe plugin covers dashboard ops. This skill audits the
client-side wiring in `lib/core/payments/stripe_service.dart` and its call
sites — this repo does no backend work, so the server side of the contract
can only be checked for whether it's *documented*, not whether it's
correctly implemented.

1. **Init guarded** — `StripeService.init()` should run inside a try/catch
   during bootstrap, not crash the app when `STRIPE_PUBLISHABLE_KEY` is
   unset. Confirm it throws a clear `StateError`, not a bare `!`
   force-unwrap.
2. **Publishable key, not secret key** — grep the whole repo (`.env*`,
   Codemagic env groups, Dart source) for anything that looks like a
   Stripe secret key (`sk_live_`/`sk_test_`) or webhook signing secret —
   those must never exist client-side. Flag immediately if found.
3. **Backend contract documented** — `presentPaymentSheet()` expects a
   `POST /create-payment-intent` endpoint returning `{"clientSecret":
   "..."}`. Check `TODO.md` (or wherever backend contracts are tracked,
   e.g. the OneSignal `additionalData.route` contract is documented in
   `TODO.md`'s OneSignal section) for a Stripe section documenting this
   endpoint, its auth requirements, and the amount/currency it expects.
   Flag if it's missing — the endpoint existing only on the backend with
   no doc trail is the actual gap this skill exists to catch.
4. **Amount handling** — confirm `amountCents` is always an integer number
   of the smallest currency unit (cents), and that the UI layer isn't
   accidentally passing a dollar amount (e.g. `9.99` instead of `999`) —
   check call sites of `presentPaymentSheet(amountCents: ...)`.
5. **Merchant display name** — `merchantDisplayName: 'Your App Name'` is a
   placeholder in the template; flag if it's still literally that string
   rather than the real app name.
6. **Error handling** — confirm `StripeException` and non-`isSuccess`
   API responses are both caught and rethrown as `AppException` with a
   user-friendly message (never a raw Stripe error surfaced directly to
   the UI), and that the calling screen shows it via `AppToast.show()`
   rather than swallowing it silently.
7. **Test mode discipline** — confirm the prod-flavor `.env`/Codemagic env
   group uses a `pk_live_` key and staging uses `pk_test_`, not the
   reverse, and that there's no test-mode bypass equivalent to
   RevenueCat's (Stripe's SDK has no such concept, but check for any
   custom "skip payment" debug flag that could ship enabled to prod).

Report each check as pass/fail with file/line references.
