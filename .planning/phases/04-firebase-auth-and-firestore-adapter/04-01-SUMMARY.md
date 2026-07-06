---
phase: 04-firebase-auth-and-firestore-adapter
plan: 01
subsystem: firebase
tags: [flutter, firebase, firestore, rules, emulator, privacy]

requires:
  - Phase 3 privacy and repository contract hardening
provides:
  - Firebase Flutter dependencies for Auth and Firestore
  - Firestore-backed repository adapter behind existing interfaces
  - Tightened Firestore privacy rules
  - Repo-local Firestore emulator test harness
  - Emulator coverage for users, clinician links, health samples, daily summaries, journal entries, and resource cards
affects: [firebase, privacy, auth, consent, production-posture]

tech-stack:
  added:
    - firebase_core
    - firebase_auth
    - cloud_firestore
    - firebase-tools
    - "@firebase/rules-unit-testing"
    - firebase
    - vitest
  patterns:
    - Firebase adapter code lives in `lib/repositories/firebase_app_repository.dart`.
    - Public demo remains local by default through `InMemoryAppRepository`.
    - Firestore authorization depends on Auth claims and deterministic accepted links, not client-selected roles.

key-files:
  created:
    - lib/repositories/firebase_app_repository.dart
    - package.json
    - package-lock.json
    - test/firestore/firestore_rules.test.mjs
  modified:
    - .gitignore
    - analysis_options.yaml
    - docs/firebase_contract.md
    - firebase.json
    - firestore.rules
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "Kept the public app on local demo mode; Firebase is available as an adapter boundary, not the default runtime."
  - "Required clinician auth claims plus accepted deterministic links for clinician sleep reads."
  - "Made clinician link writes admin-only until Phase 5 consent lifecycle work."
  - "Moved the Firestore emulator to port 8085 because port 8080 is occupied locally."

patterns-established:
  - "Rules tests seed data with security rules disabled, then assert allowed/denied access through authenticated contexts."
  - "Dart analyzer excludes `node_modules/**` so Firebase CLI templates are not analyzed as app code."

requirements-completed: [FIRE-01, FIRE-02, FIRE-03, FIRE-04, FIRE-05]

coverage:
  - id: F1
    description: "Firebase adapter implements repository interfaces and screens do not import Firebase directly."
    requirement: FIRE-01
    verification:
      - kind: static
        ref: "lib/repositories/firebase_app_repository.dart"
        status: pass
      - kind: other
        ref: "flutter analyze"
        status: pass
    human_judgment: false
  - id: F2
    description: "Firestore rules enforce patient-owned journals and accepted-link clinician sleep-only access."
    requirement: FIRE-02
    verification:
      - kind: emulator
        ref: "npm run test:firestore-rules"
        status: pass
    human_judgment: false
  - id: F3
    description: "Firestore rules deny pending, revoked, missing, malformed, and unclaimed clinician link access."
    requirement: FIRE-03
    verification:
      - kind: emulator
        ref: "test/firestore/firestore_rules.test.mjs#allows clinician sleep reads only for accepted links"
        status: pass
      - kind: emulator
        ref: "test/firestore/firestore_rules.test.mjs#requires a clinician auth claim for accepted-link sleep reads"
        status: pass
    human_judgment: false
  - id: F4
    description: "Emulator tests cover users, clinician links, health samples, daily summaries, journal entries, and resource cards."
    requirement: FIRE-04
    verification:
      - kind: emulator
        ref: "test/firestore/firestore_rules.test.mjs"
        status: pass
    human_judgment: false
  - id: F5
    description: "Analytics, Crashlytics, and telemetry remain absent."
    requirement: FIRE-05
    verification:
      - kind: static
        ref: "pubspec.yaml"
        status: pass
      - kind: static
        ref: "package.json"
        status: pass
    human_judgment: false
  - id: F6
    description: "Full Phase 4 verification passed through rules tests, Flutter analyze/test, and web builds."
    requirement: FIRE-01
    verification:
      - kind: other
        ref: "npm run test:firestore-rules"
        status: pass
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

