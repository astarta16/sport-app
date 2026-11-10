// Pure medical-certificate status and expiry-notification decisions.

import { tbilisiDayDiff } from './dates';
import { CertificateLite, CertificateStatus } from './types';

export const EXPIRING_WINDOW_DAYS = 14;

/** Tbilisi calendar days until validUntil (0 = expires today, negative = past). */
export function daysUntilExpiry(validUntil: Date, now: Date): number {
  return tbilisiDayDiff(now, validUntil);
}

/**
 * expired  : validUntil instant has passed
 * expiring : expires within the next 14 calendar days (inclusive)
 * valid    : otherwise
 */
export function computeCertificateStatus(validUntil: Date, now: Date): CertificateStatus {
  if (validUntil.getTime() <= now.getTime()) return 'expired';
  return daysUntilExpiry(validUntil, now) <= EXPIRING_WINDOW_DAYS ? 'expiring' : 'valid';
}

export type ExpiryStage = 14 | 3 | 0;

export interface ExpiryDecision {
  /** Stage to notify now, or null. */
  stage: ExpiryStage | null;
  daysLeft: number;
  status: CertificateStatus;
  /** Notification marker fields to set (stage plus any less urgent stages it supersedes). */
  markFields: Array<'notified14At' | 'notified3At' | 'notified0At'>;
  /** v1.3 idempotency flags (field paths) for the same stages. */
  reminderFields: ReminderField[];
}

export type ReminderField = 'reminders.d14SentAt' | 'reminders.d3SentAt' | 'reminders.d0SentAt';

const REMINDER_FIELD: Record<ExpiryStage, ReminderField> = {
  14: 'reminders.d14SentAt',
  3: 'reminders.d3SentAt',
  0: 'reminders.d0SentAt',
};

const REMINDER_KEY: Record<ExpiryStage, 'd14SentAt' | 'd3SentAt' | 'd0SentAt'> = { 14: 'd14SentAt', 3: 'd3SentAt', 0: 'd0SentAt' };

/** Reminder day for `daysLeft`: 14 (≤ 14 days), 3 (≤ 3 days), 0 (expiry day or later), else null. */
export function expiryStageFor(daysLeft: number): ExpiryStage | null {
  if (daysLeft <= 0) return 0;
  if (daysLeft <= 3) return 3;
  if (daysLeft <= 14) return 14;
  return null;
}

const FIELD: Record<ExpiryStage, 'notified14At' | 'notified3At' | 'notified0At'> = {
  14: 'notified14At',
  3: 'notified3At',
  0: 'notified0At',
};

/**
 * Decide the expiry push for the daily 09:00 run.
 * Stages fire at <=14 days, <=3 days and on/after the expiry day, each once
 * (idempotent via notified14At / notified3At / notified0At). Only the most
 * urgent pending stage is sent; the less urgent ones it supersedes are marked
 * too, so a parent never receives a stale "14 days left" after a "3 days" one.
 */
export function decideExpiryNotification(cert: CertificateLite, now: Date): ExpiryDecision {
  const daysLeft = daysUntilExpiry(cert.validUntil, now);
  const status = computeCertificateStatus(cert.validUntil, now);
  // v1.3 flags (reminders.dXSentAt) and the v1.2 flags (notifiedXAt) both count as "sent".
  const sent = (s: ExpiryStage) => !!cert[FIELD[s]] || !!cert.reminders?.[REMINDER_KEY[s]];

  const stage = expiryStageFor(daysLeft);

  if (stage === null || sent(stage)) {
    return { stage: null, daysLeft, status, markFields: [], reminderFields: [] };
  }
  const ladder: ExpiryStage[] = [14, 3, 0];
  const pending = ladder.filter((s) => s >= stage && !sent(s));
  return { stage, daysLeft, status, markFields: pending.map((s) => FIELD[s]), reminderFields: pending.map((s) => REMINDER_FIELD[s]) };
}

// ------------------------------------------------------------ v1.3: current certificate

export interface CertificateForSelection {
  id: string;
  childId: string;
  validUntil: Date;
  sportId?: string | null;
  replacedBy?: string | null;
  createdAt?: Date | null;
}

