---
phase: 17
plan: 17
subsystem: profile-settings-notifications
tags: [profile, settings, goals, notifications, preferences, ui, design-buildout]
requires:
  - Profile tab shell (P12)
  - ReadinessSummary + multi-signal series (P13/P14)
  - detail_screens fadeDetailRoute + Readiness/Sleep detail (P14)
  - Explore openSafety/openArticle route patterns (P16)
provides:
  - UserPreferences model (goals + notification prefs, patient-owned)
  - Local per-user preference persistence (InMemory + Firebase + rules)
  - Settings Goals screen (52) with persisted steppers + data-informed hints
  - Settings Notifications screen (54) with persisted toggles + quiet hours
  - Notifications feed (48) with Today/Yesterday/This week sections
  - NidToggle (.sw pill) primitive
affects:
  - lib/screens/tab_shells.dart (Profile wiring)
  - lib/state/app_state.dart (preferences load/save + recent averages)
tech-stack:
  added: []
  patterns:
    - Patient-owned on-device preferences (never clinician-visible)
    - Stored-preference-only notifications (no OS scheduling, no analytics)
    - Gentle-fade push routes from Profile (project motion rule)
key-files:
  created:
    - lib/screens/settings_screens.dart
    - lib/screens/notifications_feed.dart
    - test/settings_notifications_test.dart
  modified:
    - lib/models/app_models.dart
    - lib/repositories/app_repository.dart
    - lib/repositories/firebase_app_repository.dart
    - lib/state/app_state.dart
    - lib/screens/tab_shells.dart
    - lib/screens/common_widgets.dart
    - lib/theme/tokens.dart
    - firestore.rules
key-decisions:
  - Notification toggles record stored preferences only — no OS scheduling, no analytics — documented in-code and in the closing note
  - Kept the Profile group order Account/Sharing/Preferences/Support (existing widget_test asserts ACCOUNT+SHARING above the fold); mock's Account/Preferences/Sharing/Support order deviated from to keep the suite green
  - Goals hints lead with the patient's OWN recent averages (30-night sleep, 7-day activity kcal) and stay non-shaming; honest empty copy before any import
  - Quiet-hours times are display-only stored prefs (a real time picker lands with delivery scheduling in a later phase)
  - Sharing/Trends notification targets open a calm placeholder (P18 sharing flow not built here); readiness/sleep items open the real detail screens
requirements-completed: []
coverage:
  - deliverable: "Profile (31) grouped rows with Goals/Notifications wired; Journal + Safety + Sign out reachable"
    verification:
      - kind: test
        ref: "test/settings_notifications_test.dart#Notifications feed renders all three sections + opens a detail"
        status: pass
      - kind: test
        ref: "test/widget_test.dart#bottom nav exposes the Today/Trends/[+]/Explore/Profile IA"
        status: pass
    human_judgment: false
  - deliverable: "Settings Goals (52) persisted steppers + data-informed hints"
    verification:
      - kind: test
        ref: "test/settings_notifications_test.dart#Goals steppers adjust and persist the sleep goal + step target"
        status: pass
      - kind: test
        ref: "test/settings_notifications_test.dart#Goals hint leads with the patient's own recent sleep average"
        status: pass
    human_judgment: false
  - deliverable: "Settings Notifications (54) persisted toggles + quiet hours (prefs only)"
    verification:
      - kind: test
        ref: "test/settings_notifications_test.dart#Notification toggles flip and persist stored preferences"
        status: pass
    human_judgment: false
  - deliverable: "Notifications feed (48) sections render; items open referenced screens"
    verification:
      - kind: test
        ref: "test/settings_notifications_test.dart#Notifications feed renders all three sections + opens a detail"
        status: pass
    human_judgment: false
  - deliverable: "Preferences persist locally per-user; privacy-guarded (patient-owned)"
    verification:
      - kind: test
        ref: "test/settings_notifications_test.dart#preferences round-trip across an app recreation (persisted)"
        status: pass
      - kind: test
        ref: "test/settings_notifications_test.dart#repository rejects cross-patient preference access (privacy)"
        status: pass
    human_judgment: false
  - deliverable: "Visual fidelity to mocks 31/52/54/48 (calm grammar, no emoji, non-diagnostic voice)"
    verification: []
    human_judgment: true
    rationale: "Pixel-level fidelity to the HTML mocks is a visual judgment no test asserts; grammar/token reuse verified in code, but the calm feel is human-verified on device."
duration: 11 min
completed: 2026-07-12
status: complete
---

# Phase 17 Plan 17: Profile + Settings + Notifications Summary

Built out the Profile tab from a shell into the design's Profile + Settings +
Notifications surfaces: a patient-owned `UserPreferences` model with local
per-user persistence, a Goals settings screen (52) with data-informed hints, a
Notifications settings screen (54) with toggles + quiet hours (stored
preferences only — no OS scheduling, no analytics), and a display-only
Notifications feed (48). All wired via gentle-fade push routes from Profile;
Journal, Safety, and Sign out stay reachable; clinician surface unchanged.

