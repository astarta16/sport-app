// v1.1 + v1.2 security-rules tests (Firestore + Storage). Attack scenarios
// are one test each; positive cases prove the happy paths still work.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  addDoc, collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where,
} from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';
import { CLAIMS, UID, createEnv, now, seed, seedV12, ts } from './setup.js';

let env;

beforeAll(async () => {
  env = await createEnv();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seed(env);
  await seedV12(env);
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const st = (uid, claims) => env.authenticatedContext(uid, claims).storage();
const bytes = (n = 16) => new Uint8Array(n);
const admin = () => as(UID.admin, CLAIMS.platform);

const rsvp = (o = {}) => ({
  trainingId: 'tFuture', groupId: 'g1', childId: 'childA1', parentId: UID.parentA, response: 'yes', reason: null, updatedAt: now, ...o,
});
const mark = (o = {}) => ({
  trainingId: 'tFuture', groupId: 'g1', childId: 'childA1', status: 'present', markedBy: UID.coach, markedAt: now, note: null, ...o,
});
const post = (o = {}) => ({
  coachId: UID.coach, coachName: 'coach', groupIds: ['g1'], clubId: 'club1', type: 'photo',
  storagePath: `media/${UID.coach}/mp2/a.jpg`, thumbPath: null, caption: null, durationSec: null,
  createdAt: now, consentConfirmed: true, ...o,
});
const msg = (uid, role, extra = {}) => ({
  senderId: uid, senderName: 'x', senderRole: role, text: 'hello', createdAt: serverTimestamp(), type: 'text', pinned: false, ...extra,
});

// ------------------------------------------------------------------ attacks
describe('attack scenarios', () => {
  it('another parent cannot read a child', async () => {
    await assertFails(getDoc(doc(as(UID.parentB), 'children/childA1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'children/childB1')));
  });

  it('coach of another group cannot read a child, a training or attendance', async () => {
    const db = as(UID.coachOther);
    await assertFails(getDoc(doc(db, 'children/childA1')));
    await assertFails(getDoc(doc(db, 'trainings/tFuture')));
    await assertFails(getDoc(doc(db, 'attendance/tPast_childA1')));
    await assertFails(getDocs(query(collection(db, 'attendance'), where('groupId', '==', 'g1'))));
  });

  it('medical certificate metadata is not readable without access', async () => {
    await assertFails(getDoc(doc(as(UID.parentB), 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(as(UID.coachSuspended), 'medicalCertificates/cert1')));
    await assertFails(getDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'medicalCertificates/cert1')));
    await assertFails(getBytes(ref(st(UID.parentA), 'medical/childA1/cert1')));
  });

  it('coach cannot create a media post without consentConfirmed (nor upload without a post)', async () => {
    const db = as(UID.coach);
    await assertFails(setDoc(doc(db, 'mediaPosts/mp2'), post({ consentConfirmed: false })));
    const { consentConfirmed, ...noConsent } = post();
    await assertFails(setDoc(doc(db, 'mediaPosts/mp2'), noConsent));
    await assertFails(uploadBytes(ref(st(UID.coach), `media/${UID.coach}/mp2/a.jpg`), bytes(), { contentType: 'image/jpeg' }));
  });

  it('parent cannot modify a payment', async () => {
    const db = as(UID.parentA);
    await assertFails(updateDoc(doc(db, 'payments/p1'), { status: 'paid' }));
    await assertFails(updateDoc(doc(db, 'payments/p1'), { cancelledReason: 'x' }));
    await assertFails(deleteDoc(doc(db, 'payments/p1')));
  });

  it('user cannot self-assign coachStatus approved, role admin or adminRole', async () => {
    const base = { firstName: 'N', lastName: 'U', phone: '+995599111111', createdAt: serverTimestamp(), dataConsentAt: serverTimestamp(), fcmTokens: [] };
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), { ...base, role: 'coach', coachStatus: 'approved' }));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), { ...base, role: 'admin' }));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), { ...base, role: 'parent', adminRole: 'platform' }));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), { ...base, role: 'parent', adminClubIds: ['club1'] }));
    await assertFails(updateDoc(doc(as(UID.coachSuspended), `users/${UID.coachSuspended}`), { coachStatus: 'approved' }));
    await assertFails(updateDoc(doc(as(UID.parentA), `users/${UID.parentA}`), { role: 'admin' }));
    await assertFails(updateDoc(doc(as(UID.parentA), `users/${UID.parentA}`), { adminRole: 'platform' }));
    await assertFails(updateDoc(doc(as(UID.parentA), `users/${UID.parentA}`), { adminClubIds: ['club1'] }));
    await assertFails(updateDoc(doc(as(UID.coachPending), `users/${UID.coachPending}`), { coachStatusReason: 'ok now' }));
  });

  it('suspended coach cannot read group data', async () => {
    const db = as(UID.coachSuspended);
    await assertFails(getDoc(doc(db, 'groups/g1')));
    await assertFails(getDoc(doc(db, 'trainings/tFuture')));
    await assertFails(getDoc(doc(db, 'children/childA1')));
    await assertFails(getDocs(collection(db, 'chats/g1/messages')));
    await assertFails(getDoc(doc(db, 'matches/mt1')));
    await assertFails(getDoc(doc(db, 'mediaPosts/mp1')));
    await assertFails(getDoc(doc(db, 'attendance/tPast_childA1')));
    await assertFails(getBytes(ref(st(UID.coachSuspended), 'trainingPhotos/g1/photo1.jpg')));
    await assertFails(getBytes(ref(st(UID.coachSuspended), `media/${UID.coach}/mp1/a.jpg`)));
  });

  it('non-admins cannot read auditLog or other people\'s reports', async () => {
    await assertFails(getDoc(doc(as(UID.parentA), 'auditLog/a1')));
    await assertFails(getDoc(doc(as(UID.coach), 'auditLog/a1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'reports/r1')));
    await assertFails(getDoc(doc(as(UID.coach), 'reports/r1')));
    await assertSucceeds(getDoc(doc(as(UID.parentB), 'reports/r1'))); // own report
    await assertSucceeds(getDoc(doc(admin(), 'auditLog/a2')));
  });

  it('club admin of club A cannot read audit / reports / payment audit of club B', async () => {
    const db = as(UID.clubAdminA, CLAIMS.clubA);
    await assertSucceeds(getDoc(doc(db, 'auditLog/a1')));
    await assertSucceeds(getDoc(doc(db, 'reports/r1')));
    await assertSucceeds(getDoc(doc(db, 'paymentAudit/pa1')));
    await assertFails(getDoc(doc(db, 'auditLog/a2')));
    await assertFails(getDoc(doc(db, 'reports/r2')));
    await assertFails(getDoc(doc(as(UID.clubAdminB, CLAIMS.clubB), 'paymentAudit/pa1')));
    await assertSucceeds(getDocs(query(collection(db, 'auditLog'), where('clubId', '==', 'club1'))));
    await assertFails(getDocs(query(collection(db, 'auditLog'), where('clubId', '==', 'club2'))));
  });

  it('parent cannot write attendance', async () => {
    await assertFails(setDoc(doc(as(UID.parentA), 'attendance/tFuture_childA1'), mark({ markedBy: UID.parentA })));
    await assertFails(updateDoc(doc(as(UID.parentA), 'attendance/tPast_childA1'), { status: 'excused' }));
    await assertFails(deleteDoc(doc(as(UID.parentA), 'attendance/tPast_childA1')));
  });

  it('parent cannot RSVP for someone else\'s child', async () => {
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/tFuture_childB1'), rsvp({ childId: 'childB1' })));
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/tFuture_childB1'), rsvp({ childId: 'childB1', parentId: UID.parentB })));
    await assertFails(updateDoc(doc(as(UID.parentA), 'rsvps/tFuture_childB1'), { response: 'no', parentId: UID.parentA }));
  });

  it('parent cannot RSVP after the training started', async () => {
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/tPast_childA1'), rsvp({ trainingId: 'tPast' })));
  });

  it('coach of another group cannot write attendance', async () => {
    await assertFails(setDoc(doc(as(UID.coachOther), 'attendance/tFuture_childA1'), mark({ markedBy: UID.coachOther })));
    await assertFails(setDoc(doc(as(UID.coachOther), 'attendance/tFuture_childA1'), mark({ markedBy: UID.coachOther, groupId: 'g2' })));
    await assertFails(setDoc(doc(as(UID.coachSuspended), 'attendance/tFuture_childA1'), mark({ markedBy: UID.coachSuspended })));
  });

  it('cancelling a training requires a code and a 5–300 char reason', async () => {
    const db = as(UID.coach);
    await assertFails(updateDoc(doc(db, 'trainings/tFuture'), { status: 'cancelled' }));
    await assertFails(updateDoc(doc(db, 'trainings/tFuture'), { status: 'cancelled', cancelReasonCode: 'weather', cancelReason: 'rain', cancelledBy: UID.coach }));
    await assertFails(updateDoc(doc(db, 'trainings/tFuture'), { status: 'cancelled', cancelReasonCode: 'holiday', cancelReason: 'Public holiday', cancelledBy: UID.coach }));
    await assertFails(updateDoc(doc(db, 'trainings/tFuture'), { status: 'cancelled', cancelReasonCode: 'weather', cancelReason: 'Heavy rain', cancelledBy: UID.coachOther }));
    await assertSucceeds(updateDoc(doc(db, 'trainings/tFuture'), { status: 'cancelled', cancelReasonCode: 'weather', cancelReason: 'Heavy rain', cancelledBy: UID.coach, cancelledAt: now }));
  });

  it('cancelling a match follows the same reason rule', async () => {
    const db = as(UID.coach);
    await assertFails(updateDoc(doc(db, 'matches/mt1'), { status: 'cancelled', cancelReasonCode: 'other', cancelReason: 'nah', cancelledBy: UID.coach }));
    await assertSucceeds(updateDoc(doc(db, 'matches/mt1'), { status: 'cancelled', cancelReasonCode: 'other', cancelReason: 'Opponent withdrew', cancelledBy: UID.coach }));
  });

  it('no client can write a system chat message', async () => {
    await assertFails(addDoc(collection(as(UID.coach), 'chats/g1/messages'), msg(UID.coach, 'coach', { type: 'system' })));
    await assertFails(addDoc(collection(as(UID.parentA), 'chats/g1/messages'), msg(UID.parentA, 'parent', { type: 'system' })));
    await assertFails(addDoc(collection(as(UID.coach), 'chats/g1/messages'), msg('system', 'system', { type: 'system' })));
  });

  it('parent cannot write an announcement or a pinned / hidden message', async () => {
    const col = collection(as(UID.parentA), 'chats/g1/messages');
    await assertFails(addDoc(col, msg(UID.parentA, 'parent', { type: 'announcement' })));
    await assertFails(addDoc(col, msg(UID.parentA, 'parent', { pinned: true })));
    await assertFails(addDoc(col, msg(UID.parentA, 'parent', { hidden: true })));
    await assertFails(addDoc(col, msg(UID.parentA, 'parent', { reportCount: 0 })));
    await assertFails(updateDoc(doc(as(UID.parentA), 'chats/g1/messages/m1'), { pinned: true }));
    await assertSucceeds(addDoc(collection(as(UID.coach), 'chats/g1/messages'), msg(UID.coach, 'coach', { type: 'announcement', pinned: true })));
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'chats/g1/messages/m1'), { pinned: true }));
    await assertFails(updateDoc(doc(as(UID.coach), 'chats/g1/messages/m1'), { text: 'edited', pinned: true }));
  });

  it('private media and training photos become unreadable after the child is removed from the group', async () => {
    // Before: parentB (childB1 in g1) can read.
    await assertSucceeds(getDoc(doc(as(UID.parentB), 'mediaPosts/mp1')));
    await assertSucceeds(getBytes(ref(st(UID.parentB), `media/${UID.coach}/mp1/a.jpg`)));
    await assertSucceeds(getBytes(ref(st(UID.parentB), 'trainingPhotos/g1/photo1.jpg')));
    // Coach removes childB1; simulate what onGroupWritten does (parentIds, readerIds).
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'groups/g1'), { memberChildIds: ['childA1'] }));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'groups/g1'), { parentIds: [UID.parentA] });
      await updateDoc(doc(ctx.firestore(), 'mediaPosts/mp1'), { readerIds: [UID.coach, UID.coachSuspended, UID.parentA] });
    });
    await assertFails(getDoc(doc(as(UID.parentB), 'mediaPosts/mp1')));
    await assertFails(getBytes(ref(st(UID.parentB), `media/${UID.coach}/mp1/a.jpg`)));
    await assertFails(getBytes(ref(st(UID.parentB), 'trainingPhotos/g1/photo1.jpg')));
    await assertSucceeds(getBytes(ref(st(UID.parentA), `media/${UID.coach}/mp1/a.jpg`)));
  });

  it('notification owner may only flip read false -> true', async () => {
    const db = as(UID.parentA);
    await assertFails(updateDoc(doc(db, 'notifications/n1'), { title: 'hacked' }));
    await assertFails(updateDoc(doc(db, 'notifications/n1'), { read: true, title: 'x' }));
    await assertFails(updateDoc(doc(db, 'notifications/n1'), { userId: UID.parentB }));
    await assertFails(updateDoc(doc(as(UID.parentB), 'notifications/n1'), { read: true }));
    await assertFails(setDoc(doc(db, 'notifications/n2'), { userId: UID.parentA, read: false }));
    await assertFails(deleteDoc(doc(db, 'notifications/n1')));
    await assertSucceeds(updateDoc(doc(db, 'notifications/n1'), { read: true }));
    await assertFails(updateDoc(doc(db, 'notifications/n1'), { read: false }));
  });

  it('child account cannot access chat, read receipts or unread counters', async () => {
    const db = as(UID.childUser);
    await assertFails(getDocs(collection(db, 'chats/g1/messages')));
    await assertFails(addDoc(collection(db, 'chats/g1/messages'), msg(UID.childUser, 'child')));
    await assertFails(setDoc(doc(db, `chats/g1/members/${UID.childUser}`), { lastReadAt: now }));
    await assertFails(getBytes(ref(st(UID.childUser), 'chatAttachments/g1/m1/a.jpg')));
  });
});

