# Workflow comparison — v1.8 → v1.9

**Method.** Each task was walked through in the local demo build and in the
widget tree. Taps are counted from the role's home screen. Text entry counts as
one action per field. "Depth" is the number of screen or dialog levels.
These numbers are **analytical counts by the implementer, not a usability
study**: no participants were involved, so no completion times or success
rates are claimed. Screenshots are in `docs/screenshots/v1.8` and `docs/screenshots/v1.9`.
Both sets were rendered from the same script (`test/screenshots/capture_test.dart`)
in English, with real fonts and demo data.

| # | Task (role) | v1.8 | v1.9 | Confusing steps removed | Errors and recovery |
|---|---|---|---|---|---|
| 1 | Create an organization (Super Admin) | Organizations → New → 4 steps. Validation only at the end, and only the first error showed as red text. Sports were a wall of chips. ~4 + fields taps, depth 2 | Same entry. 5 steps (adds Review), each step checked before Next, errors shown on the fields, searchable sports, editable review. +1 tap (Review) | 2 (hunting for errors across steps; long sports wall) | On submit errors, the wizard jumps to the step with the error. Input is kept when going back. |
| 2 | Configure an organization's features (Super Admin) | Organizations (paged; search needed) → org → Features tab → toggle → Save → reason → OK. Depth 3. Organization-level switch not shown | Same taps. Legend plus an explicit "Org: on/off" pill per feature. Short reasons are explained instead of ignored | 2 (meaning of the status pills; silent reason dialog) | Version conflict dialog (since v1.8). Dependencies offered before saving. |
| 3 | Assign an organization admin (Super Admin) | Org → Admins tab → phone → Invite. Typed text was **wiped** whenever the invitations list updated. Double-click possible | Same 4 actions. Input survives updates. Button is busy while sending. Fields cleared only after success | 1 (lost input) | Missing phone/email explained before sending. |
| 4 | Add a coach to the organization (Org Admin) | Org settings → "Add coach" popup listing every approved coach by name only (no search; namesakes indistinguishable) → pick | Org settings → Add coach → **searchable picker** showing each coach's sports and group count → pick. Same taps | 1 | Removing a coach now asks for confirmation and reports the result. |
| 5 | Create a sport/program (Org Admin) | Programs → New → dialog | **Unchanged** in v1.9 (A16/A17 still open for this dialog) | – | – |
| 6 | Create a group (Org Admin) | **Not possible for organization admins.** Groups are created by coaches (access policy unchanged) | Same policy. Coaches now reach it from the Groups tab "+" (2 taps) instead of Profile → Groups → New group (3 taps + scroll) | 1 for coaches | – |
| 7 | Add a room (Org Admin) | Rooms → New → name, capacity **slider (1–200)**, hours **range slider applied to all 7 days** → Save. Editing a room **overwrote per-day hours** | Rooms → New → name, capacity number field, "same hours every day" switch or per-day hours, status choice → "Add room". Same taps | 2 (imprecise slider; silent overwrite) | Inline validation. Busy state prevents duplicate rooms. |
| 8 | Schedule a recurring training (Org Admin) | Schedule → New booking → room/group/coach dropdowns → recurring switch → weekdays → end date → Save. Recurrence was **not** checked until Save | Same steps with searchable pickers. Rooms busy at that time are marked with the occupying session. Every recurrence change re-runs the conflict preview | 2 (late series conflicts; unknown busy rooms) | Server-side all-or-nothing check unchanged. |
| 9 | Resolve a room conflict (Org Admin) | Drag → dialog with conflict type and plain-text suggestions → **Close** → drag again by trial | Drag → dialog naming the **conflicting session, room and time** → tap a suggested time or free room → moved (**1 tap**) | 2 | Every choice is re-checked by the server. A further conflict opens the dialog again. |
| 10 | Mark attendance (Coach) | Home → today's tile → scroll → Open attendance → Mark all → Save (**4 taps + scroll**). "Mark all" also marked children whose parent said "won't attend". "All absent" overwrote saved marks | Groups tab → **Take attendance** → Mark all → Save (**3 taps**). Declined children are left for the coach (with a message). Bulk actions only touch unmarked rows. Unmarked rows are outlined | 2 | Unsaved-changes guard (from v1.3) kept. |
| 11 | Schedule a match (Coach) | Group → Add match → form with a venue dropdown that lists every same-sport venue in the city | Same taps. Venue picker is searchable, own club first | 1 | – |
| 12 | Confirm attendance after a reschedule (Parent) | Home → next-training card → scroll → acknowledge + answer (**2–3 taps + scroll**). The reason needed a separate, unlabeled send tap. Dark mode made the change card unreadable | Home: the change card and **Will … attend?** sit under the next training. Answer in **1 tap**. "Saved: Yes. The coach sees it." shown inline. Reason auto-saves | 3 | Buttons disabled until answers load (no double answering). |
| 13 | Upload a document (Parent) | Receipt: camera or file only; picker errors silent; endless blank state on load errors | Receipt: picker errors explained; loading, error and not-found states. **Certificate upload unchanged** (M20 open) | 2 (receipt) | Retry on load errors. |
| 14 | Find the next training location (Student) | Home → scroll to events → map button | **My schedule** tab → event map (1 tap + map) | 1 | – |
| 15 | Open Brain Academy and check progress (Student) | Brain Academy tab / Progress tab (3-tab bar) | Same tabs in a 5-tab bar; sign-out and language moved into Profile, with sign-out confirmation | 1 (accidental sign-out) | – |

Safety and consent steps were **not** removed: change reasons, conflict
re-checks on the server, versioned feature saves, reschedule acknowledgment
separate from RSVP, and confirmation of destructive actions (several added).
