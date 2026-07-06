# NguyenInDoubt App

Flutter MVP for a public/patient mental-health companion with an invite-linked
clinician dashboard.

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

## Run

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port 5173
```
