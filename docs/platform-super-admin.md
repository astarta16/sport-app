# Platform Super Admin — Control Center (v1.8)

Admin web for the platform team. Platform pages are visible and routable
only for platform admins (custom claim `admin: true`); every operation is
re-checked by the callables / demo backend.

```bash
# demo
flutter run -d chrome -t lib/main_admin.dart
flutter build web -t lib/main_admin.dart --release --dart-define=APP_MODE=demo \
  --dart-define=ALLOW_DEMO_IN_RELEASE=true -o build/admin_web
cd build/admin_web && python3 -m http.server 8765   # http://127.0.0.1:8765
```

Sign in with the first demo account (platform admin). Organization admins
(Tianeti, Mtskheta, Saburtalo) get only the organization pages.

## Navigation

| Page | Route | Purpose |
| --- | --- | --- |
| Overview | `/platform` | totals (organizations, active, suspended, trial, users, coaches, students, parents), feature adoption, subscription counts, operational alerts, recent admin actions |
| Organizations | `/organizations` | directory: search, filters (status, trial, funding), sort, pagination; new-organization wizard; manage limits/status, admins, health |
| Organization detail | `/organizations/:id` | tabs below |
| Organization templates | `/templates` | create, edit, duplicate, archive |
| Feature catalog | `/features` | ids, categories, dependencies, restricted flag, adoption |
| Packages | `/packages` | features, limits, indicative pricing |
| Subscriptions | `/subscriptions` | status, end date, access per organization |
| Invitations | `/invitations` | all invitations: resend, revoke |
| Platform users | `/admins` | admin roles (existing page) |
| Audit logs | `/audit` | existing audit log |
| System health | `/health` | scheduled jobs and their feature gates, alerts, "Run entitlement refresh" |
| Activity, Sports, Coaches, Clubs, Moderation | existing pages | |
| Settings | `/settings` | language, sign-out |

### Organization detail tabs

Overview · Admins & members (admins, invite / remove, invitations) ·
**Features** (see [feature-management.md](feature-management.md)) ·
Subscription · Branding (preview and contrast) · Limits & usage ·
Audit history (configuration history + audit entries) · Settings (status,
apply template with preview).

## Organization admin (same web app)

Organization settings (profile, branding, enabled features within the
entitlement, language, time zone, booking buffer, leaderboard, coach
settings), Members (`/members`: coaches, students, guardians and groups —
counts and group names only), Programs, Groups, Rooms, Schedule, Reports,
Attendance, Compliance, Plans, Payments, Media downloads. An organization
admin cannot see or call platform pages, cannot enable non-entitled or
restricted features, cannot exceed limits and cannot administer another
organization.

## Accounts

- First platform admin: `functions/scripts/grant-platform-admin.mjs` (custom
  claim). The `platformAdmins` collection is reserved for a server-written
  mirror; clients can never write it.
- Organization admins: invitation flow ([organization-provisioning.md](organization-provisioning.md)).
