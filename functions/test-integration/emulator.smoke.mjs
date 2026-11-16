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
  const pub = await waitFor(async () => (await db.doc('clubs/club1/publicGroups/g1').get()).data() ?? null, 'publicGroups projection');
  assert.equal(pub.name, 'U12');
  assert.equal(pub.ageMin, 10);
  for (const k of ['memberChildIds', 'parentIds', 'coachIds']) assert.ok(!(k in pub), `publicGroups leaks ${k}`);
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


// ------------------------------------------------------------ v1.1 / v1.2 end-to-end flow
const { createHash } = await import('node:crypto');
const series = require('../lib/lib/series.js');
const sha1 = (x) => createHash('sha1').update(x).digest('hex');
const E2E = {};

await step('v1.2: coach creates group via callable -> unique invite code + groupCodes index', async () => {
  await db.doc('clubs/clubS').set({ name: 'Smoke Club', address: 'Tbilisi', sportIds: ['football'], status: 'active', adminIds: [] });
  await db.doc('users/coachS').set(user('coach', { coachStatus: 'approved', clubIds: ['clubS'] }));
  await db.doc('users/parentS').set(user('parent', { phone: '+995599777001' }));
  await db.doc('children/childS').set({ firstName: 'გიორგი', lastName: 'S', birthDate: ts(new Date('2015-04-01')), parentIds: ['parentS'], sportIds: [], groupIds: [], photoConsent: false });
  const r = await callable('createGroup', { clubId: 'clubS', sportId: 'football', name: 'U11', ageMin: 9, ageMax: 11 }, await idToken('coachS'));
  assert.equal(r.status, 200, JSON.stringify(r.body));
  E2E.groupId = r.body.result.groupId;
  assert.match(r.body.result.inviteCode, /^[A-HJ-NP-Z2-9]{6}$/);
  assert.equal((await db.doc(`groupCodes/${r.body.result.inviteCode}`).get()).get('groupId'), E2E.groupId);
  const denied = await callable('createGroup', { clubId: 'club1', sportId: 'football', name: 'X', ageMin: 9, ageMax: 11 }, await idToken('coachS'));
  assert.equal(denied.status, 403);
});

await step('v1.2: invite (coach-created pending child) -> parent resolved by phone, inbox entry, nothing linked', async () => {
  const r = await callable('createInvite', {
    groupId: E2E.groupId, pendingChild: { firstName: 'გიორგი', lastName: 'S', birthDate: '2015-04-01T00:00:00.000', parentPhone: '599 777 001' },
  }, await idToken('coachS'));
  assert.equal(r.status, 200, JSON.stringify(r.body));
  E2E.inviteId = r.body.result.inviteId;
  E2E.pendingChildId = r.body.result.childId;
  const inv = (await db.doc(`invites/${E2E.inviteId}`).get()).data();
  assert.equal(inv.parentId, 'parentS');
  assert.equal(inv.status, 'sent');
  const pending = (await db.doc(`children/${E2E.pendingChildId}`).get()).data();
  assert.equal(pending.status, 'pendingParent');
  assert.deepEqual(pending.parentIds, []);
  const n = await db.doc(`notifications/${sha1(`parentS|invite:${E2E.inviteId}`)}`).get();
  assert.equal(n.get('type'), 'groupInvite');
  assert.equal(n.get('category'), 'invitations');
  const wrong = await callable('respondInvite', { inviteId: E2E.inviteId, accept: true, mediaConsent: true }, await idToken('p1'));
  assert.equal(wrong.status, 403);
});

await step('v1.2: parent accepts linking the EXISTING child -> joins group, pending child deleted, coach gains access', async () => {
  const r = await callable('respondInvite', { inviteId: E2E.inviteId, accept: true, linkedChildId: 'childS', mediaConsent: true }, await idToken('parentS'));
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.equal(r.body.result.childId, 'childS');
  assert.equal((await db.doc(`children/${E2E.pendingChildId}`).get()).exists, false);
  await waitFor(async () => {
    const g = (await db.doc(`groups/${E2E.groupId}`).get()).data();
    return g.memberChildIds.includes('childS') && g.parentIds.includes('parentS');
  }, 'childS joined');
  await waitFor(async () => ((await db.doc('children/childS').get()).get('coachIds') ?? []).includes('coachS'), 'child.coachIds');
  const c = (await db.doc('children/childS').get()).data();
  assert.equal(c.mediaConsent, true);
  assert.equal(c.photoConsent, true);
  const again = await callable('respondInvite', { inviteId: E2E.inviteId, accept: true, mediaConsent: true }, await idToken('parentS'));
  assert.equal(again.status, 400); // failed-precondition: already accepted
});

await step('v1.2: coach creates a series -> occurrences with deterministic ids, one summary notification', async () => {
  const today = series.tbilisiDateKey(new Date());
  const rule = {
    groupId: E2E.groupId, clubId: 'clubS', venueId: 'v1', weekdays: [1, 3, 5], startTime: '18:00', durationMin: 60, focus: ['ball'],
    description: 'Smoke', startDate: today, endDate: null, status: 'active', createdBy: 'coachS', parentSeriesId: null,
  };
  const ref = db.collection('trainingSeries').doc('seriesS');
  await ref.set(rule);
  const expected = series.generateOccurrences({ ...rule, id: 'seriesS' }, new Date()).map((o) => o.id).sort();
  assert.ok(expected.length >= 20);
  const snap = await waitFor(async () => {
    const q = await db.collection('trainings').where('seriesId', '==', 'seriesS').get();
    return q.size === expected.length ? q : null;
  }, 'occurrences generated', 30000);
  assert.deepEqual(snap.docs.map((d) => d.id).sort(), expected);
  for (const d of snap.docs) assert.equal(d.id, `seriesS_${d.get('occurrenceDate').replace(/-/g, '')}`);
  await waitFor(async () => (await ref.get()).get('generatedUntil'), 'generatedUntil');
  const { runExtendTrainingSeries } = require('../lib/triggers/series.js');
  await runExtendTrainingSeries(new Date());
  assert.equal((await db.collection('trainings').where('seriesId', '==', 'seriesS').get()).size, expected.length, 'idempotent');
  await waitFor(async () => (await db.collection('notifications').where('userId', '==', 'parentS').where('type', '==', 'scheduleChanged').get()).size === 1, 'one summary');
  const newTraining = await db.collection('notifications').where('userId', '==', 'parentS').where('type', '==', 'newTraining').get();
  assert.equal(newTraining.size, 0, 'no per-occurrence notification');
  E2E.occurrences = expected;
});

