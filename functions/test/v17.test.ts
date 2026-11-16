// v1.7 server logic. The cases mirror test/v17/scheduling_scoring_test.dart
// so the Dart client (instant warnings, demo backend) and the TypeScript
// authority produce identical decisions and identical points.
import { describe, expect, it } from 'vitest';
import {
  Booking, Room, STANDARD_HOURS, alternatives, checkBooking, instant, lockKeys, occurrences, overlaps, wall,
} from '../src/lib/scheduling';
import { Result, ageBandOf, ordered, periodStartMs, pseudonymFor, rank, score, total } from '../src/lib/scoring';
import { checkOrgModuleChange, effectiveConfig, isModuleOn, planModules, sanitizeModules } from '../src/lib/orgs';

const tz = 'Asia/Tbilisi';
const at = (h: number, m = 0, d = 16) => instant(tz, 2026, 11, d, h * 60 + m);
const room: Room = { id: 'hall-a', orgId: 'org-1', capacity: 20, status: 'active', hours: STANDARD_HOURS };
const bk = (id: string, s: number, e: number, extra: Partial<Booking> = {}): Booking => ({
  id, orgId: 'org-1', roomId: 'hall-a', kind: 'training', startMs: s, endMs: e, status: 'active', ...extra,
});

describe('time zones', () => {
  it('Tbilisi is UTC+4; instants are UTC', () => {
    expect(new Date(at(16)).toISOString()).toBe('2026-11-16T12:00:00.000Z');
    expect(wall(Date.UTC(2026, 6, 1, 20), tz).minute).toBe(0);
    expect(wall(at(16), tz).weekday).toBe(1);
  });
});

describe('interval overlap', () => {
  it('touching is fine, overlapping is not, buffer widens', () => {
    expect(overlaps(at(9), at(10), at(10), at(11))).toBe(false);
    expect(overlaps(at(9), at(10, 30), at(10), at(11))).toBe(true);
    expect(overlaps(at(10), at(11), at(9), at(10), 10 * 60_000)).toBe(true);
  });
});

describe('conflict checker (server authority)', () => {
  const existing = [
    bk('x', at(10), at(11), { coachId: 'c1', groupId: 'g1' }),
    bk('m', at(14), at(16), { kind: 'maintenance' }),
    bk('o', at(18), at(19), { roomId: 'hall-b', coachId: 'c2', groupId: 'g2' }),
    bk('foreign', at(12), at(13), { orgId: 'org-2' }),
  ];
  const codes = (b: Booking, buffer = 0, r = room) => checkBooking(b, r, existing, tz, buffer).map((c) => c.code);

  it('same cases as the Dart checker', () => {
    expect(codes(bk('n', at(11), at(12)))).toEqual([]);
    expect(codes(bk('n', at(10, 30), at(11, 30)))).toEqual(['roomOverlap']);
    expect(codes(bk('n', at(11), at(12)), 15)).toEqual(['roomOverlap']);
    expect(codes(bk('n', at(15), at(15, 30)))).toEqual(['maintenance']);
    expect(codes(bk('n', at(7), at(8)))).toEqual(['outsideHours']);
    expect(codes(bk('n', at(12), at(12)))).toEqual(['invalidRange']);
    expect(codes(bk('n', at(8), at(21)))).toContain('tooLong');
    expect(codes(bk('n', at(18, 30), at(19, 30), { coachId: 'c2' }))).toEqual(['coachOverlap']);
    expect(codes(bk('n', at(18, 30), at(19, 30), { groupId: 'g2' }))).toEqual(['groupOverlap']);
    expect(codes(bk('n', at(12), at(13), { expectedAttendees: 25 }))).toEqual(['overCapacity']);
    expect(codes(bk('n', at(12), at(13)), 0, { ...room, status: 'unavailable' })).toEqual(['roomNotBookable']);
    expect(codes(bk('n', at(12), at(13), { orgId: 'org-2' }))).toContain('wrongTenant');
  });

  it('another tenant never conflicts', () => {
    expect(codes(bk('n', at(12), at(13)))).toEqual([]);
  });

  it('cross-midnight bookings need late opening hours', () => {
    const late = bk('n', at(23), at(0, 30, 17));
    expect(codes(late)).toEqual(['outsideHours']);
    const night: Room = { ...room, hours: { 1: [480, 1560], 2: [480, 1560] } };
    expect(checkBooking(late, night, [bk('early', at(0, 0, 17), at(1, 0, 17))], tz).map((c) => c.code)).toEqual(['roomOverlap']);
  });

  it('suggests the nearest free starts', () => {
    expect(alternatives(bk('n', at(10), at(11)), room, existing, tz).slice(0, 2)).toEqual([at(9), at(11)]);
  });

  it('overlapping bookings always share a room-day lock document', () => {
    const a = lockKeys('hall-a', at(23), at(0, 30, 17), tz);
    const b = lockKeys('hall-a', at(0, 0, 17), at(1, 0, 17), tz);
    expect(a).toEqual(['hall-a_2026-11-16', 'hall-a_2026-11-17']);
    expect(a.some((k) => b.includes(k))).toBe(true);
  });
});

