import { logger } from 'firebase-functions';
import * as functionsV1 from 'firebase-functions/v1';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { auth, bucket, db } from '../admin';
import { REGION } from '../config';
import { childFrom, groupFrom, loadUser } from '../convert';
import { canCoachSeeParentPhone, planAccountDeletion } from '../lib/access';
import { purgeChildCertificates } from './certificates';

/** Mirrors users/{uid} into publicProfiles/{uid} (no phone, no tokens). */
export const syncPublicProfile = onDocumentWritten('users/{uid}', async (event) => {
  const ref = db.doc(`publicProfiles/${event.params.uid}`);
  const after = event.data?.after.exists ? event.data.after.data()! : undefined;
  if (!after) {
    await ref.delete();
    return;
  }
  const before = event.data?.before.exists ? event.data.before.data()! : undefined;
  const pick = (d?: FirebaseFirestore.DocumentData) =>
    d ? { firstName: d.firstName ?? '', lastName: d.lastName ?? '', role: d.role ?? '' } : undefined;
  const a = pick(after)!;
  const b = pick(before);
  if (b && b.firstName === a.firstName && b.lastName === a.lastName && b.role === a.role) return;
  await ref.set(a);
});

/**
 * Parent phone for a coach: only for approved coaches of a group the parent
 * belongs to. Parents never see each other's phones.
 */
export const getParentPhone = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const parentUid = request.data?.parentUid;
  if (typeof parentUid !== 'string' || !parentUid) throw new HttpsError('invalid-argument', 'parentUid is required');
  const coach = await loadUser(request.auth.uid);
  const groupsSnap = await db.collection('groups').where('coachIds', 'array-contains', request.auth.uid).get();
  const groups = groupsSnap.docs.map((g) => groupFrom(g.id, g.data()));
  if (!canCoachSeeParentPhone(coach, parentUid, groups)) throw new HttpsError('permission-denied', 'not allowed');
  const parent = await loadUser(parentUid);
  return { phone: parent?.phone ?? null };
});

async function deleteWhere(q: FirebaseFirestore.Query): Promise<number> {
  const snap = await q.get();
  for (let i = 0; i < snap.docs.length; i += 400) {
    const b = db.batch();
    snap.docs.slice(i, i + 400).forEach((d) => b.delete(d.ref));
    await b.commit();
  }
  return snap.size;
}

/** Per-doc updates; a doc deleted concurrently (NOT_FOUND) is skipped. */
async function updateWhere(q: FirebaseFirestore.Query, patch: Record<string, unknown>): Promise<number> {
  const snap = await q.get();
  for (const d of snap.docs) {
    await d.ref.update(patch).catch((e) => {
      if ((e as { code?: number }).code !== 5) throw e;
    });
  }
  return snap.size;
}

async function deletePrefix(prefix: string): Promise<void> {
  await bucket().deleteFiles({ prefix }).catch((e) => logger.warn('storage purge failed', { prefix, error: String(e) }));
}

/**
 * Deletes everything owned by a user. Children whose only parent is this
 * user are deleted with all certificates and files (onChildDeleted also
 * covers this — both paths are idempotent), RSVPs, attendance, feedback and
 * avatars; shared children are unlinked. Payments are kept for club
 * accounting with parentId anonymised to 'deleted'. Idempotent.
 */
export async function cleanupUserData(uid: string): Promise<{ deleted: string[]; unlinked: string[] }> {
  const childrenSnap = await db.collection('children').where('parentIds', 'array-contains', uid).get();
  const children = childrenSnap.docs.map((d) => childFrom(d.id, d.data()));
  const plan = planAccountDeletion(uid, children);

  for (const childId of plan.deleteChildIds) {
    const childRef = db.doc(`children/${childId}`);
    const childUserId = (await childRef.get()).get('userId');
    await purgeChildCertificates(childId);
    const groups = await db.collection('groups').where('memberChildIds', 'array-contains', childId).get();
    await Promise.all(groups.docs.map((g) => g.ref.update({ memberChildIds: FieldValue.arrayRemove(childId) })));
    const reqs = await db.collection('membershipRequests').where('childId', '==', childId).get();
    await Promise.all(reqs.docs.map((r) => r.ref.delete()));
    for (const coll of ['rsvps', 'attendance', 'feedback']) await deleteWhere(db.collection(coll).where('childId', '==', childId));
    await deletePrefix(`childPhotos/${childId}/`);
    await childRef.delete();
    if (typeof childUserId === 'string' && childUserId) {
      await db.doc(`users/${childUserId}`).delete();
      await auth().deleteUser(childUserId).catch(() => undefined);
    }
  }
  for (const childId of plan.unlinkChildIds) {
    await db.doc(`children/${childId}`).update({ parentIds: FieldValue.arrayRemove(uid) }).catch((e) => {
      if ((e as { code?: number }).code !== 5) throw e;
    });
  }
  const ownReqs = await db.collection('membershipRequests').where('parentId', '==', uid).get();
  await Promise.all(ownReqs.docs.map((r) => r.ref.delete()));
  // Payments are kept for club accounting but anonymised; RSVPs on shared children too.
  await updateWhere(db.collection('payments').where('parentId', '==', uid), { parentId: 'deleted' });
  await updateWhere(db.collection('rsvps').where('parentId', '==', uid), { parentId: 'deleted' });
  await deleteWhere(db.collection('notifications').where('userId', '==', uid));
  await deleteWhere(db.collection('invites').where('parentId', '==', uid));
  await db.doc(`userUnread/${uid}`).delete();
  await deletePrefix(`profiles/${uid}/`);
  await deletePrefix(`exports/${uid}/`);
  await db.doc(`users/${uid}`).delete();
  await db.doc(`publicProfiles/${uid}`).delete();
  return { deleted: plan.deleteChildIds, unlinked: plan.unlinkChildIds };
}

/** Self-service account deletion: clean up data, then delete the auth user. */
export const deleteAccount = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const result = await cleanupUserData(uid);
  await auth().deleteUser(uid).catch((e) => logger.warn('auth delete failed', { uid, error: String(e) }));
  logger.info('account deleted', { uid, ...result });
  return result;
});

/**
 * Auth user deleted by any path (console, Admin SDK, deleteAccount).
 * 2nd-gen functions have no auth onDelete trigger, so this one is 1st gen.
 */
export const onUserDeleted = functionsV1
  .region(REGION)
  .auth.user()
  .onDelete(async (user) => {
    const result = await cleanupUserData(user.uid);
    logger.info('onUserDeleted cleanup', { uid: user.uid, ...result });
  });
