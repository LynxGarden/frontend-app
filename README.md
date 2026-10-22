# Lynx

> **Train. Log. Progress.**

**Lynx** is a multi-tenant SaaS training & physiotherapy platform. Coaches build
an exercise library and programs, assign them to clients (as independent instance
copies), and clients train in the gym — logging actuals with a first-class
"last time" history. A **client record is not a user account**, so staff can
operate account-less clients.

This repo is the **Flutter client** for iOS + Android.

---

## Tech Stack

| Layer      | Technology                                                   |
| ---------- | ------------------------------------------------------------ |
| Framework  | Flutter (SDK `^3.10.8`)                                      |
| State      | Riverpod (code generation)                                   |
| Backend    | Supabase (auth, database, storage, edge functions)           |
| Navigation | GoRouter                                                     |
| Fonts      | Google Fonts — Bricolage Grotesque (headings) + Inter (body) |
| Env        | flutter_dotenv (`.env` files)                                |

The full architecture, design system, and business rules live in
[`CLAUDE.md`](./CLAUDE.md).

---

## Prerequisites

- **Flutter SDK** `^3.10.8` (developed on Flutter 3.47.0 stable)
- **Xcode** (for iOS) and/or **Android Studio** (for Android)
- A **Supabase** project (URL + publishable key)

---

## Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Create your env file from the example and fill in the required keys
cp .env.example .env
#    Required: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
#    (For the prod flavor, create .env.prod with the live values.)

# 3. Generate Riverpod/Freezed code
dart run build_runner build --delete-conflicting-outputs
```

> **Env keys** — see [`.env.example`](./.env.example) for every supported key.
> `SUPABASE_URL` is the API URL (`https://<ref>.supabase.co`), and
> `SUPABASE_PUBLISHABLE_KEY` starts with `sb_publishable_...` (not the legacy
> anon/JWT key).

---

## Running the app

The app ships two flavors, each with its own entrypoint and env file:

| Flavor   | Entrypoint           | Env file    | App name |
| -------- | -------------------- | ----------- | -------- |
| **dev**  | `lib/main_dev.dart`  | `.env`      | Lynx Dev |
| **prod** | `lib/main_prod.dart` | `.env.prod` | Lynx     |

The flavor is selected by the **entrypoint** (`bootstrap(Flavor.dev/prod)`), which
also picks the env file. On **Android** you must also pass `--flavor` (product
flavors are defined in `android/app/build.gradle`). On **iOS** there are no
per-flavor Xcode schemes, so **omit `--flavor`** (passing it errors with
_"The Xcode project does not define custom schemes"_).

```bash
# iOS — no --flavor
flutter run -t lib/main_dev.dart                    # dev
flutter run -t lib/main_prod.dart        # prod

# Android — --flavor required
flutter run --flavor dev  -t lib/main_dev.dart      # dev
flutter run --flavor prod -t lib/main_prod.dart  # prod
```

Pick a target device with `-d <device-id>` (list them via `flutter devices`).

---

## Tests

```bash
flutter test
```

---

## Project Structure

```
lib/
├── core/        # config, router, supabase client, theme, utils
├── features/    # auth, exercises, programs, clients, training, review, groups, ...
├── shared/      # reusable models, providers, widgets
└── main.dart    # shared bootstrap; main_dev.dart / main_prod.dart are flavor entrypoints
```

See [`CLAUDE.md`](./CLAUDE.md) for the full feature map, navigation graph, data
models, and design-system conventions.

---

## Related repos

- **`Lynx-docs`** — product/feature documentation (fumadocs).
- **`Lynx-backend`** — Supabase schema, RLS policies, and RPCs.
