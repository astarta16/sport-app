// v1.3 payment verification: parents submit a receipt (proof), authorized
// reviewers approve or reject it. payments.status changes only on approval,
// inside the same transaction that decides the proof.
import { logger } from 'firebase-functions';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { bucket, db } from '../admin';
import { actorRoleOf, writeAudit } from '../audit';
import { loadUser, loadUsers } from '../convert';
import { pushText } from '../i18n';
import { formatAmount } from '../i18n/ka';
import { adminScopeFromClaims } from '../lib/adminScope';
import { tbilisiDayKey } from '../lib/dates';
import {
  Denial, ExistingProof, ProofStatus, ReviewerContext, VerificationAction, canReviewPayments, canViewReceipt,
  planReview, planStartReview, planSubmit, receiptMetadataMatches, validateProofInput,
} from '../lib/paymentProofs';
import { UserLite } from '../lib/types';
import { notify } from '../notify';
import { consumeRateLimit } from '../rateLimiter';
import { signedOrEmulatorUrl } from './media';

const RECEIPT_URL_TTL_MS = 5 * 60 * 1000;

interface GroupInfo {
  id: string;
  clubId: string | null;
  name: string;
  paymentManagerIds: string[];
}

function fail(d: Denial): never {
  throw new HttpsError(d.code, d.message);
}

function idArg(v: unknown, name: string): string {
  if (typeof v !== 'string' || !v || v.includes('/') || v.length > 200) throw new HttpsError('invalid-argument', `${name} is required`);
  return v;
}

async function loadGroupInfo(groupId: string): Promise<GroupInfo | undefined> {
  if (!groupId || groupId.includes('/')) return undefined;
  const g = await db.doc(`groups/${groupId}`).get();
  if (!g.exists) return undefined;
  return {
    id: g.id,
    clubId: g.get('clubId') ?? null,
    name: g.get('name') ?? '',
    paymentManagerIds: Array.isArray(g.get('paymentManagerIds')) ? g.get('paymentManagerIds') : [],
  };
}

async function reviewerContext(request: CallableRequest): Promise<ReviewerContext & { user?: UserLite; actorRole: string }> {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const token = request.auth.token as Record<string, unknown>;
  const user = await loadUser(request.auth.uid);
  return {
    uid: request.auth.uid, role: user?.role, coachStatus: user?.coachStatus, scope: adminScopeFromClaims(token), user,
    actorRole: actorRoleOf(token, user?.role),
  };
}

function eventDoc(e: {
  paymentId: string; proofId: string; action: VerificationAction; actorId: string; actorRole: string;
  groupId: string; clubId: string | null; parentId: string; reason?: string | null;
}) {
  // groupId / clubId / parentId are denormalized so the read rule needs no extra lookups.
  return { ...e, reason: e.reason ?? null, at: FieldValue.serverTimestamp() };
}

/** Reviewers to notify: approved coaches in paymentManagerIds + the club's admins (clubs/{id}.adminIds). */
async function reviewerUsers(group: GroupInfo): Promise<UserLite[]> {
  const clubAdmins: string[] = group.clubId ? ((await db.doc(`clubs/${group.clubId}`).get()).get('adminIds') ?? []) : [];
  const users = await loadUsers([...group.paymentManagerIds, ...clubAdmins]);
  const out: UserLite[] = [];
  for (const uid of new Set([...group.paymentManagerIds, ...clubAdmins])) {
    const u = users.get(uid);
    if (!u) continue;
    const isManager = group.paymentManagerIds.includes(uid) && u.role === 'coach' && u.coachStatus === 'approved';
    if (isManager || clubAdmins.includes(uid)) out.push(u);
  }
  return out;
}

const shortDate = (iso: string) => `${iso.slice(8, 10)}.${iso.slice(5, 7)}`;

/**
 * submitPaymentProof {proofId, paymentId, paidOn, reference?, note?, receiptPath, receiptMime, receiptSize}
 * → {proofId, action}. The parent uploads the receipt to
 * receipts/{uid}/{proofId}/{file} first; the proof id is that path segment.
 * Rate limit 10 / 24 h per parent.
 */
