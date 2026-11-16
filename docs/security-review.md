# Security and child-privacy review: beta v1.3 (extends v1.2)

**Scope:**
- Firestore and Storage rules, Cloud Functions;
- the client `AccessPolicy` (mirrored by the demo backend);
- admin web, logging, offline behaviour.

**Data:** the app processes minors' personal data and medical certificates, so the default is **deny**.

## Model

| Principal | How identified | Rights |
|---|---|---|
| Parent | `users/{uid}.role == parent` | Own children (`children.parentIds`), groups of those children (`groups.parentIds`, server-maintained) |
| Coach | role `coach` **and** `coachStatus == approved` | Only assigned groups (`groups.coachIds`). Pending, rejected, suspended and revoked coaches see no child data |
| Child | role `child` | Child accounts are disabled by policy; children never have chat |
| Club admin | custom claim `clubAdmin: [clubIds]` | Admin operations scoped to those clubs; no child profiles or medical data |
| Platform admin | custom claim `admin: true` | Platform-wide admin operations; still no direct medical-file access |

Roles and claims are written only by server code (`setCoachStatus`, `setAdminRole`, the bootstrap script). The `users` create/update rules reject `role: admin`, `coachStatus` changes, `adminRole` and `adminClubIds` from clients.

## Verified attacks (all rejected)

Each was run against the Firestore/Storage emulator (`rules-tests`, 94 tests) and/or the demo backend (`test/v12/workflows_security_test.dart`), which enforces the same policy.

| Attempt | Where tested |
|---|---|
| Read another parent's child; RSVP for it; read its attendance/feedback | rules + demo |
| Coach of another group reads a child, training, attendance or roster | rules + demo |
| Read a medical certificate without access (files have no client read; access only via the 5-minute signed URL after a membership check, which is audited) | rules |
| Coach publishes media without `consentConfirmed`, or to a foreign group | rules + demo |
| Parent modifies a payment; payment cancelled without a reason | rules + demo |
| User sets own `coachStatus: approved`, `role: admin` or `adminRole` | rules + demo (`setCoachStatus` by non-admin) |
| Suspended coach reads group data or chat | rules + demo |
| Non-admin reads `auditLog` or `reports`; club admin of A reads B's | rules + demo |
| Club admin moderates another club's report, edits the sports catalog, archives a club, lists admins | demo + functions |
| Parent writes attendance; RSVP after the training started | rules + demo |
| Cancel a training/match without a reason or with a 4-character reason | rules + demo + UI |
| Client writes a `system` chat message; parent writes an announcement | rules + demo |
| Read private media after the child left the group (`mediaPosts.readerIds` recomputed; demo checks live membership) | rules + demo |
| Notification owner changes anything other than `read`; read another user's notifications | rules + demo |
| Child account accesses chat | rules + demo |
| Admin route opened by a parent (web) → permission-denied state; mobile admin-only users → "use the web" | widget tests |

## Privacy decisions

- **No automatic linking.** A coach-created child stays `pendingParent` with only first and last name until a parent accepts. On accept the parent explicitly links an existing child, and the duplicate is discarded. Phone or name matches are never used to link.
- **RSVP ≠ attendance.** Statistics use coach-recorded attendance only. No rankings or comparisons between children.
- **Media**:
  - parents' consent is per child, with a timestamp;
  - coaches must confirm consent at upload, and children without consent are listed;
  - no download in the app; videos play through signed URLs; hidden content is replaced by a placeholder.
- **Admins** see counts, not child identities. Moderation shows a ≤ 200-character text preview.
- **Phones:** coaches see parents' phones only in their own groups; parents never see each other's. Invite phones are masked in the UI.
- **Logging (`ErrorReporter`)** redacts phones, 6-digit codes, JWTs, emails, `medical/...` paths and chat text. Only *unexpected* errors are sent, and only with diagnostics consent (Crashlytics is off by default).
- **Offline** never shows a rejected action as successful: writes fail with "offline", and failed chat messages keep a retry. Medical files are never cached on the device; the app holds them in memory only while displayed.
- **Account deletion** unlinks shared children and deletes solely-owned children with certificates (Firestore + Storage), RSVPs, attendance, feedback and avatars. Payments are anonymised. Export contains metadata only, no medical file contents.

## Abuse prevention

