---
phase: 05-consent-management-and-invite-lifecycle
plan: 01
subsystem: consent
tags: [flutter, consent, invites, firestore-rules, privacy]

requires:
  - Phase 4 Firebase Auth and Firestore Adapter
provides:
  - Invite validation and preview before consent
  - Patient acceptance and revocation flow
  - Consent history metadata
  - Clinician lifecycle status rows
  - Firestore rules coverage for expired links, revocation, and metadata-only consent events
affects: [consent, privacy, clinician-dashboard, firebase]

requirements-completed: [CONS-01, CONS-02, CONS-03, CONS-04, CONS-05]

duration: 90min
completed: 2026-07-06
status: complete
---

# Phase 05 Plan 01 Summary

Phase 5 replaces the hardcoded invite button with a validated consent lifecycle.

## Accomplishments

- Added consent lifecycle models: invite validation result/status, consent history events, clinician link status rows, and `LinkStatus.expired`.
- Added consent repository methods for validation, acceptance, revocation, history, and clinician status views.
- Implemented local demo validation, preview, acceptance, revocation, status listing, and persisted metadata-only consent history.
- Updated the patient dashboard with invite entry, validation errors, preview, accept, revoke, active/revoked status, and consent history.
- Updated the clinician dashboard to show accepted, pending, revoked, and expired link statuses while keeping sleep detail access accepted-only.
- Updated Firestore rules/docs so accepted-link creation remains trusted/admin-only, patient revocation is allowed, and consent events are append-only metadata.
- Expanded repository, widget, and Firestore emulator tests.

## Verification

- `dart format lib test` - passed
- `flutter analyze` - passed
- `flutter test` - passed, 22 tests
- `npm run test:firestore-rules` - passed, 7 tests

## Notes

- Firebase invite acceptance remains intentionally fail-closed in the client adapter until a trusted backend operation exists.
- Local npm tooling still reports Node engine warnings on Node `v20.13.1` and 5 moderate dev-tool audit findings.

---

*Phase: 05-consent-management-and-invite-lifecycle*
*Completed: 2026-07-06*