export const submitPaymentProof = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const user = await loadUser(uid);
  if (!user || user.role !== 'parent') throw new HttpsError('permission-denied', 'parents only');
  const v = validateProofInput((request.data ?? {}) as Record<string, unknown>, uid, tbilisiDayKey(new Date()));
  if (!v.ok) throw new HttpsError(v.code, v.message);
  const input = v.value;

  await consumeRateLimit(uid, 'paymentProofs');

  const file = bucket().file(input.receiptPath);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError('failed-precondition', 'receipt file not uploaded');
  const [meta] = await file.getMetadata();
  if (!receiptMetadataMatches(input, { contentType: meta.contentType, size: meta.size })) {
    throw new HttpsError('invalid-argument', 'receipt metadata does not match the uploaded file');
  }

  const paymentRef = db.doc(`payments/${input.paymentId}`);
  const pre = await paymentRef.get();
  if (!pre.exists) throw new HttpsError('not-found', 'payment not found');
  const group = await loadGroupInfo(String(pre.get('groupId') ?? ''));
  const proofRef = db.doc(`paymentProofs/${input.proofId}`);

  const result = await db.runTransaction(async (tx) => {
    const paySnap = await tx.get(paymentRef);
    const proofsSnap = await tx.get(db.collection('paymentProofs').where('paymentId', '==', input.paymentId));
    const sameId = await tx.get(proofRef);
    const existing: ExistingProof[] = proofsSnap.docs.map((d) => ({ id: d.id, status: d.get('status') as ProofStatus }));
    if (sameId.exists && !existing.some((p) => p.id === sameId.id)) existing.push({ id: sameId.id, status: sameId.get('status') });
    const pay = paySnap.exists ? paySnap.data()! : undefined;
    const plan = planSubmit(pay ? { status: pay.status, parentId: pay.parentId, verification: pay.verification } : undefined, uid, existing, input.proofId);
    if (!plan.ok) fail(plan);

    const childId = String(pay!.childId ?? '');
    const groupId = String(pay!.groupId ?? '');
    const clubId = group?.clubId ?? null;
    tx.create(proofRef, {
      paymentId: input.paymentId, groupId, clubId, childId, parentId: uid,
      paidOn: input.paidOn, reference: input.reference, note: input.note,
      receiptPath: input.receiptPath, receiptMime: input.receiptMime, receiptSize: input.receiptSize,
      status: 'submitted', submittedAt: FieldValue.serverTimestamp(),
      decidedBy: null, decidedByName: null, decidedAt: null, rejectionReason: null,
    });
    for (const id of plan.supersede) {
      tx.update(db.doc(`paymentProofs/${id}`), { status: 'superseded', supersededBy: input.proofId, supersededAt: FieldValue.serverTimestamp() });
    }
    tx.update(paymentRef, {
      verification: { state: 'proof_submitted', proofId: input.proofId, rejectionReason: null, updatedAt: FieldValue.serverTimestamp() },
    });
    tx.set(db.collection('paymentVerificationEvents').doc(), eventDoc({
      paymentId: input.paymentId, proofId: input.proofId, action: plan.action, actorId: uid, actorRole: 'parent', groupId, clubId, parentId: uid,
    }));
    await writeAudit({
      action: plan.action === 'resubmitted' ? 'payment.proofResubmitted' : 'payment.proofSubmitted',
      actorId: uid, actorRole: 'parent', targetType: 'paymentProof', targetId: input.proofId, clubId,
      details: { paymentId: input.paymentId, groupId, superseded: plan.supersede },
    }, tx);
    return { action: plan.action, childId, groupId, amount: Number(pay!.amount) || 0 };
  });

  if (group) {
    const reviewers = await reviewerUsers(group);
    const child = result.childId ? await db.doc(`children/${result.childId}`).get() : null;
    await notify(reviewers, {
      type: 'paymentProofSubmitted',
      ...pushText('paymentProofSubmitted', {
        group: group.name, child: child?.get('firstName') ?? '', amount: formatAmount(result.amount), date: shortDate(input.paidOn),
      }),
      route: `/payments/proofs/${input.proofId}`,
      args: { proofId: input.proofId, paymentId: input.paymentId, groupId: group.id },
      groupId: group.id,
      dedupeKey: `proof:${input.proofId}:submitted`,
      data: { proofId: input.proofId, paymentId: input.paymentId },
    });
  } else {
    logger.warn('payment proof submitted for a payment without group', { paymentId: input.paymentId });
  }
  return { proofId: input.proofId, action: result.action, state: 'proof_submitted' };
});

