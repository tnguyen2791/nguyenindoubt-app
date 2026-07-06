# Firebase contract

This MVP uses an in-memory repository for the local demo. The Firebase files are
stubs for the production boundary:

- Auth owns identity and role claims.
- Firestore stores `users`, `clinicianLinks`, `healthSamples`,
  `dailySummaries`, `journalEntries`, and `resourceCards`.
- Analytics and Crashlytics are intentionally absent until compliance review.
- Journal entries are patient-only in v1. Clinician read access is denied in
  code and in `firestore.rules`.

`clinicianLinks` should use deterministic ids:

```text
{clinicianUserId}_{patientUserId}
```

Accepted links are required before a clinician can read patient sleep samples or
daily summaries.
