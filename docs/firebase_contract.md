# Firebase contract

This MVP uses an in-memory repository for the local demo. The Firebase files are
stubs for the production boundary:

- Auth owns identity and trusted role claims. Firestore authorization uses
  `request.auth.token.role == 'clinician'`, `request.auth.token.clinician`,
  or `request.auth.token.admin`; user document `role` is display/profile data,
  not the source of authorization.
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
daily summaries. Accepted links must be written by trusted server/admin context;
the client cannot self-create an accepted clinician relationship.

Phase 4 keeps the public demo on the local repository by default. Firebase
adapters and rules are verified with the Firestore emulator before any live data
mode is enabled.
