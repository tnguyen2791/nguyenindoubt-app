# iOS build blocker (2026-07-12) — ✅ RESOLVED

**Status:** Fixed in commit `01bcb96`. Option 1 (clean regen) worked: removing
`ios/Podfile.lock` + `ios/Pods` and re-running `pod install --repo-update` let
the resolver downgrade **GTMSessionFetcher/Core to 3.5.0** — the overlap of
GoogleSignIn 9.2 (`~> 3.3`) and Firebase 12.15 (`>= 3.4, < 6.0`). The old
lockfile had been pinned at 5.3.0, which sits outside GoogleSignIn's range.
CocoaPods added a `[CP] Copy Pods Resources` phase for GoogleSignIn's bundle.
Release build compiles and runs on device + simulator. No pubspec downgrade or
Podfile pin was needed. The original diagnosis + options are kept below for the
record.

---

## Original diagnosis

`pod install --repo-update` failed with a transitive version conflict:

```
[!] CocoaPods could not find compatible versions for pod "GTMSessionFetcher/Core":
    GoogleSignIn (~> 9.0) was resolved to 9.2.0, which depends on
    (a GTMSessionFetcher/Core version that conflicts with the Firebase pods'
     pinned GTMSessionFetcher/Core inside dev pod `google_sign_in_ios`)
```

## Root cause
`google_sign_in ^7.2.0` (pubspec) pulls **GoogleSignIn ~9.0 (→9.2.0)**, which requires a **GTMSessionFetcher/Core** version incompatible with what **firebase_auth/cloud_firestore (Firebase 12.x)** pin. Web build + tests are unaffected — this is iOS pods only.

## Fix options (try in order, cheapest first)
1. **Clean regen:** `rm ios/Podfile.lock && rm -rf ios/Pods && cd ios && pod install --repo-update`. Sometimes resolves once the whole spec repo is current.
2. **Force a compatible GTMSessionFetcher** in `ios/Podfile` (inside the Runner target): `pod 'GTMSessionFetcher/Core', '~> 3.5'` (match the version Firebase 12.x wants — check `pod 'FirebaseAuth'`'s transitive pin). Then `pod install`.
3. **Pin google_sign_in down** in pubspec to a version whose GoogleSignIn (~8.x/7.x) uses a GTMSessionFetcher compatible with Firebase 12.x, then `flutter pub get` + `pod install`. Re-verify the iOS URL scheme (reversed client id) survives.

After pods resolve: `flutter run --release -d 00008140-00184CE420A2201C` onto TryCare (detach so it stays). Deployment target 15.0; team 87LV6VQZWF; URL scheme already set (com.googleusercontent.apps.6173983291-kndcs876...).

## Then continue the handoff
2. Apply `.planning/FIDELITY-SWEEP.md` (one executor pass + full bar).
3. Deploy `userPreferences` rule: `firebase deploy --only firestore:rules --project nguyenindoubt-app`.
4. Open PR `design/v1.1-experience` → main.
