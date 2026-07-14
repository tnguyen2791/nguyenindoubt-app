---
phase: 10-brand-arrival-and-guided-onboarding
plan: 03
subsystem: ui
tags: [flutter, dashboard, first-run, empty-state, permission-priming]

# Dependency graph
requires:
  - "10-01 (showSplash test seam — app-pumping tests pass showSplash: false)"
  - "10-02 (welcome vocabulary 'Get started' / \"I'm a clinician\" used by the shared onboarding helpers)"
provides:
  - "Modular PatientFirstRun widget (lib/screens/patient_first_run.dart) — guided hero + sleep-only priming + single 'Import sleep' primary"
  - "patient_dashboard empty-branch gate: summaries.isEmpty -> PatientFirstRun; else original metric tiles + trend card"
  - "First-run copy constants: \"Start with last night's sleep\", 'Import sleep', 'never your journal' priming line"
affects:
  - "Phase 11 (dashboard hierarchy + insights — extends the modular first-run layer instead of fighting inline empty-state code)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Empty-state gate via collection-if in the dashboard ListView children (first-run widget vs data widgets)"
    - "Permission priming as plain hero copy shown before any OS prompt, mirroring the trend card's disable + spinner logic on the primary action"

key-files:
  created:
    - lib/screens/patient_first_run.dart
  modified:
    - lib/screens/patient_dashboard.dart
    - test/widget_test.dart

key-decisions:
  - "Bedtime icon (not BrandMark) heads the hero — BrandHeader directly above already carries the brand mark; repeating it would double the lockup on one screen"
  - "First-run card centers its column (EmptyState idiom) inside a SectionCard rather than reusing EmptyState itself, because EmptyState cannot host the primary button"
  - "Priming copy reuses the trend card's vocabulary ('Import requests sleep-only access') so post-import permission messaging reads as the same voice"

# Metrics
duration: 6min
completed: 2026-07-12
status: complete

# Verification
verification:
  - "Task 1 grep gate: 'never your journal' + 'Import sleep' present in patient_first_run.dart"
  - "dart format lib test — 0 changed"
  - "flutter analyze — No issues found"
  - "flutter test — 39/39 pass"
  - "flutter build web — succeeds"
---

# Phase 10 Plan 03: Guided First-Run on the Empty Dashboard Summary

**One-liner:** The empty patient dashboard now shows one calm guided hero — "Start with last night's sleep" with sleep-only priming ('never your journal') and a single primary 'Import sleep' action — instead of three '--' tiles and an empty trend chart, built as a modular PatientFirstRun widget Phase 11 can extend.

## What Was Built

### Task 1 — PatientFirstRun widget + empty-dashboard wiring (`9b960d9`)
- `lib/screens/patient_first_run.dart` — `PatientFirstRun extends StatelessWidget` taking `NguyenInDoubtState state`. One `SectionCard` hero (EmptyState idiom: centered column, canopy bedtime icon, `NidSpace` tokens only, weights capped by the theme ladder at w700):
  - Headline `Start with last night's sleep` (titleLarge).
  - Priming body: "Import requests sleep-only access before anything is read — we only ever look at your sleep, never your journal." — states the sleep-only promise and primes the permission ask before any OS prompt (ONB-04).
  - Single primary `FilledButton.icon` labelled `Import sleep` → `state.importMockSleep`, disabled when `state.isBusy` or `healthPermissionStatus == unavailable`, with the same 16px spinner-while-busy icon swap as the trend card's Import button.
  - Doc comment marks it as the Phase 10 first-run layer that Phase 11 extends/replaces.
- `patient_dashboard.dart` build(): collection-if on `state.summaries.isEmpty` — empty renders `PatientFirstRun(state: state)` in place of BOTH the three `_MetricTile` Wrap and the Sleep-trend `SectionCard`; non-empty renders the original tiles + trend unchanged. `BrandHeader` ('Morning check-in') and the `_ConsentLifecycleCard` remain in both branches, untouched.
- No score ring, metric hierarchy, or insight lines added (Phase 11 scope respected).

### Task 2 — Coupled empty-state test updates (`1efb28e`)
- First test ('patient can sign up and import mock sleep data'): empty-state assertions swapped from the removed trend-card strings ('No sleep samples yet' / 'sleep permission needed' / 'Import requests sleep-only access.') to the first-run hero — `find.text("Start with last night's sleep")` and `find.textContaining('never your journal')` each findsOneWidget. Import tap now targets `find.widgetWithText(FilledButton, 'Import sleep')` (ensureVisible + tap kept). Post-import still proves `sleep access ready` findsOneWidget and the hero is gone (`findsNothing`).
- Reset test: trailing `findsNothing` assertion updated from 'No sleep samples yet' to "Start with last night's sleep".
- Demo-notice, consent, safety, and clinician assertions untouched.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Model Verification

- **T-10-03-ID (mitigate):** The priming copy states the truth — sleep-only access, "never your journal" — and does not overstate access; it appears before any OS prompt. Verified by the Task 1 grep gate and the widget test asserting the copy renders in the empty state.
- **T-10-03-TMP (accept):** 'Import sleep' calls the existing `importMockSleep` → repository path (already sleep-only guarded); no new data path or capability introduced.

## Verification Evidence

| Gate | Result |
|------|--------|
| Task 1 grep gate | `COPY_OK` ('never your journal' + 'Import sleep' present) |
| `dart format lib test` | 0 files changed |
| `flutter analyze` | No issues found |
| `flutter test` | 39/39 pass (suite unchanged in count; assertions migrated) |
| `flutter build web` | Succeeds |

**Human-check (advisory, pending, `human_verify_mode: end-of-phase`):** sign up as a patient and confirm the empty dashboard shows the single calm 'Import sleep' hero with the sleep-only promise (no '--' tiles), and that after import the normal metrics + trend chart appear.

## Known Stubs

None — the first-run hero is wired to the real `importMockSleep` state path; no placeholder data or dead-end UI introduced.

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| 9b960d9 | feat | PatientFirstRun widget + empty-dashboard gate (tiles/trend hidden until data) |
| 1efb28e | test | Empty-state + post-import assertions migrated to the guided first-run |

## Notes for Next Plans

- Phase 11 extends `PatientFirstRun` (or replaces the empty branch) — the gate is the single `state.summaries.isEmpty` collection-if in `patient_dashboard.dart` build().
- The strings 'No sleep samples yet' (SleepTrendBars empty state) and the notRequested permission label/message still exist in code but no longer render on the patient empty dashboard; clinician surfaces still use SleepTrendBars.

## Self-Check: PASSED

- lib/screens/patient_first_run.dart — FOUND
- .planning/phases/10-brand-arrival-and-guided-onboarding/10-03-SUMMARY.md — FOUND
- Commits 9b960d9, 1efb28e — FOUND in git log
