---
phase: 10-brand-arrival-and-guided-onboarding
verified: 2026-07-11T20:15:00Z
status: human_needed
score: 14/15 must-haves verified
behavior_unverified: 1
overrides_applied: 0
behavior_unverified_items:
  - truth: "Cold-start (web) paints the fog #F6F7F1 ground with a centered mark and the loader is removed once Flutter's first frame paints"
    test: "Run `flutter run -d chrome` (reuse the stable port) and cold-load the app"
    expected: "The pre-Flutter paint is the fog ground + white badge + brand mark (never a blank white frame); when Flutter's first frame renders, the loader fades out (~400ms) and detaches"
    why_human: "The loader is pre-engine HTML/JS — no widget test can exercise the browser-side flutter-first-frame removal; code is present and wired (event listener + 8s defensive fallback verified by inspection), but the runtime transition is only observable in a real browser"
human_verification:
  - test: "Cold-load the app in Chrome (flutter run -d chrome, stable port)"
    expected: "Pre-Flutter paint shows the fog #F6F7F1 ground + centered brand-mark badge (not blank white); the loader fades out when Flutter's first frame paints"
    why_human: "Pre-engine browser behavior — unreachable from widget tests (PRESENT_BEHAVIOR_UNVERIFIED truth above)"
  - test: "Watch the brand-intro splash on the same cold launch"
    expected: "BrandMark fades in with a soft bloom, the NguyenInDoubt wordmark rises over a thin ember hairline (~3.5s, gentle, no bounce), then cross-fades into onboarding — plays exactly once per cold launch, never pops"
    why_human: "Sequencing/one-shot behavior is test-proven (brand_splash_test 2/2), but felt calmness of the motion is a visual-quality judgment (plan 10-01 advisory human-check, human_verify_mode: end-of-phase)"
  - test: "Look at the welcome screen at desktop and phone widths"
    expected: "Reads patient-first — one primary 'Get started'; \"I'm a clinician\" is a quiet slate text link but clearly tappable; the local-only disclosure reads as calm secondary copy; at phone width the stag sits above the hero copy/CTAs"
    why_human: "Widget order/labels/styles are code- and test-verified; whether the hierarchy *reads* patient-first and calm is visual judgment (plan 10-02 advisory human-check)"
  - test: "Sign up as a patient and view the empty dashboard, then tap 'Import sleep'"
    expected: "One calm guided hero ('Start with last night's sleep', sleep-only promise) with a single 'Import sleep' primary — no '--' tiles, no empty trend chart; after import the normal metric tiles + trend chart appear"
    why_human: "The gate and post-import transition are test-proven (widget_test first test passes); the hero's guided/calm feel is visual judgment (plan 10-03 advisory human-check)"
---

# Phase 10: Brand Arrival and Guided Onboarding Verification Report