// ---------------------------------------------------------------- positives
describe('roles, claims and admin scope', () => {
  it('club admin reads groups/trainings/matches/series/coach users of their club only', async () => {
    const db = as(UID.clubAdminA, CLAIMS.clubA);
    await assertSucceeds(getDoc(doc(db, 'groups/g1')));
    await assertFails(getDoc(doc(db, 'groups/g2')));
    await assertSucceeds(getDoc(doc(db, 'trainings/tFuture')));
    await assertFails(getDoc(doc(db, 'trainings/tOther')));
    await assertSucceeds(getDoc(doc(db, 'matches/mt1')));
    await assertSucceeds(getDoc(doc(db, 'trainingSeries/s1')));
    await assertSucceeds(getDoc(doc(db, `users/${UID.coach}`)));
    await assertFails(getDoc(doc(db, `users/${UID.coachOther}`)));
    await assertFails(getDoc(doc(db, `users/${UID.parentA}`)));
    await assertFails(getDoc(doc(db, 'children/childA1'))); // no direct child access
  });

  it('club admin edits club details but not adminIds/status; only platform creates clubs/sports', async () => {
    const db = as(UID.clubAdminA, CLAIMS.clubA);
    await assertSucceeds(updateDoc(doc(db, 'clubs/club1'), { address: 'Rustaveli 1' }));
    await assertFails(updateDoc(doc(db, 'clubs/club1'), { status: 'archived' }));
    await assertFails(updateDoc(doc(db, 'clubs/club1'), { adminIds: [UID.clubAdminA] }));
    await assertFails(updateDoc(doc(db, 'clubs/club2'), { address: 'x' }));
    await assertFails(setDoc(doc(db, 'clubs/new'), { name: 'x' }));
    await assertFails(setDoc(doc(db, 'sports/mma'), { name: 'MMA' }));
    await assertSucceeds(setDoc(doc(admin(), 'sports/mma'), { name: 'MMA', icon: 'mma', category: 'combat', ageMin: 12, requiresMedicalCert: true, active: true, order: 5 }));
  });

  it('users may set photoPath (own avatar path only) and privacy', async () => {
    const db = as(UID.parentA);
    await assertSucceeds(updateDoc(doc(db, `users/${UID.parentA}`), { photoPath: `profiles/${UID.parentA}/avatar.jpg`, privacy: { profilePhotoVisible: true, analyticsConsent: false } }));
    await assertFails(updateDoc(doc(db, `users/${UID.parentA}`), { photoPath: `profiles/${UID.parentB}/avatar.jpg` }));
    await assertFails(updateDoc(doc(db, `users/${UID.parentA}`), { privacy: { evil: true } }));
    await assertSucceeds(updateDoc(doc(db, `users/${UID.parentA}`), { notificationPrefs: { newMatch: false, scheduleChanged: true } }));
  });
});

