// Pure decisions for the parent-facing "attendance recorded" and "coach
// feedback" notifications (v1.3.1). The triggers in triggers/progress.ts
// only load data and call notify(). Also: the series chat message and the
// plan audit actor.
import { formatShortDate } from './dates';

export type MarkStatus = 'present' | 'absent' | 'excused';

const STATUSES: readonly string[] = ['present', 'absent', 'excused'];

export function asMarkStatus(v: unknown): MarkStatus | null {
  return typeof v === 'string' && STATUSES.includes(v) ? (v as MarkStatus) : null;
}

/**
 * Status to announce for an attendance write, or null. A notification goes
 * out when a mark is created or its status changes; note-only edits and
 * deletions ("unmarked") are silent.
 */
export function attendanceNotice(
  before: { status?: unknown } | undefined,
  after: { status?: unknown } | undefined,
): MarkStatus | null {
  const next = asMarkStatus(after?.status);
  if (!next) return null;
  return asMarkStatus(before?.status) === next ? null : next;
}

/** Deterministic dedupe key: re-saving the same status never notifies twice. */
export function attendanceDedupeKey(attendanceId: string, status: MarkStatus): string {
  return `att:${attendanceId}:${status}`;
}

/** words.* key for the localized status word. */
export function attendanceWordKey(status: MarkStatus): string {
  return `words.attendance${status[0].toUpperCase()}${status.slice(1)}`;
}

/** Only newly created, parent-visible feedback is announced. */
export function feedbackNotice(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): boolean {
  return !before && !!after && after.visibleToParent === true && typeof after.childId === 'string';
}

/** Who changed the plan: `updatedBy` (rules force it to the writer's uid), else the creator. */
export function planActor(d: Record<string, unknown>): string {
  const v = typeof d.updatedBy === 'string' && d.updatedBy ? d.updatedBy : d.createdBy;
  return typeof v === 'string' && v ? v : 'unknown';
}

/** Chat message for a series write: created, or changed from a date (never in the past). */
export function scheduleSystemMessage(
  before: { startDate: string } | undefined,
  after: { startDate: string },
  todayKey: string,
): { key: 'scheduleCreated' | 'scheduleChanged'; args: Record<string, string> } {
  if (!before) return { key: 'scheduleCreated', args: {} };
  const from = after.startDate > todayKey ? after.startDate : todayKey;
  return { key: 'scheduleChanged', args: { from: formatShortDate(new Date(`${from}T12:00:00Z`)) } };
}
