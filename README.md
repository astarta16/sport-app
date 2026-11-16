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

## Admin web dashboard (v1.3, multi-tenant since v1.7, Platform Control Center since v1.8)

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
- v1.8 Platform Control Center (platform admin, first demo account): Overview, Organizations (+ provisioning wizard and
  detail tabs), Organization templates, Feature catalog, Packages, Subscriptions, Invitations, Platform users, Audit
  logs, System health. Organization admins (Tianeti, Mtskheta, Saburtalo) see only their organization's pages.
  Guide: [docs/platform-super-admin.md](docs/platform-super-admin.md).

## Android APK (demo mode)

```bash
flutter build apk --release --dart-define=APP_MODE=demo --dart-define=ALLOW_DEMO_IN_RELEASE=true \
  --build-name=1.8.0 --build-number=21
```

Release builds refuse demo mode unless `ALLOW_DEMO_IN_RELEASE=true` is passed. The release
build is signed with the debug key (no release keystore configured) — fine for testing, not for Google Play.

## What's new in v1.8: Platform Super Admin, feature management, subscriptions

- **Platform Control Center** (admin web) — overview with totals, adoption, subscriptions, alerts and recent admin
  actions; organization directory; organization detail with Overview, Admins & members, Features, Subscription,
  Branding, Limits & usage, Audit history and Settings tabs. [Guide](docs/platform-super-admin.md).
- **Provisioning** — wizard with legal/funding profile, template, package, initial features (dependency-checked) and
  an invited first administrator; stable ids; two-phase, recoverable creation. Templates: Government Sports School,
  Private Sports Club, Children's Sports Academy, Independent Coach (create, edit, duplicate, archive, apply with
  preview). [Provisioning](docs/organization-provisioning.md).
- **Central feature management** — 22 features with stable ids, a dependency graph (confirmation before adding
  dependencies), rollout states (enabled / disabled / trial / scheduled), versioned changes with reason, author,
  history and conflict detection. A disabled feature disappears from navigation, cards and actions, its routes are
  blocked, writes are rejected by the backend and rules, its jobs and notifications stop, and its data is kept.
  Changes reach open apps live. [Feature management](docs/feature-management.md).
- **Three-level authorization** — platform entitlement × organization switch × user permission.
- **Packages and subscriptions** — Starter / Professional / Enterprise / Custom with limits and informational
  pricing; trial / active / past due / suspended / cancelled / expired with grace periods and read-only access;
  manual only, **no billing**. [Subscriptions](docs/subscription-management.md).
- **Administrator invitations** — expiring, hashed, single-use tokens; accept, reject, resend, revoke, transfer.
- **Demo** — Tianeti is now a government school (payments, receipts, reminders off; rooms, student accounts and
  Brain Academy on); new **Saburtalo Sports Club** (private, payments on: coach **ლევან ჩხეიძე**, parent
  **მარიამ კაპანაძე**, admin **თამარ გელაშვილი**); **Vake Youth Academy** on a trial; Nino (demo parent) has a
  pending admin invitation to Saburtalo — in the admin web choose the parent account and enter
  `demo-invite-saburtalo-2026`.

Details, verification and open items: [docs/beta-v1.8-progress.md](docs/beta-v1.8-progress.md).
Upgrade: [docs/firebase-migration-plan.md](docs/firebase-migration-plan.md) (`functions/scripts/migrate-v18.mjs`, dry run by default).

## What's new in v1.7: multi-academy SaaS

- **Organizations (tenants):**
  - each sports school runs with its own data, branding, modules and limits;
  - the Platform Super Admin creates schools and assigns their admins;
  - organization admins manage only their own school;
  - modules are enforced on the server.
  - Docs: [multi-tenant architecture](docs/multi-tenant-architecture.md),
    [organization admin guide](docs/organization-admin-guide.md).
- **Room scheduling:**
  - halls with opening hours, capacity and maintenance;
  - a day/week calendar with drag-to-move;
  - conflict-free bookings checked atomically on the server;
  - recurring sessions checked all-or-nothing;
  - suggested free times and rooms.
  - Docs: [room scheduling](docs/room-scheduling.md).
- **RSVP for trainings and matches:**
  - answers per guardian; reschedules ask for reconfirmation;
  - a separate "გავეცანი" acknowledgment;
  - coach counters (confirmed / declined / not sure / no response / reconfirm);
  - attendance rosters for matches.
- **Student dashboard:**
  - upcoming trainings and matches with venue, map and directions;
  - coach profiles;
  - "Contact coach", mediated by the parent;
  - real points and progress;
  - opt-in academy leaderboards ([policy](docs/leaderboard-policy.md)).
- **New sports:** volleyball and badminton, with localized names from the catalog.
- **Demo:**
  - Tianeti Sports School and Mtskheta Youth Academy;
  - new quick sign-ins: **ეკა ხუციშვილი** (parent), **ნინო გელაშვილი** (coach);
  - Admin Web: **თამარ ლომიძე** (Tianeti admin), **დავით კობახიძე** (Mtskheta admin).

