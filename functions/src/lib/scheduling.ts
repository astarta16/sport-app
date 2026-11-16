// v1.7 room scheduling — pure logic, mirror of
// lib/features/organizations/domain/scheduling.dart (keep in sync).
// Boundaries are UTC instants (ms). Recurring rules are in the
// organization's local wall-clock time; only fixed-offset zones are
// supported in the beta (no DST), so conversion is exact.

export const TZ_OFFSETS_MIN: Record<string, number> = {
  'Asia/Tbilisi': 240,
  'Asia/Yerevan': 240,
  'Asia/Baku': 240,
  'Europe/Istanbul': 180,
  'Europe/Minsk': 180,
  UTC: 0,
};

export function normalizeTz(tz: unknown): string {
  return typeof tz === 'string' && tz in TZ_OFFSETS_MIN ? tz : 'Asia/Tbilisi';
}

export function offsetMs(tz: string): number {
  return TZ_OFFSETS_MIN[normalizeTz(tz)] * 60_000;
}

/** Wall-clock fields of an instant in tz. weekday: 1 = Monday … 7 = Sunday. */
export function wall(ms: number, tz: string): { y: number; m: number; d: number; minute: number; weekday: number } {
  const w = new Date(ms + offsetMs(tz));
  const wd = w.getUTCDay();
  return {
    y: w.getUTCFullYear(), m: w.getUTCMonth() + 1, d: w.getUTCDate(),
    minute: w.getUTCHours() * 60 + w.getUTCMinutes(), weekday: wd === 0 ? 7 : wd,
  };
}

/** UTC instant of a wall-clock date/time in tz. */
export function instant(tz: string, y: number, m: number, d: number, minute = 0): number {
  return Date.UTC(y, m - 1, d, 0, minute) - offsetMs(tz);
}

export type RoomStatus = 'active' | 'unavailable' | 'archived';
export type BookingKind = 'training' | 'match' | 'event' | 'maintenance';
export type ConflictCode =
  | 'invalidRange' | 'tooLong' | 'roomNotBookable' | 'outsideHours' | 'overCapacity'
  | 'roomOverlap' | 'maintenance' | 'coachOverlap' | 'groupOverlap' | 'wrongTenant';

export interface Room {
  id: string; orgId: string; capacity: number; status: RoomStatus;
  /** ISO weekday → [open, close] minutes from local midnight. */
  hours: Record<number, [number, number]>;
}

export interface Booking {
  id: string; orgId: string; roomId: string; kind: BookingKind;
  startMs: number; endMs: number; status: 'active' | 'cancelled';
  coachId?: string | null; groupId?: string | null; expectedAttendees?: number | null;
  seriesId?: string | null;
}

export interface Conflict { code: ConflictCode; otherId?: string }

export const MAX_DURATION_MS = 12 * 3600_000;
export const MAX_SERIES_WEEKS = 26;

export const STANDARD_HOURS: Record<number, [number, number]> = {
  1: [480, 1320], 2: [480, 1320], 3: [480, 1320], 4: [480, 1320], 5: [480, 1320], 6: [480, 1320], 7: [480, 1320],
};

export function blocking(c: ConflictCode): boolean {
  return c !== 'groupOverlap';
}

/** Half-open intervals overlap when aStart < bEnd && aEnd > bStart (buffer widens b). */
export function overlaps(aS: number, aE: number, bS: number, bE: number, bufferMs = 0): boolean {
  return aS < bE + bufferMs && aE + bufferMs > bS;
}

