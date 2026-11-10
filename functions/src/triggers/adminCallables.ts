// Admin callables. Every one checks claims server-side and writes auditLog.
// Platform admin = claim admin:true; club admin = claim clubAdmin:[clubId…].
import { logger } from 'firebase-functions';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, GeoPoint, Timestamp } from 'firebase-admin/firestore';
import { auth, db } from '../admin';
import { actorRoleOf, writeAudit } from '../audit';
import { loadUser } from '../convert';
import {
  AdminRole, AdminScope, adminScopeFromClaims, canActOnClub, canManageCoach, coachAuditAction, computeAdminClaims,
  isAnyAdmin, isSettableCoachStatus,
} from '../lib/adminScope';
import { cleanText } from '../lib/moderation';
import { encodeGeohash } from '../lib/geo';

interface Actor { uid: string; scope: AdminScope; role: string; name: string }

async function requireAdmin(request: CallableRequest, platformOnly = false): Promise<Actor> {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const scope = adminScopeFromClaims(request.auth.token as Record<string, unknown>);
  if (platformOnly ? !scope.platform : !isAnyAdmin(scope)) throw new HttpsError('permission-denied', platformOnly ? 'platform admin only' : 'admin only');
  const u = await loadUser(request.auth.uid);
  return {
    uid: request.auth.uid, scope,
    role: actorRoleOf(request.auth.token as Record<string, unknown>, u?.role),
    name: [u?.firstName, u?.lastName].filter(Boolean).join(' '),
  };
}

function idArg(v: unknown, name: string): string {
  if (typeof v !== 'string' || !v || v.includes('/') || v.length > 200) throw new HttpsError('invalid-argument', `${name} is required`);
  return v;
}

function strList(v: unknown, name: string, max = 50): string[] {
  if (!Array.isArray(v) || v.length > max || !v.every((x) => typeof x === 'string' && x && !x.includes('/'))) {
    throw new HttpsError('invalid-argument', `${name} must be a list of ids`);
  }
  return [...new Set(v as string[])];
}

/**
 * adminStats {} -> {parents, children, coaches, clubs, activeGroups,
 * upcomingTrainings, upcomingMatches, pendingCoaches, pendingRequests, openReports}
 * Platform admin: global count() aggregations. Club admin: scoped to their
 * clubs (parents/children = distinct members of the clubs' groups).
 */
export const adminStats = onCall(async (request) => {
  const a = await requireAdmin(request);
  const count = async (q: FirebaseFirestore.Query) => (await q.count().get()).data().count;
  const now = Timestamp.now();
  if (a.scope.platform) {
    const [parents, children, coaches, clubs, groups, archivedGroups, upcomingTrainings, upcomingMatches, pendingCoaches, pendingRequests, openReports] =
      await Promise.all([
        count(db.collection('users').where('role', '==', 'parent')),
        count(db.collection('children')),
        count(db.collection('users').where('role', '==', 'coach')),
        count(db.collection('clubs')),
        count(db.collection('groups')),
        count(db.collection('groups').where('status', '==', 'archived')),
        count(db.collection('trainings').where('startAt', '>=', now)),
        count(db.collection('matches').where('startAt', '>=', now)),
        count(db.collection('users').where('role', '==', 'coach').where('coachStatus', '==', 'pending')),
        count(db.collection('membershipRequests').where('status', '==', 'pending')),
        count(db.collection('reports').where('status', '==', 'open')),
      ]);
    return { scope: 'platform', parents, children, coaches, clubs, activeGroups: groups - archivedGroups, upcomingTrainings, upcomingMatches, pendingCoaches, pendingRequests, openReports };
  }
  const clubIds = a.scope.clubIds.slice(0, 30);
  const groupsSnap = await db.collection('groups').where('clubId', 'in', clubIds).get();
  const active = groupsSnap.docs.filter((g) => g.get('status') !== 'archived');
  const parents = new Set<string>(), children = new Set<string>();
  for (const g of active) {
    (g.get('parentIds') ?? []).forEach((p: string) => parents.add(p));
    (g.get('memberChildIds') ?? []).forEach((c: string) => children.add(c));
  }
  let upcomingTrainings = 0;
  const groupIds = active.map((g) => g.id);
  for (let i = 0; i < groupIds.length; i += 30) {
    upcomingTrainings += await count(db.collection('trainings').where('groupId', 'in', groupIds.slice(i, i + 30)).where('startAt', '>=', now));
  }
  const [coaches, upcomingMatches, pendingCoaches, pendingRequests, openReports] = await Promise.all([
    count(db.collection('users').where('role', '==', 'coach').where('clubIds', 'array-contains-any', clubIds)),
    count(db.collection('matches').where('clubId', 'in', clubIds).where('startAt', '>=', now)),
    count(db.collection('users').where('role', '==', 'coach').where('coachStatus', '==', 'pending').where('clubIds', 'array-contains-any', clubIds)),
    count(db.collection('membershipRequests').where('clubId', 'in', clubIds).where('status', '==', 'pending')),
    count(db.collection('reports').where('clubId', 'in', clubIds).where('status', '==', 'open')),
  ]);
  return {
    scope: 'club', clubIds, parents: parents.size, children: children.size, coaches, clubs: clubIds.length,
    activeGroups: active.length, upcomingTrainings, upcomingMatches, pendingCoaches, pendingRequests, openReports,
  };
});

