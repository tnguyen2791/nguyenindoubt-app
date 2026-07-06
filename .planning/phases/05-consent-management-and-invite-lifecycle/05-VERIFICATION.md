---
phase: 05-consent-management-and-invite-lifecycle
verified: 2026-07-06
status: passed
score: 10/10 acceptance criteria verified
behavior_unverified: 0
---

# Phase 05: Consent Management and Invite Lifecycle Verification Report

**Phase Goal:** Patients control invite-based sharing and clinicians see link status changes without hidden or premature access.
**Status:** passed

## Goal Achievement

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Patient can validate a pending invite and see preview before acceptance. | VERIFIED | Widget and repository tests cover `NID-1138` preview. |
| 2 | Validation alone grants no clinician sleep access. | VERIFIED | Repository test asserts sleep access still throws before acceptance. |
| 3 | Invalid, malformed, missing, wrong-patient, expired, and revoked states are non-granting. | VERIFIED | Repository tests cover empty/malformed/missing/wrong-patient/expired; Firestore rules deny non-accepted statuses. |
| 4 | Patient can accept invite sharing. | VERIFIED | Widget/repository tests accept `NID-1138` and observe `ConsentStatus.granted`. |
| 5 | Patient can revoke sharing. | VERIFIED | Widget/repository tests revoke and observe `ConsentStatus.revoked`. |
| 6 | Revocation removes clinician sleep access. | VERIFIED | Repository and Firestore tests deny sleep reads after revoked status. |
| 7 | Clinician dashboard shows lifecycle statuses. | VERIFIED | Widget test finds accepted, pending, and expired rows. |
| 8 | Consent history is represented and persists locally. | VERIFIED | Repository tests verify accepted/revoked history and persistence across repository instances. |
| 9 | Consent history is metadata-only. | VERIFIED | Firestore rules deny consent event writes containing `journalBody` or `sleepSamples`. |
| 10 | Clinician journals remain denied. | VERIFIED | Existing repository/widget tests plus Firestore tests still deny journal reads. |

## Automated Checks

- `dart format lib test` - passed
- `flutter analyze` - passed
- `flutter test` - passed, 22 tests
- `npm run test:firestore-rules` - passed, 7 tests

## Residual Risk

- Firebase client invite acceptance intentionally throws until a trusted backend operation exists. This preserves the Phase 4 trusted-write boundary and should be handled before live Firebase mode.
- Node `v20.13.1` still triggers engine warnings for some Firebase/Vitest tooling. The rules suite passed after installing the native rolldown optional binding locally.

---

*Verified: 2026-07-06*
*Verifier: Codex*
