# Phase 5: Consent Management and Invite Lifecycle - Context

**Gathered:** 2026-07-06
**Status:** Ready for planning
**Source:** Phase 5 SPEC

<domain>
## Phase Boundary

Phase 5 replaces the one-button hardcoded invite demo with a patient-controlled lifecycle:
validate an invite, preview what sharing means, accept, revoke, see status, and retain consent history. Clinicians should see link lifecycle states, but only accepted links can load sleep summaries.

</domain>

<decisions>
## Implementation Decisions

### Consent lifecycle
- Invite validation is non-granting: it may show preview/error state but must not change consent or link status.
- Acceptance must update the patient consent status, link status, timestamps, and consent history as one logical operation.
- Revocation must immediately remove clinician sleep access and leave journals, sleep samples, and account/session state intact.
- A revoked or expired invite must not be reactivated by re-entering the same code.

### Repository boundary
- Consent behavior belongs behind repository interfaces. `NguyenInDoubtState` should not call demo-only consent helpers for normal patient/clinician flows.
- The local demo repository implements the full lifecycle. Firebase can expose the contract while remaining fail-closed for client-side self-acceptance until a trusted backend operation exists.

### UI behavior
- Patient dashboard needs invite entry, validation errors, preview, acceptance, accepted state, revocation, and consent history.
- Clinician dashboard needs lifecycle status rows. Only accepted rows can open sleep summaries.
- Copy must repeat the v1 boundary: sleep summaries/samples only; journals, drafts, reflections, messaging, diagnosis, and emergency monitoring remain out of scope.

### Security posture
- Client-side clinicians must not self-create or self-accept links.
- Consent history must contain metadata only, not journal body text or raw sleep samples.
- Firestore rules should continue denying clinician journal reads for every link state.

</decisions>

<canonical_refs>
## Canonical References

### Planning
- `.planning/phases/05-consent-management-and-invite-lifecycle/05-SPEC.md` - locked Phase 5 requirements and acceptance criteria.
- `.planning/REQUIREMENTS.md` - CONS-01 through CONS-05.
- `.planning/ROADMAP.md` - Phase 5 scope and phase boundaries.
- `.planning/phases/04-firebase-auth-and-firestore-adapter/04-01-SUMMARY.md` - Firebase adapter and rules decisions from Phase 4.

### Code
- `lib/models/app_models.dart` - current consent/link model definitions.
- `lib/repositories/app_repository.dart` - local repository, repository interfaces, persistence.
- `lib/repositories/firebase_app_repository.dart` - Firebase adapter boundary.
- `lib/state/app_state.dart` - app state and current demo-only consent call.
- `lib/screens/patient_dashboard.dart` - patient invite/sharing UI.
- `lib/screens/clinician_dashboard.dart` - clinician linked-patient UI.
- `firestore.rules` - Firestore privacy boundary.
- `test/repositories/app_repository_test.dart` - repository privacy/lifecycle tests.
- `test/widget_test.dart` - user-visible patient/clinician tests.
- `test/firestore/firestore_rules.test.mjs` - emulator rules tests.

</canonical_refs>

<specifics>
## Specific Ideas

- Add `LinkStatus.expired`.
- Add consent event metadata with actor id, patient id, clinician id, invite code, previous status, next status, action, and timestamp.
- Add invite validation statuses for valid, empty, invalid, expired, already accepted, revoked, missing, malformed, and wrong-patient cases.
- Add clinician link status view model that can show accepted/pending/revoked/expired rows without passing journals or sleep data for non-accepted links.
- Update local persistence schema compatibly by defaulting absent consent history to an empty list.

</specifics>

<deferred>
## Deferred Ideas

- Live Cloud Functions deployment or production Firebase enablement.
- Admin clinic/invite management UI.
- Notifications for invite status changes.
- Messaging, diagnosis, emergency monitoring, or journal sharing.
- Broader health metric consent beyond sleep.

</deferred>

---

*Phase: 05-consent-management-and-invite-lifecycle*
*Context gathered: 2026-07-06*
