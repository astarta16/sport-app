// Pure, role-based recipient selection for push notifications.
// Rule of thumb: training-related pushes go ONLY to parents listed in
// group.parentIds; chat pushes go to group coaches + parents; child accounts
// never receive any of them.

import { ChildLite, GroupLite, NotificationType, UserLite, prefEnabled } from './types';

export interface TrainingRecipientInput {
  group: GroupLite;
  /** Users keyed by uid; missing users are skipped. */
  users: Map<string, UserLite>;
  type: NotificationType;
  /** Children of the group; required for `newPhotos` (photo-consent check). */
  children?: ChildLite[];
  excludeUid?: string;
  /** Inbox recipients: skip the notificationPrefs filter (push prefs are applied by notify()). */
  ignorePrefs?: boolean;
}

/**
 * Parents of a group who should receive a training notification.
 *
 * - only uids in group.parentIds, and only users whose role is "parent";
 * - the recipient's notificationPrefs[type] must not be false;
 * - for "newPhotos": the parent must have at least one child in the group
 *   whose photoConsent is true (photos of children without consent must not
 *   be advertised to that family).
 */
export function selectTrainingRecipients(input: TrainingRecipientInput): UserLite[] {
  const { group, users, type, children = [], excludeUid, ignorePrefs = false } = input;
  const consentingParents = new Set<string>();
  if (type === 'newPhotos') {
    for (const c of children) {
      if (c.photoConsent === true && group.memberChildIds.includes(c.id)) {
        c.parentIds.forEach((p) => consentingParents.add(p));
      }
    }
  }

  const out: UserLite[] = [];
  const seen = new Set<string>();
  for (const uid of group.parentIds) {
    if (seen.has(uid) || uid === excludeUid) continue;
    seen.add(uid);
    const u = users.get(uid);
    if (!u || u.role !== 'parent') continue;
    if (!ignorePrefs && !prefEnabled(u, type)) continue;
    if (type === 'newPhotos' && !consentingParents.has(uid)) continue;
    out.push(u);
  }
  return out;
}

/**
 * Chat members to notify about a new message: approved coaches in
 * group.coachIds and parents in group.parentIds, excluding the sender, never
 * child accounts, respecting the chatMessage preference.
 */
export function selectChatRecipients(
  group: GroupLite,
  users: Map<string, UserLite>,
  senderId: string,
): UserLite[] {
  const out: UserLite[] = [];
  const seen = new Set<string>([senderId]);
  const consider = (uid: string, expectedRole: 'coach' | 'parent') => {
    if (seen.has(uid)) return;
    seen.add(uid);
    const u = users.get(uid);
    if (!u || u.role !== expectedRole) return;
    if (expectedRole === 'coach' && u.coachStatus !== 'approved') return;
    if (!prefEnabled(u, 'chatMessage')) return;
    out.push(u);
  };
  group.coachIds.forEach((uid) => consider(uid, 'coach'));
  group.parentIds.forEach((uid) => consider(uid, 'parent'));
  return out;
}

/** Parents of a child who want certificate-expiry pushes. */
export function selectCertificateRecipients(child: ChildLite, users: Map<string, UserLite>): UserLite[] {
  return child.parentIds
    .map((uid) => users.get(uid))
    .filter((u): u is UserLite => !!u && u.role === 'parent' && prefEnabled(u, 'certificateExpiry'));
}

/** Flattens the FCM tokens of a set of users, de-duplicated. */
export function collectTokens(users: UserLite[]): string[] {
  return [...new Set(users.flatMap((u) => u.fcmTokens ?? []).filter((t) => typeof t === 'string' && t.length > 0))];
}

/** Approved coaches + parents of a group (chat members), never child accounts. */
export function groupMemberUsers(group: GroupLite, users: Map<string, UserLite>): UserLite[] {
  const out: UserLite[] = [];
  const seen = new Set<string>();
  for (const uid of [...group.coachIds, ...group.parentIds]) {
    if (seen.has(uid)) continue;
    seen.add(uid);
    const u = users.get(uid);
    if (!u) continue;
    if (u.role === 'coach' && u.coachStatus === 'approved' && group.coachIds.includes(uid)) out.push(u);
    else if (u.role === 'parent' && group.parentIds.includes(uid)) out.push(u);
  }
  return out;
}

/** Parents of a group (role parent, in group.parentIds), ignoring prefs. */
export function groupParentUsers(group: GroupLite, users: Map<string, UserLite>): UserLite[] {
  return group.parentIds.map((u) => users.get(u)).filter((u): u is UserLite => !!u && u.role === 'parent');
}
