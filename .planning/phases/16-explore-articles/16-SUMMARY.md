---
phase: 16
plan: 1
subsystem: patient-explore
tags: [explore, articles, education, crisis-988, design-buildout]
requires:
  - P12 IA restructure (Explore tab slot, SectionKicker, tab bar)
  - P11 data-display kit (InfoTip, SectionCard)
  - P14 detail_screens (fadeDetailRoute gentle-fade route)
  - Existing SafetyScreen + crisis copy (P09)
provides:
  - Explore tab rebuilt to design 70 (featured practice + markers strip + article rows + disclaimer/988)
  - Article reader (design 72) with static supportive non-diagnostic content
  - ExploreMarker / ExploreArticle / ArticleBlock content models
affects:
  - lib/screens/app_shell.dart (Explore now sourced from explore_screen.dart)
  - lib/screens/tab_shells.dart (old resources-wrapping ExploreScreen retired)
tech-stack:
  added: []
  patterns:
    - Static seed content (no repository plumbing) for educational articles/practices
    - fadeDetailRoute reuse for the Article reader gentle-fade transition
    - InfoTip reuse for both the markers strip and inline article tips
key-files:
  created:
    - lib/screens/explore_screen.dart
    - test/explore_screen_test.dart
    - .planning/phases/16-explore-articles/16-SUMMARY.md
  modified:
    - lib/models/app_models.dart
    - lib/data/seed_data.dart
    - lib/screens/tab_shells.dart
    - lib/screens/app_shell.dart
key-decisions:
  - Explore content is static seed data referenced directly (seedExploreArticles / seedExploreMarkers), not plumbed through the repository/state — it carries no wearable data and matches the "static/educational" scope, keeping it fully web/sim-verifiable and test-friendly.
  - The crisis 988 line is folded into Explore's closing disclaimer AND made tappable into the existing SafetyScreen via fadeDetailRoute, so the standing "Safety stays reachable" rule holds from Explore in addition to the Profile Safety row. No safety/crisis copy was changed — the verbatim SafetyScreen strings and safety_screen_test assertions are untouched.
  - The old P12 resources-wrapping ExploreScreen (in tab_shells.dart) was retired; SafetyScreen/ResourcesScreen remain in resources_screen.dart for reachability and the safety tests.
coverage:
  - deliverable: "Explore rebuilt to 70-explore grammar (featured practice, markers strip, article rows, disclaimer + 988)"
    verification:
      - kind: test
        ref: "test/explore_screen_test.dart#Explore tab (70) renders the featured practice, markers strip, article rows, and the disclaimer + 988 line"
        status: pass
    human_judgment: false
  - deliverable: "Marker InfoTips open reassuring, non-warning explainers"
    verification:
      - kind: test
        ref: "test/explore_screen_test.dart#Explore tab (70) a marker InfoTip opens a reassuring, non-warning explainer"
        status: pass
    human_judgment: false
  - deliverable: "Explore 988 line routes to the reachable Safety surface"
    verification:
      - kind: test
        ref: "test/explore_screen_test.dart#Explore tab (70) the 988 disclaimer line routes to the reachable Safety surface"
        status: pass
    human_judgment: false
  - deliverable: "Article reader (72) opens with kicker/lede/callout/try-it-now + read-next chain"
    verification:
      - kind: test
        ref: "test/explore_screen_test.dart#Article reader (72) opens from an Explore row with kicker, lede, callout, and the try-it-now practice"
        status: pass
      - kind: test
        ref: "test/explore_screen_test.dart#Article reader (72) the featured Begin button opens the box-breathing reader"
        status: pass
      - kind: test
        ref: "test/explore_screen_test.dart#Article reader (72) read-next chains to the next article"
        status: pass
    human_judgment: false
  - deliverable: "Safety/crisis reachable + verbatim copy intact"
    verification:
      - kind: test
        ref: "test/safety_screen_test.dart"
        status: pass
    human_judgment: false
  - deliverable: "Pixel-level fidelity to design mocks 70/72 (spacing, tone, voice)"
    verification: []
    human_judgment: true
    rationale: "Layout grammar matches the mocks and tests assert structure/copy, but exact visual fidelity (spacing rhythm, tone balance) is a judgment call best confirmed on web/sim against the mock."
