# Phase 5: Consent Management and Invite Lifecycle - Specification

**Created:** 2026-07-06
**Ambiguity score:** 0.14 (gate: <= 0.20)
**Requirements:** 8 locked

## Goal

Replace the hardcoded invite affordance with a consent lifecycle where patients validate, review, accept, revoke, and audit sleep-summary sharing while clinicians see accurate link status without premature access.

## Background

Phase 4 added Firebase Auth and Firestore adapter boundaries plus emulator-proven rules for accepted clinician links. The app still runs the public demo through `InMemoryAppRepository`, and the patient dashboard still accepts a hardcoded `NID-1138` invite with a single button. The current models have `ConsentStatus.notAsked/granted/revoked` and `LinkStatus.pending/accepted/revoked`, but no expired status, no consent event history, no invite preview, no validation error surface, and no formal consent repository contract. `NguyenInDoubtState` is still typed to `InMemoryAppRepository` because it calls demo-only consent methods directly.

## Requirements

1. **Invite validation**: Patient enters an invite code and validation returns a non-granting preview for valid pending invites.
   - Current: `PatientDashboard` displays `invite code NID-1138`, and `NguyenInDoubtState.acceptClinicInvite()` always submits that hardcoded value.
   - Target: Patient can enter a code, submit it, and see clinician/clinic identity plus sleep-only sharing scope before accepting.
   - Acceptance: Valid pending code shows preview data and leaves `ConsentStatus` and link status unchanged until the patient explicitly accepts.

2. **Validation error states**: Invalid, expired, already accepted, revoked, missing, malformed, and wrong-patient invite codes produce clear non-granting states.
   - Current: No invite input exists and the repository accepts the seeded code path without user-entered validation.
   - Target: Invite validation distinguishes these states without exposing extra patient data or granting sleep access.
   - Acceptance: Tests cover invalid, expired, accepted, revoked, missing, malformed, and wrong-patient codes; none produce an accepted link or clinician sleep access.

3. **Atomic acceptance**: Accepting a validated invite updates patient consent, link status, timestamps, and history as one logical operation.
   - Current: Local repository updates the user first, then updates a matching link if found; Firestore `clinicianLinks` writes are admin-only, so real acceptance needs a trusted operation boundary.
   - Target: The app calls a repository/service operation that validates the invite and writes the accepted state atomically or fails with no partial grant.
   - Acceptance: Repository tests prove failed validation leaves user consent, link status, and history unchanged; successful acceptance creates exactly one accepted link and one accepted history event.

4. **Revocation**: Patient can revoke sleep-summary sharing from the current sharing state.
   - Current: A test helper can change link status, but there is no patient-facing revoke flow.
   - Target: Patient sees who currently has access and can revoke from the dashboard without affecting journals, sleep samples, or local account state.
   - Acceptance: After revocation, clinician linked-patient lists and sleep-summary reads no longer include that patient, and the patient dashboard shows sharing off/revoked.

5. **Clinician lifecycle status**: Clinician dashboard distinguishes accepted, pending, revoked, expired, and missing invite states without showing sleep data for non-accepted links.
   - Current: Clinician dashboard only lists accepted patients or an empty state.
   - Target: Clinician can understand whether a link is waiting, accepted, revoked, expired, or unavailable while only accepted rows can open sleep summaries.
   - Acceptance: Widget/repository tests show accepted rows load sleep summaries; pending/revoked/expired/missing rows show status copy and cannot load sleep samples or summaries.

6. **Consent history**: Consent events are append-only and visible enough for patient review, support, and future compliance work.
   - Current: Only current `consentStatus`, `clinicCode`, and link timestamps exist.
   - Target: Acceptance and revocation write immutable history records with actor, patient id, clinician id, invite code reference, previous status, next status, and timestamp.
   - Acceptance: History records are written for accept and revoke, sorted newest-first, persist across local demo reloads, and contain no journal body or raw health samples.

