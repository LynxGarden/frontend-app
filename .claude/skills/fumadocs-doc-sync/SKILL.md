---
name: fumadocs-doc-sync
description: Flags stale docs/content/docs/*.mdx pages against recent lib/features/ changes and helps regenerate them
---

# Fumadocs Doc Sync

Keeps `docs/content/docs/*.mdx` from drifting out of sync with the app as
it evolves — the problem the old `mintlify-doc-sync` reference (back when
this template used Mintlify) gestured at but was never actually built.
Fumadocs is open source with no official Claude Code plugin to lean on
instead, so this stays fully in scope.

Use when the user asks to "sync the docs", "update the docs site", or
after landing a feature that clearly changes user-facing behavior.

1. Read `CLAUDE.md` for the current feature list, architecture, and
   business rules — the source of truth for what the app does. **If its
   Features section is still `TODO`/placeholder (fresh template), note that
   and derive the feature list from `lib/features/*` directly instead.**
2. Read `docs/content/docs/meta.json` for the existing page list.
3. Check staleness: map each doc page to a feature by slug (a page whose
   slug matches a `lib/features/<feature>/` dir). Generic pages like
   `index`/`getting-started` map to no feature — exempt them from the
   per-feature staleness check. For a mapped page, compare its last-commit
   date against the feature's last change:
   `git log -1 --format=%cs -- lib/features/<feature>/` vs the page file's
   last commit date — a page older than substantive feature commits is
   stale (more reliable than eyeballing `--oneline` subjects).
4. Check coverage gaps: any `lib/features/*` folder with no corresponding
   doc page is a candidate for a new one — ask the user whether it needs
   end-user-facing docs (not every internal feature does; `utility` — force
   update / maintenance / no-connection — usually doesn't).
5. Show a diff of proposed content changes before writing — this is
   documentation prose, not generated boilerplate; don't silently
   overwrite hand-tuned wording.
6. If adding a new page, create `docs/content/docs/{slug}.mdx` with
   Fumadocs frontmatter (`title`, `description`) and append `{slug}` to
   `docs/content/docs/meta.json`'s `pages` array — array order is the
   sidebar order.
7. Remind the user to preview locally (`cd docs && npm run dev`) before
   pushing — this is a real Next.js build, not markdown a hosted service
   renders for you.

Complements `bump-version` (which offers a changelog entry on version
bumps) — this skill handles ongoing content drift, not releases. For
deploying changes once they're ready, see `docs-deploy`.
