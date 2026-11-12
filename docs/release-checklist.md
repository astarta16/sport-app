# Release checklist: beta v1.3

## v1.3.1 local verification (done 2026-11-12)
- [x] `dart format`, `flutter analyze`: no issues
- [x] `flutter test`: 221 passed (6 new: `.ics` builder, add-to-calendar on training/match/calendar screens)
- [x] Functions build, typecheck, `npm test`: 193 passed (8 new)
- [x] Rules emulator tests: 136 passed (1 new: plan `updatedBy`)
- [x] Functions smoke test (emulators): 37 steps passed (5 new: attendance and feedback notifications, moved-training and schedule chat lines, plan audit actor)
- [x] Android release APK: `~/Desktop/SportParentApp-Beta-v1.3.1.apk`, versionName 1.3.1, versionCode 15
- [x] APK install test: installed on the Pixel 6 API 33 emulator (package manager: versionName 1.3.1, versionCode 15), launched, signed in as the demo parent, opened a training and tapped *Add to calendar*; the system share sheet offered `training_…_20261112-2104.ics` (nothing was shared)
- [x] Admin web rebuilt (`build/admin_web`)
- iOS simulator and iPad were not re-checked for 1.3.1 (widget tests only)

## Local verification (done 2026-11-11)
- [x] `dart format lib test --line-length 120`
- [x] `flutter analyze`: no issues
- [x] `flutter test`: 215 passed
- [x] `cd functions && npm run build && npm run typecheck && npm test`: 185 passed
- [x] Rules emulator tests: 135 passed (Firestore on port 8181)
- [x] Functions smoke test (emulators): 32 steps passed
- [x] Android release APK (demo) built: `~/Desktop/SportParentApp-Beta-v1.3.apk`, 74.4 MB, versionName 1.3.0, versionCode 14 (checked with `aapt2 dump badging`)
- [x] APK install test: the first 1.3.0 (14) build was installed on the Pixel 6 API 33 emulator (the package manager confirmed the version), launched, and showed the demo coach sign-in and dashboard. The final APK was rebuilt for a header-layout fix and could **not** be reinstalled, because the emulator shut itself down again (a known local emulator issue).
- [x] Admin web built (`build/admin_web`) and checked in a browser: compliance, payments queue, switching to Russian
- [x] iOS simulator build (demo) launched on iPhone 17 Pro (iOS 26.1). Sign-in and the parent dashboard (child switch, training-plans section) were checked by eye. The iPad simulator was not checked by eye (no access granted); iPad layouts are covered by widget tests only.

## Build commands

```bash
# Android beta APK (demo data, debug-signed)
flutter build apk --release --dart-define=APP_MODE=demo --dart-define=ALLOW_DEMO_IN_RELEASE=true \
  --build-name=1.3.1 --build-number=15
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/SportParentApp-Beta-v1.3.1.apk

# iOS simulator (demo)
flutter build ios --simulator --debug --dart-define=APP_MODE=demo

# Admin web (demo)
flutter build web -t lib/main_admin.dart --release --dart-define=APP_MODE=demo \
  --dart-define=ALLOW_DEMO_IN_RELEASE=true -o build/admin_web
cd build/admin_web && python3 -m http.server 8765
```

## Migration from v1.2 (run before or with the v1.3 functions deploy)
1. Deploy `firestore.indexes.json` first and wait until the new indexes are built: `paymentProofs`, `paymentVerificationEvents`, `trainingPlans`, `exerciseProgress`.
2. Deploy the functions, then the rules (`firestore.rules`, `storage.rules`).
3. **Payment reviewers:** existing groups have no `paymentManagerIds`, so after the deploy *only club admins* can mark payments paid. Ask each club admin to assign reviewers (Admin web → Groups → ✓₾), or backfill deliberately with a one-off admin script. Never default everyone to reviewer.
4. Existing payments need no change: a missing `verification` reads as `none`, and displays as Pending, Paid or Cancelled as before.
5. Existing certificates have no `sportId`, so they count as general certificates. Reminder flags `d14SentAt` / `d3SentAt` / `d0SentAt` start empty, so a certificate already inside a window gets at most one reminder for it.
6. `users.locale` is optional; the server falls back to Georgian.
7. Re-run the smoke test against staging.

## Production configuration checklist
- [ ] Firebase projects for staging and prod (`flutterfire configure`), with `APP_ENV` set explicitly per build.
- [ ] Blaze plan; Functions region chosen; Storage bucket with CORS for the admin web.
- [ ] Service account for Functions has **Service Account Token Creator** (signed URLs for certificates, receipts, plan media, media posts).
- [ ] Phone Auth enabled; test numbers for review; reCAPTCHA / web config for the admin web.
- [ ] APNs key uploaded (iOS push); FCM verified on Android.
- [ ] App Check enforced for Firestore, Storage and Functions.
- [ ] Crashlytics enabled (opt-in respected) and dSYM/mapping upload.
- [ ] SMS provider contracted and `SMS_SENDING_ENABLED=true` set only in prod (mock otherwise).
- [ ] First platform admin via `functions/scripts/grant-platform-admin.mjs`; club admins assigned; payment reviewers assigned per group.
- [ ] Scheduled functions enabled (certificate reminders, payment reminders, match reminders, series extension).
- [ ] Retention and legal texts approved (medical documents, receipts, exports).
- [ ] Native-speaker review of the Russian and English strings.

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
