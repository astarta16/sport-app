// v1.8 Platform Super Admin: provisioning, templates, packages,
// entitlements, subscriptions, invitations, versioned configuration with
// history, and the scheduled entitlement refresh.
//
// Every write re-checks the caller's claims. Configuration writes go
// through `writeConfig`, a transaction with optimistic concurrency
// (expectedVersion) that also writes the derived fields the rules read
// (effectiveModules / accessMode), an append-only history entry and the
// audit log. Nothing here charges money or sends real messages.
import { createHash, randomBytes } from 'node:crypto';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, GeoPoint, Timestamp } from 'firebase-admin/firestore';
import { auth, db } from '../admin';
import { AuditAction, writeAudit } from '../audit';
import { loadUser } from '../convert';
import { adminScopeFromClaims, computeAdminClaims } from '../lib/adminScope';
import { encodeGeohash } from '../lib/geo';
import {
  BUILTIN_PACKAGES, MODULES, Module, OrgConfigDoc, PackageDoc, Rollout, accessMode, derivedFields, effectiveConfig,
  isModuleOn, isValidSet, packageIncludes, prune, sanitizeModules, templateDiff,
} from '../lib/orgs';
import { normalizeTz } from '../lib/scheduling';

const TIMEZONE = 'Asia/Tbilisi';

function platformOnly(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  if (!adminScopeFromClaims(request.auth.token as Record<string, unknown>).platform) {
    throw new HttpsError('permission-denied', 'platform admin only');
  }
  return request.auth.uid;
}

function id(v: unknown, name: string): string {
  if (typeof v !== 'string' || !v || v.includes('/') || v.length > 200) throw new HttpsError('invalid-argument', `${name} required`);
  return v;
}

function reasonOf(v: unknown): string {
  const r = typeof v === 'string' ? v.trim() : '';
  if (r.length < 3 || r.length > 300) throw new HttpsError('invalid-argument', 'changeReason');
  return r;
}

const ms = (v: unknown): number | null =>
  v instanceof Timestamp ? v.toMillis() : typeof v === 'string' && v ? Date.parse(v) : typeof v === 'number' ? v : null;

/** Firestore document → OrgConfigDoc (timestamps as milliseconds). */
export function cfgFromDoc(d: FirebaseFirestore.DocumentData | undefined): OrgConfigDoc | undefined {
  if (!d) return undefined;
  const rollout: Record<string, Rollout> = {};
  for (const [k, v] of Object.entries((d.rollout ?? {}) as Record<string, Record<string, unknown>>)) {
    rollout[k] = { state: (v.state as Rollout['state']) ?? 'enabled', untilMs: ms(v.until), atMs: ms(v.at) };
  }
  return {
    ...d,
    rollout,
    subscription: d.subscription
      ? { status: d.subscription.status, endAtMs: ms(d.subscription.endAt), graceDays: d.subscription.graceDays }
      : undefined,
  } as OrgConfigDoc;
}

async function packageDoc(packageId: string): Promise<PackageDoc> {
  const s = await db.doc(`subscriptionPackages/${packageId}`).get();
  if (s.exists) return s.data() as PackageDoc;
  const b = BUILTIN_PACKAGES[packageId];
  if (!b) throw new HttpsError('invalid-argument', 'package');
  return b;
}

async function audit(action: AuditAction, actorId: string, targetType: string, targetId: string, clubId: string | null, details: Record<string, unknown> = {}) {
  const u = await loadUser(actorId);
  await writeAudit({ action, actorId, actorRole: 'platformAdmin', actorName: [u?.firstName, u?.lastName].filter(Boolean).join(' '), targetType, targetId, clubId, details });
}

/**
 * Transactional configuration write. Rejects a stale [expectedVersion]
 * (HttpsError 'aborted' with details.currentVersion) instead of silently
 * overwriting another administrator's change.
 */