Details and verification: [docs/beta-v1.7-progress.md](docs/beta-v1.7-progress.md).
Upgrade notes: [docs/firebase-migration-plan.md](docs/firebase-migration-plan.md).

## What's new in v1.6.1

- **Brain Academy polish:**
  - clearer start screens (objective, difficulty hints, unlocked levels);
  - an in-game status bar (level, difficulty, score, time, progress, lives, streak);
  - big right/wrong feedback with icons, shake and glow;
  - success screens with 1–3 stars, badges and the next level unlocked;
  - kind failure screens with a reason, retry and an "easier" option.
- **Per game:**
  - Memory: 3D flips and combos;
  - Logic: an explanation and a Next button;
  - Smart Play: the best choice is always marked, with pitch arrows and a coach's tip;
  - Quick Mind: an urgency timer and reaction time;
  - Sequence: separate watch and play phases;
  - Path Finder: start and goal markers, cones, "Blocked!" feedback, and a board that always fits.
- **Sound and vibration:** short bundled sounds and haptics, with switches in the game's settings (speaker icon); the switches are remembered.

Details: [docs/beta-v1.6.1-progress.md](docs/beta-v1.6.1-progress.md).

## What's new in v1.6

- **Student demo account:** on the demo sign-in screen tap **Continue as Student** (Luka Beridze, football, coach Giorgi, parent Nino). Student sign-in exists only in demo mode.
- **Student dashboard:** sports, coach, next training, matches and results, plans and homework, attendance, achievements — no payments, medical documents, chat, phone numbers or admin functions.
- **Brain Academy:** six playable games (Memory Match, Logic Quest, Smart Play, Quick Mind, Sequence Master, Path Finder) with difficulties, levels, pause/resume, scores, badges and progress charts. Points are for practice — not an IQ test.
- **Parents** see their child's Brain Academy progress in the student profile; **coaches** assign games as challenges (with optional due dates) from the group roster and review completion.

## What's new in v1.5

- **Student profile** (`/student/<childId>`): one page per child with groups, coaches, upcoming trainings and matches, training and attendance history, plans and homework, coach media, match results, certificate and payment status. Parents see their own children; coaches see only their own groups' data.
- **Message the coach about one child:** a private conversation per child and coach, visible only to that child's guardians and that coach; with a call button.
- **Receipts reach the coach:** the reviewer's notification now opens the payment request directly (view, download, approve, reject); the parent's decision notification opens their payment.
- **Match results:** coaches enter and correct the final score (win / draw / loss derived, corrections logged); parents are notified and see results on the dashboard, the student profile, match details and the calendar.

## What's new in v1.4

- **Contacts:** coaches see and call the parents/guardians of their students (chat, roster, student details); parents see and call their child's coach. Parents never see other parents.
- **Read receipts:** "Seen by 8 of 12 parents" under the coach's messages, with a per-parent detail screen. A message counts as seen only when it is actually shown in the open chat.
- **Acknowledgments:** the coach can tick *Require acknowledgment*; parents confirm with "გავეცანი". The coach sees Seen and Acknowledged counters, and the parent dashboard lists open requests.
- **Video player** with play/pause, ±10 s, a seek bar, times, fullscreen, buffering and retry.
- **Downloads** of authorized coach photos and videos, with progress, cancel and retry, through the phone's share/save sheet. Admins can turn downloads off per group and see a download log.

## What's new in v1.3.1

- **Add to calendar:** a training or match can be added to the phone's calendar (Google, Apple, Outlook) as an `.ics` file with a 1-hour reminder; the Calendar tab exports the next 60 days of the selected child's trainings in one file.
- **Server notifications for attendance and coach feedback**, in each parent's language, once per status change.
- **Chat lines when a training is moved or the schedule changes**, sent by the server (before, only the demo did this).
- **Plan audit names the person who published or archived the plan**, not its creator.

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
lib/l10n/*.arb   source of truth for strings since v1.4; add new ones with `python3 tool/add_l10n.py tool/strings_v17.json`
                 (tool/gen_arb.py is legacy and refuses to run: it would drop every string added after v1.3)
docs/             assumptions, implementation progress, backend
```

## Verification commands

```bash
dart format lib test --line-length 120
flutter analyze
flutter test                                   # 422 tests (… v1.3–v1.8 flows, games, scheduling, tenants, platform)
cd functions && npm install && npm run build && npm test      # 235 tests
cd rules-tests && npm install && npm run test:emulator        # 201 rules tests (Java 17+)
cd rules-tests && npm run smoke:functions                     # 43 end-to-end steps
# v1.7 / v1.8 callables (from rules-tests/): npx firebase emulators:exec --config ../firebase.json \
#   --only functions,firestore,auth --project demo-sport-parent \
#   "node ../functions/test-integration/v17.integration.mjs && node ../functions/test-integration/v18.integration.mjs"
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
