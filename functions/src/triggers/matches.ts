import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { DocumentData, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../admin';
import { TIMEZONE } from '../config';
import { loadGroup, loadUsers, toDate } from '../convert';
import { cancelReasonTextL, pushText, t } from '../i18n';
import { formatShortDate, formatTime } from '../lib/dates';
import {
  MATCH_REMINDER_1D_MS, MatchLite, classifyMatchWrite, matchReminderFields, matchReminderStage, movedMatchPatch,
} from '../lib/matches';
import { groupParentUsers } from '../lib/recipients';
import { notify } from '../notify';
import { postSystemMessage } from './chat';

export function matchFrom(d: DocumentData): MatchLite & { cancelReasonCode?: string; cancelReason?: string } {
  return {
    groupId: d.groupId,
    startAt: toDate(d.startAt) ?? new Date(0),
    status: d.status,
    opponentName: d.opponentName ?? '',
    reminder1dSentAt: toDate(d.reminder1dSentAt) ?? null,
    reminder2hSentAt: toDate(d.reminder2hSentAt) ?? null,
    cancelReasonCode: d.cancelReasonCode ?? undefined,
    cancelReason: d.cancelReason ?? undefined,
  };
}

/**
 * matches/{matchId} written:
 *  - create → newMatch (inbox + push) to group parents + system chat message;
 *  - status → cancelled → matchChanged with the reason + system chat message;
 *  - startAt changed → status moved, previousStartAt, reminders re-armed, matchChanged.
 */
export const onMatchWritten = onDocumentWritten('matches/{matchId}', async (event) => {
  const change = event.data;
  if (!change) return;
  const matchId = event.params.matchId;
  const before = change.before.exists ? matchFrom(change.before.data()!) : undefined;
  const after = change.after.exists ? matchFrom(change.after.data()!) : undefined;
  if (!after) return;

  if (movedMatchPatch(before, after)) {
    await change.after.ref.update({
      status: 'moved',
      previousStartAt: Timestamp.fromDate(before!.startAt),
      reminder1dSentAt: FieldValue.delete(),
      reminder2hSentAt: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  const events = classifyMatchWrite(before, after);
  if (events.length === 0) return;
  const group = await loadGroup(after.groupId);
  if (!group) return;
  const recipients = groupParentUsers(group, await loadUsers(group.parentIds));
  const baseVars = {
    group: group.name ?? '', opponent: after.opponentName ?? '',
    date: formatShortDate(after.startAt), time: formatTime(after.startAt),
  };
  const vars = (l: string) => ({ ...baseVars, reason: cancelReasonTextL(l, after.cancelReasonCode, after.cancelReason) || '—' });
  // systemArgs: raw values; the app renders {reason} as "<label(reasonCode)> — <reason>".
  const sysArgs = { opponent: baseVars.opponent, date: baseVars.date, time: baseVars.time, reasonCode: after.cancelReasonCode ?? '', reason: after.cancelReason ?? '' };
  for (const ev of events) {
    const base = { route: `/match/${matchId}`, args: { matchId, groupId: group.id }, groupId: group.id, data: { matchId } };
    if (ev.type === 'newMatch') {
      await notify(recipients, { type: 'newMatch', ...pushText('newMatch', baseVars), ...base, dedupeKey: `match:${matchId}:new` });
      await postSystemMessage(group.id, `system_match_${matchId}_new`, t('ka', 'system.newMatch', vars('ka')), { key: 'newMatch', args: sysArgs });
    } else if (ev.change === 'cancelled') {
      await notify(recipients, { type: 'matchChanged', ...pushText('matchCancelled', vars), ...base, dedupeKey: `match:${matchId}:cancelled` });
      await postSystemMessage(group.id, `system_match_${matchId}_cancelled`, t('ka', 'system.matchCancelled', vars('ka')), { key: 'matchCancelled', args: sysArgs });
    } else {
      const key = `match:${matchId}:moved:${after.startAt.getTime()}`;
      await notify(recipients, { type: 'matchChanged', ...pushText('matchMoved', baseVars), ...base, dedupeKey: key });
      await postSystemMessage(group.id, `system_match_${matchId}_moved_${after.startAt.getTime()}`, t('ka', 'system.matchMoved', vars('ka')), { key: 'matchMoved', args: sysArgs });
    }
  }
  logger.info('match notification', { matchId, events: events.map((e) => e.type), recipients: recipients.length });
});

/** Runs one reminder pass (exported for tests / the emulator smoke test). */
export async function runMatchReminders(now: Date): Promise<{ candidates: number; sent: number }> {
  const snap = await db
    .collection('matches')
    .where('startAt', '>', Timestamp.fromDate(now))
    .where('startAt', '<=', Timestamp.fromDate(new Date(now.getTime() + MATCH_REMINDER_1D_MS)))
    .get();
  let sent = 0;
  for (const doc of snap.docs) {
    if (!matchReminderStage(matchFrom(doc.data()), now)) continue;
    const stage = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists) return null;
      const s = matchReminderStage(matchFrom(fresh.data()!), now);
      if (!s) return null;
      const upd: Record<string, unknown> = {};
      for (const f of matchReminderFields(s)) if (!fresh.get(f)) upd[f] = FieldValue.serverTimestamp();
      tx.update(doc.ref, upd);
      return s;
    });
    if (!stage) continue;
    const m = matchFrom(doc.data());
    const group = await loadGroup(m.groupId);
    if (!group) continue;
    const recipients = groupParentUsers(group, await loadUsers(group.parentIds));
    const vars = { group: group.name ?? '', opponent: m.opponentName ?? '', date: formatShortDate(m.startAt), time: formatTime(m.startAt) };
    await notify(recipients, {
      type: 'matchReminder',
      ...pushText(stage === '1d' ? 'matchReminder1d' : 'matchReminder2h', vars),
      route: `/match/${doc.id}`, args: { matchId: doc.id, groupId: group.id }, groupId: group.id,
      dedupeKey: `match:${doc.id}:reminder:${stage}:${m.startAt.getTime()}`, data: { matchId: doc.id },
    });
    sent++;
  }
  return { candidates: snap.size, sent };
}

/** Every 15 minutes: match reminders 1 day and 2 hours before (sent-flag claimed in a transaction). */
export const matchReminders = onSchedule({ schedule: 'every 15 minutes', timeZone: TIMEZONE }, async () => {
  const r = await runMatchReminders(new Date());
  logger.info('match reminders run', r);
});
