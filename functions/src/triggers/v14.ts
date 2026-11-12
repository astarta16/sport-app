import { logger } from 'firebase-functions';
import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { bucket, db, isEmulator } from '../admin';
import { writeAudit } from '../audit';
import { childFrom, groupFrom, loadUser, loadUsers } from '../convert';
import { pushText } from '../i18n';
import { consumeRateLimit } from '../rateLimiter';
import { GroupLite, UserLite } from '../lib/types';
import {
  ChildForContacts, canSeeContactPhone, downloadFileName, groupContactsFor, mediaDownloadDecision, receiptCounts,
  receiptEligible, receiptRecipients,
} from '../lib/v14';
import { notify } from '../notify';

const DOWNLOAD_URL_TTL_MS = 5 * 60 * 1000;

function idArg(v: unknown, name: string): string {
  if (typeof v !== 'string' || !v || v.includes('/') || v.length > 200) throw new HttpsError('invalid-argument', name);
  return v;
}

async function groupsWhere(field: 'coachIds' | 'parentIds', uid: string): Promise<GroupLite[]> {
  const snap = await db.collection('groups').where(field, 'array-contains', uid).get();
  return snap.docs.map((d) => groupFrom(d.id, d.data()));
}

// ─── 1. Contacts ───────────────────────────────────────────────────────────

/**
 * getContactPhone {uid} → {phone}: live check of an ACTIVE shared group
 * (coach ↔ parents of the coach's groups, parent ↔ approved coaches of the
 * child's groups). Never logs the number.
 */
export const getContactPhone = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const targetId = idArg(request.data?.uid, 'uid');
  const [caller, target] = await Promise.all([loadUser(request.auth.uid), loadUser(targetId)]);
  const groups = caller?.role === 'coach' ? await groupsWhere('coachIds', request.auth.uid) : await groupsWhere('parentIds', request.auth.uid);
  if (!canSeeContactPhone(caller, target, groups)) throw new HttpsError('permission-denied', 'not allowed');
  return { phone: target?.phone ?? null };
});

/**
 * getGroupContacts {groupId} → {contacts: [{uid, role, name, phone, children}]}
 * Scoped projection — coaches get the group's parents, parents get the
 * group's approved coaches. No other user data is returned.
 */
export const getGroupContacts = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const groupId = idArg(request.data?.groupId, 'groupId');
  const snap = await db.doc(`groups/${groupId}`).get();
  if (!snap.exists) throw new HttpsError('not-found', 'group not found');
  const group = groupFrom(snap.id, snap.data()!);
  const caller = await loadUser(request.auth.uid);
  const users = await loadUsers([...group.parentIds, ...group.coachIds]);
  let children: ChildForContacts[] = [];
  if (caller?.role === 'coach' && group.memberChildIds.length) {
    const snaps = await db.getAll(...group.memberChildIds.map((c) => db.doc(`children/${c}`)));
    children = snaps.filter((s) => s.exists).map((s) => {
      const c = childFrom(s.id, s.data()!);
      const rel = s.get('guardianRelations');
      return { id: c.id, firstName: c.firstName, parentIds: c.parentIds, guardianRelations: rel && typeof rel === 'object' ? rel : undefined };
    });
  }
  const contacts = groupContactsFor(caller, group, users, children);
  if (!contacts) throw new HttpsError('permission-denied', 'not allowed');
  return { contacts };
});

// ─── 2. Read receipts and acknowledgments ──────────────────────────────────

/**
 * Called from onChatMessageCreated: for a coach message, snapshot the
 * recipients into chats/{g}/receipts/{m} (sender-only readable). For a
 * message that requires acknowledgment, also put an "acknowledgment
 * requested" entry in each recipient's inbox (no automatic reminders).
 */
export async function createReceipt(groupId: string, messageId: string, data: FirebaseFirestore.DocumentData, group: GroupLite, users: Map<string, UserLite>): Promise<void> {
  if (!receiptEligible(data)) return;
  const senderId = String(data.senderId ?? '');
  const recipientIds = receiptRecipients(group, users, senderId);
  const requiresAck = data.requiresAck === true;
  const ref = db.doc(`chats/${groupId}/receipts/${messageId}`);
  try {
    await ref.create({
      senderId, groupId, messageId, recipientIds, recipientCount: recipientIds.length,
      readCount: 0, ackCount: 0, requiresAck, createdAt: data.createdAt ?? FieldValue.serverTimestamp(),
    });
  } catch (e) {
    if ((e as { code?: number }).code === 6) return; // already created (retry)
    throw e;
  }
  if (requiresAck && recipientIds.length) {
    const text = String(data.text ?? '');
    await notify(recipientIds.map((u) => users.get(u)).filter((u): u is UserLite => !!u), {
      type: 'ackRequested',
      ...pushText('ackRequested', { group: group.name ?? '', text: text.length > 120 ? `${text.slice(0, 119)}…` : text }),
      route: `/chat/${groupId}`,
      args: { groupId, messageId },
      groupId,
      dedupeKey: `ack:${groupId}:${messageId}`,
      data: { groupId, messageId },
    });
  }
}

/** Recount from the subcollections (idempotent under at-least-once delivery). */
async function recount(groupId: string, messageId: string): Promise<void> {
  const ref = db.doc(`chats/${groupId}/receipts/${messageId}`);
  const msg = db.doc(`chats/${groupId}/messages/${messageId}`);
  const [r, reads, acks] = await Promise.all([ref.get(), msg.collection('msgReads').get(), msg.collection('msgAcks').get()]);
  if (!r.exists) return;
  const c = receiptCounts(r.get('recipientIds') ?? [], reads.docs.map((d) => d.id), acks.docs.map((d) => d.id));
  await ref.update({ readCount: c.readCount, ackCount: c.ackCount, updatedAt: FieldValue.serverTimestamp() });
}

