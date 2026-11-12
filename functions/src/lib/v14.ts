// v1.4 pure decisions: scoped phone contacts, chat read receipts /
// acknowledgments and parent media downloads. Firebase-free, unit-tested in
// test/v14.test.ts; the triggers in triggers/v14.ts only load data.
import { GroupLite, UserLite } from './types';

const activeGroups = (groups: GroupLite[]) => groups.filter((g) => g.status !== 'archived');

const isApprovedCoach = (u: UserLite | undefined) => !!u && u.role === 'coach' && u.coachStatus === 'approved';

/**
 * Phone visibility between two users, decided ONLY by current, active group
 * relationships:
 *  - an approved coach sees the phones of parents with a child in one of
 *    the coach's active groups;
 *  - a parent sees the phones of approved coaches of an active group their
 *    child belongs to.
 * Parents never see other parents; pending/suspended coaches see nothing and
 * are never shown. Admins get nothing from this path (admin web has its own,
 * audited views).
 */
export function canSeeContactPhone(caller: UserLite | undefined, target: UserLite | undefined, groups: GroupLite[]): boolean {
  if (!caller || !target || caller.uid === target.uid) return false;
  const live = activeGroups(groups);
  if (isApprovedCoach(caller) && target.role === 'parent') {
    return live.some((g) => g.coachIds.includes(caller.uid) && g.parentIds.includes(target.uid));
  }
  if (caller.role === 'parent' && isApprovedCoach(target)) {
    return live.some((g) => g.parentIds.includes(caller.uid) && g.coachIds.includes(target.uid));
  }
  return false;
}

export interface ContactChild {
  id: string;
  firstName: string;
  /** guardianRelations[parentUid] of the child, when recorded. */
  relation?: string | null;
}

export interface ContactEntry {
  uid: string;
  role: 'parent' | 'coach';
  name: string;
  phone: string | null;
  /** Parents only: their children in this group (first names). */
  children: ContactChild[];
}

export interface ChildForContacts {
  id: string;
  firstName: string;
  parentIds: string[];
  guardianRelations?: Record<string, string>;
}

/**
 * Contact projection of ONE group for the caller. Coach of the group →
 * the group's parents (with their children in the group and relation);
 * parent with a child in the group → the group's approved coaches.
 * Anyone else (incl. pending coaches, other groups, archived group) → null.
 */
export function groupContactsFor(
  caller: UserLite | undefined,
  group: GroupLite,
  users: Map<string, UserLite>,
  children: ChildForContacts[],
): ContactEntry[] | null {
  if (!caller || group.status === 'archived') return null;
  const name = (u: UserLite) => [u.firstName, u.lastName].filter(Boolean).join(' ').trim();
  if (isApprovedCoach(caller) && group.coachIds.includes(caller.uid)) {
    const members = children.filter((c) => group.memberChildIds.includes(c.id));
    return group.parentIds
      .map((id) => users.get(id))
      .filter((u): u is UserLite => !!u && u.role === 'parent')
      .map((u) => ({
        uid: u.uid,
        role: 'parent' as const,
        name: name(u),
        phone: u.phone ?? null,
        children: members
          .filter((c) => c.parentIds.includes(u.uid))
          .map((c) => ({ id: c.id, firstName: c.firstName, relation: c.guardianRelations?.[u.uid] ?? null })),
      }));
  }
  if (caller.role === 'parent' && group.parentIds.includes(caller.uid)) {
    return group.coachIds
      .map((id) => users.get(id))
      .filter((u): u is UserLite => isApprovedCoach(u))
      .map((u) => ({ uid: u.uid, role: 'coach' as const, name: name(u), phone: u.phone ?? null, children: [] }));
  }
  return null;
}

// ─── Read receipts / acknowledgments ───────────────────────────────────────

/** Coach-sent text/announcement messages get receipts; system and parent messages do not. */
export function receiptEligible(m: { senderRole?: unknown; type?: unknown }): boolean {
  const type = m.type ?? 'text';
  return m.senderRole === 'coach' && (type === 'text' || type === 'announcement');
}

