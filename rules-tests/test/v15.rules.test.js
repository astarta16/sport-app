// v1.5 rules: server-only match results, child-context parent↔coach threads.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { CLAIMS, UID, createEnv, now, seed, seedV12, ts } from './setup.js';

let env;
beforeAll(async () => {
  env = await createEnv();
});

const match = (o = {}) => ({
  groupId: 'g1', clubId: 'club1', venueId: 'v1', startAt: ts('2026-11-15T10:00:00Z'), durationMin: 90, opponentName: 'Dinamo',
  matchType: 'friendly', homeAway: 'home', status: 'scheduled', createdBy: UID.coach, updatedAt: now, ...o,
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await seedV12(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'matches/mR'), match({ status: 'played', result: { ourScore: 3, opponentScore: 1, outcome: 'win', version: 1 } }));
    await setDoc(doc(db, 'matches/mR/resultHistory/1'), { version: 1, by: UID.coach, at: now, from: null, to: { ourScore: 3, opponentScore: 1 } });
    await setDoc(doc(db, 'childThreads/childA1_coachApproved'), { childId: 'childA1', coachId: UID.coach, createdBy: UID.parentA, createdAt: now });
    await setDoc(doc(db, 'childThreads/childA1_coachApproved/messages/m1'), { senderId: UID.parentA, senderName: 'A', senderRole: 'parent', text: 'Hi', createdAt: now });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const msg = (uid, role, text = 'Question about Nika') => ({ senderId: uid, senderName: 'x', senderRole: role, text, createdAt: serverTimestamp() });

describe('v1.5 match results', () => {
  it('parents and coaches of the group read the result; outsiders do not', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'matches/mR')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'matches/mR')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'matches/mR')));
  });
  it('nobody writes `result` directly — not even the coach of the group', async () => {
    await assertFails(updateDoc(doc(as(UID.coach), 'matches/mR'), { result: { ourScore: 9, opponentScore: 0, outcome: 'win', version: 2 } }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'matches/mR'), { result: { ourScore: 9, opponentScore: 0 } }));
    await assertFails(setDoc(doc(as(UID.coach), 'matches/mNew'), match({ result: { ourScore: 1, opponentScore: 0 } })));
    // Other edits by the coach keep working and leave the result untouched.
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'matches/mR'), { description: 'Great game', updatedAt: now }));
  });
  it('correction history: coach reads, parents and writers are refused', async () => {
    await assertSucceeds(getDoc(doc(as(UID.coach), 'matches/mR/resultHistory/1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'matches/mR/resultHistory/1')));
    await assertFails(setDoc(doc(as(UID.coach), 'matches/mR/resultHistory/2'), { version: 2 }));
  });
});

describe('v1.5 child-context threads', () => {
  it('the child guardian and that coach read and write; other parents cannot', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'childThreads/childA1_coachApproved')));
    await assertSucceeds(getDocs(collection(as(UID.coach), 'childThreads/childA1_coachApproved/messages')));
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'childThreads/childA1_coachApproved/messages/m2'), msg(UID.parentA, 'parent')));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'childThreads/childA1_coachApproved/messages/m3'), msg(UID.coach, 'coach', 'Thanks!')));
    await assertFails(getDoc(doc(as(UID.parentB), 'childThreads/childA1_coachApproved')));
    await assertFails(getDocs(collection(as(UID.parentB), 'childThreads/childA1_coachApproved/messages')));
    await assertFails(setDoc(doc(as(UID.parentB), 'childThreads/childA1_coachApproved/messages/x'), msg(UID.parentB, 'parent')));
  });
  it('children, other coaches, pending coaches and admins are refused', async () => {
    await assertFails(getDoc(doc(as(UID.childUser), 'childThreads/childA1_coachApproved')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'childThreads/childA1_coachApproved')));
    await assertFails(getDoc(doc(as(UID.coachPending), 'childThreads/childA1_coachApproved')));
    await assertFails(getDoc(doc(as(UID.admin, CLAIMS.platform), 'childThreads/childA1_coachApproved')));
  });
  it('a parent can open a thread only with a current coach of the child', async () => {
    const t = (coachId, createdBy = UID.parentA) => ({ childId: 'childA1', coachId, createdBy, createdAt: serverTimestamp() });
    await env.withSecurityRulesDisabled(async (ctx) => {
      const { deleteDoc } = await import('firebase/firestore');
      await deleteDoc(doc(ctx.firestore(), 'childThreads/childA1_coachApproved'));
    });
    await assertFails(setDoc(doc(as(UID.parentA), 'childThreads/childA1_coachOther'), t(UID.coachOther)), 'not the child\'s coach');
    await assertFails(setDoc(doc(as(UID.parentB), 'childThreads/childA1_coachApproved'), t(UID.coach, UID.parentB)), 'not my child');
    await assertFails(setDoc(doc(as(UID.parentA), 'childThreads/wrongId'), t(UID.coach)), 'id must be child_coach');
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'childThreads/childA1_coachApproved'), t(UID.coach)));
  });
  it('messages are immutable, server-timed and sender-bound', async () => {
    const db = as(UID.parentA);
    await assertFails(setDoc(doc(db, 'childThreads/childA1_coachApproved/messages/m4'), { ...msg(UID.parentA, 'parent'), createdAt: ts('2030-01-01T00:00:00Z') }));
    await assertFails(setDoc(doc(db, 'childThreads/childA1_coachApproved/messages/m5'), msg(UID.coach, 'coach')));
    await assertFails(setDoc(doc(db, 'childThreads/childA1_coachApproved/messages/m6'), msg(UID.parentA, 'parent', '')));
    await assertFails(updateDoc(doc(db, 'childThreads/childA1_coachApproved/messages/m1'), { text: 'edited' }));
    await assertFails(updateDoc(doc(db, 'childThreads/childA1_coachApproved'), { lastMessageAt: now }));
  });
  it('a coach removed from the child loses access immediately', async () => {
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'children/childA1'), { coachIds: [] }));
    await assertFails(getDoc(doc(as(UID.coach), 'childThreads/childA1_coachApproved')));
    await assertFails(setDoc(doc(as(UID.coach), 'childThreads/childA1_coachApproved/messages/x'), msg(UID.coach, 'coach')));
  });
});
