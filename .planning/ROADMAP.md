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
- [x] **Phase 4: Firebase Auth and Firestore Adapter** - Add account-backed auth/storage behind repository interfaces with emulator-proven Firestore privacy rules. (completed 2026-07-06)
- [x] **Phase 5: Consent Management and Invite Lifecycle** - Replace the hardcoded invite with validated invite, consent, revocation, status, and history flows. (completed 2026-07-06)
- [x] **Phase 6: Real Sleep Import Providers** - Add HealthKit and Health Connect providers behind `HealthDataProvider` with sleep-only permissions and safe sync behavior. (completed 2026-07-06)
- [x] **Phase 7: Production Deployment Posture** - Make release verification, data expectations, and compliance blockers explicit before production launch. (completed 2026-07-06)

### Milestone v1.1 — Experience and Insight (design critique)

- [x] **Phase 8: Design System Foundations** - Real type hierarchy, spacing/radius tokens, state-driven pills, neutralize the Material seed leak, one BrandMark. (foundation for all v1.1 visual work) (completed 2026-07-06)
- [x] **Phase 9: Safety and Affordance Integrity** - Crisis buttons dial/text directly, cards tell the truth about tappability, journal gets an empty state + delete. (completed 2026-07-06)
- [x] **Phase 10: Brand Arrival and Guided Onboarding** - Animated brand-intro splash + on-brand web loader, patient-first welcome, expectation-setting onboarding, guided first-run. (completed 2026-07-12)
- [x] **Phase 11: Insightful Data Displays** - Oura-style hierarchy, a real (or retired) score ring, honest fixed-axis trend bars with a target line, gentle observational insights. (completed 2026-07-12)
- [ ] **Phase 12: Sharing as a First-Class Flow** - Promote consent to its own destination, one vocabulary, confirm-gated revoke, explicit 2-step invite.
- [ ] **Phase 13: Motion and Feedback Choreography** - Cross-fade transitions, reassuring consent/import confirmations, sleep-bar grow-in, calm loading and micro-interactions.

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

**Plans:** 1/1 plans complete
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

**Plans:** 1/1 plans complete
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

**Plans:** 1/1 plans complete
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

**Plans:** 1/1 plans complete
**UI hint**: yes

### Phase 8: Design System Foundations

**Goal:** The app has a real, tokenized design system so every later surface reads as a deliberate premium health product, not templated Material.
**Mode:** mvp
**Depends on:** v1.0 complete; this refactors the shared theme/components the rest of v1.1 builds on, so it goes first.
**Requirements:** DS-01, DS-02, DS-03, DS-04, DS-05
**Success Criteria** (what must be TRUE):

  1. A defined type ladder (distinct heading/body/label sizes and weights) is applied; no widget relies on an undefined text token or piles on w800/w900.
  2. Spacing and radius tokens exist and replace the freehand magic numbers and one-off logo radii across cards, headers, and gaps.
  3. `StatusPill` renders by semantic tone (state-encoded color), not a single default mint chip.
  4. No on-screen color comes from an un-blessed Material seed tone or a stray stock color; dialogs, nav, segmented buttons, and outlines use palette values.
  5. A single `BrandMark` widget with min-size/clearspace rules is used everywhere the logo appears.

**Plans:** 3/3 plans complete

- [x] 08-01-PLAN.md — Theme foundation: type ladder, NidSpace/NidRadius tokens, seed-leak neutralization, PillTone + BrandMark primitives (wave 1)
- [x] 08-02-PLAN.md — Patient + clinician dashboard sweep: pill tones, stock-red fix, de-weight caps labels, tokens (wave 2)
- [x] 08-03-PLAN.md — Journal + resources + app shell sweep: pill tones, single BrandMark, de-weight, tokens (wave 2)

**UI hint**: yes

### Phase 9: Safety and Affordance Integrity

**Goal:** Controls do what they look like they do, and the one screen where latency is dangerous — Safety — takes real action in a single tap.
**Mode:** mvp
**Depends on:** Phase 8; uses the new tokens/components, but is otherwise independent and high-priority (recommended first execution).
**Requirements:** SAFE-01, SAFE-02, SAFE-03
**Success Criteria** (what must be TRUE):

  1. Crisis actions launch `tel:`/`sms:` (988, emergency) directly rather than opening an explanatory dialog, while remaining educational and non-monitoring.
  2. Tappable cards signal it; non-actionable or disabled rows are visually distinct and never silently absorb a tap.
  3. The journal shows an empty state and supports per-entry delete with confirmation.

**Plans:** 3/3 plans complete

- [x] 09-01-PLAN.md — Crisis actions dial/text directly: url_launcher + injectable CrisisLauncher seam, SafetyScreen rewire, graceful web fallback (wave 1)
- [x] 09-02-PLAN.md — Affordance truth: clinician invite rows tappable+chevron vs muted/no-ripple inert rows (wave 1)
- [x] 09-03-PLAN.md — Journal EmptyState + per-entry delete with confirm, deleteJournalEntry through state + both repositories + Firestore rules test (wave 1)

**UI hint**: yes

### Phase 10: Brand Arrival and Guided Onboarding

**Goal:** The first minute feels calm, branded, and guided — from cold-start to a clear first action — instead of a blank frame and a graveyard of placeholders.
**Mode:** mvp
**Depends on:** Phase 8; the splash, welcome, and first-run surfaces use the tokenized system.
**Requirements:** ONB-01, ONB-02, ONB-03, ONB-04
**Success Criteria** (what must be TRUE):

  1. Cold-start shows an on-brand loader and a gentle animated brand-intro (once per cold launch, no analytics) rather than a blank white boot frame.
  2. The welcome leads with a single patient-first primary action; clinician demo access is de-emphasized; required local-only disclosure reads as calm secondary copy.
  3. Onboarding communicates what the app does (sleep/journal/privacy) and rejects empty/invalid names.
  4. The empty first-run dashboard presents one clear primary action with sleep-only permission priming before any OS prompt.

