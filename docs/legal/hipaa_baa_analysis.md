# HIPAA Applicability & Business Associate Agreement (BAA) Analysis

> **⚠️ DRAFT TEMPLATE — INTERNAL COMPLIANCE DOCUMENT — NOT LEGAL ADVICE**
>
> This document is a **DRAFT TEMPLATE** prepared to help [LEGAL ENTITY NAME] reason about
> HIPAA applicability for the NguyenInDoubt application. It is a compliance-analysis framework,
> **not legal advice**, and it does **not** create an attorney–client relationship. It **MUST be
> reviewed, corrected, and approved by qualified legal counsel licensed in [JURISDICTION]**
> (and, where relevant, by privacy counsel familiar with HIPAA, the FTC Health Breach
> Notification Rule, and applicable state consumer-health-privacy laws) **before any production
> use or reliance.**
>
> Statutory and regulatory citations are provided for orientation only and must be verified
> against the current text of the authorities at the time of reliance.
>
> **Last updated:** [DATE]
> **Status:** DRAFT — not yet in effect

---

## Related documents

This analysis is one of a set of coordinated compliance documents. Read it alongside:

- [`./privacy_policy.md`](./privacy_policy.md) — consumer-facing privacy policy (and the separate consumer-health-data privacy policy that WA MHMDA requires).
- [`./terms_of_service.md`](./terms_of_service.md) — terms of service, including non-diagnostic / non-treatment positioning and crisis disclaimers.
- [`./incident_response_plan.md`](./incident_response_plan.md) — breach detection, containment, and dual-regime (HIPAA + FTC HBNR) notification runbook.
- [`./support_escalation_process.md`](./support_escalation_process.md) — support, consent-dispute, and safety-escalation handling.

---

## 1. Document Control, Purpose & Scope

| Field | Value |
|---|---|
| Document title | HIPAA Applicability & BAA Analysis |
| Owner | [PRIVACY CONTACT EMAIL] (Privacy / Compliance lead) |
| Legal entity | [LEGAL ENTITY NAME] |
| Governing law / jurisdiction | [JURISDICTION] |
| DPO / privacy officer | [DPO NAME] |
| Version | [DOCUMENT VERSION] |
| Last updated | [DATE] |
| Effective date | [EFFECTIVE DATE] |
| Status | DRAFT — not yet in effect |
| Review cadence | At least annually, and on any change to the data architecture, the clinician-sharing model, the hosting configuration, or the business model (e.g., any provider/health-system arrangement). |

**Purpose.** To determine whether and when NguyenInDoubt (the "App") and [LEGAL ENTITY NAME]
(the "Company") are subject to HIPAA — specifically whether the Company is a **covered entity**,
a **business associate**, or **neither** — and to define the concrete controls and contractual
prerequisites that must be satisfied **before** any change (most importantly, enabling live cloud
storage of identifiable health data) that could alter that determination.

**Scope.** This document covers: (a) the current device-local demo posture; (b) the
compliance-gated Firebase production backend that exists as a boundary but is **not yet enabled**
for live storage of identifiable data; (c) the patient-directed clinician sleep-summary share; and
(d) the parallel non-HIPAA regimes (FTC Health Breach Notification Rule and state consumer-health-
privacy laws) that apply **regardless of** HIPAA.

**Out of scope.** International data-protection regimes (e.g., GDPR/UK GDPR), payment-card
obligations, and clinician-side HIPAA obligations (the clinician's own practice is responsible for
its own compliance). These may warrant separate analysis before any non-US launch.

---

## 2. Executive Summary & Current Determination

**Current determination (device-local demo posture):** In its current public-demo posture,
NguyenInDoubt is **NEITHER a HIPAA covered entity NOR a HIPAA business associate.**

Why:

1. **Function, not sensitivity, controls.** HIPAA regulates covered entities and their business
   associates. It turns on **on whose behalf** an entity handles health information, not on how
   sensitive that information is. A direct-to-consumer (D2C) app that the consumer independently
   chooses to download and use is generally neither a covered entity nor a business associate — even
   when it handles extremely sensitive mental-health data.
2. **No PHI in cloud custody today.** The demo stores data **device-local** (in-memory / local
   storage), with no cross-device sync and no identifiable health data at rest in the cloud. There is
   therefore no ePHI in the Company's custody that would trigger the HIPAA Security Rule, and no
   infrastructure BAA is required at this stage.
