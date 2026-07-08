# NguyenInDoubt — Terms of Service

> ⚠️ **DRAFT TEMPLATE — NOT YET IN EFFECT.**
> This document is a **DRAFT TEMPLATE** prepared for the NguyenInDoubt application. It **MUST be reviewed, edited, and approved by qualified legal counsel licensed in [JURISDICTION]** before it is published or relied upon in production. It is **provided for drafting purposes only and does not constitute legal advice.** Every bracketed placeholder must be resolved before publication.
>
> **Last updated:** [DATE]
> **Effective date:** [EFFECTIVE DATE]
> **Status:** DRAFT — not yet in effect

---

## Preliminary Notice — Please Read First

**NguyenInDoubt is a general-wellness and self-reflection companion. It is NOT a medical device, and it does NOT provide medical advice, diagnosis, treatment, cure, prevention, or monitoring of any condition.**

**NguyenInDoubt is NOT for emergencies and is NOT monitored in real time.** No person — including any clinician you invite — watches your entries or is alerted by the app. **If you are in crisis or thinking about harming yourself, call or text 988 (the U.S. Suicide & Crisis Lifeline), or call 911, or go to your nearest emergency room.** See Section 6.

These Terms include a **binding arbitration agreement and a class-action waiver** (Section 21) that affect how disputes are resolved. You may **opt out of arbitration within 30 days** as described in that section.

---

## 1. Acceptance of Terms & Binding Agreement

These Terms of Service ("**Terms**") form a legally binding agreement between you ("**you**," "**your**," or "**User**") and **[LEGAL ENTITY NAME]** ("**Company**," "**we**," "**us**," or "**our**"), the provider of the NguyenInDoubt application and related websites, software, and features (collectively, the "**Services**").

By creating an account, accepting a clinician invite/consent link, clicking "I agree," or otherwise accessing or using the Services, you acknowledge that you have read, understood, and agree to be bound by these Terms and by our **[Privacy Policy](./privacy_policy.md)**, which is incorporated by reference. The consent flow used to share sleep summaries with a clinician (described in Sections 8–9) is likewise incorporated by reference. If you do not agree, do not access or use the Services.

If you are accepting these Terms on behalf of an organization or another person, you represent that you have authority to bind that party.

## 2. Definitions

- **Patient** — a User who owns an account, creates Journal Content, and controls the sharing of their Sleep Summaries. The Patient is the data owner.
- **Clinician** (also "**Care Provider Viewer**") — a User who accepts a Patient's Consent Link and is thereby granted view-only access to that Patient's consented Sleep Summaries. A Clinician is typically a licensed care provider.
- **Journal Content** — private journal entries, reflections, notes, and other free-form inputs a Patient creates in the app.
- **Sleep Data** — sleep samples and sleep-stage records imported from Apple HealthKit or Google Health Connect.
- **Sleep Summaries** — the daily, aggregated summaries of Sleep Data that a Patient may elect to share with a Clinician. Sleep Summaries **never** include Journal Content.
- **Consent Link** — the invite/consent link a Patient uses to grant a specific Clinician access to consented Sleep Summaries, together with the associated consent record.
- **Consent History** — the auditable record of consent grants, scope, timestamps, and revocations.
- **Device-Local Mode** — the current public demo posture in which data is stored only on your device (in-memory / local storage), with no cross-device sync and no server-side retention.
- **Production Backend** — the compliance-gated Firebase Authentication / Cloud Firestore infrastructure that forms the boundary for a future production release; live cloud storage of your data is **not yet enabled**.
- **Services** — the NguyenInDoubt app (web, iOS, and Android), websites, and related features.

## 3. Eligibility & Age

The Services are intended for **users who are 18 years of age or older** (or the age of majority in your place of residence, if higher). By using the Services, you represent that you meet this requirement. We do not knowingly collect information from anyone under 18. If we learn that we have collected data from a minor, we will delete it as described in the **[Privacy Policy](./privacy_policy.md)**. The Services are designed for and directed to users **located in the United States**.

*(If the Company ever elects to permit minors, this section must be revised to add verifiable parental consent and COPPA-compliant handling before any such use is enabled.)*

## 4. Description of the Service & Nature of the App

