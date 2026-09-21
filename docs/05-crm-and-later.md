# 05 · CRM & Later Scope (v1.x+)

The CRM is **not** a marketing funnel bolted onto billing (the big-box model — wrong for Lynx). It's a **unified client record** a person travels through, from first ad click to long-term regular, across gym / pilates / physio. This is the differentiator if Lynx is ever productised.

None of this is built in v1, but the [data model](../../Lynx-backend/docs/00-data-model.md) is designed so these bolt on **without reshaping the core**. This doc captures intent so v1 decisions don't paint us into a corner.

## Guiding principle — reminders, not client spam

Automation prompts **staff** to act personally; it does not message clients automatically. A client goes quiet → the coach is nudged to reach out — never an automated "where are you?" to the client. The **only** fully-automated, client-facing flow is **billing** (auto-renewal, invoice, late-payment reminder), and that rides entirely on the chosen payment provider, not on anything we build. Keeping the human touch is a deliberate brand choice — and cheaper to build than a campaign engine.

## The lifecycle (pipeline spine) → CP8

One person, one record, moving through stages:

1. **Lead** — a public "ad questionnaire" (short form off an ad click) captures contact + basic wants → lands on a **Leads page**.
2. **Contact & intro booking** — a coach calls the lead and books a free intro meeting. Leads page needs light scheduling + outcome **dispositions**: didn't want to come (+reason), no-showed, meeting held, sale made, etc.
3. **Intro meeting → the file is born** — longer questionnaire: goals, wishes, needs, past experience, health screening, assessment/testing battery, chosen pass/subscription, optional on-the-spot payment. The conversion point: lead → client record.
4. **Onboarding** — separate module, **parked** (Robin to spec). More premium; extra tasks, coach attention, likely 1-on-1.
5. **Regular** — steady state; CRM mostly tracks subscription health: consistency, late payments, freeze/hold requests.

**Timing note:** ads run *before* opening, so the lead pipeline is a candidate to pull earlier (even onto lighter tooling first). Flagged in [open questions](06-open-questions.md).

## Progressive profiling

Data enters gradually, not all up front:
- Ad questionnaire: contact + basic wants.
- Free meeting: goals, history, health screening, assessment, chosen plan.
- Thereafter: most new data flows in through the **training engine** (§4). The record grows over time.

## The record — safety screening vs. clinical chart → CP9

- **Coach-side safety screening (v1).** Enough for a coach to stay safe: smoking, blood pressure, vertigo, migraines, medications, allergies, asthma, osteoporosis, joint pain, spine conditions. Surfaced as **flags**. *(This part ships in v1 — see [04](04-training-engine.md).)*
- **Physio-side clinical chart (v1.x, design now).** Urban's deeper record — SOAP-style notes, treatment episodes, outcome measures. Fields worked out with Urban.
- **Shared visibility.** Coach and physio share the person; each sees the other's relevant layer. **How much of the clinical layer a coach sees — full / summary / walled — is the key open question for Urban.**
- **GDPR.** Health data is special-category, shared across two legal entities (our company + Urban's practice). Ties into the Urban cooperation agreement — flag for the lawyer.

## Entitlements (memberships, packs, drop-ins) → CP7

- **Memberships first** (highest-value v1.x): recurring plans are the hardest to track and the most automatable. Needs **freezes, holds, renewals, auto-expiry warnings**.
- **Packs** (physio/PT count-down "3 of 10 left") and **drop-ins** follow as later entitlement types.
- Entitlements **attach to the person** and drive both the client-facing "valid-until / invoices" view and the owner's subscription-health view.
- Taking payment is **integrated, not built**.

## Booking (heterogeneous, lighter than it looks) → later

- **PT:** in person — no app booking.
- **Physio:** in-app appointment booking.
- **Pilates:** mixed — some fixed classes, some flexible-membership drop-in.
- **Gym:** a same-day, per-hour **spot cap** to limit how many clients are in at once — "cap the hour", **not** an advance booking calendar.
- Attendance can feed **retention flags** (no check-in in N weeks → coach nudged).

## What the owner sees → CP11 / later

- **v1.x — operational action-lists** (the stuff you act on): lapsed clients, late payers, renewals due, spots remaining, session-pack burn-down. *These run the place.*
- **Later — BI dashboards:** revenue, LTV, coach utilization, class fill. Deferring these costs nothing at launch.

## Permissions → CP10

- Robin + developer are super-admins and define, **per individual**, what each coach/physio may see and edit. Staff are not all on one clearance.
- v1 ships **basic role separation**; **granular per-user clearances** land in v1.x.

## Automation (kept narrow on purpose) → CP11

- **Internal staff-facing reminders** — the main mechanism.
- **Billing automation** — the one client-facing exception; rides on the payment provider. The provider choice (Slovenian fiscal / davčna blagajna) gates on-the-spot payment, invoices, and this automation. Decide early.

## Staff tasks & workflows → CP11

Recurring, day-of-week task cadences with simple state. E.g. Mon — find who stopped training, reach out; Tue — check who responded → mark resolved or escalate. A **lightweight** task/workflow engine, not a full project tool.

## Why this shapes v1

The data-model principles ([backend §00](../../Lynx-backend/docs/00-data-model.md)) exist so all of the above bolts on cleanly:

- One person, one record, across lifecycle stages and services.
- The record exists **from the lead stage** — before any account.
- Two health layers on one person (safety flags vs. clinical chart) — distinct, permissioned, linked.
- A **logged entry is generic** — holds set/rep/weight/time today, physio outcome measures tomorrow, without reshaping.
- Entitlements attach to the person.
- Everything multi-language-ready and modular.
