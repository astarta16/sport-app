import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { auth, bucket, db, isEmulator } from '../admin';
import { writeAudit } from '../audit';
import { buildExport } from '../lib/export';
import { consumeRateLimit } from '../rateLimiter';
import { cleanupUserData } from './users';

const EXPORT_URL_TTL_MS = 15 * 60 * 1000;

async function createRequest(uid: string, type: 'delete' | 'export'): Promise<string> {
  await consumeRateLimit(uid, 'accountRequests');
  const existing = await db.collection('accountRequests')
    .where('uid', '==', uid).where('type', '==', type).where('status', 'in', ['pending', 'processing']).limit(1).get();
  if (!existing.empty) return existing.docs[0].id;
  const ref = await db.collection('accountRequests').add({ uid, type, status: 'pending', createdAt: FieldValue.serverTimestamp() });
  return ref.id;
}

/** requestAccountDeletion {} -> {requestId}; processed by onAccountRequestCreated. */
export const requestAccountDeletion = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  return { requestId: await createRequest(request.auth.uid, 'delete') };
});

/** requestDataExport {} -> {requestId}; the JSON lands in exports/{uid}/{requestId}.json. */
export const requestDataExport = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  return { requestId: await createRequest(request.auth.uid, 'export') };
});

/** getExportUrl {requestId} -> {url}: owner of a finished export only; short-lived signed URL. */
export const getExportUrl = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const requestId = request.data?.requestId;
  if (typeof requestId !== 'string' || !requestId || requestId.includes('/')) throw new HttpsError('invalid-argument', 'requestId');
  const snap = await db.doc(`accountRequests/${requestId}`).get();
  if (!snap.exists || snap.get('uid') !== request.auth.uid || snap.get('type') !== 'export') throw new HttpsError('not-found', 'export not found');
  if (snap.get('status') !== 'done') throw new HttpsError('failed-precondition', 'export not ready');
  const path = `exports/${request.auth.uid}/${requestId}.json`;
  const expiresAt = Date.now() + EXPORT_URL_TTL_MS;
  let url: string;
  if (isEmulator) {
    const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199';
    url = `http://${host}/v0/b/${bucket().name}/o/${encodeURIComponent(path)}?alt=media`;
  } else {
    [url] = await bucket().file(path).getSignedUrl({ version: 'v4', action: 'read', expires: expiresAt });
  }
  return { url, expiresAt: new Date(expiresAt).toISOString() };
});

const docs = (snap: FirebaseFirestore.QuerySnapshot) => snap.docs.map((d) => ({ id: d.id, ...d.data() }));

async function inChunks(coll: string, field: string, ids: string[]) {
  const out: Array<Record<string, unknown> & { id: string }> = [];
  for (let i = 0; i < ids.length; i += 30) {
    out.push(...docs(await db.collection(coll).where(field, 'in', ids.slice(i, i + 30)).get()));
  }
  return out;
}

/** Builds and stores the export JSON (metadata only; no medical files). */
export async function processExport(uid: string, requestId: string): Promise<string> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const children = docs(await db.collection('children').where('parentIds', 'array-contains', uid).get());
  const childIds = children.map((c) => c.id);
  const [certificates, rsvps, attendance, feedback] = await Promise.all([
    inChunks('medicalCertificates', 'childId', childIds),
    inChunks('rsvps', 'childId', childIds),
    inChunks('attendance', 'childId', childIds),
    inChunks('feedback', 'childId', childIds),
  ]);
  const [payments, membershipRequests, invites, notifications] = await Promise.all([
    db.collection('payments').where('parentId', '==', uid).get().then(docs),
    db.collection('membershipRequests').where('parentId', '==', uid).get().then(docs),
    db.collection('invites').where('parentId', '==', uid).get().then(docs),
    db.collection('notifications').where('userId', '==', uid).get().then(docs),
  ]);
  const json = buildExport({
    uid, generatedAt: new Date(),
    user: userSnap.exists ? { id: uid, ...userSnap.data() } : undefined,
    children, certificates, rsvps, attendance, feedback, payments, membershipRequests, invites, notifications,
  });
  const path = `exports/${uid}/${requestId}.json`;
  await bucket().file(path).save(JSON.stringify(json, null, 2), { contentType: 'application/json', resumable: false });
  return path;
}

/**
 * accountRequests/{id} created (by callable or directly by the owner, see
 * rules): process it. delete → cleanupUserData (deletion rules of the
 * contract) + auth user deletion; export → exports/{uid}/{id}.json.
 * Both write auditLog.
 */
export const onAccountRequestCreated = onDocumentCreated('accountRequests/{requestId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const { uid, type, status } = snap.data();
  if (status !== 'pending' || typeof uid !== 'string' || !uid) return;
  const claimed = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(snap.ref);
    if (fresh.get('status') !== 'pending') return false;
    tx.update(snap.ref, { status: 'processing' });
    return true;
  });
  if (!claimed) return;
  try {
    if (type === 'delete') {
      await writeAudit({ action: 'account.deleteRequest', actorId: uid, actorRole: 'user', targetType: 'user', targetId: uid, details: { requestId: snap.id } });
      const result = await cleanupUserData(uid);
      await auth().deleteUser(uid).catch((e) => logger.warn('auth delete failed', { uid, error: String(e) }));
      await snap.ref.update({ status: 'done', completedAt: FieldValue.serverTimestamp(), result: { deletedChildren: result.deleted.length, unlinkedChildren: result.unlinked.length } });
    } else if (type === 'export') {
      await writeAudit({ action: 'account.exportRequest', actorId: uid, actorRole: 'user', targetType: 'user', targetId: uid, details: { requestId: snap.id } });
      const path = await processExport(uid, snap.id);
      await snap.ref.update({ status: 'done', completedAt: FieldValue.serverTimestamp(), result: path });
    } else {
      await snap.ref.update({ status: 'rejected', completedAt: FieldValue.serverTimestamp() });
    }
  } catch (e) {
    logger.error('account request failed', { requestId: snap.id, error: String(e) });
    await snap.ref.update({ status: 'rejected', error: String(e).slice(0, 300), completedAt: FieldValue.serverTimestamp() });
  }
});
