import { logger } from 'firebase-functions';
import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { bucket, db, isEmulator } from '../admin';
import { TIMEZONE } from '../config';
import { certificateFrom, childFrom, groupFrom, loadChildren, loadUser, loadUsers } from '../convert';
import { pushText } from '../i18n';
import { canAccessCertificate, canDeleteCertificate } from '../lib/access';
import { adminScopeFromClaims, isAnyAdmin } from '../lib/adminScope';
import { computeCertificateStatus, decideCertificateReminder, reminderTemplateFor } from '../lib/certificates';
import { CertificateLite } from '../lib/types';
import { formatDate } from '../lib/dates';
import { notify } from '../notify';
import { writeAudit } from '../audit';

const SIGNED_URL_TTL_MS = 5 * 60 * 1000;

async function deleteStorageFile(path: string | undefined): Promise<void> {
  if (!path) return;
  try {
    await bucket().file(path).delete({ ignoreNotFound: true });
  } catch (e) {
    logger.warn('certificate file delete failed', { path, error: String(e) });
  }
}

export type CertificatePurpose = 'view' | 'download';

/**
 * certificateAccessLog entry. v1.3 fields: viewerId, viewerRole, purpose
 * (contract); userId/action are kept for v1.2 readers.
 */
async function writeAccessLog(entry: {
  certId: string; childId: string; userId: string; action: string; viewerRole?: string; purpose?: CertificatePurpose;
}) {
  await db.collection('certificateAccessLog').add({
    certId: entry.certId,
    childId: entry.childId,
    viewerId: entry.userId,
    viewerRole: entry.viewerRole ?? (entry.userId === 'system' ? 'system' : 'unknown'),
    purpose: entry.purpose ?? null,
    userId: entry.userId,
    action: entry.action,
    at: FieldValue.serverTimestamp(),
  });
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
 * 3. Daily 09:00 Asia/Tbilisi: recompute status and remind parents at 14
 *    days, 3 days and on the expiry day — each once. v1.3 idempotency flags
 *    `reminders.d14SentAt / d3SentAt / d0SentAt` (the v1.2 `notified14At /
 *    notified3At / notified0At` are still honoured and still written), claimed
 *    in a transaction before sending. Replaced certificates and certificates
 *    superseded by a newer current one are not reminded. Text in each
 *    parent's locale.
 */
export const certificateExpiryCheck = onSchedule(
  { schedule: '0 9 * * *', timeZone: TIMEZONE },
  async () => {
    const r = await runCertificateReminders(new Date());
    logger.info('certificate expiry run', r);
  },
);

/** One reminder pass (exported for the emulator smoke test). */
export async function runCertificateReminders(now: Date): Promise<{ candidates: number; notified: number }> {
  const horizon = new Date(now.getTime() + 15 * 86_400_000);
  const snap = await db.collection('medicalCertificates').where('validUntil', '<=', Timestamp.fromDate(horizon)).get();

  const siblingsCache = new Map<string, CertificateLite[]>();
  const siblingsOf = async (childId: string) => {
    if (!siblingsCache.has(childId)) {
      const q = await db.collection('medicalCertificates').where('childId', '==', childId).get();
      siblingsCache.set(childId, q.docs.map((d) => certificateFrom(d.id, d.data())));
    }
    return siblingsCache.get(childId)!;
  };

  let notified = 0;
  for (const doc of snap.docs) {
    const childId = String(doc.get('childId') ?? '');
    if (!childId) continue;
    const siblings = await siblingsOf(childId);
    const result = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists) return null;
      const cert = certificateFrom(fresh.id, fresh.data()!);
      const d = decideCertificateReminder(cert, siblings, now);
      const update: Record<string, unknown> = {};
      if (d.status !== cert.status) update.status = d.status;
      for (const f of d.markFields) update[f] = FieldValue.serverTimestamp();
      for (const f of d.reminderFields) update[f] = FieldValue.serverTimestamp();
      if (Object.keys(update).length > 0) tx.update(doc.ref, update);
      return d.stage === null ? null : { cert, decision: d };
    });
    if (!result) continue;

    const children = await loadChildren([result.cert.childId]);
    const child = children.get(result.cert.childId);
    if (!child) continue;
    const users = await loadUsers(child.parentIds);
    const recipients = child.parentIds.map((u) => users.get(u)).filter((u): u is NonNullable<typeof u> => !!u && u.role === 'parent');
    const stage = result.decision.stage!;
    const msg = pushText(reminderTemplateFor(stage, result.decision.status), {
      child: child.firstName,
      days: Math.max(0, result.decision.daysLeft),
      date: formatDate(result.cert.validUntil),
    });
    await notify(recipients, {
      type: 'certificateExpiry',
      ...msg,
      route: `/child/${child.id}/certificates`,
      args: { certId: result.cert.id, childId: child.id, stage: String(stage), days: String(stage) },
      childId: child.id,
      dedupeKey: `cert:${result.cert.id}:${stage}:${result.cert.validUntil.getTime()}`,
      data: { certId: result.cert.id, childId: child.id, stage: String(stage) },
    });
    notified++;
  }
  return { candidates: snap.size, notified };
}

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
 * 5a. getCertificateUrl {certId, purpose: 'view' | 'download' = 'view'} →
 *     {url, expiresAt} — a 5-minute signed URL. Allowed: a parent of the child,
 *     or an approved coach CURRENTLY assigned to a group containing the child
 *     (live group query, so removal revokes immediately). Platform and club
 *     admins are always denied (they get counts via adminCompliance). Every
 *     call writes certificateAccessLog {certId, childId, viewerId, viewerRole,
 *     purpose, at} and auditLog certificate.view / certificate.download.
 */
