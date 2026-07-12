# Compliance & Regulatory Research — staying a non-device wellness app (2026-07-12)

> **Not legal advice.** A synthesis of FDA/HHS/FTC guidance + law-firm analysis,
> adversarially verified (deep-research pass, 14 high-confidence findings, mostly
> unanimous 3-0 verification votes). Given real patient data, minors, and a
> licensed-clinician builder, confirm with a health-tech attorney before the
> clinician-sharing bridge handles real PHI.

**Goal (owner constraint):** keep NguyenInDoubt a low-risk **"general wellness"**
product — explicitly NOT a regulated medical device (SaMD).

## Bottom line
A multi-signal "readiness" score + sleep trends + a private mood journal can
credibly stay a non-device general-wellness product. FDA's **revised guidance
(Jan 6, 2026)** helps: it names HRV/HR/SpO₂ as parameters that *can* be general
wellness, and Example 7 (a wrist-worn "activity and recovery" multi-biomarker
wearable) qualifies. But general wellness is **enforcement discretion, not a
statutory safe harbor** — the guardrails are the whole game.

## 1. FDA bright lines (how to stay non-device)
Two things must BOTH hold: intended for general-wellness use only, AND low risk.
Claims must stay in Category 1 (maintain/encourage general health, no disease
reference) or Category 2 (relate healthy lifestyle to reduced risk of chronic
conditions). Basis: FD&C Act §520(o)(1)(B) (21st Century Cures Act §3060).

**Never (turns it into a device):**
- Name a disease — **depression, anxiety, insomnia, PTSD, "sleep disorder"** — in
  claims, UI copy, or notifications.
- Use **diagnose / treat / cure / mitigate / prevent**.
- **NEW (Jan 2026):** outputs that **"guide clinical management"** or **"mimic
  clinical measures unless validated."**

**Do:** present readiness/sleep as **observational, relative wellness indices** —
not clinical-looking absolute values. The existing "observational, never a
diagnosis; never labels the person" framing is correct and load-bearing.
⚠️ Watch the 0-100 / ring readout — keep it a qualitative wellness index, not a
value that reads like a validated clinical measure.

## 2. ⚠️ Biggest risk is already in the code — the "Worth a look" flagging
The transmit/store/display exclusion (Non-Device-MDDS, Cures Act §520(o)(1)(D))
is **lost the moment software analyzes/interprets patient data** and surfaces it
to a clinician. FDA's 2022 MDDS guidance names "generate alarms or alerts or
prioritize patient-related information" as interpretation → device.

