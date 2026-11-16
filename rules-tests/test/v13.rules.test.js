// v1.3 security-rules tests: locale, payment proofs / receipts, payment
// managers, medical certificates, training plans, exercise progress, plan views.
// One attack scenario per test.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, query, setDoc, updateDoc, where,
} from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';
import { CLAIMS, UID, createEnv, now, seed, seedV12, ts } from './setup.js';

let env;

beforeAll(async () => {
  env = await createEnv();
});

const plan = (o = {}) => ({
  title: 'Winter plan', description: 'Ball control', type: 'weekly', groupIds: ['g1'], clubId: 'club1',
  startDate: '2026-12-01', endDate: null, status: 'draft', createdBy: UID.coach, coachName: 'coach',
  createdAt: now, updatedAt: now, publishedAt: null,
  exercises: [{
    id: 'e1', order: 0, name: 'Juggling', description: null, instructions: 'Both feet', durationMin: 10, reps: null, sets: 3, restSec: 60,
    media: [{ id: 'm1', kind: 'link', path: null, url: 'https://example.com/demo', name: 'Demo' }],
  }],
  ...o,
});

async function seedV13() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (path, data) => setDoc(doc(db, path), data);
    await put(`users/${UID.coachNoPay}`, {
      role: 'coach', firstName: 'coach', lastName: 'NoPay', phone: '+995599000001', createdAt: now, dataConsentAt: now,
      fcmTokens: [], notificationPrefs: {}, coachStatus: 'approved', clubIds: ['club1'], sportIds: ['football'],
    });
    await updateDoc(doc(db, 'groups/g1'), { coachIds: [UID.coach, UID.coachSuspended, UID.coachNoPay] });
    for (let i = 3; i <= 11; i++) {
      await put(`groups/g${i}`, { clubId: 'club1', sportId: 'football', coachIds: [UID.coach], name: `G${i}`, memberChildIds: [], parentIds: [] });
    }
    await put('paymentProofs/pf1', {
      paymentId: 'p1', groupId: 'g1', clubId: 'club1', childId: 'childA1', parentId: UID.parentA,
      paidOn: '2026-11-09', reference: 'TBC-1', note: null, receiptPath: `receipts/${UID.parentA}/pf1/r.jpg`,
      receiptMime: 'image/jpeg', receiptSize: 3, status: 'submitted', submittedAt: now,
      decidedBy: null, decidedByName: null, decidedAt: null, rejectionReason: null,
    });
    await put('paymentVerificationEvents/ev1', {
      paymentId: 'p1', proofId: 'pf1', action: 'submitted', actorId: UID.parentA, actorRole: 'parent',
      groupId: 'g1', clubId: 'club1', parentId: UID.parentA, reason: null, at: now,
    });
    await updateDoc(doc(db, 'payments/p1'), { verification: { state: 'proof_submitted', proofId: 'pf1', rejectionReason: null, updatedAt: now } });
    await put('trainingPlans/plan1', {
      ...plan({ status: 'published', publishedAt: now }),
      readerIds: [UID.coach, UID.coachNoPay, UID.parentA, UID.parentB], coachIds: [UID.coach, UID.coachNoPay],
    });
    await put('trainingPlans/plan2', { ...plan(), readerIds: [], coachIds: [UID.coach, UID.coachNoPay] });
    await put('medicalCertificates/cert2', {
      childId: 'childA1', uploadedBy: UID.parentA, storagePath: 'medical/childA1/cert2',
      issuedAt: ts('2026-10-01T00:00:00Z'), validUntil: ts('2027-10-01T00:00:00Z'), consentAt: now, status: 'valid', sportId: 'football',
    });
    const storage = ctx.storage();
    await uploadBytes(ref(storage, `receipts/${UID.parentA}/pf1/r.jpg`), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
    await uploadBytes(ref(storage, 'plans/plan1/m1_a.jpg'), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
    await uploadBytes(ref(storage, 'plans/plan2/m1_a.jpg'), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
  });
}

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seed(env);
  await seedV12(env);
  await seedV13();
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const st = (uid, claims) => env.authenticatedContext(uid, claims).storage();
const bytes = (n = 16) => new Uint8Array(n);
const rulesOff = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
const OPEN = ['submitted', 'under_review'];