describe('groups, children, invites', () => {
  const group = (o = {}) => ({
    clubId: 'club1', sportId: 'football', coachIds: [UID.coach], name: 'U14', ageMin: 12, ageMax: 14,
    memberChildIds: [], parentIds: [], scheduleNote: null, inviteCode: '', createdBy: UID.coach, status: 'active', ...o,
  });

  it('approved coach creates a group in own club without invite code; others cannot', async () => {
    await assertSucceeds(setDoc(doc(as(UID.coach), 'groups/new1'), group()));
    await assertFails(setDoc(doc(as(UID.coach), 'groups/new2'), group({ inviteCode: 'ZZZZ22' })));
    await assertFails(setDoc(doc(as(UID.coach), 'groups/new3'), group({ clubId: 'club2' })));
    await assertFails(setDoc(doc(as(UID.coach), 'groups/new4'), group({ coachIds: [UID.coachOther] })));
    await assertFails(setDoc(doc(as(UID.coach), 'groups/new5'), group({ memberChildIds: ['childB1'] })));
    await assertFails(setDoc(doc(as(UID.coachPending), 'groups/new6'), group({ coachIds: [UID.coachPending], createdBy: UID.coachPending })));
    await assertFails(updateDoc(doc(admin(), 'groups/g1'), { inviteCode: 'ZZZZ22' }));
    await assertFails(getDoc(doc(as(UID.parentA), 'groupCodes/ABCD23')));
  });

  it('children: pending child visible to its creating coach only; parents cannot forge status', async () => {
    await assertSucceeds(getDoc(doc(as(UID.coach), 'children/pend1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'children/pend1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'children/pend1')));
    const c = { firstName: 'L', lastName: 'A', birthDate: ts('2015-05-05T00:00:00Z'), parentIds: [UID.parentA], userId: null, sportIds: [], groupIds: [], photoConsent: true, mediaConsent: true, mediaConsentAt: now, status: 'active', createdByCoachId: null, photoPath: null };
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'children/n1'), c));
    await assertFails(setDoc(doc(as(UID.parentA), 'children/n2'), { ...c, status: 'pendingParent' }));
    await assertFails(setDoc(doc(as(UID.parentA), 'children/n3'), { ...c, createdByCoachId: UID.coach }));
    await assertSucceeds(updateDoc(doc(as(UID.parentA), 'children/childA1'), { photoConsent: false, mediaConsent: false, mediaConsentAt: now, photoPath: 'childPhotos/childA1/avatar.jpg' }));
    await assertFails(updateDoc(doc(as(UID.parentA), 'children/childA1'), { photoPath: 'childPhotos/childB1/avatar.jpg' }));
  });

  it('invites: addressed parent and group coaches read; nobody writes', async () => {
    await assertSucceeds(getDoc(doc(as(UID.parentB), 'invites/i1')));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'invites/i1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'invites/i1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'invites/i1')));
    await assertFails(updateDoc(doc(as(UID.parentB), 'invites/i1'), { status: 'accepted' }));
    await assertFails(setDoc(doc(as(UID.coach), 'invites/i2'), { groupId: 'g1', status: 'sent' }));
    await assertSucceeds(getDocs(query(collection(as(UID.parentB), 'invites'), where('parentId', '==', UID.parentB))));
  });

  it('membership request with source', async () => {
    const base = { parentId: UID.parentA, childId: 'childA1', clubId: 'club1', status: 'pending', createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'membershipRequests/q1'), { ...base, source: 'request' }));
    await assertFails(setDoc(doc(as(UID.parentA), 'membershipRequests/q2'), { ...base, source: 'admin' }));
  });
});

