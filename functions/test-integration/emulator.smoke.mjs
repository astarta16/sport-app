// End-to-end smoke test of the deployed-in-emulator functions.
// Run (from rules-tests/, which has the local firebase-tools):
//   npx firebase emulators:exec --config ../firebase.json \
//     --only functions,firestore,storage,auth --project demo-sport-parent \
//     "node ../functions/test-integration/emulator.smoke.mjs"
// Requires `npm run build` in functions/ first.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
process.env.GCLOUD_PROJECT ??= 'demo-sport-parent';
const PROJECT = process.env.GCLOUD_PROJECT;

const { initializeApp, getApps } = require('firebase-admin/app');
if (!getApps().length) initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const db = getFirestore();

const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/europe-west1`;
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

async function waitFor(fn, label, timeoutMs = 20000) {
  const start = Date.now();
  let last;
  while (Date.now() - start < timeoutMs) {
    last = await fn();
    if (last) return last;
    await new Promise((r) => setTimeout(r, 300));
  }
  throw new Error(`timeout waiting for: ${label}`);
}

async function idToken(uid, claims) {
  const auth = getAuth();
  await auth.createUser({ uid }).catch(() => undefined);
  if (claims) await auth.setCustomUserClaims(uid, claims);
  const custom = await auth.createCustomToken(uid, claims);
  const r = await fetch(`http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token: custom, returnSecureToken: true }),
  });
  const j = await r.json();
  if (!j.idToken) throw new Error('could not get id token: ' + JSON.stringify(j));
  return j.idToken;
}

