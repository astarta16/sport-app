// v1.7 Cloud Functions integration test against the local emulators.
// Run (from rules-tests/, which has the local firebase-tools):
//   npm --prefix ../functions run build
//   npx firebase emulators:exec --config ../firebase.json \
//     --only functions,firestore,auth --project demo-sport-parent \
//     "node ../functions/test-integration/v17.integration.mjs"
// Synthetic data only; nothing leaves the machine.
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

async function idToken(uid, claims) {
  const auth = getAuth();
  await auth.createUser({ uid }).catch(() => undefined);
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

const ts = (d) => Timestamp.fromDate(d);
const now = new Date();
const STANDARD = ['trainings', 'matches', 'attendance', 'communication', 'notifications', 'studentAccounts',
  'brainAcademy', 'trainingPlans', 'payments', 'medicalCertificates', 'media'];
// Tomorrow 10:00 Tbilisi.
const t0 = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 6, 0));
const iso = (d, min = 0) => new Date(d.getTime() + min * 60_000).toISOString();

console.log('v1.7 functions integration test');

const platform = await idToken('it-platform', { admin: true });
const adminA = await idToken('it-admin-a', { clubAdmin: ['it-org-a'] });
const adminB = await idToken('it-admin-b', { clubAdmin: ['it-org-b'] });
const parent = await idToken('it-parent');
const student = await idToken('it-student');

await Promise.all([
  db.doc('clubs/it-org-a').set({ name: 'Org A', address: 'Tianeti', sportIds: ['volleyball'], adminIds: ['it-admin-a'] }),
  db.doc('clubs/it-org-b').set({ name: 'Org B', address: 'Mtskheta', sportIds: ['badminton'], adminIds: ['it-admin-b'] }),
  db.doc('orgConfigs/it-org-a').set({ status: 'active', plan: 'premium', allowedModules: [...STANDARD, 'roomScheduling', 'leaderboards'], enabledModules: [...STANDARD, 'roomScheduling', 'leaderboards'], timezone: 'Asia/Tbilisi', leaderboard: { enabled: true, minParticipants: 2, periods: ['week'] } }),
  db.doc('orgConfigs/it-org-b').set({ status: 'active', plan: 'standard', allowedModules: [...STANDARD, 'roomScheduling'], enabledModules: [...STANDARD, 'roomScheduling'], timezone: 'Asia/Tbilisi' }),
  db.doc('clubs/it-org-a/rooms/hall-a').set({ orgId: 'it-org-a', clubId: 'it-org-a', name: 'Hall A', capacity: 30, status: 'active' }),
  db.doc('clubs/it-org-b/rooms/hall-z').set({ orgId: 'it-org-b', clubId: 'it-org-b', name: 'Hall Z', capacity: 30, status: 'active' }),
  db.doc('users/it-parent').set({ role: 'parent', firstName: 'P', lastName: 'T', phone: '+995599000001' }),
  db.doc('users/it-student').set({ role: 'child', firstName: 'S', lastName: 'T', phone: '+995599000002', lastContext: { childId: 'it-child' } }),
  db.doc('children/it-child').set({ firstName: 'Ana', lastName: 'Kapanadze', birthDate: ts(new Date('2016-03-01')), parentIds: ['it-parent'], userId: 'it-student', groupIds: ['it-g'] }),
  db.doc('groups/it-g').set({ clubId: 'it-org-a', sportId: 'volleyball', name: 'U10', coachIds: [], memberChildIds: ['it-child'], parentIds: ['it-parent'], status: 'active' }),
]);

const draft = (start, minutes, extra = {}) => ({
  orgId: 'it-org-a', roomId: 'hall-a', kind: 'event', title: 'IT', startAt: iso(start), endAt: iso(start, minutes), ...extra,
});

await step('concurrent reservations of the same room slot: exactly one wins', async () => {
  const [a, b, c] = await Promise.all([
    call('createBooking', draft(t0, 60), adminA),
    call('createBooking', draft(t0, 60, { title: 'second' }), adminA),
    call('createBooking', draft(new Date(t0.getTime() + 30 * 60_000), 60, { title: 'third' }), adminA),
  ]);
  const ok = [a, b, c].filter((r) => r.status === 200);
  const rejected = [a, b, c].filter((r) => r.status !== 200);
  assert.equal(ok.length, 1, JSON.stringify([a, b, c]));
  for (const r of rejected) {
    assert.equal(r.body.error.status, 'FAILED_PRECONDITION');
    assert.ok(r.body.error.details.conflicts.some((x) => x.code === 'roomOverlap'));
  }
  const snap = await db.collection('clubs/it-org-a/bookings').get();
  assert.equal(snap.size, 1);
});

await step('adjacent slot is accepted; rejection carries alternatives', async () => {
  // The previous step's winner is either the 10:00 or the 10:30 booking
  // (concurrent requests), so the adjacent slot starts where it ends.
  const [winner] = (await db.collection('clubs/it-org-a/bookings').get()).docs;
  const start = winner.get('startAt').toDate();
  const end = winner.get('endAt').toDate();
  const r = await call('createBooking', draft(end, 60), adminA);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const bad = await call('createBooking', draft(start, 30), adminA);
  assert.equal(bad.status, 400);
  assert.ok(bad.body.error.details.alternatives.length > 0);
});

