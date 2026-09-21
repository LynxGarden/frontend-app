---
name: docs-deploy
description: Splits docs/ into its own GitHub repo and deploys it to GitHub Pages, following docs/DEPLOYMENT.md
---

# Docs Deploy

Operationalizes `docs/DEPLOYMENT.md` — use when the user asks to "deploy
the docs", "publish the docs site", or "set up GitHub Pages for docs".

This creates a new GitHub repo and pushes code to it. Confirm with the
user before running the repo-creation/push commands below — same as any
other action with real, externally-visible side effects.

1. Confirm `docs/` has the Fumadocs scaffold (`docs/package.json`,
   `docs/next.config.mjs`) — if not, Fumadocs wasn't selected in the
   wizard; tell the user to re-run `dart run bin/setup.dart` and pick it,
   or scaffold `templates/optional/fumadocs/docs/` by hand.
2. Check whether `docs/` is already its own git repo (`docs/.git` exists)
   — if so, skip to step 5.
3. Ask the user for the new repo's name (suggest `<package-name>-docs`,
   using the `name:` field in `pubspec.yaml`) and visibility
   (public/private).
4. Initialize and push:
   ```bash
   cd docs
   git init
   git add -A
   git commit -m "Initial commit"
   gh repo create <name> --public --source=. --remote=origin --push
   ```
   If `gh auth status` fails (not authenticated), fall back to manual
   steps: create the repo on github.com, then
   `git remote add origin <url> && git branch -M main && git push -u origin main`.
5. Enable GitHub Pages — this isn't reliably scriptable across `gh`
   versions, so tell the user to go to **Settings → Pages** on the new
   repo and set **Source** to **GitHub Actions**. The workflow at
   `docs/.github/workflows/deploy.yml` is already scaffolded.
6. If Pages was enabled *after* the initial push in step 4, that first
   push ran before Pages could receive it — trigger a redeploy with
   `gh workflow run deploy.yml` (or push an empty commit).
7. Watch the deploy with `gh run watch`, or point the user at the repo's
   **Actions** tab. Report the live URL
   (`https://<org-or-user>.github.io/<repo-name>/`) once it completes.
8. Tick off the corresponding `TODO.md`/`TODO_PRODUCTION.md` Fumadocs
   items once done.

See `docs/DEPLOYMENT.md` for why the static export needs
`basePath`/`output: 'export'`/the static search route, and its
troubleshooting table if something 404s after deploy.
