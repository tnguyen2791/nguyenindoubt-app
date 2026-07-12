---
phase: 11-insightful-data-displays
plan: 03
subsystem: clinician-dashboard
tags: [flutter, stat-delta, clinician-summary, privacy-contract, widget-tests]
requires: [11-01, 11-02]
provides:
  - Clinician _PatientDetail directional stat-delta summary (Avg sleep + week delta, night-to-night variability, nights-with-data) via clinicianWeekSummary
  - Raw count tiles and _ClinicianMetric widget removed — no bare sample count anywhere on the clinician surface
  - Directional-summary regression test pinning deterministic seeded values and the verbatim consent disclosure
affects: [phase-12-sharing-surface]
tech-stack:
  added: []
  patterns:
    - Clinician-visible stats as a pure function of the consent-gated bundle.summaries (DailySummary-only seam from 11-01)
    - StatDeltaRow column with NidSpace.m gaps as the desktop stat-delta idiom
key-files:
  created: []
  modified:
    - lib/screens/clinician_dashboard.dart
    - test/clinician_affordance_test.dart
decisions:
  - "Third StatDeltaRow's delta slot carries 'sleep summaries only' — positive scope framing in the delta position per the plan"
  - "Test additionally pins the deterministic '6.7h' and '±0.5h' values (acceptance-criteria values beyond the enumerated finds) for stronger determinism anchoring"
metrics:
  duration: ~5 minutes
  completed: 2026-07-12
  tasks: 2/2
  tests: 55 passing (was 54; +1 directional-summary test)
status: complete
---

# Phase 11 Plan 03: Directional Clinician Summary Summary

The clinician patient-detail card now shows the design's stat-delta idiom — Avg sleep with a delta vs the prior week, a night-to-night variability descriptor, and nights-with-data — computed on device exclusively from the consent-gated sleep summaries, replacing the raw 7-day-avg/short-nights/samples tiles, with the whole phase verification bar green.

## Task Commits

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Directional stat-delta summary in the clinician patient detail | 11356e2 |
| 2 | Pin the directional summary in clinician_affordance_test + full phase verification bar | 86cf764 |

## What Was Built

### Rebuilt _PatientDetail stat area (lib/screens/clinician_dashboard.dart)
- Deleted the inline `average`/`shortNights` computations, the `Wrap` of three `_ClinicianMetric` tiles (including the raw `samples` count reading `bundle!.samples.length`), and the now-unused `_ClinicianMetric` class.
- `final week = clinicianWeekSummary(summaries);` (imports `../services/sleep_insights.dart` + `data_displays.dart`) feeds a Column of three `StatDeltaRow`s separated by `NidSpace.m`:
  1. `Avg sleep` / `last 7 nights` — `week.avgLabel` + `week.deltaLabel` (flagged at ≤ −30m).
  2. `Night-to-night` / `variability` — `week.variabilityValue` + `week.variabilityWord` (flagged at wide variability).
  3. `Nights with data` / `past week` — `week.nightsLabel` + the positive scope framing `'sleep summaries only'` in the delta slot.
- Everything else byte-for-byte: `BrandHeader` ('Accepted invites only. Sleep summaries, never journals.'), `_PatientList` SAFE-02 affordance logic, the 'journal private' StatusPill, honest `SleepTrendBars`, and the verbatim visibility disclosure.
- Privacy surface shrank: the detail no longer reads `bundle!.samples` at all — every rendered stat is a pure function of `bundle!.summaries`.

### Regression pin (test/clinician_affordance_test.dart)
- New `testWidgets` 'clinician summary is directional, never a raw sample count' using the file's existing 1000x1200 pump pattern with `showSplash: false`; clinician mode auto-selects the seeded 7-night patient (6.2/6.5/7.0/7.2/5.9/6.8/7.6h).
- Asserts deterministically: `SAMPLES` findsNothing; `Avg sleep`, `6.7h`, `no prior week yet`, `±0.5h`, `steady nights`, `7 of 7 nights`, `sleep summaries only` each findsOneWidget; verbatim 'Visible: sleep samples, daily summaries, trend flags.' re-asserted after `scrollUntilVisible`.
- The pre-existing SAFE-02 affordance test is untouched and passes as-is; the widget_test.dart clinician privacy + lifecycle tests pass unchanged.

## Deviations from Plan

None - plan executed exactly as written. (The extra `6.7h`/`±0.5h` test assertions come straight from Task 1's acceptance criteria — added coverage, no behavior change.)

## Verification (plan-level bar — phase close-out)

- `dart format lib test` — 0 changed
- `flutter analyze` — No issues found
- `flutter test` — 55/55 passing (suite entered the plan at 54)
- `flutter build web` — succeeds
- Task greps: no `'samples'` literal, no `_ClinicianMetric`, `clinicianWeekSummary` present, verbatim disclosure exact `grep -F` match.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. T-11-03-ID/EoP mitigations landed as planned: the summary derives only from the accepted-link, consent-gated `bundle.summaries`; the clinician detail's last direct `bundle.samples` read was removed.

## Self-Check: PASSED

- lib/screens/clinician_dashboard.dart — FOUND (rebuilt)
- test/clinician_affordance_test.dart — FOUND (new test)
- Commits 11356e2, 86cf764 — FOUND on design/v1.1-experience
