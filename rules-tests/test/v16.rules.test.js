// v1.6 rules: student account (child role linked to childA1) and Brain Academy.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { addDoc, collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where } from 'firebase/firestore';
import { CLAIMS, UID, createEnv, now, seed, seedV12, ts } from './setup.js';

let env;
beforeAll(async () => {
  env = await createEnv();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await seedV12(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, d) => setDoc(doc(db, p), d);
    await put('attendance/t1_childA1', { trainingId: 't1', groupId: 'g1', childId: 'childA1', status: 'present', markedBy: UID.coach, markedAt: now, note: null });
    await put('attendance/t1_childB1', { trainingId: 't1', groupId: 'g1', childId: 'childB1', status: 'absent', markedBy: UID.coach, markedAt: now, note: null });
    await put('brainResults/r1', { childId: 'childA1', game: 'memoryMatch', difficulty: 'easy', level: 1, score: 300, accuracy: 0.8, attempts: 5, durationMs: 40000, completed: true, playedAt: now, detail: {} });
    await put('brainResults/r2', { childId: 'childB1', game: 'logicQuest', difficulty: 'easy', level: 1, score: 500, accuracy: 0.9, attempts: 8, durationMs: 50000, completed: true, playedAt: now, detail: {} });
    await put('brainAssignments/a1', { groupId: 'g1', coachId: UID.coach, game: 'smartPlay', difficulty: 'easy', createdAt: now, dueDate: null });
    await put('trainingPlans/pl1', {
      title: 'Homework', description: '', type: 'homework', groupIds: ['g1'], clubId: 'club1', startDate: '2026-11-01', endDate: null,
      status: 'published', exercises: [], createdBy: UID.coach, coachName: 'c', createdAt: now, updatedAt: now, readerIds: [UID.parentA], coachIds: [UID.coach],
    });
    await put('trainingPlans/pl2', {
      title: 'Draft', description: '', type: 'weekly', groupIds: ['g1'], clubId: 'club1', startDate: '2026-11-01', endDate: null,
      status: 'draft', exercises: [], createdBy: UID.coach, coachName: 'c', createdAt: now, updatedAt: now, readerIds: [], coachIds: [UID.coach],
    });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const result = (o = {}) => ({
  childId: 'childA1', game: 'quickMind', difficulty: 'medium', level: 2, score: 420, accuracy: 0.75, attempts: 12,
  durationMs: 30000, completed: true, playedAt: serverTimestamp(), detail: { avgReactionMs: 800 }, ...o,
});

describe('v1.6 student account — own, non-sensitive data only', () => {
  it('reads own child, own group, own trainings/attendance and published plans', async () => {
    const db = as(UID.childUser);
    await assertSucceeds(getDoc(doc(db, 'children/childA1')));
    // Full group docs (other families' ids) stay closed; the public projection is used instead.
    await assertFails(getDoc(doc(db, 'groups/g1')));
    await assertSucceeds(getDoc(doc(db, 'trainings/t1')));
    await assertSucceeds(getDoc(doc(db, 'attendance/t1_childA1')));
    await assertSucceeds(getDoc(doc(db, 'trainingPlans/pl1')));
  });
  it('no other children, other groups, drafts, chat, payments, medical files, phones or inbox', async () => {
    const db = as(UID.childUser);
    await assertFails(getDoc(doc(db, 'children/childB1')));
    await assertFails(getDoc(doc(db, 'attendance/t1_childB1')));
    await assertFails(getDoc(doc(db, 'groups/g2')));
    await assertFails(getDoc(doc(db, 'trainings/t2')));
    await assertFails(getDoc(doc(db, 'trainingPlans/pl2')));
    await assertFails(getDocs(collection(db, 'chats/g1/messages')));
    await assertFails(getDoc(doc(db, 'payments/p1')));
    await assertFails(getDoc(doc(db, 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(db, `users/${UID.parentA}`)));
    await assertFails(addDoc(collection(db, 'chats/g1/messages'), { senderId: UID.childUser, senderName: 'k', senderRole: 'child', text: 'hi', createdAt: serverTimestamp() }));
  });
});

describe('v1.6 brainResults', () => {
  it('the linked student records own results with server time', async () => {
    await assertSucceeds(setDoc(doc(as(UID.childUser), 'brainResults/n1'), result()));
  });
  it('invalid values, client clocks, other children and other roles are refused', async () => {
    const db = as(UID.childUser);
    await assertFails(setDoc(doc(db, 'brainResults/x1'), result({ score: -5 })));
    await assertFails(setDoc(doc(db, 'brainResults/x2'), result({ level: 11 })));
    await assertFails(setDoc(doc(db, 'brainResults/x3'), result({ accuracy: 1.5 })));
    await assertFails(setDoc(doc(db, 'brainResults/x4'), result({ game: 'chess' })));
    await assertFails(setDoc(doc(db, 'brainResults/x5'), result({ playedAt: ts('2030-01-01T00:00:00Z') })));
    await assertFails(setDoc(doc(db, 'brainResults/x6'), result({ iq: 140 })));
    await assertFails(setDoc(doc(db, 'brainResults/x7'), result({ childId: 'childB1' })));
    await assertFails(setDoc(doc(as(UID.parentA), 'brainResults/x8'), result()));
    await assertFails(setDoc(doc(as(UID.coach), 'brainResults/x9'), result()));
  });
  it('student, parent and coach of the child read; other parents and admins do not', async () => {
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'brainResults/r1')));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'brainResults/r1')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'brainResults/r1')));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'brainResults'), where('childId', '==', 'childA1'))));
    await assertFails(getDoc(doc(as(UID.parentB), 'brainResults/r1')));
    await assertFails(getDoc(doc(as(UID.childUser), 'brainResults/r2')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'brainResults/r1')));
    await assertFails(getDoc(doc(as(UID.admin, CLAIMS.platform), 'brainResults/r1')));
  });
  it('results are immutable', async () => {
    await assertFails(updateDoc(doc(as(UID.childUser), 'brainResults/r1'), { score: 9999 }));
    await assertFails(deleteDoc(doc(as(UID.childUser), 'brainResults/r1')));
    await assertFails(deleteDoc(doc(as(UID.parentA), 'brainResults/r1')));
  });
});

