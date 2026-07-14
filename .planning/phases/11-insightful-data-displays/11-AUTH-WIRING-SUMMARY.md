---
phase: 11
plan: AUTH-WIRING
subsystem: auth
tags: [auth, firebase, firestore, google-sign-in, phone-auth, auth-gate]
requires:
  - AuthService abstraction + brand LoginScreen (11-AUTH-SCAFFOLD)
  - FirebaseAppRepository implementing the repository contracts
  - Google + Phone providers enabled server-side
provides:
  - getUser/ensureUser on the repository seam (both InMemory + Firebase)
  - AuthService-injected NguyenInDoubtState (default demo; uid-branched)
  - AuthGate app entry (signed-out LoginScreen <-> signed-in app, fade)
  - Apple gracefully disabled; calm Firebase-mode invite copy
affects:
  - lib/main.dart (new AuthGate + NguyenInDoubtAuthApp entry)
  - lib/state/app_state.dart (auth injection, uid branch)
  - lib/repositories/app_repository.dart + firebase_app_repository.dart
  - lib/screens/login_screen.dart (Apple disabled)
  - lib/services/auth_service.dart (const DemoAuthService)
tech-stack:
  added: []
  patterns:
    - NidRepository union type lets one state field hold either backend
    - uid==null keeps the demo path byte-identical; uid!=null bootstraps real
    - ensureUser runs in the state constructor; empty Firestore = calm empties
    - PrivacyException caught -> calm "not available yet" copy, never a throw
key-files:
  created:
    - test/auth_gate_test.dart
  modified:
    - lib/main.dart
    - lib/state/app_state.dart
    - lib/repositories/app_repository.dart
    - lib/repositories/firebase_app_repository.dart
    - lib/screens/login_screen.dart
    - lib/services/auth_service.dart
    - test/login_screen_test.dart
decisions:
  - Kept NguyenInDoubtApp(state:, showSplash:) verbatim; added a separate
    NguyenInDoubtAuthApp so all 60 existing tests compile/behave identically
  - Introduced NidRepository (AppRepository+Clinician+Consent) so the state
    field holds InMemory or Firebase behind one type without casts at call sites
  - Demo-only repo methods (currentSession, patientDemo, saveSession,
    updateDemoPatientProfile, resetDemoData) reached via a guarded
    _demoRepository, only on the uid==null path
  - firestore.rules already permit self create+read of users/{uid} with
    role=='patient' -> NO rules change required (verified against ensureUser)
metrics:
  duration: ~10 min
  completed: 2026-07-12
status: complete
---

# Phase 11 Plan AUTH-WIRING: Real-Auth Wiring Summary

Wired the NguyenInDoubt Flutter app to real Firebase auth (Google + Phone, both
live) and the live Firestore behind an `AuthGate`, without disturbing the demo
experience or the passing tests. Signed-out users see the brand `LoginScreen`;
signing in bootstraps a real `users/{uid}` profile and enters the app on
`FirebaseAppRepository`; the in-memory demo path stays byte-identical (tests
inject a demo `AuthService` + `InMemoryAppRepository`). Suite grew 60 -> 63,
all green; analyze clean; web build ok.

## What Was Built

- **Repository seam (`getUser` + `ensureUser`):** Added to the `AppRepository`
  interface and implemented in both repos. InMemory: `getUser` returns the
  seeded demo user or null; `ensureUser` is a no-op returning the demo user so
  the demo/test path never mints accounts and stays offline. Firebase:
  `getUser` reads `users/{uid}`; `ensureUser` creates a minimal patient profile
  (`role=patient`, `consentStatus=notAsked`) when absent and is idempotent.
- **`NidRepository` union type:** `AppRepository + ClinicianRepository +
  ConsentRepository`; both concrete repos implement it, so `NguyenInDoubtState`
  holds one field and swaps backends behind auth.
- **Auth-injected state:** `NguyenInDoubtState` takes an injected `AuthService`
  defaulting to `const DemoAuthService()` (existing constructors untouched).
  `currentUid == null` runs the demo/in-memory path exactly as before (seeded
  session, demo users, local persistence via a guarded `_demoRepository`).
  `currentUid != null` seeds a calm placeholder synchronously then
  `_bootstrapSignedInUser` calls `ensureUser` and loads the real data; a
  freshly signed-up account with empty Firestore lands on the existing calm
  empty states (correct, not seeded here). Bootstrap failures degrade to a calm
  signed-out screen (logged, never a raw error).
- **`AuthGate` entry (`main.dart`):** `main()` constructs `FirebaseAuthService`
  + `FirebaseAppRepository` and runs `NguyenInDoubtAuthApp`. The gate listens to
  `authService.uidChanges`: null -> `LoginScreen`; non-null -> per-uid
  `NguyenInDoubtState` behind `BrandSplashGate/AppShell`. Sign-out flows back
  through the stream to the login via a 400ms `AnimatedSwitcher` fade (never a
  pop — project rule). A guarded `Firebase.initializeApp` failure still falls
  back to the in-memory demo (`NguyenInDoubtApp`) for offline / web-demo boots.
