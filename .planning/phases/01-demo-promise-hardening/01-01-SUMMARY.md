---
phase: 01-demo-promise-hardening
plan: 01
subsystem: ui
tags: [flutter, shared_preferences, privacy, safety, responsive]

requires: []
provides:
  - Device-local demo state explanation and reset flow
  - Resettable shared_preferences-backed demo repository state
  - Phone-safe journal, resources, safety, and clinician screen rendering
  - Safety CTA fallback dialogs for urgent resources
  - Clinician sleep-only privacy regression coverage
affects: [auth, privacy, firebase, consent, health-imports, production-posture]

tech-stack:
  added: []
  patterns:
    - State-driven UI actions call `NguyenInDoubtState`, which delegates persistence to `InMemoryAppRepository`.
    - Safety CTAs use explicit fallback dialogs in the demo instead of silent no-op callbacks.

key-files:
  created: []
  modified:
    - lib/repositories/app_repository.dart
    - lib/state/app_state.dart
    - lib/screens/app_shell.dart
    - lib/screens/common_widgets.dart
    - lib/screens/journal_screen.dart
    - lib/screens/resources_screen.dart
    - test/repositories/app_repository_test.dart
    - test/widget_test.dart

key-decisions:
  - "Kept safety CTA handling dependency-free for Phase 1 by showing explicit fallback instructions instead of adding a URL-launching plugin."
  - "Reset returns the active demo to the seeded patient state and clears locally persisted patient journal/import/consent mutations."
  - "Phone app bars use a compact demo-mode menu; wider layouts keep the existing segmented patient/clinician switch."

patterns-established:
  - "Demo-local destructive actions require confirmation copy that names `demo data` and `this device`."
  - "Responsive smoke tests pump the key demo surfaces at phone and desktop sizes."

requirements-completed: [DEMO-01, DEMO-02, DEMO-03, DEMO-04, DEMO-05]

coverage:
  - id: D1
    description: "Patient demo flow still supports onboarding and mock sleep import."
    requirement: DEMO-01
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#patient can sign up and import mock sleep data"
        status: pass
    human_judgment: false
  - id: D2
    description: "Device-local demo copy and reset flow clear persisted journal, imported sleep, and consent changes back to seeded state."
    requirement: DEMO-04
    verification:
      - kind: unit
        ref: "test/repositories/app_repository_test.dart#reset clears local demo changes and restores seeded state"
        status: pass
      - kind: automated_ui
        ref: "test/widget_test.dart#patient can reset local demo data"
        status: pass
    human_judgment: false
  - id: D3
    description: "Safety CTAs no longer silently no-op and show explicit urgent-resource instructions."
    requirement: DEMO-05
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#safety actions provide explicit urgent support fallback"
        status: pass
    human_judgment: false
  - id: D4
    description: "Clinician dashboard remains sleep-summary-only with journal privacy copy and no journal content."
    requirement: DEMO-02
    verification:
      - kind: unit
        ref: "test/repositories/app_repository_test.dart#clinician can read linked sleep but cannot read journals"
        status: pass
      - kind: automated_ui
        ref: "test/widget_test.dart#clinician dashboard keeps sleep-only privacy copy"
        status: pass
    human_judgment: false
  - id: D5
    description: "Journal, resources, safety, and clinician surfaces render at phone and desktop widths without overflow exceptions."
    requirement: DEMO-03
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#phase one surfaces render at phone and desktop widths"
        status: pass
    human_judgment: false
  - id: D6
    description: "Full Phase 1 verification passed through analyze, test, and web build."
    requirement: DEMO-01
    verification:
      - kind: other
        ref: "flutter analyze"
        status: pass
      - kind: other
        ref: "flutter test"
        status: pass
      - kind: other
        ref: "flutter build web"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-07-06
status: complete
---

# Phase 01: Demo Promise Hardening Summary

**Device-local demo reset, safety fallback CTAs, responsive screen hardening, and clinician sleep-only privacy coverage for the Flutter MVP**

## Performance

- **Duration:** 45 min
- **Started:** 2026-07-06T13:18:23Z
- **Completed:** 2026-07-06
- **Tasks:** 5
- **Files modified:** 8 app/test files plus planning artifacts

## Accomplishments

- Added `InMemoryAppRepository.resetDemoData()` and `NguyenInDoubtState.resetDemoData()` so the demo can clear local persisted journal/import/consent mutations and restore seeded demo state.
- Added in-app device-local demo copy and a confirmed `Reset demo data` action.
- Hardened the app shell, shared header, journal mood control, resources layout, and clinician surface for phone-width rendering.
- Replaced inert safety buttons with explicit urgent-resource fallback dialogs for 988 and emergency care.
- Expanded repository and widget tests for reset behavior, safety activation, clinician privacy copy, and responsive surface smoke coverage.

## Task Commits

No commits were made by request.

## Files Created/Modified

- `lib/repositories/app_repository.dart` - Adds repository-level demo reset.
- `lib/state/app_state.dart` - Adds state-level demo reset and clears health permission/selected clinician state.
- `lib/screens/app_shell.dart` - Adds device-local demo notice, reset confirmation, and compact phone role menu.
- `lib/screens/common_widgets.dart` - Makes `BrandHeader` stack trailing content on narrow widths.
- `lib/screens/journal_screen.dart` - Makes mood segmented control horizontally scrollable on narrow widths.
- `lib/screens/resources_screen.dart` - Uses list-style resource cards on phone width and adds safety fallback dialogs.
- `test/repositories/app_repository_test.dart` - Adds reset persistence coverage.
- `test/widget_test.dart` - Adds reset, safety, clinician privacy, and responsive smoke coverage.

## Decisions Made

- Used fallback safety dialogs instead of adding `url_launcher`, keeping Phase 1 dependency-free and avoiding platform-specific launch behavior in the public demo.
- Reset returns to the seeded patient demo state after clearing local persistence; production account/session semantics remain deferred to Phase 2.
- Resource cards switch to natural-height list cards on phone width so crisis disclaimers remain visible.

## Deviations from Plan

One planned option was narrowed: no `pubspec.yaml` or `pubspec.lock` change was needed because safety CTA fallback behavior was implemented without a new dependency. This stays within the plan's "outward routing or explicit fallback" allowance.

## Issues Encountered

- Running Flutter commands in parallel triggered a Flutter native-assets cleanup crash. Subsequent Flutter verification was run sequentially.
- `flutter analyze` and `flutter build web` initially failed on sandboxed pub.dev advisory lookups. Both passed after rerunning with approved network access.

## User Setup Required

None - no external service configuration required.

## Verification

- `flutter analyze` - passed
- `flutter test` - passed
- `flutter build web` - passed

## Next Phase Readiness

Phase 2 can build on a clearer local demo baseline: users can see and reset device-local data, safety CTAs are not inert, and clinician privacy boundaries are covered by tests. Production auth/session work remains intentionally unimplemented.

---
*Phase: 01-demo-promise-hardening*
*Completed: 2026-07-06*
