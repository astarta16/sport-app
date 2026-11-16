# Beta v1.8 — Platform Super Admin, multi-tenant SaaS, provisioning, feature management, subscriptions

Status: implemented and verified **locally** (demo backend, Firebase emulators).
Nothing was pushed, deployed or run against a real Firebase project; no SMS
was sent and no payment was processed. Demo Mode testing alone does not make
this production-ready.

## 1. Gap analysis against v1.7 (what was extended, not rebuilt)

| Existed in v1.7 | v1.8 change |
|---|---|
| `OrgConfig` with plan, allowed/enabled modules, limits, branding | + package, subscription, rollout, profile, settings, provisioning, version/author/reason, template; derived `effectiveModules` / `accessMode` for rules |
| 13 coarse modules | 22 features with stable ids, categories, any-of dependency graph, restricted flag; legacy expansion |
| Platform org page (create, plan/modules, admins, health) | kept (limits/status/admins/health dialogs); creation moved to the provisioning wizard; new Control Center pages |
| `updateOrgPlatform` / `updateOrgSettings` callables | now versioned (`writeConfig`: transaction, conflict, history) |
| Rules `moduleOn` on allowed ∩ enabled | `cfgModuleOn` on server-derived fields + legacy fallback |
| Module checks in some repositories | every write path of payments, receipts, verification, chat, acknowledgments, plans, media, challenges, RSVP, certificates; limits on groups/students |
| Jobs and notifications unaware of modules | `jobGate()` / `moduleOfNotification` |
| Organization switcher | "All academies" option, cache invalidation, feature availability per selection |

## 2. Delivered

- **Domain** — `lib/features/organizations/domain/platform.dart`: `FeatureCatalog`, `FeatureRollout`,
  `SubscriptionPackage`, `SubscriptionInfo`, `OrgProfile`, `OrgSettings`, `ProvisioningState`, `OrgTemplate`,
  `TemplateDiff`, `OrgInvitation`, `InvitationTokens`, `OrgPermission`, `PermissionPolicy`, `EntitlementResolver`,
  `BrandContrast`, `PlatformStats`, `PlatformAlert`, `OrgUsage`, `ConfigConflictException`, `ConfigHistoryEntry`.
- **Repositories** — `PlatformRepository` (demo + Firebase), extended `OrganizationsRepository.updateOrgSettings`.
- **Backend** — `functions/src/lib/orgs.ts` (mirror), `functions/src/triggers/v18.ts` callables: `platformStats`,
  `upsertPackage`, `upsertTemplate`, `duplicateTemplate`, `archiveTemplate`, `inviteOrgAdmin`, `resendInvitation`,
  `revokeInvitation`, `acceptInvitation`, `rejectInvitation`, `provisionOrganization`, `applyTemplate`,
  `previewTemplateChanges`, `updateEntitlements`, `updateSubscription`, `orgUsage`, `refreshEntitlementsNow`;
  scheduled `refreshEntitlements` (hourly).
- **Rules** — derived-field checks; new collections; feature gates on payments, chat, acknowledgments, RSVP,
  challenges, plans, media, certificates.
- **Admin web** — Control Center (see [platform-super-admin.md](platform-super-admin.md)), organization admin
  Members page, invitation acceptance on the permission-denied page.
- **Mobile app** — `FeatureGate` / route blocking for every gated feature; live updates; organization switcher.
- **Migration** — `functions/scripts/migrate-v18.mjs` (dry run default, per-organization transaction, history,
  rollback snapshot); indexes for usage queries.
- **Strings** — 169 new keys in ka / en / ru (`tool/strings_v18.json`, merged with `tool/add_l10n.py`).
- **Docs** — this file, [platform-super-admin](platform-super-admin.md),
  [organization-provisioning](organization-provisioning.md), [feature-management](feature-management.md),
  [subscription-management](subscription-management.md); updated multi-tenant architecture, security review,
  migration plan, release checklist, README.

### Defects found and fixed while testing v1.8

- The first versioned write on a v1.7 configuration set `featureSchema: 2` but kept the coarse module lists, which
  silently dropped implied features (receipts, acknowledgments…). `writeConfig` now persists the expanded lists
  (caught by `v18.integration.mjs`).
- The hourly refresh would have upgraded every v1.7 configuration after deploy. It now skips them; only the
  reviewed migration script upgrades them.