3. **The clinician share is individual-directed.** When a patient accepts a consent link and shares
   sleep summaries with their clinician, the **patient** initiates and controls the disclosure of the
   patient's own data. Under OCR guidance (see §6), an app facilitating an individual's access to /
   sharing of their own information at the individual's request does **not** thereby become a business
   associate of the clinician.

**Decision-gated future posture:** The Company **would** become a HIPAA business associate — and the
Security, Privacy, and Breach Notification Rules would attach — if it enters an arrangement to handle
PHI **on behalf of a covered entity** (e.g., a clinic/health system licenses or deploys the App to its
patients, or the App is offered "through" a provider, or it receives PHI from a provider's EHR, or it
performs care-management/monitoring/records services for a provider). See the decision tree in §7 and
Appendix A.

**Critical near-term point:** Even though HIPAA does **not** currently apply, the Company is
**already** subject to non-HIPAA regimes:

- **FTC Health Breach Notification Rule (HBNR), 16 CFR Part 318 (2024 amendments):** NguyenInDoubt
  draws "PHR identifiable health information" from **multiple sources** (Apple HealthKit / Google Health
  Connect imports **plus** user-entered data), which places a D2C configuration squarely within HBNR
  coverage once it maintains such records. See §13.
- **State consumer-health-privacy laws** (e.g., Washington My Health My Data Act; analogues in Nevada
  and Connecticut) very likely apply to a mental-health app reaching those residents via the app stores.
  See §14.

**Bottom line:** Keep the demo device-local; treat any move to live cloud storage of identifiable
health data as a **formal compliance decision gate** (§18), not an incremental engineering change; and
build to HIPAA Security Rule safeguards as the baseline standard **now**, because FTC and state law
already demand reasonable security and honest privacy promises.

---

## 3. App & Data-Flow Description

### 3.1 What NguyenInDoubt is

NguyenInDoubt is a Flutter application (web + iOS + Android) positioned as a **mental-health companion**.
It is **not** a diagnostic tool, not a treatment tool, not an emergency-monitoring service, and not a
patient-to-clinician messaging platform. Its purpose is to give a patient a **private journal** and
**sleep tracking**, and — only with explicit, separate consent — to let the patient share **sleep
summaries** with a clinician.

### 3.2 Roles

| Role | Description | HIPAA character |
|---|---|---|
| **Patient** | The data owner. Independently chooses to use the App. Owns and controls the journal, sleep data, and any clinician-sharing consent. | The individual whose data it is. |
| **Clinician** | A viewer who, **only after** a patient accepts an invite/consent link, can see **only** consented **sleep summaries** — **never** journal content. Typically a licensed care provider. | Likely a **covered entity** in their own right; but the Company does not act **on the clinician's behalf** under contract in the D2C model. |

### 3.3 Data categories

| Category | Sensitivity | Cloud custody today | Notes |
|---|---|---|---|
| Account profile | Moderate | Device-local (demo) | Identity/auth fields. Must **never** hold journal or health content in auth custom claims. |
| **Private journal entries** | **Highest** (mental-health free text) | Device-local (demo) | **Never** shared with clinicians. Must be structurally walled off (§15). |
| Sleep samples (raw) | High | Device-local (demo) | Imported from Apple HealthKit / Google Health Connect. |
| Daily sleep summaries | High | Device-local (demo) | Derived; the **only** category a consented clinician may view. |
| Clinician invite / consent link + consent history | High (reveals a care relationship) | Device-local (demo) | Records who consented, to what, and when; supports revocation. |

### 3.4 Architecture boundary: demo vs. production

- **Public demo (current):** **Device-local only.** In-memory / local storage. No cross-device sync.
  **No identifiable health data at rest in the cloud.** No analytics, no telemetry, no Crashlytics.
- **Production backend (boundary exists; live storage NOT yet enabled):** Firebase Authentication +
  Cloud Firestore, with Firestore security rules, exist as the intended production boundary. **Live
  production storage of identifiable data is compliance-gated and NOT yet enabled.** Enabling it is a
  formal decision gate (§18) that requires, at minimum, an executed Google Cloud BAA and a
  HIPAA-eligible-services-only configuration (§12).

### 3.5 Crisis / safety posture

US-focused. The App surfaces the **988 Suicide & Crisis Lifeline** (call/text) and **911** for
emergencies. The App **does not** diagnose, treat, monitor for emergencies, or provide
patient-to-clinician messaging in this MVP. See §16.

