// v1.8 Cloud Functions integration test against the local emulators.
// Run (from rules-tests/, which has the local firebase-tools):
//   npm --prefix ../functions run build
//   npx firebase emulators:exec --config ../firebase.json \
//     --only functions,firestore,auth --project demo-sport-parent \
//     "node ../functions/test-integration/v18.integration.mjs"
// Synthetic data only; nothing leaves the machine; no SMS, no billing.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
process.env.GCLOUD_PROJECT ??= 'demo-sport-parent';
const PROJECT = process.env.GCLOUD_PROJECT;
const { initializeApp, getApps } = require('firebase-admin/app');
if (!getApps().length) initializeApp({ projectId: PROJECT });
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const db = getFirestore();

const FUNCTIONS = `${process.env.FUNCTIONS_EMULATOR_ORIGIN ?? 'http://127.0.0.1:5001'}/${PROJECT}/europe-west1`;
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099';

let passed = 0;
async function step(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  ok  ${name}`);
  } catch (e) {
    console.error(`  FAIL ${name}\n`, e);
    process.exitCode = 1;
  }
}

async function idToken(uid, claims, phoneNumber) {
  const auth = getAuth();
  await auth.createUser({ uid, ...(phoneNumber ? { phoneNumber } : {}) }).catch(() => undefined);
  if (claims) await auth.setCustomUserClaims(uid, claims);
  const custom = await auth.createCustomToken(uid, claims);
  const r = await fetch(`http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: custom, returnSecureToken: true }),
  });
  const j = await r.json();
  if (!j.idToken) throw new Error('no id token: ' + JSON.stringify(j));
  return j.idToken;
}

