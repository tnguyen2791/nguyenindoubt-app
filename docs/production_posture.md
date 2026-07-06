# Production posture

NguyenInDoubt is ready to demonstrate the v1 privacy promise. It is not ready
to run as a live production health or mental-health data service until the
items below are reviewed and implemented.

## Data modes

| Mode | Current status | What happens |
|---|---|---|
| Public web demo | Enabled | Data is stored on the current browser/device through local demo storage. It does not sync across devices and can be reset in the app. |
| Mobile demo | Enabled after local build | Data is stored on the device through local demo storage. Platform sleep permission can be requested on supported iOS/Android devices. |
| Firebase production | Not enabled | Repository and Firestore rules exist as the backend boundary, but live Auth/Firestore mode remains compliance-gated. |
| Telemetry | Not enabled | Analytics, Crashlytics, performance monitoring, session replay, and product telemetry are intentionally absent. |

## Demo data expectations

- Demo profile, journal entries, imported sleep samples, consent state, and
  session state stay on the current device.
- The GitHub Pages demo cannot sync data across browsers, devices, or installs.
- Resetting demo data clears local demo state and restores seeded demo content.
- Local demo storage is not a production retention system and should not be used
  for real clinical records.

## Production retention expectation

Before live Firebase mode is enabled, the project needs a written retention
policy covering:

- account profile records
- journal entries
- sleep samples and daily summaries
- clinician link and consent history
- support/admin audit records
- backup retention and deletion propagation

No production retention period is promised by this repository yet.

## Export expectation

Before live use, patients should be able to export at least:

- profile fields
- journal entries
- imported sleep samples
- daily summaries
- consent and clinician-link history

The current MVP does not implement production export. Demo users can inspect
the app state through the UI only.

## Deletion expectation

Before live use, patients should be able to request deletion of:

- account/profile data
- patient-owned journal entries
- patient-owned health samples and summaries
- clinician links and consent state, subject to any legally required audit log
  retention

The current reset action deletes local demo state only. It is not a production
account deletion workflow.

## Compliance blockers

Live production use remains blocked until these items are resolved:

- privacy policy, terms, and user-facing consent language reviewed for the
  intended deployment context
- HIPAA/BAA and clinical responsibility analysis, if the app is used with a
  covered entity or care team
- Firebase project configuration, Auth role-claim issuance, backup policy, and
  security monitoring reviewed
- trusted backend operation for invite acceptance implemented
- real-device HealthKit and Health Connect permission flows validated
- retention, export, and deletion workflows implemented and tested
- incident response and support escalation process defined
- telemetry decision reviewed before adding any analytics or crash reporting

## Release gate

Every demo deployment should pass:

```sh
flutter analyze
flutter test
npm run test:firestore-rules
flutter build web
```
