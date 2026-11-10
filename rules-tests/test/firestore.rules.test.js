import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  addDoc, collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp,
  setDoc, updateDoc, where,
} from 'firebase/firestore';
import { createEnv, seed, UID, ts, now } from './setup.js';

let env;

beforeAll(async () => {
  env = await createEnv();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seed(env);
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const guest = () => env.unauthenticatedContext().firestore();

const validTraining = (overrides = {}) => ({
  groupId: 'g1', venueId: 'v1', startAt: ts('2026-11-20T14:00:00Z'), durationMin: 60,
  focus: ['technique', 'ball'], description: 'Dribbling', photoUrls: [],
  status: 'scheduled', createdBy: UID.coach, updatedAt: now,
  ...overrides,
});

describe('guest mode', () => {
  it('guest can read sports, clubs and venues', async () => {
    const db = guest();
    await assertSucceeds(getDoc(doc(db, 'sports/football')));
    await assertSucceeds(getDoc(doc(db, 'clubs/club1')));
    await assertSucceeds(getDoc(doc(db, 'venues/v1')));
    await assertSucceeds(getDocs(collection(db, 'clubs')));
  });

  it('guest cannot read children, groups, trainings or users', async () => {
    const db = guest();
    await assertFails(getDoc(doc(db, 'children/childA1')));
    await assertFails(getDoc(doc(db, 'groups/g1')));
    await assertFails(getDoc(doc(db, 'trainings/t1')));
    await assertFails(getDoc(doc(db, `users/${UID.parentA}`)));
  });

  it('only admin can write the catalogue', async () => {
    await assertFails(setDoc(doc(guest(), 'clubs/x'), { name: 'x' }));
    await assertFails(setDoc(doc(as(UID.coach), 'clubs/x'), { name: 'x' }));
    await assertSucceeds(setDoc(doc(as(UID.admin, { admin: true }), 'clubs/x'), { name: 'x' }));
  });
});

describe('users & profiles', () => {
  it('parent cannot read another parent\'s user doc (phone)', async () => {
    await assertFails(getDoc(doc(as(UID.parentA), `users/${UID.parentB}`)));
    await assertSucceeds(getDoc(doc(as(UID.parentA), `users/${UID.parentA}`)));
  });

  it('coach cannot read a parent\'s user doc directly', async () => {
    await assertFails(getDoc(doc(as(UID.coach), `users/${UID.parentA}`)));
  });

  it('authenticated users can read publicProfiles but not write them', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'publicProfiles/parentB')));
    await assertFails(getDoc(doc(guest(), 'publicProfiles/parentB')));
    await assertFails(setDoc(doc(as(UID.parentB), 'publicProfiles/parentB'), { firstName: 'x', lastName: 'y', role: 'admin' }));
  });

  const newUser = (extra) => ({
    firstName: 'New', lastName: 'User', phone: '+995599111111',
    createdAt: serverTimestamp(), dataConsentAt: serverTimestamp(), fcmTokens: [], ...extra,
  });

  it('can self-register as parent or as pending coach', async () => {
    await assertSucceeds(setDoc(doc(as('newParent'), 'users/newParent'), newUser({ role: 'parent' })));
    await assertSucceeds(setDoc(doc(as('newCoach'), 'users/newCoach'),
      newUser({ role: 'coach', coachStatus: 'pending', clubIds: ['club1'], sportIds: ['football'] })));
  });

  it('cannot self-assign approved coach, admin or child role', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), newUser({ role: 'coach', coachStatus: 'approved' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), newUser({ role: 'coach' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), newUser({ role: 'admin' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), newUser({ role: 'child' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), newUser({ role: 'parent', coachStatus: 'approved' })));
  });

  it('cannot create a user doc for someone else or without data consent', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u2'), newUser({ role: 'parent' })));
    const { dataConsentAt, ...noConsent } = newUser({ role: 'parent' });
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), noConsent));
  });

  it('pending coach can update own profile but not coachStatus or role', async () => {
    const db = as(UID.coachPending);
    await assertSucceeds(updateDoc(doc(db, `users/${UID.coachPending}`), { firstName: 'Giorgi' }));
    await assertFails(updateDoc(doc(db, `users/${UID.coachPending}`), { coachStatus: 'approved' }));
    await assertFails(updateDoc(doc(as(UID.parentA), `users/${UID.parentA}`), { role: 'admin' }));
    await assertFails(updateDoc(doc(as(UID.parentA), `users/${UID.parentA}`), { role: 'coach' }));
  });

  it('approved coach cannot change own clubIds', async () => {
    await assertFails(updateDoc(doc(as(UID.coach), `users/${UID.coach}`), { clubIds: ['club1', 'club2'] }));
  });

  it('notificationPrefs only accept known keys', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(updateDoc(doc(db, `users/${UID.parentA}`), { notificationPrefs: { paymentSms: false, chatMessage: true } }));
    await assertFails(updateDoc(doc(db, `users/${UID.parentA}`), { notificationPrefs: { hack: true } }));
  });
});

