# გუნდი (Gundi) — Sports app for parents, children and coaches

**Beta v1.2:**
- mobile app (iOS / Android / iPad) plus a separate **admin web dashboard**;
- v1.0 spec + v1.1 changes + v1.2 beta: invitations, recurring schedules, attendance/RSVP, progress, matches, media, moderation, notification center, account lifecycle.

Status: [docs/beta-v1.2-progress.md](docs/beta-v1.2-progress.md).

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

**What's new in v1.2 to try:**
- Parent:
  - the invitation banner on Home (link the invite to existing Mariam → no duplicate);
  - RSVP on a training;
  - Progress (attendance %, achievements, coach feedback);
  - the chat icon in the top bar;
  - the notification center with categories.
- Coach:
  - the "+" button (training / recurring schedule / match / media / invite);
  - the group page (code, invitations, schedules);
  - attendance roster;
  - announcements in chat.
- Profile:
  - "Simulate offline" (demo card);
  - Account (consents, export, deletion preview).

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

## Admin web dashboard (v1.3)

```bash
flutter run -d chrome -t lib/main_admin.dart          # demo: platform admin / club admin / "parent" (denied)
flutter build web -t lib/main_admin.dart --release --dart-define=APP_MODE=demo \
  --dart-define=ALLOW_DEMO_IN_RELEASE=true -o build/admin_web
cd build/admin_web && python3 -m http.server 8765    # http://127.0.0.1:8765
```

What it covers:
- coach verification, clubs, sports catalog, group oversight, moderation, audit log, admin roles;
- v1.3: certificate compliance (counts only), attendance reports, plan oversight, payment verification queue with receipt review, payment reviewers per group, language (ka/en/ru);
- roles enforced server-side through custom claims. Guide: [docs/admin-guide.md](docs/admin-guide.md).

## Android APK (demo mode)

```bash
flutter build apk --release --dart-define=APP_MODE=demo --dart-define=ALLOW_DEMO_IN_RELEASE=true \
  --build-name=1.3.0 --build-number=14
```

Release builds refuse demo mode unless `ALLOW_DEMO_IN_RELEASE=true` is passed. The release
build is signed with the debug key (no release keystore configured) — fine for testing, not for Google Play.

## What's new in v1.3

- **Medical certificates:** sport-specific certificates, replace, preview, coach download with a warning and audit, reminders at 14/3/0 days, admin compliance as counts only.
- **Coach student roster:** search, sort, filters, attendance and certificate status; attendance marked as a draft and then saved; PDF/CSV exports (roster, attendance sheet, monthly report) with the Georgian font.
- **Training plans:** seasonal, monthly, weekly, exercise and homework plans, with exercises, media and https links; draft → published → archived; parent progress; homework on the dashboard.
- **Payment proofs:** the parent uploads a receipt, giving "Awaiting verification". Only explicit reviewers or club admins can approve or reject (with a reason).
- **Languages:** Georgian (default), English and Russian in the app, the admin web and server messages (Settings → Language).

Demo walk-through (sign in on the demo screen):
1. Parent Nino → Payments → football fee → *Submit proof* → demo receipt → Submit. The status changes to *Awaiting verification*.
2. Coach Giorgi → Home → *Verify payments* → Approve. The payment becomes *Paid*.
3. Coach → Home → *Training plans* → the U-12 draft → Publish. The parents of U-12 are notified.
4. Coach → Home → *Students* → Export → PDF or CSV.

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
| `APP_ENV` | `dev` (debug) / `staging` (release) | Firebase environment: `dev`, `staging`, `prod` (demo is always `demo`) |
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
  admin/          admin web dashboard (entry: lib/main_admin.dart)
  l10n/           app_ka.arb (template), app_en.arb + generated AppLocalizations
functions/        Cloud Functions (TypeScript) + unit tests
rules-tests/      Firestore/Storage rules tests + functions smoke test (emulators)
firestore.rules  storage.rules  firestore.indexes.json  firebase.json
tool/strings*.py  single source for both ARB files (strings, strings_v12, strings_admin) → `python3 tool/gen_arb.py`
docs/             assumptions, implementation progress, backend
```

## Verification commands

```bash
dart format lib test --line-length 120
flutter analyze
flutter test                                   # 215 tests (responsive, security, workflows, admin, l10n, v1.3 flows)
cd functions && npm install && npm run build && npm test      # 185 tests
cd rules-tests && npm install && npm run test:emulator        # 135 rules tests (Java 17+)
cd rules-tests && npm run smoke:functions                     # 32 end-to-end steps
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

Docs:
- [docs/assumptions.md](docs/assumptions.md) — decisions taken on open questions;
- [docs/implementation-progress.md](docs/implementation-progress.md) — v1.0 status;
- [docs/beta-v1.2-progress.md](docs/beta-v1.2-progress.md) — v1.2 status;
- [docs/beta-v1.3-progress.md](docs/beta-v1.3-progress.md) — v1.3 status (what is verified, untested or missing);
- [docs/data-model-v1.3.md](docs/data-model-v1.3.md) — v1.3 data contract;
- [docs/data-model-v1.2.md](docs/data-model-v1.2.md) — data model;
- [docs/security-review.md](docs/security-review.md) — security review;
- [docs/firebase-setup.md](docs/firebase-setup.md) — Firebase setup;
- [docs/admin-guide.md](docs/admin-guide.md) — admin guide;
- [docs/beta-test-plan.md](docs/beta-test-plan.md) — beta test plan;
- [docs/release-checklist.md](docs/release-checklist.md) — release checklist;
- [docs/backend.md](docs/backend.md) — backend.
