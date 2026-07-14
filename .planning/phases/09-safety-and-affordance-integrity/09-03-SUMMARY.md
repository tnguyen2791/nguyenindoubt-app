---
phase: 09-safety-and-affordance-integrity
plan: 03
subsystem: ui
tags: [flutter, dart, firestore-rules, journal, privacy, empty-state]

# Dependency graph
requires:
  - phase: 08-design-system
    provides: shared EmptyState, PillTone, NidSpace/NidColors tokens
  - phase: 04-firebase-privacy-rules
    provides: journalEntries `delete: if ownsDoc()` rule reused unchanged
provides:
  - AppRepository.deleteJournalEntry({requesterUserId, entryId}) + InMemory/Firebase impls
  - NguyenInDoubtState.deleteJournalEntry(id) with refetch-and-notify
  - Journal EmptyState (private, non-shared copy) + per-entry confirmed delete UI
  - Firestore rules test proving owner-only journal deletion
affects: [phase-13-motion (toast/animated delete feedback deferred here)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Repository delete mirrors ownership guard of read/add (_ensurePatientOwnsData / server ownsDoc())"
    - "Destructive UI gated by a confirmation AlertDialog reusing the demo-reset pattern"

key-files:
  created:
    - test/journal_delete_test.dart
  modified:
    - lib/repositories/app_repository.dart
    - lib/repositories/firebase_app_repository.dart
    - lib/state/app_state.dart
    - lib/screens/journal_screen.dart
    - test/firestore/firestore_rules.test.mjs

key-decisions:
  - "No firestore.rules change — existing journalEntries `delete: if ownsDoc()` (Phase 4) already enforces owner-only delete; the plan only adds a rules test proving it."
  - "InMemory missing-id delete is an idempotent no-op that returns before the ownership check (nothing to own)."
  - "Delete confirmation is a dialog now; animated/toast feedback stays deferred to Phase 13."

patterns-established:
  - "Owner-only mutation: interface guard (_ensurePatientOwnsData) + server ownsDoc(), proven by both Dart and rules tests."
  - "Journal delete has no clinician code path — privacy contract keeps journal patient-only."

requirements-completed: [SAFE-03]

coverage:
  - id: D1
    description: "AppRepository.deleteJournalEntry across interface + InMemory (ownership guard, persist, idempotent no-op) and Firebase (_requireSignedInAs + doc delete, no clinician path)."
    requirement: SAFE-03
    verification:
      - kind: unit
        ref: "test/journal_delete_test.dart#InMemoryAppRepository.deleteJournalEntry"
        status: pass
    human_judgment: false
  - id: D2
    description: "NguyenInDoubtState.deleteJournalEntry(id) refetches journal entries and notifies listeners, mirroring addJournalEntry."
    requirement: SAFE-03
    verification:
      - kind: automated_ui
        ref: "test/journal_delete_test.dart#confirming delete removes the entry; cancel keeps it"
        status: pass
    human_judgment: false
  - id: D3
    description: "Journal renders the shared private EmptyState (non-shared copy, no delete control) when there are no entries."
    requirement: SAFE-03
    verification:
      - kind: automated_ui
        ref: "test/journal_delete_test.dart#empty journal shows the private EmptyState"
        status: pass
    human_judgment: false
  - id: D4
    description: "Per-entry delete opens a permanent on-device removal confirmation dialog; cancel keeps the entry, confirm removes it."
    requirement: SAFE-03
    verification:
      - kind: automated_ui
        ref: "test/journal_delete_test.dart#confirming delete removes the entry; cancel keeps it"
        status: pass
    human_judgment: false
  - id: D5
    description: "Firestore rules prove patient-a can delete journalEntries/journal-a while patient-b and an accepted-link clinician-a cannot."
    requirement: SAFE-03
    verification:
      - kind: integration
        ref: "test/firestore/firestore_rules.test.mjs#lets only the owning patient delete a journal entry"
        status: pass
    human_judgment: false

# Metrics
duration: 15min
completed: 2026-07-06
status: complete
---

# Phase 9 Plan 03: Journal EmptyState + Owner-Only Delete Summary

**SAFE-03 completes the private-journal promise: a calm private EmptyState plus per-entry delete gated by a permanent-removal confirmation dialog, plumbed honestly through `NguyenInDoubtState` → both `AppRepository` implementations, with owner-only deletion locked by Dart and Firestore-rules tests.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-06T13:04:00Z (approx)
- **Completed:** 2026-07-06T20:07:22Z
- **Tasks:** 3
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments
- Added `AppRepository.deleteJournalEntry({requesterUserId, entryId})` to the interface and both implementations: InMemory enforces ownership via `_ensurePatientOwnsData`, persists the removal, and no-ops idempotently on a missing id; Firebase guards with `_requireSignedInAs` and deletes the doc, letting the server `ownsDoc()` rule enforce owner-only with no clinician path.
- Plumbed `NguyenInDoubtState.deleteJournalEntry(id)` (refetch + `notifyListeners`, mirroring `addJournalEntry`).
- Journal now shows the shared Phase 8 `EmptyState` (lock icon, "Your journal stays private" / "Start your first entry — only you can read it.") when empty, and each entry gains a `delete_outline` control gated by a permanent on-device-removal confirmation dialog.
- Locked owner-only deletion with a new `test/journal_delete_test.dart` (3 repo unit + 2 widget cases) and a new Firestore rules case proving patient-a deletes while patient-b and an accepted-link clinician-a cannot.

## Task Commits

Each task was committed atomically (TDD: test → feat):

1. **Task 1: Repository delete across interface + both impls** — `735be72` (test, RED), `bca7dd6` (feat, GREEN)
2. **Task 2: State plumbing + journal EmptyState + confirmed delete UI** — `c9d2ec7` (test, RED), `362e918` (feat, GREEN)
3. **Task 3: Owner-only journal delete in the Firestore rules test** — `7341a43` (test)

_TDD gate compliance: each behavior-adding task has a preceding `test(...)` commit before its `feat(...)` commit in git log._

## Files Created/Modified
- `test/journal_delete_test.dart` - New: InMemory owner-only delete unit cases + journal EmptyState/confirmed-delete widget cases (local onboarding helper replica per harness note).
- `lib/repositories/app_repository.dart` - Interface method + InMemory impl (ownership guard, persist, idempotent no-op).
- `lib/repositories/firebase_app_repository.dart` - Firebase impl (`_requireSignedInAs` then doc delete; server `ownsDoc()` enforces owner-only).
- `lib/state/app_state.dart` - `deleteJournalEntry(id)` refetch-and-notify.
- `lib/screens/journal_screen.dart` - EmptyState branch + per-entry delete `IconButton` and `_confirmDelete` dialog.
- `test/firestore/firestore_rules.test.mjs` - New `it(...)` proving owner-only journal deletion.

## Decisions Made
- **No firestore.rules change.** The `journalEntries` block already grants `delete: if ownsDoc()` (Phase 4). Confirmed present (line 116) and reused; the plan only adds a rules test proving it, preserving the standing privacy contract exactly.
- **Idempotent missing-id delete** returns before the ownership check because a non-existent entry has no owner to enforce.
- **Confirmation dialog, not toast.** A permanent-removal confirm dialog is the whole safety gate for now; animated/toast feedback stays deferred to Phase 13 per CONTEXT.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None. As flagged in the plan's harness note, `_completePatientOnboarding` in `test/widget_test.dart` is file-private, so `test/journal_delete_test.dart` replicates it locally (as 09-02's test does).

## Verification
Plan-level bar — all green:
- `dart format lib test` — Formatted 25 files (0 changed)
- `flutter analyze` — No issues found!
- `flutter test` — 36 passed (31 prior + 5 new)
- `flutter build web` — Built build/web
- `npm run test:firestore-rules` — 8 passed

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SAFE-03 complete; this is the final Phase 9 plan. Journal is now fully private-with-control (EmptyState + owner-only delete) across in-memory and Firebase paths.
- Deferred to Phase 13: animated/toast feedback for delete and other actions.

## Self-Check: PASSED

- FOUND: test/journal_delete_test.dart
- FOUND: .planning/phases/09-safety-and-affordance-integrity/09-03-SUMMARY.md
- FOUND commits: 735be72, bca7dd6, c9d2ec7, 362e918, 7341a43

---
*Phase: 09-safety-and-affordance-integrity*
*Completed: 2026-07-06*