describe('children', () => {
  it('parent cannot read another family\'s child', async () => {
    await assertFails(getDoc(doc(as(UID.parentA), 'children/childB1')));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'children/childA1')));
  });

  it('parent can list only own children with an array-contains query', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(getDocs(query(collection(db, 'children'), where('parentIds', 'array-contains', UID.parentA))));
    await assertFails(getDocs(collection(db, 'children')));
  });

  it('parent creating a child must include self in parentIds', async () => {
    const child = { firstName: 'Luka', lastName: 'A', birthDate: ts('2015-05-05T00:00:00Z'), sportIds: [], groupIds: [], photoConsent: false };
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'children/new1'), { ...child, parentIds: [UID.parentA] }));
    await assertFails(setDoc(doc(as(UID.parentA), 'children/new2'), { ...child, parentIds: [UID.parentB] }));
    await assertFails(setDoc(doc(as(UID.coach), 'children/new3'), { ...child, parentIds: [UID.coach] }));
    await assertFails(setDoc(doc(as(UID.parentA), 'children/new4'), { ...child, parentIds: [UID.parentA], groupIds: ['g1'] }));
  });

  it('parent cannot change groupIds/coachIds/parentIds of a child', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(updateDoc(doc(db, 'children/childA1'), { photoConsent: false }));
    await assertFails(updateDoc(doc(db, 'children/childA1'), { groupIds: ['g1', 'g2'] }));
    await assertFails(updateDoc(doc(db, 'children/childA1'), { coachIds: [UID.coachOther] }));
    await assertFails(updateDoc(doc(db, 'children/childA1'), { parentIds: [UID.parentA, UID.parentB] }));
  });

  it('child account can read its own child doc only', async () => {
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'children/childA1')));
    await assertFails(getDoc(doc(as(UID.childUser), 'children/childB1')));
  });

  it('approved coach reads children in own groups; others cannot', async () => {
    await assertSucceeds(getDoc(doc(as(UID.coach), 'children/childB1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'children/childB1')));
    await assertFails(getDoc(doc(as(UID.coachPending), 'children/childB1')));
  });
});

describe('groups', () => {
  it('unapproved coach cannot read groups', async () => {
    await assertFails(getDoc(doc(as(UID.coachPending), 'groups/g1')));
  });

  it('approved coach reads own group, not others', async () => {
    await assertSucceeds(getDoc(doc(as(UID.coach), 'groups/g1')));
    await assertFails(getDoc(doc(as(UID.coach), 'groups/g2')));
  });

  it('parent reads groups they belong to', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'groups/g1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'groups/g2')));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'groups'), where('parentIds', 'array-contains', UID.parentA))));
  });

  it('child account cannot read groups', async () => {
    await assertFails(getDoc(doc(as(UID.childUser), 'groups/g1')));
  });

  it('coach may remove members but not add them or edit parentIds', async () => {
    const db = as(UID.coach);
    await assertFails(updateDoc(doc(db, 'groups/g1'), { memberChildIds: ['childA1', 'childB1', 'childX'] }));
    await assertFails(updateDoc(doc(db, 'groups/g1'), { parentIds: [UID.coach] }));
    await assertSucceeds(updateDoc(doc(db, 'groups/g1'), { memberChildIds: ['childA1'] }));
  });

  it('parent cannot update a group', async () => {
    await assertFails(updateDoc(doc(as(UID.parentA), 'groups/g1'), { name: 'x' }));
  });
});

