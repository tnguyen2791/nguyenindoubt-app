# Roadmap: NguyenInDoubt Flutter MVP

## Overview

NguyenInDoubt moves from a local demo that proves the privacy promise into a reviewed, production-ready MVP shape. The phases preserve the working patient and clinician experience first, then replace placeholder role/session mechanics, harden the privacy contract, introduce Firebase behind repository boundaries, make consent lifecycle real, add platform sleep imports, and finish with deployment posture that makes data mode and compliance limits explicit.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Demo Promise Hardening** - Preserve the existing local patient and clinician demo while tightening responsiveness, local-state clarity, and safety boundaries. (completed 2026-07-06)
- [x] **Phase 2: Auth and Session Model** - Replace the fake production role switch with explicit signed-out, onboarding, patient, clinician, and refresh-safe session states. (completed 2026-07-06)
- [x] **Phase 3: Privacy and Repository Contract Hardening** - Make clinician-facing paths incapable of reading patient journals while preserving consented sleep-summary access. (completed 2026-07-06)
- [ ] **Phase 4: Firebase Auth and Firestore Adapter** - Add account-backed auth/storage behind repository interfaces with emulator-proven Firestore privacy rules.
- [ ] **Phase 5: Consent Management and Invite Lifecycle** - Replace the hardcoded invite with validated invite, consent, revocation, status, and history flows.
- [ ] **Phase 6: Real Sleep Import Providers** - Add HealthKit and Health Connect providers behind `HealthDataProvider` with sleep-only permissions and safe sync behavior.
- [ ] **Phase 7: Production Deployment Posture** - Make release verification, data expectations, and compliance blockers explicit before production launch.

## Phase Details

### Phase 1: Demo Promise Hardening

**Goal:** Users can trust the local demo to show the full patient and clinician privacy promise across responsive surfaces.
**Mode:** mvp
**Depends on:** Nothing; this locks the current baseline before auth, backend, consent, and health-provider changes build on it.
**Requirements:** DEMO-01, DEMO-02, DEMO-03, DEMO-04, DEMO-05
**Success Criteria** (what must be TRUE):

  1. Patient can complete onboarding, mock sleep import, dashboard review, private journaling, resources, and safety flow without regressions.
  2. Clinician can complete the accepted-link demo flow and see linked-patient sleep summaries without any journal content.
  3. Journal, resources, safety, and clinician screens render correctly on phone-width and desktop-width layouts.
  4. User can reset or understand device-local demo state, and safety content routes urgent situations to external crisis resources.

**Plans:** 1/1 plans complete
**UI hint**: yes

### Phase 2: Auth and Session Model

**Goal:** Users enter signed-out, onboarding, patient, and clinician sessions without relying on a fake production role switch.
**Mode:** mvp
**Depends on:** Phase 1; stable demo flows make role/session regressions visible.
**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04
**Success Criteria** (what must be TRUE):

  1. User can move through explicit signed-out and onboarding states before entering patient or clinician app states.
  2. Patient can complete onboarding with the minimum profile state needed for the app while local/demo mode remains clear.
  3. Clinician access depends on a trusted clinician role source or explicit demo override, not arbitrary client-side selection.
  4. Session refresh restores the expected role and data boundary without exposing the wrong patient or clinician state.

**Plans:** 1/1 plans complete
**UI hint**: yes

### Phase 3: Privacy and Repository Contract Hardening

**Goal:** Clinician-facing flows can only access consented sleep summaries while journal data remains patient-only by contract.
**Mode:** mvp
**Depends on:** Phase 2; explicit roles and sessions define which repository capabilities each path may use.
**Requirements:** PRIV-01, PRIV-02, PRIV-03, PRIV-04, PRIV-05
**Success Criteria** (what must be TRUE):

  1. Clinician-facing code paths cannot request or receive journal entries through repository interfaces or app state.
  2. Accepted clinician links expose only linked-patient sleep summaries, while pending, revoked, or missing links expose no sleep data.
  3. Privacy tests prove clinician access to journal entries is denied regardless of link status.
  4. Patient-facing privacy copy consistently explains that clinicians see sleep summaries only after consent.
  5. Clinician views are built without patient journal data being passed into their screens or state models.

