// v1.7 multi-tenant SaaS callables and triggers.
//
// Tenant = club document (organizationId == clubId). Every callable checks
// the caller's claims (platform admin: admin:true; organization admin:
// clubAdmin:[clubId…]) and the organization's feature flags server-side,
// and writes the audit log. Room bookings are created in Firestore
// transactions that read and write one lock document per room and local
// day, so two administrators can never reserve overlapping slots.
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { FieldValue, GeoPoint, Timestamp } from 'firebase-admin/firestore';
import { auth, db } from '../admin';
import { AuditAction, writeAudit } from '../audit';
import { loadGroup, loadUser, loadUsers } from '../convert';
import { notify } from '../notify';
import { pushText } from '../i18n';
import { consumeRateLimit } from '../rateLimiter';
import { adminScopeFromClaims, canActOnClub, computeAdminClaims } from '../lib/adminScope';
import { encodeGeohash } from '../lib/geo';
import { receiptRecipients } from '../lib/v14';
import {
  Module, MODULES, OrgConfigDoc, Plan, RESTRICTED, checkOrgModuleChange, effectiveConfig, isModuleOn, planLimits,
  planModules, sanitizeModules,
} from '../lib/orgs';
import {
  Booking, BookingKind, Conflict, Room, STANDARD_HOURS, WeeklyRule, alternatives, blocking, checkBooking, lockKeys,
  normalizeTz, occurrences, MAX_DURATION_MS,
} from '../lib/scheduling';
import { Game, GAMES, Period, Result, ageBandOf, pseudonymFor, rank, score } from '../lib/scoring';
import { TZ_OFFSETS_MIN as TZ_SHIFT } from '../lib/scheduling';
import { postSystemMessage } from './chat';

// ─── helpers ────────────────────────────────────────────────────────────

function id(v: unknown, name: string): string {
  if (typeof v !== 'string' || !v || v.includes('/') || v.length > 200) throw new HttpsError('invalid-argument', `${name} required`);
  return v;
}

function str(v: unknown, name: string, min: number, max: number): string {
  const s = typeof v === 'string' ? v.trim() : '';
  if (s.length < min || s.length > max) throw new HttpsError('invalid-argument', `${name} length`);
  return s;
}

function int(v: unknown, name: string, min: number, max: number): number {
  if (typeof v !== 'number' || !Number.isInteger(v) || v < min || v > max) throw new HttpsError('invalid-argument', `${name} out of range`);
  return v;
}

function scope(request: CallableRequest) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  return adminScopeFromClaims(request.auth.token as Record<string, unknown>);
}

function requirePlatform(request: CallableRequest): string {
  if (!scope(request).platform) throw new HttpsError('permission-denied', 'platform admin only');
  return request.auth!.uid;
}

/** Platform admin, or an administrator of THIS organization (never another). */
function requireOrgAdmin(request: CallableRequest, orgId: string): string {
  if (!canActOnClub(scope(request), orgId)) throw new HttpsError('permission-denied', 'not an administrator of this organization');
  return request.auth!.uid;
}

async function orgConfig(orgId: string): Promise<OrgConfigDoc | undefined> {
  const s = await db.doc(`orgConfigs/${orgId}`).get();
  return s.exists ? (s.data() as OrgConfigDoc) : undefined;
}

async function requireModule(orgId: string, m: Module): Promise<OrgConfigDoc | undefined> {
  const cfg = await orgConfig(orgId);
  if (!isModuleOn(cfg, m)) throw new HttpsError('failed-precondition', `moduleDisabled:${m}`);
  return cfg;
}

async function requireClub(orgId: string) {
  const c = await db.doc(`clubs/${orgId}`).get();
  if (!c.exists) throw new HttpsError('not-found', 'organization not found');
  return c;
}

async function audit(action: AuditAction, actorId: string, targetType: string, targetId: string, clubId: string, details: Record<string, unknown> = {}) {
  const u = await loadUser(actorId);
  await writeAudit({
    action, actorId, actorRole: 'admin', actorName: [u?.firstName, u?.lastName].filter(Boolean).join(' '),
    targetType, targetId, clubId, details,
  });
}

// ─── organizations ──────────────────────────────────────────────────────

