---
phase: 11
plan: fidelity-pass1
subsystem: patient-experience-ui
tags: [theme, data-widgets, patient-dashboard, design-fidelity]
requires: [11-DESIGN-SPEC, 11-FIDELITY-FIXES]
provides: [theme-foundation-v1.1, score-ring-fidelity, dashboard-greeting-lead]
affects: [clinician-surface, onboarding, first-run]
tech-stack:
  added: []
  patterns: [single-ruler-tokens, theme-driven-buttons, banner-removal]
key-files:
  created: []
  modified:
    - lib/theme/tokens.dart
    - lib/theme/app_theme.dart
    - lib/screens/data_displays.dart
    - lib/screens/common_widgets.dart
    - lib/screens/patient_dashboard.dart
    - test/widget_test.dart
decisions:
  - "filledButtonTheme minimumSize uses Size(0,50) not Size.fromHeight(50) so inline buttons keep intrinsic width; full-width only when the caller wraps in SizedBox(width: infinity)"
  - "Coupled 'Morning check-in' asserts replaced with banner-removed (findsNothing) + first-run marker, locking the removal without loosening any privacy/verbatim assert"
metrics:
  duration: ~25m
  completed: 2026-07-11
status: complete
---

# Phase 11 Fidelity Pass 1: Theme + Data Widgets + Patient Dashboard Summary

Groups A, B, and C of the Phase 11 design-fidelity closure: raised the card-radius / button / input theme foundation to the design's exact tokens, tightened the ScoreRing / ContributorBar / SleepTrendBars geometry, and removed the BrandHeader "Morning check-in" banner so the greeting block now leads the patient dashboard — with every coupled clinician/onboarding/first-run test kept green.

## What was built

### Group A — Theme foundation (`tokens.dart`, `app_theme.dart`, `common_widgets.dart`)
- `NidRadius.card` 8 → 16; added `cardLg = 18`, `control = 14`, `tile = 11`.
- `NidSpace` added `cardPad = 18`, `cardGap = 14` (4/8/12/16/24/32 scale kept; page gutter still `l` = 16).
- `cardTheme` radius → 16, hairline border alpha 0.16 → 0.14 (== design `--line` rgba(30,74,52,.14)).
- Input `OutlineInputBorder` radius 8 → 14 on `border`/`enabledBorder`/`focusedBorder` (added the missing `enabledBorder` variant so all three read the design radius).
- Added `filledButtonTheme`: radius 14, padding v15/h18, textStyle 15/w700, min height 50.
- Added `textButtonTheme`: 13/w600, slate foreground for the quiet links.
- `SectionCard` default padding 16 → 18 (`NidSpace.cardPad`); corners resolve through `NidRadius.card`.

### Group B — Data widgets (`data_displays.dart`, `app_theme.dart`, `common_widgets.dart`)
- ScoreRing radius `((shortestSide - stroke) / 2) - 3` (51 @120); number size proportional `(size * 0.28).round()` (keeps 34 @120, `letterSpacing: -0.68`); added a 3px number→word gap.
- ContributorBar name color → new `NidColors.contributorName = Color(0xFF33413A)` (not `ink`); name→track gap 8 → 5.
- SleepTrendBars: ramp legend bar height 6 → 8, day-letter 10 → 11 (faint kept), value-label gap 4 → 6; bar radius 7/4 and axis 9.5 left unchanged (spec-sanctioned).

### Group C — Patient dashboard (`patient_dashboard.dart`)
- Removed the `BrandHeader("Morning check-in")` banner; the greeting/status block is now the top of the screen (SPEC surprise #3).
- ListView gutter 24 → horizontal 16 (vertical 16).
- Section gaps 16 → 14 (`NidSpace.cardGap`); two-up mini-card gap 12 → 14.
- Mini-card label 12/w600 → 11/w700 + `letterSpacing 0.99` (0.09em × 11).
- Greeting→status gap 8 → 10; status→sub gap 8 → 12; insight sub-line `height: 1.45`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] filledButtonTheme min-size forced infinite width on inline buttons**
- **Found during:** Group A verification (`flutter test`).
- **Issue:** The spec's `minimumSize: Size.fromHeight(50)` expands to `Size(double.infinity, 50)`, which forced infinite width on the trend-card "Import" `FilledButton.icon` sitting in an unbounded `Row`, throwing `BoxConstraints forces an infinite width`.
- **Fix:** Used `minimumSize: Size(0, 50)` — preserves the design's 50px min height and still stretches to full width when a caller wraps the button in `SizedBox(width: double.infinity)` (the spec's stated intent for welcome/onboarding/first-run CTAs), without breaking inline buttons.
- **Files modified:** `lib/theme/app_theme.dart`
- **Commit:** b1ba3e2

**2. [Rule 1 - Test] Ambiguous default Scrollable in the invite-sharing test**
- **Found during:** Group C verification (`flutter test`).
- **Issue:** With the banner gone and gaps tightened, `scrollUntilVisible(find.text('Sleep sharing consent'), 200)` now needed to actually scroll and hit `Bad state: Too many elements` — the consent card's invite `TextField` adds a second `Scrollable`, so the default single-Scrollable resolution failed.
- **Fix:** Targeted the dashboard ListView explicitly via `scrollable: find.byType(Scrollable).first`, matching the pattern already used by the sibling phone-width hierarchy test. No privacy/verbatim assertion was touched.
- **Files modified:** `test/widget_test.dart`
- **Commit:** 06b4483

## Coupled tests updated (no loosened privacy/safety asserts)
- `test/widget_test.dart` — three `find.text('Morning check-in')` asserts (signup, skip-fallback, session-restore) replaced with `findsNothing` (locks the banner removal) plus the stable first-run marker `"Start with last night's sleep"`. The invite-sharing scroll now targets the dashboard scrollable explicitly. All verbatim disclosure strings, `'Hidden: journal entries, drafts'`, `'not a diagnosis'`, `'SLEEP SCORE'`, `ScoreRing`, and safety/crisis asserts are unchanged.
- `test/data_displays_test.dart` — no edits needed: ScoreRing text asserts (`'82'`/`'balanced'`) still hold (number size stays 34 @120) and the 2h-night `closeTo(2.0/9.5)` trend anchor is untouched by the geometry changes.

## Scope boundaries honored
- Groups D (clinician surface) and E (splash/welcome/onboarding/first-run) were NOT touched — a second pass owns those.
- `BrandHeader` remains defined and in use by clinician/journal/resources screens; only the patient-dashboard call site was removed.
- LOCKED-DECISION GUARDS respected: quiet slate "I'm a clinician" TextButton unchanged, verbatim clinician/patient disclosure strings byte-for-byte, Inter 400–700 only, `showSplash: false` app-pumping preserved, no STATE.md/ROADMAP.md edits.
- Pre-existing unrelated `ios/*` working-tree modifications left untouched (out of scope).

## Verification (all GREEN)
- `dart format lib test` → 0 changed (32 files formatted, no diffs).
- `flutter analyze` → No issues found!
- `flutter test` → All 55 tests passed.
- `flutter build web` → Built build/web.

## Known Stubs
None introduced. No hardcoded empty data, placeholder text, or unwired components added.

## Self-Check: PASSED
- Modified files exist and are committed (verified below).
- All three group commits present in git log.
