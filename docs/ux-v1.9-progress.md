# Beta v1.9 — UX/UI progress report

An improvement of the existing v1.8 app, not a rebuild. Business logic,
backend data contracts, Firebase rules, Cloud Functions and permissions
were **not** changed in this phase. Nothing was pushed or deployed.

Related: [audit](ux-v1.9-audit.md) · [design system](ux-v1.9-design-system.md) ·
[navigation](ux-v1.9-navigation.md) · [workflow comparison](ux-v1.9-workflow-comparison.md) ·
[accessibility](ux-v1.9-accessibility.md).

## Stages delivered (local commits)

| Phase | Commit summary |
|---|---|
| A | Audit (81 code-verified findings); tokens (`AppMotion`, `AppElevation`, `AppA11y`, info colour); searchable picker, entity options, feedback banner, step header, form section; task-based admin navigation filtered by enabled features with organization switcher; feature-off route guard; bug fixes (dropdown assertion crash, room hours overwrite, invite input loss, one-tap suspension) |
| A/D | Role-specific mobile navigation (5 tabs per role), Children and Groups hubs, Messages tab with badge, student My schedule and Profile, sign-out confirmation |
| C/D | RSVP from Parent Home with inline saved state; safe attendance bulk actions; named conflicts with one-tap alternatives; schedule loading/error states and now-line |
| B | Searchable selectors (sports, rooms with busy reasons, groups, coaches, programs, venues, registration clubs, organization switch); provisioning wizard with step header, per-step validation, review step |
| C/E | Table empty states and clear filters; contrast-safe badges; destructive-action confirmations; error/not-found instead of endless loading on edit forms and the receipt screen |
| F | v1.9 UX tests; explicit feature levels; reproducible before/after screenshots; docs; builds |

## Screens redesigned or substantially improved

- **Parent:**
  - Home (inline RSVP, theme-aware reschedule card)
  - new Children tab
  - Messages tab
  - More (Find clubs)
  - receipt upload states
- **Coach:**
  - new Groups tab (take attendance, roster, new training)
  - attendance roster
  - edit forms (training, match, plan, series)
  - venue picker
  - registration clubs
- **Student:**
  - My schedule tab
  - Profile tab (language, confirmed sign-out)
  - 5-tab bar
- **Organization Admin:**
  - sidebar
  - feature-off pages
  - room dialog
  - booking dialog
  - schedule (states, now-line, conflict dialog)
  - add coach
  - groups archive
  - tables
- **Super Admin:**
  - sidebar and organization switcher
  - provisioning wizard
  - Features tab (levels legend, organization pill)
  - Admins tab
  - status change
  - invitations and templates confirmations
  - System health refresh
  - change-reason dialog

## Shared components

New:
- `AppPickerField` (single and multi) and `showAppPicker` / `showAppMultiPicker`
- `AppChoiceGroup`
- `SportsPickerField`
- option builders for sports, coaches, groups, rooms, students and organizations
- `AppFeedbackBanner`, `AppStepHeader`, `AppFormSection`
- `AdminFeatureGate`, `AdminOrgSwitcherTile`
- `ChildrenHubScreen`, `GroupsHubScreen`
- design tokens

Improved:
- `StatusPill` (contrast)
- `AppCard` (emphasis border)
- `AdminTable` (empty states, clear filters, labelled paging)

## Results

| Check | Result |
|---|---|
| `dart format -l 120`, `flutter analyze` | clean |
| `flutter test` | **444 passed**, 10 skipped (opt-in screenshot capture). 22 new v1.9 tests: pickers, sports, contrast, conflict choice, navigation for all five roles, disabled-feature navigation, organization switching, Home RSVP, wizard validation, room hours, table states, localized overflow (ka/en/ru at 320 and 390 px) |
| Functions, rules, emulator suites | not re-run: no backend, rules or functions code changed in v1.9 (last run in v1.8: 235 / 201 / 43 + 7 + 7, all passing) |
| APK | `~/Desktop/SportParentApp-Beta-v1.9.apk`, 81,373,234 bytes, version 1.9.0 (22), demo mode |
| iOS simulator | built and launched on iPhone 16 Pro. Parent sign-in and the 5-tab Georgian navigation **checked by screenshot** (`docs/screenshots/v1.9/ios_simulator_parent_home_ka.png`) |
| Admin web | built to `build/admin_web`, served on http://127.0.0.1:8765. Visual check via rendered screenshots (below); not re-clicked in a browser in this phase |
| Screenshots | `docs/screenshots/v1.8` and `docs/screenshots/v1.9`: parent home, coach home, coach new group, student home, Brain Academy, org admin overview, room scheduling, org settings / add coach, super admin overview, organization creation, feature management (rendered from the widget tree, English, real fonts) |

Defects found while doing this work (fixed, with tests where practical):
- Admin dropdowns asserted when the current value was not in the list.
- Editing a room overwrote per-weekday hours.
- Typed invite input was wiped on rebuild.
- An organization could be suspended with one tap.
- Duplicate sport records dropped other-language names.
- The Georgian "Messages" label first chosen was the existing word for Notifications. It was replaced with "მიმოწერა".

## Remaining limitations (explicit)

- **Organization admins still cannot create groups.** The access policy lets only coaches create groups. Changing it would alter permissions, rules and functions, and was out of scope without a separate decision. The usability task "Org Admin creates a group" is therefore not supported. The coach path improved.
- **35 audit findings are open and 17 are partly done.** See the audit's status column. Among them:
  - the certificate upload redesign (M20) and a shared unsaved-changes guard (M25)
  - calendar match markers and a child selector (M27, M28)
  - message-action affordances (M31)
  - program, sport, template and package dialogs (busy state and validation, A16, A17)
  - admin assignment consolidation (A14) and dead club-creation path (A13)
  - week-view overlap layout (A9)
  - schedule date picker and hours (A24)
  - reports caching (A21) and the org-settings dirty state (A20)
  - localized package labels and technical identifiers (A28, A29, A36)
  - table keyboard and semantics (A34, A35)
- Feature descriptions in the catalog: names, categories and dependencies are shown; per-feature description text was not written.
- Student tabs are not deep-linkable.
- Georgian "Next training" pill label truncates next to the countdown pill on 390 pt phones (seen on the iOS simulator).
- **No usability study** with real parents, coaches, students or administrators was run. The workflow comparison is an analytical count.
- Dark mode: the theme supports it and the fixed light card was corrected, but dark-mode screenshots were not captured for every screen.
- The admin web was not re-tested by hand in a browser after the final build. Verification there rests on widget tests and rendered screenshots.
