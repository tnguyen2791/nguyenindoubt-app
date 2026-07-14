---
phase: 18
plan: 18
subsystem: sharing-and-provider
tags: [sharing, consent, provider-portal, privacy-contract, design-buildout]
status: complete
requires:
  - Phase 11 clinician surface (directional stat-delta summary, verbatim disclosure)
  - Consent state machine (validateInviteCode → acceptValidatedInvite → revokeConsent)
  - PatientSleepBundle (sleep-only clinician read)
provides:
  - User-side sharing flow (request → choose scopes → send → status → manage/pause)
  - Expanded provider portal (requests, worth-a-look, roster, shared readings, settings)
  - Contract test proving the shared bundle carries no journal + no readiness
affects:
  - lib/screens/clinician_dashboard.dart (rewritten into the provider portal)
  - lib/screens/patient_dashboard.dart (dashboard consent card → sharing flow entry)
  - lib/screens/tab_shells.dart (Profile "Sharing" rows wired)
tech-stack:
  added: []
  patterns:
    - Reused fadeDetailRoute + AnimatedBuilder pushed-route pattern for the flow
    - SectionKicker / _SectionLabel `.k` idiom, SectionCard, StatusPill, NidToggle reuse
    - LayoutBuilder responsive stacking (request card, provider header) to avoid overflow
key-files:
  created:
    - lib/screens/sharing_flow.dart
    - test/sharing_provider_test.dart
    - .planning/phases/18-sharing-provider/18-SUMMARY.md
  modified:
    - lib/screens/clinician_dashboard.dart
    - lib/screens/patient_dashboard.dart
    - lib/screens/tab_shells.dart
    - test/widget_test.dart
