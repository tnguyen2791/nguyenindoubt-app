---
phase: 09-safety-and-affordance-integrity
plan: 02
subsystem: ui
tags: [flutter, affordance, clinician, invite, inkwell, opacity, safe-02]

# Dependency graph
requires:
  - phase: 08-design-system
    provides: tokens (NidSpace/NidColors/NidRadius), PillTone, SectionCard, StatusPill
  - phase: 09-safety-and-affordance-integrity
    plan: "01"
    provides: sibling SAFE-01 crisis affordance truth (independent surface)
provides:
  - _PatientList row builder split by ClinicianLinkStatusView.canOpenSleepSummary
  - _InviteRow shared card content widget (avatar + code/status + trailing slot)
  - Actionable branch (accepted) = enabled InkWell + chevron at full opacity
  - Inert branch (pending/revoked/expired) = Opacity(0.6), no InkWell, StatusPill reason
  - test/clinician_affordance_test.dart locking the actionable/inert split
affects: [clinician_dashboard, safety, phase-13-motion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Row affordance branches on the model's canOpenSleepSummary flag — tappable chrome (InkWell + chevron) only where a tap actually responds; inert rows drop the tap target entirely rather than nulling onTap"
    - "Opacity(0.6) muting + StatusPill-carries-the-reason for disabled rows, reusing Phase 8 PillTone tones"

key-files:
  created:
    - test/clinician_affordance_test.dart
  modified:
    - lib/screens/clinician_dashboard.dart

key-decisions:
  - "Inert rows omit the InkWell entirely (no onTap:null placeholder) so there is zero ink ripple / hit target — the affordance lie is removed at the widget level, not just visually"
  - "Extracted a shared _InviteRow widget so accepted and inert branches render identical card content with only the trailing slot + wrapper differing — keeps '<code> - <status>' text and helpers untouched"
  - "Kept _linkStatusLabel/_linkStatusTone and the '<inviteCode> - <statusLabel>' primary text verbatim so existing lifecycle assertions in test/widget_test.dart stay green"

patterns-established:
  - "A card that looks tappable must be; inert rows carry no hover/ripple affordance (SAFE-02 general rule)"
  - "Affordance widget test asserts InkWell presence/absence + Opacity<1.0 + bundle-identity stability rather than pixel styling"

requirements-completed: [SAFE-02]

coverage:
  - id: D1
    description: "Exactly one accepted row renders an enabled InkWell + chevron; only that row exposes a tappable affordance"
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "test/clinician_affordance_test.dart#only the accepted invite row exposes a tappable affordance"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pending/revoked/expired rows wrap in Opacity < 1.0 with no InkWell tap target and never change the selected bundle when tapped"
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "test/clinician_affordance_test.dart#only the accepted invite row exposes a tappable affordance"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing invite-lifecycle label assertions stay green (primary text + status pills unchanged)"
    requirement: SAFE-02
    verification:
      - kind: integration
        ref: "test/widget_test.dart#clinician dashboard shows invite lifecycle statuses"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-07-06
status: complete
---

# Phase 9 Plan 02: Affordance truth on clinician invite rows Summary

**The clinician dashboard's invite rows now tell the truth about tappability (SAFE-02): only accepted rows keep the enabled `InkWell` + chevron, while pending/revoked/expired rows drop the ink ripple and tap target entirely, mute to `Opacity(0.6)`, and let the status pill carry the reason — so an inert card can no longer silently absorb a tap.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-07-06T20:00Z
- **Completed:** 2026-07-06T20:06Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Split `_PatientList` row rendering on `ClinicianLinkStatusView.canOpenSleepSummary`: the actionable (accepted) branch keeps the `InkWell(borderRadius: NidRadius.card, onTap: selectPatient)` + `Icons.chevron_right` at full opacity; the inert branch renders the same card **without** any `InkWell`, wrapped in `Opacity(opacity: 0.6)`, trailing a `StatusPill` carrying the pending/revoked/expired reason.
- Extracted a shared `_InviteRow` widget (avatar + name + `'<inviteCode> - <statusLabel>'` + trailing slot) so both branches reuse identical content — removing the previous single-`InkWell`-with-`onTap:null` affordance lie.
- Preserved `_linkStatusLabel` / `_linkStatusTone` and the primary row text verbatim, keeping the existing clinician-lifecycle assertions green.
- Added a focused `test/clinician_affordance_test.dart` proving: exactly one chevron, the inert row is wrapped in `Opacity < 1.0` with no `InkWell`, the accepted row's `InkWell.onTap` is non-null, tapping the inert row leaves `selectedPatientBundle` identity unchanged, and tapping the accepted row re-fetches the bundle.

## Task Commits

Each task was committed atomically:

1. **Task 1: Split invite-row affordance by actionability** - `ee1fb2c` (feat)
2. **Task 2: Widget test proving actionable vs inert affordance** - `771aee0` (test)

## Files Created/Modified
- `lib/screens/clinician_dashboard.dart` - `_PatientList` now branches on `canOpenSleepSummary`; added private `_InviteRow` shared card widget; inert rows use `Opacity(0.6)` + `StatusPill` with no `InkWell`, accepted rows keep `InkWell` + chevron.
- `test/clinician_affordance_test.dart` - New affordance test (chevron count, inert `Opacity`/no-`InkWell`, accepted `InkWell.onTap` non-null, inert-tap-no-op vs accepted-tap-selects via bundle identity).

## Decisions Made
- Inert rows omit the `InkWell` altogether rather than passing `onTap: null` — this removes the ripple/hit-target at the widget level so the disabled state is honest interactively, not just visually.
- Used bundle **identity** (`same` / `isNot(same())`) to prove tap behavior: clinician mode auto-selects the first linked patient, so a fresh `PatientSleepBundle` from `getPatientSleepSummary` on the accepted tap proves the affordance fired, while an unchanged identity proves the inert tap absorbed nothing.
- No copy changes; weights ≤ w700; reused Phase 8 `PillTone`/tokens as required.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SAFE-02 shipped and test-proven; the clinician surface no longer presents inert rows as tappable, with no change to the accepted-link-only sleep privacy contract.
- Ready for 09-03 (journal empty state + per-entry delete), which is independent of this plan.
- Plan-level bar all green: `dart format lib test` (0 changed), `flutter analyze` (No issues found!), `flutter test` (31 passed), `flutter build web` (Built build/web).

## Self-Check: PASSED

- Files verified on disk: `lib/screens/clinician_dashboard.dart`, `test/clinician_affordance_test.dart`, `09-02-SUMMARY.md`.
- Commits verified in git: `ee1fb2c`, `771aee0`.

---
*Phase: 09-safety-and-affordance-integrity*
*Completed: 2026-07-06*
