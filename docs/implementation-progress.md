# Implementation progress

Legend: ✅ implemented and verified (tests and/or run) · 🟡 implemented, not verified end-to-end · ⛔ blocked / not done

## Foundation
- ✅ Flutter project (iOS + Android), Git, `.gitignore` (no secrets / Firebase config committed)
- ✅ Feature-first clean architecture, Riverpod 3, GoRouter 18
- ✅ Design system (light + dark), reusable widgets, skeletons, empty/error states, micro-interactions
- ✅ Georgian l10n via ARB (344 keys), English ARB for phase 2, language switch in Settings
- ✅ Demo mode with in-memory backend enforcing `AccessPolicy`; never constructed in Firebase mode; release builds refuse demo unless explicitly allowed

## Authentication & onboarding (Phase 1)
- ✅ Onboarding slides, phone sign-in, OTP (demo code 123456), validation
- ✅ Registration: role → name + sports (+ clubs for coach) → consent (data + SMS)
- ✅ Coach approval gate (pending screen; admin callable; demo approve button)
- ✅ Child role disabled (policy flag), no chat for children (client + rules)
- 🟡 Firebase Phone Auth adapter — compiles; not run against a real project (no credentials)

## Parent experience
- ✅ Dashboard: greeting, child selector, sport tabs, next training (time, venue, coach, focus, directions), certificate status, payments, coach messages, photos
- ✅ lastContext persisted locally + remotely and restored on reopen
- ✅ Calendar (month view, day list, upcoming, status indicators)
- ✅ Child profiles: add, details, groups, pending requests, photo consent, history, delete
- ✅ Payments overview (pending / overdue / history)

## Coach experience
- ✅ Group selector, stats, membership requests (approve/decline), upcoming trainings, roster with ✅/⚠/❌ certificate status
- ✅ Create / edit / reschedule / cancel / mark done trainings; photos with consent check
- ✅ Roster: parents with phone (own group only), open certificate (audited), remove member (revokes access)
- ✅ Payments: mark paid / pending / cancelled, one-off charge (demo), monthly plans, idempotent monthly generation, SMS reminder job + log (mock)

## Maps & venues
- ✅ flutter_map + OSM, sport filters, search, venue/club cards, directions (Apple/Google Maps), club page, membership request, guest mode
- 🟡 Firestore geohash "nearby" query implemented; UI uses filter/search (no location permission requested yet)

## Chat (Phase 2)
- ✅ Group chat, real-time, timestamps, day separators, photo attachments, role badges, privacy note
- ✅ Authorization: group parents + approved coaches only; child accounts denied (demo + rules tests)

## Medical certificates (Phase 2)
- ✅ Consent screen → camera/gallery/PDF (JPG/PNG/PDF, ≤10 MB, image compression), issue/expiry dates
- ✅ Statuses valid/expiring/expired/missing; 14/3/0-day reminder logic (client + scheduled function)
- ✅ Private storage paths, no client read, 5-minute access via callable, audit log, revocation on group exit, deletion (also on account deletion)
- 🟡 Real V4 signed URLs need the Service Account Token Creator role (emulator returns a direct link)

## Notifications
- ✅ Types, per-category preferences (incl. SMS payment toggle), role-based recipient selection (tested), in-app inbox (demo)
- 🟡 FCM registration + foreground handling wired; no real push sent (no project / APNs key)

## Payments & SMS (Phase 3)
- ✅ Data model, statuses, plans, Tbilisi-day reminder planning (d5/d1, late-creation rule), combined SMS, idempotent claim, masked SMS log
- ✅ Abstract `SmsProvider`, mock provider; real providers only server-side behind `SMS_SENDING_ENABLED=true`
- ⛔ Real SMS provider untested (stubs only, no credentials) — by design

## Backend (Firebase)
- ✅ Firestore + Storage rules (default deny), indexes, emulator config (`demo-sport-parent`)
- ✅ Cloud Functions: training/chat/photo pushes, 2-hour reminders, certificate expiry, signed URLs, membership upkeep, public group projection, payments, account deletion, coach approval
- ✅ 68 functions unit tests · 52 rules emulator tests · 12-step functions smoke test

## Verification (2026-11-10, this machine)
- ✅ `flutter analyze` — no issues · `flutter test` — 99 passed
- ✅ Functions `npm test` — 68 passed · rules emulator tests — 52 passed · functions smoke — 12 steps passed
- ✅ `flutter build apk --debug` (demo) — built `app-debug.apk`
- ✅ `flutter build ios --simulator --debug` (demo) — built and launched on iPhone 17 Pro (iOS 26.1); onboarding, sign-in, coach dashboard, parent dashboard, calendar and map checked visually
- ⛔ Release / signed builds not attempted (no signing identity / keystore)
- 🟡 Known cosmetic: on the map, club pins can sit under venue pins at the same address

## Responsive / iPad (2026-11-10)
- ✅ Width-based breakpoints, `ConstrainedContent`, `ResponsiveGrid`, `MasterDetailLayout`, `showAdaptiveSheet`, `ScrollableFill`
- ✅ Adaptive shell: bottom bar → rail (≥ 600) → sidebar (≥ 1200); GoRouter branches, deep links and role guards unchanged
- ✅ Tablet parent dashboard (side column: payments/certificates, upcoming list, notifications) and coach dashboard (two columns, quick actions, group master list ≥ 1200)
- ✅ Master-detail chat, calendar (training detail pane on wide panes), map side panel, roster grid, two-column training form and profile, width-capped detail screens
- ✅ Overflow fixes found by the sweep (map attribution, roster rows, payment rows, onboarding/pending in landscape, text scale 1.4, hero card badges)
- ✅ 31 responsive widget tests: 9 window sizes × parent + coach screens, onboarding, sign-in, live resize, navigation, master-detail, back navigation
- 🟡 Not visually checked on an iPad simulator — iPad mini / iPad Pro 13 simulators were created but simulator access was not granted in this session
- ✅ Release APK (demo) built, copied to `~/Desktop/SportParentApp-release.apk`, installed and launched on the Pixel_6_API_33 emulator; demo parent dashboard loads

## Not done / follow-ups
- ⛔ Real Firebase project, `flutterfire configure`, APNs, deploy — needs your accounts
- ⛔ Attendance tracking, progress/evaluations, club admin web panel (spec Phase 3 items beyond payments)
- ⛔ Persisted notification inbox collection; parent-visible certificate access log in production
- ⛔ Inviting a second guardian; 14–17 child accounts (policy pending)
- ⛔ Online payment integration (spec: later)
