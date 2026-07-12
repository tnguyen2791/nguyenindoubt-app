---
phase: 11-insightful-data-displays
plan: 02
subsystem: patient-dashboard
tags: [flutter, dashboard-hierarchy, sleep-score, insight-line, widget-tests]
requires: [11-01]
provides:
  - Rebuilt with-data patient dashboard in the design's Oura-grade hierarchy (greeting -> score hero -> mini-cards -> honest trend -> consent last)
  - ScoreRing hero live on the dashboard with 3 contributors and the verbatim 'not a diagnosis' headnote
  - The one observational insight line (greeting sub-line via insightLine)
  - Consistency micro-insight caption on the trend card (INS-05 patient side)
  - Phone-width hierarchy regression test pinning the new composition
affects: [11-03, phase-12-sharing-surface]
tech-stack:
  added: []
  patterns:
    - With-data branch as a `_withDataSections` method spread so the literal `state.summaries.isEmpty` collection-if gate stays byte-identical
    - InfoTip copy as private static consts on the consuming widget
key-files:
  created: []
  modified:
    - lib/screens/patient_dashboard.dart
    - test/widget_test.dart
decisions:
  - "Hero headnote 'not a diagnosis' rendered as an Expanded right-aligned Text (not Spacer-pushed) so the header Row degrades by wrapping instead of overflowing at narrow widths"
  - "New phone-width test passes the dashboard ListView explicitly to scrollUntilVisible — the consent card's invite TextField mounts within the cache extent and adds a second Scrollable"
  - "Week-average mini-card computes the mean of the most recent up-to-7 summaries inline; weekDeltaLabel supplies its caption"
metrics:
  duration: ~7 minutes
  completed: 2026-07-12
  tasks: 2/2
  tests: 54 passing (was 53; +1 phone-width hierarchy test)
status: complete
---

# Phase 11 Plan 02: With-Data Dashboard Hierarchy Rebuild Summary

The patient dashboard's with-data state now reads greeting/status block (one on-device insight line) -> multi-factor ScoreRing hero with contributors and the verbatim 'not a diagnosis' headnote -> two calm mini-cards (LAST NIGHT / 7-NIGHT AVERAGE) -> honest 'Sleep trend · 7 nights' card with a consistency micro-insight -> consent card demoted to last, with the quality-proxy and connection-state tiles gone and every coupled test migrated additively.

## Task Commits

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Rebuild the with-data dashboard hierarchy (greeting -> hero -> mini-cards -> trend -> consent) | 7bb4670 |
| 2 | Migrate coupled widget_test assertions + phone-width hierarchy regression test | 1322c35 |

## What Was Built

### Rebuilt with-data composition (lib/screens/patient_dashboard.dart)
- `BrandHeader` keeps title/subtitle but drops the trailing sharing StatusPill in both branches — no sharing affordance above the consent card (INS-01).
- `_GreetingBlock` (plain centered Column, not a card): 'Good {daypart}, {firstName}' (bodySmall w600), a 9px moss dot + 30px/700 canopy status headline mapped from `score.tone` ('A protective night' / 'A steady night' / 'A lighter night' / 'A short night' — describes the night, never the person), and the ONE insight sub-line via `insightLine` (INS-04), maxWidth 300.
- `_ScoreHeroCard`: 'SLEEP SCORE' label (11px/700, +1.0 tracking, canopy) + Sleep-score InfoTip + right-aligned verbatim 'not a diagnosis' headnote (11px/600 faint, exactly once in the file); `ScoreRing` (120) beside three `ContributorBar`s (Consistency row carries its InfoTip), stacking ring-above-contributors below 340px inner width; `score.caption` beneath at 14px/600 in the tone color (INS-02).
- Two-up `_MiniMetricCard` row (IntrinsicHeight for equal card heights): LAST NIGHT (`hoursLabel(latest)`, `latest.trendFlag`) and 7-NIGHT AVERAGE (mean of the most recent up-to-7 nights, `weekDeltaLabel`). `_MetricTile` deleted; 'quality proxy' and 'clinician link' strings absent case-insensitively.
- Trend card retitled 'Sleep trend · 7 nights' with all Import/permission-pill logic unchanged, plus a `consistencyCaption` micro-insight under `SleepTrendBars` (INS-05 patient side).
- Consent `SectionCard(_ConsentLifecycleCard)` remains last; `_ConsentLifecycleCard`, all consent copy, and `patient_first_run.dart` are byte-for-byte unchanged; the `state.summaries.isEmpty` gate is intact (with-data content moved into a `_withDataSections` spread).