async function callable(name, data, token) {
  const r = await fetch(`${FUNCTIONS}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }),
  });
  return { status: r.status, body: await r.json() };
}

const ts = (d) => Timestamp.fromDate(d);
const now = new Date();
const user = (role, extra = {}) => ({
  role, firstName: role, lastName: 'T', phone: '+995599123456', createdAt: ts(now), dataConsentAt: ts(now),
  fcmTokens: [], notificationPrefs: {}, ...extra,
});

console.log('functions emulator smoke test');

await step('publicProfiles mirrors users without phone', async () => {
  await db.doc('users/p1').set(user('parent', { smsConsentAt: ts(now) }));
  const p = await waitFor(async () => (await db.doc('publicProfiles/p1').get()).data(), 'publicProfile');
  assert.deepEqual(p, { firstName: 'parent', lastName: 'T', role: 'parent' });
});

await step('group trigger maintains parentIds, child coachIds/groupIds and audit log', async () => {
  await db.doc('users/p2').set(user('parent'));
  await db.doc('users/coach1').set(user('coach', { coachStatus: 'approved', clubIds: ['club1'] }));
  await db.doc('children/c1').set({ firstName: 'ნიკა', lastName: 'A', birthDate: ts(new Date('2014-01-01')), parentIds: ['p1'], sportIds: [], groupIds: [], photoConsent: true });
  await db.doc('children/c2').set({ firstName: 'ანა', lastName: 'B', birthDate: ts(new Date('2015-01-01')), parentIds: ['p1'], sportIds: [], groupIds: [], photoConsent: false });
  await db.doc('children/c3').set({ firstName: 'ლუკა', lastName: 'C', birthDate: ts(new Date('2015-01-01')), parentIds: ['p2'], sportIds: [], groupIds: [], photoConsent: false });
  await db.doc('sports/football').set({ name: 'ფეხბურთი', icon: 'football' });
  await db.doc('groups/g1').set({ clubId: 'club1', sportId: 'football', coachIds: ['coach1'], name: 'U12', ageMin: 10, ageMax: 12, memberChildIds: ['c1', 'c2'], parentIds: [] });
  await waitFor(async () => {
    const g = (await db.doc('groups/g1').get()).data();
    return g.parentIds?.length === 1 && g.parentIds[0] === 'p1';
  }, 'group.parentIds');
  const c1 = await waitFor(async () => {
    const c = (await db.doc('children/c1').get()).data();
    return c.coachIds?.includes('coach1') ? c : null;
  }, 'child.coachIds');
  assert.deepEqual(c1.groupIds, ['g1']);
  assert.deepEqual(c1.sportIds, ['football']);
  const audit = await db.collection('groupAuditLog').where('groupId', '==', 'g1').get();
  assert.ok(audit.size >= 1);
});

await step('approved membership request adds child; parentIds updated', async () => {
  await db.doc('membershipRequests/r1').set({ parentId: 'p2', childId: 'c3', clubId: 'club1', status: 'pending', createdAt: ts(now) });
  await db.doc('membershipRequests/r1').update({ status: 'approved', groupId: 'g1' });
  await waitFor(async () => {
    const g = (await db.doc('groups/g1').get()).data();
    return g.memberChildIds.includes('c3') && g.parentIds.includes('p2');
  }, 'c3 joined');
});

await step('removing a child revokes coach access (children.coachIds cleared)', async () => {
  await db.doc('groups/g1').update({ memberChildIds: FieldValue.arrayRemove('c2') });
  await waitFor(async () => {
    const c = (await db.doc('children/c2').get()).data();
    return (c.coachIds ?? []).length === 0 && (c.groupIds ?? []).length === 0;
  }, 'c2 coachIds cleared');
});

await step('moving a training sets status=moved and previousStartAt', async () => {
  const start = new Date(now.getTime() + 3 * 86400000);
  await db.doc('trainings/t1').set({ groupId: 'g1', venueId: 'v1', startAt: ts(start), durationMin: 60, focus: ['ball'], description: '', photoUrls: [], status: 'scheduled', createdBy: 'coach1', updatedAt: ts(now) });
  await new Promise((r) => setTimeout(r, 1000));
  await db.doc('trainings/t1').update({ startAt: ts(new Date(start.getTime() + 86400000)) });
  const t = await waitFor(async () => {
    const d = (await db.doc('trainings/t1').get()).data();
    return d.status === 'moved' ? d : null;
  }, 'status moved');
  assert.equal(t.previousStartAt.toMillis(), start.getTime());
});

await step('certificate status computed on create; getCertificateUrl checks access and logs', async () => {
  await db.doc('medicalCertificates/cert1').set({
    childId: 'c1', uploadedBy: 'p1', storagePath: 'medical/c1/cert1', issuedAt: ts(new Date('2026-01-01')),
    validUntil: ts(new Date(now.getTime() + 5 * 86400000)), consentAt: ts(now), status: 'valid',
  });
  await waitFor(async () => (await db.doc('medicalCertificates/cert1').get()).get('status') === 'expiring', 'status expiring');
  await getStorage().bucket().file('medical/c1/cert1').save(Buffer.from('%PDF-1.4'), { contentType: 'application/pdf' });

  const ok = await callable('getCertificateUrl', { certId: 'cert1' }, await idToken('p1'));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.match(ok.body.result.url, /medical%2Fc1%2Fcert1/);
  const denied = await callable('getCertificateUrl', { certId: 'cert1' }, await idToken('p2'));
  assert.equal(denied.status, 403, JSON.stringify(denied.body));
  const coach = await callable('getCertificateUrl', { certId: 'cert1' }, await idToken('coach1'));
  assert.equal(coach.status, 200, JSON.stringify(coach.body));
  const unauth = await callable('getCertificateUrl', { certId: 'cert1' });
  assert.equal(unauth.status, 401);
  const log = await db.collection('certificateAccessLog').where('certId', '==', 'cert1').get();
  assert.equal(log.size, 2);
});

await step('deleteCertificate removes metadata and file (parent only)', async () => {
  const denied = await callable('deleteCertificate', { certId: 'cert1' }, await idToken('p2'));
  assert.equal(denied.status, 403);
  const ok = await callable('deleteCertificate', { certId: 'cert1' }, await idToken('p1'));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.equal((await db.doc('medicalCertificates/cert1').get()).exists, false);
  const [exists] = await getStorage().bucket().file('medical/c1/cert1').exists();
  assert.equal(exists, false);
});

await step('setCoachStatus is admin-only', async () => {
  await db.doc('users/coach2').set(user('coach', { coachStatus: 'pending', clubIds: ['club1'] }));
  const denied = await callable('setCoachStatus', { uid: 'coach2', status: 'approved' }, await idToken('p1'));
  assert.equal(denied.status, 403);
  const ok = await callable('setCoachStatus', { uid: 'coach2', status: 'approved' }, await idToken('admin1', { admin: true }));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.equal((await db.doc('users/coach2').get()).get('coachStatus'), 'approved');
});

await step('getParentPhone: coach of the group yes, other parent no', async () => {
  const ok = await callable('getParentPhone', { parentUid: 'p2' }, await idToken('coach1'));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.equal(ok.body.result.phone, '+995599123456');
  const denied = await callable('getParentPhone', { parentUid: 'p2' }, await idToken('p1'));
  assert.equal(denied.status, 403);
});

await step('payment reminders: combined SMS per parent, claimed once, masked log', async () => {
  const { runPaymentReminders } = require('../lib/triggers/payments.js');
  const { tbilisiParts, tbilisiLocalToUtc } = require('../lib/lib/dates.js');
  const p = tbilisiParts(now);
  const dueIn5 = tbilisiLocalToUtc(p.year, p.month, p.day + 5, 12);
  const created = ts(new Date(now.getTime() - 10 * 86400000));
  const base = { parentId: 'p1', groupId: 'g1', sportId: 'football', currency: 'GEL', dueDate: ts(dueIn5), status: 'pending', reminders: {}, createdAt: created };
  await db.doc('payments/pay1').set({ ...base, childId: 'c1', amount: 80 });
  await db.doc('payments/pay2').set({ ...base, childId: 'c2', amount: 70 });
  const r1 = await runPaymentReminders(now);
  const r2 = await runPaymentReminders(now);
  assert.deepEqual(r1, { claimed: 2, batches: 1 });
  assert.deepEqual(r2, { claimed: 0, batches: 0 });
  const logs = await db.collection('smsLog').get();
  assert.equal(logs.size, 1);
  const entry = logs.docs[0].data();
  assert.equal(entry.status, 'mocked');
  assert.equal(entry.provider, 'mock');
  assert.equal(entry.phone, '+995*****3456');
  assert.deepEqual(entry.paymentIds.sort(), ['pay1', 'pay2']);
  assert.ok((await db.doc('payments/pay1').get()).get('reminders.d5SentAt'));
});

await step('recurring payments are idempotent per plan/child/month', async () => {
  const { runRecurringPayments } = require('../lib/triggers/payments.js');
  await db.doc('paymentPlans/plan1').set({ groupId: 'g1', sportId: 'football', amount: 80, currency: 'GEL', dayOfMonth: 10, active: true, createdBy: 'coach1' });
  const a = await runRecurringPayments(now);
  const b = await runRecurringPayments(now);
  assert.equal(a.created, 2); // c1 and c3 are members
  assert.deepEqual(b, { created: 0, skipped: 2 });
});

await step('deleteAccount removes solely-owned children and their data', async () => {
  const token = await idToken('p2');
  const r = await callable('deleteAccount', {}, token);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.deepEqual(r.body.result.deleted, ['c3']);
  assert.equal((await db.doc('children/c3').get()).exists, false);
  assert.equal((await db.doc('users/p2').get()).exists, false);
  await waitFor(async () => !(await db.doc('groups/g1').get()).get('parentIds').includes('p2'), 'p2 removed from group');
});

console.log(`${passed} smoke steps passed${process.exitCode ? ' (with failures)' : ''}`);