---

## 4. HIPAA Legal Framework Primer

HIPAA (as implemented by the HHS regulations at 45 CFR Parts 160 and 164) regulates only two kinds of
entities and the information they handle:

- **Covered Entity (CE)** — a health plan, a health care clearinghouse, or a **health care provider who
  transmits health information in electronic form in connection with a HIPAA-standard transaction**
  (e.g., electronic billing/eligibility). *See* 45 CFR 160.103.
- **Business Associate (BA)** — a person or entity that **creates, receives, maintains, or transmits PHI
  to perform a function or service ON BEHALF OF a covered entity** (or another business associate).
  *See* 45 CFR 160.103.
- **PHI / ePHI** — Protected Health Information: individually identifiable health information held or
  transmitted by a covered entity or business associate. ePHI is PHI in electronic form. **Health
  information that a consumer holds in a D2C app the consumer chose is generally not PHI**, because it is
  not held by a CE or BA.

The three principal HIPAA Rules (each attaching **only** if the Company is a CE or BA):

1. **Privacy Rule** (Subpart E) — permitted uses/disclosures and the minimum-necessary standard.
2. **Security Rule** (Subpart C) — administrative, physical, and technical safeguards for ePHI.
3. **Breach Notification Rule** (Subpart D) — notification obligations after a breach of unsecured PHI.

**Key takeaway:** Sensitivity does not trigger HIPAA. **Relationship** does. A mental-health journal can
be entirely outside HIPAA while remaining heavily regulated by the FTC and state law.

---

## 5. HIPAA Scope Classification for NguyenInDoubt

| Question | NguyenInDoubt (current D2C demo) |
|---|---|
| Is it a **health plan**? | No. |
| Is it a **health care clearinghouse**? | No. |
| Is it a **health care provider transmitting HIPAA-standard transactions**? | No. It is a non-treatment companion app; it does not provide care or bill electronically. |
| Is it a **business associate** (handling PHI **on behalf of** a CE under an arrangement)? | **No** in the current model — no CE has engaged the Company to perform functions on its behalf. |
| **Classification** | **Neither** a covered entity nor a business associate. |

The controlling baseline is the **"consumer chooses the app"** scenario in OCR's *Health App Use
Scenarios & HIPAA* (Feb 2016): where a consumer independently downloads and uses an app, the developer is
**not** a business associate, because the developer is not engaged by, and does not act on behalf of, any
covered entity.

The App's non-diagnostic, non-treatment positioning (§16) reinforces that the Company is **not itself a
health care provider / covered entity** — but this does **not** exempt it from FTC or state
consumer-health-privacy obligations (§§13–14).

---

## 6. The Access-Right vs. Business-Associate Distinction

A central point for NguyenInDoubt: **the patient-directed clinician share does NOT create a
business-associate relationship.**

- OCR's *Access Right, Health Apps & APIs* guidance and **HHS FAQ 3013** are explicit: an app that
  merely **facilitates an individual's access to, or sharing of, the individual's own health information
  at the individual's request** does **not**, by that fact, become a business associate. Once a
  consumer-chosen app receives the individual's data at the individual's direction, that data is no longer
  subject to HIPAA in the app's hands.
- In NguyenInDoubt, the **patient** is the party who (a) chose the App, (b) initiated the invite/consent
  link, and (c) controls what is shared (sleep summaries only) and can revoke it. The clinician is a
  **recipient designated by the individual**, not a principal on whose behalf the Company acts under
  contract.

**Documentation practice (do this):** Preserve the "neither" classification by documenting the
**direction of flow** — that the patient initiated and controls the disclosure, that consent was
separate and affirmative, and that no clinician/practice contract engages the Company to handle PHI. The
consent-history record (grant + revocation events) is the primary evidence. This is a defensive control:
if the flow can be shown to be individual-directed, it is not BA work.

---

## 7. Business-Associate Trigger Analysis & Decision Tree

**Question: Does NguyenInDoubt become a HIPAA business associate?**