7. **Repository boundary**: Consent and invite behavior is exposed through app-level repository interfaces, not demo-only `InMemoryAppRepository` calls from state or screens.
   - Current: `NguyenInDoubtState` depends on `InMemoryAppRepository` directly and calls `grantPatientConsent(...)`.
   - Target: State and UI use consent/invite repository methods that can be implemented by both local demo and Firebase/trusted-backend adapters.
   - Acceptance: Screens do not call Firebase or demo-only repository methods; analyzer/tests prove the patient flow works through the shared interface.

8. **Privacy-preserving copy and scope**: Consent UI states exactly what is shared and what is never shared in v1.
   - Current: Copy says only sleep summaries/samples become visible and journals stay private, but there is no pre-acceptance review or revocation copy.
   - Target: Preview, accepted, revoked, and clinician status states repeat the v1 boundary: sleep summaries/samples only; journals, drafts, reflections, messaging, diagnosis, and emergency monitoring remain out of scope.
   - Acceptance: Widget tests find sleep-only and journal-private copy in invite preview, accepted state, revoked state, and clinician lifecycle status surfaces.

## Boundaries

**In scope:**
- Patient invite code entry, validation, preview, acceptance, revocation, and status display.
- Link lifecycle statuses: pending, accepted, revoked, expired, missing/invalid, and malformed/wrong-patient denial paths.
- Append-only consent history model and local persistence.
- Repository interface additions for invite validation, acceptance, revocation, status, and history.
- Firebase contract/rules test updates proving non-accepted links never expose sleep data and accepted links still never expose journals.
- Clinician dashboard status rows for accepted and non-accepted links.
- Widget/repository/rules tests for acceptance, revocation, history, and non-granting validation states.

**Out of scope:**
- Patient-clinician messaging - v1 explicitly excludes messaging and it changes clinical expectations.
- Journal sharing or selective journal excerpts - deferred to v2 and conflicts with the current privacy promise.
- Broad metric-category consent beyond sleep - Phase 6 remains sleep-only for real provider imports.
- Live Cloud Functions deployment or production Firebase enablement - Phase 5 may define the trusted operation contract, but live backend rollout remains compliance-gated.
- Push/email notifications for invite status changes - useful later, not needed to prove lifecycle correctness.
- Admin clinic/invite management UI - trusted invite creation can stay seeded/admin-contract-only for this phase.
- Data retention/export/deletion policy - Phase 7 owns production posture.

## Constraints

- Public demo must remain runnable locally without live Firebase credentials.
- No Analytics, Crashlytics, telemetry, or production monitoring package may be added.
- Clinician access remains sleep-only and accepted-link-only; journals stay patient-owned.
- Patient validation alone must not grant access or notify a clinician that the patient viewed the invite.
- A revoked link must not be reactivated by re-entering the same revoked/expired invite unless a new trusted pending invite exists.
- Firestore client rules currently keep `clinicianLinks` writes admin-only, so production acceptance/revocation needs a trusted service boundary or documented adapter limitation.

## Acceptance Criteria

- [ ] Patient can type a valid pending invite code and see a preview before accepting.
- [ ] Validation of invalid, expired, accepted, revoked, missing, malformed, and wrong-patient invite codes grants no access.
- [ ] Accepting an invite atomically updates patient consent, link status, timestamps, and consent history.
- [ ] Failed acceptance leaves user consent, link status, and history unchanged.
- [ ] Patient can revoke sharing; clinician sleep-summary access is denied immediately afterward.
- [ ] Clinician dashboard shows accepted, pending, revoked, expired, and missing/unavailable states without sleep data for non-accepted links.
- [ ] Consent history persists locally and contains only metadata, never journal text or raw health samples.
- [ ] Screens/state use repository interface methods for consent/invite behavior.
- [ ] Firestore rules tests still deny clinician journal reads for every link state.
- [ ] Widget tests cover invite preview, accepted state, revoked state, and clinician lifecycle copy.

## Edge Coverage

