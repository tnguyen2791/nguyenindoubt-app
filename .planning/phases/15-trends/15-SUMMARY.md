---
phase: 15-trends
plan: 15
subsystem: trends-tab
tags: [trends, wearable, sleep, readiness, activity, heatmap, trend-line, non-diagnostic]

# Dependency graph
requires:
  - phase: 13-wearable-signal-pipeline
    provides: ReadinessSummary/ReadinessContributor models, readiness.dart scoring, kReadinessMetricTypes multi-signal fetch, readiness persistence
  - phase: 14-today-readiness-detail
    provides: state.readiness + readiness-at-import wiring, Sleep detail (21) + Readiness detail (28) drill-downs, fadeDetailRoute, ScoreRing/ContributorBar/SleepTrendBars kit
  - phase: 12-ia-restructure
    provides: Today/Trends/[+]/Explore/Profile IA + the Trends tab slot in app_shell
provides:
  - MockHealthDataProvider widened to ~90 deterministic days (closed-form drift) for sleep + the full readiness signal set
  - app_state scores + persists a ReadinessSummary per day across the quarter and exposes readinessHistory (patient-only)
  - Pure services/trends.dart — TrendSignal/TrendRange, per-signal series, weekly averages, Monday-first consistency calendar
  - In-token data_displays widgets — TrendLine (06/20), WeeklyAverageBars (20), ConsistencyHeatmap (13) + heat-ramp theme tokens
  - Built-out Trends tab — Sleep/Readiness/Activity × Week/Month/Quarter with trend + weekly averages + heatmap, wired to the Sleep/Readiness detail routes
affects: [P16-explore, P18-provider-portal]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure trends module mirrors sleep_insights.dart/readiness.dart: imports only models, deterministic over inputs, returns plain data (TrendData)"
    - "All three Trends signals derive from persisted patient-owned data — sleep from DailySummary, readiness + activity from the ReadinessSummary series (activity = the prior-day activity contributor kcal); no new data surface"
    - "Range beyond available history returns the trailing available window calmly — never fabricates or errors"
    - "Deterministic mock via closed-form triangle waves over the day offset (no clock, no randomness), so the whole quarter round-trips identically in tests"
    - "CustomPaint TrendLine scales to the series' own min..max with padding (honest axis, no fake 0-baseline normalization)"

key-files:
  created:
    - lib/services/trends.dart
    - test/services/trends_test.dart
    - test/trends_screen_test.dart
  modified:
    - lib/services/health_data_provider.dart
    - lib/state/app_state.dart
    - lib/theme/app_theme.dart
    - lib/screens/data_displays.dart
    - lib/screens/tab_shells.dart
    - lib/screens/app_shell.dart
    - test/widget_test.dart
    - test/services/health_data_provider_test.dart

key-decisions:
  - "The three Trends signals all derive from already-persisted, patient-owned data (no new persistence surface): sleep from DailySummary, readiness from the readiness series, activity from each readiness summary's activeEnergy contributor value. Keeps the sleep-only clinician contract intact and adds zero new Firestore collections."
  - "app_state now scores a ReadinessSummary for EVERY day in the imported quarter (was one day in P14) and persists the series, so Trends readiness/activity have a real series; the most-recent day still drives the Today hero."
  - "MockHealthDataProvider widened from 7 fixed-array days to ~90 closed-form deterministic days (triangle-wave drift) so Week/Month/Quarter all have real data in demo + tests; the last-night values shifted (HRV 50, RHR 51), so two provider tests were updated to the new deterministic latest values."
  - "A calm line-trend (TrendLine) was added in data_displays.dart in the 06/20 grammar rather than reusing SleepTrendBars, because a 30/90-day series reads better as a line than as bars; weekly averages still use bars (WeeklyAverageBars) per mock 20."
  - "Sleep consistency 'on target' = a night reaching level 3-4 (>=7.25h); readiness/activity map their score (or an activity-proximity-to-~450kcal) onto the same l1-l4 ramp so one heatmap grammar covers all three signals."

patterns-established:
  - "Trends payload is fully precomputed in the pure module (TrendData) so the widget layer stays declarative and every number is unit-testable off-widget."