```
Q1. Does the App create/receive/maintain/transmit PHI?
      │
      ├─ In the DEMO (device-local, no cloud PHI at rest):
      │     effectively NO PHI in the Company's custody.
      │     ──► STOP. Classification: NEITHER (HIPAA does not attach).
      │           (FTC HBNR + state consumer-health laws may still apply.)
      │
      └─ If the App stores IDENTIFIABLE HEALTH DATA in the cloud ──► go to Q2.

Q2. Is that identifiable health data stored ON BEHALF OF a COVERED ENTITY
    under an arrangement / contract?
      │
      ├─ NO — data is held FOR THE INDIVIDUAL CONSUMER who chose the App
      │        (pure D2C custody).
      │     ──► NEITHER for HIPAA.
      │           BUT: FTC HBNR + WA MHMDA (and analogues) DO apply.
      │           A Google Cloud BAA is still advisable and adopting HIPAA
      │           Security Rule safeguards is the baseline standard.
      │
      └─ YES — go to Q3.

Q3. Is there a contract/engagement with a clinician's practice, health plan,
    EHR vendor, or other covered entity to provide the service TO / FOR /
    THROUGH them?  (e.g., a practice pays for or deploys the App to its
    patients; the App is offered "through" the provider; the App receives PHI
    from a provider's EHR; the App performs care-management/monitoring/
    records/billing for the provider.)
      │
      ├─ YES ──► NguyenInDoubt IS a BUSINESS ASSOCIATE.
      │            A signed BAA is REQUIRED before receiving PHI, and the
      │            Security, Privacy, and Breach Notification Rules attach.
      │
      └─ NO (only patient-directed sharing, no such contract)
                 ──► remains NEITHER for HIPAA.
```

### 7.1 Specific trigger scenarios that flip the App into BA status

The Company becomes a business associate if **any** of the following occurs:

- **(a)** A clinic or health system **licenses or white-labels** NguyenInDoubt to give to its patients.
- **(b)** The Company contracts to receive PHI **from a provider's EHR** (not just from the patient) to
  populate the App.
- **(c)** The Company performs a service **for the clinician** — care-management, monitoring, or storing
  the clinician's records.
- **(d)** The Company **bills or integrates** on behalf of the practice.

Absent (a)–(d), the D2C model stays outside HIPAA. **Any proposal to enter such an arrangement must be
routed to counsel and this analysis re-run before signing.**

---

## 8. If HIPAA Applies: BAA Requirements (45 CFR 164.502(e) / 164.504(e))

If the Company becomes a business associate, a written BAA with the covered entity is **mandatory before
receiving PHI**. Model it on HHS's official *Sample Business Associate Agreement Provisions* (which tracks
45 CFR 164.504(e) element-by-element). At a minimum the BAA must:

1. Establish the **permitted and required uses and disclosures** of PHI by the Company.
2. **Prohibit** use or further disclosure of PHI other than as permitted by the contract or required by
   law.
3. Require the Company to implement **appropriate safeguards** and to comply with the **Security Rule
   (Subpart C)** for ePHI.
4. Require the Company to **report** any impermissible use/disclosure, security incident, or breach of
   which it becomes aware.
5. Require **flow-down** BAAs to any **subcontractors** that create/receive/maintain/transmit PHI on the
   Company's behalf (45 CFR 164.504(e)(5)) — e.g., cloud, auth, push, future analytics.
6. Make PHI available for **individual access, amendment, and an accounting of disclosures** as required.
7. Authorize **termination** by the covered entity for material breach, and address return/destruction of
   PHI at termination.

Keep these seven headings as a compliance checklist; verify against the current HHS sample provisions at
signing time.

---

## 9. If HIPAA Applies: Security Rule Safeguards (45 CFR 164.308 / 164.310 / 164.312)

If HIPAA attaches, the Company must implement the Security Rule safeguards. **These should also be
adopted now as the baseline standard even where HIPAA does not apply** (see §13, §14, §17).

- **Administrative safeguards — 45 CFR 164.308:** risk analysis and risk management; sanction policy;
  information access management; workforce security and training; contingency/backup/disaster-recovery
  planning; and periodic evaluation.
- **Physical safeguards — 45 CFR 164.310:** facility access controls; workstation use and security; and
  device and media controls (disposal, reuse, media movement). For a cloud-hosted app, these are largely
  satisfied through the cloud provider under the BAA plus workforce endpoint controls.
- **Technical safeguards — 45 CFR 164.312:** access control (unique user IDs, emergency access,
  automatic logoff); **audit controls** (logging); integrity; person/entity authentication; and
  **transmission security** (encryption in transit). Encryption at rest is strongly recommended and helps
  render data "unsecured"-safe under the Breach Notification Rule.

---

## 10. If HIPAA Applies: Privacy Rule Minimum-Necessary & Permitted Uses (45 CFR 164.502(b), 164.514(d))