// ------------------------------------------------------------------ locale
describe('users.locale', () => {
  it('locale field accepts ka/en/ru only', async () => {
    const db = as(UID.parentA);
    for (const l of ['ka', 'en', 'ru']) await assertSucceeds(updateDoc(doc(db, `users/${UID.parentA}`), { locale: l }));
    for (const l of ['de', 'EN', '', 1, null]) await assertFails(updateDoc(doc(db, `users/${UID.parentA}`), { locale: l }));
  });

  it('new notification types are valid notificationPrefs keys', async () => {
    await assertSucceeds(updateDoc(doc(as(UID.parentA), `users/${UID.parentA}`), {
      notificationPrefs: { paymentProofSubmitted: false, paymentProofApproved: true, paymentProofRejected: true, trainingPlanPublished: false },
    }));
  });
});

// ------------------------------------------------------------------ receipts (storage)
describe('storage: payment receipts', () => {
  it('parent uploads a receipt for own payment', async () => {
    await assertSucceeds(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pfNew/r.jpg`), bytes(), { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pfNew2/r.pdf`), bytes(), { contentType: 'application/pdf' }));
    await assertSucceeds(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pfNew3/r.png`), bytes(), { contentType: 'image/png' }));
  });

  it('another parent cannot upload into a parent\'s receipt folder', async () => {
    await assertFails(uploadBytes(ref(st(UID.parentB), `receipts/${UID.parentA}/pfNew/r.jpg`), bytes(), { contentType: 'image/jpeg' }));
  });

  it('receipt over 10 MB is denied', async () => {
    await assertFails(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pfBig/r.pdf`), bytes(10 * 1024 * 1024 + 1), { contentType: 'application/pdf' }));
  });

  it('receipt of a wrong type is denied', async () => {
    await assertFails(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pfX/r.html`), bytes(), { contentType: 'text/html' }));
    await assertFails(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pfX/r.gif`), bytes(), { contentType: 'image/gif' }));
  });

  it('receipt is read by the owner only (reviewers use getReceiptUrl)', async () => {
    await assertSucceeds(getBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pf1/r.jpg`)));
    await assertFails(getBytes(ref(st(UID.coach), `receipts/${UID.parentA}/pf1/r.jpg`)));
    await assertFails(getBytes(ref(st(UID.admin, CLAIMS.platform), `receipts/${UID.parentA}/pf1/r.jpg`)));
  });

  it('a receipt that belongs to a submitted proof cannot be overwritten', async () => {
    await assertFails(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pf1/r.jpg`), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st(UID.parentA), `receipts/${UID.parentA}/pf1/other.jpg`), bytes(), { contentType: 'image/jpeg' }));
  });

  it('a coach cannot upload receipts', async () => {
    await assertFails(uploadBytes(ref(st(UID.coach), `receipts/${UID.coach}/pfC/r.jpg`), bytes(), { contentType: 'image/jpeg' }));
  });
});

