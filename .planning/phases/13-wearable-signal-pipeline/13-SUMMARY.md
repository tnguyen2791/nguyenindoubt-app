---
phase: 13-wearable-signal-pipeline
plan: 13
subsystem: health-data
tags: [healthkit, health-connect, readiness, hrv, wearable, scoring, firestore]

# Dependency graph
requires:
  - phase: 11-sleep-insights
    provides: pure sleep_insights scoring seam (StateTone, contributor pattern) and DailySummary
  - phase: 12-ia-restructure
    provides: Today/Trends/[+]/Explore/Profile IA that P14 will use to display readiness
provides:
  - MetricType widened to the full wearable signal set (restingHeartRate, respiratoryRate, temperature, bloodOxygen, activeEnergy)
  - Generic multi-metric HealthDataProvider.fetchSamples across mock + platform + stub
  - PlatformHealthDataProvider reads/permissions widened to HealthKit + Health Connect with graceful per-type guards
  - Deterministic multi-signal MockHealthDataProvider for tests/demo
  - ReadinessSummary + ReadinessContributor models, serialized in both repositories
  - Pure, non-diagnostic multi-factor readiness scoring (readiness.dart) replacing the fake sleepQualityProxy
  - readinessSummaries Firestore collection (patient-owned only)
affects: [P14-today-readiness-display, P15-trends, provider-portal]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MetricType->platform HealthDataType mapping branches per-platform (SDNN iOS / RMSSD Android; body vs skin temp)"
    - "Pure scoring module with injectable baseline + explicit weights, deterministic over inputs (mirrors sleep_insights.dart)"
    - "Per-signal contributor state word derived from its own value so evidence matches the label"
    - "Readiness is patient-owned only; no clinician path (privacy contract preserved)"

key-files:
  created:
    - lib/services/readiness.dart
    - test/services/readiness_test.dart
    - test/repositories/readiness_repository_test.dart
  modified:
    - lib/models/app_models.dart
    - lib/services/health_data_provider.dart
    - lib/services/health_data_provider_platform_io.dart
    - lib/services/health_data_provider_platform_stub.dart
    - lib/repositories/app_repository.dart
    - lib/repositories/firebase_app_repository.dart
    - firestore.rules
    - test/services/health_data_provider_test.dart

key-decisions:
  - "Readiness lives in a new readiness.dart module (option in the plan) rather than overloading sleep_insights.dart — keeps the sleep clinician seam untouched."
  - "Sleep is excluded from the generic fetchSamples path; it keeps its own read/dedupe/summarize pipeline. kReadinessMetricTypes is the generic set."
  - "Permission ready/partial still keys off the sleep types (the readiness floor); extra signals are best-effort and skipped per-type, so a denied HRV never blocks the app."
  - "Missing signals fall back to a neutral 75 subscore so a wearable data gap reads honestly rather than as a failing score."
  - "readinessSummaries is a new Firestore collection, patient-owned only (ownsDoc/willOwnDoc), with NO clinician read rule — clinician stays sleep-summaries-only."

patterns-established:
  - "Graceful degradation: a single unsupported/denied platform type is caught and skipped, never sinking the whole multi-metric read."
  - "Deterministic mock: fixed per-day-offset readings so scoring tests assert exact values."

requirements-completed: []

metrics:
  duration_minutes: 9
  completed: 2026-07-12
  tasks_completed: 4
  files_created: 3
  files_modified: 8

status: complete
---

# Phase 13 Plan 13: Wearable Signal Pipeline + Readiness Summary

Widened the app's HealthKit/Health Connect pipeline from sleep-only to the full Oura-style signal set (HRV, resting HR, respiratory rate, temperature deviation, SpO₂, active energy, steps) and built a real, pure, non-diagnostic multi-factor readiness score that retires the fake `sleepQualityProxy = sleepHours/8*100`. Data + scoring foundation only — no new UI (P14 displays it). Everything is unit-tested through an expanded deterministic mock provider and pure scoring tests; the full suite is green.

## Accomplishments

