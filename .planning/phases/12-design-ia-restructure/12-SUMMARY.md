---
phase: 12
plan: 12-01
subsystem: app-shell / navigation
tags: [ia, navigation, design-buildout, shells]
status: complete
requires:
  - patient_dashboard (Today)
  - resources_screen (Explore + Safety route)
  - journal_screen (Journal sub-route)
  - clinician_dashboard (role-based entry)
provides:
  - 5-slot bottom navigation (Today · Trends · [+] · Explore · Profile)
  - TrendsScreen calm shell (P14 fills it)
  - ProfileScreen calm shell (identity + Account/Sharing/Preferences/Support + Sign out)
  - ExploreScreen (re-homed resources under Explore title)
  - Add-sheet stub (showAddSheet)
affects:
  - lib/screens/app_shell.dart
  - lib/screens/tab_shells.dart
tech-stack:
  added: []
  patterns:
    - custom bottom tab bar with a center action slot (Add is not a tab)
    - NavigationRail equivalent for wide layout
    - pushed sub-routes wrapped in AnimatedBuilder(state) to rebuild on change
key-files:
  created:
    - lib/screens/tab_shells.dart
  modified:
    - lib/screens/app_shell.dart
    - test/widget_test.dart
    - test/journal_delete_test.dart
decisions:
  - "[+] is a center canopy-filled action that opens the Add-sheet, never a selectable tab index"
  - "Trends/Profile ship as calm shells; no fake wearable data (roadmap DEFER scope call)"
  - "Journal + Safety keep no tab but stay reachable from Profile rows (Safety = standing rule)"
metrics:
  duration: ~45m
  completed: 2026-07-12
  tasks: 1
  files: 4
---

# Phase 12 Plan 01: Bottom-nav IA Restructure Summary

Restructured the patient shell from Sleep/Journal/Guides/Safety to the design's
**Today · Trends · [+] · Explore · Profile** information architecture — the
foundation for the v1.2 buildout — wiring existing screens into the new tabs and
standing up calm shells for the new ones, with all tests green.

## What was built

- **`_NidTabBar` (mobile) + `_WideNavRail` (wide)** in `app_shell.dart`, matching
  `18-dashboard-mobile`'s tab grammar: four labelled destinations (canopy active,
  faint inactive) around a center **canopy-filled [+] Add** action. The wide
  layout keeps a `NavigationRail` equivalent with the Add action as a leading pill.
- **Today** = the existing `PatientDashboard` (unchanged content).
- **Explore** (`ExploreScreen`) = the existing `ResourcesScreen` re-homed under the
  design's "Explore" title + intro line. The crisis/988 resource card is untouched.
  The full `70-explore` rebuild is deferred to P15.
- **Profile** (`ProfileScreen`) = a calm shell: canopy identity header (display-name
  initial), grouped rows for **Account / Sharing / Preferences / Support** matching
  `31-profile`'s `.group`/`.row`/chevron grammar, and an ember **Sign out** wired to
  the real auth sign-out. Journal (Preferences) and **Safety** (Support) are wired,
  reachable rows — Safety reachability is a standing project rule now that the tab
  bar drops the Safety tab.
- **Trends** (`TrendsScreen`) = a calm shell with the design's title + section
  kickers and honest "coming soon" empty states. **No fake data** (sleep-only
  reality — roadmap DEFER scope call); the real 30-day trend/heatmap arrive in P14.
- **[+] Add-sheet** (`showAddSheet`) = a bottom sheet stub matching `30-add-sheet`
  (grab handle, "Add to today", close), whose one wired action — **Import sleep** —
  reuses the existing `state.importMockSleep`. The other rows are calm placeholders.
- **Clinician** path unchanged: role-based entry still routes to `ClinicianDashboard`,
  never into the patient tab bar.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bottom tab bar stretched to full screen height**
- **Found during:** Task 1 (first test run — the Today dashboard ListView rendered
  at height 0 and the tab labels sat mid-screen at ~y=428).
- **Issue:** Under the Scaffold's loose `bottomNavigationBar` slot constraints, the
  tab bar's `Row` of `Expanded`/`Center` children reported a full-screen intrinsic
  height, collapsing the body.
- **Fix:** Wrapped the tab-bar Row in a fixed-height `SizedBox(height: 52)` so the
  bar reports a bounded intrinsic height. Body now fills correctly.
- **Files modified:** lib/screens/app_shell.dart
- **Commit:** 4a0d679

**2. [Rule 1 - Bug] Journal sub-route didn't rebuild on add/delete**
- **Found during:** Task 1 (journal_delete_test — a deleted entry still showed).
- **Issue:** Re-homing Journal from an in-shell tab to a pushed `MaterialPageRoute`
  moved it outside `AppShell`'s `AnimatedBuilder(animation: state)`, so state changes
  (delete/add) no longer rebuilt it. `JournalScreen` reads `state.journalEntries`
  directly and does not listen itself.
- **Fix:** Wrapped the pushed Journal body in `AnimatedBuilder(animation: state)`.
- **Files modified:** lib/screens/tab_shells.dart
- **Commit:** 4a0d679

### Test updates (in-scope, plan-mandated)
Updated nav-coupled tests off the old Sleep/Journal/Guides/Safety labels:
- `widget_test.dart`: `_expectSurfacesRenderAtSize` now walks Trends/Explore/Profile;
  the safety test reaches Safety via the Profile → Support row; added a dedicated
  "bottom nav exposes the …/IA" test (tabs present, old labels gone, Trends
  coming-soon, Explore re-home, Profile groups + Sign out, Journal reachable, [+]
  opens the Add-sheet with Import sleep). All privacy/safety copy assertions kept.
- `journal_delete_test.dart`: `_openJournal` now navigates Profile → Journal row.

## Verification

- `dart format lib test` — clean (only the new `tab_shells.dart` was reformatted).
- `flutter analyze` — **No issues found!**
- `flutter test` — **All tests passed** (63 baseline + 1 new nav test = 64).
- `flutter build web` — **✓ Built build/web**.

## Known Stubs

Intentional P12 shells (documented, not accidental — resolved in later phases per
the roadmap):
- `TrendsScreen` — "coming soon" empty states, no data. Filled in **P14**.
- `ProfileScreen` Account/Sharing/Support rows (except Journal + Safety, which are
  wired) — non-functional placeholders matching the design's row grammar. Wired in
  **P16/P17**.
- Add-sheet lifestyle/mood rows — disabled placeholders; only "Import sleep" is
  wired. Expanded in a later phase.

No stub blocks the P12 goal (the IA restructure itself is complete and functional).

## Self-Check: PASSED

- FOUND: lib/screens/tab_shells.dart
- FOUND: lib/screens/app_shell.dart (modified)
- FOUND commit: 4a0d679 (feat(12-01): restructure bottom nav …)
