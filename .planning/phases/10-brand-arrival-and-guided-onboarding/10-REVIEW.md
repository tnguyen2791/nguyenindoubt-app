---
phase: 10-brand-arrival-and-guided-onboarding
reviewed: 2026-07-11T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/main.dart
  - lib/screens/app_shell.dart
  - lib/screens/brand_splash.dart
  - lib/screens/patient_dashboard.dart
  - lib/screens/patient_first_run.dart
  - lib/state/app_state.dart
  - test/brand_splash_test.dart
  - test/clinician_affordance_test.dart
  - test/journal_delete_test.dart
  - test/widget_test.dart
  - web/index.html
findings:
  critical: 0
  warning: 3
  info: 8
  total: 11
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-07-11
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Reviewed the Phase 10 surface (native web loader, `BrandSplashGate`, patient-first
welcome, onboarding name guard, `PatientFirstRun` guided empty state) plus the
state layer and tests they touch. Verified externally: `flutter analyze` clean,
all 39 tests pass, `web/nid-brand-mark.png` exists, loader background `#F6F7F1`
matches `NidColors.fog`, and every non-splash test correctly passes
`showSplash: false` (grep-confirmed — only `brand_splash_test.dart:37`
intentionally boots with the splash).

No security or privacy-invariant defects found. The web loader is static markup
with no dynamic interpolation and no external URLs; the splash flag is a plain
in-memory bool (no persistence, no telemetry), consistent with the
no-analytics posture. Journal/clinician separation is untouched and remains
test-asserted.

The real defects cluster around **silent failure paths in the new first-run
funnel** (permission denial and platform errors produce zero user feedback
exactly where the user is being onboarded) and **forced motion with no
reduced-motion escape** in both new splash layers.

## Warnings

### WR-01: First-run import fails silently on permission denial — status feedback was lost in the ONB-04 swap [WARNING]

**File:** `lib/screens/patient_first_run.dart:27-61`, `lib/screens/patient_dashboard.dart:42-43`
**Issue:** The old empty dashboard rendered the sleep-trend card, which carried
the `StatusPill` + `_healthPermissionMessage` row (`patient_dashboard.dart:104-121`).
`PatientFirstRun` replaces it while `state.summaries` is empty but renders **no
permission state at all**. Traced denied path: user taps "Import sleep" →
`importMockSleep` → `PlatformHealthDataProvider.requestPermissions()` returns
denied → `fetchSleepSamples` returns `[]` → `saveImportedSleep([])` → refresh →
summaries still empty → the identical card re-renders. The user sees the
spinner stop and nothing else — `denied`, `revoked`, and no-data `partial`
states are invisible precisely in the state that exists to walk the user
through granting permission. Likewise `unavailable` disables the button with no
visible reason (the copy still says "Import requests sleep-only access").
**Fix:** Surface the already-written helpers inside `PatientFirstRun`:

```dart
if (state.healthPermissionStatus != HealthPermissionStatus.notRequested &&
    state.healthPermissionStatus != HealthPermissionStatus.ready) ...[
  const SizedBox(height: NidSpace.m),
  StatusPill(
    label: healthPermissionLabel(state.healthPermissionStatus),
    tone: healthPermissionTone(state.healthPermissionStatus),
    icon: healthPermissionIcon(state.healthPermissionStatus),
  ),
  const SizedBox(height: NidSpace.s),
  Text(healthPermissionMessage(state.healthPermissionStatus),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall),
],
```

(Requires promoting the private `_healthPermission*` switch helpers in
`patient_dashboard.dart:135-181` to shared visibility.)

### WR-02: `importMockSleep` has no error handling — the first-run primary CTA can throw with zero user feedback [WARNING]

**File:** `lib/state/app_state.dart:209-235`
**Issue:** `PlatformHealthDataProvider` calls platform channels
(`Health().configure()`, `getHealthConnectSdkStatus()`,
`requestAuthorization()`, `getHealthDataFromTypes()`), all of which can throw
`PlatformException`/`MissingPluginException`. `importMockSleep` has only a
`finally` (clears busy) — the exception escapes through the `VoidCallback`
(`onPressed: state.importMockSleep` at `patient_first_run.dart:52` and
`patient_dashboard.dart:91`) as an unhandled async error. On a release build
the user sees the spinner stop and nothing happen; there is no error field in
state to render friendly copy. Phase 10 promotes this exact call to the single
guided first-run action, raising the blast radius of a pre-existing gap. This
also conflicts with the project's standing rule: log the real error, show
friendly copy — never raw or silent.
**Fix:**

```dart
Future<void> importMockSleep() async {
  _setBusy(true);
  try {
    ...
  } on Exception catch (error, stack) {
    debugPrint('sleep import failed: $error\n$stack');
    _importError = 'Sleep import could not finish. Nothing was changed.';
    notifyListeners();
  } finally {
    _setBusy(false);
  }
}
```

…and render `_importError` in `PatientFirstRun` / the trend card.

### WR-03: Brand splash ignores OS reduced-motion and cannot be skipped [WARNING]

