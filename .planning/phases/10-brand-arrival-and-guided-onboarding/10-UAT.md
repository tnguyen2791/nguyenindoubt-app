---
status: testing
phase: 10-brand-arrival-and-guided-onboarding
source: [10-VERIFICATION.md]
started: 2026-07-11T02:55:00Z
updated: 2026-07-11T02:55:00Z
---

## Current Test

number: 1
name: Native web loader in a real browser
expected: |
  Cold-load the app in Chrome (flutter run -d chrome). The pre-Flutter paint
  shows the fog (#F6F7F1) ground with the breathing brand mark — never a blank
  white frame — and the loader fades out when Flutter's first frame lands.
awaiting: user response

## Tests

### 1. Native web loader in a real browser
expected: Cold-load in Chrome shows fog+mark pre-paint (not blank white); loader fades out on Flutter's first frame. Pre-engine JS is unreachable from widget tests.
result: [pending]

### 2. Splash felt motion
expected: Brand splash blooms/rises gently, cross-fades into the app, plays once per cold launch, and never pops away abruptly. (Sequencing is test-proven; the feel is visual.)
result: [pending]

### 3. Welcome reads patient-first
expected: Exactly one primary CTA ("Get started"); "I'm a clinician" is a quiet text link; the local-only disclosure reads as calm secondary copy; the stag is top-billed at phone width.
result: [pending]

### 4. Guided empty first-run feel
expected: Empty dashboard shows the calm guided hero (single "Import sleep" action, sleep-only privacy promise) with no "--" tiles; after import, metrics tiles + trend render normally.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
