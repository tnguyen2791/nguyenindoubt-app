# Phase 11: Insightful Data Displays - Context

**Gathered:** 2026-07-11
**Status:** Ready for planning
**Source:** Synthesized from the v1.1 design critique (data-viz/insights lens) + REQUIREMENTS INS-01–05 + the Claude Design ground truth ("NguyenInDoubt — Data Displays (Oura-style)", project `d0b3eb3c-3d40-4a5a-b1d5-5ab7a8924baf`), distilled into `11-DESIGN-SPEC.md` (MUST READ before planning)

<domain>
## Phase Boundary

Rebuild the data surfaces in the image of the design project: the patient dashboard gains Oura-grade hierarchy (greeting/status → one hero readout → secondary metrics → honest trend → gentle insight), the fake 0–100 "quality proxy" becomes a real multi-factor non-diagnostic score ring, trend bars become honest with a fixed hour axis and target line, and the clinician dashboard's raw counts become a directional summary.

In scope: `lib/screens/patient_dashboard.dart` (with-data state; Phase 10's `PatientFirstRun` owns the empty state and is untouched), `lib/screens/clinician_dashboard.dart` (stat row + summary only), new data-display widgets (ring, trend bars, contributor rows, baseline band, info-tip), the on-device score computation in state/services, and the coupled tests.

Out of scope (later phases / deferred): the full sharing surface (Phase 12 — this phase only RELOCATES the consent/link affordance out of the metric hierarchy); motion choreography beyond existing gentle fades (Phase 13); dark theme (tokens exist in the design; the app ships light-only this milestone — deferred, keep widget code theme-token-driven so dark can land later); the Explore/education tab (design has it; not in INS scope).
</domain>

<decisions>
## Implementation Decisions (locked against the design ground truth)

### INS-01 — dashboard hierarchy
- **Today composition (with data), top to bottom:** greeting/status block (13px/600 muted hello → 30px/700 canopy status headline with a moss status dot → one-sentence observational sub-line) → **Score hero card** (ring + contributors, see INS-02) → two-up secondary metric mini-cards → sleep trend card → consent/sharing card LAST and visually quiet.
- **The clinician link/consent affordance leaves the metric hierarchy.** It is not a health metric and must not read as one. Phase 11 moves it to a demoted, calm placement at the bottom of the dashboard; Phase 12 builds the real sharing surface. Keep all consent copy verbatim (test-asserted privacy strings).
- No sharing/clinician affordance inside the greeting, hero, or metric cards — the design's Today screen has none.

### INS-02 — the score: REBUILD as a real ring (design ground truth answers the retire-vs-rebuild question)
- Replace the `sleepHours/8*100` "quality proxy" tile with a **multi-factor, on-device, non-diagnostic score** rendered as the design's ScoreRing: mint track, state-colored rounded arc (`--state-optimal/good/fair/attention` ramp), hero size ~120px stroke ~12, center = big number (34–46px/700, tight tracking) + state word ("balanced"), caption 14px/600 in the state color (e.g. "Balanced · one contributor to watch").
- **Contributors are the multi-factor evidence**, shown as 3 ContributorBar rows beside/below the ring (name left, colored state word right, thin filled track). Compute from data already on device — locked factor set: **duration vs target** (7–9h band), **consistency/rhythm** (bedtime/duration variability across the window), **week trend** (this-week vs prior average). No new data collection, no network, no new dependencies.
- **Explicit scale + humility:** the number, its state word, the contributor rows, and a "not a diagnosis" headnote on the hero card. States describe the metric, never the person.

### INS-03 — honest trend bars
- Fixed hour axis (0 to ~9.5h) — bar height = hours / axis-max. **No window-max normalization, no 0.25 floor clamp** (delete both behaviors).
- **8h-target hairline** across the chart in the design's gridline style (`rgba(30,74,52,.07)` at 1px, label "8h" in faint 10px). The design mocks carry no reference line — this is the locked reconciliation that satisfies INS-03 while staying in the design's visual grammar.
- Value labeled above each bar (10–12px/700, canopy), single-letter day labels below (10px faint), bar top radius ~7–9px, color = continuous hours→state ramp with the design's legend treatment ("short ⟶ optimal").
- Implement the honest-height rule, not the mock's hand-tuned pixel heights.

### INS-04 — gentle observational insight line
- One insight line on the dashboard (in the greeting sub-line or under the trend — planner's call, exactly one), computed on device: last-night-vs-baseline or week-over-week. Use the copy bank in `11-DESIGN-SPEC.md` verbatim-or-close ("+42m vs avg", "longer than usual", "on rhythm").
- Strictly descriptive of the metric; never labels the person; no streaks, no guilt, no emoji, no exclamation marks. When there isn't enough data for a comparison, say something calm and factual, never an error.

### INS-05 — micro-insights + directional clinician summary
- Patient side: consistency/balance micro-insights replace any raw-count framing (e.g. the trend card gains "on rhythm" / "+42m vs avg" captions).
- Clinician side: replace the raw `samples` count stat with the desktop stat-delta idiom (17px/700 value + 12px/600 delta words): **avg duration + delta vs prior week, variability descriptor, nights-with-data** — directional, non-diagnostic, within the existing privacy contract (sleep summaries only; the "Visible: sleep samples, daily summaries, trend flags." consent copy stays VERBATIM — it is disclosure, not a metric).
- **InfoTips are mandatory** on metric names a newcomer might not know (the score, "consistency", "baseline"): a small "i" affordance opening a 1–2 sentence plain-language card that ends on reassurance, never a warning. Close educational popovers with the design's humility voice.

### Claude's Discretion
- Exact score formula weights within the locked factor set (keep it explainable — each contributor's state word must follow from its own data).
- Widget decomposition and file layout for the new data-display widgets (a `lib/widgets/data/` or extension of `common_widgets.dart` — match repo conventions).
- Flutter InfoTip mechanics (popover vs bottom-sheet on mobile width) — gentle fade in/out either way.
- Insight-line placement (greeting sub-line vs trend caption) and final copy within the voice rules.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/11-insightful-data-displays/11-DESIGN-SPEC.md` — the distilled ground truth (screen inventory, exact geometry/typography/color per component, copy bank, INS mapping, Flutter mapping notes). The Claude Design project is the pixel-level source of truth; the spec is its local distillation.
- `lib/theme/app_theme.dart` — `NidColors` already matches the design tokens hex-for-hex (fog/canopy/moss/sage/mint/ember/ink). Add the four `--state-*` colors (`#4F7A3C`, `#6E8544`, `#A08B48`, `#C4633E`) here; do not hardcode in widgets.
- Design tokens (already read; values in the spec): type scale (`--fs-score:34px`, `--fs-greeting:30px`, labels 11px/700 uppercase +0.09em), shape (`--r-card:16px`, `--sp-card:18px`, `--sp-gap:14px`), no card shadows.

### Files this phase edits
- `lib/screens/patient_dashboard.dart` — with-data composition rebuild (`patient_first_run.dart` untouched; the `state.summaries.isEmpty` gate stays).
- `lib/screens/clinician_dashboard.dart` — stat row → directional summary (privacy copy verbatim).
- `lib/state/app_state.dart` and/or a small pure `lib/services/` module — score + insight computation (pure functions, unit-testable).
- New widget file(s) for ScoreRing / TrendBars / ContributorBar / InfoTip equivalents.
- `lib/screens/common_widgets.dart`, `lib/theme/app_theme.dart` — tokens + shared pieces.

### ⚠ Test coupling (IMPORTANT — the plan MUST handle)
- `lib/screens/patient_dashboard.dart:57` `'quality proxy'` tile is replaced — any test asserting it must move to the new score presentation.
- `test/widget_test.dart` pumps the dashboard with-data flow ("sleep access ready", hero disappearance after import from 10-03) — new hierarchy must keep those flows passing; update assertions to new structure deliberately, never by loosening privacy assertions.
- **Copy that must stay verbatim:** `'Visible: sleep samples, daily summaries, trend flags. Hidden: journal entries, drafts, private reflections.'` (clinician + patient consent surfaces), the reset-dialog copy in `widget_test.dart:91`, all safety/crisis copy, and the local-demo disclosures.
- `test/clinician_affordance_test.dart` covers the clinician dashboard — the `samples` stat replacement must update this suite in the same plan.
- All app-pumping tests pass `showSplash: false` (Phase 10 seam) — new tests must too.

### Standing constraints (NEVER violate)
- No analytics/telemetry; everything computed on device from existing local data; no new dependencies without strong cause.
- Clinician sees sleep summaries only, after accepted consent, never journal content — no new clinician-visible data kinds.
- Non-diagnostic everywhere: observational states, "not a diagnosis" humility, no emergency/monitoring implications.
- Gentle motion (rings/values ease in ~0.6s, controls ~0.2s; nothing pops); Inter 400/500/600/700 only; no emoji.
</canonical_refs>
