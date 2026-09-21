# 04 · Training Engine (v1 detailed spec)

Maps §4 of the brief onto concrete screens, state, and data. Each section notes the owning feature folder and the checkpoint that delivers it.

## 4.1 Accounts, roles & the account-less client → `features/auth`, `features/clients` · CP0/CP3

- **Roles:** owner/admin, coach, physio, client. Multiple coaches and physios.
- **Client record ≠ user account.** The domain identity is a **`person`**. A person may link to an `auth.users` account or not. Elderly / 1-on-1 PT clients never open the app; staff operate their profile, program, and history on their behalf.
- **App-client onboarding:** coach/physio adds the client → sends an invite → client downloads → creates a profile with basic info → linked to their coach.

**UI:** staff "Clients" tab lists persons; tapping opens the record. An "Invite" action generates a link/code. The invited client's signup binds their new account to the pre-existing person row.

## 4.2 Exercise library (coach-owned) → `features/exercises` · CP1

- Each coach builds **their own** library. Full CRUD.
- Each exercise: custom **name**, **video**, **description**, **tags** — movement pattern · main muscle group · equipment · tempo (extensible).
- Tags drive search and later "swap exercise".

**UI:** searchable/filterable grid or list; exercise editor with a video field (link first, upload later), description, and a tag chip editor. Video plays inline.

**State:** `exercisesProvider` (FutureProvider, per-coach), `exerciseTagsProvider`. Repository: `ExerciseRepository` (static methods, explicit columns).

## 4.3 Program builder & template library → `features/programs` · CP2

- **Program** = an ordered set of **sessions** (A1, A2, B1…). **No calendar, no scheduled dates** — sessions are a menu the client picks from.
- **Session** = ordered exercises, each with a **prescription** set at build time: sets · reps · weight · load/intensity · RPE · time · tempo · rest.
- **Set types** (superset, dropset, AMRAP, EMOM…) = **free-text** instruction for v1.
- Programs save as **templates** in a program library and are reused.

**UI:** program editor → add sessions → within a session, add exercises (from the library) → set prescription fields per exercise → drag to reorder. "Save as template". Template library screen to browse/duplicate.

**State:** local editing state held in a `ConsumerStatefulWidget`/notifier while building; persisted via `ProgramRepository` on save. Reorder = index updates on `session_exercises`.

## 4.4 Assignment model → `features/assignments` · CP3

- Assigning a template to a client creates an **editable copy bound to that client** — an **instance, not a reference**.
- Editing the instance **never** touches the template or other clients' copies.

**Implementation:** on assign, snapshot the template's sessions + prescriptions into per-client `assignment` rows (denormalised copy). Per-client edits mutate only the copy. This is the model rule from brief §6 and the reason "last time" and per-client tweaks stay clean.

**UI:** from a client record, "Assign program" → pick template → optional per-client adjustments → confirm.

## 4.5 Client mobile experience — the daily loop → `features/training` · CP4 (the hero)

**Flow:**
1. Open app → assigned program shown as a **list of sessions** → badge which was completed last → pick the next.
2. Enter a session → ordered list of exercises.
3. Per exercise:
   - **See the target** (the prescription).
   - **Watch the video** if needed.
   - **See last time's actual results** ← the priority feature.
   - **Enter actuals** — sets / reps / weight / time.
   - **Swap** the exercise if needed (tag-driven suggestions from the same library).
4. **Mark session complete.**

**Constraints:** internet required (no offline in v1) — show a clear banner if disconnected.

**"Last time" — first-class.** Backed by a per-client, per-exercise history (`logged_entries` + a "latest per exercise" query/view). When an exercise renders, we fetch the most recent prior `logged_entry` for that `person_id` + `exercise_id` and show it beside the input. This is designed in from commit one, not bolted on.

**Gym-friendly UX details:**
- Large numeric steppers and numeric keyboards for weight/reps.
- Minimal taps to log a set; carry last-time values as prefilled defaults.
- Optional rest timer (nice-to-have).
- Clear "completed" affordance.

**State:** `assignedProgramProvider(personId)`, `sessionProvider(sessionId)`, `lastEntryProvider(personId, exerciseId)`, plus transient logging state during a session. Writes via `LoggingRepository`.

## 4.6 Coach review → `features/review` · CP5

- On the web/mobile, the coach sees **what the client completed** and the **actuals** logged.
- v1 is **review-on-login** (fetch on open), not realtime — realtime is later.

**UI:** from a client record → "Completed sessions" list with dates → drill into a session to see logged actuals per exercise vs. the prescribed target.

## 4.7 Groups / rosters → `features/groups` · CP5

- One program assigned to a **group**; every athlete logs **individually** on their own phone.
- **Shared prescription, individual performance data.**

**Implementation:** group-assign fans out an instance copy to each member (reusing the §4.4 instance model), so each athlete's logging and "last time" stay independent while the prescription is shared at assignment time.

## 4.8 Physio variant → v1.x

The shared coach/physio record and the screening-vs-clinical split live in the CRM section ([05](05-crm-and-later.md)) and the [backend data-model](../../Lynx-backend/docs/00-data-model.md). v1 ships only the **coach-side safety screening flags** (§5.4); the physio clinical chart is v1.x, designed now with Urban.

## Screen inventory (v1)

**Client shell**
- Program / session menu
- Session runner (per-exercise: target · video · last-time · log actuals · swap)
- Progress / history (per-exercise trends)
- Profile & settings (language, account)

**Staff shell (coach/physio/admin)**
- Clients list + client record (profile + safety flags)
- Exercise library (list + editor)
- Program builder + template library
- Assign-program flow
- Review (completed sessions + actuals)
- Groups/rosters
- Profile & settings

## Data model touchpoints

Every screen above reads/writes tables defined in [`Lynx-backend/docs/00-data-model.md`](../../Lynx-backend/docs/00-data-model.md). The load-bearing ones for v1: `persons`, `exercises`, `programs`/`sessions`/`session_exercises`, `assignments` (+ instance sessions/exercises), `logged_entries`, `health_flags`, `groups`.
