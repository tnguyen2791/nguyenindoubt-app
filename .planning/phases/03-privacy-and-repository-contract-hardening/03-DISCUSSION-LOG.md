# Phase 3 Discussion Log

## Decisions

- Remove journal reads from the clinician repository interface instead of relying on a throwing clinician journal method.
- Replace arbitrary patient journal reads with a requester-checked patient repository method.
- Keep clinician sleep access centralized through `getPatientSleepSummary(...)`.
- Add a demo/test link-status mutation helper so accepted, pending, revoked, and missing sleep access can be covered without building the full Phase 5 consent UI.
- Keep clinician copy focused on accepted invites, sleep summaries, and hidden journals.

## Non-goals

- No revocation UI.
- No invite validation UI.
- No Firestore rules or emulator work.

## Risks

- Changing repository method signatures touches app state, tests, and reset/persistence coverage.
- Test-only link status mutation must not be mistaken for the production consent lifecycle.

