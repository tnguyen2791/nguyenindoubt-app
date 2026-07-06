---
phase: 01
slug: demo-promise-hardening
status: approved
shadcn_initialized: false
preset: none
created: 2026-07-06
---

# Phase 01 - UI Design Contract

> Visual and interaction contract for Phase 1 demo hardening. This phase preserves the current Flutter Material MVP and hardens the demo promise across local-state clarity, responsive surfaces, safety routing, and clinician privacy copy.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | Flutter Material 3 |
| Icon library | Material Icons |
| Font | Avenir Next, falling back to platform sans-serif |

Use existing `BrandHeader`, `SectionCard`, `StatusPill`, `EmptyState`, and `SleepTrendBars` components before adding new visual primitives. Cards stay at 8px radius. Do not introduce hero redesigns, decorative backgrounds, nested cards, or a new palette in Phase 1.

---

## Spacing Scale

Declared values:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps, chart label spacing |
| sm | 8px | Compact row gaps, pill internals |
| md | 12px | Card-to-card gaps in dense content |
| lg | 16px | Default section gaps, row-to-column spacing |
| xl | 20px | Screen padding on patient, journal, resources, safety, and clinician views |
| 2xl | 24px | Onboarding and shell padding |
| 3xl | 28px | Wide `BrandHeader` padding |

Exceptions: Existing chart internals may keep their current 6px and 10px values when changing them would create unnecessary visual churn.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 14-16px | 400 | 1.45 |
| Label | 12-14px | 700-900 | default |
| Heading | 20-24px | 700 | default |
| Display | 34px | 700 | default |

Do not scale font size with viewport width. Keep compact panel headings at `titleLarge` or smaller. Button labels must fit at phone widths without overflow.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F6F7F1` | Scaffold background and calm page surface |
| Secondary (30%) | `#FFFFFF`, `#E4EDDD` | Cards, empty states, status backgrounds |
| Accent (10%) | `#1E4A34`, `#5D7F43` | Headers, navigation selected state, chart bars, primary buttons |
| Destructive | `#C56844` | Crisis indicators, short-sleep bars, urgent disclaimers |

Accent reserved for: primary action buttons, selected navigation, privacy status indicators, and chart emphasis. Do not make Phase 1 a one-hue redesign; keep the existing fog, white, mint, canopy, moss, bark, and ember balance.

---

## Layout Contract

### App Shell
- Keep onboarding first, then patient or clinician demo mode.
- Keep patient navigation as `NavigationBar` below 880px and `NavigationRail` at 880px and above.
- The app bar may include demo-state affordances, but controls must not overflow at phone widths. If there is not enough width, collapse secondary controls into an icon button or menu.

### Patient Dashboard
- Preserve the current metric tiles, sleep trend card, and demo invite card.
- Local-demo copy should be near mode/persistence controls or the invite/demo card, not buried in a footer.
- Reset must be presented as a demo-local action, not as account deletion or clinical data deletion.

### Journal
- The private journal header must continue to make clinician-hidden status visible.
- The form must remain usable on phone width. Segmented mood controls may wrap or become a compact control if needed.
- Saved entries must remain readable without text clipping.

### Resources and Safety
- Resource cards must not hide crisis disclaimers on phone width. Prefer a list or unconstrained-height cards on narrow screens if the grid clips content.
- Safety CTAs must be action buttons that route outward or clearly explain what the user should do if the platform cannot launch the target.
- Safety page must keep no-monitoring/no-diagnosis copy visible without requiring users to infer it from README.

### Clinician Dashboard
- Phone width may stack linked-patient list above details; desktop may keep side-by-side layout.
- The detail panel must show sleep summaries and privacy boundary copy only. Do not add journal preview, journal count, note snippets, or private reflection metadata.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Local demo state | `Demo data is stored on this device. It does not sync across desktop, phone, or the GitHub Pages demo.` |
| Reset action | `Reset demo data` |
| Reset confirmation | `Reset demo data: clear journal entries, imported sleep samples, and consent state stored on this device, then restore the seeded demo.` |
| Patient privacy reminder | `Clinicians can see accepted sleep summaries only. Journal entries stay private.` |
| Clinician visibility reminder | `Visible: sleep samples, daily summaries, trend flags. Hidden: journal entries, drafts, private reflections.` |
| Safety urgent support | `Call or text 988` |
| Emergency care | `Emergency care` |
| Safety limit | `NguyenInDoubt does not provide diagnosis, treatment, emergency monitoring, or patient-to-clinician messaging in this MVP.` |

Copy must be short and direct. Avoid compliance claims such as HIPAA-ready, production-safe, clinical monitoring, or real-time risk detection.

---

## Interaction Contract

- Reset demo data requires an explicit confirmation before clearing local persistence.
- Safety actions should use platform-safe outward routing. If direct launch is not supported on a platform, show clear fallback instructions rather than silently doing nothing.
- Busy states should disable actions already using async state (`Import`, `Accept invite`, reset if added).
- Clinician mode switch remains a demo affordance for Phase 1; copy should not imply it is production auth.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| third-party registries | none | not allowed in Phase 1 |

No new UI registry, component package, or icon package should be introduced for Phase 1. If external URL-launch behavior needs a dependency, it must be justified in the plan as behavior infrastructure rather than UI styling.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-07-06
