# NguyenInDoubt — Handoff

_Last updated: 2026-07-08_

A snapshot to pick up or hand off this project. It covers current state, what
changed recently, open risks, and the exact next steps.

---

## 1. What this app is

A Flutter (web + iOS/Android) mental-health **companion**. Core privacy promise:
patients get a **private journal** + **sleep tracking**; clinicians, only after a
patient accepts an invite/consent link, see **only consented sleep summaries** —
**never** journal content. Not a diagnostic/treatment/emergency service (US-focused
988/911 crisis posture).

- **Repo:** `tnguyen2791/nguyenindoubt-app`
- **v1 product:** complete — all 7 roadmap phases merged to `main`.
- **Data mode today:** **device-local demo only** (`InMemoryAppRepository` via
  `SharedPreferences`; `main.dart` does no Firebase init). Firebase Auth/Firestore
  + rules exist as the production **boundary** but live storage is **not enabled**.
  No analytics/telemetry.

## 2. Active branch & PR

- **Branch:** `claude/project-location-86v8mj`
- **PR #2** (open): "Compliance/legal doc set + data-rights (export, deletion,
  retention) data layer & demo UI". Contains all the work below.
- A session is subscribed to PR #2 activity with an ~hourly self check-in.

## 3. What changed this session (commits on the branch)

| Commit | Summary |
|--------|---------|
| `cb5c763` | Draft compliance/legal doc set in `docs/legal/` |
| `27be289` | Data-rights **data layer**: export, per-account deletion, retention |
| `66a0e66` | Data-rights **UI**: patient app-bar "Data & privacy" menu |
| `2def691` | Demo **deploy runbook/script** + production **go-live plan** |

### Compliance/legal (`docs/legal/`)
Draft privacy policy, terms of service, HIPAA/BAA analysis, incident-response
plan, support & crisis-escalation process, + index. All are **DRAFT TEMPLATES**
with a "requires legal counsel review" banner, bracketed placeholders, and Open
Items checklists. **Not legal advice.**

### Data rights (export / deletion / retention)
- Models: `PatientDataExport`, `AccountDeletionResult`, `RetentionPolicy`
  (`lib/models/app_models.dart`).
- `DataRightsRepository` interface, implemented by both repos
  (`lib/repositories/`).
- In-memory repo (live backend today): versioned-JSON export, per-account
  deletion that **removes personal data but retains the consent audit trail**,
  and `applyRetention()`.
- Firebase repo: export implemented; **deletion deliberately defers to a trusted
  backend** (Cloud Function) — matches the `acceptInvite` pattern.
- State: `NguyenInDoubtState.exportMyData()` / `deleteMyAccount()`.
- UI: patient-only app-bar "Data & privacy" menu → Export my data (view + copy
  JSON), Delete my account (confirmation distinct from "Reset demo data").
- Tests: `test/repositories/data_rights_test.dart`.
- Plan: `.planning/phases/08-data-rights-retention-export-deletion/08-PLAN.md`.

### Launch scaffolding
- `docs/deploy_demo.md` + `scripts/deploy_demo.sh` — publish the device-local
  demo to Firebase Hosting (`nguyenindoubt-demo`).
- `.planning/GO-LIVE.md` — critical path from demo → live service, with owners.

## 4. ⚠️ Open risks / must-know caveats

1. **All code since `cb5c763` is UNVERIFIED.** The authoring environment had **no
   Flutter/Dart toolchain**, and the repo has **no CI**. `flutter analyze`,
   `flutter test`, and `flutter build web` were **not run**. Code mirrors existing
   idioms and is test-covered, but **run the release gate before merging or
   deploying**. Standing up CI is the single highest-leverage de-risking step.
2. **Legal docs are drafts, not legal advice.** Resolve placeholders and get
   counsel sign-off before any use.
3. **Demo "Delete my account" keeps a profile shell** so the local app stays
   functional; production deletion (auth-user removal + cascade + backups) is
   trusted-backend work, intentionally deferred.
4. **PR #2 combines** the legal docs and the data-rights feature (per an explicit
   decision to keep them together).

## 5. Next steps

### To publish the demo (safe, no PHI)
On a machine with Flutter + `firebase login`:
```sh
./scripts/deploy_demo.sh   # runs release gate → build web → firebase deploy
```
See `docs/deploy_demo.md`. Run the release gate first (caveat #1).

### To go live as a real service (see `.planning/GO-LIVE.md`)
**Bottleneck = Stage 1 (only [FOUNDER]/[COUNSEL] can do it):**
- Form legal entity + choose jurisdiction; engage counsel; review `docs/legal/`.
- Decide retention periods, scope (US/EU, 18+), telemetry; resolve placeholders.
- Then: Google Cloud BAA + HIPAA-eligible Firebase config.

**Engineering that can start now (build/test ahead; deploy after Stage 1/2):**
- **Trusted-backend Cloud Functions** — **scaffolded** in `functions/`
  (`acceptInvite`, `deleteAccount`, `retentionSweep`); unverified. Next: add
  emulator tests, wire the Firebase repo to call them, finalize retention days.
  See `functions/README.md`.
- Wire the app to `FirebaseAppRepository` behind a flag (`main.dart` +
  `NguyenInDoubtState` currently hardcode the concrete in-memory type).
- Cloud Functions for the deletion cascade + scheduled retention sweep.
- Firestore rules tests (clinician has no journal read path; cross-patient
  isolation) and server-side audit logging.
- Production export file-download (replace copy-to-clipboard).
- Real-device HealthKit / Health Connect validation (needs physical devices).

## 6. Key file map

| Area | Path |
|------|------|
| App entry (repo wiring) | `lib/main.dart` |
| Models | `lib/models/app_models.dart` |
| Repositories (in-memory + Firebase) | `lib/repositories/` |
| App state | `lib/state/app_state.dart` |
| UI shell (data & privacy menu) | `lib/screens/app_shell.dart` |
| Firestore rules | `firestore.rules` |
| Compliance/legal drafts | `docs/legal/` |
| Production posture | `docs/production_posture.md` |
| Demo deploy | `docs/deploy_demo.md`, `scripts/deploy_demo.sh` |
| Go-live plan | `.planning/GO-LIVE.md` |
| Planning / roadmap / state | `.planning/` |

## 7. Verify the app (release gate)

```sh
flutter pub get
flutter analyze
flutter test
npm run test:firestore-rules
flutter build web
```