### Test migration (test/widget_test.dart — additions only, no privacy assertion touched)
- First test extended post-import: 'not a diagnosis', 'SLEEP SCORE', `ScoreRing`, and the greeting present; 'QUALITY PROXY' / 'CLINICIAN LINK' find nothing.
- New 'dashboard hierarchy...at phone width' test (390x844, showSplash: false): no exception, hero present, exactly one 'vs your recent average' insight line (mock durations put last night +46m over baseline deterministically), honest-trend scale texts '5h short' / '8h+ optimal' / '8h' present after scrolling, consent card last but reachable via scrollUntilVisible.
- Reset-dialog copy, 'Visible: sleep samples, daily summaries, trend flags.', 'Accepted invites only. Sleep summaries, never journals.', demo-mode notice, and the patient consent disclosure all untouched and still asserted.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Hero header Row overflowed 11px at phone width**
- **Found during:** Task 2 (the new phone-width test's takeException assertion)
- **Issue:** 'SLEEP SCORE' + InfoTip + Spacer + 'not a diagnosis' as fixed-width Row children overflowed the 390px-wide card under the test font.
- **Fix:** Headnote became an `Expanded` right-aligned Text — same visual placement, wraps instead of overflowing at narrow widths.
- **Files modified:** lib/screens/patient_dashboard.dart
- **Commit:** 1322c35

**2. [Rule 1 - Bug] scrollUntilVisible ambiguous Scrollable in the new test**
- **Found during:** Task 2
- **Issue:** Post-import at phone width, the consent card's invite TextField mounts within the ListView cache extent, so the default `find.byType(Scrollable)` matched two scrollables ('Bad state: Too many elements').
- **Fix:** Passed `scrollable: find.byType(Scrollable).first` (the dashboard ListView) explicitly — assertions unchanged, per the plan's fix-by-scrolling-not-loosening rule.
- **Files modified:** test/widget_test.dart
- **Commit:** 1322c35

Note: a doc comment initially quoted the headnote string, making 'not a diagnosis' appear twice in the file; reworded before the Task 1 commit so the string appears exactly once (the rendered headnote), as the acceptance criteria require.

## Verification (plan-level bar)

- `dart format lib test` — 0 changed
- `flutter analyze` — No issues found
- `flutter test` — 54/54 passing (suite was 53 entering the plan)
- `flutter build web` — succeeds
- Task greps: no 'quality proxy' / 'clinician link' (case-insensitive); 'not a diagnosis', 'SLEEP SCORE', 'insightLine' present; `git diff` of patient_first_run.dart empty; widget_test diff is additions only.

## Known Stubs

None. All new displays are wired to live on-device data (`computeSleepScore`, `insightLine`, `consistencyCaption`, `weekDeltaLabel` over `state.summaries`). `DailySummary.sleepQualityProxy` remains in the model/persistence layer by design (display-only rebuild; data plumbing out of scope).

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. The dashboard remains a patient-only surface; all new strings derive from sleep summaries via sleep_insights.dart, and the consent disclosure copy is byte-for-byte preserved and test-asserted (T-11-02-ID, T-11-02-RP mitigated).

## Self-Check: PASSED

- lib/screens/patient_dashboard.dart — FOUND (rebuilt)
- test/widget_test.dart — FOUND (extended)
- Commits 7bb4670, 1322c35 — FOUND on design/v1.1-experience
