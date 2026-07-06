# Firebase contract

This MVP uses an in-memory repository for the local demo. The Firebase files are
stubs for the production boundary:

- Auth owns identity and trusted role claims. Firestore authorization uses
  `request.auth.token.role == 'clinician'`, `request.auth.token.clinician`,
  or `request.auth.token.admin`; user document `role` is display/profile data,
  not the source of authorization.
- Firestore stores `users`, `clinicianLinks`, `consentEvents`,
  `healthSamples`, `dailySummaries`, `journalEntries`, and `resourceCards`.
- Analytics and Crashlytics are intentionally absent until compliance review.
- Journal entries are patient-only in v1. Clinician read access is denied in
  code and in `firestore.rules`.

`clinicianLinks` should use deterministic ids:

```text
{clinicianUserId}_{patientUserId}
```

Accepted links are required before a clinician can read patient sleep samples or
daily summaries. Accepted links must be written by trusted server/admin context;
the client cannot self-create or self-accept a clinician relationship.

Phase 5 keeps that production boundary fail-closed:

- invite validation can preview a pending invite but does not grant access
- patient clients may revoke an already accepted link
- clinician clients cannot create, accept, or reactivate links
- `consentEvents` are append-only metadata records; they must not contain
  journal text, draft/reflection content, raw sleep samples, or raw summaries
- production invite acceptance still needs a trusted backend operation before
  live Firebase mode is enabled

Phase 6 keeps real health imports inside the same boundary:

- HealthKit and Health Connect access sits behind `HealthDataProvider`
- the MVP requests read-only sleep access, not broad health, background, or
  write permissions
- platform sleep intervals normalize into `HealthSample` and `DailySummary`
- imported sleep samples are deduplicated by patient, source, metric, start,
  and end before upsert
- production sync merges new samples into prior patient sleep data instead of
  deleting and replacing all existing samples

Phase 4 keeps the public demo on the local repository by default. Firebase
adapters and rules are verified with the Firestore emulator before any live data
mode is enabled.
