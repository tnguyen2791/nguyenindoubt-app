---
phase: 10-brand-arrival-and-guided-onboarding
plan: 02
subsystem: ui
tags: [flutter, onboarding, welcome, copy, input-guard]

# Dependency graph
requires:
  - "10-01 (showSplash test seam — all app-pumping tests pass showSplash: false)"
provides:
  - "Patient-first welcome: single primary 'Get started', quiet \"I'm a clinician\" TextButton, calm relocated disclosure"
  - "Stag top billing on narrow (mobile) layout"
  - "Appbar clinician roleLabel shortened to 'Clinician demo'"
  - "Onboarding expectation bullets (sleep / journal / guides) + name-field guard (disabled Continue, 'Skip for now' fallback)"
affects:
  - "10-03 (patient first-run — welcome vocabulary now 'Get started' / \"I'm a clinician\")"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Live-disable primary submit via controller text trim + onChanged setState"
    - "Explicit skip path routes '' through completePatientOnboarding's existing demo-name fallback"
    - "Onboarding column wrapped in SingleChildScrollView so copy growth never overflows small windows"

key-files:
  created: []
  modified:
    - lib/screens/app_shell.dart
    - test/widget_test.dart
    - test/journal_delete_test.dart
    - test/clinician_affordance_test.dart
    - test/brand_splash_test.dart

key-decisions:
  - "Hero order: primary CTA -> calm disclosure -> clinician link last (satisfies both 'below the CTAs' and 'bottom of the hero')"
  - "Clinician TextButton styled slate foreground, zero padding — quiet but a real reachable button"
  - "Guard test asserts FilledButton.onPressed null via byWidgetPredicate (FilledButton.icon returns a private subclass, so find.byType would miss it)"

# Metrics
duration: 5min
completed: 2026-07-12
status: complete

# Verification
verification:
  - "dart format lib test — 0 changed"
  - "flutter analyze — No issues found"
  - "flutter test — 39/39 pass (38 pre-existing + 1 new guard test)"
  - "flutter build web — succeeds"
---

# Phase 10 Plan 02: Patient-First Welcome + Guarded Onboarding Summary

**One-liner:** Welcome now leads with a single 'Get started' primary (clinician demo demoted to a quiet slate "I'm a clinician" text link, disclosure relocated to calm bodySmall copy, stag top-billed on mobile), and patient onboarding sets three expectations while blocking empty-name submits with an explicit 'Skip for now' demo-name fallback.

## What Was Built

### Task 1 — Patient-first welcome reframe (`56ebe50`)
- `_HeroCopy`: exactly one primary — `FilledButton.icon` labelled `Get started` wired to `onPatient`. The old `OutlinedButton` "Clinician demo override" is now a de-emphasized `TextButton` `"I'm a clinician"` (slate foreground, zero padding) at the bottom of the hero, still wired to `onClinician` → `continueAsClinicianDemo`.
- The required disclosure "Demo auth is local to this device. Firebase sign-in is not live yet." is kept verbatim but relocated below the primary CTA as `bodySmall` in `NidColors.slate` (no w600 — emotional volume lowered, not deleted).
- `_OnboardingScreen` narrow branch: `_StagPanel` now renders ABOVE `_HeroCopy` in the ListView — stag gets top billing on mobile. Wide Row layout unchanged (hero-left / stag-right).
- `_AppBar` clinician `roleLabel`: `Clinician demo override` → `Clinician demo`.
- Test migration to the new labels across `test/widget_test.dart`, `test/journal_delete_test.dart`, `test/clinician_affordance_test.dart` — plus `test/brand_splash_test.dart` (coupled, see deviations). Phone-width taps in `_expectSurfacesRenderAtSize` / `_completePatientOnboarding` gained `ensureVisible` + `pumpAndSettle` because the hero now scrolls beneath the stag at 390px.

