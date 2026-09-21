---
name: verify-onesignal
description: Checks OneSignal init wiring, permission flow, and the notification-click routing contract
---

# Verify OneSignal

The official OneSignal MCP server handles dashboard operations (send/check
delivery/segments) but can't audit code — that's what this skill is for.

Check `lib/core/notifications/onesignal_service.dart` and its call sites:

1. **Init guarded** — `OneSignalService.init()` should be called inside a
   try/catch in `lib/bootstrap.dart` (or wherever bootstrap logic lives),
   not left to crash the app if `ONESIGNAL_APP_ID` is unset.
2. **Click → route wiring** — confirm `OneSignal.Notifications.addClickListener`
   is registered and that `OneSignalService.onNotificationRoute` is actually
   assigned somewhere in `bootstrap.dart` (this closes a real gap — neither
   of this template's reference apps had click→navigation wiring at all).
   Confirm the assignment uses the app's actual root navigator/router
   (check `rootNavigatorKey` in `lib/core/router/app_router.dart` is used,
   not a dead/unused callback).
3. **Permission request flow** — find where `OneSignalService.requestPermission()`
   is called; it should happen after a deliberate user action or onboarding
   step, not unconditionally at app launch (poor UX / lower opt-in rates).
4. **User identity linking** — if auth is present, confirm push targeting
   follows the signed-in user. When OneSignal + auth are both selected the
   wizard auto-wires this in `bootstrap.dart`: an immediate
   `setUserId(currentUser.id)` for a session already restored at launch,
   plus a `SupabaseClientWrapper.auth.onAuthStateChange` listener that calls
   `setUserId(user.id)` when a session is present and `clearUser()` when it's
   null (login, logout, and account deletion all covered by session
   presence). Confirm that listener exists; if it's missing (e.g. a
   hand-edited bootstrap), that's the gap — `setUserId`/`clearUser` defined
   but never called.
5. **Account deletion clears identity** — the session-presence rule above
   only fires if the deletion flow actually ends the session. If the app has
   a custom-API delete-account endpoint (grep `ApiClient` calls / route
   names like `delete-account`, `deleteAccount`, `account/delete`, `close`,
   `deactivate`), confirm that path either calls `SupabaseClientWrapper.auth.signOut()`
   afterward **or** calls `OneSignalService.clearUser()` directly. A server
   deletes the user without a local sign-out — the local session lingers
   until token refresh fails, so OneSignal keeps targeting a deleted user
   (push to a ghost, privacy leak) until then. Flag any delete-account call
   site that doesn't end the session or clear OneSignal.
6. **Backend contract documented** — `TODO.md`'s OneSignal section should
   state the `additionalData.route` contract; flag if it's missing or the
   docs and code have drifted (e.g. code reads a different key name).

Report each check as pass/fail with file/line references.
