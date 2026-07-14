# NguyenInDoubt Design System

NguyenInDoubt ("NiD") is a recovery & sleep companion in the spirit of Oura: it reads the body's quiet signals (sleep, heart rate, HRV, temperature, movement) and explains them calmly. Scores compare you to your own baseline, never to anyone else. The name owns the uncertainty — "when in doubt, check in, don't freak out."

**Sources:** built from scratch in this project (no external Figma/codebase). Oura's app is the north-star *pattern* reference for data displays only — all visuals, palette, and copy are original.

## Content fundamentals

- Voice is quiet, second-person, lowercase-calm: "protective night", "short night", "balanced", "worth watching, not worrying".
- Explain, don't alarm: every flag carries a likely cause and a next step ("A late meal or alcohol can do this").
- Never guilt: no streaks, no shame. "Missed days are fine, they just extend calibration a little."
- Health-grade humility: "not a diagnosis" appears beside scores; "We only write when there's something worth knowing."
- Qualitative captions over numbers-alone; one insight at a time. No emoji, no exclamation marks.
- **Education layer:** NiD is also a learning resource. Every marker a newcomer might not know (HRV, RHR, temperature deviation, readiness) carries an `InfoTip` — a small italic-i dot opening a 1–2 sentence plain-language card that ends on reassurance, never a warning. The Explore tab hosts short reads and practices; mental-health topics (stress, anxiety and sleep, low days) are first-class content there, written supportively and never diagnostically. Educational surfaces close with "educational, not medical advice" and, where mood is discussed, a gentle pointer to real help (US: call/text 988).

## Visual foundations

- **Color:** warm-green forest palette (canopy/moss/sage/mint on fog). Ember is reserved for flagged states and the wordmark accent — color is meaning, never decoration. Metric states: optimal → attention greens-to-ember ramp (`--state-*`). Dark theme via `[data-theme="dark"]`.
- **Type:** Inter only. 400 body / 600 labels / 700 headlines & numbers; tracking tightens (−0.02…−0.04em) on large sizes; 11px/700 uppercase section labels with +0.09em.
- **Numbers are the heroes:** one big readout per metric with a small unit and short qualitative caption.
- **Surfaces:** white cards (dark: #18211A) with 1px hairline `--line` borders, 16–18px radii, 18px padding, 14px gaps. No drop shadows on cards — shadows only on toggle knobs and bottom sheets.
- **Charts:** rings and rounded bars, mint tracks, value labeled above, minimal gridlines, single-letter day axes.
- **Motion:** values ease in (~.2s ease for controls, .6s for rings); nothing pops. Gentle, restful.
- **Backgrounds:** flat fog; dark first-run screens may use a subtle CSS starfield. No gradients, no imagery.
- **Hover/press:** links canopy → moss; controls rely on state color change, not scale.

## Wordmark & iconography

- Wordmark: type-only "NguyenInDoubt", Inter Bold, one solid word, "In" in ember. Compact form "NiD" (ember "i") below ~80px. Spec: `foundations/01-logo-explorations.html`; icons: `foundations/icons/` (favicon 16/32, app icon 180/192/512 + dark).
- Icons: hand-kept set of 1.7px-stroke round-cap line SVGs (moon, heart, flame, bell, shield, chevrons…) drawn inline in screens — consistent with Lucide's grammar; Lucide via CDN is the sanctioned substitute for new glyphs.
- No emoji anywhere.

## Components

Namespace: `window.NguyenInDoubtDataDisplaysOuraStyle_d0b3eb` via `_ds_bundle.js`.

- **core/** — `Button` (primary/ghost/quiet/danger), `Toggle`, `Chip` (tag/filter, flagged=ember), `Card` (label + note header), `SettingsRow` (chevron/toggle), `InfoTip` (marker-explainer tooltip).
- **data/** — `ScoreRing` (0–100 ring), `TrendBars` (7-day rounded bars), `ContributorBar` (state word + track), `BaselineBand` (you-vs-your-range strip).

## Index

- `styles.css` → `tokens/` (fonts, colors, typography, shape)
- `components/core|data/` — primitives (+ `.prompt.md` usage notes per component)
- `data-displays/` — the UI kit: 59 full screens as plain HTML (dashboard, trends, sleep/readiness detail, onboarding, journal, notifications, settings; mobile + desktop, light + dark). These are the ground-truth screens; components were extracted from them.
- `foundations/` — principles, wordmark spec, app icons, brand one-pager
- `guidelines/` — token specimen cards
- `SKILL.md` — agent skill entry point

Fonts ship via Google Fonts CDN (`tokens/fonts.css`), not bundled files.
