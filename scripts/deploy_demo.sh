#!/usr/bin/env bash
#
# Publish the NguyenInDoubt device-local DEMO to Firebase Hosting.
#
# This deploys the public, device-local demo build (in-memory repository, no
# server-side storage of any personal/health data). It does NOT enable live
# Firebase Auth/Firestore production storage — see docs/production_posture.md
# and .planning/GO-LIVE.md before attempting a real production launch.
#
# Prerequisites (run on a machine with the toolchain — NOT available in the
# ephemeral cloud session that authored this script):
#   - Flutter SDK (matching pubspec: Dart sdk ^3.12.0)
#   - Firebase CLI (`npm i -g firebase-tools`) and `firebase login`
#   - Access to the Firebase Hosting project 'nguyenindoubt-demo'
#
# Usage:
#   ./scripts/deploy_demo.sh              # build + deploy to nguyenindoubt-demo
#   PROJECT=my-demo ./scripts/deploy_demo.sh   # override the target project
#   SKIP_TESTS=1 ./scripts/deploy_demo.sh      # skip the release gate (not advised)

set -euo pipefail

PROJECT="${PROJECT:-nguyenindoubt-demo}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> NguyenInDoubt demo deploy (project: $PROJECT)"

command -v flutter >/dev/null 2>&1 || { echo "ERROR: flutter not found on PATH"; exit 1; }
command -v firebase >/dev/null 2>&1 || { echo "ERROR: firebase CLI not found (npm i -g firebase-tools)"; exit 1; }

echo "==> flutter pub get"
flutter pub get

if [ "${SKIP_TESTS:-0}" != "1" ]; then
  echo "==> Release gate: analyze + test"
  flutter analyze
  flutter test
else
  echo "==> Skipping release gate (SKIP_TESTS=1)"
fi

echo "==> flutter build web (release)"
# Firebase Hosting serves at the domain root, so the default base href (/) is correct.
flutter build web --release

echo "==> firebase deploy (hosting only)"
firebase deploy --only hosting --project "$PROJECT"

echo "==> Done. Demo published to the '$PROJECT' Hosting site."
echo "    Reminder: this is the device-local demo. No production PHI storage is enabled."