**Phase Goal:** The first minute feels calm, branded, and guided — from cold-start to a clear first action — instead of a blank frame and a graveyard of placeholders.
**Verified:** 2026-07-11
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Merged from ROADMAP Success Criteria (4) and the three PLAN must_haves (15 detailed truths; roadmap SCs map onto them 1:1 — SC1→#1-4, SC2→#5-8, SC3→#9-11, SC4→#12-15).

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Cold-start (web) paints fog #F6F7F1 ground + centered mark; loader removed on Flutter's first frame | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `web/index.html:38-99` — static `#nid-loader` (background `#F6F7F1`, 96px `nid-brand-mark.png` in a white 14px-radius badge), `flutter-first-frame` listener + 8s defensive fallback; `web/nid-brand-mark.png` byte-identical to `assets/brand/nguyenindoubt-square-mark.png`. Runtime removal is browser-side JS — no test can exercise it; routed to human verification |
| 2 | Animated brand-intro splash plays once per cold launch, guarded by an in-memory bool (no persistence, no analytics) | ✓ VERIFIED | `lib/screens/brand_splash.dart:40-93` — finite 3500ms one-shot controller, status listener calls `markSplashPlayed()`; `lib/state/app_state.dart:38-44` plain in-memory bool (grep: zero persistence of the flag, no analytics anywhere); behavioral test `brand_splash_test.dart` "showSplash: true plays the splash once…" run standalone — PASS |
| 3 | Splash instant/skipped under widget tests via `showSplash` seam — no hangs | ✓ VERIFIED | `lib/main.dart:24-43` `showSplash = true` default → `BrandSplashGate(enabled:)`; disabled path returns `AppShell` with zero animation machinery (`brand_splash.dart:74-79`); all 16 app-pumping sites pass `showSplash: false` (widget_test ×13, journal_delete ×2, clinician_affordance ×1); skip-path test run standalone — PASS |
| 4 | Splash cross-fades out, never pops (graceful-transitions rule) | ✓ VERIFIED | `AnimatedSwitcher` 600ms fade (`brand_splash.dart:81-91`); behavioral test proves the settle lands on onboarding with the splash key gone — PASS (felt quality → human item 2) |
| 5 | Welcome leads with a single patient-first primary 'Get started' — exactly one primary button | ✓ VERIFIED | `app_shell.dart:389-393` — the only `FilledButton` in `_HeroCopy`; `widget_test.dart:28` asserts `find.text('Get started')` findsOneWidget |
| 6 | Clinician access de-emphasized to a text link ("I'm a clinician") but still enters the clinician demo | ✓ VERIFIED | `app_shell.dart:405-412` quiet slate `TextButton` → `onClinician` → `continueAsClinicianDemo` (`app_shell.dart:37-38`); tests tap "I'm a clinician" and land on the clinician dashboard (widget_test.dart:283, 317, 392) |
| 7 | Local-only disclosure present as calm secondary copy (relocated, not deleted) | ✓ VERIFIED | `app_shell.dart:397-402` — verbatim "Demo auth is local to this device…" as `bodySmall` in `NidColors.slate`, below the primary CTA (was moss w600 hero copy) |
| 8 | On narrow (mobile) layout the stag gets top billing — above hero copy/CTAs | ✓ VERIFIED | `app_shell.dart:346-356` — narrow ListView renders `_StagPanel()` before `_HeroCopy`; wide Row unchanged; responsive test at 390px passes (CTAs need `ensureVisible` scroll — consistent with stag on top) |
| 9 | Patient onboarding shows three one-line expectation bullets (sleep / journal / guides) | ✓ VERIFIED | `app_shell.dart:484-494` — 'Sleep, privately imported' / 'A journal only you can read' / 'Guides, with room for doubt'; guard test asserts all three findsOneWidget |
| 10 | Empty/whitespace name cannot submit (Continue disabled); explicit 'Skip for now' proceeds with the demo fallback name | ✓ VERIFIED | `app_shell.dart:451,512-526` — `trimmed.isEmpty` → `onPressed: null`; Skip → `onComplete('')` → `completePatientOnboarding` trims + falls back to `patientDemo.displayName` (`app_state.dart:118-124`); named test "onboarding guards the name field and offers a skip fallback" run standalone — PASS (asserts null onPressed for '' and '   ', enabled for a real name, skip lands on dashboard with `demoPatient.displayName`) |
| 11 | Onboarding disclosure keeps the substring 'Account-backed production storage is not enabled' | ✓ VERIFIED | `app_shell.dart:477` verbatim; test-asserted at `widget_test.dart:121` |
| 12 | Empty dashboard shows ONE calm guided hero with a single 'Import sleep' primary instead of '--' tiles + empty trend | ✓ VERIFIED | `patient_dashboard.dart:42-43` `state.summaries.isEmpty → PatientFirstRun`; `patient_first_run.dart` has exactly one `FilledButton`; named test "patient can sign up and import mock sleep data" run standalone — PASS |
| 13 | Guided hero states the sleep-only promise ('never your journal') as permission priming before the OS prompt | ✓ VERIFIED | `patient_first_run.dart:44-49` — "Import requests sleep-only access before anything is read — we only ever look at your sleep, never your journal."; test asserts `find.textContaining('never your journal')` in the empty state |
| 14 | '--' tiles and empty trend hidden until data; after import the normal metrics + trend appear | ✓ VERIFIED | `patient_dashboard.dart:42-127` collection-if — tiles/trend live only in the `else` branch; BrandHeader + consent card in both branches (lines 23, 129); test proves post-import 'sleep access ready' findsOneWidget and the hero findsNothing — PASS |
| 15 | First-run layer is a modular widget Phase 11 can extend | ✓ VERIFIED | `lib/screens/patient_first_run.dart` — self-contained `PatientFirstRun extends StatelessWidget`, single `state.summaries.isEmpty` gate in the dashboard, doc comment states the Phase-11 extension contract |

**Score:** 14/15 truths verified (1 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `web/index.html` loader block | fog ground + centered mark, first-frame removal | ✓ VERIFIED | Static markup only, same-origin image, no interpolation (T-10-01-INJ honored); base/meta/bootstrap untouched |
| `web/nid-brand-mark.png` | loader-visible copy of the square mark | ✓ VERIFIED | 22,493 bytes, `cmp`-identical to `assets/brand/nguyenindoubt-square-mark.png` |
| `lib/screens/brand_splash.dart` | BrandSplashGate widget | ✓ VERIFIED | 172 lines, substantive (finite controller, staged intervals, AnimatedSwitcher), wired via `main.dart` `home:` |
| In-memory `splashHasPlayed` on NguyenInDoubtState | flag + markSplashPlayed() | ✓ VERIFIED | `app_state.dart:38-44`; grep confirms no SharedPreferences/persistence of the flag |
| `NguyenInDoubtApp({showSplash})` seam | default true, tests pass false | ✓ VERIFIED | `main.dart:27,35`; 16 test construction sites pass false |
| `test/brand_splash_test.dart` | skip-path + play-once tests | ✓ VERIFIED | 2 tests, both pass standalone |
| Reworked `_OnboardingScreen`/`_HeroCopy` | patient-first welcome | ✓ VERIFIED | Single primary, quiet clinician link, calm disclosure, stag-first narrow layout |
| Reworked `_PatientOnboardingScreen` | bullets + name guard | ✓ VERIFIED | Three `_ExpectationBullet` rows, live-disabled Continue, Skip fallback, SingleChildScrollView |
| Updated CTA taps/asserts across test files | new vocabulary | ✓ VERIFIED | 'Patient sign up' / 'Clinician demo override' fully replaced by 'Get started' / "I'm a clinician" |
| Name-guard widget test | disabled/enabled/skip coverage | ✓ VERIFIED | `widget_test.dart:137-192`, passes standalone |
| `lib/screens/patient_first_run.dart` | modular PatientFirstRun | ✓ VERIFIED | 67 lines, substantive, imported + rendered by patient_dashboard |
| `patient_dashboard.dart` empty-branch wiring | isEmpty → first-run, else tiles+trend | ✓ VERIFIED | Collection-if at lines 42-127 |
| Updated `widget_test.dart` empty-state + post-import assertions | first-run vocabulary | ✓ VERIFIED | Lines 34-45, 103-104 |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `lib/main.dart` | `BrandSplashGate` | `home: BrandSplashGate(state: state, enabled: showSplash)` | ✓ WIRED | main.dart:43 |
| `web/index.html` | Flutter engine | `flutter-first-frame` listener removes loader | ✓ WIRED (code) | index.html:95; runtime observation → human item 1 |
| All app-pumping test files | splash skip | `showSplash: false` | ✓ WIRED | 16/16 construction sites |
| "I'm a clinician" TextButton | clinician demo | `onClinician` → `continueAsClinicianDemo` | ✓ WIRED | app_shell.dart:37-38, 406 |
| Continue / Skip | `completePatientOnboarding` | `onComplete` → trim + demo-name fallback | ✓ WIRED | app_shell.dart:50-51, 516, 525; app_state.dart:118-124 |
| PatientFirstRun 'Import sleep' | `state.importMockSleep` | onPressed (disabled while busy/unavailable) | ✓ WIRED | patient_first_run.dart:28-52 |
| `state.summaries.isEmpty` | first-run vs data dashboard | collection-if gate | ✓ WIRED | patient_dashboard.dart:42-44 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| PatientFirstRun | `state.isBusy`, `state.healthPermissionStatus` | NguyenInDoubtState (live listenable) | Yes | ✓ FLOWING |
| PatientDashboard else-branch | `state.summaries` → tiles + SleepTrendBars | `importMockSleep` → repository → refresh | Yes (test-proven: post-import metrics render) | ✓ FLOWING |
| BrandSplashGate | `state.splashHasPlayed` | in-memory flag set on completion | Yes (test-proven true after settle) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Splash skip + play-once state transition | `flutter test test/brand_splash_test.dart` | 2/2 passed | ✓ PASS |
| Name guard disable/enable + skip fallback | `flutter test test/widget_test.dart --plain-name "onboarding guards the name field and offers a skip fallback"` | passed | ✓ PASS |
| Empty first-run → import → metrics transition | `flutter test test/widget_test.dart --plain-name "patient can sign up and import mock sleep data"` | passed | ✓ PASS |
| Full suite / analyze / build web | orchestrator-confirmed | 39/39, analyze clean, build web succeeds | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` probes exist and none are declared by the plans — SKIPPED (not applicable).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| ONB-01 | 10-01 | Cold-start on-brand: native loader + gentle one-shot splash, no analytics | ✓ SATISFIED (loader runtime → human item 1) | Truths 1-4 |
| ONB-02 | 10-02 | Single patient-first primary; clinician de-emphasized; disclosure calm secondary | ✓ SATISFIED | Truths 5-8 |
| ONB-03 | 10-02 | Onboarding sets expectations + rejects empty/invalid names | ✓ SATISFIED | Truths 9-11 |
| ONB-04 | 10-03 | Guided empty first-run: one primary action + sleep-only priming before OS prompt | ✓ SATISFIED | Truths 12-15 |

No orphaned requirements — REQUIREMENTS.md maps exactly ONB-01..04 to Phase 10 and all four are claimed across the three plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No TBD/FIXME/XXX/TODO/HACK/placeholder markers in any phase-modified file | — | — |

Advisory (from 10-REVIEW.md, standard depth, 0 critical / 3 warning / 8 info — not phase-blocking, noted where they intersect must-haves):

- **WR-01** intersects ONB-04: `PatientFirstRun` dropped the trend card's permission StatusPill/message, so a denied/unavailable permission during the guided first-run gives no visible feedback. The must-have truths as written (single hero, priming copy, disabled button) are met; the silent-denial path is a quality gap for a follow-up.
- **WR-02** intersects ONB-04: `importMockSleep` has no error handling — the guided primary CTA can fail silently on platform exceptions (conflicts with the project's no-raw/no-silent-errors rule; pre-existing gap with raised blast radius).
- **WR-03** intersects ONB-01: the splash ignores OS reduced-motion and has no tap-to-skip (~4.1s forced intro), a gentle-motion/accessibility posture gap.

### Human Verification Required

#### 1. Native web loader in a real browser

**Test:** `flutter run -d chrome` (reuse the stable port), cold-load the app.
**Expected:** Pre-Flutter paint is the fog #F6F7F1 ground + centered brand-mark badge — never a blank white frame; the loader fades out (~400ms) when Flutter's first frame paints.
**Why human:** Pre-engine HTML/JS — no widget test can exercise the browser-side `flutter-first-frame` removal (the one PRESENT_BEHAVIOR_UNVERIFIED truth).

#### 2. Splash felt motion

**Test:** Watch the brand intro on the same cold launch.
**Expected:** Gentle mark fade + bloom, wordmark rise over the ember hairline (~3.5s, no bounce), cross-fade to onboarding, plays exactly once, never pops.
**Why human:** One-shot sequencing is test-proven; felt calmness is a visual judgment (plan 10-01 advisory check, `human_verify_mode: end-of-phase`).

#### 3. Welcome reads patient-first

**Test:** View the welcome at desktop and phone widths.
**Expected:** One primary 'Get started'; "I'm a clinician" quiet but tappable; disclosure calm secondary text; stag above the hero at phone width.
**Why human:** Labels/order/styles code-verified; whether the hierarchy *reads* right is visual (plan 10-02 advisory check).

#### 4. Guided empty first-run feel

**Test:** Sign up as a patient, view the empty dashboard, tap 'Import sleep'.
**Expected:** Single calm hero with the sleep-only promise (no '--' tiles), then normal metrics + trend after import.
**Why human:** Gate + transition test-proven; guided/calm feel is visual (plan 10-03 advisory check).

### Gaps Summary

No gaps. All 15 plan truths and all 4 roadmap Success Criteria are backed by real, substantive, wired code with behavioral tests exercising the state transitions (splash one-shot, name guard, empty-dashboard → data transition). The single non-VERIFIED item is not a gap but an untestable-by-design runtime behavior: the pre-engine web loader's removal on `flutter-first-frame`, which only a real browser session can observe — it is fully coded and wired with a defensive fallback. Four human checks remain (the loader plus three deferred visual-quality checks from the plans' end-of-phase advisory verification). Three advisory review warnings (silent permission-denial feedback, unhandled import exceptions, no reduced-motion escape) are quality follow-ups that do not falsify any must-have.

---

_Verified: 2026-07-11_
_Verifier: Claude (gsd-verifier)_