requirements-completed: []

coverage:
  - deliverable: "Sleep/Readiness/Activity segments x Week/Month/Quarter render with the deterministic mock"
    verification:
      - kind: test
        ref: "test/trends_screen_test.dart#Trends renders each segment and range with the deterministic mock"
        status: pass
    human_judgment: false
  - deliverable: "Trend line + weekly averages + consistency heatmap render, built to mocks 20/13/06"
    verification:
      - kind: test
        ref: "test/trends_screen_test.dart#Trends renders each segment and range with the deterministic mock"
        status: pass
    human_judgment: true
    rationale: "Pixel-level fidelity to the mocks (exact grammar, spacing, ramp colors) is a visual judgment; tests assert the widgets render and don't overflow, but the owner spot-checks the look."
  - deliverable: "MockHealthDataProvider extended to ~90 deterministic days; ranges beyond history degrade calmly"
    verification:
      - kind: test
        ref: "test/services/trends_test.dart#a range beyond available history degrades to the available window"
        status: pass
      - kind: test
        ref: "test/services/health_data_provider_test.dart#fetchSamples emits deterministic multi-signal readings"
        status: pass
    human_judgment: false
  - deliverable: "Readiness + activity trend series derive from persisted patient data; empty ranges degrade calmly"
    verification:
      - kind: test
        ref: "test/services/trends_test.dart#readiness and activity series derive from the readiness history"
        status: pass
      - kind: test
        ref: "test/trends_screen_test.dart#Trends degrades calmly before any import (no fake data)"
        status: pass
    human_judgment: false
  - deliverable: "Sleep trend card opens the Sleep detail (21); clinician surface unchanged (sleep-only)"
    verification:
      - kind: test
        ref: "test/trends_screen_test.dart#the Sleep trend card opens the Sleep detail (21)"
        status: pass
      - kind: test
        ref: "test/detail_screens_test.dart#clinician surface never exposes readiness (sleep-only)"
        status: pass
    human_judgment: false
  - deliverable: "Consistency, weekly averages, and determinism of the pure trends module"
    verification:
      - kind: test
        ref: "test/services/trends_test.dart#consistency counts on-target days and flags short nights"
        status: pass
      - kind: test
        ref: "test/services/trends_test.dart#the trend is deterministic — same inputs, same output"
        status: pass
    human_judgment: false

metrics:
  duration_minutes: 47
  completed: 2026-07-12
  tasks_completed: 2
  files_created: 3
  files_modified: 8

status: complete
---

# Phase 15 Plan 15: Trends (All Signals) Summary

Built out the Trends tab from a "coming soon" shell (screens 20/24) into the design's trends surface: a Sleep · Readiness · Activity segmented control and a Week · Month · Quarter range toggle over the real signals, each showing a calm score/metric trend line (06/20 grammar), weekly averages (20), and a Monday-first consistency heatmap (13). All three signals derive from already-persisted, patient-owned data — no new data surface, clinician stays sleep-only. The mock provider was widened to a deterministic quarter so every range has a real series in demo + tests; the whole suite is green (95) and the web build succeeds.

## Accomplishments