describe('v1.6 brainAssignments', () => {
  const challenge = (o = {}) => ({ groupId: 'g1', coachId: UID.coach, game: 'pathFinder', difficulty: 'hard', createdAt: serverTimestamp(), dueDate: ts('2026-12-01T00:00:00Z'), ...o });
  it('the coach of the group assigns and removes challenges', async () => {
    await assertSucceeds(setDoc(doc(as(UID.coach), 'brainAssignments/n1'), challenge()));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'brainAssignments/n2'), challenge({ dueDate: null })));
    await assertSucceeds(deleteDoc(doc(as(UID.coach), 'brainAssignments/a1')));
  });
  it('other coaches, parents and students cannot assign, edit or remove', async () => {
    await assertFails(setDoc(doc(as(UID.coachOther), 'brainAssignments/x1'), challenge({ coachId: UID.coachOther })));
    await assertFails(setDoc(doc(as(UID.parentA), 'brainAssignments/x2'), challenge({ coachId: UID.parentA })));
    await assertFails(setDoc(doc(as(UID.childUser), 'brainAssignments/x3'), challenge({ coachId: UID.childUser })));
    await assertFails(setDoc(doc(as(UID.coach), 'brainAssignments/x4'), challenge({ game: 'chess' })));
    await assertFails(updateDoc(doc(as(UID.coach), 'brainAssignments/a1'), { difficulty: 'hard' }));
    await assertFails(deleteDoc(doc(as(UID.parentA), 'brainAssignments/a1')));
  });
  it('group parents, the student and the coach read; outsiders do not', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'brainAssignments/a1')));
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'brainAssignments/a1')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'brainAssignments/a1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'brainAssignments/a1')));
  });
});
