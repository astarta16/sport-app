import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, doc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const PROJECT_ID = 'demo-sport-parent';

function hostPort(envName, fallbackPort) {
  const v = process.env[envName];
  if (!v) return { host: '127.0.0.1', port: fallbackPort };
  const i = v.lastIndexOf(':');
  return { host: v.slice(0, i), port: Number(v.slice(i + 1)) };
}

export async function createEnv() {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(process.env.FIRESTORE_RULES_PATH ?? resolve(root, 'firestore.rules'), 'utf8'),
      ...hostPort('FIRESTORE_EMULATOR_HOST', 8080),
    },
    storage: {
      rules: readFileSync(resolve(root, 'storage.rules'), 'utf8'),
      ...hostPort('FIREBASE_STORAGE_EMULATOR_HOST', 9199),
    },
  });
}

export const UID = {
  parentA: 'parentA',
  parentB: 'parentB',
  childUser: 'childUserA1',
  coach: 'coachApproved',
  coachPending: 'coachPending',
  coachOther: 'coachOther',
  admin: 'adminUser',
  coachSuspended: 'coachSuspended',
  clubAdminA: 'clubAdminA',
  clubAdminB: 'clubAdminB',
};

/** Custom claims used by the v1.2 tests. */
export const CLAIMS = {
  platform: { admin: true },
  clubA: { clubAdmin: ['club1'] },
  clubB: { clubAdmin: ['club2'] },
};

const ts = (iso) => Timestamp.fromDate(new Date(iso));
const now = ts('2026-11-10T10:00:00Z');

function user(role, extra = {}) {
  return {
    role,
    firstName: role,
    lastName: 'Test',
    phone: '+995599000000',
    createdAt: now,
    dataConsentAt: now,
    fcmTokens: [],
    notificationPrefs: { newTraining: true },
    ...extra,
  };
}

/** Seeds the canonical fixture used by all rules tests (rules disabled). */
export async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (path, data) => setDoc(doc(db, path), data);

    await put(`users/${UID.parentA}`, user('parent'));
    await put(`users/${UID.parentB}`, user('parent'));
    await put(`users/${UID.childUser}`, user('child', { lastContext: { childId: 'childA1' } }));
    await put(`users/${UID.coach}`, user('coach', { coachStatus: 'approved', clubIds: ['club1'], sportIds: ['football'] }));
    await put(`users/${UID.coachPending}`, user('coach', { coachStatus: 'pending', clubIds: ['club1'], sportIds: ['football'] }));
    await put(`users/${UID.coachOther}`, user('coach', { coachStatus: 'approved', clubIds: ['club2'], sportIds: ['football'] }));

    await put('sports/football', { name: 'ფეხბურთი', icon: 'football' });
    await put('clubs/club1', { name: 'Club 1', address: 'Tbilisi', sportIds: ['football'], geohash: 'szr' });
    await put('venues/v1', { name: 'Stadium', address: 'Tbilisi', sportIds: ['football'], type: 'stadium', geohash: 'szr' });

    await put('children/childA1', {
      firstName: 'Nika', lastName: 'A', birthDate: ts('2014-01-01T00:00:00Z'),
      parentIds: [UID.parentA], userId: UID.childUser, sportIds: ['football'],
      groupIds: ['g1'], coachIds: [UID.coach], photoConsent: true,
    });
    await put('children/childB1', {
      firstName: 'Ana', lastName: 'B', birthDate: ts('2016-01-01T00:00:00Z'),
      parentIds: [UID.parentB], sportIds: ['football'],
      groupIds: ['g1'], coachIds: [UID.coach], photoConsent: false,
    });

    await put('groups/g1', {
      clubId: 'club1', sportId: 'football', coachIds: [UID.coach], name: 'U12',
      ageMin: 10, ageMax: 12, memberChildIds: ['childA1', 'childB1'],
      parentIds: [UID.parentA, UID.parentB],
    });
    await put('groups/g2', {
      clubId: 'club2', sportId: 'football', coachIds: [UID.coachOther], name: 'U10',
      ageMin: 8, ageMax: 10, memberChildIds: [], parentIds: [],
    });

    await put('trainings/t1', {
      groupId: 'g1', venueId: 'v1', startAt: ts('2026-11-12T14:00:00Z'), durationMin: 90,
      focus: ['ball'], description: 'Passing', photoUrls: [], status: 'scheduled',
      createdBy: UID.coach, updatedAt: now,
    });
    await put('trainings/t2', {
      groupId: 'g2', venueId: 'v1', startAt: ts('2026-11-12T14:00:00Z'), durationMin: 60,
      focus: ['speed'], description: '', photoUrls: [], status: 'scheduled',
      createdBy: UID.coachOther, updatedAt: now,
    });

    await put('chats/g1/messages/m1', {
      senderId: UID.parentA, senderName: 'parent Test', senderRole: 'parent',
      text: 'გამარჯობა', createdAt: now,
    });

    await put('medicalCertificates/cert1', {
      childId: 'childA1', uploadedBy: UID.parentA, storagePath: 'medical/childA1/cert1',
      issuedAt: ts('2026-01-01T00:00:00Z'), validUntil: ts('2027-01-01T00:00:00Z'),
      consentAt: now, status: 'valid',
    });

    await put('payments/p1', {
      childId: 'childA1', parentId: UID.parentA, groupId: 'g1', sportId: 'football',
      amount: 80, currency: 'GEL', dueDate: ts('2026-11-15T00:00:00Z'),
      status: 'pending', reminders: {}, createdAt: now,
    });

    await put('smsLog/s1', { at: now, phone: '+995*****0000', status: 'sent', provider: 'mock', kind: 'd5' });
    await put('certificateAccessLog/l1', { certId: 'cert1', childId: 'childA1', userId: UID.parentA, at: now, action: 'view' });
    await put('publicProfiles/parentB', { firstName: 'parent', lastName: 'Test', role: 'parent' });

    const storage = ctx.storage();
    await uploadBytes(ref(storage, 'medical/childA1/cert1'), new Uint8Array([1, 2, 3]), { contentType: 'application/pdf' });
    await uploadBytes(ref(storage, 'trainingPhotos/g1/photo1.jpg'), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
  });
}

