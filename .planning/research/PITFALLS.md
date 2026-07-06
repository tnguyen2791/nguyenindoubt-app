# Domain Pitfalls

**Domain:** Flutter mental-health companion MVP with clinician-linked sleep summaries
**Researched:** 2026-07-06
**Overall confidence:** HIGH for project-specific findings; MEDIUM for platform-policy notes checked against official Apple, Android, and Firebase docs through web search.

## Critical Pitfalls

### Pitfall 1: Privacy boundary regression during Firebase migration
**What goes wrong:** Journal entries or private reflections become visible to clinicians when local repository logic is replaced with Firestore queries.
**Why it happens:** The current boundary is split across product requirements, repository behavior, and draft Firestore rules: `getPatientJournalEntries` always throws, while clinicians can read sleep bundles only after accepted links. During migration, it is easy to reuse a generic `getJournalEntries(userId)` path or widen Firestore reads for dashboard convenience.
**Consequences:** Breaks the core product promise: clinicians see consented sleep summaries, never journal content.
**Prevention:** Keep separate patient and clinician read models. Clinician repositories should not expose journal APIs. Firestore rules must keep `journalEntries` patient-owned only, with emulator tests for patient read, clinician denied, unlinked clinician denied, accepted clinician sleep-only, and revoked-link denied.
**Detection:** Any clinician dashboard query mentioning `journalEntries`; any UI showing journal count, mood, title, body, draft, or reflection metadata in clinician mode; any test that asserts journal visibility for clinicians.

### Pitfall 2: Firestore `clinicianLinks` rules allowing self-approved access
**What goes wrong:** A clinician or patient creates or updates a link directly into `accepted` status and unlocks sleep reads without the intended invite acceptance flow.
**Why it happens:** Current draft rules allow `clinicianLinks` create/update when either side matches `request.auth.uid`, but do not validate deterministic document ids, allowed status transitions, immutable patient/clinician ids, or who can set `accepted`.
**Consequences:** A malicious signed-in clinician could potentially create `{clinicianUserId: self, patientUserId: target, status: accepted}` if they know or guess a patient id, then satisfy `acceptedClinicianLink`.
**Prevention:** Before live Firestore writes, lock link ids to `{clinicianUserId}_{patientUserId}`, require immutable parties on update, let only the patient or a trusted server function accept, require `pending -> accepted/revoked` transition rules, and test with the Firestore emulator.
**Detection:** Firestore rules pass for a clinician-created accepted link, a mismatched document id, a link whose parties change on update, or a revoked link that still authorizes sleep access.

### Pitfall 3: Treating the demo mode switch as authentication
**What goes wrong:** The placeholder patient/clinician switch survives into production and becomes confused with identity, authorization, or onboarding state.
**Why it happens:** `continueAsPatient` and `continueAsClinician` directly replace `_currentUser`; the app bar exposes both modes after onboarding. This is good for a demo, but it bypasses real auth, role claims, tenant boundaries, and session lifecycle.
**Consequences:** Users can enter clinician UI without proof of clinician status, tests give false confidence, and Firestore rules become the only meaningful boundary.
**Prevention:** Replace the switch with Firebase Auth or another reviewed auth provider before any backend data. Role should come from trusted claims/server-side profile, not client state. Hide clinician routes unless the signed-in user has a clinician role claim.
**Detection:** Any production build that still renders `Patient` / `Clinician` mode controls, or any route reachable by client-side role mutation alone.

### Pitfall 4: Premature Firebase, analytics, Crashlytics, or telemetry
**What goes wrong:** Sensitive mental-health text, health-adjacent sleep data, user ids, or route names are sent to third-party services before compliance and privacy review.
**Why it happens:** Firebase files exist as stubs, and adding common Firebase packages can make analytics or crash capture feel like normal app setup. The project explicitly keeps Firebase Auth, Firestore, Analytics, Crashlytics, telemetry, and real health-platform access disabled for now.
**Consequences:** Unreviewed collection of PHI-adjacent data, hard-to-delete event history, and unclear user consent posture.
**Prevention:** Keep Firebase initialization behind an explicit production-readiness gate. Add telemetry denylist tests or build-time checks before adding packages. Redact journal bodies, titles, invite codes, user ids, health sample values, and clinician/patient names from logs and errors.
**Detection:** `firebase_analytics`, `firebase_crashlytics`, automatic screen tracking, crash breadcrumbs, unredacted exception logs, or network requests in a supposed local-only demo.

### Pitfall 5: HealthKit / Health Connect permission mismatch
**What goes wrong:** Real sleep import behaves nothing like the mock: permissions are denied, partially granted, revoked, not approved for store release, or requested too broadly.
**Why it happens:** The mock provider always grants permission and lists sleep plus steps, heart rate, HRV, and mindful minutes. Official platform docs require explicit, data-type-specific permission flows; HealthKit protects denied read access, and Health Connect requires manifest permissions, Play Console alignment, privacy policy rationale, and insufficient-access UX.
**Consequences:** Empty imports with no explanation, app review rejection, user distrust, or overcollection beyond the MVP sleep-only promise.
**Prevention:** Implement provider-specific permission states: unavailable, not requested, partially granted, denied/revoked, and ready. Request sleep only for MVP. Add platform setup checks, rationale screens, permission-management links, and tests for denied and partial access.
**Detection:** UI says import succeeded with zero samples and no reason; provider requests non-sleep metrics; Android manifest or Play Console declarations do not match requested data types; no path to manage or revoke permissions.