await step('recurring series: one conflicting occurrence rejects the whole series', async () => {
  const before = (await db.collection('clubs/it-org-a/bookings').get()).size;
  const d = new Date(t0);
  const ymd = (x) => x.toISOString().slice(0, 10);
  const wd = ((new Date(t0.getTime() + 4 * 3600_000).getUTCDay() + 6) % 7) + 1;
  const r = await call('createRecurringBookings', {
    ...draft(t0, 60), rule: { weekdays: [wd], startMinute: 600, durationMin: 60, from: ymd(d), until: ymd(new Date(d.getTime() + 28 * 86400_000)) },
  }, adminA);
  assert.equal(r.status, 400, JSON.stringify(r.body));
  assert.equal((await db.collection('clubs/it-org-a/bookings').get()).size, before);
});

await step('cross-tenant: an organization admin cannot book or configure another tenant', async () => {
  const r1 = await call('createBooking', { ...draft(t0, 60), orgId: 'it-org-b', roomId: 'hall-z' }, adminA);
  assert.equal(r1.body.error.status, 'PERMISSION_DENIED');
  const r2 = await call('updateOrgSettings', { orgId: 'it-org-b', bookingBufferMin: 5 }, adminA);
  assert.equal(r2.body.error.status, 'PERMISSION_DENIED');
  // Org B may book the same wall-clock time in its own room.
  const r3 = await call('createBooking', { ...draft(t0, 60), orgId: 'it-org-b', roomId: 'hall-z' }, adminB);
  assert.equal(r3.status, 200, JSON.stringify(r3.body));
});

await step('feature flags: no self-enabling of restricted modules; platform-only fields', async () => {
  const r1 = await call('updateOrgSettings', { orgId: 'it-org-b', enabledModules: [...STANDARD, 'leaderboards'] }, adminB);
  assert.equal(r1.body.error.status, 'PERMISSION_DENIED');
  const r2 = await call('updateOrgPlatform', { orgId: 'it-org-b', status: 'active', allowedModules: [...STANDARD, 'leaderboards'] }, adminB);
  assert.equal(r2.body.error.status, 'PERMISSION_DENIED');
  const r3 = await call('updateOrgPlatform', { orgId: 'it-org-b', allowedModules: STANDARD }, platform);
  assert.equal(r3.status, 200);
  const r4 = await call('createBooking', { ...draft(new Date(t0.getTime() + 5 * 3600_000), 60), orgId: 'it-org-b', roomId: 'hall-z' }, adminB);
  assert.match(r4.body.error.message, /moduleDisabled:roomScheduling/);
  const cfg = (await db.doc('orgConfigs/it-org-b').get()).data();
  assert.ok(!cfg.enabledModules.includes('roomScheduling'), 'withdrawn modules are switched off');
});

await step('platform admin creates an organization and assigns its admin (claims)', async () => {
  const r = await call('createOrganization', { name: 'Gori School', address: 'Gori', lat: 41.98, lng: 44.11, plan: 'standard', sportIds: ['volleyball'] }, platform);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const id = r.body.result.id;
  const cfg = (await db.doc(`orgConfigs/${id}`).get()).data();
  assert.ok(!cfg.enabledModules.includes('leaderboards'));
  await getAuth().createUser({ uid: 'it-new-admin' }).catch(() => undefined);
  const a = await call('setOrgAdmin', { orgId: id, userId: 'it-new-admin', admin: true }, platform);
  assert.equal(a.status, 200, JSON.stringify(a.body));
  const claims = (await getAuth().getUser('it-new-admin')).customClaims;
  assert.deepEqual(claims.clubAdmin, [id]);
  const denied = await call('createOrganization', { name: 'X', address: 'Y', lat: 1, lng: 1 }, adminA);
  assert.equal(denied.body.error.status, 'PERMISSION_DENIED');
});

await step('leaderboard: guardian consent only; no consent → private progress; pseudonyms', async () => {
  const s1 = await call('setLeaderboardConsent', { orgId: 'it-org-a', childId: 'it-child', granted: true }, student);
  assert.equal(s1.body.error.status, 'PERMISSION_DENIED', 'the child cannot consent');
  const b0 = await call('getLeaderboard', { orgId: 'it-org-a', childId: 'it-child', period: 'week' }, student);
  assert.equal(b0.body.result.unavailable, 'notConsented');
  const s2 = await call('setLeaderboardConsent', { orgId: 'it-org-a', childId: 'it-child', granted: true, mode: 'pseudonym' }, parent);
  assert.equal(s2.status, 200, JSON.stringify(s2.body));
  const b1 = await call('getLeaderboard', { orgId: 'it-org-a', childId: 'it-child', period: 'week' }, student);
  assert.equal(b1.body.result.unavailable, 'tooFewParticipants', 'minimum visibility');
  const other = await call('getLeaderboard', { orgId: 'it-org-a', childId: 'it-child', period: 'week' }, adminB);
  assert.equal(other.body.error.status, 'PERMISSION_DENIED');
  const consent = (await db.doc('clubs/it-org-a/leaderboardConsents/it-child').get()).data();
  assert.ok(!consent.displayName.includes('Kapanadze'));
});

console.log(`${passed} v1.7 integration steps passed`);
