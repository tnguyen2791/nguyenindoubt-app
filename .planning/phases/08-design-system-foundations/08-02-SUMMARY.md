---
phase: 08-design-system-foundations
plan: 02
subsystem: screens
tags: [design-system, pill-tone, tokens, dashboards, spacing]
requires:
  - lib/theme/tokens.dart (NidSpace, NidRadius)
  - PillTone enum + StatusPill tone API (08-01)
  - NidColors.ember
provides:
  - patient_dashboard StatusPills tone-driven (consent/health-permission/consent-lifecycle)
  - clinician_dashboard StatusPills tone-driven (messaging/link-status/journal-private)
  - _healthPermissionTone + _linkStatusTone mapping helpers
  - stock Colors.red.shade700 removed from patient_dashboard
affects:
  - 08-03 (remaining screen token/pill-tone sweep — resources_screen etc.)
tech-stack:
  added: []
  patterns:
    - "Status/enum -> PillTone mapping helper co-located beside the label helper"
    - "Screen spacings/radii reference NidSpace/NidRadius, never freehand literals"
key-files:
  created: []
  modified:
    - lib/screens/patient_dashboard.dart
    - lib/screens/clinician_dashboard.dart
decisions:
  - "SizedBox(width:10)/Wrap spacing:10 rounded to NidSpace.s (8); SizedBox(height:14)/18 rounded to NidSpace.l (16); EdgeInsets.all(14) -> NidSpace.m (12) per plan"
  - "_MetricTile/_ClinicianMetric caps labels keep labelSmall+.copyWith(color: canopy), just drop the w900 override (w600 from theme)"
metrics:
  duration_min: 9
  completed: 2026-07-06T00:00:00Z
  tasks: 2
  files_changed: 2
status: complete
---

# Phase 8 Plan 2: Dashboard Design-System Sweep Summary

Migrated `patient_dashboard.dart` and `clinician_dashboard.dart` onto the Wave-1 foundations: every StatusPill now encodes state through a semantic `PillTone` (no more default-mint "green confetti"), the stray stock `Colors.red.shade700` is gone, the `w900` caps labels are de-weighted to the theme `labelSmall` (w600), and freehand paddings/gaps/radii reference `NidSpace`/`NidRadius`. Mechanical mapping only — no copy, layout, or behavior changes; all 27 tests stay green and the sleep-only privacy strings are verbatim.

## What was built

**Task 1 — patient_dashboard.dart sweep (commit 174b048)**
- Imported `../theme/tokens.dart`.
- **Pill tones (DS-03):** BrandHeader trailing pill → `good` when consent granted ('shared sleep'), else `private` ('private'). Added `_healthPermissionTone(HealthPermissionStatus)` (ready→good, denied/revoked→flag, unavailable/partial→caution, notRequested→neutral) driving the health-permission pill. `_ConsentLifecycleCard` status pill → `good` (sharing active) / `flag` (sharing revoked) / `neutral` (invite required); clinicCode pill → explicit `neutral`. No `color:` override anywhere.
- **Stock red (DS-04):** `_InviteValidationMessage` `Colors.red.shade700` → `NidColors.ember` (border/foreground for the not-available case). Literal removed entirely.
- **De-weight (DS-01):** `_MetricTile` caps label drops `FontWeight.w900`; renders `labelSmall.copyWith(color: NidColors.canopy)` (w600), keeping `.toUpperCase()` and value/caption styles.
- **Token sweep (DS-02):** ListView `all(20)`→`all(NidSpace.xl)`; gap/pad literals 16→l, 12→m, 8→s, 6→s, 4→xs; Wrap spacings 12→m, 10→s; `_InviteValidationMessage` `circular(8)`→`NidRadius.card`, `all(12)`→`NidSpace.m`. `_MetricTile` fixed width 172 left as-is (per plan).

**Task 2 — clinician_dashboard.dart sweep (commit 9cb4e7b)**
- Imported `../theme/tokens.dart`.
- **Pill tones (DS-03):** BrandHeader 'no messaging' pill → `neutral`. Added `_linkStatusTone(LinkStatus)` (accepted→good, pending→caution, revoked→flag, expired→caution) driving the non-actionable `_PatientList` link pill. `_PatientDetail` 'journal private' pill → `private`.
- **De-weight (DS-01):** `_ClinicianMetric` caps label drops `FontWeight.w900`; uses `labelSmall.copyWith(color: NidColors.canopy)` (w600); value keeps `headlineSmall`.
- **Token sweep (DS-02):** mint metric tile `circular(8)`→`NidRadius.card`, `all(14)`→`NidSpace.m`; ListView `all(20)`→`NidSpace.xl`; InkWell `circular(8)`→`NidRadius.card`; gap literals 18→l, 16→l, 14→l, 10→s, 8→s, 2→xs; Wrap spacing 12→m. Fixed `width: 310`/`140` left as-is (per plan). CircleAvatar colors, InkWell tap behavior, `_linkStatusLabel`, and the 'Visible/Hidden' copy untouched.

## Pill-tone map (per call-site)

| Screen | Call-site | Tone |
| ------ | --------- | ---- |
| patient | BrandHeader trailing | good (granted) / private |
| patient | health permission | `_healthPermissionTone`: ready→good, denied/revoked→flag, unavailable/partial→caution, notRequested→neutral |
| patient | consent lifecycle status | good / flag / neutral |
| patient | clinicCode chip | neutral |
| clinician | 'no messaging' | neutral |
| clinician | link status (non-actionable) | `_linkStatusTone`: accepted→good, pending→caution, revoked→flag, expired→caution |
| clinician | 'journal private' | private |

## Spacing roundings applied

Small deliberate rounding onto the NidSpace grid (CONTEXT DS-02 "one ruler"): `10`→`s`(8), `14`→`l`(16), `18`→`l`(16), `6`→`s`(8), and `EdgeInsets.all(14)`→`NidSpace.m`(12) per the plan's explicit instruction. Exact-match values (16/12/8/4/20→xl) mapped directly.

## Deviations from Plan

None — plan executed as written. All spacing roundings are the deliberate rounding the plan explicitly permits.

## Verification results

- `dart format lib test` — clean (0 files changed).
- `flutter analyze` — **No issues found!**
- `flutter test` — **all 27 tests pass** (sleep-only privacy + consent lifecycle strings intact).
- `flutter build web` — **✓ Built build/web**.
- `grep -q "Colors.red"` patient_dashboard — no match; `grep "FontWeight.w9"` both dashboards — no match; both reference `PillTone`, `NidSpace`, and (clinician) `NidRadius`.

## Self-Check: PASSED

- lib/screens/patient_dashboard.dart — FOUND (modified)
- lib/screens/clinician_dashboard.dart — FOUND (modified)
- Commit 174b048 — FOUND
- Commit 9cb4e7b — FOUND
