import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { db } from '../admin';
import { childFrom, loadUsers, toDate } from '../convert';
import { pushText, t } from '../i18n';
import { formatShortDate } from '../lib/dates';
import { attendanceDedupeKey, attendanceNotice, attendanceWordKey, feedbackNotice } from '../lib/progressNotices';
import { UserLite } from '../lib/types';
import { notify } from '../notify';

async function parentsOf(childId: string) {
  const snap = await db.doc(`children/${childId}`).get();
  if (!snap.exists) return undefined;
  const child = childFrom(snap.id, snap.data()!);
  const users = await loadUsers(child.parentIds);
  const parents = child.parentIds.map((u) => users.get(u)).filter((u): u is UserLite => !!u && u.role === 'parent');
  return { child, parents };
}

/**
 * attendance/{trainingId_childId} written by a coach: tell the child's
 * parents (category "attendance", honours notificationPrefs). One inbox entry
 * per status value, so re-saving a sheet never repeats it.
 */
export const onAttendanceWritten = onDocumentWritten('attendance/{attendanceId}', async (event) => {
  const before = event.data?.before.exists ? event.data.before.data() : undefined;
  const after = event.data?.after.exists ? event.data.after.data() : undefined;
  const status = attendanceNotice(before, after);
  if (!status || !after) return;
  const childId = String(after.childId ?? '');
  const res = childId ? await parentsOf(childId) : undefined;
  if (!res || res.parents.length === 0) return;
  const training = await db.doc(`trainings/${after.trainingId}`).get();
  const startAt = toDate(training.data()?.startAt) ?? toDate(after.markedAt) ?? new Date();
  const date = formatShortDate(startAt);
  const out = await notify(res.parents, {
    type: 'attendanceRecorded',
    ...pushText('attendanceRecorded', (l) => ({ child: res.child.firstName, status: t(l, attendanceWordKey(status)), date })),
    route: `/children/${childId}/progress`,
    args: { child: res.child.firstName, status, trainingId: String(after.trainingId ?? '') },
    childId,
    groupId: typeof after.groupId === 'string' ? after.groupId : null,
    dedupeKey: attendanceDedupeKey(event.params.attendanceId, status),
    data: { childId },
  });
  logger.info('attendance notification', { attendanceId: event.params.attendanceId, status, ...out });
});

/** feedback/{id} created (always parent-visible by rule): tell the child's parents. */
export const onFeedbackWritten = onDocumentWritten('feedback/{feedbackId}', async (event) => {
  const before = event.data?.before.exists ? event.data.before.data() : undefined;
  const after = event.data?.after.exists ? event.data.after.data() : undefined;
  if (!feedbackNotice(before, after) || !after) return;
  const childId = String(after.childId);
  const res = await parentsOf(childId);
  if (!res || res.parents.length === 0) return;
  const coach = typeof after.coachName === 'string' && after.coachName.trim() ? after.coachName.trim() : '—';
  const out = await notify(res.parents, {
    type: 'feedbackAdded',
    ...pushText('feedbackAdded', { child: res.child.firstName, coach }),
    route: `/children/${childId}/progress`,
    args: { child: res.child.firstName },
    childId,
    groupId: typeof after.groupId === 'string' ? after.groupId : null,
    dedupeKey: `fb:${event.params.feedbackId}`,
    data: { childId },
  });
  logger.info('feedback notification', { feedbackId: event.params.feedbackId, ...out });
});
