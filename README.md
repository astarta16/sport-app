# გუნდი (Gundi) — Sports app for parents, children and coaches

Flutter app (iOS + Android) built from the technical specification
*„სპორტის აპლიკაცია მშობლებისთვის: ტექნიკური დოკუმენტი" v1.0*. Georgian is the
primary language; English is wired in for the second phase.

- **Stack:** Flutter 3.47 / Dart 3.13 · Riverpod 3 · GoRouter 18 · Firebase (Auth, Firestore, Storage, FCM, Cloud Functions) · flutter_map + OpenStreetMap
- **Architecture:** feature-first clean architecture (`lib/features/<feature>/{data,domain,presentation}`); every repository has a **demo** and a **Firebase** implementation behind the same interface.
- **Demo mode** runs the whole app with fictional in-memory data — no Firebase, no keys, no SMS, no real personal or medical data.

## Quick start (demo mode — no setup needed)

```bash
flutter pub get
flutter run                      # debug builds default to demo mode
```

On the sign-in screen use **Quick demo sign-in**:

| Account | What you can try |
|---|---|
| **ნინო ბერიძე** (parent) | 3 children, sport switching, next training + directions, certificates (valid / expiring / missing), payments, chat, notifications, map + membership request |
| **გიორგი კაპანაძე** (coach) | Groups U-10/U-12, roster with certificate status, create / edit / reschedule / cancel trainings, photos with consent check, approve membership requests, payments (mark paid, plans, run SMS reminders with the mock provider) |
| **ლევან გელაშვილი** (coach, pending) | The approval gate; a demo button approves him as the club admin would |

You can also sign in with any Georgian mobile number (`5XX XXX XXX`) and the demo
code **123456** to try registration. Switch demo accounts from **Profile**.
Demo data resets on every app restart; the last selected child/sport/group is
stored on the device and restored on reopen.

## iPad and adaptive layouts

Layouts follow the **window width** (so Split View, Slide Over and Stage Manager work), see `lib/core/layout/responsive.dart`:

| Width | Class | Navigation | Content |
|---|---|---|---|
| < 600 | compact (iPhone, Slide Over, 1/3 Split View) | bottom bar | original phone layouts |
| 600–839 | medium (iPad mini portrait, 1/2 Split View, phone landscape) | navigation rail | width-capped single column, sheets become dialogs |
| 840–1199 | expanded (iPad portrait, iPad mini landscape) | navigation rail | two-column dashboards, chat master-detail, calendar beside lists, two-column forms/profile, roster grid, map side panel |
| ≥ 1200 | large (iPad Air/Pro landscape) | sidebar (extended rail) | + coach group list as master pane, calendar with training-detail pane |

## Android APK (demo mode)

```bash
flutter build apk --release --dart-define=APP_MODE=demo --dart-define=ALLOW_DEMO_IN_RELEASE=true
```

Release builds refuse demo mode unless `ALLOW_DEMO_IN_RELEASE=true` is passed. The release
build is signed with the debug key (no release keystore configured) — fine for testing, not for Google Play.

## Running against Firebase

1. Create a Firebase project, enable Phone Auth, Firestore, Storage, Functions (Blaze), FCM.
2. `dart pub global activate flutterfire_cli && flutterfire configure` — this creates
   `GoogleService-Info.plist` / `google-services.json` (both git-ignored). For Android also
   apply the `com.google.gms.google-services` Gradle plugin as flutterfire instructs.
3. Deploy rules, indexes and functions — see [docs/backend.md](docs/backend.md).
4. Run: `flutter run --dart-define=APP_MODE=firebase`
   - Local emulators instead: `--dart-define=APP_MODE=firebase --dart-define=USE_FIREBASE_EMULATOR=true`
     (Android emulator: add `--dart-define=EMULATOR_HOST=10.0.2.2`).

| `--dart-define` | Default | Meaning |
|---|---|---|
| `APP_MODE` | `demo` in debug, `firebase` in release | `demo` or `firebase` |
| `ALLOW_DEMO_IN_RELEASE` | `false` | Release builds ignore `APP_MODE=demo` unless this is `true` |
| `USE_FIREBASE_EMULATOR` | `false` | Point SDKs at local emulators |
| `EMULATOR_HOST` | `localhost` | Emulator host |

If Firebase mode starts without native config, the app shows a configuration
screen instead of crashing.

## Project layout

```
lib/
  app/            config, DI (repository providers), demo/Firebase bootstrap, router, shell, settings
  core/           theme (design system), widgets, l10n helpers, utils (dates/Tbilisi, geo, validators), services
  features/
    authentication  onboarding  parent  children  coach  sports  clubs  groups
    trainings  calendar  chat  maps  medical_certificates  notifications  payments
    media  profile  settings  demo (in-memory backend + seed)
  l10n/           app_ka.arb (template), app_en.arb + generated AppLocalizations
functions/        Cloud Functions (TypeScript) + unit tests
rules-tests/      Firestore/Storage rules tests + functions smoke test (emulators)
firestore.rules  storage.rules  firestore.indexes.json  firebase.json
tool/strings.py   single source for both ARB files → `python3 tool/gen_arb.py`
docs/             assumptions, implementation progress, backend
```

## Verification commands

```bash
dart format lib test --line-length 120
flutter analyze
flutter test                                   # 130 tests (incl. 31 responsive)
cd functions && npm install && npm run build && npm test      # 68 tests
cd rules-tests && npm install && npm run test:emulator        # 52 rules tests (Java 17+)
cd rules-tests && npm run smoke:functions                     # 12 end-to-end steps
```

## Security model (summary)

Default-deny Firestore and Storage rules, enforced server-side and mirrored by
`AccessPolicy` on the client (the demo backend enforces the same policy):

- Children never have chat; child sign-in is disabled until the age/consent policy is confirmed.
- Coaches see nothing about children until **approved**; they see only their groups.
- Parents see only their own children; phone numbers are never shown between parents.
- Medical files live at `medical/{childId}/{certId}` with **no client read**; access is a
  5-minute signed URL from `getCertificateUrl` after a membership check, with an audit entry.
  Removing a child from a group revokes coach access automatically.
- SMS is server-only, mock by default, and requires `SMS_SENDING_ENABLED=true` plus a
  configured provider; reminders are claimed in a transaction before sending (idempotent).

See [docs/assumptions.md](docs/assumptions.md) for decisions taken on open questions and
[docs/implementation-progress.md](docs/implementation-progress.md) for status.
