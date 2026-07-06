# Project Research Summary

## Key Findings

NguyenInDoubt is a Flutter MVP for a patient-facing mental-health companion with an invite-linked clinician dashboard. The core product promise is narrow and important: patients can inspect sleep context and write private journal reflections, while clinicians can see only consented sleep summaries for accepted invite links. The current implementation is intentionally local/demo-first; Firebase, telemetry, Crashlytics, and real HealthKit/Health Connect ingestion are documented seams, not live production dependencies.

The recommended stack is to keep the app Flutter-first and boundary-driven. `ChangeNotifier`, `InMemoryAppRepository`, `HealthDataProvider`, and `shared_preferences` are sufficient for the current MVP. Do not add Riverpod/BLoC, a local database, live Firestore writes, analytics, or platform health ingestion until there is a reviewed reason. Production Firebase should enter as a new repository implementation behind `AppRepository` and `ClinicianRepository`, not through direct Firestore calls in screens.

The key architectural pattern is thin screens over explicit state and repository boundaries. UI screens render state and call intent methods; `NguyenInDoubtState` coordinates app flows; repositories enforce persistence and privacy rules; health providers normalize imported health samples; Firestore rules mirror the same privacy contract. The current privacy boundary is enforced in repository methods, state shape, UI affordances, and draft Firestore rules, but repository logic and server rules are the actual security controls.

The v1 feature set should stay focused on patient onboarding, mock sleep import, sleep summary dashboard, private journal, curated resources, safety limits, invite acceptance, clinician linked-patient list, and clinician sleep-only summaries. Differentiation comes from combining sleep facts with private narrative, offering clinician collaboration without surveillance, and using explicit non-diagnostic language. Avoid clinician journal access, diagnosis/risk scoring, medication advice, emergency workflow automation, patient-clinician messaging, telemetry, broad health metric sharing, and live backend writes before review.

The highest risks are privacy regressions during Firebase migration, overly permissive clinician-link rules, confusing the demo mode switch with real authentication, premature telemetry/backends, and health-platform permission mismatch. The next roadmap should treat auth, Firestore rules, health import, telemetry, and any expansion of clinician visibility as privacy/compliance-sensitive work requiring deeper research or explicit validation.

## Implications for Roadmap

Suggested phase structure:

1. **Demo Promise Hardening** — Lock down the current MVP surface before adding infrastructure. This phase should preserve the patient sleep dashboard, private journal, resources, safety page, invite acceptance, and clinician sleep-only dashboard. It should add missing widget/route coverage for journal, resources, safety, clinician views, narrow screens, large text, and long content. It should also address obvious demo risks like empty safety button callbacks, demo-only copy, and reset-local-demo-data affordances if needed.

2. **Auth and Session Model** — Replace the placeholder patient/clinician mode switch with explicit onboarding and session states before any production backend writes. Roles should come from trusted auth/profile data, not client-side segmented controls. This phase should define signed-out, patient, clinician, selected linked patient, and optional demo override states.

3. **Privacy and Repository Contract Hardening** — Make the clinician read model impossible to misuse. Separate patient and clinician repository capabilities where practical, expand privacy regression tests for accepted, pending, revoked, and missing links, and ensure clinician code cannot request journal entries. This phase should precede or accompany Firebase work because it defines the contract the backend must match.

4. **Firebase Auth and Firestore Adapter** — Implement production storage behind existing repository interfaces. Firestore rules must enforce patient-owned journals, accepted-link sleep-only access, deterministic `clinicianLinks`, immutable parties, valid status transitions, and revoked-link denial. Add emulator tests before enabling live writes. Keep analytics, Crashlytics, and telemetry absent unless a separate compliance-reviewed decision approves them.

5. **Consent Management and Invite Lifecycle** — Move beyond hardcoded invite `NID-1138`. Add real invite validation, expiration, revocation, consent history, and clear patient-facing visibility copy. Acceptance should be atomic with link update and should not grant global consent before link validation succeeds.

6. **Real Sleep Import Providers** — Add HealthKit and Health Connect implementations behind `HealthDataProvider` after platform and compliance review. Request sleep-only access for MVP, model unavailable/not requested/partial/denied/revoked/ready states, normalize to `HealthSample`, and implement deduplication/incremental sync instead of replace-all production imports.

7. **Production Deployment Posture** — Revisit hosting, data retention, account deletion/export, incident handling, and public-demo messaging once auth, storage, consent, and health permissions are coherent. GitHub Pages remains acceptable for the local demo but should not be mistaken for account-backed production.

Research flags:

- **Needs deeper research:** Phase 2 auth/session model, Phase 4 Firebase Auth/Firestore, Phase 5 consent/invite lifecycle, Phase 6 HealthKit/Health Connect, any telemetry or clinician-visible data expansion.
- **Standard patterns are sufficient:** Phase 1 Flutter UI/test hardening and Phase 7 static demo hosting mechanics, though production deployment policy still needs review.
- **Do not expand scope in v1:** clinician journal access, diagnosis/risk scoring, medication guidance, messaging, emergency workflow automation, broad health metric sharing, and analytics/Crashlytics.

Recommended verification gates:

- `flutter pub get` after dependency changes.
- `flutter analyze` and `flutter test` before declaring implementation work complete.
- `flutter build web` before web-demo changes.
- Firestore emulator tests before enabling backend writes.
- Privacy regression tests for every phase that touches repositories, rules, consent, auth, clinician UI, or logging.

Confidence:

| Area | Confidence | Notes |
|---|---|---|
| Stack | High | Based on current repo evidence; medium only for future Firebase/health integration details because they are intentionally stubbed. |
| Features | High | Product boundary and v1/v2 split are consistent across PROJECT, README, docs, screens, state, repositories, and tests. |
| Architecture | High | Existing seams are clear and sufficient for the next phases; Firebase should replace adapters rather than reshape UI. |
| Pitfalls | High for project-specific risks, medium for platform-policy details | Local risks are directly evidenced; HealthKit, Health Connect, and Firebase policy points need phase-specific validation before implementation. |

Open gaps for planning:

- Exact Firebase Auth provider, role-claim model, account recovery, and deletion flow.
- Firestore rules transition design for `clinicianLinks`, including who can create, accept, revoke, and expire invites.
- Production consent language, audit history, and revocation UX.
- HealthKit and Health Connect permission copy, app-store/play-store declarations, denied/partial access UX, and sleep-sample deduplication.
- Whether safety actions should be wired with platform launch behavior or remain informational.
- Data retention, export, deletion, incident response, and telemetry policy.

## Sources

- `.planning/PROJECT.md`
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- `README.md`
- `pubspec.yaml`
- `pubspec.lock`
- `lib/main.dart`
- `lib/state/app_state.dart`
- `lib/repositories/app_repository.dart`
- `lib/services/health_data_provider.dart`
- `lib/models/app_models.dart`
- `lib/data/seed_data.dart`
- `lib/screens/app_shell.dart`
- `lib/screens/patient_dashboard.dart`
- `lib/screens/journal_screen.dart`
- `lib/screens/resources_screen.dart`
- `lib/screens/clinician_dashboard.dart`
- `lib/theme/app_theme.dart`
- `docs/firebase_contract.md`
- `firestore.rules`
- `firebase.json`
- `lib/firebase_options.dart`
- `test/repositories/app_repository_test.dart`
- `test/services/health_data_provider_test.dart`
- `test/widget_test.dart`
- Apple Developer HealthKit docs, Android Health Connect docs, and Firebase privacy/custom-claims docs as summarized in `.planning/research/PITFALLS.md`
