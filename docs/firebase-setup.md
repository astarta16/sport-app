# Firebase setup (dev / staging / production)

Nothing in this repository is connected to a real Firebase project. Demo mode runs entirely in memory. Everything in this document requires your own accounts and **was not performed** here.

## 1. Projects and environments

Create **three** Firebase projects: `…-dev`, `…-staging`, `…-prod`. They share no data. Each needs:
- the **Blaze** plan (required for Cloud Functions and scheduled jobs);
- region `europe-west1` (functions) and a Firestore location in the EU;
- Authentication → **Phone**, plus test numbers for QA;
- Firestore, Storage and Cloud Messaging;
- Crashlytics (iOS/Android) — optional, but the app is wired for it.

The app chooses the environment at build time:

| `--dart-define` | Values | Meaning |
|---|---|---|
| `APP_MODE` | `demo`, `firebase` | Demo never initialises Firebase |
| `APP_ENV` | `dev`, `staging`, `prod` | Firebase builds only. Debug defaults to `dev`; release defaults to `staging`, so `prod` must be named explicitly |
| `ALLOW_DEMO_IN_RELEASE` | `true` | Needed for release demo builds such as the beta APK |
| `USE_FIREBASE_EMULATOR`, `EMULATOR_HOST` | | Local emulators |

Generate native config per environment with flavors or separate output folders. The generated files are git-ignored. **Never commit them**, and never commit service-account keys.

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<dev-project-id> --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=ge.sportparent.sport_parent_app.dev --android-package-name=ge.sportparent.sport_parent_app.dev
```

`firebase_bootstrap.dart` currently calls `Firebase.initializeApp()` with the platform files. When you add per-environment `firebase_options_*.dart`, select them by `AppConfig.environment`.

## 2. Deploy backend (from a trusted machine)

```bash
cd functions && npm ci && npm run build && npm test
firebase use <project-id>
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Secrets (Secret Manager; never in the repo):
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` or `SMS_HTTP_API_KEY`, only if SMS is enabled;
- environment flag `SMS_SENDING_ENABLED=true` — leave it unset until a provider is contracted.

`functions/.secret.local` holds emulator placeholders only and is git-ignored.

## 3. IAM and production-only items

- **Signed URLs** (`getCertificateUrl`, `getMediaUrl`, `getExportUrl`): grant the functions service account the *Service Account Token Creator* role.
- **Custom claims**: run `functions/scripts/grant-platform-admin.mjs` once per project to create the first platform admin. It refuses production without its explicit flag.
- **FCM / APNs**: upload the APNs auth key in Firebase → Cloud Messaging. On iOS, enable Push and Background Modes in Xcode.
- **Crashlytics**:
  - add the `com.google.firebase.crashlytics` Gradle plugin (Android) and the dSYM upload script (iOS) for symbolication;
  - collection starts **disabled** and is enabled only when the user opts in under Privacy.
- **App Check** (recommended before public launch): Play Integrity / DeviceCheck plus enforcement on Firestore, Storage and Functions.
- **Web admin**: add the web app in Firebase, enable phone auth reCAPTCHA for the admin domain, and host the `build/admin_web` output (Firebase Hosting or another host) behind HTTPS.
- **Video**: H.264/720p transcoding and thumbnails need a worker (Cloud Run with ffmpeg) triggered by `onMediaUpload`. They are not implemented; `onMediaUpload` validates type and size only.
- **Retention**: `processAccountRequests` deletes immediately in the current implementation. Confirm the legal retention periods (payments for accounting) before production.

## 4. Local emulators (what was used for testing)

```bash
cd rules-tests && npm ci && npm run test:emulator          # 94 rules tests
npm run smoke:functions                                      # 22 end-to-end steps
flutter run --dart-define=APP_MODE=firebase --dart-define=USE_FIREBASE_EMULATOR=true
```

The emulator project id is `demo-sport-parent`, so the emulators can never reach real services. If port 8080 is taken, copy `firebase.json`, change `emulators.firestore.port`, and pass `--config`.
