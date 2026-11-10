// Recurring training series: pure occurrence generation and reconciliation.
// Mirrors lib/features/trainings/domain/series.dart (RecurrenceEngine) in the
// Flutter app. Asia/Tbilisi is a fixed UTC+4 (no DST since 2005); all math is
// on wall-clock 'YYYY-MM-DD' + 'HH:mm'.

export const HORIZON_DAYS = 56; // 8 weeks
export const SCHEDULE_CHANGED_REASON = 'განრიგი შეიცვალა';
const DAY_MS = 86_400_000;
const TBILISI_OFFSET_MS = 4 * 3_600_000;

export type SeriesStatus = 'active' | 'ended';

export interface SeriesRule {
  id: string;
  groupId: string;
  clubId?: string | null;
  venueId: string;
  weekdays: number[]; // 1 = Mon … 7 = Sun
  startTime: string; // 'HH:mm'
  durationMin: number;
  focus: string[];
  description: string;
  startDate: string; // 'YYYY-MM-DD'
  endDate?: string | null;
  status: SeriesStatus;
  createdBy: string;
  parentSeriesId?: string | null;
}

export interface ExistingOccurrence {
  id: string;
  seriesId?: string | null;
  occurrenceDate?: string | null;
  startAt: Date;
  status: string;
  detached?: boolean;
  cancelReason?: string | null;
  venueId?: string;
  durationMin?: number;
  focus?: string[];
  description?: string;
  groupId?: string;
}

export interface NewOccurrence {
  id: string;
  groupId: string;
  venueId: string;
  startAt: Date;
  durationMin: number;
  focus: string[];
  description: string;
  createdBy: string;
  status: 'scheduled';
  photoUrls: string[];
  seriesId: string;
  occurrenceDate: string;
  detached: false;
}

export interface OccurrencePatch {
  id: string;
  patch: {
    seriesId: string;
    occurrenceDate: string;
    groupId: string;
    venueId: string;
    startAt: Date;
    durationMin: number;
    focus: string[];
    description: string;
    previousStartAt?: Date;
    /** Present when a schedule-change cancellation is reverted (date covered again). */
    status?: 'scheduled';
    cancelReasonCode?: null;
    cancelReason?: null;
    cancelledBy?: null;
    cancelledAt?: null;
  };
}

export interface CancelPatch {
  id: string;
  patch: { status: 'cancelled'; cancelReasonCode: 'other'; cancelReason: string; cancelledBy: string };
}

export interface SeriesPlan {
  create: NewOccurrence[];
  update: OccurrencePatch[];
  cancel: CancelPatch[];
  delete: string[];
  /** Dates skipped because a one-off training of the group starts at the same instant. */
  skippedConflicts: string[];
}

// ------------------------------------------------------------ date helpers

const DAY_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const TIME_RE = /^([01]\d|2[0-3]):([0-5]\d)$/;

/** Epoch day number of a 'YYYY-MM-DD' key (throws on invalid input). */
export function dayNumber(key: string): number {
  const m = DAY_RE.exec(key);
  if (!m) throw new Error(`invalid date key: ${key}`);
  const ms = Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  if (dayKey(Math.round(ms / DAY_MS)) !== key) throw new Error(`invalid date: ${key}`);
  return Math.round(ms / DAY_MS);
}