### Task 2 — Onboarding expectations + name guard (`da96a73`)
- `_PatientOnboardingScreen` adds three one-line expectation rows (new `_ExpectationBullet` icon+label widget, bodyMedium, no bolding, single screen, no carousel) beneath the disclosure paragraph: `Sleep, privately imported` / `A journal only you can read` / `Guides, with room for doubt`. The paragraph and its test-asserted substring 'Account-backed production storage is not enabled' are untouched.
- Name guard: `trimmed = _nameController.text.trim()` computed in build; `Continue` FilledButton's `onPressed` is `null` whenever `trimmed` is empty; `TextField.onChanged` triggers `setState` so the button enables/disables live; `onSubmitted` completes only for non-empty trimmed input.
- Explicit `Skip for now` TextButton calls `widget.onComplete('')` — `completePatientOnboarding` already trims and falls back to the seeded demo name (`demoPatient.displayName`, 'Alex Rivera').
- Body wrapped in `SingleChildScrollView` (taller column would overflow 600px-tall test windows under Ahem metrics).
- New guard widget test: bullets present; Continue disabled for `''` and `'   '`; enabled for a real name; `Skip for now` lands on the patient dashboard with the demo fallback name.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `test/brand_splash_test.dart` also asserted the old 'Patient sign up' label**
- **Found during:** Task 1
- **Issue:** The plan listed three test files, but 10-01's splash test asserts the welcome CTA label three times and would break on the rename.
- **Fix:** Replaced all three `find.text('Patient sign up')` with `find.text('Get started')`.
- **Files modified:** test/brand_splash_test.dart
- **Commit:** 56ebe50

**2. [Rule 1 - Bug] Phone-width taps missed offscreen CTAs after the stag reorder**
- **Found during:** Task 1 (responsive test failed at 390×844 — tap offset y=859.5 outside the 844px viewport)
- **Issue:** Stag top billing pushes 'Get started' / "I'm a clinician" below the fold on phones; bare `tester.tap` derived an offscreen offset.
- **Fix:** `ensureVisible` + `pumpAndSettle` before those taps in `_expectSurfacesRenderAtSize` and `_completePatientOnboarding` (the settle is required for the scroll to take layout effect before `getCenter`).
- **Files modified:** test/widget_test.dart
- **Commit:** 56ebe50

**3. [Rule 2 - Missing critical] Onboarding column would overflow short windows after adding bullets + skip**
- **Found during:** Task 2
- **Issue:** The extra ~150px of bullets and the Skip button push the fixed Column past 600px test-window height under Ahem font metrics → RenderFlex overflow exceptions.
- **Fix:** Wrapped the onboarding content in `SingleChildScrollView`; guard test scrolls to `Skip for now` before tapping.
- **Files modified:** lib/screens/app_shell.dart
- **Commit:** da96a73

## Threat Model Verification

- **T-10-02-INJ (mitigate):** Input is trimmed before gating/use, empty/whitespace cannot submit (onPressed null + guarded onSubmitted), and the name renders only through Flutter `Text` — no HTML/script surface. Verified by the new guard test.
- **T-10-02-ID (accept):** Disclosure relocated/restyled but retained; 'Account-backed production storage is not enabled' substring still test-asserted; welcome disclosure kept verbatim as calm secondary copy.
- **T-10-02-EOP (accept):** "I'm a clinician" calls the same `onClinician` → `continueAsClinicianDemo` path — no new privilege.

## Verification Evidence

| Gate | Result |
|------|--------|
| Task 1 grep gate | `LABELS_OK` (Get started + I'm a clinician present) |
| `dart format lib test` | 0 files changed |
| `flutter analyze` | No issues found |
| `flutter test` | 39/39 pass (suite was 38; +1 name-guard test) |
| `flutter build web` | Succeeds |

**Human-check (advisory, pending, `human_verify_mode: end-of-phase`):** confirm the welcome reads patient-first (one primary), the clinician link is quiet but tappable, the disclosure is calm secondary text, and at phone width the stag sits above the primary action.

## Known Stubs

None — all new UI is wired to real state paths (`startPatientOnboarding`, `continueAsClinicianDemo`, `completePatientOnboarding`); no placeholder data introduced.

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| 56ebe50 | feat | Patient-first welcome: single 'Get started' primary, quiet clinician link, calm disclosure, stag top billing, test label migration |
| da96a73 | feat | Onboarding expectation bullets + name guard (disabled Continue, 'Skip for now' fallback) + guard test |

## Notes for Next Plans

- Welcome vocabulary is now `Get started` / `I'm a clinician` / appbar `Clinician demo` — 10-03 tests must use these labels (and `showSplash: false`, per 10-01).
- `_ExpectationBullet` is file-private to app_shell.dart; the 10-03 first-run widget should reuse `EmptyState`/tokens rather than this helper.
- Onboarding body is now scrollable — tests tapping near its bottom should `ensureVisible` first.

## Self-Check: PASSED

- .planning/phases/10-brand-arrival-and-guided-onboarding/10-02-SUMMARY.md — FOUND
- Commits 56ebe50, da96a73 — FOUND in git log
- Working tree clean, no unintended file deletions across the plan's commits
