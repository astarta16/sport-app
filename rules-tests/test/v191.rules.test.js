// v1.9.1 rules: organization admins manage groups only through callables;
// invitations of their own organization are readable; cross-tenant denied.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { CLAIMS, UID, createEnv, now, seed, seedV12 } from './setup.js';

let env;
beforeAll(async () => {
  env = await createEnv();
});
afterAll(async () => {
  await env?.cleanup();
});
beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await seedV12(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'invites/i1'), { groupId: 'g1', clubId: 'club1', status: 'sent', childFirstName: 'Ana', phone: '+995*', createdBy: UID.clubAdminA, createdAt: now });
    await setDoc(doc(db, 'invites/i2'), { groupId: 'g2', clubId: 'club2', status: 'sent', childFirstName: 'Bo', phone: '+995*', createdBy: UID.clubAdminB, createdAt: now });
  });
});
const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const groupDoc = (o = {}) => ({
  clubId: 'club1', sportId: 'football', coachIds: [UID.coach], name: 'U-9', ageMin: 7, ageMax: 9,
  memberChildIds: [], parentIds: [], createdBy: UID.coach, status: 'active', inviteCode: '', ...o,
});

describe('groups', () => {
  it('organization admins do not write groups directly (only via audited callables)', async () => {
    const db = as(UID.clubAdminA, CLAIMS.clubA);
    await assertFails(setDoc(doc(db, 'groups/new1'), groupDoc({ createdBy: UID.clubAdminA })));
    await assertFails(updateDoc(doc(db, 'groups/g1'), { name: 'renamed' }));
    await assertFails(updateDoc(doc(db, 'groups/g1'), { memberChildIds: [] }));
  });

  it('organization admin of another club cannot read or write the group', async () => {
    const db = as(UID.clubAdminB, CLAIMS.clubB);
    await assertFails(getDoc(doc(db, 'groups/g1')));
    await assertFails(updateDoc(doc(db, 'groups/g1'), { name: 'x' }));
  });

  it('coach direct create keeps working; optional capacity must be 1..500', async () => {
    const db = as(UID.coach);
    await assertSucceeds(setDoc(doc(db, 'groups/c1'), groupDoc({ capacity: 12 })));
    await assertFails(setDoc(doc(db, 'groups/c2'), groupDoc({ capacity: 0 })));
    await assertFails(setDoc(doc(db, 'groups/c3'), groupDoc({ capacity: 'many' })));
    await assertFails(setDoc(doc(db, 'groups/c4'), groupDoc({ clubId: 'club2' })), 'not the coach\'s club');
  });

  it('unauthenticated writes are denied', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, 'groups/u1'), groupDoc()));
  });
});

describe('invitations', () => {
  it('readable by the admin of the invitation\'s organization only', async () => {
    await assertSucceeds(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'invites/i1')));
    await assertFails(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'invites/i2')));
    await assertFails(getDoc(doc(as(UID.parentB), 'invites/i1')));
  });

  it('nobody writes invitations from a client (server creates them)', async () => {
    await assertFails(setDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'invites/i3'), { groupId: 'g1', clubId: 'club1', status: 'sent' }));
    await assertFails(updateDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'invites/i1'), { status: 'accepted' }));
  });
});

describe('child records stay private from organization admins', () => {
  it('an organization admin cannot read a child record directly', async () => {
    await assertFails(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'children/childA1')));
  });
  it('medical certificates are not readable by an organization admin', async () => {
    await assertFails(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'medicalCertificates/cert1')));
  });
});
