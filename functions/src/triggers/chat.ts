import { logger } from 'firebase-functions';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../admin';
import { loadGroup, loadUsers } from '../convert';
import { Locale, normalizeLocale, pushText } from '../i18n';
import { truncate } from '../i18n/ka';
import { groupMemberUsers, selectChatRecipients } from '../lib/recipients';
import { resetGroupUnread, unreadRecipients } from '../lib/unread';
import { notify } from '../notify';
import { sendPushToUsers } from '../push';

export const SYSTEM_SENDER = 'system';

/**
 * Writes a server-only chat message (type 'system'). The id is deterministic,
 * so repeated trigger runs never post twice.
 */
export async function postSystemMessage(
  groupId: string,
  messageId: string,
  text: string,
  system?: { key: string; args: Record<string, string> },
): Promise<boolean> {
  try {
    await db.doc(`chats/${groupId}/messages/${messageId}`).create({
      senderId: SYSTEM_SENDER,
      senderName: '',
      senderRole: SYSTEM_SENDER,
      type: 'system',
      pinned: false,
      // Georgian fallback; v1.3 readers render systemKey + systemArgs in their own language.
      text,
      ...(system ? { systemKey: system.key, systemArgs: system.args } : {}),
      createdAt: FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    if ((e as { code?: number }).code === 6) return false; // already exists
    throw e;
  }
}

/**
 * 4. New chat message:
 *  - updateUnread: increments userUnread/{uid}.byGroup[groupId] and .total for
 *    every chat member (approved group coaches + group parents) except the sender;
 *  - announcements are forced to pinned and land in the inbox (category announcements);
 *  - push to members except the sender for normal messages (system messages
 *    are already announced by the trigger that wrote them).
 */
export const onChatMessageCreated = onDocumentCreated('chats/{groupId}/messages/{messageId}', async (event) => {
  const snap = event.data;
  const data = snap?.data();
  if (!snap || !data) return;
  const { groupId, messageId } = event.params;
  const group = await loadGroup(groupId);
  if (!group) return;
  const users = await loadUsers([...group.coachIds, ...group.parentIds]);
  const senderId = String(data.senderId ?? '');
  const type = data.type === 'announcement' || data.type === 'system' ? data.type : 'text';

  // Unread counters.
  const members = groupMemberUsers(group, users).map((u) => u.uid);
  const targets = unreadRecipients(members, senderId);
  if (targets.length) {
    const batch = db.batch();
    for (const uid of targets) {
      batch.set(
        db.doc(`userUnread/${uid}`),
        { total: FieldValue.increment(1), byGroup: { [groupId]: FieldValue.increment(1) }, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
    await batch.commit();
  }

  if (type === 'announcement') {
    if (data.pinned !== true) await snap.ref.update({ pinned: true });
    const recipients = groupMemberUsers(group, users).filter((u) => u.uid !== senderId);
    const msg = pushText('announcement', { group: group.name ?? '', text: truncate(String(data.text ?? ''), 120) });
    await notify(recipients, {
      type: 'announcement', ...msg, route: `/chat/${groupId}`, args: { groupId, messageId },
      groupId, dedupeKey: `announcement:${groupId}:${messageId}`,
    });
    return;
  }
  if (type === 'system') return;

  const recipients = selectChatRecipients(group, users, senderId);
  if (recipients.length === 0) return;
  const msg = pushText('chatMessage', {
    sender: String(data.senderName ?? ''),
    group: group.name ?? '',
    text: truncate(String(data.text ?? ''), 120),
  });
  const byLocale = new Map<Locale, typeof recipients>();
  for (const u of recipients) {
    const l = normalizeLocale(u.locale);
    byLocale.set(l, [...(byLocale.get(l) ?? []), u]);
  }
  let delivered = 0;
  for (const [l, us] of byLocale) {
    delivered += await sendPushToUsers(us, { ...msg.localized(l), data: { type: 'chatMessage', groupId: group.id, messageId } });
  }
  logger.info('chat push', { groupId: group.id, recipients: recipients.length, delivered, unread: targets.length });
});

/**
 * chats/{groupId}/members/{uid} written (owner sets lastReadAt): reset that
 * group's unread count for the user and recompute the total.
 */
export const onChatMemberWritten = onDocumentWritten('chats/{groupId}/members/{uid}', async (event) => {
  const after = event.data?.after.exists ? event.data.after.data() : undefined;
  if (!after?.lastReadAt) return;
  const before = event.data?.before.exists ? event.data.before.data() : undefined;
  if (before?.lastReadAt && before.lastReadAt.isEqual?.(after.lastReadAt)) return;
  const { groupId, uid } = event.params;
  const ref = db.doc(`userUnread/${uid}`);
  await db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    const next = resetGroupUnread(cur.exists ? cur.data() : undefined, groupId);
    tx.set(ref, { ...next, updatedAt: FieldValue.serverTimestamp() });
  });
});
