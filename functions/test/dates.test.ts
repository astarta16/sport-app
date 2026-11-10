import { describe, expect, it } from 'vitest';
import {
  daysInMonth, formatDate, formatShortDate, formatTime, tbilisiDayDiff, tbilisiDayKey,
  tbilisiLocalToUtc, tbilisiMonthKey,
} from '../src/lib/dates';

describe('Tbilisi calendar helpers', () => {
  it('uses the Tbilisi calendar day, not UTC', () => {
    // 21:00 UTC = 01:00 next day in Tbilisi (UTC+4)
    expect(tbilisiDayKey(new Date('2026-11-10T21:00:00Z'))).toBe('2026-11-11');
    expect(tbilisiDayKey(new Date('2026-11-10T19:59:59Z'))).toBe('2026-11-10');
  });

  it('counts calendar days, not 24h periods', () => {
    const now = new Date('2026-11-10T06:00:00Z'); // 10:00 Tbilisi
    expect(tbilisiDayDiff(now, new Date('2026-11-15T19:00:00Z'))).toBe(5); // 23:00 on the 15th
    expect(tbilisiDayDiff(now, new Date('2026-11-15T20:30:00Z'))).toBe(6); // 00:30 on the 16th
    expect(tbilisiDayDiff(now, new Date('2026-11-10T19:00:00Z'))).toBe(0);
    expect(tbilisiDayDiff(now, new Date('2026-11-09T06:00:00Z'))).toBe(-1);
  });

  it('handles month and year boundaries', () => {
    expect(tbilisiDayDiff(new Date('2026-12-30T08:00:00Z'), new Date('2027-01-02T08:00:00Z'))).toBe(3);
    expect(tbilisiMonthKey(new Date('2026-12-31T20:30:00Z'))).toBe('2027-01');
  });

  it('formats dates and times in Tbilisi time', () => {
    const d = new Date('2026-03-05T14:30:00Z');
    expect(formatShortDate(d)).toBe('05.03');
    expect(formatDate(d)).toBe('05.03.2026');
    expect(formatTime(d)).toBe('18:30');
  });

  it('converts Tbilisi local time to UTC', () => {
    expect(tbilisiLocalToUtc(2026, 11, 15, 0).toISOString()).toBe('2026-11-14T20:00:00.000Z');
    expect(tbilisiLocalToUtc(2026, 1, 1, 10).toISOString()).toBe('2026-01-01T06:00:00.000Z');
  });

  it('knows month lengths', () => {
    expect(daysInMonth(2026, 2)).toBe(28);
    expect(daysInMonth(2028, 2)).toBe(29);
    expect(daysInMonth(2026, 4)).toBe(30);
  });
});
