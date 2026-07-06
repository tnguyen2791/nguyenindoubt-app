# Feature Landscape

**Project:** NguyenInDoubt Flutter MVP
**Domain:** Patient mental-health companion with invite-linked clinician sleep summaries
**Researched:** 2026-07-06
**Sources:** `.planning/PROJECT.md`, `README.md`, `docs/firebase_contract.md`, `lib/screens`, `lib/state`, `lib/repositories`, `test`

## Product Boundary

NguyenInDoubt should stay a reflective companion, not a treatment system. The v1 promise is: patients can inspect sleep context and write honestly, while clinicians see only consented sleep summaries from accepted invite links. Journal entries, drafts, mood reflections, and private notes must remain patient-only in UI, repository logic, Firestore rules, tests, and future backend models.

The current MVP is local/demo-first. Firebase Auth, Firestore writes, analytics, Crashlytics, telemetry, and real HealthKit/Health Connect ingestion are intentionally not live until privacy, security, and compliance review are complete.

## Table Stakes

Features users expect. Missing means the product feels incomplete or unsafe.

| Feature | Why Expected | Complexity | Current Status | Privacy / Compliance Notes |
|---------|--------------|------------|----------------|----------------------------|
| Patient onboarding and role state | Patients need a clear entry path before any health or journal data appears. | Med | Demo mode switch exists; proper auth/onboarding is active work. | Replace demo switch with authenticated role model before production. |
| Sleep import permission flow | Sleep is the anchor data source; users need explicit permission and clear import state. | High | Mock provider and permission seam exist. | Real HealthKit/Health Connect requires platform permission copy, data minimization, revocation behavior, and review. |
| Sleep summary dashboard | Patients need simple trend context, not raw data overload. | Med | Patient dashboard shows last sleep, quality proxy, trend bars, and import state. | Label derived metrics as informational, not diagnostic. |
| Private journal | The companion needs a private place for narrative reflection. | Med | Journal create/list exists with mood tags and private-by-default copy. | Must never be visible to clinicians unless the product promise intentionally changes after review. |
| Invite acceptance for clinician sharing | Sharing must be explicit, scoped, and reversible. | Med | Demo invite `NID-1138` grants accepted link. | Add real invite validation, expiration, revocation, and consent history before production. |
| Clinician linked-patient list | Clinicians need to see only patients who accepted an invite. | Med | Repository and dashboard filter to accepted links. | Access control must be enforced server-side, not only in client state. |
| Clinician sleep-only summary view | Clinicians need actionable sleep context without private journal access. | Med | Dashboard shows sleep metrics, samples count, trend chart, and visibility copy. | Keep the data contract narrow: sleep samples, daily summaries, trend flags only. |
| Safety and crisis limits | Mental-health apps need clear escalation boundaries. | Low | Safety screen points to 988/911 and states MVP limits. | Do not imply monitoring, emergency dispatch, or guaranteed clinician response. |
| Curated educational resources | Users expect basic, non-diagnostic psychoeducation. | Low | Seeded resource cards cover sleep, medication questions, therapy, family context, safety. | Keep disclaimers visible; avoid medical instructions or medication changes. |
| Local persistence for demo state | The demo needs continuity across refreshes without a backend. | Low | Shared preferences persistence is covered by tests. | Make clear that demo data is per-device and not a production storage model. |
| Privacy regression tests | The core trust boundary needs automated protection. | Low | Tests cover clinician accepted-link filtering, unlinked rejection, and journal denial. | Expand tests with each backend/auth change. |

## Differentiators

Features that are not generic wellness-app checklist items but make this product worth building.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| "Facts plus story" framing | Combines objective sleep context with private narrative rather than treating either as the whole truth. | Med | Preserve copy and IA that separate sleep facts from journal reflection. |
| Clinician collaboration without chart-like surveillance | Lets clinicians see enough sleep signal to discuss care while protecting the patient's inner narrative. | High | This is the main product wedge and should drive roadmap ordering. |
| Explicit humility and non-diagnosis language | Reduces false authority in a sensitive mental-health context. | Low | Continue using labels like "quality proxy", "not a diagnosis", and "educational only". |
| Consent-scoped dashboard | Invite-linked visibility creates a clear mental model for what is shared. | High | Build revocation and audit trail before adding more clinician-facing data. |
| Privacy-first local/demo posture | Avoids premature production handling of sensitive data while validating UX. | Low | Keep telemetry off by default until reviewed. |

## Anti-Features

