<!-- GSD:project-start source:PROJECT.md -->

## Project

**NguyenInDoubt Flutter MVP**

NguyenInDoubt is a Flutter MVP for a patient-facing mental-health companion with an invite-linked clinician dashboard. The current app demonstrates onboarding, mock HealthKit-style sleep import, a patient sleep dashboard, a private journal, curated resources, a safety page, and clinician-only access to accepted patients' sleep summaries.

The MVP is intentionally local/demo-first. Firebase files and Firestore rules document the intended production boundary, but live Firebase Auth, Firestore, analytics, Crashlytics, telemetry, and real health-platform access are not enabled.

**Core Value:** Patients can explore sleep context and private reflection while clinicians see only consented sleep summaries, never journal content.

### Constraints

- **Tech stack**: Flutter/Dart first, with iOS, Android, and web targets — aligns with the scaffold and user preferences.
- **Privacy**: Journal entries stay private and inaccessible to clinicians — this is the central trust boundary.
- **Compliance**: Firebase, health data, telemetry, and production storage require compliance review before live use — the data domain is sensitive.
- **Demo hosting**: GitHub Pages can host the app shell but cannot sync local browser data across devices — user-entered demo data remains per-device until a backend exists.
- **Development workflow**: Run `flutter analyze` and `flutter test` before declaring code changes done; run `flutter pub get` after dependency changes.
- **Local servers**: Keep port `5173` stable and do not run multiple app instances.
- **Git**: Commit/push only when requested; this GSD initialization creates planning commits per the framework.

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Stack Recommendation

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

| Concern | Current | Next Production-Seam Step |
|---|---|---|
| Identity | Placeholder patient/clinician mode switch | Firebase Auth plus role claims after compliance review. |
| Data storage | `InMemoryAppRepository` with optional `SharedPreferences` JSON persistence | `FirebaseAppRepository` implementing the same repository contracts. |
| Authorization | Code-level accepted-link checks and `PrivacyException` | Keep code checks and enforce equivalent Firestore rules. |
| Collections | Documented in `docs/firebase_contract.md` | `users`, `clinicianLinks`, `healthSamples`, `dailySummaries`, `journalEntries`, `resourceCards`. |
| Journals | Patient-only in repository | Patient-only in Firestore rules; never readable by clinicians. |
| Telemetry | Absent | Keep absent until reviewed; no Analytics or Crashlytics by default. |

## Health Data Boundary

| Provider | Target | Notes |
|---|---|---|
| `MockHealthDataProvider` | Demo and tests | Keep as default for public web demo and deterministic test coverage. |
| Future `AppleHealthDataProvider` | iOS HealthKit | Requires platform permissions, review copy, and careful local-to-backend consent design. |
| Future `HealthConnectDataProvider` | Android Health Connect | Same abstraction; Android-specific permission UX and data availability checks. |

## Testing and Verification

| Test Area | Existing Evidence | Next Coverage |
|---|---|---|
| Health provider | Mock permission and sleep-summary tests | Add fake real-provider tests before HealthKit / Health Connect integration. |
| Repository privacy | Clinician linked sleep allowed, journals denied, unlinked sleep rejected | Reuse these expectations for any Firebase repository implementation. |
| Local persistence | Shared preferences round-trip test | Add migration tests if the local schema changes from `schemaVersion: 1`. |
| Widget flow | Patient signup/import smoke test | Add route/responsiveness coverage for journal, resources, safety, and clinician views. |

## Deployment Posture

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

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
