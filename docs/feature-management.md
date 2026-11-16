# Feature management (v1.8)

Central, versioned control of what every organization can use. One source of
truth is shared by the app (Dart), the demo backend, the Cloud Functions
(TypeScript) and the security rules.

| Layer | Where |
| --- | --- |
| Catalog, dependencies, rollout, resolver | `lib/features/organizations/domain/platform.dart` (`FeatureCatalog`, `FeatureRollout`, `EntitlementResolver`) |
| Configuration document | `OrgConfig` in `organization.dart` → `orgConfigs/{orgId}` |
| Server mirror | `functions/src/lib/orgs.ts` (`MODULES`, `REQUIRES`, `isModuleOn`, `derivedFields`) |
| Writes | callables in `functions/src/triggers/v18.ts` (`writeConfig`, `updateEntitlements`, …) |
| Rules | `firestore.rules` → `moduleOn` / `cfgModuleOn` |
| UI | Admin web → Platform → Organization → **Features** tab; Feature catalog page |

## Feature catalog (stable ids)

Ids are the `OrgModule` enum names and never change (they are stored in
Firestore). Categories: core, communication, learning, finance, facilities,
administration.

| Id | Requires (any of each group) | Restricted* |
| --- | --- | --- |
| `trainings`, `matches`, `communication`, `notifications`, `medicalCertificates`, `trainingPlans`, `brainAcademy`, `media`, `payments`, `reports`, `dataExports` | — | |
| `attendance`, `parentRsvp` | trainings **or** matches | |
| `messageAcks` | communication | |
| `coachChallenges`, `leaderboards` | brainAcademy | leaderboards |
| `paymentReceipts`, `paymentReminders` | payments | |
| `paymentVerification` | payments **and** paymentReceipts | |
| `studentAccounts` | — | yes |
| `facilities` | — | yes |
| `roomScheduling` | facilities | yes |

\*Restricted features are never switched on by default and cannot be enabled
by an organization admin unless the platform entitled them.

## Three levels

1. **Platform entitlement** (`allowedModules`, package, rollout,
   subscription, organization status, provisioning) — Super Admin only.
2. **Organization switch** (`enabledModules`) — the organization admin may
   turn entitled features off/on; never beyond level 1, never an invalid
   dependency set.
3. **User permission** (`OrgPermission` × role, `PermissionPolicy.forRoles`,
   organization settings such as `coachesCanBookRooms`) plus the existing
   resource checks (own group, own child…).

`OrgConfig.isEnabled(m, now:)` = organization active ∧ provisioned ∧ full
access ∧ allowed ∧ enabled ∧ rollout allows ∧ every dependency effectively on.
`EntitlementResolver.blockOf` returns the first reason a feature is off
(shown in the Features tab).

## Rollout states

| State | Meaning |
| --- | --- |
| enabled | default |
| disabled | entitled but held back |
| trial | on until `until` |
| scheduled | off until `at` |

Time-based states are evaluated by the clients immediately. The rules read
the server-derived `effectiveModules`, recomputed on every change and by the
hourly `refreshEntitlements` job (the System Health page can run it now via
`refreshEntitlementsNow`). **Server enforcement of a trial end / scheduled
start can lag up to 60 minutes.**

## When a feature is disabled

- Navigation, cards and actions disappear (`FeatureGate`,
  `featureOnProvider`, `moduleOnForGroupProvider`); config streams are live,
  so open apps update without a restart.
- Routes are blocked (`routeModule` in the app router; old deep links go
  home).
- Writes are rejected: demo repositories (`requireModule`,
  `requireGroupModule`, `requireChildModule`), Firestore rules
  (`moduleOn`), callables.
- Scheduled jobs and notifications skip the organization (`jobGate`,
  `moduleOfNotification`): payment reminders, recurring payments, and
  notification fan-out.
- **Historical data is kept.** Nothing is deleted; switching back on shows
  it again.

## Changing features (Super Admin)

Features tab: search, category filters, per-feature package availability,
effective state with block reason, rollout selector, last change, bulk
presets (from a package or template), Save / Cancel, unsaved-changes warning.

On save:
1. missing dependencies are listed and the admin confirms adding them (never
   silently);
2. a change preview is shown and a **reason** is required;
3. the write is **versioned**: `expectedVersion` must equal the stored
   `version`, otherwise the save is rejected (`ConfigConflictException` /
   `aborted` with `currentVersion`) and nothing is overwritten;
4. `version`, `updatedAt`, `updatedBy`, `changeReason` are stored and
   `orgConfigs/{id}/history/{version}` records who, when, why and what;
5. an audit entry is written.

## Legacy compatibility

v1.7 documents (no `featureSchema`) used coarse modules. They are read with
`expandLegacy` (payments → receipts/verification/reminders, communication →
acknowledgments, brainAcademy → challenges, attendance → RSVP,
roomScheduling → facilities, trainings → reports/exports). The rules do the
same through `legacyParent`. The first versioned write, or
`functions/scripts/migrate-v18.mjs`, persists the expanded lists. The
scheduler never upgrades a legacy document on its own.
