# Backend (Firebase)

Firebase backend for the Sport Parent App: Firestore + Cloud Storage security
rules, Cloud Functions (2nd gen, TypeScript) and the tests that cover them.

| Path | What |
| --- | --- |
| `firebase.json`, `.firebaserc` | Project config. Default project `demo-sport-parent` (the `demo-` prefix keeps the emulators fully offline). |
| `firestore.rules`, `storage.rules` | Security rules — default deny. |
| `firestore.indexes.json` | Composite indexes used by the app and functions. |
| `functions/` | Cloud Functions (firebase-functions 6, firebase-admin 13, Node 22, region `europe-west1`, schedules in `Asia/Tbilisi`). |
| `functions/src/lib/` | Pure business logic (dates, recipient selection, reminder decisions, certificate status, templates, SMS providers). Unit-tested. |
| `functions/src/i18n/ka.ts` | Georgian SMS + push templates. |
| `functions/test/` | Vitest unit tests for `src/lib`. |
| `functions/test-integration/emulator.smoke.mjs` | End-to-end smoke test of triggers/callables in the emulator (v1.0 + the v1.1/v1.2 flow). |
| `functions/scripts/grant-platform-admin.mjs` | One-off bootstrap of the first platform admin (emulator by default). |
| `functions/.secret.local` | Emulator-only **placeholder** values for the SMS secrets (never real credentials). |
| `rules-tests/` | Rules tests (`@firebase/rules-unit-testing` + vitest) and a local, pinned `firebase-tools`. |

## Collections

Field names are the contract with the Flutter app. "Server-managed" fields are
written only by Cloud Functions (Admin SDK); rules reject client writes.

- **users/{uid}** — `role` (`parent`/`child`/`coach`/`admin`), `firstName`, `lastName`, `phone`, `createdAt`, `lastContext {childId?, sportId?, groupId?}`, `fcmTokens[]`, `coachStatus` (coaches: `pending`/`approved`/`rejected`/`suspended`/`revoked`; only `approved` counts as a coach in the rules), `clubIds[]`, `sportIds[]` (coach), `smsConsentAt?`, `dataConsentAt`, `photoPath?` (`profiles/{uid}/avatar.jpg`), `privacy? {profilePhotoVisible, analyticsConsent}`, `notificationPrefs` (keys = notification types: `newTraining`, `trainingChanged`, `trainingReminder`, `chatMessage`, `certificateExpiry`, `newPhotos`, `paymentReminder`, `paymentSms`, `newMatch`, `matchChanged`, `matchReminder`, `groupInvite`, `inviteAnswered`, `attendanceRecorded`, `feedbackAdded`, `announcement`, `newMedia`, `scheduleChanged`; a missing key means **on**). Server-managed: `coachStatusReason`, `adminRole` (`platform`/`club`, UI mirror only), `adminClubIds`. Readable by the owner (contains the phone), platform admins, and club admins for coaches assigned to their clubs. No other keys are accepted by the rules.
  - Child accounts: `role: "child"`, created server-side/admin only; linked through `children/{id}.userId`. For rules to resolve the child, set `users/{uid}.lastContext.childId` to the linked child id.