describe('RSVP, attendance, feedback', () => {
  it('parent RSVPs for own member child before start; coach and parent read', async () => {
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'rsvps/tFuture_childA1'), rsvp()));
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'rsvps/tFuture_childA1'), rsvp({ response: 'no', reason: 'ავადაა' })));
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/tFuture_childA1'), rsvp({ reason: 'x'.repeat(201) })));
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/wrongId'), rsvp()));
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/tFuture_childA1'), rsvp({ response: 'definitely' })));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'rsvps/tFuture_childB1')));
    await assertSucceeds(getDocs(query(collection(as(UID.coach), 'rsvps'), where('trainingId', '==', 'tFuture'))));
    await assertSucceeds(getDocs(query(collection(as(UID.parentB), 'rsvps'), where('childId', '==', 'childB1'))));
    await assertFails(getDoc(doc(as(UID.parentA), 'rsvps/tFuture_childB1')));
  });

  it('RSVP for a child that is not in the training\'s group fails', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'children/childA2'), {
      firstName: 'X', lastName: 'A', birthDate: ts('2015-01-01T00:00:00Z'), parentIds: [UID.parentA], groupIds: [], coachIds: [],
    }));
    await assertFails(setDoc(doc(as(UID.parentA), 'rsvps/tFuture_childA2'), rsvp({ childId: 'childA2' })));
  });

  it('approved coach of the group marks attendance (and unmarks); parent of child reads', async () => {
    await assertSucceeds(setDoc(doc(as(UID.coach), 'attendance/tFuture_childA1'), mark()));
    await assertFails(setDoc(doc(as(UID.coach), 'attendance/tFuture_childA1'), mark({ markedBy: UID.coachOther })));
    await assertFails(setDoc(doc(as(UID.coach), 'attendance/tFuture_childA1'), mark({ status: 'late' })));
    await assertFails(setDoc(doc(as(UID.coach), 'attendance/tOther_childA1'), mark({ trainingId: 'tOther', groupId: 'g2' })));
    await assertSucceeds(deleteDoc(doc(as(UID.coach), 'attendance/tFuture_childA1')));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'attendance/tPast_childA1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'attendance/tPast_childA1')));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'attendance'), where('childId', '==', 'childA1'))));
    await assertSucceeds(getDocs(query(collection(as(UID.coach), 'attendance'), where('trainingId', '==', 'tPast'))));
  });

  it('feedback: group coach writes ratings 1–5 in the 5 keys; parents read, never write', async () => {
    const f = { childId: 'childA1', groupId: 'g1', coachId: UID.coach, coachName: 'c', trainingId: null, createdAt: now, ratings: { technique: 5, effort: 1 }, comment: 'ok', visibleToParent: true };
    await assertSucceeds(setDoc(doc(as(UID.coach), 'feedback/f2'), f));
    await assertFails(setDoc(doc(as(UID.coach), 'feedback/f3'), { ...f, ratings: { technique: 6 } }));
    await assertFails(setDoc(doc(as(UID.coach), 'feedback/f4'), { ...f, ratings: { charisma: 3 } }));
    await assertFails(setDoc(doc(as(UID.coach), 'feedback/f5'), { ...f, comment: 'x'.repeat(501) }));
    await assertFails(setDoc(doc(as(UID.coachOther), 'feedback/f6'), { ...f, coachId: UID.coachOther }));
    await assertFails(setDoc(doc(as(UID.parentA), 'feedback/f7'), { ...f, coachId: UID.parentA }));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'feedback/f1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'feedback/f1')));
    await assertFails(updateDoc(doc(as(UID.parentA), 'feedback/f1'), { comment: 'better' }));
  });
});