duration: 60min
completed: 2026-07-06
status: complete
---

# Phase 04: Firebase Auth and Firestore Adapter Summary

**Firebase Auth and Firestore are now represented behind repository boundaries with emulator-proven privacy rules, while the public demo remains local by default**

## Performance

- **Duration:** 60 min
- **Started:** 2026-07-06T14:02:00Z
- **Completed:** 2026-07-06T15:01:08Z
- **Tasks:** 5
- **Files modified:** Firebase rules/config, Flutter dependencies, repository adapter, docs, and emulator tests

## Accomplishments

- Added Firebase Flutter dependencies for Auth, Firestore, and Core.
- Added `FirebaseAppRepository`, implementing `AppRepository` and `ClinicianRepository` behind the existing privacy contracts.
- Kept `main.dart` unchanged in local demo mode, so the public app does not initialize Firebase by default.
- Tightened Firestore rules:
  - clinician sleep reads require a clinician auth claim and accepted deterministic link
  - journals remain patient-owned only
  - clinician link writes are admin-only until Phase 5
  - resource cards are public read and admin create/update, with delete denied
- Added repo-local Firebase emulator testing with Vitest and `@firebase/rules-unit-testing`.
- Added rules tests for journals, accepted/pending/revoked/missing/malformed clinician links, resource cards, link writes, and deletes.

## Task Commits

No commits were made by request.

## Files Created/Modified

- `lib/repositories/firebase_app_repository.dart` - Adds Firestore-backed adapter behind repository interfaces.
- `firestore.rules` - Tightens Firebase privacy boundary.
- `firebase.json` - Adds Firestore emulator config on `127.0.0.1:8085`.
- `test/firestore/firestore_rules.test.mjs` - Adds emulator privacy tests.
- `package.json` / `package-lock.json` - Adds repo-local rules test tooling.
- `pubspec.yaml` / `pubspec.lock` - Adds Firebase Flutter dependencies.
- `docs/firebase_contract.md` - Documents trusted claims and link-write posture.
- `.gitignore` / `analysis_options.yaml` - Ignores/excludes npm tooling artifacts.

## Decisions Made

- Local demo remains the default runtime; Firebase mode is not enabled until a future explicit switch/config path.
- Auth custom claims are the rule authority for clinician/admin behavior.
- `users/{userId}.role` is profile/display data, not the authorization source.
- Accepted clinician links cannot be client-created; trusted server/admin setup is required until Phase 5 designs the consent lifecycle.

## Deviations from Plan

None. The emulator port changed from the Firestore default `8080` to `8085` because a local WhatsApp process was listening on `8080`.

## Issues Encountered

- `firebase-tools` emitted a Node engine warning because a dependency supports Node 20/22/24 while this machine runs Node 26. The repo-local CLI still ran successfully.
- `flutter analyze` initially scanned Firebase CLI Dart templates under `node_modules`; `analysis_options.yaml` now excludes `node_modules/**`.
- `npm audit` reports 5 moderate findings in npm dev tooling. No runtime app dependency or production telemetry package was added.

## User Setup Required

None for the current public demo. To run rules tests locally, use:

```sh
npm install
npm run test:firestore-rules
```

## Verification

- `npm run test:firestore-rules` - passed, 6 tests
- `flutter analyze` - passed
- `flutter test` - passed, 17 tests
- `flutter build web` - passed
- `flutter build web --base-href /nguyenindoubt-app/` - passed

## Next Phase Readiness

Phase 5 can now build consent management and invite lifecycle behavior on top of rules that already deny untrusted accepted links, clinician journal reads, and non-accepted sleep access.

---
*Phase: 04-firebase-auth-and-firestore-adapter*
*Completed: 2026-07-06*

