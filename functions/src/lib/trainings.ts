// Pure decisions about training writes and reminders.

import { TrainingLite } from './types';

export type TrainingEvent =
  | { type: 'newTraining' }
  | { type: 'trainingChanged'; change: 'cancelled' | 'moved' }
  | { type: 'newPhotos'; added: number };

/**
 * Which notifications a training write should produce.
 * - create (before undefined)       -> newTraining
 * - status changed to "cancelled"    -> trainingChanged/cancelled
 * - startAt changed (not cancelled)  -> trainingChanged/moved
 * - photoUrls grew                   -> newPhotos
 * A status-only change to "moved" (e.g. the follow-up write the trigger makes
 * itself) produces nothing, so the trigger cannot loop.
 */
export function classifyTrainingWrite(before: TrainingLite | undefined, after: TrainingLite | undefined): TrainingEvent[] {
  if (!after) return [];
  if (!before) return after.status === 'cancelled' ? [] : [{ type: 'newTraining' }];

  const events: TrainingEvent[] = [];
  const cancelledNow = after.status === 'cancelled' && before.status !== 'cancelled';
  const moved = before.startAt.getTime() !== after.startAt.getTime();
  if (cancelledNow) {
    events.push({ type: 'trainingChanged', change: 'cancelled' });
  } else if (moved && after.status !== 'cancelled') {
    events.push({ type: 'trainingChanged', change: 'moved' });
  }
  const added = (after.photoUrls?.length ?? 0) - (before.photoUrls?.length ?? 0);
  if (added > 0 && after.status !== 'cancelled') events.push({ type: 'newPhotos', added });
  return events;
}

/**
 * Follow-up fields the trigger writes when a training's start time changed:
 * status -> "moved", previousStartAt, and a cleared reminderSentAt so the
 * 2-hour reminder fires again for the new time. Returns null if nothing to do.
 */
export function movedTrainingPatch(
  before: TrainingLite | undefined,
  after: TrainingLite | undefined,
): { status: 'moved'; previousStartAt: Date; clearReminder: boolean } | null {
  if (!before || !after) return null;
  if (before.startAt.getTime() === after.startAt.getTime()) return null;
  if (after.status === 'cancelled' || after.status === 'done') return null;
  return { status: 'moved', previousStartAt: before.startAt, clearReminder: true };
}

export const REMINDER_LEAD_MS = 2 * 60 * 60 * 1000;

/**
 * True if a 2-hour reminder is due: training is active (scheduled/moved),
 * starts within (now, now + 2h], and no reminder was sent yet.
 */
export function isTrainingReminderDue(t: TrainingLite, now: Date): boolean {
  if (t.status !== 'scheduled' && t.status !== 'moved') return false;
  if (t.reminderSentAt) return false;
  const delta = t.startAt.getTime() - now.getTime();
  return delta > 0 && delta <= REMINDER_LEAD_MS;
}
