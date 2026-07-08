# NguyenInDoubt — Compliance & Legal Documents

> ⚠️ **ALL DOCUMENTS IN THIS DIRECTORY ARE DRAFT TEMPLATES — NOT LEGAL ADVICE.**
> They must be reviewed, completed (every `[BRACKETED PLACEHOLDER]` resolved), and
> approved by qualified legal counsel licensed in `[JURISDICTION]` before any
> production use or publication. Nothing here creates an attorney–client relationship.

This folder holds the compliance/legal foundation called for in
[`../production_posture.md`](../production_posture.md) under **Compliance blockers**.
The documents were drafted for NguyenInDoubt's specific architecture: a private
patient journal that is **never** shared, clinicians who see **only consented sleep
summaries**, HealthKit/Health Connect sleep imports, a **device-local demo** vs. a
**compliance-gated Firebase production** boundary, and a US-focused 988/911 crisis
posture.

## Documents

| Document | Purpose | Audience |
|---|---|---|
| [`privacy_policy.md`](./privacy_policy.md) | User-facing privacy policy incl. the Consumer Health Data Notice (WA MHMDA), HealthKit/Health Connect disclosures, GDPR/CPRA handling, and the clinician-sharing consent model. | Public / users |
| [`terms_of_service.md`](./terms_of_service.md) | Terms of Service with not-medical-advice + emergency/no-monitoring disclaimers, journal ownership, clinician-role terms, liability, and dispute resolution. | Public / users |
| [`hipaa_baa_analysis.md`](./hipaa_baa_analysis.md) | Internal analysis of whether/when the app is a HIPAA business associate, with a decision tree, the FTC HBNR parallel obligation, and a production go-live gate. | Internal / counsel |
| [`incident_response_plan.md`](./incident_response_plan.md) | NIST 800-61 incident response + breach-notification runbook (HIPAA / FTC HBNR / GDPR / state), roles, severity, and templates. | Internal |
| [`support_escalation_process.md`](./support_escalation_process.md) | Support tiers/SLAs, triage, and the mental-health crisis-escalation protocol (in-app + staff), plus the support↔incident-response hand-off. | Internal |

## How the documents relate

- The **Privacy Policy** and **Terms of Service** are the two user-facing documents;
  they must stay consistent with each other on the journal-never-shared, no-sale,
  no-ad-use, and crisis (988/911, no-monitoring) promises.
- The **HIPAA/BAA Analysis** is the gate that decides what must be true before live
  cloud storage of identifiable health data is enabled (executed Google Cloud BAA,
  HIPAA-eligible services, etc.).
- The **Incident Response Plan** operationalizes breach notification across whichever
  regime applies; the **Support & Crisis-Escalation Process** feeds it (frontline
  support is often the first detector) and owns the crisis-signposting protocol.

## Before any of these go live

1. Resolve every `[PLACEHOLDER]` (legal entity, jurisdiction, contacts, retention
   periods, region, etc.) — see each document's **Open Items** checklist.
2. Have counsel licensed in `[JURISDICTION]` review and sign off on the full set.
3. Complete the production **go-live gate** in
   [`hipaa_baa_analysis.md`](./hipaa_baa_analysis.md) §18 and
   [`incident_response_plan.md`](./incident_response_plan.md) §18 before enabling the
   compliance-gated Firebase/Firestore production backend.
4. Mirror the not-medical-advice and crisis disclaimers in-app (onboarding +
   persistent screen), and publish the Consumer Health Data Notice as a prominently
   linked notice per WA MHMDA.

## Status

All five documents are **DRAFT — not yet in effect**. This is scaffolding to
accelerate counsel review, not a substitute for it.
