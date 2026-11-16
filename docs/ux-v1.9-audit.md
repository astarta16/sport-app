# UX audit — v1.9 (baseline: v1.8)

Method: code-level review of every presentation file of the mobile app
(`lib/features/**/presentation`, `lib/app`) and the admin web (`lib/admin`),
plus rendering of the v1.8 builds. Findings are code-verified (file:line at
the time of the audit). **No usability study with real participants was
run**; severities are expert judgement (Nielsen heuristics, WCAG 2.2,
Material 3 / Apple HIG guidance), not measured user data.

Severity: **High** = blocks or misleads a normal task; **Medium** = slows or
confuses; **Low** = polish. Status: **Fixed** (implemented and tested in
v1.9), **Partly** (improved, gaps named), **Open** (not done in v1.9).

**Result after v1.9:** 29 of 81 findings fixed, 17 partly improved, 35 open (listed with their status below and in [ux-v1.9-progress.md](ux-v1.9-progress.md)).

## Mobile app (Parent, Coach, Student)

| ID | Screen (file:line) | Role | Problem | Impact | Sev | Proposed solution | Status |
|---|---|---|---|---|---|---|---|
| M1 | `app/shell.dart:29`, `router.dart:179` | Parent, Coach | Same 4 tabs for both (Home, Calendar, Map, Profile); no Messages, Children or Groups tab | Daily tasks hidden; rarely used Map takes a tab | High | Role-specific tabs | Fixed |
| M2 | `top_bar_actions.dart:29` | Parent, Coach | Chat and notifications only in the Home header on phones | Must return Home to read messages | High | Messages tab with unread badge | Fixed |
| M3 | `student_home_screen.dart:72` | Student | 3 local tabs; no My Schedule or Profile; sign-out and language as bare app-bar icons | Schedule buried; no profile | High | 5-tab student shell | Partly — 5 tabs; tabs not deep-linkable |
| M4 | `training_widgets.dart:102-240` | Parent | Home card and calendar tiles never show or collect RSVP; RSVP only deep in the detail screen | 2–4 taps + scroll per answer; unanswered sessions invisible | High | Inline RSVP on Home card + "needs your answer" banner | Partly — RSVP on Home for the next session; no "N unanswered" banner |
| M5 | `training_form_screen.dart:116`, `match_screens.dart:118`, `plan_editor_screen.dart:137` | Coach | Edit forms show a skeleton forever on error / deleted item | Endless loading | High | AsyncView + not-found + retry | Fixed |
| M6 | `series_form_screen.dart:120` | Coach | Blank body or endless skeleton in edit mode | Blank screen | High | Same as M5 | Fixed |
| M7 | `payment_proof_screens.dart:164` | Parent | Loading/error shows only a hint, no form, no spinner | Receipt can't be uploaded, no reason given | High | AsyncView with error/not-found | Fixed |
| M8 | `attendance_widgets.dart:83` | Parent | Reschedule acknowledgment card has a fixed light background; unreadable in dark mode | Can't read the change to acknowledge | High | Theme-aware warning container | Fixed |
| M9 | `attendance_widgets.dart:152` | Parent | No/Maybe saved immediately; reason needs a second, untooltipped send tap | Reasons lost; double snackbars | Medium | Optional reason sheet before saving | Fixed — reason auto-saved on leaving the field |
| M10 | `attendance_widgets.dart:40` | Parent | RSVP buttons show no selection while loading | Parents re-answer | Low | Disabled/skeleton until loaded | Fixed |
| M11 | `attendance_widgets.dart:52` | Parent | No "same answer for all my children" | Extra taps for siblings | Low | Apply-to-all | Open |
| M12 | `attendance_screen.dart:183` | Coach | "All absent/excused" overwrite saved marks without confirmation | One tap wipes the roster | Medium | Unmarked only + confirm | Fixed |
| M13 | `attendance_screen.dart:176` | Coach | "Mark all present" also marks children whose parent said No | Wrong attendance | Medium | Pre-fill from RSVP; skip declined | Fixed |
| M14 | `attendance_screen.dart:196` | Coach | No unmarked-first order, highlight or search | Slow on 20+ rosters | Medium | Unmarked first + count | Partly — unmarked rows outlined; no search/reorder |
| M15 | `attendance_screen.dart:118,137` | Coach | AsyncView without retry | Must leave the screen | Medium | onRetry | Open |
| M16 | `coach_home_screen.dart:202,491` | Coach | Phone dashboard has no quick actions and no "Take attendance" shortcut | 4 taps + scroll for the most frequent task | Medium | Attendance shortcut on today's session; quick actions on phone | Partly — "Take attendance" in Groups hub |
| M17 | `group_management.dart:78` | Coach | Add match / Roster / New plan shown even when the feature is off; route then silently goes Home | Confusing dead buttons | Medium | Same feature gating as quick actions | Open |
| M18 | `group_roster_screen.dart:58` | Coach | Empty roster says "No groups in this club" | Wrong copy, no action | Medium | Proper empty state + action | Open |
| M19 | `group_roster_screen.dart:51` | Coach | No search; Remove inside every expanded tile | Slow; risky | Low | Search; overflow menu | Open |
| M20 | `upload_certificate_screen.dart:186` | Parent | No remove/replace, preview far away, no progress, errors at bottom, no unsaved guard | Unsure what is attached | Medium | File card with preview + remove; progress | Open |
| M21 | `form_fields.dart:72` et al. | All | `validationText(e) ?? e` can show raw keys | Technical text to users | Medium | Generic localized fallback | Open |
| M22 | `payment_proof_screens.dart:247` | Parent | Receipt: camera or file only, no gallery, no preview | Screenshots hard to attach | Medium | Gallery + preview + remove | Open |
| M23 | `payment_proof_screens.dart:126` | Parent | Picker errors not caught | Silent failure | Medium | Guarded picker | Fixed |
| M24 | `payment_proof_screens.dart:155` | Parent | Failure only as snackbar | Easy to miss | Low | Inline error + retry | Open |
| M25 | forms (training, series, match, plan, child, certificate, receipt) | Coach, Parent | No unsaved-changes guard | Back discards typing | Medium | Shared guard | Open |
| M26 | `student_profile_screen.dart:152` | Parent, Coach | ~10 `.value ?? []` reads | False "nothing here" | Medium | AsyncView per section | Open |
| M27 | `calendar_screen.dart:104` | Parent, Coach | Match days have no calendar marker; match errors silent | Matches missed | Medium | Mark matches; handle errors | Open |
| M28 | `calendar_screen.dart:52` | Parent | Calendar silently filtered to the child chosen on Home | "Missing" sibling sessions | Medium | Visible child selector | Open |
| M29 | `parent_home_screen.dart:345` | Parent | Child profile only via long-press | Undiscoverable | Medium | Visible action | Open |
| M30 | `parent_home_screen.dart:364` | Parent | "Add child" has no button semantics | Screen readers miss it | Low | Semantics | Open |
| M31 | `chat_room_screen.dart:297` | All | Message actions only on long-press | Hidden | Low | Visible affordance | Open |
| M32 | `app_widgets.dart:135` StatusPill | All | Status text in its own colour on a light tint (~2:1 for amber) | Fails WCAG AA | Medium | Darker "on" colours | Fixed |
| M33 | `profile_screen.dart:212`, `student_home_screen.dart:63` | All | Sign out without confirmation | Accidental logouts | Medium | Confirm | Fixed |
| M34 | `club_screen.dart:205` | Parent | Join picker ignores age eligibility | Requests fail on the server | Low | Disable ineligible with reason | Open |
| M35 | `group_management.dart:316` | Coach | "No results" before any search ran | Misleading | Low | Track searched | Open |
| M36 | `student_profile_screen.dart:281` | Parent | Contact coach returns silently with no coach | Low | Low | Message | Open |
| M37 | `contacts_screens.dart:102` | Coach, Parent | Error as bare text, no retry | Low | Low | ErrorView | Open |
| M38 | 16 AsyncView call sites | All | No onRetry | Error is a dead end | Medium | Default retry | Open |
| M39 | 11 IconButtons (RSVP send, chat send, map clear, stars…) | All | No tooltip / accessible name; compact targets | Screen readers; small targets | Medium | Tooltips; normal density | Partly — RSVP reason button |
| M40 | `group_management.dart:472` | Coach | New-group dropdowns without labels; club list not searchable | Low | Low | Labels; searchable | Open |
| M41 | `registration_screen.dart:272` | Coach | All clubs as a checkbox list | Long list | Medium | Searchable multi-select | Fixed |
| M42 | `venue_picker.dart:39` | Coach | Venue dropdown includes every same-sport venue in the city | Long unsearchable list | Medium | Searchable, own venues first | Fixed |
| M43 | `export_sheet.dart:293` | Coach | 30 dates without context | Low | Low | Group by month | Open |
| M44 | `phone_screen.dart:85` | All | Hardcoded hint | Low | Low | Localize | Open |
| M45 | Profile / Home | Coach | Groups in two places with different behaviour; no Groups hub | Confusing model | Medium | Groups tab | Fixed |

