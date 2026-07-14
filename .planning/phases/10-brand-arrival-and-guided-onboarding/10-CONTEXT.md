# Phase 10: Brand Arrival and Guided Onboarding - Context

**Gathered:** 2026-07-06
**Status:** Ready for planning
**Source:** Synthesized from the v1.1 design critique (onboarding/splash lens) + REQUIREMENTS ONB-01–04

<domain>
## Phase Boundary

Make the first minute feel calm, branded, and guided — from cold-start to a clear first action — instead of a blank white boot frame and a graveyard of `--` placeholders. Four concerns: (1) an on-brand cold-start (native web loader + an animated brand-intro splash); (2) a patient-first welcome that de-emphasizes the clinician door and softens disclosures; (3) an onboarding that sets expectations and guards the name field; (4) a guided empty-dashboard first-run with sleep-only permission priming.

In scope: `web/index.html` (loader), a Flutter splash gate at boot, the onboarding + patient-onboarding screens, and the *first-run guidance layer* on the empty dashboard. Reuses the Phase 8 design system + Phase 9 patterns.

Out of scope (later phases): app-wide tab/screen transitions, SnackBars, sleep-bar grow-in (Phase 13 — but the splash's own gentle fade IS in scope here); dashboard metric hierarchy, the score ring, and insights (Phase 11 — Phase 10 only adds the empty-state "start here" + priming layer, kept modular so Phase 11 extends it).
</domain>

<decisions>
## Implementation Decisions

### ONB-01 — on-brand cold-start (native web loader + animated splash)
- **Native web loader** in `web/index.html`: fill the pre-Flutter paint with the brand `fog #F6F7F1` background + a centered mark, so the several-second DDC/engine boot is on-brand instead of blank white. Remove it once Flutter's first frame paints.
- **Animated brand-intro splash** (in Flutter): a gate widget wrapping `AppShell`, using `AnimatedSwitcher` to cross-fade splash → app. Sequence (gentle, no bounce, ~3.5–4s): fog ground → the `BrandMark` fades in (~40%→100%, ease-out) → a soft bloom/scale or a thin `canopy` antler stroke-reveal → the "NguyenInDoubt" wordmark fades up beneath → hold → cross-fade into onboarding. Palette: fog ground, canopy ink, ember accent.
- **Plays once per cold launch** — guard with an in-memory bool (a top-level/app-state flag), NOT a persisted counter and NOT analytics. Cross-fade out, never pop.
- **Test-friendliness (REQUIRED):** the splash must be skippable/instant under widget tests — e.g. a `NguyenInDoubtApp({showSplash = true})` or a zero-duration path when a test flag is set — so existing `pumpAndSettle`-from-boot tests don't hang on a 4s animation. Document the seam.

### ONB-02 — patient-first welcome
- Make the patient path the sole primary button — rename "Patient sign up" → "Get started" (or "Set up privately"). Move clinician access to a low-key text link at the bottom ("I'm a clinician"), and rename "Clinician demo override" → "Clinician preview" / "Clinician demo".
- Relocate the required local-only disclosure from bolded hero copy to calm secondary text (below the fold / smaller) — keep the disclosure, lower its emotional volume.
- Give the stag top billing on mobile (put `_StagPanel` or a banner crop first in the narrow layout).

### ONB-03 — onboarding sets expectations + guards input
- On the patient-onboarding screen, add three one-line "what this app does" bullets: *Sleep, privately imported* / *A journal only you can read* / *Guides, with room for doubt*.
- Guard the name field: trim input; an empty name cannot submit (disable Continue, or offer an explicit "Skip for now"). Keep it to one screen — no carousel.

### ONB-04 — guided first-run on the empty dashboard
- When `state.summaries.isEmpty`, replace the three `--` tiles with a single calm guided hero: a "start with last night's sleep — we only ever read sleep, never your journal" message + one primary `Import sleep` action. Demote/hide the empty metric tiles until there's data. This doubles as **sleep-only permission priming shown before the OS prompt**.
- Keep this a modular first-run widget so Phase 11 (dashboard hierarchy + insights) extends rather than fights it.

### Claude's Discretion
- Exact splash timing/curve and whether the antler is a true stroke-reveal or a simpler mark bloom (favor simple + calm over clever).
- Precise copy of the new welcome/onboarding/first-run strings (calm, non-clinical, non-monitoring).
- Where the splash gate lives (main.dart vs a wrapper widget).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Files this phase edits
- `web/index.html` — native loader (fog + mark).
- `lib/main.dart` — app boot; splash gate wrapping `AppShell`.
- `lib/screens/app_shell.dart` — `_OnboardingScreen` (CTAs, stag order, disclosure copy), `_PatientOnboardingScreen` (expectation bullets + name guard). SafetyScreen etc. untouched.
- `lib/screens/patient_dashboard.dart` — the empty-state guided first-run layer (coordinate with Phase 11).
- `assets/brand/` — the mark for loader + splash.
- `lib/screens/common_widgets.dart` — reuse `BrandMark`, tokens, EmptyState. `lib/theme/*` — palette/motion tokens.

### ⚠ Test coupling (IMPORTANT — the plan MUST handle)
- `test/widget_test.dart` asserts onboarding copy and labels: "NguyenInDoubt", **"Patient sign up"**, **"Clinician demo override"**, the demo-notice paragraph, and pumps from boot. ONB-02 renames those CTAs and ONB-01 adds a boot splash — so the plan MUST update these assertions to the new labels AND ensure the splash is instant/skipped under test so `pumpAndSettle` doesn't hang. The **local-only disclosure and safety copy remain asserted** — do not remove those guarantees, only relocate/restyle.

### Design direction
- `.planning/REQUIREMENTS.md` → ONB-01..ONB-04.
- The sister app's loved splash (badge→wordmark bloom, ~4.6s, once per cold launch) is the reference feel — but simpler.
- Standing constraints: NO analytics (splash-once via in-memory flag, not a persisted count); keep demo/local-only disclosure (relocated, not deleted); patient-first but clinician demo still reachable; non-diagnostic; gentle motion (fade, never pop).
</canonical_refs>

<specifics>
## Specific Ideas
- Critic's sharpest line: "the app's first frame is a bug" — the blank-white cold-start is the single biggest miss; the native web loader + splash fixes it.
- Verification bar: `dart format lib test`, `flutter analyze` (no issues), `flutter test` (green — updated onboarding assertions + a splash-skip seam), `flutter build web` (loader change must not break the build).
</specifics>

<deferred>
## Deferred Ideas
- App-wide tab/screen/role transitions, SnackBars, sleep-bar grow-in → Phase 13.
- Dashboard metric hierarchy, score ring, insight lines → Phase 11.
- Consent/sharing destination → Phase 12.
</deferred>

---

*Phase: 10-brand-arrival-and-guided-onboarding*
*Context synthesized: 2026-07-06 from the v1.1 design critique*