// ------------------------------------------------------------------ payments + proofs
describe('payments and proofs', () => {
  it('parent cannot set payment status', async () => {
    await assertFails(updateDoc(doc(as(UID.parentA), 'payments/p1'), { status: 'paid' }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'payments/p1'), { status: 'paid', paidAt: now, updatedBy: UID.parentA }));
  });

  it('parent cannot set payment verification', async () => {
    await assertFails(updateDoc(doc(as(UID.parentA), 'payments/p1'), { verification: { state: 'none', updatedAt: now } }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'payments/p1'), { verifiedBy: UID.parentA, verifiedAt: now }));
  });

  it('verification / verifiedBy / verifiedAt are server-only even for reviewers and admins', async () => {
    await assertFails(updateDoc(doc(as(UID.coach), 'payments/p1'), { verification: { state: 'none', updatedAt: now } }));
    await assertFails(updateDoc(doc(as(UID.coach), 'payments/p1'), { status: 'paid', verifiedBy: UID.coach, verifiedAt: now }));
    await assertFails(updateDoc(doc(as(UID.admin, CLAIMS.platform), 'payments/p1'), { verifiedBy: UID.admin }));
  });

  it('parents never write proofs or verification events directly', async () => {
    await assertFails(setDoc(doc(as(UID.parentA), 'paymentProofs/pfX'), { paymentId: 'p1', parentId: UID.parentA, status: 'approved' }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'paymentProofs/pf1'), { status: 'approved' }));
    await assertFails(setDoc(doc(as(UID.parentA), 'paymentVerificationEvents/x'), { paymentId: 'p1' }));
    await assertFails(updateDoc(doc(as(UID.coach), 'paymentProofs/pf1'), { status: 'approved' }));
  });

  it('coach NOT in paymentManagerIds cannot read proofs', async () => {
    const db = as(UID.coachNoPay);
    await assertFails(getDoc(doc(db, 'paymentProofs/pf1')));
    await assertFails(getDocs(query(collection(db, 'paymentProofs'), where('groupId', '==', 'g1'), where('status', 'in', OPEN))));
    await assertFails(getDocs(query(collection(db, 'paymentVerificationEvents'), where('paymentId', '==', 'p1'))));
  });

  it('coach NOT in paymentManagerIds cannot change payment status (v1.3 behaviour change)', async () => {
    await assertFails(updateDoc(doc(as(UID.coachNoPay), 'payments/p1'), { status: 'paid', paidAt: now, updatedBy: UID.coachNoPay }));
    await assertFails(updateDoc(doc(as(UID.coachNoPay), 'payments/p1'), { status: 'cancelled', cancelledReason: 'left the club' }));
    // still reads the group's payments as a group coach
    await assertSucceeds(getDoc(doc(as(UID.coachNoPay), 'payments/p1')));
  });

  it('payment manager reads proofs, the reviewer queue and events', async () => {
    const db = as(UID.coach);
    await assertSucceeds(getDoc(doc(db, 'paymentProofs/pf1')));
    await assertSucceeds(getDocs(query(collection(db, 'paymentProofs'), where('groupId', '==', 'g1'), where('status', 'in', OPEN))));
    await assertSucceeds(getDocs(query(collection(db, 'paymentProofs'), where('groupId', 'in', ['g1']), where('status', '==', 'submitted'))));
    await assertFails(getDocs(query(collection(db, 'paymentProofs'), where('groupId', 'in', ['g1', 'g2']), where('status', '==', 'submitted'))));
    await assertSucceeds(getDocs(query(collection(db, 'paymentVerificationEvents'), where('paymentId', '==', 'p1'))));
  });

  it('payment manager may mark a payment paid directly', async () => {
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'payments/p1'), { status: 'paid', paidAt: now, updatedBy: UID.coach, updatedAt: now }));
  });

  it('reviewer queue without a groupId/clubId constraint is not allowed for a coach', async () => {
    await assertFails(getDocs(query(collection(as(UID.coach), 'paymentProofs'), where('status', 'in', OPEN))));
  });

  it('club admin of the club reads proofs (clubId query) and may set payment status', async () => {
    const db = as(UID.clubAdminA, CLAIMS.clubA);
    await assertSucceeds(getDoc(doc(db, 'paymentProofs/pf1')));
    await assertSucceeds(getDocs(query(collection(db, 'paymentProofs'), where('clubId', '==', 'club1'), where('status', 'in', OPEN))));
    await assertSucceeds(getDocs(query(collection(db, 'paymentVerificationEvents'), where('paymentId', '==', 'p1'))));
    await assertSucceeds(updateDoc(doc(db, 'payments/p1'), { status: 'cancelled', cancelledReason: 'duplicate' }));
  });

  it('club admin of another club is denied', async () => {
    const db = as(UID.clubAdminB, CLAIMS.clubB);
    await assertFails(getDoc(doc(db, 'paymentProofs/pf1')));
    await assertFails(getDocs(query(collection(db, 'paymentProofs'), where('clubId', '==', 'club1'))));
    await assertFails(getDocs(query(collection(db, 'paymentVerificationEvents'), where('paymentId', '==', 'p1'))));
    await assertFails(getDoc(doc(db, 'payments/p1')));
    await assertFails(updateDoc(doc(db, 'payments/p1'), { status: 'paid' }));
  });

  it('parent reads only own proofs and events', async () => {
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'paymentProofs'), where('paymentId', '==', 'p1'), where('parentId', '==', UID.parentA))));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'paymentVerificationEvents'), where('paymentId', '==', 'p1'))));
    await assertFails(getDoc(doc(as(UID.parentB), 'paymentProofs/pf1')));
    await assertFails(getDocs(query(collection(as(UID.parentB), 'paymentVerificationEvents'), where('paymentId', '==', 'p1'))));
  });

  it('paymentManagerIds cannot be changed by clients (not even a platform admin, nor set on create)', async () => {
    await assertFails(updateDoc(doc(as(UID.coach), 'groups/g1'), { paymentManagerIds: [UID.coach, UID.coachNoPay] }));
    await assertFails(updateDoc(doc(as(UID.admin, CLAIMS.platform), 'groups/g1'), { paymentManagerIds: [UID.coachNoPay] }));
    await assertFails(updateDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'groups/g1'), { paymentManagerIds: [UID.coachNoPay] }));
    await assertFails(setDoc(doc(as(UID.admin, CLAIMS.platform), 'groups/gNew'), { clubId: 'club1', name: 'x', coachIds: [], paymentManagerIds: [UID.coach] }));
  });
});

