---
name: bump-version
description: Single-source-of-truth version/build-number bump across pubspec.yaml and store metadata
---

# Bump Version

1. Read the current `version:` line in `pubspec.yaml` (format
   `X.Y.Z+build`).
2. Ask the user whether this is a patch/minor/major bump, or take an
   explicit version if given.
3. Update `pubspec.yaml`'s `version:` field. Decide the build number:
   - If Codemagic is set up and CI derives build numbers itself (check
     `codemagic.yaml` for `--build-number=$(($(date +%s) / 60))` or an App
     Store Connect build-number lookup step), the local `pubspec.yaml`
     build number mostly matters for local `flutter run`/`flutter build`
     — bump it by 1, but tell the user CI will use its own scheme.
   - Otherwise, bump the build number by 1 as the source of truth.
4. If Shorebird is in use, remind the user that a version bump normally
   means a new **release** (`shorebird release`), not a patch — patches
   are for same-version Dart/asset-only fixes. Don't bump the version for
   a Shorebird patch.
5. If a `docs/` (Fumadocs) changelog page exists, offer to add an entry.
6. This does not touch App Store Connect / Play Console listing versions —
   those update automatically from the next build's `CFBundleShortVersionString`/
   `versionName`, which come from `pubspec.yaml`'s version via Flutter's
   build tooling. No separate manual step needed there.
