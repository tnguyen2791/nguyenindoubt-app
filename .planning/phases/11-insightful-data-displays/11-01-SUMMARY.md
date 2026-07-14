---
phase: 11-insightful-data-displays
plan: 01
subsystem: data-displays
tags: [flutter, sleep-score, trend-bars, design-system, pure-dart]
requires: []
provides:
  - NidStateColors state palette + sleep-hours color ramp in the theme
  - Pure on-device sleep_insights computation module (score, insight line, consistency caption, week delta, clinician week summary)
  - Honest SleepTrendBars (fixed 0-9.5h axis, 8h hairline, hours ramp, explicit legend) live on both dashboards
  - Reusable data-display widget kit (ScoreRing, ContributorBar, InfoTip, StatDeltaRow, nidToneColor)
affects: [11-02, 11-03]
tech-stack:
  added: []
  patterns:
    - Pure Dart insight module importing only app models (privacy seam by type signature)
    - Theme-sourced state colors — no hex literals in widget code
    - CustomPaint rings/bars, no chart package
key-files:
  created:
    - lib/services/sleep_insights.dart
    - lib/screens/data_displays.dart
    - test/services/sleep_insights_test.dart
    - test/data_displays_test.dart
  modified:
    - lib/theme/app_theme.dart
    - lib/screens/common_widgets.dart
decisions:
  - "Population sd computed with an in-module Newton sqrt so sleep_insights.dart imports ONLY app_models.dart (not even dart:math)"
  - "Value labels ride each bar's top via Positioned offsets inside a fixed-height per-column Stack, keeping heightFactor an honest fraction of the full 168px bar region"
  - "Ramp legend moved to the bottom of the trend card (design's explicit-scale row position)"
metrics:
  duration: ~10 minutes
  completed: 2026-07-12
  tasks: 3/3
  tests: 53 passing (was 39; +9 unit, +5 widget)
status: complete
---

# Phase 11 Plan 01: Honest Trend Bars + Insight Computation Foundation Summary

Multi-factor on-device sleep score (duration/consistency/trend) as a pure DailySummary-only Dart module, honest fixed-axis ramp-colored trend bars with an 8h hairline live on both dashboards, and the Oura-style ScoreRing/ContributorBar/InfoTip/StatDeltaRow widget kit for plans 02/03.

## Task Commits

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | State-color tokens + pure sleep_insights module + unit tests | 01ad434 |
| 2 | Honest SleepTrendBars — fixed axis, 8h hairline, ramp, legend | 202ca52 |
| 3 | ScoreRing/ContributorBar/InfoTip/StatDeltaRow kit + widget tests | 3f86143 |

## What Was Built

### Theme (lib/theme/app_theme.dart)
- `NidColors.faint` (#7A887F) for axis/day labels.
- `NidStateColors` — optimal #4F7A3C, good #6E8544, fair #A08B48, attention #C4633E, plus `rampStops`/`rampColors` and `forSleepHours(double)` (piecewise `Color.lerp` over t = ((hours-5)/3).clamp(0,1)). All state color lives in the theme; widgets never hardcode hex.

### Pure computation module (lib/services/sleep_insights.dart)
- Imports ONLY `../models/app_models.dart` — no Flutter, no dart:io, no dart:math, no `DateTime.now()`. Journal types cannot enter by signature (T-11-01-ID mitigated).
- `computeSleepScore` — 3 contributors (Duration vs 7-9h band, Consistency via population sd, Week trend earlier-vs-later half with <4-night honest neutral), weighted 0.5/0.3/0.2, overall word protective/balanced/fair/pay-attention, caption per copy-bank pattern; calm no-data fallback.
- `insightLine` (exact single-night fallback string), `consistencyCaption`, `weekDeltaLabel`, `ClinicianWeekSummary`/`clinicianWeekSummary` (deltaFlagged at <= -30m, variability words, 'N of 7 nights').
- 9 deterministic unit tests, fixed dates, no clock reads.

### Honest SleepTrendBars (lib/screens/common_widgets.dart)
- `static const axisMaxHours = 9.5`; heightFactor = hours/9.5 clamped only at 1.0 — window-max fold and 0.25 floor clamp deleted; a 2h night renders tiny.
- 8h-target hairline (canopy at 0.07 alpha) with faint '8h' label at 8/9.5 of the 168px bar region; bars in per-column Stacks so the hairline aligns with the bar area only.
- Bar color = `NidStateColors.forSleepHours`; radii 7 top / 4 bottom; value labels w700 canopy riding bar tops; single-letter day labels via new `dayLetter` helper; base hairline kept; ramp legend '5h short — gradient — 8h+ optimal'.
- Signature and empty-state branch ('No sleep samples yet') unchanged — both dashboards picked up the rewrite with zero call-site edits.

### Widget kit (lib/screens/data_displays.dart)
- `nidToneColor(StateTone)`, `ScoreRing` (mint track + state arc, TweenAnimationBuilder 600ms easeOutCubic, 34px/w700/-0.68 number over 11px/w600 word), `ContributorBar` (name + optional InfoTip + state word + 7px filled track), `InfoTip` (15px mint circle, italic 'i', AlertDialog with 'Got it'), `StatDeltaRow` (17px/700 value, 12px/600 moss delta, ember when flagged).
- 5 widget tests including the honest-height regression anchor: 2h bar asserts heightFactor closeTo(2.0/9.5, 0.001).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's Task 2 grep gate self-conflicts**
- **Found during:** Task 2 verification
- **Issue:** `! grep -q "maxHours"` matches the plan's own mandated constant name `axisMaxHours` (substring), making the gate unsatisfiable as written.
- **Fix:** Ran the gate as word-boundary grep (`! grep -qw "maxHours"`), which verifies the old window-max variable is gone — the gate's clear intent. `grep -q "axisMaxHours"` passes as specified.
- **Files modified:** none (verification interpretation only)
- **Commit:** 202ca52

**2. [Rule 3 - Blocking] Analyzer lint in ContributorBar**
- **Found during:** Task 3 verification
- **Issue:** `use_null_aware_elements` info-level lint on `if (infoTip != null) infoTip!`.
- **Fix:** Replaced with the null-aware element `?infoTip`.
- **Files modified:** lib/screens/data_displays.dart
- **Commit:** 3f86143

## Verification (plan-level bar)

- `dart format lib test` — 0 changed
- `flutter analyze` — No issues found
- `flutter test` — 53/53 passing (suite was 39 entering the phase)
- `flutter build web` — succeeds
- Privacy greps: no `JournalEntry`, no Flutter import, no `DateTime.now` in sleep_insights.dart; no `Color(0x` hex literals in data_displays.dart; pubspec.yaml untouched.

## Known Stubs

None. Note: `data_displays.dart` widgets are not yet composed into any screen — plans 11-02 (patient dashboard) and 11-03 (clinician summary) wire them by design; SleepTrendBars changes are live on both dashboards now.

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes; the module's import surface shrinks the disclosure risk as planned.

## Self-Check: PASSED

- lib/services/sleep_insights.dart — FOUND
- lib/screens/data_displays.dart — FOUND
- test/services/sleep_insights_test.dart — FOUND
- test/data_displays_test.dart — FOUND
- Commits 01ad434, 202ca52, 3f86143 — FOUND on design/v1.1-experience
