# Phase 2 Discussion Log

## Decisions

- The app starts signed out when no local session exists.
- Patient entry is a two-step flow: choose patient sign up, then complete a minimal onboarding form with display name.
- The patient onboarding display name updates the seeded demo patient locally.
- Clinician entry is labeled as a clinician demo override and is only available from the signed-out surface.
- After sign-in, the app bar offers sign out rather than a patient/clinician toggle.
- Local session state is persisted with the same demo storage blob so refresh restores patient or clinician state on that device.
- Reset demo data clears local data and returns to the signed-out state.

## Non-goals

- No Firebase Auth integration in this phase.
- No production clinician verification beyond making the demo override explicit.
- No invite lifecycle changes beyond preserving existing accepted-link behavior.

## Risks

- Persisting session inside the existing demo JSON requires backward-compatible restore for users with Phase 1 local storage.
- Widget tests that assumed one-tap patient entry must be updated to complete onboarding.
- Removing the role switch changes demo ergonomics, so the signed-out surface must keep clinician demo access obvious.

