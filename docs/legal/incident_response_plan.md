# Security Incident Response & Breach Notification Plan

> ⚠️ **DRAFT TEMPLATE — NOT LEGAL ADVICE.** This document is a drafting template for the NguyenInDoubt application. It **MUST be reviewed, completed, and approved by qualified legal counsel licensed in [JURISDICTION]** before it is relied upon or put into production use. It does not constitute legal advice, and no attorney-client relationship is created by its use. Every bracketed placeholder must be resolved before this plan takes effect. The breach-notification obligations described below are **conditional** and depend on go-live decisions and facts (see the applicability tests in §9–§11).
>
> **Last updated:** [DATE]
> **Status:** DRAFT — not yet in effect
> **Document owner:** [DPO / PRIVACY OFFICER] — [PRIVACY CONTACT EMAIL]
> **Applies to:** [LEGAL ENTITY NAME] ("the Company"), operator of the NguyenInDoubt companion application

---

## Table of Contents

1. [Purpose, Scope & Definitions](#1-purpose-scope--definitions)
2. [Roles & Responsibilities (Incident Response Team)](#2-roles--responsibilities-incident-response-team)
3. [Governance & Program Management](#3-governance--program-management)
4. [Severity & Incident Classification Matrix](#4-severity--incident-classification-matrix)
5. [Prepare (CSF Govern / Identify / Protect)](#5-prepare-csf-govern--identify--protect)
6. [Detect & Analyze](#6-detect--analyze)
7. [Contain, Eradicate & Recover](#7-contain-eradicate--recover)
8. [Evidence Preservation & Forensics](#8-evidence-preservation--forensics)
9. [Breach Determination & Risk Assessment](#9-breach-determination--risk-assessment)
10. [Regulatory & User Notification Decision Flow](#10-regulatory--user-notification-decision-flow)
11. [Breach Notification Timeline & Trigger Matrix](#11-breach-notification-timeline--trigger-matrix)
12. [Communications Plan & Notification Templates](#12-communications-plan--notification-templates)
13. [Post-Incident Activity / Lessons Learned](#13-post-incident-activity--lessons-learned)
14. [Incident Runbook Quick Reference](#14-incident-runbook-quick-reference)
15. [Third-Party, Vendor & Sub-processor Incidents](#15-third-party-vendor--sub-processor-incidents)
16. [Record-Keeping, Metrics & Regulator Cooperation](#16-record-keeping-metrics--regulator-cooperation)
17. [Definitions & Acronyms](#17-definitions--acronyms)
18. [Open Items / To Finalize Before Launch](#18-open-items--to-finalize-before-launch)

---

## 1. Purpose, Scope & Definitions

### 1.1 Purpose
This plan establishes how [LEGAL ENTITY NAME] prepares for, detects, analyzes, contains, and recovers from security and privacy incidents affecting the NguyenInDoubt application, and how it determines and discharges any breach-notification obligations. It is built on **NIST SP 800-61 Rev. 3 (April 2025)**, mapped to the **NIST Cybersecurity Framework (CSF) 2.0** functions (Govern, Identify, Protect, Detect, Respond, Recover). The familiar operational lifecycle — Prepare → Detect & Analyze → Contain, Eradicate & Recover → Post-Incident Activity — is retained as the runbook layer (§5–§8, §13).

### 1.2 Scope — systems in scope
- **Firebase Authentication** (identity) and **Cloud Firestore** (production data store) — the compliance-gated production backend boundary. **Firestore security rules are the production access boundary** enforcing that a clinician can read only consented sleep summaries and **never** journal content.
- **Apple HealthKit** and **Google Health Connect** import paths (sleep samples and daily summaries flow from the device platform into the app).
- **Device-local demo store** (in-memory / local storage) used by the current public demo — no cross-device sync, no cloud PHI at rest.
- Consent artifacts: clinician **invite/consent link** and **consent history**.
- Company workstations, source code, secrets/keys, and any administrative access to [FIREBASE/GCP REGION] infrastructure.

**Current live breach surface is minimal.** The public demo is device-local only, with no analytics, no Crashlytics, and no telemetry. Most obligations in this plan **activate when compliance-gated Firebase/Firestore production storage is enabled** (see the go-live gate in §18 and `./hipaa_baa_analysis.md`).

### 1.3 Data classes (sensitivity ranking)
| Class | Examples | Sensitivity | Notes |
|---|---|---|---|
| **Private journal content** | Free-text mental-health journaling | **HIGHEST** | Core privacy promise; never shared with clinicians. Any exposure = automatic top severity (§4). |
| Health / sleep data | HealthKit / Health Connect sleep samples, daily sleep summaries | High (special-category) | Consented sleep summaries are the only clinician-visible data. |
| Consent records | Clinician invite/consent link, consent grant/revocation history | High (legally load-bearing) | Tampering can invalidate the lawful basis for clinician access. |
| Account / profile | Email, display name, auth identifiers | Moderate | |

### 1.4 Definitions (event vs. incident vs. breach)
- **Event:** any observable occurrence in a system (may be benign).
- **Security incident:** an event (or series) that actually or imminently jeopardizes the confidentiality, integrity, or availability (CIA) of in-scope systems or data, or violates security/privacy policy.
- **Breach (regulatory):** an incident that meets the legal definition of a reportable breach under an applicable regime (HIPAA §164.402, FTC HBNR "breach of security," GDPR "personal data breach," or a US state statute). **Not every incident is a breach** — see §9. Full acronym glossary in §17.

---

## 2. Roles & Responsibilities (Incident Response Team)

### 2.1 Core roles
| Role | Responsibility | Assigned to |
|---|---|---|
| **Incident Commander (IC)** | Owns the incident end-to-end; declares severity; coordinates the team; authorizes containment. | [IC NAME / ON-CALL] |
| **Privacy / Legal Lead** | Runs breach determination (§9), owns the notification decision (§10–§11), approves all external comms, engages outside counsel. | [DPO / PRIVACY OFFICER] — [PRIVACY CONTACT EMAIL] |
| **Engineering Lead** | Technical investigation, containment, eradication, recovery; log/evidence collection; Firestore rules and key/credential actions. | [ENGINEERING LEAD] |
| **Communications Lead** | Drafts and sequences internal/external messaging from approved templates (§12); manages user, clinician-partner, media, and regulator comms. | [COMMS LEAD] |
| **Support Liaison** | Bridges to the support team; surfaces incident signals from tickets; assists user-notification logistics. See `./support_escalation_process.md`. | [SUPPORT LEAD] |
| **Executive Sponsor** | Business decisions, budget, external-counsel authorization, final sign-off on regulator filings. | [EXECUTIVE SPONSOR] |

### 2.2 On-call & escalation
- On-call rotation and 24/7 reachability: [ON-CALL ROTATION / PAGER]. **Note:** on-call covers *security incidents* only — it is **not** user-facing emergency monitoring. NguyenInDoubt does not monitor accounts or respond to user emergencies (see crisis posture in §1 and `./support_escalation_process.md`).
- Escalation ladder: Detector → IC → Privacy/Legal Lead + Engineering Lead → Executive Sponsor → outside counsel [OUTSIDE COUNSEL] / forensic vendor [FORENSIC VENDOR].

### 2.3 RACI (summary)
| Activity | IC | Privacy/Legal | Engineering | Comms | Exec |
|---|---|---|---|---|---|
| Declare incident & severity | **A/R** | C | C | I | I |
| Containment actions | A | C | **R** | I | I |
| Breach determination (§9) | C | **A/R** | C | I | I |
| Regulator/user notification | C | **A/R** | C | **R** | A |
| External statements / media | I | A | I | **R** | A |
| Post-incident review | **A/R** | C | C | C | I |

*R = Responsible, A = Accountable, C = Consulted, I = Informed.*

---

## 3. Governance & Program Management

- **Framework mapping.** Preparation activities map to CSF 2.0 **Govern** (policy, roles, risk strategy), **Identify** (asset & data-flow inventory, risk assessment), and **Protect** (access control, encryption, Firestore rules). Response activities map to **Detect**, **Respond**, and **Recover**.
- **Policy owner:** [DPO / PRIVACY OFFICER]. **Approver:** [EXECUTIVE SPONSOR] / [OUTSIDE COUNSEL].
- **Review cadence:** at minimum annually, and upon any of: enabling production Firebase storage, executing a clinician/BAA arrangement, a material architecture change, or a SEV1/SEV2 incident.
- **Training:** all workforce members with data access complete IR and privacy awareness training at onboarding and annually; support staff additionally train on the crisis-content protocol (`./support_escalation_process.md`).
- **Tabletop exercises:** run at least one tabletop per year; mandatory scenarios include (a) journal-content exposure and (b) a Firestore-rules misconfiguration leaking cross-patient data.

---

## 4. Severity & Incident Classification Matrix

Severity is driven primarily by **data sensitivity and risk of harm**, not record count. **Any confirmed or suspected exposure of private journal content is automatically SEV1**, even for a single user, because it breaks the app's core privacy promise.

| Severity | Definition & example triggers | Response |
|---|---|---|
| **SEV1 — Critical** | Confirmed/suspected exposure of **journal content**; clinician or third party able to read journal data; cross-patient data leakage; consent-record tampering that invalidates lawful basis; large-scale credential compromise; ransomware/data destruction. | Immediate IC + full IRT activation; legal hold; outside counsel + forensic vendor engaged; breach clock treated as running from discovery. |
| **SEV2 — High** | Exposure of **sleep/health data or consent records** beyond consented scope; Firestore-rules misconfiguration with potential (unconfirmed) journal/cross-user access; account takeover of a limited set of users; sensitive data exposed but likely encrypted/secured. | IC activation within [X] hours; full triage & scoping; provisional breach assessment started. |
| **SEV3 — Moderate** | Exposure of account/profile data; single-account compromise with no health/journal data reached; vendor incident with no confirmed data impact to us. | Handle within business hours; document; assess for notification. |
| **SEV4 — Low** | Policy violation, near-miss, failed intrusion attempt, misconfiguration caught before exposure, false alarm. | Log in incident register (§16); no escalation unless pattern emerges. |

**Escalation thresholds:** any SEV3 that on investigation touches journal, health, or consent data is immediately re-classified upward. When in doubt, classify **higher** and de-escalate later.

---

## 5. Prepare (CSF Govern / Identify / Protect)

- **Asset & data-flow inventory.** Maintain a current map of where each data class (§1.3) lives and flows: device-local demo store; Firebase Auth; Firestore collections (with the structural wall separating journal documents from sleep summaries); HealthKit/Health Connect import paths; consent artifacts.
- **Access controls.** Deny-by-default **Firestore security rules**; the clinician role has **no read path** to journal documents. Enforce least privilege on administrative/console access to [FIREBASE/GCP REGION].
- **Encryption.** Document encryption in transit and at rest and key separation as controls (relevant to the "secured data" safe-harbor analysis in §9). [CONFIRM ENCRYPTION POSTURE / KEY MANAGEMENT].
- **Logging (detection prerequisite).** The current demo has **no telemetry/Crashlytics**, which limits automated detection. **Before production go-live**, enable privacy-preserving, compliance-reviewed server-side logging (Firebase/GCP audit logs, Firestore access logs). **Do not log journal content.**
- **Backups.** Configure and test Firestore backups/restore for [FIREBASE/GCP REGION] before production.
- **Contacts & playbooks.** Keep the contact card (§14.4), vendor SLAs (§15), pre-approved templates (§12), and outside counsel/forensic vendor on retainer or pre-identified.

---

## 6. Detect & Analyze

- **Detection sources:** Firebase/GCP audit and Firestore access logs (once enabled); auth anomaly signals; vendor (Google/Apple) security notices; **support tickets** (a frequent first detector — e.g., a user reports seeing another user's journal → immediate IR hand-off per `./support_escalation_process.md`); external/researcher reports.
- **Triage & declaration.** The IC confirms the event is a genuine incident (filter false positives), assigns provisional severity (§4), timestamps the **moment of discovery** (starts regulatory clocks), and opens an incident record (§16).
- **Scoping — the pivotal question.** Determine **whether journal content was ever exposed, or only sleep summaries / lesser data.** This single determination drives severity, breach analysis, and notification obligations. Establish: which data classes, how many individuals, which states/countries of residence [affects §11], whether data was secured/encrypted, and whether a clinician/BAA relationship exists [affects HIPAA branch].
- **Detection gap note.** Until production logging exists, detection depends heavily on user reports and vendor notices; treat this as a known limitation and prioritize logging in the go-live gate (§18).

---

## 7. Contain, Eradicate & Recover

> **Preserve evidence FIRST.** Before any containment action that alters logs or systems, execute the legal-hold and preservation steps in §8. Key rotation and backup restores can destroy evidence.

- **Short-term containment:** disable affected accounts/sessions; block offending access paths; if a Firestore-rules flaw is implicated, deploy corrected deny-by-default rules; take the affected feature offline if needed.
- **Consent-specific containment:** where consent records are implicated or clinician access is suspect, **revoke affected (or all) clinician invite/consent links** and suspend clinician read access until integrity is validated.
- **Eradication:** rotate credentials, API keys, and service-account secrets; remove attacker persistence/access; patch the root vulnerability; re-verify Firestore rules against journal/cross-user read paths.
- **Recovery:** restore from validated clean backups; verify data integrity (especially consent-history integrity); confirm the journal↔clinician wall is intact via test cases; monitor for recurrence before declaring recovery complete.
- **Validation gate:** IC + Engineering Lead sign off that CIA is restored and that no journal read path exists for the clinician role before returning to normal operations.

---

## 8. Evidence Preservation & Forensics

- **Legal hold on declaration.** On incident declaration (SEV1/SEV2), the Privacy/Legal Lead issues a legal hold suspending routine deletion/rotation of relevant logs, backups, and systems.
- **Chain of custody.** Record who collected what, when, from where, and how it was stored. Preserve original logs (Firebase/GCP audit, Firestore access), system images, and timestamps; work on **copies**.
- **Do-not-alter.** No investigator modifies source evidence; hashing recommended to prove integrity.
- **Vendor & counsel.** Engage forensic vendor [FORENSIC VENDOR] and outside counsel [OUTSIDE COUNSEL] for SEV1/SEV2; where appropriate, conduct the investigation under privilege.
- **Rationale.** Forensic integrity is required for regulator cooperation (HHS OCR, FTC, DPAs) and potential litigation, and to substantiate the §9 risk assessment.

---

## 9. Breach Determination & Risk Assessment

Determine, and **document**, whether the incident is a reportable breach under each potentially applicable regime. Record the rationale even where the conclusion is "no notice required" (§16).

### 9.1 Secured-data / encryption safe harbor (first-line analysis)
Both the HIPAA Breach Notification Rule and the FTC HBNR key on **"unsecured"** data. If the exposed data was encrypted/secured to the applicable standard with keys not compromised, notification duties may be reduced or eliminated. Document encryption status and key control for the affected data as the first analytical step.

### 9.2 HIPAA 4-factor risk assessment (only if HIPAA applies — see §10 and `./hipaa_baa_analysis.md`)
If [LEGAL ENTITY NAME] is a **business associate** (via a clinician/covered-entity relationship + BAA), an impermissible use/disclosure is a presumed breach unless a low probability of compromise is shown across: (1) nature/extent of PHI involved; (2) the unauthorized recipient; (3) whether PHI was actually acquired/viewed; (4) extent to which risk has been mitigated.

### 9.3 FTC HBNR (consumer/default path)
For the consumer app, assess whether a **"breach of security"** of **unsecured PHR identifiable health information** occurred. Under the 2024 amendments this **includes unauthorized disclosures**, not only intrusions. NguyenInDoubt near-certainly qualifies as a **multi-source PHR vendor** (it draws health data from HealthKit/Health Connect **plus** user-entered journal/sleep data).

### 9.4 GDPR / UK GDPR (only if EU/UK data subjects — conditional on [FIREBASE/GCP REGION] and user base)
Assess whether a "personal data breach" occurred and whether it is likely to result in a **risk** (DPA notice) or **high risk** (individual notice) to rights and freedoms. Journal + health data are **Art. 9 special-category data**, which raises the risk assessment.

### 9.5 US state laws
Assess covered-PII definitions and thresholds for each affected resident's state (increasingly includes health/biometric data); also consider consumer-health-privacy laws (e.g., Washington My Health My Data Act, Nevada SB 370) and comprehensive state privacy laws (CCPA/CPRA and successors).

---

## 10. Regulatory & User Notification Decision Flow

Resolve **which legal regime(s) apply before assuming any single timeline.** The same incident can trigger several regimes simultaneously, each with its own clock.

```
                        ┌─────────────────────────────────────────┐
                        │ Confirmed reportable breach of unsecured │
                        │ data? (see §9 — secured-data safe harbor)│
                        └───────────────┬─────────────────────────┘
                       No → log & close │ Yes
                          (§16)         ▼
        ┌──────────────────────────────────────────────────────────────┐
        │ Q1. Is [LEGAL ENTITY NAME] a HIPAA business associate for this │
        │ data? (clinician/covered-entity relationship + BAA in place)  │
        │  → see ./hipaa_baa_analysis.md decision tree                   │
        └───────────────┬───────────────────────────┬──────────────────┘
                    Yes │                            │ No
                        ▼                            ▼
          ┌──────────────────────┐     ┌──────────────────────────────────┐
          │ HIPAA branch:        │     │ FTC HBNR branch (default consumer │
          │ notify the covered   │     │ path): multi-source PHR vendor →  │
          │ entity per BAA;      │     │ notify individuals + FTC          │
          │ 60-day rule (§11)    │     │ (+ media if 500+), 60-day (§11)   │
          └──────────────────────┘     └──────────────────────────────────┘
                        │                            │
                        └────────────┬───────────────┘
                                     ▼
        ┌──────────────────────────────────────────────────────────────┐
        │ Q2. Any EU/UK data subjects affected?  (depends on user base   │
        │      and [FIREBASE/GCP REGION])                                │
        │   Yes → GDPR/UK GDPR: DPA within 72h; individuals if high risk │
        └───────────────────────────────┬──────────────────────────────┘
                                         ▼
        ┌──────────────────────────────────────────────────────────────┐
        │ Q3. Which US states are affected residents in?                 │
        │   → apply each state's breach law + consumer-health-privacy    │
        │     laws (WA MHMDA, NV SB 370) + CCPA/CPRA where applicable    │
        └──────────────────────────────────────────────────────────────┘
```

**All applicable branches run in parallel.** The Privacy/Legal Lead owns the determination; outside counsel confirms applicability given unresolved placeholders.

---

## 11. Breach Notification Timeline & Trigger Matrix

> **CONDITIONAL — confirm applicability and every value with counsel.** Which regimes attach depends on unresolved placeholders ([JURISDICTION], [FIREBASE/GCP REGION], user base, whether a BAA exists). Clocks generally run **from discovery**. Cross-reference `./hipaa_baa_analysis.md`.

| Regime | Applies when | Notify whom | Deadline | Content / threshold notes |
|---|---|---|---|---|
| **HIPAA Breach Notification Rule** (45 CFR 164.400–414) | Only if Company is a **business associate** (clinician CE + BAA). | The **covered entity** (per BAA); the CE then notifies individuals/HHS. | Notify CE **without unreasonable delay, ≤ 60 calendar days** from discovery (BAA may shorten). | CE-side: individuals ≤60 days; HHS ≤60 days if 500+ (annual log for <500); media if 500+ in one state. 4-factor test (§9.2); unsecured-PHI trigger. |
| **FTC Health Breach Notification Rule** (16 CFR Part 318, amended 2024) | **Default consumer path** — non-HIPAA multi-source PHR vendor (HealthKit/Health Connect + user input). | **Affected individuals**; the **FTC**; **media** if 500+. | Individuals **without unreasonable delay, ≤ 60 days**; FTC **at the same time as individuals when 500+** (else ≤60 days after calendar year-end); media if 500+. | "Breach of security" includes **unauthorized disclosure**. Expanded/modernized notice content; electronic notice permitted. Penalties up to ~$51,744/violation. |
| **GDPR / UK GDPR** (Art. 33 & 34) | Only if **EU/UK data subjects** affected. | Supervisory authority (**DPA**); **individuals** if high risk. | DPA **within 72 hours** of awareness (unless unlikely to result in risk); individuals **without undue delay** if high risk. | Journal/health = **Art. 9 special-category** → elevated risk. Maintain internal breach register (Art. 33(5)). |
| **US State Breach Laws** (50 states + DC/territories) | Based on **affected residents' state**. | Individuals; state **AG/regulator** above certain thresholds. | Varies — many "without unreasonable delay"; several hard caps (e.g., 30/45/60 days). | Covered-PII definitions vary and increasingly include health/biometric data. Use a maintained 50-state chart (e.g., IAPP / major law firm) as a living reference. |
| **State consumer-health-privacy laws** (e.g., WA MHMDA, NV SB 370, CCPA/CPRA) | Non-HIPAA health data / applicable consumers. | Per statute (consumer notice/rights). | Per statute. | May impose their own security-incident and consumer-notice/rights obligations. |

---

## 12. Communications Plan & Notification Templates

**Approval chain:** all external communications are drafted by the Comms Lead, reviewed by the Privacy/Legal Lead, approved by the Executive Sponsor, and — for SEV1/SEV2 and any regulator filing — cleared by outside counsel [OUTSIDE COUNSEL] before release. Templates are pre-approved during Prepare so clocks are not lost to drafting.

### 12.1 Individual / user notice letter (template)
```
Subject: Important security notice about your NguyenInDoubt account

Dear [USER NAME],

We are writing to inform you of a data security incident that may have
involved your information. On [DATE OF DISCOVERY], [LEGAL ENTITY NAME]
discovered [PLAIN-LANGUAGE DESCRIPTION OF WHAT HAPPENED].

What information was involved: [DATA CLASSES INVOLVED — e.g., account
profile / sleep summaries / journal content].

What we are doing: [CONTAINMENT & REMEDIATION STEPS].

What you can do: [PROTECTIVE STEPS — e.g., change password, review
account]. This notice is not a diagnosis or medical advice.

If you are in emotional distress or crisis, help is available now:
call or text 988 (Suicide & Crisis Lifeline), or call 911 for a
life-threatening emergency. NguyenInDoubt does not monitor accounts
and cannot respond to emergencies.

For questions, contact us at [SUPPORT EMAIL] / [PRIVACY CONTACT EMAIL].

Sincerely,
[LEGAL ENTITY NAME] — [POSTAL ADDRESS]
```

### 12.2 Regulator submissions
- **HHS/OCR** (HIPAA branch, via covered entity or as directed): breach description, PHI types, individuals affected, mitigation, safeguards. See HHS breach-reporting portal.
- **FTC** (HBNR branch): file per FTC content requirements; same-time-as-individuals when 500+.
- **DPA** (GDPR branch): Art. 33 content — nature of breach, categories/approx. number of data subjects and records, DPO contact, likely consequences, measures taken; within 72 hours.

### 12.3 Media notice (500+ in a state — HIPAA/FTC)
Prominent-media statement for the affected state/jurisdiction; factual, counsel-approved, mirrors individual-notice content.

### 12.4 Clinician-partner notice (template)
```
To our clinician partners,

We are notifying you of a security incident that may affect data shared
through NguyenInDoubt consent links. [SCOPE]. Consented sleep summaries
[WERE / WERE NOT] involved. Private patient journal content is never
shared with clinicians and [WAS / WAS NOT] involved. Affected consent
links have been [REVOKED / suspended]. [NEXT STEPS].
Contact: [PRIVACY CONTACT EMAIL].
```

### 12.5 Holding statement & internal comms
- **Holding statement** (for inbound press/user questions before facts are confirmed): "We are aware of a potential security issue, are investigating with urgency, and will share verified information. Nothing is more important to us than the privacy of our users' data."
- **Internal:** notify workforce on a need-to-know basis; remind them not to speculate externally; route all inquiries to the Comms Lead.

---

## 13. Post-Incident Activity / Lessons Learned

- Hold a blameless retrospective within [X] business days of closure (mandatory for SEV1/SEV2).
- Produce a root-cause analysis and a corrective-action plan with owners and due dates (e.g., Firestore rule hardening, logging additions, key-management changes).
- Capture metrics: **MTTD**, **MTTR**, dwell time, records/individuals affected, regimes triggered.
- Update controls **and this plan**; feed changes into the next tabletop; confirm corrective actions are verified as implemented.

---

## 14. Incident Runbook Quick Reference

### 14.1 First 1 hour
1. Confirm it's a real incident; assign IC; **timestamp discovery**.
2. Assign provisional severity (§4). **Journal exposure = SEV1.**
3. Issue legal hold; **preserve evidence before containment** (§8).
4. Begin short-term containment (§7); if consent/clinician access implicated, revoke clinician consent links.
5. Open the incident record (§16); notify Privacy/Legal Lead.

### 14.2 First 24 hours
6. Scope: **journal exposed or only sleep summaries?** Count individuals; identify states/countries of residence; determine secured vs. unsecured data.
7. Engage forensic vendor / outside counsel for SEV1/SEV2.
8. Start §9 breach determination; begin §10 decision flow.
9. Prepare holding statement (§12.5); brief Executive Sponsor.

### 14.3 First 72 hours
10. **If EU/UK subjects involved → DPA notice within 72 hours** (§11).
11. Finalize which regimes apply; calendar every notification deadline from discovery.
12. Eradicate & begin validated recovery (§7); do not declare recovery until the journal↔clinician wall is re-verified.
13. Confirm and, where required, issue notifications within statutory windows (HIPAA/FTC 60-day; state caps).

### 14.4 Contact card
| Function | Contact |
|---|---|
| Incident Commander / on-call | [IC / ON-CALL / PAGER] |
| Privacy/Legal Lead (DPO) | [DPO NAME] — [PRIVACY CONTACT EMAIL] |
| Engineering Lead | [ENGINEERING LEAD] |
| Support Liaison | [SUPPORT LEAD] — [SUPPORT EMAIL] |
| Outside counsel | [OUTSIDE COUNSEL] |
| Forensic vendor | [FORENSIC VENDOR] |
| Firebase/Google Cloud support | [GOOGLE CLOUD SUPPORT / BAA CONTACT] |

---

## 15. Third-Party, Vendor & Sub-processor Incidents

Production storage runs on **Firebase / Google Cloud** in [FIREBASE/GCP REGION]; sleep data is sourced via **Apple HealthKit** and **Google Health Connect**. A provider-side incident still obligates [LEGAL ENTITY NAME] to assess and possibly notify.

- **Shared responsibility.** The provider secures the platform; the Company is responsible for its configuration, Firestore rules, access management, and data handling.
- **Upstream notice SLAs.** Contracts/DPAs (and any Google Cloud **BAA**, if the HIPAA branch is live) must guarantee timely upstream breach notification so downstream clocks (§11) can be met. Record each vendor's notification SLA: [VENDOR SLA — Google Cloud], [VENDOR SLA — Apple], [VENDOR SLA — Google Health Connect].
- **Who reports.** For consumer-side data, [LEGAL ENTITY NAME] is the reporting party (FTC HBNR / state / GDPR). Under a HIPAA BAA, the Company notifies the covered entity, which handles individual/HHS notice.
- On vendor-incident notice: open an internal incident record, run §6 scoping and §9 determination as if first-party.

---

## 16. Record-Keeping, Metrics & Regulator Cooperation

- **Incident register / breach log.** Record **every** incident — including SEV4 near-misses and **"no notice required"** determinations with their rationale. (HIPAA requires logging small breaches for annual HHS reporting; GDPR Art. 33(5) requires an internal register; documented risk assessments demonstrate good-faith compliance.)
- **Retention.** Retain incident records for [RETENTION PERIOD — confirm per HIPAA 6-year / applicable state law].
- **Regulator cooperation.** Preserve evidence (§8) and cooperate with HHS OCR, the FTC, and DPAs; route all regulator contact through the Privacy/Legal Lead and outside counsel.
- **Metrics reported to governance:** count by severity, MTTD/MTTR, notifications issued, corrective-action closure rate.

---

## 17. Definitions & Acronyms

- **BAA** — Business Associate Agreement (HIPAA).
- **CE / BA** — Covered Entity / Business Associate (HIPAA).
- **CIA** — Confidentiality, Integrity, Availability.
- **CSF** — NIST Cybersecurity Framework (2.0).
- **DPA** — Data Protection Authority (GDPR supervisory authority).
- **HBNR** — FTC Health Breach Notification Rule (16 CFR Part 318).
- **IC / IRT** — Incident Commander / Incident Response Team.
- **MTTD / MTTR** — Mean Time To Detect / Mean Time To Respond (or Recover).
- **OCR** — HHS Office for Civil Rights (HIPAA enforcement).
- **PHI / ePHI** — Protected Health Information / electronic PHI (HIPAA).
- **PHR** — Personal Health Record (FTC HBNR scope).
- **PII** — Personally Identifiable Information.
- **SEV1–SEV4** — Severity levels (§4).

---

## 18. Open Items / To Finalize Before Launch

**Placeholders to resolve (route through counsel licensed in [JURISDICTION]):**
- [ ] [LEGAL ENTITY NAME]
- [ ] [JURISDICTION] / governing law
- [ ] [DPO / PRIVACY OFFICER] name + [PRIVACY CONTACT EMAIL]
- [ ] [SUPPORT EMAIL]
- [ ] [POSTAL ADDRESS]
- [ ] [FIREBASE/GCP REGION] (drives which state/GDPR obligations attach and cross-border transfer questions)
- [ ] [RETENTION PERIOD] for incident records
- [ ] [EFFECTIVE DATE]
- [ ] Named IC / on-call rotation, Engineering Lead, Comms Lead, Support Liaison, Executive Sponsor
- [ ] [OUTSIDE COUNSEL] and [FORENSIC VENDOR] engaged/retained
- [ ] Vendor notification SLAs recorded (Google Cloud, Apple HealthKit, Google Health Connect)

**Production go-live gate — do NOT enable compliance-gated Firebase/Firestore production storage until:**
- [ ] This plan is finalized, approved, and in effect (Status changed from DRAFT).
- [ ] Privacy-preserving server-side logging enabled (Firebase/GCP audit + Firestore access logs); **no journal-content logging**; Crashlytics/telemetry remain disabled.
- [ ] Firestore backups configured and restore tested.
- [ ] Firestore deny-by-default rules verified: **clinician role has no read path to journal documents**; test cases pass for the journal↔clinician wall and cross-patient isolation.
- [ ] Encryption in transit/at rest and key separation documented (for the §9 safe-harbor analysis).
- [ ] HIPAA branch decision resolved and, **if** a clinician/BAA arrangement exists, Google Cloud BAA executed and architecture limited to HIPAA-eligible services (see `./hipaa_baa_analysis.md`).
- [ ] Notification templates (§12) pre-approved by counsel.
- [ ] Tabletop exercise completed for journal-exposure and Firestore-rules-misconfiguration scenarios.
- [ ] Support↔IR hand-off wired (`./support_escalation_process.md`); breach-notification matrix (§11) applicability confirmed with counsel.

**Related documents:** `./privacy_policy.md` · `./terms_of_service.md` · `./hipaa_baa_analysis.md` · `./support_escalation_process.md`

---

*End of DRAFT. This template must be reviewed and approved by qualified legal counsel before it is relied upon.*