The **minimum-necessary** standard requires using or disclosing only the minimum PHI needed for the
purpose. This maps directly onto NguyenInDoubt's core promise: a consented clinician receives **sleep
summaries only — never journal content.** Even outside HIPAA, minimum-necessary is a sound design
principle and evidences reasonable data practices. Enforce it structurally (§15), not just in policy text.

---

## 11. If HIPAA Applies: Breach Notification Rule (45 CFR 164.400–414)

If the Company is a business associate and a breach of unsecured PHI occurs, it must:

- **Notify the covered entity** without unreasonable delay (business associates report to the CE, which
  then notifies individuals).
- Support notification to **affected individuals** without unreasonable delay and **no later than 60
  days** from discovery.
- Support notification to **HHS/OCR**, and to **prominent media** for breaches affecting **500+**
  residents of a state or jurisdiction.

This differs in trigger, timeline, and recipients from the FTC HBNR track (§13). The dual-regime runbook
lives in [`./incident_response_plan.md`](./incident_response_plan.md).

---

## 12. Cloud & Infrastructure BAAs (Google Cloud / Firebase)

**Rule: sign the BAA and restrict the architecture to HIPAA-eligible Covered Products BEFORE any PHI is
stored.** A Firebase/GCP BAA covers **only enumerated services** and only when configured correctly.
Storing PHI in a non-covered service, or in identity custom claims / profile fields, **breaks compliance
even with a signed BAA.**

Requirements before storing any identifiable health data in the cloud:

1. **Execute the Google Cloud BAA** for the Company's GCP/Firebase organization.
2. **Limit the architecture to HIPAA-eligible "Covered Products"** — expected to include **Cloud
   Firestore, Firebase Authentication / Identity Platform, Cloud Storage, and Cloud Functions** — deployed
   in a supported region **[GCP REGION]**. **Verify the exact current Covered Products list against
   Google's official "HIPAA Compliance on Google Cloud" page at BAA-signing time;** the list changes, and
   third-party blog lists drift and must not be relied on.
3. **Keep PHI out of non-covered surfaces:** no PHI in **Google Analytics / Firebase Analytics**, no PHI
   in **Crashlytics** or any telemetry (all already disabled — **keep disabled**), no PHI used as a
   convenience payload in Realtime Database if RTDB is not covered/used, and **no PHI in auth custom
   claims or user-profile fields**.
4. **Map every third party** that could receive identifiable health data (cloud, auth, push, any future
   analytics) and confirm contractual coverage (BAA flow-down under HIPAA; and, under FTC HBNR, that no
   unauthorized disclosure occurs) **before enabling it.**

---

## 13. Parallel Non-HIPAA Obligation: FTC Health Breach Notification Rule (2024 amendments)

**This applies to NguyenInDoubt as a D2C app even though HIPAA does not.**

- The FTC HBNR (**16 CFR Part 318**, as amended effective **July 29, 2024**) applies to **vendors of
  personal health records (PHRs) and related entities NOT covered by HIPAA** — i.e., most health apps.
- The 2024 amendments confirm coverage of apps that draw **"PHR identifiable health information from
  multiple sources."** NguyenInDoubt imports sleep data from **Apple HealthKit / Google Health Connect**
  **and** combines it with **user-entered data** — a multi-source configuration squarely within the
  definition.
- Critically, the amendments clarify that an **unauthorized disclosure is itself a reportable "breach of
  security"** — not just a security intrusion. An accidental exposure of journal content to a clinician,
  or a sharing of health data with an analytics/advertising SDK without authorization, could be a
  reportable breach.
- On a breach, notify **affected individuals**, the **FTC**, and (for **500+** affected) the **media**,
  within the Rule's timelines and using its content requirements.
- Civil penalties can reach **up to $51,744 per violation** (amount subject to inflation adjustment;
  verify current figure).
- **FTC Act Section 5** is an independent basis for enforcement against deceptive privacy promises and
  unauthorized health-data sharing (cf. the GoodRx, BetterHelp, and Flo matters). Honoring the "clinician
  never sees journal content" promise and avoiding advertising/analytics SDKs is therefore both a product
  promise and a legal necessity.

**Implication:** The breach runbook in [`./incident_response_plan.md`](./incident_response_plan.md) must
be keyed to **FTC HBNR now** (and to HIPAA **if/when** the Company becomes a BA).

---

## 14. Parallel Non-HIPAA Obligation: State Consumer Health Privacy Laws

