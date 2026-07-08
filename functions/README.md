# NguyenInDoubt — trusted backend (Cloud Functions)

> ⚠️ **SCAFFOLD — not yet verified or deployed.** Authored without a
> Node/Firebase toolchain; run against the emulator and review before deploy.
> Depends on the compliance-gated production Firebase project and an executed
> Google Cloud BAA. See [`../.planning/GO-LIVE.md`](../.planning/GO-LIVE.md)
> (Stage 3) and [`../docs/legal/hipaa_baa_analysis.md`](../docs/legal/hipaa_baa_analysis.md).

These functions implement operations the Firestore **client cannot be trusted**
to perform, which the Firebase repository (`lib/repositories/firebase_app_repository.dart`)
intentionally defers to a trusted backend:

| Function | Type | Purpose |
|----------|------|---------|
| `acceptInvite` | callable | Server-side invite validation, then atomic link-accept + consent grant + consent event. The client cannot self-accept. |
| `deleteAccount` | callable | Cascade-delete the caller's personal data, end active sharing (retaining a consent audit event), delete profile + auth user. Consent history retained. |
| `retentionSweep` | scheduled | Purge records older than each category's retention window. |

## Develop & test (required before deploy)

```sh
cd functions
npm install
npm run serve        # firebase emulators: functions + firestore + auth
```

Write emulator tests exercising: invite accept happy-path + rejection of
already-accepted/pending-mismatch/wrong-patient; deletion cascade with audit
retention; retention windows. None exist yet — **add them before relying on
this**.

## Before deploy (go-live gate)

- [ ] Emulator tests pass; code reviewed.
- [ ] Production Firebase project + executed Google Cloud BAA; HIPAA-eligible
      services only (see the HIPAA analysis).
- [ ] Finalize `RETENTION_DAYS` with counsel (currently placeholder `null` =
      retain).
- [ ] Wire the Flutter app's `FirebaseAppRepository.acceptInvite` /
      `deletePatientData` to call `acceptInvite` / `deleteAccount` (they
      currently throw "requires a trusted backend").
- [ ] Batch pagination for large datasets (deletion + sweep cap at 500 ops).
- [ ] Deletion propagation to backups per the retention policy / DPA.

## Deploy (only after the gate)

```sh
firebase deploy --only functions --project <production-project>
```
