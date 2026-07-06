# Phase 1: Demo Promise Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-06
**Phase:** 1-Demo Promise Hardening
**Areas discussed:** Local demo state, responsive demo surfaces, safety boundaries, clinician privacy proof

---

## Local Demo State

| Option | Description | Selected |
|--------|-------------|----------|
| Explanation only | Add copy explaining device-local storage, but no reset affordance. | |
| Reset plus explanation | Add both local-demo copy and a reset path for persisted demo state. | yes |
| Defer to auth phase | Leave state clarity until Phase 2 session work. | |

**User's choice:** User answered "Done"; interpreted as ready to write context with conservative decisions.
**Notes:** Reset plus explanation best satisfies DEMO-04 without entering production auth or backend scope.

---

## Responsive Demo Surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow polish only | Fix obvious mobile overflow and clipped content while preserving layout. | yes |
| Full redesign | Rework navigation, cards, charting, and hierarchy across the app. | |
| Defer visual work | Leave current layouts unchanged until later phases. | |

**User's choice:** User answered "Done"; interpreted as ready to write context with conservative decisions.
**Notes:** Phase 1 should harden journal, resources, safety, and clinician surfaces without changing the design system.

---

## Safety Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Copy only | Keep safety page educational and leave actions as inert demo buttons. | |
| External routing | Route urgent support actions outward while keeping no-monitoring copy explicit. | yes |
| Build in-app crisis flow | Add crisis triage, risk scoring, chat, or safety-plan behavior. | |

**User's choice:** User answered "Done"; interpreted as ready to write context with conservative decisions.
**Notes:** External routing supports DEMO-05 while avoiding emergency-monitoring scope creep.

---

## Clinician Privacy Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Copy only | Rely on clinician dashboard labels that journals are hidden. | |
| Copy plus tests | Preserve sleep-only UI, improve copy where needed, and keep privacy tests focused. | yes |
| Expand lifecycle tests now | Cover pending, revoked, malformed, and missing links in full detail. | |

**User's choice:** User answered "Done"; interpreted as ready to write context with conservative decisions.
**Notes:** Copy plus tests keeps Phase 1 aligned with DEMO-02 and avoids pulling Phase 3 privacy-contract expansion forward.

---

## Claude's Discretion

- Choose exact placement for local-demo explanation and reset controls based on the existing app shell.
- Use existing shared UI components and Material controls.
- Add focused tests for any changed behavior.

## Deferred Ideas

- Production session/auth behavior.
- Full consent lifecycle and invite validation.
- Broad privacy contract hardening beyond Phase 1 regression coverage.
- Real health providers and live Firebase storage.