/** A certificate applies to `sportId` when it is for that sport or general (sportId null). */
export function certificateApplies(c: Pick<CertificateForSelection, 'sportId'>, sportId: string | null | undefined): boolean {
  const own = c.sportId ?? null;
  if (own === null) return true;
  return !!sportId && own === sportId;
}

/**
 * Current certificate of a child for a sport (mirrors the app):
 * among the child's NON-replaced certificates that apply to the sport
 * (matching sportId, or general = sportId null), the one with the latest
 * validUntil; ties → sport-specific before general, then the newest createdAt,
 * then the id. `sportId` null/undefined → only general certificates count.
 */
export function selectCurrentCertificate<T extends CertificateForSelection>(
  certs: T[],
  childId: string,
  sportId: string | null | undefined,
): T | null {
  let best: T | null = null;
  const rank = (c: T) => [c.validUntil.getTime(), c.sportId ? 1 : 0, c.createdAt?.getTime() ?? 0] as const;
  for (const c of certs) {
    if (c.childId !== childId || c.replacedBy) continue;
    if (!certificateApplies(c, sportId)) continue;
    if (!best) {
      best = c;
      continue;
    }
    const a = rank(c);
    const b = rank(best);
    const cmp = a[0] - b[0] || a[1] - b[1] || a[2] - b[2] || (c.id > best.id ? 1 : c.id < best.id ? -1 : 0);
    if (cmp > 0) best = c;
  }
  return best;
}

/**
 * Expiry reminder decision for one certificate given its siblings (all
 * certificates of the same child). No reminder for a replaced certificate,
 * or when another applicable certificate is current with a later validUntil
 * (the parent already uploaded a newer one).
 */
export function decideCertificateReminder(
  cert: CertificateLite,
  siblings: CertificateLite[],
  now: Date,
): ExpiryDecision & { skipped?: 'replaced' | 'superseded' } {
  const d = decideExpiryNotification(cert, now);
  if (d.stage === null) return d;
  const none = { ...d, stage: null, markFields: [], reminderFields: [] };
  if (cert.replacedBy) return { ...none, skipped: 'replaced' };
  const current = selectCurrentCertificate([cert, ...siblings.filter((s) => s.id !== cert.id)], cert.childId, cert.sportId ?? null);
  if (current && current.id !== cert.id && current.validUntil.getTime() > cert.validUntil.getTime()) {
    return { ...none, skipped: 'superseded' };
  }
  return d;
}

/** Template for a reminder stage: 0 → expired (past) or expires today; 3/14 → expiring. */
export function reminderTemplateFor(stage: ExpiryStage, status: CertificateStatus): 'certificateExpired' | 'certificateExpiresToday' | 'certificateExpiring' {
  if (stage === 0) return status === 'expired' ? 'certificateExpired' : 'certificateExpiresToday';
  return 'certificateExpiring';
}

// ------------------------------------------------------------ v1.3: compliance

export type ComplianceState = 'valid' | 'expiring' | 'expired' | 'missing';

export function complianceStateOf(current: { validUntil: Date } | null, now: Date): ComplianceState {
  return current ? computeCertificateStatus(current.validUntil, now) : 'missing';
}

export interface ComplianceGroupInput {
  groupId: string;
  groupName?: string;
  sportId?: string | null;
  memberChildIds: string[];
}

export interface ComplianceCounts {
  groupId: string;
  groupName: string;
  valid: number;
  expiring: number;
  expired: number;
  missing: number;
}

/**
 * Per-group counts of member children by their CURRENT certificate for the
 * group's sport. Counts only — no child ids, names or documents.
 */
export function countGroupCompliance(
  group: ComplianceGroupInput,
  certsByChild: Map<string, CertificateForSelection[]>,
  now: Date,
): ComplianceCounts {
  const out: ComplianceCounts = { groupId: group.groupId, groupName: group.groupName ?? '', valid: 0, expiring: 0, expired: 0, missing: 0 };
  for (const childId of new Set(group.memberChildIds)) {
    const current = selectCurrentCertificate(certsByChild.get(childId) ?? [], childId, group.sportId ?? null);
    out[complianceStateOf(current, now)]++;
  }
  return out;
}
