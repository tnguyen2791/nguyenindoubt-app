---
phase: 10-brand-arrival-and-guided-onboarding
plan: 01
subsystem: ui
tags: [flutter, web-loader, splash, onboarding, animation]

# Dependency graph
requires: []
provides:
  - "web/index.html native fog+mark loader removed on flutter-first-frame"
  - "BrandSplashGate widget (lib/screens/brand_splash.dart) with static splashKey marker"
  - "In-memory NguyenInDoubtState.splashHasPlayed flag + markSplashPlayed()"
  - "NguyenInDoubtApp({showSplash}) test seam (default true)"
  - "All app-pumping tests pass showSplash: false"
affects:
  - "10-02 (onboarding copy rework — pumps app in tests, must use showSplash: false)"
  - "10-03 (patient first-run — same seam requirement)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Boot gate wrapping AppShell via AnimatedSwitcher cross-fade (never pop)"
    - "showSplash constructor seam for test-instant boot (zero animation machinery when disabled)"
    - "Native pre-Flutter loader removed on flutter-first-frame with defensive timeout"

key-files:
  created:
    - web/nid-brand-mark.png
    - lib/screens/brand_splash.dart
    - test/brand_splash_test.dart
  modified:
    - web/index.html
    - lib/main.dart
    - lib/state/app_state.dart
    - test/widget_test.dart
    - test/journal_delete_test.dart
    - test/clinician_affordance_test.dart

key-decisions:
  - "Splash gate lives in a dedicated lib/screens/brand_splash.dart widget (not inline in main.dart) so 10-02/10-03 never touch the gate"
  - "Disabled/already-played path returns AppShell directly with no AnimationController allocated — guarantees instant pumpAndSettle in tests"
  - "Loader uses a copied same-origin mark (web/nid-brand-mark.png) because Flutter assets are not servable pre-engine"
  - "Ember accent rendered as a thin 32px hairline under the wordmark (simple + calm over clever, per CONTEXT discretion)"

# Metrics
duration: 5min
completed: 2026-07-12
status: complete

# Verification
verification:
  - "dart format lib test — 0 changed"
  - "flutter analyze — No issues found"
  - "flutter test — 38/38 pass (36 pre-existing + 2 new), no hangs"
  - "flutter build web — succeeds; loader markup + mark present in build/web"
  - "pubspec.yaml/lock unchanged (threat T-10-01-SC verified)"
---

# Phase 10 Plan 01: Brand Arrival — Native Loader + Animated Splash Summary

**One-liner:** Cold-start now paints an on-brand fog #F6F7F1 native web loader (mark badge, removed on flutter-first-frame) and a finite ~3.5s one-shot BrandSplashGate intro that cross-fades to AppShell, guarded by an in-memory flag with a showSplash test seam.

## What Was Built

### Task 1 — Native on-brand web loader (`cd4f6c5`)
- `web/index.html` gains a static full-viewport `#nid-loader`: fog `#F6F7F1` ground, centered white badge (14px radius, echoing `NidRadius.badge`) holding a 96px brand mark with a gentle 2.4s opacity "breathe" (no bounce).
- Removal: listens for `flutter-first-frame` on `window`, fades the loader out over 400ms then detaches it; a defensive 8s timeout guarantees the user is never trapped if the event is missed.
- `web/nid-brand-mark.png` is a same-origin copy of `assets/brand/nguyenindoubt-square-mark.png` (Flutter assets are not available pre-engine).
- All markup fully static — no dynamic interpolation, no external URLs (threat T-10-01-INJ mitigated as planned). `<base href>`, meta, and bootstrap tags untouched.

### Task 2 — BrandSplashGate + flag + seam (TDD: `955aec3` RED, `6e218f2` GREEN)
- `NguyenInDoubtState.splashHasPlayed` — plain in-memory bool + `markSplashPlayed()`. Not persisted, not a counter, no analytics, no notifyListeners (the gate drives its own rebuild).
- `lib/screens/brand_splash.dart` — `BrandSplashGate(state, enabled)`:
  - `!enabled || splashHasPlayed` → returns `AppShell` directly, zero animation machinery (no controller, no timers).
  - Otherwise a single finite 3500ms `AnimationController`: BrandMark fade-in (0–40%, ease-out) + soft 0.92→1.0 bloom (15–70%), wordmark "NguyenInDoubt" in canopy fades up (55–95%) over a thin ember hairline; on completion sets the flag and `AnimatedSwitcher` cross-fades (600ms) to AppShell — never pops.
  - `BrandSplashGate.splashKey` static marker key for tests.
