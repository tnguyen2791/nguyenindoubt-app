# Phase 11 — Design-Fidelity Closure Spec

**Source:** four parallel fidelity audits (data widgets, patient dashboard, onboarding/splash, clinician) against the local design ground truth in `docs/design-handoff/` + `11-DESIGN-SPEC.md`. All values below are exact, from the design's `shape.css`/`typography.css`/screen inline CSS. Owner rulings applied: **remove the BrandHeader banner entirely**; **build the missing clinician framing + onboarding chrome**.

**Verification bar (must be GREEN before each executor writes its SUMMARY):** `dart format lib test` (0 unexpected) · `flutter analyze` (No issues found!) · `flutter test` (all pass — 55 entering; update coupled tests, net count may change) · `flutter build web` (succeeds).

## LOCKED-DECISION GUARDS (do NOT "fix" these — they override the audit)
- The **"I'm a clinician" entry stays a quiet slate TextButton** (Phase 10 ONB-02 locked). Do NOT promote it to a bordered ghost button.
- The **stag panel** on welcome and the **PatientFirstRun** empty-state layer are locked Phase 10 work — keep their structure; only apply token/type corrections.
- **Verbatim copy stays byte-for-byte:** the clinician disclosure `Visible: sleep samples, daily summaries, trend flags. Hidden: journal entries, drafts, private reflections.`, the patient `Visible after acceptance: …` string, all safety/crisis copy, the reset-dialog copy, and the `not a diagnosis` headnote.
- **Clinician never sees journal** — do NOT add journal scope columns/pills. Positive scope framing is fine; the "Hidden: journal…" string stays.
- Inter ships **400/500/600/700 only**. Gentle motion; nothing pops. Every app-pumping test passes `showSplash: false`.
- Do NOT touch STATE.md/ROADMAP.md (orchestrator owns those).

---

## GROUP A — Theme foundation  (`lib/theme/tokens.dart`, `lib/theme/app_theme.dart`)
- `NidRadius.card`: **8 → 16**. Add `cardLg = 18`, `control = 14`, `tile = 11`.
- `NidSpace`: add `cardPad = 18` and `cardGap = 14` (keep the existing 4/8/12/16/24/32 scale; page gutter uses existing `l`=16).
- `cardTheme` borderRadius: **8 → 16** (`app_theme.dart:176`).
- Input `OutlineInputBorder` radius on every border variant (border/enabled/focused): **8 → 14** (`app_theme.dart:183-185`).
- Card border hairline alpha **0.16 → 0.14** (== design `--line` rgba(30,74,52,.14)).
- **ADD `filledButtonThemeData`**: shape `RoundedRectangleBorder(radius 14)`, `padding: EdgeInsets.symmetric(vertical: 15, horizontal: 18)`, `textStyle: 15/w700`, `minimumSize: Size.fromHeight(50)` (enables full-width when wrapped). Primary CTAs on welcome/onboarding/first-run are wrapped `SizedBox(width: double.infinity)` in their screens (Groups C/E).
- **ADD `textButtonThemeData`**: `textStyle: 13/w600`, foreground slate for the quiet links (keeps "I'm a clinician"/"Skip for now" calm).
- `SectionCard` default padding **16 → 18** (`common_widgets.dart:188`); ensure it uses `NidRadius.card` (now 16) so every card corner updates in one place.

