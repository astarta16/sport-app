import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../admin';
import { TIMEZONE } from '../config';
import { loadChildren, loadGroup, loadUsers, trainingFrom } from '../convert';
import { sendPushToUsers } from '../push';
import { renderPush } from '../i18n/ka';
import { formatShortDate, formatTime } from '../lib/dates';
import { selectTrainingRecipients } from '../lib/recipients';
import {
  REMINDER_LEAD_MS, TrainingEvent, classifyTrainingWrite, isTrainingReminderDue, movedTrainingPatch,
} from '../lib/trainings';
import { ChildLite, TrainingLite } from '../lib/types';

function pushFor(ev: TrainingEvent, t: TrainingLite, groupName: string) {
  const vars = { group: groupName, date: formatShortDate(t.startAt), time: formatTime(t.startAt) };
  switch (ev.type) {
    case 'newTraining':
      return renderPush('newTraining', vars);
    case 'trainingChanged':
      return renderPush(ev.change === 'cancelled' ? 'trainingCancelled' : 'trainingMoved', vars);
    case 'newPhotos':
      return renderPush('newPhotos', { ...vars, count: ev.added });
  }
}

/**
 * 1. Training notifications: newTraining / trainingChanged / newPhotos to the
 *    group's parents (group.parentIds only), honouring notificationPrefs and,
 *    for photos, the children's photoConsent.
 *    When startAt changes, the trigger also sets status "moved",
 *    previousStartAt and clears reminderSentAt.
 */
export const onTrainingWritten = onDocumentWritten('trainings/{trainingId}', async (event) => {
  const change = event.data;
  if (!change) return;
  const before = change.before.exists ? trainingFrom(change.before.data()!) : undefined;
  const after = change.after.exists ? trainingFrom(change.after.data()!) : undefined;
  if (!after) return;

  const patch = movedTrainingPatch(before, after);
  if (patch) {
    await change.after.ref.update({
      status: patch.status,
      previousStartAt: Timestamp.fromDate(patch.previousStartAt),
      reminderSentAt: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  const events = classifyTrainingWrite(before, after);
  if (events.length === 0) return;

  const group = await loadGroup(after.groupId);
  if (!group) {
    logger.warn('training references missing group', { trainingId: event.params.trainingId, groupId: after.groupId });
    return;
  }
  const users = await loadUsers(group.parentIds);
  let children: ChildLite[] = [];
  if (events.some((e) => e.type === 'newPhotos')) {
    children = [...(await loadChildren(group.memberChildIds)).values()];
  }

  for (const ev of events) {
    const recipients = selectTrainingRecipients({ group, users, type: ev.type, children });
    if (recipients.length === 0) continue;
    const msg = pushFor(ev, after, group.name ?? '');
    const delivered = await sendPushToUsers(recipients, {
      ...msg,
      data: { type: ev.type, trainingId: event.params.trainingId, groupId: group.id },
    });
    logger.info('training push', { type: ev.type, trainingId: event.params.trainingId, recipients: recipients.length, delivered });
  }
});

/**
 * 2. Every 15 minutes: 2-hour reminders. Idempotent — reminderSentAt is
 *    claimed inside a transaction before the push is sent.
 */
export const sendTrainingReminders = onSchedule(
  { schedule: 'every 15 minutes', timeZone: TIMEZONE },
  async () => {
    const now = new Date();
    const snap = await db
      .collection('trainings')
      .where('startAt', '>', Timestamp.fromDate(now))
      .where('startAt', '<=', Timestamp.fromDate(new Date(now.getTime() + REMINDER_LEAD_MS)))
      .get();

    let sent = 0;
    for (const doc of snap.docs) {
      if (!isTrainingReminderDue(trainingFrom(doc.data()), now)) continue;
      const claimed = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(doc.ref);
        if (!fresh.exists || !isTrainingReminderDue(trainingFrom(fresh.data()!), now)) return false;
        tx.update(doc.ref, { reminderSentAt: FieldValue.serverTimestamp() });
        return true;
      });
      if (!claimed) continue;

      const t = trainingFrom(doc.data());
      const group = await loadGroup(t.groupId);
      if (!group) continue;
      const users = await loadUsers(group.parentIds);
      const recipients = selectTrainingRecipients({ group, users, type: 'trainingReminder' });
      const msg = renderPush('trainingReminder', { group: group.name ?? '', time: formatTime(t.startAt) });
      await sendPushToUsers(recipients, { ...msg, data: { type: 'trainingReminder', trainingId: doc.id, groupId: group.id } });
      sent++;
    }
    logger.info('training reminders run', { candidates: snap.size, sent });
  },
);
