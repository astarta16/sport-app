import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../admin';
import { writeAudit } from '../audit';
import { childFrom, groupFrom, loadUser, loadUsers, toDate } from '../convert';
import { pushText } from '../i18n';
import { formatShortDate } from '../lib/dates';
import { outcomeOf, resultChanged, validateResult } from '../lib/matchResults';
import { groupParentUsers } from '../lib/recipients';
import { threadParticipants } from '../lib/childThreads';
import { UserLite } from '../lib/types';
import { notify } from '../notify';

/**
 * recordMatchResult {matchId, ourScore, opponentScore, summary?, completedAt?}
 * Approved coach of the match's group only. Writes `result` (server-only
 * field) and status 'played' with trusted timestamps. The first result is
 * announced to the group's parents (matchResult, deduped); every correction
 * appends to matches/{id}/resultHistory and the audit log.
 */
export const recordMatchResult = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const matchId = typeof request.data?.matchId === 'string' ? request.data.matchId : '';
  if (!matchId || matchId.includes('/')) throw new HttpsError('invalid-argument', 'matchId');
  const ref = db.doc(`matches/${matchId}`);
  const now = new Date();

  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'match not found');
    const m = snap.data()!;
    const groupSnap = await tx.get(db.doc(`groups/${m.groupId}`));
    const coach = await loadUser(uid);
    const isCoach = coach?.role === 'coach' && coach.coachStatus === 'approved' && (groupSnap.get('coachIds') ?? []).includes(uid);
    if (!isCoach) throw new HttpsError('permission-denied', 'coach of the group only');
    const v = validateResult(request.data ?? {}, { status: String(m.status), startAt: toDate(m.startAt) ?? new Date(0) }, now);
    if (!v.ok) throw new HttpsError('invalid-argument', v.error);
    const prev = m.result as Record<string, unknown> | undefined;
    if (!resultChanged(prev, v.value)) return { changed: false, first: false, prev, m, group: groupSnap };
    const version = Number(prev?.version ?? 0) + 1;
    const result = {
      ourScore: v.value.ourScore,
      opponentScore: v.value.opponentScore,
      outcome: outcomeOf(v.value.ourScore, v.value.opponentScore),
      summary: v.value.summary,
      completedAt: Timestamp.fromDate(v.value.completedAt),
      recordedBy: uid,
      recordedAt: FieldValue.serverTimestamp(),
      version,
      publishedAt: prev?.publishedAt ?? FieldValue.serverTimestamp(),
    };
    tx.update(ref, { result, status: 'played', updatedAt: FieldValue.serverTimestamp() });
    tx.create(ref.collection('resultHistory').doc(String(version)), {
      version, by: uid, at: FieldValue.serverTimestamp(),
      from: prev ? { ourScore: prev.ourScore, opponentScore: prev.opponentScore, summary: prev.summary ?? null } : null,
      to: { ourScore: result.ourScore, opponentScore: result.opponentScore, summary: result.summary },
    });
    return { changed: true, first: !prev, prev, m, group: groupSnap, result };
  });

  if (!out.changed) return { ok: true, changed: false };
  const clubId = String(out.m.clubId ?? '') || null;
  await writeAudit({
    action: out.first ? 'match.result' : 'match.resultCorrected', actorId: uid, actorRole: 'coach', targetType: 'match', targetId: matchId, clubId,
    details: {
      to: `${out.result!.ourScore}-${out.result!.opponentScore}`,
      ...(out.prev ? { from: `${out.prev.ourScore}-${out.prev.opponentScore}` } : {}),
    },
  });
  if (out.first) {
    const group = groupFrom(out.group.id, out.group.data() ?? {});
    const parents = groupParentUsers(group, await loadUsers(group.parentIds));
    const res = await notify(parents, {
      type: 'matchResult',
      ...pushText('matchResult', {
        group: group.name ?? '', opponent: String(out.m.opponentName ?? ''),
        our: out.result!.ourScore, their: out.result!.opponentScore, date: formatShortDate(toDate(out.m.startAt) ?? new Date()),
      }),
      route: `/match/${matchId}`,
      args: { matchId, groupId: group.id, our: String(out.result!.ourScore), their: String(out.result!.opponentScore), opponent: String(out.m.opponentName ?? '') },
      groupId: group.id,
      dedupeKey: `match:${matchId}:result`,
      data: { matchId },
    });
    logger.info('match result published', { matchId, ...res });
  }
  return { ok: true, changed: true, version: out.result!.version };
});

/**
 * childThreads/{childId}_{coachId}/messages/{m} created: notify the other
 * side (the coach, or the child's current guardians), never other parents.
 */
export const onChildThreadMessageCreated = onDocumentCreated('childThreads/{threadId}/messages/{messageId}', async (event) => {
  const { threadId, messageId } = event.params;
  const msg = event.data?.data();
  if (!msg) return;
  const thread = (await db.doc(`childThreads/${threadId}`).get()).data();
  if (!thread) return;
  const childSnap = await db.doc(`children/${thread.childId}`).get();
  if (!childSnap.exists) return;
  const child = childFrom(childSnap.id, childSnap.data()!);
  const sender = String(msg.senderId ?? '');
  const ids = threadParticipants({ coachId: String(thread.coachId), childParentIds: child.parentIds }).filter((u) => u !== sender);
  const users = await loadUsers(ids);
  const recipients = ids.map((u) => users.get(u)).filter((u): u is UserLite => !!u && (u.role === 'parent' || u.role === 'coach'));
  const text = String(msg.text ?? '');
  await notify(recipients, {
    type: 'childMessage',
    ...pushText('childMessage', { child: child.firstName, sender: String(msg.senderName ?? ''), text: text.length > 120 ? `${text.slice(0, 119)}…` : text }),
    route: `/student/${child.id}/coach/${thread.coachId}`,
    args: { childId: child.id, coachId: String(thread.coachId), child: child.firstName },
    childId: child.id,
    dedupeKey: `thread:${threadId}:${messageId}`,
    data: { threadId },
  });
  await db.doc(`childThreads/${threadId}`).update({ lastMessageAt: FieldValue.serverTimestamp(), lastSenderId: sender });
});

