import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../admin';
import { SMS_SECRETS } from '../config';
import { childFrom, groupFrom, loadUser, loadUsers, toDate } from '../convert';
import { normalizeLocale, pushText, t } from '../i18n';
import { tbilisiLocalToUtc } from '../lib/dates';
import { normalizeInviteCode } from '../lib/inviteCode';
import { InviteLite, isInviteAddressee, isUnclaimedPendingChild, normalizePhone, planInviteResponse, validateNewChild } from '../lib/invites';
import { SearchableChild, filterSearchResults, normalizeQuery, prefixVariants } from '../lib/search';
import { assignInviteCode } from './groups';
import { adminScopeFromClaims, canActOnClub } from '../lib/adminScope';
import { CoachDoc, hasRoom, parseCapacity, validGroupCoaches, withinGroupLimit } from '../lib/groupAdmin';
import { maskPhone } from '../lib/phone';
import { tbilisiDateKey } from '../lib/series';
import { smsSegments } from '../lib/sms/provider';
import { ChildLite, UserLite } from '../lib/types';
import { notify } from '../notify';
import { consumeRateLimit } from '../rateLimiter';
import { createSmsProvider } from '../sms';

function requireAuth(request: { auth?: { uid: string } }): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  return request.auth.uid;
}

function idArg(v: unknown, name: string): string {
  if (typeof v !== 'string' || !v || v.includes('/') || v.length > 200) throw new HttpsError('invalid-argument', `${name} is required`);
  return v;
}

async function requireParent(uid: string): Promise<UserLite> {
  const u = await loadUser(uid);
  if (!u || u.role !== 'parent') throw new HttpsError('permission-denied', 'parents only');
  return u;
}

/**
 * createInvite {groupId, childId?, child?: {firstName, lastName, birthDate, parentPhone}}
 * Approved coach of the (active) group. Either an existing child the coach can
 * already see (child.coachIds contains the coach, or a pending child they
 * created), or a NEW pending child (status pendingParent, parentIds []).
 * parentId is resolved by phone but nothing is linked: the parent decides in
 * respondInvite. Rate limit 30 invites / 24 h per coach. Push to a
 * registered parent, otherwise a (mock unless enabled) SMS logged in smsLog.
 */
