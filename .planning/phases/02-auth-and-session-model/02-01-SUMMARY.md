---
phase: 02-auth-and-session-model
plan: 01
subsystem: auth-session
tags: [flutter, shared_preferences, onboarding, session, privacy]

requires:
  - Phase 1 demo promise hardening
provides:
  - Explicit signed-out, onboarding, patient, and clinician session states
  - Shared preferences-backed local session restore
  - Minimum patient profile onboarding
  - Clinician demo override entry without in-app arbitrary role switching
  - Reset-to-signed-out behavior
affects: [auth, privacy, consent, firebase, production-posture]

tech-stack:
  added: []
  patterns:
    - App session state is modeled in `AppSession` and owned by `NguyenInDoubtState`.
    - Demo session persistence lives alongside demo repository data in the shared preferences JSON blob.
    - Signed-in app chrome offers sign out rather than patient/clinician role switching.

key-files:
  created: []
  modified:
    - lib/models/app_models.dart
    - lib/repositories/app_repository.dart
    - lib/state/app_state.dart
    - lib/screens/app_shell.dart
    - test/repositories/app_repository_test.dart
    - test/widget_test.dart

key-decisions:
  - "Fresh local demo sessions start signed out unless a prior local session exists."
  - "Patient onboarding captures display name only for Phase 2."
  - "Clinician access is an explicit `Clinician demo override` entry from the signed-out surface."
  - "Reset clears local demo data and returns to signed out."

patterns-established:
  - "Session restore tests recreate repository and state with the same `SharedPreferences` instance."
  - "Clinician session tests assert the sleep-only dashboard and absence of journal content after restore."

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, AUTH-04]

coverage:
  - id: A1
    description: "App exposes explicit signed-out, patient onboarding, patient, and clinician session states."
    requirement: AUTH-01
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#patient can sign up and import mock sleep data"
        status: pass
    human_judgment: false
  - id: A2
    description: "Patient onboarding captures the display name while preserving local-demo copy."
    requirement: AUTH-02
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#patient can sign up and import mock sleep data"
        status: pass
      - kind: unit
        ref: "test/repositories/app_repository_test.dart#local session and patient profile persist across repository instances"
        status: pass
    human_judgment: false
  - id: A3
    description: "Clinician access uses an explicit demo override rather than a signed-in role switch."
    requirement: AUTH-03
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#clinician dashboard keeps sleep-only privacy copy"
        status: pass
      - kind: automated_ui
        ref: "test/widget_test.dart#local clinician demo override session restores sleep-only view"
        status: pass
    human_judgment: false
  - id: A4
    description: "Local session refresh restores patient or clinician state without exposing the wrong data boundary."
    requirement: AUTH-04
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#local patient session restores after app recreation"
        status: pass
      - kind: automated_ui
        ref: "test/widget_test.dart#local clinician demo override session restores sleep-only view"
        status: pass
    human_judgment: false
  - id: A5
    description: "Reset clears persisted session and returns the app to signed out."
    requirement: AUTH-04
    verification:
      - kind: unit
        ref: "test/repositories/app_repository_test.dart#reset clears persisted session"
        status: pass
      - kind: automated_ui
        ref: "test/widget_test.dart#patient can reset local demo data"
        status: pass
    human_judgment: false
  - id: A6
    description: "Full Phase 2 verification passed through analyze, test, and web builds."
    requirement: AUTH-01
    verification:
      - kind: other
        ref: "flutter analyze"
        status: pass
      - kind: other
        ref: "flutter test"
        status: pass
      - kind: other
        ref: "flutter build web"
        status: pass
      - kind: other
        ref: "flutter build web --base-href /nguyenindoubt-app/"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-07-06
status: complete
---

# Phase 02: Auth and Session Model Summary

**Explicit demo session states, minimum patient onboarding, clinician demo override, and local session restore for the Flutter MVP**

## Performance

- **Duration:** 30 min
- **Started:** 2026-07-06T13:31:00Z
- **Completed:** 2026-07-06T13:41:13Z
- **Tasks:** 5
- **Files modified:** 6 app/test files plus planning artifacts

## Accomplishments

- Added `SessionStage` and `AppSession` models.
- Persisted local demo session state alongside existing shared preferences demo data.
- Refactored `NguyenInDoubtState` to own signed-out, onboarding, patient, and clinician states.
- Replaced the post-entry patient/clinician switch with sign out plus a signed-out `Clinician demo override` entry.
- Added a minimum patient onboarding form that captures display name.
- Updated reset behavior so clearing demo data returns to signed out.
- Added repository and widget tests for session/profile persistence, patient restore, clinician restore, reset session clearing, and sleep-only clinician boundaries.

## Task Commits

No commits were made by request.

## Files Created/Modified

- `lib/models/app_models.dart` - Adds `SessionStage` and `AppSession`.
- `lib/repositories/app_repository.dart` - Persists session state and patient display name updates.
- `lib/state/app_state.dart` - Owns session transitions and role-scoped refresh behavior.
- `lib/screens/app_shell.dart` - Adds signed-out/onboarding surfaces and replaces role switch with sign out.
- `test/repositories/app_repository_test.dart` - Adds session/profile persistence and reset-session coverage.
- `test/widget_test.dart` - Updates flows for onboarding and adds patient/clinician session restore tests.

## Decisions Made

- Kept Phase 2 auth local and demo-only; Firebase Auth remains deferred.
- Captured only display name in onboarding to satisfy the minimum profile requirement without inventing production account fields.
- Made clinician entry explicitly a demo override from signed out instead of retaining a fake signed-in role toggle.
- Reset now returns to signed out because session state is part of local demo data.

## Deviations from Plan

None.

## Issues Encountered

- `flutter analyze` initially failed because a non-existent theme color token was used in new copy. It was corrected to `NidColors.moss`, and analysis then passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `flutter analyze` - passed
- `flutter test` - passed, 16 tests
- `flutter build web` - passed
- `flutter build web --base-href /nguyenindoubt-app/` - passed

## Next Phase Readiness

Phase 3 can now harden repository privacy contracts against explicit patient and clinician sessions. The signed-in app no longer depends on an arbitrary role switch, and session restore behavior has regression coverage.

---
*Phase: 02-auth-and-session-model*
*Completed: 2026-07-06*

