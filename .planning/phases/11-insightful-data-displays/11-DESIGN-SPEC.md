# 11-DESIGN-SPEC — Ground truth from Claude Design "NguyenInDoubt — Data Displays (Oura-style)"

Source project: `d0b3eb3c-3d40-4a5a-b1d5-5ab7a8924baf`. Screens read: 18-dashboard-mobile,
15-dashboard (desktop), 20-trends-mobile, 21-sleep-detail-mobile, 28-readiness-detail-mobile,
01-metric-hero, 03-trend-bars. All values below are exact extractions.

## Screen inventory

**18-dashboard-mobile (390×844)** — Sticky top bar (wordmark 15px/700, "In" in ember; bell + 32px mint avatar).
Centered greeting block: "Good morning, Minh" (13px/600 muted) → status headline 30px/700 canopy
lh 1.12 ls -0.02em with a 9px moss dot glyph ("Ready to take on the day") → sub-line 13px muted
max-width 300px ("You recovered well overnight — a protective night and a low resting heart rate.").
Then cards in order: Readiness hero (ring 120 + 3 contributors, headnote "not a diagnosis"),
two-up Sleep/Activity minirings (104), Sleep stages hypnogram, Sleep trend · 7 nights (bars + ramp
legend). Sticky bottom tab bar (Today/Trends/+/Explore/Profile, blur white, 1px hairline top).

**15-dashboard (desktop 1200, max-width 1120, 12-col grid gap 16)** — Same hierarchy scaled:
greeting h1 26px/700 + sub 14px muted + status as a white pill (13px/600 moss, 8px dot).
col-8 Readiness hero (ring 168, 5 contributors in 110px/1fr/100px grid rows), col-4 Sleep score
ring (132, cap "protective"), col-8 hypnogram + legend, col-4 "Last night" stat rows with deltas,
col-6 Overnight HR line, col-6 Nighttime HRV line, col-7 Sleep trend bars (+ chip legend
"on target" moss / "short" ember), col-5 activity rings, col-12 consistency heatmap.