export async function writeConfig(
  orgId: string, actor: string, reason: string, expectedVersion: number | null,
  mutate: (cur: FirebaseFirestore.DocumentData) => Record<string, unknown>,
): Promise<number> {
  const ref = db.doc(`orgConfigs/${orgId}`);
  const version = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const cur = snap.data() ?? {};
    const curVersion = (cur.version as number | undefined) ?? 1;
    if (expectedVersion != null && expectedVersion !== curVersion) {
      throw new HttpsError('aborted', 'configConflict', { currentVersion: curVersion });
    }
    // A v1.7 document (featureSchema < 2) stores coarse modules; persist the
    // expanded v1.8 lists with the first versioned write so no implied
    // feature (receipts, acknowledgments, …) is silently dropped.
    const legacy = (cur.featureSchema ?? 1) < 2;
    const expanded = legacy ? effectiveConfig(cfgFromDoc(cur)) : null;
    const upgrade = expanded
      ? { allowedModules: expanded.allowedModules, enabledModules: expanded.enabledModules, featureSchema: 2 }
      : {};
    const patch = { ...upgrade, ...mutate(cur) };
    const next: Record<string, any> = { ...cur, ...patch, version: curVersion + 1 }; // eslint-disable-line @typescript-eslint/no-explicit-any
    const derived = derivedFields(cfgFromDoc(next)!);
    const changes: string[] = [];
    for (const m of MODULES) {
      const a = (cur.enabledModules ?? []).includes(m), b = ((next.enabledModules as string[]) ?? []).includes(m);
      if (a !== b) changes.push(`${b ? '+' : '-'}${m}`);
      const x = (cur.allowedModules ?? []).includes(m), y = ((next.allowedModules as string[]) ?? []).includes(m);
      if (x !== y) changes.push(`${y ? 'entitle' : 'revoke'}:${m}`);
    }
    if (cur.packageId !== next.packageId) changes.push(`package:${cur.packageId}→${next.packageId}`);
    if (cur.subscription?.status !== (next.subscription as { status?: string } | undefined)?.status) changes.push('subscription');
    tx.set(ref, { ...patch, ...derived, version: curVersion + 1, updatedAt: FieldValue.serverTimestamp(), updatedBy: actor, changeReason: reason }, { merge: true });
    tx.set(ref.collection('history').doc(String(curVersion + 1)), {
      version: curVersion + 1, at: FieldValue.serverTimestamp(), by: actor, reason, changes,
    });
    return curVersion + 1;
  });
  return version;
}

// ── overview ───────────────────────────────────────────────────────────

export const platformStats = onCall(async (request) => {
  platformOnly(request);
  const [clubs, cfgs, users] = await Promise.all([
    db.collection('clubs').get(),
    db.collection('orgConfigs').get(),
    db.collection('users').select('role').get(),
  ]);
  const byId = new Map(cfgs.docs.map((d) => [d.id, cfgFromDoc(d.data())]));
  const now = Date.now();
  const configs = clubs.docs.map((c) => byId.get(c.id));
  const adoption: Record<string, number> = {};
  for (const m of MODULES) adoption[m] = configs.filter((c) => isModuleOn(c, m, now)).length;
  const bySubscription: Record<string, number> = {};
  for (const c of configs) {
    const st = c?.subscription?.status ?? 'active';
    bySubscription[st] = (bySubscription[st] ?? 0) + 1;
  }
  const alerts = clubs.docs.flatMap((c) => {
    const cfg = byId.get(c.id);
    const out: Array<{ kind: string; orgId: string }> = [];
    if (cfg?.subscription?.status === 'pastDue') out.push({ kind: 'pastDue', orgId: c.id });
    if (accessMode(cfg, now) === 'readOnly') out.push({ kind: 'readOnly', orgId: c.id });
    if ((cfg?.provisioning ?? 'ready') !== 'ready') out.push({ kind: 'provisioningStuck', orgId: c.id });
    return out;
  });
  const roles = users.docs.map((u) => u.get('role'));
  return {
    organizations: clubs.size,
    active: configs.filter((c) => effectiveConfig(c).status === 'active').length,
    suspended: configs.filter((c) => effectiveConfig(c).status !== 'active').length,
    trial: configs.filter((c) => c?.subscription?.status === 'trial').length,
    users: users.size,
    coaches: roles.filter((r) => r === 'coach').length,
    parents: roles.filter((r) => r === 'parent').length,
    students: (await db.collection('children').count().get()).data().count,
    adoption, bySubscription, alerts,
  };
});

