---
name: sentry-setup
description: Drives Sentry CLI login and project creation against the development@thecalda.com org, writes the DSN back into env files
---

# Sentry Setup

This is the one piece the official Sentry Claude plugin doesn't cover:
actually creating a Sentry project for a *new* app and wiring its DSN in.
Use this when a project has the Sentry integration selected but no real
DSN yet (check `.env`/`.env.*` — `SENTRY_DSN=` empty or missing).

For ongoing Sentry work on an already-configured project (PR review,
triaging issues), tell the user to install the official plugin instead
(`claude.com/plugins/sentry` / `getsentry/skills`) — don't duplicate that
here.

1. Check whether the Sentry CLI is authenticated:
   `sentry-cli info` (fails if not logged in).
2. If not authenticated, run `sentry-cli login` — this requires an
   interactive browser flow the user must complete themselves against the
   `development@thecalda.com`-owned Sentry org. Tell them clearly what's
   about to happen before running it; don't run it silently.
3. Once authenticated, create the project:
   `sentry-cli projects create --org <org-slug> <project-slug> --platform flutter`
   (ask the user for the org slug if it's not obvious — usually visible in
   the Sentry dashboard URL).
4. Retrieve the DSN for the new project (via `sentry-cli` or by asking the
   user to copy it from the dashboard's project settings — the CLI doesn't
   always expose it directly depending on version).
5. Write the DSN into the correct `.env`/`.env.{flavor}` file(s) — ask
   which environment (staging/prod) this project is for if flavors are in
   use, since staging and prod should generally be separate Sentry
   projects, not one shared DSN.
6. Remind the user this also needs adding to the matching Codemagic env
   var group (`SENTRY_DSN`) if CI is set up — check `codemagic.yaml`'s
   header comment for the exact group name.
7. Tick off the corresponding `TODO.md`/`TODO_PRODUCTION.md` item once done.
