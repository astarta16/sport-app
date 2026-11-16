# Regression and workflow verification — v1.9.1

All runs are local: the demo backend and the Firebase emulators. Nothing touched a real Firebase project.

## Automated suites

| Suite | Command | Result |
|---|---|---|
| Format / analyze | `dart format -l 120 lib test`, `flutter analyze` | clean |
| Flutter | `flutter test` | **490 passed**, 14 skipped (opt-in screenshot capture). v1.9.1 adds 4 new files: `org_admin_groups` 14, `admin_schedule` 4, `mobile_screens` 21, `mobile_forms` 7 |
| Cloud Functions unit | `cd functions && npx vitest run` | **239 passed** (4 new) |
| Firestore / Storage rules | `cd rules-tests && npm run test:emulator` | **209 passed** (8 new) |
| Functions smoke | `npm run smoke:functions` | **43 steps passed** |
| Callable integration | `v17` / `v18` / `v191` `.integration.mjs` | **7 / 7 / 8 passed** |

Regressions found and fixed during v1.9.1:
- Group action buttons overflowed: the actions cell now wraps.
- The v1.8 Features-tab test could no longer reach a row once descriptions made rows taller. The helper now scrolls vertically; the product behaviour was correct.
- The empty-picker label overlapped its placeholder (visual). Fixed in the shared component.
- A v15 receipt test failed once under parallel load and passed in every rerun. It is recorded as flaky (timed download), not hidden.

## End-to-end workflows (spec §10)

How each workflow was checked:
- **UI:** driven through the real widget tree in widget tests.
- **Repo:** demo-repository tests.
- **Emu:** Firebase emulator integration.
- **Manual:** looked at by hand on the simulator or in the browser.

| # | Workflow | Verified by | Where |
|---|---|---|---|
| 1 | Super Admin creates a sports school | UI | `v17_ui_test` (provisioning wizard incl. review) |
| 2 | Select organization template | Repo, Emu | `v18_workflows_test`, `v18.integration` |
| 3 | Configure features | UI | `v18_ui_test` Features tab (toggle, reason, version, conflict, dependencies) |
| 4 | Assign an Organization Admin | UI, Emu | `v18_ui_test` invitation accept; `v18.integration` |
| 5 | Restricted feature cannot be enabled by that admin | Repo, Emu | `v18_workflows_test`; `v191.integration` escalation step |
| 6 | Org Admin logs into the organization | UI | `v18_ui_test`, `v19_ux_test` |
| 7 | Add a coach | Repo | v1.7/v1.8 workflow tests (`setOrgCoach`). The searchable picker is **not** UI-tested. |
| 8 | Create a sports program | Repo | v1.7 workflow tests. The improved dialog is **not** UI-tested. |
| 9 | Create a group | UI, Repo, Emu | `org_admin_groups` wizard; `v191.integration` |
| 10 | Assign a coach | UI, Repo, Emu | wizard; `updateGroupDetails` test; `updateGroup` integration |
| 11 | Add a room | UI | `v19_ux_test` room hours; `v17_ui_test` |
| 12 | Create recurring trainings | UI, Emu | `v17_ui_test` booking; `v17.integration` recurring all-or-nothing |
| 13 | Resolve a room conflict | UI | `v19_ux_test` conflict dialog choice; `v17_ui_test` live conflict |
| 14 | Enroll a student through the guardian | Repo, Emu | `org_admin_groups` (invite → accept → full group); `v191.integration`. The admin invite form is **not** UI-tested. |
| 15 | View attendance reports | UI | `v17_ui_test` reports |
| 16 | Coach opens a group | UI | `v19_ux_test` Groups hub |
| 17 | Coach schedules a training | UI | `v12` series form (with guard) |
| 18 | Coach creates a match | UI | `mobile_forms` match form; `v15` flows |
| 19 | Coach marks attendance | UI | `v12`, `v17` attendance |
| 20 | Coach sends a parent announcement | UI | `v14` acknowledgment flows |
| 21 | Parent confirms attendance | UI | `v19_ux_test` Home RSVP; `mobile_screens` answer-for-all |
| 22 | Parent acknowledges a reschedule | UI | `v17_ui_test` reschedule acknowledgment |
| 23 | Parent uploads a medical certificate | UI | `mobile_forms` (file card, failure + retry) |
| 24 | Parent views homework and match results | UI | `v13`, `v15` UI flows |
| 25 | Student opens the schedule and location | UI | `v17_ui_test` (map sheet); `mobile_screens` `?tab=` |
| 26 | Student plays a Brain Academy game | UI | `v16_ui_test` |
| 27 | Student views updated progress | UI | `v16_ui_test`, `v17_ui_test` points |
| 28 | Student views the leaderboard (consented) | UI | `v17_ui_test` |

## Manual checks

- iOS simulator (iPhone 16 Pro): the v1.9.1 build was launched (see the progress report).
- Admin web: built and served; checked through rendered screenshots (`docs/screenshots/v1.9.1`), not clicked through in a browser in this phase.
- Automated tests do **not** replace usability research with real parents, coaches, students or administrators. None was run.
