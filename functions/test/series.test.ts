import { describe, expect, it } from 'vitest';
import {
  ExistingOccurrence, HORIZON_DAYS, NewOccurrence, SCHEDULE_CHANGED_REASON, SeriesRule, addDays, generateOccurrences,
  horizonEnd, isoWeekday, occurrenceId, occurrencesInScope, reconcileSeries, ruleChanged, seriesDates, splitSeries,
  tbilisiDateKey, tbilisiInstant, validateSeries,
} from '../src/lib/series';

// 2026-11-10 is a Tuesday. 06:00 UTC = 10:00 Tbilisi.
const NOW = new Date('2026-11-10T06:00:00Z');

const rule = (o: Partial<SeriesRule> = {}): SeriesRule => ({
  id: 's1', groupId: 'g1', clubId: 'club1', venueId: 'v1', weekdays: [1, 3], startTime: '18:00', durationMin: 90,
  focus: ['ball'], description: 'Passing', startDate: '2026-11-01', endDate: null, status: 'active', createdBy: 'coach1',
  ...o,
});

/** Existing docs as they would be stored after applying `create`. */
const asExisting = (occ: NewOccurrence[], extra: Partial<ExistingOccurrence> = {}): ExistingOccurrence[] =>
  occ.map((o) => ({
    id: o.id, seriesId: o.seriesId, occurrenceDate: o.occurrenceDate, startAt: o.startAt, status: 'scheduled', detached: false,
    venueId: o.venueId, durationMin: o.durationMin, focus: o.focus, description: o.description, groupId: o.groupId, ...extra,
  }));

describe('series date helpers (Tbilisi UTC+4, no DST)', () => {
  it('weekday numbering 1=Mon..7=Sun', () => {
    expect(isoWeekday('2026-11-09')).toBe(1);
    expect(isoWeekday('2026-11-10')).toBe(2);
    expect(isoWeekday('2026-11-15')).toBe(7);
  });
  it('wall clock to instant and back', () => {
    expect(tbilisiInstant('2026-11-11', '18:00').toISOString()).toBe('2026-11-11T14:00:00.000Z');
    expect(tbilisiInstant('2026-07-01', '18:00').toISOString()).toBe('2026-07-01T14:00:00.000Z'); // no DST
    expect(tbilisiDateKey(new Date('2026-11-10T20:30:00Z'))).toBe('2026-11-11');
    expect(tbilisiDateKey(new Date('2026-11-10T19:59:00Z'))).toBe('2026-11-10');
  });
  it('deterministic occurrence id', () => {
    expect(occurrenceId('s1', '2026-11-11')).toBe('s1_20261111');
  });
  it('validates the rule', () => {
    expect(validateSeries(rule())).toEqual([]);
    expect(validateSeries(rule({ weekdays: [0, 8] }))).toContain('weekdays');
    expect(validateSeries(rule({ weekdays: [] }))).toContain('weekdays');
    expect(validateSeries(rule({ startTime: '25:00' }))).toContain('startTime');
    expect(validateSeries(rule({ startDate: '2026-02-30' }))).toContain('startDate');
    expect(validateSeries(rule({ endDate: '2026-10-01' }))).toContain('endDate');
  });
});

describe('generation', () => {
  it('8-week horizon, only selected weekdays, never in the past', () => {
    const occ = generateOccurrences(rule(), NOW);
    expect(occ.length).toBe(16); // Mon+Wed for 8 weeks after today (Tuesday)
    expect(occ[0].occurrenceDate).toBe('2026-11-11');
    expect(occ[0].id).toBe('s1_20261111');
    expect(occ.every((o) => [1, 3].includes(isoWeekday(o.occurrenceDate)))).toBe(true);
    expect(occ.every((o) => o.startAt > NOW)).toBe(true);
    expect(occ[occ.length - 1].occurrenceDate <= addDays('2026-11-10', HORIZON_DAYS)).toBe(true);
  });
  it('skips an occurrence that already started today', () => {
    const r = rule({ weekdays: [2], startTime: '09:00' }); // today 09:00 Tbilisi = 05:00 UTC < NOW
    expect(generateOccurrences(r, NOW)[0].occurrenceDate).toBe('2026-11-17');
    const later = rule({ weekdays: [2], startTime: '11:00' });
    expect(generateOccurrences(later, NOW)[0].occurrenceDate).toBe('2026-11-10');
  });
  it('respects startDate and endDate', () => {
    expect(generateOccurrences(rule({ startDate: '2026-11-20' }), NOW)[0].occurrenceDate).toBe('2026-11-23');
    const ended = generateOccurrences(rule({ endDate: '2026-11-18' }), NOW).map((o) => o.occurrenceDate);
    expect(ended).toEqual(['2026-11-11', '2026-11-16', '2026-11-18']);
    expect(horizonEnd(rule({ endDate: '2026-11-18' }), NOW)).toBe('2026-11-18');
    expect(horizonEnd(rule(), NOW)).toBe('2027-01-05');
  });
  it('ended series generates nothing', () => {
    expect(generateOccurrences(rule({ status: 'ended' }), NOW)).toEqual([]);
  });
  it('seriesDates is inclusive', () => {
    expect(seriesDates(rule({ weekdays: [3] }), '2026-11-11', '2026-11-18')).toEqual(['2026-11-11', '2026-11-18']);
  });
});

