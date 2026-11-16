// v1.7 multi-tenant rules: tenant isolation, feature flags, schedule
// versions, RSVP/attendance for matches, consents, coach contact, storage.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection, collectionGroup, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';
import { ref, uploadBytes, getBytes } from 'firebase/storage';
import { CLAIMS, UID, createEnv, now, seed, seedV12, ts } from './setup.js';

let env;
beforeAll(async () => {
  env = await createEnv();
});

const STANDARD = ['trainings', 'matches', 'attendance', 'communication', 'notifications', 'studentAccounts',
  'brainAcademy', 'trainingPlans', 'payments', 'medicalCertificates', 'media'];

async function seedV17(extra = async () => {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, d) => setDoc(doc(db, p), d);
    await put('orgConfigs/club1', {
      status: 'active', plan: 'premium', allowedModules: [...STANDARD, 'roomScheduling', 'leaderboards'],
      enabledModules: [...STANDARD, 'roomScheduling', 'leaderboards'], branding: { names: { ka: 'Club 1' } },
    });
    await put('orgConfigs/club2', { status: 'active', plan: 'standard', allowedModules: STANDARD, enabledModules: STANDARD });
    await put(`clubs/club1/orgMembers/${UID.coach}`, { orgId: 'club1', userId: UID.coach, roles: ['coach'], active: true });
    await put(`clubs/club1/orgMembers/${UID.parentA}`, { orgId: 'club1', userId: UID.parentA, roles: ['parent'], active: true });
    await put(`clubs/club2/orgMembers/${UID.coachOther}`, { orgId: 'club2', userId: UID.coachOther, roles: ['coach'], active: true });
    await put('clubs/club1/rooms/hallA', { orgId: 'club1', clubId: 'club1', name: 'Hall A', capacity: 30, status: 'active' });
    await put('clubs/club2/rooms/hallZ', { orgId: 'club2', clubId: 'club2', name: 'Hall Z', capacity: 30, status: 'active' });
    await put('clubs/club1/bookings/b1', { orgId: 'club1', roomId: 'hallA', kind: 'training', startAt: now, endAt: now, status: 'active' });
    await put('clubs/club2/bookings/bz', { orgId: 'club2', roomId: 'hallZ', kind: 'training', startAt: now, endAt: now, status: 'active' });
    await put('clubs/club1/programs/p1', { orgId: 'club1', name: 'Football', sportId: 'football' });
    await put('clubs/club1/leaderboardConsents/childA1', { orgId: 'club1', childId: 'childA1', guardianId: UID.parentA, granted: true, displayName: 'Swift Fox 11' });
    await put('clubs/club1/leaderboards/week', { entries: [] });
    await put('coachContactRequests/cr1', {
      childId: 'childA1', coachId: UID.coach, groupId: 'g1', topic: 'question', studentUid: UID.childUser,
      parentIds: [UID.parentA], status: 'open', handledBy: null, createdAt: now,
    });
    await put('matches/mFuture', {
      groupId: 'g1', clubId: 'club1', venueId: 'v1', startAt: ts('2030-06-02T10:00:00Z'), durationMin: 90, opponentName: 'Rivals',
      matchType: 'friendly', homeAway: 'home', status: 'scheduled', createdBy: UID.coach, updatedAt: now,
    });
    await put('matches/mPast', {
      groupId: 'g1', clubId: 'club1', venueId: 'v1', startAt: ts('2020-06-02T10:00:00Z'), durationMin: 90, opponentName: 'Old',
      matchType: 'friendly', homeAway: 'home', status: 'scheduled', createdBy: UID.coach, updatedAt: now,
    });
    await extra(db);
  });
}

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await seedV12(env);
  await seedV17();
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const anon = () => env.unauthenticatedContext().firestore();

function rsvp(over = {}) {
  return {
    trainingId: 'mFuture', eventId: 'mFuture', eventType: 'match', groupId: 'g1', childId: 'childA1', parentId: UID.parentA,
    response: 'yes', reason: null, updatedAt: serverTimestamp(), scheduleVersion: 1,
    guardianResponses: { [UID.parentA]: { response: 'yes', version: 1, at: serverTimestamp(), reason: null } },
    ...over,
  };
}

describe('tenant configuration (feature flags)', () => {
  it('signed-in users read config; nobody writes it from a client', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'orgConfigs/club1')));
    await assertFails(getDoc(doc(anon(), 'orgConfigs/club1')));
    // An organization admin cannot self-enable modules or change platform fields.
    await assertFails(updateDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'orgConfigs/club1'), { enabledModules: ['trainings'] }));
    await assertFails(updateDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'orgConfigs/club1'), { status: 'active', plan: 'premium' }));
    await assertFails(updateDoc(doc(as(UID.admin, CLAIMS.platform), 'orgConfigs/club2'), { allowedModules: STANDARD }));
  });
});

