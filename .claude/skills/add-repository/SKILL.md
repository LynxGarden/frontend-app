---
name: add-repository
description: Scaffolds a Supabase-backed data layer (model + repository + provider) for a table, following the template's repository-pattern rules
---

# Add Repository

Scaffolds the `data/` layer the template deliberately leaves empty, following
CLAUDE.md's rules exactly so table access never leaks into the UI. Use when
adding a feature that reads/writes a Supabase table. Ask for the table name and
its columns (or infer from a Supabase schema the user pastes) if not given.

Generate three files under the owning feature (`lib/features/<feature>/data/`,
or `lib/shared/` if cross-feature). snake_case filenames, PascalCase classes.

1. **Model** — `data/models/<name>.dart`
   - Immutable class with a `fromJson(Map<String, dynamic>)` factory and (if
     writes are needed) `toJson()`.
   - Parse only the explicit columns the repository selects — never assume a
     shape. Provide sensible fallbacks for nullable/enum fields (enum
     `fromString` with a default). NOTE: the template ships no `fromJson`
     model to copy (its only model, `AppConfig`, is built from a key/value
     map) — establish the pattern here rather than looking for an existing one.

2. **Repository** — `data/<name>_repository.dart`
   - Default to a class with **static methods** (mirrors the template's static
     `SupabaseClientWrapper`); offer an injectable `Provider<XRepository>`
     variant only if the user wants to swap it in tests. Wrap
     `SupabaseClientWrapper.db('<table>')`.
   - **Explicit column selection always**: `.select('col1, col2')`, never
     `.select()` / `.select('*')` (CLAUDE.md rule #9).
   - Wrap every call in try/catch and throw `AppException`
     (`lib/core/utils/app_exception.dart`) with a friendly message — never let
     a raw PostgREST/Supabase error reach the UI (rule #7). The UI layer
     catches it and shows `AppToast.show()`.
   - Methods return domain models (`Future<List<Name>>`, `Future<Name?>`),
     not raw maps.

3. **Provider** — `providers/<name>_provider.dart` (or alongside the repo)
   - `FutureProvider` for one-shot async reads, `StreamProvider` for realtime
     (`.stream(primaryKey: [...])`). NOTE on the realtime builder chain: with
     `.stream()`, any `.eq(...)` filter must come BEFORE `.order(...)`/`.limit(...)`
     (SDK builder ordering) or it won't compile. Riverpod code-gen is available — if the
     project uses `@riverpod` elsewhere, match it and remind the user to run
     `dart run build_runner build`; otherwise use a plain
     `FutureProvider`/`StreamProvider` like the template's
     `app_config_provider.dart`.

Rules to hold to (all from CLAUDE.md):
- Supabase is **never** called from a widget — only from the repository.
- Tokens/sensitive values go through `SecureStorageService`, never
  `LocalStorageService`/`shared_preferences`.
- This repo does **no** SQL/migration work — do NOT create the table or write
  DDL. Note in the output that the user must create the `<table>` (with columns
  + RLS) via the official Supabase agent skills
  (`npx skills add supabase/agent-skills`), and add it to `TODO.md`.

After generating, run `flutter analyze` on the new files. Offer to wire the
provider into the relevant screen, but keep the widget calling the provider,
not Supabase directly.
