# Beta v1.6: student account, student dashboard and Brain Academy

Legend: **✅ Verified** (tests run locally; where noted also on a device) · **🟢 Implemented, Firebase path untested in production** · **🔧 Requires production work** · **⛔ Not implemented**

## What existed before v1.6

A `child` role and rules for "child accounts" existed, but child sign-in was disabled everywhere (`PolicyFlags.childAccountsEnabled = false`, router → `/auth/child`). There were no student screens and no games.

## Status

| Area | Status | Notes |
|---|---|---|
| **Demo student account**: Luka Beridze, football, coach Giorgi Kapanadze, linked to demo parent Nino Beridze; "Continue as Student" on the demo login | ✅ widget tests + Android device | Uses the existing demo child Luka (`child-1`), whose seeded age is now 11. His football group is still the seeded **"U-10 · ახალგაზრდები"** (renaming or moving him to the U-12 "juniors" group would have rewritten the v1.2–v1.5 demo flows); he is also in swimming |
| Student sign-in **only in demo mode** | ✅ router unit test | Firebase builds still send child accounts to `/auth/child`. No self-registration, no production student auth (needs age verification, parental consent, privacy policy review) 🔧 |
| **Student dashboard** `/kid/home`: avatar, welcome, Brain Academy hero, coach challenges, my sports, my coach, next training, upcoming matches, match results, plans, homework, attendance, achievements; tabs Home · Brain Academy · Progress; language switch, sign out | ✅ | Students cannot reach payments, certificates, chat, contacts/phones, parent or admin routes (router + rules tests) |
| **Brain Academy — six games**, all playable end to end | ✅ every game played to completion in widget tests; Smart Play also on the Android device | Pure, seeded engines (`domain/engines.dart`) + Flutter widgets. Flame was not used: the games are turn/tap based and work well with widgets, and no extra engine dependency was needed offline |
| 1 Memory Match: sports cards, difficulty = pairs, attempts, time | ✅ | |
| 2 Logic Quest: repeating patterns, growing counts, missing element; feedback | ✅ | |
| 3 Smart Play: football pitch, choose pass/move, explanation after each answer, harder sets per difficulty | ✅ | `StrategyLibrary` is keyed by sport, so new sports add a scenario list |
| 4 Quick Mind: find target symbol+colour, per-round timer, reaction time, accuracy, faster with streaks/levels | ✅ | |
| 5 Sequence Master: watch → repeat, grows each round, lives | ✅ | |
| 6 Path Finder: generated mazes (always solvable), cones as obstacles, arrows/swipe/keyboard, moves and time | ✅ | A maze-initialisation crash was caught by the new unit tests and fixed |
| Game shell: instructions, difficulty, level selection/progression (10 levels each), start, pause/resume (timers stop), restart, completion with score, accuracy, time, best score, new badges, next level; optional sound + haptics; pauses when the app goes to the background | ✅ | Large tap targets (≥ 56 px), semantics labels, shapes as well as colours, reduced-motion respected. No ads, no leaderboards, "not an IQ test" note shown |
| **Progress and achievements**: per game plays, completed, best score/accuracy/time, unlocked levels per difficulty, recent scores chart, 9 badges | ✅ | No IQ or comparison with other children |
| Demo progress survives app restarts | ✅ unit test | SharedPreferences (`demo.brainAcademy.v1`); games and saving work offline |
| **Parents**: "Brain Academy" tab in the student profile (progress, badges, challenges with status) | ✅ | |
| **Coaches**: `/group/:id/challenges` (from the group roster): assign game + difficulty + optional due date, see completion per child, remove; Brain tab in the student profile | ✅ | Coaches see only their own groups' children |
| **Firebase**: `brainResults` (create-only by the linked student, server time, bounded values), `brainAssignments` (group coaches), student reads of own attendance and published plans of own groups; student view uses the public group projection, never full group docs | ✅ rules emulator tests · 🟢 not used in production | `publicGroups` now also stores `groupId` |
| **Languages**: 127 new strings in ka / en / ru | ✅ l10n tests + layout sweep (ru 320 px, en landscape, iPad portrait/landscape) | Russian machine-assisted |

## Tests (run locally on 2026-11-16)

| Suite | Result |
|---|---|
| `dart format`, `flutter analyze` | no issues |
| `flutter test` | **298 passed** (38 new: 17 engine/progress tests, 8 repository/permission/persistence tests, 13 UI tests) |
| Functions `npm test` | **215 passed** |
| Rules emulator tests | **167 passed** (9 new) |
| Functions smoke test | **43 steps passed** |

## Not done / production blockers

- Real student authentication for production (age verification, verified parental consent, privacy policy and legal review) 🔧 — intentionally not enabled.
- Chess ⛔ (out of scope by request).
- Smart Play has football scenarios only (structure ready for more sports).