## Admin web (Organization Admin, Platform Super Admin)

| ID | Screen (file:line) | Role | Problem | Impact | Sev | Proposed solution | Status |
|---|---|---|---|---|---|---|---|
| A1 | `admin_shell.dart:48` | Both | Sidebar ignores enabled features; Plans, Payments, Media downloads, Attendance, Compliance, Reports unguarded | Dead or misleading pages | High | Hide disabled; route guard explains | Fixed |
| A2 | tenant pages | Both | Some pages scoped to the selected organization, others list all tenants | Unclear which organization an action affects | High | One organization context, visible switcher | Partly — organization context + switcher; some pages still list all tenants |
| A3 | `v18_pages.dart:980` | Super | Invite fields created in `build()` (input wiped on rebuild); no busy state | Lost input; duplicate invitations | High | Stateful + busy | Fixed |
| A4 | `v18_pages.dart:1657` | Super | One tap on a status chip suspends a tenant, no confirmation or reason | Accidental lock-out | High | Confirm + reason | Partly — confirmation; the platform API has no reason field |
| A5 | booking cancel, remove admin, make admin, remove coach, revoke, archive template/group | Both | Destructive actions without confirmation | Irreversible changes | High | Confirm dialogs | Partly — invitations, templates, groups, bookings, coach/admin removal |
| A6 | `v17_pages.dart:2207,1953,1971,832,896` | Org Admin | Dropdown value not in items (booking start 05:30, duration 100 min, buffer, min participants) → assertion | Dialog / form fails | High | Include current value; pickers | Fixed |
| A7 | `v17_pages.dart:1886` | Org Admin | Drag conflict dialog doesn't name the conflicting session; alternatives are plain text | Trial-and-error rescheduling | High | Name it; alternatives as buttons | Fixed |
| A8 | `v17_pages.dart:2269` | Org Admin | Booking dialog: conflict without session; alternatives only after save; chips hide date change; recurrence changes not previewed | Hidden day change; late conflicts | High | Live preview incl. recurrence; date on chips | Fixed |
| A9 | `v17_pages.dart:1709` | Org Admin | Week view "All rooms": parallel bookings overlap | Bookings hidden | High | Side-by-side layout | Open |
| A10 | `v17_pages.dart:1467` | Org Admin | Schedule shows "no rooms"/empty grid while loading or on error | Misleading "all free" | High | AsyncView | Fixed |
| A11 | `v17_pages.dart:607` | Super | Health dialog spins forever on error | Stuck dialog | Medium | Error view | Open |
| A12 | `v17_pages.dart:1325,1409` | Org Admin | Room dialog writes the first day's hours to all 7 days | Silent data overwrite | High | Keep per-day hours | Fixed |
| A13 | `clubs_page.dart:28`; dead `v17:149-370` | Super | Second org creation path without config/package; dead code | Half-provisioned tenants | High | One creation path | Open |
| A14 | admins page, org table, Admins tab | Super | Four ways to assign an admin; remove acts on any picked user | Wrong user affected | Medium | One place | Open |
| A15 | `v18_pages.dart:763` | Super | Wizard validates only at the end; first error shown at the bottom | Hunting for errors | Medium | Per-step validation, jump to step | Fixed |
| A16 | program, room, sport, club, template, package dialogs | Both | Save enabled while saving; `id: ''` → duplicates on double click | Duplicate records | Medium | Busy state | Partly — room dialog |
| A17 | same dialogs | Both | No inline validation; silent returns; defaults replace bad numbers | Silent failures | Medium | Form validators | Partly — room dialog |
| A18 | `v18_pages.dart:218` | Super | Change reason < 3 chars: Save silently does nothing | Looks broken | Medium | Error text | Fixed |
| A19 | `v17_pages.dart:445` | Super | Plan change silently resets module chips | Lost edits | Medium | Confirm/merge | Open |
| A20 | `v17_pages.dart:657` | Org Admin | Settings form recreated on any config update; no dirty state; no busy | Silent loss of edits | Medium | Stable key + dirty + busy | Open |
| A21 | `v17_pages.dart:2448` | Org Admin | Reports re-fetch on every rebuild; error without retry | Flicker | Medium | Provider + retry | Open |
| A22 | `widgets.dart:136` | Both | One empty message for "no data" and "no matches"; no clear-filters | Unclear state | Medium | Distinct states + clear | Fixed |
| A23 | org picker, admin assignment, add coach, booking group/coach/program, program chips, provisioning sports, audit chips | Both | Long unsearchable lists; equal names indistinguishable | Slow, error-prone | Medium | Searchable pickers | Partly — booking, add coach, organization switch, sports; admin assignment & program chips open |
| A24 | `v17_pages.dart:1443` | Org Admin | No now-line, fixed hours, no date picker, week tap books first room silently | Hard to orient; wrong room | Medium | Now-line, date picker, explicit room | Partly — now-line; no date picker/hours setting |
| A25 | `admin_shell.dart:31` | Super | 28 flat items; same pages in different sections per role; "Activity" next to "Overview" | Hard to scan | Medium | Task-based sections | Fixed |
| A26 | `admin_shell.dart:77` | Both | Unmatched route highlights the first item | Wrong active state | Low | No selection | Fixed |
| A27 | `v18_pages.dart:2248` | Super | Refresh without error handling or busy | Unhandled errors | Medium | Guarded + busy | Fixed |
| A28 | `v18_pages.dart:2071,2078` | Super | Package limit labels are raw keys; hardcoded "(GEL/month)" | Unlocalized | Medium | Labels | Open |
| A29 | packageId, statuses, audit keys, job names, IANA zones | Both | Technical identifiers shown | Jargon | Low | Localized labels | Open |
| A30 | plan, status, program/room status, booking kind, language, funding | Both | 2–4-option dropdowns | Hidden options | Low | Segmented choices | Partly — room status |
| A31 | `v17_pages.dart:1112,1347` | Org Admin | Capacity sliders (1–200), existing >60 clamped | Imprecise; silently changed | Low | Number fields | Partly — room capacity |
| A32 | many | Both | Generic "Saved" for create/archive/revoke; "Close" with unsaved edits | Vague | Low | Specific messages | Partly |
| A33 | 10 IconButtons | Both | No tooltip | No accessible name | Medium | Tooltips | Partly — pagination |
| A34 | colour swatches, StatCards, sortable headers | Both | No semantics | Screen readers blocked | Medium | Semantics | Open |
| A35 | all `lib/admin` | Both | Enter doesn't submit; no table keyboard actions; calendar drag-only | Keyboard users slowed | Medium | Form submit, focus traversal | Partly — picker keyboard, Enter in reason dialog |
| A36 | several | Both | Hardcoded strings ('ID', ' MB', '60 min', invite domain…) | Unlocalized | Low | l10n | Open |

## Navigation as audited (v1.8)

| Role | Tabs / items |
|---|---|
| Parent | Home, Calendar, Map, Profile; chat and notifications only in the Home header |
| Coach | Home, Calendar, Map, Profile (same shell) |
| Student | Home, Brain Academy, Progress (local state, not routed) |
| Org Admin | 19 flat items incl. Clubs, Sports, Moderation, Audit; none filtered by features |
| Super Admin | 28 items: Platform (15) + Tenant (12) + Settings; none filtered by features |

## Theme tokens as audited

Present: brand and status colours, light **and** dark schemes, spacing
4–32, radii 12/20/28, component themes, breakpoints in
`core/layout/responsive.dart`. Missing: motion tokens (54 hard-coded
durations), elevation scale, focus styling, tap-target policy, accessible
"on" colours for status text, Brain Academy colour token.