// ── packages & templates ────────────────────────────────────────────────

export const upsertPackage = onCall(async (request) => {
  const actor = platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  let modules: Module[];
  try {
    modules = sanitizeModules(d.modules ?? []);
  } catch {
    throw new HttpsError('invalid-argument', 'modules');
  }
  if (d.custom !== true && !isValidSet(modules)) throw new HttpsError('invalid-argument', 'featureDependencies');
  const l = (d.limits ?? {}) as Record<string, number>;
  for (const k of ['maxCoaches', 'maxStudents', 'maxGroups']) {
    if (!Number.isInteger(l[k]) || l[k] < 1) throw new HttpsError('invalid-argument', 'limitRange');
  }
  const ref = typeof d.id === 'string' && d.id ? db.doc(`subscriptionPackages/${id(d.id, 'id')}`) : db.collection('subscriptionPackages').doc();
  await ref.set({
    names: d.names ?? {}, modules, limits: l, price: d.price ?? {}, durationDays: d.durationDays ?? 365,
    custom: d.custom === true, archived: d.archived === true, updatedAt: FieldValue.serverTimestamp(),
  });
  await audit('package.upsert', actor, 'package', ref.id, null);
  return { id: ref.id };
});

export const upsertTemplate = onCall(async (request) => {
  const actor = platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  let modules: Module[];
  try {
    modules = sanitizeModules(d.modules ?? []);
  } catch {
    throw new HttpsError('invalid-argument', 'modules');
  }
  if (!isValidSet(modules)) throw new HttpsError('invalid-argument', 'featureDependencies');
  await packageDoc(id(d.packageId, 'packageId'));
  const ref = typeof d.id === 'string' && d.id ? db.doc(`orgTemplates/${id(d.id, 'id')}`) : db.collection('orgTemplates').doc();
  await ref.set({
    names: d.names ?? {}, description: d.description ?? {}, modules, type: d.type ?? 'club', funding: d.funding ?? 'private',
    packageId: d.packageId, settings: d.settings ?? {}, bookingBufferMin: d.bookingBufferMin ?? 0, builtIn: false,
    archived: d.archived === true, updatedAt: FieldValue.serverTimestamp(),
  });
  await audit('template.upsert', actor, 'template', ref.id, null);
  return { id: ref.id };
});

export const duplicateTemplate = onCall(async (request) => {
  const actor = platformOnly(request);
  const src = await db.doc(`orgTemplates/${id((request.data ?? {}).templateId, 'templateId')}`).get();
  if (!src.exists) throw new HttpsError('not-found', 'template');
  const ref = await db.collection('orgTemplates').add({ ...src.data(), builtIn: false, archived: false });
  await audit('template.upsert', actor, 'template', ref.id, null, { from: src.id });
  return { id: ref.id };
});

export const archiveTemplate = onCall(async (request) => {
  const actor = platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const ref = db.doc(`orgTemplates/${id(d.templateId, 'templateId')}`);
  if (!(await ref.get()).exists) throw new HttpsError('not-found', 'template');
  await ref.update({ archived: d.archived === true });
  await audit(d.archived === true ? 'template.archive' : 'template.restore', actor, 'template', ref.id, null);
  return { ok: true };
});

// ── invitations ─────────────────────────────────────────────────────────

const hashToken = (t: string) => createHash('sha256').update(t).digest('hex');
const VALID_MS = 7 * 86400_000;

async function issueInvitation(orgId: string, by: string, phone?: string | null, email?: string | null, transferFrom?: string | null, batch?: FirebaseFirestore.WriteBatch) {
  if (!phone && !email) throw new HttpsError('invalid-argument', 'orgAdminMissing');
  const token = randomBytes(32).toString('hex');
  const ref = db.collection('orgInvitations').doc();
  const data = {
    orgId, tokenHash: hashToken(token), expiresAt: Timestamp.fromMillis(Date.now() + VALID_MS), invitedBy: by,
    createdAt: FieldValue.serverTimestamp(), phone: phone ?? null, email: email ?? null, status: 'pending',
    acceptedBy: null, transferFrom: transferFrom ?? null, resendCount: 0,
  };
  if (batch) batch.set(ref, data);
  else await ref.set(data);
  return { id: ref.id, token };
}

