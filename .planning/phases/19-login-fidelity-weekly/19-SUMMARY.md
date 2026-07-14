---
phase: 19
plan: 19
subsystem: [auth-ui, onboarding, weekly-report]
tags: [design-fidelity, login, otp, weekly-report, patterns-not-grades]
requires: [readiness-series, sleep-summaries, journal-tags, auth-service]
provides: [login-42-62-fidelity, weekly-report-94, weekly-report-service]
affects: [login_screen, notifications_feed, profile, tab_shells]
tech-stack:
  added: []
  patterns:
    - pure-deterministic-service (weekly_report.dart mirrors readiness/trends)
    - hidden-field-OTP-boxes (6-box grammar over one TextField)
    - gentle-fade pushed-route (openWeeklyReport shares fadeDetailRoute)
key-files:
  created:
    - lib/services/weekly_report.dart
    - lib/screens/weekly_report_screen.dart
    - test/weekly_report_test.dart
  modified:
    - lib/screens/login_screen.dart
    - test/login_screen_test.dart
    - lib/screens/notifications_feed.dart
    - lib/screens/tab_shells.dart
decisions:
  - LoginScreen reworked to the 42 welcome + 62 OTP grammar; app keeps
    Google/Apple/Phone providers (Apple gracefully disabled "coming soon").
  - OTP caret is static, not blinking — a repeating animation would break the
    pumpAndSettle the app-pumping suite relies on; the canopy border already
    signals the active box.
  - Weekly report reads the patient's OWN last-week sleep + readiness + journal
    tags; clinician never sees it (sleep-summaries-only contract preserved).
  - app_shell onboarding (_OnboardingScreen/_PatientOnboardingScreen) left
    unchanged — it already honors locked ONB-02/03 and its type is aligned to
    the login/verify scale; touching it risked the tight ONB tests for no gain.
metrics:
  duration: ~40m
  completed: 2026-07-12
status: complete
---

# Phase 19 Plan 19: Login fidelity + Weekly report Summary

Brought the LoginScreen to design 42/62 fidelity (welcome lockup + 6-box OTP)
and built the design-94 Weekly report from the patient's own data — "patterns,
not grades", non-diagnostic, reachable from the Notifications feed and Profile.
Suite green at 121 tests (113 baseline + 8 new).

## What shipped

**A — Login + onboarding fidelity**
- `LoginScreen` rebuilt to the **42 welcome grammar**: onboarding progress
  dots, a concentric-ring hero wrapping the compact `NiD` canopy lockup (ember
  "i"), the "Quiet signals, clear mornings" headline + calm lede, and three
  **full-width provider blocks** in the design's order — Continue with Google
  (canopy fill), Continue with Apple (canopy-outline ghost, gracefully disabled
  with "Apple sign-in is coming soon."), Continue with phone (ghost). Closes
  with the "Private by design — your data stays yours." fine print + Terms ·
  Privacy. Friendly errors only via the inline banner; raw exceptions never
  reach the UI.
- Phone verify step reworked to the **62 OTP grammar**: six code boxes driven
  by a single hidden field (native keyboard, paste, and SMS autofill still
  work), the active box carrying a canopy border + static caret, a Resend code ·
  Change number affordance, and a full-width Verify CTA. Still wired to the
  existing `FirebaseAuthService` phone flow and the `DemoAuthService`
  test-number path.
- Welcome/patient-onboarding in `app_shell` left intact — already faithful to
  the locked ONB-02 (quiet slate "I'm a clinician" text link, relocated
  disclosure, single patient-first primary) and ONB-03 (expectation bullets),
  with headline type already at the login/verify scale.

**B — Weekly report (94)**
- `computeWeeklyReport` (new pure service, mirrors `readiness.dart` /
  `trends.dart`): takes the patient's own sleep + readiness series and journal
  mood tags, returns the takeaway headline+sub (from the week's readiness arc,
  sleep fallback), three stats (avg readiness, avg sleep, days on target),
  7-night bar data, observational tag-vs-sleep correlations (warm-flagged when
  a tag's nights ran short), and one gentle "one thing to try". Deterministic,
  patient-only, non-diagnostic, no Flutter/IO/clock.
- `WeeklyReportScreen` renders that payload to design 94 — 3-up stat grid,
  7-night sleep bars on the blessed `forSleepHours` ramp, a "What lined up"
  card, the mint "One thing to try" block, and the verbatim "Patterns, not
  grades — a week is data, not a verdict." close. Calm empty state before an
  import.
- Reachable: the Notifications feed's weekly-report item now opens the real
  screen (new `NotificationTarget.weeklyReport`, no longer the trends
  placeholder), and a "Weekly report" row was added to Profile > Preferences.

## Tests

- `test/login_screen_test.dart` updated to the new block/OTP grammar: three
  provider blocks (Google/phone live, Apple disabled + "coming soon"), the
  welcome headline + fine print, the phone guard, the 6-box code advance +
  short-code guard, and the no-raw-error assertion.
- `test/weekly_report_test.dart` (new, 8 tests): pure — empty payload, the
  three stats from the patient's own data, rising-week takeaway, honest
  night-bar fractions, journal-tag correlations (deterministic order, warm flag
  on short nights, no exclamation marks), and the "one thing to try" branch;
  widget — full design-94 chrome renders, calm empty before import.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stat grid forced an infinite height**
- **Found during:** first run of the Weekly report widget test.
- **Issue:** the 3-up stat `Row` with `CrossAxisAlignment.stretch` inside the
  vertically-unbounded report `ListView` threw `BoxConstraints forces an
  infinite height`.
- **Fix:** wrapped the stat grid in `IntrinsicHeight` so the tiles share the
  tallest tile's height without an unbounded constraint.
- **Files modified:** lib/screens/weekly_report_screen.dart
- **Commit:** b27bf23

**2. [Rule 1 - Bug] Blinking OTP caret broke pumpAndSettle**
- **Found during:** login test run — `pumpAndSettle timed out` on the code step.
- **Issue:** a repeating caret `AnimationController` keeps the tree animating
  forever, which `pumpAndSettle` (used across the whole suite) never resolves.
- **Fix:** replaced the blinking caret with a calm static canopy bar; the
  active-box canopy border already signals the cursor. Documented inline.
- **Files modified:** lib/screens/login_screen.dart
- **Commit:** d1e36e7

## Standing rules honored

- Clinician never sees the weekly report or journal (sleep-summaries-only).
- No analytics/telemetry; on-device compute; Inter 400–700; gentle motion;
  friendly errors only; observational / non-diagnostic voice ("patterns, not
  grades"). No emoji, no exclamation marks in produced copy.
- STATE.md / ROADMAP.md untouched per plan.

## Known Stubs

- Login `Terms` / `Privacy` links are calm no-op affordances (no legal pages
  exist yet) — layout fidelity only, resolved when those pages land.
- Weekly report `sleepGoalHours` derives from the patient's stored sleep goal;
  the "days on target" reference is that goal, not a separately-authored target.

## Self-Check: PASSED
