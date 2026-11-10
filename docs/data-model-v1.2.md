# Data model — v1.1 + v1.2 additions (contract)

This is the single contract shared by the Flutter app (demo + Firebase adapters),
Firestore/Storage rules and Cloud Functions. v1.0 collections stay as they are;
this file lists only additions and changes. Timestamps are Firestore `Timestamp`.
"server" = written only by Cloud Functions (Admin SDK); clients cannot write it.

## Roles and claims

| Concept | Source of truth | Notes |
|---|---|---|
| `users/{uid}.role` | `parent` \| `coach` \| `child` \| `admin` | `admin` is never client-assignable (create rule rejects it) |
| `users/{uid}.coachStatus` | `pending` \| `approved` \| `rejected` \| `suspended` \| `revoked` | server only (callable `setCoachStatus`) |
| `users/{uid}.coachStatusReason` | string? | server only |
| Custom claim `admin: true` | Platform admin | set only by `setAdminRole` callable / ops script |
| Custom claim `clubAdmin: [clubId…]` | Club admin scope | set only by `setAdminRole`; also mirrored to `users/{uid}.adminClubIds` (server) |
| `users/{uid}.adminRole` | `platform` \| `club` | mirror for UI only; rules use claims |

Club admin = claim `clubAdmin` non-empty. A club admin may act only on documents
whose `clubId` is in the claim list. Platform admin may act on everything.

## v1.1 changes

### groups/{groupId} (+)
- `inviteCode: string` — 6 chars `[A-HJ-NP-Z2-9]`, unique (server generates on create; `groupCodes/{code}` → `{groupId}` index, server only)
- `createdBy: uid`, `status: 'active' | 'archived'`
- Coach (approved, assigned to the club) may create a group in their club; `coachIds` must contain creator.

### children/{childId} (+)
- `status: 'active' | 'pendingParent'`
- `createdByCoachId: uid?`
- `photoPath: string?` (`childPhotos/{childId}/avatar.jpg`)
- `mediaConsent: bool` (alias of v1.0 `photoConsent`, both written for compatibility), `mediaConsentAt: Timestamp?`
- `coachIds` server managed (v1.0)
- A coach-created child has `parentIds: []`, `status: pendingParent`, and only
  `firstName`, `lastName`, `birthDate` — coach sees nothing else until a parent accepts.

### invites/{inviteId}
```
groupId, clubId, sportId, groupName
childId?            // existing child (search flow) or coach-created pending child
childFirstName, childLastName
phone               // E.164 parent phone (masked in UI except to the inviting coach)
parentId?           // set when the phone belongs to a registered parent (server)
status: 'sent' | 'accepted' | 'declined' | 'revoked'
createdBy: uid, createdAt
decidedAt?, decidedBy?
linkedChildId?      // child the parent chose on accept (duplicate prevention)
```
- Coach creates (callable `createInvite`) only for own group. Server resolves
  `parentId` by phone, sends push/mock-SMS. **No automatic linking by name/phone.**
- Parent reads invites where `parentId == uid` (or phone matches their verified phone).
- Accept (callable `respondInvite`): parent chooses `linkedChildId` = one of *their*
  children (to avoid a duplicate) or accepts the pending child (becomes parent of it).
  If they link an existing child, the coach-created pending child is deleted.
  Acceptance records `mediaConsent` choice and adds child to group.
- Join by code (callable `joinGroupByCode {code, childId}`) creates a
  `membershipRequests` doc (v1.0) with `source: 'code'` that the coach approves —
  or, if the parent accepts an invite, membership is immediate.
- Leave group: parent callable `leaveGroup {groupId, childId}` → removes membership, revokes coach access.

### users/{uid} (+) `photoPath: string?` → Storage `profiles/{uid}/avatar.jpg` (≤ 1 MB JPEG)

### chats/{groupId}/messages/{id} (+)
- `type: 'text' | 'announcement' | 'system'`, `pinned: bool`
- `status` client-only (sending/failed), never stored
- `hidden: bool` (server, moderation), `reportCount: number` (server)
- Only coaches may write `announcement`/`pinned`; `system` is server only.