**Washington My Health My Data Act (MHMDA), RCW 19.373 — likely applies today, regardless of HIPAA.**

- MHMDA regulates **"consumer health data"** — information linkable to a consumer that identifies past,
  present, or future **physical OR mental** health status, expressly **including mental-health
  interventions** — held by **non-HIPAA entities** that do business in Washington or target WA consumers.
- A mental-health app distributed via the app stores reaches WA residents by default, so MHMDA very
  likely applies to NguyenInDoubt **even in the demo/early stage.**
- MHMDA requires, among other things: **consent or necessity** to collect/process consumer health data;
  a **SEPARATE consent to share**; a **signed authorization to sell**; a **distinct, linked
  consumer-health-data privacy policy** (the WA AG requires it be its own policy, **not** buried in the
  general privacy policy); and consumer **rights of access and deletion**. Enforced via the WA Consumer
  Protection Act (AG **and** a private right of action).
- **Analogues:** **Nevada SB 370** and **Connecticut** consumer-health-data amendments impose similar
  obligations; assume comparable requirements for those states' residents.

**Action:** Publish the separate consumer-health-data privacy policy (drafted as its own document; see
[`./privacy_policy.md`](./privacy_policy.md)), obtain **separate, affirmative consent** for (a) collecting
health data and (b) sharing sleep summaries with a clinician, provide an easy revocation path, retain
consent history, and honor access/deletion requests.

---

## 15. Special Sensitivity: Journal Content, Mental-Health Data & the Never-Share Promise

The private journal is the **highest-sensitivity** data the App holds (free-text mental-health content).
The core privacy promise — **clinicians NEVER see journal content; a consented clinician sees ONLY sleep
summaries** — must be enforced **in code and in Firestore security rules, not just in policy text**:

- **Separate collections/paths** for journal data vs. sleep summaries.
- A **clinician role with NO read path** to journal documents.
- **Deny-by-default** Firestore security rules; the clinician role is granted access **only** to the
  specific consented sleep-summary documents, scoped to patients who have an active, unrevoked consent.
- **No journal content in auth custom claims or profile fields**, and none in analytics/telemetry.
- **Log consent grant and revocation events** to make the promise auditable and to establish the
  individual-directed nature of any clinician disclosure (§6).

A structural control here is what prevents an accidental impermissible disclosure — which, under whichever
regime governs (FTC HBNR now; HIPAA if a BA), would be a reportable breach.

---

## 16. Crisis / Safety Posture & Non-Diagnostic Positioning

- The App is a **companion**, not a treatment tool. It surfaces **988** (Suicide & Crisis Lifeline;
  call/text) and **911** for emergencies, and **explicitly does not** diagnose, treat, monitor for
  emergencies, or provide patient-to-clinician messaging in this MVP.
- This non-treatment positioning **reinforces** that the Company is **not a health care provider / covered
  entity** (§5), but it does **not** exempt the Company from FTC or state consumer-health-privacy
  obligations.
- Crisis language and non-diagnostic disclaimers should be consistent across
  [`./terms_of_service.md`](./terms_of_service.md), [`./privacy_policy.md`](./privacy_policy.md), and the
  in-app UI. Safety-escalation handling is covered in
  [`./support_escalation_process.md`](./support_escalation_process.md).

---

## 17. Gap Analysis: Current Posture vs. Target Posture

| Area | Current posture | Target posture (before/at cloud go-live) | Gap / condition |
|---|---|---|---|
| HIPAA classification | Neither (D2C demo) | Neither, unless a CE arrangement is entered | Re-run §7 before any provider/health-system deal |
| Cloud PHI at rest | None (device-local) | Only after go-live gate satisfied | Gate = §18 checklist |
| Google Cloud BAA | Not executed | Executed before any PHI stored | **Blocking** for cloud go-live |
| HIPAA-eligible services only | N/A (no cloud storage) | Firestore/Auth/Storage/Functions only, [GCP REGION] | Verify Covered Products list at signing |
| Analytics / Crashlytics / telemetry | Disabled | Remain disabled; no PHI in them ever | Keep disabled |
| Journal wall-off | Design intent | Enforced in code + Firestore rules, deny-by-default | Verify with tests before go-live |
| Separate consent (collect vs. share) | To confirm | Granular, affirmative, separate, revocable, logged | Required by WA MHMDA now |
| Consumer-health-data privacy policy | To publish | Distinct, linked policy live | Required by WA MHMDA now |
| FTC HBNR breach runbook | To finalize | Live before go-live | See incident_response_plan.md |
| Security safeguards (164.312) | Baseline | Encryption in transit/at rest, access control, audit logging | Adopt as baseline now |
| Placeholders resolved | Open | All resolved and counsel-approved | See §19 |