requirements-completed: []
duration: 22 min
completed: 2026-07-12
status: complete
---

# Phase 16 Plan 1: Explore Rebuild + Article Reader Summary

Rebuilt the Explore tab from the P12 resources wrapper into the design's full
`70-explore` surface — a mint featured-practice hero, a "your markers,
explained" InfoTip strip for the wearable signals the app reads, Mind & mood
article rows, and a closing disclaimer folded around a tappable crisis 988 line
— and added the `72-article` reader (kicker, byline, lede, inline InfoTip,
"Worth knowing" callout, "Try it now" practice, and a read-next chain) reachable
by a gentle-fade route. All content is static, supportive, non-diagnostic seed
data authored in the brand voice, so the whole surface verifies on web/sim.

## Accomplishments

- **Content models** (`app_models.dart`): `ExploreMarker` (signal name + abbr +
  reassurance-first InfoTip body), `ExploreArticle` (kind/read-time/section/
  byline/lede/body/callout/try-it-now/read-next), and `ArticleBlock`
  (heading or paragraph with an optional inline InfoTip term/body).
- **Seed content** (`seed_data.dart`): the four marker explainers (HRV, RHR,
  temperature deviation, readiness) and five articles/practices — the featured
  Box breathing practice plus Stress leaves a signature, Anxiety and sleep, Low
  days are data, and a wind-down practice. Each closes on reassurance; mood
  reads point to 988; no exclamation marks in the educational tips.
- **Explore surface** (`explore_screen.dart` — new): title/intro, mint featured
  hero with a Begin CTA, the markers card (InfoTip per row), Mind & mood rows
  (icon tile + meta + chevron), and the disclaimer/988 block.
- **Article reader** (`explore_screen.dart`): moss kicker (section · kind ·
  time), canopy title, byline, lede, body blocks with an inline HRV InfoTip, a
  mint "Worth knowing" callout, a "Try it now" practice card, tappable read-next
  rows, and the closing disclaimer + 988. Opened via the reused `fadeDetailRoute`.
- **Safety reachability**: the 988 disclaimer line taps through to the existing
  `SafetyScreen` (fade route); Profile keeps its own Safety row. No safety/crisis
  copy changed.
- **Wiring**: `app_shell.dart` now imports `ExploreScreen` from
  `explore_screen.dart`; the old resources-wrapping `ExploreScreen` was removed
  from `tab_shells.dart`.
- **Tests** (`explore_screen_test.dart` — new, 6 tests): Explore layout
  (featured practice, markers strip + abbrs, article rows, disclaimer/988),
  marker InfoTip behavior (reassuring, no `!`), the 988 → Safety route, and the
  Article reader (opens with kicker/lede/callout/try-it-now, featured Begin
  opens box breathing, read-next chains onward).

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `dart format lib test` → 47 files, 0 unexpected changes.
- `flutter analyze` → No issues found!
- `flutter test` → All 101 tests passed (95 baseline + 6 new Explore/Article).
- `flutter build web` → Built build/web.

## Known Stubs

- The "Try it now" / "Begin practice" CTAs in the Article reader are inert
  (no-op `onTap`) — the guided-practice player is out of scope for P16. The
  featured card's Begin and the Explore article rows are fully wired to open the
  reader. This is an intentional placeholder; a guided-practice runner is future
  work, not part of the static-content scope of this phase.

## Self-Check: PASSED

- `lib/screens/explore_screen.dart` — FOUND
- `test/explore_screen_test.dart` — FOUND
- `.planning/phases/16-explore-articles/16-SUMMARY.md` — FOUND
- Commit `ab2dca9` (feat(16-1)) — FOUND in git log
