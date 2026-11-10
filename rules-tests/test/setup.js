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
      rules: readFileSync(resolve(root, 'firestore.rules'), 'utf8'),
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

export { Timestamp, now, ts };
