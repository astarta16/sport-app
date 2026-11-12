// v1.4 security-rules tests: phone privacy, chat read receipts and
// acknowledgments, media download log, media policy field.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection, collectionGroup, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';
import { CLAIMS, UID, createEnv, now, seed, seedV12, ts } from './setup.js';

let env;
beforeAll(async () => {
  env = await createEnv();
});

const GUARDIAN2 = 'parentA2';

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await seedV12(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, d) => setDoc(doc(db, p), d);
    // Second guardian of childA1.
    await put(`users/${GUARDIAN2}`, { role: 'parent', firstName: 'G2', lastName: 'A', phone: '+995599000222', createdAt: now, dataConsentAt: now, fcmTokens: [], notificationPrefs: {} });
    await updateDoc(doc(db, 'children/childA1'), { parentIds: [UID.parentA, GUARDIAN2] });
    await updateDoc(doc(db, 'groups/g1'), { parentIds: [UID.parentA, UID.parentB, GUARDIAN2] });
    // Coach message with a server-made recipient snapshot (parentB joined later is NOT in it).
    await put('chats/g1/messages/cm1', { senderId: UID.coach, senderName: 'Coach', senderRole: 'coach', type: 'text', text: 'Bring water', createdAt: now, requiresAck: true });
    await put('chats/g1/receipts/cm1', { senderId: UID.coach, groupId: 'g1', messageId: 'cm1', recipientIds: [UID.parentA, GUARDIAN2], recipientCount: 2, readCount: 0, ackCount: 0, requiresAck: true, createdAt: now });
    await put('chats/g1/messages/cm2', { senderId: UID.coach, senderName: 'Coach', senderRole: 'coach', type: 'text', text: 'FYI', createdAt: now });
    await put('chats/g1/receipts/cm2', { senderId: UID.coach, groupId: 'g1', messageId: 'cm2', recipientIds: [UID.parentA, UID.parentB, GUARDIAN2], recipientCount: 3, readCount: 0, ackCount: 0, requiresAck: false, createdAt: now });
    await put('mediaDownloads/d1', { postId: 'post1', userId: UID.parentA, role: 'parent', groupId: 'g1', clubId: 'club1', mediaType: 'photo', at: now });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const mark = (uid, messageId, field) => ({ uid, groupId: 'g1', messageId, [field]: serverTimestamp() });
const readRef = (db, m, u) => doc(db, `chats/g1/messages/${m}/msgReads/${u}`);
const ackRef = (db, m, u) => doc(db, `chats/g1/messages/${m}/msgAcks/${u}`);

describe('v1.4 phone privacy', () => {
  it('phones are not in public profiles and other users docs are unreadable', async () => {
    await assertFails(getDoc(doc(as(UID.parentB), `users/${UID.parentA}`)));
    await assertFails(getDoc(doc(as(UID.coach), `users/${UID.parentA}`)));
    await assertFails(getDoc(doc(as(GUARDIAN2), `users/${UID.parentA}`)));
    await assertFails(getDocs(query(collection(as(UID.parentA), 'users'), where('role', '==', 'parent'))));
    await assertSucceeds(getDoc(doc(as(UID.parentA), `users/${UID.parentA}`)));
  });
});

describe('v1.4 read receipts', () => {
  it('a recipient parent marks a message read once with the server time', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(setDoc(readRef(db, 'cm2', UID.parentA), mark(UID.parentA, 'cm2', 'readAt')));
    await assertFails(setDoc(readRef(db, 'cm2', UID.parentA), mark(UID.parentA, 'cm2', 'readAt')), 'no second write / update');
    await assertFails(setDoc(readRef(db, 'cm1', UID.parentA), { uid: UID.parentA, groupId: 'g1', messageId: 'cm1', readAt: ts('2030-01-01T00:00:00Z') }), 'client clock rejected');
  });
  it('multiple guardians mark separately; nobody marks for someone else', async () => {
    await assertSucceeds(setDoc(readRef(as(GUARDIAN2), 'cm2', GUARDIAN2), mark(GUARDIAN2, 'cm2', 'readAt')));
    await assertFails(setDoc(readRef(as(UID.parentA), 'cm2', GUARDIAN2), mark(GUARDIAN2, 'cm2', 'readAt')));
    await assertFails(setDoc(readRef(as(UID.parentA), 'cm2', GUARDIAN2), mark(UID.parentA, 'cm2', 'readAt')));
  });
  it('parents outside the snapshot, removed parents, coaches and outsiders cannot mark', async () => {
    await assertFails(setDoc(readRef(as(UID.parentB), 'cm1', UID.parentB), mark(UID.parentB, 'cm1', 'readAt')), 'not in snapshot');
    await assertFails(setDoc(readRef(as(UID.coachOther), 'cm2', UID.coachOther), mark(UID.coachOther, 'cm2', 'readAt')));
    await assertFails(setDoc(readRef(as(UID.coach), 'cm2', UID.coach), mark(UID.coach, 'cm2', 'readAt')));
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'groups/g1'), { parentIds: [UID.parentB, GUARDIAN2] }));
    await assertFails(setDoc(readRef(as(UID.parentA), 'cm2', UID.parentA), mark(UID.parentA, 'cm2', 'readAt')), 'membership ended');
  });
  it('only the sending coach reads receipts; parents read only their own marks', async () => {
    await assertSucceeds(setDoc(readRef(as(UID.parentA), 'cm2', UID.parentA), mark(UID.parentA, 'cm2', 'readAt')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'chats/g1/receipts/cm2')));
    await assertSucceeds(getDocs(collection(as(UID.coach), 'chats/g1/messages/cm2/msgReads')));
    await assertSucceeds(getDocs(query(collection(as(UID.coach), 'chats/g1/receipts'), where('senderId', '==', UID.coach))));
    await assertFails(getDoc(doc(as(UID.parentA), 'chats/g1/receipts/cm2')));
    await assertFails(getDocs(collection(as(GUARDIAN2), 'chats/g1/messages/cm2/msgReads')), 'other guardians\' reads are private');
    await assertFails(getDoc(doc(as(UID.admin, CLAIMS.platform), 'chats/g1/receipts/cm2')), 'admins get no read history');
    await assertFails(getDoc(doc(as(UID.coachOther), 'chats/g1/receipts/cm2')));
    await assertSucceeds(getDocs(query(collectionGroup(as(UID.parentA), 'msgReads'), where('uid', '==', UID.parentA), where('groupId', '==', 'g1'))));
    await assertFails(getDocs(query(collectionGroup(as(UID.parentA), 'msgReads'), where('groupId', '==', 'g1'))));
  });
  it('a removed coach loses access to receipts', async () => {
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'groups/g1'), { coachIds: [UID.coachOther] }));
    await assertFails(getDoc(doc(as(UID.coach), 'chats/g1/receipts/cm2')));
  });
  it('receipts are server-only', async () => {
    await assertFails(setDoc(doc(as(UID.coach), 'chats/g1/receipts/x'), { senderId: UID.coach, recipientIds: [] }));
    await assertFails(updateDoc(doc(as(UID.coach), 'chats/g1/receipts/cm2'), { readCount: 99 }));
  });
});