/** Platform admin creates a tenant: club document + orgConfigs document. */
export const createOrganization = onCall(async (request) => {
  const actor = requirePlatform(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const name = str(d.name, 'name', 2, 120);
  const address = str(d.address, 'address', 2, 300);
  const lat = Number(d.lat), lng = Number(d.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) {
    throw new HttpsError('invalid-argument', 'location');
  }
  const plan = (['free', 'standard', 'premium'].includes(d.plan as string) ? d.plan : 'standard') as Plan;
  const sportIds = Array.isArray(d.sportIds) ? (d.sportIds as unknown[]).filter((s): s is string => typeof s === 'string').slice(0, 30) : [];
  const branding = (d.branding ?? {}) as Record<string, unknown>;
  const color = typeof branding.primaryColor === 'number' ? branding.primaryColor : 0xff1d4ed8;
  if (color < 0xff000000 || color > 0xffffffff) throw new HttpsError('invalid-argument', 'brandColor');
  const ref = db.collection('clubs').doc();
  const batch = db.batch();
  batch.set(ref, {
    name, address, sportIds, phone: typeof d.phone === 'string' ? d.phone : null,
    description: typeof d.description === 'string' ? d.description.slice(0, 1000) : null,
    location: new GeoPoint(lat, lng), geohash: encodeGeohash(lat, lng, 9), status: 'active', adminIds: [],
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(db.doc(`orgConfigs/${ref.id}`), {
    status: 'active', plan,
    allowedModules: planModules(plan),
    // Child-safety default: restricted modules start switched off.
    enabledModules: planModules(plan).filter((m) => !RESTRICTED.includes(m)),
    branding: {
      names: typeof branding.names === 'object' && branding.names ? branding.names : { ka: name },
      primaryColor: color, description: '', address, logoUrl: null, contactPhone: null, contactEmail: null,
    },
    timezone: normalizeTz(d.timezone),
    defaultLanguage: ['ka', 'en', 'ru'].includes(d.defaultLanguage as string) ? d.defaultLanguage : 'ka',
    limits: planLimits(plan), leaderboard: { enabled: false, minParticipants: 3, byAgeBand: true, periods: ['week', 'month'], games: [] },
    bookingBufferMin: 0, updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  await audit('org.create', actor, 'club', ref.id, ref.id, { name, plan });
  return { id: ref.id };
});

/** Platform-only fields: status, plan, allowed modules, limits. */
export const updateOrgPlatform = onCall(async (request) => {
  const actor = requirePlatform(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  await requireClub(orgId);
  const old = effectiveConfig(await orgConfig(orgId));
  const patch: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
  if (d.status !== undefined) {
    if (!['active', 'suspended', 'deactivated'].includes(d.status as string)) throw new HttpsError('invalid-argument', 'status');
    patch.status = d.status;
  }
  let allowed = old.allowedModules as Module[];
  if (d.plan !== undefined) {
    if (!['free', 'standard', 'premium'].includes(d.plan as string)) throw new HttpsError('invalid-argument', 'plan');
    patch.plan = d.plan;
    allowed = planModules(d.plan as Plan);
  }
  if (d.allowedModules !== undefined) {
    try {
      allowed = sanitizeModules(d.allowedModules);
    } catch {
      throw new HttpsError('invalid-argument', 'allowedModules');
    }
  }
  patch.allowedModules = allowed;
  // Withdrawing a module also switches it off.
  patch.enabledModules = (old.enabledModules as string[]).filter((m) => allowed.includes(m as Module));
  if (d.limits !== undefined) {
    const l = d.limits as Record<string, unknown>;
    patch.limits = {
      maxStudents: int(l.maxStudents, 'maxStudents', 1, 100000), maxCoaches: int(l.maxCoaches, 'maxCoaches', 1, 10000),
      maxRooms: int(l.maxRooms, 'maxRooms', 0, 1000), maxGroups: int(l.maxGroups, 'maxGroups', 1, 10000),
    };
  }
  await db.doc(`orgConfigs/${orgId}`).set(patch, { merge: true });
  if (patch.status) await db.doc(`clubs/${orgId}`).set({ status: patch.status === 'deactivated' ? 'archived' : 'active' }, { merge: true });
  await audit('org.platform', actor, 'club', orgId, orgId, { status: patch.status ?? null, plan: patch.plan ?? null, allowed });
  return { ok: true };
});

/** Organization-admin settings; enabled modules must stay within the allowed set. */
export const updateOrgSettings = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const actor = requireOrgAdmin(request, orgId);
  await requireClub(orgId);
  const cfg = await orgConfig(orgId);
  const eff = effectiveConfig(cfg);
  if (eff.status !== 'active') throw new HttpsError('failed-precondition', 'orgInactive');
  const patch: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
  if (d.enabledModules !== undefined) {
    let mods: Module[];
    try {
      mods = sanitizeModules(d.enabledModules);
    } catch {
      throw new HttpsError('invalid-argument', 'enabledModules');
    }
    const err = checkOrgModuleChange(cfg, mods);
    if (err) throw new HttpsError('permission-denied', err);
    patch.enabledModules = mods;
  }
  if (d.branding !== undefined) {
    const b = d.branding as Record<string, unknown>;
    const color = typeof b.primaryColor === 'number' ? b.primaryColor : 0xff1d4ed8;
    if (color < 0xff000000 || color > 0xffffffff) throw new HttpsError('invalid-argument', 'brandColor');
    const names: Record<string, string> = {};
    for (const k of ['ka', 'en', 'ru']) {
      const v = (b.names as Record<string, unknown> | undefined)?.[k];
      if (typeof v === 'string' && v.trim()) names[k] = v.trim().slice(0, 120);
    }
    const logo = typeof b.logoUrl === 'string' && /^https:\/\//.test(b.logoUrl) ? b.logoUrl.slice(0, 500) : null;
    patch.branding = {
      names, primaryColor: color, logoUrl: logo,
      description: typeof b.description === 'string' ? b.description.slice(0, 1000) : '',
      contactPhone: typeof b.contactPhone === 'string' ? b.contactPhone.slice(0, 30) : null,
      contactEmail: typeof b.contactEmail === 'string' ? b.contactEmail.slice(0, 120) : null,
      address: typeof b.address === 'string' ? b.address.slice(0, 300) : '',
    };
  }
  if (d.defaultLanguage !== undefined) {
    if (!['ka', 'en', 'ru'].includes(d.defaultLanguage as string)) throw new HttpsError('invalid-argument', 'language');
    patch.defaultLanguage = d.defaultLanguage;
  }
  if (d.timezone !== undefined) patch.timezone = normalizeTz(d.timezone);
  if (d.bookingBufferMin !== undefined) patch.bookingBufferMin = int(d.bookingBufferMin, 'bookingBufferMin', 0, 120);
  if (d.leaderboard !== undefined) {
    const l = d.leaderboard as Record<string, unknown>;
    if (l.enabled === true && !(eff.allowedModules as string[]).includes('leaderboards')) {
      throw new HttpsError('permission-denied', 'moduleNotAllowed:leaderboards');
    }
    patch.leaderboard = {
      enabled: l.enabled === true,
      games: Array.isArray(l.games) ? (l.games as unknown[]).filter((g): g is Game => GAMES.includes(g as Game)) : [],
      periods: Array.isArray(l.periods) ? (l.periods as unknown[]).filter((p) => ['week', 'month', 'allTime'].includes(p as string)) : ['week'],
      byAgeBand: l.byAgeBand !== false,
      minParticipants: typeof l.minParticipants === 'number' ? Math.min(50, Math.max(2, Math.round(l.minParticipants))) : 3,
    };
  }
  if (d.sportIds !== undefined) {
    const ids = Array.isArray(d.sportIds) ? (d.sportIds as unknown[]).filter((s): s is string => typeof s === 'string') : [];
    for (const s of ids) if (!(await db.doc(`sports/${s}`).get()).exists) throw new HttpsError('invalid-argument', 'sport');
    await db.doc(`clubs/${orgId}`).set({ sportIds: ids }, { merge: true });
  }
  await db.doc(`orgConfigs/${orgId}`).set(patch, { merge: true });
  await audit('org.settings', actor, 'club', orgId, orgId, { fields: Object.keys(patch) });
  return { ok: true };
});

/** Platform admin assigns/removes an organization administrator (claims). */
export const setOrgAdmin = onCall(async (request) => {
  const actor = requirePlatform(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const target = id(d.userId, 'userId');
  if (target === actor) throw new HttpsError('failed-precondition', 'cannot change own role');
  await requireClub(orgId);
  const u = await auth().getUser(target).catch(() => null);
  if (!u) throw new HttpsError('not-found', 'user');
  const claims = (u.customClaims ?? {}) as Record<string, unknown>;
  if (claims.admin === true) throw new HttpsError('failed-precondition', 'already platform admin');
  const current = Array.isArray(claims.clubAdmin) ? (claims.clubAdmin as string[]) : [];
  const next = d.admin === true ? [...new Set([...current, orgId])] : current.filter((c) => c !== orgId);
  await auth().setCustomUserClaims(target, computeAdminClaims(u.customClaims, next.length ? 'club' : 'none', next));
  await db.doc(`users/${target}`).set(next.length ? { adminRole: 'club', adminClubIds: next } : { adminRole: FieldValue.delete(), adminClubIds: FieldValue.delete() }, { merge: true });
  await db.doc(`clubs/${orgId}`).set({ adminIds: d.admin === true ? FieldValue.arrayUnion(target) : FieldValue.arrayRemove(target) }, { merge: true });
  await db.doc(`clubs/${orgId}/orgMembers/${target}`).set(
    { orgId, userId: target, roles: d.admin === true ? FieldValue.arrayUnion('admin') : FieldValue.arrayRemove('admin'), active: true },
    { merge: true },
  );
  await audit(d.admin === true ? 'org.admin.assign' : 'org.admin.remove', actor, 'user', target, orgId);
  return { ok: true };
});

/** Organization admin adds/removes an approved coach (limit-checked). */
export const setOrgCoach = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const actor = requireOrgAdmin(request, orgId);
  const coachId = id(d.coachId, 'coachId');
  const coach = await loadUser(coachId);
  if (!coach || coach.role !== 'coach') throw new HttpsError('failed-precondition', 'notCoach');
  const cfg = effectiveConfig(await orgConfig(orgId));
  if (cfg.status !== 'active') throw new HttpsError('failed-precondition', 'orgInactive');
  if (d.member === true) {
    const n = (await db.collection('users').where('role', '==', 'coach').where('clubIds', 'array-contains', orgId).count().get()).data().count;
    if (n >= (cfg.limits?.maxCoaches ?? planLimits(cfg.plan ?? 'standard').maxCoaches)) throw new HttpsError('resource-exhausted', 'limitCoaches');
  }
  await db.doc(`users/${coachId}`).set({ clubIds: d.member === true ? FieldValue.arrayUnion(orgId) : FieldValue.arrayRemove(orgId) }, { merge: true });
  await db.doc(`clubs/${orgId}/orgMembers/${coachId}`).set(
    { orgId, userId: coachId, roles: d.member === true ? FieldValue.arrayUnion('coach') : FieldValue.arrayRemove('coach'), active: true },
    { merge: true },
  );
  await audit(d.member === true ? 'org.coach.add' : 'org.coach.remove', actor, 'user', coachId, orgId);
  return { ok: true };
});

export const upsertProgram = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId ?? d.clubId, 'orgId');
  const actor = requireOrgAdmin(request, orgId);
  const cfg = effectiveConfig(await orgConfig(orgId));
  if (cfg.status !== 'active') throw new HttpsError('failed-precondition', 'orgInactive');
  const club = await requireClub(orgId);
  const sportId = id(d.sportId, 'sportId');
  if (!((club.get('sportIds') ?? []) as string[]).includes(sportId)) throw new HttpsError('failed-precondition', 'sportNotInOrg');
  const ageMin = int(d.ageMin, 'ageMin', 3, 99), ageMax = int(d.ageMax, 'ageMax', 3, 99);
  if (ageMin > ageMax) throw new HttpsError('invalid-argument', 'programAge');
  const groupIds = Array.isArray(d.groupIds) ? (d.groupIds as string[]) : [];
  for (const g of groupIds) if ((await loadGroup(g))?.clubId !== orgId) throw new HttpsError('permission-denied', 'wrongTenant');
  const ref = typeof d.id === 'string' && d.id ? db.doc(`clubs/${orgId}/programs/${id(d.id, 'id')}`) : db.collection(`clubs/${orgId}/programs`).doc();
  await ref.set({
    orgId, clubId: orgId, sportId, name: str(d.name, 'name', 2, 80), description: typeof d.description === 'string' ? d.description.slice(0, 1000) : '',
    ageMin, ageMax, coachIds: Array.isArray(d.coachIds) ? d.coachIds : [], groupIds, roomId: typeof d.roomId === 'string' ? d.roomId : null,
    venueId: typeof d.venueId === 'string' ? d.venueId : null, scheduleNote: typeof d.scheduleNote === 'string' ? d.scheduleNote.slice(0, 200) : '',
    capacity: int(d.capacity, 'capacity', 1, 500), status: ['active', 'paused', 'archived'].includes(d.status as string) ? d.status : 'active',
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  await audit('program.upsert', actor, 'program', ref.id, orgId);
  return { id: ref.id };
});

// ─── rooms and bookings ─────────────────────────────────────────────────

function roomFrom(id: string, d: FirebaseFirestore.DocumentData): Room {
  const hours: Record<number, [number, number]> = {};
  for (const [k, v] of Object.entries(d.hours ?? {})) if (Array.isArray(v) && v.length === 2) hours[Number(k)] = [Number(v[0]), Number(v[1])];
  return { id, orgId: d.orgId ?? d.clubId, capacity: d.capacity ?? 30, status: d.status ?? 'active', hours: Object.keys(hours).length ? hours : STANDARD_HOURS };
}

function bookingFrom(id: string, d: FirebaseFirestore.DocumentData): Booking {
  const ms = (v: unknown) => (v instanceof Timestamp ? v.toMillis() : typeof v === 'string' ? Date.parse(v) : Number(v));
  return {
    id, orgId: d.orgId ?? d.clubId, roomId: d.roomId, kind: d.kind ?? 'training', startMs: ms(d.startAt), endMs: ms(d.endAt),
    status: d.status ?? 'active', coachId: d.coachId ?? null, groupId: d.groupId ?? null,
    expectedAttendees: d.expectedAttendees ?? null, seriesId: d.seriesId ?? null,
  };
}

export const upsertRoom = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId ?? d.clubId, 'orgId');
  const actor = requireOrgAdmin(request, orgId);
  const cfg = await requireModule(orgId, 'roomScheduling');
  const isNew = !(typeof d.id === 'string' && d.id);
  if (isNew) {
    const n = (await db.collection(`clubs/${orgId}/rooms`).where('status', '!=', 'archived').count().get()).data().count;
    if (n >= (cfg?.limits?.maxRooms ?? 5)) throw new HttpsError('resource-exhausted', 'limitRooms');
  }
  const ref = isNew ? db.collection(`clubs/${orgId}/rooms`).doc() : db.doc(`clubs/${orgId}/rooms/${id(d.id, 'id')}`);
  await ref.set({
    orgId, clubId: orgId, name: str(d.name, 'name', 2, 60), capacity: int(d.capacity, 'capacity', 1, 1000),
    sportIds: Array.isArray(d.sportIds) ? d.sportIds : [], hours: typeof d.hours === 'object' && d.hours ? d.hours : STANDARD_HOURS,
    status: ['active', 'unavailable', 'archived'].includes(d.status as string) ? d.status : 'active',
    venueId: typeof d.venueId === 'string' ? d.venueId : null, note: typeof d.note === 'string' ? d.note.slice(0, 300) : null,
  }, { merge: true });
  await audit(isNew ? 'room.create' : 'room.update', actor, 'room', ref.id, orgId);
  return { id: ref.id };
});