Server rate limits per user per day: invites 30, reports 20, join-by-code 20, venue pins 20, export 3. Chat writes are limited in demo, and the backend chat counters use the `rateLimits` collection. Reports created directly through rules (allowed by the contract) bypass the rate limit; the app always uses the `createReport` callable.

## v1.3 additions

- **Financial permission is explicit.** Payment `status` changes only for coaches listed in the group's `paymentManagerIds`, club admins of the group's club, or platform admins. A coach of the group without that flag gets `permission-denied` (rules tests + `v13_workflows_test`). `verification`, `verifiedBy` and `verifiedAt` are server-only.
- **A parent's claim never marks a payment paid.** `submitPaymentProof` only sets `verification.state = proof_submitted`. Approval happens in one transaction that requires the proof to be `submitted` or `under_review`, so a second approval fails.
- **Receipts** (`receipts/{uid}/{proofId}/…`): only the owning parent can write them (JPG/PNG/PDF ≤ 10 MB, and the server re-checks type and size). Nobody reads them directly; `getReceiptUrl` returns a short-lived link to the parent or an authorized reviewer, and logs `receipt.view`.
- **Medical documents:** admins are denied based on their role alone. Downloads need a confirmation that warns about sensitive data and are logged separately from views. Replacing a certificate can only set `replacedBy`/`replacedAt`, pointing to another certificate of the same child.
- **Training plans:**
  - parents read published plans only through server-computed `readerIds`, which are recomputed on membership changes, so leaving a group revokes access (tested in the demo, rules and smoke suites);
  - plan media is private and read through `readerIds`;
  - links must be `https://`. The server quarantines a plan with a bad link (back to draft, no readers, `validationErrors`), and the app opens links externally only after a confirmation.
- **Exports** are generated on the device from data the coach can already read. Certificate status is excluded unless the coach ticks it, a privacy warning precedes every export, and no copy is uploaded anywhere.
- **Language preference** (`users.locale`) is the only new client-writable user field and is validated to `ka | en | ru`.
- **Demo mode** contains only fictional people, payments and receipts, and never initializes Firebase.

## v1.4 additions

- **Phone numbers** are never in public profiles and other users' `users` docs stay unreadable (rules test). Numbers come only from `getContactPhone` / `getGroupContacts`, which check current, active group relationships on every call: coach ↔ parents of the coach's groups, parent → approved coaches. Parents never see other parents; pending/suspended coaches and archived groups get nothing. Numbers are not logged and admins get no contact list through this path.
- **Read receipts** use a server snapshot of the recipients, taken when the message is created (`chats/{g}/receipts/{m}`). Marks (`msgReads`, `msgAcks`) can be created once, only by that parent, only while still a group parent, only when listed in the snapshot, with `request.time`, so a client clock is never trusted. They can't be updated or deleted. Only the sending coach, while still a coach of the group, can read them; other parents and admins cannot (rules tests). New members are not counted for older messages, and removed members can no longer mark.
- **Acknowledgments** are explicit: the button writes `msgAcks/{uid}`, and reading never does. The server writes an immutable `auditLog` entry (`chat.acknowledge`) and keeps the acknowledgment when a message is deleted.
- **Media downloads** go through `getMediaDownload` only. It checks active membership, moderation (hidden posts), the consent-confirmed post and the group media policy. It returns a 5-minute attachment URL and logs `mediaDownloads` + `media.download`. No public URL is stored. The app explains that a downloaded copy cannot be revoked and does not claim it can't be shared. Medical certificates are not reachable through this path.
- **Video playback** uses short-lived URLs that are re-requested on retry and never logged.

## v1.5 additions

- **Child-context conversations** (`childThreads/{childId}_{coachId}`): readable/writable only by the child's current guardians and by that coach while `children.coachIds` contains them (server-maintained). A parent can open a thread only with a current coach of the child. Messages: sender-bound, `createdAt == request.time`, immutable. Other parents, other coaches, admins and child accounts are refused (rules tests).
- **Match results** are server-only: clients cannot write `result` (rules tests). `recordMatchResult` checks the approved coach of the group, validates scores and the finish time against trusted server time, writes an immutable `resultHistory` entry and audit for every change, and notifies parents once.
- **Receipt download** is a separate audited purpose (`receipt.download`) with a short-lived attachment URL for the parent or an authorized reviewer only.
- **Student profile** shows coaches only data of their own active groups; medical documents remain behind `getCertificateUrl`.

## v1.6 additions

