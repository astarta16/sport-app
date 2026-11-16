# Multi-tenant architecture (v1.7)

The platform hosts many independent sports schools, academies and companies
("organizations", "tenants"). This document describes how tenant data is
owned, scoped and protected.

## 1. Tenant = club document

The audit (see [beta-v1.7-progress.md](beta-v1.7-progress.md)) found that
`clubs/{clubId}` already behaved like a tenant:

- groups carry `clubId`;
- club admins hold the custom claim `clubAdmin: [clubId…]`;
- the platform admin holds `admin: true`.

So **`clubId` is the `organizationId`**. Nothing was duplicated: a new
organization is a club document plus its configuration.

| Collection | Owner key | Notes |
|---|---|---|
| `clubs/{clubId}` | itself | name, address, sports, admins (public profile of the school) |
| `orgConfigs/{clubId}` | clubId | status, plan, allowed/enabled modules, branding, time zone, limits, leaderboard settings |
| `clubs/{clubId}/orgMembers/{uid}` | clubId | membership + roles (`admin`, `coach`, `parent`, `student`) |
| `clubs/{clubId}/programs/{id}` | clubId | sports programs / circles |
| `clubs/{clubId}/rooms/{id}` | clubId | halls, capacity, opening hours, status |
| `clubs/{clubId}/bookings/{id}` | clubId | room reservations (UTC instants) |
| `clubs/{clubId}/roomLocks/{roomId_YYYY-MM-DD}` | clubId | transaction lock per room and local day (server only) |
| `clubs/{clubId}/leaderboardConsents/{childId}` | clubId | guardian consent + display name |
| `groups`, `trainings`, `matches`, `rsvps`, `attendance` | via `groups.clubId` | matches also store `clubId` |
| `coachContactRequests/{id}` | via group | student → guardian requests |

Records from before v1.7 already carry their tenant through the group, so
no rewrite is needed. See [firebase-migration-plan.md](firebase-migration-plan.md).

## 2. Users in several organizations

A parent, coach or student may belong to several organizations, so nothing
assumes one permanent organization per user:

- Membership comes from `orgMembers` records, admin claims, coach `clubIds`,
  or a child in one of the organization's groups. The Cloud Function
  `onGroupOrgMembers` keeps `orgMembers` in step with groups.
- The apps keep an **active organization** (`activeOrgProvider`, remembered on
  the device). It only selects what is shown. Every request is still
  authorized against the user's real memberships.
- The demo shows this: the parent Nino and the student Luka belong to both
  the original demo club and Tianeti Sports School.

## 3. Configuration and branding

`OrgConfig` (Dart) and `lib/orgs.ts` (TypeScript) describe the same document:

- **Platform-only fields:** `status` (active / suspended / deactivated),
  `plan` (free / standard / premium), `allowedModules`, `limits`.
- **Organization-admin fields:** `enabledModules` (a subset of
  `allowedModules`), `branding` (names in ka/en/ru, logo URL, colour,
  description, contacts, address), `defaultLanguage`, `timezone`,
  `bookingBufferMin`, and `leaderboard`.

The apps read the configuration at runtime (`orgConfigProvider`). The
organization switcher shows the academy's localized name and colour, so the
branding changes without rebuilding the app.

## 4. Feature flags

There is one rule, implemented identically in three places:

```
enabled(module) = status == active
               && module ∈ allowedModules   (platform)
               && module ∈ enabledModules   (organization)
```

| Layer | Where |
|---|---|
| UI | `OrgConfig.isEnabled`, `moduleOnForGroupProvider`. Disabled modules are hidden or shown as locked. |
| Demo backend | `DemoBackend.requireModule()`, called by the repositories |
| Firestore rules | `moduleOn()` / `groupModuleOn()`: trainings, matches, RSVP, attendance |
| Cloud Functions | `requireModule()` / `isModuleOn()`: bookings, rooms, reports, notifications, Brain Academy result validation |
| Scheduled tasks | schedule-change notices are skipped when `notifications` is off |

- `leaderboards`, `roomScheduling` and `studentAccounts` are **restricted**: a
  new organization starts with them off, and only the platform can allow them.
- An organization admin can never enable a module the platform did not allow
  (callable and rules both check this).
- Feature flags never grant access. They are always combined with a role check.
- **Suspended or deactivated organizations:** data stays readable by its
  owners, but every module is off and nothing new can be created.

## 5. Enforcement on the backend (not client filters)

- **Rules:** every new collection is default-deny for writes from clients.
  Reads are scoped:
  - rooms and programs: organization members and admins;
  - bookings: organization admins and member coaches (never parents or students);
  - consents: guardians and the linked student;
  - leaderboards: server only.
- **Callables:**
  - `requireOrgAdmin(orgId)` checks the `clubAdmin` claim for that exact
    organization (or the platform claim);
  - every referenced group, room, coach or program is re-checked to belong to
    the same tenant (`wrongTenant`).
- **Storage:** `orgs/{clubId}/branding/*` can be written only by that
  organization's admins; every other `orgs/**` path is closed.
- **Notifications:** recipients are always derived from the event's group,
  so a notification can never go to another tenant.

## 6. Tests

| What | Where | Result |
|---|---|---|
| Pure logic | `test/v17/scheduling_scoring_test.dart`, `functions/test/v17.test.ts` (same cases on both sides) | both pass |
| Isolation, escalation, flags, concurrency (demo backend) | `test/v17/v17_workflows_test.dart` | passes |
| Rules on the emulator | `rules-tests/test/v17.rules.test.js` | 18 tests pass |
| Callables on the emulator | `functions/test-integration/v17.integration.mjs` | 7 steps pass |