export function dayKey(n: number): string {
  const d = new Date(n * DAY_MS);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(d.getUTCDate()).padStart(2, '0')}`;
}

export function addDays(key: string, days: number): string {
  return dayKey(dayNumber(key) + days);
}

/** ISO weekday (1 = Mon … 7 = Sun) of a date key. */
export function isoWeekday(key: string): number {
  const d = new Date(dayNumber(key) * DAY_MS).getUTCDay();
  return d === 0 ? 7 : d;
}

/** Tbilisi calendar date of an instant. */
export function tbilisiDateKey(now: Date): string {
  return dayKey(Math.floor((now.getTime() + TBILISI_OFFSET_MS) / DAY_MS));
}

/** Instant of `HH:mm` Tbilisi wall-clock time on `key`. */
export function tbilisiInstant(key: string, hhmm: string): Date {
  const t = TIME_RE.exec(hhmm);
  if (!t) throw new Error(`invalid time: ${hhmm}`);
  return new Date(dayNumber(key) * DAY_MS + (Number(t[1]) * 60 + Number(t[2])) * 60_000 - TBILISI_OFFSET_MS);
}

/** Deterministic occurrence id `{seriesId}_{YYYYMMDD}`. */
export function occurrenceId(seriesId: string, key: string): string {
  return `${seriesId}_${key.replace(/-/g, '')}`;
}

// ------------------------------------------------------------ validation

export function validateSeries(s: Partial<SeriesRule>): string[] {
  const errors: string[] = [];
  if (!Array.isArray(s.weekdays) || s.weekdays.length === 0 || s.weekdays.length > 7 ||
      !s.weekdays.every((w) => Number.isInteger(w) && w >= 1 && w <= 7)) errors.push('weekdays');
  if (typeof s.startTime !== 'string' || !TIME_RE.test(s.startTime)) errors.push('startTime');
  const validDay = (v: unknown) => { try { return typeof v === 'string' && dayNumber(v) > 0; } catch { return false; } };
  if (!validDay(s.startDate)) errors.push('startDate');
  if (s.endDate != null && (!validDay(s.endDate) || (validDay(s.startDate) && s.endDate < s.startDate!))) errors.push('endDate');
  if (typeof s.durationMin !== 'number' || s.durationMin < 15 || s.durationMin > 300) errors.push('durationMin');
  if (s.status !== 'active' && s.status !== 'ended') errors.push('status');
  if (!s.groupId) errors.push('groupId');
  if (!s.venueId) errors.push('venueId');
  return errors;
}

// ------------------------------------------------------------ generation

/** Dates covered by the rule between `from` and `until` (inclusive). */
export function seriesDates(s: SeriesRule, from: string, until: string): string[] {
  const start = from > s.startDate ? from : s.startDate;
  const end = s.endDate && s.endDate < until ? s.endDate : until;
  const out: string[] = [];
  const weekdays = new Set(s.weekdays);
  for (let n = dayNumber(start), last = dayNumber(end); n <= last; n++) {
    const k = dayKey(n);
    if (weekdays.has(isoWeekday(k))) out.push(k);
  }
  return out;
}

export function buildOccurrence(s: SeriesRule, key: string): NewOccurrence {
  return {
    id: occurrenceId(s.id, key),
    groupId: s.groupId,
    venueId: s.venueId,
    startAt: tbilisiInstant(key, s.startTime),
    durationMin: s.durationMin,
    focus: [...s.focus],
    description: s.description,
    createdBy: s.createdBy,
    status: 'scheduled',
    photoUrls: [],
    seriesId: s.id,
    occurrenceDate: key,
    detached: false,
  };
}

/** Future occurrences the rule wants within the 8-week horizon. */
export function generateOccurrences(s: SeriesRule, now: Date, horizonDays = HORIZON_DAYS): NewOccurrence[] {
  if (s.status !== 'active') return [];
  const today = tbilisiDateKey(now);
  return seriesDates(s, today, addDays(today, horizonDays))
    .map((k) => buildOccurrence(s, k))
    .filter((o) => o.startAt.getTime() > now.getTime());
}

/** Last date of the generation horizon (stored as series.generatedUntil). */
export function horizonEnd(s: SeriesRule, now: Date): string {
  const h = addDays(tbilisiDateKey(now), HORIZON_DAYS);
  return s.endDate && s.endDate < h ? s.endDate : h;
}

export interface ExistingOccurrenceCancel { cancelReason?: string | null }

/** Cancelled by a series reconciliation (not by a coach): may be restored. */
const isScheduleCancelled = (t: ExistingOccurrence & ExistingOccurrenceCancel) =>
  t.status === 'cancelled' && t.detached !== true && t.cancelReason === SCHEDULE_CHANGED_REASON;

const isFrozen = (t: ExistingOccurrence) => t.detached === true || t.status === 'cancelled' || t.status === 'done';

const sameList = (a: string[] = [], b: string[] = []) => a.length === b.length && a.every((x) => b.includes(x));

/**
 * Reconciles a series with its existing occurrences.
 *
 * `existing`: occurrences of this series, plus — for a split-off series —
 * the parent series' occurrences on or after its start date (adopted by date,
 * so RSVPs/attendance keep their training id). `withActivity`: training ids
 * with RSVPs or attendance. `oneOffStarts`: start instants (ms) of non-series
 * trainings of the group (duplicate prevention).
 *
 * - never touches the past, detached, cancelled or done occurrences — except
 *   that a cancellation made by a previous reconciliation (reason
 *   SCHEDULE_CHANGED_REASON, not detached) is reverted when the date is
 *   covered again (e.g. a split-off series written after the parent's end date);
 * - desired dates: create (deterministic id) or update in place;
 * - future occurrences no longer covered: cancelled (with reason) when they
 *   have activity, otherwise deleted.
 */
export function reconcileSeries(
  s: SeriesRule,
  opts: { existing: ExistingOccurrence[]; now: Date; withActivity?: Set<string>; oneOffStarts?: Set<number> },
): SeriesPlan {
  const { existing, now } = opts;
  const withActivity = opts.withActivity ?? new Set<string>();
  const oneOff = opts.oneOffStarts ?? new Set<number>();
  const plan: SeriesPlan = { create: [], update: [], cancel: [], delete: [], skippedConflicts: [] };

  const today = tbilisiDateKey(now);
  const desired = s.status === 'active' ? seriesDates(s, today, addDays(today, HORIZON_DAYS)) : [];
  const desiredSet = new Set(desired);

  const byDate = new Map<string, ExistingOccurrence>();
  for (const t of existing) {
    if (!t.occurrenceDate) continue;
    const prev = byDate.get(t.occurrenceDate);
    // Prefer the doc that already belongs to this series (deterministic id).
    if (!prev || t.seriesId === s.id) byDate.set(t.occurrenceDate, t);
  }

  for (const d of desired) {
    const want = buildOccurrence(s, d);
    if (want.startAt.getTime() <= now.getTime()) continue; // already started today
    const have = byDate.get(d);
    if (!have) {
      if (oneOff.has(want.startAt.getTime())) {
        plan.skippedConflicts.push(d);
        continue;
      }
      plan.create.push(want);
      continue;
    }
    const restore = isScheduleCancelled(have);
    if (isFrozen(have) && !restore) continue;
    const differs =
      restore ||
      have.seriesId !== s.id ||
      have.startAt.getTime() !== want.startAt.getTime() ||
      have.venueId !== want.venueId ||
      have.durationMin !== want.durationMin ||
      (have.description ?? '') !== want.description ||
      !sameList(have.focus, want.focus) ||
      (have.groupId !== undefined && have.groupId !== want.groupId);
    if (!differs) continue;
    const patch: OccurrencePatch['patch'] = {
      seriesId: s.id,
      occurrenceDate: d,
      groupId: want.groupId,
      venueId: want.venueId,
      startAt: want.startAt,
      durationMin: want.durationMin,
      focus: want.focus,
      description: want.description,
    };
    if (have.startAt.getTime() !== want.startAt.getTime()) patch.previousStartAt = have.startAt;
    if (restore) Object.assign(patch, { status: 'scheduled', cancelReasonCode: null, cancelReason: null, cancelledBy: null, cancelledAt: null });
    plan.update.push({ id: have.id, patch });
  }

  for (const [d, t] of byDate) {
    if (desiredSet.has(d)) continue;
    if (t.startAt.getTime() <= now.getTime()) continue; // never rewrite history
    if (isFrozen(t)) continue;
    if (withActivity.has(t.id)) {
      plan.cancel.push({
        id: t.id,
        patch: { status: 'cancelled', cancelReasonCode: 'other', cancelReason: SCHEDULE_CHANGED_REASON, cancelledBy: s.createdBy },
      });
    } else {
      plan.delete.push(t.id);
    }
  }
  return plan;
}

export interface SeriesDraft {
  venueId: string;
  weekdays: number[];
  startTime: string;
  durationMin: number;
  focus: string[];
  description: string;
  endDate?: string | null;
}

/**
 * "Edit this and future occurrences" from `from`: the old series ends the day
 * before (status 'ended' when nothing of it remains); a new series `newId`
 * starts at `from` with the draft and `parentSeriesId = old.id`.
 */
export function splitSeries(old: SeriesRule, draft: SeriesDraft, from: string, newId: string): { ended: SeriesRule; next: SeriesRule } {
  const ended: SeriesRule = {
    ...old,
    endDate: addDays(from, -1),
    status: from <= old.startDate ? 'ended' : old.status,
  };
  const next: SeriesRule = {
    id: newId,
    groupId: old.groupId,
    clubId: old.clubId ?? null,
    venueId: draft.venueId,
    weekdays: [...new Set(draft.weekdays)].sort((a, b) => a - b),
    startTime: draft.startTime,
    durationMin: draft.durationMin,
    focus: [...draft.focus],
    description: draft.description.trim(),
    startDate: from,
    endDate: draft.endDate ?? null,
    status: 'active',
    createdBy: old.createdBy,
    parentSeriesId: old.id,
  };
  return { ended, next };
}

/**
 * Which existing docs a series reconciles over:
 * - its own occurrences, minus those on/after the start date of a child
 *   (split-off) series — the child owns them;
 * - for a child series, also the parent's occurrences on/after its start date.
 */
export function occurrencesInScope(
  s: SeriesRule,
  own: ExistingOccurrence[],
  opts: { childStartDates?: string[]; parentOccurrences?: ExistingOccurrence[] } = {},
): ExistingOccurrence[] {
  const cut = (opts.childStartDates ?? []).filter(Boolean).sort()[0];
  const mine = cut ? own.filter((t) => !t.occurrenceDate || t.occurrenceDate < cut) : own;
  const adopted = (opts.parentOccurrences ?? []).filter((t) => t.occurrenceDate && t.occurrenceDate >= s.startDate);
  return [...mine, ...adopted];
}

/** True when a series write changed anything that affects occurrences. */
export function ruleChanged(before: SeriesRule | undefined, after: SeriesRule): boolean {
  if (!before) return true;
  return (
    before.venueId !== after.venueId ||
    before.startTime !== after.startTime ||
    before.durationMin !== after.durationMin ||
    before.description !== after.description ||
    before.startDate !== after.startDate ||
    (before.endDate ?? null) !== (after.endDate ?? null) ||
    before.status !== after.status ||
    !sameList(before.focus.map(String), after.focus.map(String)) ||
    !sameList(before.weekdays.map(String), after.weekdays.map(String))
  );
}
