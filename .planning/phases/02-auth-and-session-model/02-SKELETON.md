# Phase 2 Skeleton

## Model

- Add `SessionStage` enum.
- Add immutable `AppSession` with stage and optional user id.

## Repository

- Persist optional session JSON alongside users, links, samples, and entries.
- Restore missing session as signed out.
- Add methods to save session and update the demo patient profile.

## State

- Own session stage in `NguyenInDoubtState`.
- Add methods for patient onboarding start, patient onboarding completion, clinician demo override, and sign out.
- Refresh role-scoped data based on session stage.

## UI

- Move signed-out/onboarding decisions from local widget state into app state.
- Add patient onboarding form.
- Replace app bar role switch with session label and sign out action.

## Tests

- Repository restores persisted session and demo patient display name.
- Widget flow starts signed out, completes patient onboarding, persists across state recreation, and signs out.
- Clinician demo override restores as clinician and keeps journals hidden.