`lib/screens/clinician_dashboard.dart` → **`_WorthALookSection`** ("Worth a look ·
not alerts, just patterns") computes which patients had short/variable nights and
surfaces them to the clinician. **This is exactly the bright line** — and the
"not alerts, just patterns" label does NOT save it; flagging/prioritizing *is*
interpretation. **Action:** drop the auto-flagging, or move that computation to a
patient-initiated "share this" action. A pure patient-directed transmit/display
bridge stays non-device.

## 3. HIPAA — outside it until the clinician bridge goes live
- HIPAA binds covered entities + business associates, **not a standalone consumer
  app**. Outside HIPAA today.
- **Facilitating a patient's access to their OWN data ≠ Business Associate**
  (HHS FAQ 3013). Keep sharing **patient-initiated and patient-directed** — the
  invite model already is.
- **BUT** if the backend stores/transmits identifiable patient data **"on behalf
  of" the clinician** (app furnished/commissioned by the practice) → BA → a
  **written BAA is mandatory before any PHI flows** (45 CFR 164.502(e)). This is
  the load-bearing risk in the deferred server-side `acceptInvite` step — gate it
  behind that analysis.
- If PHI is in scope: **execute Google's BAA** (Firestore IS a covered service),
  and use only covered services; signing is necessary-not-sufficient (owner still
  builds the compliant configuration).

## 4. Laws that apply even OUTSIDE HIPAA (the real exposure)
- **FTC Health Breach Notification Rule** likely covers the app: a multi-source
  HealthKit/Health Connect + mood app is a "personal health record." "Breach"
  now includes **unconsented sharing** (ad/tracking pixels), not just hacks.
- **GoodRx bright line (FTC, 2023):** permanent ban on health-data-for-advertising
  + $1.5M. → **Never sell health data or share it for ads.** (App has zero
  analytics/telemetry — already aligned; keep it.)
- **Washington My Health My Data-style laws:** affirmative express consent, clear
  category disclosure, **no dark patterns**, honor deletion, accurate privacy
  policy.

## 5. Apple / HealthKit
No ads, no selling HealthKit data, health/fitness use only with consent,
**mandatory privacy policy**, clear medical disclaimer ("observational, not a
diagnosis, not a substitute for professional care"), keep the 988 surface.
⚠️ Legal/privacy pages are currently no-ops in the app — an App Store blocker.

## 6. Minors — IN SCOPE (owner is a child & adolescent psychiatrist)
Owner decision (2026-07-12): **kids will use the app.** This materially raises the
bar — minor mental-health data is among the most scrutinized categories.

- **Under 13 → COPPA:** verifiable parental consent before collecting anything;
  health data is sensitive. Heaviest burden.
- **13–17 → teen privacy laws** (CA Age-Appropriate Design Code + growing states),
  increasingly with sensitive-data consent.
- **The adolescent-consent paradox (the crux):** most US states let adolescents
  consent to their OWN mental-health treatment — with confidentiality *from
  parents* (thresholds vary by state). A naïve **parent-controlled** sharing flow
  can *violate* the confidentiality state law grants the teen. Must decide, state-
  aware: who consents to share (parent / adolescent / both), and what a parent can
  see.
- **Design already helps:** journal + readiness stay private, sleep-summaries-only
  to the clinician — good for adolescent confidentiality. New wrinkle: a potential
  **third party (parent)** — "what can a parent see?" must be answered
  deliberately.
- **⚠️ Clinical-safety tension:** the private journal protects confidentiality but
  means a distressed teen could journal something acute that *no one sees* except
  the 988 nudge. Needs an explicit stance on crisis-surface prominence around
  journaling.
- **App Store "Kids" rules:** no third-party analytics/ads, stricter review
  (already clean).
- FDA non-device analysis unchanged by pediatric use; the §2 "Worth a look" risk
  matters more with minors. FERPA only if school-connected.
- **Fork:** (1) restrict to 13+ (dodges COPPA's heaviest machinery, still handles
  teen privacy + consent), or (2) full pediatric incl. under-13 (parental consent
  + adolescent-confidentiality-aware sharing). Owner leans toward (2).
- **Open:** a focused, cited deep-dive on the minors-in-scope path (COPPA
  mechanics, state-by-state adolescent-consent map, teen privacy laws, App Store
  Kids, and a concrete parent/teen/clinician access design) — not yet run.

## Guardrail checklist
1. Never name a disease; never diagnose/treat/cure/mitigate/prevent.
2. Readiness/sleep = observational relative indices; never mimic clinical measures
   or guide clinical management.
3. **Clinician bridge = transmit/store/display the patient's own sleep summaries
   only. No flags, no "worth a look," no alerts, no prioritization.**
4. Keep readiness + journal off every clinician surface (already done).
5. Keep sharing patient-initiated/patient-directed; don't position as
   clinician-furnished.
6. Before real PHI flows: BA analysis → BAA → Google BAA + covered-services-only.
7. Never sell/share health data for ads.
8. Affirmative express consent, category disclosure, no dark patterns, honor
   deletion, real privacy policy.
9. Medical disclaimer + keep 988.
10. Minors IN scope → parental consent (COPPA) + adolescent-confidentiality-aware
    sharing design; decide the parent-visibility model deliberately.

## Sources
FDA General Wellness guidance (rev. Jan 6 2026) + Cures Act §520(o); HHS HIPAA
guidance + FAQ 3013 (45 CFR 160.103 / 164.502); FTC HBNR (2024) + GoodRx order
(2023); Google Cloud HIPAA docs. Corroborated across Troutman, Faegre Drinker,
Covington, ArentFox Schiff, King & Spalding.
