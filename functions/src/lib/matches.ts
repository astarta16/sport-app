// Pure decisions for match writes and reminders.

export type MatchStatus = 'scheduled' | 'cancelled' | 'moved' | 'played';

export interface MatchLite {
  groupId: string;
  startAt: Date;
  status: MatchStatus;
  opponentName?: string;
  reminder1dSentAt?: Date | null;
  reminder2hSentAt?: Date | null;
}

export type MatchEvent = { type: 'newMatch' } | { type: 'matchChanged'; change: 'cancelled' | 'moved' };

export function classifyMatchWrite(before: MatchLite | undefined, after: MatchLite | undefined): MatchEvent[] {
  if (!after) return [];
  if (!before) return after.status === 'cancelled' ? [] : [{ type: 'newMatch' }];
  if (after.status === 'cancelled' && before.status !== 'cancelled') return [{ type: 'matchChanged', change: 'cancelled' }];
  if (after.status !== 'cancelled' && after.status !== 'played' && before.startAt.getTime() !== after.startAt.getTime()) {
    return [{ type: 'matchChanged', change: 'moved' }];
  }
  return [];
}

/** Server follow-up when startAt changed: status moved + re-arm reminders. */
export function movedMatchPatch(before: MatchLite | undefined, after: MatchLite | undefined): boolean {
  if (!before || !after) return false;
  if (before.startAt.getTime() === after.startAt.getTime()) return false;
  return after.status === 'scheduled' || after.status === 'moved';
}

export const MATCH_REMINDER_1D_MS = 24 * 3_600_000;
export const MATCH_REMINDER_2H_MS = 2 * 3_600_000;

export type MatchReminderStage = '1d' | '2h';

/**
 * Due reminder for a match at `now`:
 * - 2h stage when the match starts within (0, 2h] and none was sent;
 * - 1d stage when it starts within (2h, 24h] and none was sent.
 * Inside the 2-hour window an unsent 1-day reminder is skipped (only 2h goes out).
 */
export function matchReminderStage(m: MatchLite, now: Date): MatchReminderStage | null {
  if (m.status !== 'scheduled' && m.status !== 'moved') return null;
  const delta = m.startAt.getTime() - now.getTime();
  if (delta <= 0) return null;
  if (delta <= MATCH_REMINDER_2H_MS) return m.reminder2hSentAt ? null : '2h';
  if (delta <= MATCH_REMINDER_1D_MS) return m.reminder1dSentAt ? null : '1d';
  return null;
}

export function matchReminderFields(stage: MatchReminderStage): string[] {
  // Claiming the 2h stage also closes the 1d stage.
  return stage === '2h' ? ['reminder2hSentAt', 'reminder1dSentAt'] : ['reminder1dSentAt'];
}