async function loadProofForReviewer(request: CallableRequest) {
  const who = await reviewerContext(request);
  const proofId = idArg(request.data?.proofId, 'proofId');
  const proofSnap = await db.doc(`paymentProofs/${proofId}`).get();
  if (!proofSnap.exists) throw new HttpsError('not-found', 'proof not found');
  const group = await loadGroupInfo(String(proofSnap.get('groupId') ?? ''));
  return { who, proofId, proofSnap, group };
}

/** startPaymentReview {proofId}: submitted → under_review (idempotent). Reviewers only. */
export const startPaymentReview = onCall(async (request) => {
  const { who, proofId, group } = await loadProofForReviewer(request);
  if (!canReviewPayments(who, group)) throw new HttpsError('permission-denied', 'not a payment reviewer of this group');
  const proofRef = db.doc(`paymentProofs/${proofId}`);
  const changed = await db.runTransaction(async (tx) => {
    const p = await tx.get(proofRef);
    const plan = planStartReview(p.exists ? { status: p.get('status') } : undefined);
    if (!plan.ok) fail(plan);
    if (!plan.changed) return false;
    const paymentId = String(p.get('paymentId'));
    tx.update(proofRef, { status: 'under_review', reviewStartedBy: who.uid, reviewStartedAt: FieldValue.serverTimestamp() });
    tx.update(db.doc(`payments/${paymentId}`), {
      verification: { state: 'under_review', proofId, rejectionReason: null, updatedAt: FieldValue.serverTimestamp() },
    });
    tx.set(db.collection('paymentVerificationEvents').doc(), eventDoc({
      paymentId, proofId, action: 'review_started', actorId: who.uid, actorRole: who.actorRole,
      groupId: String(p.get('groupId') ?? ''), clubId: p.get('clubId') ?? null, parentId: String(p.get('parentId') ?? ''),
    }));
    return true;
  });
  return { proofId, status: 'under_review', changed };
});

/**
 * reviewPaymentProof {proofId, decision: 'approve' | 'reject', reason?}.
 * Reviewers: group.paymentManagerIds (approved coaches), club admins of the
 * proof's club, platform admins. One transaction decides the proof and, on
 * approval, sets payment status 'paid' + paidAt + verifiedBy + verifiedAt.
 * A second (or concurrent) decision fails with failed-precondition.
 */