- **Student accounts** (role `child`, linked both ways: `children.userId` and the account's `lastContext.childId`) are enabled only in demo mode. In rules a student reads only: own child doc, trainings/matches of own groups, own attendance, published plans of own groups, own Brain Academy data and challenges of own groups. **Not**: full group docs (they hold other families' ids — the public projection is used), other children, chat, payments, medical certificates, users/phones, inbox (rules tests).
- **Brain Academy results** are create-only by the linked student, server-timed and bounded; readable by the student, the child's parents and coaches — not by admins or other parents. **Challenges** are written only by coaches of the group.
- No public leaderboards, no ads, no IQ claims; scores are labelled as practice points.

## v1.7 additions (multi-tenant SaaS)

Verified on the local emulator (rules tests `rules-tests/test/v17.rules.test.js`,
callable integration `functions/test-integration/v17.integration.mjs`) and in
the demo backend (`test/v17/v17_workflows_test.dart`). All attacks below were
rejected.

**Cross-tenant reads and writes**

- An organization admin reads or books another tenant's rooms, bookings,
  programs, members, reports or health.
- A Tianeti booking points at another tenant's room or group (`wrongTenant`).
- Mtskheta's admin reads Tianeti's room plan.

**Cross-tenant files**

- One organization's admin uploads to another organization's
  `orgs/{clubId}/branding`.
- Any other `orgs/**` path is used.

**Role escalation**

- An organization admin writes `orgConfigs` directly.
- An organization admin changes status, plan, allowed modules or limits, or
  assigns admins (all platform-only).
- An organization admin creates a new organization.
- An organization admin self-enables leaderboards or another module the
  platform did not allow.

**Feature-flag bypass**

- RSVP for an event in an organization where `attendance` is enabled but not
  allowed.
- Creating trainings or matches in a suspended organization, or with
  `trainings` off.
- Booking a room after the platform withdrew `roomScheduling`. Withdrawing a
  module also switches it off.

**Room bookings**

- Direct client writes to `bookings`, `rooms` or `roomLocks`.
- Overlapping, adjacent-within-buffer, maintenance, closed-room,
  outside-hours, over-capacity and coach double-booking requests.
- Three concurrent requests for one slot: exactly one succeeds.
- A series with one conflicting occurrence writes nothing.

**Child accounts**

- A student answers RSVPs, reads another child's attendance, reads chats,
  sets leaderboard consent, or contacts a coach outside their own group.
- Students never see phone numbers.
- Coach contact is mediated by the guardian: the coach is not notified and
  there is no student ↔ coach messaging.

**Guardian consent**

- Only a guardian of the child can grant or revoke it (not the child, a coach
  or the organization).
- Revocation removes the child immediately.

**Leaderboard privacy**

- No global or cross-organization board.
- A minimum number of participants is required.
- Ranking happens within the age band.
- Only pseudonyms or first name + initial are shown.
- Totals are computed on the server only.

**Attendance changes**

- Only an approved coach of the event's group marks attendance (training or
  match), and the event type must match.
- Students read their own records only.
- Admins of another club read nothing.

**Score abuse**

- Results are create-only, so a retry with the same id can't overwrite.
- Client-side totals are rejected.
- Repeat factors and a daily cap limit farming.

**Schedule versions**

- A reschedule without a version bump is rejected.
- A bump without a material change is rejected.
- An RSVP for a stale version is rejected.
- Room-linked trainings change time only through the booking callables.

**Organization deactivation**

- Every module is off and nothing new can be created.
- Data stays readable to its owners.

**Medical data** is unchanged: organization admins get counts only, never
certificates.

**Honest limits**

- Brain Academy results are produced on the device, so plausibility checks
  and caps limit the effect of fabricated results but can't rule them out.
- Production App Check for the new callables is still to do.

## Open items before production

1. App Check enforcement (Firestore, Storage, Functions).
2. A legal review of retention periods and of the 14–17 child-account policy (still disabled).
3. A penetration test against a staging project, with real Phone Auth.
4. Video transcoding worker, and server-side EXIF/geo stripping for photos.
5. ~~Server attendance / feedback notifications~~ (done in v1.3.1).
6. v1.7: legal/privacy review of leaderboard consent and student accounts before enabling them for any real organization; DST-aware time zones; App Check on the new callables.
7. Deploy the v1.4 indexes (collection-group `msgReads` / `msgAcks`, `receipts`, `mediaDownloads`).
