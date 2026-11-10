# Security and child-privacy review — beta v1.2

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

## Open items before production

1. App Check enforcement (Firestore, Storage, Functions).
2. A legal review of retention periods and of the 14–17 child-account policy (still disabled).
3. A penetration test against a staging project, with real Phone Auth.
4. Video transcoding worker, and server-side EXIF/geo stripping for photos.
5. The server does not yet send `attendanceRecorded` / `feedbackAdded` notifications (the demo does).