export const getCertificateUrl = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const rawPurpose = request.data?.purpose ?? 'view';
  if (rawPurpose !== 'view' && rawPurpose !== 'download') throw new HttpsError('invalid-argument', "purpose must be 'view' or 'download'");
  const purpose: CertificatePurpose = rawPurpose;
  if (isAnyAdmin(adminScopeFromClaims(request.auth.token as Record<string, unknown>))) {
    throw new HttpsError('permission-denied', 'admins cannot open medical certificates');
  }
  const { cert, child } = await loadCertContext(request.data?.certId);
  const user = await loadUser(uid);
  if (user?.role === 'admin') throw new HttpsError('permission-denied', 'admins cannot open medical certificates');
  const groupsSnap = child
    ? await db.collection('groups').where('memberChildIds', 'array-contains', child.id).get()
    : null;
  const groups = groupsSnap ? groupsSnap.docs.map((g) => groupFrom(g.id, g.data())) : [];
  if (!canAccessCertificate(user, child, groups)) {
    throw new HttpsError('permission-denied', 'no access to this certificate');
  }

  const path = String(cert.storagePath ?? '');
  if (!path.startsWith(`medical/${cert.childId}/`)) throw new HttpsError('failed-precondition', 'invalid storage path');

  const certId = String(request.data.certId);
  const viewerRole = user?.role ?? 'unknown';
  await writeAccessLog({ certId, childId: cert.childId, userId: uid, action: purpose, viewerRole, purpose });
  await writeAudit({
    action: purpose === 'download' ? 'certificate.download' : 'certificate.view', actorId: uid, actorRole: viewerRole,
    targetType: 'medicalCertificate', targetId: certId, details: { childId: cert.childId, purpose },
  });

  const expiresAt = Date.now() + SIGNED_URL_TTL_MS;
  let url: string;
  if (isEmulator) {
    // The Storage emulator cannot sign URLs; return a direct emulator link.
    const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199';
    url = `http://${host}/v0/b/${bucket().name}/o/${encodeURIComponent(path)}?alt=media`;
  } else {
    [url] = await bucket().file(path).getSignedUrl({
      version: 'v4', action: 'read', expires: expiresAt,
      ...(purpose === 'download' ? { responseDisposition: `attachment; filename="certificate-${certId}"` } : {}),
    });
  }
  return { url, expiresAt: new Date(expiresAt).toISOString(), purpose };
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
  await writeAccessLog({ certId: certSnap.id, childId: cert.childId, userId: uid, action: 'delete', viewerRole: user?.role ?? 'unknown' });
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
