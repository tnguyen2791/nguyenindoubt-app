---
phase: 11-insightful-data-displays
reviewed: 2026-07-12T04:16:57Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/theme/app_theme.dart
  - lib/services/sleep_insights.dart
  - lib/screens/data_displays.dart
  - lib/screens/common_widgets.dart
  - lib/screens/patient_dashboard.dart
  - lib/screens/clinician_dashboard.dart
  - test/services/sleep_insights_test.dart
  - test/data_displays_test.dart
  - test/widget_test.dart
  - test/clinician_affordance_test.dart
findings:
  critical: 0
  warning: 8
  info: 6
  total: 14
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-07-12T04:16:57Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the Phase 11 Oura-style data-display work: the pure sleep-insights
scoring engine, the ScoreRing/ContributorBar/InfoTip/StatDeltaRow kit, the
fixed-axis trend bars, and the patient/clinician dashboard rebuilds, plus the
four test files. Verification pass: `flutter analyze` is clean and all 16
tests in the three phase test files pass.

The privacy seam holds: `sleep_insights.dart` imports only `app_models.dart`,
`PatientSleepBundle` carries only `patient`/`summaries`/`samples` (verified in
`lib/models/app_models.dart:249-258`), the only journal references in
clinician-reachable code are the test-asserted disclosure strings, and no
analytics/telemetry, secrets, or debug artifacts were introduced. The bar
heights below the axis are honest fractions with no floor.

The defects cluster in two places: (1) **statistical honesty at degenerate and
count-vs-calendar windows** — small windows produce confident state words and
inflated scores, "week" labels are computed over record counts rather than
date ranges, and the score InfoTip makes a claim the math directly
contradicts; (2) **chart edge behavior** — the trend chart renders an
unbounded number of bars under a "7 nights" title, and above-axis nights clamp
invisibly. InfoTip also fails basic touch-target and screen-reader
accessibility.

## Narrative Findings (AI reviewer)

### Warnings

### WR-01: Score InfoTip claims "one rough night barely moves it" — the math says the opposite