export const reviewPaymentProof = onCall(async (request) => {
  const { who, proofId, group } = await loadProofForReviewer(request);
  if (!canReviewPayments(who, group)) throw new HttpsError('permission-denied', 'not a payment reviewer of this group');
  const proofRef = db.doc(`paymentProofs/${proofId}`);
  const out = await db.runTransaction(async (tx) => {
    const p = await tx.get(proofRef);
    if (!p.exists) throw new HttpsError('not-found', 'proof not found');
    const paymentRef = db.doc(`payments/${p.get('paymentId')}`);
    const pay = await tx.get(paymentRef);
    const plan = planReview({ status: p.get('status') }, pay.exists ? { status: pay.get('status') } : undefined, request.data?.decision, request.data?.reason);
    if (!plan.ok) fail(plan);
    const now = FieldValue.serverTimestamp();
    tx.update(proofRef, {
      status: plan.proofStatus, decidedBy: who.uid, decidedByName: [who.user?.firstName, who.user?.lastName].filter(Boolean).join(' '),
      decidedAt: now, rejectionReason: plan.proofStatus === 'rejected' ? plan.reason : null,
    });
    if (plan.markPaid) {
      tx.update(paymentRef, {
        status: 'paid', paidAt: now, verifiedBy: who.uid, verifiedAt: now, updatedBy: who.uid, updatedAt: now,
        verification: { state: 'none', proofId, rejectionReason: null, updatedAt: now },
      });
    } else {
      tx.update(paymentRef, { verification: { state: 'rejected', proofId, rejectionReason: plan.reason, updatedAt: now } });
    }
    const base = {
      paymentId: paymentRef.id, proofId, actorId: who.uid, actorRole: who.actorRole,
      groupId: String(p.get('groupId') ?? ''), clubId: p.get('clubId') ?? null, parentId: String(p.get('parentId') ?? ''),
    };
    tx.set(db.collection('paymentVerificationEvents').doc(), eventDoc({ ...base, action: plan.markPaid ? 'approved' : 'rejected', reason: plan.reason }));
    await writeAudit({
      action: plan.markPaid ? 'payment.proofApproved' : 'payment.proofRejected', actorId: who.uid, actorRole: who.actorRole,
      actorName: [who.user?.firstName, who.user?.lastName].filter(Boolean).join(' '),
      targetType: 'paymentProof', targetId: proofId, clubId: base.clubId,
      details: { paymentId: paymentRef.id, groupId: base.groupId, reason: plan.reason },
    }, tx);
    return { plan, parentId: base.parentId, childId: String(p.get('childId') ?? ''), amount: Number(pay.get('amount')) || 0, paymentId: paymentRef.id };
  });

  const parent = out.parentId ? (await loadUsers([out.parentId])).get(out.parentId) : undefined;
  if (parent) {
    const child = out.childId ? await db.doc(`children/${out.childId}`).get() : null;
    const vars = { child: child?.get('firstName') ?? '', amount: formatAmount(out.amount), reason: out.plan.reason ?? '' };
    const type = out.plan.markPaid ? 'paymentProofApproved' : 'paymentProofRejected';
    await notify([parent], {
      type, ...pushText(type, vars),
      route: `/payments/${out.paymentId}`,
      args: { proofId, paymentId: out.paymentId, ...(out.plan.markPaid ? {} : { reason: out.plan.reason ?? '' }) },
      childId: out.childId || null, groupId: group?.id ?? null,
      dedupeKey: `proof:${proofId}:${out.plan.markPaid ? 'approved' : 'rejected'}`,
      data: { proofId, paymentId: out.paymentId },
    });
  }
  return { proofId, status: out.plan.proofStatus, paymentStatus: out.plan.markPaid ? 'paid' : 'pending' };
});

/** getReceiptUrl {proofId} → {url, mimeType, expiresAt} (5 min). Owning parent or a reviewer; logged as receipt.view. */
export const getReceiptUrl = onCall(async (request) => {
  const { who, proofId, proofSnap, group } = await loadProofForReviewer(request);
  const proof = proofSnap.data()!;
  if (!canViewReceipt(who, { parentId: String(proof.parentId ?? '') }, group)) throw new HttpsError('permission-denied', 'no access to this receipt');
  const path = String(proof.receiptPath ?? '');
  if (!path.startsWith(`receipts/${proof.parentId}/${proofId}/`)) throw new HttpsError('failed-precondition', 'invalid receipt path');
  await db.collection('paymentVerificationEvents').add(eventDoc({
    paymentId: String(proof.paymentId ?? ''), proofId, action: 'viewed', actorId: who.uid, actorRole: who.actorRole,
    groupId: String(proof.groupId ?? ''), clubId: proof.clubId ?? null, parentId: String(proof.parentId ?? ''),
  }));
  await writeAudit({
    action: 'receipt.view', actorId: who.uid, actorRole: who.actorRole, targetType: 'paymentProof', targetId: proofId,
    clubId: proof.clubId ?? null, details: { paymentId: proof.paymentId ?? null },
  });
  const expiresAt = Date.now() + RECEIPT_URL_TTL_MS;
  return { url: await signedOrEmulatorUrl(path, expiresAt), mimeType: String(proof.receiptMime ?? ''), expiresAt: new Date(expiresAt).toISOString() };
});
