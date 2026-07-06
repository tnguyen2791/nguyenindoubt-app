# Architecture Patterns

**Domain:** Flutter mental-health companion MVP with invite-linked clinician dashboard
**Researched:** 2026-07-06
**Scope:** Current repo structure only; no external architecture research.

## Current Architecture

NguyenInDoubt is a single-process Flutter app with local demo persistence. The
composition root is `lib/main.dart`: it initializes `SharedPreferences`, creates
`InMemoryAppRepository`, injects `MockHealthDataProvider`, wraps both in
`NguyenInDoubtState`, and passes that state into `NguyenInDoubtApp`.

The app is intentionally layered but lightweight:

1. UI screens render state and call state methods.
2. `NguyenInDoubtState` coordinates role mode, loading state, repository reads,
   writes, and health imports.
3. `InMemoryAppRepository` owns demo data, local JSON persistence, consent/link
   checks, sleep summaries, and the v1 clinician privacy boundary.
4. `HealthDataProvider` is the integration seam for future HealthKit and Health
   Connect providers; the current implementation is mock-only.
5. Firebase files define the intended production boundary but are not wired into
   runtime code.

Keep this shape. The next phases should replace implementations behind existing
seams before changing screens.

## Component Boundaries

| Component | Current Files | Responsibility | Should Not Own |
|-----------|---------------|----------------|----------------|
| Composition root | `lib/main.dart` | Instantiate storage, repository, provider, app state, theme, and shell. | Auth decisions, privacy rules, feature logic. |
| App state/controller | `lib/state/app_state.dart` | Expose screen-ready state, switch patient/clinician demo mode, accept invites, import health data, add journals, select clinician patients. | Long-term persistence schema, platform health APIs, Firestore rules. |
| Repository boundary | `lib/repositories/app_repository.dart` | Store and retrieve users, links, samples, summaries, resources, journals; enforce clinician link checks; persist local demo JSON. | Widget state, navigation, platform permissions. |
| Health provider boundary | `lib/services/health_data_provider.dart` | Request health permission and return normalized `HealthSample` rows. | App-wide consent, clinician visibility, UI rendering. |
| Domain models | `lib/models/app_models.dart` | Immutable-ish value objects for users, links, health samples, summaries, journals, resources, clinician sleep bundles. | Serialization policy outside repository adapters. |
| Seed/demo data | `lib/data/seed_data.dart` | Demo users, links, resources, journal entries, and linked-patient sleep data. | Production fixtures or secrets. |
| Shell/navigation | `lib/screens/app_shell.dart` | Onboarding gate, patient/clinician mode switch, responsive patient navigation, clinician screen routing. | Auth persistence, authorization, data filtering. |
| Patient screens | `patient_dashboard.dart`, `journal_screen.dart`, `resources_screen.dart` | Render sleep, journal, guides, and safety workflows; call state commands. | Direct repository access, clinician filtering. |
| Clinician screen | `clinician_dashboard.dart` | Render accepted linked patients and sleep-only summaries. | Journal access, invite acceptance, raw storage reads. |
| Shared UI/theme | `common_widgets.dart`, `theme/app_theme.dart` | Presentational widgets and design tokens. | Business rules. |
| Production contract | `firestore.rules`, `docs/firebase_contract.md` | Document backend collections and security boundary for Firebase phase. | Runtime behavior until Firebase is explicitly integrated. |

## Data Flow

### Patient startup and local refresh

`main.dart` -> `InMemoryAppRepository(preferences)` -> restore local JSON if
available, otherwise seed demo data -> `NguyenInDoubtState.refresh()` -> patient
resources, sleep summaries, and journal entries -> `AppShell` and patient
screens via `AnimatedBuilder`.

### Patient sleep import

`PatientDashboard` import button -> `NguyenInDoubtState.importMockSleep()` ->
`HealthDataProvider.requestPermissions()` -> `fetchSleepSamples(range)` ->
`InMemoryAppRepository.saveImportedSleep()` -> replace the current user's samples
and summaries -> persist JSON -> refresh patient screen state.