### chats/{groupId}/members/{uid} `{ lastReadAt }` — owner writes own doc only
### userUnread/{uid} `{ total, byGroup: map }` — server (`updateUnread`), owner read

### mediaPosts/{postId}
```
coachId, groupIds[], clubId, type: 'photo' | 'video', storagePath, thumbPath?,
caption?, durationSec?, createdAt, hidden: bool (server), reportCount (server),
consentConfirmed: true (required)
```
Storage: `media/{coachId}/{postId}/{file}`; read via membership in any `groupIds`
(rules use `firestore.get` on the post). No public URLs; videos via signed URL callable.

### sports/{sportId} (+)
`category: 'team' | 'combat' | 'other'`, `ageMin: number?`, `requiresMedicalCert: bool`,
`active: bool`, `order: number`. New seed: MMA, ტაეკვონდო, თავისუფალი ჭიდაობა.

### trainings/{id} (+)
`cancelReasonCode: 'illness' | 'weather' | 'venueBusy' | 'other'?`, `cancelReason: string?` (5–300 chars, required when status=cancelled),
`cancelledAt?`, `cancelledBy?`, `seriesId?`, `occurrenceDate?: 'YYYY-MM-DD'` (Tbilisi), `detached: bool` (edited individually).

### matches/{matchId}
```
groupId, clubId, venueId, startAt, durationMin (default 90), opponentName,
matchType: 'friendly' | 'league' | 'tournament', homeAway: 'home' | 'away' | 'neutral',
description?, status: 'scheduled' | 'cancelled' | 'moved' | 'played',
cancelReasonCode?, cancelReason?, cancelledAt?, cancelledBy?, createdBy, updatedAt
```

### venues/{venueId} (+) `createdBy: uid?`, `verified: bool`, `geohash` — coaches may create
unverified venues; client shows existing venues within 200 m first.

## v1.2 additions

### trainingSeries/{seriesId}  (recurrence rule, stored separately from occurrences)
```
groupId, clubId, venueId, weekdays: int[] (1=Mon … 7=Sun), startTime: 'HH:mm' (Tbilisi),
durationMin, focus[], description, startDate: 'YYYY-MM-DD', endDate?: 'YYYY-MM-DD',
status: 'active' | 'ended', createdBy, createdAt, updatedAt, generatedUntil: 'YYYY-MM-DD'
```
- Occurrence id is deterministic: `{seriesId}_{YYYYMMDD}` → re-generation is idempotent.
- Generation horizon: 8 weeks ahead (scheduled function `extendTrainingSeries` daily; client
  in demo). Never generates before `startDate`, after `endDate`, or in the past.
- **Edit one occurrence** → that training gets `detached: true`; series regeneration never touches it.
- **Edit this and future** → series is split: old series `endDate = date-1`; new series from date.
  Future non-detached occurrences of the old series without attendance are deleted and
  re-generated from the new rule; those with RSVPs/attendance whose date still matches keep
  their id (deterministic id) and are updated in place; those whose weekday disappeared are
  **cancelled** (reason code `other`, "განრიგი შეიცვალა") rather than deleted so RSVPs stay explainable.
- Cancel one occurrence = regular cancel (reason required); it stays detached.
- One summary notification per series create/change (not one per occurrence).
- Tbilisi is UTC+4 with no DST (since 2005); all occurrence math uses wall-clock `YYYY-MM-DD` + `HH:mm` in Asia/Tbilisi.

### rsvps/{trainingId}_{childId}  (parent intent — never counted as attendance)
```
trainingId, groupId, childId, parentId, response: 'yes' | 'no' | 'maybe',
reason?: string (≤ 200), updatedAt
```
Parent of child (child in group) writes before training start; coach of group reads.

### attendance/{trainingId}_{childId}  (coach-recorded actual attendance)
```
trainingId, groupId, childId, status: 'present' | 'absent' | 'excused',
markedBy, markedAt, note?
```
"Not marked" = no doc. Only approved coach of the group writes. Parent of child reads.
Bulk marking = batched writes. Statistics: present / (present + absent + excused) for
`done` or past, non-cancelled trainings in a period.

