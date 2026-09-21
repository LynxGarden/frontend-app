---
name: check-dependencies
description: Runs pub outdated/dart pub deps, flags discontinued or major-version-behind packages and version conflicts
---

# Check Dependencies

1. Run `flutter pub outdated` and summarize: which packages are behind,
   by how much (patch/minor/major), and which are flagged discontinued.
2. For anything discontinued, check pub.dev for the recommended
   replacement and flag it — don't silently ignore it.
3. For major-version-behind packages actually used by this template
   (`flutter_timezone`, `sentry_flutter`, `purchases_flutter`,
   `powersync`, `flutter_stripe`, `onesignal_flutter`, etc.), a major bump
   can carry breaking API changes — if bumping, actually check the
   package's own changelog/migration guide before touching call sites, and
   verify the app still compiles + (for native-plugin packages) still
   builds for both platforms after the bump. A caret constraint
   (`^X.Y.Z`) silently resolving to a much newer major on a *fresh*
   `pub get` for a new clone is exactly the kind of drift this check
   exists to catch early.
4. **Dead / unbounded dependencies** (freshness isn't the only rot):
   - Cross-check every direct dependency in `pubspec.yaml` against actual
     `package:` imports in `lib/` (grep). Flag any declared dep with zero
     imports as a candidate dead dependency (e.g. a `geocoding`/
     `purchases_ui_flutter`/`cached_network_image` that nothing references),
     and any imported package missing from `pubspec.yaml`. `flutter pub
     outdated` alone will NOT catch these.
   - Flag any dependency using an `any` or otherwise-unbounded version
     constraint — on a fresh clone that can resolve to an arbitrary breaking
     major (worse than caret drift). It should be caret-pinned.
5. Run `dart pub deps` and look for version conflicts or packages pinned
   by a transitive dependency (e.g. `flutter_localizations` from the
   Flutter SDK pins `intl` to an exact version — a constraint mismatch
   there fails `pub get` outright with a clear message, but it's worth
   proactively checking after any SDK upgrade).
6. Summarize clearly: what's safe to bump now (patch/minor, no API
   surface change), what needs a manual changelog review before bumping
   (major, or a native plugin), and what's actively broken/discontinued
   and needs a decision.
7. Don't bump anything without asking first — this skill reports, it
   doesn't act unilaterally on dependency versions.
