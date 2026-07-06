# Phase 7 SPEC: Production Deployment Posture

## Intent

Make the demo and release posture explicit before anyone treats the app as a
production health or mental-health data system. The public demo must identify
its local data mode, documentation must describe retention/export/deletion
expectations, and release notes must call out privacy-sensitive changes plus
remaining compliance blockers.

## Scope

- Update public-facing app copy so demo-local data mode is visible in the app.
- Update README with data mode, verification, and deployment posture.
- Add documentation for data expectations, retention, export, deletion, and
  production blockers.
- Add release notes for the v1 MVP privacy-sensitive changes.
- Capture verification evidence for analyze, tests, rules tests, and web build.

## Out of Scope

- Enabling live Firebase mode.
- Implementing account deletion/export workflows.
- Adding analytics, Crashlytics, telemetry, monitoring, or session replay.
- Production privacy policy/legal terms.
- Production app-store release.

## Acceptance Criteria

- PROD-01: The public demo clearly distinguishes device-local demo data from
  account-backed production data.
- PROD-02: Retention, export, and deletion expectations are documented.
- PROD-03: Deployment verification includes `flutter analyze`, `flutter test`,
  and `flutter build web`.
- PROD-04: Release notes identify privacy-sensitive changes and remaining
  compliance blockers.
