---
phase: 08-design-system-foundations
plan: 01
subsystem: theme
tags: [design-system, typography, tokens, color-scheme, brand]
requires: []
provides:
  - lib/theme/tokens.dart (NidSpace, NidRadius)
  - NidColors.slate palette const
  - buildNidTheme full TextTheme ladder (displayLarge..labelSmall)
  - neutralized ColorScheme + dialogTheme + segmentedButtonTheme
  - PillTone enum + StatusPill tone API
  - BrandMark widget
affects:
  - 08-02 (screen token/pill-tone/BrandMark sweep)
  - 08-03 (screen token/pill-tone/BrandMark sweep)
tech-stack:
  added: []
  patterns:
    - "Spacing/radius tokens as static-const doubles in lib/theme/tokens.dart"
    - "PillTone -> (background, foreground) record is the single place pill color encodes state"
    - "StatusPill: tone-driven default with optional `color` override for un-migrated call-sites"
    - "BrandMark: single framed-badge lockup with min-size clamp + clearspace"
key-files:
  created:
    - lib/theme/tokens.dart
  modified:
    - lib/theme/app_theme.dart
    - lib/screens/common_widgets.dart
decisions:
  - "labelMedium/labelSmall both w600; StatusPill reads labelSmall (12) not labelMedium (13) to avoid a widget-test square-glyph wrap regression"
  - "Kept ColorScheme.fromSeed(canopy) base and pinned leaking tones via .copyWith rather than hand-authoring a full ColorScheme"
metrics:
  duration_min: 17
  completed: 2026-07-06T19:00:33Z
  tasks: 3
  files_changed: 3
status: complete
---

# Phase 8 Plan 1: Design System Foundations Summary

Established the tokenized design-system base for v1.1: a complete Inter type ladder (no undefined tokens, no weight above w700), NidSpace/NidRadius spacing-and-radius tokens, a state-driven PillTone StatusPill, a neutralized Material color scheme (no fromSeed tones leaking into Dialog/SegmentedButton/NavigationBar/outline/surface), and one BrandMark framed-badge widget that BrandHeader now uses.

## What was built

**Task 1 — Tokens + slate (commit 44f8f5f)**
- New `lib/theme/tokens.dart`: `NidSpace` (xs=4, s=8, m=12, l=16, xl=24, xxl=32) and `NidRadius` (card=8, pill=999, badge=14) as static-const doubles with private const constructors, documented as the single spacing/radius ruler.
- `NidColors.slate = Color(0xFF54635A)` added so the one-off legend literal moves inside the blessed palette.

**Task 2 — Type ladder + seed neutralization (commit f001a2d)**
- Full explicit `TextTheme` ladder — every token the app reads is now defined (previously `headlineMedium`, `bodySmall`, `labelMedium`, `labelSmall`, `displayLarge` fell back to stock M3; the onboarding title read an undefined `headlineMedium`).
- Neutralized the `ColorScheme.fromSeed(canopy)` leak via `.copyWith(...)` and added `dialogTheme` + `segmentedButtonTheme` + an extended `navigationBarTheme`.

**Task 3 — PillTone, BrandMark, tokenized primitives (commit ab3c208)**
- `PillTone { neutral, good, caution, flag, private }` + a `({Color background, Color foreground})` mapping.
- `StatusPill` is now tone-driven (`tone` default `neutral`) with `color` retained as an optional override.
- `BrandMark` framed-badge widget; `BrandHeader` renders it. Primitives swept onto NidSpace/NidRadius and off heavy weights.

## Final token values (Wave 2 depends on these)

**NidSpace** (doubles): xs=4, s=8, m=12, l=16, xl=24, xxl=32
**NidRadius** (doubles): card=8, pill=999, badge=14

**TextTheme ladder** (family Inter; weights only 400/500/600/700):

| Token          | Size | Weight | Color          | Notes            |
| -------------- | ---- | ------ | -------------- | ---------------- |
| displayLarge   | 40   | w700   | ink            |                  |
| displaySmall   | 32   | w700   | ink            |                  |
| headlineMedium | 28   | w700   | ink            | was MISSING      |
| headlineSmall  | 24   | w700   | ink            |                  |
| titleLarge     | 20   | w700   | ink            |                  |
| titleMedium    | 16   | w700   | ink            |                  |
| bodyLarge      | 16   | w400   | ink, height1.45|                  |
| bodyMedium     | 14   | w400   | ink, height1.45|                  |
| bodySmall      | 13   | w400   | slate          |                  |
| labelLarge     | 14   | w600   | (inherit)      | was w700         |
| labelMedium    | 13   | w600   | (inherit)      |                  |
| labelSmall     | 12   | w600   | (inherit)      | StatusPill reads |

**PillTone → (background, foreground):**

