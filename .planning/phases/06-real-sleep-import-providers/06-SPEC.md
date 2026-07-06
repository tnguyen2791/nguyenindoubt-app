# Phase 6 SPEC: Real Sleep Import Providers

## Intent

Patients can import real platform sleep data while preserving the existing
sleep-summary privacy boundary. HealthKit and Health Connect must remain behind
`HealthDataProvider`, request sleep-only access, expose clear permission states,
and persist imports incrementally instead of replacing prior production data.

## Scope

- Add a mobile platform provider backed by the Flutter `health` package.
- Keep web and unsupported desktop targets explicit as unavailable.
- Show patient-facing permission states for unavailable, not requested,
  partial, denied, revoked, and ready.
- Normalize platform sleep intervals into `HealthSample` and `DailySummary`.
- Deduplicate sleep samples by patient, source, metric, start, and end.
- Upsert/merge imported sleep data in local and Firebase repositories.
- Add iOS HealthKit and Android Health Connect sleep-only configuration.

## Out of Scope

- Writing HealthKit or Health Connect data.
- Background health sync.
- Health Connect historical-data permission beyond the default window.
- Non-sleep metrics.
- Clinician visibility changes beyond existing consented sleep summaries.

## Acceptance Criteria

- HLTH-01: HealthKit and Health Connect providers sit behind
  `HealthDataProvider`.
- HLTH-02: Patient can see all required health permission states.
- HLTH-03: Platform permission requests are sleep-only.
- HLTH-04: Imported samples normalize into existing sleep models.
- HLTH-05: Production imports deduplicate and incrementally sync.