## GROUP B — Data widgets  (`lib/screens/data_displays.dart`, `lib/screens/common_widgets.dart`)
- **ScoreRing radius**: `((size.shortestSide - strokeWidth) / 2) - 3` (design `-3` inset; was 54, target 51 @120).
- **ScoreRing number size**: make proportional `= (size * 0.28).round().toDouble()` (keeps 34 @120; correct at other sizes). Keep `letterSpacing: -0.68` (== -0.02em @34).
- **ScoreRing**: add `SizedBox(height: 3)` between number and word label.
- **ContributorBar name color**: `#33413A` (add `NidColors.contributorName = Color(0xFF33413A)`), NOT `ink`.
- **ContributorBar** name→track gap: **8 → 5**.
- **SleepTrendBars** ramp legend bar height: **6 → 8**; day-letter font size **10 → 11** (keep faint #7A887F); value-label gap above bar **4 → 6**. Keep bar radius 7/4 (spec-sanctioned mobile) and axis 9.5 (correct).

## GROUP C — Patient dashboard  (`lib/screens/patient_dashboard.dart`)
- **REMOVE the BrandHeader "Morning check-in" banner entirely** — the greeting block becomes the top of the screen (matches mock; SPEC surprise #3). Remove the `BrandHeader(...)` call at the top of `build`. Update any coupled test that asserts it.
- Page gutter: ListView padding **24 → horizontal 16** (keep vertical 16).
- Section gaps **16 → 14**; two-up mini-card gap **12 → 14**.
- Mini-card label: **12/w600 → 11/w700 + letterSpacing ≈0.99** (0.09em×11).
- Greeting→status gap **8 → 10**; status→sub gap **8 → 12**; sub-line `height: 1.45`.

## GROUP D — Clinician surface  (`lib/screens/clinician_dashboard.dart`)
- **ADD the "Worth a look" section label** above the stat rows: uppercase **11px/w700 canopy, letterSpacing 0.09em×11**, with the tail `· not alerts, just patterns` in **ember**. (Design 76-provider-dashboard-desktop.html `.k`.)
- **ADD closing humility note** below the summary (centered, **12px faint, height 1.6**): `People control exactly what you see and can pause sharing anytime.\nReadings are educational context for conversations — never a diagnosis.`
- Adopt the `.k` section-label idiom (uppercase 11/700 canopy +0.09em) for the clinician section headers currently rendered as `titleLarge`/`titleMedium` sentence case (e.g. "Invite status", "Clinician visibility").
- Person-detail heading: **20px → 26px** (use a 26/w700 -0.015em style for the scoped-detail name).
- StatDeltaRow itself is already EXACT — leave it. Keep the verbatim consent string and journal-hidden contract.

## GROUP E — Splash / welcome / onboarding / first-run
`lib/screens/brand_splash.dart`:
- **Wordmark → RichText**: `Nguyen` + `In`(ember `#C56844`) + `Doubt`, all Inter w700, `letterSpacing ≈ -0.84` (-0.03em @28). Update the coupled splash test (find.text('NguyenInDoubt') will break → assert the RichText via a Key or find the ember span).
- **Drop the decorative 32×2 ember divider bar** (ember = meaning, not decoration).

`lib/screens/app_shell.dart` (welcome + onboarding):
- Welcome headline: **canopy color + -0.02em tracking** (currently ink, untracked).
- Primary CTAs full-width (`SizedBox(width: double.infinity)`); radius/pad/weight come from the new button theme.
- Onboarding back button: wrap in **32×32 circle** — white fill, 1px canopy@14% border, canopy chevron.
- Expectation bullets: wrap each icon in a **38×38 mint tile, radius 11 (`--r-tile`)**, canopy icon; bump the bullet **label to w700**.
- Onboarding page title: **28px → 26px, ink → canopy, add -0.02em tracking**.
- SKIP progress dots (the 2-step flow is intentionally minimal — dots read odd on 2 steps).

`lib/screens/patient_first_run.dart`:
- Heading **20px → 24px + -0.02em tracking**; sub copy **14px ink → 13px slate**; CTA full-width. Card corner/pad now correct via SectionCard (Group A).

---

## Coupled tests to update (enumerate + fix, don't loosen privacy/safety asserts)
- `test/widget_test.dart` — BrandHeader/"Morning check-in" removal; any dashboard label/structure asserts; mini-card label; button finders if they keyed on stock layout.
- `test/brand_splash_test.dart` — wordmark RichText change (ember "In").
- `test/clinician_affordance_test.dart` — new "worth a look" label + humility note + section-label idiom; keep the verbatim disclosure + deterministic stat values ('6.7h', 'no prior week yet', '±0.5h', 'steady nights', '7 of 7 nights').
- `test/data_displays_test.dart` — ScoreRing/ContributorBar/trend geometry if any assert exact sizes; the 2h-night `closeTo(2.0/9.5)` anchor must still hold.
