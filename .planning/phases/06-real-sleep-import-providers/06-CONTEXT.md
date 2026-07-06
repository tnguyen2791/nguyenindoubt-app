# Phase 6 CONTEXT: Real Sleep Import Providers

## Starting Point

- Phase 5 completed invite validation, consent revocation, link status, and
  consent history.
- `HealthDataProvider` existed with a mock provider used by the patient import
  flow.
- Sleep persistence replaced all prior patient sleep samples on each import.
- The hosted demo still needs to build for web.

## Implementation Decisions

- Use `health: ^13.3.1`, the current Flutter wrapper for Apple HealthKit and
  Google Health Connect.
- Keep the mobile provider behind conditional imports so web builds use an
  unavailable provider instead of importing the mobile-only plugin.
- Keep the old `importMockSleep` state method name for test and UI stability,
  but make its behavior provider-driven.
- Represent permission state as `HealthPermissionStatus` with unavailable,
  not requested, partial, denied, revoked, and ready.
- Infer `revoked` when a previously requested/ready provider no longer reports
  any sleep permissions.
- Request only read access for sleep data types.
- Aggregate same-day sleep intervals into one `DailySummary`, since real
  providers can return stage intervals rather than one nightly sample.
- Merge existing and incoming sleep samples by deterministic sample identity
  before writing summaries.

## Platform Notes

- iOS needs HealthKit usage strings and a HealthKit entitlement.
- Android needs `android.permission.health.READ_SLEEP`, Health Connect package
  visibility, permission rationale routing, and `FlutterFragmentActivity`.
- No background, write, activity-recognition, location, or broad health
  permissions are included in this phase.
