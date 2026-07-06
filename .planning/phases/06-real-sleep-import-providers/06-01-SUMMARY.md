# Phase 6 Summary 06-01: Real Sleep Import Providers

## What Shipped

- Added `health: ^13.3.1`.
- Added a conditional `PlatformHealthDataProvider` for iOS/Android and an
  unavailable provider for web/unsupported targets.
- Added explicit health permission states: unavailable, not requested, partial,
  denied, revoked, and ready.
- Kept import UI flow stable while making it provider-driven.
- Requested sleep-only read permissions for HealthKit/Health Connect.
- Added iOS HealthKit usage descriptions and entitlement.
- Added Android Health Connect `READ_SLEEP`, package visibility, permission
  usage activity, rationale intent, and `FlutterFragmentActivity`.
- Normalized platform sleep intervals into `HealthSample` values in hours.
- Aggregated same-day sleep samples into one `DailySummary`.
- Changed local and Firebase sleep imports to merge/deduplicate instead of
  replacing all prior patient sleep data.
- Added tests for permission states, sleep-only metrics, summary aggregation,
  sample dedupe, incremental imports, and UI status copy.

## Notes

- Web demo builds keep working because the mobile health plugin is behind a
  conditional import.
- Flutter warns that the `health` plugin does not yet support Swift Package
  Manager for iOS. This is a toolchain warning, not an analyzer failure.
