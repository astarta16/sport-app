import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { bucket, db, isEmulator } from '../admin';
import { groupFrom, loadUser, loadUsers } from '../convert';
import { renderPush } from '../i18n/ka';
import { canViewMediaPost, computeReaderIds, parseMediaPath, validateMediaUpload } from '../lib/media';
import { groupParentUsers } from '../lib/recipients';
import { GroupLite } from '../lib/types';
import { notify } from '../notify';

const MEDIA_URL_TTL_MS = 15 * 60 * 1000;

async function loadGroups(ids: string[]): Promise<GroupLite[]> {
  const unique = [...new Set(ids.filter((x) => typeof x === 'string' && x && !x.includes('/')))];
  if (!unique.length) return [];
  const snaps = await db.getAll(...unique.map((id) => db.doc(`groups/${id}`)));
  return snaps.filter((s) => s.exists).map((s) => groupFrom(s.id, s.data()!));
}

/** Recomputes mediaPosts/{postId}.readerIds (server-managed; rules + Storage use it). */
export async function refreshMediaReaders(postId: string): Promise<void> {
  const ref = db.doc(`mediaPosts/${postId}`);
  const snap = await ref.get();
  if (!snap.exists) return;
  const groups = await loadGroups(snap.get('groupIds') ?? []);
  const readerIds = computeReaderIds(groups, snap.get('coachId'));
  const cur: string[] = snap.get('readerIds') ?? [];
  if (cur.length === readerIds.length && cur.every((u, i) => u === readerIds[i])) return;
  await ref.update({ readerIds });
}

export async function refreshMediaReadersForGroup(groupId: string): Promise<void> {
  const posts = await db.collection('mediaPosts').where('groupIds', 'array-contains', groupId).select().get();
  for (const p of posts.docs) await refreshMediaReaders(p.id);
}

/**
 * mediaPosts/{postId} written: maintain readerIds; on create, announce to the
 * group parents (inbox + push, type newMedia); on delete, remove the files.
 */
export const onMediaPostWritten = onDocumentWritten('mediaPosts/{postId}', async (event) => {
  const postId = event.params.postId;
  const before = event.data?.before.exists ? event.data.before.data()! : undefined;
  const after = event.data?.after.exists ? event.data.after.data()! : undefined;
  if (!after) {
    if (before?.coachId) {
      await bucket().deleteFiles({ prefix: `media/${before.coachId}/${postId}/` }).catch((e) =>
        logger.warn('media folder delete failed', { postId, error: String(e) }));
    }
    return;
  }
  await refreshMediaReaders(postId);
  if (before) return;
  const groups = await loadGroups(after.groupIds ?? []);
  for (const g of groups) {
    const parents = groupParentUsers(g, await loadUsers(g.parentIds));
    await notify(parents, {
      type: 'newMedia', ...renderPush('newMedia', { group: g.name ?? '', count: 1 }),
      route: `/media/${postId}`, args: { postId, groupId: g.id }, groupId: g.id,
      dedupeKey: `media:${postId}:${g.id}`, data: { postId },
    });
  }
});

/**
 * Storage upload under media/{coachId}/{postId}/{file}: the rules already
 * check type/size/ownership; this re-validates server-side and deletes
 * anything invalid (wrong type, too large, or no matching post by that coach).
 */
export const onMediaUpload = onObjectFinalized(async (event) => {
  const obj = event.data;
  const parsed = parseMediaPath(obj.name ?? '');
  if (!parsed) return;
  const verdict = validateMediaUpload(obj.contentType, Number(obj.size));
  let reason = verdict.ok ? '' : verdict.reason;
  if (!reason) {
    const post = await db.doc(`mediaPosts/${parsed.postId}`).get();
    if (!post.exists || post.get('coachId') !== parsed.coachId) reason = 'no_post';
  }
  if (reason) {
    await bucket().file(obj.name!).delete({ ignoreNotFound: true });
    logger.warn('invalid media upload deleted', { path: obj.name, reason });
  }
});

function signedOrEmulatorUrl(path: string, expiresAt: number): Promise<string> {
  if (isEmulator) {
    const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199';
    return Promise.resolve(`http://${host}/v0/b/${bucket().name}/o/${encodeURIComponent(path)}?alt=media`);
  }
  return bucket().file(path).getSignedUrl({ version: 'v4', action: 'read', expires: expiresAt }).then(([u]) => u);
}

/**
 * Callable {path} (or {postId, thumb?}) -> {url, expiresAt}: short-lived URL
 * after a LIVE membership check. Supported paths:
 *  - media/{coachId}/{postId}/{file}: owner coach, or parent / approved coach
 *    of any of the post's groups (hidden posts: owner and platform admin only);
 *  - trainingPhotos/{groupId}/… and chatAttachments/{groupId}/…: group
 *    parents and approved group coaches.
 * Production: V4 signed URL (15 min); emulator: direct emulator link.
 */
export const getMediaUrl = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const isPlatformAdmin = request.auth.token.admin === true;
  let path = typeof request.data?.path === 'string' ? request.data.path : '';
  const postIdArg = request.data?.postId;
  if (!path && typeof postIdArg === 'string' && postIdArg && !postIdArg.includes('/')) {
    const p = await db.doc(`mediaPosts/${postIdArg}`).get();
    if (!p.exists) throw new HttpsError('not-found', 'post not found');
    path = String((request.data?.thumb === true ? p.get('thumbPath') : p.get('storagePath')) ?? '');
  }
  if (!path || path.includes('..') || path.includes('//') || path.length > 500) throw new HttpsError('invalid-argument', 'path is required');
  const user = await loadUser(request.auth.uid);
  const userLite = user ? { uid: user.uid, role: user.role, coachStatus: user.coachStatus } : undefined;

  let allowed = false;
  const media = parseMediaPath(path);
  const groupScoped = /^(trainingPhotos|chatAttachments)\/([^/]+)\/.+$/.exec(path);
  if (media) {
    const snap = await db.doc(`mediaPosts/${media.postId}`).get();
    if (!snap.exists || snap.get('coachId') !== media.coachId) throw new HttpsError('not-found', 'post not found');
    const post = snap.data()!;
    const groups = await loadGroups(post.groupIds ?? []);
    allowed = isPlatformAdmin || canViewMediaPost(userLite, { coachId: post.coachId, groupIds: post.groupIds ?? [], hidden: post.hidden === true }, groups);
  } else if (groupScoped) {
    const groups = await loadGroups([groupScoped[2]]);
    allowed = isPlatformAdmin || canViewMediaPost(userLite, { coachId: '', groupIds: [groupScoped[2]] }, groups);
  } else {
    throw new HttpsError('invalid-argument', 'unsupported path');
  }
  if (!allowed) throw new HttpsError('permission-denied', 'no access to this file');
  const expiresAt = Date.now() + MEDIA_URL_TTL_MS;
  return { url: await signedOrEmulatorUrl(path, expiresAt), expiresAt: new Date(expiresAt).toISOString() };
});
