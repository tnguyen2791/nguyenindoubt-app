---
phase: 14-today-readiness-detail
plan: 14
subsystem: today-dashboard
tags: [readiness, wearable, today, detail-screens, drill-down, non-diagnostic]

# Dependency graph
requires:
  - phase: 13-wearable-signal-pipeline
    provides: ReadinessSummary/ReadinessContributor models, readiness.dart scoring, widened multi-signal providers + kReadinessMetricTypes, readiness persistence
  - phase: 12-ia-restructure
    provides: Today/Trends/[+]/Explore/Profile IA + the pushed-route-in-AnimatedBuilder pattern the detail routes reuse
provides:
  - app_state computes/loads/exposes the real current ReadinessSummary (patient-only)
  - Today hero renders the real multi-signal readiness ring + contributors (retired sleep proxy gone from the hero)
  - Readiness detail screen (28) reachable via a gentle-fade route
  - Sleep detail screen (21) reachable via a gentle-fade route
  - nidReadinessTone(fraction) — maps a subscore to a StateTone so bar color matches the model's own value
affects: [P15-trends, P14b-activity-overnight-hr]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Readiness computed in app_state on import (fetchSamples -> readinessInputsFromSamples -> computeReadiness -> persist); pure scoring stays in readiness.dart"
    - "Detail routes are PageRouteBuilder fade-throughs wrapped in AnimatedBuilder(animation: state) so a pushed route rebuilds on state (P12 journal-route pattern)"
    - "Contributor bar tone derived from the contributor's own fraction via nidReadinessTone, so evidence matches the label"

key-files:
  created:
    - lib/screens/detail_screens.dart
    - test/detail_screens_test.dart
  modified:
    - lib/state/app_state.dart
    - lib/screens/patient_dashboard.dart
    - lib/screens/data_displays.dart
    - test/widget_test.dart
    - test/data_displays_test.dart

key-decisions:
  - "The Today hero shows the first three readiness contributors (matching 18's compact three-row readout); the full contributor list lives on the detail screen (28)."
  - "Readiness is computed at import time (not lazily in the widget) and persisted, so the dashboard and the detail screen read one consistent, patient-owned summary; refresh() reloads the most recent day."
  - "When no wearable read has happened yet (readiness == null) the hero falls back to the Phase-11 sleep-score hero — an honest degrade, never a fabricated readiness."
  - "Readiness stays patient-only: refresh() only loads it on the patient branch and clears it for clinician/signed-out/reset. A clinician-surface test proves state.readiness is null there."
  - "StatDeltaRow's value/delta column was made Flexible + right-aligned (Rule 1) so a long observational delta wraps instead of overflowing at phone width."

patterns-established:
  - "Detail drill-downs open via a shared fadeDetailRoute() so every push eases in (project motion rule)."

requirements-completed: []

metrics:
  duration_minutes: 20
  completed: 2026-07-12
  tasks_completed: 4
  files_created: 2
  files_modified: 5

status: complete
---

# Phase 14 Plan 14: Today (Real Readiness) + Detail Drill-downs Summary

Made the wearable core visible: wired the app state to P13's real readiness pipeline, replaced the Today hero's retired sleep proxy with the genuine multi-signal `ReadinessSummary` + contributors (matching mocks 18/28), and built the Readiness-detail (28) and Sleep-detail (21) drill-downs against their exact mocks, reachable via gentle-fade routes. The clinician surface stays sleep-summaries-only; the suite is green (85 tests) and the web build succeeds.

## Accomplishments