| Tone    | Background                                   | Foreground |
| ------- | -------------------------------------------- | ---------- |
| neutral | mint                                         | canopy     |
| good    | alphaBlend(sage @0.45, white)                | canopy     |
| caution | alphaBlend(bark @0.16, white)                | bark       |
| flag    | ember @0.14 alpha                            | ember      |
| private | fog                                          | ink        |

**StatusPill:** `tone` (default `neutral`) drives background+foreground; `color` optional override wins over the tone background; label uses theme `labelSmall`; padding `symmetric(h: NidSpace.m, v: NidSpace.s)`; radius `NidRadius.pill`; icon/text use the tone foreground.

**BrandMark:** `BrandMark({size = 56})`; effective render size clamped to `>= 28`; clearspace = `effective * 0.11`; white badge `NidRadius.badge`, inner `ClipRRect` `NidRadius.card` over `Image.asset('assets/brand/nguyenindoubt-square-mark.png', fit: cover)`. BrandHeader passes `size: markSize` (82 wide / 62 narrow).

**ColorScheme fields pinned via `.copyWith` (DS-04):** outline=sage, outlineVariant=mint, secondaryContainer=mint, onSecondaryContainer=canopy, tertiary=moss, onSurfaceVariant=slate, surfaceContainerLowest=white, surfaceContainerLow=fog, surfaceContainer=fog, surfaceContainerHigh=mint, surfaceContainerHighest=mint.
**Component themes:** `dialogTheme` (white bg, transparent surfaceTint, titleLarge/bodyMedium text); `segmentedButtonTheme` (selected canopy/white, unselected white/ink, side canopy@0.16); `navigationBarTheme` (backgroundColor fog, surfaceTint transparent, indicator mint, label 12/w600).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] StatusPill reads `labelSmall` (12) instead of `labelMedium` (13)**
- **Found during:** Task 3 (surfaced by the plan-level `flutter test` gate after Task 2).
- **Issue:** Defining `labelMedium` at 13 (per CONTEXT) widened the "988 / 911" pill by ~1 glyph. Widget tests run without the real Inter font, so Flutter uses a fixed-width square-glyph test font where "Safety and limits" (17 chars) sits exactly at BrandHeader's copy-column width boundary. The ~9px wider pill shrank the copy column just enough to wrap that title to a 2nd line, cascading the Safety action button under the NavigationBar and failing `safety actions provide explicit urgent support fallback`. In production (real Inter) the title is ~238px and never wraps — a pure test-font boundary artifact.
- **Fix:** The theme ladder keeps `labelMedium` = 13 exactly as specified; the compact StatusPill chip reads `labelSmall` (12, w600) — the design-appropriate size for a pill and identical to the blessed baseline width (baseline pill fell back to M3's 12px). Both weights are w600, so the DS-01 ladder is unaffected.
- **Files modified:** lib/screens/common_widgets.dart
- **Commit:** ab3c208
- **Diagnosis method:** bisected the textTheme, then measured widget rects (BrandHeader grew 32px; header title went 1→2 lines; pill widened 9px) to isolate the square-glyph boundary.

## Verification results

- `dart format lib test` — clean (0 files changed).
- `flutter analyze` — **No issues found!** (no deprecated-field warnings).
- `flutter test` — **all 27 tests pass.**
- `flutter build web` — **✓ Built build/web** (BrandMark Image.asset, dialog/segmentedButton theming, ColorScheme changes all compile for the Pages deploy).
- `grep -rEn 'FontWeight\.w(800|900)' lib/theme/app_theme.dart lib/screens/common_widgets.dart` — no matches (this plan's files; lib-wide sweep of the remaining screen call-sites in patient_dashboard/clinician_dashboard/resources_screen is Wave 2).
- `lib/theme/tokens.dart` exists; `NidColors.slate`, `PillTone`, `BrandMark` all defined.

## Notes for Wave 2 (08-02 / 08-03)

- Remaining `FontWeight.w900`/`w800` call-sites to sweep: `lib/screens/patient_dashboard.dart:400` (w900), `lib/screens/clinician_dashboard.dart:249` (w900), `lib/screens/resources_screen.dart:94` (w800). The lib-wide no-heavy-weight guarantee is verified at phase completion after these are migrated.
- StatusPill call-sites still pass `color:` (or default neutral); migrate them to `tone:` (e.g. "sharing active" → good, "short night"/errors → flag, "private"/"journal private" → private, "invite required" → neutral).
- `Colors.red.shade700` invalid-invite message in patient_dashboard still needs → `NidColors.ember` (CONTEXT DS-04), plus the raw 34px AppBar mark tile → BrandMark.

## Self-Check: PASSED

- lib/theme/tokens.dart — FOUND
- lib/theme/app_theme.dart — FOUND (modified)
- lib/screens/common_widgets.dart — FOUND (modified)
- Commit 44f8f5f — FOUND
- Commit f001a2d — FOUND
- Commit ab3c208 — FOUND
