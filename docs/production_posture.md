# Production posture

NguyenInDoubt is ready to demonstrate the v1 privacy promise. It is not ready
to run as a live production health or mental-health data service until the
items below are reviewed and implemented.

## Data modes

| Mode | Current status | What happens |
|---|---|---|
| Public web demo | Enabled | Data is stored on the current browser/device through local demo storage. It does not sync across devices and can be reset in the app. |
| Mobile demo | Enabled after local build | Data is stored on the device through local demo storage. Platform sleep permission can be requested on supported iOS/Android devices. |
| Firebase production | Not enabled | Repository and Firestore rules exist as the backend boundary, but live Auth/Firestore mode remains compliance-gated. |
| Telemetry | Not enabled | Analytics, Crashlytics, performance monitoring, session replay, and product telemetry are intentionally absent. |

## Demo data expectations

- Demo profile, journal entries, imported sleep samples, consent state, and
  session state stay on the current device.
- The GitHub Pages demo cannot sync data across browsers, devices, or installs.
- Resetting demo data clears local demo state and restores seeded demo content.
- Local demo storage is not a production retention system and should not be used
  for real clinical records.

## Production retention expectation

Before live Firebase mode is enabled, the project needs a written retention
policy covering:

- account profile records
- journal entries
- sleep samples and daily summaries
- clinician link and consent history
- support/admin audit records
- backup retention and deletion propagation

No production retention period is promised by this repository yet.

## Export expectation

Before live use, patients should be able to export at least:

- profile fields
- journal entries
- imported sleep samples
- daily summaries
- consent and clinician-link history

The device-local demo now implements export end to end: the repository assembles
a versioned JSON bundle across all of the categories above (`exportPatientData` /
`patientDataExportToJson` via `NguyenInDoubtState.exportMyData`), surfaced in the
patient app bar's **Data & privacy** menu ("Export my data" → view + copy JSON).
Remaining work: a production file-download path (web/mobile) instead of
copy-to-clipboard. See
`.planning/phases/08-data-rights-retention-export-deletion/08-PLAN.md`.

## Deletion expectation

Before live use, patients should be able to request deletion of:

- account/profile data
- patient-owned journal entries
- patient-owned health samples and summaries
- clinician links and consent state, subject to any legally required audit log
  retention

The device-local demo now implements a per-account deletion
(`deletePatientData` / `NguyenInDoubtState.deleteMyAccount`, surfaced in the
patient app bar's **Data & privacy** menu as "Delete my account"): it removes the
patient's journal, sleep samples, and daily summaries, ends active clinician
sharing, and **retains the consent audit trail**. This is distinct from "Reset
demo data", which wipes the whole device demo. Remaining work: implement
production deletion — removing the auth user,
cascading across collections, and propagating to backups — in a trusted backend
(Cloud Function), which the Firebase repository intentionally defers to. A
`RetentionPolicy` model + enforcement point (`applyRetention`) also exists;
concrete, counsel-approved retention periods and a scheduled backend sweep remain
to be set. See `.planning/phases/08-data-rights-retention-export-deletion/08-PLAN.md`.

## Compliance blockers

Live production use remains blocked until these items are resolved:

- privacy policy, terms, and user-facing consent language reviewed for the
  intended deployment context — **draft templates now in [docs/legal/](legal/README.md)
  ([privacy policy](legal/privacy_policy.md), [terms of service](legal/terms_of_service.md));
  pending counsel review and placeholder resolution**
- HIPAA/BAA and clinical responsibility analysis, if the app is used with a
  covered entity or care team — **draft analysis now in
  [docs/legal/hipaa_baa_analysis.md](legal/hipaa_baa_analysis.md); pending counsel review**
- Firebase project configuration, Auth role-claim issuance, backup policy, and
  security monitoring reviewed
- trusted backend operation for invite acceptance implemented
- real-device HealthKit and Health Connect permission flows validated
- retention, export, and deletion workflows implemented and tested — **export
  and per-account deletion implemented in the device-local demo data layer with
  tests; UI wiring and production trusted-backend deletion/retention sweep
  remain (see the Export/Deletion sections above)**
- incident response and support escalation process defined — **draft
  [incident response plan](legal/incident_response_plan.md) and
  [support & crisis-escalation process](legal/support_escalation_process.md) now in
  docs/legal/; pending counsel review**
- telemetry decision reviewed before adding any analytics or crash reporting

> The legal/compliance drafts above are **templates, not final instruments**. Each
> carries a "requires legal counsel review" banner and an Open Items checklist of
> bracketed placeholders (legal entity, jurisdiction, contacts, retention periods,
> region) that must be resolved before the document takes effect. See
> [docs/legal/README.md](legal/README.md).

## Release gate

Every demo deployment should pass:

```sh
flutter analyze
flutter test
npm run test:firestore-rules
flutter build web
```
