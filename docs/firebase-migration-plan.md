# Firebase migration plan: v1.6.x → v1.7

Nothing in this plan has been run against a real Firebase project. Everything
was executed only against the local emulator. **Do not migrate production
silently.** Every step below needs an explicit go-ahead and a backup.

## What changes in the data

| Data | Change | Needs a migration? |
|---|---|---|
| `clubs` | none (the club is the tenant) | no |
| `orgConfigs/{clubId}` | **new** | yes: legacy config per existing club |
| `clubs/{clubId}/orgMembers` | **new** | yes: built from groups (afterwards kept by `onGroupOrgMembers`) |
| `clubs/{clubId}/programs`, `rooms`, `bookings`, `roomLocks`, `leaderboardConsents` | new, start empty | no |
| `coachContactRequests` | new | no |
| `trainings`, `matches` | optional `scheduleVersion` (default 1), `previousVenueId`, `roomId` | no (defaults apply) |
| `rsvps` | optional `eventId`, `eventType` (default training), `scheduleVersion` (1), `guardianResponses`, `history` subcollection | no |
| `attendance` | optional `eventId`, `eventType` | no |
| `brainResults` | client-generated ids, `clientPlayedAt`; server adds `valid` | no |
| `sports` | optional `names` map; volleyball and badminton added | catalog upsert by a platform admin |

### Old records without an organization id

- Trainings, RSVPs and attendance resolve their tenant through `groups.clubId`.
- Matches, payments and plans already store `clubId`.
- A record whose group is missing or has no `clubId` is **reported** by the
  migration script and left untouched for a human decision. It stays readable
  under the old membership rules.

## Steps

### 1. Back up

```bash
gcloud firestore export gs://<backup-bucket>/pre-v17
```

### 2. Rehearse on staging (a copy of production data)

```bash
cd functions
node scripts/migrate-v17.mjs --production --project <staging-id>          # dry run: prints the plan
node scripts/migrate-v17.mjs --production --project <staging-id> --apply  # additive writes only
```

The script:

- creates the `orgConfigs` for existing clubs with the **legacy** feature set,
  so nothing a club used before is switched off and no restricted module is
  switched on;
- upserts `orgMembers` from groups and club admins;
- reports orphans.

It never rewrites existing documents and is idempotent (verified on the
emulator: dry run → apply → second apply creates nothing).

### 3. Deploy in this order (staging first)

1. **Indexes:** `firebase deploy --only firestore:indexes`. Wait until they are built.
2. **Functions:** `firebase deploy --only functions`. The new callables and
   triggers do no harm before the rules change.
3. **Migration script** (step 2) against the target project.
4. **Rules:** `firebase deploy --only firestore:rules,storage`. The new rules
   expect `orgMembers` for room and program reads.
5. **Catalog:** add volleyball and badminton (and names in ka/en/ru for every
   sport) through Admin Web → Sports, as a platform admin.
6. **Apps:** release the apps. Older app versions keep working:
   - RSVPs without the new fields are still valid;
   - attendance remains training-only for them.

### 4. Check

- the rules test suite on the emulator: `cd rules-tests && npm run test:emulator`;
- the integration test: `functions/test-integration/v17.integration.mjs`;
- a manual pass with a staging organization: create a room, create a booking,
  try a conflicting booking.

### 5. Roll back

- Rules and functions: redeploy the v1.6.1 tag.
- New collections can stay; old clients ignore them.
- Restore from the export only if data was damaged (not expected: all writes
  are additive).

## Production configuration still needed (not done locally)

- App Check for the new callables.
- A legal and privacy review of the leaderboard consent text and of student
  accounts before enabling `studentAccounts` or `leaderboards` for any real
  organization.
- Choose the organization time zones; the beta supports fixed-offset zones only.

## v1.8 → feature schema 2 (platform control)

Nothing here runs automatically; **no production migration was run**.

1. **Back up:** `gcloud firestore export gs://<bucket>/pre-v1.8` (staging
   first).
2. **Deploy** rules, indexes (`notifications` groupId+createdAt, `smsLog`
   clubId+at) and functions. Old documents keep working: the rules fall back
   to the coarse v1.7 lists and the scheduler skips v1.7 documents.
3. **Grant** the first platform admin (`grant-platform-admin.mjs`).
4. **Dry run:** `cd functions && npm run build && node scripts/migrate-v18.mjs
   --production --project <id>` — prints, per organization, the version
   bump, package derived from the plan and the implied features that will be
   persisted (payments → receipts / verification / reminders, …). Nothing is
   written.
5. **Apply** after review: add `--apply`. Each organization is upgraded in its
   own transaction (skipped if it changed after the plan), with a history
   entry `v1.8 feature schema migration`; built-in packages are created if
   missing. A JSON snapshot of the previous documents is written locally.
6. **Check:** Overview totals and alerts; one organization per package in the
   Features tab; `rules-tests` and `v18.integration.mjs` on the emulator.
7. **Roll back:** `node scripts/migrate-v18.mjs --rollback <snapshot.json>
   [--production --project <id>] --apply` restores the configuration
   documents and removes the migration history entries; redeploy the v1.7
   rules/functions if needed. No data is deleted by the migration itself.

Verified on the emulator: dry run writes nothing; apply upgrades and records
history; a second run is a no-op; rollback restores the v1.7 document.
