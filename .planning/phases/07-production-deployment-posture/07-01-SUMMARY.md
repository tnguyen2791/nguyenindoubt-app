# Phase 7 Summary 07-01: Production Deployment Posture

## What Shipped

- Added `docs/production_posture.md` covering demo mode, production mode,
  retention, export, deletion, compliance blockers, and release gates.
- Added `docs/release_notes_v1.md` with privacy-sensitive changes,
  deployment posture, verification commands, and known caveats.
- Updated README with data-mode expectations, posture docs, verification
  commands, and production blockers.
- Tightened in-app public demo copy so users see that data is device-local and
  account-backed production storage is not enabled.
- Added widget coverage for the public demo data-mode disclosure.

## Verification

- `flutter analyze` passed.
- `flutter test` passed with 27 tests.
- `npm run test:firestore-rules` passed with 7 rules tests.
- `flutter build web` passed.

## Caveats

- Production data retention, export, deletion, support, incident response, and
  trusted invite acceptance remain documented blockers, not implemented live
  production workflows.
- The `health` plugin still emits Flutter's Swift Package Manager warning for
  iOS.
