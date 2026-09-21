---
name: release-notes-generator
description: Drafts App Store/Play release notes from the commit range since the last tag
---

# Release Notes Generator

Turns raw commit history into short, user-facing release notes — the
audience is app users deciding whether to update, not developers reading
a diff.

1. **Find the range.** `git tag --sort=-v:refname | head -1` (version-semantic
   order; falls back sensibly for lightweight tags — `git describe --tags`
   also works) for the last release tag. If no tags exist yet, use the
   version-bump history in `pubspec.yaml` (`git log -p -- pubspec.yaml`, find
   the last commit that changed the `version:` line). **Terminal case:** if
   that last version-changing commit IS the initial commit (version never
   bumped) or the range resolves to the whole history, don't proceed on the
   whole history — say so and ask the user for an explicit base ref. Diff
   against `HEAD` (or a ref the user specifies).
2. **Pull the commit log** for that range: `git log <range> --oneline`.
   If commits follow Conventional Commits (`feat:`, `fix:`, `chore:`,
   etc. — check recent history first, this repo generally does), group by
   type; otherwise read full messages/diffs to infer intent.
3. **Filter ruthlessly.** Release notes are not a changelog:
   - Drop `chore:`, `refactor:`, `test:`, `docs:`, CI/tooling commits, and
     anything internal (dependency bumps, lint fixes) — users don't care.
   - Keep only **user-facing** `feat:`/`fix:`. A `feat:` on developer tooling,
     setup/wizard, or CI is NOT a release-note item — drop it like a `chore:`.
   - Merge multiple commits that describe one user-facing change into a
     single bullet.
   - **Allowed outcome:** if nothing in range is a user-facing app change
     (e.g. a starter template, or a tooling-only cycle), output "No
     user-facing changes in this range" — do NOT promote internal/tooling
     commits into bullets to fill space.
4. **Rewrite in user language.** Translate implementation detail into
   outcome. "feat: add debounce to search input" → "Search feels
   snappier." Never mention file names, class names, or internal
   mechanisms.
5. **Match platform constraints:**
   - App Store "What's New": no hard character limit but keep each bullet
     to one line; Apple discourages marketing fluff in this field.
   - Google Play "What's new": 500 character limit for the whole field —
     if the draft exceeds it, cut to the highest-impact 3-5 bullets and
     say so explicitly rather than silently truncating.
6. **Tone** — short, plain-language bullets starting with a verb ("Added",
   "Fixed", "Improved"), no jargon, no emoji unless the project's existing
   release notes use them (check App Store Connect / Play Console history
   if the user can share it).
7. **Output both variants** (App Store + Play) since Play's length limit
   often forces a shorter cut than App Store's.

Don't invent features that aren't in the commit log — if a commit message
is too vague to translate confidently (e.g. `fix: bug`), read the actual
diff before guessing what it means, or ask the user.
