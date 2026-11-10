// Pure payment-proof (receipt) verification logic: input validation, the
// proof state machine and reviewer authorization. Mirrors docs/data-model-v1.3.md.
//
// payments.status stays authoritative (pending | paid | cancelled). A parent
// never changes it; the verification workflow lives in payments.verification
// and paymentProofs. Only a reviewer's approval sets status = 'paid'.

import { AdminScope, canActOnClub } from './adminScope';

export const MAX_RECEIPT_BYTES = 10 * 1024 * 1024;
export const RECEIPT_MIME_TYPES = ['image/jpeg', 'image/png', 'application/pdf'] as const;
export const MIN_REJECTION_REASON = 5;
export const MAX_REJECTION_REASON = 300;

export type ProofStatus = 'submitted' | 'under_review' | 'approved' | 'rejected' | 'superseded';
export type VerificationState = 'none' | 'proof_submitted' | 'under_review' | 'rejected';
export type ProofDecision = 'approve' | 'reject';
export type VerificationAction = 'submitted' | 'resubmitted' | 'review_started' | 'approved' | 'rejected' | 'viewed';

export const OPEN_PROOF_STATUSES: readonly ProofStatus[] = ['submitted', 'under_review'];

export interface ProofInput {
  paymentId: string;
  paidOn: string;
  reference: string | null;
  note: string | null;
  receiptPath: string;
  receiptMime: string;
  receiptSize: number;
  /** proofId taken from receiptPath (receipts/{parentId}/{proofId}/{file}). */
  proofId: string;
}

export type Result<T> = { ok: true; value: T } | { ok: false; code: 'invalid-argument'; message: string };

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

/** 'YYYY-MM-DD' that is a real calendar date. */
export function isIsoDate(v: unknown): v is string {
  if (typeof v !== 'string') return false;
  const m = DATE_RE.exec(v);
  if (!m) return false;
  const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  return d.getUTCFullYear() === +m[1] && d.getUTCMonth() === +m[2] - 1 && d.getUTCDate() === +m[3];
}

/** Parses `receipts/{parentId}/{proofId}/{file}`; null otherwise. */
export function parseReceiptPath(path: unknown): { parentId: string; proofId: string; file: string } | null {
  if (typeof path !== 'string' || path.length > 500 || path.includes('..')) return null;
  const m = /^receipts\/([^/]+)\/([^/]+)\/([^/]+)$/.exec(path);
  if (!m || !ID_RE.test(m[2])) return null;
  return { parentId: m[1], proofId: m[2], file: m[3] };
}

const optText = (v: unknown, max: number): string | null | undefined => {
  if (v === undefined || v === null) return null;
  if (typeof v !== 'string') return undefined;
  const s = v.trim();
  if (s.length > max) return undefined;
  return s.length ? s : null;
};

/**
 * Validates the submitPaymentProof payload for `parentId`. `todayKey`
 * ('YYYY-MM-DD', Tbilisi) bounds paidOn (no future dates).
 */
export function validateProofInput(raw: Record<string, unknown>, parentId: string, todayKey: string): Result<ProofInput> {
  const bad = (message: string): Result<ProofInput> => ({ ok: false, code: 'invalid-argument', message });
  if (typeof raw.paymentId !== 'string' || !ID_RE.test(raw.paymentId)) return bad('paymentId');
  if (!isIsoDate(raw.paidOn)) return bad('paidOn must be YYYY-MM-DD');
  if (raw.paidOn > todayKey) return bad('paidOn is in the future');
  const reference = optText(raw.reference, 60);
  if (reference === undefined) return bad('reference (≤ 60 chars)');
  const note = optText(raw.note, 300);
  if (note === undefined) return bad('note (≤ 300 chars)');
  const parsed = parseReceiptPath(raw.receiptPath);
  if (!parsed || parsed.parentId !== parentId) return bad('receiptPath must be receipts/{yourUid}/{proofId}/{file}');
  // The app sends the client-generated proofId; it must be the path's proofId segment.
  if (raw.proofId !== undefined && raw.proofId !== null && raw.proofId !== parsed.proofId) return bad('proofId must match receiptPath');
  if (typeof raw.receiptMime !== 'string' || !(RECEIPT_MIME_TYPES as readonly string[]).includes(raw.receiptMime)) {
    return bad('receiptMime must be image/jpeg, image/png or application/pdf');
  }
  const size = Number(raw.receiptSize);
  if (!Number.isInteger(size) || size <= 0 || size > MAX_RECEIPT_BYTES) return bad('receiptSize must be 1 byte … 10 MB');
  return {
    ok: true,
    value: {
      paymentId: raw.paymentId, paidOn: raw.paidOn, reference, note,
      receiptPath: raw.receiptPath as string, receiptMime: raw.receiptMime, receiptSize: size, proofId: parsed.proofId,
    },
  };
}

