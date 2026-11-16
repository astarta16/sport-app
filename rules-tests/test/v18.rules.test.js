// v1.8 rules: server-derived entitlements (effectiveModules / accessMode /
// provisioning), feature-gated writes, platform collections, escalation and
// cross-tenant access. Synthetic data only.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, getDocs, collection, serverTimestamp, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { CLAIMS, UID, createEnv, now, seed, seedV12, ts } from './setup.js';

let env;
beforeAll(async () => {
  env = await createEnv();
});
afterAll(async () => {
  await env?.cleanup();
});

const ALL = [
  'trainings', 'matches', 'attendance', 'communication', 'studentAccounts', 'brainAcademy', 'trainingPlans',
  'payments', 'medicalCertificates', 'media', 'leaderboards', 'roomScheduling', 'notifications', 'parentRsvp',
  'messageAcks', 'coachChallenges', 'paymentReceipts', 'paymentVerification', 'paymentReminders', 'facilities',
  'reports', 'dataExports',
];
const without = (...m) => ALL.filter((x) => !m.includes(x));

/** A v1.8 configuration document as the server writes it. */
function cfg(over = {}) {
  return {
    status: 'active', plan: 'premium', packageId: 'enterprise', featureSchema: 2, version: 3,
    allowedModules: ALL, enabledModules: ALL, effectiveModules: ALL, accessMode: 'full', provisioning: 'ready',
    subscription: { status: 'active', endAtMs: null, graceDays: 14 }, ...over,
  };
}

async function setConfig(data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'orgConfigs/club1'), data);
  });
}

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await seedV12(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, d) => setDoc(doc(db, p), d);
    await put('orgConfigs/club1', cfg());
    await put('orgConfigs/club2', cfg());
    await put('orgConfigs/club1/history/3', { version: 3, by: UID.admin, reason: 'seed', at: now, changes: [] });
    await put('subscriptionPackages/professional', { names: { en: 'Professional' }, modules: ALL, limits: {} });
    await put('orgTemplates/tpl-government-school', { names: { en: 'Government' }, modules: ALL, packageId: 'enterprise' });
    await put('orgInvitations/inv1', {
      orgId: 'club1', tokenHash: 'a'.repeat(64), phone: '+995599000001', status: 'pending',
      expiresAt: ts('2030-01-01T00:00:00Z'), invitedBy: UID.admin, createdAt: now,
    });
    await put(`platformAdmins/${UID.admin}`, { since: now });
  });
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const markPaid = (db) => updateDoc(doc(db, 'payments/p1'), { status: 'paid', paidAt: now, updatedBy: UID.coach, updatedAt: now });
const plan = (o = {}) => ({
  title: 'Winter plan', description: 'Ball control', type: 'weekly', groupIds: ['g1'], clubId: 'club1',
  startDate: '2026-12-01', endDate: null, status: 'draft', createdBy: UID.coach, coachName: 'coach',
  createdAt: now, updatedAt: now, publishedAt: null, exercises: [], ...o,
});
const post = (o = {}) => ({
  coachId: UID.coach, coachName: 'coach', groupIds: ['g1'], clubId: 'club1', type: 'photo',
  storagePath: `media/${UID.coach}/mp9/a.jpg`, thumbPath: null, caption: null, durationSec: null,
  createdAt: now, consentConfirmed: true, ...o,
});
const msg = (o = {}) => ({
  senderId: UID.coach, senderName: 'x', senderRole: 'coach', type: 'text', text: 'hello', createdAt: serverTimestamp(), ...o,
});
const challenge = () => ({
  groupId: 'g1', coachId: UID.coach, game: 'pathFinder', difficulty: 'hard', createdAt: serverTimestamp(), dueDate: null,
});

describe('derived entitlements (effectiveModules)', () => {
  it('payments: allowed when effective, rejected when the platform turned it off', async () => {
    await assertSucceeds(markPaid(as(UID.coach)));
    await setConfig(cfg({ effectiveModules: without('payments', 'paymentReceipts', 'paymentVerification', 'paymentReminders') }));
    await assertFails(markPaid(as(UID.coach)));
  });

  it('effectiveModules wins over allowed/enabled lists (rollout, dependencies, package)', async () => {
    // allowed + enabled say yes, but the server-derived list says no (e.g. scheduled rollout).
    await setConfig(cfg({ effectiveModules: without('trainingPlans') }));
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p1'), plan()));
  });

  it('media, training plans and coach challenges follow their features', async () => {
    await assertSucceeds(setDoc(doc(as(UID.coach), 'trainingPlans/p1'), plan()));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'mediaPosts/mp9'), post()));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'brainAssignments/c1'), challenge()));
    await setConfig(cfg({ effectiveModules: without('trainingPlans', 'media', 'coachChallenges', 'leaderboards') }));
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p2'), plan()));
    await assertFails(setDoc(doc(as(UID.coach), 'mediaPosts/mp10'), post({ storagePath: `media/${UID.coach}/mp10/a.jpg` })));
    await assertFails(setDoc(doc(as(UID.coach), 'brainAssignments/c2'), challenge()));
  });

  it('chat needs communication; acknowledgment requests also need messageAcks', async () => {
    await assertSucceeds(setDoc(doc(as(UID.coach), 'chats/g1/messages/v18m1'), msg()));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'chats/g1/messages/v18m2'), msg({ requiresAck: true })));
    await setConfig(cfg({ effectiveModules: without('messageAcks') }));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'chats/g1/messages/v18m3'), msg()));
    await assertFails(setDoc(doc(as(UID.coach), 'chats/g1/messages/v18m4'), msg({ requiresAck: true })));
    await setConfig(cfg({ effectiveModules: without('communication', 'messageAcks') }));
    await assertFails(setDoc(doc(as(UID.coach), 'chats/g1/messages/v18m5'), msg()));
  });
});