export const createInvite = onCall({ secrets: SMS_SECRETS }, async (request) => {
  const uid = requireAuth(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const groupId = idArg(data.groupId, 'groupId');
  const coach = await loadUser(uid);
  const groupSnap = await db.doc(`groups/${groupId}`).get();
  if (!groupSnap.exists) throw new HttpsError('not-found', 'group not found');
  const group = groupFrom(groupSnap.id, groupSnap.data()!);
  // v1.9.1: the group's coach or an administrator of its organization.
  const scope = adminScopeFromClaims((request.auth?.token ?? {}) as Record<string, unknown>);
  const isCoach = !!coach && coach.role === 'coach' && coach.coachStatus === 'approved' && group.coachIds.includes(uid);
  if (!isCoach && !canActOnClub(scope, group.clubId)) {
    throw new HttpsError('permission-denied', 'coach of this group or its organization administrator only');
  }
  if (groupSnap.get('status') === 'archived') throw new HttpsError('failed-precondition', 'group is archived');

  await consumeRateLimit(uid, 'invites');

  let child: ChildLite;
  let phone: string | null;
  let addressee: string | null = null;
  if (typeof data.childId === 'string' && data.childId) {
    const childSnap = await db.doc(`children/${idArg(data.childId, 'childId')}`).get();
    if (!childSnap.exists) throw new HttpsError('not-found', 'child not found');
    child = childFrom(childSnap.id, childSnap.data()!);
    // Search flow: an active child (found via searchChildren) or a pending child this coach created.
    const pendingOwn = child.status === 'pendingParent' && child.createdByCoachId === uid;
    if (child.status === 'pendingParent' && !pendingOwn) throw new HttpsError('permission-denied', 'child not available');
    if (group.memberChildIds.includes(child.id)) throw new HttpsError('already-exists', 'child is already a member');
    if (!pendingOwn && child.parentIds.length === 0) throw new HttpsError('failed-precondition', 'child has no parent');
    addressee = child.parentIds[0] ?? null;
    phone = normalizePhone(data.phone);
    if (!phone && addressee) phone = normalizePhone((await loadUser(addressee))?.phone);
    if (!phone) phone = '';
    if (!phone && !addressee) throw new HttpsError('invalid-argument', 'phone is required');
  } else {
    const v = validateNewChild(data.pendingChild ?? data.child, tbilisiDateKey(new Date()));
    if (!v.ok) throw new HttpsError('invalid-argument', `invalid child: ${v.error}`);
    const [y, m, d] = v.value.birthDate.split('-').map(Number);
    const ref = db.collection('children').doc();
    await ref.set({
      firstName: v.value.firstName,
      lastName: v.value.lastName,
      birthDate: Timestamp.fromDate(tbilisiLocalToUtc(y, m, d, 0)),
      parentIds: [],
      status: 'pendingParent',
      createdByCoachId: uid,
    });
    child = { id: ref.id, firstName: v.value.firstName, lastName: v.value.lastName, parentIds: [], status: 'pendingParent', createdByCoachId: uid };
    phone = v.value.parentPhone;
  }

  // Resolve a registered parent by phone (no linking happens here).
  let parentId = addressee;
  if (!parentId && phone) {
    const parents = await db.collection('users').where('phone', '==', phone).where('role', '==', 'parent').limit(2).get();
    parentId = parents.size === 1 ? parents.docs[0].id : null;
  }

  const inviteRef = db.collection('invites').doc();
  await inviteRef.set({
    groupId,
    clubId: group.clubId ?? '',
    sportId: group.sportId ?? '',
    groupName: group.name ?? '',
    childId: child.id,
    childFirstName: child.firstName,
    childLastName: child.lastName ?? '',
    phone,
    parentId,
    status: 'sent',
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (parentId) {
    const parent = (await loadUsers([parentId])).get(parentId);
    if (parent) {
      await notify([parent], {
        type: 'groupInvite',
        ...pushText('groupInvite', { group: group.name ?? '', child: child.firstName }),
        route: `/invites/${inviteRef.id}`,
        args: { inviteId: inviteRef.id, groupId },
        groupId,
        dedupeKey: `invite:${inviteRef.id}`,
        data: { inviteId: inviteRef.id },
      });
    }
  } else if (phone) {
    const provider = createSmsProvider();
    // The phone has no account (no users.locale): Georgian unless the coach passes smsLocale.
    const text = t(normalizeLocale(data.smsLocale), 'sms.invite', { group: group.name ?? '', child: child.firstName });
    let status = 'failed';
    let providerResponse = '';
    try {
      const r = await provider.send(phone, text);
      status = r.ok ? (provider.name === 'mock' ? 'mocked' : 'sent') : 'failed';
      providerResponse = r.response;
    } catch (e) {
      providerResponse = String(e).slice(0, 300);
    }
    const seg = smsSegments(text);
    await db.collection('smsLog').add({
      at: FieldValue.serverTimestamp(), phone: maskPhone(phone), status, provider: provider.name, providerResponse,
      kind: 'invite', inviteId: inviteRef.id, segments: seg.segments, chars: seg.units,
    });
  }
  logger.info('invite created', { inviteId: inviteRef.id, groupId, registered: !!parentId });
  return { inviteId: inviteRef.id, childId: child.id };
});

/**
 * respondInvite {inviteId, accept, linkedChildId?, mediaConsent}
 * Only the addressed parent. See planInviteResponse for the semantics.
 * Runs in one transaction (double-accept safe).
 */
export const respondInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const inviteId = idArg(data.inviteId, 'inviteId');
  if (typeof data.accept !== 'boolean') throw new HttpsError('invalid-argument', 'accept must be boolean');
  const accept = data.accept;
  const mediaConsent = data.mediaConsent === true;
  const linkedChildId = typeof data.linkedChildId === 'string' && data.linkedChildId ? idArg(data.linkedChildId, 'linkedChildId') : null;
  await requireParent(uid);
  const verifiedPhone = (request.auth?.token as { phone_number?: string } | undefined)?.phone_number ?? null;

  const result = await db.runTransaction(async (tx) => {
    const inviteRef = db.doc(`invites/${inviteId}`);
    const inv = await tx.get(inviteRef);
    if (!inv.exists) throw new HttpsError('not-found', 'invite not found');
    const invite: InviteLite = { id: inv.id, ...(inv.data() as Omit<InviteLite, 'id'>) };
    if (!isInviteAddressee(invite, uid, verifiedPhone)) throw new HttpsError('permission-denied', 'not your invite');
    const groupRef = db.doc(`groups/${invite.groupId}`);
    const [groupSnap, inviteChildSnap, linkedSnap] = await Promise.all([
      tx.get(groupRef),
      invite.childId ? tx.get(db.doc(`children/${invite.childId}`)) : Promise.resolve(null),
      linkedChildId ? tx.get(db.doc(`children/${linkedChildId}`)) : Promise.resolve(null),
    ]);
    const inviteChild = inviteChildSnap?.exists ? childFrom(inviteChildSnap.id, inviteChildSnap.data()!) : undefined;
    const linkedChild = linkedSnap?.exists ? childFrom(linkedSnap.id, linkedSnap.data()!) : undefined;
    const plan = planInviteResponse({ invite, uid, accept, inviteChild, linkedChild, linkedChildId });
    if (plan.kind === 'error') throw new HttpsError(plan.code, plan.message);
    if (accept && (!groupSnap.exists || groupSnap.get('status') === 'archived')) {
      throw new HttpsError('failed-precondition', 'group is not available');
    }
    // v1.9.1: optional group capacity.
    if (accept && plan.kind !== 'decline' && !hasRoom(groupSnap.get('capacity'), groupSnap.get('memberChildIds') ?? [], plan.memberChildId)) {
      throw new HttpsError('resource-exhausted', 'groupFull');
    }

    const decided = { decidedAt: FieldValue.serverTimestamp(), decidedBy: uid, parentId: uid };
    const consent = { photoConsent: mediaConsent, mediaConsent, mediaConsentAt: FieldValue.serverTimestamp() };
    if (plan.kind === 'decline') {
      tx.update(inviteRef, { status: 'declined', ...decided });
      if (plan.deleteChildId) tx.delete(db.doc(`children/${plan.deleteChildId}`));
      return { status: 'declined', childId: null };
    }
    if (plan.kind === 'link') {
      tx.update(db.doc(`children/${plan.memberChildId}`), consent);
      if (plan.deleteChildId) tx.delete(db.doc(`children/${plan.deleteChildId}`));
      tx.update(inviteRef, { status: 'accepted', linkedChildId: plan.memberChildId, ...decided });
    } else if (plan.kind === 'claim') {
      tx.update(db.doc(`children/${plan.memberChildId}`), { parentIds: [uid], status: 'active', ...consent });
      tx.update(inviteRef, { status: 'accepted', linkedChildId: plan.memberChildId, ...decided });
    } else {
      tx.update(db.doc(`children/${plan.memberChildId}`), consent);
      tx.update(inviteRef, { status: 'accepted', linkedChildId: plan.memberChildId, ...decided });
    }
    tx.update(groupRef, { memberChildIds: FieldValue.arrayUnion(plan.memberChildId) });
    return { status: 'accepted', childId: plan.memberChildId };
  });

  // Tell the inviting coach.
  const invSnap = await db.doc(`invites/${inviteId}`).get();
  const coachId = invSnap.get('createdBy');
  if (coachId) {
    const coach = (await loadUsers([coachId])).get(coachId);
    if (coach) {
      await notify([coach], {
        type: 'inviteAnswered',
        ...pushText('inviteAnswered', (l) => ({
          child: invSnap.get('childFirstName') ?? '',
          answer: t(l, result.status === 'accepted' ? 'words.inviteAccepted' : 'words.inviteDeclined'),
        })),
        route: `/group/${invSnap.get('groupId')}`,
        args: { inviteId, groupId: invSnap.get('groupId') },
        groupId: invSnap.get('groupId'),
        dedupeKey: `invite:${inviteId}:${result.status}`,
      });
    }
  }
  return result;
});

/**
 * joinGroupByCode {code, childId}: parent of the child; creates a pending
 * membershipRequests doc (source 'code') that a coach approves (the existing
 * onMembershipRequestUpdated trigger adds the child). Rate-limited 20 / 24 h.
 */
export const joinGroupByCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const childId = idArg(data.childId, 'childId');
  const code = normalizeInviteCode(data.code);
  if (!code) throw new HttpsError('invalid-argument', 'invalid code');
  await requireParent(uid);
  await consumeRateLimit(uid, 'joinCode');
  const childSnap = await db.doc(`children/${childId}`).get();
  if (!childSnap.exists || !(childSnap.get('parentIds') ?? []).includes(uid)) throw new HttpsError('permission-denied', 'not your child');
  const idx = await db.doc(`groupCodes/${code}`).get();
  if (!idx.exists) throw new HttpsError('not-found', 'unknown code');
  const groupSnap = await db.doc(`groups/${idx.get('groupId')}`).get();
  if (!groupSnap.exists || groupSnap.get('status') === 'archived') throw new HttpsError('not-found', 'unknown code');
  const group = groupFrom(groupSnap.id, groupSnap.data()!);
  if (group.memberChildIds.includes(childId)) return { status: 'member', groupId: group.id, groupName: group.name ?? '' };
  const dup = await db.collection('membershipRequests')
    .where('childId', '==', childId).where('groupId', '==', group.id).where('status', '==', 'pending').limit(1).get();
  if (!dup.empty) return { status: 'pending', requestId: dup.docs[0].id, groupId: group.id, groupName: group.name ?? '' };
  const ref = await db.collection('membershipRequests').add({
    parentId: uid,
    childId,
    clubId: group.clubId ?? '',
    groupId: group.id,
    status: 'pending',
    source: 'code',
    childName: String(childSnap.get('firstName') ?? '').slice(0, 40),
    createdAt: FieldValue.serverTimestamp(),
  });
  return { status: 'pending', requestId: ref.id, groupId: group.id, groupName: group.name ?? '' };
});

