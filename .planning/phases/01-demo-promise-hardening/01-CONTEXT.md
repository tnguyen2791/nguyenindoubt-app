# Phase 1: Demo Promise Hardening - Context

**Gathered:** 2026-07-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 preserves the current local Flutter demo and makes its promise clearer: a patient can complete onboarding, mock sleep import, dashboard review, private journaling, resources, and safety flows; a clinician can view only accepted-link sleep summaries; and users understand that mutable demo data is device-local until real auth/storage exist.

This phase does not introduce production auth, live Firebase, real HealthKit or Health Connect imports, telemetry, clinician messaging, journal sharing, or broad consent lifecycle behavior. Those are later roadmap phases.

</domain>

<decisions>
## Implementation Decisions

### Local Demo State
- **D-01:** Add an explicit local-demo state explanation where users naturally see mode and persistence, preferably in the app shell or account/demo controls rather than only in README copy.
- **D-02:** Provide a reset control for device-local demo data. Reset should clear persisted journal, import, and consent state, then restore seeded demo data without requiring users to clear browser storage manually.
- **D-03:** Keep demo state per device and do not imply sync between desktop, phone, or the GitHub Pages demo. Copy should say the demo uses local device storage until account-backed storage is implemented.

### Responsive Demo Surfaces
- **D-04:** Keep the current Material navigation pattern: bottom navigation on phone-width screens and NavigationRail on wider screens.
- **D-05:** Harden journal, resources, safety, and clinician layouts for narrow screens first. Avoid clipped text, fixed-height resource cards that hide important disclaimers, and oversized action controls that overflow.
- **D-06:** Prefer existing `BrandHeader`, `SectionCard`, `StatusPill`, and trend components over a visual redesign. Phase 1 is polish and trust hardening, not a new visual system.

### Safety Boundaries
- **D-07:** Safety actions should route outward to crisis resources rather than no-op buttons. The app should make clear it is not emergency monitoring, diagnosis, treatment, or clinician messaging.
- **D-08:** Keep 988 and emergency-care actions prominent, but use platform-safe external launch behavior and fallback copy if direct dialing cannot be supported on web.
- **D-09:** Safety copy should stay concise and action-oriented. Avoid adding in-app risk scoring, triage, crisis chat, or safety-plan features in this phase.

### Clinician Privacy Proof
- **D-10:** Clinician-facing screens should continue to receive only `PatientSleepBundle` and linked patient metadata. Journal lists or journal bodies must not be passed into clinician UI state.
- **D-11:** Clinician copy should repeatedly state the boundary in product terms: accepted invites only, sleep summaries only, journals hidden.
- **D-12:** Phase 1 verification should include tests proving the accepted-link demo flow works and that clinician journal access remains denied. Broader pending/revoked/missing link tests can be expanded in Phase 3 unless needed to prevent a Phase 1 regression.

### Claude's Discretion
- Keep implementation small and local to the existing demo surface.
- Choose copy placement and UI affordances that fit existing Material widgets.
- Add focused widget or repository tests where the change creates regression risk.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning
- `.planning/PROJECT.md` - Core value, constraints, and project posture.
- `.planning/REQUIREMENTS.md` - DEMO-01 through DEMO-05 and out-of-scope constraints.
- `.planning/ROADMAP.md` - Phase 1 goal, success criteria, dependencies, and boundary.
- `.planning/STATE.md` - Current GSD position and session continuity.

### App Surface
- `lib/main.dart` - App initialization, repository/provider creation, and shared preferences hookup.
- `lib/screens/app_shell.dart` - Onboarding, role switching, app bar, and patient navigation shell.
- `lib/screens/patient_dashboard.dart` - Mock sleep import, consent invite entry point, and patient sleep summary surface.
- `lib/screens/journal_screen.dart` - Private journal creation and display.
- `lib/screens/resources_screen.dart` - Resource cards and safety page.
- `lib/screens/clinician_dashboard.dart` - Accepted-link clinician sleep summary view.
- `lib/screens/common_widgets.dart` - Shared UI components used by Phase 1 polish.
- `lib/state/app_state.dart` - Demo session state, import, consent, journal, and clinician selection behavior.
- `lib/repositories/app_repository.dart` - Local persistence and privacy boundary.

### Data and Privacy Contract
- `lib/models/app_models.dart` - App data models, roles, consent status, summaries, journal entries, and clinician bundles.
- `lib/data/seed_data.dart` - Seed users, linked sleep data, journal entries, resources, and invite code.
- `lib/services/health_data_provider.dart` - Mock health provider and sleep summarization.
- `docs/firebase_contract.md` - Future Firebase boundary; useful for avoiding accidental live-backend implications.

### Verification
- `test/widget_test.dart` - Patient onboarding and mock import smoke flow.
- `test/repositories/app_repository_test.dart` - Clinician privacy and linked-patient repository behavior.
- `test/services/health_data_provider_test.dart` - Mock provider and sleep-summary normalization coverage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BrandHeader`, `SectionCard`, `StatusPill`, `EmptyState`, and `SleepTrendBars`: Reuse these to keep Phase 1 polish consistent with the current MVP.
- `NguyenInDoubtState`: Central place for demo reset and mode-state behavior if repository reset support is added.
- `InMemoryAppRepository`: Owns seeded data, shared preferences persistence, consent, journal, imported sleep, and clinician privacy checks.

### Established Patterns
- App state is a single `ChangeNotifier` with explicit async methods. Keep Phase 1 additions in that style.
- Local persistence is optional `SharedPreferences` JSON under `nguyenindoubt.local_demo.v1`; do not introduce a new database for Phase 1.
- Screens depend on state methods rather than direct persistence calls. Preserve that boundary.
- Clinician sleep access is guarded through accepted clinician links, and `getPatientJournalEntries` throws `PrivacyException`.

### Integration Points
- Demo reset likely connects `AppShell` or app bar controls to a new state/repository reset method.
- Safety CTA routing connects `SafetyScreen` to platform URL behavior if a dependency is already acceptable or a minimal platform-safe approach is chosen.
- Responsive hardening touches `JournalScreen`, `ResourcesScreen`, `SafetyScreen`, and `ClinicianDashboard`.
- Verification should rerun `flutter analyze`, `flutter test`, and `flutter build web`.

</code_context>

<specifics>
## Specific Ideas

- Keep the GitHub Pages demo honest: it is phone-accessible, but demo-entered data is local to each device and does not sync.
- The hardcoded invite `NID-1138` may remain in Phase 1 as a demo affordance, but copy should label it as demo-local.
- Avoid adding production compliance claims; the correct posture is "stubbed, local demo, not emergency monitoring."

</specifics>

<deferred>
## Deferred Ideas

- Production auth, signed-out sessions, and non-demo clinician role trust belong in Phase 2.
- Repository contract hardening for all pending, revoked, malformed, and missing link permutations belongs in Phase 3 unless a Phase 1 change touches that logic.
- Live Firebase Auth, Firestore adapters, emulator tests, analytics decisions, and Crashlytics decisions belong in Phase 4 or later.
- Real invite validation, revocation, consent history, and lifecycle changes belong in Phase 5.
- HealthKit and Health Connect imports belong in Phase 6.
- Public production deployment posture, retention, export, deletion, and release notes belong in Phase 7.

</deferred>

---

*Phase: 1-Demo Promise Hardening*
*Context gathered: 2026-07-06*
