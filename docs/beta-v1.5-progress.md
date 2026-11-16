# Beta v1.5: progress and status

Legend: **✅ Verified** (tests run locally; where noted also checked on a device) · **🟢 Implemented, Firebase path untested in production** · **🔧 Requires production configuration** · **⛔ Not implemented**

v1.5 builds on v1.4; every earlier feature is kept and the earlier suites still pass.

## What existed before v1.5 (inspected first)

| Area | State in v1.4 |
|---|---|
| Child page | Parent "child profile" (groups, certificates, history) and coach "progress" screen, nothing combined |
| Parent ↔ coach messaging | Group chat only (every parent of the group sees it) |
| Receipt workflow | Submission, reviewer notification, queue, approve/reject all existed (v1.3). **Broken links:** the reviewer's notification opened `/payments/proofs/<id>` and the parent's decision notification opened `/payments/<id>`; neither route existed in the app. Reviewers could view but not download a receipt |
| Matches | Scheduled / moved / cancelled / "played"; no score |

## Status by area

| Area | Status | Notes |
|---|---|---|
| **Student profile** `/student/:childId`: name, photo, sports and groups, coaches, upcoming trainings and matches, training history with attendance, plans and homework, coach media, match results, certificate status, payments | ✅ widget tests + Android device | Tabs: Overview · Trainings · Plans · Media · Matches. Opened from the parent dashboard ("Profile · Luka"), the coach's student roster and group roster |
| Permissions: parents only their children; coaches only their own active groups containing the child (data filtered to those groups); certificate documents keep their own checks (status only here) | ✅ unit + widget tests | Coach sees payments only where they may manage them (existing policy) |
| **Child-context conversation** `/student/:childId/coach/:coachId` | ✅ demo + rules + smoke + Android device · 🟢 Firebase | One thread per (child, coach). Visible to the child's current guardians and that coach while coaching the child. Other parents, other coaches, admins and child accounts are refused (rules tests). Messages are server-timed and immutable. The other side is notified (`childMessage`). The screen says which child it concerns; the call button dials the coach on tap |
| **Receipt delivery**: reviewer notification → `/payments/proofs/:id` (details, view, **download**, approve / reject); parent's decision notification → `/payments/:id/proof` | ✅ demo + smoke · 🟢 Firebase | Download is a separate, audited purpose (`receipt.download`, event `downloaded`), short-lived attachment URL. A submission never marks the payment paid; a second approval fails; each reviewer is notified once (deduplicated) |
| **Match results**: coach enters / corrects our score, opponent score, summary, finish time; win / draw / loss derived | ✅ demo + rules + smoke · 🟢 Firebase | `recordMatchResult` callable only (rules forbid writing `result`). Trusted server time; finish time must be between kickoff and now. Corrections bump `version`, write `resultHistory` + audit `match.resultCorrected`. Parents notified once (`matchResult`) |
| Results shown in: parent dashboard ("Latest result"), student profile, match details, calendar (selected day + recent results), match history | ✅ widget tests + Android device (profile) | No player statistics are invented |
| **Languages** ka / en / ru: 50 new strings | ✅ l10n tests + responsive sweep (ru / en at narrow widths) | Russian machine-assisted |
| **Demo mode**: finished match 3:1 with summary, a match played yesterday waiting for the coach's score, a sample conversation about Luka | ✅ | Fictional data only |
| Responsive: new screens at all 9 sizes (iPhone portrait/landscape, iPad portrait/landscape, Slide Over, Android, desktop) | ✅ widget sweep | Fixed: the error view now scrolls instead of overflowing in phone landscape |

## Tests (run locally on 2026-11-16)

| Suite | Result |
|---|---|
| `dart format`, `flutter analyze` | no issues |
| `flutter test` | **260 passed**: 11 v1.5 repository tests, 3 demo flows (UI), sweep extended |
| Functions build, typecheck, `npm test` | **215 passed** (9 new) |
| Rules emulator tests | **158 passed** (8 new) |
| Functions smoke test (emulators) | **43 steps passed** (3 new) |

## Remaining production blockers / gaps

- Everything Firebase-side is untested in production 🔧: deploy rules, the new index (`childThreads` coachId + lastMessageAt) and functions together.
- Relationship of a guardian to the child: still no editing screen (shown when recorded).
- Coaches can message a child's guardians through the child conversation; there is no per-guardian private channel (all current guardians of the child share it, by design).
- iPad was checked through the widget sweep only (see release checklist for the simulator status).
