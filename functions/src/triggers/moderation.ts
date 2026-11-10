import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { createHash } from 'node:crypto';
import { db } from '../admin';
import { actorRoleOf, writeAudit } from '../audit';
import { groupFrom, loadUser } from '../convert';
import { adminScopeFromClaims, canActOnClub } from '../lib/adminScope';
import { cleanText, isModerationDecision, isReportReason, parseReportTarget } from '../lib/moderation';
import { GroupLite, UserLite } from '../lib/types';
import { consumeRateLimit } from '../rateLimiter';

function isMember(u: UserLite | undefined, g: GroupLite): boolean {
  if (!u) return false;
  if (u.role === 'parent') return g.parentIds.includes(u.uid);
  if (u.role === 'coach') return u.coachStatus === 'approved' && g.coachIds.includes(u.uid);
  return false;
}

/**
 * createReport {targetType, targetPath, groupId?, reason, note?, preview?}
 * The reporter must be a member (group parent / approved group coach) of the
 * content's group. Rate limit 20 / 24 h per user. One open report per
 * reporter+target (deterministic id). Increments the target's reportCount.
 */
export const createReport = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const data = (request.data ?? {}) as Record<string, unknown>;
  const target = parseReportTarget(data.targetType, data.targetPath);
  if (!target) throw new HttpsError('invalid-argument', 'invalid target');
  if (!isReportReason(data.reason)) throw new HttpsError('invalid-argument', 'invalid reason');
  const user = await loadUser(uid);

  let groupIds: string[];
  if (target.type === 'mediaPost') {
    const post = await db.doc(target.docPath).get();
    if (!post.exists) throw new HttpsError('not-found', 'content not found');
    groupIds = post.get('groupIds') ?? [];
  } else {
    if (target.type === 'chatMessage' && !(await db.doc(target.docPath).get()).exists) throw new HttpsError('not-found', 'content not found');
    groupIds = [target.groupId];
  }
  const groupSnaps = groupIds.length ? await db.getAll(...groupIds.map((g) => db.doc(`groups/${g}`))) : [];
  const wanted = typeof data.groupId === 'string' && data.groupId ? data.groupId : null;
  if (wanted && !groupIds.includes(wanted)) throw new HttpsError('invalid-argument', 'groupId does not match the content');
  const group = groupSnaps
    .filter((s) => s.exists)
    .map((s) => groupFrom(s.id, s.data()!))
    .find((g) => (!wanted || g.id === wanted) && isMember(user, g));
  if (!group) throw new HttpsError('permission-denied', 'not a member of the content\'s group');

  await consumeRateLimit(uid, 'reports');

  const reportId = createHash('sha1').update(`${uid}|${String(data.targetPath)}`).digest('hex').slice(0, 24);
  const ref = db.doc(`reports/${reportId}`);
  const created = await db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (cur.exists && cur.get('status') === 'open') return false;
    tx.set(ref, {
      targetType: target.type,
      targetPath: String(data.targetPath),
      groupId: group.id,
      clubId: group.clubId ?? '',
      reason: data.reason,
      note: cleanText(data.note, 500),
      preview: cleanText(data.preview, 200),
      reporterId: uid,
      createdAt: FieldValue.serverTimestamp(),
      status: 'open',
    });
    if (target.type !== 'trainingPhoto') tx.update(db.doc(target.docPath), { reportCount: FieldValue.increment(1) });
    return true;
  });
  return { reportId, created };
});

/**
 * moderate {reportId, decision: 'hidden'|'kept'} — platform admin, or club
 * admin of the report's clubId. Sets `hidden` on the target (chat message /
 * media post; a training photo is removed from trainings.photoUrls, the file
 * is kept for review), resolves every open report on the same target, and
 * writes auditLog 'moderation.decide'.
 */
export const moderate = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const scope = adminScopeFromClaims(request.auth.token as Record<string, unknown>);
  const { reportId, decision } = (request.data ?? {}) as { reportId?: unknown; decision?: unknown };
  if (typeof reportId !== 'string' || !reportId || reportId.includes('/')) throw new HttpsError('invalid-argument', 'reportId');
  if (!isModerationDecision(decision)) throw new HttpsError('invalid-argument', 'decision must be hidden or kept');
  const snap = await db.doc(`reports/${reportId}`).get();
  if (!snap.exists) throw new HttpsError('not-found', 'report not found');
  const report = snap.data()!;
  if (!canActOnClub(scope, report.clubId)) throw new HttpsError('permission-denied', 'admin of this club only');
  const target = parseReportTarget(report.targetType, report.targetPath);
  if (!target) throw new HttpsError('failed-precondition', 'invalid report target');

  const hidden = decision === 'hidden';
  if (target.type === 'trainingPhoto') {
    if (hidden) {
      const ts = await db.collection('trainings').where('photoUrls', 'array-contains', target.storagePath).get();
      await Promise.all(ts.docs.map((t) => t.ref.update({ photoUrls: FieldValue.arrayRemove(target.storagePath) })));
    }
  } else {
    const t = await db.doc(target.docPath).get();
    if (t.exists) await t.ref.update({ hidden });
  }

  const open = await db.collection('reports').where('targetPath', '==', report.targetPath).where('status', '==', 'open').get();
  const batch = db.batch();
  const ids = new Set([snap.id, ...open.docs.map((d) => d.id)]);
  for (const id of ids) {
    batch.update(db.doc(`reports/${id}`), {
      status: 'resolved', decision, decidedBy: request.auth.uid, decidedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  const actor = await loadUser(request.auth.uid);
  await writeAudit({
    action: 'moderation.decide', actorId: request.auth.uid,
    actorRole: actorRoleOf(request.auth.token as Record<string, unknown>, actor?.role),
    actorName: [actor?.firstName, actor?.lastName].filter(Boolean).join(' '),
    targetType: report.targetType, targetId: report.targetPath, clubId: report.clubId ?? null,
    details: { reportId, decision, resolved: ids.size },
  });
  return { decision, resolved: ids.size };
});
