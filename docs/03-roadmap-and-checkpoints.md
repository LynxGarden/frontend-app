# 03 · Roadmap & Checkpoints

The plan is organised into **checkpoints (CP)**. Each checkpoint is a demoable slice — something you can put in front of Robin / a real coach / a real client and get feedback on. A checkpoint is "done" only when its **acceptance criteria** pass on a real device against the real Supabase project.

Checkpoints are ordered by dependency, not by calendar. The brief is explicit that calendar time depends on developer hours; so this plan sequences the work and marks the **launch-critical spine** vs. what can slip.

## Legend

- 🎯 **Launch-critical** — part of the v1 hero; must land for a real launch.
- 🧩 **v1 nice-to-have** — in v1 scope but can be trimmed under time pressure.
- 🔭 **v1.x** — designed-for now, built later.
- Each CP lists **App** deliverables and **Backend** deliverables (the backend ones link to [`Lynx-backend/docs/02-migrations-and-checkpoints.md`](../../Lynx-backend/docs/02-migrations-and-checkpoints.md)).

---

## CP0 · Foundations 🎯 — ✅ largely delivered

**Goal:** an installable app that authenticates against Supabase, shows the branded adaptive shell, and routes by role. Nothing domain-specific yet.

> **Status:** app scaffolded (`lynx_app`), Lynx light theme, EN/SL i18n, adaptive shell + role routing, SSO + magic-link auth, tenant-aware session, and **dev/prod flavors** all in place; `flutter analyze` clean. Backend migrations applied & verified on the local stack. **Remaining before "done":** configure Supabase auth providers + redirect URLs, push migrations to the cloud project, create a linked test user to walk the shells on a device, and (later) native per-flavor bundle IDs. See [07 · Getting Started](07-getting-started.md).

**App**
- Init Flutter project from the starter (`bin/setup.dart`): rename to `lynx_app`, set bundle IDs, deeplink scheme/host, brand colours & fonts.
- Port branding tokens into `core/theme` ([02](02-navigation-and-ui.md)); replace dark-only theme with Lynx light theme.
- Enable **i18n** shipping **`en` + `sl`** (`flutter_localizations`, `.arb`, `flutter gen-l10n`); wire `MaterialApp.router` locales. Extract all starter strings.
- Build the **platform-adaptive `MainShell`** (iOS `CNTabBar` / Android pill) + the two role-based shells (client / staff) with placeholder tab screens.
- **Auth: magic link + Google SSO + Apple SSO** (plus starter email/password fallback); `currentUserProvider` reads **role + `tenant_id`**; router redirects by role and to a "finish setup / accept invite" screen when no `person` is linked yet.
- **Tenant-aware repositories**: base repository pattern scopes every query to `current tenant_id`.

**Backend** → CP-B0: `supabase init`, seed **tenant #1 (Lynx Center)**, enable **magic-link + Google + Apple** providers with all redirect URLs, and the identity core (`tenants`, `persons` + `tenant_id`, `person_roles`) with **tenant-isolation RLS**.

**Website** (`Lynx-website`) — ✅ done this round: top-right **Log in** button + profile menu, login modal with Google/Apple/magic-link (EN + SL), sharing this backend. Fill `assets/js/config.js` with the Supabase URL + publishable key and it goes live ([website auth-setup](../../Lynx-website/docs/auth-setup.md)).

**Acceptance**
- Fresh install on an iOS device shows the native Cupertino tab bar; on Android the pill bar.
- Can sign in with Google, Apple, and a magic link **on both the app and the website**; land in the correct shell for the account's role; sign out.
- App language switches **EN ↔ SL** and strings update.
- A user in a second (test) tenant sees none of Lynx's data.
- No hardcoded colours/strings in new code (lint + review).

---

## CP1 · Exercise Library 🎯

**Goal:** a coach can build and manage their own exercise library with video, description, and tags.

**App**
- `features/exercises`: list, search/filter by tag, create/edit/delete.
- Video: **link-based first** (paste a URL) to protect the timeline; add player (`video_player`/`chewie`) for playback. Hosted upload is a stretch — see open questions.
- Tag editor: movement pattern · muscle group · equipment · tempo (extensible).
- Repository + providers per the [data rules](01-architecture.md).

**Backend** → CP-B1: `exercises` table, `tags`/tagging, RLS (coach owns their library), storage bucket for video (if hosted).

**Acceptance**
- Coach creates an exercise with name, video link, description, ≥1 tag; it appears in the library and is searchable by tag.
- Edit and delete work; another coach cannot see/edit the first coach's exercises (RLS).
- Video plays on iOS and Android.

---

## CP2 · Program Builder & Templates 🎯

**Goal:** a coach composes programs from their exercises and saves them as reusable templates.

**App**
- `features/programs`: create a **program** = ordered set of **sessions** (A1, A2, B1…). No calendar/dates — a menu.
- Each **session** = ordered exercises, each with a **prescription** set at build time: sets · reps · weight · load/intensity · RPE · time · tempo · rest.
- Set types (superset/dropset/AMRAP/EMOM…) as **free-text** instruction for v1.
- Reorder (drag), duplicate, save as template; browse the template library.

**Backend** → CP-B2: `programs`, `sessions`, `session_exercises` (with prescription fields), `is_template` flag / template library.

**Acceptance**
- Coach builds a 2-session program, sets prescriptions per exercise, reorders exercises, saves as a template.
- Template reappears in the library and can be opened/duplicated.

---

## CP3 · Assignment & the Client Record 🎯

**Goal:** a coach assigns a template to a client as an **editable per-client copy**, and the minimal client record exists (incl. account-less clients).