- **publicProfiles/{uid}** — `firstName`, `lastName`, `role`. Server-managed mirror of `users` (trigger `syncPublicProfile`); readable by any signed-in user. Use this to show names; never read other users' `users` docs.
- **children/{childId}** — `firstName`, `lastName`, `birthDate`, `parentIds[]`, `userId?`, `sportIds[]`, `groupIds[]`, `photoConsent`, `mediaConsent` (same value as `photoConsent`), `mediaConsentAt?`, `status` (`active`/`pendingParent`), `createdByCoachId?`, `photoPath?` (`childPhotos/{childId}/avatar.jpg`). A coach-created (invite) child has `parentIds: []`, `status: pendingParent` and only name + birth date; `status`/`createdByCoachId` are server-managed. Plus **`coachIds[]`** (addition, server-managed): union of `coachIds` of every group the child is in — this is what lets approved coaches read the child and their certificate metadata. `groupIds`/`coachIds` are server-managed; `parentIds` and `userId` are immutable from the client after create.
- **sports/{id}** `name, icon` · **clubs/{id}** `name, address, phone?, sportIds, location (geopoint), geohash` · **venues/{id}** `clubId?, name, address, location, geohash, sportIds, type (stadium|hall|field)`. Public (guest) read.
- **groups/{groupId}** — `clubId, sportId, coachIds[], name, ageMin, ageMax, memberChildIds[], parentIds[], scheduleNote?, createdBy, status (active|archived), inviteCode, createdAt?`. Server-managed: `parentIds` (trigger `onGroupWritten`) and `inviteCode` (6 chars `[A-HJ-NP-Z2-9]`, assigned by `createGroup` / `onGroupWritten`; a client-created group sends `inviteCode: ''` or omits it).
- **groupCodes/{code}** — `{groupId, createdAt}` unique index for invite codes. Server only (no client access).
- **trainings/{trainingId}** — `groupId, venueId, startAt, durationMin (15..300), focus[] ⊆ {technique,speed,physical,ball}, description, photoUrls[] (storage paths like trainingPhotos/{groupId}/x.jpg, not public URLs), status (scheduled|cancelled|moved|done), createdBy, updatedAt, previousStartAt?`, cancel fields `cancelReasonCode? (illness|weather|venueBusy|other), cancelReason? (5–300 chars), cancelledAt?, cancelledBy?`, series fields `seriesId?, occurrenceDate? ('YYYY-MM-DD' Tbilisi), detached (bool)`. Server-managed: `reminderSentAt`, `seriesId`, `occurrenceDate`; on a `startAt` change of a one-off (or detached) training the trigger sets `status: "moved"`, `previousStartAt` and clears `reminderSentAt`. Series occurrences have deterministic ids `{seriesId}_{YYYYMMDD}`; editing one occurrence in the app must set `detached: true`.
- **medicalCertificates/{certId}** — `childId, uploadedBy, storagePath ("medical/{childId}/{certId}"), issuedAt, validUntil, consentAt, status (valid|expiring|expired)`. Server-managed: `status` (recomputed on create and daily; `expiring` = within 14 days), `notified14At`, `notified3At`, `notified0At`.
- **certificateAccessLog/{id}** (top level) — `certId, childId, userId, at, action` (`view`, `delete`, `file_deleted`). Admin read only.
- **chats/{groupId}/messages/{messageId}** — `senderId, senderName, senderRole, text, attachments[]?, createdAt` (`createdAt` must be `serverTimestamp()`), `type` (`text`/`announcement`/`system`), `pinned`, `hidden?` (server, moderation), `reportCount?` (server). System messages are written by functions with `senderId: "system"`, `senderRole: "system"` and deterministic ids (`system_training_{id}_cancelled`, `system_match_{id}_new`, `system_match_{id}_cancelled`, `system_match_{id}_moved_{startMs}`).
- **chats/{groupId}/members/{uid}** — `{lastReadAt}` written by the member themself.
- **userUnread/{uid}** — `{total, byGroup: {groupId: n}, updatedAt}`. Server-managed, owner read.
- **membershipRequests/{id}** — `parentId, childId, clubId, groupId?, status (pending|approved|rejected), createdAt, childName?, source? (request|code)` (`createdAt` must be `serverTimestamp()`). `joinGroupByCode` creates them with `source: "code"` and `groupId` set.
- **payments/{paymentId}** — `childId, parentId, groupId, sportId, amount, currency "GEL", dueDate, status (pending|paid|cancelled), reminders {d5SentAt?, d1SentAt?}, paidAt?, cancelledReason?, updatedBy?, updatedAt?`, plus `createdAt`, `planId` and `period` (`YYYY-MM`, generated payments; id `{planId}_{childId}_{YYYY-MM}`). `parentId` becomes `"deleted"` when the payer deletes their account.
- **paymentAudit/{id}** — `paymentId, groupId, clubId, from, to, actorId, cancelledReason, at`. Server only (`onPaymentWritten`).
- **paymentPlans/{id}** — `groupId, sportId, amount, currency, dayOfMonth (1..28), active, createdBy`.
- **smsLog/{id}** — `at, phone (masked, e.g. +995*****3456), status (mocked|sent|failed|skipped), provider, providerResponse, paymentIds[], kind (d5|d1)`, plus `parentId`, `segments`, `chars`. Admin read only.
- **groupAuditLog/{id}** — `groupId, at, action, childrenAdded, childrenRemoved, coachesAdded, coachesRemoved`. Admin read only.

### v1.1 / v1.2 collections

The authoritative schema is [`docs/data-model-v1.2.md`](data-model-v1.2.md). Backend specifics:

