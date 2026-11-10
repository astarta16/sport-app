# Beta v1.2 — progress and status

Legend:
- **✅ Verified** — implemented and covered by tests that were run locally (and, where noted, checked in a running build).
- **🟢 Implemented, not externally verified** — code exists for both demo and Firebase; the Firebase path was only checked by the emulator suites, never against a real project.
- **🔧 Requires production configuration** — needs credentials or accounts we don't have (Firebase project, APNs, SMS provider, signing).
- **⛔ Not implemented**

Contract for all new data: [data-model-v1.2.md](data-model-v1.2.md). Backend details: [backend.md](backend.md).

## Audit (start of v1.2)

The starting point was commit `5b62e9f`. The v1.0 spec was implemented (130 Flutter tests, 68 functions tests, 52 rules tests). The **v1.1 change document had not been implemented at all**:
- group invite codes and invitations, and coach-created pending children;
- profile photos;
- the chat icon in the top bar (chat was still a bottom tab);
- coach media posts;
- sport category, age and medical-certificate fields, plus MMA, Taekwondo and Freestyle wrestling;
- the mandatory cancel reason;
- matches;
- venue pins.

v1.2 therefore covers v1.1 as well. A `pre-v1.2` git tag marks the baseline.

## Status by area

| Area | Status | Notes |
|---|---|---|
| Groups: create, 6-char code, join by code (coach approves), leave | ✅ | callables `createGroup`, `joinGroupByCode`, `leaveGroup` |
| Invitations: search or manual entry, pending child, accept/decline, explicit link to an existing child (no duplicate), media consent at accept | ✅ | never auto-linked by name or phone |
| Navigation v1.1: Home · Calendar · Map · Profile; chat icon with unread badge in the top bar or rail | ✅ | `/parent/chat` redirects to `/chats` |
| Chat: unread counts, previews, pinned announcements, system messages, coach read receipts, pagination, retry on failure, report | ✅ | server `updateUnread` / `onChatMemberWritten` |
| Mandatory cancel reason (trainings + matches), shown in calendar and chat | ✅ | client validation + rules (5–300 chars) |
| Matches: create/edit/cancel/played, next-match card, calendar badge, reminders 1 day / 2 h | ✅ app · 🟢 reminders | `matchReminders` scheduled function |
| Venue pin + 200 m duplicate check | ✅ demo · 🟢 Firebase geohash query | |
| Sports catalog in DB (category, min. age, certificate requirement, active) | ✅ | admin-managed |
| Recurring schedules: weekly rule, deterministic ids `{series}_{YYYYMMDD}`, edit one / this-and-future, cancel one, end, overlap and duplicate guard, Tbilisi dates | ✅ | 13 engine tests + server `onSeriesWritten` / `extendTrainingSeries` |
| Parent RSVP (yes / no / maybe + reason) kept separate from coach-recorded attendance | ✅ | RSVP never counts as attendance (tested) |
| Coach attendance roster, bulk "rest present", group stats | ✅ | |
| Progress: totals, monthly rate and trend, achievements, coach feedback (5 categories), history; no rankings | ✅ | parents and the child's coaches only |
| Notification center: categories, read/unread, mark all, pagination, deep links switching child/group, per-category prefs, dedupe | ✅ demo · 🟢 Firebase inbox | persisted `notifications/{sha1(uid\|key)}` |
| Payments: parent filters/totals, coach cancel with reason, duplicate guard, `paymentAudit`, audit log | ✅ | no card payments (by design) |
| Coach media: photo/video publish to groups, consent confirmation, viewer, report, no download | ✅ demo · 🟢 Firebase upload/signed URL | video transcoding/thumbnails are server TODO 🔧 |
| Moderation queue: hide/keep, audit | ✅ | |
| Admin web (Flutter Web): platform/club admin, dashboard, coach verification, clubs, sports, groups, moderation, audit, admins | ✅ demo (widget tests + run in a browser) · 🟢 Firebase | separate entry `lib/main_admin.dart` |
| Server-side role enforcement (custom claims, club scope) | ✅ emulator rules tests (94) + functions | first platform admin via `functions/scripts/grant-platform-admin.mjs` |
| Account: profile photo, privacy settings, consents (SMS, media per child), data export, deletion with an impact preview (shared children unlinked) | ✅ demo · 🟢 Firebase | |
| Offline: banner, cached reads, writes fail with a clear error, retry, 25 s timeouts | ✅ demo (tested) · 🟢 Firestore cache | |
| Monitoring: redacted structured errors, categories, Crashlytics (opt-in), build/env reporting | ✅ redaction tests · 🔧 Crashlytics needs a Firebase project | |
| Environments demo / dev / staging / prod (`APP_ENV`); demo never touches Firebase | ✅ | |
| Responsive iPhone / iPad / Android, phone landscape, Split View | ✅ 9 sizes × all screens in tests; iPhone 17 Pro simulator checked by eye; iPad simulator access not granted (iPad layouts verified only by widget tests) | |

## Tests (run locally on 2026-11-10)

| Suite | Result |
|---|---|
| `flutter analyze` | no issues |
| `flutter test` | **185 passed**: v1.0 suite, 31 responsive tests extended with every new screen, 13 series-engine, 5 attendance/notification, 21 cross-role security and workflow, 5 UI flows, 9 admin web, 2 monitoring |
| Functions `npm test` | 130 passed |
| Rules emulator tests | 94 passed (run on firestore port 8181, because another project's `flutter run` occupies 8080) |
| Functions smoke test (emulators) | 22 steps passed |

## Builds

See the final section of [release-checklist.md](release-checklist.md).

## Known gaps

- Real Firebase project, APNs/FCM, Crashlytics, App Check, signed URLs (needs the Service Account Token Creator role) and an SMS provider: 🔧.
- Video transcoding (H.264 720p) and thumbnails: the client caps duration at 60 s and validates size; server transcoding is not implemented ⛔ (`onMediaUpload` validates type and size only).
- Admin web phone sign-in on the web needs reCAPTCHA / web Firebase config: 🔧. Demo admin login works.
- The "today / this week" map layers for trainings and matches (v1.1 §9) are not implemented ⛔. The map shows clubs and venues; trainings and matches open from the calendar and dashboard.
- Server `attendanceRecorded` / `feedbackAdded` notifications: the demo sends them, the Cloud Functions do not yet ⛔.
- Release signing for the stores: not configured; the APK uses the debug key 🔧.