/** leaveGroup {groupId, childId}: parent removes their child; onGroupWritten revokes access. */
export const leaveGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const groupId = idArg(data.groupId, 'groupId');
  const childId = idArg(data.childId, 'childId');
  await requireParent(uid);
  const childSnap = await db.doc(`children/${childId}`).get();
  if (!childSnap.exists || !(childSnap.get('parentIds') ?? []).includes(uid)) throw new HttpsError('permission-denied', 'not your child');
  const groupRef = db.doc(`groups/${groupId}`);
  const g = await groupRef.get();
  if (!g.exists || !(g.get('memberChildIds') ?? []).includes(childId)) throw new HttpsError('failed-precondition', 'child is not a member');
  await groupRef.update({ memberChildIds: FieldValue.arrayRemove(childId) });
  return { left: true };
});

/**
 * revokeInvite {inviteId}: approved coach of the invite's group; status
 * 'sent' -> 'revoked'; an unused coach-created pending child is deleted.
 */
export const revokeInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const inviteId = idArg(request.data?.inviteId, 'inviteId');
  const coach = await loadUser(uid);
  if (!coach || coach.role !== 'coach' || coach.coachStatus !== 'approved') throw new HttpsError('permission-denied', 'approved coaches only');
  return db.runTransaction(async (tx) => {
    const ref = db.doc(`invites/${inviteId}`);
    const inv = await tx.get(ref);
    if (!inv.exists) throw new HttpsError('not-found', 'invite not found');
    const g = await tx.get(db.doc(`groups/${inv.get('groupId')}`));
    if (!g.exists || !(g.get('coachIds') ?? []).includes(uid)) throw new HttpsError('permission-denied', 'not a coach of this group');
    if (inv.get('status') !== 'sent') throw new HttpsError('failed-precondition', `invite is ${inv.get('status')}`);
    const childId = inv.get('childId');
    const childSnap = childId ? await tx.get(db.doc(`children/${childId}`)) : null;
    const child = childSnap?.exists ? childFrom(childSnap.id, childSnap.data()!) : undefined;
    tx.update(ref, { status: 'revoked', decidedAt: FieldValue.serverTimestamp(), decidedBy: uid });
    const deleteChild = isUnclaimedPendingChild(child);
    if (deleteChild) tx.delete(childSnap!.ref);
    return { revoked: true, deletedPendingChild: deleteChild };
  });
});

