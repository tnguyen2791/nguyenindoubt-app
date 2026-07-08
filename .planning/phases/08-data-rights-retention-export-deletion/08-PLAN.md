# Phase 8 (proposed): Data Rights — Retention, Export & Deletion

**Status:** In progress — data layer + demo UI implemented; production trusted-backend work pending.
**Depends on:** Phase 4 (repository/Firestore boundary), Phase 5 (consent lifecycle).
**Addresses production blocker:** "retention, export, and deletion workflows implemented and tested" (`docs/production_posture.md`).

## Goal

Give patients working data-portability (export) and account-deletion rights, and
introduce a retention-policy enforcement point — satisfying GDPR/CPRA and
Washington MHMDA obligations documented in `docs/legal/privacy_policy.md`. The
existing "Reset demo data" action is a whole-device wipe; it is **not** a
per-account deletion and keeps no audit trail.

## What "done" looks like

1. A patient can **export** all their data (profile, journal, sleep samples,
   daily summaries, clinician links, consent history) as versioned JSON.
2. A patient can **delete their account**: personal data is removed, active
   clinician sharing ends, and the **consent audit trail is retained** (per the
   privacy policy's "subject to audit retention" language).
3. A **retention policy** exists as a first-class model with an enforcement
   point; the default purges nothing until real, counsel-approved periods are set.
4. Export/deletion/retention are covered by tests and honor the patient-ownership
   guard (a clinician can never export or delete a patient's data).

## Design

### Data layer (implemented)

- **Models** (`lib/models/app_models.dart`): `PatientDataExport`,
  `AccountDeletionResult`, `RetentionPolicy`.
- **Interface** (`lib/repositories/app_repository.dart`): new
  `DataRightsRepository` with `exportPatientData` and `deletePatientData`,
  implemented by both repositories so the boundary stays symmetric.
- **In-memory repo (the live backend today):** full implementation of export,
  per-account deletion (retaining consent history), and `applyRetention`. A
  public `patientDataExportToJson` serializer reuses the existing per-model
  encoders so the export format cannot drift from stored data.
- **Firebase repo:** `exportPatientData` implemented as reads; `deletePatientData`
  intentionally throws a trusted-backend `PrivacyException` (mirrors the existing
  `acceptInvite` pattern) because production deletion — removing the auth user,
  cascading across collections, retaining the audit trail, and propagating to
  backups — must run in a **Cloud Function**, not on the client.
- **State** (`lib/state/app_state.dart`): `exportMyData()` (returns indented
  JSON) and `deleteMyAccount()`.

### Decisions taken

- **Deletion retains consent/audit history** (not a hard-delete of everything).
- **Export format is versioned JSON** (`exportVersion: 1`).
- **`ConsentEventAction` was not extended** with a `deleted` value: it has an
  exhaustive `switch` in `patient_dashboard.dart`, so deletion reuses the
  existing `revoked` sharing-termination event to avoid breaking compilation.
- Demo deletion keeps a minimal **profile shell** so the local app stays
  functional; production removes the profile + auth user via the trusted backend.

## UI (implemented)

The patient app bar (`lib/screens/app_shell.dart`) now has a **Data & privacy**
overflow menu (patient-only) with:
- **Export my data** → `state.exportMyData()`, shown in a dialog with
  copy-to-clipboard. A real file download on web/mobile is a follow-up.
- **Delete my account** → confirmation dialog clearly distinct from "Reset demo
  data", calling `state.deleteMyAccount()` and reporting the result.

## Remaining work (next steps)

1. **Production file-download** for export (web/mobile) instead of clipboard.
2. **Trusted-backend Cloud Functions** (gated with the Firebase go-live): account
   deletion cascade + auth-user deletion, and a **scheduled retention sweep**
   mirroring `applyRetention`.
3. **Finalize retention periods** per category with counsel and wire the real
   `RetentionPolicy` (currently `pendingReview` = purge nothing).
4. **Human-readable export** (optional) alongside the JSON.

## Verification

- `test/repositories/data_rights_test.dart` covers export completeness + JSON
  serialization, deletion scoping (personal data gone, audit retained, clinician
  access severed), ownership enforcement, and retention (default no-op + windowed
  purge).
- **Not run in this environment:** the Flutter/Dart toolchain is unavailable here,
  so `flutter analyze` / `flutter test` / `flutter build web` must be run in a
  Flutter environment (or CI) before merge.
