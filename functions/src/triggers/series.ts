import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { DocumentData, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { createHash } from 'node:crypto';
import { db } from '../admin';
import { TIMEZONE } from '../config';
import { loadGroup, loadUser, loadUsers, toDate } from '../convert';
import { renderPush, weekdaySummary } from '../i18n/ka';
import { groupParentUsers } from '../lib/recipients';
import {
  ExistingOccurrence, HORIZON_DAYS, SeriesDraft, SeriesPlan, SeriesRule, horizonEnd, occurrencesInScope,
  reconcileSeries, ruleChanged, splitSeries, tbilisiDateKey, validateSeries,
} from '../lib/series';
import { notify } from '../notify';

export function seriesFrom(id: string, d: DocumentData): SeriesRule {
  return {
    id,
    groupId: d.groupId,
    clubId: d.clubId ?? null,
    venueId: d.venueId,
    weekdays: Array.isArray(d.weekdays) ? d.weekdays.map(Number) : [],
    startTime: d.startTime,
    durationMin: Number(d.durationMin),
    focus: Array.isArray(d.focus) ? d.focus.map(String) : [],
    description: typeof d.description === 'string' ? d.description : '',
    startDate: d.startDate,
    endDate: d.endDate ?? null,
    status: d.status,
    createdBy: d.createdBy ?? '',
    parentSeriesId: d.parentSeriesId ?? null,
  };
}

function occurrenceFrom(id: string, d: DocumentData): ExistingOccurrence {
  return {
    id,
    seriesId: d.seriesId ?? null,
    occurrenceDate: d.occurrenceDate ?? null,
    startAt: toDate(d.startAt) ?? new Date(0),
    status: d.status,
    detached: d.detached === true,
    cancelReason: d.cancelReason ?? null,
    venueId: d.venueId,
    durationMin: d.durationMin,
    focus: Array.isArray(d.focus) ? d.focus : [],
    description: d.description ?? '',
    groupId: d.groupId,
  };
}

async function occurrencesOf(seriesId: string): Promise<ExistingOccurrence[]> {
  const snap = await db.collection('trainings').where('seriesId', '==', seriesId).get();
  return snap.docs.map((d) => occurrenceFrom(d.id, d.data()));
}

/** Training ids (among `ids`) that have at least one RSVP or attendance record. */
async function idsWithActivity(ids: string[]): Promise<Set<string>> {
  const out = new Set<string>();
  for (let i = 0; i < ids.length; i += 30) {
    const chunk = ids.slice(i, i + 30);
    for (const coll of ['rsvps', 'attendance']) {
      const snap = await db.collection(coll).where('trainingId', 'in', chunk).select('trainingId').get();
      snap.docs.forEach((d) => out.add(String(d.get('trainingId'))));
    }
  }
  return out;
}

async function applyPlan(plan: SeriesPlan): Promise<void> {
  const ops: Array<(b: FirebaseFirestore.WriteBatch) => void> = [];
  for (const o of plan.create) {
    ops.push((b) => b.set(db.doc(`trainings/${o.id}`), {
      groupId: o.groupId, venueId: o.venueId, startAt: Timestamp.fromDate(o.startAt), durationMin: o.durationMin,
      focus: o.focus, description: o.description, photoUrls: [], status: 'scheduled', createdBy: o.createdBy,
      updatedAt: FieldValue.serverTimestamp(), seriesId: o.seriesId, occurrenceDate: o.occurrenceDate, detached: false,
    }));
  }
  for (const u of plan.update) {
    const { startAt, previousStartAt, cancelledAt, ...rest } = u.patch;
    const restoreFields = cancelledAt === null ? { cancelledAt: null } : {};
    ops.push((b) => b.update(db.doc(`trainings/${u.id}`), {
      ...rest,
      ...restoreFields,
      startAt: Timestamp.fromDate(startAt),
      ...(previousStartAt ? { previousStartAt: Timestamp.fromDate(previousStartAt), reminderSentAt: FieldValue.delete() } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    }));
  }
  for (const c of plan.cancel) {
    ops.push((b) => b.update(db.doc(`trainings/${c.id}`), {
      ...c.patch, cancelledAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    }));
  }
  for (const id of plan.delete) ops.push((b) => b.delete(db.doc(`trainings/${id}`)));
  for (let i = 0; i < ops.length; i += 400) {
    const batch = db.batch();
    ops.slice(i, i + 400).forEach((op) => op(batch));
    await batch.commit();
  }
}

export interface SyncResult {
  created: number;
  updated: number;
  cancelled: number;
  deleted: number;
  conflicts: number;
}

/**
 * (Re)generates a series' occurrences — idempotent. Handles split-off
 * series: a series with parentSeriesId adopts the parent's occurrences from
 * its start date; the parent leaves those dates to the child.
 */
export async function syncSeries(seriesId: string, now = new Date()): Promise<SyncResult | null> {
  const snap = await db.doc(`trainingSeries/${seriesId}`).get();
  if (!snap.exists) return null;
  const rule = seriesFrom(snap.id, snap.data()!);
  const errors = validateSeries(rule);
  if (errors.length) {
    logger.warn('invalid series ignored', { seriesId, errors });
    return null;
  }
  const own = await occurrencesOf(seriesId);
  const childSnap = await db.collection('trainingSeries').where('parentSeriesId', '==', seriesId).get();
  const childStartDates = childSnap.docs.map((d) => String(d.get('startDate') ?? '')).filter(Boolean);
  const parentOccurrences = rule.parentSeriesId ? await occurrencesOf(rule.parentSeriesId) : [];
  const existing = occurrencesInScope(rule, own, { childStartDates, parentOccurrences });

  const candidates = existing.filter((t) => t.startAt.getTime() > now.getTime() && !t.detached && t.status !== 'done');
  const withActivity = await idsWithActivity(candidates.map((t) => t.id));

  const oneOffSnap = await db.collection('trainings')
    .where('groupId', '==', rule.groupId)
    .where('startAt', '>', Timestamp.fromDate(now))
    .where('startAt', '<=', Timestamp.fromDate(new Date(now.getTime() + (HORIZON_DAYS + 2) * 86_400_000)))
    .get();
  const oneOffStarts = new Set(oneOffSnap.docs
    .filter((d) => !d.get('seriesId') && d.get('status') !== 'cancelled')
    .map((d) => (toDate(d.get('startAt')) ?? new Date(0)).getTime()));

  const plan = reconcileSeries(rule, { existing, now, withActivity, oneOffStarts });
  await applyPlan(plan);

  const until = horizonEnd(rule, now);
  if (snap.get('generatedUntil') !== until) await snap.ref.update({ generatedUntil: until });
  const result = { created: plan.create.length, updated: plan.update.length, cancelled: plan.cancel.length, deleted: plan.delete.length, conflicts: plan.skippedConflicts.length };
  logger.info('series synced', { seriesId, ...result });
  return result;
}

function ruleHash(r: SeriesRule): string {
  const key = JSON.stringify([r.venueId, [...r.weekdays].sort(), r.startTime, r.durationMin, r.focus, r.description, r.startDate, r.endDate ?? null, r.status]);
  return createHash('sha1').update(key).digest('hex').slice(0, 16);
}

/**
 * trainingSeries/{id} written: regenerate occurrences and send ONE summary
 * notification ('scheduleChanged') per create / rule change (never one per
 * occurrence). The parent side of a split (only endDate/status changed while
 * a child series exists) is not announced separately.
 */
export const onSeriesWritten = onDocumentWritten('trainingSeries/{seriesId}', async (event) => {
  const seriesId = event.params.seriesId;
  const afterData = event.data?.after.exists ? event.data.after.data()! : undefined;
  if (!afterData) return;
  const before = event.data?.before.exists ? seriesFrom(seriesId, event.data.before.data()!) : undefined;
  const after = seriesFrom(seriesId, afterData);
  const result = await syncSeries(seriesId);
  if (!result || !ruleChanged(before, after)) return;

  if (before) {
    const onlyEnd = before.weekdays.join() === after.weekdays.join() && before.startTime === after.startTime &&
      before.venueId === after.venueId && before.durationMin === after.durationMin && before.description === after.description;
    if (onlyEnd) {
      const child = await db.collection('trainingSeries').where('parentSeriesId', '==', seriesId).limit(1).get();
      if (!child.empty) return;
    }
  }
  const group = await loadGroup(after.groupId);
  if (!group) return;
  const recipients = groupParentUsers(group, await loadUsers(group.parentIds));
  const summary = after.status === 'active' ? weekdaySummary(after.weekdays, after.startTime) : 'სერია დასრულდა';
  await notify(recipients, {
    type: 'scheduleChanged',
    ...renderPush('scheduleChanged', { group: group.name ?? '', summary }),
    route: `/group/${group.id}/schedule`,
    args: { seriesId, groupId: group.id },
    groupId: group.id,
    dedupeKey: `series:${seriesId}:${ruleHash(after)}`,
    data: { seriesId },
  });
});

export async function runExtendTrainingSeries(now = new Date()): Promise<{ series: number }> {
  const snap = await db.collection('trainingSeries').where('status', '==', 'active').get();
  for (const d of snap.docs) {
    try {
      await syncSeries(d.id, now);
    } catch (e) {
      logger.error('series extend failed', { seriesId: d.id, error: String(e) });
    }
  }
  return { series: snap.size };
}

/** Daily 03:00 Tbilisi: roll every active series forward to the 8-week horizon. */
export const extendTrainingSeries = onSchedule({ schedule: '0 3 * * *', timeZone: TIMEZONE }, async () => {
  logger.info('extendTrainingSeries', await runExtendTrainingSeries(new Date()));
});

/**
 * "Edit this and future": callable {seriesId, fromDate, draft}. Ends the old
 * series the day before, creates the split-off series (parentSeriesId) in one
 * batch, then reconciles both (child first, so RSVP-bearing occurrences are
 * adopted rather than cancelled). Approved coach of the group only.
 */
export const splitTrainingSeries = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const { seriesId, fromDate, draft } = (request.data ?? {}) as { seriesId?: unknown; fromDate?: unknown; draft?: Partial<SeriesDraft> };
  if (typeof seriesId !== 'string' || !seriesId || seriesId.includes('/')) throw new HttpsError('invalid-argument', 'seriesId');
  if (typeof fromDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(fromDate)) throw new HttpsError('invalid-argument', 'fromDate');
  const oldSnap = await db.doc(`trainingSeries/${seriesId}`).get();
  if (!oldSnap.exists) throw new HttpsError('not-found', 'series not found');
  const old = seriesFrom(oldSnap.id, oldSnap.data()!);
  const [user, group] = await Promise.all([loadUser(request.auth.uid), loadGroup(old.groupId)]);
  if (!user || user.role !== 'coach' || user.coachStatus !== 'approved' || !group?.coachIds.includes(user.uid)) {
    throw new HttpsError('permission-denied', 'coach of the group only');
  }
  if (fromDate < tbilisiDateKey(new Date())) throw new HttpsError('invalid-argument', 'fromDate is in the past');
  const d: SeriesDraft = {
    venueId: String(draft?.venueId ?? old.venueId),
    weekdays: Array.isArray(draft?.weekdays) ? draft!.weekdays.map(Number) : old.weekdays,
    startTime: String(draft?.startTime ?? old.startTime),
    durationMin: Number(draft?.durationMin ?? old.durationMin),
    focus: Array.isArray(draft?.focus) ? draft!.focus.map(String) : old.focus,
    description: String(draft?.description ?? old.description),
    endDate: draft?.endDate === undefined ? old.endDate ?? null : draft.endDate,
  };
  const newRef = db.collection('trainingSeries').doc();
  const { ended, next } = splitSeries(old, d, fromDate, newRef.id);
  const errors = validateSeries(next);
  if (errors.length) throw new HttpsError('invalid-argument', `invalid series: ${errors.join(',')}`);
  const batch = db.batch();
  batch.update(oldSnap.ref, { endDate: ended.endDate, status: ended.status, updatedAt: FieldValue.serverTimestamp() });
  const { id: _newId, ...nextData } = next;
  batch.set(newRef, { ...nextData, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  await batch.commit();
  await syncSeries(newRef.id);
  await syncSeries(seriesId);
  return { newSeriesId: newRef.id, oldSeriesId: seriesId };
});
