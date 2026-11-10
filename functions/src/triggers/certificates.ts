import { logger } from 'firebase-functions';
import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { bucket, db, isEmulator } from '../admin';
import { TIMEZONE } from '../config';
import { certificateFrom, childFrom, groupFrom, loadChildren, loadUser, loadUsers } from '../convert';
import { renderPush } from '../i18n/ka';
import { canAccessCertificate, canDeleteCertificate } from '../lib/access';
import { computeCertificateStatus, decideExpiryNotification } from '../lib/certificates';
import { formatDate } from '../lib/dates';
import { selectCertificateRecipients } from '../lib/recipients';
import { sendPushToUsers } from '../push';

const SIGNED_URL_TTL_MS = 5 * 60 * 1000;

async function deleteStorageFile(path: string | undefined): Promise<void> {
  if (!path) return;
  try {
    await bucket().file(path).delete({ ignoreNotFound: true });
  } catch (e) {
    logger.warn('certificate file delete failed', { path, error: String(e) });
  }
}

async function writeAccessLog(entry: { certId: string; childId: string; userId: string; action: string }) {
  await db.collection('certificateAccessLog').add({ ...entry, at: FieldValue.serverTimestamp() });
}

/** New certificate: compute status server-side (clients may send any enum value). */
export const onCertificateCreated = onDocumentCreated('medicalCertificates/{certId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const cert = certificateFrom(snap.id, snap.data());
  const status = computeCertificateStatus(cert.validUntil, new Date());
  if (status !== cert.status) await snap.ref.update({ status });
});

/** Certificate metadata deleted (by client or callable): remove the file too. */
export const onCertificateDeleted = onDocumentDeleted('medicalCertificates/{certId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  await deleteStorageFile(data.storagePath);
  await writeAccessLog({ certId: event.params.certId, childId: data.childId ?? '', userId: 'system', action: 'file_deleted' });
});

/**
 * 3. Daily 09:00 Asia/Tbilisi: recompute status and push expiry warnings at
 *    14 days, 3 days and on the expiry day — each once (notified14At /
 *    notified3At / notified0At claimed in a transaction before sending).
 */
export const certificateExpiryCheck = onSchedule(
  { schedule: '0 9 * * *', timeZone: TIMEZONE },
  async () => {
    const now = new Date();
    const horizon = new Date(now.getTime() + 15 * 86_400_000);
    const snap = await db.collection('medicalCertificates').where('validUntil', '<=', Timestamp.fromDate(horizon)).get();

    let notified = 0;
    for (const doc of snap.docs) {
      const result = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(doc.ref);
        if (!fresh.exists) return null;
        const cert = certificateFrom(fresh.id, fresh.data()!);
        const d = decideExpiryNotification(cert, now);
        const update: Record<string, unknown> = {};
        if (d.status !== cert.status) update.status = d.status;
        for (const f of d.markFields) update[f] = FieldValue.serverTimestamp();
        if (Object.keys(update).length > 0) tx.update(doc.ref, update);
        return d.stage === null ? null : { cert, decision: d };
      });
      if (!result) continue;

      const children = await loadChildren([result.cert.childId]);
      const child = children.get(result.cert.childId);
      if (!child) continue;
      const users = await loadUsers(child.parentIds);
      const recipients = selectCertificateRecipients(child, users);
      const msg =
        result.decision.stage === 0
          ? renderPush('certificateExpired', { child: child.firstName })
          : renderPush('certificateExpiring', {
              child: child.firstName,
              days: result.decision.daysLeft,
              date: formatDate(result.cert.validUntil),
            });
      await sendPushToUsers(recipients, {
        ...msg,
        data: { type: 'certificateExpiry', certId: result.cert.id, childId: child.id, stage: String(result.decision.stage) },
      });
      notified++;
    }
    logger.info('certificate expiry run', { candidates: snap.size, notified });
  },
);

async function loadCertContext(certId: unknown) {
  if (typeof certId !== 'string' || certId.length === 0 || certId.includes('/')) {
    throw new HttpsError('invalid-argument', 'certId is required');
  }
  const certSnap = await db.doc(`medicalCertificates/${certId}`).get();
  if (!certSnap.exists) throw new HttpsError('not-found', 'certificate not found');
  const cert = certSnap.data()!;
  const childSnap = await db.doc(`children/${cert.childId}`).get();
  const child = childSnap.exists ? childFrom(childSnap.id, childSnap.data()!) : undefined;
  return { certSnap, cert, child };
}

/**
 * 5a. Returns a 5-minute signed URL for a certificate file after checking
 *     that the caller is a parent of the child or an approved coach of a
 *     group containing the child. Every access is logged.
 */
export const getCertificateUrl = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const { cert, child } = await loadCertContext(request.data?.certId);
  const user = await loadUser(uid);
  const groupsSnap = child
    ? await db.collection('groups').where('memberChildIds', 'array-contains', child.id).get()
    : null;
  const groups = groupsSnap ? groupsSnap.docs.map((g) => groupFrom(g.id, g.data())) : [];
  if (!canAccessCertificate(user, child, groups)) {
    throw new HttpsError('permission-denied', 'no access to this certificate');
  }

  const path = String(cert.storagePath ?? '');
  if (!path.startsWith(`medical/${cert.childId}/`)) throw new HttpsError('failed-precondition', 'invalid storage path');

  await writeAccessLog({ certId: String(request.data.certId), childId: cert.childId, userId: uid, action: 'view' });

  const expiresAt = Date.now() + SIGNED_URL_TTL_MS;
  let url: string;
  if (isEmulator) {
    // The Storage emulator cannot sign URLs; return a direct emulator link.
    const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199';
    url = `http://${host}/v0/b/${bucket().name}/o/${encodeURIComponent(path)}?alt=media`;
  } else {
    [url] = await bucket().file(path).getSignedUrl({ version: 'v4', action: 'read', expires: expiresAt });
  }
  return { url, expiresAt: new Date(expiresAt).toISOString() };
});

/** 5b. Deletes certificate metadata AND the stored file (parent of the child only). */
export const deleteCertificate = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const { certSnap, cert, child } = await loadCertContext(request.data?.certId);
  const user = await loadUser(uid);
  if (!canDeleteCertificate(user, child)) throw new HttpsError('permission-denied', 'only a parent of the child may delete');
  await deleteStorageFile(cert.storagePath);
  await certSnap.ref.delete();
  await writeAccessLog({ certId: certSnap.id, childId: cert.childId, userId: uid, action: 'delete' });
  return { deleted: true };
});

/**
 * Deletes every certificate (metadata + file) of a child and the child's
 * whole medical/{childId}/ folder. Idempotent.
 */
export async function purgeChildCertificates(childId: string): Promise<number> {
  const snap = await db.collection('medicalCertificates').where('childId', '==', childId).get();
  for (const d of snap.docs) {
    await deleteStorageFile(d.data().storagePath);
    await d.ref.delete();
  }
  try {
    await bucket().deleteFiles({ prefix: `medical/${childId}/` });
  } catch (e) {
    logger.warn('medical folder purge failed', { childId, error: String(e) });
  }
  return snap.size;
}
