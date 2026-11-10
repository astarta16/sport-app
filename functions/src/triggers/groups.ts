import { logger } from 'firebase-functions';
import { onDocumentDeleted, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../admin';
import { groupFrom, loadChildren } from '../convert';
import { computeChildCoachIds, computeGroupParentIds, diffIds, sameSet } from '../lib/membership';
import { purgeChildCertificates } from './certificates';

/**
 * Recomputes the server-managed children/{id}.groupIds and .coachIds from the
 * groups the child currently belongs to. Rules use coachIds to grant approved
 * coaches read access, so this is what revokes access when a child leaves.
 */
export async function syncChildMembership(childId: string): Promise<void> {
  const ref = db.doc(`children/${childId}`);
  const [childSnap, groupsSnap] = await Promise.all([
    ref.get(),
    db.collection('groups').where('memberChildIds', 'array-contains', childId).get(),
  ]);
  if (!childSnap.exists) return;
  const groups = groupsSnap.docs.map((d) => groupFrom(d.id, d.data()));
  const groupIds = groups.map((g) => g.id).sort();
  const coachIds = computeChildCoachIds(groups);
  const sportIds = [...new Set([...(childSnap.get('sportIds') ?? []), ...groups.map((g) => g.sportId).filter(Boolean)])] as string[];
  const cur = childSnap.data()!;
  if (sameSet(cur.groupIds ?? [], groupIds) && sameSet(cur.coachIds ?? [], coachIds) && sameSet(cur.sportIds ?? [], sportIds)) return;
  await ref.update({ groupIds, coachIds, sportIds });
}

/**
 * Public projection used by the club page / join flow: only name, sport, age
 * range and schedule — never member, parent or coach ids.
 */
export function publicGroupFields(data: FirebaseFirestore.DocumentData): Record<string, unknown> {
  return {
    name: data.name ?? '',
    sportId: data.sportId ?? '',
    ageMin: data.ageMin ?? 0,
    ageMax: data.ageMax ?? 18,
    scheduleNote: data.scheduleNote ?? null,
  };
}

async function syncPublicGroup(groupId: string, beforeClubId: string | undefined, after?: FirebaseFirestore.DocumentData) {
  if (beforeClubId && beforeClubId !== after?.clubId) {
    await db.doc(`clubs/${beforeClubId}/publicGroups/${groupId}`).delete();
  }
  if (after?.clubId) {
    await db.doc(`clubs/${after.clubId}/publicGroups/${groupId}`).set(publicGroupFields(after));
  }
}

/**
 * 6. groups/{groupId} written: maintain group.parentIds (denormalized for
 *    rules), sync each affected child's groupIds/coachIds, and write an audit
 *    entry for membership / coach changes.
 */
export const onGroupWritten = onDocumentWritten('groups/{groupId}', async (event) => {
  const groupId = event.params.groupId;
  const before = event.data?.before.exists ? groupFrom(groupId, event.data.before.data()!) : undefined;
  const after = event.data?.after.exists ? groupFrom(groupId, event.data.after.data()!) : undefined;

  const members = diffIds(before?.memberChildIds, after?.memberChildIds);
  const coaches = diffIds(before?.coachIds, after?.coachIds);
  const coachesChanged = coaches.added.length + coaches.removed.length > 0;

  if (after) {
    const children = await loadChildren(after.memberChildIds);
    const parentIds = computeGroupParentIds(after.memberChildIds, children);
    if (!sameSet(after.parentIds, parentIds)) {
      await event.data!.after.ref.update({ parentIds });
    }
  }

  await syncPublicGroup(groupId, before?.clubId, event.data?.after.exists ? event.data.after.data() : undefined);

  const affected = new Set<string>([...members.added, ...members.removed]);
  if (coachesChanged || !after) {
    (after?.memberChildIds ?? before?.memberChildIds ?? []).forEach((c) => affected.add(c));
  }
  for (const childId of affected) await syncChildMembership(childId);

  if (members.added.length || members.removed.length || coachesChanged || !after || !before) {
    await db.collection('groupAuditLog').add({
      groupId,
      at: FieldValue.serverTimestamp(),
      action: !before ? 'created' : !after ? 'deleted' : 'membership_changed',
      childrenAdded: members.added,
      childrenRemoved: members.removed,
      coachesAdded: coaches.added,
      coachesRemoved: coaches.removed,
    });
    logger.info('group membership changed', { groupId, ...members, coaches });
  }
});

/**
 * Membership request approved (by a coach of the club, see rules): add the
 * child to the chosen group. onGroupWritten then updates parentIds etc.
 */
export const onMembershipRequestUpdated = onDocumentUpdated('membershipRequests/{requestId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.status === 'approved' || after.status !== 'approved' || !after.groupId) return;

  const [childSnap, groupSnap] = await Promise.all([
    db.doc(`children/${after.childId}`).get(),
    db.doc(`groups/${after.groupId}`).get(),
  ]);
  const valid =
    childSnap.exists &&
    groupSnap.exists &&
    (childSnap.get('parentIds') ?? []).includes(after.parentId) &&
    groupSnap.get('clubId') === after.clubId;
  if (!valid) {
    logger.warn('membership approval rejected by server check', { requestId: event.params.requestId });
    await event.data!.after.ref.update({ status: 'rejected' });
    return;
  }
  await groupSnap.ref.update({ memberChildIds: FieldValue.arrayUnion(after.childId) });
});

/**
 * Child deleted (by a parent or by account deletion): remove from all groups
 * and delete all medical certificates + files.
 */
export const onChildDeleted = onDocumentDeleted('children/{childId}', async (event) => {
  const childId = event.params.childId;
  const groups = await db.collection('groups').where('memberChildIds', 'array-contains', childId).get();
  await Promise.all(groups.docs.map((g) => g.ref.update({ memberChildIds: FieldValue.arrayRemove(childId) })));
  const n = await purgeChildCertificates(childId);
  logger.info('child deleted: cleaned up', { childId, groups: groups.size, certificates: n });
});
