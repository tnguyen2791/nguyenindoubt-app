# Phase 2 Context: Auth and Session Model

## Objective

Replace the fake production role switch with an explicit demo session model that has signed-out, onboarding, patient, and clinician states.

## Current implementation baseline

- `AppShell` owns a local `_started` boolean, so refresh behavior is not represented in app state.
- `NguyenInDoubtState` initializes directly as `repository.patientDemo` and fetches patient data immediately.
- The app bar exposes a patient/clinician role switch after entry, which is useful for demos but reads like arbitrary client-side production auth.
- `InMemoryAppRepository` persists journals, imported sleep, and consent in a single shared preferences JSON blob.

## Requirements covered

- `AUTH-01`: signed-out, onboarding, patient, and clinician states are first-class.
- `AUTH-02`: patient onboarding captures minimum profile state while preserving demo-local copy.
- `AUTH-03`: clinician entry is explicitly a demo override, not an arbitrary in-app role switch.
- `AUTH-04`: local session state restores without crossing patient and clinician data boundaries.

## Constraints

- Firebase remains stubbed.
- No live auth, analytics, crash reporting, or telemetry are introduced.
- No commits or pushes unless explicitly requested.
- Existing Phase 1 demo reset, safety fallback, responsive rendering, and privacy tests must keep passing or be updated to match the new session contract.

