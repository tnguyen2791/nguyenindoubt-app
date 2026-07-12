# Fidelity Sweep — findings backlog (2026-07-12)

> **STATUS — APPLIED.** Pass 1 (this backlog) applied in commit `55dae8e`;
> a second pass re-audited the untouched Today / detail / login screens and
> applied confirmed drift in `4b704c3` (contributor gaps 12→10, login CTA gaps
> 8→12; several audit findings were rejected as false positives). Verified:
> `dart format` clean, `flutter analyze` clean, 121 tests pass, `flutter build
> web` succeeds. A separate branding gap surfaced from running the app on device
> — the app shipped the **default Flutter icon** and a "Nguyenindoubt App" label
> on every platform; fixed in `563198a` (real NiD icon + "NguyenInDoubt" name +
> branded launch screen across iOS/Android/web). See §"Deviations" below.
>
> **Deviations from this backlog (intentional, mock-justified):** item 4 said
> only Trends H1 → ink, but both `20-trends` and `31-profile` mocks inherit
> `--ink` for `h1` (no color override) while the code had *both* on canopy — so
> both page titles were set to ink. Deferred (ambiguous/structural, flagged to
> owner): shared-readings card grammar 18/22; provider Worth-a-look grid + roster
> table responsive layout; §5 owner-ruling items.


Full-app audit of the v1.2 buildout vs the design mocks (`docs/design-handoff/screens/*`). Four read-only auditors (auth+Today+detail · Trends+widgets · Explore/Profile/Settings/Notifications · Sharing/Provider/Weekly). **Verdict: structurally faithful** — tokens hex-for-hex, radii/widget geometry (ScoreRing, TrendBars, TrendLine, ConsistencyHeatmap, 44×26 toggle + knob shadow, 40×40 steppers, 36×36 tiles, kicker type) all EXACT; no leaked hex. Remaining drift is chrome + type-size, mechanical and low-risk.

## Already fixed
- ✅ Detail hero rings → `ScoreRing(size:150, strokeWidth:14)` (readiness + sleep detail) — commit `923e284`.

## The convergent root cause (all clusters)
**Type-size substitution:** widgets use theme styles where the mock specifies an off-ladder value. The theme styles themselves are fine; the fix is explicit `fontSize`/`height` on the specific captions/labels (or per-widget, NOT a global theme change — that would ripple unpredictably).

## Prioritized fix list

### 1. Type-size drift (MED, app-wide) — biggest visual lever after gutters
- Closing notes on Goals/Notifications/Feed + Profile member sub-line: `bodySmall` 13 → **12** (+ mock line-heights 1.5/1.6).
- Explore `.sub`: `bodyMedium` 14 → **13**, height 1.5.
- Profile identity: name 16 → **17**; avatar initial 20 → **22**; member sub 13 → **12**.
- Provider portal / shared-readings: bodyMedium 14 → 13, titleMedium 16 → 14–15 per mock; shared-readings card grammar 16/18 → **18/22** (`cardLg`).

### 2. Page gutters (HIGH where they appear)
- **Trends** ListView L/R padding 24 → **16** (`NidSpace.l`). (tab_shells)
- **Profile** page gutter horizontal 24 → **16** (keep 24 bottom). (tab_shells)

### 3. Kicker vertical rhythm (MED, app-wide)
- Section kickers: mocks want **~22px above / 10px below**; code uses 16/24 above + 12 below. Normalize pre-kicker gap → 22, post → 10.

### 4. Per-cluster smaller items
- **Trends:** H1 color canopy → **ink** (#17211B); stats-under-header gap 12 → **6**; active segment soft shadow (0 1px 3px canopy@12%); heatmap legend 1px `--line` top divider; inter-card gap 16 → 14.
- **Explore:** tipdot 15/9 → **16/10** (the Explore mock size; article-reader stays 15/9); chevrons 18 → **16**; pre-kicker gap 12 → 22; Begin-pill top gap 12 → 14; featured-card top gap 16 → 18.
- **Settings Goals:** goal value units (h/m) should render inline at **15px/600/muted** (currently whole string at 34px); note 13 → 12. Content gap: mock has a Bedtime-window row + Activity Rest-days/Inactivity toggles (not built — IA decision, flag to owner).
- **Settings Notifications:** quiet card pad 18 → 16; time-pill gap 8 → 10, top gap 16 → 14.
- **Provider portal (desktop):** add 1120px max-width clamp + desktop page padding (mock 32/28/48 vs code 24); Worth-a-look grid + roster table currently collapse to stacked cards on wide.
- **Profile:** chevron 18 → 16; identity card pad 18 → 16.

### 5. Flagged for owner ruling (possibly intentional, NOT auto-fix)
- Offered-scope check-circle vs mock toggle; inline "verified" text vs filled pill; absent "Share this week" button on Weekly report (94); Profile group order (Account/Sharing/Preferences/Support vs mock's Account/Preferences/Sharing/Support — kept for a test assertion).

## Notes
- Journal-not-shareable + "Hidden: journal…" disclosure are contract-intended — NOT gaps.
- Recommended fix approach: one executor pass, per-surface explicit sizes + the two gutters + kicker rhythm, then the full verification bar. Low risk; a few widget tests may assert nav labels but not font px.