- **Quarter-wide deterministic mock.** `MockHealthDataProvider` now emits ~90 days of sleep + the full readiness signal set via closed-form triangle-wave drift over the day offset (no clock, no randomness), so Week/Month/Quarter all have real data and every run is reproducible. `importMockSleep` reads the quarter window (`days: 91`).
- **Per-day readiness series.** `app_state._computeAndSaveReadiness` now scores a `ReadinessSummary` for every day in the imported window (grouping the day's readings, using a trailing 7-night sleep window per day) and persists the whole series; the most-recent day still drives the Today hero. New patient-only `state.readinessHistory` getter (cleared for clinician/signed-out/reset) feeds the Trends readiness + activity signals.
- **Pure trends module.** `lib/services/trends.dart` — `TrendSignal`/`TrendRange`, `computeTrendData(...)` returning a fully-precomputed `TrendData`: the trailing-window series, average/best/avg-sleep stats, an observational headnote, up to four weekly averages, and a Monday-first consistency calendar with on-target counts. Deterministic over its inputs; a range beyond history returns the available window calmly, and no data yields a calm empty payload (never a throw).
- **In-token display widgets.** `data_displays.dart` gains `TrendLine` (CustomPaint: 3 faint gridlines, moss area fill + polyline + end dot, honest min..max axis, date ticks — 06/20 grammar), `WeeklyAverageBars` (20's `.bars`, sleep-hours ramp for sleep / state ramp for score+activity), and `ConsistencyHeatmap` (13's 7-col l1-l4 + ember flag + transparent gaps, weekday header, less→more legend). New `NidStateColors` heat-ramp tokens (`heatL1`-`heatL4`, `heatFlag`) match the mock hexes exactly.
- **Built-out Trends tab.** `TrendsScreen` is now stateful: the mint-track canopy-active segmented control (`.seg`), outlined canopy-fill range pills (`.range`), a trend card with a three-stat readout + `TrendLine`, a weekly-averages card, and a consistency card. The sleep trend card opens the Sleep detail (21); readiness opens the Readiness detail (28) via the existing gentle-fade routes. Wired into the Trends tab slot in `app_shell`.
- **Honest empty states.** Before any import, each signal shows its own calm, non-diagnostic empty copy — never fabricated data.
- **Clinician unchanged.** Readiness stays patient-only; the sleep-only clinician contract and all privacy/safety/verbatim assertions are intact.

## Verification

All gates run against the deterministic multi-signal `MockHealthDataProvider` (real-device HealthKit HRV/temperature/SpO₂ is the owner's spot-check per the roadmap's honest verification reality):

- `dart format lib test` — clean (reflow only)
- `flutter analyze` — No issues found!
- `flutter test` — all 95 pass (85 baseline + 8 new pure trends_test + 3 new trends_screen widget tests; 2 provider tests updated for the widened mock)
- `flutter build web` — Built build/web

## Deviations from Plan

**1. [Rule 1 - Layout] RenderFlex overflows in the new Trends cards at 390px.** Found while running the Trends widget test at phone width. Three honest layout fixes, no clipping:
- `WeeklyAverageBars` reserved explicit label chrome (`height + 44`) so a full-height bar never overflows its column (was 3.7–4.9px bottom overflow).
- The `ConsistencyHeatmap` legend and the `_RangeToggle` now use `Wrap` so the swatch/label groups and the three range pills never overflow the narrowest phone width (was 9.8px right overflow).
- The trend-stats row uses `Expanded` stat columns instead of `spaceBetween` with intrinsic-width children.
Files: `lib/screens/data_displays.dart`, `lib/screens/tab_shells.dart`. Commit: `343a042`.

**2. [Scope #4 test update] Provider tests updated for the widened mock.** Widening `MockHealthDataProvider` from 7 fixed-array days to a ~90-day deterministic series (an explicit plan-scope call) shifted the last-night values, so two `health_data_provider_test` cases were updated: the latest-HRV assertion (52 → 50, the new deterministic last-night value) and the summarize-short-night test now uses a full-quarter range (short nights sit earlier in the widened series). These are expected consequences of the intentional data change, not behavior regressions. Commit: `343a042`.

## Device verification (owner spot-check)

Real HRV / body-temperature / SpO₂ / activity samples cannot be fully exercised on a plain iOS simulator. The Trends tab, all three signals, and the three range windows are proven here against the deterministic mock. The owner should spot-check on the device (TryCare) with real Health data that the Trends line, weekly averages, and heatmap render real overnight/activity signals, and eyeball fidelity against mocks 20/24/13/06.

## Known Stubs

None. The Trends tab renders real computed data from the persisted series for every signal and range. The pre-import empty state and the "off balance"/"low readiness" heatmap flag labels are intentional honest states, not placeholders. Activity has no dedicated detail-route drill-down yet (its trend card is non-tappable) — noted as a follow-on (P14b/later), not a stub.

## Self-Check: PASSED

- Files verified on disk: `lib/services/trends.dart`, `test/services/trends_test.dart`, `test/trends_screen_test.dart`, `lib/screens/tab_shells.dart`, `.planning/phases/15-trends/15-SUMMARY.md`.
- Commits verified in git: `a4323a1`, `343a042`, `05257b2`.
