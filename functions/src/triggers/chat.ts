import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { loadGroup, loadUsers } from '../convert';
import { renderPush, truncate } from '../i18n/ka';
import { selectChatRecipients } from '../lib/recipients';
import { sendPushToUsers } from '../push';

/**
 * 4. New chat message -> push to group coaches + parents except the sender.
 *    Child accounts are never recipients (role filter in selectChatRecipients).
 */
export const onChatMessageCreated = onDocumentCreated('chats/{groupId}/messages/{messageId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const group = await loadGroup(event.params.groupId);
  if (!group) return;
  const users = await loadUsers([...group.coachIds, ...group.parentIds]);
  const recipients = selectChatRecipients(group, users, String(data.senderId ?? ''));
  if (recipients.length === 0) return;
  const msg = renderPush('chatMessage', {
    sender: String(data.senderName ?? ''),
    group: group.name ?? '',
    text: truncate(String(data.text ?? ''), 120),
  });
  const delivered = await sendPushToUsers(recipients, {
    ...msg,
    data: { type: 'chatMessage', groupId: group.id, messageId: event.params.messageId },
  });
  logger.info('chat push', { groupId: group.id, recipients: recipients.length, delivered });
});
