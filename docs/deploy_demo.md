# Publishing the NguyenInDoubt demo

This is the runbook for **Path A — publish the device-local demo** to the web.
It deploys the current app, which uses the in-memory repository
(`InMemoryAppRepository`, backed by browser/device local storage). **No personal
or health data is stored server-side**, so this is safe to publish without the
production-launch compliance work.

> For a real, account-backed production launch, see
> [`../.planning/GO-LIVE.md`](../.planning/GO-LIVE.md) — that path is gated on
> compliance work and must not reuse this demo deploy.

## What gets deployed

- Target: **Firebase Hosting**, project `nguyenindoubt-demo`
  (`firebase.json` → `build/web`; `.firebaserc` → default `nguyenindoubt-demo`).
- The web build runs entirely device-local: `main.dart` constructs
  `InMemoryAppRepository`; there is **no** Firebase Auth/Firestore initialization
  and no server-side write path.

## Prerequisites

Run on a machine with the toolchain (the ephemeral cloud session cannot build or
deploy):

- Flutter SDK (Dart `sdk: ^3.12.0` per `pubspec.yaml`)
- Firebase CLI: `npm i -g firebase-tools`, then `firebase login`
- Access to the `nguyenindoubt-demo` Firebase project

## Deploy

```sh
./scripts/deploy_demo.sh
```

The script runs `flutter pub get`, the release gate (`flutter analyze` +
`flutter test`), `flutter build web --release`, then
`firebase deploy --only hosting`. Overrides:

- `PROJECT=my-demo ./scripts/deploy_demo.sh` — deploy to a different project
- `SKIP_TESTS=1 ./scripts/deploy_demo.sh` — skip the release gate (not advised)

Or manually:

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
firebase deploy --only hosting --project nguyenindoubt-demo
```

## Before you announce it

- [ ] The release gate passes (`flutter analyze`, `flutter test`,
      `flutter build web`). **Note:** the recent data-rights and legal-docs work
      was authored without a Flutter toolchain available, so run the gate before
      the first deploy.
- [ ] The in-app demo notice is visible ("Demo mode: data stays on this
      device…") — it is rendered by `_DemoNotice` in `app_shell.dart`.
- [ ] The public page distinguishes device-local demo data from production
      (PROD-01 in the roadmap; see `docs/production_posture.md`).
- [ ] Crisis resources (988/911) render and the dialer/links work on web.

## Optional: automated deploy

A GitHub Actions job could build and deploy on push (using a Firebase
service-account secret you add to the repo). Not set up here per your call to
skip CI; the local runbook above needs no CI. Ask if you want the workflow added.
