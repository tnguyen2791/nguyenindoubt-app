# Handoff: NguyenInDoubt (NiD) — Recovery & Sleep Companion

## Overview
NguyenInDoubt is a recovery/sleep companion app (Oura-style ring wearable) with a consent-first sharing model: users track sleep, readiness, and activity against their own baseline; they can **opt in** to share chosen data with one provider (Dr. Nguyen), who can accept or decline requests. The app doubles as an education resource — plain-language marker explanations (InfoTips) and mental-health reads are first-class. Positioning: "When in doubt, check in — don't freak out." No streaks, no guilt, never a diagnosis.

## About the Design Files
Everything in this bundle is a **design reference created in HTML** — prototypes showing intended look and behavior, not production code. The task is to **recreate these designs in your target codebase's environment** (React Native, Swift/Kotlin, React web, etc.) using its established patterns. If no environment exists yet, choose what fits a mobile-first health app with a small desktop provider portal (e.g. React Native + a React web portal).

## Fidelity
**High-fidelity.** Colors, type, spacing, radii, copy, and interactions are final. Recreate pixel-perfectly. The `components/` folder contains reference React implementations with exact prop contracts and usage notes (`.prompt.md`) — port these first, then compose screens from them. (Source files carry a `.txt` suffix — `Button.jsx.txt`, `Button.d.ts.txt` — so they stay inert as references; strip the suffix when porting.)

## Architecture of this bundle
- `screens/` — 102 full-screen HTML mocks. Naming: `NN-name-{mobile|desktop}[-dark].html`. Every light screen has a dark twin (token swap only — same markup). Screens are **wired**: tapping through them walks the real flows.
- `components/` — reference primitives: Button, Toggle, Chip, Card, SettingsRow, InfoTip (core); ScoreRing, TrendBars, ContributorBar, BaselineBand (data).
- `tokens/` — colors.css (light + `[data-theme="dark"]`), typography.css, shape.css, fonts.css.
- `templates/` — 9 parameterized screen templates (Design Components) showing state variants (e.g. RequestStatus: waiting/accepted/declined).
- `foundations/` — brand one-pager, wordmark spec, app icons (PNG 16→512), printable user welcome one-pager.
- `brand-readme.md` — full voice & visual guide (copy rules live here; follow them for any new copy).

## Screens / Views (by flow)

### Onboarding (mobile, files 42–47, 60–69)
Welcome (starfield dark option) → Email sign-in → Verify code (6-box OTP) → Permissions (per-signal toggles; Bluetooth "Required") → Ring pairing (pulse animation, found-ring card) → About you (units segmented control, baseline inputs) → Notification priming (real notification preview, "no streaks" promises) → Baseline calibration ("we're learning you", 14 days) → Day-one empty state.
Progress: 6px dots, active = 18px pill, canopy. Back buttons: 32px circle, surface bg, hairline border.

