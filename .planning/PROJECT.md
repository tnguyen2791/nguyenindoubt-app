# NguyenInDoubt Flutter MVP

## What This Is

NguyenInDoubt is a Flutter MVP for a patient-facing mental-health companion with an invite-linked clinician dashboard. The current app demonstrates onboarding, mock HealthKit-style sleep import, a patient sleep dashboard, a private journal, curated resources, a safety page, and clinician-only access to accepted patients' sleep summaries.

The MVP is intentionally local/demo-first. Firebase files and Firestore rules document the intended production boundary, but live Firebase Auth, Firestore, analytics, Crashlytics, telemetry, and real health-platform access are not enabled.

## Core Value

Patients can explore sleep context and private reflection while clinicians see only consented sleep summaries, never journal content.

## Requirements

### Validated

- ✓ Patient can start the demo as a patient and see a responsive patient shell — existing Flutter MVP
- ✓ Patient can import mock sleep samples and view sleep trend summaries — existing Flutter MVP
- ✓ Patient can write private journal entries that are not exposed to clinicians — existing Flutter MVP
- ✓ Patient can browse curated educational resources and a safety page — existing Flutter MVP
- ✓ Patient can accept an invite code to share sleep summaries with a clinician — existing Flutter MVP
- ✓ Clinician can view accepted invite-linked patients' sleep summaries only — existing Flutter MVP
- ✓ Clinician journal access is denied in repository logic and Firestore rules — existing Flutter MVP
- ✓ Demo-local persistence stores mutable demo state in browser/app preferences — existing Flutter MVP
- ✓ Static web demo is deployed to GitHub Pages for phone access — existing deployment

### Active

- [ ] Replace the placeholder patient/clinician mode switch with a proper auth and onboarding state model.
- [ ] Preserve the privacy boundary as storage moves from local demo state toward production services.
- [ ] Expand widget and route responsiveness coverage for journal, resources, safety, and clinician views.
- [ ] Prepare a compliance-reviewed Firebase Auth and Firestore integration path.
- [ ] Add real HealthKit and Health Connect providers behind the `HealthDataProvider` abstraction.
- [ ] Improve production deployment posture beyond the temporary public GitHub Pages demo.

### Out of Scope

- Live Firebase Auth/Firestore writes before compliance review — patient mental-health and health-adjacent data needs review before production storage.
- Firebase Analytics, Crashlytics, or live telemetry by default — privacy posture explicitly avoids telemetry until reviewed.
- Clinician access to journals — v1 privacy promise says journals stay patient-only.
- Diagnosis, clinical advice, or medication recommendations — the app is educational and reflective, not a medical decision system.
- Real urgent-care workflow automation — the safety page can point to crisis resources, but emergency handling remains outside the app.
- Production HealthKit/Health Connect ingestion without platform permission, privacy, and review work — current import is mock-only.

## Context

- The codebase is a new Flutter project scaffolded for iOS, Android, and web.
- Core state lives in `NguyenInDoubtState`, backed by `InMemoryAppRepository` with optional `shared_preferences` persistence for local/demo data.
- `HealthDataProvider` is the seam for future real health data integrations; `MockHealthDataProvider` powers the current demo.
- Firebase is represented by stubs and a contract only: `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`, `lib/firebase_options.dart`, and `docs/firebase_contract.md`.
- The current public demo is hosted from a Flutter web build at `https://tnguyen2791.github.io/nguyenindoubt-app/`.
- The repository is public for now at `https://github.com/tnguyen2791/nguyenindoubt-app`; do not commit secrets or real patient data.
- Previous verification passed: `flutter analyze`, `flutter test`, and `flutter build web`.

## Constraints

- **Tech stack**: Flutter/Dart first, with iOS, Android, and web targets — aligns with the scaffold and user preferences.
- **Privacy**: Journal entries stay private and inaccessible to clinicians — this is the central trust boundary.
- **Compliance**: Firebase, health data, telemetry, and production storage require compliance review before live use — the data domain is sensitive.
- **Demo hosting**: GitHub Pages can host the app shell but cannot sync local browser data across devices — user-entered demo data remains per-device until a backend exists.
- **Development workflow**: Run `flutter analyze` and `flutter test` before declaring code changes done; run `flutter pub get` after dependency changes.
- **Local servers**: Keep port `5173` stable and do not run multiple app instances.
- **Git**: Commit/push only when requested; this GSD initialization creates planning commits per the framework.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep Firebase stubbed until compliance review | Avoid live handling of sensitive mental-health and health-adjacent data before policy and security review | — Pending |
| Use local preferences for demo persistence | Lets journal/import/consent changes survive refresh without adding a backend prematurely | ✓ Good |
| Keep clinician view sleep-only | Preserves the product's privacy promise and maps to Firestore rules | ✓ Good |
| Host a temporary public web demo on GitHub Pages | Makes the MVP reachable from a phone quickly while Firebase remains disabled | — Pending |
| Use vertical MVP GSD phases | This is a user-facing MVP where each phase should preserve a working app | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-06 after initialization*