await step('v1.2: parent RSVP + coach attendance; weekday removal cancels (not deletes) the RSVP occurrence', async () => {
  const fridays = E2E.occurrences.filter((id) => series.isoWeekday(`${id.slice(-8, -4)}-${id.slice(-4, -2)}-${id.slice(-2)}`) === 5);
  const t = fridays[0];
  await db.doc(`rsvps/${t}_childS`).set({ trainingId: t, groupId: E2E.groupId, childId: 'childS', parentId: 'parentS', response: 'yes', reason: null, updatedAt: ts(new Date()) });
  await db.doc(`attendance/${t}_childS`).set({ trainingId: t, groupId: E2E.groupId, childId: 'childS', status: 'present', markedBy: 'coachS', markedAt: ts(new Date()), note: null });
  await db.doc('trainingSeries/seriesS').update({ weekdays: [1, 3], updatedAt: ts(new Date()) });
  await waitFor(async () => (await db.doc(`trainings/${t}`).get()).get('status') === 'cancelled', 'RSVP occurrence cancelled');
  const tr = (await db.doc(`trainings/${t}`).get()).data();
  assert.equal(tr.cancelReasonCode, 'other');
  assert.equal(tr.cancelReason, series.SCHEDULE_CHANGED_REASON);
  await waitFor(async () => !(await db.doc(`trainings/${fridays[1]}`).get()).exists, 'other Fridays deleted');
  await waitFor(async () => (await db.collection('notifications').where('userId', '==', 'parentS').where('type', '==', 'scheduleChanged').get()).size === 2, 'second summary');
});

await step('v1.2: payment status change writes paymentAudit with the actor', async () => {
  await db.doc('payments/payS').set({ childId: 'childS', parentId: 'parentS', groupId: E2E.groupId, sportId: 'football', amount: 60, currency: 'GEL', dueDate: ts(new Date()), status: 'pending', reminders: {}, createdAt: ts(new Date()) });
  await db.doc('payments/payS').update({ status: 'paid', paidAt: ts(new Date()), updatedBy: 'coachS' });
  const audit = await waitFor(async () => {
    const q = await db.collection('paymentAudit').where('paymentId', '==', 'payS').get();
    return q.size ? q.docs[0].data() : null;
  }, 'paymentAudit');
  assert.deepEqual([audit.from, audit.to, audit.actorId, audit.clubId], ['pending', 'paid', 'coachS', 'clubS']);
  const log = await db.collection('auditLog').where('action', '==', 'payment.status').where('targetId', '==', 'payS').get();
  assert.equal(log.size, 1);
});