---

## 18. Recommendations & Production Decision Gate

### 18.1 Do now (demo stage)

- Keep the demo **device-local**; no identifiable health data at rest in the cloud.
- Keep analytics/telemetry/Crashlytics **disabled**.
- Adopt **HIPAA Security Rule safeguards** (encryption in transit/at rest, access controls, audit
  logging, minimum-necessary sharing) as the **baseline standard**.
- Enforce the journal wall-off **structurally** (§15) and add tests proving the clinician role cannot read
  journal data.
- Obtain **granular, separate, affirmative consent** for (a) health-data collection and (b) clinician
  sleep-summary sharing; provide easy revocation; retain consent history.
- Publish the **consumer-health-data privacy policy** (WA MHMDA) as a distinct, linked document.
- Finalize the **FTC HBNR** breach runbook.

### 18.2 Production go-live decision gate (before enabling live Firebase storage of identifiable data)

**All of the following must be satisfied — this is a formal gate, not an engineering toggle:**

1. **Executed Google Cloud BAA.**
2. **Architecture limited to HIPAA-eligible Covered Products** (Cloud Firestore, Firebase Auth / Identity
   Platform, Cloud Storage, Cloud Functions) in a supported region **[GCP REGION]** — verified against
   Google's current Covered Products list.
3. **No PHI in Analytics/Crashlytics/telemetry** (keep disabled) and **no PHI in auth custom claims /
   profile fields.**
4. **Encryption** (in transit and at rest), **access controls**, and **audit logging** in place.
5. **Breach runbook** for the applicable regime(s) — FTC HBNR now; HIPAA if the Company becomes a BA —
   tested and staffed.
6. **All placeholders resolved** ([LEGAL ENTITY NAME], [JURISDICTION], [RETENTION PERIOD], [PRIVACY
   CONTACT EMAIL], [GCP REGION], etc.) and the full document set **approved by counsel licensed in
   [JURISDICTION].**

### 18.3 Before any covered-entity / clinician-practice arrangement

- **Stop and re-run §7.** If any of scenarios (a)–(d) applies, the Company **becomes a business
  associate**: execute a BAA **before** receiving PHI, attach the Security/Privacy/Breach Rules, and
  establish subcontractor flow-down BAAs. Route to counsel first. See the deeper analysis in this
  document and coordinate with [`./incident_response_plan.md`](./incident_response_plan.md).

---

## 19. Open Items / To Finalize Before Launch

- [ ] **[LEGAL ENTITY NAME]** — confirm the exact legal entity that operates the App.
- [ ] **[JURISDICTION]** — governing law / venue; confirm counsel is licensed there.
- [ ] **[PRIVACY CONTACT EMAIL]** and **[SUPPORT EMAIL]** — publish and route.
- [ ] **[DPO NAME]** — designate a privacy/compliance owner (if applicable).
- [ ] **[POSTAL ADDRESS]** — registered physical/mailing address.
- [ ] **[GCP REGION]** — chosen HIPAA-eligible region for Firestore/Storage/Functions.
- [ ] **[RETENTION PERIOD]** — retention periods per data category (profile, journal, sleep, consent
      history) and deletion procedures.
- [ ] **[EFFECTIVE DATE]** / **[DATE]** / **[DOCUMENT VERSION]** — finalize.
- [ ] Verify Google Cloud **Covered Products** list at BAA-signing time (do not rely on this document's
      list).
- [ ] Confirm current **FTC HBNR** civil-penalty amount (inflation-adjusted).
- [ ] Confirm applicability and specifics of **state consumer-health-privacy laws** for all target states
      (WA, NV, CT, and any others).
- [ ] Confirm **Apple HealthKit** and **Google Health Connect** platform terms are honored (e.g.,
      prohibition on using HealthKit data for advertising).
- [ ] **Legal counsel review and sign-off** on this analysis and all sibling documents.

---

## 20. Appendices

### Appendix A — Decision-tree quick reference

See §7 for the full tree. Summary:

