import { describe, expect, it } from 'vitest';
import {
  decidePaymentReminder, decideReminderChannels, groupReminders, recurringDueDate,
  recurringPaymentId, reminderField, renderReminderText, tbilisiYearMonth,
} from '../src/lib/payments';
import { PaymentLite, UserLite } from '../src/lib/types';

const now = new Date('2026-11-10T06:00:00Z'); // 10:00 Tbilisi, 10 Nov
// Tbilisi midnight of a given November day
const due = (day: number) => new Date(Date.UTC(2026, 10, day) - 4 * 3600_000);

const pay = (id: string, extra: Partial<PaymentLite> = {}): PaymentLite => ({
  id, childId: 'k1', parentId: 'p1', groupId: 'g1', sportId: 'football', amount: 80,
  currency: 'GEL', dueDate: due(15), status: 'pending', createdAt: new Date('2026-11-01T08:00:00Z'),
  reminders: {}, ...extra,
});

describe('decidePaymentReminder', () => {
  it('d5 exactly 5 Tbilisi days before', () => {
    expect(decidePaymentReminder(pay('a'), now)).toBe('d5');
  });

  it('d1 exactly 1 day before', () => {
    expect(decidePaymentReminder(pay('a', { dueDate: due(11) }), now)).toBe('d1');
  });

  it('nothing on other days', () => {
    for (const d of [10, 12, 13, 14, 16]) expect(decidePaymentReminder(pay('a', { dueDate: due(d) }), now)).toBeNull();
  });

  it('idempotent: already-claimed reminders are not repeated', () => {
    expect(decidePaymentReminder(pay('a', { reminders: { d5SentAt: now } }), now)).toBeNull();
    expect(decidePaymentReminder(pay('a', { dueDate: due(11), reminders: { d1SentAt: now } }), now)).toBeNull();
  });

  it('only pending payments', () => {
    expect(decidePaymentReminder(pay('a', { status: 'paid' }), now)).toBeNull();
    expect(decidePaymentReminder(pay('a', { status: 'cancelled' }), now)).toBeNull();
  });

  it('payment created later than 5 days before due -> skip d5, still d1', () => {
    const late = pay('a', { createdAt: new Date('2026-11-12T08:00:00Z') });
    expect(decidePaymentReminder(late, now)).toBeNull();
    const dayBefore = new Date('2026-11-14T06:00:00Z');
    expect(decidePaymentReminder(late, dayBefore)).toBe('d1');
  });

  it('uses Tbilisi calendar days around midnight', () => {
    // 23:30 Tbilisi on 9 Nov -> due 14 Nov is 5 days away
    expect(decidePaymentReminder(pay('a', { dueDate: due(14) }), new Date('2026-11-09T19:30:00Z'))).toBe('d5');
    // 00:30 Tbilisi on 10 Nov -> due 14 Nov is 4 days away
    expect(decidePaymentReminder(pay('a', { dueDate: due(14) }), new Date('2026-11-09T20:30:00Z'))).toBeNull();
  });

  it('claims the right field', () => {
    expect(reminderField('d5')).toBe('reminders.d5SentAt');
    expect(reminderField('d1')).toBe('reminders.d1SentAt');
  });
});

describe('grouping and SMS text', () => {
  const names = {
    childName: (id: string) => ({ k1: 'ნიკა', k2: 'ანა' } as Record<string, string>)[id] ?? id,
    sportName: (id: string) => ({ football: 'ფეხბურთი', basketball: 'კალათბურთი' } as Record<string, string>)[id] ?? id,
  };

  it('one parent, two children, same day -> one combined batch', () => {
    const batches = groupReminders([
      { payment: pay('a'), kind: 'd5' },
      { payment: pay('b', { childId: 'k2', sportId: 'basketball', amount: 70.5 }), kind: 'd5' },
      { payment: pay('c', { parentId: 'p2' }), kind: 'd5' },
      { payment: pay('d', { dueDate: due(16) }), kind: 'd5' },
    ]);
    expect(batches).toHaveLength(3);
    const combined = batches.find((b) => b.parentId === 'p1' && b.dueDayKey === '2026-11-15')!;
    expect(combined.payments.map((p) => p.id)).toEqual(['a', 'b']);
    expect(renderReminderText(combined, names)).toBe(
      'შეხსენება: ნიკა, ანა-ს გადასახადები (150.50 ₾) გადასახდელია 15.11-მდე.',
    );
  });

  it('single d5 and d1 texts match the Georgian templates', () => {
    const [b5] = groupReminders([{ payment: pay('a'), kind: 'd5' }]);
    expect(renderReminderText(b5, names)).toBe('შეხსენება: ნიკა-ს ფეხბურთი-ის გადასახადი 80 ₾ გადასახდელია 15.11-მდე.');
    const [b1] = groupReminders([{ payment: pay('a'), kind: 'd1' }]);
    expect(renderReminderText(b1, names)).toBe(
      'შეხსენება: ხვალ 15.11 ბოლო დღეა ნიკა-ს ფეხბურთი-ის გადასახადის (80 ₾) გადასახდელად.',
    );
  });

  it('d5 and d1 for the same parent are separate batches', () => {
    const batches = groupReminders([
      { payment: pay('a'), kind: 'd5' },
      { payment: pay('b', { dueDate: due(11) }), kind: 'd1' },
    ]);
    expect(batches).toHaveLength(2);
  });
});

describe('decideReminderChannels', () => {
  const parent = (extra: Partial<UserLite> = {}): UserLite => ({
    uid: 'p1', role: 'parent', phone: '+995599123456', smsConsentAt: new Date(), notificationPrefs: {}, ...extra,
  });

  it('sms + push by default with consent', () => {
    expect(decideReminderChannels(parent())).toEqual({ sms: true, push: true });
  });
  it('no smsConsentAt -> no sms', () => {
    expect(decideReminderChannels(parent({ smsConsentAt: null }))).toMatchObject({ sms: false, push: true, smsSkipReason: 'no_consent' });
  });
  it('paymentSms=false -> no sms; paymentReminder=false -> no push', () => {
    expect(decideReminderChannels(parent({ notificationPrefs: { paymentSms: false } }))).toMatchObject({ sms: false, push: true, smsSkipReason: 'pref_off' });
    expect(decideReminderChannels(parent({ notificationPrefs: { paymentReminder: false } }))).toMatchObject({ sms: true, push: false });
  });
  it('no phone -> no sms', () => {
    expect(decideReminderChannels(parent({ phone: undefined }))).toMatchObject({ sms: false, smsSkipReason: 'no_phone' });
  });
});

describe('recurring payments', () => {
  it('deterministic id', () => {
    expect(recurringPaymentId('plan1', 'k1', '2026-11')).toBe('plan1_k1_2026-11');
  });
  it('due date is Tbilisi midnight of dayOfMonth, clamped to month length', () => {
    expect(recurringDueDate(10, 2026, 11).toISOString()).toBe('2026-11-09T20:00:00.000Z');
    expect(recurringDueDate(31, 2026, 2).toISOString()).toBe('2026-02-27T20:00:00.000Z');
  });
  it('year/month in Tbilisi', () => {
    expect(tbilisiYearMonth(new Date('2026-11-30T21:00:00Z'))).toEqual({ year: 2026, month: 12 });
  });
});