Features to explicitly not build for v1.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Clinician journal access | Violates the central privacy promise and current repository/rules boundary. | Keep journals patient-only; if sharing is ever explored, make it a separate opt-in artifact, not blanket access. |
| Diagnosis, risk scoring, or treatment recommendations | Creates clinical safety, regulatory, and liability concerns beyond the MVP. | Provide educational context and encourage clinician discussion. |
| Medication start/stop/change guidance | Unsafe without a prescribing clinician and medication-specific review. | Let users write down medication questions and observed patterns. |
| Emergency monitoring or crisis workflow automation | The app cannot guarantee real-time response or duty-of-care coverage. | Point users to 988/911/emergency care with clear limits. |
| Patient-clinician messaging in MVP | Messaging changes operational expectations, retention needs, response-time risk, and compliance scope. | Keep clinician view read-only for sleep summaries. |
| Analytics, Crashlytics, or telemetry by default | Sensitive mental-health and health-adjacent behavior should not be collected casually. | Add only after compliance review, minimization, consent, and retention decisions. |
| Live Firebase writes before review | Production storage changes the risk profile. | Keep Firebase as a documented contract until auth, rules, retention, audit, and incident practices are reviewed. |
| Broad health metric sharing | Steps, HRV, heart rate, medication, and mindful minutes expand sensitivity and interpretation risk. | Start with sleep only; add other metrics only behind explicit per-metric consent. |
| Social feed, community posting, or public sharing | High moderation and privacy risk with little MVP value. | Keep the experience individual and clinician-linked. |

## Likely V2 Features

Features to consider after the v1 privacy boundary, auth model, and sleep-only clinician workflow are solid.

| Feature | Value Proposition | Complexity | Prerequisites |
|---------|-------------------|------------|---------------|
| Real Firebase Auth with patient/clinician roles | Removes demo role switching and enables durable accounts. | High | Compliance-reviewed auth model, role claims, account recovery, deletion flow. |
| Firestore-backed data sync | Lets patients use multiple devices and clinicians see real accepted links. | High | Security rules, deterministic `clinicianLinks`, data retention, audit logging, tests. |
| Consent management screen | Patients need to see, revoke, and understand what is shared. | Med | Link status model, revocation propagation, clinician empty/error states. |
| Real HealthKit and Health Connect adapters | Moves beyond mock import into useful sleep data. | High | Platform permissions, provider abstraction, import deduplication, data provenance. |
| Invite creation and management for clinicians | Clinicians need to issue and monitor invites without hardcoded demo codes. | Med | Authenticated clinician accounts, invite expiration, accepted/revoked states. |
| Exportable clinician sleep summary | Makes the dashboard useful in appointments without opening journal data. | Med | Export privacy review and clear generated-content disclaimer. |
| Patient-facing sleep annotations | Lets patients explain context around short nights without sharing private journal content. | Med | Separate annotation model with explicit share toggle. |
| Resource library curation workflow | Keeps guides current and clinically reviewed. | Med | Admin/editor role, source review process, versioning. |
| Accessibility and responsiveness hardening | Required for a serious patient-facing app. | Med | Widget coverage across patient, journal, resources, safety, clinician screens. |
| Account deletion and data export | Expected for sensitive personal data products. | High | Backend storage, retention policy, identity verification, audit trail. |

## Feature Dependencies

```text
Auth and role model -> Firebase sync -> Server-side clinician access control
Firebase sync -> Consent management -> Invite revocation and audit trail
HealthDataProvider real adapters -> Sleep import deduplication -> Reliable clinician summaries
Private journal boundary -> Optional shared annotations (not journal sharing)
Compliance review -> Telemetry decision -> Production observability
```

## MVP Recommendation

Prioritize:

1. Proper auth/onboarding state model replacing the demo role switch.
2. Server-enforced sleep-only clinician access with accepted invite links.
3. Patient consent management that shows exactly what is shared and supports revocation.
4. Real sleep import behind the existing `HealthDataProvider` seam, after platform and compliance review.
5. Broader privacy regression tests covering repository logic, Firestore rules, and UI affordances.

Defer: messaging, diagnosis/risk scoring, clinician journal access, broad health metric sharing, telemetry, and production Firebase writes until the compliance boundary is reviewed and documented.

## Roadmap Notes

Phase 1 should harden the current demo promise: patient sleep dashboard, private journal, resources, safety, invite acceptance, and clinician sleep-only view. Phase 2 should replace demo identity and storage with reviewed auth and Firestore without expanding the shared data surface. Phase 3 can add real health integrations and consent management. V2 should then consider clinician invite management, exports, annotations, and resource curation.

The roadmap should treat any feature that increases clinician visibility, introduces backend storage, adds telemetry, or interprets mental-health risk as requiring deeper privacy/compliance research before implementation.
