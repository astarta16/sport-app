# Admin guide: web dashboard (beta v1.3)

The admin dashboard is a separate Flutter Web app (`lib/main_admin.dart`). It shares the domain and repositories with the mobile app. **Every admin action is checked again on the server** (custom claims plus Cloud Functions). Hiding buttons in the UI is not the security mechanism.

## Run it

```bash
# Demo mode — no credentials needed
flutter run -d chrome -t lib/main_admin.dart

# Static build (already produced in build/admin_web)
flutter build web -t lib/main_admin.dart --release \
  --dart-define=APP_MODE=demo --dart-define=ALLOW_DEMO_IN_RELEASE=true -o build/admin_web
cd build/admin_web && python3 -m http.server 8765   # open http://127.0.0.1:8765
```

On first load the browser downloads Noto fonts for Georgian, so it needs internet access.

### Demo accounts (sign-in page)

| Account | Role | Scope |
|---|---|---|
| მარიამ წერეთელი | Platform admin | All clubs, sports catalog, admin roles |
| ირაკლი ჩხეიძე | Club admin | საბურთალოს ფეხბურთის აკადემია (club-1) only |
| "Check: parent account" | Parent | Shows the permission-denied screen |

Demo data resets on every reload.

## Roles

| Action | Platform admin | Club admin |
|---|---|---|
| Dashboard numbers | all clubs | own clubs |
| Approve / reject / suspend / revoke / reinstate coaches | all | coaches assigned to own clubs |
| Assign / unassign a coach to a club | all | own clubs |
| Create a club, archive or restore a club | ✓ | — |
| Edit club details | ✓ | own clubs |
| Sports catalog (create, edit, deactivate) | ✓ | read-only |
| Groups oversight, archive a group | all | own clubs |
| Moderation (hide / keep) | all | reports from own clubs |
| Audit log | all | entries for own clubs |
| Admin roles (club admin assignment, removal) | ✓ | — |

Rights come from the custom claims `admin: true` (platform) and `clubAdmin: [clubIds]`, which only server code sets. Users can never assign a role to themselves. The **first platform admin** is created with `functions/scripts/grant-platform-admin.mjs`. It targets the emulator by default and refuses to touch production without an explicit flag (see [backend.md](backend.md)).

A coach can also be a club admin. They keep the coach app on mobile and use the web dashboard for administration. Accounts whose only role is admin see "use the web dashboard" in the mobile app.

## Pages

- **Overview**:
  - parents, children, coaches, clubs, active groups, trainings in the next 7 days, upcoming matches;
  - a "Needs attention" row: coach applications, membership requests, open reports.
- **Coaches**: search, status filter, sort, pagination.
  - Rejecting, suspending or revoking requires a reason of at least 5 characters.
  - A suspended or revoked coach loses all access to child data immediately, because the rules check `coachStatus == approved`.
- **Clubs**: create/edit (name, address, coordinates, phone, description, sports), archive/restore. Archived clubs disappear from search and get no new groups.
- **Sports**:
  - category (team / combat / other), minimum age, medical-certificate requirement, active, order;
  - combat sports default to requiring a certificate.
- **Groups**:
  - shows coach names, member count, schedule, pending requests and upcoming trainings;
  - lets you archive or restore a group;
  - **no child names**: admins see counts only.
- **Moderation**:
  - lists reported chat messages, media posts and training photos;
  - **Hide** sets `hidden: true` on the content (members see a placeholder); **Keep** dismisses the report;
  - every other open report on the same content is resolved together, and every decision is audited.
- **Audit log**:
  - append-only, written by the server;
  - covers coach decisions, role changes, club, sport and group changes, payment status changes, moderation, certificate access, and account deletion/export requests.
- **Certificates** (v1.3): compliance per group as counts only (valid / expiring within 14 days / expired / missing). Admins never receive certificate files or links. The server denies `getCertificateUrl` to every admin role.
- **Attendance** (v1.3): monthly report per group (members, recorded sessions, attendance rate), month picker for the last 6 months. No child names.
- **Training plans** (v1.3): oversight list (title, type, status, groups, coach, number of exercises, start date). Read-only.
- **Payments** (v1.3): verification queue of submitted payment proofs for the admin's clubs.
  - Open the receipt (a short-lived link; every view is audited as `receipt.view`).
  - **Approve** marks the payment paid and records who verified it. **Reject** requires a reason of at least 5 characters, which the parent sees before resubmitting.
  - Decisions are transactional: if two reviewers act at once, the second gets an error.
- **Groups → payment reviewers** (v1.3, the ✓₾ button on each group): choose which of the group's coaches may verify payments. **Coaches are not reviewers by default.** Without a reviewer, only club admins can verify. Changes are audited (`group.paymentManagers`).
- **Settings** (v1.3): interface language (ქართული / English / Русский), saved on this device and to the admin's profile. It does not change the language of data typed by users.
- **Administrators** (platform only): promote a coach to club admin for their clubs, or remove admin rights.

## Data minimisation

Admins never open child profiles, medical certificates or chat histories in the dashboard. Payment receipts are the one document admins can open, and only for their own clubs, through an audited short-lived link. Moderation shows a short text preview of the reported item. Media opens only through short-lived signed URLs (`getMediaUrl`).
