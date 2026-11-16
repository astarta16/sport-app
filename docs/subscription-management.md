# Packages and subscriptions (v1.8)

Manual management only. **No billing provider is connected and nothing is
ever charged** (by instruction). Prices are informational.

## Packages

`SubscriptionPackage` (`platform.dart`), stored in
`subscriptionPackages/{id}` (server-written; built-ins are used when the
document is missing). Edited on Admin web → **Packages**.

| Package | Features | Limits (coaches / students / groups / rooms / storage) |
| --- | --- | --- |
| Starter | core, communication, RSVP, acks, notifications, reports | 5 / 50 / 5 / 1 / 512 MB |
| Professional | Starter + student accounts, Brain Academy, challenges, plans, payments (+ receipts, verification, reminders), certificates, media, exports, facilities, room scheduling | 30 / 300 / 40 / 5 / 10 GB |
| Enterprise | everything | 200 / 2000 / 300 / 30 / 100 GB, 2000 SMS |
| Custom | every feature available; entitlements and limits set per organization | negotiated |

Further limits per package: media upload size, notifications per month, SMS
per month. Pricing: `amountMinor`, `currency` (GEL), `period`.

Limits are enforced on creation: groups (`limitGroups`), students joining or
approved into groups (`limitStudents`), coaches, rooms. Built-in packages use
their own limits; negotiated limits apply to the Custom package.

## Subscription status

`SubscriptionInfo { status, startAt, endAt, graceDays, note }`.

| Status | Access |
| --- | --- |
| trial | full until `endAt` (+ grace) |
| active | full; after `endAt` full during `graceDays`, then read-only |
| pastDue | full during grace, then read-only |
| suspended / cancelled / expired | read-only immediately |

Read-only (`AccessMode.readOnly`): every feature write is rejected by the
app, the demo backend, the rules (`accessMode`) and the callables; data stays
readable to its owners. **Data is never deleted** by any status change.

The hourly `refreshEntitlements` job turns ended trials / active
subscriptions past grace into `expired` and refreshes the derived fields.

## Where

- Admin web → **Subscriptions**: status, end date and access of every
  organization (filters per status).
- Organization → **Subscription** tab: package, status, end date, grace
  slider, resulting access, reason; versioned save.
- Organization → **Limits & usage**: usage bars per limit. In demo mode
  storage and message counts are estimates; on Firebase `orgUsage` counts
  coaches, students, groups, rooms, notifications and SMS this month —
  **storage usage is not measured yet (reported as 0)**.
- Overview: subscription counts, alerts (trial ending, past due, read-only,
  over limit, provisioning stuck, invitation expiring).
