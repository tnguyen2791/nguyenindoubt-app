# Phase 7 CONTEXT: Production Deployment Posture

## Starting Point

- Phases 1-6 implemented the local demo, auth/session shape, privacy boundary,
  Firebase adapter/rules boundary, consent lifecycle, and platform health import
  provider boundary.
- The app still runs local/demo-first by default.
- Firebase and HealthKit/Health Connect integration points exist, but production
  use remains gated by compliance and operational review.
- README and in-app copy mention local demo storage but do not yet form a full
  release posture.

## Decisions

- Public demo stays device-local and must say so directly.
- Production backend mode is not enabled in this phase.
- Retention/export/deletion are documented as expectations and blockers, not as
  completed production user workflows.
- Release notes should name privacy-sensitive changes, verification commands,
  and compliance blockers.
- Verification should include the Phase 7 required commands plus Firestore rules
  regression because privacy rules remain central to launch posture.
