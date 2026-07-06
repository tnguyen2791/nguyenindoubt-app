# Phase 4 Context: Firebase Auth and Firestore Adapter

## Objective

Introduce account-backed Firebase Auth and Firestore boundaries behind repository interfaces while preserving the Phase 3 privacy contract.

## Current implementation baseline

- The app runs against `InMemoryAppRepository` and `SharedPreferences`.
- Firebase files are present but stubbed:
  - `firebase.json`
  - `.firebaserc`
  - `firestore.rules`
  - `firestore.indexes.json`
  - `lib/firebase_options.dart`
  - `docs/firebase_contract.md`
- No Firebase Analytics, Crashlytics, or telemetry dependencies are enabled.
- Phase 3 hardened repository contracts so clinician-facing code has no journal read method.

## Requirements covered

- `FIRE-01`: Firebase Auth and Firestore remain behind repository interfaces rather than direct screen calls.
- `FIRE-02`: Firestore rules enforce patient-owned journal access and accepted-link sleep-only clinician access.
- `FIRE-03`: Firestore rules deny pending, revoked, missing, or malformed clinician links.
- `FIRE-04`: Firestore emulator tests cover users, clinician links, health samples, daily summaries, journal entries, and resource cards.
- `FIRE-05`: Analytics, Crashlytics, and telemetry remain disabled unless separately compliance-reviewed.

## Constraints

- Do not make the public demo depend on live Firebase credentials or network writes by default.
- Do not add Analytics, Crashlytics, or telemetry.
- Do not introduce real invite lifecycle behavior; that remains Phase 5.
- Preserve the local/demo repository as a runnable fallback.

## Current rule risk

`firestore.rules` currently allows a signed-in user to create or update a `clinicianLinks` document if they are either the patient or clinician in the requested data. That is too broad for a production trust boundary because a clinician could self-create an accepted link. Phase 4 should tighten this before treating Firestore rules as emulator-proven.

