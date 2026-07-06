# Requirements: NguyenInDoubt Flutter MVP

**Defined:** 2026-07-06
**Core Value:** Patients can explore sleep context and private reflection while clinicians see only consented sleep summaries, never journal content.

## v1 Requirements

Requirements for the next release arc. The existing local MVP is the baseline; these requirements harden it and move it toward a reviewed production-ready shape.

### Demo Baseline

- [x] **DEMO-01**: Patient can complete the current demo flow from onboarding to sleep import, dashboard review, private journaling, resources, and safety page without regressions.
- [x] **DEMO-02**: Clinician can complete the current accepted-link demo flow and view linked-patient sleep summaries without journal visibility.
- [x] **DEMO-03**: Journal, resources, safety, and clinician screens render correctly on phone-width and desktop-width layouts.
- [x] **DEMO-04**: Mutable local demo state persists across browser/app refresh and can be reset or clearly explained as device-local demo data.
- [x] **DEMO-05**: Safety content remains educational and clearly routes urgent situations to external crisis resources without implying in-app emergency monitoring.

### Auth and Onboarding

- [x] **AUTH-01**: User can move through explicit signed-out, onboarding, patient, and clinician states without relying on a fake role switch as production auth.
- [x] **AUTH-02**: Patient onboarding captures the minimum profile state needed for the app while preserving the local/demo mode.
- [x] **AUTH-03**: Clinician access depends on a trusted clinician role source or demo override, not arbitrary client-side selection.
- [x] **AUTH-04**: Session state restores predictably after app refresh without exposing the wrong role or patient data.

### Privacy and Data Access

- [x] **PRIV-01**: Repository contracts make patient journal reads unavailable to clinician-facing code paths.
- [x] **PRIV-02**: Tests cover accepted, pending, revoked, and missing clinician links for sleep-summary access.
- [x] **PRIV-03**: Tests prove clinician access to journal entries is denied regardless of link status.
- [x] **PRIV-04**: Screens and state models avoid passing journal data into clinician views.
- [x] **PRIV-05**: Privacy copy consistently explains that clinicians see sleep summaries only after consent.

### Firebase Backend

- [ ] **FIRE-01**: Firebase Auth and Firestore remain behind repository interfaces rather than direct screen calls.
- [ ] **FIRE-02**: Firestore rules enforce patient-owned journal access and accepted-link sleep-only clinician access.
- [ ] **FIRE-03**: Firestore rules deny pending, revoked, missing, or malformed clinician links.
- [ ] **FIRE-04**: Firestore emulator tests cover users, clinician links, health samples, daily summaries, journal entries, and resource cards.
- [ ] **FIRE-05**: Analytics, Crashlytics, and telemetry remain disabled unless a separate compliance-reviewed decision enables them.

### Consent and Invites

- [ ] **CONS-01**: Patient can validate and accept a real invite code instead of hardcoded `NID-1138`.
- [ ] **CONS-02**: Patient can revoke clinician sleep-summary sharing.
- [ ] **CONS-03**: Invite and consent status changes are atomic and cannot grant access before invite validation succeeds.
- [ ] **CONS-04**: Clinician dashboard updates when a link is accepted, revoked, expired, or missing.
- [ ] **CONS-05**: Consent history is represented well enough for audit, support, or future compliance review.

### Sleep Import Providers

- [ ] **HLTH-01**: HealthKit and Health Connect implementations sit behind `HealthDataProvider`.
- [ ] **HLTH-02**: Patient sees clear permission states for unavailable, not requested, partial, denied, revoked, and ready health access.
- [ ] **HLTH-03**: Sleep imports request sleep-only access for the MVP.
- [ ] **HLTH-04**: Imported health samples normalize into the existing `HealthSample` and `DailySummary` model.
- [ ] **HLTH-05**: Production imports deduplicate and incrementally sync samples rather than replacing all prior production data.

### Production Posture

- [ ] **PROD-01**: Public demo hosting clearly distinguishes demo-local data from account-backed production data.
- [ ] **PROD-02**: User data retention, export, and deletion expectations are documented before production launch.
- [ ] **PROD-03**: Deployment verification includes `flutter analyze`, `flutter test`, and `flutter build web`.
- [ ] **PROD-04**: Production release notes identify privacy-sensitive changes and any remaining compliance blockers.

## v2 Requirements

Deferred to future release. Tracked but not in the current roadmap.

### Care Collaboration

- **COLL-01**: Patient can selectively share a journal excerpt with a clinician.
- **COLL-02**: Patient and clinician can exchange asynchronous messages.
- **COLL-03**: Clinician can annotate sleep trends without accessing private journal text.

### Broader Health Context

- **METR-01**: Patient can import additional health metrics beyond sleep.
- **METR-02**: Patient can choose which metric categories are visible to a clinician.
- **METR-03**: Patient can export a personal longitudinal report.

### Operations

- **OPS-01**: Admin can manage resource cards through a reviewed content workflow.
- **OPS-02**: Support staff can handle account recovery without accessing journals.
- **OPS-03**: Production monitoring can be added after privacy and compliance review.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Clinician journal access by default | Violates the core privacy promise. |
| Diagnosis, risk scoring, or medication recommendations | The app is educational and reflective, not a medical decision system. |
| Emergency monitoring or dispatch | Safety resources can route users outward, but the app does not monitor crises. |
| Analytics, Crashlytics, or telemetry by default | Requires separate compliance and privacy review. |
| Broad health metric sharing in v1 | Sleep-only scope keeps the consent surface narrow. |
| Patient-clinician messaging in v1 | Adds safety, compliance, and expectation-management complexity beyond the MVP. |
| Live Firebase writes before emulator/rules validation | Sensitive data requires rules, tests, and review before production storage. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEMO-01 | Phase 1 | Complete |
| DEMO-02 | Phase 1 | Complete |
| DEMO-03 | Phase 1 | Complete |
| DEMO-04 | Phase 1 | Complete |
| DEMO-05 | Phase 1 | Complete |
| AUTH-01 | Phase 2 | Complete |
| AUTH-02 | Phase 2 | Complete |
| AUTH-03 | Phase 2 | Complete |
| AUTH-04 | Phase 2 | Complete |
| PRIV-01 | Phase 3 | Complete |
| PRIV-02 | Phase 3 | Complete |
| PRIV-03 | Phase 3 | Complete |
| PRIV-04 | Phase 3 | Complete |
| PRIV-05 | Phase 3 | Complete |
| FIRE-01 | Phase 4 | Pending |
| FIRE-02 | Phase 4 | Pending |
| FIRE-03 | Phase 4 | Pending |
| FIRE-04 | Phase 4 | Pending |
| FIRE-05 | Phase 4 | Pending |
| CONS-01 | Phase 5 | Pending |
| CONS-02 | Phase 5 | Pending |
| CONS-03 | Phase 5 | Pending |
| CONS-04 | Phase 5 | Pending |
| CONS-05 | Phase 5 | Pending |
| HLTH-01 | Phase 6 | Pending |
| HLTH-02 | Phase 6 | Pending |
| HLTH-03 | Phase 6 | Pending |
| HLTH-04 | Phase 6 | Pending |
| HLTH-05 | Phase 6 | Pending |
| PROD-01 | Phase 7 | Pending |
| PROD-02 | Phase 7 | Pending |
| PROD-03 | Phase 7 | Pending |
| PROD-04 | Phase 7 | Pending |

**Coverage:**

- v1 requirements: 33 total
- Mapped to phases: 33
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-06*
*Last updated: 2026-07-06 after initial definition*