export function checkBooking(
  c: Booking, room: Room, existing: Booking[], tz: string, bufferMin = 0, ignore: Set<string> = new Set(),
): Conflict[] {
  const out: Conflict[] = [];
  if (!(c.endMs > c.startMs)) return [{ code: 'invalidRange' }];
  if (c.endMs - c.startMs > MAX_DURATION_MS) out.push({ code: 'tooLong' });
  if (room.orgId !== c.orgId) out.push({ code: 'wrongTenant' });
  if (room.status !== 'active') out.push({ code: 'roomNotBookable' });
  if (c.kind !== 'maintenance') {
    const w = wall(c.startMs, tz);
    const h = room.hours[w.weekday];
    const dur = Math.round((c.endMs - c.startMs) / 60_000);
    if (!h || w.minute < h[0] || w.minute + dur > h[1]) out.push({ code: 'outsideHours' });
    if (c.expectedAttendees != null && c.expectedAttendees > room.capacity) out.push({ code: 'overCapacity' });
  }
  const buf = bufferMin * 60_000;
  for (const b of existing) {
    if (b.status !== 'active' || b.id === c.id || ignore.has(b.id) || b.orgId !== c.orgId) continue;
    if (b.roomId === c.roomId && overlaps(c.startMs, c.endMs, b.startMs, b.endMs, buf)) {
      out.push({ code: b.kind === 'maintenance' ? 'maintenance' : 'roomOverlap', otherId: b.id });
      continue;
    }
    if (!overlaps(c.startMs, c.endMs, b.startMs, b.endMs)) continue;
    if (c.coachId && c.coachId === b.coachId) out.push({ code: 'coachOverlap', otherId: b.id });
    else if (c.groupId && c.groupId === b.groupId) out.push({ code: 'groupOverlap', otherId: b.id });
  }
  return out;
}

export interface WeeklyRule { weekdays: number[]; startMinute: number; durationMin: number; from: string; until: string }

function ymd(s: string): [number, number, number] {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
  if (!m) throw new Error('bad date');
  return [Number(m[1]), Number(m[2]), Number(m[3])];
}

/** Occurrences [startMs, endMs] within the bounded generation window. */
export function occurrences(rule: WeeklyRule, tz: string): Array<[number, number]> {
  const [fy, fm, fd] = ymd(rule.from);
  const [uy, um, ud] = ymd(rule.until);
  const fromDay = Date.UTC(fy, fm - 1, fd);
  const lastDay = Math.min(Date.UTC(uy, um - 1, ud), fromDay + MAX_SERIES_WEEKS * 7 * 86400_000);
  const out: Array<[number, number]> = [];
  for (let day = fromDay; day <= lastDay; day += 86400_000) {
    const dt = new Date(day);
    const wd = dt.getUTCDay() === 0 ? 7 : dt.getUTCDay();
    if (!rule.weekdays.includes(wd)) continue;
    const s = instant(tz, dt.getUTCFullYear(), dt.getUTCMonth() + 1, dt.getUTCDate(), rule.startMinute);
    out.push([s, s + rule.durationMin * 60_000]);
  }
  return out;
}

/** Up to `limit` conflict-free starts on the same local day (30-min grid), nearest first. */
export function alternatives(
  c: Booking, room: Room, existing: Booking[], tz: string, bufferMin = 0, limit = 3, ignore: Set<string> = new Set(),
): number[] {
  const dur = c.endMs - c.startMs;
  const w = wall(c.startMs, tz);
  const dayStart = instant(tz, w.y, w.m, w.d);
  const slots: number[] = [];
  for (let m = 0; m * 60_000 + dur <= 86400_000; m += 30) {
    const s = dayStart + m * 60_000;
    if (s === c.startMs) continue;
    const conflicts = checkBooking({ ...c, startMs: s, endMs: s + dur }, room, existing, tz, bufferMin, ignore);
    if (!conflicts.some((x) => blocking(x.code))) slots.push(s);
  }
  return slots.sort((a, b) => Math.abs(a - c.startMs) - Math.abs(b - c.startMs)).slice(0, limit);
}

/** Local day keys ("roomId_YYYY-MM-DD") a booking touches — the lock documents. */
export function lockKeys(roomId: string, startMs: number, endMs: number, tz: string): string[] {
  const keys = new Set<string>();
  for (let t = startMs; t < endMs + 1; t += 3600_000) {
    const w = wall(Math.min(t, endMs - 1), tz);
    keys.add(`${roomId}_${w.y}-${String(w.m).padStart(2, '0')}-${String(w.d).padStart(2, '0')}`);
  }
  return [...keys].sort();
}
