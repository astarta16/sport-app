import { logger } from 'firebase-functions';
import * as functionsV1 from 'firebase-functions/v1';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { auth, db } from '../admin';
import { REGION } from '../config';
import { childFrom, groupFrom, loadUser } from '../convert';
import { canCoachSeeParentPhone, isValidCoachDecision, planAccountDeletion } from '../lib/access';
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

/** 8. Admin-only (custom claim admin == true): approve or reject a coach. */
export const setCoachStatus = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  if (request.auth.token.admin !== true) throw new HttpsError('permission-denied', 'admin only');
  const { uid, status } = (request.data ?? {}) as { uid?: unknown; status?: unknown };
  if (typeof uid !== 'string' || !uid) throw new HttpsError('invalid-argument', 'uid is required');
  if (!isValidCoachDecision(status)) throw new HttpsError('invalid-argument', 'status must be approved or rejected');

  const ref = db.doc(`users/${uid}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'user not found');
  if (snap.get('role') !== 'coach') throw new HttpsError('failed-precondition', 'user is not a coach');
  await ref.update({ coachStatus: status });
  logger.info('coach status set', { uid, status, by: request.auth.uid });
  return { uid, coachStatus: status };
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

/**
 * Deletes everything owned by a user. Children whose only parent is this
 * user are deleted with all certificates and files (onChildDeleted also
 * covers this — both paths are idempotent); shared children are unlinked.
 * Payments are kept as financial records (see docs/backend.md).
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
    await childRef.delete();
    if (typeof childUserId === 'string' && childUserId) {
      await db.doc(`users/${childUserId}`).delete();
      await auth().deleteUser(childUserId).catch(() => undefined);
    }
  }
  for (const childId of plan.unlinkChildIds) {
    await db.doc(`children/${childId}`).update({ parentIds: FieldValue.arrayRemove(uid) });
  }
  const ownReqs = await db.collection('membershipRequests').where('parentId', '==', uid).get();
  await Promise.all(ownReqs.docs.map((r) => r.ref.delete()));
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
