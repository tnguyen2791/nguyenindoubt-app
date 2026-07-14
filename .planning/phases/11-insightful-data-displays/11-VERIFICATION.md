---
phase: 11-insightful-data-displays
verified: 2026-07-12T00:00:00Z
status: human_needed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Import mock sleep on the patient dashboard and read the with-data screen top to bottom at phone width"
    expected: "Reads greeting/status -> score ring hero ('not a diagnosis' visible, ring eases in ~0.6s, nothing pops) -> two mini-cards -> honest trend with a visible 8h hairline aligned to the bar region and the '5h short -> 8h+ optimal' ramp legend -> consent card at the very bottom; nothing about sharing appears above the consent card; short nights visibly render shorter"
    why_human: "Visual hierarchy quality, hairline-to-bar-region alignment, and animation gentleness are appearance judgments grep/widget-tests cannot make (plans 11-01/11-02 deferred these as end-of-phase human checks)"
  - test: "Enter the clinician demo and open the accepted patient detail"
    expected: "Detail card shows Avg sleep with a delta line ('6.7h' / 'no prior week yet'), a variability descriptor ('±0.5h' / 'steady nights'), and 'Nights with data' ('7 of 7 nights' / 'sleep summaries only') — no bare sample count; honest ramp trend bars below; unchanged 'Visible: sleep samples...' disclosure"
    why_human: "Stat-delta idiom legibility and layout at desktop width is a visual judgment (plan 11-03's deferred end-of-phase human check)"
  - test: "Tap the 'i' InfoTips on 'SLEEP SCORE' and the Consistency contributor row"
    expected: "A calm dialog opens with plain-language copy and a 'Got it' button, fading gently in/out; the tip is findable and tappable"
    why_human: "Dialog feel and the tiny 15px tap-target usability (flagged as WR-06) need a finger on a device, not a widget test"
---

# Phase 11: Insightful Data Displays Verification Report