/**
 * searchChildren {groupId, query} -> {results: [{childId, firstName, lastName, birthYear}]}
 * Approved coach of the group; ≥ 2 characters; prefix match on first or last
 * name; max 20; excludes pending children and current members; returns no
 * parent, contact or health fields. Rate-limited (200 / 24 h).
 */
export const searchChildren = onCall(async (request) => {
  const uid = requireAuth(request);
  const groupId = idArg(request.data?.groupId, 'groupId');
  const query = normalizeQuery(request.data?.query);
  if (!query) throw new HttpsError('invalid-argument', 'query must have at least 2 characters');
  const coach = await loadUser(uid);
  const g = await db.doc(`groups/${groupId}`).get();
  if (!coach || coach.role !== 'coach' || coach.coachStatus !== 'approved' || !g.exists || !(g.get('coachIds') ?? []).includes(uid)) {
    throw new HttpsError('permission-denied', 'coach of the group only');
  }
  await consumeRateLimit(uid, 'childSearch');
  const candidates: SearchableChild[] = [];
  for (const field of ['firstName', 'lastName']) {
    for (const p of prefixVariants(query)) {
      const snap = await db.collection('children').where(field, '>=', p).where(field, '<', p + '\uf8ff').limit(50).get();
      for (const d of snap.docs) {
        const bd = toDate(d.get('birthDate'));
        candidates.push({
          id: d.id, firstName: d.get('firstName') ?? '', lastName: d.get('lastName') ?? '',
          birthYear: bd ? bd.getUTCFullYear() : null, status: d.get('status') ?? 'active',
        });
      }
    }
  }
  return { results: filterSearchResults(candidates, query, g.get('memberChildIds') ?? []) };
});