NguyenInDoubt is a **general-wellness and self-reflection companion** that lets a Patient keep a **private journal** and view their own **sleep information** imported from Apple HealthKit or Google Health Connect. A Patient may optionally share **only** consented Sleep Summaries with a Clinician they invite.

**NguyenInDoubt is NOT, and does not provide:**

- diagnosis, treatment, cure, prevention, or mitigation of any disease, disorder, or condition;
- medical, clinical, psychological, or professional advice;
- emergency services, real-time monitoring, or crisis intervention;
- patient-to-clinician messaging or any means of contacting a Clinician through the app in this MVP; or
- a medical record, an electronic health record, or a substitute for professional care.

The app is a supplemental wellness tool. Always seek the advice of a qualified health provider with any questions about a medical or mental-health condition.

## 5. NOT MEDICAL ADVICE / NOT A MEDICAL DEVICE

> **NguyenInDoubt is a general-wellness product, not a medical device. It does not diagnose, treat, cure, prevent, monitor, or mitigate any disease or health condition, and it is not intended to be relied upon for any medical or clinical decision.**

The content, features, sleep information, and summaries provided through the Services are for **general informational and self-reflection purposes only** and are **not a substitute for professional medical or mental-health advice, diagnosis, or treatment.** Never disregard professional advice or delay seeking it because of anything you saw or entered in the app. Reliance on any information provided by the Services is solely at your own risk. This disclaimer is also presented within the app (for example, at onboarding and on a persistent information screen).

## 6. Emergency & Crisis Disclaimer / No-Monitoring Notice

> **NguyenInDoubt is NOT an emergency service and is NOT monitored in real time.**

**No person — including any Clinician you invite — reviews your Journal Content or Sleep Data in real time, is notified of anything you enter, or is on standby to respond.** The app does not detect, monitor, or respond to emergencies, and it will not alert anyone on your behalf.

**If you are experiencing a medical or mental-health emergency, or are thinking about harming yourself or others:**

- **Call or text 988** — the U.S. Suicide & Crisis Lifeline (available 24/7).
- **Call 911** or go to your nearest emergency room.

The Services are intended for users located in the United States, and the crisis resources referenced above are U.S. resources. NguyenInDoubt provides no diagnosis, treatment, emergency monitoring, or patient-to-clinician messaging in this MVP. Nothing in the Services creates any duty on the part of the Company or any Clinician to monitor, respond to, or intervene in any situation.

## 7. Account Registration, Security & Accurate Information

To use most features you must register an account and provide accurate, current information. You are responsible for maintaining the confidentiality of your credentials and for all activity under your account. Use **one account per person**. Notify us promptly at **[SUPPORT EMAIL]** of any unauthorized use. To import Sleep Data, you must grant the app the necessary Apple HealthKit or Google Health Connect authorizations at the operating-system level; you may revoke these authorizations at any time through your device settings.

## 8. User Roles & the Clinician-Link / Consent Model

**The Patient is the data owner.** A Clinician sees **nothing** until the Patient creates and the Clinician accepts a **Consent Link**.

- Acceptance of a Consent Link grants the Clinician **view-only access to the Patient's consented Sleep Summaries and nothing else.**
- **A Clinician never has access to Journal Content**, raw device data beyond the consented summaries, or any other Patient data.
- Consent is **revocable and self-serve.** A Patient may revoke a Consent Link at any time, which stops future sharing. The effect of revocation on previously shared summaries is described in the consent flow and the **[Privacy Policy](./privacy_policy.md)**; [confirm exact behavior — e.g., whether cached summaries persist on the Clinician side — before launch].
- Consent grants, scope, timestamps, and revocations are recorded in the **Consent History** as an audit record.

The invite/consent lifecycle, the separation between consent to **collect** health data and the separate, distinct consent to **share** Sleep Summaries, and the retention of the Consent History are further described in the **[Privacy Policy](./privacy_policy.md)** and the in-app consent flow, which are incorporated by reference.

## 9. Clinician Terms & Acknowledgments

**This Section applies to Clinicians and is accepted when a Clinician accepts a Consent Link.** By accepting, the Clinician acknowledges and agrees that:

1. **Supplemental wellness data only.** The Clinician receives only consented **Sleep Summaries**, which are supplemental, self-reported/device-sourced wellness information — **not a medical record, not clinically validated, and not a substitute for a clinical assessment.**
2. **No reliance for clinical decisions.** The Clinician will not rely on Sleep Summaries as the basis for any diagnosis, treatment, or other clinical decision.
3. **Sole professional responsibility.** The Clinician remains solely responsible for their own professional licensure, standards of care, and legal and regulatory obligations, **including any obligations under HIPAA** and applicable state law that may apply to them as a covered entity or otherwise.
4. **No Business Associate relationship.** The Company is **not** the Clinician's Business Associate, is not acting on the Clinician's behalf, does not create or maintain the Clinician's records, and no Business Associate Agreement arises from use of the Services. See **[HIPAA / BAA analysis](./hipaa_baa_analysis.md)**.
5. **No practice of medicine or supervision of care.** The Company does not practice medicine, provide clinical services, or supervise, direct, or participate in the care the Clinician provides.
6. **Permitted use.** The Clinician will use Sleep Summaries only for the Patient's benefit consistent with the Patient's consent, will not attempt to access Journal Content or any non-consented data, and will not misuse, redistribute, or repurpose the summaries.

## 10. User-Generated Content — Journal & Inputs: Ownership, License & Responsibility

**You retain full ownership of your Journal Content and all inputs you create.** We claim no ownership over it.

You grant the Company only a **limited, non-exclusive, royalty-free license to store, back up, process, and display your Journal Content back to you** for the sole purpose of operating and providing the Services to you. This license is strictly limited to that purpose.

**We do not, and this license does not permit us to:**

- read your Journal Content for advertising or marketing;
- sell, rent, or share your Journal Content;
- use your Journal Content to train, develop, or improve any artificial-intelligence or machine-learning model; or
- disclose your Journal Content to any Clinician or other third party.

**Journal Content is never shown to any Clinician.** You are responsible for the content you create and for ensuring you have the right to input any information you provide.

## 11. Acceptable Use / Prohibited Conduct

You agree not to:

- reverse engineer, decompile, or attempt to derive source code from the Services, except as permitted by law;
- misuse a Consent Link or Clinician access, or attempt to access data you are not consented to view;
- upload another person's data or impersonate anyone;
- use the Services for any unlawful, harmful, or fraudulent purpose;
- scrape, harvest, or use automated means to access the Services;
- interfere with, disrupt, or compromise the security or integrity of the Services; or
- circumvent role separation between Patient and Clinician access.

## 12. Third-Party Services & Platform Terms

The Services interoperate with third-party platforms, including **Apple HealthKit**, **Google Health Connect**, and, in the future Production Backend, **Google Firebase / Google Cloud Platform** acting as a data processor. Your use of those platforms is governed by their own terms and privacy policies, and we are not responsible for their practices.