- **invites/{id}** — as in the contract. Written only by callables. `phone` is E.164 (empty for the search flow when the addressed parent has no phone on file). `parentId` is set when the phone (or, for an existing child, the child's first parent) resolves to exactly one registered parent.
- **matches/{id}** — as in the contract, plus server-managed `reminder1dSentAt`, `reminder2hSentAt` (a client may keep or drop them, never set them).
- **venues/{id}** — plus `createdBy`, `verified`, `createdAt?`.
- **trainingSeries/{id}** — contract fields plus `parentSeriesId` (split-off series) and server-managed `generatedUntil`.
- **rsvps/{trainingId}_{childId}**, **attendance/{trainingId}_{childId}**, **feedback/{id}** (plus `coachName`) — as in the contract.
- **notifications/{sha1(userId|dedupeKey)}** — `userId, type, category, title, body, route, args{}, childId, groupId, createdAt, read, dedupeKey`. Categories: trainings (newTraining, trainingChanged, trainingReminder, scheduleChanged), matches (newMatch, matchChanged, matchReminder), invitations (groupInvite, inviteAnswered), attendance (attendanceRecorded, feedbackAdded), payments (paymentReminder, paymentSms), chat (chatMessage), certificates (certificateExpiry), announcements (announcement, newPhotos, newMedia). Ordinary chat messages are push-only (unread counters cover them); announcements go to the inbox.
- **mediaPosts/{id}** — contract fields plus `coachName` and the **server-managed `readerIds[]`** (= coachIds ∪ parentIds of all `groupIds`, plus the owner), recomputed by `onMediaPostWritten` and on every membership/coach change by `onGroupWritten`. Rules and Storage use it for read access (query with `where('readerIds', 'array-contains', uid)`).
- **reports/{id}** — contract fields plus `preview?` (≤ 200). The `createReport` callable uses a deterministic id per reporter+target.
- **auditLog/{id}** — contract fields plus `actorName`.
- **clubs/{id}** — plus `status`, `adminIds[]` (server), `description?`, `createdAt`. **coachClubs/{coachId}_{clubId}** — `{coachId, clubId, status (active|removed), updatedAt}` (server).
- **accountRequests/{id}** — `uid, type (delete|export), status (pending|processing|done|rejected), createdAt, completedAt?, result?` (export: `exports/{uid}/{id}.json`; delete: counts), `error?`.
- **rateLimits/{uid}_{bucket}** — `{uid, bucket, hits[] (ms), updatedAt}`; buckets `invites` 30/24 h, `reports` 20/24 h, `joinCode` 20/24 h, `accountRequests` 5/24 h, `childSearch` 200/24 h, `createGroup` 20/24 h. Server only.

## Security rules summary

Default deny. Admin = custom claim `admin == true` (never a client-writable field).

- **Guest (no auth)**: read `sports`, `clubs`, `venues`. Nothing else.
- **users**: read/update only own doc. Self-registration only as `parent` (no `coachStatus`) or `coach` with `coachStatus: "pending"`; `child`/`admin` are never self-assignable. `role`, `coachStatus`, `createdAt`, `dataConsentAt` can never change from the client; an approved coach cannot change `clubIds`. `dataConsentAt` is required at create.
- **Phones**: only in `users/{uid}` (owner only). Coaches get a parent's phone through the `getParentPhone` callable, which checks shared group membership. Parents never see each other's phones.
- **children**: parents in `parentIds` read/update/delete; create must include the caller in `parentIds` and no groups. Child account reads its own child doc. Approved coaches read children in their groups (`children.coachIds`).
- **groups**: parents in `parentIds`, approved coaches in `coachIds`. Coaches may only *remove* members; additions happen via approved membership requests. Create/delete: admin.
- **trainings**: read by group parents, approved group coaches and the group's child accounts. Create only by an approved coach of the group with `createdBy == uid`, `status == "scheduled"`, valid `focus`, `durationMin` 15..300. Update by an approved coach of the group (cannot change `groupId`, `createdBy`, `reminderSentAt`). Delete: admin (cancel instead).
- **chat**: members = parents in `group.parentIds` + approved coaches in `group.coachIds`. Child accounts can never read or write. `senderId == uid`, `senderRole` must equal the caller's role, messages immutable, sender may delete own.
- **medicalCertificates**: metadata readable by the child's parents and approved coaches of a group containing the child. Create only by a parent of the child, with `consentAt` and `storagePath == "medical/{childId}/{certId}"`. No client update. Delete by a parent (the file is then deleted by `onCertificateDeleted`).
- **Storage `medical/**`**: no client read at all. Write by a parent of the child (`image/jpeg`, `image/png`, `application/pdf`, < 10 MB); delete by a parent. Files are opened only through `getCertificateUrl`.
- **Storage `trainingPhotos/{groupId}/**`**: write by approved coach of the group (images < 10 MB); read by group parents and coaches.
- **payments**: parent reads own (`parentId == uid`); approved coach of the group reads and may update only `status`/`paidAt`. Create/delete: admin/functions.
- **paymentPlans**: approved group coach reads/creates (`createdBy == uid`) and updates `amount`/`dayOfMonth`/`active`.
- **smsLog, certificateAccessLog, groupAuditLog**: admin read only; no client writes.

### v1.1 / v1.2 rules

Helpers: `isPlatformAdmin()` (= claim `admin == true`), `isClubAdmin(clubId)` (claim `clubAdmin` list contains the id), `validCancelTransition()`. A coach whose `coachStatus` is `suspended`/`revoked` is not an approved coach, so every coach-only path (groups, children, trainings, chat, media, attendance, …) closes for them immediately.

- **Club admins** read groups, trainings, matches, series, membership requests, media posts, reports, auditLog and paymentAudit of their clubs, and the `users` docs of coaches assigned to those clubs. They have **no direct read of children or medical certificates** (most restrictive choice; they get counts via `adminStats`). They may edit their club's details but not `adminIds`/`status`.
- **groups**: an approved coach may create a group in a club listed in their `clubIds` (club not archived) with `coachIds == [uid]`, `createdBy == uid`, `status: active`, no members and an empty/absent `inviteCode`. `inviteCode` is never client-writable (not even by a platform admin).
- **children**: parents cannot set `status`/`createdByCoachId` (create must be `active`, no coach); `photoPath` must be the child's own avatar path. The creating coach can read a coach-created pending child (name + birth date only).
- **invites**: read by the addressed parent (`parentId == uid`) and approved coaches of the group; all writes via callables. (The contract's "or phone matches their verified phone" is honoured by `respondInvite` via the auth token's `phone_number`, not by the read rule.)
- **trainings / matches**: changing `status` to `cancelled` requires `cancelReasonCode ∈ {illness, weather, venueBusy, other}`, `cancelReason` 5–300 chars and `cancelledBy == uid`. Clients cannot create series occurrences (`seriesId` must be null on create) nor change `seriesId`/`occurrenceDate`. Matches: approved group coach creates/updates (`clubId` must equal the group's club; reminder flags untouchable); group parents, coaches, the group's child accounts and club admins read.
- **trainingSeries**: approved group coach creates (`status: active`, `createdBy == uid`, `clubId` = group's club, `parentSeriesId` must be a series of the same group) and updates (not `groupId`/`clubId`/`createdBy`/`parentSeriesId`); weekdays ⊆ 1..7 (1–7 entries), `startTime` `HH:mm`, dates `YYYY-MM-DD`. No client delete — end a series with `status: ended` / `endDate`.
- **rsvps**: id must be `{trainingId}_{childId}`; parent of the child, `parentId == uid`, child is a member of the training's group, training not cancelled and `request.time < startAt`; delete likewise before start. Read: parents of the child and approved coaches of the group.
- **attendance**: id `{trainingId}_{childId}`; only an approved coach of the training's group, child must be a member, `markedBy == uid`; delete = unmark. Read: parents of the child and group coaches.
- **feedback**: approved coach of a group containing the child creates (`coachId == uid`, ratings ⊆ {technique, discipline, teamwork, effort, improvement} with integer values 1–5, comment ≤ 500, `visibleToParent == true`); the author may edit ratings/comment; parents read and never write.
- **chat**: `type` from clients is `text` or `announcement` (announcement and `pinned: true` only for approved group coaches; `system` never); `hidden`/`reportCount` cannot be set; approved group coaches may update `pinned` only. **Hidden messages remain readable by members; the app filters `hidden == true`** (keeps list queries simple). `members/{uid}`: only the member writes their own `{lastReadAt}`. `userUnread/{uid}`: owner read.
- **notifications**: owner reads; owner may only flip `read` from false to true; no client create/delete.
- **mediaPosts**: create by an approved coach of **every** listed group (1–5 groups), `coachId == uid`, `consentConfirmed == true`, `clubId` = the first group's club, `storagePath`/`thumbPath` under `media/{uid}/{postId}/`. No client update (`hidden`, `reportCount`, `readerIds` are server-managed); the owner deletes. Read: owner, platform/club admin, or a parent / approved coach in `readerIds`.
- **payments**: parents never write. The group coach may change only `status`, `paidAt`, `cancelledReason` and `updatedBy`/`updatedAt`; `updatedBy`, when present, must be the caller. **paymentAudit**: read by group coaches, the club admin of `clubId`, platform admins.
- **reports**: a group member creates their own `open` report (`clubId` must be the group's club); read by the reporter, club admins of `clubId` and platform admins; updates via `moderate` only. The client path has no rate limit — the app should use the `createReport` callable (rate-limited); see *Known gaps*.
- **auditLog**: platform admins read all, club admins entries with their `clubId`; append-only, server only.
- **sports**, **clubs** create/delete, **venues** verify: platform admin. **venues** create: approved coach with `verified == false`, `createdBy == uid`.
- **accountRequests**: owner creates `{uid, type: delete|export, status: pending, createdAt: serverTimestamp()}`; owner and platform admins read; server-only updates.
- **invites, groupCodes, rateLimits, coachClubs (write), userUnread (write)**: no client writes; `groupCodes` and `rateLimits` not even readable.

Storage additions: `profiles/{uid}/avatar.jpg` (owner writes `image/jpeg` ≤ 1 MB; any signed-in user reads), `childPhotos/{childId}/avatar.jpg` (parent of the child writes an image ≤ 1 MB; parents and approved coaches of the child read), `media/{coachId}/{postId}/{file}` (owner, approved coach, after the post doc with `coachId == uid` exists; images < 10 MB, videos < 100 MB; read by the owner or a parent/approved coach in the post's `readerIds`), `exports/**` (no client access).

Notes for the app:
- List queries must be provably safe, e.g. `children where parentIds array-contains uid`, `groups where parentIds array-contains uid` (parents) or `where coachIds array-contains uid` (coaches), `trainings where groupId == X`, `payments where parentId == uid`.
- Rules evaluate *current* membership, so removing a child from a group revokes that family's and coach's access immediately (after the trigger updates `parentIds`/`coachIds`).

## Cloud Functions

All in `europe-west1`; schedules use `Asia/Tbilisi`.

| Function | Type | Purpose |
| --- | --- | --- |
| `onTrainingWritten` | Firestore `trainings/{id}` written | create → `newTraining`; status→cancelled or `startAt` changed → `trainingChanged` (also sets `status: moved`, `previousStartAt`, clears `reminderSentAt`); `photoUrls` grown → `newPhotos` (only parents with a child in the group who has `photoConsent == true`). Recipients: `group.parentIds` with role `parent`, honouring `notificationPrefs`. |
| `sendTrainingReminders` | every 15 min | 2-hour reminders; `reminderSentAt` claimed in a transaction before sending. |
| `certificateExpiryCheck` | daily 09:00 | Recomputes status; pushes parents at ≤14 days, ≤3 days and on expiry; each stage once (`notified14At/3At/0At`, claimed in a transaction). |
| `onCertificateCreated` | Firestore create | Computes `status` server-side. |
| `onCertificateDeleted` | Firestore delete | Deletes the storage file, logs `file_deleted`. |
| `getCertificateUrl` | callable `{certId}` | Auth + parent/approved-coach check, writes `certificateAccessLog` (`view`), returns `{url, expiresAt}` — a V4 signed URL valid 5 minutes (emulator: direct emulator URL). |
| `deleteCertificate` | callable `{certId}` | Parent only; deletes file + metadata, logs `delete`. |
| `onChatMessageCreated` | Firestore create | Push to approved group coaches + group parents except sender; never child accounts. |
| `onGroupWritten` | Firestore `groups/{id}` written | Maintains `group.parentIds`, each member child's `groupIds`/`coachIds`/`sportIds`, writes `groupAuditLog`. |
| `onMembershipRequestUpdated` | Firestore update | On `approved`: verifies child/parent/club, adds the child to `group.memberChildIds`. |
| `onChildDeleted` | Firestore delete | Removes the child from groups and deletes all its certificates + files. |
| `syncPublicProfile` | Firestore `users/{uid}` written | Mirrors name/role into `publicProfiles`. |
| `getParentPhone` | callable `{parentUid}` | Approved coach sharing a group with that parent → `{phone}`. |
| `setCoachStatus` | callable `{uid, status, reason?}` | Platform admin, or club admin when the coach's `clubIds` intersect theirs. `status`: approved/rejected/suspended/revoked; `reason` (≥ 5 chars) required for all but approved → `coachStatusReason`. auditLog `coach.*`. |
| `deleteAccount` | callable | Deletes children solely owned by the caller (with all certificates/files, membership requests, RSVPs, attendance, feedback, child avatars, linked child accounts), unlinks shared children, anonymises payments and RSVPs (`parentId: "deleted"`), deletes notifications, invites addressed to the user, `userUnread`, the profile avatar and exports, the user + public profile, then the auth user. Chat messages stay in the group. |
| `onUserDeleted` | Auth user deleted (**1st gen** — 2nd gen has no auth delete trigger) | Same cleanup, idempotent. |
| `sendPaymentReminders` | daily 10:00 | `status == pending` payments; Tbilisi calendar-day diff to `dueDate`: 5 → d5 (skipped if the payment was created later than 5 days before due), 1 → d1. Claims `reminders.d5SentAt/d1SentAt` in a transaction **before** sending. One combined SMS per parent per due day. SMS only with `smsConsentAt`, a phone and `paymentSms != false`; push if `paymentReminder != false`. Every attempt is logged in `smsLog` with a masked phone. |
| `generateRecurringPayments` | monthly, 1st 06:00 | For each active `paymentPlans` doc, creates a payment per member child with id `${planId}_${childId}_${yyyy-MM}` via `create()` (idempotent), with `period`. Payer = first entry of `child.parentIds`. |

### v1.1 / v1.2 functions

| Function | Type | Purpose |
| --- | --- | --- |
| `createGroup` | callable `{clubId, sportId, name, ageMin, ageMax, scheduleNote?}` → `{groupId, inviteCode}` | Approved coach assigned to the active club; caller becomes the only coach; invite code assigned immediately. Rate limit 20/24 h. |
| `onGroupWritten` (extended) | Firestore | Also assigns a missing invite code (`assignInviteCode`: unique via `groupCodes/{code}` in a transaction), removes the code index when a group is deleted, and refreshes `mediaPosts.readerIds` when parents/coaches change. |
| `createInvite` | callable `{groupId, childId}` or `{groupId, pendingChild: {firstName, lastName, birthDate, parentPhone}}` → `{inviteId, childId}` | Approved coach of the (active) group. Existing child (search flow; active) or a new pending child (`status: pendingParent`, `parentIds: []`, `createdByCoachId`). Resolves `parentId` by phone — **never links anything**. Inbox + push (`groupInvite`) to a registered parent, otherwise SMS through the existing provider gating (mock unless `SMS_SENDING_ENABLED=true`), logged in `smsLog` (`kind: invite`, masked phone). Rate limit 30/24 h per coach. |
| `revokeInvite` | callable `{inviteId}` | Coach of the group; `sent` → `revoked`; deletes the unused coach-created pending child. |
| `respondInvite` | callable `{inviteId, accept, linkedChildId?, mediaConsent}` | Only the addressed parent (`parentId`, or verified `phone_number` when unresolved). One transaction: accept + `linkedChildId` (one of the caller's children) → that child joins, pending child deleted; accept without link → caller becomes parent of the pending child (`status: active`) or, for an existing-child invite, their child joins; decline → `declined`, unused pending child deleted. Records `mediaConsent`/`photoConsent`/`mediaConsentAt`. Notifies the coach (`inviteAnswered`). |
| `searchChildren` | callable `{groupId, query}` → `{results: [{childId, firstName, lastName, birthYear}]}` | Approved coach of the group; ≥ 2 chars; prefix match on first/last name (Firestore range queries, Latin capitalisation variant); max 20; excludes pending children and members; no parent/contact/health fields. Rate limit 200/24 h. |
| `joinGroupByCode` | callable `{code, childId}` → `{status, groupId, groupName, requestId?}` | Parent of the child; creates a pending `membershipRequests` doc (`source: code`, `groupId` set) approved by the coach as in v1.0. Rate limit 20/24 h (code guessing). |
| `leaveGroup` | callable `{groupId, childId}` | Parent of the child removes it from the group; `onGroupWritten` revokes coach/media access. |
| `onTrainingWritten` (extended) | Firestore | Notifications go through `notify()` (inbox + push). Cancellation pushes the reason and posts a `system` chat message. Series-managed occurrences (seriesId set, not detached) do not send per-occurrence new/moved/schedule-change pushes. |
| `onMatchWritten` | Firestore `matches/{id}` | create → `newMatch` + system message; cancelled → `matchChanged` with reason + system message; `startAt` changed → `status: moved`, `previousStartAt`, reminder flags cleared, `matchChanged` + system message. |
| `matchReminders` | every 15 min | 1 day and 2 hours before; `reminder1dSentAt`/`reminder2hSentAt` claimed in a transaction (`runMatchReminders(now)` exported for tests). |
| `onChatMessageCreated` (extended) | Firestore | `updateUnread`: increments `userUnread/{uid}` (`total`, `byGroup.{groupId}`) for every member except the sender; announcements are forced `pinned: true` and go to the inbox (`announcement`); system messages are not pushed again. |
| `onChatMemberWritten` | Firestore `chats/{g}/members/{uid}` | New `lastReadAt` → that group's counter set to 0, total recomputed. |
| `onSeriesWritten` | Firestore `trainingSeries/{id}` | Reconciles occurrences (`lib/series.ts`, mirrors the app's `RecurrenceEngine`): 8-week horizon, deterministic ids, never past/detached/cancelled/done; vanished dates are cancelled (`other`, "განრიგი შეიცვალა") when they have RSVPs/attendance, deleted otherwise; schedule-change cancellations are restored if the date is covered again. Split-off series (`parentSeriesId`) adopt the parent's occurrences from their start date (ids kept); the parent leaves those dates to the child. Sends ONE `scheduleChanged` notification per create/rule change (deduped by a hash of the rule). |
| `extendTrainingSeries` | daily 03:00 | Re-syncs every active series (rolls the horizon). `runExtendTrainingSeries(now)` exported. |
| `splitTrainingSeries` | callable `{seriesId, fromDate, draft}` | Optional server-side "edit this and future": ends the old series, creates the child in one batch and reconciles child then parent. The app's own two-write flow (update old + create child with `parentSeriesId`) is handled by `onSeriesWritten`. |
| `onPaymentWritten` | Firestore `payments/{id}` | On a status change: `paymentAudit` + auditLog `payment.status` (actor = `updatedBy` or `unknown`). |
| `onMediaPostWritten` | Firestore `mediaPosts/{id}` | Maintains `readerIds`; on create notifies group parents (`newMedia`); on delete removes `media/{coachId}/{postId}/`. |
| `onMediaUpload` | Storage object finalized | Re-validates `media/**` uploads (image < 10 MB / video < 100 MB, post exists with that coach) and deletes invalid files. |
| `getMediaUrl` | callable `{path}` (or `{postId, thumb?}`) → `{url, expiresAt}` | Live membership check for `media/…`, `trainingPhotos/{groupId}/…`, `chatAttachments/{groupId}/…`; hidden posts only for the owner/platform admin. 15-min V4 signed URL (emulator: direct link). |
| `createReport` | callable `{targetType, targetPath, groupId?, reason, note?, preview?}` → `{reportId, created}` | Reporter must be a member of the content's group; 20/24 h; one open report per reporter+target; increments the target's `reportCount`. |
| `moderate` | callable `{reportId, decision: hidden\|kept}` | Platform admin or club admin of the report's club: sets `hidden` on the message/post (training photo: removed from `photoUrls`, file kept), resolves all open reports of the target, auditLog `moderation.decide`. |
| `adminStats` | callable `{}` | `{parents, children, coaches, clubs, activeGroups, upcomingTrainings, upcomingMatches, pendingCoaches, pendingRequests, openReports}` via `count()`; club admins get values scoped to their clubs (parents/children = distinct members of their groups). |
| `setAdminRole` | callable `{uid, role: platform\|club\|null, clubIds}` | Platform only. Sets claims (`admin` / `clubAdmin`, other claims kept), mirrors `users.adminRole/adminClubIds` and `clubs.adminIds`; cannot demote yourself. auditLog `role.set`. The user must refresh their ID token. |
| `upsertClub` | callable `{clubId?, name, address, lat, lng, sportIds, phone?, description?}` → `{clubId}` | Create: platform only (`status: active`, `adminIds: []`). Update: platform or club admin of that club. Stores `location` as GeoPoint + `geohash`. auditLog `club.create`/`club.update`. |
| `archiveClub` | callable `{clubId, archived}` | Platform only. auditLog `club.archive`. |
| `assignCoach` | callable `{clubId, coachId, assign}` | Platform or club admin of the club: `coachClubs/{coachId}_{clubId}` + `users.clubIds`. auditLog `club.update`. |
| `upsertSport` | callable `{id?, name, icon, category, ageMin?, requiresMedicalCert, active, order}` | Platform only. auditLog `sport.upsert`. |
| `updateGroup` | callable `{groupId, name?, status?, coachIds?}` | Platform / club admin of the group's club (coachIds must be approved coaches of that club); an approved coach of the group may change name/status only. auditLog `group.update`. |
| `requestAccountDeletion`, `requestDataExport` | callable `{}` → `{requestId}` | Create (or return the open) `accountRequests` doc; 5/24 h. |
| `onAccountRequestCreated` | Firestore create | delete → `cleanupUserData` + auth deletion; export → `exports/{uid}/{id}.json` (user, children, certificate **metadata only**, RSVPs, attendance, feedback, own payments, requests, invites, notifications; no FCM tokens, storage paths or phone numbers of invites). auditLog `account.*`. Requests created directly by the client are processed the same way. |
| `getExportUrl` | callable `{requestId}` → `{url}` | Owner of a finished export; 15-min signed URL (emulator: direct link). |
| `getCertificateUrl` (extended) | callable | Also writes auditLog `certificate.access`. |

`notify()` (`functions/src/notify.ts`) is the single path for user notifications:
it creates `notifications/{sha1(userId|dedupeKey)}` with `create()` (a repeat of
the same event is neither stored nor pushed again), then pushes to the users
whose `notificationPrefs[type]` is not `false` (invitations are always pushed).
Training, match, series, certificate, payment-reminder, invite, announcement and
media notifications use it.

Delivery semantics: reminders are at-most-once — if a provider call fails after
the claim, it is logged (`status: failed`) and not retried automatically.

Push in the emulator (or with `PUSH_DISABLED=true`) is logged, not sent.

## Running locally

Prerequisites: Node 20+ (22 recommended), Java 17+. Nothing is installed
globally; `firebase-tools` is a local devDependency of `rules-tests/`, pinned to
**13.35.1** because firebase-tools 14+ requires JDK 21 for the emulators.

```bash
# Functions: build + unit tests
cd functions
npm install
npm run build
npm test            # vitest, pure logic in src/lib
npm run typecheck   # also type-checks tests

# Security rules tests (Firestore + Storage emulators)
cd ../rules-tests
npm install
npx firebase emulators:exec --only firestore,storage --project demo-sport-parent "npm test"
# (same as: npm run test:emulator)

# Functions end-to-end smoke test (functions + firestore + storage + auth emulators)
npm run smoke:functions

# Interactive emulators with UI (http://127.0.0.1:4000)
npx firebase emulators:start --project demo-sport-parent --config ../firebase.json
```

Scheduled functions are not triggered by the emulator (no Pub/Sub emulator);
the smoke test calls their exported run functions (`runPaymentReminders`,
`runRecurringPayments`, `runExtendTrainingSeries`) directly; `runMatchReminders`
is exported the same way.

The smoke test honours `FUNCTIONS_EMULATOR_ORIGIN` (default
`http://127.0.0.1:5001`) so it can run against emulators on other ports. If a
port in `firebase.json` is taken by another process, run the suites with a
throw-away config outside the repo that uses other ports (the rules tests read
the emulator hosts from the env vars that `emulators:exec` sets).

What the suites cover: `functions/test` (pure logic: series generation and
split, attendance stats/achievements, notification ids/categories, rate
limiter, invite codes and the respondInvite decision, cancel reasons, match
reminders, unread maths, media validation, moderation targets, admin scopes and
claims, payment audit, data export, child search, geohash);
`rules-tests/test/v12.rules.test.js` (one test per attack scenario plus happy
paths for every new collection); the smoke test's v1.2 flow (createGroup →
createInvite → respondInvite with an existing child → series occurrences with
deterministic ids and one summary notification → RSVP/attendance and a weekday
change cancelling the RSVP occurrence → paymentAudit → unread counters →
createReport + moderate hides the message → match system messages → admin
callables → data export).

### First platform admin

```bash
cd functions
node scripts/grant-platform-admin.mjs <uid>            # emulator (default: demo-sport-parent, 127.0.0.1:9099/8080)
node scripts/grant-platform-admin.mjs <uid> --revoke
# production — refuses unless BOTH flags are present, emulator env vars are unset
# and GOOGLE_APPLICATION_CREDENTIALS points to a service-account key:
node scripts/grant-platform-admin.mjs <uid> --production --project <real-project-id>
```

The script sets the `admin: true` claim (keeping other claims), mirrors
`users/{uid}.adminRole`, and writes an auditLog `role.set` entry. Everything
after that goes through `setAdminRole`.

Flutter: connect to the emulators with `useFirestoreEmulator('127.0.0.1', 8080)`,
`useStorageEmulator('127.0.0.1', 9199)`, `useAuthEmulator('127.0.0.1', 9099)`,
`useFunctionsEmulator('127.0.0.1', 5001)` and `FirebaseFunctions.instanceFor(region: 'europe-west1')`.
(Android emulator: host `10.0.2.2`.)

## Deploying (not done here)

1. Create the real Firebase project and add it: `npx firebase use --add` (from `rules-tests/` or with a local CLI).
2. Grant the functions runtime service account **Service Account Token Creator** on itself (needed by `getSignedUrl` for `getCertificateUrl`).
3. Create the secrets below (they are bound to `sendPaymentReminders`; deploy fails if they don't exist — dummy values are fine while SMS is disabled).
4. `npx firebase deploy --only firestore,storage,functions`.

### Secrets (Secret Manager)

| Secret | Used by |
| --- | --- |
| `TWILIO_ACCOUNT_SID` | `TwilioSmsProvider` |
| `TWILIO_AUTH_TOKEN` | `TwilioSmsProvider` |
| `SMS_HTTP_API_KEY` | `GenericHttpSmsProvider` (Bearer token) |

```bash
npx firebase functions:secrets:set TWILIO_ACCOUNT_SID
npx firebase functions:secrets:set TWILIO_AUTH_TOKEN
npx firebase functions:secrets:set SMS_HTTP_API_KEY
```

Admins: bootstrap the first platform admin with
`functions/scripts/grant-platform-admin.mjs` (see *First platform admin*),
then use `setAdminRole`.

### What needs real production configuration

| Item | Why |
| --- | --- |
| **Service Account Token Creator** on the functions runtime service account | V4 signed URLs in `getCertificateUrl`, `getMediaUrl`, `getExportUrl`. |
| SMS provider (`SMS_PROVIDER`, `SMS_SENDING_ENABLED=true`, sender id, secrets) | Payment reminders and invite SMS to unregistered phones. Off (mock) by default. Secrets are now also bound to `createInvite`. |
| FCM + APNs key (iOS) in the Firebase project | Push delivery (`notify()` / `sendPushToUsers`). Push is logged, not sent, in the emulator or with `PUSH_DISABLED=true`. |
| First platform admin | `grant-platform-admin.mjs --production --project …`. |
| Composite indexes | `firestore.indexes.json` (deployed with `firebase deploy --only firestore:indexes`). |
| Default Storage bucket + Storage → Firestore cross-service rules permission | Storage rules use `firestore.get` (`media`, `childPhotos`, existing paths); the console asks to grant it on first deploy. |

`functions/.secret.local` holds **placeholders only** so the emulator does not
try to reach Secret Manager for the bound SMS secrets.

### Decisions and known gaps (v1.1 / v1.2)

- `mediaPosts.readerIds` (server-managed) is added to the contract; Firestore and Storage read access use it so that `array-contains` queries work and revocation follows membership (it is recomputed on every group membership/coach change, so access ends seconds after removal, once the trigger runs). `getMediaUrl` always checks live membership.
- Hidden chat messages stay readable by members; the app must filter `hidden == true`. Hidden media posts are not served by `getMediaUrl` (except to the owner/platform admin).
- Club admins have no direct access to children or medical data; aggregate numbers come from `adminStats`.
- `trainingSeries` cannot be deleted by clients (end them). Clients cannot create series occurrences; the server generates them.
- A schedule-change cancellation (reason "განრიგი შეიცვალა", not detached) is reverted when the series covers that date again. This makes the app's two-write split robust when the parent update is processed before the child series exists.
- Reports created directly through the rules (allowed per the contract) are not rate-limited; the app should use `createReport`.
- Notification `type` values beyond the v1.0 enum (`newMatch`, `matchChanged`, `matchReminder`, `groupInvite`, `inviteAnswered`, `scheduleChanged`, `announcement`, `newMedia`) must exist in the app's `NotificationType` enum (agreed list). `attendanceRecorded` and `feedbackAdded` are valid categories/prefs but no function sends them yet.
- `searchChildren` is a platform-wide name-prefix search (as specified), returning only id, names and birth year.
- The `createInvite` existing-child path accepts any active child (found via `searchChildren`) and addresses the child's first parent.

## Enabling a real SMS provider

By default **no SMS is sent**: `MockSmsProvider` records the message and
`smsLog.status` is `mocked`. Real sending requires **both** env vars:

```dotenv
# functions/.env  (see functions/.env.example)
SMS_PROVIDER=twilio          # or "http" for a generic JSON gateway
SMS_SENDING_ENABLED=true
SMS_SENDER_ID=+1555...       # Twilio "From" number / gateway sender id
SMS_HTTP_URL=https://...     # only for SMS_PROVIDER=http
```

- `twilio` → `TwilioSmsProvider` (Twilio Messages REST API, Basic auth from the two Twilio secrets).
- `http` → `GenericHttpSmsProvider`: `POST SMS_HTTP_URL` with JSON `{to, text, sender}` and `Authorization: Bearer <SMS_HTTP_API_KEY>`. Adapt `functions/src/lib/sms/realProviders.ts` to the chosen Georgian gateway's payload.
- Both real providers are **stubs**: they are unit-tested against a fake `fetch` only, never against a live provider. Verify in the provider's sandbox first.
- If a real provider is selected but misconfigured, the function logs an error and falls back to the mock (nothing is sent).

SMS text: Georgian is sent as UCS-2 (70 chars per single SMS, 67 per part when
split). Templates live in `functions/src/i18n/ka.ts`; `smsLog.segments` records
the segment count per message.
