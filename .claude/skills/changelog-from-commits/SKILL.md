---
name: changelog-from-commits
description: Maintains a CHANGELOG.md from conventional commits, for projects that adopt that convention
---

# Changelog From Commits

Unlike `release-notes-generator` (short, user-facing, per-release), this
maintains a developer-facing `CHANGELOG.md` in [Keep a Changelog](https://keepachangelog.com)
style — complete, technical, and cumulative.

1. **Confirm the convention is actually in use.** Check recent history
   (`git log --oneline -30`) for `feat:`/`fix:`/`chore:`/`refactor:`/
   `docs:`/`test:`/`perf:` prefixes. If the project doesn't consistently
   use Conventional Commits, say so and ask whether to (a) proceed anyway
   by inferring type from the diff, or (b) skip this skill in favor of
   `release-notes-generator`.
2. **Locate or create `CHANGELOG.md`** at the repo root. If it doesn't
   exist, scaffold it with a `## [Unreleased]` header and a link-reference
   footer style if the project uses git tags for versions.
3. **Determine the range** to process: everything after the last entry
   already recorded in `CHANGELOG.md` (find the last documented commit
   hash/tag) through `HEAD`.
4. **Group by Conventional Commit type into Keep a Changelog categories:**
   - `feat:` → **Added**
   - `fix:` → **Fixed**
   - `refactor:`/`perf:` → **Changed**
   - `deprecate`-flagged commits → **Deprecated**
   - commits removing a feature → **Removed**
   - `chore:`/`docs:`/`test:`/CI-only commits → omit entirely (internal,
     not user- or consumer-facing)
5. **One entry per commit**, written from the commit message but cleaned
   up (imperative mood, no scope prefix in the final text, capitalized).
   Squash-merge commits that bundle multiple unrelated changes should be
   split into separate entries if the diff makes the split obvious.
6. **Version headers** — when the user confirms a version is being cut,
   move `[Unreleased]` entries under a new `## [X.Y.Z] - YYYY-MM-DD`
   header matching the version being set in `pubspec.yaml`, and start a
   fresh empty `[Unreleased]` section above it.
7. **Never rewrite history that's already in the file** — only append new
   entries above the last-processed point; don't reformat or re-derive
   past releases unless explicitly asked.

This is additive/cumulative by design — don't regenerate the whole file
from `git log` every time, only the delta since the last run.
