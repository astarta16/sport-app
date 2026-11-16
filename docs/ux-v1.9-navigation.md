# Navigation — v1.9

Each role sees only what is relevant, authorized **and** enabled. A
feature that is switched off is left out of the navigation. It is never
shown as a dead item. Direct links and old bookmarks to a disabled feature
lead to an explanation (admin) or back home (mobile).

## Mobile (`lib/app/shell.dart`, `lib/app/router.dart`)

Bottom bar below 600 px, rail from 600 px, extended rail from 1200 px.

| Role | Tabs | Notes |
|---|---|---|
| Parent | Home · Calendar · **Messages** · **Children** · More | Messages has an unread badge and disappears when chat is off for all the parent's organizations. Children = one card per child with Profile, Progress, Health documents, Plans and Payments (the last three only when enabled). More = account, settings, privacy, find clubs on the map, sign out (confirmed). |
| Coach | Home · **Schedule** · **Groups** · Messages · More | Groups = each group with its next session, **Take attendance** (today's session), Roster and New training. |
| Student | Home · **My schedule** · Brain Academy · Progress · **Profile** | My schedule = trainings and matches told apart, with venue map and coaches. Profile holds language and sign-out (confirmed), which used to be bare app-bar icons. Tabs are local (not deep-linkable): known limitation. |

The Map moved from a tab to More ("Find clubs on the map") and Explore.
`/chats` and the legacy `/parent/chat` and `/coach/chat` paths lead to the
Messages tab.

Home priorities:
- **Parent:** next training with **Will … attend?** answered in place, plus the reschedule acknowledgment kept separate. Invitations and confirmations waiting. Payments only when enabled.
- **Coach:** today's sessions, quick actions (tablet), attendance shortcut in Groups.

## Admin web (`lib/admin/admin_shell.dart`)

The **Platform** context and the **Organization** context are visually
separated. The organization block in the sidebar names the organization
that every page below it works on, and opens a **searchable switcher**.

**Platform Super Admin**
- **Platform:** Overview, Organizations, Organization templates, Feature catalog, Packages, Subscriptions, Invitations, System health, Audit log, Platform users
- **Catalog & content:** Activity, Sports, Coaches, Clubs, Moderation
- **[Organization switcher]**
- **People:** Members
- **Sports & programs:** Programs, Groups, Training plans\*
- **Calendar & facilities:** Room schedule\*, Rooms\*, Attendance\*, Certificates\*
- **Communication:** Media downloads\*
- **Payments & reports:** Payments\*, Reports\*
- **Organization:** Organization settings, Settings

**Organization Admin**
- Overview
- **[Organization block]**
- **People:** Members, Coaches
- **Sports & programs:** Programs, Groups, Training plans\*, Sports
- **Calendar & facilities:** Room schedule\*, Rooms\*, Attendance\*, Certificates\*
- **Communication:** Moderation\*, Media downloads\*
- **Payments & reports:** Payments\*, Reports\*, Audit log
- **Organization:** Organization settings, Club profile, Settings

\* Listed only when the feature is effectively on for the selected
organization (`OrgConfig.isEnabled`). The matching routes are wrapped in
`AdminFeatureGate`, which explains a disabled feature and links to where it
can be changed.

The 28 flat items of v1.8 became titled sections. The active item is no
longer wrongly highlighted when a route has no menu entry.

## Not done

- A "Communication" page for organization admins (announcements are sent
  from the mobile app).
- Pending-count badges in the admin sidebar.
- Deep-linkable student tabs.
