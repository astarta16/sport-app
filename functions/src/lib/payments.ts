// Pure payment-reminder and recurring-payment logic.

import { SMS_TEMPLATES_KA, formatAmount, renderTemplate } from '../i18n/ka';
import { daysInMonth, formatShortDate, tbilisiDayDiff, tbilisiDayKey, tbilisiLocalToUtc, tbilisiParts } from './dates';
import { PaymentLite, UserLite, prefEnabled } from './types';

export type ReminderKind = 'd5' | 'd1';

/**
 * Which reminder (if any) is due for a payment on the run at `now`.
 * - only status == "pending"
 * - diff = Tbilisi calendar days from today to dueDate
 * - diff == 5 and no d5SentAt -> "d5", unless the payment was created later
 *   than 5 days before the due date (then only d1 is ever sent)
 * - diff == 1 and no d1SentAt -> "d1"
 */
export function decidePaymentReminder(p: PaymentLite, now: Date): ReminderKind | null {
  if (p.status !== 'pending') return null;
  const diff = tbilisiDayDiff(now, p.dueDate);
  if (diff === 5 && !p.reminders?.d5SentAt) {
    if (p.createdAt && tbilisiDayDiff(p.createdAt, p.dueDate) < 5) return null;
    return 'd5';
  }
  if (diff === 1 && !p.reminders?.d1SentAt) return 'd1';
  return null;
}

/** Firestore field path that claims a reminder. */
export function reminderField(kind: ReminderKind): 'reminders.d5SentAt' | 'reminders.d1SentAt' {
  return kind === 'd5' ? 'reminders.d5SentAt' : 'reminders.d1SentAt';
}

export interface ClaimedReminder {
  payment: PaymentLite;
  kind: ReminderKind;
}

export interface ReminderBatch {
  parentId: string;
  kind: ReminderKind;
  dueDayKey: string;
  dueDate: Date;
  payments: PaymentLite[];
}

/**
 * Groups claimed reminders so that one parent with several children due on
 * the same day (same reminder kind) gets ONE combined SMS.
 */
export function groupReminders(claimed: ClaimedReminder[]): ReminderBatch[] {
  const map = new Map<string, ReminderBatch>();
  for (const { payment, kind } of claimed) {
    const dueDayKey = tbilisiDayKey(payment.dueDate);
    const key = `${payment.parentId}|${kind}|${dueDayKey}`;
    let b = map.get(key);
    if (!b) {
      b = { parentId: payment.parentId, kind, dueDayKey, dueDate: payment.dueDate, payments: [] };
      map.set(key, b);
    }
    b.payments.push(payment);
  }
  return [...map.values()];
}

export interface NameLookup {
  childName: (childId: string) => string;
  sportName: (sportId: string) => string;
}

/** Renders the Georgian reminder text for a batch (single or combined). */
export function renderReminderText(batch: ReminderBatch, names: NameLookup): string {
  const total = batch.payments.reduce((s, p) => s + p.amount, 0);
  const date = formatShortDate(batch.dueDate);
  const amount = formatAmount(Math.round(total * 100) / 100);
  if (batch.payments.length === 1) {
    const p = batch.payments[0];
    const tpl = batch.kind === 'd5' ? SMS_TEMPLATES_KA.d5 : SMS_TEMPLATES_KA.d1;
    return renderTemplate(tpl, {
      child: names.childName(p.childId),
      sport: names.sportName(p.sportId),
      amount,
      date,
    });
  }
  const children = [...new Set(batch.payments.map((p) => names.childName(p.childId)))].join(', ');
  const tpl = batch.kind === 'd5' ? SMS_TEMPLATES_KA.d5Multi : SMS_TEMPLATES_KA.d1Multi;
  return renderTemplate(tpl, { children, amount, date });
}

export interface ChannelDecision {
  sms: boolean;
  push: boolean;
  smsSkipReason?: 'no_consent' | 'pref_off' | 'no_phone';
}

/**
 * SMS requires smsConsentAt, a phone number and paymentSms != false.
 * Push requires paymentReminder != false (tokens are checked by the sender).
 */
export function decideReminderChannels(parent: UserLite | undefined): ChannelDecision {
  if (!parent) return { sms: false, push: false, smsSkipReason: 'no_phone' };
  const push = prefEnabled(parent, 'paymentReminder');
  if (!parent.smsConsentAt) return { sms: false, push, smsSkipReason: 'no_consent' };
  if (!prefEnabled(parent, 'paymentSms')) return { sms: false, push, smsSkipReason: 'pref_off' };
  if (!parent.phone) return { sms: false, push, smsSkipReason: 'no_phone' };
  return { sms: true, push };
}

// ------------------------------------------------------------ recurring

/** Deterministic, idempotent payment id: `${planId}_${childId}_${yyyy-MM}`. */
export function recurringPaymentId(planId: string, childId: string, monthKey: string): string {
  return `${planId}_${childId}_${monthKey}`;
}

/**
 * Due date for a plan in the given Tbilisi month: Tbilisi midnight of the
 * plan's dayOfMonth (clamped to the month length). All reminder comparisons
 * are on Tbilisi calendar days, so the time of day does not matter.
 */
export function recurringDueDate(dayOfMonth: number, year: number, month: number): Date {
  const day = Math.min(Math.max(1, Math.floor(dayOfMonth)), daysInMonth(year, month));
  return tbilisiLocalToUtc(year, month, day, 0);
}

/** Year and month (1-12) of `now` in Tbilisi. */
export function tbilisiYearMonth(now: Date): { year: number; month: number } {
  const { year, month } = tbilisiParts(now);
  return { year, month };
}

// ------------------------------------------------------------ audit

export interface PaymentAuditInput {
  status?: string;
  updatedBy?: string | null;
}

/**
 * paymentAudit entry for a payment write, or null when the status did not
 * change (creates and deletes are not status changes). actorId is the
 * `updatedBy` set in this write (rules force it to the caller when present),
 * otherwise 'unknown' (server/admin writes).
 */
export function paymentAuditEntry(
  before: PaymentAuditInput | undefined,
  after: PaymentAuditInput | undefined,
): { from: string; to: string; actorId: string } | null {
  if (!before || !after) return null;
  if (!before.status || !after.status || before.status === after.status) return null;
  const actorId = after.updatedBy ? String(after.updatedBy) : 'unknown';
  return { from: before.status, to: after.status, actorId };
}