**File:** `lib/screens/brand_splash.dart:48-64`
**Issue:** The gate unconditionally runs a 3500ms animation plus a 600ms
cross-fade on every cold launch. It never consults the accessibility flag
(`SemanticsBinding.instance.accessibilityFeatures.disableAnimations` /
`MediaQuery.disableAnimations`), and there is no tap-to-skip. For a
mental-health app whose design contract is "gentle motion," forcing ~4.1s of
animated intro on users who have asked the OS to reduce motion is an
accessibility/robustness defect, not a style preference. It also delays access
to the safety surface by 4 seconds on every launch.
**Fix:** In `initState`, short-circuit when animations are disabled, and let a
tap complete the intro:

```dart
final reduceMotion =
    SemanticsBinding.instance.accessibilityFeatures.disableAnimations;
if (widget.enabled && !widget.state.splashHasPlayed && !reduceMotion) { ... }
```

…and wrap `_BrandSplashView` in a `GestureDetector(onTap: () =>
controller.value = 1.0)` (status listener already handles completion).

## Info

### IN-01: Dead `latest == null` fallbacks in the non-empty dashboard branch [INFO]

**File:** `lib/screens/patient_dashboard.dart:49-67`
**Issue:** The entire `else` block is gated on `state.summaries.isEmpty ==
false`, so `latest` (line 18) is never null inside it. The `'--'` values and
`'awaiting import'` caption are unreachable leftovers from the pre-ONB-04
layout and mislead readers into thinking tiles still render in the empty state.
**Fix:** Move `final latest = state.summaries.last;` into the else branch and
delete the null branches.

### IN-02: Onboarding prefill / skip can carry a previous user's name; comment is inaccurate [INFO]

**File:** `lib/screens/app_shell.dart:48,521-526`; `lib/state/app_state.dart:118-121`
**Issue:** `repository.patientDemo.displayName` reflects the last
`updateDemoPatientProfile` write. After completing onboarding as "Taylor" and
signing out, the next onboarding pass prefills the name field with "Taylor" and
"Skip for now" silently keeps it — the comment claims skip "falls back to the
seeded demo profile name," which is only true on a fresh install. On a shared
demo device this leaks the prior session's display name.
**Fix:** Fall back to the seed constant (`demoPatient.displayName` from
`data/seed_data.dart`, i.e. "Alex Rivera") in `completePatientOnboarding`, or
start onboarding with an empty field.

### IN-03: `splashHasPlayed` is a public mutable field beside its own setter method [INFO]

**File:** `lib/state/app_state.dart:38-44`
**Issue:** `markSplashPlayed()` implies controlled mutation, but the field is
directly writable by any caller (including flipping it back to `false`).
**Fix:** `bool _splashHasPlayed = false;` + `bool get splashHasPlayed =>
_splashHasPlayed;`, keep `markSplashPlayed()` as the sole mutator.

### IN-04: Web loader pulse lacks a `prefers-reduced-motion` guard [INFO]

**File:** `web/index.html:61-72`
**Issue:** `nid-breathe` runs an infinite opacity pulse regardless of the OS
reduce-motion setting — same gentle-motion posture gap as WR-03, on the web
pre-paint layer.
**Fix:**

```css
@media (prefers-reduced-motion: reduce) {
  #nid-loader .nid-badge { animation: none; }
}
```

### IN-05: `_signOut` omits the `mounted` guard that `_confirmResetDemoData` has [INFO]

**File:** `lib/screens/app_shell.dart:160-163` (contrast 190-193)
**Issue:** `setState` after `await widget.state.signOut()` with no `mounted`
check. Currently safe because `AppShell` is never unmounted beneath the gate,
but it is inconsistent with the sibling method and fragile if the splash gate
or navigation ever remounts the shell.
**Fix:** `if (mounted) setState(() => _selectedIndex = 0);`

### IN-06: Import-CTA logic duplicated between first-run card and trend card [INFO]

**File:** `lib/screens/patient_first_run.dart:28-61`; `lib/screens/patient_dashboard.dart:85-99`
**Issue:** The disabled predicate (`isBusy || unavailable`) and the
spinner-in-button treatment are copy-pasted in both surfaces; they will drift
(e.g., if WR-01/WR-02 feedback lands in one but not the other).
**Fix:** Extract a shared `ImportSleepButton(state: ..., label: ...)` widget in
`common_widgets.dart`.

### IN-07: `BrandSplashGate` never reacts to widget updates [INFO]

**File:** `lib/screens/brand_splash.dart:45-65`
**Issue:** `enabled` and `state` are consulted only in `initState`; there is no
`didUpdateWidget`. If an ancestor rebuild ever changes `showSplash` or swaps
the state object, the gate silently keeps its original configuration. Harmless
in the current single-boot usage but an unstated invariant.
**Fix:** Either implement `didUpdateWidget` or document the one-shot contract
on the constructor.

### IN-08: State layer fetches sleep even when the post-request permission status is not granted [INFO]

**File:** `lib/state/app_state.dart:212-225`
**Issue:** After the permission re-check, `importMockSleep` proceeds to
`fetchSleepSamples` regardless of the resulting status (denied/unavailable
included). Both current providers internally return `[]` when not
ready/partial, so behavior is correct today — but the test-asserted promise
("sleep-only access before anything is read") is enforced only inside the
providers. A future provider that forgets the internal guard would read data
without permission.
**Fix:** Bail out early at the state layer:

```dart
if (_healthPermissionStatus != HealthPermissionStatus.ready &&
    _healthPermissionStatus != HealthPermissionStatus.partial) {
  await refresh();
  return;
}
```

---

_Reviewed: 2026-07-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