describe('reconcile', () => {
  it('first run creates everything; second run is a no-op (idempotent)', () => {
    const p1 = reconcileSeries(rule(), { existing: [], now: NOW });
    expect(p1.create.length).toBe(16);
    const p2 = reconcileSeries(rule(), { existing: asExisting(p1.create), now: NOW });
    expect(p2).toEqual({ create: [], update: [], cancel: [], delete: [], skippedConflicts: [] });
  });

  it('weekday change: removed weekday deleted, or cancelled when it has RSVPs/attendance; new weekday created', () => {
    const existing = asExisting(reconcileSeries(rule(), { existing: [], now: NOW }).create);
    const changed = rule({ weekdays: [1, 5] }); // Wed -> Fri
    const withActivity = new Set(['s1_20261118']);
    const p = reconcileSeries(changed, { existing, now: NOW, withActivity });
    expect(p.cancel.map((c) => c.id)).toEqual(['s1_20261118']);
    expect(p.cancel[0].patch).toEqual({ status: 'cancelled', cancelReasonCode: 'other', cancelReason: SCHEDULE_CHANGED_REASON, cancelledBy: 'coach1' });
    expect(p.delete).toContain('s1_20261111');
    expect(p.delete).not.toContain('s1_20261118');
    expect(p.create.every((o) => isoWeekday(o.occurrenceDate) === 5)).toBe(true);
    expect(p.create.length).toBe(8);
    expect(p.update).toEqual([]); // Mondays unchanged
  });

  it('time change updates in place with previousStartAt (ids kept)', () => {
    const existing = asExisting(reconcileSeries(rule(), { existing: [], now: NOW }).create);
    const p = reconcileSeries(rule({ startTime: '19:00' }), { existing, now: NOW });
    expect(p.create).toEqual([]);
    expect(p.update.length).toBe(16);
    expect(p.update[0].id).toBe('s1_20261111');
    expect(p.update[0].patch.startAt.toISOString()).toBe('2026-11-11T15:00:00.000Z');
    expect(p.update[0].patch.previousStartAt?.toISOString()).toBe('2026-11-11T14:00:00.000Z');
  });

  it('new endDate removes occurrences after it', () => {
    const existing = asExisting(reconcileSeries(rule(), { existing: [], now: NOW }).create);
    const p = reconcileSeries(rule({ endDate: '2026-11-18' }), { existing, now: NOW, withActivity: new Set(['s1_20261123']) });
    expect(p.delete.length + p.cancel.length).toBe(13);
    expect(p.cancel.map((c) => c.id)).toEqual(['s1_20261123']);
  });

  it('detached, cancelled-by-coach, done and past occurrences are never touched', () => {
    const existing = asExisting(reconcileSeries(rule(), { existing: [], now: NOW }).create);
    existing[0].detached = true; // 11-11 edited individually
    existing[1].status = 'cancelled'; // 11-16 cancelled by coach
    existing[1].detached = true;
    existing.push({ id: 's1_20261104', seriesId: 's1', occurrenceDate: '2026-11-04', startAt: new Date('2026-11-04T14:00:00Z'), status: 'done', detached: false });
    const p = reconcileSeries(rule({ weekdays: [5], startTime: '17:00' }), { existing, now: NOW });
    const touched = [...p.delete, ...p.cancel.map((c) => c.id), ...p.update.map((u) => u.id)];
    expect(touched).not.toContain('s1_20261111');
    expect(touched).not.toContain('s1_20261116');
    expect(touched).not.toContain('s1_20261104');
  });

  it('skips dates where a one-off training starts at the same instant', () => {
    const clash = tbilisiInstant('2026-11-11', '18:00').getTime();
    const p = reconcileSeries(rule(), { existing: [], now: NOW, oneOffStarts: new Set([clash]) });
    expect(p.skippedConflicts).toEqual(['2026-11-11']);
    expect(p.create.find((o) => o.occurrenceDate === '2026-11-11')).toBeUndefined();
  });

  it('a schedule-change cancellation is restored when the date is covered again', () => {
    const existing = asExisting(reconcileSeries(rule(), { existing: [], now: NOW }).create);
    existing[0] = { ...existing[0], status: 'cancelled', cancelReason: SCHEDULE_CHANGED_REASON };
    const p = reconcileSeries(rule(), { existing, now: NOW });
    expect(p.update.map((u) => u.id)).toEqual([existing[0].id]);
    expect(p.update[0].patch.status).toBe('scheduled');
    expect(p.update[0].patch.cancelReason).toBeNull();
  });
});

