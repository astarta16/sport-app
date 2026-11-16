# UX audit closure — v1.9.1

**Scope.** Every finding that [ux-v1.9-audit.md](ux-v1.9-audit.md) left **Open** or **Partly** done (52 of 81) was re-checked against the code and closed out individually below. The 29 findings fixed in v1.9 were not re-opened. Their tests still pass in the v1.9.1 regression run.

**Statuses**
- **Fixed and verified:** a test or check exercises the behavior.
- **Partially fixed:** improved, but part of it is still open, or the behavior was fixed without a test that exercises it.
- **Requires product decision.**
- **Blocked by external dependency.**
- **Not fixed.**

**Test files referenced**

| Short name | File |
|---|---|
| `mobile_screens` | `test/v191/mobile_screens_test.dart` |
| `mobile_forms` | `test/v191/mobile_forms_test.dart` |
| `org_admin_groups` | `test/v191/org_admin_groups_test.dart` |
| `admin_schedule` | `test/v191/admin_schedule_test.dart` |
| `v18_ui` | `test/v18/v18_ui_test.dart` |
| `v19_ux` | `test/v19/v19_ux_test.dart` |

| ID | Role | Screen / workflow | Original problem | Root cause | Implemented fix | Evidence | Final status |
|---|---|---|---|---|---|---|---|
| M3 | Student | Student tabs | Tabs not linkable | Tab index held in widget state only | `/kid/home?tab=schedule\|brain\|progress\|profile`; URL kept in sync | `mobile_screens` "/kid/home?tab=brain…" | Fixed and verified |
| M4 | Parent | Home / calendar RSVP | RSVP only deep in the detail screen | RSVP widget only on the detail screen | v1.9 put RSVP on Home under the next session. **No "N sessions need your answer" banner and no RSVP on calendar tiles.** | `v19_ux` Home RSVP test | Partially fixed |
| M11 | Parent | RSVP | No "same answer for siblings" | Per-child cards only | "Same answer for all children" row for 2+ children | `mobile_screens` answer-for-all (+ one-child case) | Fixed and verified |
| M14 | Coach | Attendance roster | No unmarked-first order, highlight or search | – | Unmarked rows outlined (v1.9). **No search and no reordering.** | v1.9 tests | Partially fixed |
| M15 | Coach | Attendance | No retry on load errors | `onRetry` missing | `onRetry` on both AsyncViews | Code review. Error path not exercised by a test. | Partially fixed |
| M16 | Coach | Coach home | No "Take attendance" shortcut on phones | Quick actions were tablet-only | Groups tab "Take attendance" for today's session (v1.9). Phone Home quick actions unchanged. | `v19_ux` groups hub | Partially fixed |
| M17 | Coach | Group header | Buttons shown with the feature off | Gating only in quick actions | Add match / Roster / New plan gated by `moduleOnForGroupProvider` | `mobile_screens` gating test | Fixed and verified |
| M18 | Coach | Roster | Wrong empty-state copy | Reused string | Dedicated empty state with "Add child" | `mobile_screens` empty group test | Fixed and verified |
| M19 | Coach | Roster | No search; destructive action inline | – | Name search; Remove moved to a menu with confirmation | `mobile_screens` roster test | Fixed and verified |
| M20 | Parent | Certificate upload | No preview, replace or progress; errors at the bottom | Single-column legacy form | Camera / library / PDF; type and size guidance (10 MB from `CertificatePolicy.maxBytes`); file card with replace and remove; current-certificate status; who can see it; inline error with Retry that keeps inputs. **Progress is indeterminate:** the repository has no `onProgress`. | `mobile_forms` file card, failed upload + retry, guard | Fixed and verified (indeterminate progress) |
| M21 | All | Form errors | Raw validation codes could show | `validationText(e) ?? e` | `fieldErrorText()` with a localized generic fallback | Code review. No test feeds an unknown code. | Partially fixed |
| M22 | Parent | Receipt | No photo library, no preview | – | Library option, preview card, remove | `mobile_forms` receipt test | Fixed and verified |
| M24 | Parent | Receipt | Failure only as a snackbar | – | Inline "Not sent" banner with Retry; snackbar removed | `mobile_forms` receipt offline test | Fixed and verified |
| M25 | All | Forms | Back discarded typing | No guard | Shared `UnsavedChangesGuard` (Stay / Discard) on training, series, match, plan, child, certificate and receipt forms, plus the admin group wizard and edit dialog | `mobile_forms` guard tests | Fixed and verified (mobile + group dialogs; see A20) |
| M26 | Parent, Coach | Student profile | False "nothing here" while loading | `.value ?? []` | **Not changed** | – | Not fixed |
| M27 | Parent, Coach | Calendar | Match days unmarked; errors silent | Event loader used trainings only | Trophy marker + legend; error card with retry; local-date lookup bug fixed | `mobile_screens` match marker test | Fixed and verified |
| M28 | Parent | Calendar | Hidden child filter | Filter applied silently | Visible child selector bound to the Home selection | `mobile_screens` selector test | Fixed and verified |
| M29 | Parent | Home | Child profile only via long-press | – | Visible "{name}'s details" link | `mobile_screens` Home test | Fixed and verified |
| M30 | Parent | Home | "Add child" not a button for screen readers | GestureDetector | InkWell + `Semantics(button)` | `mobile_screens` Home test | Fixed and verified |
| M31 | All | Chat | Message actions only on long-press | – | **Not changed** | – | Not fixed |
| M34 | Parent | Join club | Ineligible children selectable | Picker ignored age and membership | Disabled with reason (age, already a member, pending) | `mobile_screens` join picker test | Fixed and verified |
| M35 | Coach | Child search | "No results" before searching | No searched flag | Shown only after a search ran | `mobile_screens` M35 test | Fixed and verified |
| M36 | Parent | Contact coach | Silent return with no coach | – | Explains that the group has no coach yet | Code review | Partially fixed |
| M37 | Coach, Parent | Contacts | Bare error text | – | `ErrorView` with retry | Code review | Partially fixed |
| M38 | All | 16 AsyncViews | No retry | `onRetry` optional | Added where touched (attendance, hubs, schedule, groups). **Not all 16 call sites.** | Code review | Partially fixed |
| M39 | All | Icon buttons | No accessible names | – | Tooltips on all listed controls; star targets ≥ 48 dp | Code review, analyzer | Partially fixed (no semantics test) |
| M40 | Coach | New group | Unlabelled, unsearchable dropdowns | – | Searchable club picker; sports picker limited to the club | Code review; existing group tests pass | Partially fixed |
| M43 | Coach | Export | 30 undated entries | – | Picker grouped by month | `mobile_screens` M43 test | Fixed and verified |
| M44 | All | Phone sign-in | Hardcoded hint | – | Localized string | l10n completeness test | Fixed and verified |
| A2 | Both | Tenant pages | Some pages mix tenants | Pages predate the organization context | Groups page now scoped to the selected organization (v1.9.1). **Attendance, Compliance, Plans, Payments and Media downloads still list all permitted tenants.** | `org_admin_groups` | Partially fixed |
| A4 | Super | Org status | One-tap suspension | – | Confirmation (v1.9). **No change reason:** `updatePlatformSettings` has no reason field. Adding one is a backend contract change. | v1.9 | Requires product decision (reason field) |
| A5 | Both | Destructive actions | No confirmation | – | v1.9 plus group member removal and roster removal (v1.9.1). **Admins page role changes are still unconfirmed.** | `org_admin_groups`, `mobile_screens` | Partially fixed |
| A9 | Org Admin | Week view | Parallel bookings overlapped | Full-width positioning | Lane layout: overlapping bookings side by side | `admin_schedule` unit + rendered rects do not overlap | Fixed and verified |
| A11 | Super | Health dialog | Spins forever on error | `snap.hasError` ignored | ErrorView | Code review | Partially fixed |
| A13 | Super | Org creation | Two creation paths; dead code | Legacy Clubs dialog | Clubs "New" opens the provisioning wizard; v1.7 dead code removed | Analyzer clean; v17 and v18 wizard tests pass | Fixed and verified |
| A14 | Super | Admin assignment | Four entry points | Historical growth | **Not consolidated** (invitation flow remains the recommended path) | – | Not fixed |
| A16 | Both | Create dialogs | Double submit possible | No busy state | `AsyncFilledButton` on program, sport, template and package dialogs (room dialog in v1.9) | Code review; no double-click test | Partially fixed |
| A17 | Both | Create dialogs | Silent failures; bad numbers replaced | No validation | Inline errors and duplicate detection (program, sport, template, package); numbers validated | Code review | Partially fixed |
| A19 | Super | Platform dialog | Plan change resets module chips | – | **Not changed** | – | Not fixed |
| A20 | Org Admin | Org settings | Edits discarded on remote update | Form keyed by `updatedAt` | Keyed by organization. **No dirty indicator or guard yet.** | Code review | Partially fixed |
| A21 | Org Admin | Reports | Re-fetch on rebuild; no retry | Futures created in `build` | **Not changed** | – | Not fixed |
| A23 | Both | Long lists | Unsearchable | – | v1.9 pickers plus group wizard and edit (sports, programs, coaches). **Admin assignment and program dialog chips remain.** | `org_admin_groups` wizard test | Partially fixed |
| A24 | Org Admin | Schedule | No now-line, date picker or hours | – | Now-line (v1.9), date picker, labelled prev/next. **Visible hours still fixed 07–23.** | `admin_schedule` date picker test | Partially fixed |
| A28 | Super | Packages | Raw limit keys | – | Localized labels; real currency in the price label | Code review | Partially fixed (code review only) |
| A29 | Both | Various | Technical identifiers | – | Feature ids replaced by plain-language descriptions (all 22 features). **Package ids, audit action keys, job names and IANA zones still visible.** | `v18_ui` features tests | Partially fixed |
| A30 | Both | Small dropdowns | 2–4-option dropdowns | – | Room status (v1.9). Others unchanged. | – | Partially fixed |
| A31 | Org Admin | Capacity | Sliders | – | Room capacity number field (v1.9); group capacity number field. **Program sliders unchanged.** | `org_admin_groups` | Partially fixed |
| A32 | Both | Feedback | Generic "Saved" | – | Specific messages for group, program, coach, invite, template and removal actions | Tests assert outcomes, not wording | Partially fixed |
| A33 | Both | Icon buttons | No tooltip | – | Pagination, schedule navigation, group actions | Code review | Partially fixed |
| A34 | Both | Tables | No semantics | – | Sortable headers announce "Sort by X · ascending"; unsortable headers are plain text. **Swatches and stat cards unchanged.** | Code review | Partially fixed |
| A35 | Both | Keyboard | No keyboard workflows | – | Picker keyboard (v1.9); sortable headers focusable with Enter/Space; Enter submits the reason dialog. **No table row focus; calendar moves remain drag or dialog only.** | `v19_ux` keyboard picker test | Partially fixed |
| A36 | Both | Hardcoded strings | 'ID', ' MB', '60 min', invite domain | – | 'ID' and '(GEL/month)' removed. **' MB', job intervals and the invite domain remain.** | Code review | Partially fixed |

## Summary

| Status | Count |
|---|---|
| Fixed and verified | 19 |
| Partially fixed | 27 |
| Requires product decision | 1 (A4 change reason) |
| Not fixed | 5 (M26, M31, A14, A19, A21) |

The audit is **not** 100 % resolved. Including v1.9, **48 of 81** findings are fixed and verified: the 29 from v1.9 plus 19 here.

## Beyond the audit (v1.9.1 functional work)

- **Organization admin independence:**
  - create, edit and archive groups
  - assign and change coaches
  - capacity and age range
  - minimal roster with removal
  - guardian enrollment invitations
  - setup checklist from saved data
  - Details: [organization-admin-workflows.md](organization-admin-workflows.md).
- **Bugs found while doing this work:**
  - Server `createGroup` did not enforce the organization's group limit.
  - Overlapping bookings were hidden in week view.
  - The picker label overlapped its placeholder.
  - Group action buttons overflowed.
  - Calendar match lookup used UTC dates.
  - The club "Request membership" button overflowed at phone width.
