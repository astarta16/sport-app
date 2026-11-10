# Release checklist — beta v1.2

## Local verification (done 2026-11-10)
- [x] `dart format lib test --line-length 120`
- [x] `flutter analyze` — no issues
- [x] `flutter test` — 185 passed
- [x] `cd functions && npm run build && npm test` — 130 passed
- [x] Rules emulator tests — 94 passed
- [x] Functions smoke test (emulators) — 22 steps passed
- [x] Android release APK (demo) built, installed and launched on the Pixel 6 API 33 emulator
- [x] Admin web built (`build/admin_web`) and checked in a browser (sign-in, dashboard, coaches)
- [x] iOS simulator build (demo) — built, launched on iPhone 17 Pro (iOS 26.1); sign-in and coach dashboard checked. iPad simulator not checked by eye (no access granted)

## Build commands

```bash
# Android beta APK (demo data, debug-signed)
flutter build apk --release --dart-define=APP_MODE=demo --dart-define=ALLOW_DEMO_IN_RELEASE=true \
  --build-name=1.2.0 --build-number=12
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/SportParentApp-Beta-v1.2.apk

# iOS simulator (demo)
flutter build ios --simulator --debug --dart-define=APP_MODE=demo

# Admin web (demo)
flutter build web -t lib/main_admin.dart --release --dart-define=APP_MODE=demo \
  --dart-define=ALLOW_DEMO_IN_RELEASE=true -o build/admin_web
```

## Before a store/TestFlight release (not done — needs accounts)
- [ ] **Android signing:** create an upload keystore, add `android/key.properties` (git-ignored) and a `release` signingConfig. The current APK uses the **debug key** and is only for side-loading.
- [ ] **iOS:**
  - Apple Developer team, bundle id, provisioning, push capability + APNs key;
  - archive with `flutter build ipa --dart-define=APP_MODE=firebase --dart-define=APP_ENV=staging`;
  - upload to App Store Connect (not done, by instruction).
- [ ] **TestFlight requirements:**
  - privacy manifest / App Privacy answers (children's data, health documents);
  - export compliance;
  - beta app review information with demo credentials (use staging test phone numbers).
- [ ] Firebase staging/prod projects configured ([firebase-setup.md](firebase-setup.md)); `APP_ENV` set explicitly.
- [ ] Rules, indexes and functions deployed to staging; smoke test re-run against staging.
- [ ] First platform admin granted via `grant-platform-admin.mjs`.
- [ ] Crashlytics symbol upload; App Check enforced.
- [ ] Legal: privacy policy, parental consent text and retention periods approved.
- [ ] SMS provider contracted (or leave SMS disabled — the default).
- [ ] Version bump (`pubspec.yaml` `version:` and `AppConfig.version`).