- **LoginScreen live wiring:** Google + Phone drive the real
  `FirebaseAuthService`. Apple is gently disabled with "Apple sign-in is coming
  soon." copy (provider not enabled server-side) instead of throwing on tap.
- **Calm consent surfaces:** `acceptValidatedInvite` / `revokeConsent` catch
  `PrivacyException` (Firebase mode throws by design for `acceptInvite`) and
  surface calm "not available yet" invite copy — never an uncaught throw. The
  demo path never reaches these branches.
- **`test/auth_gate_test.dart`:** A `FakeAuthService` drives the gate offline:
  signed-out renders the `LoginScreen`; signed-in (`uid='patient-demo'`)
  bootstraps into the patient app shell via `ensureUser`; sign-out fades back
  to the `LoginScreen`.

## firestore.rules Change

**No change required.** The existing `match /users/{userId}` already grants a
signed-in user create + read of their own doc:

- `allow read: if isSelf(userId) || acceptedClinicianLink(userId);`
- `allow create: if isSelf(userId) && request.resource.data.role == 'patient';`

`ensureUser` writes `role: 'patient'` under `isSelf(uid)`, so both the create
and the subsequent read are already authorized. The extra `create` payload
fields (`displayName`, `consentStatus`, `clinicCode`, `createdAt`, `updatedAt`)
are permitted because the create rule constrains only `role` and identity, not
the key set. No rules edit was made; nothing to deploy for this plan.

## Verification

| Gate | Result |
| --- | --- |
| `dart format lib test` | 0 changed |
| `flutter analyze` | No issues found! |
| `flutter test` | 63 passed (60 baseline + 3 new AuthGate) |
| `flutter build web` | Built build/web |

Real Google OAuth was NOT tap-verified here (needs a human tap-through in the
sim). It is covered indirectly: the signed-out path renders `LoginScreen` and
the signed-in path bootstraps into the app, both asserted in the new gate test.

`STATE.md` and `ROADMAP.md` were not modified (per plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `const DemoAuthService()` constructor**
- **Found during:** Task 2
- **Issue:** Defaulting the injected `AuthService` to `const DemoAuthService()`
  requires a const constructor, which `DemoAuthService` lacked.
- **Fix:** Added `const DemoAuthService();`. Keeps every existing demo/test
  constructor call unchanged and Firebase-free.
- **Files modified:** lib/services/auth_service.dart
- **Commit:** 5acbd2f

**2. [Rule 2 - Correctness] Guard Firebase-mode consent throws**
- **Found during:** Task 4
- **Issue:** In Firebase mode `acceptInvite` throws `PrivacyException` by design
  (needs a trusted backend op); `acceptValidatedInvite` let it propagate
  uncaught to the UI, violating the no-raw-errors rule.
- **Fix:** Catch `PrivacyException` in `acceptValidatedInvite` and `revokeConsent`
  and surface calm "not available yet" invite copy. Demo path is unaffected (it
  only throws when `!canAccept`, already guarded).
- **Files modified:** lib/state/app_state.dart
- **Commit:** c0dc4ce

### Plan-driven test updates (not auto-fixes)

- `test/login_screen_test.dart` updated to assert Apple is disabled with
  "Apple sign-in is coming soon." copy (the plan intentionally disables Apple)
  and to tap only the live Google provider in the raw-error guard. This is a
  deliberate behavior change mandated by the plan's design, not a regression.

## Known Stubs

- **Apple sign-in disabled** (`lib/screens/login_screen.dart`): intentional —
  the Apple provider is not enabled server-side. Shown as calm "coming soon"
  copy; wiring already exists in `FirebaseAuthService.signInWithApple` for when
  the provider is enabled.
- **Firebase-mode `acceptInvite` throws by design** (`firebase_app_repository`):
  invite acceptance requires a trusted backend operation not built yet. Surfaced
  as calm "not available yet" copy; a future plan adds the backend path.
- **iOS Google URL scheme placeholder** (`ios/Runner/Info.plist`): carried over
  from 11-AUTH-SCAFFOLD, untouched here. Must be replaced with the real
  REVERSED_CLIENT_ID from the live `GoogleService-Info.plist` before an iOS
  build ships Google sign-in.

## Commits

- 387ec1d feat(11-AUTH-WIRING): add getUser + ensureUser to repository seam
- 5acbd2f feat(11-AUTH-WIRING): inject AuthService into app state, branch on uid
- f10b7bd feat(11-AUTH-WIRING): auth-gate the app entry with fade transitions
- c0dc4ce feat(11-AUTH-WIRING): Apple gracefully disabled, calm invite copy for Firebase
- 46a1e06 test(11-AUTH-WIRING): cover the AuthGate signed-out/in/out flow

## Self-Check: PASSED

All created files exist on disk (`test/auth_gate_test.dart`, the SUMMARY) and
all five task commits are present in git history.
