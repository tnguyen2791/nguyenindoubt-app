---
phase: 11
plan: AUTH-SCAFFOLD
subsystem: auth
tags: [auth, firebase, google-sign-in, sign-in-with-apple, phone-auth, scaffolding]
requires:
  - firebase_core/firebase_auth already wired in main.dart
  - InMemory demo flow remains the default entry
provides:
  - AuthService abstraction (Firebase + demo impls)
  - brand-styled LoginScreen (Google/Apple/phone + OTP), not yet mounted
  - iOS Google URL scheme placeholder
affects:
  - pubspec.yaml (2 new deps)
  - ios/Runner/Info.plist (CFBundleURLTypes)
tech-stack:
  added: [google_sign_in ^7.2.0, sign_in_with_apple ^8.1.0]
  patterns:
    - abstract AuthService seam; provider SDK calls confined to FirebaseAuthService
    - DemoAuthService no-op keeps tests/demo Firebase-free
    - AuthFailure carries only calm user-facing copy; raw errors logged via debugPrint
key-files:
  created:
    - lib/services/auth_service.dart
    - lib/screens/login_screen.dart
    - test/login_screen_test.dart
  modified:
    - pubspec.yaml
    - pubspec.lock
    - ios/Runner/Info.plist
decisions:
  - google_sign_in 7.x uses the singleton/initialize/authenticate API; obtain the
    Firebase access token via authorizationClient.authorizeScopes(['email'])
  - GoogleService-Info.plist is a stub with no OAuth client, so the iOS URL scheme
    is a documented REVERSED_CLIENT_ID placeholder to swap when the provider is enabled
  - LoginScreen kept standalone (injected AuthService, optional onSignedIn hook);
    main.dart entry and the demo flow deliberately unchanged this pass
metrics:
  duration: ~6 min
  completed: 2026-07-12
status: complete
---

# Phase 11 Plan AUTH-SCAFFOLD: Real-Auth Scaffolding Summary

Additive, verifiable scaffolding for multi-provider auth (Google, Apple, Phone)
in the NguyenInDoubt Flutter app — abstraction, brand-styled login UI, iOS URL
scheme, and a widget test — without flipping the app off its in-memory demo flow.
Everything compiles, analyzes clean, and the suite stays green (56 → 60 tests).

## What Was Built

- **Deps:** `google_sign_in ^7.2.0` and `sign_in_with_apple ^8.1.0` resolve clean
  on the pinned Flutter 3.44 / Dart ^3.12 SDK (`flutter pub get` succeeds).
- **iOS Google URL scheme:** Added `CFBundleURLTypes` to `ios/Runner/Info.plist`
  with a documented REVERSED_CLIENT_ID placeholder. Existing plist keys untouched;
  `plutil -lint` passes. The current `GoogleService-Info.plist` is a stub with no
  OAuth client (Google provider not enabled server-side yet), so the scheme is a
  clearly-commented placeholder to replace when the provider goes live.
- **`lib/services/auth_service.dart`:** Abstract `AuthService`
  (`uidChanges`, `currentUid`, `signInWithGoogle`, `signInWithApple`,
  `startPhoneSignIn` → `PhoneStartResult`, `confirmPhoneCode`, `signOut`), plus:
  - `FirebaseAuthService` — FirebaseAuth + google_sign_in 7.x + sign_in_with_apple;
    phone flow uses `verifyPhoneNumber` with auto-resolve handling; all failures
    become `AuthFailure` with calm copy, raw errors logged via `debugPrint`.
  - `DemoAuthService` — always-null uid, no-op provider calls (no Firebase needed).
- **`lib/screens/login_screen.dart`:** Brand-styled sign-in (fog ground, ember-"In"
  wordmark, full-width button theme) with three provider buttons and a calm phone +
  OTP entry flow per designs 42/60/62. Wired to an injected `AuthService`; errors
  surface only through a friendly inline banner. Buttons guard empty/invalid phone
  and short codes. NOT mounted as the app entry — staged for the next pass.
- **`test/login_screen_test.dart`:** Four tests with `DemoAuthService` — three
  provider labels render, phone entry guards empty/invalid numbers, the flow
  advances to code entry and guards short codes, and no raw exception/error-code
  strings ever surface.

## Verification

| Gate | Result |
| --- | --- |
| `dart format lib test` | 0 changed |
| `flutter analyze` | No issues found! |
| `flutter test` | 60 passed (56 baseline + 4 new) |
| `flutter build web` | Built build/web |

`main.dart` default entry and the in-memory demo flow are unchanged; `STATE.md`
and `ROADMAP.md` untouched. The app boots and behaves exactly as before.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Correctness] Google access token acquisition (7.x API)**
- **Found during:** Task 3
- **Issue:** google_sign_in 7.x no longer returns an access token from
  `authentication`; `GoogleAuthProvider.credential` benefits from both idToken and
  accessToken. Using `authorizationForScopes` (nullable, non-prompting) could yield
  a null access token.
- **Fix:** Used `account.authorizationClient.authorizeScopes(['email'])`, which
  prompts if necessary and returns a non-null authorization, then passed both
  idToken and accessToken to the Firebase credential.
- **Files modified:** lib/services/auth_service.dart
- **Commit:** 3114877

**2. [Rule 2 - Correctness] iOS URL scheme is a documented placeholder, not a real value**
- **Found during:** Task 2
- **Issue:** The plan says to copy REVERSED_CLIENT_ID from GoogleService-Info.plist,
  but that stub plist has no OAuth CLIENT_ID (the Google provider isn't enabled
  server-side yet), so no real reversed client ID exists.
- **Fix:** Added the `CFBundleURLTypes` structure with a clearly-commented
  placeholder scheme and an inline note describing the exact swap needed when the
  provider is enabled. This keeps the scaffolding additive and honest rather than
  fabricating a client ID.
- **Files modified:** ios/Runner/Info.plist
- **Commit:** fe9ef95

## Known Stubs

- **iOS Google URL scheme placeholder** (`ios/Runner/Info.plist`,
  `com.googleusercontent.apps.6173983291-REPLACE_WITH_REVERSED_CLIENT_ID`):
  intentional — the Google provider is not enabled server-side yet. The next pass
  (flip to real auth) must enable Google sign-in in Firebase, re-download
  `GoogleService-Info.plist`, and replace this value with its real REVERSED_CLIENT_ID.
  Documented inline in the plist and does not affect the demo flow or web build.

## Commits

- 1d35072 chore: add google_sign_in and sign_in_with_apple deps
- fe9ef95 chore: stage iOS Google URL scheme placeholder
- 3114877 feat: add AuthService abstraction with Firebase + demo impls
- fb5ecab feat: add brand-styled LoginScreen wired to AuthService
- 808f5e8 test: add LoginScreen widget test with DemoAuthService

## Self-Check: PASSED

All created files exist on disk and all five task commits are present in git history.
