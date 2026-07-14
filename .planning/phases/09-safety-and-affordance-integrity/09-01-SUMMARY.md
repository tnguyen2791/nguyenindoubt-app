---
phase: 09-safety-and-affordance-integrity
plan: 01
subsystem: ui
tags: [flutter, url_launcher, crisis, safety, tel, sms, tdd]

# Dependency graph
requires:
  - phase: 08-design-system
    provides: tokens (NidSpace/NidColors), PillTone, BrandHeader, SectionCard, StatusPill
provides:
  - CrisisLauncher abstract seam + const UrlCrisisLauncher (canLaunchUrl-guarded)
  - SafetyScreen({launcher}) injectable constructor
  - Direct tel:988 / sms:988 / tel:911 crisis controls (no blocking dialog)
  - Graceful web/no-handler fallback (SelectableText number)
  - test/safety_screen_test.dart with a recording fake launcher
affects: [09-02, 09-03, safety, resources_screen, phase-13-motion]

# Tech tracking
tech-stack:
  added: [url_launcher ^6.3.1]
  patterns:
    - "Injectable platform seam (abstract CrisisLauncher) mirrors HealthDataProvider style so widget tests assert intent without hitting platform channels"
    - "canLaunchUrl guard + false-return-never-throw for graceful web degradation"

key-files:
  created:
    - lib/services/crisis_launcher.dart
    - test/safety_screen_test.dart
  modified:
    - pubspec.yaml
    - lib/screens/resources_screen.dart
    - test/widget_test.dart

key-decisions:
  - "Three separate honestly-labeled controls (Call 988 / Text 988 / Call 911) rather than one combined 988 control — each affordance does exactly what its label says"
  - "SafetyScreen converted to StatefulWidget to hold the inline unlaunchable-number fallback set; no toast (deferred to Phase 13)"
  - "Educational 988/911 guidance kept as inline secondary Text; verbatim non-monitoring disclosure preserved (DEMO-05)"

patterns-established:
  - "Crisis URIs are hardcoded constants; no user/remote input flows into a launched Uri"
  - "Full-app widget test asserts labels + disclosure only; never taps crisis buttons (default launcher would hit an unmocked platform channel)"

requirements-completed: [SAFE-01]

coverage:
  - id: D1
    description: "Tapping a crisis control launches tel:988 / sms:988 / tel:911 through the injected seam with no intervening AlertDialog"
    requirement: SAFE-01
    verification:
      - kind: unit
        ref: "test/safety_screen_test.dart#crisis controls launch tel/sms URIs through the seam"
        status: pass
    human_judgment: false
  - id: D2
    description: "On web / no handler the number degrades to a selectable SelectableText fallback; nothing crashes, nothing auto-dials"
    requirement: SAFE-01
    verification:
      - kind: unit
        ref: "test/safety_screen_test.dart#no handler degrades to a selectable number without crashing"
        status: pass
    human_judgment: false
  - id: D3
    description: "Educational safety copy + verbatim non-monitoring disclosure render on the Safety screen without any tap (DEMO-05 preserved)"
    requirement: SAFE-01
    verification:
      - kind: unit
        ref: "test/safety_screen_test.dart#educational and non-monitoring copy render without any tap"
        status: pass
      - kind: integration
        ref: "test/widget_test.dart#safety actions provide explicit urgent support fallback"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-07-06
status: complete
---

# Phase 9 Plan 01: Crisis actions dial/text directly Summary

**SafetyScreen crisis controls now launch tel:988 / sms:988 / tel:911 in one tap through an injectable, canLaunchUrl-guarded CrisisLauncher seam — the old explanatory AlertDialog is gone and the educational, explicitly non-monitoring copy stays inline.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-06T19:46:46Z
- **Completed:** 2026-07-06T19:52Z
- **Tasks:** 2
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments
- Added `url_launcher ^6.3.1` (flutter.dev first-party) and a thin `CrisisLauncher` seam with a const `UrlCrisisLauncher` that guards with `canLaunchUrl` and returns `false` (never throws) when no handler exists.
- Rewired `SafetyScreen` to fire the OS dialer/SMS directly via the seam — removed the "affordance lie" (button that only opened a paragraph) and the `_showSafetyInstructions` / `AlertDialog` / "Got it" path entirely.
- Kept the 988 Lifeline and 911 emergency guidance as calm inline secondary text and preserved the verbatim non-monitoring disclosure sentence (DEMO-05).
- Graceful degradation: when a launch returns `false` (web / no dialer), the number surfaces as a `SelectableText` so the user can still act — no crash, no auto-dial.
- Proven behind the seam via a new recording-fake test that never actually launches; updated the full-app safety test to assert labels + disclosure without tapping crisis buttons.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add url_launcher and injectable CrisisLauncher seam** - `1927e7f` (feat)
2. **Task 2 (RED): failing safety screen crisis-launcher tests** - `cd1401d` (test)
3. **Task 2 (GREEN): rewire SafetyScreen crisis controls to launch directly** - `c3c8551` (feat)

_TDD task 2: test (RED) → feat (GREEN); no refactor commit needed._

## Files Created/Modified
- `lib/services/crisis_launcher.dart` - Abstract `CrisisLauncher` seam + const `UrlCrisisLauncher` wrapping url_launcher with a canLaunchUrl guard.
- `pubspec.yaml` - Added `url_launcher: ^6.3.1` dependency.
- `lib/screens/resources_screen.dart` - `SafetyScreen` now `StatefulWidget` with injectable `launcher`; three direct crisis controls, inline educational copy, selectable-number fallback; dialog path deleted.
- `test/safety_screen_test.dart` - Recording fake launcher; asserts tel:988/sms:988/tel:911 requests, false-return fallback, and copy-without-tap.
- `test/widget_test.dart` - Safety test re-pointed to new labels + verbatim disclosure (scrolls to disclosure; no button taps).

## Decisions Made
- Three separate controls (Call 988 / Text 988 / Call 911) over a combined 988 control — cleaner affordance truth and simpler test intent. Within Claude's discretion per plan/CONTEXT.
- StatefulWidget with a `Set<String>` of unlaunchable numbers for the inline fallback; no toast (Phase 13).
- Emergency "Call 911" styled with `NidColors.ember` to signal urgency; weights unchanged (≤ w700).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- The verbatim non-monitoring disclosure sits below the fold in the taller Safety `ListView`, so the full-app widget test needed a `scrollUntilVisible` before asserting it (the old test relied on tapping visible buttons). Resolved within the planned test update; not a code defect.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SAFE-01 shipped and test-proven. `CrisisLauncher` seam is reusable for any future OS-handoff affordances.
- Ready for 09-02 (affordance truth on clinician invite rows) and 09-03 (journal empty state + delete), which are independent of this plan.
- Plan-level bar all green: `dart format lib test` (clean), `flutter analyze` (No issues found!), `flutter test` (30 passed), `flutter build web` (Built build/web).

## Self-Check: PASSED

- Files verified on disk: `lib/services/crisis_launcher.dart`, `test/safety_screen_test.dart`, `09-01-SUMMARY.md`.
- Commits verified in git: `1927e7f`, `cd1401d`, `c3c8551`.

---
*Phase: 09-safety-and-affordance-integrity*
*Completed: 2026-07-06*