**Plans:** 1/1 plans complete
**UI hint**: yes

### Phase 4: Firebase Auth and Firestore Adapter

**Goal:** Account-backed storage can be introduced behind repository adapters while Firebase rules preserve the same privacy boundary.
**Mode:** mvp
**Depends on:** Phase 3; the repository and privacy contracts define what the Firebase adapter and rules must enforce.
**Requirements:** FIRE-01, FIRE-02, FIRE-03, FIRE-04, FIRE-05
**Success Criteria** (what must be TRUE):

  1. Patient and clinician app flows use repository interfaces rather than direct Firebase calls from screens.
  2. Firestore emulator tests show patient journals are patient-owned and clinician access is sleep-only for accepted links.
  3. Pending, revoked, missing, or malformed clinician links are denied by Firestore rules.
  4. Emulator coverage exercises users, clinician links, health samples, daily summaries, journal entries, and resource cards.
  5. Analytics, Crashlytics, and telemetry remain disabled unless a separate compliance-reviewed decision enables them.

**Plans:** TBD
**UI hint**: yes

### Phase 5: Consent Management and Invite Lifecycle

**Goal:** Patients control invite-based sharing and clinicians see link status changes without hidden or premature access.
**Mode:** mvp
**Depends on:** Phase 4; invite state must be backed by reviewed auth/storage rules before real lifecycle behavior grants access.
**Requirements:** CONS-01, CONS-02, CONS-03, CONS-04, CONS-05
**Success Criteria** (what must be TRUE):

  1. Patient can validate and accept a real invite code instead of the hardcoded `NID-1138` demo code.
  2. Patient can revoke clinician sleep-summary sharing and immediately understand the current sharing state.
  3. Invite acceptance and revocation are atomic, and access is not granted before invite validation succeeds.
  4. Clinician dashboard updates when a link is accepted, revoked, expired, or missing.
  5. Consent history is represented well enough to support audit, support, or future compliance review.

**Plans:** TBD
**UI hint**: yes

### Phase 6: Real Sleep Import Providers

**Goal:** Patients can import real sleep data through platform providers with clear permissions and production-safe normalization.
**Mode:** mvp
**Depends on:** Phase 5; account, consent, and backend boundaries must be coherent before real health data enters the app.
**Requirements:** HLTH-01, HLTH-02, HLTH-03, HLTH-04, HLTH-05
**Success Criteria** (what must be TRUE):

  1. HealthKit and Health Connect providers operate behind `HealthDataProvider` without changing patient sleep-import flows.
  2. Patient sees clear unavailable, not requested, partial, denied, revoked, and ready permission states.
  3. Sleep import requests sleep-only permission for MVP use.
  4. Imported samples normalize into the existing `HealthSample` and `DailySummary` outputs.
  5. Production import deduplicates and incrementally syncs samples rather than replacing prior data.

**Plans:** TBD
**UI hint**: yes

### Phase 7: Production Deployment Posture

**Goal:** The public and release posture makes data mode, privacy expectations, verification, and compliance blockers explicit before launch.
**Mode:** mvp
**Depends on:** Phase 6; deployment posture must reflect the final auth, storage, consent, and health-import behavior.
**Requirements:** PROD-01, PROD-02, PROD-03, PROD-04
**Success Criteria** (what must be TRUE):

  1. Public demo page clearly distinguishes device-local demo data from account-backed production data.
  2. User data retention, export, and deletion expectations are documented before production launch.
  3. Deployment verification includes passing `flutter analyze`, `flutter test`, and `flutter build web`.
  4. Production release notes identify privacy-sensitive changes and any remaining compliance blockers.

**Plans:** TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Demo Promise Hardening | 1/1 | Complete    | 2026-07-06 |
| 2. Auth and Session Model | 1/1 | Complete    | 2026-07-06 |
| 3. Privacy and Repository Contract Hardening | 1/1 | Complete    | 2026-07-06 |
| 4. Firebase Auth and Firestore Adapter | 0/TBD | Not started | - |
| 5. Consent Management and Invite Lifecycle | 0/TBD | Not started | - |
| 6. Real Sleep Import Providers | 0/TBD | Not started | - |
| 7. Production Deployment Posture | 0/TBD | Not started | - |
