---
phase: 08-design-system-foundations
plan: 03
subsystem: ui
tags: [flutter, design-system, brandmark, pilltone, tokens, theme]

# Dependency graph
requires:
  - phase: 08-01
    provides: NidSpace/NidRadius tokens, PillTone enum, StatusPill tone API, BrandMark widget, blessed theme
provides:
  - journal_screen migrated to PillTone (private/neutral) and NidSpace
  - resources/safety screen migrated to PillTone (flag/neutral); last StatusPill color override retired
  - app_shell using the single BrandMark for all three logo appearances (34/82/64px), tokenized spacings/radii
  - Wave 2 complete — zero FontWeight.w800/w900 across lib/
affects: [future ui phases, v1.1-experience surfaces]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Semantic pill tone at every call-site (no raw color overrides)"
    - "Single BrandMark framed lockup for every logo appearance"
    - "NidSpace/NidRadius as the one spacing/corner ruler; emphasis weight capped at w700"

key-files:
  created: []
  modified:
    - lib/screens/journal_screen.dart
    - lib/screens/resources_screen.dart
    - lib/screens/app_shell.dart

key-decisions:
  - "Tie-break spacing rounds up (10->NidSpace.m, 14->NidSpace.l, 20->NidSpace.xl, 28->NidSpace.xxl) for a calmer, more generous rhythm"
  - "AppBar logo now the framed BrandMark(size:34) badge, replacing the raw 34px ClipRRect radius-6 tile"

patterns-established:
  - "Pattern 1: StatusPill state is expressed only via tone: — color: override is fully retired app-wide"
  - "Pattern 2: Every logo appearance routes through BrandMark; no raw Image.asset brand tiles remain"

requirements-completed: [DS-01, DS-02, DS-03, DS-04, DS-05]

coverage:
  - id: D1
    description: "Journal/resources/safety pills pass semantic PillTone (private/neutral/flag); no StatusPill color override remains"
    requirement: DS-03
    verification:
      - kind: unit
        ref: "test/widget_test.dart#safety actions provide explicit urgent support fallback"
        status: pass
      - kind: other
        ref: "grep -L 'color:' StatusPill call-sites; grep PillTone.flag/private/neutral present"
        status: pass
    human_judgment: false
  - id: D2
    description: "Single BrandMark replaces the three raw logo treatments in app_shell (34px AppBar, 82px hero, 64px onboarding)"
    requirement: DS-05
    verification:
      - kind: unit
        ref: "test/widget_test.dart#phase one surfaces render at phone and desktop widths"
        status: pass
    human_judgment: true
    rationale: "Visual lockup quality (framed badge vs muddy raw tile) is an aesthetic judgment the tests cannot assert"
  - id: D3
    description: "No FontWeight above w700 in the three screens; Wave 2 phase-completion sweep clean across lib/"
    requirement: DS-01
    verification:
      - kind: other
        ref: "grep -rEn 'FontWeight\\.w(800|900)' lib/ | grep -v '//' -> empty"
        status: pass
    human_judgment: false
  - id: D4
    description: "Freehand paddings/gaps/radii on the three screens reference NidSpace/NidRadius"
    requirement: DS-02
    verification:
      - kind: other
        ref: "grep NidSpace present in each of the three files; flutter analyze clean"
        status: pass
    human_judgment: false
  - id: D5
    description: "Reset-demo and safety dialogs render on blessed dialogTheme with no stray stock color; copy verbatim"
    requirement: DS-04
    verification:
      - kind: unit
        ref: "test/widget_test.dart#patient can reset local demo data"
        status: pass
    human_judgment: false

# Metrics
duration: 18min
completed: 2026-07-06
status: complete
---

# Phase 08 Plan 03: Wave-2 Call-Site Sweep (Journal / Resources / App Shell) Summary

**Journal, resources/safety, and app shell migrated to semantic PillTone, the single BrandMark lockup (34/82/64px), and NidSpace/NidRadius tokens — retiring the app's last StatusPill color override and closing out Wave 2 with zero heavy weights in lib/.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-07-06T18:59Z
- **Completed:** 2026-07-06T19:18Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Journal pills now encode privacy state (`clinician hidden` -> `PillTone.private`, entry mood -> `PillTone.neutral`); emphasis caption de-weighted to themed `labelSmall`; spacings tokenized.
- Resources category pill migrated to `PillTone.flag`/`PillTone.neutral`, retiring the **last** `StatusPill(color:)` override in the app; SafetyScreen `988 / 911` pill kept calm (`PillTone.neutral`); disclaimer dropped from `w800` to themed `labelSmall`.
- App shell now uses the single `BrandMark` for all three logo appearances — `BrandMark(size: 34)` in the AppBar (killing the raw muddy ClipRRect radius-6 tile), `size: 82` in the hero, `size: 64` in patient onboarding — with demo-notice/hero emphasis softened to `w600` and paddings/gaps/radii swept onto `NidSpace`/`NidRadius`.
- Wave 2 phase-completion gate clean: `grep -rEn 'FontWeight\.w(800|900)' lib/` returns nothing across the whole tree.

## Task Commits

Each task was committed atomically:

1. **Task 1: Sweep journal_screen.dart** - `4e535ca` (feat)
2. **Task 2: Sweep resources_screen.dart (retire last color override)** - `9045086` (feat)
3. **Task 3: Sweep app_shell.dart (one BrandMark)** - `22c954c` (feat)

## Files Created/Modified
- `lib/screens/journal_screen.dart` - PillTone.private/neutral, de-weighted caption, NidSpace spacings
- `lib/screens/resources_screen.dart` - PillTone.flag/neutral (last color override retired), de-weighted disclaimer, NidSpace list/grid/gap spacings
- `lib/screens/app_shell.dart` - single BrandMark for AppBar/hero/onboarding, w600 emphasis, NidSpace/NidRadius sweep

## Decisions Made
- Spacing tie-breaks round up (10→`NidSpace.m`, 14→`NidSpace.l`, 20→`NidSpace.xl`, 28→`NidSpace.xxl`) for a calmer, more generous rhythm consistent across all three files.
- Remaining `color:` references in resources_screen are the crisis Icon color and disclaimer text foreground — not StatusPill overrides; these are intentional and correct.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Verification
- `dart format lib test` - no changes (clean).
- `flutter analyze` - No issues found!
- `flutter test` - all 27 tests pass (demo-notice, onboarding, reset-dialog, safety copy intact).
- `flutter build web` - release web build succeeded (BrandMark + theme changes survive tree-shaken release build).
- Phase-completion: `grep -rEn 'FontWeight\.w(800|900)' lib/ | grep -v '//'` returns nothing.

## Next Phase Readiness
- Wave 2 of the design-system foundation is complete: all patient/clinician/journal/resources/safety/app-shell surfaces now consume the tokens, semantic pill tones, and single BrandMark.
- No blockers. StatusPill's optional `color:` param is now unused by any call-site and could be removed in a future cleanup if desired.

## Self-Check: PASSED

All three modified files and the SUMMARY exist on disk; all three task commits (`4e535ca`, `9045086`, `22c954c`) are present in git history.

---
*Phase: 08-design-system-foundations*
*Completed: 2026-07-06*