describe('trainings', () => {
  it('approved coach can create a training only in own group', async () => {
    const db = as(UID.coach);
    await assertSucceeds(setDoc(doc(db, 'trainings/new1'), validTraining()));
    await assertFails(setDoc(doc(db, 'trainings/new2'), validTraining({ groupId: 'g2' })));
  });

  it('training validation: createdBy, focus values, duration bounds', async () => {
    const db = as(UID.coach);
    await assertFails(setDoc(doc(db, 'trainings/a'), validTraining({ createdBy: UID.coachOther })));
    await assertFails(setDoc(doc(db, 'trainings/b'), validTraining({ focus: ['technique', 'yoga'] })));
    await assertFails(setDoc(doc(db, 'trainings/c'), validTraining({ durationMin: 10 })));
    await assertFails(setDoc(doc(db, 'trainings/d'), validTraining({ durationMin: 301 })));
    await assertSucceeds(setDoc(doc(db, 'trainings/e'), validTraining({ durationMin: 15 })));
    await assertSucceeds(setDoc(doc(db, 'trainings/f'), validTraining({ durationMin: 300 })));
  });

  it('unapproved coach and parents cannot create trainings', async () => {
    await assertFails(setDoc(doc(as(UID.coachPending), 'trainings/x'), validTraining({ createdBy: UID.coachPending })));
    await assertFails(setDoc(doc(as(UID.parentA), 'trainings/y'), validTraining({ createdBy: UID.parentA })));
  });

  it('coach can update (e.g. cancel) but not move to another group or set reminderSentAt', async () => {
    const db = as(UID.coach);
    await assertSucceeds(updateDoc(doc(db, 'trainings/t1'), { status: 'cancelled', updatedAt: now }));
    await assertFails(updateDoc(doc(db, 'trainings/t1'), { groupId: 'g2' }));
    await assertFails(updateDoc(doc(db, 'trainings/t1'), { reminderSentAt: now }));
    await assertFails(updateDoc(doc(as(UID.coachOther), 'trainings/t1'), { status: 'cancelled' }));
  });

  it('parents, coaches and child accounts read only their group\'s trainings', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'trainings/t1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'trainings/t2')));
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'trainings/t1')));
    await assertFails(getDoc(doc(as(UID.childUser), 'trainings/t2')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'trainings/t1')));
    await assertFails(getDoc(doc(as(UID.coachPending), 'trainings/t1')));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'trainings'), where('groupId', '==', 'g1'))));
  });

  it('child account cannot write trainings', async () => {
    await assertFails(updateDoc(doc(as(UID.childUser), 'trainings/t1'), { status: 'cancelled' }));
  });
});

describe('chat', () => {
  const msg = (uid, role, extra = {}) => ({
    senderId: uid, senderName: 'x', senderRole: role, text: 'hello', createdAt: serverTimestamp(), ...extra,
  });

  it('child account can never read or write chat', async () => {
    const db = as(UID.childUser);
    await assertFails(getDoc(doc(db, 'chats/g1/messages/m1')));
    await assertFails(getDocs(collection(db, 'chats/g1/messages')));
    await assertFails(addDoc(collection(db, 'chats/g1/messages'), msg(UID.childUser, 'child')));
  });

  it('group parents and the group coach can read and post', async () => {
    await assertSucceeds(getDocs(collection(as(UID.parentB), 'chats/g1/messages')));
    await assertSucceeds(getDocs(collection(as(UID.coach), 'chats/g1/messages')));
    await assertSucceeds(addDoc(collection(as(UID.parentB), 'chats/g1/messages'), msg(UID.parentB, 'parent')));
    await assertSucceeds(addDoc(collection(as(UID.coach), 'chats/g1/messages'), msg(UID.coach, 'coach')));
  });

  it('outsiders and unapproved coaches cannot read the chat', async () => {
    await assertFails(getDocs(collection(as(UID.coachOther), 'chats/g1/messages')));
    await assertFails(getDocs(collection(as(UID.coachPending), 'chats/g1/messages')));
  });

  it('senderId must be the caller and senderRole must match', async () => {
    await assertFails(addDoc(collection(as(UID.parentB), 'chats/g1/messages'), msg(UID.parentA, 'parent')));
    await assertFails(addDoc(collection(as(UID.parentB), 'chats/g1/messages'), msg(UID.parentB, 'coach')));
  });

  it('messages are immutable; only the sender may delete', async () => {
    await assertFails(updateDoc(doc(as(UID.parentA), 'chats/g1/messages/m1'), { text: 'edited' }));
    await assertFails(deleteDoc(doc(as(UID.parentB), 'chats/g1/messages/m1')));
    await assertSucceeds(deleteDoc(doc(as(UID.parentA), 'chats/g1/messages/m1')));
  });
});