- **Device-local demo → no cloud PHI → NEITHER** (FTC HBNR + state law may still apply).
- **Cloud storage for the consumer, no CE contract → NEITHER for HIPAA** (FTC HBNR + WA MHMDA apply; GCP
  BAA advisable).
- **Cloud storage on behalf of a covered entity under contract → BUSINESS ASSOCIATE** (BAA required;
  Security/Privacy/Breach Rules attach).

### Appendix B — BAA required-elements checklist (45 CFR 164.504(e))

- [ ] Permitted/required uses and disclosures established.
- [ ] Other use/disclosure prohibited.
- [ ] Appropriate safeguards + Security Rule (Subpart C) compliance for ePHI required.
- [ ] Reporting of impermissible use/disclosure, security incidents, and breaches required.
- [ ] Flow-down to subcontractors (164.504(e)(5)).
- [ ] PHI made available for access / amendment / accounting.
- [ ] Termination for material breach; return/destruction of PHI at termination.

### Appendix C — Expected HIPAA-eligible Firebase/GCP services (verify at signing)

- Cloud Firestore
- Firebase Authentication / Identity Platform
- Cloud Storage
- Cloud Functions

**Do NOT store PHI in:** Firebase Analytics / Google Analytics, Crashlytics, any telemetry, auth custom
claims, or profile fields. **Verify the authoritative Covered Products list on Google Cloud's "HIPAA
Compliance on Google Cloud" page at BAA-signing time — it changes.**

### Appendix D — Authorities & citations

- 45 CFR 160.103 — Definitions (covered entity; business associate; PHI).
- 45 CFR 164.502(e), 164.504(e) — Business associate contracts / organizational requirements.
- 45 CFR 164.308 / 164.310 / 164.312 — Security Rule administrative / physical / technical safeguards.
- 45 CFR 164.502(b), 164.514(d) — Privacy Rule minimum-necessary standard.
- 45 CFR 164.400–414 — Breach Notification Rule.
- FTC Health Breach Notification Rule, 16 CFR Part 318 (2024 amendments, eff. July 29, 2024).
- FTC Act Section 5 — Unfair or deceptive acts or practices.
- Washington My Health My Data Act, RCW 19.373 (2024); Nevada SB 370; Connecticut consumer-health-data
  amendments.

**Selected source URLs (verify current versions):**

- HHS OCR — HIPAA & Health Apps: https://www.hhs.gov/hipaa/for-professionals/special-topics/health-apps/index.html
- HHS OCR — Access Right, Health Apps, & APIs: https://www.hhs.gov/hipaa/for-professionals/privacy/guidance/access-right-health-apps-apis/index.html
- HHS OCR — Health App Use Scenarios & HIPAA (Feb 2016): https://www.hhs.gov/sites/default/files/ocr-health-app-developer-scenarios-2-2016.pdf
- HHS FAQ 3013 — BAA with an individual-designated app: https://www.hhs.gov/hipaa/for-professionals/faq/3013/does-hipaa-require-a-covered-entity-to-enter-into-a-business-associate-agreement.html
- HHS — Sample Business Associate Agreement Provisions: https://www.hhs.gov/hipaa/for-professionals/covered-entities/sample-business-associate-agreement-provisions/index.html
- eCFR — 45 CFR 164.504: https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-E/section-164.504
- eCFR — 45 CFR 164.502: https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-E/section-164.502
- HHS — Summary of the HIPAA Security Rule: https://www.hhs.gov/hipaa/for-professionals/security/laws-regulations/index.html
- FTC — Complying with the Health Breach Notification Rule: https://www.ftc.gov/business-guidance/resources/complying-ftcs-health-breach-notification-rule-0
- FTC — Health Breach Notification Rule Final Rule (text): https://www.ftc.gov/system/files/ftc_gov/pdf/hbnr_final_rule_04_25.pdf
- Google Cloud — HIPAA Compliance on Google Cloud: https://cloud.google.com/security/compliance/hipaa-compliance
- Washington My Health My Data Act — RCW 19.373: https://app.leg.wa.gov/RCW/default.aspx?cite=19.373&full=true
- Washington State AG — Protecting Washingtonians' Personal Health Data: https://www.atg.wa.gov/protecting-washingtonians-personal-health-data-and-privacy
- IAPP — Washington's My Health, My Data Act Overview: https://iapp.org/resources/article/washington-my-health-my-data-act-overview

---

*End of document. This is a DRAFT — not legal advice. Route through counsel licensed in [JURISDICTION]
before any production use.*