**Plans:** 3/3 plans complete

- [x] 10-01-PLAN.md — Native web loader + animated brand-intro splash gate + splash-skip test seam (wave 1)
- [x] 10-02-PLAN.md — Patient-first welcome reframe + onboarding expectations & name guard (wave 2)
- [x] 10-03-PLAN.md — Guided empty-dashboard first-run (modular, sleep-only priming) (wave 3)

**UI hint**: yes

### Phase 11: Insightful Data Displays

**Goal:** Data surfaces deliver Oura-grade insight — hierarchy, honest charts, and gentle observations — instead of raw, redundant numbers.
**Mode:** mvp
**Depends on:** Phase 8; also coordinates with Phase 12 (moving "clinician link" out of the metric row).
**Requirements:** INS-01, INS-02, INS-03, INS-04, INS-05
**Success Criteria** (what must be TRUE):

  1. The dashboard has a clear hero readout and does not present a connection toggle as a co-equal health metric.
  2. The 0–100 measure is retired or rebuilt as a real, multi-factor, non-diagnostic score shown as a ring with an explicit scale.
  3. Trend bars use a fixed hour axis with a target/average reference line and honest heights (no window-max normalization or floor clamp).
  4. A gentle, strictly-observational insight line (week-over-week / last-night-vs-baseline) is present and never labels the person.
  5. Consistency/balance micro-insights and a directional clinician summary replace raw counts like "samples".

**Plans:** 3/3 plans complete

Plans:

- [x] 11-01-PLAN.md — State-color tokens, pure on-device score/insight computation (unit-tested), honest fixed-axis SleepTrendBars with 8h hairline + ramp legend, ScoreRing/ContributorBar/InfoTip/StatDeltaRow widget kit (wave 1)
- [x] 11-02-PLAN.md — Patient dashboard hierarchy rebuild: greeting/status + insight line, score ring hero with contributors + "not a diagnosis", two-up mini-cards, trend micro-insight, consent card last; coupled widget_test migration (wave 2)
- [x] 11-03-PLAN.md — Clinician directional stat-delta summary (avg + delta vs prior week, variability, nights-with-data) replacing raw counts; clinician_affordance_test coverage + full phase verification bar (wave 3)

**UI hint**: yes

### Phase 12: Sharing as a First-Class Flow

**Goal:** A patient can always find, understand, and safely control who sees their data, with one vocabulary and no one-tap trapdoors.
**Mode:** mvp
**Depends on:** Phase 8; touches the consent surfaces from v1.0 Phase 5 without changing the privacy contract.
**Requirements:** SHARE-01, SHARE-02, SHARE-03, SHARE-04, SHARE-05
**Success Criteria** (what must be TRUE):

  1. Consent/sharing is a first-class destination with a compact status + deep link from the Sleep tab.
  2. A single "sharing" vocabulary replaces the mixed clinician-link/invite/shared-sleep status terms.
  3. Revoke is gated by a confirmation that states the one-way consequence before the action.
  4. The invite flow is an explicit 2-step (validate → confirm) with one primary action at a time and the shared/hidden scope shown inline.
  5. Casing and dates are normalized and the clinician scope is framed positively.

**Plans:** Not yet planned
**UI hint**: yes

### Phase 13: Motion and Feedback Choreography

**Goal:** The app feels alive and calming — transitions fade, actions confirm reassuringly, and data settles gently — never static or janky.
**Mode:** mvp
**Depends on:** Phase 8; best executed after Phases 10–12 so it animates the final surfaces.
**Requirements:** MOT-01, MOT-02, MOT-03, MOT-04
**Success Criteria** (what must be TRUE):

  1. Screen/tab/role transitions cross-fade rather than pop.
  2. Consent accept/revoke and sleep import give reassuring, non-diagnostic confirmations and calm error handling (no silent outcomes).
  3. Sleep bars animate in gently and async loads settle via skeleton/opacity rather than blinking.
  4. Micro-interactions (icon↔spinner cross-fade, subtle press feedback, softened destructive reset) feel calm and intentional.

**Plans:** Not yet planned
**UI hint**: yes

## Progress

**Execution Order:**
v1.0 (complete): 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7
v1.1 (Experience & Insight): 8 -> 9 -> 10 -> 11 -> 12 -> 13 (Phase 8 first; 9 is the recommended first real fix; 13 last so it animates the final surfaces)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Demo Promise Hardening | 1/1 | Complete    | 2026-07-06 |
| 2. Auth and Session Model | 1/1 | Complete    | 2026-07-06 |
| 3. Privacy and Repository Contract Hardening | 1/1 | Complete    | 2026-07-06 |
| 4. Firebase Auth and Firestore Adapter | 1/1 | Complete    | 2026-07-06 |
| 5. Consent Management and Invite Lifecycle | 1/1 | Complete    | 2026-07-06 |
| 6. Real Sleep Import Providers | 1/1 | Complete    | 2026-07-06 |
| 7. Production Deployment Posture | 1/1 | Complete    | 2026-07-06 |
| 8. Design System Foundations | 3/3 | Complete | 2026-07-06 |
| 9. Safety & Affordance Integrity | 3/3 | Complete | 2026-07-06 |
| 10. Brand Arrival & Guided Onboarding | 3/3 | Complete   | 2026-07-12 |
| 11. Insightful Data Displays | 3/3 | Complete   | 2026-07-12 |
| 12. Sharing as a First-Class Flow | 0/0 | Not started | - |
| 13. Motion & Feedback Choreography | 0/0 | Not started | - |