### Patient journal write

`JournalScreen` save -> `NguyenInDoubtState.addJournalEntry()` ->
`InMemoryAppRepository.addJournalEntry()` -> persist JSON -> reload only the
current user's journal entries. Journal data does not pass through clinician
state or clinician screens.

### Invite acceptance and clinician read

`PatientDashboard` accept invite -> `grantPatientConsent(patient-demo,
NID-1138)` -> update user consent and matching `ClinicianLink` from pending to
accepted -> persist JSON. In clinician mode, `refresh()` calls
`getLinkedPatients(clinicianId)` and then `getPatientSleepSummary()`. The
repository returns a `PatientSleepBundle` with patient identity, sleep samples,
and daily summaries only.

## Storage Boundary

The current runtime storage boundary is local preferences under
`nguyenindoubt.local_demo.v1`. Stored JSON includes:

- `users`
- `links`
- `samples`
- `entries`

`dailySummaries` are recomputed from samples on restore, and `resourceCards` are
seeded static content. There is no server sync, no auth session, no analytics,
no Crashlytics, and no live Firebase writes.

Treat `InMemoryAppRepository` as a local adapter, not the domain model itself.
The Firebase phase should introduce a new repository implementation behind
`AppRepository` and `ClinicianRepository` instead of making screens call
Firestore directly.

## Privacy Enforcement Points

Privacy is currently enforced in four places:

1. Repository read methods:
   - `getLinkedPatients()` returns only accepted links where the patient has
     `ConsentStatus.granted`.
   - `getPatientSleepSummary()` throws `PrivacyException` unless an accepted
     clinician/patient link exists.
   - `getPatientJournalEntries()` always throws `PrivacyException`.
2. State shape:
   - Patient refresh loads `summaries` and `journalEntries`.
   - Clinician refresh loads `linkedPatients` and `selectedPatientBundle`, never
     journals.
3. UI copy and affordances:
   - Patient and clinician screens explicitly state that journals stay private.
   - Clinician dashboard has no control path for journal retrieval.
4. Firestore contract:
   - `firestore.rules` allows clinicians to read `healthSamples` and
     `dailySummaries` through `acceptedClinicianLink(patientId)`.
   - `journalEntries` are readable only by the owning patient.

The repository and Firestore rules are the real enforcement points. UI labels
are supporting clarity, not security.

## Recommended Architecture Direction

### Pattern 1: Keep Screens Thin

Screens should continue to render state and call intent methods. Put new
behavior in `NguyenInDoubtState` only when it coordinates multiple dependencies;
put durable data rules in repository implementations.

### Pattern 2: Split Demo, Local, and Production Adapters

Keep `AppRepository` and `ClinicianRepository` as contracts. Add production
adapters beside `InMemoryAppRepository` when Firebase is approved:

```dart
abstract class AppRepository {
  Future<List<ResourceCard>> getResourceCards();
  Future<List<JournalEntry>> getJournalEntries(String userId);
  Future<void> addJournalEntry(JournalEntry entry);
  Future<void> saveImportedSleep({
    required String userId,
    required List<HealthSample> samples,
  });
  Future<List<DailySummary>> getDailySummaries(String userId);
}
```

Do not put Firestore SDK calls into widgets. That would scatter privacy logic
across presentation code and make rule parity harder to test.

### Pattern 3: Model Auth Before Firebase Writes

The current patient/clinician segmented control is a demo switch. The auth phase
should introduce an explicit session/onboarding model before any production data
write path:

- signed-out/onboarding
- authenticated patient
- authenticated clinician
- selected linked patient
- local demo override, if retained

That session model should feed repository calls with the authenticated user id,
not a screen-selected id.

### Pattern 4: Normalize Health Imports at the Provider Boundary

Future HealthKit and Health Connect implementations should return the same
`HealthSample` model as the mock provider. Permission state, platform source,
metric availability, and denial/error states should be represented before data
is saved.

## Anti-Patterns to Avoid

### Firestore in Widgets

