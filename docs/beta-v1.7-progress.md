# Beta v1.7: multi-academy SaaS, attendance, scheduling, leaderboards

Everything was built and verified locally:

- demo mode;
- the Firebase emulators;
- the iOS simulator.

Nothing was pushed or deployed, and no real Firebase project, SMS or push
service was used. All data is synthetic.

## 1. Audit (what existed, what was extended)

| Area | Found | v1.7 decision |
|---|---|---|
| Tenancy | `clubs` already scoped groups (`clubId`), platform admin (`admin`) and club admins (`clubAdmin` claim) | the club **is** the organization; added `orgConfigs` + `orgMembers` instead of a parallel system |
| Roles | parent / coach / child (student, demo-only) / admin (platform or club) | unchanged; added organization membership roles |
| RSVP / attendance | trainings only; one answer per child; coach roster with bulk marking, edit, export | extended to matches, schedule versions, per-guardian answers, history |
| Acknowledgment | v1.4 "გავეცანი" for coach chat messages | reused for schedule-change notices |
| Brain Academy | results stored, badges, progress cards; no points, no idempotency | shared scoring service, idempotent ids, offline-safe save, points dashboard, leaderboards |
| Sports | DB catalog, Georgian names only | localized `names` map; volleyball, badminton (plus taekwondo, MMA, general physical training) |
| Admin Web | platform/club pages (coaches, clubs, groups, compliance, payments…) | split Platform / Academy navigation; 6 new pages |
| Localization | ARB files are the source of truth since v1.4 (`tool/gen_arb.py` is stale and would drop 500+ strings) | strings added with `tool/add_l10n.py` (`tool/strings_v17.json`); the old generator now refuses to run |

## 2. Milestones

| # | Milestone | Commit |
|---|---|---|
| 1 | Tenant config, feature flags, scheduling engine, RSVP versioning, scoring, demo tenants | `7149cea` |
| 2 | Event RSVP UI (training + match), student events / maps / coach contact, points, leaderboards, consent | `2457f26` |
| 3 | Admin Web (organizations, settings, programs, rooms, calendar, reports), rules, Cloud Functions, tests | `b032ef7` |
| 4 | Functions parity tests, emulator rules tests, callable integration test, rule regressions fixed | `9146b0b` |
| 5 | Migration script, indexes, docs, simulator fixes, builds | final commit |

## 3. What was built

### Parent attendance confirmation (trainings and matches)

- The parent answers **will attend / will not attend / not sure yet**, with an
  optional reason. The current date, time and venue are shown before the
  buttons.
- A coach edit that changes date, time or place is a **material change**. It:
  - bumps `scheduleVersion`;
  - notifies parents;
  - posts a "გავეცანი" notice.
- Earlier answers are kept: they count as **needs reconfirmation** until a
  guardian answers for the new version. An append-only history keeps every
  answer.
- Acknowledging ("got it") and answering are separate actions. The app says
  so in the UI; acknowledging never sets "will attend".
- Several guardians: each answer is stored per guardian. The **latest answer
  is the child-level expectation**, the child counts once, and the coach sees
  when guardians disagree.
- The coach sees counters (confirmed / declined / not sure / no response /
  needs reconfirmation) and every guardian's answer per child.

### Coach attendance

- The training roster now works for **matches** too: present / absent /
  excused / not marked, bulk marking, editing, export.
- Parent responses are shown while marking.
- Coach attendance is stored separately from the RSVP (it never creates one).
- Parents see attendance in the child profile; students see only their own.
- Admin **Reports → Attendance** filters by date range and group.

### Student dashboard

- **Upcoming trainings and matches** (21 days), each with:
  - time, venue name and address;
  - **map with a marker** and **directions** (Apple/Google Maps);
  - cancelled, rescheduled and location-changed flags.
- **Coaches** with their public profile (name, the sports and groups they
  coach).
- **Contact coach**, mediated by the parent. The student picks a topic; only
  the guardians are notified. They open the existing parent–coach chat and
  mark the request done. There are no phone numbers, no student ↔ coach
  messages, and still no group chat for students.
- A future direct-messaging design would need guardian authorization,
  safeguarding, moderation and a reviewed privacy policy (not built).

### Brain Academy progress

- A result is validated and saved with a client-generated id (idempotent,
  offline-safe). Points, best scores, accuracy, levels, badges and weekly
  totals are **computed from stored results**, and the dashboard updates live.
- **Progress tab:**
  - total points, completed games, points this week;
  - a 7-day chart;
  - per game: points, accuracy, highest level, best score;
  - the last 10 games;
  - badges and coach challenges.
- Results persist across restarts (demo: SharedPreferences; Firebase:
  Firestore offline cache, synced on reconnect).
- Totals are derived from append-only results, so concurrent devices can't
  conflict.

### Multi-academy SaaS

- See [multi-tenant-architecture.md](multi-tenant-architecture.md).
- **Platform Super Admin:**
  - create organizations;
  - plan, status, allowed modules, limits;
  - assign admins (claims);
  - tenant health;
  - sports catalog.
