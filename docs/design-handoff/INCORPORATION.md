# Design Handoff — Incorporation Notes

**Imported:** 2026-07-11 from the owner's export of the Claude Design project
"NguyenInDoubt — Data Displays (Oura-style)" (`d0b3eb3c-3d40-4a5a-b1d5-5ab7a8924baf`).
This bundle SUPERSEDES the remote project snapshot used for Phase 11 planning: it
carries 102 wired screens (remote had 73) plus `brand-readme.md`, the full handoff
`README.md`, and reference component sources (`components/*.txt`).

## What's new vs. the remote snapshot Phase 11 was built from

| Screens | Flow | Maps to |
|---------|------|---------|
| 74–77, 80–81, 96–97, 100–101 | Provider portal: sign-in, dashboard (requests / "Worth a look" / roster), shared readings, provider settings | Phase 12 (sharing), extends the clinician surface |
| 82–93, 102–103 | User-side sharing: request → choose scopes → send → status (waiting/accepted/declined), manage/pause | **Phase 12 ground truth** |
| 78–79 | Manage sharing (per-category toggles, "Pause sharing") | Phase 12 |
| 94–95 | Weekly report ("patterns, not grades") | Phase 12/13 candidate |
| 98–99 | Activity detail | Out of current milestone (wearable-product scope) |
| foundations/04 | Printable user welcome one-pager | Marketing/onboarding collateral |

Tokens, components, voice rules, and the Today/trends/detail screens are IDENTICAL
in spirit and values to what Phases 8–11 already implemented — no retrofit needed.
The provider dashboard's "Worth a look · not alerts, just patterns" + closing
humility copy confirm Phase 11-03's directional stat-delta treatment.

## ⚠ CONFLICT to resolve at Phase 12 discuss — do not silently adopt

The handoff's consent model allows **opt-in journal-TAG sharing** (scope strings
like "scores · sleep · journal"; a "Worth a look" card citing journal tags). The
project's standing privacy contract says **clinician never sees journal content,
period** (test-asserted, verbatim consent copy). Until the owner explicitly
revises that rule, the standing contract WINS: any Phase 12 planning against
these screens must strip journal from the shareable scopes and keep the
"Hidden: journal entries…" disclosures intact.

Also note: the handoff describes the full wearable product (ring pairing, OTP
auth, HRV/temperature, activity). The current MVP scope (mock sleep import,
local demo mode) is narrower — treat wearable-only surfaces as reference, not
requirements.

## Consent rules worth lifting verbatim into Phase 12 (compatible with contract)

- Sharing is read-only; one provider; user sees everything the provider sees.
- Pause / cancel / decline generate NO notification to the other party.
- Nothing shared until both sides opt in and accept.
- Sharing state machine: none → requested(offer) → active(scopes) | declined;
  active → paused → active.
