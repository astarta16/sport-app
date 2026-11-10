// Pure media validation and reader computation.

export const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
export const MAX_VIDEO_BYTES = 100 * 1024 * 1024;

export type MediaUploadVerdict = { ok: true; kind: 'photo' | 'video' } | { ok: false; reason: string };

export function validateMediaUpload(contentType: string | undefined, size: number): MediaUploadVerdict {
  const ct = (contentType ?? '').toLowerCase();
  if (!Number.isFinite(size) || size <= 0) return { ok: false, reason: 'empty' };
  if (ct.startsWith('image/')) return size < MAX_IMAGE_BYTES ? { ok: true, kind: 'photo' } : { ok: false, reason: 'image_too_large' };
  if (ct.startsWith('video/')) return size < MAX_VIDEO_BYTES ? { ok: true, kind: 'video' } : { ok: false, reason: 'video_too_large' };
  return { ok: false, reason: 'content_type' };
}

/** Parses `media/{coachId}/{postId}/{file}`; null for any other path. */
export function parseMediaPath(path: string): { coachId: string; postId: string; file: string } | null {
  const m = /^media\/([^/]+)\/([^/]+)\/([^/]+)$/.exec(path);
  return m ? { coachId: m[1], postId: m[2], file: m[3] } : null;
}

/** mediaPosts.readerIds: union of coachIds and parentIds of the post's groups (sorted). */
export function computeReaderIds(groups: Array<{ coachIds?: string[]; parentIds?: string[] }>, ownerId?: string): string[] {
  const s = new Set<string>();
  for (const g of groups) {
    (g.coachIds ?? []).forEach((u) => s.add(u));
    (g.parentIds ?? []).forEach((u) => s.add(u));
  }
  if (ownerId) s.add(ownerId);
  return [...s].sort();
}

/** Can the user see the post right now (live membership, not readerIds)? */
export function canViewMediaPost(
  user: { uid: string; role: string; coachStatus?: string } | undefined,
  post: { coachId: string; groupIds: string[]; hidden?: boolean },
  groups: Array<{ id: string; coachIds: string[]; parentIds: string[] }>,
): boolean {
  if (!user) return false;
  if (user.uid === post.coachId) return true;
  if (post.hidden) return false;
  const relevant = groups.filter((g) => post.groupIds.includes(g.id));
  if (user.role === 'parent') return relevant.some((g) => g.parentIds.includes(user.uid));
  if (user.role === 'coach' && user.coachStatus === 'approved') return relevant.some((g) => g.coachIds.includes(user.uid));
  return false;
}