Direct Firestore calls from screens would bypass the repository privacy contract
and make it easy to accidentally expose journals or unaccepted sleep data.

### Role-Based UI as Authorization

The clinician screen currently avoids journal controls, but authorization must
remain in repositories and Firestore rules. Do not rely on hidden buttons.

### Expanding `PatientSleepBundle` Casually

This bundle is clinician-visible data. Adding mood, journal-derived summaries,
or notes to it changes the product privacy promise and should require an
explicit compliance/product decision.

### Treating `SharedPreferences` as Production Storage

The local JSON blob is suitable for demo state only. It has no cross-device sync,
server-side authorization, audit trail, or revocation guarantees.

## Recommended Build Order for Upcoming GSD Phases

1. **Auth and session model**
   - Replace the placeholder mode switch with explicit onboarding/session state.
   - Keep demo mode available only as a controlled path.
   - Do this before Firebase writes so user ids and roles are coherent.

2. **Privacy-preserving repository contract hardening**
   - Add tests around all patient/clinician read paths, revoked links, missing
     links, and journal denial.
   - Consider separating repository interfaces by caller capability so clinician
     code cannot even request patient journals.

3. **Responsive route and widget coverage**
   - Expand widget tests for journal, resources, safety, and clinician layouts.
   - This is low infrastructure risk and protects the current UX while backend
     seams change.

4. **Firebase adapter behind existing repositories**
   - Implement Auth-backed user/session lookup and Firestore-backed
     repositories.
   - Keep `firestore.rules` and repository tests in parity.
   - Do not enable telemetry by default.

5. **Real health providers**
   - Add HealthKit and Health Connect implementations behind
     `HealthDataProvider`.
   - Preserve normalized `HealthSample` output and explicit permission/error
     states.

6. **Production deployment posture**
   - Move beyond the temporary public GitHub Pages demo after auth, storage,
     privacy review, and health permissions are coherent.

## Scalability Considerations

| Concern | Current Demo | Next Production Shape |
|---------|--------------|-----------------------|
| State management | Single `ChangeNotifier` is adequate. | Keep until flows become deeply nested; only then consider Provider/Riverpod. |
| Persistence | One local preferences JSON blob. | Repository adapters backed by Firebase Auth and Firestore. |
| Privacy | Enforced in repository tests and Firestore rules draft. | Enforce in repository, server rules, tests, and compliance review. |
| Health data | Mock provider returns sleep samples. | Platform providers normalize to `HealthSample` and handle permission denial. |
| Clinician dashboard | Reads one selected patient's sleep bundle. | Add pagination/query limits before large panels or multi-clinician groups. |
| Telemetry | None. | Keep absent until compliance-reviewed; prefer explicit, minimal diagnostics. |

## Phase Research Flags

| Phase Topic | Research Need | Reason |
|-------------|---------------|--------|
| Firebase Auth and Firestore | High | Sensitive health-adjacent and journal data require rule parity, identity model, and compliance review. |
| HealthKit and Health Connect | High | Platform permissions, store review language, background access, and metric differences need dedicated research. |
| Journal privacy | Medium | Any sharing/export/summarization feature could alter the v1 privacy promise. |
| Responsive UI coverage | Low | Existing Flutter patterns are straightforward; main work is test coverage. |
| GitHub Pages demo | Low | Already working as static web deployment; production posture is the real decision. |

## Sources

- `.planning/PROJECT.md`
- `lib/main.dart`
- `lib/state/app_state.dart`
- `lib/repositories/app_repository.dart`
- `lib/services/health_data_provider.dart`
- `lib/models/app_models.dart`
- `lib/screens/app_shell.dart`
- `lib/screens/patient_dashboard.dart`
- `lib/screens/journal_screen.dart`
- `lib/screens/clinician_dashboard.dart`
- `lib/screens/resources_screen.dart`
- `test/repositories/app_repository_test.dart`
- `test/services/health_data_provider_test.dart`
- `test/widget_test.dart`
- `firestore.rules`
- `docs/firebase_contract.md`
