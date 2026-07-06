# Technology Stack

**Project:** NguyenInDoubt Flutter MVP
**Researched:** 2026-07-06
**Scope:** Local repository evidence only; no web research.
**Overall confidence:** HIGH for current implementation, MEDIUM for next-step recommendations because Firebase and health-platform integrations are intentionally stubbed.

## Stack Recommendation

Keep the MVP Flutter-first, local-demo-first, and boundary-driven. The current stack is already appropriately small for a sensitive mental-health companion: Flutter renders iOS, Android, and web from one codebase; `ChangeNotifier` owns app state; repository interfaces isolate persistence and clinician privacy rules; `shared_preferences` keeps mutable demo data alive across refreshes; Firebase remains a documented production boundary, not a live dependency.

Do not add analytics, Crashlytics, live Firestore writes, or real HealthKit / Health Connect ingestion until compliance review is complete.

## Current Stack

| Layer | Technology | Version / Source | Keep? | Rationale |
|---|---|---:|---|---|
| App framework | Flutter / Dart | SDK constraint `^3.12.0` | Yes | Existing scaffold targets iOS, Android, and web with one UI codebase. |
| UI shell | Flutter Material | SDK | Yes | `MaterialApp`, app theme, and screen widgets are already sufficient for the MVP. |
| State | `ChangeNotifier` | Flutter foundation | Yes | `NguyenInDoubtState` is small and explicit; adding Riverpod/BLoC now would add ceremony without solving a current problem. |
| Persistence | `shared_preferences` | `2.5.5` locked | Yes, demo only | Good for local browser/app preferences and refresh survival; not appropriate for production PHI-adjacent storage. |
| Repository boundary | `AppRepository`, `ClinicianRepository` | Local code | Yes | Central privacy seam: patient journal reads stay patient-only; clinician reads require accepted links. |
| Health data | `HealthDataProvider` + `MockHealthDataProvider` | Local code | Yes | Correct abstraction for replacing mock import with HealthKit / Health Connect providers later. |
| Firebase boundary | Firestore rules, hosting config, stub options | Local files only | Keep stubbed | Contract documents future Auth/Firestore shape while avoiding live sensitive data handling. |
| Testing | `flutter_test` | SDK | Yes | Existing widget, repository, and provider tests cover core demo and privacy behavior. |
| Linting | `flutter_lints` | `6.0.0` locked | Yes | Standard analyzer coverage; keep `flutter analyze` as a gate. |
| Web deployment | Flutter web build, GitHub Pages demo, Firebase Hosting config | Local docs/config | Yes for demo | Static web demo is appropriate while data remains per-device and local. |

## Firebase Boundary

Firebase should enter through a new repository implementation, not by spreading Firestore calls through screens or state objects.

Recommended next shape:

| Concern | Current | Next Production-Seam Step |
|---|---|---|
| Identity | Placeholder patient/clinician mode switch | Firebase Auth plus role claims after compliance review. |
| Data storage | `InMemoryAppRepository` with optional `SharedPreferences` JSON persistence | `FirebaseAppRepository` implementing the same repository contracts. |
| Authorization | Code-level accepted-link checks and `PrivacyException` | Keep code checks and enforce equivalent Firestore rules. |
| Collections | Documented in `docs/firebase_contract.md` | `users`, `clinicianLinks`, `healthSamples`, `dailySummaries`, `journalEntries`, `resourceCards`. |
| Journals | Patient-only in repository | Patient-only in Firestore rules; never readable by clinicians. |
| Telemetry | Absent | Keep absent until reviewed; no Analytics or Crashlytics by default. |

## Health Data Boundary

Preserve `HealthDataProvider` as the only health-platform integration surface. The current mock provider already models permission gating, available metrics, and sleep-sample fetches. Real platform work should add separate implementations behind the same interface:

| Provider | Target | Notes |
|---|---|---|
| `MockHealthDataProvider` | Demo and tests | Keep as default for public web demo and deterministic test coverage. |
| Future `AppleHealthDataProvider` | iOS HealthKit | Requires platform permissions, review copy, and careful local-to-backend consent design. |
| Future `HealthConnectDataProvider` | Android Health Connect | Same abstraction; Android-specific permission UX and data availability checks. |

Do not let health provider classes write directly to Firebase. They should return normalized `HealthSample` values; repositories decide storage and sharing behavior.

## Testing and Verification

Keep these as the minimum gates before declaring stack-affecting work done:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
```

Current tests worth preserving and expanding:

| Test Area | Existing Evidence | Next Coverage |
|---|---|---|
| Health provider | Mock permission and sleep-summary tests | Add fake real-provider tests before HealthKit / Health Connect integration. |
| Repository privacy | Clinician linked sleep allowed, journals denied, unlinked sleep rejected | Reuse these expectations for any Firebase repository implementation. |
| Local persistence | Shared preferences round-trip test | Add migration tests if the local schema changes from `schemaVersion: 1`. |
| Widget flow | Patient signup/import smoke test | Add route/responsiveness coverage for journal, resources, safety, and clinician views. |

## Deployment Posture

Use GitHub Pages / static Flutter web for public MVP demos while Firebase remains disabled. Firebase Hosting config can stay as a future production hosting option, but enabling backend services should be a distinct reviewed phase.

Stable local run command from the repo:

```bash
flutter run -d chrome --web-port 5173
```

Before starting a local server, check for an existing `flutter run` process and reuse the stable port.

## Alternatives Rejected

| Category | Rejected Option | Why Not Now |
|---|---|---|
| State management | Riverpod, BLoC, Redux | Current state is a single small `ChangeNotifier`; extra framework cost is not justified yet. |
| Local database | SQLite, Isar, Hive | Shared preferences is enough for local demo persistence; production storage should go through the Firebase boundary after review. |
| Backend now | Live Firestore/Auth writes | Sensitive mental-health and health-adjacent data requires compliance review first. |
| Telemetry | Analytics, Crashlytics, session replay | Explicitly absent in project posture; avoid collecting sensitive usage data by default. |
| Health integration now | Direct HealthKit / Health Connect calls | Current mock provider supports demo value; real ingestion needs permission, privacy, and platform review work. |

## Source Files

- `.planning/PROJECT.md`
- `pubspec.yaml`
- `pubspec.lock`
- `lib/main.dart`
- `lib/state/app_state.dart`
- `lib/repositories/app_repository.dart`
- `lib/services/health_data_provider.dart`
- `lib/models/app_models.dart`
- `docs/firebase_contract.md`
- `firestore.rules`
- `firebase.json`
- `lib/firebase_options.dart`
- `test/repositories/app_repository_test.dart`
- `test/services/health_data_provider_test.dart`
- `test/widget_test.dart`
- `README.md`
