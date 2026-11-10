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
| `functions/test-integration/emulator.smoke.mjs` | End-to-end smoke test of triggers/callables in the emulator. |
| `rules-tests/` | Rules tests (`@firebase/rules-unit-testing` + vitest) and a local, pinned `firebase-tools`. |

## Collections

Field names are the contract with the Flutter app. "Server-managed" fields are
written only by Cloud Functions (Admin SDK); rules reject client writes.

- **users/{uid}** — `role` (`parent`/`child`/`coach`/`admin`), `firstName`, `lastName`, `phone`, `createdAt`, `lastContext {childId?, sportId?, groupId?}`, `fcmTokens[]`, `coachStatus` (coaches: `pending`/`approved`/`rejected`), `clubIds[]`, `sportIds[]` (coach), `smsConsentAt?`, `dataConsentAt`, `notificationPrefs` (keys: `newTraining`, `trainingChanged`, `trainingReminder`, `chatMessage`, `certificateExpiry`, `newPhotos`, `paymentReminder`, `paymentSms`; a missing key means **on**). Readable by the owner only (contains the phone). No other keys are accepted by the rules.
  - Child accounts: `role: "child"`, created server-side/admin only; linked through `children/{id}.userId`. For rules to resolve the child, set `users/{uid}.lastContext.childId` to the linked child id.
- **publicProfiles/{uid}** — `firstName`, `lastName`, `role`. Server-managed mirror of `users` (trigger `syncPublicProfile`); readable by any signed-in user. Use this to show names; never read other users' `users` docs.
- **children/{childId}** — `firstName`, `lastName`, `birthDate`, `parentIds[]`, `userId?`, `sportIds[]`, `groupIds[]`, `photoConsent`. Plus **`coachIds[]`** (addition, server-managed): union of `coachIds` of every group the child is in — this is what lets approved coaches read the child and their certificate metadata. `groupIds`/`coachIds` are server-managed; `parentIds` and `userId` are immutable from the client after create.
- **sports/{id}** `name, icon` · **clubs/{id}** `name, address, phone?, sportIds, location (geopoint), geohash` · **venues/{id}** `clubId?, name, address, location, geohash, sportIds, type (stadium|hall|field)`. Public (guest) read.
- **groups/{groupId}** — `clubId, sportId, coachIds[], name, ageMin, ageMax, memberChildIds[], parentIds[]`. `parentIds` is server-managed (trigger `onGroupWritten`).
- **trainings/{trainingId}** — `groupId, venueId, startAt, durationMin (15..300), focus[] ⊆ {technique,speed,physical,ball}, description, photoUrls[] (storage paths like trainingPhotos/{groupId}/x.jpg, not public URLs), status (scheduled|cancelled|moved|done), createdBy, updatedAt, previousStartAt?`. Server-managed: `reminderSentAt`; on a `startAt` change the trigger sets `status: "moved"`, `previousStartAt` and clears `reminderSentAt`.
- **medicalCertificates/{certId}** — `childId, uploadedBy, storagePath ("medical/{childId}/{certId}"), issuedAt, validUntil, consentAt, status (valid|expiring|expired)`. Server-managed: `status` (recomputed on create and daily; `expiring` = within 14 days), `notified14At`, `notified3At`, `notified0At`.
- **certificateAccessLog/{id}** (top level) — `certId, childId, userId, at, action` (`view`, `delete`, `file_deleted`). Admin read only.
- **chats/{groupId}/messages/{messageId}** — `senderId, senderName, senderRole, text, attachments[]?, createdAt` (`createdAt` must be `serverTimestamp()`).
- **membershipRequests/{id}** — `parentId, childId, clubId, groupId?, status (pending|approved|rejected), createdAt` (`createdAt` must be `serverTimestamp()`).
- **payments/{paymentId}** — `childId, parentId, groupId, sportId, amount, currency "GEL", dueDate, status (pending|paid|cancelled), reminders {d5SentAt?, d1SentAt?}, paidAt?`, plus `createdAt` and `planId` (generated payments).
- **paymentPlans/{id}** — `groupId, sportId, amount, currency, dayOfMonth (1..28), active, createdBy`.
- **smsLog/{id}** — `at, phone (masked, e.g. +995*****3456), status (mocked|sent|failed|skipped), provider, providerResponse, paymentIds[], kind (d5|d1)`, plus `parentId`, `segments`, `chars`. Admin read only.
- **groupAuditLog/{id}** — `groupId, at, action, childrenAdded, childrenRemoved, coachesAdded, coachesRemoved`. Admin read only.

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
| `setCoachStatus` | callable `{uid, status}` | Admin claim only; sets `coachStatus` to `approved`/`rejected`. |
| `deleteAccount` | callable | Deletes children solely owned by the caller (with all certificates/files, membership requests, linked child accounts), unlinks shared children, deletes user + public profile, then the auth user. Payments are kept as financial records; chat messages stay in the group. |
| `onUserDeleted` | Auth user deleted (**1st gen** — 2nd gen has no auth delete trigger) | Same cleanup, idempotent. |
| `sendPaymentReminders` | daily 10:00 | `status == pending` payments; Tbilisi calendar-day diff to `dueDate`: 5 → d5 (skipped if the payment was created later than 5 days before due), 1 → d1. Claims `reminders.d5SentAt/d1SentAt` in a transaction **before** sending. One combined SMS per parent per due day. SMS only with `smsConsentAt`, a phone and `paymentSms != false`; push if `paymentReminder != false`. Every attempt is logged in `smsLog` with a masked phone. |
| `generateRecurringPayments` | monthly, 1st 06:00 | For each active `paymentPlans` doc, creates a payment per member child with id `${planId}_${childId}_${yyyy-MM}` via `create()` (idempotent). Payer = first entry of `child.parentIds`. |

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
`runRecurringPayments`) directly.

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

Admins: set the custom claim with the Admin SDK, e.g.
`getAuth().setCustomUserClaims(uid, { admin: true })`.

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