/**
 * Recipient snapshot at creation: unique parent ACCOUNTS of the group at that
 * moment (several guardians of one child count separately; a parent with two
 * children in the group counts once). Later members never become recipients.
 */
export function receiptRecipients(group: GroupLite, users: Map<string, UserLite>, senderId: string): string[] {
  const out: string[] = [];
  for (const id of group.parentIds) {
    if (id === senderId || out.includes(id)) continue;
    const u = users.get(id);
    if (u && u.role === 'parent') out.push(id);
  }
  return out.sort();
}

export type ReceiptState = 'notSeen' | 'seen' | 'acknowledged';

/** Per-recipient state; an acknowledgment implies having seen the message. */
export function receiptState(uid: string, reads: Set<string>, acks: Set<string>): ReceiptState {
  if (acks.has(uid)) return 'acknowledged';
  return reads.has(uid) ? 'seen' : 'notSeen';
}

/** Counters over the snapshot only (ids outside it never count). */
export function receiptCounts(recipientIds: string[], reads: Iterable<string>, acks: Iterable<string>) {
  const r = new Set(recipientIds);
  const readSet = new Set([...reads].filter((x) => r.has(x)));
  const ackSet = new Set([...acks].filter((x) => r.has(x)));
  for (const a of ackSet) readSet.add(a);
  return { recipientCount: r.size, readCount: readSet.size, ackCount: ackSet.size };
}

// ─── Media downloads ───────────────────────────────────────────────────────

export type DownloadDenial = 'notFound' | 'hidden' | 'notMember' | 'policy' | 'role';

/**
 * Parent download of a coach media post: the post must be visible (not
 * hidden by moderation), published with the coach's consent confirmation,
 * and the parent must CURRENTLY have a child in an ACTIVE group of the post
 * whose media policy allows downloads. The owning coach may always download
 * their own upload. Medical documents never go through this path.
 */
export function mediaDownloadDecision(
  user: UserLite | undefined,
  post: { coachId: string; groupIds: string[]; hidden?: boolean; consentConfirmed?: boolean } | undefined,
  groups: GroupLite[],
): { ok: true } | { ok: false; reason: DownloadDenial } {
  if (!post) return { ok: false, reason: 'notFound' };
  if (!user) return { ok: false, reason: 'role' };
  if (user.uid === post.coachId) return { ok: true };
  if (post.hidden) return { ok: false, reason: 'hidden' };
  if (user.role !== 'parent') return { ok: false, reason: 'role' };
  if (post.consentConfirmed === false) return { ok: false, reason: 'policy' };
  const mine = activeGroups(groups).filter((g) => post.groupIds.includes(g.id) && g.parentIds.includes(user.uid));
  if (!mine.length) return { ok: false, reason: 'notMember' };
  if (!mine.some((g) => g.mediaDownloadsEnabled !== false)) return { ok: false, reason: 'policy' };
  return { ok: true };
}

const EXT: Record<string, string> = {
  'image/jpeg': 'jpg', 'image/png': 'png', 'image/heic': 'heic', 'image/webp': 'webp',
  'video/mp4': 'mp4', 'video/quicktime': 'mov', 'video/webm': 'webm',
};

/** sportparent_{type}_{postId}.{ext} — ASCII only, safe for Content-Disposition. */
export function downloadFileName(post: { id: string; type: string }, mimeType: string | undefined, storagePath: string): string {
  const fromPath = /\.([A-Za-z0-9]{2,5})$/.exec(storagePath)?.[1]?.toLowerCase();
  const ext = (mimeType && EXT[mimeType]) || fromPath || (post.type === 'video' ? 'mp4' : 'jpg');
  const id = post.id.replace(/[^A-Za-z0-9_-]/g, '');
  return `sportparent_${post.type === 'video' ? 'video' : 'photo'}_${id}.${ext}`;
}