async function call(name, data, token) {
  const r = await fetch(`${FUNCTIONS}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }),
  });
  return { status: r.status, body: await r.json() };
}
const ok = (r) => {
  assert.equal(r.status, 200, JSON.stringify(r.body));
  return r.body.result;
};
const err = (r, status) => {
  assert.equal(r.body?.error?.status, status, JSON.stringify(r.body));
  return r.body.error;
};

console.log('v1.8 functions integration test');

const platform = await idToken('it18-platform', { admin: true });
const orgAdmin = await idToken('it18-org-admin', { clubAdmin: ['it18-existing'] });
const invitee = await idToken('it18-invitee', undefined, '+995599018001');
const stranger = await idToken('it18-stranger', undefined, '+995599018002');

await Promise.all([
  db.doc('sports/volleyball').set({ name: 'Volleyball', ageMin: 6 }),
  db.doc('clubs/it18-existing').set({ name: 'Existing', address: 'Tbilisi', sportIds: ['volleyball'], adminIds: ['it18-org-admin'] }),
  db.doc('orgConfigs/it18-existing').set({
    status: 'active', plan: 'standard', allowedModules: ['trainings', 'payments', 'communication'],
    enabledModules: ['trainings', 'payments', 'communication'], version: 1,
  }),
  db.doc('users/it18-invitee').set({ role: 'parent', firstName: 'I', lastName: 'T', phone: '+995599018001' }),
]);

let provisioned;
await step('provisionOrganization: platform only, two-phase, derived fields, invitation hash', async () => {
  const req = {
    names: { ka: 'ტესტ სკოლა', en: 'Test School' }, legalName: 'Test School (synthetic)', type: 'sportsSchool',
    funding: 'government', address: 'Street 1', city: 'Tbilisi', contactEmail: 'info@test.example',
    contactPhone: '+995599018000', sportIds: ['volleyball'], packageId: 'professional',
    modules: ['trainings', 'matches', 'attendance', 'communication'], adminPhone: '+995599018001',
  };
  err(await call('provisionOrganization', req, orgAdmin), 'PERMISSION_DENIED');
  err(await call('provisionOrganization', { ...req, modules: ['paymentReceipts'] }, platform), 'INVALID_ARGUMENT');
  provisioned = ok(await call('provisionOrganization', req, platform));
  assert.match(provisioned.orgId, /^org-test-school-/);
  const cfg = (await db.doc(`orgConfigs/${provisioned.orgId}`).get()).data();
  assert.equal(cfg.provisioning, 'ready');
  assert.equal(cfg.featureSchema, 2);
  assert.equal(cfg.accessMode, 'full');
  assert.ok(cfg.effectiveModules.includes('attendance'));
  assert.ok(!cfg.effectiveModules.includes('payments'));
  const inv = (await db.doc(`orgInvitations/${provisioned.invitationId}`).get()).data();
  assert.notEqual(inv.tokenHash, provisioned.token, 'only the hash is stored');
  assert.equal(inv.tokenHash.length, 64);
});

await step('acceptInvitation: bound to the invited phone, grants org admin claims', async () => {
  err(await call('acceptInvitation', { token: provisioned.token }, stranger), 'PERMISSION_DENIED');
  const r = ok(await call('acceptInvitation', { token: provisioned.token }, invitee));
  assert.equal(r.orgId, provisioned.orgId);
  const u = await getAuth().getUser('it18-invitee');
  assert.deepEqual(u.customClaims.clubAdmin, [provisioned.orgId]);
  assert.notEqual(u.customClaims.admin, true);
  err(await call('acceptInvitation', { token: provisioned.token }, invitee), 'FAILED_PRECONDITION');
});

await step('updateEntitlements: versioned, conflict detected, history written', async () => {
  const cfg = (await db.doc(`orgConfigs/${provisioned.orgId}`).get()).data();
  const v = cfg.version;
  const allowed = [...cfg.allowedModules.filter((m) => m !== 'media')];
  const r = ok(await call('updateEntitlements', { orgId: provisioned.orgId, expectedVersion: v, allowed, reason: 'no media yet' }, platform));
  assert.equal(r.version, v + 1);
  const stale = await call('updateEntitlements', { orgId: provisioned.orgId, expectedVersion: v, allowed: cfg.allowedModules, reason: 'stale' }, platform);
  const e = err(stale, 'ABORTED');
  assert.equal(e.details.currentVersion, v + 1);
  const h = (await db.doc(`orgConfigs/${provisioned.orgId}/history/${v + 1}`).get()).data();
  assert.equal(h.reason, 'no media yet');
  assert.equal(h.by, 'it18-platform');
  err(await call('updateEntitlements', { orgId: provisioned.orgId, expectedVersion: v + 1, allowed: ['paymentReceipts'], reason: 'bad set' }, platform), 'INVALID_ARGUMENT');
  err(await call('updateEntitlements', { orgId: provisioned.orgId, expectedVersion: v + 1, allowed, reason: 'x' }, invitee), 'PERMISSION_DENIED');
});

await step('updateSubscription: suspended → read-only (derived), data kept', async () => {
  const cfg = (await db.doc(`orgConfigs/${provisioned.orgId}`).get()).data();
  ok(await call('updateSubscription', {
    orgId: provisioned.orgId, expectedVersion: cfg.version, subscription: { status: 'suspended' }, reason: 'contract paused',
  }, platform));
  const after = (await db.doc(`orgConfigs/${provisioned.orgId}`).get()).data();
  assert.equal(after.accessMode, 'readOnly');
  assert.deepEqual(after.effectiveModules, []);
  assert.ok((await db.doc(`clubs/${provisioned.orgId}`).get()).exists);
});

await step('legacy v1.7 config: first versioned write expands coarse modules', async () => {
  const cfg = (await db.doc('orgConfigs/it18-existing').get()).data();
  ok(await call('updateSubscription', { orgId: 'it18-existing', expectedVersion: cfg.version, subscription: { status: 'active' }, reason: 'migrate' }, platform));
  const after = (await db.doc('orgConfigs/it18-existing').get()).data();
  assert.equal(after.featureSchema, 2);
  assert.ok(after.effectiveModules.includes('paymentReceipts'));
  assert.ok(after.effectiveModules.includes('messageAcks'));
});

await step('refreshEntitlementsNow: platform only; expires an ended trial', async () => {
  await db.doc('orgConfigs/it18-trial').set({
    status: 'active', plan: 'free', allowedModules: ['trainings'], enabledModules: ['trainings'], featureSchema: 2, version: 1,
    subscription: { status: 'trial', endAt: Timestamp.fromMillis(Date.now() - 86400_000), graceDays: 0 },
  });
  err(await call('refreshEntitlementsNow', {}, orgAdmin), 'PERMISSION_DENIED');
  const r = ok(await call('refreshEntitlementsNow', {}, platform));
  assert.ok(r.changed.includes('it18-trial'));
  const after = (await db.doc('orgConfigs/it18-trial').get()).data();
  assert.equal(after.subscription.status, 'expired');
  assert.equal(after.accessMode, 'readOnly');
});

await step('invitations: org admin cannot invite to another org; revoke closes it', async () => {
  err(await call('inviteOrgAdmin', { orgId: provisioned.orgId, phone: '+995599018003' }, orgAdmin), 'PERMISSION_DENIED');
  const i = ok(await call('inviteOrgAdmin', { orgId: provisioned.orgId, phone: '+995599018002' }, platform));
  ok(await call('revokeInvitation', { invitationId: i.invitationId }, platform));
  err(await call('acceptInvitation', { token: i.token }, stranger), 'FAILED_PRECONDITION');
});

console.log(`${passed} passed`);
