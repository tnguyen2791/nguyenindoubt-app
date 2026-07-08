# NguyenInDoubt — Production Go-Live Plan

**Purpose:** the critical path from the current **device-local demo** to a
**live, account-backed service** that stores real journals and health data.
This is mostly *not* an engineering task — it is a sequence with hard legal,
compliance, and operational gates. Launching before these are met is real legal
and human risk, not a shortcut.

**Companion documents:**
[`../docs/production_posture.md`](../docs/production_posture.md) ·
[`../docs/legal/hipaa_baa_analysis.md`](../docs/legal/hipaa_baa_analysis.md) ·
[`../docs/legal/incident_response_plan.md`](../docs/legal/incident_response_plan.md) ·
[`../docs/legal/privacy_policy.md`](../docs/legal/privacy_policy.md)

**Owner legend:** `[FOUNDER]` business/legal decisions · `[COUNSEL]` external legal ·
`[ENG]` engineering · `[VENDOR]` Google/Apple/other · `[OPS]` support/on-call.

---

## Stage 0 — Publish the demo (now)  ·  Owner: [ENG]

Ship the labeled, device-local demo to the web. Safe — no server-side PHI.
See [`../docs/deploy_demo.md`](../docs/deploy_demo.md). **Prerequisite:** run the
release gate (`flutter analyze/test/build web`) once, since recent work was
authored without a Flutter toolchain. This is independent of everything below.

---

## Stage 1 — Business & legal foundation (GATES EVERYTHING)  ·  Owner: [FOUNDER] + [COUNSEL]

Nothing account-backed should launch until these are resolved. They also unblock
the placeholders throughout `docs/legal/`.

- [ ] Form / confirm the **legal entity** and **governing jurisdiction**.
- [ ] Engage **privacy/health counsel**; have them review the `docs/legal/` set
      (privacy policy, terms, HIPAA/BAA analysis, IR plan, support/crisis).
- [ ] Decide **data-retention periods** per category (profile, journal, sleep,
      consent history) — feeds `RetentionPolicy` and the policies.
- [ ] Decide **scope**: US-only vs. EU/UK; 18+ only (current assumption).
- [ ] **Telemetry decision** (default: stay dark). Any analytics/crash reporting
      needs its own compliance review before enabling.
- [ ] Resolve **all `[PLACEHOLDER]` values** in `docs/legal/` (entity,
      jurisdiction, contacts, address, DPO, region).
- [ ] Publish the **Consumer Health Data Notice** (WA MHMDA) as a linked notice.

---

## Stage 2 — Compliance infrastructure  ·  Owner: [FOUNDER] + [ENG] + [VENDOR]

Depends on Stage 1 (jurisdiction, region, entity).

- [ ] Stand up the **production Firebase project** (separate from the demo).
- [ ] Execute the **Google Cloud BAA** for the org.  `[FOUNDER]/[VENDOR]`
- [ ] Restrict architecture to **HIPAA-eligible Covered Products** (Firestore,
      Auth/Identity Platform, Storage, Functions) in the chosen region; verify
      Google's current Covered Products list at signing.  `[ENG]`
- [ ] Confirm **no PHI** in Analytics/Crashlytics/auth-custom-claims/profile.

---

## Stage 3 — Engineering hardening  ·  Owner: [ENG]  (CAN START NOW, before launch)

These do not depend on Stage 1/2 to *build and test* — only to *deploy to prod*.
This is the engineering critical path I can begin immediately.

- [ ] **Wire the app to `FirebaseAppRepository`** behind a build/config flag
      (today `main.dart` hardcodes `InMemoryAppRepository`; `NguyenInDoubtState`
      also depends on the concrete type — needs an interface seam).
- [ ] **Trusted-backend Cloud Functions** (client cannot be trusted for these):
  - [ ] Invite **acceptance** (Firebase `acceptInvite` currently throws
        "requires a trusted backend").
  - [ ] **Account-deletion cascade** + auth-user deletion + backup propagation
        (Firebase `deletePatientData` currently defers to this).
  - [ ] **Scheduled retention sweep** mirroring `applyRetention`.
- [ ] **Server-side audit logging** (privacy-preserving; never log journal
      content) — required for breach *detection* per the IR plan.
- [ ] **Firestore rules tests**: prove clinician role has **no** journal read
      path and cross-patient isolation holds (deny-by-default).
- [ ] **Production export file-download** (web/mobile) replacing copy-to-clipboard.
- [ ] **Verification**: stand up CI or a local gate — no code above should reach
      prod unverified (recent work is currently unverified; there is no CI).

---

## Stage 4 — Real health-data validation  ·  Owner: [ENG] + physical devices

- [ ] Validate **HealthKit** (iOS) and **Health Connect** (Android) permission
      + import flows on **real devices** (cannot be done in CI/emulator).
- [ ] Confirm sleep-only scope and correct normalization into existing models.

---

## Stage 5 — Operational readiness  ·  Owner: [FOUNDER] + [OPS]

Per `docs/legal/incident_response_plan.md` and `support_escalation_process.md`.

- [ ] Named **incident-response roles** + on-call; outside counsel / forensic
      vendor identified.
- [ ] **Support channel** live with the crisis auto-reply; staff trained on the
      crisis-content protocol.
- [ ] **Breach-notification templates** pre-approved by counsel.
- [ ] Run a **tabletop exercise** (journal-exposure + Firestore-rules-misconfig).

---

## Stage 6 — Pre-launch gate (all must be TRUE)  ·  Owner: [FOUNDER] sign-off

The consolidated go-live gate from `hipaa_baa_analysis.md` §18 and
`incident_response_plan.md` §18:

- [ ] Executed Google Cloud BAA; HIPAA-eligible services only; PHI kept out of
      telemetry/claims.
- [ ] Encryption in transit + at rest; access controls; audit logging live.
- [ ] Retention/export/deletion workflows implemented **and tested** in prod.
- [ ] Trusted backend for invite acceptance + deletion live.
- [ ] Counsel **sign-off** on the full `docs/legal/` set; placeholders resolved.
- [ ] Release gate green (`flutter analyze/test/build web`).
- [ ] App Store / Play: privacy labels + EULA + medical-disclaimer copy match
      the policies.

---

## Stage 7 — Launch  ·  Owner: [FOUNDER] + [ENG]

- [ ] Staged rollout (small cohort → monitor → widen).
- [ ] Re-consent flow for any users migrating from device-local to cloud.
- [ ] Post-launch monitoring; keep IR + support check-ins active.

---

## Critical path at a glance

```
Stage 0 (demo)  ─ independent, ship now
Stage 1 (legal/business) ─┬─► Stage 2 (BAA/infra) ─┐
                          │                         ├─► Stage 6 (gate) ─► Stage 7 (launch)
Stage 3 (engineering) ────┴── build now, deploy after 2 ─┤
Stage 4 (device health validation) ─────────────────────┤
Stage 5 (ops readiness) ─────────────────────────────────┘
```

**Bottleneck:** Stage 1. Most engineering (Stage 3) can proceed in parallel and
be ready, but nothing goes live until the legal/compliance foundation and the
Stage 6 gate are real. The single most valuable code task I can start now, that
is also a genuine security gap, is the **trusted invite-acceptance Cloud
Function** (Stage 3).