/** Uploaded object metadata must agree with what the client declared. */
export function receiptMetadataMatches(declared: { receiptMime: string; receiptSize: number }, actual: { contentType?: string; size?: number | string }): boolean {
  return actual.contentType === declared.receiptMime && Number(actual.size) === declared.receiptSize && declared.receiptSize <= MAX_RECEIPT_BYTES;
}

// ------------------------------------------------------------ state machine

export interface PaymentForProof {
  status: string;
  parentId: string;
  verification?: { state?: string | null } | null;
}

export interface ExistingProof {
  id: string;
  status: ProofStatus;
}

export type Denial = { ok: false; code: 'permission-denied' | 'failed-precondition' | 'already-exists' | 'invalid-argument' | 'not-found'; message: string };

export interface SubmitPlan {
  ok: true;
  action: 'submitted' | 'resubmitted';
  /** Previously rejected proofs to mark 'superseded'. */
  supersede: string[];
}

/** Treats a missing/unknown verification block as 'none' (pre-v1.3 payments). */
export function verificationStateOf(p: { verification?: { state?: string | null } | null } | undefined): VerificationState {
  const s = p?.verification?.state;
  return s === 'proof_submitted' || s === 'under_review' || s === 'rejected' ? s : 'none';
}

/**
 * submitPaymentProof decision (run inside the transaction with fresh data):
 * - only the payment's parent;
 * - not when the payment is paid or cancelled (failed-precondition);
 * - not while another proof is submitted / under_review (already-exists);
 * - rejected proofs become superseded; the action is 'resubmitted' if any existed.
 */
export function planSubmit(payment: PaymentForProof | undefined, callerUid: string, existing: ExistingProof[], newProofId: string): SubmitPlan | Denial {
  if (!payment) return { ok: false, code: 'not-found', message: 'payment not found' };
  if (payment.parentId !== callerUid) return { ok: false, code: 'permission-denied', message: 'not your payment' };
  if (payment.status === 'paid') return { ok: false, code: 'failed-precondition', message: 'payment is already paid' };
  if (payment.status === 'cancelled') return { ok: false, code: 'failed-precondition', message: 'payment is cancelled' };
  if (payment.status !== 'pending') return { ok: false, code: 'failed-precondition', message: 'payment is not pending' };
  if (existing.some((p) => p.id === newProofId)) return { ok: false, code: 'already-exists', message: 'proof id already used' };
  if (existing.some((p) => OPEN_PROOF_STATUSES.includes(p.status))) {
    return { ok: false, code: 'already-exists', message: 'a proof is already waiting for review' };
  }
  const rejected = existing.filter((p) => p.status === 'rejected').map((p) => p.id);
  const resubmit = rejected.length > 0 || verificationStateOf(payment) === 'rejected';
  return { ok: true, action: resubmit ? 'resubmitted' : 'submitted', supersede: rejected };
}

export interface ReviewPlan {
  ok: true;
  proofStatus: 'approved' | 'rejected';
  verificationState: VerificationState;
  /** Approve → payment.status = 'paid' (+ paidAt, verifiedBy, verifiedAt). */
  markPaid: boolean;
  reason: string | null;
}

export function normalizeReason(reason: unknown): string | null {
  if (typeof reason !== 'string') return null;
  const r = reason.trim();
  return r.length ? r : null;
}

