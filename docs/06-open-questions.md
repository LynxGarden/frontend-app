# 06 · Open Questions & Decisions

Decisions still owed. Each has an **owner** and a note on **what it gates**. Resolve the 🔴 ones before or during the checkpoint noted.

## Resolved for this build

| Question | Decision |
|----------|----------|
| PWA vs. native | **Native iOS + Android in Flutter.** |
| Product model | **Multi-tenant SaaS** from day one; Lynx Center is tenant #1; sellable to other gyms later. |
| Auth & SSO | **Shared** across app + website: email **magic link** + **Google SSO** + **Apple SSO** (email/password kept as fallback). |
| Login surface (website) | Top-right **Log in** button → in-page modal; profile menu when signed in. **Done this round.** |
| Coach/admin dashboard | Lives in the **website** (`Lynx-website`) on the shared backend — not a separate project. Rich web builder still grows post-v1. |
| Languages | **English + Slovenian** (`en`/`sl`) on app + website, i18n-ready for more. |
| v1 training scope | **Full §4 training engine** in the Flutter app. |
| Docs location | Split: app docs here, DB docs in `Lynx-backend/docs/`. |
| DB approach | Full v1 schema now (multi-tenant), CRM tables stubbed extensible. |

## Product / business (owners: Robin, Urban, lawyer)

| # | Question | Owner | Gates | Priority |
|---|----------|-------|-------|----------|
| 1 | **Payment/billing provider** — which one? Must handle Slovenian fiscal receipts (davčna blagajna). | Robin + dev | on-the-spot payment, invoices, billing automation (CP7+) | 🔴 decide early |
| 2 | **Physio intake path** — do first-time physio patients go through the free-meeting path or a different intake? | Urban | CRM pipeline shape (CP8/CP9) | 🟡 v1.x |
| 3 | **Clinical-layer visibility** — how much of the physio chart does a coach see: full / summary / walled? | Urban | physio chart RLS (CP9) | 🟡 v1.x |
| 4 | **Lead pipeline timing** — needed live at opening (ads run pre-launch) or start on lighter tooling and move in as v1.x? | Robin + dev | whether CP8 pulls earlier | 🟡 pre-opening |
| 5 | **GDPR / health data across two legal entities** — consent model, data-sharing agreement with Urban's practice. | lawyer | health flags (CP3), clinical chart (CP9), launch (CP6) | 🔴 before storing real health data |
| 6 | **Onboarding module** — Robin to spec in its own round. | Robin | onboarding (parked) | ⚪ parked |

## SaaS / multi-tenant (owner: Robin + dev)

| # | Question | Gates | Notes / recommendation |
|---|----------|-------|------------------------|
| S1 | **Tenant onboarding** — how does a *new gym* sign up and get provisioned (self-serve vs. we create it)? | v1.x tenant signup | v1 seeds Lynx only; recommend **we-provision** first, self-serve later. |
| S2 | **Tenant addressing** — subdomain (`gym.lynx.app`), path, or in-app tenant switch? Affects website + OAuth redirect URLs. | dashboard/website, OAuth setup | Decide before custom domain; start single-tenant path (`/frontend-app/`). |
| S3 | **Per-tenant branding** — how far do we let other gyms theme (logo/colours via `tenants.branding`)? | later | Stub the column now; no UI in v1. |
| S4 | **Cross-tenant staff** — can one coach work for two gyms? | RLS/model | v1 assumes **one tenant per user**; revisit if it comes up. |
| S5 | **Pricing/plans for the SaaS itself** (vs. the gym's own memberships). | commercialization | Out of scope for v1; note it's distinct from §5.5 entitlements. |
| S6 | **Website dashboard tech** — the coach/admin dashboard currently = the static site + login. When it grows, stay vanilla, or introduce a framework (or Flutter Web) sharing app models? | dashboard build | Login is vanilla now; **decide the dashboard stack before building real dashboard screens.** |

## Auth (owner: dev)

| # | Question | Gates | Notes / recommendation |
|---|----------|-------|------------------------|
| A1 | **Supabase project credentials** — URL + publishable key needed to activate website login (`config.js`) and app `.env`. | CP0 go-live | Provide the project ref; the anon/publishable key is public-safe. |
| A2 | **Google OAuth clients** — web + iOS + Android client IDs/secrets in Google Cloud. | Google SSO | Console work (dev + Robin's Google org). |
| A3 | **Apple Sign in** — Services ID + key in the Apple Developer portal; required for App Store if Google SSO ships on iOS. | Apple SSO, App Store | Needs the Apple Developer account. |
| A4 | **Magic-link email sender** — Supabase default vs. custom SMTP/domain for deliverability. | email UX | Default fine for dev; custom SMTP before launch. |

## Technical (owner: dev)

| # | Question | Gates | Recommendation |
|---|----------|-------|----------------|
| 7 | **Exercise video hosting** — hosted (Supabase Storage: storage + CDN + transcoding, best UX, most work) vs. **link-based** (cheap). | CP1 | **Start link-based**; add hosted upload later if it doesn't eat the timeline. |
| 8 | **go_router shell** — `StatefulShellRoute.indexedStack` (per-tab stacks) vs. kaddy's plain `ShellRoute`. | CP0 | Prefer `StatefulShellRoute.indexedStack` unless it fights the native `CNTabBar`. |
| 9 | **`cupertino_native` dependency** — pre-1.0 (`^0.1.1`) package for the native iOS tab bar. Accept the dependency, or fall back to Flutter's `CupertinoTabBar`? | CP0 | Match kaddy (`cupertino_native`) for a genuinely native feel; keep `CupertinoTabBar` as a fallback if the package causes trouble. |
| 10 | **Dark theme** — brand is light (cream). Ship light-only for v1? | CP0/CP6 | **Light-only for v1**; dark is not a launch requirement. |
| 11 | **Set-type modelling** — free-text for v1 (per brief). When do supersets/dropsets become structured? | later | Keep free-text through v1; revisit with real coach feedback. |
| 12 | **Rest timer & in-session UX niceties** — how much gym-UX polish in CP4 vs. CP6? | CP4/CP6 | Ship core logging in CP4; timer/polish in CP6 if time. |
| 13 | **Offline** — confirmed out for v1. When does it come, and does it change the logging data flow? | later | Online-only v1; revisit post-launch (PowerSync is in the starter's optional modules). |

## Terms (owner: Robin + dev) — from brief §10

- Ownership, workload, and future-sale split between Robin and the developer. **Write this down before real work starts** — protects the friendship as much as the business. Not a technical blocker, but a prerequisite the brief calls out explicitly.

## How to use this doc

- 🔴 must be resolved before the gated checkpoint or before touching real user/health data.
- 🟡 can be resolved during v1.x planning.
- ⚪ parked — revisit when its owner brings it back.
- When a question is answered, move it into the "Resolved" table with the decision and date.
