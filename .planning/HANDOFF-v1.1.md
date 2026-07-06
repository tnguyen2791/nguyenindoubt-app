# Handoff — v1.1 "Experience & Insight" milestone (NguyenInDoubt Flutter app)

**Written:** 2026-07-06 by the Claude session that set up this milestone. Safe to hand to a fresh Codex session.

## Where things stand — CLEAN, ready to resume

- **Branch:** `design/v1.1-experience` (forked off the merged v1.0 content). **Working tree is clean — everything is committed.**
- **Milestone v1.1** = 6 design/UX phases (8–13) derived from a 5-lens senior design critique (visual/brand, IA & affordances, onboarding & splash, data-viz & insights, motion & micro-UX). Roadmap + requirements live in `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` (v1.1 section: requirement groups DS / SAFE / ONB / INS / SHARE / MOT).

| Phase | Status |
|-------|--------|
| **8 — Design System Foundations** (DS-01..05) | ✅ shipped + verified (5/5), 12 commits |
| **9 — Safety & Affordance Integrity** (SAFE-01..03) | ✅ shipped + verified (9/9) |
| **10 — Brand Arrival & Guided Onboarding** (ONB-01..04) | 📋 **planned + plan-checker PASS** (blocker fixed) — **ready to execute** |
| **11 — Insightful Data Displays** (INS-01..05) | ⏳ not started (context not yet written) |
| **12 — Sharing as a First-Class Flow** (SHARE-01..05) | ⏳ not started |
| **13 — Motion & Feedback Choreography** (MOT-01..04) | ⏳ not started |

STATE.md currently reads `current_phase: 09 / completed`. Phase 10 plans are committed under `.planning/phases/10-brand-arrival-and-guided-onboarding/` (10-01/02/03-PLAN.md + 10-CONTEXT.md).

## RESUME HERE

**Next action:** execute Phase 10 → `/gsd-execute-phase 10` (or the equivalent GSD command in Codex). It runs 3 strictly-sequential waves (10-01 splash seam → 10-02 CTA rename → 10-03 empty-state). Then verify, mark complete, and continue the loop for Phases 11 → 12 → 13.

### The per-phase loop that's been working
For each remaining phase: **synthesize CONTEXT** (from the matching critic lens — see roast summaries below) → **plan** (gsd-planner) → **plan-checker gate** → **execute** (gsd-executor, one plan at a time) → **verify** (gsd-verifier) → mark complete in STATE + ROADMAP → next.

### Critical execution facts (don't relearn these the hard way)
- **Worktrees are OFF for this run** — `worktree.base-check` degrades to sequential because HEAD is an unmerged feature branch (worktree isolation would fork executors from `origin/main`, which LACKS these plans). Run executors **directly on `design/v1.1-experience`, one plan at a time** (no `isolation="worktree"`).
- **Verification bar every plan:** `dart format lib test` · `flutter analyze` (No issues found!) · `flutter test` (currently **36 pass**) · `flutter build web`. Add `npm run test:firestore-rules` on any plan touching `firestore.rules` or the Firebase path.
- **Commit trailers** on every commit:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` (Codex: swap to its own attribution) and a session link.
- Executors must NOT touch STATE.md/ROADMAP.md — the orchestrator marks phases complete via `gsd-tools query state.complete-phase --phase NN` + manual ROADMAP checklist/table edits.
- Phase names use plain "and" (I normalized `&amp;`→`and` so slugs are clean, e.g. `10-brand-arrival-and-guided-onboarding`).

## Standing product constraints (NEVER violate — enforced across all phases)
- No analytics / telemetry / Crashlytics / session replay.
- Clinician sees **sleep summaries only, after accepted consent, never journal content**.
- Keep the **local/demo-only disclosure copy** and **safety/crisis copy** verbatim (tests assert them).
- **Non-diagnostic** — insights stay observational ("less than usual"), never label the person; no emergency monitoring / dispatch implications.
- Gentle motion — screens fade, never pop. Inter font only ships **400/500/600/700** (no w800/w900 glyphs).
- **Design source of truth:** the Claude Design project "NguyenInDoubt — Data Displays (Oura-style)" (id `d0b3eb3c-3d40-4a5a-b1d5-5ab7a8924baf`) — the Oura app is the north star for all graphs/metrics (esp. Phase 11).

## The roast (design critique that drives phases 8–13)
Five senior-designer critic agents reviewed the app; their full transcripts are in this session's task outputs. Phase→lens mapping: 8←visual/brand, 9←IA/affordances, 10←onboarding/splash, 11←data-viz/insights, 12←IA/sharing, 13←motion. Each phase's `NN-CONTEXT.md` already distills the relevant lens into locked decisions — **read the CONTEXT before planning each phase.** Phase 11's known hot decision: *retire vs. rebuild* the redundant "quality proxy" score (currently `sleepHours/8*100` — just last-sleep in disguise) into a real multi-factor non-diagnostic Oura-style ring.

## When all 6 phases land
Open a PR from `design/v1.1-experience` (base `main`) summarizing the milestone. Everything is atomic-committed, so the history is the changelog.