await step('v1.2: chat unread counters, then report + moderate hides the message', async () => {
  // v1.3.1 series system messages are unread too: start from a read chat.
  for (const u of ['coachS', 'parentS']) await db.doc(`chats/${E2E.groupId}/members/${u}`).set({ lastReadAt: ts(new Date()) });
  for (const u of ['coachS', 'parentS']) {
    await waitFor(async () => ((await db.doc(`userUnread/${u}`).get()).get(`byGroup.${E2E.groupId}`) ?? 0) === 0, `${u} read`);
  }
  await db.doc(`chats/${E2E.groupId}/messages/msgS`).set({ senderId: 'parentS', senderName: 'parent T', senderRole: 'parent', type: 'text', pinned: false, text: 'spam spam', createdAt: ts(new Date()) });
  await waitFor(async () => ((await db.doc('userUnread/coachS').get()).get(`byGroup.${E2E.groupId}`) ?? 0) >= 1, 'unread incremented');
  assert.equal((await db.doc('userUnread/parentS').get()).get(`byGroup.${E2E.groupId}`) ?? 0, 0, 'sender not counted');
  await db.doc(`chats/${E2E.groupId}/members/coachS`).set({ lastReadAt: ts(new Date()) });
  await waitFor(async () => (await db.doc('userUnread/coachS').get()).get(`byGroup.${E2E.groupId}`) === 0, 'unread reset');

  const outsider = await callable('createReport', { targetType: 'chatMessage', targetPath: `chats/${E2E.groupId}/messages/msgS`, reason: 'spam' }, await idToken('p1'));
  assert.equal(outsider.status, 403);
  const rep = await callable('createReport', { targetType: 'chatMessage', targetPath: `chats/${E2E.groupId}/messages/msgS`, groupId: E2E.groupId, reason: 'spam', note: 'რეკლამა' }, await idToken('coachS'));
  assert.equal(rep.status, 200, JSON.stringify(rep.body));
  const reportId = rep.body.result.reportId;
  assert.equal((await db.doc(`reports/${reportId}`).get()).get('clubId'), 'clubS');
  const notAdmin = await callable('moderate', { reportId, decision: 'hidden' }, await idToken('coachS'));
  assert.equal(notAdmin.status, 403);
  const otherClub = await callable('moderate', { reportId, decision: 'hidden' }, await idToken('clubAdminX', { clubAdmin: ['club1'] }));
  assert.equal(otherClub.status, 403);
  const ok = await callable('moderate', { reportId, decision: 'hidden' }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  const m = (await db.doc(`chats/${E2E.groupId}/messages/msgS`).get()).data();
  assert.equal(m.hidden, true);
  assert.equal(m.reportCount, 1);
  assert.equal((await db.doc(`reports/${reportId}`).get()).get('status'), 'resolved');
  const audit = await db.collection('auditLog').where('action', '==', 'moderation.decide').where('clubId', '==', 'clubS').get();
  assert.equal(audit.size, 1);
});

await step('v1.2: match create/cancel -> system chat messages + inbox', async () => {
  const start = new Date(Date.now() + 5 * 86400000);
  await db.doc('matches/matchS').set({ groupId: E2E.groupId, clubId: 'clubS', venueId: 'v1', startAt: ts(start), durationMin: 90, opponentName: 'Dinamo', matchType: 'friendly', homeAway: 'home', status: 'scheduled', createdBy: 'coachS', updatedAt: ts(new Date()) });
  await waitFor(async () => (await db.doc(`chats/${E2E.groupId}/messages/system_match_matchS_new`).get()).exists, 'system new-match message');
  await db.doc('matches/matchS').update({ status: 'cancelled', cancelReasonCode: 'weather', cancelReason: 'ძლიერი წვიმა', cancelledBy: 'coachS', cancelledAt: ts(new Date()) });
  const sys = await waitFor(async () => (await db.doc(`chats/${E2E.groupId}/messages/system_match_matchS_cancelled`).get()).data(), 'system cancel message');
  assert.equal(sys.type, 'system');
  assert.match(sys.text, /ძლიერი წვიმა/);
  assert.ok((await db.doc(`notifications/${sha1('parentS|match:matchS:cancelled')}`).get()).exists);
});

await step('v1.2: admin callables are scoped and audited', async () => {
  const stats = await callable('adminStats', {}, await idToken('admin1', { admin: true }));
  assert.equal(stats.status, 200, JSON.stringify(stats.body));
  assert.ok(stats.body.result.parents >= 1 && 'upcomingMatches' in stats.body.result);
  const clubStats = await callable('adminStats', {}, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(clubStats.status, 200, JSON.stringify(clubStats.body));
  assert.equal(clubStats.body.result.activeGroups, 1);
  assert.equal((await callable('adminStats', {}, await idToken('parentS'))).status, 403);
  await db.doc('users/coachS2').set(user('coach', { coachStatus: 'approved', clubIds: ['clubS'] }));
  const noReason = await callable('setCoachStatus', { uid: 'coachS2', status: 'suspended' }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(noReason.status, 400);
  const otherClub = await callable('setCoachStatus', { uid: 'coachS2', status: 'suspended', reason: 'Repeated no-shows' }, await idToken('clubAdminX', { clubAdmin: ['club1'] }));
  assert.equal(otherClub.status, 403);
  const ok = await callable('setCoachStatus', { uid: 'coachS2', status: 'suspended', reason: 'Repeated no-shows' }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.equal((await db.doc('users/coachS2').get()).get('coachStatus'), 'suspended');
  const role = await callable('setAdminRole', { uid: 'clubAdminS', role: 'club', clubIds: ['clubS'] }, await idToken('admin1', { admin: true }));
  assert.equal(role.status, 200, JSON.stringify(role.body));
  assert.deepEqual((await getAuth().getUser('clubAdminS')).customClaims.clubAdmin, ['clubS']);
  assert.deepEqual((await db.doc('clubs/clubS').get()).get('adminIds'), ['clubAdminS']);
  const notPlatform = await callable('setAdminRole', { uid: 'parentS', role: 'platform', clubIds: [] }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(notPlatform.status, 403);
});

await step('v1.2: data export writes exports/{uid}/{id}.json without medical files', async () => {
  const r = await callable('requestDataExport', {}, await idToken('parentS'));
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const id = r.body.result.requestId;
  await waitFor(async () => (await db.doc(`accountRequests/${id}`).get()).get('status') === 'done', 'export done', 30000);
  const [buf] = await getStorage().bucket().file(`exports/parentS/${id}.json`).download();
  const json = JSON.parse(buf.toString());
  assert.equal(json.uid, 'parentS');
  assert.ok(json.children.some((c) => c.id === 'childS'));
  assert.equal(json.user.fcmTokens, undefined);
  const url = await callable('getExportUrl', { requestId: id }, await idToken('parentS'));
  assert.equal(url.status, 200, JSON.stringify(url.body));
  assert.equal((await callable('getExportUrl', { requestId: id }, await idToken('p1'))).status, 404);
});


// ------------------------------------------------------------ v1.3 flow
const V13 = {};
const putReceipt = (parentId, proofId, file = 'r.jpg', contentType = 'image/jpeg', body = Buffer.from([1, 2, 3, 4])) =>
  getStorage().bucket().file(`receipts/${parentId}/${proofId}/${file}`).save(body, { contentType }).then(() => body.length);
const proofPayload = async (proofId, paymentId) => {
  const size = await putReceipt('parentS', proofId);
  return { proofId, paymentId, paidOn: series.tbilisiDateKey(new Date()), reference: 'TBC-42', note: 'ბანკით', receiptPath: `receipts/parentS/${proofId}/r.jpg`, receiptMime: 'image/jpeg', receiptSize: size };
};

await step('v1.3: club admin sets paymentManagerIds via updateGroup (audited); a coach cannot', async () => {
  await db.doc('users/parentS').update({ locale: 'en' });
  await db.doc('users/clubAdminS').set(user('parent', { locale: 'ru' }));
  const denied = await callable('updateGroup', { groupId: E2E.groupId, paymentManagerIds: ['coachS'] }, await idToken('coachS'));
  assert.equal(denied.status, 403, JSON.stringify(denied.body));
  const ok = await callable('updateGroup', { groupId: E2E.groupId, paymentManagerIds: ['coachS'] }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.deepEqual((await db.doc(`groups/${E2E.groupId}`).get()).get('paymentManagerIds'), ['coachS']);
  const audit = await db.collection('auditLog').where('action', '==', 'group.paymentManagers').where('targetId', '==', E2E.groupId).get();
  assert.equal(audit.size, 1);
  assert.deepEqual(audit.docs[0].get('details.to'), ['coachS']);
});

await step('v1.3: proof submit → second submit rejected → approve → payment paid → second approve fails', async () => {
  const pay = { childId: 'childS', parentId: 'parentS', groupId: E2E.groupId, sportId: 'football', amount: 60, currency: 'GEL', dueDate: ts(new Date(Date.now() + 5 * 86400000)), status: 'pending', reminders: {}, createdAt: ts(new Date()) };
  await db.doc('payments/payV13').set(pay);
  await db.doc('payments/payV13b').set({ ...pay, amount: 70 });
  const parentTok = await idToken('parentS');
  const other = await callable('submitPaymentProof', await proofPayload('proofX', 'payV13'), await idToken('p1'));
  assert.equal(other.status, 400, JSON.stringify(other.body)); // receiptPath is not under the caller's uid
  const r = await callable('submitPaymentProof', await proofPayload('proofA', 'payV13'), parentTok);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.equal(r.body.result.proofId, 'proofA');
  assert.equal(r.body.result.action, 'submitted');
  const p = (await db.doc('payments/payV13').get()).data();
  assert.equal(p.status, 'pending');
  assert.equal(p.verification.state, 'proof_submitted');
  assert.equal(p.verification.proofId, 'proofA');
  const proof = (await db.doc('paymentProofs/proofA').get()).data();
  assert.deepEqual([proof.status, proof.parentId, proof.groupId, proof.clubId, proof.childId], ['submitted', 'parentS', E2E.groupId, 'clubS', 'childS']);
  assert.ok((await db.doc(`notifications/${sha1('coachS|proof:proofA:submitted')}`).get()).exists, 'payment manager notified');
  const adminN = (await db.doc(`notifications/${sha1('clubAdminS|proof:proofA:submitted')}`).get()).data();
  assert.ok(adminN, 'club admin notified');
  assert.equal(adminN.title, 'Подтверждение оплаты на проверку', 'rendered in the club admin locale (ru)');

  const second = await callable('submitPaymentProof', await proofPayload('proofB', 'payV13'), parentTok);
  assert.equal(second.status, 409, JSON.stringify(second.body)); // already-exists
  assert.equal((await db.doc('paymentProofs/proofB').get()).exists, false);

  const notReviewer = await callable('reviewPaymentProof', { proofId: 'proofA', decision: 'approve' }, parentTok);
  assert.equal(notReviewer.status, 403);
  const otherClub = await callable('reviewPaymentProof', { proofId: 'proofA', decision: 'approve' }, await idToken('clubAdminX', { clubAdmin: ['club1'] }));
  assert.equal(otherClub.status, 403);
  const start = await callable('startPaymentReview', { proofId: 'proofA' }, await idToken('coachS'));
  assert.equal(start.status, 200, JSON.stringify(start.body));
  assert.equal((await db.doc('payments/payV13').get()).get('verification.state'), 'under_review');

  const ok = await callable('reviewPaymentProof', { proofId: 'proofA', decision: 'approve' }, await idToken('coachS'));
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  const paid = (await db.doc('payments/payV13').get()).data();
  assert.equal(paid.status, 'paid');
  assert.equal(paid.verifiedBy, 'coachS');
  assert.ok(paid.paidAt && paid.verifiedAt);
  assert.equal(paid.verification.state, 'none');
  assert.equal(paid.verification.proofId, 'proofA');
  assert.equal((await db.doc('paymentProofs/proofA').get()).get('status'), 'approved');

  const again = await callable('reviewPaymentProof', { proofId: 'proofA', decision: 'approve' }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(again.status, 400, JSON.stringify(again.body)); // failed-precondition
  assert.equal(again.body.error.status, 'FAILED_PRECONDITION');

  const n = (await db.doc(`notifications/${sha1('parentS|proof:proofA:approved')}`).get()).data();
  assert.equal(n.type, 'paymentProofApproved');
  assert.equal(n.category, 'payments');
  assert.equal(n.title, 'Payment confirmed', 'rendered in the parent locale (en)');
  const events = await db.collection('paymentVerificationEvents').where('paymentId', '==', 'payV13').get();
  assert.deepEqual(events.docs.map((d) => d.get('action')).sort(), ['approved', 'review_started', 'submitted']);
  for (const a of ['payment.proofSubmitted', 'payment.proofApproved']) {
    assert.equal((await db.collection('auditLog').where('action', '==', a).where('targetId', '==', 'proofA').get()).size, 1, a);
  }
  await waitFor(async () => (await db.collection('paymentAudit').where('paymentId', '==', 'payV13').get()).docs.some((d) => d.get('to') === 'paid' && d.get('actorId') === 'coachS'), 'paymentAudit actor');

  const url = await callable('getReceiptUrl', { proofId: 'proofA' }, await idToken('coachS'));
  assert.equal(url.status, 200, JSON.stringify(url.body));
  assert.equal(url.body.result.mimeType, 'image/jpeg');
  assert.match(url.body.result.url, /receipts%2FparentS%2FproofA/);
  assert.equal((await callable('getReceiptUrl', { proofId: 'proofA' }, await idToken('p1'))).status, 403);
  assert.equal((await db.collection('auditLog').where('action', '==', 'receipt.view').where('targetId', '==', 'proofA').get()).size, 1);
});

await step('v1.3: reject (reason required) → parent notified → resubmit supersedes the rejected proof', async () => {
  const parentTok = await idToken('parentS');
  const r = await callable('submitPaymentProof', await proofPayload('proofC', 'payV13b'), parentTok);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const short = await callable('reviewPaymentProof', { proofId: 'proofC', decision: 'reject', reason: 'no' }, await idToken('coachS'));
  assert.equal(short.status, 400);
  const rej = await callable('reviewPaymentProof', { proofId: 'proofC', decision: 'reject', reason: 'Amount does not match' }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(rej.status, 200, JSON.stringify(rej.body));
  const p = (await db.doc('payments/payV13b').get()).data();
  assert.equal(p.status, 'pending');
  assert.equal(p.verification.state, 'rejected');
  assert.equal(p.verification.rejectionReason, 'Amount does not match');
  const n = (await db.doc(`notifications/${sha1('parentS|proof:proofC:rejected')}`).get()).data();
  assert.equal(n.type, 'paymentProofRejected');
  assert.match(n.body, /Amount does not match/);
  const re = await callable('submitPaymentProof', await proofPayload('proofD', 'payV13b'), parentTok);
  assert.equal(re.status, 200, JSON.stringify(re.body));
  assert.equal(re.body.result.action, 'resubmitted');
  assert.equal((await db.doc('paymentProofs/proofC').get()).get('status'), 'superseded');
  assert.equal((await db.doc('payments/payV13b').get()).get('verification.state'), 'proof_submitted');
  assert.equal((await db.collection('auditLog').where('action', '==', 'payment.proofResubmitted').where('targetId', '==', 'proofD').get()).size, 1);
});

const planDoc = (o = {}, planId = 'planS') => ({
  title: 'Winter technique', description: 'Ball control', type: 'weekly', groupIds: [E2E.groupId], clubId: 'clubS',
  startDate: series.tbilisiDateKey(new Date()), endDate: null, status: 'draft', createdBy: 'coachS', coachName: 'coach',
  createdAt: ts(new Date()), updatedAt: ts(new Date()), publishedAt: null,
  exercises: [{ id: 'e1', order: 0, name: 'Juggling', description: null, instructions: 'Both feet', durationMin: 10, reps: null, sets: 3, restSec: null,
    media: [{ id: 'm1', kind: 'photo', path: `plans/${planId}/m1_a.jpg`, url: null, name: 'a.jpg' }, { id: 'm2', kind: 'link', path: null, url: 'https://example.com/drill', name: null }] }],
  ...o,
});

await step('v1.3: plan publish → readerIds set → parent notification (en) → audit; media URL access', async () => {
  await db.doc('trainingPlans/planS').set(planDoc());
  const draft = await waitFor(async () => {
    const d = (await db.doc('trainingPlans/planS').get()).data();
    return Array.isArray(d.coachIds) && d.coachIds.includes('coachS') ? d : null;
  }, 'coachIds');
  assert.deepEqual(draft.readerIds, []);
  await getStorage().bucket().file('plans/planS/m1_a.jpg').save(Buffer.from([1, 2, 3]), { contentType: 'image/jpeg' });
  const parentTok = await idToken('parentS');
  assert.equal((await callable('getPlanMediaUrl', { planId: 'planS', path: 'plans/planS/m1_a.jpg' }, parentTok)).status, 403, 'draft is not visible to parents');

  await db.doc('trainingPlans/planS').update({ status: 'published', updatedAt: ts(new Date()) });
  const pub = await waitFor(async () => {
    const d = (await db.doc('trainingPlans/planS').get()).data();
    return d.readerIds?.includes('parentS') && d.publishedAt ? d : null;
  }, 'readerIds');
  assert.ok(pub.readerIds.includes('coachS'));
  const n = await waitFor(async () => (await db.doc(`notifications/${sha1('parentS|plan:planS:published')}`).get()).data(), 'plan notification');
  assert.equal(n.type, 'trainingPlanPublished');
  assert.equal(n.category, 'trainings');
  assert.equal(n.title, 'New training plan');
  assert.equal((await db.collection('auditLog').where('action', '==', 'plan.publish').where('targetId', '==', 'planS').get()).size, 1);
  const url = await callable('getPlanMediaUrl', { planId: 'planS', path: 'plans/planS/m1_a.jpg' }, parentTok);
  assert.equal(url.status, 200, JSON.stringify(url.body));
  assert.equal((await callable('getPlanMediaUrl', { planId: 'planS', path: 'plans/planS/m1_a.jpg' }, await idToken('p1'))).status, 403);
  assert.equal((await callable('getPlanMediaUrl', { planId: 'planS', path: 'plans/planS/other.jpg' }, parentTok)).status, 404);

  // re-publish never notifies twice
  await db.doc('trainingPlans/planS').update({ status: 'draft' });
  await waitFor(async () => ((await db.doc('trainingPlans/planS').get()).get('readerIds') ?? []).length === 0, 'readers cleared on draft');
  await db.doc('trainingPlans/planS').update({ status: 'published' });
  await waitFor(async () => ((await db.doc('trainingPlans/planS').get()).get('readerIds') ?? []).includes('parentS'), 'readers back');
  const all = await db.collection('notifications').where('userId', '==', 'parentS').where('type', '==', 'trainingPlanPublished').get();
  assert.equal(all.size, 1);
  await db.doc('trainingPlans/planS').update({ status: 'archived' });
  await waitFor(async () => (await db.collection('auditLog').where('action', '==', 'plan.archive').where('targetId', '==', 'planS').get()).size === 1, 'plan.archive audit');
  assert.deepEqual((await db.doc('trainingPlans/planS').get()).get('readerIds'), []);
});

await step('v1.3: plan with a javascript:/http: link is quarantined (draft, no readers, no notification)', async () => {
  const bad = planDoc({ status: 'published', exercises: [{ id: 'e1', order: 0, name: 'x', media: [
    { id: 'm1', kind: 'link', path: null, url: 'javascript:alert(1)', name: null },
    { id: 'm2', kind: 'link', path: null, url: 'http://example.com', name: null }] }] });
  await db.doc('trainingPlans/planBad').set(bad);
  const d = await waitFor(async () => {
    const x = (await db.doc('trainingPlans/planBad').get()).data();
    return x.status === 'draft' && x.validationErrors ? x : null;
  }, 'quarantine');
  assert.deepEqual(d.readerIds ?? [], []);
  assert.ok(d.validationErrors.includes('exercises[0].media[0].url'));
  assert.ok(d.validationErrors.includes('exercises[0].media[1].url'));
  await new Promise((r) => setTimeout(r, 1500));
  assert.equal((await db.doc(`notifications/${sha1('parentS|plan:planBad:published')}`).get()).exists, false);
});

await step('v1.3: removing the child from the group revokes plan read (readerIds recomputed)', async () => {
  await db.doc('trainingPlans/planR').set(planDoc({ status: 'published' }, 'planR'));
  await waitFor(async () => ((await db.doc('trainingPlans/planR').get()).get('readerIds') ?? []).includes('parentS'), 'reader');
  await db.doc(`groups/${E2E.groupId}`).update({ memberChildIds: FieldValue.arrayRemove('childS') });
  await waitFor(async () => !((await db.doc('trainingPlans/planR').get()).get('readerIds') ?? []).includes('parentS'), 'reader removed', 30000);
  await db.doc(`groups/${E2E.groupId}`).update({ memberChildIds: FieldValue.arrayUnion('childS') });
  await waitFor(async () => ((await db.doc('trainingPlans/planR').get()).get('readerIds') ?? []).includes('parentS'), 'reader back', 30000);
  await waitFor(async () => ((await db.doc('children/childS').get()).get('coachIds') ?? []).includes('coachS'), 'coach access back');
});

await step('v1.3: certificate download is logged with purpose; admins are denied', async () => {
  await db.doc('medicalCertificates/certS').set({
    childId: 'childS', uploadedBy: 'parentS', storagePath: 'medical/childS/certS', issuedAt: ts(new Date('2026-01-01')),
    validUntil: ts(new Date(Date.now() + 200 * 86400000)), consentAt: ts(new Date()), status: 'valid', sportId: 'football',
  });
  await getStorage().bucket().file('medical/childS/certS').save(Buffer.from('%PDF-1.4'), { contentType: 'application/pdf' });
  const r = await callable('getCertificateUrl', { certId: 'certS', purpose: 'download' }, await idToken('parentS'));
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.ok(r.body.result.url && r.body.result.expiresAt);
  const v = await callable('getCertificateUrl', { certId: 'certS', purpose: 'view' }, await idToken('coachS'));
  assert.equal(v.status, 200, JSON.stringify(v.body));
  assert.equal((await callable('getCertificateUrl', { certId: 'certS', purpose: 'print' }, await idToken('parentS'))).status, 400);
  assert.equal((await callable('getCertificateUrl', { certId: 'certS' }, await idToken('admin1', { admin: true }))).status, 403);
  assert.equal((await callable('getCertificateUrl', { certId: 'certS' }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }))).status, 403);
  const log = (await db.collection('certificateAccessLog').where('certId', '==', 'certS').get()).docs.map((d) => d.data());
  assert.equal(log.length, 2);
  const dl = log.find((e) => e.purpose === 'download');
  assert.deepEqual([dl.viewerId, dl.viewerRole, dl.childId], ['parentS', 'parent', 'childS']);
  assert.ok(log.some((e) => e.purpose === 'view' && e.viewerRole === 'coach'));
  assert.equal((await db.collection('auditLog').where('action', '==', 'certificate.download').where('targetId', '==', 'certS').get()).size, 1);
  assert.equal((await db.collection('auditLog').where('action', '==', 'certificate.view').where('targetId', '==', 'certS').get()).size, 1);
});

await step('v1.3: adminCompliance returns per-group counts only, scoped to the admin', async () => {
  const r = await callable('adminCompliance', {}, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const g = r.body.result.groups.find((x) => x.groupId === E2E.groupId);
  assert.deepEqual(g, { groupId: E2E.groupId, groupName: 'U11', clubId: 'clubS', valid: 1, expiring: 0, expired: 0, missing: 0 });
  assert.ok(r.body.result.groups.every((x) => x.clubId === 'clubS'));
  assert.ok(!JSON.stringify(r.body).includes('childS'), 'no child ids');
  await db.doc('medicalCertificates/certS').update({ validUntil: ts(new Date(Date.now() - 86400000)) });
  const r2 = await callable('adminCompliance', { clubId: 'clubS' }, await idToken('admin1', { admin: true }));
  assert.equal(r2.status, 200, JSON.stringify(r2.body));
  assert.equal(r2.body.result.groups.find((x) => x.groupId === E2E.groupId).expired, 1);
  assert.equal((await callable('adminCompliance', { clubId: 'clubS' }, await idToken('clubAdminX', { clubAdmin: ['club1'] }))).status, 403);
  assert.equal((await callable('adminCompliance', {}, await idToken('parentS'))).status, 403);
});

await step('v1.3: certificate reminder at 3 days, localized, sent once (reminders.d3SentAt)', async () => {
  const { runCertificateReminders } = require('../lib/triggers/certificates.js');
  await db.doc('medicalCertificates/certS').update({ validUntil: ts(new Date(Date.now() + 2.5 * 86400000)) });
  await db.doc('medicalCertificates/certOld').set({
    childId: 'childS', uploadedBy: 'parentS', storagePath: 'medical/childS/certOld', issuedAt: ts(new Date('2025-01-01')),
    validUntil: ts(new Date(Date.now() + 2 * 86400000)), consentAt: ts(new Date()), status: 'valid', replacedBy: 'certS', replacedAt: ts(new Date()),
  });
  await runCertificateReminders(new Date());
  await runCertificateReminders(new Date());
  const c = (await db.doc('medicalCertificates/certS').get()).data();
  assert.ok(c.reminders?.d3SentAt && c.reminders?.d14SentAt);
  assert.ok(!c.reminders?.d0SentAt);
  const ns = await db.collection('notifications').where('userId', '==', 'parentS').where('type', '==', 'certificateExpiry').get();
  assert.equal(ns.size, 1, 'one reminder; the replaced certificate is not reminded');
  assert.match(ns.docs[0].get('title'), /Certificate expiring soon/);
  assert.equal(ns.docs[0].get('args.stage'), '3');
  assert.equal(((await db.doc('medicalCertificates/certOld').get()).get('reminders') ?? {}).d3SentAt, undefined);
});

await step('v1.3: system chat messages carry systemKey + systemArgs (text stays Georgian)', async () => {
  const m = (await db.doc(`chats/${E2E.groupId}/messages/system_match_matchS_cancelled`).get()).data();
  assert.equal(m.systemKey, 'matchCancelled');
  assert.deepEqual(Object.keys(m.systemArgs).sort(), ['date', 'opponent', 'reason', 'reasonCode', 'time']);
  assert.equal(m.systemArgs.reasonCode, 'weather');
  assert.match(m.text, /მატჩი/);
});

await step('v1.3.1: attendance mark notifies the parent once per status (localized, attendance category)', async () => {
  const att = (await db.collection('attendance').where('childId', '==', 'childS').limit(1).get()).docs[0];
  assert.ok(att, 'attendance doc from the RSVP step');
  const n = await waitFor(async () => (await db.doc(`notifications/${sha1(`parentS|att:${att.id}:present`)}`).get()).data(), 'attendance notification');
  assert.equal(n.type, 'attendanceRecorded');
  assert.equal(n.category, 'attendance');
  assert.equal(n.title, 'დასწრება აღირიცხა', 'rendered in the locale at the time (ka, before the en switch)');
  await att.ref.update({ note: 'late', markedAt: ts(new Date()) });
  await att.ref.update({ status: 'excused', markedAt: ts(new Date()) });
  const n2 = await waitFor(async () => (await db.doc(`notifications/${sha1(`parentS|att:${att.id}:excused`)}`).get()).data(), 'status change notification');
  assert.match(n2.body, /excused/, 'en status word');
  const all = await db.collection('notifications').where('userId', '==', 'parentS').where('type', '==', 'attendanceRecorded').get();
  assert.equal(all.size, 2, 'note-only edit is silent');
});

await step('v1.3.1: coach feedback notifies the parent', async () => {
  await db.doc('feedback/fbS').set({
    childId: 'childS', groupId: E2E.groupId, coachId: 'coachS', coachName: 'Coach S', createdAt: ts(new Date()),
    ratings: { technique: 4 }, comment: 'Good', visibleToParent: true,
  });
  const n = await waitFor(async () => (await db.doc(`notifications/${sha1('parentS|fb:fbS')}`).get()).data(), 'feedback notification');
  assert.equal(n.type, 'feedbackAdded');
  assert.match(n.body, /Coach S/);
});

await step('v1.3.1: moving a one-off training posts a trainingMoved system message', async () => {
  const start = new Date(Date.now() + 4 * 86400000);
  await db.doc('trainings/tmS').set({ groupId: E2E.groupId, venueId: 'v1', startAt: ts(start), durationMin: 60, focus: [], description: '', photoUrls: [], status: 'scheduled', createdBy: 'coachS', updatedAt: ts(new Date()) });
  await new Promise((r) => setTimeout(r, 1000));
  const next = new Date(start.getTime() + 86400000);
  await db.doc('trainings/tmS').update({ startAt: ts(next) });
  const m = await waitFor(async () => (await db.doc(`chats/${E2E.groupId}/messages/system_training_tmS_moved_${next.getTime()}`).get()).data(), 'moved message');
  assert.equal(m.systemKey, 'trainingMoved');
  assert.deepEqual(Object.keys(m.systemArgs).sort(), ['from', 'to']);
  assert.notEqual(m.systemArgs.from, m.systemArgs.to);
});

await step('v1.3.1: series create/change post scheduleCreated / scheduleChanged chat messages', async () => {
  const q = await db.collection(`chats/${E2E.groupId}/messages`).where('type', '==', 'system').get();
  const keys = q.docs.map((d) => d.get('systemKey'));
  assert.ok(keys.includes('scheduleCreated'), keys.join());
  assert.ok(keys.includes('scheduleChanged'), keys.join());
});

await step('v1.3.1: plan archive is audited with the actual actor (updatedBy)', async () => {
  await db.doc('trainingPlans/planAud').set(planDoc({ status: 'published', updatedBy: 'coachS' }, 'planAud'));
  await waitFor(async () => (await db.collection('auditLog').where('action', '==', 'plan.publish').where('targetId', '==', 'planAud').get()).size === 1, 'publish audit');
  await db.doc('trainingPlans/planAud').update({ status: 'archived', updatedBy: 'coachOtherS', updatedAt: ts(new Date()) });
  const a = await waitFor(async () => (await db.collection('auditLog').where('action', '==', 'plan.archive').where('targetId', '==', 'planAud').get()).docs[0], 'archive audit');
  assert.equal(a.get('actorId'), 'coachOtherS');
});

// ─── v1.4 ─────────────────────────────────────────────────────────────────
await step('v1.4: second guardian joins via the child; contacts are scoped both ways', async () => {
  await db.doc('users/parentS2').set(user('parent', { phone: '+995599777002', firstName: 'Guardian', lastName: 'Two' }));
  await db.doc('children/childS').update({ parentIds: ['parentS', 'parentS2'], guardianRelations: { parentS: 'mother', parentS2: 'father' } });
  await db.doc(`groups/${E2E.groupId}`).update({ memberChildIds: FieldValue.arrayRemove('childS') });
  await waitFor(async () => !((await db.doc(`groups/${E2E.groupId}`).get()).get('parentIds') ?? []).includes('parentS'), 'parents removed', 30000);
  await db.doc(`groups/${E2E.groupId}`).update({ memberChildIds: FieldValue.arrayUnion('childS') });
  await waitFor(async () => {
    const ids = (await db.doc(`groups/${E2E.groupId}`).get()).get('parentIds') ?? [];
    return ids.includes('parentS') && ids.includes('parentS2');
  }, 'both guardians in parentIds', 30000);

  const coachTok = await idToken('coachS');
  const r = await callable('getGroupContacts', { groupId: E2E.groupId }, coachTok);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const byId = Object.fromEntries(r.body.result.contacts.map((c) => [c.uid, c]));
  assert.equal(byId.parentS2.phone, '+995599777002');
  assert.equal(byId.parentS2.children[0].relation, 'father');
  const p = await callable('getGroupContacts', { groupId: E2E.groupId }, await idToken('parentS'));
  assert.equal(p.status, 200, JSON.stringify(p.body));
  assert.deepEqual(p.body.result.contacts.map((c) => c.role), ['coach'], 'parents only see coaches');
  assert.equal((await callable('getContactPhone', { uid: 'coachS' }, await idToken('parentS'))).status, 200);
  assert.equal((await callable('getContactPhone', { uid: 'parentS2' }, await idToken('parentS'))).status, 403, 'parent → parent denied');
  assert.equal((await callable('getContactPhone', { uid: 'parentS' }, await idToken('p1'))).status, 403);
  assert.equal((await callable('getGroupContacts', { groupId: E2E.groupId }, await idToken('p1'))).status, 403);
});

await step('v1.4: coach message requiring acknowledgment → recipient snapshot, inbox entry, read/ack counters, audit', async () => {
  await db.doc(`chats/${E2E.groupId}/messages/ackS`).set({
    senderId: 'coachS', senderName: 'Coach S', senderRole: 'coach', type: 'announcement', pinned: true,
    text: 'Training moved to the indoor hall', createdAt: ts(new Date()), requiresAck: true,
  });
  const r = await waitFor(async () => (await db.doc(`chats/${E2E.groupId}/receipts/ackS`).get()).data(), 'receipt');
  assert.deepEqual(r.recipientIds, ['parentS', 'parentS2']);
  assert.equal(r.requiresAck, true);
  const n = await waitFor(async () => (await db.doc(`notifications/${sha1(`parentS2|ack:${E2E.groupId}:ackS`)}`).get()).data(), 'ack inbox');
  assert.equal(n.type, 'ackRequested');
  const msg = db.doc(`chats/${E2E.groupId}/messages/ackS`);
  await msg.collection('msgReads').doc('parentS').set({ uid: 'parentS', groupId: E2E.groupId, messageId: 'ackS', readAt: ts(new Date()) });
  await waitFor(async () => (await db.doc(`chats/${E2E.groupId}/receipts/ackS`).get()).get('readCount') === 1, 'read 1/2');
  assert.equal((await db.doc(`chats/${E2E.groupId}/receipts/ackS`).get()).get('ackCount'), 0, 'reading is not acknowledging');
  await msg.collection('msgAcks').doc('parentS2').set({ uid: 'parentS2', groupId: E2E.groupId, messageId: 'ackS', ackAt: ts(new Date()) });
  await waitFor(async () => {
    const d = (await db.doc(`chats/${E2E.groupId}/receipts/ackS`).get()).data();
    return d.readCount === 2 && d.ackCount === 1;
  }, 'ack implies seen: 2/2 seen, 1/2 acknowledged');
  const audit = await waitFor(async () => (await db.collection('auditLog').where('action', '==', 'chat.acknowledge').where('actorId', '==', 'parentS2').get()).docs[0], 'ack audit');
  assert.equal(audit.get('targetId'), `${E2E.groupId}/ackS`);
  // A parent message gets no receipt.
  await db.doc(`chats/${E2E.groupId}/messages/parMsg`).set({ senderId: 'parentS', senderName: 'P', senderRole: 'parent', type: 'text', text: 'ok', createdAt: ts(new Date()) });
  await new Promise((res) => setTimeout(res, 1500));
  assert.equal((await db.doc(`chats/${E2E.groupId}/receipts/parMsg`).get()).exists, false);
  // Deleting the message drops receipts and reads, keeps acknowledgments.
  await msg.delete();
  await waitFor(async () => !(await db.doc(`chats/${E2E.groupId}/receipts/ackS`).get()).exists, 'receipt deleted');
  assert.equal((await msg.collection('msgReads').get()).size, 0);
  assert.equal((await msg.collection('msgAcks').get()).size, 1, 'acknowledgment kept as audit');
});

await step('v1.4: media download is authorized live, logged, and refused to outsiders / hidden posts / disabled policy', async () => {
  const path = 'media/coachS/postDl/clip.mp4';
  await getStorage().bucket().file(path).save(Buffer.from([0, 0, 0, 24, 102, 116, 121, 112]), { contentType: 'video/mp4' });
  await db.doc('mediaPosts/postDl').set({
    coachId: 'coachS', coachName: 'Coach S', groupIds: [E2E.groupId], clubId: 'clubS', type: 'video', storagePath: path,
    thumbPath: null, caption: 'Drill', durationSec: 5, createdAt: ts(new Date()), consentConfirmed: true,
  });
  const parentTok = await idToken('parentS2');
  const ok = await callable('getMediaDownload', { postId: 'postDl' }, parentTok);
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.equal(ok.body.result.fileName, 'sportparent_video_postDl.mp4');
  assert.equal(ok.body.result.mimeType, 'video/mp4');
  assert.equal(ok.body.result.sizeBytes, 8);
  // Production returns a V4 signed URL; the emulator returns a direct link that
  // the Storage emulator still guards with rules, so only its target is checked here.
  assert.ok(ok.body.result.url.includes(encodeURIComponent(path)));
  const log = await db.collection('mediaDownloads').where('postId', '==', 'postDl').get();
  assert.equal(log.size, 1);
  assert.equal(log.docs[0].get('userId'), 'parentS2');
  assert.equal((await db.collection('auditLog').where('action', '==', 'media.download').where('targetId', '==', 'postDl').get()).size, 1);

  assert.equal((await callable('getMediaDownload', { postId: 'postDl' }, await idToken('p1'))).status, 403, 'outsider');
  assert.equal((await callable('getMediaDownload', { postId: 'nope' }, parentTok)).status, 404);
  assert.equal((await callable('getMediaDownload', { postId: 'medical' }, parentTok)).status, 404, 'no generic access to other collections');
  const admin = await callable('updateGroup', { groupId: E2E.groupId, mediaDownloadsEnabled: false }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  assert.equal(admin.status, 200, JSON.stringify(admin.body));
  assert.equal((await callable('getMediaDownload', { postId: 'postDl' }, parentTok)).status, 403, 'policy off');
  assert.equal((await callable('updateGroup', { groupId: E2E.groupId, mediaDownloadsEnabled: true }, await idToken('coachS'))).status, 403, 'coach cannot change policy');
  await callable('updateGroup', { groupId: E2E.groupId, mediaDownloadsEnabled: true }, await idToken('clubAdminS', { clubAdmin: ['clubS'] }));
  await db.doc('mediaPosts/postDl').update({ hidden: true });
  assert.equal((await callable('getMediaDownload', { postId: 'postDl' }, parentTok)).status, 403, 'hidden by moderation');
});

// ─── v1.5 ─────────────────────────────────────────────────────────────────
await step('v1.5: coach records a match result → parents notified once; correction audited; others refused', async () => {
  await db.doc('matches/mResS').set({
    groupId: E2E.groupId, clubId: 'clubS', venueId: 'v1', startAt: ts(new Date(Date.now() - 3 * 3600000)), durationMin: 90,
    opponentName: 'Dinamo Smoke', matchType: 'friendly', homeAway: 'home', status: 'scheduled', createdBy: 'coachS', updatedAt: ts(new Date()),
  });
  const coachTok = await idToken('coachS');
  assert.equal((await callable('recordMatchResult', { matchId: 'mResS', ourScore: 3, opponentScore: 1 }, await idToken('parentS'))).status, 403);
  assert.equal((await callable('recordMatchResult', { matchId: 'mResS', ourScore: -1, opponentScore: 1 }, coachTok)).status, 400);
  const r = await callable('recordMatchResult', { matchId: 'mResS', ourScore: 3, opponentScore: 1, summary: 'Great teamwork' }, coachTok);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const m = (await db.doc('matches/mResS').get()).data();
  assert.equal(m.status, 'played');
  assert.equal(m.result.outcome, 'win');
  assert.equal(m.result.version, 1);
  const n = await waitFor(async () => (await db.doc(`notifications/${sha1('parentS2|match:mResS:result')}`).get()).data(), 'result notification');
  assert.equal(n.type, 'matchResult');
  assert.equal(n.category, 'matches');
  // Correction: new version + history + audit, no second notification.
  const c = await callable('recordMatchResult', { matchId: 'mResS', ourScore: 2, opponentScore: 2 }, coachTok);
  assert.equal(c.status, 200, JSON.stringify(c.body));
  const m2 = (await db.doc('matches/mResS').get()).data();
  assert.equal(m2.result.outcome, 'draw');
  assert.equal(m2.result.version, 2);
  assert.equal((await db.collection('matches/mResS/resultHistory').get()).size, 2);
  const audit = await db.collection('auditLog').where('action', '==', 'match.resultCorrected').where('targetId', '==', 'mResS').get();
  assert.equal(audit.size, 1);
  assert.equal(audit.docs[0].get('details.from'), '3-1');
  const same = await callable('recordMatchResult', { matchId: 'mResS', ourScore: 2, opponentScore: 2 }, coachTok);
  assert.equal(same.body.result.changed, false, 'no-op when nothing changed');
  const all = await db.collection('notifications').where('type', '==', 'matchResult').where('userId', '==', 'parentS').get();
  assert.equal(all.size, 1, 'parents are notified once per match');
  await db.doc('matches/mFut').set({
    groupId: E2E.groupId, clubId: 'clubS', venueId: 'v1', startAt: ts(new Date(Date.now() + 86400000)), durationMin: 90,
    opponentName: 'Future', matchType: 'friendly', homeAway: 'home', status: 'scheduled', createdBy: 'coachS', updatedAt: ts(new Date()),
  });
  assert.equal((await callable('recordMatchResult', { matchId: 'mFut', ourScore: 1, opponentScore: 0 }, coachTok)).status, 400, 'not started');
});

await step('v1.5: child-context message notifies the coach / the child guardians only', async () => {
  await db.doc('users/parentOther').set(user('parent', { firstName: 'Other' }));
  const tid = 'childS_coachS';
  await db.doc(`childThreads/${tid}`).set({ childId: 'childS', coachId: 'coachS', createdBy: 'parentS', createdAt: ts(new Date()) });
  await db.doc(`childThreads/${tid}/messages/q1`).set({ senderId: 'parentS', senderName: 'Parent S', senderRole: 'parent', text: 'Is Giorgi ok after the game?', createdAt: ts(new Date()) });
  const coachN = await waitFor(async () => (await db.doc(`notifications/${sha1(`coachS|thread:${tid}:q1`)}`).get()).data(), 'coach notified');
  assert.equal(coachN.type, 'childMessage');
  assert.equal(coachN.route, '/student/childS/coach/coachS');
  assert.ok((await db.doc(`notifications/${sha1(`parentS2|thread:${tid}:q1`)}`).get()).exists, 'other guardian of the SAME child');
  assert.ok(!(await db.doc(`notifications/${sha1(`parentS|thread:${tid}:q1`)}`).get()).exists, 'sender not notified');
  assert.ok(!(await db.doc(`notifications/${sha1(`parentOther|thread:${tid}:q1`)}`).get()).exists);
  await waitFor(async () => (await db.doc(`childThreads/${tid}`).get()).get('lastMessageAt'), 'lastMessageAt');
});

await step('v1.5: receipt download is a separate, audited purpose; parent decision link opens the proof screen', async () => {
  const proof = (await db.collection('paymentProofs').limit(1).get()).docs[0];
  assert.ok(proof, 'a proof exists from the v1.3 steps');
  const reviewer = await idToken('clubAdminS', { clubAdmin: ['clubS'] });
  const d = await callable('getReceiptUrl', { proofId: proof.id, purpose: 'download' }, reviewer);
  assert.equal(d.status, 200, JSON.stringify(d.body));
  assert.match(d.body.result.fileName, /^receipt_/);
  assert.equal(d.body.result.purpose, 'download');
  assert.equal((await db.collection('auditLog').where('action', '==', 'receipt.download').where('targetId', '==', proof.id).get()).size, 1);
  assert.equal((await callable('getReceiptUrl', { proofId: proof.id, purpose: 'print' }, reviewer)).status, 400);
  const decided = await db.collection('notifications').where('type', 'in', ['paymentProofApproved', 'paymentProofRejected']).get();
  assert.ok(decided.size > 0);
  for (const doc of decided.docs) assert.match(doc.get('route'), /^\/payments\/[^/]+\/proof$/);
  const submitted = await db.collection('notifications').where('type', '==', 'paymentProofSubmitted').get();
  for (const doc of submitted.docs) assert.match(doc.get('route'), /^\/payments\/proofs\/[^/]+$/);
});

console.log(`${passed} smoke steps passed${process.exitCode ? ' (with failures)' : ''}`);