### feedback/{feedbackId}  (coach → child progress)
```
childId, groupId, coachId, trainingId?, createdAt,
ratings: { technique?, discipline?, teamwork?, effort?, improvement? }  // 1–5
comment?: string (≤ 500, constructive), visibleToParent: true
```
Coach of child's group writes; parents of child + coaches of child's groups read.
Achievements are **computed** from attendance (no stored ranking): first training,
5/10/25/50/100 attended, perfect month (≥ 4 trainings, 100 %), 3-month streak.

### notifications/{id}  (persisted inbox, server-written)
```
userId, type, category: 'trainings' | 'matches' | 'invitations' | 'attendance' |
'payments' | 'chat' | 'certificates' | 'announcements', title, body, route, args{},
childId?, groupId?, createdAt, read: bool, dedupeKey
```
Doc id = sha1(`userId|dedupeKey`) → duplicates are impossible. Owner may only flip
`read`. Paginated by `createdAt desc`.

### payments (+)
`childId`, `sportId`, `period: 'YYYY-MM'?`, `cancelledReason?`; monthly docs use the
deterministic id `{planId}_{childId}_{YYYY-MM}` (v1.0 behaviour kept).
`paymentAudit/{id}` `{ paymentId, groupId, clubId, from, to, actorId, at }` — server only
(`onPaymentWritten`), readable by coach of group / club admin / platform admin.
Parents can never write payments.

### reports/{reportId}  (moderation queue)
```
targetType: 'chatMessage' | 'mediaPost' | 'trainingPhoto', targetPath, groupId, clubId,
reason: 'inappropriate' | 'privacy' | 'spam' | 'other', note?, reporterId, createdAt,
status: 'open' | 'resolved' | 'dismissed', decision?: 'hidden' | 'kept',
decidedBy?, decidedAt?
```
Any group member may create a report for content in their group (rate-limited: 20/day,
server). Admins (club-scoped) decide via callable `moderate`, which sets `hidden` on the target.

### auditLog/{id}  (append-only, server only)
```
action: 'coach.approve' | 'coach.reject' | 'coach.suspend' | 'coach.revoke' | 'role.set' |
'club.create' | 'club.update' | 'club.archive' | 'group.update' | 'sport.upsert' |
'payment.status' | 'moderation.decide' | 'certificate.access' | 'account.deleteRequest' |
'account.exportRequest',
actorId, actorRole, targetType, targetId, clubId?, details{}, at
```
Readable by platform admins (all) and club admins (their clubs). Nobody can update/delete.

### clubs/{clubId} (+) `status: 'active' | 'archived'`, `adminIds[]` (server), `createdAt`
### coachApplications — use `users` (role coach) + `coachClubs/{uid}_{clubId}` `{coachId, clubId, status}`

### accountRequests/{id}
```
uid, type: 'delete' | 'export', status: 'pending' | 'processing' | 'done' | 'rejected',
createdAt, completedAt?, result? (export: storage path `exports/{uid}/{id}.json`, signed URL only)
```
Deletion rules: children with another guardian are **unlinked** (uid removed from
`parentIds`), not deleted; children whose only guardian is the user are deleted together
with their medical certificates (Firestore + Storage), RSVPs, attendance, feedback and
avatars. Payments are anonymised (`parentId: 'deleted'`) and kept for club accounting.

### rateLimits/{uid}_{bucket}  (server only) — sliding counters for reports, invites, chat.

## Admin callables (all check claims server-side, write auditLog)
`adminStats`, `setCoachStatus {uid, status, reason?}`, `setAdminRole {uid, role, clubIds}`
(platform only), `upsertClub`, `archiveClub`, `assignCoach {clubId, coachId, assign}`,
`upsertSport` (platform only), `moderate {reportId, decision}`, `updateGroup`.

## Storage paths
| Path | Read | Write |
|---|---|---|
| `profiles/{uid}/avatar.jpg` | signed-in (group-related users, see rules) | owner, image ≤ 1 MB |
| `childPhotos/{childId}/avatar.jpg` | parent, coach of child | parent, image ≤ 1 MB |
| `media/{coachId}/{postId}/{file}` | members of post groups (via post doc) | coach owner, image ≤ 10 MB / video ≤ 100 MB |
| `exports/{uid}/…` | none (signed URL) | none |
| v1.0 paths unchanged | | |