export const setRoomStatus = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const actor = requireOrgAdmin(request, orgId);
  await requireModule(orgId, 'roomScheduling');
  if (!['active', 'unavailable', 'archived'].includes(d.status as string)) throw new HttpsError('invalid-argument', 'status');
  const ref = db.doc(`clubs/${orgId}/rooms/${id(d.roomId, 'roomId')}`);
  if (!(await ref.get()).exists) throw new HttpsError('not-found', 'room');
  await ref.update({ status: d.status });
  await audit('room.status', actor, 'room', ref.id, orgId, { status: d.status });
  return { ok: true };
});

interface Draft {
  orgId: string; roomId: string; kind: BookingKind; startMs: number; endMs: number; title: string;
  coachId: string | null; groupId: string | null; programId: string | null; sportId: string | null;
  expectedAttendees: number | null; allowGroupOverlap: boolean;
}

function parseDraft(d: Record<string, unknown>): Draft {
  const startMs = Date.parse(String(d.startAt)), endMs = Date.parse(String(d.endAt));
  if (!Number.isFinite(startMs) || !Number.isFinite(endMs)) throw new HttpsError('invalid-argument', 'times');
  const kind = (['training', 'match', 'event', 'maintenance'].includes(d.kind as string) ? d.kind : 'training') as BookingKind;
  const opt = (v: unknown) => (typeof v === 'string' && v && !v.includes('/') ? v : null);
  return {
    orgId: id(d.orgId ?? d.clubId, 'orgId'), roomId: id(d.roomId, 'roomId'), kind, startMs, endMs,
    title: typeof d.title === 'string' ? d.title.slice(0, 120) : '',
    coachId: kind === 'maintenance' ? null : opt(d.coachId), groupId: kind === 'maintenance' ? null : opt(d.groupId),
    programId: opt(d.programId), sportId: opt(d.sportId),
    expectedAttendees: typeof d.expectedAttendees === 'number' ? Math.round(d.expectedAttendees) : null,
    allowGroupOverlap: d.allowGroupOverlap === true,
  };
}