// ------------------------------------------------------------------ medical certificates
describe('medical certificates (v1.3)', () => {
  const cert = (o = {}) => ({
    childId: 'childA1', uploadedBy: UID.parentA, storagePath: 'medical/childA1/c9', issuedAt: now,
    validUntil: ts('2027-11-01T00:00:00Z'), consentAt: now, status: 'valid', ...o,
  });

  it('admin cannot read a medical file in storage', async () => {
    await assertFails(getBytes(ref(st(UID.admin, CLAIMS.platform), 'medical/childA1/cert1')));
    await assertFails(getBytes(ref(st(UID.clubAdminA, CLAIMS.clubA), 'medical/childA1/cert1')));
  });

  it('create accepts optional sportId / groupId', async () => {
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'medicalCertificates/c9'), cert({ sportId: 'football', groupId: 'g1' })));
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'medicalCertificates/c10'), cert({ storagePath: 'medical/childA1/c10', sportId: null })));
    await assertFails(setDoc(doc(as(UID.parentA), 'medicalCertificates/c11'), cert({ storagePath: 'medical/childA1/c11', replacedBy: 'cert1' })));
  });

  it('parent marks own child\'s older certificate as replaced (replacedBy + replacedAt only)', async () => {
    await assertSucceeds(updateDoc(doc(as(UID.parentA), 'medicalCertificates/cert1'), { replacedBy: 'cert2', replacedAt: now }));
  });

  it('replacement cannot touch other fields, point to itself / a missing or foreign certificate, or be done by others', async () => {
    const db = as(UID.parentA);
    await assertFails(updateDoc(doc(db, 'medicalCertificates/cert1'), { replacedBy: 'cert2', replacedAt: now, status: 'expired' }));
    await assertFails(updateDoc(doc(db, 'medicalCertificates/cert1'), { replacedBy: 'cert1', replacedAt: now }));
    await assertFails(updateDoc(doc(db, 'medicalCertificates/cert1'), { replacedBy: 'nope', replacedAt: now }));
    await assertFails(updateDoc(doc(as(UID.parentB), 'medicalCertificates/cert1'), { replacedBy: 'cert2', replacedAt: now }));
    await assertFails(updateDoc(doc(as(UID.coach), 'medicalCertificates/cert1'), { replacedBy: 'cert2', replacedAt: now }));
  });
});