- **Organization admin:**
  - branding (ka/en/ru names, colour, logo URL, contacts);
  - enabled modules within what the platform allowed;
  - language, time zone, booking buffer, leaderboard settings;
  - coaches;
  - programs (sport, ages, coaches, groups, room, capacity, status);
  - rooms and the schedule;
  - reports.
- Feature flags are enforced in the UI, demo backend, rules and functions.
- A user can belong to several organizations; the app has an academy switcher
  with branding.

### Organization leaderboards

- See [leaderboard-policy.md](leaderboard-policy.md).
- Off by default, platform-allowed, organization-enabled, and per-child
  guardian consent (revocable).
- Pseudonyms or first name + initial; same age band; minimum number of
  participants.
- No cross-organization board. Server-side ranking with deterministic ties.

### Room scheduling

- See [room-scheduling.md](room-scheduling.md).
- Interval-overlap checks, buffer, opening hours (also past midnight),
  capacity, maintenance, unavailable rooms, coach and group double-booking.
- Transactional callables with per-room-day locks.
- Recurring bookings checked all-or-nothing within a 26-week window.
- Edit this occurrence or this and later; cancel; drag to move.
- Times are UTC instants, interpreted in the organization's time zone
  (Asia/Tbilisi by default).
- Rooms and trainings are one schedule (`eventId` ↔ `roomId`).

### New sports

- Volleyball (ფრენბურთი / Волейбол) and badminton (ბადმინტონი / Бадминтон),
  plus taekwondo, MMA and general physical training.
- All sport names are localized from the database (`Sport.names`) on every
  screen that shows a sport: clubs, map filters, child and student profiles,
  payments, certificates, programs, rooms, calendar filters.
- No sport list is hardcoded in screens.

### Demo mode

- **Tianeti Sports School / თიანეთის სპორტსკოლა:**
  - premium plan;
  - Hall A and Hall B;
  - volleyball, badminton and football programs;
  - recurring bookings for ±3 weeks, plus a maintenance block;
  - a rescheduled training with one confirmed and one needs-reconfirmation
    answer, and a child with two guardians;
  - attendance history;
  - Brain Academy plays;
  - four consented children on the leaderboard (including the demo student Luka).
- **Mtskheta Youth Academy:** the second tenant, which books the same
  wall-clock slot without conflict, to show isolation.
- **New demo accounts:**
  - Tianeti admin and Mtskheta admin (Admin Web);
  - Tianeti parent and volleyball coach (mobile).

## 4. Verification (all run locally)

| Check | Result |
|---|---|
| `dart format -l 120`, `flutter analyze` | no issues |
| `flutter test` | **383 passed** (318 before + 65 new in `test/v17/`) |
| `cd functions && npm test` | **229 passed** (incl. 15 new in `test/v17.test.ts`) |
| Rules on the emulator (Firestore + Storage) | **185 passed** (incl. 18 new in `v17.rules.test.js`) |
| Functions smoke on the emulator | **43/43 steps** |
| v1.7 callable integration on the emulator | **7/7 steps** (concurrent bookings, series all-or-nothing, cross-tenant, flags, org creation + claims, consent/leaderboard) |
| Migration script on the emulator | dry run writes nothing; apply additive; rerun idempotent; orphans reported |
| Admin Web build + browser | built; Tianeti admin calendar at 1400 px and 420 px; conflict warning with Save disabled |
| iOS simulator (iPhone 16 Pro, debug, demo) | Tianeti parent: academy chip, acknowledgment banner → rescheduled training → reconfirm + "გავეცანი" |
| Android APK | `~/Desktop/SportParentApp-Beta-v1.7.apk` (see release checklist) |

### Problems found while verifying (fixed)

- **Simulator:** the schedule-change chat line reused the existing series key
  `scheduleChanged` and showed an empty date. It now has its own key
  `eventRescheduled` with ka/en/ru text.
- **Simulator:** the "waiting for your confirmation" banner opened the chat.
  For schedule changes it now opens the event, where the answer and the
  acknowledgment are.
- **UI tests:**
  - the "needs reconfirmation" pill overflowed the child row on 320 px (it now
    has its own line);
  - the contact-coach sheet overflowed at 320×640 (it now scrolls);
  - admin dropdowns overflowed with long Georgian/Russian labels;
  - the new-organization dialog didn't load the sports list;
  - the demo admin login lacked the new academy admins.
- **Rules regressions:**
  - coach queries by event id lost a rule path (restored for trainings and
    matches);
  - a duration-only edit was treated as a reschedule (now only date, time or
    place count).
- **v1.6 tests:** they assumed only the demo student had Brain Academy
  results; they were adjusted to count that student's results.

## 5. Not done or limited (needs a decision or external setup)

- No production deployment, App Check, or real push/SMS (by instruction).
- Time zones: only fixed-offset zones are offered. DST zones need a tz library.
- Brain Academy anti-cheat is limited to bounds, caps and plausibility
  (client-side games).
- Not checked: Android on a physical device or emulator (only the APK build
  and its contents were checked); iPad and the student screens on the
  simulator (covered by widget tests at iPad sizes, not by hand); sound on
  real devices (from v1.6.1).
- The Georgian and Russian v1.7 strings need a native-speaker review.
- Drag-and-drop in the calendar is implemented and validated, but tested only
  through the server path (widget tests use tap flows).