key-decisions:
  - Journal stripped from every shareable scope; rendered as explicit "Not offered" rows (contract wins over the handoff's opt-in-journal model)
  - Provider shared-readings is sleep-only — no readiness ring, no journal-tags card (design 80's journal card omitted)
  - Sharing flow reuses the invite-code mechanic (backend-safe) rather than the mocks' aspirational provider-search; acceptInvite stays guarded in Firebase mode
  - "Send request" activates sharing immediately in demo mode (no separate clinician-accept step locally); Firebase mode surfaces calm "not available yet" copy
requirements-completed: []
coverage:
  - deliverable: "User-side sharing flow: request → choose scopes → send → status → manage/pause"
    verification:
      - kind: test
        ref: "test/sharing_provider_test.dart#request → choose scopes → send → status → pause"
        status: pass
    human_judgment: false
  - deliverable: "Journal is never an offered shareable scope"
    verification:
      - kind: test
        ref: "test/sharing_provider_test.dart#the sharing flow never offers journal as a scope"
        status: pass
    human_judgment: false
  - deliverable: "Provider portal renders requests / worth-a-look / roster / shared readings"
    verification:
      - kind: test
        ref: "test/sharing_provider_test.dart#renders requests, worth-a-look, roster, and shared readings"
        status: pass
    human_judgment: false
  - deliverable: "Provider settings render sleep-only, no journal scope"
    verification:
      - kind: test
        ref: "test/sharing_provider_test.dart#provider settings render sleep-only, no journal scope"
        status: pass
    human_judgment: false
  - deliverable: "Shared bundle carries no journal and no readiness (contract enforced in logic)"
    verification:
      - kind: test
        ref: "test/sharing_provider_test.dart#the provider sleep bundle carries no journal and no readiness"
        status: pass
      - kind: test
        ref: "test/sharing_provider_test.dart#a clinician cannot read the patient journal directly"
        status: pass
    human_judgment: false
  - deliverable: "Verbatim visibility disclosure + Phase-11 stat-delta preserved on the provider surface"
    verification:
      - kind: test
        ref: "test/clinician_affordance_test.dart#clinician summary is directional, never a raw sample count"
        status: pass
      - kind: test
        ref: "test/widget_test.dart#clinician dashboard keeps sleep-only privacy copy"
        status: pass
    human_judgment: false
  - deliverable: "Visual fidelity to design mocks 82/84/86/102/78 and 74/76/80/96"
    verification: []
    human_judgment: true
    rationale: "Pixel-level fidelity to the mocks is a visual judgment; automated tests assert structure and grammar, not appearance. Owner spot-check recommended on device."
metrics:
  duration: 12 min
  completed: 2026-07-12
  tasks: 3
  files: 7
---

# Phase 18 Plan 18: Sharing flow + Provider portal Summary

Built the consent-first user-side **Sharing flow** (request → choose sleep-only
scopes → send → status → manage/pause) on the existing consent state machine, and
expanded the Phase-11 clinician surface into a full **Provider portal** (greeting
+ roster summary, Requests, Worth-a-look, Everyone roster, person-first shared
readings, and a settings sheet) — all sleep-summaries-only, with journal never a
shareable scope and the verbatim "Hidden: journal entries…" disclosure intact.

## Accomplishments

- **User-side sharing flow** (`lib/screens/sharing_flow.dart`, design 82/84/86/102/78):
  a single `SharingFlowScreen` that routes by consent status — `RequestSharingScreen`
  (find provider by invite code → choose scopes → send), `RequestSentScreen`
  (confirmation, design 86), and `ManageSharingScreen` (what a provider can see +
  quiet Pause, design 78/102). Reuses `validateInviteCode` / `acceptValidatedInvite`
  / `revokeConsent` — no new trust boundary. Reachable from the Profile "Sharing"
  rows (with a live Active/Paused/Off value) and the dashboard consent card.
- **Contract enforcement:** the scope list offers **Scores & trends** and **Sleep
  detail** only. **Journal tags** and **Journal notes** render as explicit
  "Not offered — your … stay private" rows (design 102's contract-correct
  treatment), never as a toggle. No `Switch` exists in the flow. The verbatim
  visibility disclosure appears on every step that names provider visibility.
- **Provider portal** (`lib/screens/clinician_dashboard.dart`, design 74/76/80/96):
  header with the "N people currently share … · M worth a look this morning" summary
  and a settings sheet; Requests (pending invites, Accept/Decline with calm demo
  feedback); Worth-a-look (sleep-only pattern observations derived purely from the
  shared sleep summaries — never journal citations); Everyone roster (SAFE-02
  affordance truth preserved — only accepted rows tappable, sleep-only "shares:
  scores · sleep" descriptor); person-first shared-readings detail keeping the
  Phase-11 directional stat-delta, the honest 7-night trend, the verbatim
  disclosure, and the humility note.
- **Stripped per contract:** the design mocks' "journal tags" scope chip, the
  journal-citing Worth-a-look card, the "scores · sleep · journal" shares label,
  the shared-readings journal-tags card, and the readiness ring on the provider
  surface. Readiness stays patient-only.
- **Tests** (`test/sharing_provider_test.dart`, 6 new): shared bundle carries no
  journal + no readiness; clinician cannot read the journal directly
  (PrivacyException); full user flow request→choose→send→status→pause; journal
  never offered; provider portal renders all sections; provider settings sleep-only.

## Deviations from Plan

**None from the phase intent.** Two contract-driven adjustments were required
because several design mocks themselves violate the standing privacy contract
(as flagged in `docs/design-handoff/INCORPORATION.md`). These are the ruling in
action, not scope deviations:

**1. [Rule 2 — Contract enforcement] Stripped journal from provider mocks**
- **Found during:** Provider portal build (design 76/80/96).
- **Issue:** Mock 76 shows "scores · sleep · journal" in the roster shares
  column and a journal-tag citation in "Worth a look"; mock 80 has a "Journal ·
  this week / tags" card and a "journal tags" scope chip; mock 96 shows "scores,
  sleep & journal" request copy. All violate the sleep-only contract.
- **Fix:** Journal removed from every provider-facing scope label, worth-a-look
  citation, and shared-readings card. Provider shares descriptors read
  "scores · sleep" only.
- **Verification:** `test/sharing_provider_test.dart` asserts no
  "scores · sleep · journal" leak; `flutter test` green.

**2. [Rule 1 — Layout] Responsive request card + provider header**
- **Found during:** `phase one surfaces render` test (390px phone width).
- **Issue:** The Requests card's inline Accept/Decline Row overflowed by 39px at
  phone width.
- **Fix:** `LayoutBuilder` stacks the actions below the identity under 460px;
  wide layouts keep them inline.
- **Verification:** `flutter test` green at both 390px and 1180px.

**Total deviations:** 2 auto-applied (1 contract enforcement, 1 layout).
**Impact:** None negative — both strengthen the privacy contract / robustness.

## Existing tests updated (not deviations)

Two Phase-11 clinician widget tests encoded the old surface grammar and were
updated to the P18 provider portal while keeping every privacy-critical
assertion verbatim:
- `clinician dashboard shows invite lifecycle statuses`: `INVITE STATUS` kicker →
  `EVERYONE` roster kicker; tall viewport so the stacked sections lay out.
- `phase one surfaces render …`: unchanged assertions; passed once the request
  card became responsive.

The verbatim disclosure, the "Accepted invites only. Sleep summaries, never
journals." promise, the humility note, the directional stat-delta, and the
SAFE-02 affordance-truth tests are all unchanged and green.

## Verification

- `dart format lib test` — 3 files formatted, 0 unexpected.
- `flutter analyze` — **No issues found!**
- `flutter test` — **113 passed** (107 baseline + 6 new).
- `flutter build web` — **✓ Built build/web**.

## Known Stubs

- Provider Requests **Accept/Decline** are demo-only: they surface calm feedback
  (a SnackBar explaining "accepting invites needs a verified backend step") rather
  than mutating a trusted link, because a real accept requires the Cloud Function
  that Firebase-mode `acceptInvite` intentionally guards. This matches the plan
  ("build UI, guard the accept") and the state layer's existing calm-copy path.
  Resolution lands with the trusted-backend operation in a later phase.
- Provider settings **Notifications** toggles are display-only values (matching
  the design), consistent with the patient-side notifications preference model.

## Next

Phase complete for the Sharing + Provider portal slice. The Weekly report
(design 94/95) is deliberately out of scope and is the next candidate. Ready for
`/gsd-verify-work 18`.

## Self-Check: PASSED

All created files exist on disk; all three production/test commits (dca80a0, 3842197, 447b21e) are in git history. Verification bar green: format clean, analyze clean, 113 tests pass, web build succeeds.
