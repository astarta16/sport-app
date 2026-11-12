# Beta v1.3: progress and status

Legend:
- **✅ Verified**: implemented and covered by tests that were run locally (and, where noted, checked in a running build).
- **🟢 Implemented, Firebase path untested in production**: the Firebase adapter exists and the backend passes the emulator suites, but nothing has run against a real Firebase project.
- **🔧 Requires production configuration**: needs accounts or credentials we don't have.
- **⛔ Not implemented**

Contract: [data-model-v1.3.md](data-model-v1.3.md). Backend: [backend.md](backend.md) § v1.3. Every v1.2 feature is kept, and the v1.2 suite still passes.

## Status by area

| Area | Status | Notes |
|---|---|---|
| **Medical certificates**: upload (camera / file, JPG/PNG/PDF ≤ 10 MB), issue/expiry dates, consent, sport-specific or general, preview, replace (old one marked `replacedBy`), delete, statuses | ✅ demo · 🟢 Firebase | `CertificatePolicy.current` picks the applicable certificate for each sport |
| Certificates: coach view/download through a 5-minute link, sensitivity warning before download, audit `certificate.view` / `certificate.download`, access log visible to the parent | ✅ demo · 🟢 `getCertificateUrl {purpose}` | Admins are always denied, even when the same person is also a parent (server) |
| Certificates: admin compliance as counts only (valid / expiring / expired / missing per group) | ✅ | `adminCompliance` callable, scoped to the club admin's clubs |
| Certificate reminders at 14 / 3 / 0 days, de-duplicated, in the parent's language | ✅ functions tests + smoke (3-day) | `reminders.d14SentAt / d3SentAt / d0SentAt` |
| **Student roster**: group chips, search, sort (name / age / attendance / certificate), filters (certificate issues, attendance < 70 %), lazy list, certificate status | ✅ | `/students` |
| **Attendance**: draft marking per child and in bulk (rest present / all absent / all excused), Save / Discard, warning on leaving with unsaved changes, edit history note, summaries; RSVP shown separately | ✅ | `saveBatch` (single Firestore batch) |
| **Exports**: roster, training attendance sheet, monthly report as PDF or CSV; Georgian font embedded; privacy warning; timestamped file names; compliance status only when ticked | ✅ | CSV is UTF-8 with BOM (opens correctly in Excel). Shared through the system share sheet |
| **Training plans**: seasonal / monthly / weekly / exercise / homework; exercises with photo, video, PDF and https links; reorder; draft → published → archived; multi-group | ✅ demo · 🟢 Firebase | Server limit: at most 9 groups per plan (see backend.md) |
| Plans: publish notification once (`plan:{id}:published`), system chat message, parent view with self-reported progress, homework on the parent dashboard, coach sees views and completion | ✅ | Progress is labelled as self-reported, not as verified performance |
| Plans: private media; access revoked when the child leaves the group; https-only links (the server quarantines bad plans) | ✅ demo + rules/smoke | Links open externally, with a confirmation |
| **Internationalization ka / en / ru** (ka default): selector in the app and the admin web, persisted, independent of the device language, switches immediately, saved to `users.locale` | ✅ | 1,004 keys, all translated. Russian was machine-assisted; a native-speaker review is recommended |
| Localized server texts: push, inbox, SMS, system messages, reminders (`functions/src/i18n`) | ✅ functions tests | System chat messages carry `systemKey` / `systemArgs`, so each reader sees their own language |
| Localization checks: identical keys, matching placeholders, correct script per language, no ru → en fallbacks, no hardcoded Georgian/Russian in UI code | ✅ `test/v13/l10n_completeness_test.dart` | |
| **Payment proofs**: parent submits date, reference, note and receipt (≤ 10 MB) with upload progress → "Awaiting verification"; a parent claim never marks the payment paid | ✅ demo · 🟢 Firebase | |
| Payment review: only explicit reviewers (`paymentManagerIds`), club admins or platform admins; approve or reject (reason ≥ 5 characters); transactional, so a second decision fails; resubmission after a rejection; events and audit; notifications | ✅ | **Behaviour change:** coaches no longer change payment status unless a club admin made them a reviewer |
| Display states: pending · proof submitted · under review · paid · rejected · cancelled | ✅ | |
| **Admin web**: compliance, monthly attendance report, plan oversight, payment verification queue with receipt review, reviewer assignment per group, language setting; audit log extended | ✅ demo (widget tests + checked in a browser) · 🟢 Firebase | |
| **Demo mode**: payment reviewers, a submitted and a rejected proof, three plans with exercises and demo media, progress, a sport-specific certificate. Example flows 1–4 run as UI tests | ✅ | All data is fictional; demo mode never touches Firebase |
| Responsive: every new screen at 9 sizes, plus Russian and English at the narrowest layouts | ✅ widget tests | iPad simulator not checked by eye (no simulator access granted) |

## v1.2 gaps found and fixed during v1.3

- Parent payments had no child or sport filter. Filters were added.
- Coach "cancel payment" sent no reason, so it always failed validation. It now asks for the reason.
- The coach payment summary and the payment audit list were computed but never shown. Both are now displayed.

## Tests (run locally on 2026-11-11)

| Suite | Result |
|---|---|
| `flutter analyze` | no issues |
| `flutter test` | **215 passed**: the v1.2 suite, 13 v1.3 workflow/security tests, 9 l10n/export tests, 5 cross-role UI flows, and the responsive sweep extended with all v1.3 screens plus ru/en |
| Functions `npm run build`, `typecheck`, `npm test` | **185 passed** (55 new) |
| Rules emulator tests | **135 passed** (41 new); run on Firestore port 8181 because another project occupies 8080 |
| Functions smoke test (emulators) | **32 steps passed** (10 new) |

## v1.3.1 additions (2026-11-12)

| Item | Status |
|---|---|
| Add to calendar (`.ics`, UTC, 1-hour reminder, folded Georgian lines) on training and match detail; Calendar tab exports the next 60 days | ✅ unit + widget tests |
| Server `attendanceRecorded` / `feedbackAdded` notifications (localized, once per status) | ✅ functions + smoke · 🟢 production |
| Server chat lines for a moved training and for schedule create/change | ✅ functions + smoke · 🟢 production |
| Plan publish/archive audit names the actual actor (`updatedBy`, enforced by rules) | ✅ rules + smoke |

## Known gaps

- Video transcoding/thumbnails ⛔ (carried over from v1.2). Plan videos are capped by size only.
- Plan video playback in the app downloads at most 10 MB through Storage; larger videos need the `getPlanMediaUrl` signed-URL path in the client ⛔.
- Map layers for trainings and matches ⛔ (carried over from v1.2).
- Everything production-related 🔧: Firebase project, APNs/FCM, App Check, signed URLs (needs the Service Account Token Creator role), SMS provider, store signing, admin web phone sign-in.
