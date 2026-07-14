# Design Buildout Roadmap — v1.2 "Full IA + Wearable Core"

**Created:** 2026-07-12 · **Revised:** 2026-07-12 (wearables are CORE, not deferred)
**Why:** Fidelity audit found the app is a ~5-screen sleep MVP (tabs: Sleep/Journal/Guides/Safety) while the Claude Design project is a ~33-screen Oura-style product (tabs: **Today · Trends · [+] · Explore · Profile**). Tokens are byte-identical — this is a **coverage + IA + data-scope gap**, not styling drift. Owner decisions (2026-07-12): **adopt the full design IA**, and **the wearable signals are the core of the app — build them out** (readiness, HRV, resting HR, respiratory rate, temperature, activity, SpO₂), not sleep-only.
**Design source of truth:** Claude Design project `d0b3eb3c-…` + local mirror `docs/design-handoff/screens/*`. Tokens already match `lib/theme` hex-for-hex.

## The data reality (this is the real work)
The real HealthKit/Health Connect pipeline EXISTS (`health` package, `PlatformHealthDataProvider`) but is deliberately **narrowed to sleep** (`_sleepTypes`, `fetchSleepSamples`, sleep-only permissions; `fetchAvailableMetrics → [sleep]`). `MetricType` already lists `{sleep, steps, heartRate, hrv, mindfulMinutes, medication}` but only sleep is fetched. `DailySummary` is sleep-only (`sleepDurationHours`, `sleepQualityProxy`, `trendFlag`).
**Build-out = widen the pipeline to the full signal set + real multi-signal readiness + the screens that show it.** The fake `sleepQualityProxy` becomes a genuine multi-factor **readiness** (evolves the Phase-11 ring with REAL signals). Clinician stays **sleep-summaries-only** per the standing privacy contract (readiness-sharing is a separate owner ruling, not assumed).

## Verification reality (honest)
Real HRV/temperature/SpO₂ can't be fully exercised on a plain iOS simulator (limited HealthKit sample data). So: the pipeline + scoring are **unit-tested via an expanded `MockHealthDataProvider`** (deterministic multi-signal data) and analyzer/build gates; **real-signal display is verified on the device (TryCare) with real Health data**. Each phase states which bar applies.

## Standing rules (never violate)
Clinician sees sleep summaries only, never journal; crisis/Safety stays reachable + folded into Explore's 988 line; no analytics/telemetry; on-device compute; Inter 400–700; gentle motion; friendly errors only; non-diagnostic ("observational, never labels the person").

## IA mapping (existing → design)
`patient_dashboard` → **Today** (real readiness ring + contributors) · `resources_screen` → **Explore** (rebuild) · `journal_screen` → Journal sub-route · `clinician_dashboard` → **Provider portal** (expand) · Safety → Explore 988 + reachable route · NEW top tabs **Trends**, **Profile**, center **[+] Add**.

## Phases
- **P12 — IA restructure (FOUNDATION):** 5-slot bottom bar Today/Trends/[+]/Explore/Profile; wire existing screens; calm shells for Trends/Profile; [+] add-sheet stub. *(RUNNING.)* Bar: format/analyze/test/build web.
- **P13 — Wearable signal pipeline + readiness (FOUNDATION, the core):**
  1. Expand `MetricType` (add restingHeartRate, respiratoryRate, temperature, bloodOxygen, activeEnergy; wire the existing steps/heartRate/hrv).
  2. Widen `HealthDataProvider` to a generic multi-metric fetch; expand `PlatformHealthDataProvider` permissions + reads to the full HealthKit/Health Connect type set; expand `MockHealthDataProvider` to emit deterministic multi-signal data.
  3. New `ReadinessSummary` model (readiness score + per-signal contributors: HRV, resting HR, respiratory rate, temp deviation, prior-day activity, sleep) — replaces the fake `sleepQualityProxy`. Persist to Firestore (extend `FirebaseAppRepository` + `InMemoryAppRepository` + rules); keep clinician sleep-only.
  4. Real multi-factor readiness scoring (pure, unit-tested; observational, non-diagnostic).
  Bar: format/analyze/test (expanded mock) /build web. Device verification deferred to P14 display.
- **P14 — Today (real readiness) + detail drill-downs:** Today shows the real readiness ring + contributors (`18/28`); Sleep detail (`21`), Readiness detail (`28`), Activity detail (`98`), overnight HR (`08`). Device-verify with real Health data.
- **P15 — Trends (all signals):** `20/24` + `13-consistency-heatmap`, `06-trend-line`; Sleep/Readiness/Activity × Week/Month/Quarter over real signals.
- **P16 — Explore rebuild + Article reader** (`70`, `72`) + crisis/988.
- **P17 — Profile + Settings + Notifications** (`31`, `52/54`, `48`).
- **P18 — Sharing flow + Provider portal + Weekly report** (`82–87` — ⚠ journal stays hidden per contract; `76/80/96`; `94`). `acceptInvite` needs a Cloud Function (Blaze) — build UI, guard the accept.
- **P13-login (interleave):** login/onboarding fidelity vs `42/60/62` (the new LoginScreen was built without a mock) — slot right after P12 since it shares `app_shell`/`login_screen`.

Each phase: build against the exact mock/spec with exact values → verification bar → fidelity spot-check → commit. Worktrees off; sequential on `design/v1.1-experience`.
