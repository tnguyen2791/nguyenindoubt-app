# NguyenInDoubt Privacy Policy

> ⚠️ **DRAFT TEMPLATE — NOT YET IN EFFECT.** This document is an implementation-ready draft. It **MUST be reviewed and approved by qualified legal counsel licensed in [JURISDICTION] before any production use or publication.** It is **not legal advice** and does not create an attorney–client relationship. Bracketed values (e.g. `[LEGAL ENTITY NAME]`) are placeholders that must be resolved before launch.
>
> **Last updated:** [DATE]
> **Effective date:** [EFFECTIVE DATE]
> **Status:** DRAFT — not yet in effect

---

## Key Privacy Promises at a Glance

These plain-language promises summarize the detailed policy below. The full legal text controls where there is any conflict.

- **Your journal is private and is NEVER shared.** Your private journal entries are the most sensitive data in NguyenInDoubt. They are architecturally walled off. Clinicians can never see them. We do not use them for advertising, analytics, or any purpose other than showing them back to you.
- **Clinicians see only consented sleep summaries — nothing else.** A clinician sees nothing until you accept their invite/consent link, and even then they can access **only the daily sleep summaries you have specifically agreed to share** — never your journal, never your raw device data.
- **We do not sell your data. We do not use your health data for advertising.** We do not share your data for cross-context behavioral advertising, and we do not transfer or sell health data to advertisers, ad networks, or data brokers.
- **No hidden tracking.** The app currently runs **no analytics, telemetry, or crash-reporting** (no Crashlytics, no Google Analytics, no third-party SDKs collecting your data).
- **The public demo stays on your device.** In the current public demo, your data is stored **locally on your device only** — there is no cross-device cloud sync and no server copy. We will give you fresh notice and ask for renewed consent **before** enabling any cloud storage of your data.
- **This is a companion app, not a medical or emergency service.** NguyenInDoubt does not diagnose, treat, monitor, or respond to emergencies. **If you are in crisis, call or text 988 (Suicide & Crisis Lifeline), or call 911.**

---

## 1. Introduction & Scope

NguyenInDoubt ("NguyenInDoubt," the "App," "we," "us," or "our") is a mental-health **companion** application operated by **[LEGAL ENTITY NAME]**, a [entity type] organized under the laws of **[JURISDICTION]**. This Privacy Policy explains how we collect, use, disclose, and protect information when you use the App on the web and on iOS and Android.

**What the App is.** NguyenInDoubt gives you a **private journal** and **sleep tracking**, and — only if you choose — lets you share **sleep summaries** with a clinician you invite.

**What the App is NOT.** NguyenInDoubt is **not** a diagnostic tool, a treatment tool, a telehealth or messaging service, or an emergency or crisis-monitoring service. It does not provide medical advice, diagnosis, or treatment, and it does not monitor you or respond to emergencies. See **Section 16 (Crisis & Safety Disclaimer)**.

**HIPAA note.** [LEGAL ENTITY NAME] is **not itself a HIPAA covered entity or business associate** with respect to your independent, consumer use of the App. A clinician you choose to share with may separately be a HIPAA covered entity subject to their own legal obligations, but those obligations govern **their** records, not the App. HIPAA does not govern your own personal use of the App. For the detailed classification, see [`./hipaa_baa_analysis.md`](./hipaa_baa_analysis.md).