/**
 * reviewPaymentProof decision (inside the transaction, fresh data):
 * the proof must be submitted / under_review (else failed-precondition — so a
 * second or concurrent decision fails), the payment still pending; a reject
 * needs a reason of ≥ 5 characters.
 */
export function planReview(
  proof: { status: string } | undefined,
  payment: { status: string } | undefined,
  decision: unknown,
  reason: unknown,
): ReviewPlan | Denial {
  if (decision !== 'approve' && decision !== 'reject') return { ok: false, code: 'invalid-argument', message: "decision must be 'approve' or 'reject'" };
  if (!proof) return { ok: false, code: 'not-found', message: 'proof not found' };
  if (!payment) return { ok: false, code: 'not-found', message: 'payment not found' };
  if (!OPEN_PROOF_STATUSES.includes(proof.status as ProofStatus)) {
    return { ok: false, code: 'failed-precondition', message: `proof already ${proof.status}` };
  }
  if (payment.status !== 'pending') return { ok: false, code: 'failed-precondition', message: `payment is ${payment.status}` };
  const r = normalizeReason(reason);
  if (decision === 'reject') {
    if (!r || r.length < MIN_REJECTION_REASON) return { ok: false, code: 'invalid-argument', message: 'reason (≥ 5 characters) is required' };
    if (r.length > MAX_REJECTION_REASON) return { ok: false, code: 'invalid-argument', message: 'reason is too long' };
    return { ok: true, proofStatus: 'rejected', verificationState: 'rejected', markPaid: false, reason: r };
  }
  return { ok: true, proofStatus: 'approved', verificationState: 'none', markPaid: true, reason: r && r.length <= MAX_REJECTION_REASON ? r : null };
}

/** startPaymentReview: submitted → under_review; under_review → no-op; anything else fails. */
export function planStartReview(proof: { status: string } | undefined): { ok: true; changed: boolean } | Denial {
  if (!proof) return { ok: false, code: 'not-found', message: 'proof not found' };
  if (proof.status === 'submitted') return { ok: true, changed: true };
  if (proof.status === 'under_review') return { ok: true, changed: false };
  return { ok: false, code: 'failed-precondition', message: `proof already ${proof.status}` };
}

// ------------------------------------------------------------ authorization

export interface ReviewerContext {
  uid: string;
  role?: string;
  coachStatus?: string;
  scope: AdminScope;
}

/**
 * Payment reviewer for a group: platform admin, club admin of the group's
 * club, or an APPROVED coach listed in group.paymentManagerIds. Coaches are
 * not reviewers by default (v1.3).
 */
export function canReviewPayments(who: ReviewerContext, group: { clubId?: string | null; paymentManagerIds?: string[] } | undefined): boolean {
  if (!group) return who.scope.platform;
  if (canActOnClub(who.scope, group.clubId ?? null)) return true;
  return who.role === 'coach' && who.coachStatus === 'approved' && (group.paymentManagerIds ?? []).includes(who.uid);
}

/** Receipt access: the owning parent or a reviewer of the proof's group. */
export function canViewReceipt(who: ReviewerContext, proof: { parentId: string }, group: { clubId?: string | null; paymentManagerIds?: string[] } | undefined): boolean {
  if (who.uid === proof.parentId && who.role === 'parent') return true;
  return canReviewPayments(who, group);
}

/** Client display state: paid / cancelled / verification state / pending. */
export function paymentDisplayState(p: { status: string; verification?: { state?: string | null } | null }): 'paid' | 'cancelled' | 'proof_submitted' | 'under_review' | 'rejected' | 'pending' {
  if (p.status === 'paid') return 'paid';
  if (p.status === 'cancelled') return 'cancelled';
  const v = verificationStateOf(p);
  return v === 'none' ? 'pending' : v;
}

/** paymentManagerIds validation for updateGroup: ≤ 20 distinct ids. */
export function normalizeManagerIds(v: unknown): string[] | null {
  if (!Array.isArray(v) || v.length > 20) return null;
  if (!v.every((x) => typeof x === 'string' && x.length > 0 && x.length <= 128 && !x.includes('/'))) return null;
  return [...new Set(v as string[])].sort();
}