## Moderate Pitfalls

### Pitfall 1: Local persistence mistaken for production storage
**What goes wrong:** Users enter real journal or health data into the public GitHub Pages demo, assuming it is account-backed, encrypted, synced, or clinician-visible across devices.
**Why it happens:** `SharedPreferences` persists demo users, links, samples, and journal entries under a local demo key. On web, this maps to browser-local storage behavior and does not sync across devices.
**Prevention:** Keep clear demo-only copy near journal/import/consent flows. Add a reset-local-demo-data control. Do not promise sync, account recovery, or production retention until backend storage exists.

### Pitfall 2: Consent and invite flow too permissive
**What goes wrong:** Accepting an invite grants consent even when no valid link exists, cannot be revoked, or does not explain exactly what becomes visible.
**Why it happens:** `grantPatientConsent` sets `consentStatus: granted` before checking whether the invite matched a link, and the state layer hardcodes `NID-1138`.
**Prevention:** Validate invite codes before changing consent state. Add revoke and expired-invite states. Make acceptance atomic with link update. Keep the UI copy explicit: sleep samples and summaries only, journals excluded.

### Pitfall 3: Mobile responsiveness coverage remains too narrow
**What goes wrong:** The app appears responsive in the patient happy path but overflows on small phones, long names, long resource text, clinician lists, or browser text scaling.
**Why it happens:** Current widget coverage exercises patient sign-up and mock import only. Several surfaces depend on fixed widths, app-bar segmented controls, grid aspect ratios, and faded text.
**Prevention:** Add golden/widget checks for narrow phone, large text, clinician dashboard, journal, resources, safety, and long seeded content. Prefer wrapping or overflow-safe layouts in app bars and metric cards.

### Pitfall 4: Safety screen implies action without implementation
**What goes wrong:** Crisis buttons look tappable but do nothing.
**Why it happens:** `Call 988` and `Emergency care` buttons currently have empty callbacks.
**Prevention:** Either wire platform-safe launch behavior after review or render them as informational text until phone/url launching is intentionally implemented and tested.

### Pitfall 5: Sleep summaries overwrite rather than merge
**What goes wrong:** A real import deletes previous samples for the user and replaces summaries wholesale.
**Why it happens:** `saveImportedSleep` removes all existing samples and summaries for `userId` before adding the latest import.
**Prevention:** For production providers, use stable external sample ids, source ids, observed intervals, deduplication, and incremental sync windows. Keep replace-all behavior only for mock/demo data.

## Minor Pitfalls

### Pitfall 1: Seed data contains realistic names and journal prose
**What goes wrong:** Demo content gets mistaken for real patient data or trains developers to commit plausible sensitive examples.
**Prevention:** Keep seed data fictional, obviously synthetic, and documented as demo-only. Avoid importing real notes into fixtures.

### Pitfall 2: Resource cards hide important disclaimers
**What goes wrong:** Long educational copy or safety disclaimers fade or compress in grid cards.
**Prevention:** Test longest copy at phone widths and large text. Keep crisis/safety content in a scrolling detail view if it cannot fit reliably in cards.

### Pitfall 3: Timezone and DST drift in sleep summaries
**What goes wrong:** Sleep dates can shift when samples cross midnight, daylight-saving boundaries, or user timezone changes.
**Prevention:** Store provider timestamps with timezone/source metadata and summarize by the user's intended sleep day, not just local `sample.end` date.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Auth/onboarding | Client-side mode switch remains the authority | Gate clinician UI from trusted auth claims and delete demo switch from production paths |
| Firebase integration | Firestore rules allow self-accepted clinician links or broad journal reads | Write emulator tests before app code writes production collections |
| Journal | Privacy promise erodes through summaries, metadata, logs, or clinician convenience features | Treat journal as patient-only data with no clinician DTO fields |
| Health import | Mock permission assumptions hide denied/partial/revoked platform states | Model permission state explicitly and request sleep-only access |
| Telemetry | Analytics/crash logs capture PHI-adjacent content | Keep telemetry absent until reviewed; add redaction and build-time checks |
| Mobile UI | Patient import test passes while other screens overflow | Add narrow, large-text widget/golden coverage for journal, resources, safety, clinician dashboard |
| Deployment | GitHub Pages demo is mistaken for account-backed production | Keep demo-only messaging, local reset, and no real-data copy in public builds |

## Sources

- `.planning/PROJECT.md`: local/demo-first scope, privacy promise, active risks, Firebase/telemetry/HealthKit out-of-scope flags.
- `docs/firebase_contract.md`: intended Auth, Firestore collections, deterministic clinician link ids, and journal-only-to-patient contract.
- `firestore.rules`: draft patient ownership, accepted clinician link, and journal-entry read rules.
- `lib/repositories/app_repository.dart`: local persistence, consent/link handling, clinician sleep-only access, and explicit journal denial.
- `lib/state/app_state.dart`: placeholder mode switch, hardcoded invite code, and mock sleep import state.
- `lib/services/health_data_provider.dart`: mock permissions and future provider seam.
- `lib/screens/*` and `test/*`: current UI coverage and tested privacy expectations.
- Apple Developer HealthKit docs: explicit per-type permission and privacy behavior for sensitive health data.
- Android Health Connect docs: manifest permissions, Play Console alignment, privacy policy rationale, and insufficient-access UX.
- Firebase privacy and custom claims docs: review needed before Firebase-backed identity, role claims, telemetry, or sensitive data storage.