function reject(conflicts: Conflict[], alts: number[] = []): never {
  throw new HttpsError('failed-precondition', 'booking-conflict', {
    conflicts: conflicts.map((c) => ({ code: c.code, otherId: c.otherId ?? null })),
    alternatives: alts.map((a) => new Date(a).toISOString()),
  });
}

async function validateRefs(dr: Draft) {
  if (dr.groupId && (await loadGroup(dr.groupId))?.clubId !== dr.orgId) throw new HttpsError('permission-denied', 'wrongTenant');
  if (dr.coachId) {
    const c = await loadUser(dr.coachId);
    if (!c || c.role !== 'coach' || !((c as unknown as { clubIds?: string[] }).clubIds ?? []).includes(dr.orgId)) {
      throw new HttpsError('failed-precondition', 'coachNotInOrg');
    }
  }
}

/**
 * Transactional booking. Inside ONE transaction: read the lock document
 * of every (room, local day) the new intervals touch, read the existing
 * bookings that could overlap, run the conflict checker, then write the
 * bookings AND bump the locks. Two concurrent transactions touching the
 * same room-day contend on the same lock document, so Firestore retries
 * the later one, which then sees the first booking and is rejected.
 */
async function reserve(
  dr: Draft, intervals: Array<[number, number]>, actor: string, seriesId: string | null, rule: WeeklyRule | null,
  ignore: Set<string> = new Set(), updateIds?: string[],
): Promise<string[]> {
  const cfgDoc = await requireModule(dr.orgId, 'roomScheduling');
  const tz = normalizeTz(cfgDoc?.timezone);
  const buffer = cfgDoc?.bookingBufferMin ?? 0;
  const roomRef = db.doc(`clubs/${dr.orgId}/rooms/${dr.roomId}`);
  return db.runTransaction(async (tx) => {
    const roomSnap = await tx.get(roomRef);
    if (!roomSnap.exists) throw new HttpsError('not-found', 'room');
    const room = roomFrom(roomSnap.id, roomSnap.data()!);
    const keys = [...new Set(intervals.flatMap(([s, e]) => lockKeys(dr.roomId, s, e, tz)))];
    const lockRefs = keys.map((k) => db.doc(`clubs/${dr.orgId}/roomLocks/${k}`));
    const locks = await Promise.all(lockRefs.map((r) => tx.get(r)));
    const minS = Math.min(...intervals.map((i) => i[0])), maxE = Math.max(...intervals.map((i) => i[1]));
    const q = db.collection(`clubs/${dr.orgId}/bookings`)
      .where('startAt', '<', Timestamp.fromMillis(maxE + buffer * 60_000))
      .where('startAt', '>=', Timestamp.fromMillis(minS - MAX_DURATION_MS - buffer * 60_000));
    const existing = (await tx.get(q)).docs.map((s) => bookingFrom(s.id, s.data()));
    const pending: Booking[] = [];
    for (const [s, e] of intervals) {
      const b: Booking = { id: updateIds?.[pending.length] ?? `new-${pending.length}`, orgId: dr.orgId, roomId: dr.roomId, kind: dr.kind, startMs: s, endMs: e, status: 'active', coachId: dr.coachId, groupId: dr.groupId, expectedAttendees: dr.expectedAttendees };
      const conflicts = checkBooking(b, room, [...existing, ...pending], tz, buffer, ignore)
        .filter((c) => !(dr.allowGroupOverlap && c.code === 'groupOverlap'));
      if (conflicts.length) reject(conflicts, conflicts.some((c) => blocking(c.code)) ? alternatives(b, room, existing, tz, buffer, 3, ignore) : []);
      pending.push(b);
    }
    const ids: string[] = [];
    for (const [i, b] of pending.entries()) {
      const updateId = updateIds?.[i];
      const ref = updateId ? db.doc(`clubs/${dr.orgId}/bookings/${updateId}`) : db.collection(`clubs/${dr.orgId}/bookings`).doc();
      tx.set(ref, {
        orgId: dr.orgId, clubId: dr.orgId, roomId: dr.roomId, kind: dr.kind, startAt: Timestamp.fromMillis(b.startMs),
        endAt: Timestamp.fromMillis(b.endMs), title: dr.title, coachId: dr.coachId, groupId: dr.groupId, programId: dr.programId,
        sportId: dr.sportId, status: 'active', expectedAttendees: dr.expectedAttendees, updatedAt: FieldValue.serverTimestamp(),
        ...(updateId ? (seriesId === undefined ? {} : { seriesId, rule }) : { seriesId, rule, eventId: null, createdBy: actor }),
      }, { merge: !!updateId });
      ids.push(ref.id);
    }
    locks.forEach((l, i) => tx.set(lockRefs[i], { v: (l.get('v') ?? 0) + 1, at: FieldValue.serverTimestamp() }));
    return ids;
  });
}

