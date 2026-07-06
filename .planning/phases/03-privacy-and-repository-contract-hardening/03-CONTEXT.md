# Phase 3 Context: Privacy and Repository Contract Hardening

## Objective

Make clinician-facing flows incapable of reading patient journals while preserving consented sleep-summary access.

## Current implementation baseline

- `ClinicianRepository` still exposes `getPatientJournalEntries(...)`, even though the implementation throws.
- `AppRepository.getJournalEntries(String userId)` and `getDailySummaries(String userId)` accept arbitrary user ids.
- `NguyenInDoubtState` clears `_journalEntries` for clinician sessions, and `ClinicianDashboard` receives only `PatientSleepBundle`, but the repository interface is still too permissive.
- Existing tests cover accepted clinician sleep and one journal denial path, but not pending, revoked, and missing links.

## Requirements covered

- `PRIV-01`: Repository contracts make journal reads unavailable to clinician-facing code paths.
- `PRIV-02`: Link-status tests cover accepted, pending, revoked, and missing sleep-summary access.
- `PRIV-03`: Clinician journal attempts are denied regardless of link status.
- `PRIV-04`: Clinician screens/state avoid receiving patient journal data.
- `PRIV-05`: Copy explains that clinicians see sleep summaries only after consent.

## Constraints

- No live Firebase or production backend changes.
- No Phase 5 invite lifecycle UI work.
- Keep demo behavior working across patient and clinician flows.

