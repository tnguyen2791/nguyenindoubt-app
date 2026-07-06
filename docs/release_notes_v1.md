# Release notes: v1 MVP readiness

Date: 2026-07-06

## Summary

This release candidate hardens the NguyenInDoubt local demo into a reviewed MVP
shape. The app demonstrates patient onboarding, private journaling, sleep import
and summary review, invite-based clinician sleep-summary sharing, consent
revocation, and clinician sleep-only views.

## Privacy-sensitive changes

- Journal entries remain patient-only in repository contracts and Firestore
  rules.
- Clinician access is limited to accepted-link sleep samples, daily summaries,
  and trend flags.
- Pending, revoked, expired, missing, and malformed clinician links do not grant
  sleep access.
- Invite validation previews a pending invite but does not grant access until
  patient acceptance.
- Consent acceptance and revocation write metadata-only history events.
- Real sleep providers sit behind `HealthDataProvider` and request sleep-only
  read access.
- Imported sleep samples deduplicate and sync incrementally rather than wiping
  prior patient sleep data.
- Analytics, Crashlytics, performance monitoring, session replay, and telemetry
  remain absent.

## Deployment posture

- Public web demo mode is device-local and does not sync across browsers or
  devices.
- Firebase Auth/Firestore production mode is not enabled by default.
- Firestore rules and adapter code define the intended production boundary.
- Production invite acceptance still requires a trusted backend operation.
- Production retention, export, deletion, support, and incident workflows remain
  blockers before live use.

## Verification required for this release

```sh
flutter analyze
flutter test
npm run test:firestore-rules
flutter build web
```

## Known caveats

- Real HealthKit and Health Connect flows need manual validation on physical
  devices before production use.
- Flutter currently warns that the `health` plugin does not support Swift
  Package Manager for iOS.
- Node `20.13.1` can run the Firestore rules tests after dependencies are
  installed, but Firebase/Vitest tooling warns about newer Node engine ranges.
- npm reports moderate audit findings in dev tooling.
