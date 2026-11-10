# Data model — v1.3 additions (contract)

Extends [data-model-v1.2.md](data-model-v1.2.md). Everything listed there stays valid. "server" means written only by Cloud Functions.

## Locale
- `users/{uid}.locale: 'ka' | 'en' | 'ru'` (client-writable, default `ka`). The server uses it for push, SMS, inbox and system-message templates. The app keeps its own preference in local settings and mirrors it here.
- System chat messages carry `systemKey` and `systemArgs{}` so every reader sees them in their own language. `text` stays as the Georgian fallback.
- Notifications are rendered client-side from `type + args`. The server picks title/body in the recipient's `locale` (ka fallback).

## Medical certificates (`medicalCertificates/{certId}`, existing)
- New optional fields:
  - `groupId?`, `sportId?` — the group/sport the certificate applies to (null = general);
  - `replacedBy?: certId` and `replacedAt?` — a replaced certificate stays until the parent deletes it, but is no longer "current".
- **Current certificate** for a child and sport: the newest non-replaced one with the latest `validUntil` and a matching `sportId`, or a general one (`sportId == null`). The client computes this; it is mirrored in `functions/src/lib/certificates.ts`.
- Access callable `getCertificateUrl {certId, purpose: 'view' | 'download'}` → `{url, expiresAt}`, valid 5 minutes. It checks parent-of-child or an approved coach currently assigned to a group containing the child. Every call writes `certificateAccessLog {certId, childId, viewerId, viewerRole, purpose, at}`.
- Admins never receive URLs. `adminCompliance {clubId?}` → per group: `{groupId, valid, expiring, expired, missing}` counts only.
- Reminders at 14 / 3 / 0 days, idempotent via `reminders.d14SentAt / d3SentAt / d0SentAt`, rendered in the parent's locale.

## Groups (+)
- `paymentManagerIds: uid[]` — coaches explicitly authorized to verify payments for the group. Only club admins (or platform admins) may change it, through `updateGroup {paymentManagerIds}`. **Coaches are not payment reviewers by default.**

## Payments (`payments/{id}`, existing — authoritative `status` unchanged: pending | paid | cancelled)
Verification is a separate workflow and never changes `status` on the parent's word:
- `verification: { state: 'none' | 'proof_submitted' | 'under_review' | 'rejected', proofId?, rejectionReason?, updatedAt }` — server only.
- When a reviewer approves: `status = 'paid'`, `paidAt`, `verifiedBy`, `verifiedAt`, `verification.state = 'none'`, `verification.proofId` kept. One transaction.
- Display state (client): `paid` → Paid; `cancelled` → Cancelled; otherwise `verification.state` (proof_submitted / under_review / rejected) or `pending`.

### `paymentProofs/{proofId}`
```
paymentId, groupId, clubId, childId, parentId,
paidOn: 'YYYY-MM-DD', reference?: string(≤ 60), note?: string(≤ 300),
receiptPath: 'receipts/{parentId}/{proofId}/{file}', receiptMime, receiptSize (≤ 10 MB),
status: 'submitted' | 'under_review' | 'approved' | 'rejected' | 'superseded',
submittedAt, decidedBy?, decidedAt?, rejectionReason?
```
- `submitPaymentProof {paymentId, paidOn, reference?, note?, receiptPath, receiptMime, receiptSize}`:
  - the client first uploads to Storage; the rule allows only the owning parent, JPG/PNG/PDF, ≤ 10 MB;
  - in a transaction the server rejects the call if the payment is paid or cancelled, or if another proof is submitted/under_review (`already-exists`);
  - a previously *rejected* proof becomes `superseded`;
  - sets `payment.verification`, notifies the reviewers, and writes `paymentVerificationEvents`.
- `reviewPaymentProof {proofId, decision: 'approve' | 'reject', reason?}`:
  - allowed for `paymentManagerIds` of the group, a club admin of `clubId`, or a platform admin;
  - transactional: the proof must be `submitted` or `under_review`, otherwise `failed-precondition`, so a second reviewer cannot double-approve;
  - a reason (≥ 5 characters) is required on reject;
  - notifies the parent and writes events and audit entries.
- `startPaymentReview {proofId}` (optional) → `under_review`.
- `getReceiptUrl {proofId}` → short-lived URL for the owning parent or an authorized reviewer. Logged as `receipt.view`.
- `paymentVerificationEvents/{id} {paymentId, proofId, action: 'submitted' | 'resubmitted' | 'review_started' | 'approved' | 'rejected' | 'viewed', actorId, actorRole, at, reason?}` — server only. Readable by the parent of the payment, reviewers of the group, and admins of the club.

## Training plans
### `trainingPlans/{planId}`
```
title (1–120), description (≤ 4000), type: 'seasonal' | 'monthly' | 'weekly' | 'exercise' | 'homework',
groupIds: string[] (1–10, coach of each), clubId, startDate: 'YYYY-MM-DD', endDate?: 'YYYY-MM-DD',
status: 'draft' | 'published' | 'archived', createdBy, createdAt, updatedAt, publishedAt?,
exercises: [ {
  id, order, name (1–120), description?, instructions?, durationMin?, reps?, sets?, restSec?,
  media: [ { id, kind: 'photo' | 'video' | 'pdf' | 'link', path? (storage, private), url? (https only), name? } ]
} ]  (≤ 50 exercises, ≤ 10 media each),
readerIds: uid[]   // server: parents + coaches of groupIds while published
```
- Coaches of **all** `groupIds` may create/update. Parents read only published plans where `readerIds` contains them; `readerIds` is recomputed on membership change, which revokes access.
- Storage `plans/{planId}/{file}` — write: plan creator (image ≤ 10 MB, video ≤ 100 MB, pdf ≤ 10 MB); read: via `readerIds` on the plan doc.
- `onTrainingPlanWritten`: when status changes to published, notify group parents once (`dedupeKey plan:{id}:published`) with type `trainingPlanPublished`.
- Links: `https://` only. The client validates them and opens them externally (`LaunchMode.externalApplication`) without credentials.

### `exerciseProgress/{planId}_{exerciseId}_{childId}`
`planId, exerciseId, childId, groupId, parentId, status: 'not_started' | 'in_progress' | 'completed', viewedAt?, updatedAt` — written by the parent of the child (who must be a reader of the plan). Read by that parent and by coaches of the group. This is **self-reported**: it is not coach-verified performance.

### `planViews/{planId}_{parentId}` `{planId, parentId, firstViewedAt, lastViewedAt}` — written by the parent, read by the plan's coaches.

## Exports
These are generated on the client from data the coach can already read (their own groups): roster, training attendance sheet, monthly attendance report, as PDF or CSV. No new collections. Certificate *status* is included only when the coach ticks "include compliance status".

## Notification types (+)
| type | category |
|---|---|
| `paymentProofSubmitted` | payments (reviewers) |
| `paymentProofApproved` | payments |
| `paymentProofRejected` | payments |
| `trainingPlanPublished` | trainings |
| `certificateExpiry` (existing; args `days` = 14/3/0) | certificates |

## Audit actions (+)
`certificate.view`, `certificate.download`, `receipt.view`, `payment.proofSubmitted`, `payment.proofResubmitted`, `payment.proofApproved`, `payment.proofRejected`, `plan.publish`, `plan.archive`, `group.paymentManagers`.
