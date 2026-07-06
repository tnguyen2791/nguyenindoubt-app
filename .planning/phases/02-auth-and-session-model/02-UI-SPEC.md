# Phase 2 UI Spec

## Signed-out surface

- Primary action: `Patient sign up`
- Secondary action: `Clinician demo override`
- Copy states that Firebase/auth are not live and demo state is stored on this device.

## Patient onboarding

- Single required field: display name.
- Primary action: `Continue`
- Secondary action: back to the signed-out surface.
- Copy keeps the demo-local data boundary visible.

## Signed-in app chrome

- Remove the patient/clinician role switch from the app bar.
- Show the current session role as compact copy.
- Provide a `Sign out` action.
- Keep the Phase 1 demo notice and reset control visible in patient and clinician sessions.

## Reset behavior

- Reset clears local demo data and returns to signed out.
- The next patient session must pass through onboarding again.

