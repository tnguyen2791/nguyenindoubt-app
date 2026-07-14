---
phase: 11
plan: fidelity-pass2
subsystem: patient-experience-ui
tags: [clinician-surface, onboarding, splash, first-run, design-fidelity]
requires: [11-DESIGN-SPEC, 11-FIDELITY-FIXES, theme-foundation-v1.1]
provides: [clinician-framing-v1.1, brand-wordmark-ember-in, onboarding-chrome-v1.1]
affects: []
tech-stack:
  added: []
  patterns: [section-label-idiom, meaning-bearing-ember-span, full-width-cta-wrap]
key-files:
  created: []
  modified:
    - lib/screens/clinician_dashboard.dart
    - lib/screens/brand_splash.dart
    - lib/screens/app_shell.dart
    - lib/screens/patient_first_run.dart
    - test/clinician_affordance_test.dart
    - test/brand_splash_test.dart
    - test/widget_test.dart
decisions:
  - "Section-label idiom (.k) extracted as a reusable _SectionLabel widget in clinician_dashboard so 'Invite status', 'Clinician visibility', and 'Worth a look' share one uppercase 11/w700 canopy +0.09em rule; the ember tail is an optional TextSpan on the same base"
  - "Brand wordmark is a keyed _BrandWordmark (RichText) so the ember 'In' is a real inline span the splash test asserts by color, not a coincidental substring"
  - "Full-width CTAs wrap FilledButton in SizedBox(width: infinity) — radius/pad/weight/min-height 50 all inherit from the pass-1 filledButton theme, no per-call restyle"
metrics:
  duration: ~20m
  completed: 2026-07-11
status: complete
---

# Phase 11 Fidelity Pass 2: Clinician Framing + Splash/Onboarding Chrome Summary

Groups D and E of the Phase 11 design-fidelity closure, built on top of the pass-1 theme foundation: the clinician surface gained its "worth a look" framing, closing humility note, `.k` section-label idiom, and a 26px person heading; the splash wordmark now carries the meaning-bearing ember "In" (decorative bar dropped); and the welcome / onboarding / first-run chrome picked up full-width CTAs, a circled back button, mint expectation-icon tiles, and corrected typography — with every coupled clinician/splash/onboarding test kept green and no privacy/safety/verbatim assert loosened.

## What was built

### Group D — Clinician surface (`clinician_dashboard.dart`)
- Added `_SectionLabel` — the design's `.k` idiom (uppercase 11px/w700 canopy, letterSpacing 0.99 ≈ 0.09em×11), with an optional ember `tail` span.
- Added the **"Worth a look · not alerts, just patterns"** label (ember tail) above the stat rows.
- Added the **closing humility note** below the visibility card: centered 12px faint, height 1.6, verbatim two-line copy ("People control exactly what you see and can pause sharing anytime." / "Readings are educational context for conversations — never a diagnosis.").
- Adopted the section-label idiom for the "Invite status" and "Clinician visibility" headers (were `titleLarge`/`titleMedium` sentence case).
- Person-detail heading 20 → 26px (w700, letterSpacing -0.39 ≈ -0.015em).
- `StatDeltaRow`, the verbatim consent disclosure, and the journal-hidden contract left untouched.

### Group E — Splash / welcome / onboarding / first-run
- **`brand_splash.dart`**: wordmark → keyed `_BrandWordmark` RichText — `Nguyen` + ember(`#C56844`) `In` + `Doubt`, all w700, letterSpacing -0.84 (-0.03em@28); dropped the decorative 32×2 ember divider bar and the now-unused `theme` local.
- **`app_shell.dart` (welcome)**: headline → canopy + -0.02em tracking (letterSpacing -0.64); "Get started" CTA full-width.
- **`app_shell.dart` (onboarding)**: back button wrapped in a 32×32 circle (white `Material`/`CircleBorder`, 1px canopy@14% border, canopy chevron, InkWell tap + tooltip); page title 28 → 26px, ink → canopy, -0.02em tracking (-0.52); "Continue" CTA full-width; expectation bullets → each icon in a 38×38 mint tile radius 11 (`NidRadius.tile`), canopy icon, label bumped to w700, gap → `NidSpace.m`.
- **`patient_first_run.dart`**: heading 20 → 24px + -0.02em tracking (-0.48); sub copy 14 ink → 13 slate (via `bodySmall` + explicit slate); CTA full-width.
- Progress dots intentionally SKIPPED (2-step flow reads odd with dots) per spec.

## Deviations from Plan
None — Groups D and E were implemented exactly to the spec's values. No auto-fixes (Rules 1-3) or architectural pauses (Rule 4) were needed.

## Coupled tests updated (no loosened privacy/safety/verbatim asserts)
- `test/clinician_affordance_test.dart` — added asserts for the "WORTH A LOOK / NOT ALERTS, JUST PATTERNS" RichText label and the two-line humility note (via `textContaining` + `scrollUntilVisible`). Every deterministic seeded stat ('6.7h', 'no prior week yet', '±0.5h', 'steady nights', '7 of 7 nights'), the 'sleep summaries only' scope framing, and the verbatim `Visible: sleep samples…` disclosure are unchanged.
- `test/brand_splash_test.dart` — added a test asserting the wordmark renders as a single `NguyenInDoubt` RichText with an ember-colored `In` span (color-checked, not substring-checked). The `splashKey` presence/absence asserts and `showSplash:false` seam are unchanged.
- `test/widget_test.dart` — the "Invite status" assertion moved from `find.text` to a RichText-span predicate (`INVITE STATUS`) to track the section-label idiom, without changing what it verifies. All onboarding copy finders ('Get started', 'Continue', 'Skip for now', 'Patient onboarding', the three expectation-bullet labels) still resolve because only styling changed, not copy. Banner-removal (`findsNothing`) and safety/crisis asserts untouched.

## Scope boundaries honored
- LOCKED-DECISION GUARDS respected: quiet slate "I'm a clinician" TextButton unchanged (still a text link, not a ghost button); stag panel + `PatientFirstRun` structure preserved; verbatim clinician/patient/safety/reset copy byte-for-byte; clinician never gains journal scope columns; Inter 400–700 only (headings top out at w700); every app-pumping test passes `showSplash: false`.
- Only Groups D and E touched — Groups A/B/C (pass 1) relied on, not modified. Pass-1 tokens/themes (`filledButtonTheme`, `textButtonTheme`, `NidRadius.tile`, `NidColors.faint/slate/ember`) reused, never redefined.
- STATE.md / ROADMAP.md untouched.
- Normal git hooks on (no `--no-verify`); files staged individually.

## Verification (all GREEN)
- `dart format lib test` → 32 files formatted, 0 changed.
- `flutter analyze` → No issues found!
- `flutter test` → All 56 tests passed (55 entering + 1 new splash-wordmark test).
- `flutter build web` → Built build/web.

## Known Stubs
None introduced. No hardcoded empty data, placeholder text, or unwired components added.

## Self-Check: PASSED
- All modified source files + this SUMMARY exist on disk.
- All three commits (28df7e4 Group D, d0ac61e Group E, 33f1884 SUMMARY) present in git log.
- STATE.md / ROADMAP.md clean (untouched). Branch: design/v1.1-experience.
