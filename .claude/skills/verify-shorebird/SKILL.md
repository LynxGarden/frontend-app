---
name: verify-shorebird
description: Checks shorebird.yaml app IDs are real (not placeholders) and patch/release workflow consistency
---

# Verify Shorebird

Nothing official exists for Shorebird + Claude Code — this stays fully in scope.

Check:

1. **Placeholder IDs** — `shorebird.yaml`'s `app_id` and any `flavors:`
   entries should not still read `REPLACE_WITH_REAL_APP_ID` /
   `REPLACE_WITH_REAL_FLAVOR_APP_ID` (the wizard's generated placeholders).
   If they are, the user hasn't run `shorebird init` yet — flag this
   clearly and point at the relevant `TODO.md`/`TODO_PRODUCTION.md` item.
2. **Flavor coverage** — first derive the authoritative flavor list from a
   cross-reference (the `codemagic.yaml` env groups / `--flavor` args, or the
   CLAUDE.md "Flavors" section), not from `shorebird.yaml` alone — otherwise
   you can't tell an under- or over-count. Then confirm every flavor has an
   entry under `shorebird.yaml`'s `flavors:` map (or, if there's exactly one
   flavor, the top-level `app_id` alone is correct and no `flavors:` map is
   needed — don't flag that as an error).
3. **Release vs. patch workflow pairing** — in `codemagic.yaml`, every
   flavor/platform combination with a `shorebird release` workflow should
   also have a matching patch workflow. Pair release↔patch by the actual
   `--flavor` value and platform in the shorebird command, not solely by the
   workflow name — a renamed-but-correct workflow shouldn't be flagged.
   They're deliberately separate per-platform (native/dependency state can
   diverge between iOS and Android releases cut at different times) — flag
   if someone merged them back into one workflow, since that breaks the
   Shorebird patch contract.
4. **`--target` consistency** — the `--target lib/main_{flavor}.dart` (or
   `lib/main.dart` if no flavors) in each `shorebird release`/`shorebird patch`
   command should match the actual entrypoint file that exists in `lib/`.
5. **Patches carry no native changes** — this can't be fully verified from
   code, but remind the user of the rule (Dart/asset changes only) if
   they're asking this skill to review a patch workflow run.

Report each check as pass/fail with the specific file/line for any failure.
