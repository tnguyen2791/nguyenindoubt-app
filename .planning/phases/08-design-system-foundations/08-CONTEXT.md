# Phase 8: Design System Foundations - Context

**Gathered:** 2026-07-06
**Status:** Ready for planning
**Source:** Synthesized from the v1.1 five-lens design critique (visual/brand lens primary) + REQUIREMENTS DS-01–05

<domain>
## Phase Boundary

Refactor the shared theme and core UI primitives into a real, tokenized design system so every later v1.1 surface (onboarding, data-viz, sharing, motion) inherits a deliberate, premium, calm look instead of templated Material. This phase touches the **theme and shared components only** — it must NOT redesign screens, change product copy, alter the consent/privacy contract, or add features. Visual regressions to existing screens are acceptable *only* where they move toward the tokens; behavior and tests stay green.

In scope: `lib/theme/app_theme.dart`, `lib/screens/common_widgets.dart` (StatusPill, SectionCard, BrandHeader, EmptyState, SleepTrendBars styling hooks), a new tokens file, a new `BrandMark` widget, and mechanical token/weight/color sweeps across screens.

Out of scope (later phases): the score ring & insights (Phase 11), splash/onboarding (Phase 10), consent IA (Phase 12), motion/transitions (Phase 13). Do not build those here — only the tokens/components they will consume.
</domain>

<decisions>
## Implementation Decisions

### Typography (DS-01)
- Define a real ladder with widening size jumps and a weight hierarchy. Target scale: `displayLarge`/`displaySmall` ~40, `headlineMedium` ~28, `headlineSmall` ~24, `titleLarge` ~20, `titleMedium` ~16, `bodyLarge` 16, `bodyMedium` 14, `labelLarge` 14, `labelMedium`/`labelSmall` 13/12.
- Weights: headings `w700`, body `w400`, labels `w500`–`w600` **max**. Remove every `w800`/`w900` (StatusPill, `_MetricTile`/`_ClinicianMetric` caps labels).
- Define **every** token the app references — notably `headlineMedium` (used at app_shell onboarding but undefined today, silently falling back to stock M3). No screen may rely on an undefined token.
- Keep the Inter family already bundled (Phase-0 design pass). Do not re-open the font choice.

### Spacing & radius tokens (DS-02)
- Introduce `NidSpace` (e.g. `xs=4, s=8, m=12, l=16, xl=24, xxl=32`) and `NidRadius` (`card=8, pill=999, badge=14`).
- Sweep the freehand magic numbers (2/6/10/14/18/22 gaps, `SectionCard` pad 18, `ListView` pad 20, one-off logo radii 6/14) onto the grid. Small, deliberate rounding is fine; the goal is one ruler.

### State-driven StatusPill (DS-03)
- Add a `PillTone { neutral, good, caution, flag, private }` enum mapping to bg + fg/icon color: neutral→mint, good→sage, caution→bark-tint, flag→ember-tint, private→fog (final hexes at planner/executor discretion within `NidColors`). Color must **encode state**, not default to mint for everything.
- Update existing pill call-sites to pass the correct tone (e.g. "sharing active"→good, "short night"/errors→flag, "private"/"journal private"→private, "invite required"→neutral). This is a mechanical mapping, not new copy.

### Neutralize the Material seed leak (DS-04)
- The current `ColorScheme.fromSeed(canopy)` leaks unblessed surfaceVariant/tertiary/outline tones into `SegmentedButton`, `Dialog`, `NavigationBar`. Explicitly theme those (and `outline`/`surfaceVariant`) to palette values, or specify a fuller `ColorScheme`. Nothing on screen should be a tone we didn't choose.
- Replace the stray `Colors.red.shade700` (invalid-invite message in patient_dashboard) with `NidColors.ember`. No stock Material colors anywhere.

### Single BrandMark (DS-05)
- Create one `BrandMark` widget with a min-size rule and enforced clearspace, one lockup (the framed white badge), used in the AppBar, `BrandHeader`, and onboarding — replacing today's three-radii/two-treatment usage. Kill the raw muddy 34px tile in the AppBar by using the badged lockup there too.

### Claude's Discretion
- Exact hex values within the existing `NidColors` palette, precise token numbers, and whether tokens live in `app_theme.dart` or a new `lib/theme/tokens.dart`.
- Whether `SleepTrendBars`' honest-axis fix rides here or defers to Phase 11 — prefer deferring data-viz logic; this phase only touches its *styling tokens*.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Theme & components (the files this phase edits)
- `lib/theme/app_theme.dart` — current theme, `NidColors`, `buildNidTheme()`; the `fromSeed` + `fontFamily` + textTheme + cardTheme + pill/nav themes live here.
- `lib/screens/common_widgets.dart` — `StatusPill`, `SectionCard`, `BrandHeader`, `EmptyState`, `SleepTrendBars`; the shared primitives to tokenize.
- `lib/screens/patient_dashboard.dart`, `lib/screens/clinician_dashboard.dart`, `lib/screens/app_shell.dart`, `lib/screens/journal_screen.dart`, `lib/screens/resources_screen.dart` — call-sites for the token/weight/pill-tone/BrandMark sweep.

### Design direction (the "why")
- `.planning/REQUIREMENTS.md` → DS-01..DS-05 (the acceptance bar).
- Claude Design project **"NguyenInDoubt — Data Displays (Oura-style)"** (id `d0b3eb3c-3d40-4a5a-b1d5-5ab7a8924baf`) — the Oura north-star grammar these tokens serve.
- Standing constraints: no analytics; clinician sleep-only, post-consent, never journals; keep demo/local-only disclosure copy verbatim; non-diagnostic; gentle motion.
</canonical_refs>

<specifics>
## Specific Ideas
- The single biggest "non-designer tell" per the crit: everything is near-max weight. Fixing the weight ladder is the highest-leverage change in the phase.
- `StatusPill` today: `color = NidColors.mint` default, text `w800` — the "green confetti" problem. The tone enum + weight fix resolves both.
- Verification bar: `dart format lib test`, `flutter analyze` (no issues), `flutter test` (27 pass) must stay green; run `flutter build web` since theme/assets feed the deploy.
</specifics>

<deferred>
## Deferred Ideas
- Score ring, honest bar axis + target line, insight lines → Phase 11.
- Splash / onboarding / first-run → Phase 10.
- Consent IA / sharing destination → Phase 12.
- Transitions / SnackBars / bar grow-in → Phase 13.
</deferred>

---

*Phase: 08-design-system-foundations*
*Context synthesized: 2026-07-06 from the v1.1 design critique*
