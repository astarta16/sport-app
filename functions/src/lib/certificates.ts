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
  const sent = (s: ExpiryStage) => !!cert[FIELD[s]];

  let stage: ExpiryStage | null = null;
  if (daysLeft <= 0) stage = 0;
  else if (daysLeft <= 3) stage = 3;
  else if (daysLeft <= 14) stage = 14;

  if (stage === null || sent(stage)) {
    return { stage: null, daysLeft, status, markFields: [] };
  }
  const ladder: ExpiryStage[] = [14, 3, 0];
  const markFields = ladder
    .filter((s) => s >= stage! && !sent(s))
    .map((s) => FIELD[s]);
  return { stage, daysLeft, status, markFields };
}