// ------------------------------------------------------------------ training plans
describe('training plans', () => {
  it('parent reads only published plans of own child\'s group', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(getDoc(doc(db, 'trainingPlans/plan1')));
    await assertFails(getDoc(doc(db, 'trainingPlans/plan2')));
    await assertSucceeds(getDocs(query(collection(db, 'trainingPlans'), where('readerIds', 'array-contains', UID.parentA), where('status', '==', 'published'))));
    await assertFails(getDocs(query(collection(db, 'trainingPlans'), where('groupIds', 'array-contains', 'g1'))));
    // v1.6: the linked student account may read PUBLISHED plans of its own group.
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'trainingPlans/plan1')));
    await assertFails(getDoc(doc(as(UID.childUser), 'trainingPlans/plan2')));
  });

  it('parent loses plan read after the child is removed (readerIds updated by the server)', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'trainingPlans/plan1')));
    await assertSucceeds(getBytes(ref(st(UID.parentA), 'plans/plan1/m1_a.jpg')));
    await rulesOff((db) => updateDoc(doc(db, 'trainingPlans/plan1'), { readerIds: [UID.coach, UID.coachNoPay, UID.parentB] }));
    await assertFails(getDoc(doc(as(UID.parentA), 'trainingPlans/plan1')));
    await assertFails(getBytes(ref(st(UID.parentA), 'plans/plan1/m1_a.jpg')));
  });

  it('coaches of the plan\'s groups read all statuses (coachIds query)', async () => {
    const db = as(UID.coachNoPay);
    await assertSucceeds(getDoc(doc(db, 'trainingPlans/plan2')));
    await assertSucceeds(getDocs(query(collection(db, 'trainingPlans'), where('coachIds', 'array-contains', UID.coachNoPay))));
    await assertFails(getDoc(doc(as(UID.coachOther), 'trainingPlans/plan2')));
  });

  it('coach of another group cannot create a plan for a foreign group', async () => {
    await assertFails(setDoc(doc(as(UID.coachOther), 'trainingPlans/p9'), plan({ createdBy: UID.coachOther })));
    await assertFails(setDoc(doc(as(UID.coachOther), 'trainingPlans/p9'), plan({ createdBy: UID.coachOther, groupIds: ['g2', 'g1'], clubId: 'club2' })));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'trainingPlans/p9'), plan()));
  });

  // Links: the rules cannot iterate 50 exercises × 10 media within their
  // 1000-expression budget, so https-only links are enforced by the server
  // (onTrainingPlanWritten quarantines the plan: status → draft, readerIds [],
  // validationErrors). See the smoke test "plan with a javascript:/http: link
  // is quarantined". Here: the server-managed fields cannot be forged.
  it('plan with a javascript: or http: link can never be made readable by the client (readerIds / validationErrors are server-only)', async () => {
    const bad = plan({ status: 'published', exercises: [{ id: 'e1', order: 0, name: 'x', media: [{ id: 'm', kind: 'link', path: null, url: 'javascript:alert(1)', name: null }] }] });
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p9'), { ...bad, readerIds: [UID.parentA] }));
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p9'), { ...bad, coachIds: [UID.coach] }));
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p9'), { ...bad, validationErrors: [] }));
    await rulesOff((db) => updateDoc(doc(db, 'trainingPlans/plan2'), { validationErrors: ['exercises[0].media[0].url'] }));
    await assertFails(updateDoc(doc(as(UID.coach), 'trainingPlans/plan2'), { validationErrors: [] }));
    await assertFails(updateDoc(doc(as(UID.coach), 'trainingPlans/plan2'), { readerIds: [UID.parentA] }));
  });

  it('a full-size plan (50 exercises × 10 media) is accepted by the rules', async () => {
    const exercises = Array.from({ length: 50 }, (_, i) => ({
      id: `e${i}`, order: i, name: `Ex ${i}`, description: 'd', instructions: 'i', durationMin: 5, reps: 10, sets: 3, restSec: 30,
      media: Array.from({ length: 10 }, (_, j) => ({ id: `m${j}`, kind: 'link', path: null, url: `https://example.com/${i}/${j}`, name: `L${j}` })),
    }));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'trainingPlans/pBig'), plan({ exercises })));
  });

  it('field validation: > 50 exercises, server fields, bad type/status/dates/groups', async () => {
    const db = as(UID.coach);
    const ex = (i) => ({ id: `e${i}`, order: i, name: 'x' });
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ exercises: Array.from({ length: 51 }, (_, i) => ex(i)) })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ readerIds: [UID.parentA] })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ coachIds: [UID.coach] })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ type: 'daily' })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ status: 'archived' })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ endDate: '2026-01-01' })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ title: '' })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ clubId: 'club2' })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ createdBy: UID.coachNoPay })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ exercises: 'not a list' })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ groupIds: [] })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ groupIds: ['g1', 'g1'] })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ startDate: '1.12.2026' })));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ unknownField: true })));
  });

  // Firestore rules may read at most 10 documents per request (measured: also
  // inside a WriteBatch), i.e. the caller's users doc + 9 groups. Client-written
  // plans therefore list at most 9 groups (contract: 10) — documented deviation.
  it('a coach of all 9 listed groups can create the plan; 10 groups are rejected', async () => {
    const groupIds = ['g1', 'g3', 'g4', 'g5', 'g6', 'g7', 'g8', 'g9', 'g10', 'g11'];
    await assertSucceeds(setDoc(doc(as(UID.coach), 'trainingPlans/p9g'), plan({ groupIds: groupIds.slice(0, 9) })));
    await assertFails(setDoc(doc(as(UID.coach), 'trainingPlans/p10'), plan({ groupIds })));
    await assertFails(setDoc(doc(as(UID.coachNoPay), 'trainingPlans/p11'), plan({ groupIds: groupIds.slice(0, 9), createdBy: UID.coachNoPay })));
  });

  it('status transitions: draft→published→archived, published→draft; readerIds untouchable', async () => {
    const db = as(UID.coach);
    const by = { updatedBy: UID.coach };
    await assertSucceeds(updateDoc(doc(db, 'trainingPlans/plan2'), { status: 'published', publishedAt: now, updatedAt: now, ...by }));
    await assertFails(updateDoc(doc(db, 'trainingPlans/plan2'), { readerIds: [UID.parentA], ...by }));
    await assertSucceeds(updateDoc(doc(db, 'trainingPlans/plan1'), { status: 'draft', updatedAt: now, ...by }));
    await assertSucceeds(updateDoc(doc(db, 'trainingPlans/plan2'), { status: 'archived', updatedAt: now, ...by }));
    await assertFails(updateDoc(doc(db, 'trainingPlans/plan2'), { status: 'published', updatedAt: now }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'trainingPlans/plan1'), { status: 'archived' }));
    await assertFails(updateDoc(doc(as(UID.coachOther), 'trainingPlans/plan1'), { status: 'archived' }));
  });

  it('updatedBy (the audit actor) must be the writer on every update', async () => {
    const db = as(UID.coach);
    await assertFails(updateDoc(doc(db, 'trainingPlans/plan2'), { status: 'published', updatedAt: now }));
    await assertFails(updateDoc(doc(db, 'trainingPlans/plan2'), { status: 'published', updatedAt: now, updatedBy: UID.coachNoPay }));
    await assertSucceeds(updateDoc(doc(as(UID.coachNoPay), 'trainingPlans/plan2'), { status: 'published', updatedAt: now, updatedBy: UID.coachNoPay }));
    await assertFails(setDoc(doc(db, 'trainingPlans/p9'), plan({ updatedBy: UID.coachNoPay })));
    await assertSucceeds(setDoc(doc(db, 'trainingPlans/p9'), plan({ updatedBy: UID.coach })));
  });

  it('draft → archived is not allowed; only drafts are deleted', async () => {
    await assertFails(updateDoc(doc(as(UID.coach), 'trainingPlans/plan2'), { status: 'archived', updatedAt: now }));
    await assertFails(deleteDoc(doc(as(UID.coach), 'trainingPlans/plan1')));
    await assertFails(deleteDoc(doc(as(UID.coachOther), 'trainingPlans/plan2')));
    await assertSucceeds(deleteDoc(doc(as(UID.coach), 'trainingPlans/plan2')));
  });

  it('plan media storage: creator uploads within limits; readers and plan coaches read', async () => {
    await assertSucceeds(uploadBytes(ref(st(UID.coach), 'plans/plan2/m2_b.pdf'), bytes(), { contentType: 'application/pdf' }));
    await assertSucceeds(uploadBytes(ref(st(UID.coach), 'plans/plan2/m3_c.mp4'), bytes(), { contentType: 'video/mp4' }));
    await assertFails(uploadBytes(ref(st(UID.coach), 'plans/plan2/m4_d.jpg'), bytes(10 * 1024 * 1024 + 1), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st(UID.coach), 'plans/plan2/m5_e.html'), bytes(), { contentType: 'text/html' }));
    await assertFails(uploadBytes(ref(st(UID.coachNoPay), 'plans/plan2/m6_f.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st(UID.coach), 'plans/nope/m1.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(st(UID.coachNoPay), 'plans/plan2/m1_a.jpg')));
    await assertFails(getBytes(ref(st(UID.parentA), 'plans/plan2/m1_a.jpg')));
    await assertFails(getBytes(ref(st(UID.coachOther), 'plans/plan1/m1_a.jpg')));
  });
});