export const createBooking = onCall(async (request) => {
  const dr = parseDraft((request.data ?? {}) as Record<string, unknown>);
  const actor = requireOrgAdmin(request, dr.orgId);
  await validateRefs(dr);
  const [bookingId] = await reserve(dr, [[dr.startMs, dr.endMs]], actor, null, null);
  await audit('booking.create', actor, 'booking', bookingId, dr.orgId, { room: dr.roomId });
  return { id: bookingId, eventId: null };
});

export const createRecurringBookings = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const dr = parseDraft(d);
  const actor = requireOrgAdmin(request, dr.orgId);
  await validateRefs(dr);
  const r = (d.rule ?? {}) as Record<string, unknown>;
  const rule: WeeklyRule = {
    weekdays: Array.isArray(r.weekdays) ? (r.weekdays as number[]).filter((x) => Number.isInteger(x) && x >= 1 && x <= 7) : [],
    startMinute: int(r.startMinute, 'startMinute', 0, 1439), durationMin: int(r.durationMin, 'durationMin', 15, 720),
    from: String(r.from), until: String(r.until),
  };
  if (!rule.weekdays.length) throw new HttpsError('invalid-argument', 'recurrence');
  const tz = normalizeTz((await orgConfig(dr.orgId))?.timezone);
  let occ: Array<[number, number]>;
  try {
    occ = occurrences(rule, tz);
  } catch {
    throw new HttpsError('invalid-argument', 'recurrence');
  }
  if (!occ.length || occ.length > 7 * 26) throw new HttpsError('invalid-argument', 'recurrence');
  const seriesId = db.collection('_').doc().id;
  // All occurrences inside the generation window are checked in the same
  // transaction before anything is written: all or nothing.
  const ids = await reserve(dr, occ, actor, seriesId, rule);
  await audit('booking.series', actor, 'booking', seriesId, dr.orgId, { count: ids.length });
  return { ids, seriesId, timezone: tz };
});

export const updateBooking = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const dr = parseDraft(d);
  const actor = requireOrgAdmin(request, dr.orgId);
  const bookingId = id(d.id, 'id');
  const old = await db.doc(`clubs/${dr.orgId}/bookings/${bookingId}`).get();
  if (!old.exists) throw new HttpsError('not-found', 'booking');
  await validateRefs(dr);
  // Editing one occurrence detaches it from its series (seriesId → null).
  await reserve(dr, [[dr.startMs, dr.endMs]], actor, null, null, new Set([bookingId]), [bookingId]);
  await audit('booking.update', actor, 'booking', bookingId, dr.orgId);
  return { ok: true };
});

