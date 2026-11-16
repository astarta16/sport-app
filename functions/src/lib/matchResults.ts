// v1.5 match results: pure validation / outcome logic (unit-tested in
// test/v15.test.ts). The score is always from the coached team's side.

export type MatchOutcome = 'win' | 'draw' | 'loss';

export const MAX_SCORE = 999;
export const MAX_SUMMARY = 1000;

export interface ResultInput {
  ourScore: unknown;
  opponentScore: unknown;
  summary?: unknown;
  completedAt?: unknown;
}

export interface ValidResult {
  ourScore: number;
  opponentScore: number;
  summary: string | null;
  completedAt: Date;
}

export function outcomeOf(our: number, opponent: number): MatchOutcome {
  if (our > opponent) return 'win';
  if (our < opponent) return 'loss';
  return 'draw';
}

const isScore = (v: unknown): v is number => typeof v === 'number' && Number.isInteger(v) && v >= 0 && v <= MAX_SCORE;

/**
 * Validates the coach's input against the match and the TRUSTED server time:
 * scores are whole numbers 0–999; the completion time defaults to now and
 * must lie between the match start and now (+5 min clock tolerance); the
 * match must have started and not be cancelled.
 */
export function validateResult(
  input: ResultInput,
  match: { status: string; startAt: Date },
  now: Date,
): { ok: true; value: ValidResult } | { ok: false; error: string } {
  if (match.status === 'cancelled') return { ok: false, error: 'cancelled' };
  if (match.startAt.getTime() > now.getTime()) return { ok: false, error: 'notStarted' };
  if (!isScore(input.ourScore) || !isScore(input.opponentScore)) return { ok: false, error: 'score' };
  let summary: string | null = null;
  if (input.summary !== undefined && input.summary !== null) {
    if (typeof input.summary !== 'string' || input.summary.length > MAX_SUMMARY) return { ok: false, error: 'summary' };
    summary = input.summary.trim() || null;
  }
  let completedAt = now;
  if (input.completedAt !== undefined && input.completedAt !== null) {
    const d = typeof input.completedAt === 'string' ? new Date(input.completedAt) : undefined;
    if (!d || Number.isNaN(d.getTime())) return { ok: false, error: 'completedAt' };
    if (d.getTime() < match.startAt.getTime() || d.getTime() > now.getTime() + 5 * 60 * 1000) return { ok: false, error: 'completedAt' };
    completedAt = d;
  }
  return { ok: true, value: { ourScore: input.ourScore, opponentScore: input.opponentScore, summary, completedAt } };
}

/** True when a stored result differs from the new one (otherwise the call is a no-op). */
export function resultChanged(
  prev: { ourScore?: unknown; opponentScore?: unknown; summary?: unknown } | undefined,
  next: ValidResult,
): boolean {
  if (!prev) return true;
  return prev.ourScore !== next.ourScore || prev.opponentScore !== next.opponentScore || (prev.summary ?? null) !== next.summary;
}