describe('cross-tenant isolation', () => {
  it('rooms, programs and bookings are readable only inside the tenant', async () => {
    await assertSucceeds(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'clubs/club1/bookings/b1')));
    await assertFails(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'clubs/club2/bookings/bz')));
    await assertFails(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'clubs/club2/rooms/hallZ')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'clubs/club1/bookings/b1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'clubs/club1/bookings/b1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'clubs/club1/rooms/hallA')));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'clubs/club1/rooms/hallA')));
    await assertFails(getDoc(doc(as(UID.parentA), 'clubs/club1/bookings/b1')), 'parents never read the room plan');
    await assertFails(getDoc(doc(as(UID.parentB), 'clubs/club1/programs/p1')), 'not a member');
    await assertSucceeds(getDoc(doc(as(UID.admin, CLAIMS.platform), 'clubs/club2/bookings/bz')));
  });

  it('bookings, rooms, programs, members and locks are written only by trusted code', async () => {
    const adminA = as(UID.clubAdminA, CLAIMS.clubA);
    await assertFails(setDoc(doc(adminA, 'clubs/club1/bookings/x'), { orgId: 'club1', roomId: 'hallA', status: 'active' }));
    await assertFails(setDoc(doc(adminA, 'clubs/club1/rooms/x'), { orgId: 'club1', name: 'X' }));
    await assertFails(setDoc(doc(adminA, 'clubs/club1/programs/x'), { orgId: 'club1', name: 'X' }));
    await assertFails(setDoc(doc(adminA, `clubs/club1/orgMembers/${UID.clubAdminA}`), { roles: ['admin'] }));
    await assertFails(setDoc(doc(adminA, 'clubs/club1/roomLocks/hallA_2030-06-01'), { v: 1 }));
    await assertFails(setDoc(doc(as(UID.clubAdminB, CLAIMS.clubB), 'clubs/club1/bookings/x'), { orgId: 'club1' }));
  });

  it('membership records: own only, plus the collection-group query for "my organizations"', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), `clubs/club1/orgMembers/${UID.parentA}`)));
    await assertFails(getDoc(doc(as(UID.parentA), `clubs/club1/orgMembers/${UID.coach}`)));
    await assertSucceeds(getDocs(query(collectionGroup(as(UID.parentA), 'orgMembers'), where('userId', '==', UID.parentA))));
    await assertFails(getDocs(collectionGroup(as(UID.parentA), 'orgMembers')));
    await assertSucceeds(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), `clubs/club1/orgMembers/${UID.coach}`)));
  });

  it('leaderboards are server-only; club admins of another club see nothing', async () => {
    await assertFails(getDoc(doc(as(UID.parentA), 'clubs/club1/leaderboards/week')));
    await assertFails(getDoc(doc(as(UID.clubAdminB, CLAIMS.clubB), 'clubs/club1/orgMembers/' + UID.coach)));
  });
});

describe('feature flags enforced by the rules', () => {
  it('a disabled module blocks creating trainings and matches; re-enabling allows it', async () => {
    const t = {
      groupId: 'g1', venueId: 'v1', startAt: ts('2030-07-01T10:00:00Z'), durationMin: 60, focus: ['ball'], description: '',
      photoUrls: [], status: 'scheduled', createdBy: UID.coach, updatedAt: now,
    };
    await assertSucceeds(setDoc(doc(as(UID.coach), 'trainings/newOk'), t));
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'orgConfigs/club1'), { enabledModules: ['matches'] }));
    await assertFails(setDoc(doc(as(UID.coach), 'trainings/newBlocked'), t));
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'orgConfigs/club1'), { enabledModules: STANDARD, status: 'suspended' }));
    await assertFails(setDoc(doc(as(UID.coach), 'trainings/newSuspended'), t), 'suspended organization');
    await assertFails(setDoc(doc(as(UID.coach), 'matches/mNew'), {
      groupId: 'g1', clubId: 'club1', venueId: 'v1', startAt: ts('2030-07-01T10:00:00Z'), durationMin: 90, opponentName: 'X',
      matchType: 'friendly', homeAway: 'home', status: 'scheduled', createdBy: UID.coach, updatedAt: now,
    }));
  });

  it('an allowed-but-not-enabled module stays off (feature flag bypass attempt)', async () => {
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'orgConfigs/club1'), {
      allowedModules: STANDARD.filter((m) => m !== 'attendance'), enabledModules: STANDARD,
    }));
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/mFuture_childA1'), rsvp()), 'enabled but not allowed');
  });
});

