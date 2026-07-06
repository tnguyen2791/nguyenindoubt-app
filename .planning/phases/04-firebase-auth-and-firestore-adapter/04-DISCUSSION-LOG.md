# Phase 4 Discussion Log

## Proposed decisions

- Keep `InMemoryAppRepository` as the default demo adapter until Firebase emulator and production configuration are explicitly selected.
- Add Firebase behind repository interfaces; screens and widgets should not import Firebase packages directly.
- Split repository construction by data mode:
  - local demo mode: existing `InMemoryAppRepository`
  - Firebase emulator/live mode: Firestore-backed adapter
- Use Firebase Auth uid as the canonical user id.
- Treat clinician role as a trusted auth claim or server-owned user field, not a client-selected role.
- Keep `resourceCards` public read, admin-only write.
- Keep journals patient-owned only.
- Keep sleep samples and daily summaries readable by the owner patient or clinicians with accepted links only.
- Tighten `clinicianLinks` writes so accepted links cannot be self-created by arbitrary clinicians.

## Suggested Firestore collections

- `users/{userId}`
  - `displayName`
  - `role`
  - `consentStatus`
  - `clinicCode`
- `clinicianLinks/{clinicianUserId}_{patientUserId}`
  - `clinicianUserId`
  - `patientUserId`
  - `inviteCode`
  - `status`
  - `createdAt`
  - `updatedAt`
- `healthSamples/{sampleId}`
  - `userId`
  - `source`
  - `metricType`
  - `start`
  - `end`
  - `value`
  - `unit`
  - `createdAt`
- `dailySummaries/{summaryId}`
  - `userId`
  - `date`
  - `sleepDurationHours`
  - `sleepQualityProxy`
  - `trendFlag`
- `journalEntries/{entryId}`
  - `userId`
  - `title`
  - `body`
  - `moodTag`
  - `createdAt`
  - `privateByDefault`
- `resourceCards/{resourceId}`
  - `title`
  - `category`
  - `body`
  - `disclaimer`
  - `crisisFlag`
  - `sortOrder`

## Emulator test matrix

- Patient can read and write own user document.
- Patient cannot read another patient journal.
- Patient can create, read, update, and delete own journal entry.
- Clinician cannot read patient journal with accepted, pending, revoked, missing, or malformed links.
- Clinician can read linked patient sleep samples and daily summaries only when link status is `accepted`.
- Clinician is denied sleep samples and daily summaries when link status is `pending`, `revoked`, missing, or malformed.
- Public user can read resource cards.
- Non-admin cannot write resource cards.
- Admin can write resource cards.
- Analytics and Crashlytics packages remain absent from `pubspec.yaml`.

## Open questions

- Should Phase 4 add Firebase packages and emulator tests only, or also add a runtime switch that lets the Flutter app use the Firestore adapter in emulator mode?
- Should clinician role be represented only as an Auth custom claim in rules, or also mirrored in `users/{userId}.role` for UI display?
- Should link creation be fully blocked client-side until Phase 5, or should patients be allowed to create pending links while only trusted server/admin paths can mark links accepted?
- Should Phase 4 seed emulator fixture data through a script, or should tests create all documents directly through the rules test environment?

## Recommended answers

- Add packages and emulator tests in Phase 4, but keep the public demo defaulting to local mode.
- Use Auth custom claims for authorization and `users/{userId}.role` only for display.
- Block client creation of accepted links; allow patient-owned pending link writes only if needed, otherwise defer link writes to Phase 5.
- Let emulator tests create fixture data through the rules test environment to keep tests self-contained.