**Phase Goal:** Data surfaces deliver Oura-grade insight — hierarchy, honest charts, and gentle observations — instead of raw, redundant numbers.
**Verified:** 2026-07-12
**Status:** human_needed (all 5 success criteria verified in code; visual-quality checks remain for a human)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria — the contract)

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | Dashboard has a clear hero readout; no connection toggle as a co-equal health metric | ✓ VERIFIED | `patient_dashboard.dart` build order: BrandHeader (no trailing sharing pill) -> `_GreetingBlock` -> `_ScoreHeroCard` -> mini-card Row -> trend SectionCard -> consent card last (lines 20-38, 58-151). `grep -i 'quality proxy\|clinician link'` finds nothing; `_MetricTile` gone; tests pin `QUALITY PROXY`/`CLINICIAN LINK` findsNothing (widget_test.dart:54-55) |
| 2   | 0-100 measure rebuilt as a real, multi-factor, non-diagnostic score shown as a ring with an explicit scale | ✓ VERIFIED | `computeSleepScore` (sleep_insights.dart:147-273): 3 contributors (Duration vs 7-9h band, Consistency via population sd, Week trend with <4-night honest neutral), weighted 0.5/0.3/0.2; `ScoreRing` + 3 `ContributorBar`s + state word + caption on the hero; verbatim 'not a diagnosis' headnote (patient_dashboard.dart:582), test-pinned findsOneWidget; 9 deterministic unit tests pass |
| 3   | Trend bars use a fixed hour axis with a target reference line and honest heights (no window-max normalization, no floor clamp) | ✓ VERIFIED | `SleepTrendBars` (common_widgets.dart:259-423): `axisMaxHours = 9.5`, `heightFactor = (hours/9.5).clamp(0.0, 1.0)` — 1.0 upper bound is the only clamp; no window-max fold, no `.clamp(0.25` anywhere; 8h hairline at 8/9.5 of the 168px bar region + faint '8h' label; ramp color via `NidStateColors.forSleepHours`; regression test asserts a 2h bar renders `closeTo(2.0/9.5, 0.001)` (data_displays_test.dart:118-122) — ran and passed |
| 4   | A gentle, strictly-observational insight line (last-night-vs-baseline) is present and never labels the person | ✓ VERIFIED | Exactly one insight line: `insightLine(state.summaries)` as the greeting sub-line (patient_dashboard.dart:62); copy is metric-descriptive ('Last night ran +{m}m vs your recent average.'), calm <2-night fallback, no emoji/exclamations, headlines describe the night ('A short night'), never the person; phone-width test pins one 'vs your recent average' findsOneWidget |
| 5   | Consistency/balance micro-insights and a directional clinician summary replace raw counts like "samples" | ✓ VERIFIED | Patient: `consistencyCaption` micro-insight under the trend bars (patient_dashboard.dart:144-147). Clinician: `_ClinicianMetric` class and the raw samples tile deleted; `clinicianWeekSummary(summaries)` feeds 3 `StatDeltaRow`s (clinician_dashboard.dart:190, 217-238); detail no longer reads `bundle.samples` at all; test 'clinician summary is directional, never a raw sample count' pins `SAMPLES` findsNothing + '6.7h'/'no prior week yet'/'±0.5h'/'steady nights'/'7 of 7 nights' — ran and passed. The only remaining 'samples' mentions are the verbatim consent disclosures (disclosure, not a metric) |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified — all behavior-bearing truths are exercised by the 16 phase tests, independently re-run green)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/theme/app_theme.dart` | NidStateColors (4 state colors), NidColors.faint, forSleepHours ramp | ✓ VERIFIED | Exact hexes per spec (#4F7A3C/#6E8544/#A08B48/#C4633E, faint #7A887F); piecewise `Color.lerp` ramp (lines 17-56) |
| `lib/services/sleep_insights.dart` | Pure module: StateTone, ScoreContributor, SleepScore, ClinicianWeekSummary, computeSleepScore, insightLine, consistencyCaption, weekDeltaLabel, clinicianWeekSummary | ✓ VERIFIED | All 9 symbols present; sole import is `../models/app_models.dart`; grep confirms no Flutter/dart:io/DateTime.now/JournalEntry — the privacy seam holds by signature |
| `lib/screens/data_displays.dart` | ScoreRing, ContributorBar, InfoTip, StatDeltaRow, nidToneColor | ✓ VERIFIED | All present; zero `Color(0x` hex literals (all colors theme-sourced); TweenAnimationBuilder 600ms ring ease; dialog with 'Got it' |
| `lib/screens/common_widgets.dart` | Honest SleepTrendBars rewrite | ✓ VERIFIED | Read in full (lines 259-423) — fixed axis, hairline, ramp, legend, dayLetter; empty-state 'No sleep samples yet' branch unchanged; signature unchanged so both dashboards picked it up |
| `lib/screens/patient_dashboard.dart` | Rebuilt with-data hierarchy; PatientFirstRun gate untouched | ✓ VERIFIED | `state.summaries.isEmpty` gate intact (line 31); `patient_first_run.dart` has zero diff across all 6 phase commits; `_ConsentLifecycleCard` copy present ('Only sleep summaries and samples become visible...', 'Visible after acceptance: ...') |
| `lib/screens/clinician_dashboard.dart` | StatDeltaRow directional summary; raw tiles removed | ✓ VERIFIED | Verbatim disclosure grep -F exact match = 1; no `'samples'` label literal, no `_ClinicianMetric` |
| `test/services/sleep_insights_test.dart` | Deterministic unit coverage | ✓ VERIFIED | 9 tests, ran green |
| `test/data_displays_test.dart` | Widget kit + honest-height regression anchor | ✓ VERIFIED | 5 tests incl. the 2h/9.5 closeTo anchor, ran green |
| `test/widget_test.dart` | Migrated assertions + phone-width hierarchy test | ✓ VERIFIED | Additive migration; privacy/consent/reset-dialog assertions untouched; phone-width test present (390x844, showSplash: false) |
| `test/clinician_affordance_test.dart` | Directional-summary regression | ✓ VERIFIED | New test present; pre-existing SAFE-02 test untouched, both ran green |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| patient_dashboard.dart | sleep_insights.dart | computeSleepScore/insightLine/consistencyCaption/weekDeltaLabel | ✓ WIRED | Calls at lines 46, 62, 83, 145 — results rendered, not discarded |
| patient_dashboard.dart | data_displays.dart | ScoreRing/ContributorBar/InfoTip/nidToneColor | ✓ WIRED | Hero card composes all four (lines 550-596) |
| clinician_dashboard.dart | sleep_insights.dart | clinicianWeekSummary(bundle.summaries) | ✓ WIRED | Line 190; no `bundle.samples` read remains — privacy surface shrank |
| clinician_dashboard.dart | data_displays.dart | StatDeltaRow x3 | ✓ WIRED | Lines 217-238, all fields fed from `week` |
| SleepTrendBars height | hours / 9.5 fixed axis | FractionallySizedBox heightFactor | ✓ WIRED | Line 312-316; upper bound 1.0 only |
| data_displays tone colors | NidStateColors in theme | nidToneColor switch | ✓ WIRED | No hex literals in widget files |
| sleep_insights.dart | app_models.dart ONLY | import statement | ✓ WIRED | Single import — the privacy seam is grep-verifiable |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| _ScoreHeroCard | score (SleepScore) | computeSleepScore(state.summaries) <- repository summaries | Yes (deterministic against mock durations, unit-tested) | ✓ FLOWING |
| SleepTrendBars | summaries | state.summaries / bundle.summaries (consent-gated) | Yes | ✓ FLOWING |
| Clinician StatDeltaRows | week (ClinicianWeekSummary) | clinicianWeekSummary(bundle.summaries) | Yes (seeded 7 nights -> '6.7h', '±0.5h', test-pinned) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Score math, insight strings, clinician summary deterministic | `flutter test test/services/sleep_insights_test.dart test/data_displays_test.dart test/clinician_affordance_test.dart` | 16/16 passed (independent re-run) | ✓ PASS |
| Honest-height regression (2h night has no floor) | included above — closeTo(2.0/9.5) assertion | passed | ✓ PASS |
| Full suite / analyze / build web | orchestrator-confirmed: flutter analyze clean, flutter test 55/55, flutter build web succeeds | green | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| INS-01 | 11-02 | Hierarchy — one hero readout; connection state out of the metric row | ✓ SATISFIED | SC1 evidence above |
| INS-02 | 11-01, 11-02 | Real multi-factor on-device non-diagnostic score as an Oura-style ring with explicit scale | ✓ SATISFIED | SC2 evidence above |
| INS-03 | 11-01 | Fixed hour axis, target reference line, honest heights | ✓ SATISFIED | SC3 evidence above |
| INS-04 | 11-02 | Gentle observational insight line, never labels the person | ✓ SATISFIED | SC4 evidence above |
| INS-05 | 11-01, 11-02, 11-03 | Micro-insights + directional clinician summary replace raw counts | ✓ SATISFIED | SC5 evidence above |

No orphaned requirements: REQUIREMENTS.md maps exactly INS-01..05 to Phase 11 and all five are claimed across the three plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No TBD/FIXME/XXX/TODO/HACK/placeholder markers in any phase-modified file; no stub returns; pubspec.yaml unmodified | — | — |

### Advisory Findings (review warnings weighed against the success criteria — none falsify an SC)

The orchestrator asked specifically whether WR-01/02/03/05 break SC3 or SC4. Assessment, code-confirmed:

1. **WR-01 — Score InfoTip copy contradicts the math (ADVISORY, highest priority follow-up).** Confirmed in code: `_scoreTipBody` (patient_dashboard.dart:533-536) says "one rough night barely moves it," while Duration is computed from `window.last` alone (sleep_insights.dart:161) at 0.5 weight — one 4h night after seven 7.5h nights moves the score ~70 points. This copy was mandated verbatim by plan 11-02 (the plan-level inconsistency, faithfully executed). It does NOT falsify SC2 (the score is genuinely real, multi-factor, non-diagnostic, with an explicit scale) or SC4 (the insight line is a separate, accurate string), but it is a factually false user-facing claim on a reachable surface in a trust-focused app. **Recommend fixing before ship** (either average the duration window or correct the copy) — a one-line copy change is the cheapest true fix.
2. **WR-02 — Degenerate windows emit confident descriptors (ADVISORY).** Confirmed: no minimum-window guard on Duration/Consistency; empty-summaries clinician fallback hardcodes 'steady nights'. Unreachable in the current demo (mock import and clinician seed are always exactly 7 nights; the only linked patient has data), so no SC is falsified on any reachable path. Latent honesty defect for real HealthKit data later.
3. **WR-03 — Count-based, not date-based, "week" windows (ADVISORY).** Confirmed: all windows are `sublist`-by-count. Single-session demo behavior is correct and deterministic; multi-day demo use (re-import on a later day) can label an n=1 baseline "vs prior week." SC5 asks that a directional summary *replace raw counts* — it does; window semantics are a correctness follow-up, not an SC breaker.
4. **WR-05 — >9.5h nights clamp to full optimal-green bars (ADVISORY).** SC3's explicit prohibitions are window-max normalization and the 0.25 floor clamp — both verifiably deleted. The 1.0 upper bound was a locked phase decision (CONTEXT INS-03: "bar height = hours / axis-max", plan must-have: "upper-bounded at 1.0 only") and is unreachable with demo data (max 7.9h). Oversleep treatment is a real design question for the HealthKit milestone.
5. Also carried as follow-ups: WR-04 (unbounded bar count under a "7 nights" title on multi-day imports), WR-06 (InfoTip 15px tap target / no Semantics — folded into human check #3), WR-07 (empty-display-name crash guard), WR-08 (greeting dot always moss). None touch an SC.

Suggested routing: fold WR-01 (and optionally WR-02/03/08) into a small follow-up plan or Phase 12/13 pre-work; none block phase closure.

### Human Verification Required

#### 1. Patient dashboard visual pass (phone width)

**Test:** Import mock sleep; read the with-data dashboard top to bottom on a phone-width window.
**Expected:** Greeting/status -> score ring hero ('not a diagnosis' visible, ring eases in gently) -> two mini-cards -> honest trend with the 8h hairline visually aligned to the bar region and the '5h short -> 8h+ optimal' legend -> consent card last; no sharing affordance above it; short nights visibly shorter.
**Why human:** Oura-grade hierarchy quality, hairline alignment, and motion gentleness are appearance judgments; the plans deferred these as end-of-phase human checks.

#### 2. Clinician detail visual pass

**Test:** Enter the clinician demo, open the accepted patient.
**Expected:** Stat-delta rows ('6.7h' + 'no prior week yet', '±0.5h' + 'steady nights', '7 of 7 nights' + 'sleep summaries only'), no bare sample count, honest ramp bars, unchanged 'Visible: sleep samples...' disclosure.
**Why human:** Stat-delta idiom legibility/layout at desktop width.

#### 3. InfoTip interaction feel

**Test:** Tap the 'i' next to 'SLEEP SCORE' and next to the Consistency contributor.
**Expected:** Calm dialog with plain-language copy and 'Got it'; comfortably tappable.
**Why human:** Dialog feel plus the WR-06 tap-target concern (15px visual, small hit area) need a real finger/device.

### Gaps Summary

No gaps. All five ROADMAP success criteria are observably true in the codebase, all plan must-have truths hold, all key links are wired with real data flowing, all five INS requirements are satisfied, and the behavior-bearing claims are pinned by 16 phase tests (independently re-run green) within a 55/55 suite with clean analyze and a successful web build. The eight review warnings were each weighed against the success criteria: none falsifies one; WR-01 (InfoTip copy contradicting the 50% last-night weighting) is the one reachable-in-demo defect and should be fixed as a fast follow-up before or alongside Phase 12.

---

_Verified: 2026-07-12_
_Verifier: Claude (gsd-verifier)_