describe('event RSVP v1.7', () => {
  it('a parent answers for a match, own guardian entry only, current schedule version', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(setDoc(doc(db, 'rsvps/mFuture_childA1'), rsvp()));
    await assertFails(setDoc(doc(db, 'rsvps/mFuture_childA1'), rsvp({
      guardianResponses: { [UID.parentB]: { response: 'no', version: 1, at: serverTimestamp(), reason: null } },
    })), 'cannot write another guardian\'s answer');
    await assertFails(setDoc(doc(db, 'rsvps/mFuture_childA1'), rsvp({ scheduleVersion: 0 })), 'stale version');
    await assertFails(setDoc(doc(as(UID.parentB), 'rsvps/mFuture_childA1'), rsvp({ parentId: UID.parentB })), 'not their child');
    await assertFails(setDoc(doc(as(UID.childUser), 'rsvps/mFuture_childA1'), rsvp({ parentId: UID.childUser })), 'students do not RSVP');
  });

  it('answer + append-only history in one batch; history cannot be forged or edited', async () => {
    const db = as(UID.parentA);
    const b = writeBatch(db);
    b.set(doc(db, 'rsvps/mFuture_childA1'), rsvp());
    b.set(doc(db, 'rsvps/mFuture_childA1/history/h1'), { guardianId: UID.parentA, response: 'yes', version: 1, reason: null, at: serverTimestamp() });
    await assertSucceeds(b.commit());
    await assertFails(setDoc(doc(db, 'rsvps/mFuture_childA1/history/h2'), { guardianId: UID.parentB, response: 'no', version: 1, reason: null, at: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'rsvps/mFuture_childA1/history/h1'), { response: 'no' }));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'rsvps/mFuture_childA1/history/h1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'rsvps/mFuture_childA1/history/h1')));
  });

  it('a material reschedule must bump the version; nothing else may', async () => {
    const coach = as(UID.coach);
    await assertFails(updateDoc(doc(coach, 'trainings/tFuture'), { startAt: ts('2030-06-02T14:00:00Z') }));
    await assertSucceeds(updateDoc(doc(coach, 'trainings/tFuture'), { startAt: ts('2030-06-02T14:00:00Z'), scheduleVersion: 2, status: 'moved' }));
    await assertFails(updateDoc(doc(coach, 'trainings/tFuture'), { description: 'x', scheduleVersion: 3 }));
    await assertSucceeds(updateDoc(doc(coach, 'trainings/tFuture'), { description: 'x' }));
    // Now an RSVP for the old version is rejected; the new one is accepted.
    const parent = as(UID.parentA);
    const old = { trainingId: 'tFuture', eventId: 'tFuture', eventType: 'training', groupId: 'g1', childId: 'childA1', parentId: UID.parentA, response: 'no', reason: null, updatedAt: serverTimestamp(), scheduleVersion: 1, guardianResponses: { [UID.parentA]: { response: 'no', version: 1, at: serverTimestamp(), reason: null } } };
    await assertFails(setDoc(doc(parent, 'rsvps/tFuture_childA1'), old));
    await assertSucceeds(setDoc(doc(parent, 'rsvps/tFuture_childA1'), { ...old, scheduleVersion: 2, guardianResponses: { [UID.parentA]: { response: 'no', version: 2, at: serverTimestamp(), reason: null } } }));
    await assertSucceeds(updateDoc(doc(coach, 'matches/mFuture'), { venueId: 'v2', scheduleVersion: 2, previousVenueId: 'v1' }));
    await assertFails(updateDoc(doc(coach, 'matches/mFuture'), { venueId: 'v3' }));
  });

  it('room-linked trainings change time only through the booking callables', async () => {
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'trainings/tFuture'), { roomId: 'hallA' }));
    await assertFails(updateDoc(doc(as(UID.coach), 'trainings/tFuture'), { startAt: ts('2030-06-03T14:00:00Z'), scheduleVersion: 2 }));
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'trainings/tFuture'), { description: 'bring water' }));
  });
});

