# Closed beta test plan — v1.2

Goal: confirm that the parent, coach and admin workflows work end to end, using synthetic data only. Demo builds need no accounts; staging builds need the Firebase staging project ([firebase-setup.md](firebase-setup.md)).

## Builds
- Android: `~/Desktop/SportParentApp-Beta-v1.2.apk` (demo, debug-signed).
- iOS: simulator build (demo). TestFlight requires signing — see [release-checklist.md](release-checklist.md).
- Admin web: `build/admin_web` (demo). Run it with `python3 -m http.server 8765` from that folder.

## Participants
2 clubs (club-1 Saburtalo football, club-2 Vake basketball), 3 coaches, 6–10 parents, 1 club admin, 1 platform admin.

## Scenarios (record pass/fail + device + screenshot)

| # | Role | Scenario | Expected |
|---|---|---|---|
| 1 | Coach | Create group → share code | 6-character code; parent request appears for approval |
| 2 | Coach | Invite a registered child by search; invite a new child manually | Parent gets the invitation; the coach sees only the name |
| 3 | Parent | Accept the invitation, linking the existing child + media consent | No duplicate child; the child appears in the group |
| 4 | Parent | Join with a code; leave a group | Request pending → coach approves; leaving removes coach access |
| 5 | Coach | Create recurring schedule Mon/Wed/Fri 18:00 | Occurrences for 8 weeks; one notification |
| 6 | Coach | Edit one occurrence; edit "this and future" (time change) | Only that one changes / future change; parent RSVPs remain |
| 7 | Coach | Cancel a training without a reason → with a reason | Blocked → cancelled; parents see the reason in calendar and chat |
| 8 | Parent | RSVP "can't attend" + reason | The coach sees it in the roster; it does not count as attendance |
| 9 | Coach | Take attendance, "mark the rest present" | Parent sees the recorded status; monthly % updates |
| 10 | Coach | Add feedback | Parent sees it under Progress; notification |
| 11 | Coach | Create, move and cancel a match | Notifications, calendar badge, next-match card |
| 12 | Coach | Publish a photo to two groups (with consent) | Parents of both groups see it; others don't |
| 13 | Parent | Report a media post / chat message | Appears in the admin moderation queue |
| 14 | Admin | Hide the reported content | Members see a placeholder; audit entry |
| 15 | Admin | Approve, reject (reason) and suspend a coach | A suspended coach loses access immediately |
| 16 | Club admin | Try another club's data | Not visible / denied |
| 17 | Parent | Notification center: filter, mark all, open deep link | Opens the right child, group and screen |
| 18 | Parent | Chat: unread badge, pinned announcement, read | Badge clears; announcement pinned |
| 19 | Any | Airplane mode | Offline banner; cached schedule visible; actions fail clearly |
| 20 | Parent | Payments: filter by child/sport; coach marks paid/cancelled | Totals update; audit history |
| 21 | Parent | Export data; delete account (with a shared child) | JSON without medical content; shared child kept with the other guardian |
| 22 | All | iPhone, Android phone, iPad portrait/landscape, Split View | No overflow; rail and multi-column on tablet |
| 23 | Parent | Large text (1.4×) and dark mode | Readable, no clipping |

## Automated coverage (already passing)
- `flutter test`: 185 tests.
- Functions: 130 tests.
- Rules emulator: 94 tests.
- Smoke: 22 steps.

See [beta-v1.2-progress.md](beta-v1.2-progress.md).

## Exit criteria
All scenarios pass on at least one iPhone, one Android phone and one iPad. No P1 (security, data loss, crash) defects open. Every P2 has a workaround.

## Feedback
In-app bugs go to the project's issue tracker with build number `1.2.0+12` (shown under Profile).
