# Phase 9: Safety and Affordance Integrity - Context

**Gathered:** 2026-07-06
**Status:** Ready for planning
**Source:** Synthesized from the v1.1 design critique (IA/affordances lens) + REQUIREMENTS SAFE-01–03

<domain>
## Phase Boundary

Make controls do what they look like they do — and make the one screen where latency is dangerous (Safety) take real action in a single tap. Three concerns: (1) crisis actions actually launch the dialer/SMS; (2) cards signal tappability truthfully (disabled ≠ silently dead); (3) the journal gets an empty state and per-entry delete. This is the milestone's highest-impact, mostly-independent phase — it builds on the Phase 8 design system (tokens, PillTone, EmptyState).

In scope: the Safety screen crisis buttons, the clinician invite-status rows' disabled affordance, and the journal screen's empty state + delete (with the state/repository plumbing delete requires).

Out of scope (later phases): consent IA / sharing destination (Phase 12), onboarding (Phase 10), insights (Phase 11), motion/transitions & SnackBars (Phase 13 — a delete *confirmation dialog* is in scope here as a safety gate, but animated toasts are Phase 13). Do not restyle unrelated screens.
</domain>

<decisions>
## Implementation Decisions

### SAFE-01 — crisis actions dial/text directly
- Add the `url_launcher` package (pubspec). Wire the Safety screen's crisis controls to launch real intents instead of showing an explanatory `AlertDialog`:
  - "Call or text 988" → offer `tel:988` (call) and `sms:988` (text) — the 988 Suicide & Crisis Lifeline. If a single control, launch `tel:988`; a secondary affordance covers `sms:988`.
  - Emergency → `tel:911`.
- Keep the existing educational copy as **secondary** text near the buttons (not as a blocking dialog). Use `launchUrl(..., mode: LaunchMode.externalApplication)`; guard with `canLaunchUrl` and fail gracefully (a calm inline message) if unavailable — never crash, never auto-dial without the user tapping.
- Constraint: this hands off to the OS dialer/messages — it does NOT place the call itself and must NOT imply in-app monitoring or emergency dispatch. Do not add any "we contacted…" language. On web, `tel:`/`sms:` may no-op — degrade to showing the number as selectable text.

### SAFE-02 — affordance truth
- Clinician invite-status rows (`clinician_dashboard.dart`): an accepted row is a tappable `InkWell` with a chevron; a pending/revoked/expired row currently reuses the identical card with `onTap: null` and no disabled styling. Make non-actionable rows visibly distinct — reduced opacity (e.g. `Opacity`/muted foreground), no ink ripple, and let the status pill carry the "why" (pending/revoked). Reserve the tappable card + chevron for rows that respond.
- General rule: any card that looks tappable must be; anything inert must not present hover/ripple affordances.

### SAFE-03 — journal empty state + delete
- Journal (`journal_screen.dart`) currently trails into void when empty — add the shared `EmptyState` (icon + calm "start your first private entry" copy; do not imply anyone else can read it).
- Add **per-entry delete** with a confirmation dialog (reuse the demo-reset confirm pattern: state the entry is permanently removed from this device). Plumb it through: `NguyenInDoubtState.deleteJournalEntry(id)` → `AppRepository.deleteJournalEntry(...)` implemented in **both** `InMemoryAppRepository` and `FirebaseAppRepository` to keep the interface honest. Journal is patient-only — delete is the patient removing their own entry.
- If the Firebase path / firestore.rules are touched to permit a patient to delete their **own** journal entry, add/extend a rule + a rules test (patient can delete own journal; clinician/other cannot). Preserve the standing privacy contract exactly.

### Claude's Discretion
- Exact Safety button layout (one combined 988 control with call+text, or two controls), icon choices, and copy wording of the new empty-state / delete-confirm strings (keep them calm, non-clinical, non-monitoring).
- Whether delete confirmation is a dialog now (fine) — animated toast feedback is deferred to Phase 13.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Files this phase edits
- `lib/screens/resources_screen.dart` — contains `SafetyScreen` (crisis buttons) + Guides. (Confirm exact location; `app_shell.dart` also references `SafetyScreen`.)
- `lib/screens/clinician_dashboard.dart` — invite-status rows (`_PatientList`): tappable vs. inert row affordance.
- `lib/screens/journal_screen.dart` — empty state + per-entry delete UI.
- `lib/state/app_state.dart` — has `addJournalEntry`; add `deleteJournalEntry`.
- `lib/repositories/app_repository.dart` (interface) + `lib/repositories/firebase_app_repository.dart` + the in-memory impl — add a journal delete method.
- `firestore.rules` + `test/firestore/firestore_rules.test.mjs` — only if the delete path touches Firebase; keep patient-owned deletion, run `npm run test:firestore-rules`.
- `pubspec.yaml` — add `url_launcher`.
- `lib/screens/common_widgets.dart` — reuse `EmptyState`, `PillTone`, tokens from Phase 8. `test/widget_test.dart` — keep existing assertions green (safety fallback copy is asserted).

### Design direction
- `.planning/REQUIREMENTS.md` → SAFE-01..SAFE-03.
- Standing constraints: no analytics; clinician sleep-only, post-consent, never journals; non-diagnostic; no emergency monitoring/dispatch; keep demo/local-only disclosure.
</canonical_refs>

<specifics>
## Specific Ideas
- Critic's sharpest line: "'Call or text 988' doesn't call — a button labeled with an action that instead shows a paragraph is an affordance lie, and in a crisis you've added a tap + a read." SAFE-01 is the priority.
- Verification bar: `dart format lib test`, `flutter analyze` (no issues), `flutter test` (keep green — add tests for delete + the launcher wiring behind an injectable seam so tests don't actually dial), `flutter build web`. If firestore touched: `npm run test:firestore-rules`.
- Make the `url_launcher` call testable via a thin injectable launcher (so widget tests verify the correct URI is requested without launching anything).
</specifics>

<deferred>
## Deferred Ideas
- Animated/toast feedback for delete & actions → Phase 13.
- Consent/sharing destination → Phase 12.
- Onboarding, splash → Phase 10.
- Insight surfaces → Phase 11.
</deferred>

---

*Phase: 09-safety-and-affordance-integrity*
*Context synthesized: 2026-07-06 from the v1.1 design critique*