describe('attendance for matches and student visibility', () => {
  it('the coach marks match attendance; parents and other coaches cannot', async () => {
    const rec = { trainingId: 'mPast', eventId: 'mPast', eventType: 'match', groupId: 'g1', childId: 'childA1', status: 'present', markedBy: UID.coach, markedAt: now, note: null };
    await assertSucceeds(setDoc(doc(as(UID.coach), 'attendance/mPast_childA1'), rec));
    await assertFails(setDoc(doc(as(UID.parentA), 'attendance/mPast_childB1'), { ...rec, childId: 'childB1', markedBy: UID.parentA }));
    await assertFails(setDoc(doc(as(UID.coachOther), 'attendance/mPast_childB1'), { ...rec, childId: 'childB1', markedBy: UID.coachOther }));
    await assertFails(setDoc(doc(as(UID.coach), 'attendance/mPast_childA1'), { ...rec, eventType: 'training' }), 'event type must match');
  });

  it('a student reads only their own attendance', async () => {
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'attendance/tPast_childA1')));
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'attendance/tPast_childB1'), {
      trainingId: 'tPast', groupId: 'g1', childId: 'childB1', status: 'absent', markedBy: UID.coach, markedAt: now, note: null,
    }));
    await assertFails(getDoc(doc(as(UID.childUser), 'attendance/tPast_childB1')));
    await assertSucceeds(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'attendance/tPast_childB1')));
    await assertFails(getDoc(doc(as(UID.clubAdminB, CLAIMS.clubB), 'attendance/tPast_childB1')));
  });
});

describe('guardian consent and coach contact', () => {
  it('consents: guardians and the student read; nobody writes directly', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'clubs/club1/leaderboardConsents/childA1')));
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'clubs/club1/leaderboardConsents/childA1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'clubs/club1/leaderboardConsents/childA1')));
    await assertFails(getDoc(doc(as(UID.coach), 'clubs/club1/leaderboardConsents/childA1')));
    await assertFails(setDoc(doc(as(UID.parentA), 'clubs/club1/leaderboardConsents/childA1'), { granted: true }));
    await assertFails(setDoc(doc(as(UID.childUser), 'clubs/club1/leaderboardConsents/childA1'), { granted: true }));
  });

  it('coach contact: no client creates; guardian may only mark handled; no coach access', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'coachContactRequests/cr1')));
    await assertSucceeds(getDoc(doc(as(UID.childUser), 'coachContactRequests/cr1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'coachContactRequests/cr1')));
    await assertFails(getDoc(doc(as(UID.coach), 'coachContactRequests/cr1')));
    await assertFails(setDoc(doc(as(UID.childUser), 'coachContactRequests/cr2'), { childId: 'childA1', coachId: UID.coach, parentIds: [UID.parentA] }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'coachContactRequests/cr1'), { status: 'handled', handledBy: UID.parentA, coachId: 'x' }));
    await assertFails(updateDoc(doc(as(UID.childUser), 'coachContactRequests/cr1'), { status: 'handled', handledBy: UID.childUser }));
    await assertSucceeds(updateDoc(doc(as(UID.parentA), 'coachContactRequests/cr1'), { status: 'handled', handledBy: UID.parentA }));
  });

  it('students still cannot read group chats (child-account restriction kept)', async () => {
    await assertFails(getDocs(collection(as(UID.childUser), 'chats/g1/messages')));
  });
});

describe('Brain Academy results (idempotent, create-only)', () => {
  it('the linked student creates once with a client id; a retry cannot overwrite', async () => {
    const db = as(UID.childUser);
    const r = {
      childId: 'childA1', game: 'logicQuest', difficulty: 'easy', level: 1, score: 100, accuracy: 0.9, attempts: 5,
      durationMs: 30000, completed: true, playedAt: serverTimestamp(), detail: {}, clientPlayedAt: '2026-11-16T10:00:00.000Z',
    };
    await assertSucceeds(setDoc(doc(db, 'brainResults/r-client-1'), r));
    await assertFails(setDoc(doc(db, 'brainResults/r-client-1'), { ...r, score: 99999 }));
    await assertFails(setDoc(doc(db, 'brainResults/r-client-2'), { ...r, totalPoints: 5000 }), 'no client totals');
    await assertFails(setDoc(doc(as(UID.parentA), 'brainResults/r-client-3'), r), 'only the student');
  });
});

describe('storage: tenant branding files', () => {
  const st = (uid, claims) => env.authenticatedContext(uid, claims).storage();
  const png = new Uint8Array([137, 80, 78, 71]);

  it('only admins of that organization upload its logo; anyone may read', async () => {
    await assertSucceeds(uploadBytes(ref(st(UID.clubAdminA, CLAIMS.clubA), 'orgs/club1/branding/logo.png'), png, { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(st(UID.clubAdminB, CLAIMS.clubB), 'orgs/club1/branding/logo.png'), png, { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(st(UID.coach), 'orgs/club1/branding/logo.png'), png, { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(st(UID.clubAdminA, CLAIMS.clubA), 'orgs/club1/branding/x.exe'), png, { contentType: 'application/octet-stream' }));
    await assertFails(uploadBytes(ref(st(UID.clubAdminA, CLAIMS.clubA), 'orgs/club1/private/data.png'), png, { contentType: 'image/png' }));
    await assertSucceeds(getBytes(ref(env.unauthenticatedContext().storage(), 'orgs/club1/branding/logo.png')));
  });
});
