# Design Buildout Roadmap — v1.2 "Full IA"

**Created:** 2026-07-12
**Why:** Fidelity audit found the app is a ~5-screen privacy MVP (tabs: Sleep/Journal/Guides/Safety) while the Claude Design project is a ~33-screen product (tabs: **Today · Trends · [+] · Explore · Profile**). Tokens are byte-identical — this is a **coverage + IA gap**, not styling drift. Owner decision (2026-07-12): **adopt the design's full IA and build it out.**
**Design source of truth:** Claude Design project `d0b3eb3c-…` + local mirror `docs/design-handoff/screens/*`. Tokens already match `lib/theme` hex-for-hex.

## Scope calls (LOCKED — the data reality drives these)
The MVP has **mock sleep only** — no wearable (HRV, temperature, activity, overnight HR, ring). Screens are triaged:
- **BUILD (real sleep data or static content):** Today, Sleep detail, Trends (sleep-only), Explore (practices + markers + articles + reader), Profile, Settings (goals/notifications), Add-sheet, Journal (restyle), Notifications feed, Weekly report, Sharing flow, Provider portal.
- **DEFER (no data in a sleep-only app — stub with the design's calm empty state + "coming soon", do NOT fake data):** Readiness detail (multi-signal), Activity detail + activity rings, Overnight HR, HRV/temperature trends, ring-pairing onboarding.
- **STANDING RULES:** crisis/Safety content stays prominent (fold the 988 line into Explore per design AND keep a reachable Safety route); clinician sees sleep summaries only, never journal; no analytics; Inter 400–700; gentle motion; friendly errors only.

## IA mapping (existing → design)
- `patient_dashboard` → **Today** (already fidelity-matched; add detail drill-down).
- `resources_screen` → **Explore** (rebuild to 70-explore: featured practice, "your markers explained", article rows, 988).
- `journal_screen` → **Journal** sub-screen (reachable from Today/Profile; design tab bar has no Journal tab).
- `clinician_dashboard` → **Provider portal** (expand to 76/80: requests, worth-a-look, roster, shared readings, settings).
- Safety → folded into Explore's crisis line + kept as a reachable route.
- NEW top tabs: **Trends**, **Profile**, center **[+] Add**.

## Phases
- **P12 — IA restructure (FOUNDATION):** 5-slot bottom bar Today/Trends/[+]/Explore/Profile (design nav grammar); wire existing screens (Today=dashboard, Explore=resources shell, Profile shell, Journal as sub-route); Trends + Profile as calm shells; center [+] opens the Add-sheet stub. All 63 tests green (update nav-coupled tests). Ref: `18-dashboard-mobile`, `30-add-sheet-mobile`, `31-profile-mobile`, `70-explore-mobile`.
- **P13 — Login + onboarding fidelity:** match `LoginScreen` (built without a mock) + welcome/onboarding to `42-onboarding-welcome`, `60-onboarding-email`, `62-onboarding-verify`. Real-auth already wired; this is visual.
- **P14 — Sleep detail + Trends (sleep-only):** `21-sleep-detail-mobile` drill-down from Today; Trends = 30-day score trend + weekly averages + consistency heatmap over sleep (`20-trends-mobile`, `13-consistency-heatmap`).
- **P15 — Explore rebuild + Article reader:** `70-explore-mobile` + `72-article-mobile`; fold crisis/988.
- **P16 — Profile + Settings + Notifications:** `31-profile`, `52/54-settings`, `48-notifications-mobile`.
- **P17 — Sharing flow + Provider portal + Weekly report:** `82-87` sharing invite flow (⚠ journal stays hidden per contract — strip journal from shareable scopes), `76/80/96` provider portal, `94-weekly-report`. Note: `acceptInvite` needs a Cloud Function (Blaze) — build UI, guard the accept step.
- **Deferred (documented):** wearable screens above.

Each phase: build against the exact mock with exact values → verification bar (`dart format` · `flutter analyze` · `flutter test` · `flutter build web`) → fidelity spot-check → commit. Worktrees off; sequential on `design/v1.1-experience`.
