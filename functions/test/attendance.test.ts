import { describe, expect, it } from 'vitest';
import { AttendanceRecordLite, computeAttendanceStats, countableTrainings } from '../src/lib/attendance';

/** n trainings in a Tbilisi month, 18:00 local = 14:00 UTC. */
function month(y: number, m: number, statuses: Array<'present' | 'absent' | 'excused'>, prefix = `${y}-${m}`) {
  const starts = new Map<string, Date>();
  const recs: AttendanceRecordLite[] = [];
  statuses.forEach((s, i) => {
    const id = `${prefix}-${i}`;
    starts.set(id, new Date(Date.UTC(y, m - 1, 2 + i * 3, 14)));
    recs.push({ trainingId: id, status: s });
  });
  return { starts, recs };
}

function merge(...parts: Array<{ starts: Map<string, Date>; recs: AttendanceRecordLite[] }>) {
  const starts = new Map<string, Date>();
  const recs: AttendanceRecordLite[] = [];
  for (const p of parts) {
    p.starts.forEach((v, k) => starts.set(k, v));
    recs.push(...p.recs);
  }
  return { starts, recs };
}

describe('attendance statistics', () => {
  it('empty', () => {
    const s = computeAttendanceStats([], new Map());
    expect(s.rate).toBeNull();
    expect(s.months).toEqual([]);
    expect(s.achievements).toEqual([]);
  });

  it('monthly buckets, totals and percentage', () => {
    const { starts, recs } = merge(month(2026, 9, ['present', 'absent', 'excused', 'present']), month(2026, 10, ['present']));
    const s = computeAttendanceStats(recs, starts);
    expect([s.totalPresent, s.totalAbsent, s.totalExcused, s.recorded]).toEqual([3, 1, 1, 5]);
    expect(s.rate).toBeCloseTo(0.6);
    expect(s.months.map((m) => [m.year, m.month, m.present, m.recorded])).toEqual([[2026, 9, 2, 4], [2026, 10, 1, 1]]);
    expect(s.months[0].rate).toBe(0.5);
  });

  it('records of unknown trainings are ignored (RSVPs are never attendance)', () => {
    const s = computeAttendanceStats([{ trainingId: 'nope', status: 'present' }], new Map());
    expect(s.recorded).toBe(0);
  });

  it('buckets by Tbilisi month, not UTC', () => {
    // 2026-09-30 21:00 UTC = 2026-10-01 01:00 Tbilisi
    const s = computeAttendanceStats([{ trainingId: 't', status: 'present' }], new Map([['t', new Date('2026-09-30T21:00:00Z')]]));
    expect([s.months[0].year, s.months[0].month]).toEqual([2026, 10]);
  });

  it('milestones first/5/10/25/50/100 on the n-th present', () => {
    const starts = new Map<string, Date>();
    const recs: AttendanceRecordLite[] = [];
    for (let i = 0; i < 100; i++) {
      starts.set(`t${i}`, new Date(Date.UTC(2025, 0, 1) + i * 3 * 86_400_000));
      recs.push({ trainingId: `t${i}`, status: 'present' });
    }
    recs.splice(3, 0, { trainingId: 'ab', status: 'absent' });
    starts.set('ab', new Date(Date.UTC(2025, 0, 1, 20)));
    const s = computeAttendanceStats(recs, starts);
    const kinds = s.achievements.filter((a) => a.kind.startsWith('attended') || a.kind === 'firstTraining');
    expect(kinds.map((a) => a.kind)).toEqual(['firstTraining', 'attended5', 'attended10', 'attended25', 'attended50', 'attended100']);
    expect(kinds[1].achievedOn.getTime()).toBe(starts.get('t4')!.getTime());
  });

  it('perfect month needs ≥ 4 trainings all present', () => {
    const three = computeAttendanceStats(month(2026, 9, ['present', 'present', 'present']).recs, month(2026, 9, ['present', 'present', 'present']).starts);
    expect(three.achievements.some((a) => a.kind === 'perfectMonth')).toBe(false);
    const m = month(2026, 9, ['present', 'present', 'present', 'present']);
    expect(computeAttendanceStats(m.recs, m.starts).achievements.filter((a) => a.kind === 'perfectMonth').length).toBe(1);
    const ex = month(2026, 9, ['present', 'present', 'present', 'excused']);
    expect(computeAttendanceStats(ex.recs, ex.starts).achievements.some((a) => a.kind === 'perfectMonth')).toBe(false);
  });

  it('3-month streak: three consecutive months with ≥ 4 trainings and ≥ 75 %, awarded once', () => {
    const good = (y: number, m: number) => month(y, m, ['present', 'present', 'present', 'absent']);
    const s = merge(good(2026, 11), good(2026, 12), good(2027, 1), good(2027, 2));
    const st = computeAttendanceStats(s.recs, s.starts);
    const streaks = st.achievements.filter((a) => a.kind === 'streak3Months');
    expect(streaks.length).toBe(1);
    expect(streaks[0].achievedOn.toISOString().slice(0, 7)).toBe('2027-01');
  });

  it('a gap month or a bad month breaks the streak', () => {
    const good = (y: number, m: number) => month(y, m, ['present', 'present', 'present', 'present']);
    const gap = merge(good(2026, 1), good(2026, 2), good(2026, 4));
    expect(computeAttendanceStats(gap.recs, gap.starts).achievements.some((a) => a.kind === 'streak3Months')).toBe(false);
    const bad = merge(good(2026, 1), month(2026, 2, ['present', 'absent', 'absent', 'present']), good(2026, 3));
    expect(computeAttendanceStats(bad.recs, bad.starts).achievements.some((a) => a.kind === 'streak3Months')).toBe(false);
  });

  it('countableTrainings: done or started, never cancelled', () => {
    const now = new Date('2026-11-10T10:00:00Z');
    const m = countableTrainings([
      { id: 'past', startAt: new Date('2026-11-01T14:00:00Z'), status: 'scheduled' },
      { id: 'cancelled', startAt: new Date('2026-11-01T14:00:00Z'), status: 'cancelled' },
      { id: 'future', startAt: new Date('2026-11-20T14:00:00Z'), status: 'scheduled' },
      { id: 'doneFuture', startAt: new Date('2026-11-20T14:00:00Z'), status: 'done' },
    ], now);
    expect([...m.keys()].sort()).toEqual(['doneFuture', 'past']);
  });
});