describe('organization and subscription state', () => {
  it('read-only subscription (expired / suspended / cancelled) blocks writes', async () => {
    await setConfig(cfg({ accessMode: 'readOnly' }));
    await assertFails(markPaid(as(UID.coach)));
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p1'), plan()));
    // Data stays readable to its owners.
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'payments/p1')));
  });

  it('suspended organization blocks feature writes', async () => {
    await setConfig(cfg({ status: 'suspended' }));
    await assertFails(markPaid(as(UID.coach)));
    await assertFails(setDoc(doc(as(UID.coach), 'chats/g1/messages/v18m1'), msg()));
  });

  it('an organization that is still provisioning is not usable', async () => {
    await setConfig(cfg({ provisioning: 'provisioning' }));
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p1'), plan()));
  });
});

describe('legacy compatibility', () => {
  it('a v1.7 document (no featureSchema) keeps working through the parent module', async () => {
    await setConfig({
      status: 'active', plan: 'standard',
      allowedModules: ['trainings', 'matches', 'attendance', 'communication', 'payments', 'trainingPlans'],
      enabledModules: ['trainings', 'matches', 'attendance', 'communication', 'payments', 'trainingPlans'],
    });
    await assertSucceeds(markPaid(as(UID.coach)));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'chats/g1/messages/v18m1'), msg({ requiresAck: true })));
  });

  it('a club with no configuration document keeps the pre-v1.7 feature set', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => deleteDoc(doc(ctx.firestore(), 'orgConfigs/club1')));
    await assertSucceeds(markPaid(as(UID.coach)));
  });
});

describe('platform collections', () => {
  it('nobody writes configuration, packages, templates, invitations, history or platform admins from a client', async () => {
    const platform = as(UID.admin, CLAIMS.platform);
    const clubAdmin = as(UID.clubAdminA, CLAIMS.clubA);
    for (const db of [platform, clubAdmin]) {
      await assertFails(updateDoc(doc(db, 'orgConfigs/club1'), { effectiveModules: ALL, version: 99 }));
      await assertFails(setDoc(doc(db, 'subscriptionPackages/free'), { modules: ALL }));
      await assertFails(setDoc(doc(db, 'orgTemplates/t2'), { modules: ALL }));
      await assertFails(updateDoc(doc(db, 'orgInvitations/inv1'), { status: 'accepted' }));
      await assertFails(setDoc(doc(db, 'orgConfigs/club1/history/4'), { version: 4 }));
      await assertFails(setDoc(doc(db, `platformAdmins/${UID.clubAdminA}`), { since: now }));
    }
  });

  it('organization admin cannot escalate: no self-granted modules, accessMode or status', async () => {
    const db = as(UID.clubAdminA, CLAIMS.clubA);
    await setConfig(cfg({ effectiveModules: without('payments'), accessMode: 'readOnly', status: 'suspended' }));
    await assertFails(updateDoc(doc(db, 'orgConfigs/club1'), { effectiveModules: ALL }));
    await assertFails(updateDoc(doc(db, 'orgConfigs/club1'), { accessMode: 'full' }));
    await assertFails(updateDoc(doc(db, 'orgConfigs/club1'), { status: 'active' }));
  });

  it('templates and platform admins are readable by the platform only', async () => {
    await assertSucceeds(getDoc(doc(as(UID.admin, CLAIMS.platform), 'orgTemplates/tpl-government-school')));
    await assertFails(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'orgTemplates/tpl-government-school')));
    await assertFails(getDoc(doc(as(UID.parentA), 'orgTemplates/tpl-government-school')));
    await assertSucceeds(getDoc(doc(as(UID.admin, CLAIMS.platform), `platformAdmins/${UID.admin}`)));
    await assertFails(getDoc(doc(as(UID.coach), `platformAdmins/${UID.admin}`)));
  });

  it('packages are readable by administrators, not by parents', async () => {
    await assertSucceeds(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'subscriptionPackages/professional')));
    await assertFails(getDoc(doc(as(UID.parentA), 'subscriptionPackages/professional')));
  });
});

describe('cross-tenant access', () => {
  it('invitations: own organization admin and platform only', async () => {
    await assertSucceeds(getDoc(doc(as(UID.admin, CLAIMS.platform), 'orgInvitations/inv1')));
    await assertSucceeds(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'orgInvitations/inv1')));
    await assertFails(getDoc(doc(as(UID.clubAdminB, CLAIMS.clubB), 'orgInvitations/inv1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'orgInvitations/inv1')));
  });

  it('configuration history: own organization admin and platform only', async () => {
    await assertSucceeds(getDocs(collection(as(UID.clubAdminA, CLAIMS.clubA), 'orgConfigs/club1/history')));
    await assertSucceeds(getDoc(doc(as(UID.admin, CLAIMS.platform), 'orgConfigs/club1/history/3')));
    await assertFails(getDoc(doc(as(UID.clubAdminB, CLAIMS.clubB), 'orgConfigs/club1/history/3')));
    await assertFails(getDoc(doc(as(UID.coach), 'orgConfigs/club1/history/3')));
  });

  it('a coach of another organization cannot mark payments, even with payments on', async () => {
    await assertFails(markPaid(as(UID.coachOther)));
  });
});