## Accomplishments

- **UserPreferences model + persistence (17-01):** New plain-data model (sleep
  goal minutes, step target, six notification toggles, quiet hours) persisted
  per-user via `InMemoryAppRepository` (SharedPreferences, schemaVersion 4,
  defaults when unset) and `FirebaseAppRepository` (`userPreferences`
  collection), with a matching patient-owned `firestore.rules` block. State
  loads prefs on patient refresh and exposes `recentSleepAverageHours` /
  `recentActivityAverageKcal` for goal hints plus an `updatePreferences`
  mutator.
- **Settings Goals (52) (17-02):** Sleep goal (15-minute steps, 5h–11h) and
  activity step-target (500-step steps, 2k–20k) steppers persisting on tap,
  each with a calm hint that leads with the patient's OWN recent average
  (honest empty copy before any import) and a closing "goals shape guidance
  only — they never change your scores" note.
- **Settings Notifications (54) (17-02):** Daily + Signals toggle groups and a
  Quiet hours card (enable toggle + From/Until time pills). Every toggle writes
  a stored preference only; the closing note keeps the "never streaks, never
  guilt" promise. New `NidToggle` (`.sw` pill) primitive.
- **Notifications feed (48) (17-02):** Seeded Today / Yesterday / This week
  sections of calm, non-diagnostic items; readiness/sleep items open the real
  detail screens, sharing/trends items open a calm placeholder (P18 sharing
  lands later). Display-only — no delivery.
- **Profile (31) wiring (17-02):** Goals & targets → Goals settings,
  Notifications → Notification settings, a header bell → Notifications feed;
  live preference values on rows; Journal, Safety, and Sign out all still
  reachable.
- **Tests (17-03):** Six new tests covering steppers+persistence, the
  data-informed hint, toggle persistence, feed sections + detail navigation,
  cross-recreation persistence, and the cross-patient privacy guard.

## Verification

- `dart format lib test` → 0 unexpected changes
- `flutter analyze` → No issues found!
- `flutter test` → 107 passed (101 baseline + 6 new)
- `flutter build web` → Built build/web

## Deviations from Plan

**1. [Rule 2 - Missing critical] FirebaseAppRepository + firestore.rules
preference support**
- **Found during:** 17-01 (analyze failed: `FirebaseAppRepository` missing the
  new abstract methods)
- **Issue:** Adding `getUserPreferences`/`saveUserPreferences` to the
  `AppRepository` contract left the Firebase implementation non-concrete, and a
  new patient-owned collection needs a security rule (the P13 readiness
  precedent).
- **Fix:** Implemented both methods over a `userPreferences` Firestore
  collection (patient-owned, doc id == uid + matching `userId` field) and added
  a patient-only `firestore.rules` match block (never clinician-visible).
- **Files modified:** lib/repositories/firebase_app_repository.dart,
  firestore.rules
- **Verification:** analyze clean; rule mirrors readiness (ownsDoc/willOwnDoc)
- **Commit:** e521b32

**Group-order note (not a deviation from correctness):** Kept the existing
Profile group order (Account / Sharing / Preferences / Support) rather than the
mock's Account / Preferences / Sharing / Support, because the existing
`widget_test` asserts ACCOUNT + SHARING above the fold. Row grammar, kickers,
and wiring match the design.

**Total deviations:** 1 auto-fixed (1 Rule 2). **Impact:** none to scope — the
Firebase/rules work keeps the signed-in path and the privacy contract intact.

## Notifications: stored preferences only

The Notifications settings toggles and quiet hours set **stored preferences
only**. This app does not yet schedule real OS notifications and runs no
analytics/telemetry — nothing here wakes a background job. The feed (48) is
seeded/static and display-only (no real delivery). A future delivery layer can
honor these preferences.

## Known Stubs

- **Notifications feed items are seeded/static** (`notifications_feed.dart`,
  `seedNotificationSections`) — intentional per P17 scope ("seeded/static for
  now"). Real delivery is out of scope; documented here for the verifier.
- **Quiet-hours times are display-only** — a real time picker lands with
  delivery scheduling in a later phase. Intentional.
- **Sharing/Trends notification targets open a calm placeholder** — the sharing
  flow is P18; readiness/sleep targets open the real detail screens.

## Standing rules honored

- Clinician surface unchanged — readiness/preferences stay patient-only
  (sleep-summaries-only privacy contract intact).
- No streaks / no guilt / non-diagnostic voice; no emoji; gentle-fade routes;
  Inter 400–700; friendly copy only.
- Safety stays reachable (Profile Support group); Journal + Sign out reachable.
- No analytics/telemetry; on-device compute.
- STATE.md / ROADMAP.md untouched (per plan).

## Self-Check: PASSED

- Created files exist on disk: lib/screens/settings_screens.dart,
  lib/screens/notifications_feed.dart, test/settings_notifications_test.dart —
  all FOUND.
- Commits present: a9210d8 (17-01), e521b32 (17-02), c1548a9 (17-03).
