# Walking Skeleton - NguyenInDoubt Flutter MVP

**Phase:** 1
**Generated:** 2026-07-06

## Capability Proven End-to-End

A demo user can open the Flutter app, choose patient or clinician mode, persist local demo changes, and see the privacy boundary that journals are patient-only while clinicians see accepted-link sleep summaries only.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter / Dart with Material 3 | One UI codebase already targets iOS, Android, and web. |
| Data layer | `InMemoryAppRepository` with optional `SharedPreferences` JSON persistence | Fits demo-local persistence without production PHI storage. |
| Auth | Demo mode switch only | Production auth is intentionally deferred to Phase 2. |
| Health import | `HealthDataProvider` with `MockHealthDataProvider` default | Keeps public demo deterministic while preserving future provider seam. |
| Deployment target | Static Flutter web build for GitHub Pages and local port 5173 serving | Appropriate while Firebase is stubbed and demo data remains per-device. |
| Directory layout | Flutter feature screens under `lib/screens`, state in `lib/state`, repository in `lib/repositories`, services in `lib/services` | Matches the existing MVP organization and keeps privacy boundaries centralized. |

## Stack Touched in Phase 1

- [x] Project scaffold (framework, build, lint, test runner)
- [x] Routing/navigation through onboarding, patient shell, and clinician dashboard
- [x] Local read/write persistence for journal, imported sleep, and consent state
- [x] UI interactions for onboarding, import, journaling, resources, safety, and clinician view
- [x] Deployment through static web build and GitHub Pages demo

## Out of Scope (Deferred to Later Slices)

- Production signed-out/auth/session model
- Firebase Auth or live Firestore storage
- Real HealthKit or Health Connect imports
- Real invite validation, revocation, consent history, or audit lifecycle
- Clinician access to journal content
- Patient-clinician messaging
- Analytics, Crashlytics, telemetry, emergency monitoring, diagnosis, or treatment recommendations

## Subsequent Slice Plan

- Phase 2: Auth and Session Model
- Phase 3: Privacy and Repository Contract Hardening
- Phase 4: Firebase Auth and Firestore Adapter
- Phase 5: Consent Management and Invite Lifecycle
- Phase 6: Real Sleep Import Providers
- Phase 7: Production Deployment Posture
