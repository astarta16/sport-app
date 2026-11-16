// v1.7 shared scoring — pure mirror of
// lib/features/brain_academy/domain/scoring.dart (keep the numbers equal;
// functions/test/v17.test.ts pins the same cases as the Dart tests).
// The server recomputes every total from stored results, so a client can
// never submit an authoritative score or leaderboard total.

export type Game = 'memoryMatch' | 'logicQuest' | 'smartPlay' | 'quickMind' | 'sequenceMaster' | 'pathFinder';
export type Difficulty = 'easy' | 'medium' | 'hard';
export const GAMES: Game[] = ['memoryMatch', 'logicQuest', 'smartPlay', 'quickMind', 'sequenceMaster', 'pathFinder'];

export interface Result {
  id: string; childId: string; game: Game; difficulty: Difficulty; level: number; score: number;
  accuracy: number; attempts: number; durationMs: number; completed: boolean; playedAtMs: number;
}

export const RULES = {
  base: { easy: 10, medium: 20, hard: 30 } as Record<Difficulty, number>,
  perLevel: 2,
  accuracyBonusMax: 10,
  firstClearBonus: 15,
  repeatFactors: [1, 0.5, 0.25],
  dailyCap: 300,
  minDurationMs: 3000,
};

const TBILISI_MS = 4 * 3600_000;

export function validResult(r: Result): boolean {
  return r.level >= 1 && r.level <= 10 && r.score >= 0 && r.score <= 100000 && r.accuracy >= 0 && r.accuracy <= 1
    && r.attempts >= 0 && r.attempts <= 10000 && r.durationMs >= 0 && r.durationMs <= 3 * 3600_000
    && GAMES.includes(r.game) && ['easy', 'medium', 'hard'].includes(r.difficulty);
}

/** Deterministic order (time, then id) and idempotency (one per id). */
export function ordered(results: Result[]): Result[] {
  const seen = new Set<string>();
  return results
    .filter((r) => (seen.has(r.id) ? false : (seen.add(r.id), true)))
    .sort((a, b) => (a.playedAtMs !== b.playedAtMs ? a.playedAtMs - b.playedAtMs : a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
}

/** Dart's round(): half away from zero. */
function dartRound(x: number): number {
  return x < 0 ? -Math.round(-x) : Math.round(x);
}

export function score(results: Result[]): Array<{ r: Result; points: number }> {
  const out: Array<{ r: Result; points: number }> = [];
  const cleared = new Set<string>();
  const perDayKey = new Map<string, number>();
  const perDay = new Map<string, number>();
  for (const r of ordered(results)) {
    if (!r.completed || !validResult(r) || r.durationMs < RULES.minDurationMs) {
      out.push({ r, points: 0 });
      continue;
    }
    const day = Math.floor((r.playedAtMs + TBILISI_MS) / 86400_000).toString();
    const key = `${r.game}|${r.difficulty}|${r.level}`;
    const n = perDayKey.get(`${day}|${key}`) ?? 0;
    perDayKey.set(`${day}|${key}`, n + 1);
    const factor = n < RULES.repeatFactors.length ? RULES.repeatFactors[n] : 0;
    const raw = RULES.base[r.difficulty] + RULES.perLevel * (r.level - 1)
      + dartRound(RULES.accuracyBonusMax * Math.min(1, Math.max(0, r.accuracy)));
    const first = !cleared.has(key);
    cleared.add(key);
    let pts = dartRound(raw * factor) + (first ? RULES.firstClearBonus : 0);
    const used = perDay.get(day) ?? 0;
    if (used + pts > RULES.dailyCap) pts = Math.max(0, Math.min(pts, RULES.dailyCap - used));
    perDay.set(day, used + pts);
    out.push({ r, points: pts });
  }
  return out;
}

export function total(results: Result[]): number {
  return score(results).reduce((a, s) => a + s.points, 0);
}

export function pseudonymFor(childId: string): string {
  const adj = ['Swift', 'Brave', 'Clever', 'Bright', 'Bold', 'Calm', 'Quick', 'Sharp', 'Lucky', 'Happy'];
  const animal = ['Falcon', 'Tiger', 'Dolphin', 'Wolf', 'Eagle', 'Fox', 'Panda', 'Lynx', 'Owl', 'Bear'];
  let h = 0;
  for (let i = 0; i < childId.length; i++) h = (h * 31 + childId.charCodeAt(i)) & 0x7fffffff;
  return `${adj[h % adj.length]} ${animal[Math.floor(h / 10) % animal.length]} ${(h % 90) + 10}`;
}

export function ageBandOf(age: number): string {
  if (age <= 8) return '6-8';
  if (age <= 11) return '9-11';
  if (age <= 14) return '12-14';
  return '15-17';
}

export type Period = 'week' | 'month' | 'allTime';

/** Start of the period in Tbilisi (Monday for weeks). */
export function periodStartMs(p: Period, nowMs: number): number {
  const w = new Date(nowMs + TBILISI_MS);
  const y = w.getUTCFullYear(), m = w.getUTCMonth(), d = w.getUTCDate();
  if (p === 'allTime') return Date.UTC(2000, 0, 1);
  if (p === 'month') return Date.UTC(y, m, 1) - TBILISI_MS;
  const wd = w.getUTCDay() === 0 ? 7 : w.getUTCDay();
  return Date.UTC(y, m, d - (wd - 1)) - TBILISI_MS;
}

export interface Participant { childId: string; displayName: string; ageBand: string }
export interface Entry { rank: number; childId: string; displayName: string; points: number }

/** Points desc, then who reached the total first, then id — never ambiguous. */
export function rank(participants: Participant[], results: Result[], period: Period, nowMs: number, games: Game[]): Entry[] {
  const from = periodStartMs(period, nowMs);
  const allowed = new Set(games.length ? games : GAMES);
  const rows = participants.map((p) => {
    let pts = 0;
    let reached = Date.UTC(2000, 0, 1);
    for (const s of score(results.filter((r) => r.childId === p.childId))) {
      if (s.points === 0 || !allowed.has(s.r.game) || s.r.playedAtMs < from) continue;
      pts += s.points;
      reached = s.r.playedAtMs;
    }
    return { p, pts, reached };
  });
  rows.sort((a, b) => (a.pts !== b.pts ? b.pts - a.pts : a.reached !== b.reached ? a.reached - b.reached
    : a.p.childId < b.p.childId ? -1 : 1));
  return rows.map((x, i) => ({ rank: i + 1, childId: x.p.childId, displayName: x.p.displayName, points: x.pts }));
}
