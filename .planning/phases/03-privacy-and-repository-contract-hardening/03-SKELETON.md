# Phase 3 Skeleton

## Repository

- Remove `getPatientJournalEntries(...)` from `ClinicianRepository`.
- Add requester-checked patient journal reads.
- Use private repository helpers for clinician sleep-summary assembly.
- Add a demo/test helper to mutate link status for privacy tests.

## State

- Patient refresh uses requester-checked patient data methods.
- Clinician refresh continues to clear journal state and fetch sleep summaries only.

## Tests

- Accepted link returns sleep summary.
- Pending, revoked, and missing links throw `PrivacyException`.
- Clinician journal attempts throw for accepted, pending, revoked, and missing link situations.
- Clinician UI/state expose no journal entries.

