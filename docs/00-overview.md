# 00 · Overview

## Context — why this project exists

Lynx Center needs an all-in-one training and physiotherapy platform. Today the pieces (programming, client records, physio notes, membership tracking) live in scattered tools or in people's heads. The brief (`Lynx-App-Scope-Brief-v0.2`) sets a dual goal:

1. **Serve Lynx now** — get coaches building programs and clients training on their phones by the launch window.
2. **Keep the door open to sell later** — build cleanly and modularly on a data model that could become a product for other gyms, without paying the full cost of a sellable product before it's proven.

Every scope decision is weighed against both.

### This is a SaaS product, multi-tenant from day one

Lynx is **not** a one-off app for a single gym — it's a **SaaS product** that Lynx Center is the first customer of. The data layer is **multi-tenant** (every row scoped to a `tenant`, isolated by row-level security) from the very first migration, so the same backend can later serve many independent studios without re-architecting. Lynx Center is **tenant #1**. See [`Lynx-backend/docs/00-data-model.md` → Multi-tenancy](../../Lynx-backend/docs/00-data-model.md#multi-tenancy-saas).

### One backend, three surfaces

The app, the **website** (`Lynx-website`), and the Supabase backend all share **one auth system and one database**:

- **Flutter app** (iOS + Android) — clients train; coaches/physios manage on mobile.
- **Website** — marketing site **plus** the login entry point and the coach/admin **dashboard** (the dashboard grows over time). Login lives top-right on every page.
- **Supabase** — Postgres + Auth + Storage shared by both.

**Sign-in is unified across app + web:** email **magic link** (passwordless) + **Google SSO** + **Apple SSO**. See [01 · Architecture → Auth](01-architecture.md).

### Languages

The product ships in **English and Slovenian** (`en` / `sl`), for both the app and the website. Everything is built i18n-ready so more languages (and per-tenant default locale) can follow.

## The v1 launch hero

**The one thing v1 must do well:**

> A coach builds a training program from their own exercise library, assigns it to a client (adjusting it for that client), and the client trains in the gym on their phone — seeing the target, watching the exercise video if needed, seeing what they did last time, and logging today's actual sets, reps, weight, and time. The coach then sees what was completed.

The shared spine between the training half and the (later) CRM half is the **client record**, so a minimal version of that record ships in v1.

## Scope for THIS repo

Confirmed decisions for this planning round:

- **Platform:** native **iOS + Android**, built in **Flutter**. (The brief floats PWA-vs-native as an open question; for this build we commit to native Flutter.)
- **v1 target:** the **full §4 training engine** ships in the Flutter mobile app — exercise library, program builder, assignment, the client daily loop, and coach review. This is ambitious for the launch window; see [roadmap](03-roadmap-and-checkpoints.md) for the go/no-go checkpoint that de-risks it.
- **Coach role runs on mobile too.** Coaches build libraries and programs *in this app* on their phone (responsive, works on tablet). The richer coach/admin **web dashboard** now lives in the **website** (`Lynx-website`) on the shared backend — it is no longer a separate future project, though the full web builder still grows post-v1.
- **CRM** (§5) is designed-for but deferred: the schema is built extensible now, the UI lands in v1.x.
- **Multi-tenant SaaS** from the first migration (see above).
- **Auth:** shared across app + web — email magic link, Google SSO, Apple SSO.
- **Languages:** **English + Slovenian**, i18n-ready from commit one.
- **Connectivity:** online-only for v1 (no offline mode).

### In scope (v1)

| Area | Summary | Detail |
|------|---------|--------|
| Accounts & roles | owner/admin, coach, physio, client — plus client records with **no login** | [04](04-training-engine.md) |
| Exercise library | coach-owned, video + description + tags, full CRUD | [04](04-training-engine.md) |
| Program builder | ordered sessions → ordered exercises with prescriptions; save as templates | [04](04-training-engine.md) |
| Assignment | template → **editable per-client copy** (an instance, not a reference) | [04](04-training-engine.md) |
| Client daily loop | pick session, target + video + **last-time**, log actuals, swap exercise, mark complete | [04](04-training-engine.md) |
| "Last time" history | per-client, per-exercise — **the priority feature**, first-class from day one | [04](04-training-engine.md) |
| Coach review | web/mobile review of completed sessions & actuals (review-on-login, not realtime) | [04](04-training-engine.md) |
| Groups / rosters | one program to a group, individual logging per athlete | [04](04-training-engine.md) |
| Minimal client record | basic profile + **safety health-screening flags** | [04](04-training-engine.md) |

### Out of scope for v1 (designed-for, deferred)

- Lead → meeting → sale pipeline (§5.2) — *v1.x, candidate to pull forward*
- Membership/entitlement engine with freezes/holds/renewals (§5.5) — *v1.x*
- Physio clinical chart / SOAP notes (§5.4) — *v1.x, design now with Urban*
- Granular per-user permissions (§5.8) — *v1.x*
- Staff reminders & recurring task workflows (§5.9–5.10) — *v1.x*
- Operational action-list dashboards (§5.7) — *v1.x*
- Coach ⇄ client chat, calendar, client-facing stats — *v1.x*

### Explicitly not now (parked)

- Full coach **web** program builder (the website hosts login + a starter dashboard now; the rich builder grows post-v1)
- Tenant self-service onboarding / signup for *other* gyms (the SaaS multi-tenant schema is in place; the onboarding UI is v1.x+)
- Payments/invoicing (integrate a provider later; never build — Slovenian fiscal / davčna blagajna)
- Booking beyond the gym "cap the hour" minimum
- Business-intelligence dashboards (revenue, LTV, utilization)
- Session packs & drop-ins as entitlement types
- Wearables / health-app sync
- Actively **reselling to other gyms** (go-to-market) — the multi-tenant *schema* ships day one, but onboarding real external tenants is later
- Onboarding module (Robin to spec separately)

## Roles at a glance

| Role | Uses | Can do (v1) |
|------|------|-------------|
| **owner/admin** | mobile | everything a coach can, plus user management |
| **coach** | mobile | build exercise library & programs, assign to clients, review completed work, manage safety flags |
| **physio** | mobile | shares the client record; clinical chart is v1.x |
| **client** | mobile | train the assigned program, log actuals, see own history |
| **account-less client** | — | has a full record operated **on their behalf** by a coach/physio; never logs in |

## Key product principles (from the brief)

- **Multi-tenant SaaS.** Every domain row belongs to a `tenant`; RLS guarantees one gym never sees another's data. Roles below are scoped *within* a tenant.
- **Client record ≠ user account.** Records exist from the lead stage, before any login. Elderly / 1-on-1 PT clients may never open the app; their program and history must be fully operable by staff on their behalf.
- **Assigned program = an instance, not a reference.** Editing a client's program never touches the template or other clients.
- **"Last time" is first-class** — a per-client, per-exercise history table from commit one.
- **Reminders, not client spam.** Automation (later) nudges *staff* to act personally; the only automated client-facing flow is billing (also later).
- **Everything modular & i18n-ready** so features bolt on without touching the core.

See [01 · Architecture](01-architecture.md) for how these principles map onto code and the database.