describe('medical certificates (metadata)', () => {
  const cert = (extra = {}) => ({
    childId: 'childA1', uploadedBy: UID.parentA, storagePath: 'medical/childA1/c2',
    issuedAt: ts('2026-10-01T00:00:00Z'), validUntil: ts('2027-10-01T00:00:00Z'),
    consentAt: now, status: 'valid', ...extra,
  });

  it('readable by the child\'s parents and approved coaches of the child\'s group', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'medicalCertificates/cert1')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(as(UID.coachPending), 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(as(UID.childUser), 'medicalCertificates/cert1')));
  });

  it('create only by a parent of the child, with consentAt and a matching storagePath', async () => {
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'medicalCertificates/c2'), cert()));
    await assertFails(setDoc(doc(as(UID.parentA), 'medicalCertificates/c3'), cert({ storagePath: 'medical/childA1/c3', consentAt: null })));
    await assertFails(setDoc(doc(as(UID.parentB), 'medicalCertificates/c4'), cert({ uploadedBy: UID.parentB, storagePath: 'medical/childA1/c4' })));
    await assertFails(setDoc(doc(as(UID.parentA), 'medicalCertificates/c5'), cert({ storagePath: 'medical/childB1/c5' })));
  });

  it('delete only by parent; nobody updates from client', async () => {
    await assertFails(updateDoc(doc(as(UID.parentA), 'medicalCertificates/cert1'), { status: 'valid' }));
    await assertFails(deleteDoc(doc(as(UID.coach), 'medicalCertificates/cert1')));
    await assertSucceeds(deleteDoc(doc(as(UID.parentA), 'medicalCertificates/cert1')));
  });

  it('certificateAccessLog and smsLog: admin read only', async () => {
    await assertFails(getDoc(doc(as(UID.parentA), 'certificateAccessLog/l1')));
    await assertFails(getDoc(doc(as(UID.coach), 'smsLog/s1')));
    await assertSucceeds(getDoc(doc(as(UID.admin, { admin: true }), 'smsLog/s1')));
    await assertSucceeds(getDoc(doc(as(UID.admin, { admin: true }), 'certificateAccessLog/l1')));
    await assertFails(setDoc(doc(as(UID.admin, { admin: true }), 'smsLog/s2'), { x: 1 }));
  });
});

describe('payments', () => {
  it('parent reads own payments only', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'payments/p1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'payments/p1')));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'payments'), where('parentId', '==', UID.parentA))));
  });

  it('coach of the group may update only status/paidAt', async () => {
    const db = as(UID.coach);
    await assertSucceeds(updateDoc(doc(db, 'payments/p1'), { status: 'paid', paidAt: now }));
    await assertFails(updateDoc(doc(db, 'payments/p1'), { amount: 1 }));
    await assertFails(updateDoc(doc(db, 'payments/p1'), { status: 'paid', amount: 1 }));
    await assertFails(updateDoc(doc(db, 'payments/p1'), { status: 'refunded' }));
  });

  it('other coaches and parents cannot update; nobody but admin creates', async () => {
    await assertFails(updateDoc(doc(as(UID.coachOther), 'payments/p1'), { status: 'paid' }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'payments/p1'), { status: 'paid' }));
    const p = { childId: 'childA1', parentId: UID.parentA, groupId: 'g1', sportId: 'football', amount: 10, currency: 'GEL', dueDate: now, status: 'pending' };
    await assertFails(setDoc(doc(as(UID.coach), 'payments/p2'), p));
    await assertFails(setDoc(doc(as(UID.parentA), 'payments/p3'), p));
    await assertSucceeds(setDoc(doc(as(UID.admin, { admin: true }), 'payments/p4'), p));
  });
});

describe('membership requests', () => {
  it('parent requests membership for own child only', async () => {
    const base = { parentId: UID.parentA, clubId: 'club1', status: 'pending', createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'membershipRequests/r1'), { ...base, childId: 'childA1' }));
    await assertFails(setDoc(doc(as(UID.parentA), 'membershipRequests/r2'), { ...base, childId: 'childB1' }));
    await assertFails(setDoc(doc(as(UID.parentA), 'membershipRequests/r3'), { ...base, childId: 'childA1', status: 'approved' }));
  });

  it('club coach approves into own group only', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'membershipRequests/r9'), {
      parentId: UID.parentB, childId: 'childB1', clubId: 'club1', status: 'pending', createdAt: now,
    }));
    await assertFails(updateDoc(doc(as(UID.coachOther), 'membershipRequests/r9'), { status: 'approved', groupId: 'g2' }));
    await assertFails(updateDoc(doc(as(UID.coach), 'membershipRequests/r9'), { status: 'approved', groupId: 'g2' }));
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'membershipRequests/r9'), { status: 'approved', groupId: 'g1' }));
  });
});