- **MetricType widened** with `restingHeartRate`, `respiratoryRate`, `temperature`, `bloodOxygen`, `activeEnergy` (existing `steps`/`heartRate`/`hrv` retained). No exhaustive `switch` over `MetricType` existed to break — the codebase used only equality checks and `.values.byName`, both forward-compatible.
- **Generic multi-metric fetch** added to `HealthDataProvider` (`fetchSamples({metrics, range})`) plus a `kReadinessMetricTypes` constant; `fetchAvailableMetrics` widened. `fetchSleepSamples` unchanged (still its own dedupe/summary path).
- **PlatformHealthDataProvider** now maps each `MetricType` to the correct per-platform `HealthDataType` (HRV = SDNN on iOS / RMSSD on Android; temperature = BODY on iOS / SKIN on Android; plus RESTING_HEART_RATE, RESPIRATORY_RATE, BLOOD_OXYGEN, ACTIVE_ENERGY_BURNED, STEPS, HEART_RATE). Permissions request the full set in one prompt; reads guard per-type and skip unsupported/denied types without throwing. Stub updated to the new interface.
- **MockHealthDataProvider** emits deterministic multi-signal data across the 7-day window and reports the full metric set once ready.
- **ReadinessSummary / ReadinessContributor** models added and serialized in both `InMemoryAppRepository` (JSON, schemaVersion 3, per-(patient,date) upsert, persisted round-trip) and `FirebaseAppRepository` (batched upsert to a new `readinessSummaries` collection). New repo methods: `saveReadinessSummaries` / `getReadinessSummariesForPatient`, both patient-owned.
- **Real multi-factor readiness scoring** in `lib/services/readiness.dart`: explicit weights (sleep .30, HRV .20, resting HR .18, respiratory .12, temperature .12, activity .08), each contributor's state word derived from its own value vs an injectable personal baseline, observational/non-diagnostic language, contributor order matching readiness-detail screens 28/05 (Resting HR, HRV balance, Body temp, Respiratory rate, Sleep balance, Prior-day activity).
- **Clinician path unchanged** — `PatientSleepBundle` still carries sleep summaries + samples only; readiness has no clinician read (rule + a test prove it).

## Verification

All gates run against the expanded mock + pure scoring (device HealthKit verification is deferred to P14 display, per the roadmap's honest verification reality):

- `dart format lib test` — clean (reflow only)
- `flutter analyze` — No issues found!
- `flutter test` — all 80 pass (64 baseline + 16 new: 8 readiness scoring, 3 new provider, 7 readiness repository... counted as 16 new asserts blocks)
- `flutter build web` — Built build/web

## Deviations from Plan

None — plan executed as written. The plan offered "evolve sleep_insights.dart OR a new readiness.dart"; I chose the new module (documented as a key decision) to avoid touching the sleep clinician seam.

## Firestore rules — NOT deployed (orchestrator action)

A new collection rule was added to `firestore.rules`:

```
match /readinessSummaries/{summaryId} {
  allow read, update, delete: if ownsDoc();
  allow create: if willOwnDoc();
}
```

Patient-owned only, no clinician read — mirrors `journalEntries`, preserving the sleep-summaries-only clinician contract. **This rule change is committed but NOT deployed.** The orchestrator (or owner) should deploy it (`firebase deploy --only firestore:rules`) before any live Firebase readiness writes. The demo/test path is in-memory and unaffected.

## Known Stubs

None. All new data flows are wired: the mock provider emits real deterministic values, the scoring consumes them, and both repositories persist the result. No placeholder/empty-value stubs were introduced. The `bloodOxygen` metric is fetched and available but not yet consumed by the readiness score (SpO₂ is a P14/P15 display signal, not a P13 scoring factor) — intentional per the plan's contributor set (HRV, resting HR, respiratory, temp, activity, sleep).

## Notes for P14 (display)

- `computeReadiness(inputs, recentSleepHours, baseline)` returns a `ReadinessSummary` ready for the Today ring + contributors; `readinessInputsFromSamples(...)` reduces a day's `fetchSamples` output (+ sleep hours) into `ReadinessInputs`.
- Contributor `fraction` is 0..1 for track fills; `value`/`unit` ride along for the detail baseline strips (screen 28).
- `readinessStateWord(int)` maps 0-100 → protective/balanced/fair/pay attention.

## Self-Check: PASSED

- Files verified on disk: `lib/services/readiness.dart`, `test/services/readiness_test.dart`, `test/repositories/readiness_repository_test.dart`, `13-SUMMARY.md`.
- Commits verified in git: `6e987b0`, `3ea9c5f`, `1a92549`, `64b9714`.
