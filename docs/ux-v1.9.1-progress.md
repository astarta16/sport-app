# Beta v1.9.1 — progress report

v1.9.1 builds on v1.9.0 (no rebuild). Local only: nothing pushed or deployed, no production data, no real children's or parents' data.
Not production-ready on the basis of demo and emulator testing alone.

Related docs:
- [closure](ux-v1.9.1-closure.md)
- [organization admin workflows](organization-admin-workflows.md)
- [accessibility](ux-v1.9.1-accessibility.md)
- [regression](ux-v1.9.1-regression.md)
- [v1.9 audit (updated)](ux-v1.9-audit.md)

## Stages (local commits)

1. **Organization admins create and manage their own groups.**
   - Server (`createGroup`, `updateGroup`, `createInvite`, new `adminGroupRoster`), demo repositories, rules, admin web wizard, edit and members dialogs.
   - Optional group capacity, enforced on every join path.
   - The organization's group limit is now enforced on the server for everyone. It was previously enforced only in the demo.
2. **Security tests:** rules (8) and emulator integration (8).
3. **Setup checklist** computed from saved data.
4. **Admin dialogs:**
   - validation, duplicate detection and single-submit
   - one organization-creation path
   - plain-language descriptions for all 22 features
5. **Mobile screens** (parallel stream):
   - calendar match markers and child selector
   - linkable student tabs
   - Georgian label no longer truncated
   - coach group gating and roster
   - parent Home links
   - same RSVP answer for siblings
   - join eligibility
   - export picker
6. **Mobile forms** (parallel stream):
   - unsaved-changes guard
   - certificate upload redesign
   - receipt library, preview and retry
   - no raw validation codes
   - tooltips
7. **Room schedule:** side-by-side overlapping bookings, date picker, labelled navigation.
8. **Tables and smaller fixes:**
   - sortable headers announce their state
   - health dialog error state
   - org settings edits no longer discarded by remote updates
   - package labels readable
   - retry and empty-state fixes
9. **Picker label overlap fix**, screenshots, docs, version 1.9.1+23.

## Product decisions taken (safest defaults)

- **Admins and children's records:** an organization admin never reads child records. A minimal server-side roster (first name, last-name initial, birth year) is enough to manage membership.
- **Enrollment:** always through a guardian invitation. Admins never create child accounts, and duplicate profiles are avoided because the guardian links an existing child.
- **Group writes:** organization admins change groups only through audited callables, never by direct Firestore writes.
- **Coaches:** a group must have at least one approved coach of the organization.
- **Change reason for suspensions (A4):** left for a product decision, because the platform API has no reason field.

## Results

| Check | Result |
|---|---|
| analyze / format | clean |
| Flutter tests | **490 passed**, 14 skipped (opt-in captures) |
| Functions unit | **239 passed** |
| Rules (emulator) | **209 passed** |
| Functions smoke | **43 steps passed** |
| Integration v17 / v18 / v1.9.1 | **7 / 7 / 8 passed** |
| Android APK | `~/Desktop/SportParentApp-Beta-v1.9.1.apk`: **81,504,290 bytes**, 1.9.1 (23), demo mode |
| iOS simulator | built and launched on iPhone 16 Pro. Parent Home checked in Georgian: full "შემდეგი ვარჯიში" label, child-details link, 5-tab navigation (`docs/screenshots/v1.9.1/ios_simulator_parent_home_ka.png`) |
| Admin web | built to `build/admin_web`. New admin screens checked via rendered screenshots (group wizard, setup checklist, schedule); not clicked through in a browser |
| Screenshots | `docs/screenshots/v1.9` vs `docs/screenshots/v1.9.1` (same capture script; new: group wizard, setup checklist, certificate upload, parent calendar) |

Note on verification: one iOS check first showed the old truncated label. The cause was launching the app before the iOS build had finished. It was relaunched with the finished build and checked again.

## Audit status

| Status | Count |
|---|---|
| Fixed and verified | 19 |
| Partially fixed | 27 |
| Not fixed | 5 (M26, M31, A14, A19, A21) |
| Requires product decision | 1 (A4) |

Overall, 48 of 81 v1.9 findings are fixed and verified. **The audit is not fully resolved.**

## Remaining limitations

- The items listed as not fixed or partial in the closure report. The main ones:
  - Several admin pages still list all permitted tenants (A2).
  - Admin assignment has several entry points (A14).
  - Reports caching and retry (A21).
  - No keyboard row focus in tables (A35).
  - Student profile false-empty states (M26).
  - Chat action discoverability (M31).
- Certificate upload progress is indeterminate (the repository has no progress callback).
- Browser close or refresh is not covered by the unsaved-changes guard.
- "Profile · {name}" and "{name} — details" now sit next to each other on Parent Home. Both are useful (student view vs editing details), but the pairing may confuse users. Worth a design review.
- No usability study with real users. Automated tests do not replace one.
