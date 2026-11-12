# Beta v1.4: progress and status

Legend:
- **✅ Verified**: implemented and covered by tests that were run locally (and, where noted, checked in a running build).
- **🟢 Implemented, Firebase path untested in production**: the Firebase code exists and the backend passes the emulator suites, but nothing has run against a real Firebase project.
- **🔧 Requires production configuration**
- **⛔ Not implemented**

v1.4 builds on v1.3.1; every earlier feature is kept and the earlier suites still pass.

## What already existed before v1.4 (inspected first)

| Area | State in v1.3.1 |
|---|---|
| Coach → parent phone | `getParentPhone` callable (one direction only); shown in the group roster |
| Parent → coach phone | Demo only. In Firebase mode the coach's phone was never returned (no backend path) |
| Read receipts | Timestamp-based (`members/{uid}.lastReadAt` compared with message times), and the Firebase version could not work: the rules only let a member read their own `members` doc |
| Video | Placeholder icon only; the app had no video player |
| Downloads | Disabled on purpose ("Downloading is disabled to protect children's privacy") |

## Status by area

| Area | Status | Notes |
|---|---|---|
| **Contacts**: coach → parents/guardians of the coach's active groups (name, relation when recorded, phone, call); parent → approved coach(es) of the child's groups | ✅ demo · 🟢 Firebase | `getGroupContacts` and `getContactPhone` callables, live checks on every call. Entry points: chat header, student roster row, group roster, student details (progress), child profile → group ("Contact coach") |
| Calls only on tap (`tel:` via url_launcher) | ✅ | Checked on Android: the dialer opens pre-filled and no call is placed |
| Privacy: parents never see other parents; pending/suspended coaches get nothing; archived groups and ended memberships revoke access; no phones in public profiles or logs | ✅ unit + rules + smoke + demo tests | Admins get no contact list through this path |
| Relation to child (`children.guardianRelations`) | ✅ shown when recorded | 🔧 There is no in-app editor yet; the field can be set only by admins or the server |
| **Read receipts**: per message, unique parent accounts, recipient snapshot at creation | ✅ demo · 🟢 Firebase | `chats/{g}/receipts/{m}` (sender-only), `…/msgReads/{uid}` (create-only, server time) |
| Read only when visibly shown (≥ 60 % of the bubble, app in the foreground, route current); never from a push or the chat list; 600 ms debounced batch writes; own marks loaded so nothing is rewritten | ✅ widget + demo tests | Offline: the mark fails without a fake success and is retried when the message is seen again |
| Coach: "Seen by X of Y parents" on own messages, details screen (not seen / seen / acknowledged, times), real-time | ✅ | Admins cannot read receipts (rules test) |
| **Acknowledgments**: "Require acknowledgment" in the composer; parent button "გავეცანი" → "დადასტურებულია"; distinctive marker in chat; inbox entry (`ackRequested`); dashboard banner (group names only, no message text) | ✅ demo + Android device · 🟢 Firebase | Each parent once; reading ≠ acknowledging; server time; immutable `msgAcks` + `auditLog` `chat.acknowledge`; kept when the parent leaves or the message is deleted. No automatic reminders |
| **Video player**: play/pause, ±10 s, interactive progress bar, current/total time, fullscreen, loading, buffering, error + retry (re-requests the source), pause in background, released when leaving | ✅ widget tests (fake engine) · ✅ Android device (real player: plays, seeks) | Uses `video_player` 2.14. Firebase: `getMediaUrl` 15-minute URL, refreshed on retry or expiry; URL never logged |
| **Downloads** (photo + video): notice that a downloaded copy cannot be revoked, progress, cancel, retry, success, file name + extension, share/save sheet (no storage permission requested) | ✅ widget tests · ✅ Android device (progress → share sheet with `sportparent_video_post-2.mp4`) · 🟢 Firebase | `getMediaDownload`: active membership, not hidden by moderation, consent-confirmed post, group media policy on; 5-minute attachment URL; `mediaDownloads` log + audit `media.download` |
| Medical documents stay out of the media module | ✅ | Downloads accept only `mediaPosts`; certificates keep `getCertificateUrl` |
| **Admin web**: per-group "parents may download" switch (audited), media download audit page | ✅ demo | Contact permissions need no admin setting (they follow membership). Read history is deliberately not exposed to admins. Abuse reports: unchanged moderation |
| **Languages** ka / en / ru: 60 new strings | ✅ l10n tests (same keys/placeholders, scripts, no hardcoded text) + responsive sweep in ru and en at 320 px | Russian machine-assisted, as before |
| **Demo mode**: second guardian (father) for Luka, fictional 555-range numbers, receipt/ack data, sample video (`assets/demo/sample_video.mp4`, Flutter's public video_player example clip, no people) and a generated sample photo, basketball group with downloads off | ✅ | No Firebase in demo mode |

## Tests (run locally on 2026-11-12)

| Suite | Result |
|---|---|
| `dart format`, `flutter analyze` | no issues |
| `flutter test` | **246 passed**: 18 v1.4 repository tests, 7 v1.4 UI flows, responsive sweep extended with the v1.4 screens |
| Functions build, typecheck, `npm test` | **206 passed** (13 new) |
| Rules emulator tests | **150 passed** (14 new) |
| Functions smoke test (emulators) | **40 steps passed** (3 new) |

## Known gaps / not verified

- **iOS:** the simulator build launches, but video playback, downloads and the share sheet were not tried by hand on iOS (the simulator tool needs permission in its panel). The iPad was not checked by eye; layouts are covered by the responsive widget sweep only.

- The emulator smoke test checks the target of the download URL but cannot fetch it: the Storage emulator guards its direct link with rules. Production uses V4 signed URLs (Service Account Token Creator role) 🔧.
- Downloads in Firebase mode stream to the app's temporary folder and hand the file to the share/save sheet. Saving straight into the photo library would need a gallery plugin plus a permission (not added on purpose).
- Plan videos (training plans) still use the v1.3 path (≤ 10 MB); the new player is used for coach media posts.
- Video transcoding / thumbnails ⛔ (unchanged).
- Collection-group indexes for `msgReads` / `msgAcks` and the `receipts` / `mediaDownloads` indexes are in `firestore.indexes.json` but not deployed 🔧.
