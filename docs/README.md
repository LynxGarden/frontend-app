# Lynx App — Documentation

Scope, architecture, and delivery plan for the **Lynx** training & physiotherapy platform (Flutter client for iOS + Android). This folder is the app-side source of truth. Backend/database docs live in the [`Lynx-backend`](https://github.com/LynxGarden/backend-supabase) repo under `docs/`.

**At a glance:** a **multi-tenant SaaS** (Lynx Center is tenant #1, sellable to other gyms later) with **one shared backend** behind three surfaces — the Flutter app, the website (`Lynx-website`, which hosts login + the coach/admin dashboard), and Supabase. **Unified auth**: email magic link + Google SSO + Apple SSO. Shipped in **English + Slovenian**.

> Derived from `Lynx-App-Scope-Brief-v0.2.md`. Where this document and the brief disagree, the brief's intent wins — flag the conflict in [`06-open-questions.md`](06-open-questions.md).

## Index

| # | Doc | What it covers |
|---|-----|----------------|
| 00 | [Overview](00-overview.md) | Vision, the v1 hero, scope tiers, what this repo does and does not own |
| 01 | [Architecture](01-architecture.md) | Stack, layering, Riverpod / go_router / Supabase conventions, roles, data flow |
| 02 | [Navigation & UI](02-navigation-and-ui.md) | Platform-adaptive Cupertino tab bar, responsive strategy, branding tokens, theming |
| 03 | [Roadmap & Checkpoints](03-roadmap-and-checkpoints.md) | The phased plan — CP0…CP6 for v1, plus v1.x, with acceptance criteria |
| 04 | [Training Engine](04-training-engine.md) | Detailed v1 feature spec mapped to screens, state, and data |
| 05 | [CRM & Later Scope](05-crm-and-later.md) | v1.x/later: leads pipeline, entitlements, physio chart, permissions, tasks |
| 06 | [Open Questions](06-open-questions.md) | Decisions still owed, with owners |
| 07 | [Getting Started](07-getting-started.md) | Dev setup — run the local backend + app, flavors, what CP0 built |

## The one-line summary

> A coach builds a training program from their exercise library, assigns it to a client, and the client trains in the gym on their phone — seeing the target, the video, and **what they did last time**, and logging today's actual sets/reps/weight/time. The coach then reviews what was completed.

Everything in v1 serves that loop. The CRM is designed for but mostly deferred to v1.x.

## Repos & environments

| Thing | Location |
|-------|----------|
| This app | `/Users/matevzmiskec/PersonalProjects/Lynx-app` → `LynxGarden/frontend-app` |
| Backend (Supabase) | `/Users/matevzmiskec/PersonalProjects/Lynx-backend` → `LynxGarden/backend-supabase` |
| Reference website (branding) | `/Users/matevzmiskec/PersonalProjects/Lynx-website` → https://lynxgarden.github.io/frontend-website/ |
| Flutter starter template (base) | `/Users/matevzmiskec/CaldaProjects/flutter-starter/calda-flutter-starter` |
| Cupertino navbar reference | `/Users/matevzmiskec/CaldaProjects/kaddy-frontend` |