/**
 * setCoachStatus {uid, status: approved|rejected|suspended|revoked, reason?}
 * reason (≥ 5 chars) is required for rejected/suspended/revoked.
 * Platform admin, or club admin when the coach's clubIds intersect theirs.
 * (Extends the v1.0 callable; same name and return shape.)
 */
export const setCoachStatus = onCall(async (request) => {
  const a = await requireAdmin(request);
  const { uid, status, reason } = (request.data ?? {}) as { uid?: unknown; status?: unknown; reason?: unknown };
  const target = idArg(uid, 'uid');
  if (!isSettableCoachStatus(status)) throw new HttpsError('invalid-argument', 'status must be approved, rejected, suspended or revoked');
  const ref = db.doc(`users/${target}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'user not found');
  if (snap.get('role') !== 'coach') throw new HttpsError('failed-precondition', 'user is not a coach');
  const coachClubs: string[] = snap.get('clubIds') ?? [];
  if (!canManageCoach(a.scope, coachClubs)) throw new HttpsError('permission-denied', 'coach is not in your clubs');
  const why = cleanText(reason, 500);
  if (status !== 'approved' && (!why || why.length < 5)) throw new HttpsError('invalid-argument', 'reason (≥ 5 characters) is required');
  await ref.update({ coachStatus: status, coachStatusReason: why ?? FieldValue.delete() });
  await writeAudit({
    action: coachAuditAction(status), actorId: a.uid, actorRole: a.role, actorName: a.name,
    targetType: 'user', targetId: target, clubId: coachClubs.find((c) => canActOnClub(a.scope, c)) ?? null,
    details: { from: snap.get('coachStatus') ?? null, to: status, reason: why },
  });
  logger.info('coach status set', { uid: target, status, by: a.uid });
  return { uid: target, coachStatus: status };
});

/**
 * setAdminRole {uid, role: 'platform'|'club'|null ('none' accepted), clubIds} — platform only.
 * Sets custom claims (admin / clubAdmin), mirrors users.adminRole/adminClubIds
 * and clubs.adminIds. A platform admin cannot demote themselves (lockout guard).
 */
export const setAdminRole = onCall(async (request) => {
  const a = await requireAdmin(request, true);
  const { uid, role: rawRole, clubIds } = (request.data ?? {}) as { uid?: unknown; role?: unknown; clubIds?: unknown };
  const target = idArg(uid, 'uid');
  const role = rawRole === null || rawRole === undefined ? 'none' : rawRole;
  if (role !== 'platform' && role !== 'club' && role !== 'none') throw new HttpsError('invalid-argument', 'role must be platform, club or none');
  const ids = role === 'club' ? strList(clubIds, 'clubIds', 30) : [];
  if (role === 'club' && ids.length === 0) throw new HttpsError('invalid-argument', 'clubIds required for a club admin');
  if (target === a.uid && role !== 'platform') throw new HttpsError('failed-precondition', 'cannot demote yourself');
  for (const c of ids) if (!(await db.doc(`clubs/${c}`).get()).exists) throw new HttpsError('not-found', `club ${c} not found`);

  const authUser = await auth().getUser(target).catch(() => null);
  if (!authUser) throw new HttpsError('not-found', 'auth user not found');
  const prevClubs = Array.isArray(authUser.customClaims?.clubAdmin) ? (authUser.customClaims!.clubAdmin as string[]) : [];
  const claims = computeAdminClaims(authUser.customClaims, role as AdminRole, ids);
  await auth().setCustomUserClaims(target, claims);

  const userRef = db.doc(`users/${target}`);
  if ((await userRef.get()).exists) {
    await userRef.update(role === 'none'
      ? { adminRole: FieldValue.delete(), adminClubIds: FieldValue.delete() }
      : { adminRole: role, adminClubIds: ids });
  }
  const batch = db.batch();
  for (const c of prevClubs.filter((c) => !ids.includes(c))) batch.set(db.doc(`clubs/${c}`), { adminIds: FieldValue.arrayRemove(target) }, { merge: true });
  for (const c of ids) batch.set(db.doc(`clubs/${c}`), { adminIds: FieldValue.arrayUnion(target) }, { merge: true });
  await batch.commit();
  await writeAudit({
    action: 'role.set', actorId: a.uid, actorRole: a.role, actorName: a.name, targetType: 'user', targetId: target,
    details: { role, clubIds: ids, previousClubIds: prevClubs },
  });
  return { uid: target, role: role === 'none' ? null : role, clubIds: ids };
});

const CLUB_FIELDS = ['name', 'address', 'phone', 'sportIds', 'description'] as const;

/** Club fields from {name, address, lat, lng, sportIds, phone?, description?}; location is a GeoPoint + geohash. */
function clubPatch(data: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (data.lat !== undefined || data.lng !== undefined) {
    const lat = Number(data.lat), lng = Number(data.lng);
    try {
      out.geohash = encodeGeohash(lat, lng);
    } catch {
      throw new HttpsError('invalid-argument', 'lat/lng');
    }
    out.location = new GeoPoint(lat, lng);
  }
  for (const k of CLUB_FIELDS) {
    if (!(k in data)) continue;
    const v = data[k];
    if (k === 'sportIds') out[k] = strList(v, 'sportIds');
    else {
      if (v !== null && (typeof v !== 'string' || v.length > 2000)) throw new HttpsError('invalid-argument', k);
      out[k] = v;
    }
  }
  return out;
}

/**
 * upsertClub {clubId?, name, address, …}: platform admin creates/updates any
 * club; a club admin may update details of their own clubs (never status or adminIds).
 */
export const upsertClub = onCall(async (request) => {
  const a = await requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const patch = clubPatch(data);
  if (typeof data.clubId === 'string' && data.clubId) {
    const clubId = idArg(data.clubId, 'clubId');
    if (!canActOnClub(a.scope, clubId)) throw new HttpsError('permission-denied', 'not your club');
    const ref = db.doc(`clubs/${clubId}`);
    if (!(await ref.get()).exists) throw new HttpsError('not-found', 'club not found');
    await ref.update({ ...patch, updatedAt: FieldValue.serverTimestamp() });
    await writeAudit({ action: 'club.update', actorId: a.uid, actorRole: a.role, actorName: a.name, targetType: 'club', targetId: clubId, clubId, details: { fields: Object.keys(patch) } });
    return { clubId };
  }
  if (!a.scope.platform) throw new HttpsError('permission-denied', 'platform admin only');
  if (typeof patch.name !== 'string' || !patch.name) throw new HttpsError('invalid-argument', 'name is required');
  const ref = db.collection('clubs').doc();
  await ref.set({ sportIds: [], ...patch, status: 'active', adminIds: [], createdAt: FieldValue.serverTimestamp() });
  await writeAudit({ action: 'club.create', actorId: a.uid, actorRole: a.role, actorName: a.name, targetType: 'club', targetId: ref.id, clubId: ref.id, details: { name: patch.name } });
  return { clubId: ref.id };
});

/** archiveClub {clubId, archived = true} — platform only. */
export const archiveClub = onCall(async (request) => {
  const a = await requireAdmin(request, true);
  const clubId = idArg(request.data?.clubId, 'clubId');
  const archived = request.data?.archived !== false;
  const ref = db.doc(`clubs/${clubId}`);
  if (!(await ref.get()).exists) throw new HttpsError('not-found', 'club not found');
  await ref.update({ status: archived ? 'archived' : 'active', updatedAt: FieldValue.serverTimestamp() });
  await writeAudit({ action: 'club.archive', actorId: a.uid, actorRole: a.role, actorName: a.name, targetType: 'club', targetId: clubId, clubId, details: { archived } });
  return { clubId, status: archived ? 'archived' : 'active' };
});

/**
 * assignCoach {clubId, coachId, assign}: platform admin or club admin of the
 * club. Maintains coachClubs/{coachId}_{clubId} and users.clubIds.
 */
export const assignCoach = onCall(async (request) => {
  const a = await requireAdmin(request);
  const clubId = idArg(request.data?.clubId, 'clubId');
  const coachId = idArg(request.data?.coachId, 'coachId');
  const assign = request.data?.assign !== false;
  if (!canActOnClub(a.scope, clubId)) throw new HttpsError('permission-denied', 'not your club');
  const userRef = db.doc(`users/${coachId}`);
  const u = await userRef.get();
  if (!u.exists || u.get('role') !== 'coach') throw new HttpsError('failed-precondition', 'user is not a coach');
  if (!(await db.doc(`clubs/${clubId}`).get()).exists) throw new HttpsError('not-found', 'club not found');
  const batch = db.batch();
  batch.set(db.doc(`coachClubs/${coachId}_${clubId}`), { coachId, clubId, status: assign ? 'active' : 'removed', updatedAt: FieldValue.serverTimestamp() });
  batch.update(userRef, { clubIds: assign ? FieldValue.arrayUnion(clubId) : FieldValue.arrayRemove(clubId) });
  await batch.commit();
  await writeAudit({ action: 'club.update', actorId: a.uid, actorRole: a.role, actorName: a.name, targetType: 'user', targetId: coachId, clubId, details: { coachAssigned: assign } });
  return { coachId, clubId, assigned: assign };
});

/** upsertSport {id? (or sportId), name, icon, category, ageMin?, requiresMedicalCert, active, order} — platform only. */
export const upsertSport = onCall(async (request) => {
  const a = await requireAdmin(request, true);
  const d = (request.data ?? {}) as Record<string, unknown>;
  if (typeof d.name !== 'string' || !d.name || d.name.length > 100) throw new HttpsError('invalid-argument', 'name');
  if (!['team', 'combat', 'other'].includes(String(d.category))) throw new HttpsError('invalid-argument', 'category');
  if (d.ageMin != null && (typeof d.ageMin !== 'number' || d.ageMin < 0 || d.ageMin > 30)) throw new HttpsError('invalid-argument', 'ageMin');
  const doc = {
    name: d.name,
    icon: typeof d.icon === 'string' ? d.icon : 'other',
    category: d.category,
    ageMin: d.ageMin ?? null,
    requiresMedicalCert: d.requiresMedicalCert === true,
    active: d.active !== false,
    order: typeof d.order === 'number' ? d.order : 100,
  };
  const sid = (typeof d.id === 'string' && d.id) || (typeof d.sportId === 'string' && d.sportId) || '';
  const ref = sid ? db.doc(`sports/${idArg(sid, 'id')}`) : db.collection('sports').doc();
  await ref.set(doc, { merge: true });
  await writeAudit({ action: 'sport.upsert', actorId: a.uid, actorRole: a.role, actorName: a.name, targetType: 'sport', targetId: ref.id, details: doc });
  return { id: ref.id, sportId: ref.id };
});

/**
 * updateGroup {groupId, name?, status?, coachIds?}
 * - platform admin / club admin of the group's club: name, status, coachIds
 *   (every coach must be an approved coach assigned to the club);
 * - approved coach of the group: name and status only.
 */
export const updateGroup = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const scope = adminScopeFromClaims(request.auth.token as Record<string, unknown>);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const groupId = idArg(d.groupId, 'groupId');
  const ref = db.doc(`groups/${groupId}`);
  const g = await ref.get();
  if (!g.exists) throw new HttpsError('not-found', 'group not found');
  const clubId: string = g.get('clubId');
  const user = await loadUser(uid);
  const isAdminOfClub = canActOnClub(scope, clubId);
  const isGroupCoach = user?.role === 'coach' && user.coachStatus === 'approved' && (g.get('coachIds') ?? []).includes(uid);
  if (!isAdminOfClub && !isGroupCoach) throw new HttpsError('permission-denied', 'not allowed');

  const patch: Record<string, unknown> = {};
  if (d.name !== undefined) {
    if (typeof d.name !== 'string' || !d.name.trim() || d.name.length > 100) throw new HttpsError('invalid-argument', 'name');
    patch.name = d.name.trim();
  }
  if (d.status !== undefined) {
    if (d.status !== 'active' && d.status !== 'archived') throw new HttpsError('invalid-argument', 'status');
    patch.status = d.status;
  }
  if (d.coachIds !== undefined) {
    if (!isAdminOfClub) throw new HttpsError('permission-denied', 'only admins change coaches');
    const ids = strList(d.coachIds, 'coachIds', 20);
    if (!ids.length) throw new HttpsError('invalid-argument', 'a group needs at least one coach');
    const snaps = await db.getAll(...ids.map((c) => db.doc(`users/${c}`)));
    const ok = snaps.every((s) => s.exists && s.get('role') === 'coach' && s.get('coachStatus') === 'approved' && (s.get('clubIds') ?? []).includes(clubId));
    if (!ok) throw new HttpsError('failed-precondition', 'every coach must be approved and assigned to the club');
    patch.coachIds = ids;
  }
  if (!Object.keys(patch).length) throw new HttpsError('invalid-argument', 'nothing to update');
  await ref.update({ ...patch, updatedAt: FieldValue.serverTimestamp() });
  await writeAudit({
    action: 'group.update', actorId: uid, actorRole: actorRoleOf(request.auth.token as Record<string, unknown>, user?.role),
    actorName: [user?.firstName, user?.lastName].filter(Boolean).join(' '),
    targetType: 'group', targetId: groupId, clubId, details: patch,
  });
  return { groupId, ...patch };
});