export const onMessageReadCreated = onDocumentCreated('chats/{groupId}/messages/{messageId}/msgReads/{uid}', async (event) => {
  await recount(event.params.groupId, event.params.messageId);
});

/**
 * Acknowledgment: also guarantees a read record (an acknowledged message has
 * been seen) and writes an immutable audit entry. msgAcks docs are
 * create-only by rule and never deleted, also when the parent later leaves
 * the group or the message is deleted.
 */
export const onMessageAckCreated = onDocumentCreated('chats/{groupId}/messages/{messageId}/msgAcks/{uid}', async (event) => {
  const { groupId, messageId, uid } = event.params;
  const ackAt = event.data?.get('ackAt') ?? FieldValue.serverTimestamp();
  const readRef = db.doc(`chats/${groupId}/messages/${messageId}/msgReads/${uid}`);
  await readRef.create({ uid, groupId, messageId, readAt: ackAt }).catch((e) => {
    if ((e as { code?: number }).code !== 6) throw e;
  });
  await recount(groupId, messageId);
  const clubId = (await db.doc(`groups/${groupId}`).get()).get('clubId') ?? null;
  await writeAudit({
    action: 'chat.acknowledge', actorId: uid, actorRole: 'parent', targetType: 'chatMessage',
    targetId: `${groupId}/${messageId}`, clubId, details: { groupId, messageId },
  });
});

/** Deleted message: drop the receipt summary and read records; acknowledgments stay as audit. */
export const onChatMessageDeleted = onDocumentDeleted('chats/{groupId}/messages/{messageId}', async (event) => {
  const { groupId, messageId } = event.params;
  const reads = await db.collection(`chats/${groupId}/messages/${messageId}/msgReads`).get();
  const batch = db.batch();
  reads.docs.forEach((d) => batch.delete(d.ref));
  batch.delete(db.doc(`chats/${groupId}/receipts/${messageId}`));
  await batch.commit();
});

// ─── 4. Media downloads ────────────────────────────────────────────────────

/**
 * getMediaDownload {postId} → {url, fileName, mimeType, sizeBytes, expiresAt}
 * Live authorization (mediaDownloadDecision), 5-minute attachment URL,
 * download event in mediaDownloads/{id} + audit `media.download`. The
 * downloaded copy lives on the device and cannot be revoked remotely.
 */
export const getMediaDownload = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const uid = request.auth.uid;
  const postId = idArg(request.data?.postId, 'postId');
  const snap = await db.doc(`mediaPosts/${postId}`).get();
  const post = snap.exists ? snap.data()! : undefined;
  const user = await loadUser(uid);
  const groupIds: string[] = Array.isArray(post?.groupIds) ? post!.groupIds : [];
  const groups = groupIds.length
    ? (await db.getAll(...groupIds.map((g) => db.doc(`groups/${g}`)))).filter((s) => s.exists).map((s) => groupFrom(s.id, s.data()!))
    : [];
  const decision = mediaDownloadDecision(
    user,
    post ? { coachId: String(post.coachId ?? ''), groupIds, hidden: post.hidden === true, consentConfirmed: post.consentConfirmed !== false } : undefined,
    groups,
  );
  if (!decision.ok) {
    if (decision.reason === 'notFound') throw new HttpsError('not-found', 'post not found');
    throw new HttpsError('permission-denied', decision.reason);
  }
  await consumeRateLimit(uid, 'mediaDownloads');
  const path = String(post!.storagePath ?? '');
  if (!path.startsWith(`media/${post!.coachId}/${postId}/`)) throw new HttpsError('failed-precondition', 'unsupported media path');
  const file = bucket().file(path);
  const [meta] = await file.getMetadata().catch(() => [undefined]);
  if (!meta) throw new HttpsError('not-found', 'file missing');
  const mimeType = String(meta.contentType ?? (post!.type === 'video' ? 'video/mp4' : 'image/jpeg'));
  const fileName = downloadFileName({ id: postId, type: String(post!.type ?? 'photo') }, mimeType, path);
  const expiresAt = Date.now() + DOWNLOAD_URL_TTL_MS;
  const url = isEmulator
    ? `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199'}/v0/b/${bucket().name}/o/${encodeURIComponent(path)}?alt=media`
    : (await file.getSignedUrl({ version: 'v4', action: 'read', expires: expiresAt, responseDisposition: `attachment; filename="${fileName}"` }))[0];
  const groupId = groups.find((g) => g.parentIds.includes(uid))?.id ?? groupIds[0] ?? null;
  const clubId = String(post!.clubId ?? groups[0]?.clubId ?? '') || null;
  await db.collection('mediaDownloads').add({
    postId, userId: uid, role: user?.role ?? null, groupId, clubId, mediaType: post!.type ?? 'photo',
    at: FieldValue.serverTimestamp(),
  });
  await writeAudit({
    action: 'media.download', actorId: uid, actorRole: user?.role === 'coach' ? 'coach' : 'parent',
    targetType: 'mediaPost', targetId: postId, clubId, details: { groupId },
  });
  logger.info('media download authorized', { postId, role: user?.role });
  return { url, fileName, mimeType, sizeBytes: Number(meta.size ?? 0), expiresAt: new Date(expiresAt).toISOString() };
});