- **State wiring.** `importMockSleep` now also reads the full readiness signal set (`fetchSamples(metrics: kReadinessMetricTypes)`), reduces the most-recent day into `ReadinessInputs` (`readinessInputsFromSamples`), scores it against the recent-sleep window (`computeReadiness`), and persists the result. `refresh()` loads the most recent persisted readiness for patients and clears it for clinician/signed-out. New `state.readiness` getter (patient-only). Demo/auth seam untouched — the wearable read is best-effort, so a partial/denied signal yields a neutral contributor via the scoring's null fallback, never a failed import.
- **Today readiness hero (rewired).** `patient_dashboard`'s hero is now `_ReadinessHeroCard`: the real 120px `ScoreRing` with the readiness score + state word, the top-3 multi-signal contributors via `ContributorBar`, the `READINESS` kicker, and the verbatim `not a diagnosis` headnote. It falls back to the sleep-score hero only when `readiness == null`. Matches 18's compact readout.
- **Readiness detail (28).** New `ReadinessDetailScreen`: centered 120px ring, observational caption (`Balanced · one contributor to watch`), the full contributor list with per-signal `InfoTip`s (HRV, body temp, respiratory, sleep balance, prior-day activity — each ending on reassurance, no exclamation marks) and raw values, plus the `not a diagnosis` headnote and an observational closing caption.
- **Sleep detail (21).** New `SleepDetailScreen`: sleep-score ring + `protective/short · Xh asleep` caption, last-night + 7-night stat/delta rows, the honest 7-night trend (reused `SleepTrendBars`), and the sleep-score contributors. Sleep-only, real data.
- **Routing.** Both details open through a shared `fadeDetailRoute()` (240ms fade-through) wrapped in `AnimatedBuilder(animation: state)` so a re-import updates them live — the P12 journal-route pattern. Tap targets: the hero opens Readiness; the `last night` mini-card opens Sleep (now chevron-affordanced).
- **Helper.** `nidReadinessTone(fraction)` maps a 0–1 subscore to a `StateTone` using the same bands the scoring uses, so a contributor bar's color always matches its own value.

## Verification

All gates run against the deterministic multi-signal `MockHealthDataProvider` (real-device HealthKit HRV/temperature/SpO₂ is the owner's spot-check per the roadmap's honest verification reality — noted below):

- `dart format lib test` — clean (0 unexpected changes)
- `flutter analyze` — No issues found!
- `flutter test` — all 85 pass (80 baseline + 5 new: 4 detail-screen widget tests, 1 `nidReadinessTone` band test)
- `flutter build web` — Built build/web

## Deviations from Plan

**1. [Rule 1 - Bug] StatDeltaRow overflowed at phone width.** Found while building the Sleep detail: `StatDeltaRow`'s right value/delta column had no width bound, so a long observational delta (the insight line) triggered a RenderFlex overflow (205px) at 390px width. Fixed by making that column `Flexible` + right-aligned so long deltas wrap. Benefits all callers. Files: `lib/screens/data_displays.dart`. Commit: `742ed70`.

## Device verification (owner spot-check)

Real HRV / body-temperature / SpO₂ samples cannot be fully exercised on a plain iOS simulator. The readiness pipeline, hero, and both detail screens are proven here against the deterministic mock. The owner should spot-check on the device (TryCare) with real Health data that the Today ring + contributors and the Readiness detail render real overnight signals.

## Follow-ons (out of scope this phase)

- **Activity detail (98)** and **overnight HR (08)** — noted in mock 18's two-up (Activity mini-card) and the Sleep-detail overnight-HR card; deferred to P14b/P15. The Today two-up currently keeps the existing sleep mini-cards rather than adding an Activity ring.
- **Trends (all signals)** — P15.
- Readiness is deliberately NOT exposed to the clinician (sleep-only contract); a clinician-sharing ruling is a separate owner decision, not assumed here.

## Known Stubs

None. The hero and both detail screens render real computed/persisted data (readiness from the scoring, sleep from the summaries). The `readiness == null` hero fallback is an intentional honest degrade, not a placeholder.

## Self-Check: PASSED

- Files verified on disk: `lib/screens/detail_screens.dart`, `test/detail_screens_test.dart`, `lib/state/app_state.dart`, `lib/screens/patient_dashboard.dart`, `.planning/phases/14-today-readiness-detail/14-SUMMARY.md`.
- Commits verified in git: `c484c9c`, `ab87271`, `742ed70`.