**Coverage:** 10/10 applicable edges resolved - 0 unresolved

| Category | Requirement | Status | Resolution / Reason |
|----------|-------------|--------|---------------------|
| Empty / degenerate | R1 | resolved | Empty or whitespace invite input is rejected before validation and grants no access. |
| Encoding / representation | R1 | resolved | Invite code normalization trims whitespace and treats code casing consistently. |
| Idempotency / repetition | R3 | resolved | Re-accepting an already accepted link does not create duplicate accepted history events. |
| Concurrency / effect ordering | R3 | resolved | Acceptance is one logical operation; failed validation leaves no partial grant. |
| Idempotency / repetition | R4 | resolved | Repeated revocation leaves the link revoked and does not restore access. |
| Concurrency / effect ordering | R4 | resolved | Revocation takes effect before clinician sleep reads can succeed again. |
| Ordering / stability | R5 | resolved | Clinician status rows use deterministic ordering: accepted first, then pending, revoked, expired/missing. |
| Empty / degenerate | R5 | resolved | No links renders an empty state, not stale selected patient sleep data. |
| Ordering / stability | R6 | resolved | Consent history is sorted newest-first by event timestamp. |
| Empty / degenerate | R6 | resolved | No history renders a clear empty state and does not imply sharing exists. |

## Prohibitions (must-NOT)

**Coverage:** 5/5 applicable prohibitions resolved - 0 unresolved

| Prohibition (must-NOT statement) | Requirement | Status | Verification / Reason |
|----------------------------------|-------------|--------|------------------------|
| MUST NOT grant clinician sleep access from validation alone. | R1 | resolved | verification: test |
| MUST NOT expose journal entries, drafts, or private reflections through invite, status, history, or clinician surfaces. | R4/R5/R6/R8 | resolved | verification: test |
| MUST NOT let a clinician self-create or self-accept a link through client-side writes. | R3/R7 | resolved | verification: test |
| MUST NOT use coercive copy that pressures the patient to share data or frames revocation as unsafe/noncompliant. | R8 | resolved | verification: judgment |
| MUST NOT store raw journal text or raw sleep samples in consent history. | R6 | resolved | verification: test |

## Ambiguity Report

| Dimension          | Score | Min   | Status | Notes |
|--------------------|-------|-------|--------|-------|
| Goal Clarity       | 0.90  | 0.75  | met    | Outcome is concrete: replace hardcoded invite with validated lifecycle. |
| Boundary Clarity   | 0.85  | 0.70  | met    | In-scope and out-of-scope lists separate consent from messaging, journal sharing, health imports, and production rollout. |
| Constraint Clarity | 0.80  | 0.65  | met    | Firebase trusted-operation limitation and privacy constraints are explicit. |
| Acceptance Criteria| 0.82  | 0.70  | met    | Pass/fail checks cover patient, clinician, repository, and rules behavior. |
| **Ambiguity**      | 0.14  | <=0.20| met    | Ready for discuss/plan with the trusted operation boundary called out. |

## Interview Log

| Round | Perspective | Question summary | Decision locked |
|-------|-------------|------------------|-----------------|
| 1 | Researcher | What exists today for consent and invites? | Hardcoded `NID-1138`, minimal current-status fields, accepted-link rules, no history/preview/revocation UI. |
| 2 | Simplifier | What is the irreducible Phase 5 scope? | Validate, preview, accept, revoke, status, history, tests; no messaging/journal sharing/health imports. |
| 3 | Boundary Keeper | What additional features should be included? | Add error states, expired status, trusted operation boundary, clinician non-accepted status rows, and append-only history. |
| 4 | Failure Analyst | What breaks the privacy promise? | Validation granting access, clinician self-acceptance, reusing revoked invites, history storing private content, or coercive sharing copy. |

---

*Phase: 05-consent-management-and-invite-lifecycle*
*Spec created: 2026-07-06*
*Next step: /gsd-discuss-phase 5 - implementation decisions*
