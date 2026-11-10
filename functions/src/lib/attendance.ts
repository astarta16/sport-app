// Pure attendance statistics and achievements over coach-recorded attendance.
// RSVPs are never counted. Mirrors AttendanceStats.compute in
// lib/features/attendance/domain/attendance.dart (Flutter).
import { tbilisiParts } from './dates';

export type AttendanceStatus = 'present' | 'absent' | 'excused';

export interface AttendanceRecordLite {
  trainingId: string;
  childId?: string;
  status: AttendanceStatus;
}

export type AchievementKind =
  | 'firstTraining' | 'attended5' | 'attended10' | 'attended25' | 'attended50' | 'attended100'
  | 'perfectMonth' | 'streak3Months';

export interface Achievement {
  kind: AchievementKind;
  achievedOn: Date;
}

export interface MonthStats {
  year: number;
  month: number;
  present: number;
  absent: number;
  excused: number;
  recorded: number;
  /** present / recorded, null when nothing was recorded. */
  rate: number | null;
}

export interface AttendanceStats {
  totalPresent: number;
  totalAbsent: number;
  totalExcused: number;
  recorded: number;
  rate: number | null;
  /** Oldest first. */
  months: MonthStats[];
  achievements: Achievement[];
}

const MILESTONES: Record<number, AchievementKind> = {
  1: 'firstTraining', 5: 'attended5', 10: 'attended10', 25: 'attended25', 50: 'attended50', 100: 'attended100',
};

/** Minimum recorded trainings for a month to count as "perfect" or part of a streak. */
export const MIN_TRAININGS_PER_MONTH = 4;
/** Monthly rate needed for a month to extend the 3-month streak. */
export const STREAK_MIN_RATE = 0.75;

/**
 * `trainingStarts` maps training id -> start instant; records of trainings not
 * in the map (unknown, cancelled or future — the caller decides) are ignored.
 */
export function computeAttendanceStats(records: AttendanceRecordLite[], trainingStarts: Map<string, Date>): AttendanceStats {
  const list = records
    .filter((r) => trainingStarts.has(r.trainingId))
    .sort((a, b) => trainingStarts.get(a.trainingId)!.getTime() - trainingStarts.get(b.trainingId)!.getTime());

  const buckets = new Map<string, { year: number; month: number; c: [number, number, number] }>();
  let p = 0, a = 0, e = 0;
  const achievements: Achievement[] = [];
  for (const r of list) {
    const when = trainingStarts.get(r.trainingId)!;
    const { year, month } = tbilisiParts(when);
    const key = `${year}-${String(month).padStart(2, '0')}`;
    let b = buckets.get(key);
    if (!b) buckets.set(key, (b = { year, month, c: [0, 0, 0] }));
    if (r.status === 'present') {
      p++;
      b.c[0]++;
      const kind = MILESTONES[p];
      if (kind) achievements.push({ kind, achievedOn: when });
    } else if (r.status === 'absent') {
      a++;
      b.c[1]++;
    } else {
      e++;
      b.c[2]++;
    }
  }

  const months: MonthStats[] = [...buckets.keys()].sort().map((k) => {
    const { year, month, c } = buckets.get(k)!;
    const recorded = c[0] + c[1] + c[2];
    return { year, month, present: c[0], absent: c[1], excused: c[2], recorded, rate: recorded === 0 ? null : c[0] / recorded };
  });

  let streak = 0;
  let prev: { year: number; month: number } | null = null;
  let streakAwarded = false;
  for (const m of months) {
    const monthEnd = new Date(Date.UTC(m.year, m.month - 1, 28));
    if (m.recorded >= MIN_TRAININGS_PER_MONTH && m.present === m.recorded) {
      achievements.push({ kind: 'perfectMonth', achievedOn: monthEnd });
    }
    const consecutive =
      prev !== null &&
      ((m.year === prev.year && m.month === prev.month + 1) || (m.year === prev.year + 1 && prev.month === 12 && m.month === 1));
    const good = m.recorded >= MIN_TRAININGS_PER_MONTH && (m.rate ?? 0) >= STREAK_MIN_RATE;
    streak = good ? (consecutive && streak > 0 ? streak + 1 : 1) : 0;
    if (streak >= 3 && !streakAwarded) {
      achievements.push({ kind: 'streak3Months', achievedOn: monthEnd });
      streakAwarded = true;
    }
    prev = { year: m.year, month: m.month };
  }

  const recorded = p + a + e;
  return {
    totalPresent: p, totalAbsent: a, totalExcused: e, recorded,
    rate: recorded === 0 ? null : p / recorded,
    months, achievements,
  };
}

/**
 * Which trainings count for statistics: not cancelled, and either `done` or
 * already started. Returns the id -> startAt map for computeAttendanceStats.
 */
export function countableTrainings(
  trainings: Array<{ id: string; startAt: Date; status: string }>,
  now: Date,
): Map<string, Date> {
  const out = new Map<string, Date>();
  for (const t of trainings) {
    if (t.status === 'cancelled') continue;
    if (t.status === 'done' || t.startAt.getTime() <= now.getTime()) out.set(t.id, t.startAt);
  }
  return out;
}
