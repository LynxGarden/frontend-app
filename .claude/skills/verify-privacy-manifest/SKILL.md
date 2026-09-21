---
name: verify-privacy-manifest
description: Checks iOS PrivacyInfo.xcprivacy declares every required-reason API actually used, and cross-checks Android Data Safety
---

# Verify Privacy Manifest

Apple's required-reason API list changes over time — the wizard's
generated `ios/Runner/PrivacyInfo.xcprivacy` is best-effort, not
guaranteed correct. This skill re-checks it against actual usage.

## iOS

1. Read `ios/Runner/PrivacyInfo.xcprivacy`'s declared
   `NSPrivacyAccessedAPITypes`.
2. Grep `lib/` and any native code under `ios/Runner`/`macos/Runner` for
   usage patterns Apple currently classifies as "required reason" APIs
   (this list changes — check Apple's current docs rather than memorized
   categories). Concrete grep patterns to start from:
   - UserDefaults: `UserDefaults`, `shared_preferences` (always present here)
   - DiskSpace: `volumeAvailableCapacity`, `systemFreeSize`, `NSFileSystemFreeSize`
   - FileTimestamp: `contentModificationDate`, `creationDate`, `\.stat\(`
   - SystemBootTime: `systemUptime`, `kern.boottime`, `mach_absolute_time`
   - ActiveKeyboard: `activeInputModes`
   **Crucial:** only *first-party* usage (in `lib/` and `ios/Runner`) needs
   an app-level declaration. Third-party SDKs (Sentry, OneSignal, RevenueCat)
   ship their OWN `PrivacyInfo.xcprivacy` under `ios/Pods/**` which Xcode
   merges at build — grep `ios/Pods/**/PrivacyInfo.xcprivacy` to confirm an
   SDK covers itself, and do NOT flag an SDK's internal API use as a missing
   app-level declaration.
3. Flag any first-party usage with no matching declaration (under-declaration
   — the risky case). Also flag a declaration with no first-party usage AND
   not required by any bundled SDK manifest as **removable-but-benign**
   over-declaration — worth trimming, but not a submission blocker (Apple
   accepts extra declarations).
4. Remind the user this file needs a final human review against Apple's
   *current* required-reason API list before App Store submission — this
   skill's checks are a starting point, not a compliance guarantee.

## Android

No manifest file for this — Play Data Safety is filled in the Play
Console UI. Instead:

1. Read `TODO.md`/`TODO_PRODUCTION.md`'s "Play Data Safety" section.
2. Cross-check the listed data types against what's actually collected per
   the selected integrations (Supabase auth → email/user ID, Sentry →
   crash logs/device identifiers, OneSignal → push tokens, location
   services → precise/approximate location). Flag any mismatch between
   what's documented and what's actually wired in code.