describe('edit this and future (split)', () => {
  it('ends the old series the day before and starts a child series', () => {
    const { ended, next } = splitSeries(rule(), {
      venueId: 'v2', weekdays: [5, 1, 1], startTime: '17:30', durationMin: 60, focus: ['speed'], description: ' new ',
    }, '2026-11-20', 's2');
    expect(ended.endDate).toBe('2026-11-19');
    expect(ended.status).toBe('active');
    expect(next).toMatchObject({ id: 's2', parentSeriesId: 's1', startDate: '2026-11-20', weekdays: [1, 5], description: 'new', groupId: 'g1' });
    const fromStart = splitSeries(rule({ startDate: '2026-11-20' }), { ...next, endDate: null }, '2026-11-20', 's3');
    expect(fromStart.ended.status).toBe('ended');
  });

  it('child adopts parent occurrences by date (RSVP ids kept), cancels vanished dates with activity, deletes the rest', () => {
    const parentOcc = asExisting(reconcileSeries(rule(), { existing: [], now: NOW }).create);
    const { ended, next } = splitSeries(rule(), {
      venueId: 'v1', weekdays: [1], startTime: '19:00', durationMin: 90, focus: ['ball'], description: 'Passing',
    }, '2026-11-20', 's2');

    // Child first: it owns parent dates >= 2026-11-20.
    const childScope = occurrencesInScope(next, [], { parentOccurrences: parentOcc });
    expect(childScope.every((t) => t.occurrenceDate! >= '2026-11-20')).toBe(true);
    const withActivity = new Set(['s1_20261123', 's1_20261125']); // a Monday (kept) and a Wednesday (vanishes)
    const cp = reconcileSeries(next, { existing: childScope, now: NOW, withActivity });
    // Mondays adopted in place: id stays s1_..., seriesId switches to s2, time updated.
    const adopted = cp.update.find((u) => u.id === 's1_20261123')!;
    expect(adopted.patch.seriesId).toBe('s2');
    expect(adopted.patch.startAt.toISOString()).toBe('2026-11-23T15:00:00.000Z');
    expect(cp.create.find((o) => o.occurrenceDate === '2026-11-23')).toBeUndefined();
    expect(cp.cancel.map((c) => c.id)).toEqual(['s1_20261125']);
    expect(cp.delete).toContain('s1_20261202');
    // New Mondays beyond the parent's horizon would be created with s2 ids.
    expect(cp.create.every((o) => o.id.startsWith('s2_'))).toBe(true);

    // Parent afterwards: leaves dates >= child start to the child; earlier dates untouched.
    const parentScope = occurrencesInScope(ended, parentOcc, { childStartDates: [next.startDate] });
    expect(parentScope.every((t) => t.occurrenceDate! < '2026-11-20')).toBe(true);
    const pp = reconcileSeries(ended, { existing: parentScope, now: NOW });
    expect(pp).toEqual({ create: [], update: [], cancel: [], delete: [], skippedConflicts: [] });
  });

  it('ruleChanged ignores bookkeeping-only writes', () => {
    expect(ruleChanged(undefined, rule())).toBe(true);
    expect(ruleChanged(rule(), rule())).toBe(false);
    expect(ruleChanged(rule(), rule({ weekdays: [3, 1] }))).toBe(false);
    expect(ruleChanged(rule(), rule({ weekdays: [1] }))).toBe(true);
    expect(ruleChanged(rule(), rule({ endDate: '2026-12-01' }))).toBe(true);
  });
});
