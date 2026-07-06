# Phase 4 Skeleton

## Flutter

- Add Firebase packages needed for an account-backed adapter.
- Keep `main.dart` on local demo mode by default.
- Add a Firestore-backed repository adapter that implements existing repository interfaces.
- Keep Firebase imports out of screens and widgets.

## Firestore Rules

- Require trusted clinician auth claims for clinician sleep access.
- Require accepted deterministic clinician links for clinician sleep access.
- Keep journals patient-owned only.
- Make clinician link writes trusted/admin-only until Phase 5 lifecycle work.
- Keep resource cards public read and admin create/update.

## Emulator Tests

- Add repo-local Firebase CLI and rules test dependencies.
- Run Firestore emulator on `127.0.0.1:8085` because local port 8080 is occupied on this machine.
- Cover users, clinician links, health samples, daily summaries, journal entries, and resource cards.

