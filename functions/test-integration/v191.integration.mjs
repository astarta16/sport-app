// v1.9.1 integration test: organization admins manage their own groups.
// Run (from rules-tests/):
//   npm --prefix ../functions run build
//   npx firebase emulators:exec --config ../firebase.json \
//     --only functions,firestore,auth --project demo-sport-parent \
//     "node ../functions/test-integration/v191.integration.mjs"
// Synthetic data only; nothing leaves the machine; no SMS is sent (mock provider).
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
  return (await r.json()).idToken;
}
async function call(name, data, token) {
  const r = await fetch(`${FUNCTIONS}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }),
  });
  return { status: r.status, body: await r.json() };
}
const ok = (r) => { assert.equal(r.status, 200, JSON.stringify(r.body)); return r.body.result; };
const err = (r, status) => { assert.equal(r.body?.error?.status, status, JSON.stringify(r.body)); return r.body.error; };

console.log('v1.9.1 organization-admin groups integration test');

const adminA = await idToken('g191-admin-a', { clubAdmin: ['g191-a'] });
const adminB = await idToken('g191-admin-b', { clubAdmin: ['g191-b'] });
const coachA = await idToken('g191-coach-a');
const parent = await idToken('g191-parent', undefined, '+995599019001');
const parent2 = await idToken('g191-parent2', undefined, '+995599019002');
const anon = null;
const user = (role, extra = {}) => ({ role, firstName: role, lastName: 'T', phone: '+995599019000', createdAt: Timestamp.now(), ...extra });
await Promise.all([
  db.doc('clubs/g191-a').set({ name: 'Org A', address: 'x', sportIds: ['volleyball'], adminIds: ['g191-admin-a'], status: 'active' }),
  db.doc('clubs/g191-b').set({ name: 'Org B', address: 'x', sportIds: ['volleyball'], adminIds: ['g191-admin-b'], status: 'active' }),
  db.doc('orgConfigs/g191-a').set({ status: 'active', accessMode: 'full', featureSchema: 2, limits: { maxGroups: 2 }, effectiveModules: ['trainings'] }),
  db.doc('users/g191-coach-a').set(user('coach', { coachStatus: 'approved', clubIds: ['g191-a'] })),
  db.doc('users/g191-coach-b').set(user('coach', { coachStatus: 'approved', clubIds: ['g191-b'] })),
  db.doc('users/g191-parent').set(user('parent', { phone: '+995599019001' })),
  db.doc('users/g191-parent2').set(user('parent', { phone: '+995599019002' })),
]);
const base = { clubId: 'g191-a', sportId: 'volleyball', name: 'U-10', ageMin: 8, ageMax: 10 };
let groupId;

await step('org admin creates a group in their organization with its coach and a capacity', async () => {
  const r = ok(await call('createGroup', { ...base, coachIds: ['g191-coach-a'], capacity: 1 }, adminA));
  groupId = r.groupId;
  const g = (await db.doc(`groups/${groupId}`).get()).data();
  assert.deepEqual(g.coachIds, ['g191-coach-a']);
  assert.equal(g.capacity, 1);
  assert.equal(g.createdBy, 'g191-admin-a');
  assert.ok(r.inviteCode.length === 6);
});

await step('denied: another organization, foreign coach, no coach, bad capacity, unauthenticated', async () => {
  err(await call('createGroup', { ...base, clubId: 'g191-b', coachIds: ['g191-coach-b'] }, adminA), 'PERMISSION_DENIED');
  err(await call('createGroup', { ...base, coachIds: ['g191-coach-b'] }, adminA), 'FAILED_PRECONDITION');
  err(await call('createGroup', { ...base, coachIds: [] }, adminA), 'INVALID_ARGUMENT');
  err(await call('createGroup', { ...base, coachIds: ['g191-coach-a'], capacity: 0 }, adminA), 'INVALID_ARGUMENT');
  err(await call('createGroup', { ...base, coachIds: ['g191-coach-a'] }, anon), 'UNAUTHENTICATED');
});

await step('coach permissions preserved; the organization group limit is enforced for everyone', async () => {
  ok(await call('createGroup', base, coachA)); // 2nd active group (limit 2)
  err(await call('createGroup', base, coachA), 'RESOURCE_EXHAUSTED');
  err(await call('createGroup', { ...base, coachIds: ['g191-coach-a'] }, adminA), 'RESOURCE_EXHAUSTED');
});

await step('suspended organization: no new groups', async () => {
  await db.doc('orgConfigs/g191-a').update({ status: 'suspended' });
  err(await call('createGroup', { ...base, coachIds: ['g191-coach-a'] }, adminA), 'FAILED_PRECONDITION');
  await db.doc('orgConfigs/g191-a').update({ status: 'active' });
});

let inviteId;
await step('org admin invites a guardian; nobody joins before the guardian accepts', async () => {
  const r = ok(await call('createInvite', {
    groupId, pendingChild: { firstName: 'Ana', lastName: 'Test', birthDate: '2017-03-01', parentPhone: '+995599019001' },
  }, adminA));
  inviteId = r.inviteId ?? r.id;
  assert.ok(inviteId, JSON.stringify(r));
  assert.deepEqual((await db.doc(`groups/${groupId}`).get()).get('memberChildIds'), []);
  err(await call('createInvite', {
    groupId, pendingChild: { firstName: 'X', lastName: 'Y', birthDate: '2017-03-01', parentPhone: '+995599019002' },
  }, adminB), 'PERMISSION_DENIED');
  ok(await call('respondInvite', { inviteId, accept: true }, parent));
  assert.equal((await db.doc(`groups/${groupId}`).get()).get('memberChildIds').length, 1);
});

await step('capacity: a full group refuses the next child', async () => {
  const r = ok(await call('createInvite', {
    groupId, pendingChild: { firstName: 'Nika', lastName: 'Test', birthDate: '2017-05-01', parentPhone: '+995599019002' },
  }, adminA));
  err(await call('respondInvite', { inviteId: r.inviteId ?? r.id, accept: true }, parent2), 'RESOURCE_EXHAUSTED');
});

await step('roster is minimal and own-organization only; removal by org admin', async () => {
  const r = ok(await call('adminGroupRoster', { groupId }, adminA));
  assert.equal(r.children.length, 1);
  assert.deepEqual(Object.keys(r.children[0]).sort(), ['birthYear', 'childId', 'firstName', 'lastInitial']);
  assert.equal(r.children[0].lastInitial, 'T');
  err(await call('adminGroupRoster', { groupId }, adminB), 'PERMISSION_DENIED');
  err(await call('updateGroup', { groupId, removeChildIds: [r.children[0].childId] }, adminB), 'PERMISSION_DENIED');
  err(await call('updateGroup', { groupId, removeChildIds: [r.children[0].childId] }, coachA), 'PERMISSION_DENIED');
  ok(await call('updateGroup', { groupId, removeChildIds: [r.children[0].childId], capacity: 5, ageMin: 7 }, adminA));
  const g = (await db.doc(`groups/${groupId}`).get()).data();
  assert.deepEqual(g.memberChildIds, []);
  assert.equal(g.capacity, 5);
  assert.equal(g.ageMin, 7);
});

await step('no privilege escalation: an org admin cannot touch platform callables', async () => {
  err(await call('updateEntitlements', { orgId: 'g191-a', expectedVersion: 1, allowed: ['trainings'], reason: 'self-grant' }, adminA), 'PERMISSION_DENIED');
  err(await call('provisionOrganization', {}, adminA), 'PERMISSION_DENIED');
});

console.log(`${passed} passed`);
