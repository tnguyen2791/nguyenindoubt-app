# Phase 01: Demo Promise Hardening - Research

**Date:** 2026-07-06
**Status:** Complete

## Scope Read

Phase 1 is a demo hardening phase, not a production architecture phase. The existing Flutter MVP already demonstrates onboarding, mock sleep import, journal entry, resources/safety, and clinician sleep-only dashboard behavior. The work should preserve that baseline while making demo-local persistence, safety boundaries, responsive layout, and clinician privacy easier to trust.

## Current Implementation Findings

- `lib/main.dart` creates `SharedPreferences`, `InMemoryAppRepository`, `MockHealthDataProvider`, and `NguyenInDoubtState`.
- `lib/repositories/app_repository.dart` persists local demo JSON under `nguyenindoubt.local_demo.v1`, restores users/links/samples/journal entries, and recomputes summaries.
- `InMemoryAppRepository._seedDemoData()` already restores a clean seeded state internally, but there is no public reset API and no storage removal method.
- `NguyenInDoubtState` centralizes import, consent, journal, mode switching, and selected clinician patient behavior. A reset should be state-driven rather than called directly from widgets into preferences.
- `AppShell` keeps onboarding local to `_started`, patient screens behind bottom navigation/rail, and clinician mode as a single dashboard. Any reset that returns users to the demo starting point needs to account for `_started` or deliberately keep the user in the current demo mode with clean data.
- `ResourcesScreen` uses a fixed-aspect `GridView.count`; at one-column phone widths, `childAspectRatio: 1.65` can hide longer resource body/disclaimer copy through fade/expanded constraints.
- `SafetyScreen` has visible 988/emergency buttons, but both callbacks are no-ops.
- `ClinicianDashboard` uses `PatientSleepBundle` only and does not receive journal entries. Repository tests already prove linked sleep is readable and journal reads throw `PrivacyException`.

## Planning Implications

### Local Demo Reset

Add a narrow reset capability:

- Repository: public method to clear persisted storage and reseed in-memory users, links, samples, summaries, entries, and resources.
- State: public `resetDemoData()` that sets busy state, calls repository reset, clears selected clinician bundle, resets health permission flag, returns current user to a valid seeded demo user, refreshes, and notifies listeners.
- UI: demo-local copy plus reset affordance in the app shell/app bar, with an explicit confirmation dialog.

Verification should assert stored journals/imported sleep/consent are cleared and seeded demo state is restored.

### Safety Routing

Phase 1 needs outward routing, not emergency-monitoring features. The likely implementation path is to add `url_launcher` and route:

- `tel:988` or a web-safe 988 URL for urgent support.
- An emergency-care fallback such as `tel:911` where supported, with copy that the user should call local emergency services or go to emergency care.

If dependency additions are avoided, the fallback should at minimum show an instructional dialog instead of doing nothing. The implementation plan should let the executor choose the smallest cross-platform path, but verification must prove button activation has observable behavior.

### Responsive Surfaces

Use current Material patterns:

- Keep `NavigationBar` under 880px and `NavigationRail` above it.
- Convert resources to list-like cards on narrow widths or remove fixed-height clipping so body/disclaimer copy remains visible.
- Make `BrandHeader` trailing content wrap or stack on narrow screens if needed.
- Ensure journal mood controls and app bar demo controls do not overflow on phone widths.

Widget tests can set constrained surface sizes with `tester.binding.window` or current Flutter test APIs, pump screens, and assert no overflow exceptions and expected privacy/safety/demo copy appears.

### Clinician Privacy Proof

Preserve existing boundary:

- No clinician screen or state model should receive journal entries.
- Keep copy in clinician dashboard: accepted invites only, sleep summaries only, journals hidden.
- Add/extend tests only where Phase 1 touches code. Full pending/revoked/missing matrix belongs to Phase 3.

## Risks

- Adding a reset action without confirmation can look like destructive clinical data deletion. Copy must say "demo data" and "this device".
- Adding app bar controls can overflow at phone width. Prefer menu/icon affordance for secondary demo actions.
- Direct dial links behave differently on web, iOS simulator, Android emulator, and desktop. Provide fallback instructions and keep behavior testable through an injected launcher or small routing abstraction.
- Resource card changes can accidentally create nested cards or a visual redesign. Keep existing `SectionCard` styling.

## Verification Strategy

- `flutter analyze`
- `flutter test`
- `flutter build web`
- Widget tests for:
  - patient demo flow still works;
  - reset clears persisted journal/import/consent state;
  - safety buttons produce outward-route/fallback behavior;
  - clinician dashboard states sleep-only visibility copy and does not show journal content;
  - narrow resource/safety/journal/clinician surfaces pump without overflow exceptions.

## RESEARCH COMPLETE
