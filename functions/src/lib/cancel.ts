// Cancellation reason validation (trainings and matches) — mirrors the rules.

export const CANCEL_REASON_CODES = ['illness', 'weather', 'venueBusy', 'other'] as const;
export type CancelReasonCode = (typeof CANCEL_REASON_CODES)[number];

export const CANCEL_REASON_LABELS_KA: Record<CancelReasonCode, string> = {
  illness: 'ავადმყოფობა',
  weather: 'ამინდი',
  venueBusy: 'მოედანი დაკავებულია',
  other: 'სხვა',
};

export function isValidCancel(code: unknown, reason: unknown): boolean {
  if (typeof code !== 'string' || !(CANCEL_REASON_CODES as readonly string[]).includes(code)) return false;
  if (typeof reason !== 'string') return false;
  const n = reason.trim().length;
  return n >= 5 && reason.length <= 300;
}

/** Human-readable reason for push / system chat message. */
export function cancelReasonText(code: unknown, reason: unknown): string {
  const label = typeof code === 'string' && code in CANCEL_REASON_LABELS_KA ? CANCEL_REASON_LABELS_KA[code as CancelReasonCode] : '';
  const r = typeof reason === 'string' ? reason.trim() : '';
  if (label && r) return `${label} — ${r}`;
  return r || label;
}
