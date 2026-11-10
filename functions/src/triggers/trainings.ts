import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../admin';
import { TIMEZONE } from '../config';
import { loadChildren, loadGroup, loadUsers, trainingFrom } from '../convert';
import { SYSTEM_MESSAGES_KA, renderPush, renderTemplate } from '../i18n/ka';
import { cancelReasonText } from '../lib/cancel';
import { formatShortDate, formatTime } from '../lib/dates';
import { selectTrainingRecipients } from '../lib/recipients';
import { SCHEDULE_CHANGED_REASON } from '../lib/series';
import {
  REMINDER_LEAD_MS, TrainingEvent, classifyTrainingWrite, isTrainingReminderDue, movedTrainingPatch,
} from '../lib/trainings';
import { ChildLite, TrainingLite } from '../lib/types';
import { notify } from '../notify';
import { postSystemMessage } from './chat';

function pushFor(ev: TrainingEvent, t: TrainingLite, groupName: string) {
  const vars = { group: groupName, date: formatShortDate(t.startAt), time: formatTime(t.startAt) };
  switch (ev.type) {
    case 'newTraining':
      return renderPush('newTraining', vars);
    case 'trainingChanged':
      if (ev.change === 'cancelled') {
        const reason = cancelReasonText(t.cancelReasonCode, t.cancelReason);
        return reason ? renderPush('trainingCancelledReason', { ...vars, reason }) : renderPush('trainingCancelled', vars);
      }
      return renderPush('trainingMoved', vars);
    case 'newPhotos':
      return renderPush('newPhotos', { ...vars, count: ev.added });
  }
}

function dedupeKeyFor(ev: TrainingEvent, trainingId: string, t: TrainingLite): string {
  switch (ev.type) {
    case 'newTraining':
      return `training:${trainingId}:new`;
    case 'trainingChanged':
      return ev.change === 'cancelled' ? `training:${trainingId}:cancelled` : `training:${trainingId}:moved:${t.startAt.getTime()}`;
    case 'newPhotos':
      return `training:${trainingId}:photos:${t.photoUrls?.length ?? 0}`;
  }
}

/**
 * Occurrences managed by a series (seriesId set, not detached) are announced
 * by ONE summary notification from onSeriesWritten, so per-occurrence
 * "new"/"moved" pushes and schedule-change cancellations are suppressed.
 */
export function suppressedBySeries(ev: TrainingEvent, t: TrainingLite): boolean {
  if (!t.seriesId || t.detached) return false;
  if (ev.type === 'newTraining') return true;
  if (ev.type === 'trainingChanged' && ev.change === 'moved') return true;
  if (ev.type === 'trainingChanged' && ev.change === 'cancelled' && t.cancelReason === SCHEDULE_CHANGED_REASON) return true;
  return false;
}

/**
 * 1. Training notifications: newTraining / trainingChanged / newPhotos to the
 *    group's parents (group.parentIds only), persisted to the inbox and
 *    pushed honouring notificationPrefs; for photos, only families with a
 *    consenting child. Cancellation also posts a system chat message with the reason.
 *    When startAt changes, the trigger sets status "moved", previousStartAt
 *    and clears reminderSentAt (not for series-managed occurrences).
 */
export const onTrainingWritten = onDocumentWritten('trainings/{trainingId}', async (event) => {
  const change = event.data;
  if (!change) return;
  const trainingId = event.params.trainingId;
  const before = change.before.exists ? trainingFrom(change.before.data()!) : undefined;
  const after = change.after.exists ? trainingFrom(change.after.data()!) : undefined;
  if (!after) return;

  const patch = movedTrainingPatch(before, after);
  if (patch && !(after.seriesId && !after.detached)) {
    await change.after.ref.update({
      status: patch.status,
      previousStartAt: Timestamp.fromDate(patch.previousStartAt),
      reminderSentAt: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } else if (patch && after.reminderSentAt) {
    await change.after.ref.update({ reminderSentAt: FieldValue.delete() });
  }

  const events = classifyTrainingWrite(before, after).filter((ev) => !suppressedBySeries(ev, after));
  if (events.length === 0) return;

  const group = await loadGroup(after.groupId);
  if (!group) {
    logger.warn('training references missing group', { trainingId, groupId: after.groupId });
    return;
  }
  const users = await loadUsers(group.parentIds);
  let children: ChildLite[] = [];
  if (events.some((e) => e.type === 'newPhotos')) {
    children = [...(await loadChildren(group.memberChildIds)).values()];
  }

  for (const ev of events) {
    const recipients = selectTrainingRecipients({ group, users, type: ev.type, children, ignorePrefs: true });
    const msg = pushFor(ev, after, group.name ?? '');
    const res = await notify(recipients, {
      type: ev.type,
      ...msg,
      route: `/training/${trainingId}`,
      args: { trainingId, groupId: group.id },
      groupId: group.id,
      dedupeKey: dedupeKeyFor(ev, trainingId, after),
      data: { trainingId },
    });
    if (ev.type === 'trainingChanged' && ev.change === 'cancelled') {
      const text = renderTemplate(SYSTEM_MESSAGES_KA.trainingCancelled, {
        date: formatShortDate(after.startAt),
        time: formatTime(after.startAt),
        reason: cancelReasonText(after.cancelReasonCode, after.cancelReason) || '—',
      });
      await postSystemMessage(group.id, `system_training_${trainingId}_cancelled`, text);
    }
    logger.info('training notification', { type: ev.type, trainingId, recipients: recipients.length, ...res });
  }
});

/**
 * 2. Every 15 minutes: 2-hour reminders. Idempotent — reminderSentAt is
 *    claimed inside a transaction before the push is sent (and the inbox id
 *    is deterministic per training start time).
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
      const recipients = selectTrainingRecipients({ group, users, type: 'trainingReminder', ignorePrefs: true });
      const msg = renderPush('trainingReminder', { group: group.name ?? '', time: formatTime(t.startAt) });
      await notify(recipients, {
        type: 'trainingReminder', ...msg, route: `/training/${doc.id}`, args: { trainingId: doc.id, groupId: group.id },
        groupId: group.id, dedupeKey: `training:${doc.id}:reminder:${t.startAt.getTime()}`, data: { trainingId: doc.id },
      });
      sent++;
    }
    logger.info('training reminders run', { candidates: snap.size, sent });
  },
);
