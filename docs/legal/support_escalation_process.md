# Support & Crisis-Escalation Process

> ⚠️ **DRAFT TEMPLATE — REQUIRES LEGAL REVIEW.**
> This document is a **DRAFT TEMPLATE** and **MUST be reviewed and approved by qualified legal counsel** (and, where applicable, a licensed clinical advisor) **before it is used in production**. It is **not legal advice** and does not create an attorney–client relationship. Language in the crisis, disclaimer, and duty-of-care sections is legally load-bearing — boilerplate that overpromises safety can create liability — so counsel must review it before any go-live.
>
> **Last updated:** [DATE]
> **Status:** DRAFT — not yet in effect

---

## Table of Contents

1. [Purpose & How to Use This Document](#1-purpose--how-to-use-this-document)
2. [Support Overview, Scope & Boundaries](#2-support-overview-scope--boundaries)
3. [Contact Channels & Hours](#3-contact-channels--hours)
4. [Support Tiers & SLAs](#4-support-tiers--slas)
5. [Support Triage Flow](#5-support-triage-flow)
6. [Mental-Health Crisis Escalation Protocol (In-App)](#6-mental-health-crisis-escalation-protocol-in-app)
7. [Crisis Content Seen via Support — Staff Protocol](#7-crisis-content-seen-via-support--staff-protocol)
8. [Duty of Care, Disclaimers & Liability Positioning](#8-duty-of-care-disclaimers--liability-positioning)
9. [Crisis Resource Accuracy & Maintenance](#9-crisis-resource-accuracy--maintenance)
10. [Interaction Between Support & Incident Response](#10-interaction-between-support--incident-response)
11. [Privacy & Data-Subject-Rights Requests via Support](#11-privacy--data-subject-rights-requests-via-support)
12. [Staff Wellbeing & Training](#12-staff-wellbeing--training)
13. [Definitions & Acronyms](#13-definitions--acronyms)
14. [Open Items / To Finalize Before Launch](#14-open-items--to-finalize-before-launch)
15. [Version Control & Review Schedule](#15-version-control--review-schedule)

---

## 1. Purpose & How to Use This Document

This document defines how **[LEGAL ENTITY NAME]** ("we," "us," the "Company") operates user support for **NguyenInDoubt** and how support staff must respond when a user signals a mental-health crisis or self-harm, or when a support contact reveals a security or privacy incident.

**NguyenInDoubt** is a Flutter (web + iOS/Android) mental-health **companion** app. It is **not** a diagnostic tool, not a treatment tool, not a medical device, and **not an emergency service**. Its core privacy promise is:

- **Patients** get a **private journal** plus **sleep tracking** (sleep samples and daily summaries imported from Apple HealthKit / Google Health Connect).
- **Clinicians** — only after a patient generates an invite and the clinician accepts a consent link — see **only consented sleep summaries** and **never** journal content.

This process must be read alongside its sibling documents:

- Privacy Policy — [`./privacy_policy.md`](./privacy_policy.md)
- Terms of Service / EULA — [`./terms_of_service.md`](./terms_of_service.md)
- HIPAA / Business-Associate Analysis — [`./hipaa_baa_analysis.md`](./hipaa_baa_analysis.md)
- Incident Response Plan — [`./incident_response_plan.md`](./incident_response_plan.md)

> **Current product state (affects scope of this process).** The public demo is **device-local only** (in-memory / local storage, no cross-device sync). Firebase Auth/Firestore and Firestore security rules exist as the production backend **boundary**, but **live production storage is not yet enabled** (compliance-gated). There is **no analytics, telemetry, or Crashlytics**. As a result, most account-recovery, data-export, and cross-device support obligations only fully activate when compliance-gated production storage goes live. Where an obligation depends on a go-live decision, it is flagged with **[GO-LIVE CONDITION]**.

---

## 2. Support Overview, Scope & Boundaries

### 2.1 What support does

- Answer questions about how to use the app (journaling, sleep import, generating and revoking clinician invite/consent links).
- Help with account and sign-in issues **[GO-LIVE CONDITION: full account recovery depends on Firebase Auth production being enabled]**.
- Triage and route bug reports, HealthKit / Health Connect import problems, and general feedback.
- Route privacy and data-subject-rights requests to **[PRIVACY CONTACT EMAIL]** (see §11).
- Detect and hand off suspected security/privacy incidents to the Incident Response team (see §10).
- Signpost crisis resources (988 / 911) when a user indicates distress or self-harm (see §7).

### 2.2 What support does NOT do — hard boundaries

These boundaries must be stated **in-app, in the Terms of Service, and in every support auto-reply**, and must be repeated at each relevant touchpoint:

- **We do not monitor accounts, journals, sleep data, or any user activity for signs of crisis, self-harm, or emergency.** The app is passive by design.
- **We are not an emergency service and cannot respond to emergencies.** We cannot dispatch help, send a welfare check, contact emergency services on a user's behalf, or provide real-time or 24/7 monitoring.
- **We do not provide medical, clinical, diagnostic, or treatment advice.** Support staff are not clinicians and must not attempt clinical triage, assessment, or intervention.
- **We do not read journal content, and support staff cannot access patient journal entries** to "help" — journal content is private to the patient by design and is never exposed to clinicians or to Company staff through the product boundary.
- **We do not relay messages between patients and clinicians.** There is **no patient-to-clinician messaging** in this MVP; support cannot pass a message, alert, or crisis signal to a clinician.

Every user-facing crisis-adjacent surface must direct users to **call or text 988** (Suicide & Crisis Lifeline) or **call 911** for a life-threatening emergency.

---

## 3. Contact Channels & Hours

| Channel | Address / Location | Intended use | Monitoring |
|---|---|---|---|
| In-app Help / Support form | In-app "Help & Support" screen | General questions, bug reports, feedback | Asynchronous, business hours only |
| Support email | **[SUPPORT EMAIL]** | General and technical support | Asynchronous, business hours only |
| Privacy / data-rights email | **[PRIVACY CONTACT EMAIL]** | Privacy questions, data-subject-rights requests, DPO contact | Asynchronous, business hours only |
| Postal mail | **[POSTAL ADDRESS]** | Formal / legal notices | As received |

- **Support hours:** [SUPPORT HOURS, e.g., Monday–Friday, 9:00–17:00 [TIME ZONE], excluding public holidays].
- **No real-time or 24/7 monitoring.** Messages are handled asynchronously during support hours only.
- Every channel must carry a standing **crisis banner / auto-reply**: *"NguyenInDoubt does not monitor accounts and cannot respond to emergencies. If you or someone else is in crisis, call or text 988 (Suicide & Crisis Lifeline) or call 911 for a life-threatening emergency."*

---

## 4. Support Tiers & SLAs

> SLA targets below are **business-hours** targets (see §3) and are **first-response** targets unless stated otherwise. They are **not guarantees** and are subject to the Terms of Service. Confirm final numbers with operations and counsel before publishing any externally.

### 4.1 Tiers

- **Tier 1 — General support.** Front line. Usage questions, how-to, basic troubleshooting, initial triage and routing. Follows scripts in this document, including the crisis-content script (§7). Escalates anything outside script to Tier 2 or the correct queue.
- **Tier 2 — Technical & privacy.** App bugs, HealthKit / Health Connect import failures, account/auth issues **[GO-LIVE CONDITION]**, consent-link problems, and privacy / data-subject-rights intake for routing to **[PRIVACY CONTACT EMAIL]**.
- **Tier 3 — Engineering / Legal / Incident escalation.** Engineering for reproducible defects and backend issues; Privacy/Legal (**[DPO NAME]** / counsel) for rights requests and legal questions; and the **Incident Response team** for any suspected security or privacy incident (see §10 and [`./incident_response_plan.md`](./incident_response_plan.md)).

### 4.2 SLA targets by priority

| Priority | Definition | First-response target | Resolution / update target |
|---|---|---|---|
| **P1 — Critical** | Suspected security/privacy incident (e.g., a user reports seeing another user's data), widespread outage, or safety-adjacent report | Immediate escalation to Tier 3 / IR; acknowledge to user within **[e.g., 4 business hours]** | Managed under [`./incident_response_plan.md`](./incident_response_plan.md); user updates per IR comms plan |
| **P2 — High** | Blocking bug, failed sleep import affecting core use, cannot revoke a clinician consent link, account lockout **[GO-LIVE CONDITION]** | **[e.g., 1 business day]** | **[e.g., 3–5 business days]** |
| **P3 — Normal** | Non-blocking bug, general how-to, feature question | **[e.g., 2 business days]** | **[e.g., 5–10 business days]** |
| **P4 — Low** | Feature request, general feedback | **[e.g., 3 business days]** | Best effort |
| **Data-rights** | Access, deletion, correction, portability requests | Acknowledge within **[e.g., 5 calendar days]**; route to **[PRIVACY CONTACT EMAIL]** | Fulfilled within statutory deadline (see [`./privacy_policy.md`](./privacy_policy.md)) — **confirm applicable deadline with counsel** |

> **Crisis signals are not an SLA priority tier.** A crisis disclosure is handled by the **crisis-content protocol (§7)** on a **same-interaction / immediate** basis regardless of ticket priority. Support does **not** treat a crisis signal as a routine ticket to be queued.

---

## 5. Support Triage Flow

Every inbound contact follows this flow. **Step 2 (safety check) runs first and overrides queueing** — if there is any indication of self-harm or danger, jump immediately to §7 before doing anything else with the ticket.

```
1. INTAKE
   Capture: channel, user identifier (if provided), summary, timestamp.

2. SAFETY / CRISIS SCREEN  ← runs before categorization
   Does the message indicate self-harm, suicidality, intent to harm others,
   abuse, or an in-progress emergency?
        YES → Go to §7 (Crisis Content Staff Protocol) IMMEDIATELY.
              Do not queue as a normal ticket. Do not delay.
        NO  → continue.

3. SECURITY / PRIVACY SCREEN
   Does the message suggest cross-user data exposure, someone seeing data
   they should not (e.g., "I can see another person's journal / sleep data"),
   a clinician seeing journal content, account takeover, or a leak?
        YES → Treat as P1. Hand off to Incident Response (§10).
        NO  → continue.

4. CATEGORIZE
        a. Account / sign-in            → Tier 1, escalate to Tier 2 if unresolved [GO-LIVE CONDITION]
        b. Data-subject-rights / privacy → route to [PRIVACY CONTACT EMAIL] (§11)
        c. Bug / technical / import      → Tier 2 (engineering hand-off if reproducible)
        d. Consent / clinician invite    → Tier 2 (verify user is the patient/owner)
        e. Billing / subscription        → [BILLING QUEUE / N/A if no paid tier]
        f. General / feedback            → Tier 1

5. RESOLVE or ESCALATE per SLA (§4). Document outcome.

6. INCIDENT CHECK-BACK
   If, at any point, a ticket reveals a security/privacy incident,
   stop and hand off to IR (§10). The notification clock may already be running.
```

---

## 6. Mental-Health Crisis Escalation Protocol (In-App)

This section describes how the **app itself** (not staff) handles crisis. The design is deliberately **passive, always-available signposting** — never monitoring, detection, or dispatch.

### 6.1 Design principles

- **Passive, not monitoring.** The app never analyzes journal text, sleep data, or behavior to infer crisis or self-harm risk. It does not score, flag, or alert on user content. There is no automated risk detection.
- **Always-available resources.** A **crisis resources screen** is reachable at all times (e.g., a persistent, easily discoverable entry point) presenting:
  - **988 Suicide & Crisis Lifeline** — **call or text 988** (available 24/7 in the US).
  - **911** — for a life-threatening emergency or imminent physical-safety threat.
  - Brief, plain-language framing that these are the appropriate channels and that NguyenInDoubt is not one.
- **Clear boundary language, repeated.** The crisis screen and Terms both state that NguyenInDoubt **does not monitor accounts and cannot respond to emergencies**, and direct users to 988 / 911.
- **US focus, with guidance for others.** Crisis routing is US-focused (988 / 911). Provide guidance for out-of-US users to contact their **local emergency number** and local crisis services, since 988 is US-specific. **[Confirm out-of-US wording with counsel; see §9.]**
- **No dispatch, no contact on the user's behalf.** The app never contacts emergency services, a clinician, or a third party based on user content. Tapping **call 988** / **call 911** uses the device's native dialer at the **user's** initiation.

### 6.2 What the app does NOT do (state in-app)

- Does not diagnose, treat, or provide clinical advice.
- Does not monitor for emergencies or perform welfare checks.
- Does not send crisis signals to clinicians (there is **no patient-to-clinician messaging** in the MVP; the clinician relationship carries **only consented sleep summaries**).
- Does not guarantee that any human will see anything the user writes.

### 6.3 The only crisis surfaces

The only crisis pathways in this MVP are (a) the **in-app 988 / 911 resources screen**, and (b) rarely, a **support ticket** in which a user discloses distress — handled by staff under §7. The clinician relationship is **not** a crisis channel.

---

## 7. Crisis Content Seen via Support — Staff Protocol

Human agents will occasionally see self-harm or suicidality disclosed in a support message. The goal is a **scripted, boundaried** response that avoids both **under-response** (ignoring the person) and **over-response** (acting as an unlicensed crisis service or contacting authorities without basis), while protecting the agent.

### 7.1 Do

1. **Acknowledge with empathy** (do not ignore, minimize, or interrogate). Use the approved script (§7.3).
2. **Surface crisis resources immediately:** direct the user to **call or text 988** and to **call 911** if there is a life-threatening emergency; for out-of-US users, direct them to their **local emergency number** and local crisis services.
3. **Restate the boundary:** remind the user, gently, that NguyenInDoubt does not monitor and cannot respond to emergencies, so 988 / 911 is the right place to reach real-time help.
4. **Document** the interaction factually in the ticketing system: what was said, resources provided, timestamp. Do **not** copy or store more sensitive detail than necessary, and do **not** move the content into non-secure systems.
5. **Escalate internally** to **[SUPPORT LEAD / DESIGNATED CRISIS-PROTOCOL OWNER]** per the notification path in §7.4 (for awareness, quality, and staff support — **not** to trigger any intervention).
6. **Attend to your own wellbeing** afterward (see §12).

### 7.2 Do NOT

- Do **not** attempt clinical triage, risk assessment, diagnosis, counseling, or treatment.
- Do **not** promise to monitor the user, "check on" them, or follow up as if providing care.
- Do **not** contact emergency services, police, a clinician, or a family member **on the user's behalf** as a matter of routine — the app has no basis, no location data, and no mandate to do so, and doing so can breach privacy and create a duty the Company cannot sustain. **[Any narrow exception must be defined and approved by counsel — see §7.5; default is no third-party contact.]**
- Do **not** access or read the user's journal to "understand" the situation. Journal content is private by design and is not a support tool.
- Do **not** leave the disclosure unanswered.

### 7.3 Approved agent script (adapt with counsel)

> "Thank you for reaching out, and I'm sorry you're going through this. I want to make sure you get real support right now. NguyenInDoubt isn't able to monitor accounts or respond to emergencies, so please reach the people who can help 24/7: in the US you can **call or text 988** (the Suicide & Crisis Lifeline), and if you or someone else is in immediate danger please **call 911**. If you're outside the US, please contact your local emergency number and local crisis line. You matter, and trained counselors are available to talk with you right now."

- If the user indicates an **emergency in progress** (imminent danger), reinforce **911** (or local emergency number) as the immediate step.
- Keep the message calm, brief, non-judgmental, and free of clinical claims or promises of follow-up care.

### 7.4 Internal notification path

Agent → **[SUPPORT LEAD / CRISIS-PROTOCOL OWNER]** (for awareness and QA) → **[PRIVACY/LEGAL — DPO NAME]** if the disclosure also raises a legal or privacy question. This internal escalation is for **oversight and staff support only** and must **not** be used to initiate any intervention against the user.

### 7.5 Legal note on third-party contact and mandatory reporting

Whether any situation ever warrants Company-initiated third-party contact (or triggers any mandatory-reporting obligation) is **jurisdiction-dependent** ([JURISDICTION]) and must be resolved by **[LEGAL ENTITY NAME]** counsel **before launch**. Until counsel defines an explicit, narrow, approved exception, the **default rule is: no Company-initiated contact with third parties or authorities**; staff signpost 988 / 911 and document only.

---

## 8. Duty of Care, Disclaimers & Liability Positioning

- **Positioning.** NguyenInDoubt is a **general-wellness companion**, consistent with FDA "general wellness" positioning for low-risk products that do **not** claim to diagnose, treat, cure, or monitor for medical conditions or emergencies. Marketing, in-app copy, and support language must **not** claim monitoring, emergency response, diagnosis, or treatment.
- **Avoid creating a special relationship / duty of care.** Repeated, clear "we do not monitor and cannot respond to emergencies" statements — in-app, in the Terms, and in support auto-replies — help set correct expectations and reduce the risk of an implied special relationship or duty the Company cannot meet. This mirrors SAMHSA's 2026 guidance emphasizing clear roles and boundaries between support resources and 988 / 911.
- **Terms / EULA linkage.** The boundaries in §2.2, §6, and §7 must be reflected in and consistent with [`./terms_of_service.md`](./terms_of_service.md) and [`./privacy_policy.md`](./privacy_policy.md). Informed-consent and disclaimer language there governs; this process operationalizes it.
- **Governing law.** Duty-of-care and liability analysis depends on **[JURISDICTION]** / governing law; all disclaimer and duty-of-care wording must be reviewed by counsel for that jurisdiction.

---

## 9. Crisis Resource Accuracy & Maintenance

Research and SAMHSA guidance warn that many apps surface **broken or wrong** hotlines. Accuracy is a safety obligation.

- **Verify the resources work.** On a **[REVIEW CADENCE, e.g., quarterly]** basis, confirm that **988** (call and text) and **911** references are correct and current, and that any in-app links/dialer actions function on both iOS and Android and on web.
- **Owner.** **[CRISIS-RESOURCE OWNER / ROLE]** owns this review and records each check (date, result) in the changelog (§15).
- **US focus + out-of-US guidance.** Keep the US-focused 988 / 911 framing, and maintain the out-of-US guidance (local emergency number / local crisis services). **[Confirm the exact out-of-US wording and any additional regional resources with counsel.]**
- **No broken hotlines.** Any resource found broken, changed, or deprecated is fixed on a **[URGENT SLA, e.g., within 2 business days]** basis and treated as a P1/P2 for engineering.
- **Change control.** Any change to crisis wording or resources requires review by **[SUPPORT LEAD]** and, for boundary/disclaimer language, **counsel**.

---

## 10. Interaction Between Support & Incident Response

Frontline support is often the **first detector** of a security or privacy incident. A defined trigger and hand-off ensures the breach-notification clock and forensic preservation start on time.

**Immediate IR hand-off triggers (treat as P1):**

- A user reports **seeing another user's data** — especially **another user's journal content** (the single most damaging scenario, and an automatic top-severity event because it breaks the core privacy promise).
- A **clinician reports seeing journal content** or any data beyond consented sleep summaries (a Firestore-rules boundary failure).
- Reports of **cross-patient data leakage**, account takeover, or exposed consent records / tampered consent history.
- Any credible report suggesting the **Firestore security-rules boundary** (which limits clinicians to consented sleep summaries and never journal content) was bypassed or misconfigured **[GO-LIVE CONDITION]**.

**Hand-off procedure:**

1. Do **not** attempt to "fix" or investigate beyond confirming the report. Preserve the message and metadata intact.
2. Escalate immediately to the **Incident Response team / Incident Commander** per [`./incident_response_plan.md`](./incident_response_plan.md).
3. Do **not** send further substantive communication to the reporter beyond an acknowledgment until IR/Legal approves messaging (see the IR communications plan).
4. Note the exact discovery time — the **notification clock may already be running** under HIPAA / FTC HBNR / GDPR / state law depending on applicability (see [`./incident_response_plan.md`](./incident_response_plan.md) and [`./hipaa_baa_analysis.md`](./hipaa_baa_analysis.md)).

---

## 11. Privacy & Data-Subject-Rights Requests via Support

- Requests to **access, delete, correct, or export** personal data — and requests to **revoke clinician consent** — are routed to **[PRIVACY CONTACT EMAIL]** and handled per [`./privacy_policy.md`](./privacy_policy.md).
- **Verify the requester** is the account owner (patient) before acting, consistent with the privacy policy's verification standard. Clinicians are **not** owners of patient data and cannot exercise patient rights.
- **Consent revocation** must be actionable: a patient can revoke a clinician's access, and support must know how to confirm revocation took effect (and escalate to Tier 2/engineering if it did not — potential P2, or P1 if it indicates a boundary failure).
- **Retention:** data and support records are retained per **[RETENTION PERIOD]** (confirm with counsel; see [`./privacy_policy.md`](./privacy_policy.md)).
- Applicable rights and statutory response deadlines depend on **[JURISDICTION]**, whether **GDPR/UK GDPR** applies (EU/UK users), and applicable US state privacy laws — **confirm with counsel**.

---

## 12. Staff Wellbeing & Training

- **Training.** All support agents complete crisis-content training (this §7 script, boundaries, and the "do not / do" lists) and privacy/incident-handoff training **before** handling live tickets, refreshed **[ANNUALLY / CADENCE]**.
- **Staff support.** Handling self-harm disclosures is distressing. Agents may debrief with **[SUPPORT LEAD]** after any crisis-content interaction and may access **[EAP / WELLBEING RESOURCE, if any]**. No agent is expected to act as a counselor.
- **No lone heroics.** Agents follow the script and escalate for awareness; they are not responsible for a user's outcome and must not shoulder that as if they were.

---

## 13. Definitions & Acronyms

- **988** — US Suicide & Crisis Lifeline (call / text / chat), 24/7, for emotional/behavioral crises.
- **911** — US emergency number, for imminent physical-safety threats / life-threatening emergencies.
- **Patient** — the data owner; owns the journal and sleep data.
- **Clinician** — a consented, sleep-summary-only viewer (typically a licensed provider and a potential HIPAA covered entity).
- **PHI** — Protected Health Information (HIPAA).
- **PHR** — Personal Health Record (relevant to the FTC Health Breach Notification Rule).
- **PII** — Personally Identifiable Information.
- **HBNR** — FTC Health Breach Notification Rule.
- **OCR** — HHS Office for Civil Rights (HIPAA enforcement).
- **DPA** — Data Protection Authority (GDPR supervisory authority).
- **DPO** — Data Protection Officer.
- **SLA** — Service-Level Agreement (target, not guarantee).
- **IR** — Incident Response (see [`./incident_response_plan.md`](./incident_response_plan.md)).
- **SEV1–SEV4** — incident severity levels defined in the Incident Response Plan.

---

## 14. Open Items / To Finalize Before Launch

- [ ] Replace all placeholders: **[LEGAL ENTITY NAME]**, **[JURISDICTION]**, **[PRIVACY CONTACT EMAIL]**, **[SUPPORT EMAIL]**, **[POSTAL ADDRESS]**, **[DPO NAME]**, **[RETENTION PERIOD]**, **[EFFECTIVE DATE]**, **[DATE]**, **[SUPPORT HOURS / TIME ZONE]**, **[REVIEW CADENCE]**, **[CRISIS-RESOURCE OWNER / ROLE]**, **[SUPPORT LEAD / CRISIS-PROTOCOL OWNER]**, **[BILLING QUEUE / N/A]**, **[EAP / WELLBEING RESOURCE]**.
- [ ] **Counsel review** of all crisis, disclaimer, duty-of-care, and boundary language (§2.2, §6, §7, §8) for **[JURISDICTION]**.
- [ ] Confirm final **SLA numbers** (§4) with operations and counsel before publishing any externally.
- [ ] Resolve the **third-party contact / mandatory-reporting** question (§7.5) with counsel; define any narrow exception or confirm the default "no third-party contact" rule.
- [ ] Confirm **out-of-US crisis guidance** wording (§6, §9) and whether any non-US regional resources are needed.
- [ ] Confirm **data-subject-rights deadlines** and applicable regimes (GDPR/UK GDPR, US state laws) with counsel (§11).
- [ ] Verify **988 (call/text) and 911** links/dialer actions work on iOS, Android, and web before launch (§9).
- [ ] Ensure the **crisis boundary auto-reply** is configured on every channel (§3).
- [ ] Confirm alignment with [`./terms_of_service.md`](./terms_of_service.md) and [`./privacy_policy.md`](./privacy_policy.md) so disclaimers match.
- [ ] **[GO-LIVE CONDITION]** items — account recovery, cross-device support, Firestore-rules incident triggers — are validated when compliance-gated Firebase/Firestore production storage is enabled, and this process is finalized as a **go-live gate**.
- [ ] Confirm the **Incident Response Plan** ([`./incident_response_plan.md`](./incident_response_plan.md)) is finalized and the hand-off contacts (§10) are live.

---

## 15. Version Control & Review Schedule

- **Document owner:** [SUPPORT LEAD / CRISIS-PROTOCOL OWNER]
- **Approvers:** [LEGAL ENTITY NAME] counsel; [DPO NAME]; [ENGINEERING LEAD]
- **Review cadence:** at least **[ANNUALLY]**, and on any trigger — change to crisis resources (988/911), a relevant incident, a product change (e.g., enabling production storage, adding messaging), or a legal/regulatory change.
- **Effective date:** [EFFECTIVE DATE] — **not yet in effect while Status = DRAFT.**

| Version | Date | Author | Summary of changes |
|---|---|---|---|
| 0.1 (DRAFT) | [DATE] | [AUTHOR] | Initial draft template — pending counsel review |