**File:** `lib/screens/patient_dashboard.dart:533-536`, `lib/services/sleep_insights.dart:161-169,230-233`
**Issue:** `_scoreTipBody` tells the user the score "compares only to your own
recent nights, so one rough night barely moves it." But the Duration
contributor is computed from **last night alone** (`window.last`,
sleep_insights.dart:162) and carries **50% of the overall score weight**
(line 231). Traced example: seven 7.5h nights score ~97 ("protective"); one
4h night appended drops duration to 0 (`100 - 3*40`), consistency to ~52
(sd ≈ 1.22), trend to ~47, overall to **~25 → "pay attention"** and the
greeting headline flips to "A short night." One rough night moves the score
by ~70 points. In a mental-health app whose stated posture is honest,
trust-preserving copy, user-facing educational text that is factually false
against the implemented math is a genuine defect, not a nit.
**Fix:** Either make the copy true (average duration over the window instead
of last-night-only, e.g. `_mean(window)` for the duration subscore, or reduce
last-night weighting), or correct the copy to describe what the score actually
does ("last night counts most, with your week's rhythm and direction behind
it"). Do one or the other — they must agree.

### WR-02: Degenerate windows emit confident descriptors — 1 night scores 95 "protective", 0 nights reads "steady nights"

**File:** `lib/services/sleep_insights.dart:172-175,181-185,347-357,373-380`
**Issue:** The trend contributor honestly neutralizes below 4 nights
(lines 181-185), but the other two contributors have no such guard:
- A window of 1-2 nights has population sd ≈ 0, so consistency reads
  **"on rhythm" at 100** (line 174) with zero evidence of rhythm.
- A single in-band night therefore scores `0.5*100 + 0.3*100 + 0.2*75 = 95`
  → **"protective"** from one night, with caption "contributors steady."
- The empty-summaries `clinicianWeekSummary` fallback hardcodes
  `variabilityWord: 'steady nights'` (line 354) — a clinician sees "steady
  nights" for a patient with **no data at all**; the same word appears for a
  1-night window (sd = 0 at line 369-373).
**Fix:** Apply the same honest-neutral pattern the trend already uses: below a
minimum window (e.g. 3 nights) give consistency a neutral word/score
("building rhythm", 75) instead of "on rhythm"/100, and make the empty/sparse
clinician fallback say "not enough nights" rather than "steady nights".

### WR-03: "Week" labels are record-count windows, not calendar windows — clinician can see "7 of 7 nights, past week" from month-old data

**File:** `lib/services/sleep_insights.dart:311-344,360-390`; `lib/screens/patient_dashboard.dart:48-56,80-84`
**Issue:** Every "week" in the module is `sublist(length - 7)` over the sorted
record list; dates are never consulted beyond ordering. Consequences:
- `nightsLabel: '${recent.length} of 7 nights'` under the clinician sub-line
  "past week" (clinician_dashboard.dart:233-238) reports "7 of 7 nights" even
  when the last 7 records span a month or the newest record is weeks old.
- `_weekDeltaMinutes` (lines 327-344) with 8 total records compares a 7-night
  mean against a **single prior night** yet labels it "vs prior week", and
  `deltaFlagged` (line 385) can raise a clinician-facing flag off that n=1
  baseline.
- The patient "7-night average" mini-card (patient_dashboard.dart:80-84) has
  the same count-based semantics.
The mock provider always emits 7 consecutive nights ending today, so tests
cannot catch this; any gapped or stale data (real HealthKit later, or a demo
user returning after a break) misreports.
**Fix:** Window by date, not count: filter summaries to
`date >= mostRecentDate - 6 days` for "recent" and the 7 days before that for
"prior"; derive `nightsLabel` from that date window so gaps honestly read
"3 of 7 nights". Guard `deltaFlagged`/"vs prior week" behind a minimum prior
count (e.g. ≥ 4 nights), otherwise say "not enough prior nights".

### WR-04: SleepTrendBars renders ALL summaries under a "Sleep trend · 7 nights" title — bar count is unbounded

**File:** `lib/screens/common_widgets.dart:259-380`; `lib/screens/patient_dashboard.dart:140`; `lib/screens/clinician_dashboard.dart:242`
**Issue:** Both call sites pass the full summaries list. The repository merges
imports and regenerates one summary per distinct night
(`saveImportedSleep`/`dedupeSleepSamples`, app_repository.dart:500-513) and
the mock provider anchors its 7-night window to `DateTime.now()` — so
importing on two different days already yields 8+ summaries, and daily use
grows without bound. The chart then renders N bars and N day letters inside
the same width: the patient card title "Sleep trend · 7 nights"
(patient_dashboard.dart:100) becomes false, value labels
(`hoursLabel` per bar) collide into unreadable overlap, and single-letter
weekday labels repeat meaninglessly past 7 bars.
**Fix:** Slice inside the widget so the honesty guarantee is self-contained:
```dart
final visible = summaries.length <= 7
    ? summaries
    : summaries.sublist(summaries.length - 7);
```
and render from `visible` everywhere (bars, labels, day letters). Add a
widget test with 9 summaries asserting 7 bars.

### WR-05: Above-axis nights clamp invisibly — a 12h night renders identical to 9.5h and reads "optimal"; its label escapes the chart

**File:** `lib/screens/common_widgets.dart:281,312-316,346-349`; `lib/theme/app_theme.dart:47-48`
**Issue:** The fixed axis is honest downward (the 2h no-floor test proves it)
but not upward: `heightFactor` clamps at 1.0 (line 313-316), so any night
above `axisMaxHours` (9.5) renders as a full bar, and
`NidStateColors.forSleepHours` clamps at 8h+ so a 12h night paints **optimal
green**. In a mental-health context oversleep/hypersomnia is exactly as
watch-worthy as short sleep, and `summarizeSleepSamples` sums all samples per
end-day (health_data_provider.dart:119-133), so real HealthKit data
(night + naps) can exceed 9.5h even though the mock never does. Additionally
the value label is positioned at `_chartHeight * heightFactor + 4` inside a
`Clip.none` stack (lines 346-349), so for bars above ~9.2h the label draws
outside the 168px chart region, overlapping the content above it.
**Fix:** Minimum: cap the label offset (`math.min(_chartHeight * heightFactor,
_chartHeight - labelHeight)`) and add an overflow affordance for above-axis
bars (e.g. a flat top / distinct treatment plus the honest label). Better:
decide explicitly whether long sleep is "optimal" — if not, extend the ramp
to descend past ~9.5h instead of clamping at green.

### WR-06: InfoTip is not accessible — 15px tap target and no semantic label

**File:** `lib/screens/data_displays.dart:220-278`
**Issue:** The tip is documented "mandatory beside metric names a newcomer
might not know," yet:
- The tappable area is the 15×15 container plus 5px padding — far below the
  48×48dp Material / 44pt iOS minimum touch target. Motor-impaired (or merely
  thumb-on-phone) users cannot reliably hit it.
- There is no `Semantics`/`Tooltip`: a screen reader announces only the
  literal glyph "i" with no indication it is a button or what it opens.
**Fix:**
```dart
child: Semantics(
  button: true,
  label: 'About ${term.toLowerCase()}',
  child: InkWell(
    customBorder: const CircleBorder(),
    onTap: _open,
    child: const SizedBox(
      width: 32, height: 32, // hit area
      child: Center(child: _InfoGlyph()), // keep the 15px visual
    ),
  ),
)
```
(Visual stays 15px; the hit target and semantics grow.)

### WR-07: Clinician invite row crashes on an empty (non-null) patient display name

**File:** `lib/screens/clinician_dashboard.dart:131`
**Issue:** `(link.patientDisplayName ?? '?').characters.first` guards null but
not the empty string — `''.characters.first` throws `StateError: No element`,
which would take down the entire clinician list. Today the invariant "names
are never empty" is enforced only at one distant call site
(`completePatientOnboarding` normalizes blank input, app_state.dart:118-121);
nothing at the model or repository layer enforces it, so any future profile
path (or persisted legacy data) reintroduces a crash here. Same fragile
assumption feeds `_firstName('')` in the greeting
(patient_dashboard.dart:156-162), which degrades to "Good morning, " rather
than crashing.
**Fix:**
```dart
final name = link.patientDisplayName?.trim() ?? '';
child: Text(name.isEmpty ? '?' : name.characters.first),
```

### WR-08: Greeting status dot is always moss-green — even beside the "A short night" attention headline

**File:** `lib/screens/patient_dashboard.dart:488-511`
**Issue:** `_GreetingBlock` receives the score `tone` but uses it only to pick
the headline text; the 9px dot beside it is hardcoded `NidColors.moss`
(line 493). The phase's own design rule is that color encodes state (the
StatusPill doc calls out "never mint-for-everything"). A green all-good dot
juxtaposed with an attention-state headline ("A short night") sends
contradictory signals in exactly the state where the display should be
coherent.
**Fix:** Encode the tone: `color: nidToneColor(tone)` (import from
data_displays), or remove the dot if it is meant to be purely decorative —
but do not pair a fixed "good" color with a state-driven headline.

