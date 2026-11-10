// Calendar arithmetic in the Asia/Tbilisi time zone.
// All "day" comparisons (payment due dates, certificate expiry) are made on
// Tbilisi calendar days, never on raw 24h differences.

export const TIMEZONE = 'Asia/Tbilisi';
const DAY_MS = 86_400_000;

const partsFmt = new Intl.DateTimeFormat('en-US', {
  timeZone: TIMEZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hourCycle: 'h23',
});

export interface ZonedParts {
  year: number;
  month: number; // 1-12
  day: number;
  hour: number;
  minute: number;
  second: number;
}

export function tbilisiParts(d: Date): ZonedParts {
  const out: Record<string, number> = {};
  for (const p of partsFmt.formatToParts(d)) {
    if (p.type !== 'literal') out[p.type] = Number(p.value);
  }
  return {
    year: out.year,
    month: out.month,
    day: out.day,
    hour: out.hour,
    minute: out.minute,
    second: out.second,
  };
}

/** Sequential day number of the Tbilisi calendar date containing `d`. */
export function tbilisiDayNumber(d: Date): number {
  const { year, month, day } = tbilisiParts(d);
  return Math.round(Date.UTC(year, month - 1, day) / DAY_MS);
}

/** Number of Tbilisi calendar days from `from` to `to` (to - from). */
export function tbilisiDayDiff(from: Date, to: Date): number {
  return tbilisiDayNumber(to) - tbilisiDayNumber(from);
}

const pad = (n: number, w = 2) => String(n).padStart(w, '0');

/** "2026-11-10" (Tbilisi calendar date). */
export function tbilisiDayKey(d: Date): string {
  const { year, month, day } = tbilisiParts(d);
  return `${year}-${pad(month)}-${pad(day)}`;
}

/** "2026-11" (Tbilisi calendar month). */
export function tbilisiMonthKey(d: Date): string {
  const { year, month } = tbilisiParts(d);
  return `${year}-${pad(month)}`;
}

/** "10.11" — short date used in SMS to save characters. */
export function formatShortDate(d: Date): string {
  const { month, day } = tbilisiParts(d);
  return `${pad(day)}.${pad(month)}`;
}

/** "10.11.2026" */
export function formatDate(d: Date): string {
  const { year, month, day } = tbilisiParts(d);
  return `${pad(day)}.${pad(month)}.${year}`;
}

/** "18:30" */
export function formatTime(d: Date): string {
  const { hour, minute } = tbilisiParts(d);
  return `${pad(hour)}:${pad(minute)}`;
}

/** The UTC instant of Tbilisi local time `year-month-day hour:00`. */
export function tbilisiLocalToUtc(year: number, month: number, day: number, hour = 0): Date {
  const guess = new Date(Date.UTC(year, month - 1, day, hour));
  const p = tbilisiParts(guess);
  const asIfUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  const offsetMs = asIfUtc - guess.getTime();
  return new Date(guess.getTime() - offsetMs);
}

export function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}