/**
 * createGroup {clubId, sportId, name, ageMin, ageMax, scheduleNote?} -> {groupId, inviteCode}
 * Approved coach assigned to the (active) club; the caller becomes the only
 * coach; a unique invite code is assigned immediately.
 */
export const createGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const clubId = idArg(d.clubId, 'clubId');
  const sportId = idArg(d.sportId, 'sportId');
  const name = typeof d.name === 'string' ? d.name.trim() : '';
  if (!name || name.length > 100) throw new HttpsError('invalid-argument', 'name');
  const ageMin = Number(d.ageMin), ageMax = Number(d.ageMax);
  if (!Number.isInteger(ageMin) || !Number.isInteger(ageMax) || ageMin < 0 || ageMax > 30 || ageMin > ageMax) {
    throw new HttpsError('invalid-argument', 'age range');
  }
  const scheduleNote = d.scheduleNote == null ? null : String(d.scheduleNote).slice(0, 500);
  const capacity = parseCapacity(d.capacity);
  if (capacity === 'invalid') throw new HttpsError('invalid-argument', 'capacity');
  // v1.9.1: an organization administrator of this club (or a platform
  // admin) may create groups for its coaches; a coach creates groups for
  // themself. Nobody else.
  const scope = adminScopeFromClaims((request.auth?.token ?? {}) as Record<string, unknown>);
  const orgAdmin = canActOnClub(scope, clubId);
  let coachIds: string[];
  if (orgAdmin) {
    if (!Array.isArray(d.coachIds) || d.coachIds.length < 1 || d.coachIds.length > 20 ||
        !d.coachIds.every((x) => typeof x === 'string' && x && !x.includes('/'))) {
      throw new HttpsError('invalid-argument', 'coachIds');
    }
    coachIds = [...new Set(d.coachIds as string[])];
    const snaps = await db.getAll(...coachIds.map((c) => db.doc(`users/${c}`)));
    if (!validGroupCoaches(clubId, snaps.map((s) => (s.exists ? (s.data() as CoachDoc) : undefined)))) {
      throw new HttpsError('failed-precondition', 'every coach must be an approved coach of this organization');
    }
  } else {
    const coach = await loadUser(uid);
    const userSnap = await db.doc(`users/${uid}`).get();
    if (!coach || coach.role !== 'coach' || coach.coachStatus !== 'approved' || !(userSnap.get('clubIds') ?? []).includes(clubId)) {
      throw new HttpsError('permission-denied', 'approved coach of this club or its administrator only');
    }
    coachIds = [uid];
  }
  const club = await db.doc(`clubs/${clubId}`).get();
  if (!club.exists || club.get('status') === 'archived') throw new HttpsError('failed-precondition', 'club not available');
  // Organization must be active with full access, and within its group limit.
  const cfgSnap = await db.doc(`orgConfigs/${clubId}`).get();
  if (cfgSnap.exists) {
    const cfg = cfgSnap.data()!;
    if ((cfg.status ?? 'active') !== 'active' || (cfg.accessMode ?? 'full') !== 'full') {
      throw new HttpsError('failed-precondition', 'orgInactive');
    }
    const active = (await db.collection('groups').where('clubId', '==', clubId).where('status', '==', 'active').count().get()).data().count;
    if (!withinGroupLimit(active, cfg.limits?.maxGroups)) throw new HttpsError('resource-exhausted', 'limitGroups');
  }
  await consumeRateLimit(uid, 'createGroup');
  const ref = db.collection('groups').doc();
  await ref.set({
    clubId, sportId, name, ageMin, ageMax, scheduleNote, coachIds, memberChildIds: [], parentIds: [],
    createdBy: uid, status: 'active', inviteCode: '', createdAt: FieldValue.serverTimestamp(),
    ...(capacity === null ? {} : { capacity }),
  });
  const inviteCode = await assignInviteCode(ref.id);
  return { groupId: ref.id, inviteCode };
});
