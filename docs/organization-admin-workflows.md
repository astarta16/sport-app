# Organization admin workflows (v1.9.1)

An organization admin (for example the admin of Tianeti Sports School)
runs their school without help from the platform team or a coach. Every
workflow below is limited to **their own organization**. The server
enforces this (Cloud Functions + Firestore rules); the UI only reflects it.

| Task | Where (admin web) | Who may do it | Enforcement |
|---|---|---|---|
| Choose the sports offered | Organization settings | org admin | `updateOrgSettings` callable |
| Add / remove coaches | Organization settings → Coaches (searchable picker; removal confirmed) | org admin | `setOrgCoach` |
| Create, edit, archive programs | Sports & programs → Programs (inline validation, duplicate names refused, single submit) | org admin | `upsertProgram` |
| **Create a group** | Groups → **New group** wizard | org admin of that organization, or a coach of it (for themself) | `createGroup` callable |
| Edit a group (name, coaches, ages, capacity) | Groups → ✎ | org admin | `updateGroup` callable |
| Archive / restore a group | Groups → archive (confirmed) | org admin | `updateGroup` |
| See who is in a group | Groups → Members (first name, last-name initial, birth year only) | org admin | `adminGroupRoster` callable |
| Remove a child from a group | Members → remove (confirmed; history kept) | org admin | `updateGroup` `removeChildIds` |
| **Enroll a child** | Members → "Enroll through the guardian" | org admin or the group's coach | `createInvite`; the child joins only when the guardian accepts |
| Rooms and opening hours | Calendar & facilities → Rooms | org admin (Facilities feature on) | scheduling callables |
| Recurring sessions, moves, cancellations | Room schedule | org admin (Room scheduling feature on) | transactional booking callables |
| Resolve a room conflict | Room schedule: the dialog names the clashing session and offers free times and rooms | org admin | the server re-checks every choice |
| Attendance reports | Attendance / Reports | org admin (features on) | rules + callables |
| Feature switches within the package | Organization settings | org admin; restricted features need platform permission | `updateOrgSettings` (subset of allowed, valid dependencies) |

## Group wizard

1. **Sport.** Optionally pick a program; it fills in the sport, ages, coaches, places and schedule note. Only the organization's sports are offered.
2. **Name and ages.** The name is required; ages default to 6–12.
3. **Coach.** Searchable multi-select of the organization's approved coaches. If there are none yet, the wizard explains this and links to Organization settings.
4. **Places.** Optional capacity (1–500) and an optional schedule note.
5. **Review.** Every value can be edited from here; then **Create group**.

Errors appear on the step they belong to. Closing with entered data asks
before discarding. After creating, the confirmation points to the next steps:
invite guardians, then schedule sessions.

## Enrollment and safeguarding (product decision: safest default)

- An admin **never** creates a child account or adds a child directly. The guardian receives an invitation (SMS only when the provider is enabled; demo uses a mock) and decides.
- If the guardian already registered the child, they link the existing profile, so no duplicate is created. The guardian also gives media consent at this point.
- Invitation status is visible to the admin: Waiting for guardian, Joined, Declined, Withdrawn.
- Admins see a **minimal roster** only: first name, last-name initial and birth year. Child records, contacts, medical certificates and payments remain unreadable for admins. This is enforced by the rules and covered by tests.
- Group **capacity** is enforced on every join path: invitation acceptance (demo + `respondInvite`), membership approval (demo + `onMembershipRequestWritten`), and join-by-code request approval.

## Setup checklist

Shown on the Overview while setup is incomplete, and computed from **saved data** only:

1. sports chosen
2. at least one coach
3. at least one room (only when Facilities is on)
4. at least one active program
5. at least one active group
6. a group with an upcoming session
7. a group with at least one enrolled child

Each open step links to the page where it is done. The checklist disappears when all steps are complete.

## Security (verified)

| Check | Result |
|---|---|
| Org admin creates a group in their own organization | allowed |
| Org admin in another organization | denied (callable and rules) |
| A coach outside the organization assigned to a group | refused |
| Group limit of the package | enforced on the server for admins **and** coaches (previously demo only) |
| Suspended organization | no new groups |
| Unauthenticated | denied |
| Direct Firestore group writes by org admins | denied (callables only, audited) |
| Org admin calling platform callables (entitlements, provisioning) | denied |
| Invitations | readable by the organization's admin only |

Evidence:
- `functions/test-integration/v191.integration.mjs` (8 steps)
- `rules-tests/test/v191.rules.test.js` (8 tests)
- `functions/test/groupAdmin.test.ts`
- `test/v191/org_admin_groups_test.dart`