**Apple.** If you download the app from the Apple App Store, the **Apple Licensed Application End User License Agreement** (or a custom EULA meeting Apple's minimum terms) applies, and **Apple and its subsidiaries are third-party beneficiaries of these Terms** with the right to enforce them. You represent that you are not located in a U.S.-embargoed country or on a U.S. prohibited-parties list.

**Google.** If you download the app from Google Play, applicable Google Play terms apply. The app's store description includes the required "not a medical device" disclaimer in its first paragraph.

## 13. Intellectual Property & License to Use the App

The Services, including all software, design, text, and trademarks (other than your Journal Content), are owned by the Company or its licensors and are protected by intellectual-property laws. Subject to these Terms, we grant you a **limited, revocable, non-exclusive, non-transferable, non-sublicensable license** to install and use the app for your personal, non-commercial use. All rights not expressly granted are reserved. "NguyenInDoubt" and associated logos are trademarks of the Company; you may not use them without permission.

## 14. Privacy, Data Handling & Cross-Reference to Privacy Policy

Our collection and use of your data is described in the **[Privacy Policy](./privacy_policy.md)**, incorporated by reference.

**Current posture (honest disclosure).** The public demo currently operates in **Device-Local Mode**: your data is stored **only on your device**, with **no cross-device sync**, **no server-side retention**, and **no analytics, telemetry, or crash reporting** (e.g., no Crashlytics). The Firebase Authentication / Cloud Firestore **Production Backend and its security rules exist as a boundary** for a future release, but **live cloud storage of your data is compliance-gated and not yet enabled.** We do not promise server-side protections that are not yet live. Before enabling cloud sync or any new server-side processing of your data, we will provide notice and, where required, obtain fresh consent. The **[Firebase/GCP region] is [FIREBASE/GCP REGION]** once production is enabled.

## 15. Disclaimer of Warranties

> **THE SERVICES ARE PROVIDED "AS IS" AND "AS AVAILABLE," WITHOUT WARRANTIES OF ANY KIND**, whether express, implied, or statutory, including any implied warranties of merchantability, fitness for a particular purpose, title, and non-infringement.

We do not warrant that the Services will be uninterrupted, timely, secure, or error-free, and we provide **no uptime guarantee**. In particular, **we do not warrant the accuracy, completeness, or reliability of Sleep Data or Sleep Summaries imported from Apple HealthKit or Google Health Connect.** That data originates from device sensors and third-party sources we do not control, and it should not be relied upon for any medical purpose. **The app does not write inaccurate data back to HealthKit or Health Connect.** Some jurisdictions do not allow the exclusion of certain warranties, so some of the above may not apply to you.

## 16. Limitation of Liability

> **TO THE MAXIMUM EXTENT PERMITTED BY LAW**, the Company and its officers, employees, and agents will **not be liable for any indirect, incidental, special, consequential, exemplary, or punitive damages**, or for any loss of data, profits, or goodwill, arising out of or relating to your use of (or inability to use) the Services, **even if advised of the possibility of such damages.**

Given the wellness (non-clinical) nature of the Services, you acknowledge that you assume responsibility for your own health decisions and that the Company is not responsible for any health outcome. **The Company's total aggregate liability** for all claims relating to the Services will not exceed the greater of **the amount you paid us for the Services in the twelve (12) months before the claim, or [USD 100 / other cap — confirm with counsel].**

Nothing in these Terms limits liability that cannot be limited under applicable law (for example, for gross negligence, willful misconduct, or personal injury where the law forbids such limitation). Some jurisdictions do not allow certain limitations, so parts of this section may not apply to you.

## 17. Indemnification

You agree to indemnify, defend, and hold harmless the Company and its affiliates from any claims, damages, losses, and expenses (including reasonable attorneys' fees) arising out of or related to: (a) your misuse of the Services; (b) a Clinician's misuse of Sleep Summaries or access; (c) content or data you upload or input; (d) your violation of these Terms or of any law; or (e) your violation of any third-party right.

## 18. Termination & Suspension

You may stop using the Services and delete your account at any time. We may suspend or terminate your access, with or without notice, if you violate these Terms or if we discontinue the Services. On termination: (a) your license to use the app ends; (b) applicable Consent Links terminate and future sharing stops; and (c) data export and deletion are handled as described in the **[Privacy Policy](./privacy_policy.md)**. Provisions that by their nature should survive termination (including Sections 5, 6, 9, 10, 15, 16, 17, 20, 21, and 22) will survive.

## 19. Changes to the Terms & to the Service

We may update these Terms or modify, suspend, or discontinue any part of the Services. For **material changes**, we will provide reasonable notice (for example, in-app or by email) before they take effect. Your continued use of the Services after changes become effective constitutes acceptance. If you do not agree, stop using the Services. Where a change introduces new sensitive-data processing, we will seek any consent required by the **[Privacy Policy](./privacy_policy.md)**.

## 20. Governing Law & Jurisdiction

These Terms are governed by the laws of **[JURISDICTION]**, without regard to its conflict-of-laws rules. Subject to the arbitration agreement in Section 21, the state and federal courts located in **[JURISDICTION]** will have exclusive jurisdiction over any dispute not subject to arbitration.

## 21. Dispute Resolution — Arbitration & Class-Action Waiver

**PLEASE READ THIS SECTION CAREFULLY. IT AFFECTS YOUR LEGAL RIGHTS.**

**Informal resolution first.** Before starting arbitration, you and the Company agree to try to resolve any dispute informally by contacting **[SUPPORT EMAIL]** and allowing **at least 30 days** to reach a resolution.

**Binding arbitration.** If the dispute is not resolved, it will be resolved by **final and binding arbitration** administered by **[ARBITRATION PROVIDER — e.g., AAA]** under its applicable rules, rather than in court, except as provided below. The **Federal Arbitration Act** governs the interpretation and enforcement of this section.

**Class-action waiver.** You and the Company agree that each may bring claims **only in an individual capacity, and not as a plaintiff or class member in any purported class or representative proceeding.** The arbitrator may not consolidate claims or preside over any class proceeding.

**Small-claims carve-out.** Either party may bring an individual claim in small-claims court if it qualifies.

**30-day opt-out.** You may opt out of this arbitration agreement by sending written notice to **[PRIVACY CONTACT EMAIL]** (or **[POSTAL ADDRESS]**) within **30 days** of first accepting these Terms, stating your name and intent to opt out. If you opt out, disputes will be resolved in the courts identified in Section 20.

**Severability.** If the class-action waiver is found unenforceable as to a particular claim, that claim will be severed and heard in court, but the remainder of this section will remain in effect.

## 22. Miscellaneous / General

- **Severability.** If any provision is held unenforceable, the remaining provisions remain in full force.
- **Entire agreement.** These Terms, the **[Privacy Policy](./privacy_policy.md)**, and the consent flow constitute the entire agreement between you and the Company regarding the Services.
- **Assignment.** You may not assign these Terms without our consent; we may assign them in connection with a merger, acquisition, or sale of assets.
- **No waiver.** Our failure to enforce any provision is not a waiver.
- **Force majeure.** We are not liable for delays or failures caused by events beyond our reasonable control.
- **Notices.** We may provide notices in-app or by email; you may contact us as set out below.
- **Survival.** Sections that by their nature should survive termination will survive.

## 23. Contact Information

**[LEGAL ENTITY NAME]**
Postal address: **[POSTAL ADDRESS]**
General/support: **[SUPPORT EMAIL]**
Privacy / legal: **[PRIVACY CONTACT EMAIL]**
Data Protection Officer / privacy contact: **[DPO NAME]**

For privacy-specific matters, see the **[Privacy Policy](./privacy_policy.md)**. For support and escalation, see the **[Support & Escalation Process](./support_escalation_process.md)**. For security-incident handling, see the **[Incident Response Plan](./incident_response_plan.md)**.

**Last updated:** [DATE]  ·  **Effective date:** [EFFECTIVE DATE]  ·  **Status:** DRAFT — not yet in effect

---

## Open items / to finalize before launch

- [ ] Resolve all placeholders: `[LEGAL ENTITY NAME]`, `[JURISDICTION]`, `[PRIVACY CONTACT EMAIL]`, `[SUPPORT EMAIL]`, `[POSTAL ADDRESS]`, `[DPO NAME]`, `[EFFECTIVE DATE]`, `[DATE]`, `[FIREBASE/GCP REGION]`, `[ARBITRATION PROVIDER]`, liability cap amount.
- [ ] Have counsel licensed in **[JURISDICTION]** review the full document, especially Sections 5, 6, 9, 15, 16, and 21.
- [ ] Confirm the exact behavior of consent **revocation** on previously shared Sleep Summaries (Section 8) and align with the consent flow and Privacy Policy.
- [ ] Confirm the app is offered **only** to U.S. users; if EU/UK or minors are ever in scope, revise Sections 3 and 20 and coordinate with the Privacy Policy.
- [ ] Verify the "not a medical device" disclaimer appears in the **first paragraph** of the Google Play store description and that Apple's EULA / third-party-beneficiary terms are satisfied (Section 12).
- [ ] Confirm arbitration provider and rules; finalize the 30-day opt-out mechanics and small-claims carve-out (Section 21).
- [ ] Before enabling the Production Backend / cloud sync, revise Section 14 (retention, region, breach notice) and provide re-notice/re-consent; align with the **[Incident Response Plan](./incident_response_plan.md)** and FTC Health Breach Notification Rule commitments.
- [ ] Ensure this ToS matches the **[Privacy Policy](./privacy_policy.md)** exactly on the journal-never-shared, no-sale, no-ad-use, and no-AI-training promises (FTC Act §5 alignment).
- [ ] Mirror the not-medical-advice and crisis (988/911, no-monitoring) disclaimers in-app (onboarding + persistent screen).