### Info

### IN-01: Consistency thresholds disagree between the contributor band and the captions

**File:** `lib/services/sleep_insights.dart:174-175,296-309,371-380`
**Issue:** The contributor calls "on rhythm" only when the subscore ≥ 85,
i.e. sd ≤ 0.725 (`(2.0 - sd)/1.5*100`), while `consistencyCaption` and
`clinicianWeekSummary` use sd ≤ 0.75. For sd in (0.725, 0.75] the trend card
says "on rhythm — nights are landing close together" while the hero's
Consistency bar says "good". Narrow band, but it undercuts the "evidence
matches the label" promise.
**Fix:** Derive both from one shared threshold constant (0.75), or band the
contributor by sd directly instead of via the subscore.

### IN-02: Hand-rolled Newton sqrt to avoid `dart:math`, plus a dead initial assignment

**File:** `lib/services/sleep_insights.dart:91-113`
**Issue:** `dart:math` is a zero-cost core library — avoiding it does not
strengthen the purity claim (no Flutter, no IO, no clock) but adds 20 lines of
numerical code that must be trusted by inspection, with a fixed 24-iteration
loop. Also `double guess = variance;` (line 103) is immediately overwritten
on every path that uses it — dead assignment.
**Fix:** `import 'dart:math' as math;` and `final sd = math.sqrt(variance);`.

### IN-03: `_mean` divides by `values.length` with no empty guard

**File:** `lib/services/sleep_insights.dart:87-88`
**Issue:** All current callers guard for emptiness upstream, but `_mean(const
[])` silently returns `NaN` (Dart double division), which would propagate into
labels as "NaNh". `_populationSd` guards its own emptiness but the invariant
for `_mean` lives in four separate call sites.
**Fix:** `if (values.isEmpty) return 0;` at the top of `_mean` (matching
`_populationSd`'s defensive posture), or an `assert(values.isNotEmpty)`.

### IN-04: InfoTip attachment via string equality on the contributor name

**File:** `lib/screens/patient_dashboard.dart:555-557`
**Issue:** `score.contributors[i].name == 'Consistency'` couples the dashboard
to a string literal defined in `sleep_insights.dart:218`. Renaming the
contributor silently drops the "mandatory" educational tip — no analyzer or
test failure.
**Fix:** Give `ScoreContributor` a stable enum/id (e.g.
`ContributorKind.consistency`) and match on that; or move the tip body into
the contributor definition itself.

### IN-05: Week-trend word and bar fill can disagree

**File:** `lib/services/sleep_insights.dart:190-206`
**Issue:** The trend word is banded on `deltaMinutes` while the bar fraction
is `trendScore/100 = (100 + delta)/100`. At delta = -16m the word is "fair"
(fair tone) but the bar renders 84% full — an almost-full bar labeled "fair",
against the class doc's "the evidence always matches the label."
**Fix:** Derive the fraction from the same bands as the word (e.g. map
fair → ~0.6 region), or band the word from the score via `_bandFor` like the
other two contributors.

### IN-06: `StatusPill.color` override replaces the background but keeps the tone's foreground

**File:** `lib/screens/common_widgets.dart:214-231`
**Issue:** The documented migration shim lets a caller-supplied `color` win
over `tone.colors.background` while `foreground` still comes from the tone —
a mismatched pair can produce low-contrast text (e.g. a dark override behind
the default dark-canopy foreground). No current call site in the reviewed
files does this, but the shim invites it.
**Fix:** When `color != null`, also require/derive a foreground, or
deprecate-annotate the parameter with a removal note for Wave 2.

---

_Reviewed: 2026-07-12T04:16:57Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