This policy should be read together with our [`./terms_of_service.md`](./terms_of_service.md). For state consumer-health-data disclosures, see the linked [**Consumer Health Data Notice** (Section 14)](#14-consumer-health-data-notice-washington--nevada--connecticut).

## 2. Definitions

- **Patient.** A user who is the owner of the data in their account (journal, sleep data, consent records). The default role.
- **Clinician.** A user — typically a licensed care provider — whom a Patient invites via a consent link, and who, after the Patient accepts, may view **only** the Patient's consented sleep summaries.
- **Journal content.** Your private, free-text journal entries and associated metadata. Highest-sensitivity data. **Never shared with clinicians or any third party.**
- **Sleep samples.** Granular sleep data (e.g. sleep periods and sleep stages) imported from Apple HealthKit or Google Health Connect.
- **Sleep summaries.** Aggregated daily sleep summaries derived from sleep samples. These, and only these, are what a Patient may consent to share with a clinician.
- **Consumer health data (CHD).** Personal information linked or linkable to you that identifies your past, present, or future physical or **mental** health status, including mental-health interventions, as defined by Washington, Nevada, and Connecticut law.
- **Consent link.** The invite/consent link a Patient sends to (or accepts from) a clinician that establishes the sharing relationship.
- **Consent history.** The auditable record of consent events (grant, scope, policy version, timestamp, method, and status).
- **Processor / Service provider.** A third party (e.g. cloud infrastructure such as Firebase/Google Cloud) that processes data on our behalf under contract and only on our documented instructions.

## 3. Data We Collect and Sources

We practice data minimization: we collect only what a feature needs.

| Category | Examples | Source | Sharable with clinician? |
|---|---|---|---|
| **Account / profile** | Display name, email/identifier, role (patient/clinician), authentication data | You; authentication provider | No |
| **Private journal entries** | Free-text entries, timestamps, entry metadata | You | **Never** |
| **Sleep samples** | Sleep periods, sleep stages | Apple HealthKit / Google Health Connect (with your OS-level permission) | No (raw samples not shared) |
| **Daily sleep summaries** | Aggregated per-day sleep metrics | Derived on-device from sleep samples | **Only** the summaries you specifically consent to share |
| **Clinician invite / consent link + consent history** | Invite tokens, grant/revoke events, scope, policy version, timestamps | You; system-generated | Consent records are used to administer and evidence sharing |
| **Device / technical data** | Minimal data necessary to run the app (e.g. app/OS version, local storage state) | Your device | No |

**No analytics or telemetry.** The App currently runs **no** analytics, product telemetry, or crash-reporting SDKs (no Google Analytics, no Crashlytics, no advertising SDKs). If this ever changes, we will update this policy and provide notice before enabling any such collection, and we will never route your health data or journal content into advertising or profiling systems.

## 4. Current Storage Posture (Device-Local Demo vs. Production)

We describe our current posture honestly so this policy is accurate under the FTC Act's prohibition on deceptive practices.

- **Public demo (current).** Data is stored **device-local only** — in memory or in local device storage. There is **no cross-device sync** and **no server-side copy** of your data held by us.
- **Production backend (compliance-gated, not yet enabled).** A Firebase Authentication / Cloud Firestore backend, together with Firestore security rules enforcing the patient/clinician role separation, exists as the **production boundary**. Live cloud storage of identifiable data is **compliance-gated and not yet enabled.**
- **Before we enable cloud sync**, we will provide **renewed notice and obtain fresh consent**, because storing your health data in the cloud is a material change involving new sensitive processing. Enabling production will also require the controls described in [`./hipaa_baa_analysis.md`](./hipaa_baa_analysis.md) (e.g. an executed Google Cloud BAA and HIPAA-eligible service configuration) where applicable.

## 5. How We Use Your Data and the Purpose for Each Category

We use each category of data only for the specific purposes below (purpose limitation):

| Category | Purpose(s) |
|---|---|
| Account / profile | Create and secure your account; authenticate you; assign patient/clinician role |
| Private journal entries | Provide the private journaling feature back to **you only**; no other use |
| Sleep samples | Compute your on-device sleep tracking and derive daily summaries |
| Daily sleep summaries | Show you your sleep trends; enable **consented** sharing with a clinician you invite |
| Consent link / consent history | Establish, administer, evidence, and revoke clinician sharing; maintain an audit trail |
| Device / technical data | Operate, secure, and troubleshoot the App |

We do **not** use your data for advertising, cross-context behavioral advertising, sale, or automated diagnostic profiling. See **Sections 9, 10, and 20**.

## 6. Legal Bases for Processing (GDPR / UK GDPR)

Where the GDPR or UK GDPR applies, we rely on the following legal bases:

- **Explicit consent — Art. 9(2)(a)** for all health and mental-health (special-category) data, including journal content and sleep data. This is a higher bar than ordinary consent: it names the specific data and purposes, is unbundled from general terms, and is withdrawable at any time.
- **Consent — Art. 6(1)(a)** and/or **performance of a contract — Art. 6(1)(b)** for account and profile data needed to provide the service you request.
- **Legitimate interests — Art. 6(1)(f)** only for narrow operational purposes such as securing the App, where not overridden by your rights.

For US users, our processing of consumer health data is grounded in your **affirmative, opt-in consent** as required by applicable state law (see Sections 8 and 14).

## 7. Sensitive / Special-Category & Consumer Health Data

We treat **mental-health data — especially journal content — as the highest-sensitivity data we handle.** Depending on where you live, this data may be:

- **"Special category data"** under GDPR Art. 9 / UK GDPR (processed only with your explicit consent);
- **"Sensitive personal information"** under the California CPRA (data concerning health, and data collected and analyzed concerning your health);
- **"Consumer health data"** under the Washington My Health My Data Act (RCW 19.373), Nevada SB 370, and Connecticut's consumer-health-data provisions.

Our core protection is **structural**: journal content is architecturally excluded from all sharing and is never disclosed to clinicians or third parties. This promise is enforced not only in policy but in the App's design and Firestore security rules (see Section 12).

## 8. Consent, Withdrawal, and the Clinician-Sharing Model

Consent in NguyenInDoubt is **layered, granular, and opt-in**, presented as a distinct interaction — never bundled into general Terms of Service acceptance and never obtained through dark patterns.

We obtain **separate and distinct** consents, consistent with Washington MHMDA and Nevada SB 370:

1. **Consent to collect health data** — a specific, informed, opt-in consent to import sleep samples/summaries from Apple HealthKit or Google Health Connect.
2. **Consent to share** — a **separate** consent to share **specific daily sleep summaries** with a **specific clinician** you invite.

**The clinician-sharing flow, precisely:**

- A clinician sees **nothing** until you accept an invite/consent link.
- Acceptance grants the clinician access to **only the consented daily sleep summaries** — **never** your journal content and **never** raw sleep samples.
- Your **consent history** (type, scope, policy version, timestamp, method, and status) is retained as an audit record.
- **Withdrawal is as easy as granting.** You may revoke consent at any time. Revocation **stops all future sharing** immediately. **[Describe here what happens to summaries previously shared with the clinician — e.g., whether the clinician's already-viewed/downloaded copies persist, and whether access to previously shared summaries is also cut off. Confirm actual product behavior before launch — [RETENTION/REVOCATION BEHAVIOR TO CONFIRM].]**
- Once a clinician receives data in their professional capacity, that clinician's own HIPAA and professional obligations may apply to **their** records. This policy governs the App, not the clinician's records.

## 9. How We Share Data & Who Receives It

We share data only as described here:

- **With clinicians you invite** — only consented sleep summaries, only after you accept the consent link (Section 8).
- **With processors / service providers** — e.g. cloud infrastructure and authentication (**Firebase / Google Cloud Platform**), which process data on our behalf under contract, only on our instructions, and not for their own purposes. (Applies once production storage is enabled.)
- **For legal reasons** — where required by law, valid legal process, or to protect rights and safety.
- **In a business transfer** — subject to this policy and applicable law, with notice where required.

**Categories of third parties that may receive consumer health data:** cloud infrastructure/hosting providers and authentication providers (**[NAME SPECIFIC AFFILIATES / PROCESSORS — e.g., Google LLC / Firebase]**). We will maintain and disclose a current list; see the Consumer Health Data Notice (Section 14).

**We do NOT:** sell your personal information; share it for cross-context behavioral advertising; or disclose your journal content to anyone.

## 10. Apple HealthKit & Google Health Connect Disclosures

When you grant permission, the App imports **sleep samples, sleep stages, and derives daily sleep summaries** from **Apple HealthKit** (iOS) or **Google Health Connect** (Android). We commit to the following, consistent with Apple's HealthKit policy (App Store Guideline 5.1.3) and Google's Health Connect / Android health data-use policy:

- Health/fitness data is used **only** to provide the sleep-tracking and consented-sharing features you request.
- We **do not** use HealthKit or Health Connect data for **advertising** or any use-based data mining.
- We **do not** sell, and **do not** transfer, health/fitness data to advertising platforms, data brokers, or resellers.
- Sleep data is handled on a **per-device / on-device** basis in the current demo posture; raw samples are not shared with clinicians.
- You can **revoke** the App's access at any time through your operating system's Health permissions (iOS Health app / Android Health Connect settings). Revoking OS access stops future imports.

## 11. Data Retention & Deletion

- **Device-local demo.** Data lives on your device; you control it and can delete it by clearing the App's local data or deleting the App. We hold no server copy.
- **Retention (when production storage is enabled).** We retain each category only as long as necessary for its purpose: account/profile — **[RETENTION PERIOD]**; sleep samples/summaries — **[RETENTION PERIOD]**; journal content — **[RETENTION PERIOD]** (retained solely for you); consent history — **[RETENTION PERIOD]** (retained to evidence lawful sharing).
- **Deletion on request or account closure.** You may request deletion of your data (Section 13). Deletion propagates across our systems and any processors/affiliates. **[Describe effect on summaries already shared with a clinician and on consent/audit records we are required to retain for compliance.]**
- Note: our deletion/export workflows are **pending** as production launches; see [`../production_posture.md`](../production_posture.md) and the Open Items checklist.

## 12. Data Security

- **Encryption** in transit and (once cloud storage is enabled) at rest.
- **Access controls and role separation.** The patient/clinician boundary is enforced in code and by **Firestore security rules** using a deny-by-default posture: the clinician role has **no read path** to journal documents and can access only consented sleep summaries.
- **Structural walling-off** of journal content from all sharing surfaces.
- **Current demo posture:** device-local storage, no server-side custody of your data by us.
- Even where HIPAA does not apply, we adopt recognized HIPAA Security Rule–style safeguards (access control, audit logging, minimum-necessary sharing) as our baseline standard.
- **Breach response.** See Section 17 and our [`./incident_response_plan.md`](./incident_response_plan.md).

## 13. Your Privacy Rights

Depending on your jurisdiction, you may have the rights below. We honor requests as required by applicable law.

**GDPR / UK GDPR:** access; rectification; erasure; restriction of processing; data portability; objection; **withdraw consent** at any time (without affecting prior lawful processing); and the right to lodge a complaint with a supervisory authority.

**US state rights (California/CPRA, Washington, Nevada, Connecticut, and others):** to know/access; to delete; to correct; to obtain a **list of third parties** that received your (consumer health) data; to **opt out of sale, sharing, and targeted advertising** and profiling; to **limit the use and disclosure of sensitive personal information**; and to **non-discrimination** for exercising your rights.

**How to exercise.** Contact us at **[PRIVACY CONTACT EMAIL]** or **[POSTAL ADDRESS]**. We will verify your identity in a manner proportionate to the sensitivity of the data before acting. If we deny a request, you may **appeal** by replying to our decision; we will respond within the time your jurisdiction requires.

Because our access/export/deletion workflows are **pending** during the pre-production phase (see [`../production_posture.md`](../production_posture.md)), we will handle early requests manually via **[PRIVACY CONTACT EMAIL]**.

## 14. Consumer Health Data Notice (Washington / Nevada / Connecticut)

> **This section is our Consumer Health Data Notice, required to be separately and prominently linked (including from our homepage) under the Washington My Health My Data Act.** It may also be maintained as a standalone linked document.

- **Categories of CHD collected:** mental-health-related inputs (journal content — retained for you only and never shared), sleep samples and daily sleep summaries, and consent/relationship records.
- **Sources:** you (journal, profile, consents) and, with your permission, Apple HealthKit / Google Health Connect (sleep data).
- **Purposes:** to provide the private journal and sleep tracking, and to enable consented sharing of sleep summaries with a clinician you invite.
- **Sharing / recipients:** clinicians you invite (consented sleep summaries only); processors/service providers such as cloud and authentication infrastructure (**[NAME SPECIFIC AFFILIATES]**). **We do not sell CHD and do not share it for advertising.**
- **Your rights:** to confirm whether we collect/share your CHD; to access it; to a list of third parties/affiliates with whom we share it; to **delete** it (including across affiliates and processors); and to **withdraw consent** to collection and to sharing.
- **How to submit a request:** email **[PRIVACY CONTACT EMAIL]** or write to **[POSTAL ADDRESS]**. We honor withdrawal of consent as easily as it was given.
- **Geofencing.** We do not use geofences around health-care facilities to identify, track, or collect data from, or send notifications to, consumers, consistent with WA/NV/CT prohibitions.
- Washington residents note: the MHMDA provides a private right of action; Nevada and Connecticut are enforced by their Attorneys General.

## 15. Children & Minors

NguyenInDoubt is intended for users **18 and older**. We do **not** knowingly collect personal information from anyone under 18, given the sensitivity of mental-health data and the requirements of COPPA (and evolving proposals to extend protections to older minors). If we learn we have inadvertently collected data from a minor, we will delete it promptly. If you believe a minor has provided us data, contact **[PRIVACY CONTACT EMAIL]**.

## 16. Crisis & Safety Disclaimer

**NguyenInDoubt is not for emergencies and does not monitor or respond to crises.** It does not provide diagnosis, treatment, emergency monitoring, or patient-to-clinician messaging.

**If you are in crisis or thinking about harming yourself:**
- **Call or text 988** — the **988 Suicide & Crisis Lifeline** (US), available 24/7.
- **Call 911** or go to your nearest emergency room for a medical emergency.

The App does not review or respond to your journal entries, and no one is monitoring your data for signs of crisis. Nothing in the App is medical advice.

## 17. FTC Health Breach Notification Rule

Because we draw identifiable health information from **multiple sources** (Apple HealthKit / Google Health Connect **and** your own inputs), the App is a "vendor of personal health records" within the FTC's Health Breach Notification Rule (16 CFR Part 318, as amended effective July 29, 2024). If an unauthorized acquisition or disclosure of your identifiable health data occurs, we will notify **affected individuals**, the **FTC**, and, where thresholds are met, the **media**, within the timeframes the Rule requires. See our [`./incident_response_plan.md`](./incident_response_plan.md).

## 18. International Data Transfers

In the current device-local demo, your data stays on your device and is not transferred by us. Once production storage is enabled, data may be processed in **[FIREBASE/GCP REGION]**. Where we transfer personal data out of the EEA, UK, or Switzerland, we rely on appropriate safeguards such as the **EU Standard Contractual Clauses** and/or the **UK IDTA / Addendum**. Contact us for details.

## 19. Third-Party Services & Links

The App integrates with **Apple** (HealthKit), **Google** (Health Connect; Firebase/Google Cloud). Their handling of data under their own agreements is governed by their policies:
- Apple: https://www.apple.com/legal/privacy/
- Google: https://policies.google.com/privacy
- Firebase/Google Cloud: https://firebase.google.com/support/privacy

We are not responsible for the privacy practices of third parties. Review their policies.

## 20. Automated Decision-Making / No Diagnostic Profiling

We do **not** use your data for automated decision-making that produces legal or similarly significant effects, and we do **not** perform diagnostic profiling or algorithmic assessment of your mental-health status. The App is a companion tool, not a diagnostic engine.

## 21. Changes to This Policy

We may update this policy. We will revise the "Last updated" date and, for **material changes** — especially any new sensitive processing such as enabling cloud storage of health data — we will provide prominent notice and, where required, obtain **renewed explicit consent** before the change takes effect. Prior versions and version numbers will be maintained.

## 22. Contact & Data Protection Officer / Representative

- **Controller:** [LEGAL ENTITY NAME]
- **Privacy contact / DPO:** [DPO NAME], **[PRIVACY CONTACT EMAIL]**
- **Support:** [SUPPORT EMAIL] (see also [`./support_escalation_process.md`](./support_escalation_process.md))
- **Postal address:** [POSTAL ADDRESS]
- **EU / UK representative (if applicable):** [EU/UK REPRESENTATIVE — NAME & CONTACT]

You may lodge a complaint with your local data-protection supervisory authority (EEA/UK) or applicable state Attorney General.

## 23. State-Specific & Jurisdictional Disclosures

**California (CPRA).** This policy serves as our **Notice at Collection**. We collect the categories in Section 3, including **sensitive personal information** (health data). We do not sell or share personal information for cross-context behavioral advertising, and we do not use or disclose your sensitive personal information beyond the limited purposes permitted without a right to limit. We nonetheless honor **"Do Not Sell or Share My Personal Information"** and **"Limit the Use of My Sensitive Personal Information"** requests via **[PRIVACY CONTACT EMAIL]**. California residents have the rights in Section 13 and the right to non-discrimination.

**Washington / Nevada / Connecticut.** See the **Consumer Health Data Notice** (Section 14).

**Other states.** Residents of other states with comprehensive privacy laws may have analogous rights; contact us to exercise them.

**Governing law.** This policy is governed by the laws of **[JURISDICTION]**, without prejudice to mandatory consumer-protection rights in your place of residence.

## 24. Open Items / To Finalize Before Launch

Implementers must resolve the following before this policy goes live:

- [ ] Replace all placeholders: `[LEGAL ENTITY NAME]`, `[JURISDICTION]`, `[EFFECTIVE DATE]`, `[DATE]`, `[DPO NAME]`, `[PRIVACY CONTACT EMAIL]`, `[SUPPORT EMAIL]`, `[POSTAL ADDRESS]`, `[FIREBASE/GCP REGION]`, all `[RETENTION PERIOD]` values, `[EU/UK REPRESENTATIVE]`, and `[NAME SPECIFIC AFFILIATES / PROCESSORS]`.
- [ ] Confirm and document the exact **revocation behavior** for previously shared sleep summaries (Section 8) and effect of deletion on shared data and retained consent records (Section 11).
- [ ] Finalize per-category **retention periods** with counsel.
- [ ] Stand up **access / export / deletion** workflows (currently pending per [`../production_posture.md`](../production_posture.md)) and update Sections 11 & 13 accordingly.
- [ ] Confirm whether cloud production storage is enabled at launch; if so, complete the go-live gate in [`./hipaa_baa_analysis.md`](./hipaa_baa_analysis.md) (executed Google Cloud BAA, HIPAA-eligible services, region) and run the **re-consent** flow (Section 21).
- [ ] Publish the **Consumer Health Data Notice** (Section 14) as a prominently linked notice (including from the homepage) per WA MHMDA.
- [ ] Ensure this policy **exactly matches** Apple's App Privacy "nutrition labels" and Google Play's "Data safety" disclosures.
- [ ] Confirm the **18+** age gate is implemented and enforced (Section 15).
- [ ] Provide a valid, accessible privacy-policy **URL** for App Store and Google Play listings.
- [ ] **Legal counsel review and sign-off in [JURISDICTION].**