// ------------------------------------------------------------------ progress + views
describe('exercise progress and plan views', () => {
  const progress = (o = {}) => ({
    planId: 'plan1', exerciseId: 'e1', childId: 'childA1', groupId: 'g1', parentId: UID.parentA,
    status: 'in_progress', viewedAt: now, updatedAt: now, ...o,
  });

  it('parent records progress for own child on a published plan; coaches read by planId', async () => {
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'exerciseProgress/plan1_e1_childA1'), progress()));
    await assertSucceeds(updateDoc(doc(as(UID.parentA), 'exerciseProgress/plan1_e1_childA1'), { status: 'completed', updatedAt: now }));
    await assertSucceeds(getDocs(query(collection(as(UID.coachNoPay), 'exerciseProgress'), where('planId', '==', 'plan1'))));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'exerciseProgress'), where('childId', '==', 'childA1'))));
    await assertFails(getDocs(query(collection(as(UID.coachOther), 'exerciseProgress'), where('planId', '==', 'plan1'))));
  });

  it('exerciseProgress for someone else\'s child is denied', async () => {
    await assertFails(setDoc(doc(as(UID.parentB), 'exerciseProgress/plan1_e1_childA1'), progress({ parentId: UID.parentB })));
    await assertFails(setDoc(doc(as(UID.parentB), 'exerciseProgress/plan1_e1_childA1'), progress()));
  });

  it('exerciseProgress: draft plan, wrong id, bad status, foreign group are denied', async () => {
    const db = as(UID.parentA);
    await assertFails(setDoc(doc(db, 'exerciseProgress/plan2_e1_childA1'), progress({ planId: 'plan2' })));
    await assertFails(setDoc(doc(db, 'exerciseProgress/x'), progress()));
    await assertFails(setDoc(doc(db, 'exerciseProgress/plan1_e1_childA1'), progress({ status: 'mastered' })));
    await assertFails(setDoc(doc(db, 'exerciseProgress/plan1_e1_childA1'), progress({ groupId: 'g2' })));
  });

  it('planViews: parent writes own view of a published plan; coaches read by planId; others denied', async () => {
    const v = { planId: 'plan1', parentId: UID.parentA, firstViewedAt: now, lastViewedAt: now };
    await assertSucceeds(setDoc(doc(as(UID.parentA), `planViews/plan1_${UID.parentA}`), v));
    await assertSucceeds(updateDoc(doc(as(UID.parentA), `planViews/plan1_${UID.parentA}`), { lastViewedAt: now }));
    await assertFails(updateDoc(doc(as(UID.parentA), `planViews/plan1_${UID.parentA}`), { firstViewedAt: ts('2020-01-01T00:00:00Z') }));
    await assertFails(setDoc(doc(as(UID.parentB), `planViews/plan1_${UID.parentA}`), v));
    await assertFails(setDoc(doc(as(UID.parentA), `planViews/plan2_${UID.parentA}`), { ...v, planId: 'plan2' }));
    await assertSucceeds(getDocs(query(collection(as(UID.coach), 'planViews'), where('planId', '==', 'plan1'))));
    await assertFails(getDocs(query(collection(as(UID.coachOther), 'planViews'), where('planId', '==', 'plan1'))));
    await assertFails(getDocs(query(collection(as(UID.parentB), 'planViews'), where('planId', '==', 'plan1'))));
  });
});