describe('weekly recurrence', () => {
  it('local wall-clock occurrences within a bounded window', () => {
    const occ = occurrences({ weekdays: [1, 3], startMinute: 960, durationMin: 90, from: '2026-11-16', until: '2026-11-29' }, tz);
    expect(occ.length).toBe(4);
    expect(occ[0]).toEqual([at(16), at(17, 30)]);
    expect(occurrences({ weekdays: [1], startMinute: 600, durationMin: 60, from: '2026-01-05', until: '2028-01-01' }, tz).length).toBeLessThanOrEqual(27);
  });
});

describe('scoring (mirror of the Dart ScoringService)', () => {
  const day = Date.UTC(2026, 10, 16, 8);
  const r = (id: string, o: Partial<Result> = {}): Result => ({
    id, childId: 'c1', game: 'memoryMatch', difficulty: 'easy', level: 1, score: 100, accuracy: 1, attempts: 5,
    durationMs: 60000, completed: true, playedAtMs: day, ...o,
  });

  it('first clear + 1 / 0.5 / 0.25 / 0 repeat factors', () => {
    const s = score([0, 1, 2, 3, 4].map((m) => r(`p${m}`, { playedAtMs: day + m * 60_000 })));
    expect(s.map((x) => x.points)).toEqual([35, 10, 5, 0, 0]);
  });

  it('difficulty, incomplete, implausible duration, daily cap, duplicate ids', () => {
    expect(total([r('h', { difficulty: 'hard', level: 5, accuracy: 0.5 })])).toBe(30 + 8 + 5 + 15);
    expect(total([r('x', { completed: false })])).toBe(0);
    expect(total([r('x', { durationMs: 1000 })])).toBe(0);
    const games = ['memoryMatch', 'logicQuest', 'smartPlay', 'quickMind', 'sequenceMaster', 'pathFinder'] as const;
    const many = Array.from({ length: 30 }, (_, i) =>
      r(`p${i}`, { level: (i % 10) + 1, difficulty: 'hard', playedAtMs: day + i * 60_000, game: games[i % 6] }));
    expect(total(many)).toBe(300);
    expect(total([r('same'), r('same')])).toBe(35);
    expect(ordered([r('b', { playedAtMs: day }), r('a', { playedAtMs: day })]).map((x) => x.id)).toEqual(['a', 'b']);
  });

  it('ranking: points desc, earliest to reach, then id', () => {
    const ps = [
      { childId: 'c1', displayName: 'A', ageBand: '9-11' },
      { childId: 'c2', displayName: 'B', ageBand: '9-11' },
      { childId: 'c3', displayName: 'C', ageBand: '9-11' },
    ];
    const results = [r('1'), r('2', { childId: 'c2', playedAtMs: day + 5 * 60_000 }), r('3', { childId: 'c3', level: 2 })];
    const e = rank(ps, results, 'week', day + 3600_000, []);
    expect(e.map((x) => x.childId)).toEqual(['c3', 'c1', 'c2']);
    expect(e[1].points).toBe(e[2].points);
  });

  it('pseudonyms and age bands match Dart', () => {
    expect(pseudonymFor('child-1')).toMatch(/^[A-Z][a-z]+ [A-Z][a-z]+ \d{2}$/);
    expect(pseudonymFor('child-1')).toBe(pseudonymFor('child-1'));
    expect([8, 11, 14, 16].map(ageBandOf)).toEqual(['6-8', '9-11', '12-14', '15-17']);
    // Monday 00:00 Tbilisi of the week containing 2026-11-18 (Wed).
    expect(new Date(periodStartMs('week', Date.UTC(2026, 10, 18, 12))).toISOString()).toBe('2026-11-15T20:00:00.000Z');
  });
});

describe('feature flags', () => {
  it('active AND allowed AND enabled; legacy clubs keep the pre-v1.7 set', () => {
    expect(isModuleOn({ status: 'active', allowedModules: ['trainings'], enabledModules: ['trainings'] }, 'trainings')).toBe(true);
    expect(isModuleOn({ status: 'suspended', allowedModules: ['trainings'], enabledModules: ['trainings'] }, 'trainings')).toBe(false);
    expect(isModuleOn({ allowedModules: ['trainings'], enabledModules: ['trainings', 'roomScheduling'] }, 'roomScheduling')).toBe(false);
    expect(isModuleOn(undefined, 'brainAcademy')).toBe(true);
    expect(isModuleOn(undefined, 'roomScheduling')).toBe(false);
    expect(isModuleOn(undefined, 'leaderboards')).toBe(false);
    expect(effectiveConfig({ plan: 'premium' }).enabledModules).not.toContain('leaderboards');
  });

  it('organization admins cannot self-enable modules the platform did not allow', () => {
    const cfg = { plan: 'standard' as const, allowedModules: planModules('standard') };
    expect(checkOrgModuleChange(cfg, ['trainings', 'media'])).toBeNull();
    expect(checkOrgModuleChange(cfg, ['trainings', 'leaderboards'])).toBe('moduleNotAllowed:leaderboards');
    expect(checkOrgModuleChange({ ...cfg, status: 'deactivated' }, ['trainings'])).toBe('orgInactive');
    expect(() => sanitizeModules(['trainings', 'superPowers'])).toThrow();
  });
});