**20-trends-mobile** — h1 "Trends" 26px/700; segmented control (mint pill track, white active pill
w/ shadow 0 1 3 rgba(30,74,52,.12)): Sleep/Readiness/Activity; range chips Week/Month/Quarter
(active = canopy fill, white text). Cards: "Sleep score · 30 days" (stat row 22px/700 nums:
84 avg / 95 best / 6.9h avg sleep; area line chart 130px h, 3 horizontal gridlines
rgba(30,74,52,.07), moss 2.5px polyline + 12% moss fill + 4px end dot; date axis 10px faint);
"Weekly sleep avg" 4 bars W1-W4; "Consistency" heatmap (7-col, 5 rows, cells rounded 5px,
levels #D7E4C9/sage/moss/canopy, flag #C4633E, headnote "24 / 30 on target").

**21-sleep-detail-mobile** — Back-chevron top bar (34px white circles), title "Sleep" 15px/700 +
"Last night · Jul 7" 11px faint. Hero ring 150 (r64 stroke14) num 44px/700 "95" label "quality";
caption 14px/600 state-green "Protective night · 7h 36m asleep". Cards: Composition (22px segbar,
radius 7, 2px gaps; rows chip/name/percent/value: Deep 16% 1h 12m canopy, Light 54% 4h 05m
moss .8, REM 20% 1h 34m moss .55, Awake 10% 45m sage), Stages hypnogram, Contributors (5 rows w/
InfoTips: Total sleep optimal, Efficiency optimal, Restfulness good, Latency "a bit long" #A08B48,
Timing "on rhythm"), Overnight HR (bignum 28px "51 bpm · resting low", canopy line chart, low dot).

**28-readiness-detail-mobile** — Same shell; hero ring 150 "82 / balanced", caption
"Balanced · one contributor to watch" (14px/600 #4F7A3C). Contributors card: 6 rows — Resting HR
optimal, HRV balance good (InfoTip), Body temp good (InfoTip), Recovery index "pay attention"
#C4633E (InfoTip), Sleep balance optimal (InfoTip), Previous night good. "Resting HR vs baseline"
BaselineBand card (headnote "within range"; 20px/700 "51 bpm"; 9px mint band, sage .55 normal-range
segment left:32% right:20%, 4×17px rounded canopy-green marker at 38%; scale row 10px faint
"44 / 58 baseline / 72"). "HRV balance · 2 weeks" line card (bignum "52 ms · balanced").

**01-metric-hero (dark starfield)** — First-run/ambient variant: 126px discs, 3px thin rings on
rgba(255,255,255,.10) track, icon + 29px/600 value, 14px/500 label. Dark bg #0B120F with CSS
radial-gradient stars. Not a dashboard pattern — do not use for Today.

**03-trend-bars (isolated)** — Canonical trend-bar card: title 16px/700 + note "color = hours slept";
chart 170px h, gap 12, bar radius 9 9 6 6, value labels "7.4h" 12px/700 canopy above, day names
11px below; hairline base border; explicit scale legend row: "5h short" (#C25A3A) — gradient ramp
(#C25A3A 0% → #C0784A 22% → #B58F47 42% → #94904A 60% → #6E8544 80% → #4F7A3C 100%) — "8h+ optimal".

## Dashboard target composition (Flutter patient dashboard, WITH-DATA state)

Order top-to-bottom (mobile-first; PatientFirstRun from Phase 10 owns the empty state):
1. **Greeting block** (not a card): "Good {daypart}, {name}" 13px/600 muted → status headline
   30px/700 canopy w/ moss dot → one-sentence observational sub-line 13px muted.
2. **Hero card: Readiness/score ring + contributors** — `.k` uppercase label + headnote
   **"not a diagnosis"** (verbatim, 11px/600 faint). Ring 120 left, 3–4 ContributorBars right.
   This is THE hero readout (INS-01, INS-02). Tap → detail (if detail ships) or expands.
3. **Sleep trend · 7 nights card** — honest bars + ramp scale legend (INS-03).
4. **Insight line** — lives as the greeting sub-line AND/OR card captions (INS-04); never a
   raw-number dump.
5. Consent/clinician link: NOT in the metric row — no design screen shows sharing on Today
   (INS-01; full move is Phase 12's, Phase 11 must at minimum demote it below all metric cards).
Card chrome everywhere: white surface, 1px `--line` border, radius 16, padding 18, 14px gaps,
no shadows.

## Component specs

**ScoreRing** (SVG circle pair, rotate -90°, round caps, track = mint):
| Context | box | r | stroke | num | label |
|---|---|---|---|---|---|
| Dashboard hero (mobile) | 120 | 51 | 12 | 34px/700 ls-0.02 | 11px/600 muted |
| Detail hero | 150 | 64 | 14 | 44px/700 | 12px/600 muted |
| Mini (two-up) | 104 | 44 | 11 | 28px/700 (+11px small unit) | — |
| Desktop hero | 168 | 72 | 14 | 46px/700 | 12px/600 |
Arc: dashoffset = (1 − score/100) × 2πr. Color = state ramp value. Center: number + word-label
("balanced", "quality"). Caption below hero ring: 14px/600 in state color
("Balanced · one contributor to watch"). Explicit scale = the 0–100 number + state word +
"not a diagnosis" headnote; detail adds contributor breakdown (multi-factor evidence).

**TrendBars**: fixed-height chart area (120 mobile / 150–170 desktop), equal flex columns,
gap 8–12. Bar radius 7 7 4 4 (mobile) / 8-9 top, 5-6 bottom. Value label above each bar
10–12px/700 canopy ("7.4" mobile, "7.4h" desktop); day letter/name below 10–11px faint.
**Height = hours on a FIXED axis** (design mock ≈ linear on a ~0–9.5h window; implement honestly:
height% = hours / 9.5h axis max, no window-max normalization, no floor clamp — a 2h night renders
tiny). Color = continuous hours ramp (gradient stops above; ≥8h → #4F7A3C, ≤5h → #C25A3A).
Scale is explicit via ramp legend row ("5h short" ⟶ ramp ⟶ "8h+ optimal") and/or desktop chip
legend ("on target" moss dot, "short" ember dot). Reference line: no bar screen draws one, but
line charts use 3 horizontal gridlines rgba(30,74,52,.07); an 8h-target hairline in that gridline
style is the design-consistent way to satisfy INS-03's reference-line requirement.

**ContributorBar**: row = name (12px/600 #33413a, InfoTip dot after unfamiliar terms) + state word
right (11px/600, state color); below: 7px track, radius 99, mint bg, full-width fill in state
color. Stack gap 10–12px. State words: "optimal" #4F7A3C, "good" #6E8544 / #8C8E49,
"a bit long"/"fair" #A08B48, "pay attention" #C4633E, "on rhythm" #4F7A3C.

**BaselineBand**: header name + 20px/700 value w/ 12px unit; 9px mint strip radius 99;
sage .55 opacity segment = typical range; 4×17px radius-3 marker (state green; ember when
flagged) at today's value; scale row 10px faint: min / "N baseline" / max. Headnote e.g.
"within range".

**InfoTip**: 15px circle, mint bg, 1px hairline border, italic "i" 9px/700 canopy, 5px left
margin after metric name. Content voice: 1–2 sentences, what it is + what a change usually
means, ends reassuring (see Copy bank). Place beside HRV, Body temp, Recovery index, Sleep
balance, Efficiency, Restfulness, Latency, Timing.

**Stat/delta rows** (desktop "Last night" card; the clinician-summary idiom): name 14px/600 +
sub 12px faint; right: value 17px/700 + delta line 12px/600 moss ("+42m vs avg", "optimal",
"on rhythm") or ember when flagged ("longer than usual").

**Consistency heatmap**: 7-col grid, day letters M-T-W-T-F-S-S 10-11px faint; square cells
radius 5-6, gap 5-6; levels: empty transparent, #D7E4C9, sage, moss, canopy; flagged #C4633E.
Headnote counts: "24 / 30 on target".

**Line charts** (score trend, HR, HRV): 3 horizontal gridlines rgba(30,74,52,.07-.08); 2.5-3px
polyline moss (HRV/score) or canopy (HR), round joins; 10-12% opacity area fill; 4-5px dot on
the notable point; 10-11px faint axis labels (dates or clock times).

## Copy bank (verbatim from screens; voice = lowercase-calm, observational, no emoji)

- Headnotes: "not a diagnosis" · "color = hours" / "color = hours slept" · "trending up" ·
  "within range" · "24 / 30 on target" · "7h 36m in bed" · "lowest 3:48a" · "avg 46 ms" ·
  "healthy balance" · "hours"
- Status/insight lines: "Ready to take on the day" · "You recovered well overnight — a
  protective night and a low resting heart rate." · "Balanced · one contributor to watch" ·
  "Protective night · 7h 36m asleep"
- Delta words: "+42m vs avg" · "longer than usual" · "on rhythm" · "optimal" · "good" ·
  "a bit long" · "pay attention" · "balanced" · "quality" · "protective" · "resting low"
- Trend-bar scale: "5h short" ↔ "8h+ optimal"; desktop legend "on target" / "short"
- InfoTip examples: Efficiency — "Share of time in bed actually spent asleep. Above 85% is
  typical; one restless night barely moves it." · Latency — "How long it took to fall asleep.
  10–20 minutes is common; longer often follows late screens or caffeine." · Sleep balance —
  "Your recent sleep vs what your body typically needs — a two-week view, so one short night
  will not sink it." · HRV balance — "The tiny timing differences between heartbeats, vs your
  norm. Higher usually means rested; dips after stress recover with rest."
- Rules: states describe the METRIC, never the person ("a bit long", not "you're slow to
  sleep"); explanations name a likely benign cause; no exclamation marks; scores compare only
  to the user's own baseline.

## Mapping to INS-01..05

- **INS-01 (hierarchy, hero readout; clinician link out of metric row):** greeting-block +
  Readiness-hero-card order from 18/15-dashboard; no sharing affordance appears anywhere on
  Today in the design — consent card must sit below all metric content (full relocation is
  Phase 12; coordinate, don't collide).
- **INS-02 (retire-or-rebuild 0–100 as real multi-factor ring):** the design REBUILDS it —
  ScoreRing with center word-label, "not a diagnosis" headnote, and 3–6 ContributorBars as the
  multi-factor evidence (18-dashboard hero + 28-readiness contributors). Explicit scale =
  number + state word + contributor breakdown.
- **INS-03 (fixed hour axis, reference, honest heights):** 03-trend-bars/18/15 — fixed ~0–9.5h
  axis, value-above-bar labels, hours→color ramp with explicit "5h short ⟶ 8h+ optimal" legend;
  add the 8h-target hairline in gridline style (design gap reconciled — see surprises).
- **INS-04 (gentle observational insight line):** greeting sub-line pattern ("You recovered
  well overnight — …") + hero caption pattern ("Balanced · one contributor to watch") + delta
  words ("+42m vs avg"). Strictly descriptive; templates in Copy bank.
- **INS-05 (consistency/balance micro-insights + directional clinician summary):** Consistency
  heatmap card w/ "N / M on target" headnote (20-trends); "Last night" stat-delta rows
  (15-dashboard) are the idiom for the clinician summary — deltas + variability words, never
  "samples: 14".

## Flutter mapping notes

- Existing theme: `lib/theme/app_theme.dart` (Phase 8 established NiD tokens — verify canopy
  #1E4A34 / moss #5D7F43 / sage #A9BA92 / mint #E4EDDD / fog #F6F7F1 / ember #C56844 /
  line rgba(30,74,52,.14) / muted #54635a / faint #7a887f + state colors #4F7A3C #6E8544
  #A08B48 #C4633E exist; add any missing state-ramp stops).
- Screens to touch: `lib/screens/patient_dashboard.dart` (hierarchy + hero + trend rework;
  keep `PatientFirstRun` empty-state gate from Phase 10 intact), `lib/screens/common_widgets.dart`
  (extract ScoreRing/TrendBars/ContributorBar/InfoTip as reusable widgets — mirrors the design
  system's components/data), `lib/screens/clinician_dashboard.dart` (INS-05 directional summary,
  sleep-summaries-only), `lib/state/app_state.dart` (score computation multi-factor + insight
  string derivation, on-device only).
- Score must be computed on-device from available sleep factors (duration vs baseline,
  consistency/timing, efficiency if available) — NOT `sleepHours/8*100`. With mock-import data,
  factors derive from the seeded summaries; label it with the state word.
- CustomPaint for rings/bars/band (no chart package — keeps no-new-deps posture).
- Constraint checks: all copy above is observational and non-diagnostic ✓; no analytics ✓;
  Inter 400/500/600/700 only ✓ (design uses exactly these); motion: rings ease ~.6s, controls
  .2s, nothing pops ✓; clinician surface shows sleep summaries only ✓ (design has no clinician
  screen — apply the stat-delta idiom within existing privacy contract).
- Dark theme: tokens flip via `[data-theme="dark"]` equivalents (surface #18211A, fog #0B120F,
  canopy #8FB56A…); Flutter app is currently light-only — out of Phase 11 scope unless CONTEXT
  says otherwise.

## Surprises / decisions for CONTEXT

1. **No drawn reference line in any trend-bar screen** — the design's "explicit scale" is the
   color-ramp legend + value labels. INS-03 demands a target/average reference line: reconcile
   by drawing an 8h-target hairline styled like the line-chart gridlines (rgba(30,74,52,.07))
   with a tiny "8h" faint label. Design-consistent, requirement-satisfying.
2. **The 0–100 score is unambiguously REBUILT, not retired** — every screen leads with the ring
   + contributors ("readiness 82 balanced"). Phase 11's hot decision is answered by ground truth.
3. **Greeting/status block becomes the top of the dashboard** (not a card) — bigger reframe of
   patient_dashboard.dart than "fix the tiles": hierarchy is greeting → hero ring card →
   trend → everything else.
4. **Mock bar heights in the design are hand-tuned** (not one exact formula) — implement the
   honest fixed-axis rule (height = hours / 9.5h max), which the mocks approximate.
5. **InfoTip is load-bearing** for the education layer — contributor names need tips or the
   screen violates the DS's own "every unfamiliar marker carries an InfoTip" rule.
