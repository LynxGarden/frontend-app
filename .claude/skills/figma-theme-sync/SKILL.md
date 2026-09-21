---
name: figma-theme-sync
description: Pulls Figma variables via MCP into app_colors.dart/app_text_styles.dart/app_spacing.dart
---

# Figma Theme Sync

No official Figma→Flutter-theme skill exists for this specific workflow —
this fills that gap using the Figma MCP server's tools directly.

Prerequisite: the Figma MCP server must already be connected (see
`CLAUDE.md`'s Figma section for the connection command). If not connected,
tell the user how to connect it instead of failing silently.

1. Use the Figma MCP's variable-inspection tool (e.g. `get_variable_defs`)
   against the Figma file URL in `CLAUDE.md` to pull the design system's
   color/typography/spacing variables.
2. Map Figma variable names to this template's existing structure:
   - Colors → `lib/core/theme/app_colors.dart` (`AppColors.primary`,
     `.background`, `.surface`, etc. — match by semantic name, not literal
     Figma variable name, since naming conventions rarely line up exactly).
   - Type scale → `lib/core/theme/app_text_styles.dart`
     (`AppTextStyles.heading1`/`.body`/etc.).
   - Spacing/radius → `lib/core/theme/app_spacing.dart`
     (`AppSpacing.*`/`AppRadius.*`).
3. Show the user a diff of proposed changes before applying — don't
   silently overwrite hand-tuned values without confirmation, since Figma
   variable names/values can be stale or a partial subset of what's
   actually used in code.
4. Preserve the existing class structure (`static const` fields with the
   same names) — this is a values update, not a restructuring. If the
   Figma file introduces a token with no existing counterpart, ask whether
   to add a new field or skip it.
5. If dark/light theme variants exist in Figma, make sure both map to the
   corresponding sections of `app_colors.dart`/`app_theme.dart` — don't
   just take the first mode found.