describe('v1.4 acknowledgments', () => {
  it('a recipient acknowledges once; reads and acks are distinct', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(setDoc(readRef(db, 'cm1', UID.parentA), mark(UID.parentA, 'cm1', 'readAt')));
    await assertSucceeds(setDoc(ackRef(db, 'cm1', UID.parentA), mark(UID.parentA, 'cm1', 'ackAt')));
    await assertFails(setDoc(ackRef(db, 'cm1', UID.parentA), mark(UID.parentA, 'cm1', 'ackAt')), 'duplicate');
    await assertFails(updateDoc(ackRef(db, 'cm1', UID.parentA), { ackAt: serverTimestamp() }));
  });
  it('both guardians acknowledge separately in one batch with their own read', async () => {
    const db = as(GUARDIAN2);
    const b = writeBatch(db);
    b.set(readRef(db, 'cm1', GUARDIAN2), mark(GUARDIAN2, 'cm1', 'readAt'));
    b.set(ackRef(db, 'cm1', GUARDIAN2), mark(GUARDIAN2, 'cm1', 'ackAt'));
    await assertSucceeds(b.commit());
  });
  it('no acknowledgment where none was requested, outside the snapshot, or by others', async () => {
    await assertFails(setDoc(ackRef(as(UID.parentA), 'cm2', UID.parentA), mark(UID.parentA, 'cm2', 'ackAt')), 'not requested');
    await assertFails(setDoc(ackRef(as(UID.parentB), 'cm1', UID.parentB), mark(UID.parentB, 'cm1', 'ackAt')), 'joined later');
    await assertFails(setDoc(ackRef(as(UID.coach), 'cm1', UID.coach), mark(UID.coach, 'cm1', 'ackAt')));
    await assertFails(setDoc(ackRef(as(UID.parentA), 'cm1', GUARDIAN2), mark(GUARDIAN2, 'cm1', 'ackAt')));
  });
  it('only coaches can send messages that require acknowledgment', async () => {
    const msg = (sender, role) => ({ senderId: sender, senderName: 'x', senderRole: role, type: 'text', text: 'Important', createdAt: serverTimestamp(), requiresAck: true });
    await assertSucceeds(setDoc(doc(as(UID.coach), 'chats/g1/messages/n1'), msg(UID.coach, 'coach')));
    await assertFails(setDoc(doc(as(UID.parentA), 'chats/g1/messages/n2'), msg(UID.parentA, 'parent')));
    await assertFails(setDoc(doc(as(UID.coach), 'chats/g1/messages/n3'), { ...msg(UID.coach, 'coach'), requiresAck: 'yes' }));
  });
  it('acknowledgment records stay readable to their owner after leaving the group, but not the chat', async () => {
    await assertSucceeds(setDoc(ackRef(as(UID.parentA), 'cm1', UID.parentA), mark(UID.parentA, 'cm1', 'ackAt')));
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'groups/g1'), { parentIds: [UID.parentB, GUARDIAN2] }));
    await assertSucceeds(getDoc(ackRef(as(UID.parentA), 'cm1', UID.parentA)));
    await assertFails(getDoc(doc(as(UID.parentA), 'chats/g1/messages/cm1')));
  });
});

describe('v1.4 media downloads and policy', () => {
  it('download events are readable by platform and club admins only', async () => {
    await assertSucceeds(getDoc(doc(as(UID.admin, CLAIMS.platform), 'mediaDownloads/d1')));
    await assertSucceeds(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'mediaDownloads/d1')));
    await assertFails(getDoc(doc(as(UID.clubAdminB, CLAIMS.clubB), 'mediaDownloads/d1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'mediaDownloads/d1')));
    await assertFails(setDoc(doc(as(UID.parentA), 'mediaDownloads/d2'), { postId: 'x', userId: UID.parentA, clubId: 'club1', at: now }));
  });
  it('the media download policy is server-managed (updateGroup), not written directly', async () => {
    await assertFails(updateDoc(doc(as(UID.admin, CLAIMS.platform), 'groups/g1'), { mediaDownloadsEnabled: false }));
    await assertFails(updateDoc(doc(as(UID.coach), 'groups/g1'), { mediaDownloadsEnabled: false }));
  });
});