export const inviteOrgAdmin = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const scope = adminScopeFromClaims(request.auth.token as Record<string, unknown>);
  const transferFrom = typeof d.transferFrom === 'string' ? d.transferFrom : null;
  // An organization admin may only hand over their OWN role.
  const selfTransfer = transferFrom === request.auth.uid && scope.clubIds.includes(orgId);
  if (!scope.platform && !selfTransfer) throw new HttpsError('permission-denied', 'invite');
  if (!(await db.doc(`clubs/${orgId}`).get()).exists) throw new HttpsError('not-found', 'organization');
  const r = await issueInvitation(orgId, request.auth.uid, d.phone as string | undefined, d.email as string | undefined, transferFrom);
  await audit('invitation.create', request.auth.uid, 'invitation', r.id, orgId);
  return { invitationId: r.id, token: r.token };
});

export const resendInvitation = onCall(async (request) => {
  const actor = platformOnly(request);
  const ref = db.doc(`orgInvitations/${id((request.data ?? {}).invitationId, 'invitationId')}`);
  const s = await ref.get();
  if (!s.exists) throw new HttpsError('not-found', 'invitation');
  if (!['pending', 'expired'].includes(s.get('status'))) throw new HttpsError('failed-precondition', 'invitationClosed');
  const token = randomBytes(32).toString('hex');
  await ref.update({ tokenHash: hashToken(token), expiresAt: Timestamp.fromMillis(Date.now() + VALID_MS), status: 'pending', resendCount: FieldValue.increment(1) });
  await audit('invitation.resend', actor, 'invitation', ref.id, s.get('orgId'));
  return { invitationId: ref.id, token };
});

export const revokeInvitation = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const ref = db.doc(`orgInvitations/${id((request.data ?? {}).invitationId, 'invitationId')}`);
  const s = await ref.get();
  if (!s.exists) throw new HttpsError('not-found', 'invitation');
  const scope = adminScopeFromClaims(request.auth.token as Record<string, unknown>);
  if (!scope.platform && s.get('invitedBy') !== request.auth.uid) throw new HttpsError('permission-denied', 'revoke');
  await ref.update({ status: 'revoked' });
  await audit('invitation.revoke', request.auth.uid, 'invitation', ref.id, s.get('orgId'));
  return { ok: true };
});

async function invitationByToken(token: unknown) {
  if (typeof token !== 'string' || token.length < 16 || token.length > 200) throw new HttpsError('invalid-argument', 'token');
  const q = await db.collection('orgInvitations').where('tokenHash', '==', hashToken(token.trim())).limit(1).get();
  if (q.empty) throw new HttpsError('not-found', 'invitation');
  const s = q.docs[0];
  if (s.get('status') !== 'pending') throw new HttpsError('failed-precondition', 'invitationClosed');
  if ((s.get('expiresAt') as Timestamp).toMillis() <= Date.now()) throw new HttpsError('failed-precondition', 'invitationExpired');
  return s;
}