export const cancelBooking = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const bookingId = id(d.bookingId, 'bookingId');
  const actor = requireOrgAdmin(request, orgId);
  const ref = db.doc(`clubs/${orgId}/bookings/${bookingId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'booking');
  const b = bookingFrom(snap.id, snap.data()!);
  const targets = d.scope === 'thisAndFuture' && b.seriesId
    ? (await db.collection(`clubs/${orgId}/bookings`).where('seriesId', '==', b.seriesId).get()).docs
        .filter((x) => bookingFrom(x.id, x.data()).startMs >= b.startMs)
    : [snap];
  const batch = db.batch();
  for (const t of targets) batch.update(t.ref, { status: 'cancelled', updatedAt: FieldValue.serverTimestamp() });
  await batch.commit();
  await audit('booking.cancel', actor, 'booking', bookingId, orgId, { count: targets.length });
  return { ok: true, count: targets.length };
});

/** "This and all later occurrences": new local time/duration/room, all re-checked in one transaction. */
export const updateBookingSeries = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const actor = requireOrgAdmin(request, orgId);
  const anchorSnap = await db.doc(`clubs/${orgId}/bookings/${id(d.bookingId, 'bookingId')}`).get();
  if (!anchorSnap.exists) throw new HttpsError('not-found', 'booking');
  const anchor = bookingFrom(anchorSnap.id, anchorSnap.data()!);
  if (!anchor.seriesId) throw new HttpsError('failed-precondition', 'notRecurring');
  const startMinute = int(d.startMinute, 'startMinute', 0, 1439), durationMin = int(d.durationMin, 'durationMin', 15, 720);
  const tz = normalizeTz((await orgConfig(orgId))?.timezone);
  const affected = (await db.collection(`clubs/${orgId}/bookings`).where('seriesId', '==', anchor.seriesId).get()).docs
    .map((x) => ({ snap: x, b: bookingFrom(x.id, x.data()) }))
    .filter((x) => x.b.status === 'active' && x.b.startMs >= anchor.startMs)
    .sort((a, b) => a.b.startMs - b.b.startMs);
  const intervals = affected.map(({ b }): [number, number] => {
    const day = new Date(b.startMs + (TZ_SHIFT[tz] ?? 240) * 60_000);
    const s = Date.UTC(day.getUTCFullYear(), day.getUTCMonth(), day.getUTCDate(), 0, startMinute) - (TZ_SHIFT[tz] ?? 240) * 60_000;
    return [s, s + durationMin * 60_000];
  });
  const data = anchorSnap.data()!;
  const dr = parseDraft({
    ...data, orgId, roomId: typeof d.roomId === 'string' && d.roomId ? d.roomId : data.roomId,
    startAt: new Date(intervals[0][0]).toISOString(), endAt: new Date(intervals[0][1]).toISOString(),
  });
  const ids = affected.map((x) => x.snap.id);
  await reserve(dr, intervals, actor, undefined as unknown as null, null, new Set(ids), ids);
  await audit('booking.series.update', actor, 'booking', anchor.seriesId, orgId, { count: ids.length });
  return { ok: true, count: ids.length };
});

// ─── leaderboards and consent ───────────────────────────────────────────

export const setLeaderboardConsent = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId'), childId = id(d.childId, 'childId');
  const child = await db.doc(`children/${childId}`).get();
  // Only a guardian of the child decides (never the child, coach or org).
  if (!child.exists || !((child.get('parentIds') ?? []) as string[]).includes(request.auth.uid)) {
    throw new HttpsError('permission-denied', 'guardian only');
  }
  const groups = await db.collection('groups').where('clubId', '==', orgId).where('memberChildIds', 'array-contains', childId).limit(1).get();
  if (groups.empty) throw new HttpsError('permission-denied', 'wrongTenant');
  const mode = d.mode === 'firstNameInitial' ? 'firstNameInitial' : 'pseudonym';
  const first = String(child.get('firstName') ?? ''), last = String(child.get('lastName') ?? '');
  const displayName = mode === 'pseudonym' ? pseudonymFor(childId) : last ? `${first} ${[...last][0]}.` : first;
  await db.doc(`clubs/${orgId}/leaderboardConsents/${childId}`).set({
    orgId, childId, guardianId: request.auth.uid, granted: d.granted === true, mode, displayName, at: FieldValue.serverTimestamp(),
  });
  await writeAudit({
    action: d.granted === true ? 'leaderboard.consent' : 'leaderboard.revoke', actorId: request.auth.uid, actorRole: 'parent',
    actorName: '', targetType: 'child', targetId: childId, clubId: orgId, details: { mode },
  });
  return { ok: true };
});

function resultFrom(id: string, d: FirebaseFirestore.DocumentData): Result {
  const at = d.playedAt instanceof Timestamp ? d.playedAt.toMillis() : Date.parse(String(d.playedAt));
  return {
    id, childId: d.childId, game: d.game, difficulty: d.difficulty, level: d.level, score: d.score, accuracy: d.accuracy,
    attempts: d.attempts, durationMs: d.durationMs, completed: d.completed === true && d.valid !== false, playedAtMs: at,
  };
}

function ageOf(birth: unknown, nowMs: number): number {
  const b = birth instanceof Timestamp ? birth.toDate() : new Date(String(birth));
  const n = new Date(nowMs);
  let a = n.getUTCFullYear() - b.getUTCFullYear();
  if (n.getUTCMonth() < b.getUTCMonth() || (n.getUTCMonth() === b.getUTCMonth() && n.getUTCDate() < b.getUTCDate())) a--;
  return a;
}

/**
 * Server-side ranking from stored results only. The viewer must be the
 * child's student account or guardian; only opted-in children of THIS
 * organization are ranked; pseudonyms only; no child ids leave the server.
 */
export const getLeaderboard = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId'), childId = id(d.childId, 'childId');
  const period = (['week', 'month', 'allTime'].includes(d.period as string) ? d.period : 'week') as Period;
  const child = await db.doc(`children/${childId}`).get();
  if (!child.exists) throw new HttpsError('not-found', 'child');
  const isGuardian = ((child.get('parentIds') ?? []) as string[]).includes(request.auth.uid);
  const isStudent = child.get('userId') === request.auth.uid;
  if (!isGuardian && !isStudent) throw new HttpsError('permission-denied', 'leaderboard');
  const cfgDoc = await orgConfig(orgId);
  const lb = cfgDoc?.leaderboard ?? {};
  if (!isModuleOn(cfgDoc, 'leaderboards') || lb.enabled !== true || !(lb.periods ?? ['week']).includes(period)) {
    return { unavailable: 'disabled', entries: [] };
  }
  const viewerConsent = await db.doc(`clubs/${orgId}/leaderboardConsents/${childId}`).get();
  if (viewerConsent.get('granted') !== true) return { unavailable: 'notConsented', entries: [] };
  const now = Date.now();
  const consents = await db.collection(`clubs/${orgId}/leaderboardConsents`).where('granted', '==', true).get();
  const groups = await db.collection('groups').where('clubId', '==', orgId).get();
  const inOrg = new Set(groups.docs.filter((g) => g.get('status') !== 'archived').flatMap((g) => (g.get('memberChildIds') ?? []) as string[]));
  const viewerBand = ageBandOf(ageOf(child.get('birthDate'), now));
  const participants = [];
  for (const c of consents.docs) {
    if (!inOrg.has(c.id)) continue;
    const kid = await db.doc(`children/${c.id}`).get();
    const band = ageBandOf(ageOf(kid.get('birthDate'), now));
    if (lb.byAgeBand !== false && band !== viewerBand) continue;
    participants.push({ childId: c.id, displayName: String(c.get('displayName') ?? pseudonymFor(c.id)), ageBand: band });
  }
  if (participants.length < (lb.minParticipants ?? 3)) return { unavailable: 'tooFewParticipants', ageBand: viewerBand, entries: [] };
  const results: Result[] = [];
  for (let i = 0; i < participants.length; i += 30) {
    const chunk = participants.slice(i, i + 30).map((p) => p.childId);
    const s = await db.collection('brainResults').where('childId', 'in', chunk).get();
    results.push(...s.docs.map((x) => resultFrom(x.id, x.data())));
  }
  const games = typeof d.game === 'string' && GAMES.includes(d.game as Game) ? [d.game as Game] : ((lb.games ?? []) as Game[]);
  const ranked = rank(participants, results, period, now, games);
  const badges = (cid: string) => new Set(score(results.filter((r) => r.childId === cid)).filter((s) => s.points > 0).map((s) => s.r.game)).size;
  return {
    ageBand: lb.byAgeBand !== false ? viewerBand : null,
    entries: ranked.slice(0, 20).map((e) => ({ rank: e.rank, displayName: e.displayName, points: e.points, badges: badges(e.childId), me: e.childId === childId })),
  };
});

/** Marks results of children whose organizations all disabled Brain Academy (excluded from scoring). */
export const onBrainResultCreated = onDocumentCreated('brainResults/{resultId}', async (event) => {
  const d = event.data?.data();
  if (!d) return;
  const groups = await db.collection('groups').where('memberChildIds', 'array-contains', d.childId).get();
  const orgs = [...new Set(groups.docs.map((g) => String(g.get('clubId') ?? '')))].filter(Boolean);
  let on = orgs.length === 0;
  for (const o of orgs) if (isModuleOn(await orgConfig(o), 'brainAcademy')) on = true;
  if (!on) await event.data!.ref.update({ valid: false, invalidReason: 'moduleDisabled' });
});

// ─── coach contact (parent-mediated) ─────────────────────────────────────

export const requestCoachContact = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const me = await db.doc(`users/${request.auth.uid}`).get();
  const childId = String(me.get('lastContext.childId') ?? '');
  const child = childId ? await db.doc(`children/${childId}`).get() : null;
  if (me.get('role') !== 'child' || !child?.exists || child.get('userId') !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'student only');
  }
  const d = (request.data ?? {}) as Record<string, unknown>;
  const groupId = id(d.groupId, 'groupId'), coachId = id(d.coachId, 'coachId');
  const g = await loadGroup(groupId);
  if (!g || !g.coachIds.includes(coachId) || !((await db.doc(`groups/${groupId}`).get()).get('memberChildIds') ?? []).includes(childId)) {
    throw new HttpsError('permission-denied', 'coach');
  }
  if (!['question', 'absence', 'training', 'other'].includes(d.topic as string)) throw new HttpsError('invalid-argument', 'topic');
  await consumeRateLimit(request.auth.uid, 'coachContact');
  const parentIds = (child.get('parentIds') ?? []) as string[];
  const ref = await db.collection('coachContactRequests').add({
    childId, coachId, groupId, topic: d.topic, studentUid: request.auth.uid, parentIds, status: 'open', handledBy: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  const users = await loadUsers(parentIds);
  await notify([...users.values()], {
    type: 'ackRequested',
    ...pushText('ackRequested', { group: g.name ?? '', text: String(child.get('firstName') ?? '') }),
    route: '/parent/home', args: { kind: 'coachContact', child: String(child.get('firstName') ?? '') }, childId, groupId,
    dedupeKey: `contact:${ref.id}`,
  });
  return { id: ref.id };
});

// ─── reports and health ─────────────────────────────────────────────────

export const tenantHealth = onCall(async (request) => {
  const orgId = id((request.data ?? {}).orgId, 'orgId');
  requireOrgAdmin(request, orgId);
  const groups = await db.collection('groups').where('clubId', '==', orgId).get();
  const kids = new Set(groups.docs.flatMap((g) => (g.get('memberChildIds') ?? []) as string[]));
  const count = async (q: FirebaseFirestore.Query) => (await q.count().get()).data().count;
  const now = Timestamp.now();
  const week = Timestamp.fromMillis(Date.now() + 7 * 86400_000);
  return {
    students: kids.size,
    coaches: await count(db.collection('users').where('role', '==', 'coach').where('clubIds', 'array-contains', orgId)),
    groups: groups.size,
    rooms: await count(db.collection(`clubs/${orgId}/rooms`).where('status', '!=', 'archived')),
    upcomingEvents: await count(db.collection('matches').where('clubId', '==', orgId).where('startAt', '>', now)),
    bookingsThisWeek: await count(db.collection(`clubs/${orgId}/bookings`).where('startAt', '>', now).where('startAt', '<', week)),
    brainPlays7d: 0,
  };
});

export const orgReport = onCall(async (request) => {
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  requireOrgAdmin(request, orgId);
  const groups = await db.collection('groups').where('clubId', '==', orgId).get();
  const groupMap = new Map(groups.docs.map((g) => [g.id, g]));
  if (d.kind === 'brain') {
    const rows: Array<Record<string, unknown> & { childId: string }> = [];
    for (const g of groups.docs) {
      for (const cid of (g.get('memberChildIds') ?? []) as string[]) {
        if (rows.some((r) => r.childId === cid)) continue;
        const kid = await db.doc(`children/${cid}`).get();
        const res = (await db.collection('brainResults').where('childId', '==', cid).get()).docs.map((x) => resultFrom(x.id, x.data()));
        const scored = score(res);
        const last = String(kid.get('lastName') ?? '');
        rows.push({
          childId: cid, displayName: `${kid.get('firstName') ?? ''}${last ? ` ${[...last][0]}.` : ''}`,
          groupNames: groups.docs.filter((x) => ((x.get('memberChildIds') ?? []) as string[]).includes(cid)).map((x) => String(x.get('name') ?? '')),
          points: scored.reduce((a, s) => a + s.points, 0), gamesCompleted: scored.filter((s) => s.r.completed).length,
          lastPlayed: res.length ? new Date(Math.max(...res.map((r) => r.playedAtMs))).toISOString() : null,
        });
      }
    }
    return { rows };
  }
  await requireModule(orgId, 'attendance');
  const from = Timestamp.fromMillis(Date.parse(String(d.from))), to = Timestamp.fromMillis(Date.parse(String(d.to)));
  const groupFilter = typeof d.groupId === 'string' ? d.groupId : null;
  if (groupFilter && !groupMap.has(groupFilter)) throw new HttpsError('permission-denied', 'wrongTenant');
  const ids = groupFilter ? [groupFilter] : [...groupMap.keys()];
  const rows: unknown[] = [];
  for (let i = 0; i < ids.length; i += 30) {
    const chunk = ids.slice(i, i + 30);
    for (const [col, type] of [['trainings', 'training'], ['matches', 'match']] as const) {
      const evs = await db.collection(col).where('groupId', 'in', chunk).where('startAt', '>=', from).where('startAt', '<', to).get();
      for (const e of evs.docs) {
        if (e.get('status') === 'cancelled') continue;
        const g = groupMap.get(e.get('groupId'))!;
        const members = (g.get('memberChildIds') ?? []) as string[];
        const base = { eventId: e.id, type, groupId: g.id, groupName: g.get('name') ?? '', startAt: (e.get('startAt') as Timestamp).toDate().toISOString() };
        if (d.kind === 'rsvp') {
          const version = e.get('scheduleVersion') ?? 1;
          const rs = new Map((await db.collection('rsvps').where('trainingId', '==', e.id).get()).docs.map((r) => [r.get('childId'), r.data()]));
          const counts: Record<string, number> = { confirmed: 0, declined: 0, uncertain: 0, notResponded: 0, needsReconfirmation: 0 };
          for (const c of members) {
            const r = rs.get(c);
            if (!r) counts.notResponded++;
            else if ((r.scheduleVersion ?? 1) < version) counts.needsReconfirmation++;
            else counts[r.response === 'yes' ? 'confirmed' : r.response === 'no' ? 'declined' : 'uncertain']++;
          }
          rows.push({ ...base, version, counts });
        } else {
          const recs = (await db.collection('attendance').where('trainingId', '==', e.id).get()).docs.map((r) => r.get('status'));
          rows.push({
            ...base, present: recs.filter((s) => s === 'present').length, absent: recs.filter((s) => s === 'absent').length,
            excused: recs.filter((s) => s === 'excused').length, unmarked: Math.max(0, members.length - recs.length),
          });
        }
      }
    }
  }
  return { rows };
});

// ─── schedule changes → reconfirmation + acknowledgment ──────────────────

async function announceChange(kind: 'training' | 'match', eventId: string, before: FirebaseFirestore.DocumentData | undefined, after: FirebaseFirestore.DocumentData | undefined) {
  if (!before || !after) return;
  const v0 = before.scheduleVersion ?? 1, v1 = after.scheduleVersion ?? 1;
  if (v1 <= v0 || after.status === 'cancelled') return;
  const group = await loadGroup(after.groupId);
  if (!group || !isModuleOn(await orgConfig(group.clubId ?? ''), 'notifications')) return;
  const users = await loadUsers(group.parentIds);
  const recipientIds = receiptRecipients(group, users, 'system');
  const messageId = `sched_${eventId}_v${v1}`;
  const when = (after.startAt as Timestamp).toDate().toISOString();
  const created = await postSystemMessage(group.id, messageId, 'განრიგი შეიცვალა. გთხოვთ, დაადასტუროთ დასწრება.', {
    key: 'scheduleChanged', args: { eventId, eventType: kind, version: String(v1), when },
  });
  if (!created) return; // retried trigger: already announced
  await db.doc(`chats/${group.id}/messages/${messageId}`).update({ requiresAck: true });
  await db.doc(`chats/${group.id}/receipts/${messageId}`).set({
    senderId: 'system', groupId: group.id, messageId, recipientIds, recipientCount: recipientIds.length,
    readCount: 0, ackCount: 0, requiresAck: true, createdAt: FieldValue.serverTimestamp(),
  });
  // Acknowledging is separate from the RSVP: earlier answers stay, but
  // count as "needs reconfirmation" until a guardian answers for v1.
  await notify(recipientIds.map((u) => users.get(u)!).filter(Boolean), {
    type: 'ackRequested',
    ...pushText('ackRequested', { group: group.name ?? '', text: when }),
    route: kind === 'match' ? `/match/${eventId}` : `/training/${eventId}`,
    args: { groupId: group.id, messageId, eventId }, groupId: group.id, dedupeKey: `sched:${eventId}:${v1}`,
  });
}

export const onTrainingScheduleChanged = onDocumentWritten('trainings/{id}', (e) =>
  announceChange('training', e.params.id, e.data?.before?.data(), e.data?.after?.data()));
export const onMatchScheduleChanged = onDocumentWritten('matches/{id}', (e) =>
  announceChange('match', e.params.id, e.data?.before?.data(), e.data?.after?.data()));

// ─── membership records (tenant-aware rules rely on them) ────────────────

/** Keeps clubs/{clubId}/orgMembers in step with the group: coaches, parents, students. */
export const onGroupOrgMembers = onDocumentWritten('groups/{groupId}', async (e) => {
  const after = e.data?.after?.data();
  if (!after?.clubId) return;
  const clubId = String(after.clubId);
  const batch = db.batch();
  const put = (uid: string, role: string) =>
    batch.set(db.doc(`clubs/${clubId}/orgMembers/${uid}`), { orgId: clubId, userId: uid, roles: FieldValue.arrayUnion(role), active: true }, { merge: true });
  for (const c of (after.coachIds ?? []) as string[]) put(c, 'coach');
  for (const p of (after.parentIds ?? []) as string[]) put(p, 'parent');
  for (const cid of (after.memberChildIds ?? []) as string[]) {
    const kid = await db.doc(`children/${cid}`).get();
    const su = kid.get('userId');
    if (typeof su === 'string' && su) put(su, 'student');
  }
  await batch.commit();
});

export const V17_MODULES = MODULES;