/**
 * v1.1/v1.2 fixture on top of seed(): suspended coach in g1, a far-future and
 * a past training, a media post with its file, inbox, audit and report docs.
 */
export async function seedV12(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (path, data) => setDoc(doc(db, path), data);
    await put(`users/${UID.coachSuspended}`, user('coach', { coachStatus: 'suspended', clubIds: ['club1'], sportIds: ['football'] }));
    await put(`users/${UID.clubAdminA}`, user('parent'));
    await put('clubs/club2', { name: 'Club 2', address: 'Batumi', sportIds: ['football'], geohash: 'sz', status: 'active', adminIds: [UID.clubAdminB] });
    await put('groups/g1', {
      clubId: 'club1', sportId: 'football', coachIds: [UID.coach, UID.coachSuspended], name: 'U12',
      ageMin: 10, ageMax: 12, memberChildIds: ['childA1', 'childB1'],
      parentIds: [UID.parentA, UID.parentB], inviteCode: 'ABCD23', status: 'active', createdBy: UID.coach,
    });
    const training = (groupId, iso, extra = {}) => ({
      groupId, venueId: 'v1', startAt: ts(iso), durationMin: 60, focus: ['ball'], description: '',
      photoUrls: [], status: 'scheduled', createdBy: UID.coach, updatedAt: now, ...extra,
    });
    await put('trainings/tFuture', training('g1', '2030-06-01T14:00:00Z'));
    await put('trainings/tPast', training('g1', '2020-06-01T14:00:00Z'));
    await put('trainings/tOther', training('g2', '2030-06-01T14:00:00Z', { createdBy: UID.coachOther }));
    await put('attendance/tPast_childA1', {
      trainingId: 'tPast', groupId: 'g1', childId: 'childA1', status: 'present', markedBy: UID.coach, markedAt: now, note: null,
    });
    await put('rsvps/tFuture_childB1', {
      trainingId: 'tFuture', groupId: 'g1', childId: 'childB1', parentId: UID.parentB, response: 'yes', reason: null, updatedAt: now,
    });
    await put('feedback/f1', {
      childId: 'childA1', groupId: 'g1', coachId: UID.coach, coachName: 'coach', trainingId: null, createdAt: now,
      ratings: { technique: 4 }, comment: 'კარგი', visibleToParent: true,
    });
    await put('mediaPosts/mp1', {
      coachId: UID.coach, coachName: 'coach', groupIds: ['g1'], clubId: 'club1', type: 'photo',
      storagePath: `media/${UID.coach}/mp1/a.jpg`, thumbPath: null, caption: 'ვარჯიში', durationSec: null,
      createdAt: now, consentConfirmed: true, hidden: false, reportCount: 0,
      readerIds: [UID.coach, UID.coachSuspended, UID.parentA, UID.parentB],
    });
    await put('notifications/n1', {
      userId: UID.parentA, type: 'newTraining', category: 'trainings', title: 't', body: 'b', route: '/training/t1',
      args: {}, childId: null, groupId: 'g1', createdAt: now, read: false, dedupeKey: 'training:t1:new',
    });
    await put('auditLog/a1', { action: 'coach.approve', actorId: UID.admin, actorRole: 'platformAdmin', targetType: 'user', targetId: UID.coach, clubId: 'club1', details: {}, at: now });
    await put('auditLog/a2', { action: 'coach.approve', actorId: UID.admin, actorRole: 'platformAdmin', targetType: 'user', targetId: UID.coachOther, clubId: 'club2', details: {}, at: now });
    await put('reports/r1', { targetType: 'chatMessage', targetPath: 'chats/g1/messages/m1', groupId: 'g1', clubId: 'club1', reason: 'spam', reporterId: UID.parentB, createdAt: now, status: 'open' });
    await put('reports/r2', { targetType: 'chatMessage', targetPath: 'chats/g2/messages/x', groupId: 'g2', clubId: 'club2', reason: 'spam', reporterId: UID.coachOther, createdAt: now, status: 'open' });
    await put('paymentAudit/pa1', { paymentId: 'p1', groupId: 'g1', clubId: 'club1', from: 'pending', to: 'paid', actorId: UID.coach, at: now });
    await put('invites/i1', {
      groupId: 'g1', clubId: 'club1', sportId: 'football', groupName: 'U12', childId: 'pend1', childFirstName: 'Luka',
      childLastName: 'C', phone: '+995599000009', parentId: UID.parentB, status: 'sent', createdBy: UID.coach, createdAt: now,
    });
    await put('children/pend1', { firstName: 'Luka', lastName: 'C', birthDate: ts('2016-01-01T00:00:00Z'), parentIds: [], status: 'pendingParent', createdByCoachId: UID.coach });
    await put('trainingSeries/s1', {
      groupId: 'g1', clubId: 'club1', venueId: 'v1', weekdays: [1, 3], startTime: '18:00', durationMin: 90, focus: ['ball'],
      description: '', startDate: '2026-11-01', endDate: null, status: 'active', createdBy: UID.coach, parentSeriesId: null,
    });
    await put('matches/mt1', {
      groupId: 'g1', clubId: 'club1', venueId: 'v1', startAt: ts('2030-06-02T14:00:00Z'), durationMin: 90, opponentName: 'Dinamo',
      matchType: 'friendly', homeAway: 'home', description: null, status: 'scheduled', cancelReasonCode: null, cancelReason: null,
      cancelledAt: null, cancelledBy: null, previousStartAt: null, createdBy: UID.coach, updatedAt: now,
    });
    await put(`userUnread/${UID.parentA}`, { total: 2, byGroup: { g1: 2 } });
    await put('groupCodes/ABCD23', { groupId: 'g1' });
    await put('rateLimits/parentA_reports', { hits: [] });

    const storage = ctx.storage();
    await uploadBytes(ref(storage, `media/${UID.coach}/mp1/a.jpg`), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
    await uploadBytes(ref(storage, 'childPhotos/childA1/avatar.jpg'), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
    await uploadBytes(ref(storage, 'exports/parentA/x.json'), new Uint8Array([1]), { contentType: 'application/json' });
  });
}

export { Timestamp, now, ts };