describe('series, matches, venues', () => {
  const series = (o = {}) => ({
    groupId: 'g1', clubId: 'club1', venueId: 'v1', weekdays: [2, 4], startTime: '17:30', durationMin: 60, focus: ['speed'],
    description: '', startDate: '2026-12-01', endDate: null, status: 'active', createdBy: UID.coach, parentSeriesId: null, ...o,
  });

  it('coach of the group creates/ends series with valid fields', async () => {
    const db = as(UID.coach);
    await assertSucceeds(setDoc(doc(db, 'trainingSeries/s2'), series()));
    await assertSucceeds(setDoc(doc(db, 'trainingSeries/s3'), series({ parentSeriesId: 's1' })));
    await assertFails(setDoc(doc(db, 'trainingSeries/s4'), series({ weekdays: [0] })));
    await assertFails(setDoc(doc(db, 'trainingSeries/s5'), series({ weekdays: [8] })));
    await assertFails(setDoc(doc(db, 'trainingSeries/s6'), series({ startTime: '7:30' })));
    await assertFails(setDoc(doc(db, 'trainingSeries/s7'), series({ groupId: 'g2', clubId: 'club2' })));
    await assertFails(setDoc(doc(db, 'trainingSeries/s8'), series({ status: 'ended' })));
    await assertSucceeds(updateDoc(doc(db, 'trainingSeries/s1'), { endDate: '2026-12-31', status: 'ended', updatedAt: now }));
    await assertFails(updateDoc(doc(db, 'trainingSeries/s1'), { groupId: 'g2' }));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'trainingSeries/s1')));
  });

  it('clients cannot create or relink series occurrences', async () => {
    const t = { groupId: 'g1', venueId: 'v1', startAt: ts('2030-01-01T14:00:00Z'), durationMin: 60, focus: ['ball'], description: '', photoUrls: [], status: 'scheduled', createdBy: UID.coach, updatedAt: now };
    await assertFails(setDoc(doc(as(UID.coach), 'trainings/s1_20300101'), { ...t, seriesId: 's1', occurrenceDate: '2030-01-01' }));
    await assertSucceeds(setDoc(doc(as(UID.coach), 'trainings/one'), { ...t, seriesId: null, detached: false, cancelReasonCode: null, cancelReason: null }));
    await assertFails(updateDoc(doc(as(UID.coach), 'trainings/tFuture'), { seriesId: 's1' }));
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'trainings/tFuture'), { detached: true, durationMin: 75 }));
  });

  it('matches: coach of group creates, parents read, others not', async () => {
    const m = { groupId: 'g1', clubId: 'club1', venueId: 'v1', startAt: ts('2030-07-01T14:00:00Z'), durationMin: 90, opponentName: 'Iberia', matchType: 'league', homeAway: 'away', description: null, status: 'scheduled', createdBy: UID.coach, updatedAt: now };
    await assertSucceeds(setDoc(doc(as(UID.coach), 'matches/m2'), m));
    await assertFails(setDoc(doc(as(UID.coach), 'matches/m3'), { ...m, clubId: 'club2' }));
    await assertFails(setDoc(doc(as(UID.coach), 'matches/m4'), { ...m, reminder1dSentAt: now }));
    await assertFails(setDoc(doc(as(UID.coachOther), 'matches/m5'), { ...m, createdBy: UID.coachOther }));
    await assertFails(setDoc(doc(as(UID.parentA), 'matches/m6'), { ...m, createdBy: UID.parentA }));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'matches/mt1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'matches/mt1')));
    await assertFails(updateDoc(doc(as(UID.coach), 'matches/mt1'), { reminder2hSentAt: now }));
  });

  it('venues: approved coach adds unverified venues; only platform admin verifies', async () => {
    const v = { name: 'Field', address: 'Vake', sportIds: ['football'], type: 'field', geohash: 'szr', verified: false, createdBy: UID.coach };
    await assertSucceeds(setDoc(doc(as(UID.coach), 'venues/nv1'), v));
    await assertFails(setDoc(doc(as(UID.coach), 'venues/nv2'), { ...v, verified: true }));
    await assertFails(setDoc(doc(as(UID.parentA), 'venues/nv3'), { ...v, createdBy: UID.parentA }));
    await assertFails(updateDoc(doc(as(UID.coach), 'venues/v1'), { verified: true }));
    await assertSucceeds(updateDoc(doc(admin(), 'venues/v1'), { verified: true }));
  });
});