export const acceptInvitation = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const inv = await invitationByToken((request.data ?? {}).token);
  const uid = request.auth.uid;
  const user = await auth().getUser(uid);
  const invitedPhone = inv.get('phone') as string | null;
  if (invitedPhone && (user.phoneNumber ?? '').replace(/\s/g, '') !== invitedPhone.replace(/\s/g, '')) {
    throw new HttpsError('permission-denied', 'invitationRecipient');
  }
  const claims = (user.customClaims ?? {}) as Record<string, unknown>;
  if (claims.admin === true) throw new HttpsError('failed-precondition', 'alreadyPlatformAdmin');
  const orgId = inv.get('orgId') as string;
  const next = [...new Set([...(Array.isArray(claims.clubAdmin) ? (claims.clubAdmin as string[]) : []), orgId])];
  await auth().setCustomUserClaims(uid, computeAdminClaims(user.customClaims, 'club', next));
  const batch = db.batch();
  batch.set(db.doc(`users/${uid}`), { adminRole: 'club', adminClubIds: next }, { merge: true });
  batch.set(db.doc(`clubs/${orgId}`), { adminIds: FieldValue.arrayUnion(uid) }, { merge: true });
  batch.set(db.doc(`clubs/${orgId}/orgMembers/${uid}`), { orgId, userId: uid, roles: FieldValue.arrayUnion('admin'), active: true }, { merge: true });
  batch.update(inv.ref, { status: 'accepted', acceptedBy: uid });
  await batch.commit();
  const from = inv.get('transferFrom') as string | null;
  if (from && from !== uid) {
    const old = await auth().getUser(from).catch(() => null);
    if (old) {
      const oc = (old.customClaims ?? {}) as Record<string, unknown>;
      const rest = (Array.isArray(oc.clubAdmin) ? (oc.clubAdmin as string[]) : []).filter((c) => c !== orgId);
      await auth().setCustomUserClaims(from, computeAdminClaims(old.customClaims, rest.length ? 'club' : 'none', rest));
      await db.doc(`users/${from}`).set(rest.length ? { adminClubIds: rest } : { adminRole: FieldValue.delete(), adminClubIds: FieldValue.delete() }, { merge: true });
      await db.doc(`clubs/${orgId}`).set({ adminIds: FieldValue.arrayRemove(from) }, { merge: true });
      await db.doc(`clubs/${orgId}/orgMembers/${from}`).set({ roles: FieldValue.arrayRemove('admin') }, { merge: true });
    }
  }
  await audit('invitation.accept', uid, 'invitation', inv.id, orgId, { transferFrom: from ?? '' });
  return { orgId };
});

export const rejectInvitation = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const inv = await invitationByToken((request.data ?? {}).token);
  await inv.ref.update({ status: 'rejected' });
  await audit('invitation.reject', request.auth.uid, 'invitation', inv.id, inv.get('orgId'));
  return { ok: true };
});

// ── provisioning ────────────────────────────────────────────────────────

/**
 * Two-phase provisioning: one batch writes club, configuration
 * (`provisioning: 'provisioning'`), and the admin invitation; a second write
 * flips the configuration to `ready`. If the second step never happens the
 * organization is unusable (rules require `provisioning == ready`) and the
 * platform dashboard raises a `provisioningStuck` alert for recovery.
 */