**App**
- `features/clients`: client list; client record = basic profile + **safety health-screening flags** (smoking, blood pressure, vertigo, migraines, medications, allergies, asthma, osteoporosis, joint pain, spine conditions) surfaced as flags.
- Create an **account-less client** and operate their record fully.
- Invite flow for app clients: add client → send invite → client downloads → creates profile → linked to coach.
- `features/assignments`: assign template → creates an **instance** bound to the client; editing the instance never touches the template. Per-client adjustments.

**Backend** → CP-B3: `assignments` as instance copies (denormalised snapshot of sessions/prescriptions), `health_flags`, invite/link mechanism, RLS for staff↔client visibility.

**Acceptance**
- Assigning a template to client A creates an independent copy; editing A's copy leaves the template and client B untouched.
- A coach creates an account-less client, assigns a program, and can view/edit it on the client's behalf.
- Invite → new client signs up → their record links to the inviting coach and shows the assigned program.
- Safety flags display prominently on the client record.

---

## CP4 · Client Daily Loop 🎯 (the hero)

**Goal:** the client trains in the gym — this is the single most important slice.

**App** (`features/training`)
- Open app → program shown as a **list of sessions** → see which was completed last → pick the next.
- Per exercise: **see target**, **watch video**, **see last time's actual results** (priority), **enter actuals** (sets/reps/weight/time), **swap** an exercise (tag-driven suggestions).
- Mark session complete. Online-only (clear messaging if offline).
- Gym-friendly UX: big numeric steppers, minimal taps, rest timer (nice-to-have).

**Backend** → CP-B4: `logged_entries` (generic, extensible), the **"last time" per-client/per-exercise history** query/view, session-completion state.

**Acceptance**
- Client picks a session, sees the prescribed target and the video, and — **critically** — sees exactly what they logged for that exercise last time.
- Client logs today's actuals; on the next visit those become the new "last time".
- Swap replaces an exercise for this session's logging without corrupting history.
- Works end-to-end on iOS and Android against the real backend.

---

## CP5 · Coach Review & Groups 🧩

**Goal:** the coach closes the loop by seeing completed work; groups let one program serve many athletes.

**App**
- `features/review`: coach sees completed sessions and the actuals each client logged (review-on-login; realtime is later).
- `features/groups`: assign one program to a **group/roster**; every athlete logs individually on their own phone (shared prescription, individual data).

**Backend** → CP-B5: review queries across a coach's clients; `groups` + roster membership; group-assignment fan-out to per-client instances.

**Acceptance**
- Coach opens a client and sees their completed sessions with logged actuals and dates.
- A program assigned to a 3-person group produces three independent logging streams; each athlete sees only their own.

---

## CP6 · Launch Hardening 🎯

**Goal:** ship-quality. Turn the working slices into something real people use daily.

**App**
- Full i18n pass (all strings extracted; EN complete, structure ready for SL).
- Responsive/polish pass on all screens (phones + tablet); empty/loading/error states everywhere (`skeleton_loader`, `AppToast`).
- GDPR: consent copy for health data; privacy-policy link; account/data-deletion path. Coordinate with the lawyer (see [open questions](06-open-questions.md)).
- Crash-safety: `mounted` checks, error boundaries, offline messaging.
- Repository unit tests for the training-engine data layer; golden tests for the daily-loop screens.
- Store setup: iOS TestFlight + Android internal testing; icons/splash (`flutter_launcher_icons`, `flutter_native_splash`); store listings.

**Backend** → CP-B6: RLS audit across all tables, backups, seed/demo data, production project hardening.

**Acceptance**
- Real coach + real client complete a full cycle (build → assign → train → review) on production, on both platforms, with no blocking bugs.
- Health data handled per an agreed GDPR stance.
- Builds distributed via TestFlight and Play internal testing.

---

## 🚦 Late-November go/no-go (from brief §8)

A hard checkpoint independent of code progress. **The opening does not depend on this app being finished.** By late November, honestly assess CP0–CP4:

- **Green:** the hero (CP0–CP4) is stable → soft-launch the custom app; CP5–CP6 continue.
- **Red:** run the opening on an off-the-shelf tool (spreadsheets / existing gym app) and keep building Lynx into 2027. No drama.

This checkpoint exists so timeline risk never threatens the actual gym opening.

---

## v1.x and later (post-launch) 🔭

Built on the schema that CP0–CP6 already lays down. See [05 · CRM & Later](05-crm-and-later.md) for detail. Rough order:

| CP | Slice | Notes |
|----|-------|-------|
| CP7 | **Memberships / entitlement engine** | freezes, holds, renewals, auto-expiry warnings — the highest-value CRM piece |
| CP8 | **Lead → meeting → sale pipeline** | leads page, intro scheduling, dispositions. Candidate to pull *earlier* since ads run pre-opening |
| CP9 | **Physio clinical chart** | SOAP notes, treatment episodes, outcome measures — fields designed with Urban |
| CP10 | **Granular permissions** | per-user clearances beyond basic roles |
| CP11 | **Staff reminders & task workflows + operational action-lists** | "reminders not spam"; lapsed/late/due-to-renew/spots-left |
| Later | Booking (gym cap-the-hour, physio appts), payments integration, BI dashboards, chat/calendar, offline, wearables, **tenant self-serve onboarding / reselling** (schema already multi-tenant) | see [00 · Overview](00-overview.md) |

## Dependency graph (v1)

```
CP0 ──▶ CP1 ──▶ CP2 ──▶ CP3 ──▶ CP4 ──▶ CP5
 │                              │
 └──────────────────────────────┴──▶ CP6 (hardening, runs against whatever has landed)
```

CP4 depends on CP3 (needs an assigned instance) and CP1 (needs exercises with video). CP2 depends on CP1. CP5 depends on CP4.