- The System Health "refresh" button did nothing on Firebase and the demo let any user run it. New platform-only
  callable `refreshEntitlementsNow`; demo checks the platform role.
- `smsLog` had no organization, so per-organization SMS usage was always 0. Entries now carry `clubId` / `clubIds`.
- Flaky v1.7 integration step (pre-existing): after the concurrent-booking step either the 10:00 or the 10:30 booking
  wins; when 10:30 won, the "adjacent" 11:00 booking really overlapped and was (correctly) rejected. The step now
  derives the adjacent slot from the actual winner. Product behaviour was correct; only the test was racy.

## 3. Demo walkthrough

Mobile app (APK / simulator):
1. **ნინო გელაშვილი** (Tianeti volleyball coach): no payments anywhere; `/group/…/payments` redirects home.
2. **ლევან ჩხეიძე** (Saburtalo coach): payments, receipts and review queue available.
3. **მარიამ კაპანაძე** (Saburtalo parent): pending payment, receipt upload.
4. A multi-organization user (Luka / coach Giorgi): organization switcher with "All academies"; features follow
   the selected organization.

Admin web (`build/admin_web`):
5. Platform admin → **Overview**: totals, adoption, subscriptions, alerts (Vake trial ending, Mtskheta past due).
6. **Organizations → New organization**: wizard (try the Government template; payments are not offered).
7. **Organization → Features**: disable media → unsaved warning → reason → saved as a new version; the History tab
   shows it.
8. **Features**: switch on receipts without payments → "Enable required features" confirmation.
9. Two browser tabs editing the same organization → the second save reports the conflict.
10. **Settings → Apply template** on Saburtalo → preview of removed payment features → apply with reason.
11. **Subscription**: set Saburtalo to suspended → read-only; data still visible.
12. **Packages / Templates**: edit, duplicate, archive.
13. **Invitations**: sign in as the demo parent → enter `demo-invite-saburtalo-2026` → Nino becomes Saburtalo's
    administrator (only of Saburtalo).
14. **System health**: run the entitlement refresh (Vake trial expires once its end date passes).

## 4. Verification (local)

| Check | Result |
|---|---|
| `dart format -l 120`, `flutter analyze` | clean |
| `flutter test` | 422 passed (31 v1.8 workflow + 8 v1.8 UI tests new) |
| functions `npm test` (vitest) | 235 passed |
| rules on the emulator | 201 passed (16 new in `v18.rules.test.js`) |
| functions smoke (emulator) | 43 steps passed |
| `v17.integration.mjs` / `v18.integration.mjs` | 7 / 7 steps passed |
| `migrate-v18.mjs` on the emulator | dry run writes nothing; apply + history; re-run no-op; rollback restores |
| APK | `~/Desktop/SportParentApp-Beta-v1.8.apk` |
| iOS simulator | built (`flutter build ios --simulator --debug --dart-define=APP_MODE=demo`) and launched on iPhone 16 Pro |
| Admin web | built to `build/admin_web`, checked in a browser (Overview, organization detail, Features tab) |

## 5. Not done / limits (explicit)

- **No real Firebase verification.** Everything ran on the demo backend and local emulators.
- **Billing**: none, by instruction. Prices are informational; subscription changes are manual.
- **Invitation delivery**: no email/SMS provider; the link/code is shown once to the Super Admin.
- **Storage usage** per organization is not measured on Firebase (`orgUsage.storageMb = 0`); demo values are
  synthetic.
- **Server-side timing**: trial ends / scheduled rollouts reach the rules through the hourly refresh (≤ 60 min lag;
  clients switch immediately).
- **Organization admin scope**: the Members page shows counts and groups; individual student/guardian editing stays
  with the existing coach/parent flows; groups are still created by coaches (existing access policy).
- **Platform users page** is the existing admin-roles page (no separate platform-user lifecycle such as MFA
  enforcement).
- **Branding**: secondary color is stored and previewed; the mobile theme uses the primary color only.
- **App Check** on the new callables, DST-aware time zones and the legal review of student accounts / leaderboards
  remain open (see [release-checklist.md](release-checklist.md)).
- The original v1.8 acceptance-criteria list (1–20) is mapped above by area; any criterion that depends on a real
  Firebase project (deploy, production migration, real invitations) is **not** met by local verification.