export const provisionOrganization = onCall(async (request) => {
  const actor = platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const names = (d.names ?? {}) as Record<string, string>;
  const name = (names.ka ?? names.en ?? '').trim();
  const email = String(d.contactEmail ?? '').trim();
  const phone = String(d.contactPhone ?? '').trim();
  if (name.length < 2) throw new HttpsError('invalid-argument', 'orgName');
  if (String(d.address ?? '').trim().length < 2) throw new HttpsError('invalid-argument', 'orgAddress');
  if (String(d.city ?? '').trim().length < 2) throw new HttpsError('invalid-argument', 'orgCity');
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new HttpsError('invalid-argument', 'orgEmail');
  if (!/^\+?[0-9 ]{9,16}$/.test(phone)) throw new HttpsError('invalid-argument', 'orgPhone');
  const sportIds = Array.isArray(d.sportIds) ? (d.sportIds as string[]) : [];
  if (!sportIds.length) throw new HttpsError('invalid-argument', 'orgSports');
  if (!d.adminPhone && !d.adminEmail) throw new HttpsError('invalid-argument', 'orgAdminMissing');
  const packageId = id(d.packageId, 'packageId');
  const pkg = await packageDoc(packageId);
  let template: FirebaseFirestore.DocumentData | undefined;
  if (typeof d.templateId === 'string' && d.templateId) {
    const t = await db.doc(`orgTemplates/${id(d.templateId, 'templateId')}`).get();
    if (!t.exists || t.get('archived') === true) throw new HttpsError('failed-precondition', 'template');
    template = t.data();
  }
  let modules: Module[];
  try {
    modules = d.modules ? sanitizeModules(d.modules) : (template?.modules as Module[] | undefined) ?? pkg.modules;
  } catch {
    throw new HttpsError('invalid-argument', 'modules');
  }
  if (!isValidSet(modules)) throw new HttpsError('invalid-argument', 'featureDependencies');
  const notIn = modules.filter((m) => !packageIncludes(pkg, m));
  if (notIn.length) throw new HttpsError('invalid-argument', `notInPackage:${notIn[0]}`);
  const lat = Number(d.lat ?? 41.7151), lng = Number(d.lng ?? 44.8271);
  const slug = (names.en ?? name).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40) || 'school';
  const orgId = `org-${slug}-${randomBytes(3).toString('hex')}`;
  const now = Date.now();
  const sub = (d.subscription ?? {}) as Record<string, unknown>;
  const cfg = {
    status: 'active', provisioning: 'provisioning', packageId, featureSchema: 2, version: 1,
    allowedModules: pkg.custom ? modules : pkg.modules, enabledModules: modules,
    limits: { maxCoaches: pkg.limits.maxCoaches, maxStudents: pkg.limits.maxStudents, maxGroups: pkg.limits.maxGroups, maxRooms: pkg.limits.maxRooms },
    subscription: {
      status: sub.status ?? 'active', startAt: Timestamp.fromMillis(now),
      endAt: Timestamp.fromMillis(ms(sub.endAt) ?? now + (pkg.durationDays ?? 365) * 86400_000), graceDays: sub.graceDays ?? 14,
    },
    branding: {
      names, primaryColor: d.primaryColor ?? 0xff1d4ed8, secondaryColor: d.secondaryColor ?? 0xff0f172a, logoUrl: d.logoUrl ?? null,
      description: String(d.description ?? '').slice(0, 1000), contactEmail: email, contactPhone: phone, address: d.address,
    },
    profile: { legalName: d.legalName ?? '', type: template?.type ?? d.type ?? 'club', funding: d.funding ?? 'private', registrationId: d.registrationId ?? null, city: d.city },
    settings: template?.settings ?? {}, bookingBufferMin: template?.bookingBufferMin ?? 0,
    timezone: normalizeTz(d.timezone), defaultLanguage: ['ka', 'en', 'ru'].includes(d.defaultLanguage as string) ? d.defaultLanguage : 'ka',
    leaderboard: { enabled: false, minParticipants: 3, byAgeBand: true, periods: ['week', 'month'], games: [] },
    templateId: d.templateId ?? null, rollout: {},
  };
  const batch = db.batch();
  batch.set(db.doc(`clubs/${orgId}`), {
    name, address: d.address, sportIds, phone, description: d.description ?? null, location: new GeoPoint(lat, lng),
    geohash: encodeGeohash(lat, lng, 9), status: 'active', adminIds: [], createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(db.doc(`orgConfigs/${orgId}`), { ...cfg, ...derivedFields(cfgFromDoc(cfg)!), updatedAt: FieldValue.serverTimestamp(), updatedBy: actor });
  const inv = await issueInvitation(orgId, actor, d.adminPhone as string | null, d.adminEmail as string | null, null, batch);
  await batch.commit();
  await writeConfig(orgId, actor, template ? 'provisioned from template' : 'provisioned', null, () => ({ provisioning: 'ready' }));
  await audit('org.provision', actor, 'club', orgId, orgId, { packageId, templateId: d.templateId ?? null });
  return { orgId, invitationId: inv.id, token: inv.token };
});

export const applyTemplate = onCall(async (request) => {
  const actor = platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const t = await db.doc(`orgTemplates/${id(d.templateId, 'templateId')}`).get();
  if (!t.exists) throw new HttpsError('not-found', 'template');
  const tpl = t.data()!;
  const pkg = await packageDoc(tpl.packageId);
  const reason = reasonOf(d.reason);
  const v = await writeConfig(orgId, actor, reason, Number(d.expectedVersion), () => ({
    packageId: tpl.packageId, allowedModules: pkg.custom ? tpl.modules : pkg.modules, enabledModules: tpl.modules,
    settings: tpl.settings ?? {}, bookingBufferMin: tpl.bookingBufferMin ?? 0, templateId: t.id,
    limits: { maxCoaches: pkg.limits.maxCoaches, maxStudents: pkg.limits.maxStudents, maxGroups: pkg.limits.maxGroups, maxRooms: pkg.limits.maxRooms },
  }));
  await audit('org.template.apply', actor, 'club', orgId, orgId, { templateId: t.id, reason });
  return { version: v };
});

export const previewTemplateChanges = onCall(async (request) => {
  platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const cfg = await db.doc(`orgConfigs/${id(d.orgId, 'orgId')}`).get();
  const t = await db.doc(`orgTemplates/${id(d.templateId, 'templateId')}`).get();
  return { changes: templateDiff(cfgFromDoc(cfg.data()) ?? {}, { modules: t.get('modules') ?? [], packageId: t.get('packageId') }) };
});

// ── entitlements & subscriptions ─────────────────────────────────────────

export const updateEntitlements = onCall(async (request) => {
  const actor = platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const reason = reasonOf(d.reason);
  let allowed: Module[];
  try {
    allowed = sanitizeModules(d.allowed ?? []);
  } catch {
    throw new HttpsError('invalid-argument', 'modules');
  }
  if (!isValidSet(allowed)) throw new HttpsError('invalid-argument', 'featureDependencies');
  const cfgSnap = await db.doc(`orgConfigs/${orgId}`).get();
  const pkg = await packageDoc(cfgSnap.get('packageId') ?? 'professional');
  const notIn = allowed.filter((m) => !packageIncludes(pkg, m));
  if (notIn.length) throw new HttpsError('invalid-argument', `notInPackage:${notIn[0]}`);
  const rollout: Record<string, Record<string, unknown>> = {};
  for (const [k, v] of Object.entries((d.rollout ?? {}) as Record<string, Record<string, unknown>>)) {
    if (!(MODULES as readonly string[]).includes(k)) throw new HttpsError('invalid-argument', 'rollout');
    if (v.state === 'trial' && !v.until) throw new HttpsError('invalid-argument', 'rolloutDate');
    if (v.state === 'scheduled' && !v.at) throw new HttpsError('invalid-argument', 'rolloutDate');
    rollout[k] = { state: v.state, until: v.until ? Timestamp.fromMillis(Date.parse(String(v.until))) : null, at: v.at ? Timestamp.fromMillis(Date.parse(String(v.at))) : null };
  }
  const v = await writeConfig(orgId, actor, reason, Number(d.expectedVersion), (cur) => {
    const enabled = effectiveConfig(cfgFromDoc(cur)).enabledModules.filter((m) => allowed.includes(m as Module));
    return { allowedModules: allowed, enabledModules: prune(enabled), rollout, featureSchema: 2 };
  });
  await audit('org.entitlements', actor, 'club', orgId, orgId, { reason });
  return { version: v };
});

export const updateSubscription = onCall(async (request) => {
  const actor = platformOnly(request);
  const d = (request.data ?? {}) as Record<string, unknown>;
  const orgId = id(d.orgId, 'orgId');
  const reason = reasonOf(d.reason);
  const sub = d.subscription as Record<string, unknown> | undefined;
  if (sub && !['trial', 'active', 'pastDue', 'suspended', 'cancelled', 'expired'].includes(sub.status as string)) {
    throw new HttpsError('invalid-argument', 'subscriptionStatus');
  }
  const pkgId = typeof d.packageId === 'string' ? d.packageId : null;
  const pkg = pkgId ? await packageDoc(pkgId) : null;
  const v2 = await writeConfig(orgId, actor, reason, Number(d.expectedVersion), (cur) => {
    const patch: Record<string, unknown> = { featureSchema: 2 };
    if (pkg && pkgId) {
      const allowed = pkg.custom ? (cur.allowedModules ?? []) : pkg.modules;
      patch.packageId = pkgId;
      patch.allowedModules = allowed;
      patch.enabledModules = prune(effectiveConfig(cfgFromDoc(cur)).enabledModules.filter((m) => allowed.includes(m)));
      patch.limits = pkg.custom && d.limits ? d.limits : { maxCoaches: pkg.limits.maxCoaches, maxStudents: pkg.limits.maxStudents, maxGroups: pkg.limits.maxGroups, maxRooms: pkg.limits.maxRooms };
    }
    if (sub) {
      patch.subscription = {
        ...(cur.subscription ?? {}), status: sub.status,
        endAt: sub.endAt ? Timestamp.fromMillis(Date.parse(String(sub.endAt))) : cur.subscription?.endAt ?? null,
        graceDays: typeof sub.graceDays === 'number' ? Math.min(90, Math.max(0, sub.graceDays)) : 14, note: sub.note ?? null,
      };
    }
    return patch;
  });
  await audit('org.subscription', actor, 'club', orgId, orgId, { reason, packageId: pkgId, status: sub?.status ?? null });
  return { version: v2 };
});

export const orgUsage = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const orgId = id((request.data ?? {}).orgId, 'orgId');
  const scope = adminScopeFromClaims(request.auth.token as Record<string, unknown>);
  if (!scope.platform && !scope.clubIds.includes(orgId)) throw new HttpsError('permission-denied', 'usage');
  const groups = await db.collection('groups').where('clubId', '==', orgId).get();
  const monthStart = new Date(); monthStart.setUTCDate(1); monthStart.setUTCHours(0, 0, 0, 0);
  const ids = groups.docs.map((g) => g.id);
  let notifications = 0;
  for (let i = 0; i < ids.length; i += 30) {
    notifications += (await db.collection('notifications').where('groupId', 'in', ids.slice(i, i + 30)).where('createdAt', '>=', Timestamp.fromDate(monthStart)).count().get()).data().count;
  }
  return {
    coaches: (await db.collection('users').where('role', '==', 'coach').where('clubIds', 'array-contains', orgId).count().get()).data().count,
    students: new Set(groups.docs.flatMap((g) => (g.get('memberChildIds') ?? []) as string[])).size,
    groups: groups.size,
    rooms: (await db.collection(`clubs/${orgId}/rooms`).where('status', '!=', 'archived').count().get()).data().count,
    storageMb: 0, // needs Storage usage metrics (Cloud Monitoring) — not available locally
    notificationsThisMonth: notifications,
    smsThisMonth: (await db.collection('smsLog').where('clubId', '==', orgId).where('at', '>=', Timestamp.fromDate(monthStart)).count().get()).data().count,
  };
});