- `lib/main.dart` — `NguyenInDoubtApp({showSplash = true})`; `home: BrandSplashGate(state: state, enabled: showSplash)`. Production `main()` gets the splash by default.
- Core Flutter animation APIs only — no new dependencies.

### Task 3 — Test migration + splash behavior tests (`70e5cff`)
- `showSplash: false` added to all 15 app-pumping construction sites: `test/widget_test.dart` (12), `test/journal_delete_test.dart` (2 — both the empty-journal and confirming-delete sites), `test/clinician_affordance_test.dart` (1). No assertions or labels changed (renames are Plan 10-02).
- `test/brand_splash_test.dart` (2 tests): (1) skip path — onboarding reachable immediately, no splash widget; (2) play path — splash marker present pre-settle, bounded `pumpAndSettle` (15s cap) completes, signed-out onboarding shown, `splashHasPlayed` true.

## TDD Gate Compliance

RED (`955aec3` test) → GREEN (`6e218f2` feat) sequence verified in git log. RED failed for the right reason (missing `showSplash` param / `brand_splash.dart` / `splashHasPlayed`). No refactor commit needed — GREEN landed formatted and clean.

## Deviations from Plan

**1. [Task ordering] `test/brand_splash_test.dart` created in Task 2's TDD RED step, not Task 3**
- **Found during:** Task 2
- **Issue:** Task 2 is `tdd="true"`, which mandates a failing test before implementation; the plan listed the splash test file under Task 3.
- **Fix:** Wrote the two splash behavior tests as Task 2's RED commit; Task 3 verified them alongside the migrated suite. Content matches the Task 3 spec exactly.
- **Files modified:** test/brand_splash_test.dart
- **Commit:** 955aec3

No other deviations — plan executed as written.

## Verification Evidence

| Gate | Result |
|------|--------|
| Task 1 grep gate | `LOADER_OK` |
| `dart format lib test` | 0 files changed |
| `flutter analyze` | No issues found |
| `flutter test` | 38/38 pass, no hangs (suite was 36 before; +2 splash tests) |
| `flutter build web` | Succeeds; `nid-loader` markup ×7 and `nid-brand-mark.png` present in `build/web/` |
| pubspec unchanged | `git diff HEAD -- pubspec.yaml pubspec.lock` empty (T-10-01-SC) |

**Human-check (advisory, pending):** `flutter run -d chrome` on the stable port to feel the loader→splash→onboarding motion. Automated tests prove sequencing/one-shot behavior but not felt calmness. Phase config uses `human_verify_mode: end-of-phase`.

## Known Stubs

None — no placeholder data paths introduced; the loader and splash render only brand assets and the app name (T-10-01-ID accepted as planned).

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| cd4f6c5 | feat | Native on-brand web loader in index.html |
| 955aec3 | test | Failing BrandSplashGate behavior tests (TDD RED) |
| 6e218f2 | feat | BrandSplashGate + splashHasPlayed flag + showSplash seam (TDD GREEN) |
| 70e5cff | test | Migrate all 15 app-pumping test sites to showSplash: false |

## Notes for Next Plans

- 10-02/10-03 MUST pass `showSplash: false` in any new app-pumping tests (seam documented in `lib/main.dart` and `brand_splash.dart` doc comments).
- The gate wraps AppShell in `main.dart`; onboarding copy changes (10-02) do not touch the gate.
- `BrandSplashGate.splashKey` is the stable splash marker if later plans need to assert around boot.

## Self-Check: PASSED

- web/nid-brand-mark.png — FOUND
- lib/screens/brand_splash.dart — FOUND
- test/brand_splash_test.dart — FOUND
- Commits cd4f6c5, 955aec3, 6e218f2, 70e5cff — FOUND in git log
