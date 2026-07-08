# NguyenInDoubt App

Flutter MVP for a public/patient mental-health companion with an invite-linked
clinician dashboard.

## Data mode

The public demo is device-local. Demo profile data, journal entries, imported
sleep samples, consent state, and session state stay in the current browser or
app install. They do not sync across devices and can be cleared with **Reset
demo data**.

Firebase Auth/Firestore code, Firestore rules, and platform health-provider
code define the production boundary, but live production storage is not enabled
by default. See:

- [Production posture](docs/production_posture.md)
- [Firebase contract](docs/firebase_contract.md)
- [v1 release notes](docs/release_notes_v1.md)
- [Compliance & legal documents](docs/legal/README.md) (draft privacy policy,
  terms, HIPAA/BAA analysis, incident response, support & crisis escalation)
- [Publish the demo](docs/deploy_demo.md) (device-local web deploy runbook)
- [Production go-live plan](.planning/GO-LIVE.md) (critical path from demo to a
  live, account-backed service)

## Demo flows

- Patient sign up -> mock HealthKit-style sleep import -> private journal ->
  curated resources and safety page.
- Patient accepts invite code `NID-1138` -> clinician can see sleep summaries.
- Clinician demo -> linked-patient dashboard with sleep trends and no journal
  visibility.

## Privacy posture

The local MVP uses seeded in-memory data. Firebase is represented by project
stubs and Firestore rules only. No analytics, Crashlytics, or live telemetry are
enabled by default.

## Run and verify

```sh
flutter pub get
flutter analyze
flutter test
npm run test:firestore-rules
flutter build web
flutter run -d chrome --web-port 5173
```

## Production blockers

Before live use, the project still needs reviewed retention, export, deletion,
incident response, support escalation, trusted invite acceptance, Firebase role
claim issuance, and real-device HealthKit/Health Connect validation.