// ── scheduled refresh ───────────────────────────────────────────────────

/** Expires trials and subscriptions, applies scheduled rollouts, refreshes the derived fields the rules read. */
export async function refreshAllEntitlements(nowMs = Date.now()): Promise<string[]> {
  const cfgs = await db.collection('orgConfigs').get();
  const changed: string[] = [];
  for (const c of cfgs.docs) {
    const data = c.data();
    // v1.7 documents are upgraded only by scripts/migrate-v18.mjs (reviewed,
    // dry run first) — never silently by the scheduler. The rules keep
    // using the legacy fallback for them meanwhile.
    if ((data.featureSchema ?? 1) < 2) continue;
    const doc = cfgFromDoc(data)!;
    const derived = derivedFields(doc, nowMs);
    const subStatus = data.subscription?.status;
    const expire = (subStatus === 'trial' || subStatus === 'active') && accessMode(doc, nowMs) === 'readOnly';
    const same = JSON.stringify(derived.effectiveModules) === JSON.stringify(data.effectiveModules ?? []) && derived.accessMode === (data.accessMode ?? 'full');
    if (same && !expire) continue;
    await writeConfig(c.id, 'system', 'scheduled entitlement refresh', null, () => (expire ? { subscription: { ...data.subscription, status: 'expired' } } : {}));
    changed.push(c.id);
  }
  return changed;
}

export const refreshEntitlements = onSchedule({ schedule: 'every 60 minutes', timeZone: TIMEZONE }, async () => {
  await refreshAllEntitlements();
});

/** System Health "run now" button: same job, platform admins only. */
export const refreshEntitlementsNow = onCall(async (request) => {
  platformOnly(request);
  return { changed: await refreshAllEntitlements() };
});

/** Is a feature-specific job allowed for the organization of a group? (cached per run) */
export function jobGate() {
  const cache = new Map<string, OrgConfigDoc | null>();
  return async (groupId: string | undefined | null, m: Module): Promise<boolean> => {
    if (!groupId) return true;
    const g = await db.doc(`groups/${groupId}`).get();
    const clubId = g.get('clubId') as string | undefined;
    if (!clubId) return true;
    if (!cache.has(clubId)) cache.set(clubId, cfgFromDoc((await db.doc(`orgConfigs/${clubId}`).get()).data()) ?? null);
    return isModuleOn(cache.get(clubId), m);
  };
}