### Core app (mobile tab bar: Today · Trends · [+] · Explore · Profile)
- **Today dashboard (18/19)**: brand wordmark top-left, bell → notifications feed, avatar → profile. Greeting (13px muted) + status headline (30px/700, canopy, -0.03em). Readiness card: 120px ScoreRing + 3 ContributorBars. Two-up Sleep/Activity mini-rings (104px) → detail screens. Sleep stages hypnogram. 7-night TrendBars.
- **Detail screens**: Sleep (21/23, 25/27 desktop), Readiness (28/32), Activity (98/99 — hero ring, hourly movement bars, auto-detected sessions). Contributors carry InfoTip dots (15px, italic i, mint bg) with reassurance-first explanations.
- **Trends (20/22, 24/26)**: segmented Sleep/Readiness/Activity + Week/Month/Quarter. 30-day score trend, weekly averages, consistency heatmap.
- **Journal (50/51)**: filter chips, weekly tag-frequency strip + one correlation insight, day entries (tags + notes + that morning's readiness). Flagged tags (Alcohol, Stressed, Late meal) = ember tint.
- **Add sheet (30/34)**: bottom sheet, tag chips, "History" link.
- **Explore (70/71)**: featured practice (box breathing), "Your markers, explained" (one InfoTip shown open), Mind & mood article rows, disclaimer + US 988 line.
- **Article (72/73)**: kicker (read time), byline, lede, inline InfoTip, "Worth knowing" callout, "Try it now" practice card, read-next.
- **Notifications feed (48/49)**: Today/Yesterday/This week sections; items link to referenced screens. Includes accepted + declined sharing outcomes, weekly report.
- **Weekly report (94/95)**: takeaway headline, 3 stats, 7-night bars, "What lined up" tag correlations, "One thing to try". Voice: "patterns, not grades."
- **Profile & settings (31/35, 38/41 desktop; 52–59)**: Account/Sharing/Preferences/Support groups; Goals (steppers + data-informed hints), Notifications (toggles, quiet hours).

### Sharing (consent-first, opt-in model)
- **User side (82–87 mobile, 88–93 desktop, 102/103)**: Profile → "Request to share" → search provider ("Accepting share requests", verified badge) → choose what to offer (scores/sleep ON, journal tags/notes OFF by default) → "Send request" → Request sent → status screen (waiting pulse dot / accepted / declined states; quiet cancel). Manage screen (78/79): per-category toggles, "Pause sharing" (ember text button).
- **Provider side (74–77, 80/81, 96/97, 100/101, desktop)**: Sign-in (invite-only clinician accounts, one-time code) → Dashboard: "N people share with you", **Requests** card (Accept/Decline), "Worth a look · not alerts, just patterns", roster (consent-scoped Shares column, paused rows at 55% opacity) → Shared readings ("Thao's readings" — the user's own view scoped by consent; person-first, never clinical) → Provider settings (sharing requests list, digest prefs, "you're never notified when someone pauses — by design").

## Interactions & Behavior
- Navigation: plain anchors/onclick in mocks → replace with router. All flows walkable; back buttons everywhere.
- Toggles animate .18s ease (bg + knob left). Rings ease stroke-dashoffset .6s. No pop/bounce anywhere — restful motion only.
- Pulse animations (pairing, waiting dot) gated on prefers-reduced-motion.
- InfoTip: tap toggles a 230px popover card (term title + 1–2 sentence body, ends on reassurance). aria-expanded, role=tooltip.
- Consent rules (enforce in logic, not just copy): sharing read-only; one provider; user sees everything provider sees; pause/cancel/decline generate NO notification to the other party; nothing shared until both opt-in and accept.

## State Management
- User: auth (passwordless OTP), permission grants, baseline-calibration progress (days), daily scores + contributors, journal entries (tags/notes), notification prefs, sharing state machine: none → requested(offer) → active(scopes) | declined; active → paused → active.
- Provider: session, request queue (accept/decline), roster of consented sharers with scope lists.

## Design Tokens
Light: --ink #17211B · --canopy #1E4A34 (accent) · --moss #5D7F43 · --sage #A9BA92 · --mint #E4EDDD (tints/tracks) · --fog #F6F7F1 (app bg) · --desk #E9ECE3 · --ember #C56844 (flags ONLY + wordmark accent) · --surface #fff · --line rgba(30,74,52,.14) · --muted #54635a · --faint #7a887f.
Dark ([data-theme="dark"]): ink #E8EEE2 · canopy #8FB56A · moss #7FA45E · mint #26332A · fog #0B120F · desk #050806 · ember #E08A63 · surface #18211A · line rgba(232,238,226,.12) · muted #9DA99B · faint #7C8A7E · onaccent #0B120F.
Metric states: optimal #4F7A3C · good #6E8544 · fair #A08B48 · attention #C4633E. Color = meaning, never decoration; one accent per metric.
Type: Inter only (Google Fonts). 34/26/18/15/14/13/12/11/10px scale; 400 body, 600 labels, 700 headlines+numbers; -0.02…-0.03em on large; 11px/700 uppercase +0.09em section labels.
Shape: cards 16–18px radius, controls 14px, tiles 11px, pills 99px. Card padding 18px, gaps 14px, page gutter 16px. Hairline borders, no card shadows (shadows only knobs/sheets). Hit targets ≥44px.

## Assets
- App icons: `foundations/icons/` — favicon 16/32 (N + ember tittle), app icon 180/192/512 + 512-dark (NiD on canopy tile, 26% radius). Drawn programmatically, PNG.
- Icons in screens: inline SVG, 1.7px stroke, round caps (Lucide grammar). No icon font. No emoji anywhere.
- Wordmark: type-only "NguyenInDoubt", Inter Bold, "In" in ember; compact "NiD" (ember i) below ~80px. Spec: `foundations/01-logo-explorations.html`.

## Files
Full index in `brand-readme.md`. Start with tokens/, then components/, then walk screens/ starting at 42 (onboarding) and 18 (Today).
