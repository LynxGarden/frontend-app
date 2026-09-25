# 08 · GDPR / Consent — DRAFT for legal review

> **⚠️ DRAFT — not legal advice.** The copy below is placeholder wording to be
> reviewed and finalized with the lawyer (see [06 · Open Questions](06-open-questions.md) #5).
> Health data (`health_flags`, later `clinical_notes`) is **special-category
> personal data** shared across two legal entities (the company + Urban's physio
> practice). Do **not** store real health data in production until consent + the
> data-sharing agreement are in place.

## What we must ship for CP6

1. **Consent capture** before storing health data (a `consents` table or a
   consent record on `persons`): who consented, to what version of the notice,
   when. Staff recording a `health_flag` on a client's behalf must attest consent
   was obtained.
2. **Privacy policy link** — reachable from Settings/Profile and the sign-in
   screen. Host on the marketing site (`Lynx-website`).
3. **Right to erasure / export** — a self-serve "Delete my account & data" path
   and a data-export request path. Deleting a `person` must cascade or anonymize
   training + health data. Account-less clients have these rights too (staff-
   initiated on their behalf).
4. **Data-sharing agreement** governs coach↔physio visibility. The technical
   lever is `clinical_notes.visibility` (`full`/`summary`/`walled`) — default TBD
   with Urban. Default coaches to *summary* until decided.
5. **Audit** — consider an append-only access log for health tables (who read a
   clinical note, when) once the physio chart lands.

## Placeholder consent copy (to be replaced by legal)

**Health screening consent (shown before a coach records safety flags):**
> [DRAFT] "To train you safely, your coach records health-screening notes
> (e.g. blood pressure, injuries, medications). This is sensitive personal data.
> By continuing you confirm you consent to Lynx and your coach storing and using
> it to plan and adapt your training. You can withdraw consent or request
> deletion at any time in Settings. See our Privacy Policy."

**Account deletion confirmation:**
> [DRAFT] "This permanently deletes your account and your training and health
> data. Programs you were assigned and your logged history will be removed. This
> cannot be undone."

## Implementation notes (app side, when approved)

- Add a `consents` table (backend, CP-B6) — `person_id`, `type`
  (`health_screening`|`privacy_policy`), `version`, `granted_at`, `granted_by`,
  `withdrawn_at`.
- Gate the `_addFlag` flow (`client_detail_screen`) behind a consent check +
  the consent dialog above.
- Settings: add "Privacy Policy" (url_launcher), "Export my data", and "Delete
  my account" entries. Deletion calls a SECURITY DEFINER RPC that cascades/anon.
- Store listings (App Store Privacy "Nutrition Label" + Play Data Safety) must
  match `PrivacyInfo.xcprivacy` and declare health data collection.