describe('chat receipts, unread, media, payments, reports, accounts', () => {
  it('members write only their own lastReadAt; owners read their unread counters', async () => {
    await assertSucceeds(setDoc(doc(as(UID.parentA), `chats/g1/members/${UID.parentA}`), { lastReadAt: now }));
    await assertFails(setDoc(doc(as(UID.parentA), `chats/g1/members/${UID.parentB}`), { lastReadAt: now }));
    await assertFails(setDoc(doc(as(UID.parentA), `chats/g1/members/${UID.parentA}`), { lastReadAt: now, x: 1 }));
    await assertFails(setDoc(doc(as(UID.coachOther), `chats/g1/members/${UID.coachOther}`), { lastReadAt: now }));
    await assertSucceeds(getDoc(doc(as(UID.parentA), `userUnread/${UID.parentA}`)));
    await assertFails(getDoc(doc(as(UID.parentB), `userUnread/${UID.parentA}`)));
    await assertFails(setDoc(doc(as(UID.parentA), `userUnread/${UID.parentA}`), { total: 0, byGroup: {} }));
  });

  it('media: coach of every listed group with consent creates, then uploads; readers via readerIds', async () => {
    await assertSucceeds(setDoc(doc(as(UID.coach), 'mediaPosts/mp2'), post()));
    await assertFails(setDoc(doc(as(UID.coach), 'mediaPosts/mp3'), post({ groupIds: ['g1', 'g2'], storagePath: `media/${UID.coach}/mp3/a.jpg` })));
    await assertFails(setDoc(doc(as(UID.coach), 'mediaPosts/mp4'), post({ storagePath: `media/${UID.coachOther}/mp4/a.jpg` })));
    await assertFails(setDoc(doc(as(UID.coach), 'mediaPosts/mp5'), post({ storagePath: `media/${UID.coach}/mp5/a.jpg`, readerIds: [UID.parentA] })));
    await assertFails(setDoc(doc(as(UID.coach), 'mediaPosts/mp6'), post({ storagePath: `media/${UID.coach}/mp6/a.jpg`, hidden: false })));
    await assertSucceeds(uploadBytes(ref(st(UID.coach), `media/${UID.coach}/mp2/a.jpg`), bytes(), { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(ref(st(UID.coach), `media/${UID.coach}/mp2/b.mp4`), bytes(), { contentType: 'video/mp4' }));
    await assertFails(uploadBytes(ref(st(UID.coach), `media/${UID.coach}/mp2/c.pdf`), bytes(), { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(st(UID.coach), `media/${UID.coach}/mp2/d.jpg`), bytes(10 * 1024 * 1024), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st(UID.coachOther), `media/${UID.coach}/mp2/e.jpg`), bytes(), { contentType: 'image/jpeg' }));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'mediaPosts/mp1')));
    await assertFails(getDoc(doc(as(UID.coachOther), 'mediaPosts/mp1')));
    await assertFails(getBytes(ref(st(UID.coachOther), `media/${UID.coach}/mp1/a.jpg`)));
    await assertFails(updateDoc(doc(as(UID.coach), 'mediaPosts/mp1'), { hidden: false, reportCount: 0, caption: 'x' }));
    await assertFails(deleteDoc(doc(as(UID.parentA), 'mediaPosts/mp1')));
    await assertSucceeds(deleteDoc(doc(as(UID.coach), 'mediaPosts/mp1')));
    await assertSucceeds(getDocs(query(collection(as(UID.parentA), 'mediaPosts'), where('readerIds', 'array-contains', UID.parentA))));
  });

  it('avatars: owner JPEG ≤ 1 MB; child photos by parents, read by coach of child', async () => {
    await assertSucceeds(uploadBytes(ref(st(UID.parentA), `profiles/${UID.parentA}/avatar.jpg`), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st(UID.parentA), `profiles/${UID.parentA}/avatar.jpg`), bytes(1024 * 1024 + 1), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st(UID.parentA), `profiles/${UID.parentA}/avatar.jpg`), bytes(), { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(st(UID.parentA), `profiles/${UID.parentB}/avatar.jpg`), bytes(), { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(ref(st(UID.parentA), 'childPhotos/childA1/avatar.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st(UID.parentB), 'childPhotos/childA1/avatar.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(st(UID.coach), 'childPhotos/childA1/avatar.jpg')));
    await assertFails(getBytes(ref(st(UID.coachOther), 'childPhotos/childA1/avatar.jpg')));
    await assertFails(getBytes(ref(st(UID.parentB), 'childPhotos/childA1/avatar.jpg')));
    await assertFails(getBytes(ref(st(UID.parentA), 'exports/parentA/x.json')));
    await assertFails(uploadBytes(ref(st(UID.parentA), 'exports/parentA/y.json'), bytes(), { contentType: 'application/json' }));
  });

  it('payments: coach may set cancelledReason and updatedBy (= self) only', async () => {
    await assertSucceeds(updateDoc(doc(as(UID.coach), 'payments/p1'), { status: 'cancelled', cancelledReason: 'left the club', updatedBy: UID.coach }));
    await assertFails(updateDoc(doc(as(UID.coach), 'payments/p1'), { status: 'paid', updatedBy: UID.coachOther }));
    await assertFails(updateDoc(doc(as(UID.coach), 'payments/p1'), { period: '2026-12' }));
    await assertFails(setDoc(doc(as(UID.coach), 'paymentAudit/x'), { paymentId: 'p1' }));
    await assertSucceeds(getDoc(doc(as(UID.coach), 'paymentAudit/pa1')));
    await assertFails(getDoc(doc(as(UID.parentA), 'paymentAudit/pa1')));
  });

  it('reports: group member creates own open report; outsiders and forged fields fail', async () => {
    const r = { targetType: 'chatMessage', targetPath: 'chats/g1/messages/m1', groupId: 'g1', clubId: 'club1', reason: 'spam', note: null, preview: 'გამარჯობა', reporterId: UID.parentA, createdAt: serverTimestamp(), status: 'open' };
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'reports/n1'), r));
    await assertFails(setDoc(doc(as(UID.parentA), 'reports/n2'), { ...r, reporterId: UID.parentB }));
    await assertFails(setDoc(doc(as(UID.parentA), 'reports/n3'), { ...r, status: 'resolved' }));
    await assertFails(setDoc(doc(as(UID.parentA), 'reports/n4'), { ...r, clubId: 'club2' }));
    await assertFails(setDoc(doc(as(UID.coachOther), 'reports/n5'), { ...r, reporterId: UID.coachOther }));
    await assertFails(updateDoc(doc(as(UID.clubAdminA, CLAIMS.clubA), 'reports/r1'), { status: 'resolved' }));
  });

  it('account requests: owner creates pending delete/export, reads own; nobody updates', async () => {
    const a = { uid: UID.parentA, type: 'export', status: 'pending', createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as(UID.parentA), 'accountRequests/x1'), a));
    await assertFails(setDoc(doc(as(UID.parentA), 'accountRequests/x2'), { ...a, uid: UID.parentB }));
    await assertFails(setDoc(doc(as(UID.parentA), 'accountRequests/x3'), { ...a, status: 'done' }));
    await assertFails(setDoc(doc(as(UID.parentA), 'accountRequests/x4'), { ...a, type: 'wipe' }));
    await assertSucceeds(getDoc(doc(as(UID.parentA), 'accountRequests/x1')));
    await assertFails(getDoc(doc(as(UID.parentB), 'accountRequests/x1')));
    await assertFails(updateDoc(doc(as(UID.parentA), 'accountRequests/x1'), { status: 'done' }));
  });

  it('server-only collections are closed to clients', async () => {
    await assertFails(getDoc(doc(as(UID.parentA), 'rateLimits/parentA_reports')));
    await assertFails(setDoc(doc(as(UID.parentA), 'rateLimits/parentA_reports'), { hits: [] }));
    await assertFails(setDoc(doc(admin(), 'auditLog/x'), { action: 'role.set' }));
    await assertFails(getDoc(doc(admin(), 'groupCodes/ABCD23')));
    await assertFails(setDoc(doc(as(UID.coach), 'coachClubs/x'), { coachId: UID.coach, clubId: 'club2' }));
  });
});
