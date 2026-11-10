import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../admin';
import { SMS_SECRETS, TIMEZONE } from '../config';
import { loadChildren, loadUser, paymentFrom } from '../convert';
import { renderPush } from '../i18n/ka';
import { tbilisiLocalToUtc, tbilisiMonthKey, tbilisiParts } from '../lib/dates';
import {
  ClaimedReminder, decidePaymentReminder, decideReminderChannels, groupReminders,
  recurringDueDate, recurringPaymentId, reminderField, renderReminderText, tbilisiYearMonth,
} from '../lib/payments';
import { maskPhone, normalizeGeorgianPhone } from '../lib/phone';
import { smsSegments } from '../lib/sms/provider';
import { sendPushToUsers } from '../push';
import { createSmsProvider } from '../sms';

/**
 * 7a. Daily 10:00 Asia/Tbilisi payment reminders (d5 / d1).
 * Each reminder is CLAIMED in a transaction (reminders.d5SentAt / d1SentAt)
 * BEFORE anything is sent, so overlapping or repeated runs never duplicate.
 * Trade-off: a provider failure after the claim is logged in smsLog
 * (status "failed") and not retried automatically (at-most-once).
 */
export const sendPaymentReminders = onSchedule(
  { schedule: '0 10 * * *', timeZone: TIMEZONE, secrets: SMS_SECRETS },
  async () => {
    await runPaymentReminders(new Date());
  },
);

export async function runPaymentReminders(now: Date): Promise<{ claimed: number; batches: number }> {
  const { year, month, day } = tbilisiParts(now);
  const from = tbilisiLocalToUtc(year, month, day, 0);
  const to = new Date(from.getTime() + 7 * 86_400_000);
  const snap = await db
    .collection('payments')
    .where('status', '==', 'pending')
    .where('dueDate', '>=', Timestamp.fromDate(from))
    .where('dueDate', '<', Timestamp.fromDate(to))
    .get();

  const claimed: ClaimedReminder[] = [];
  for (const doc of snap.docs) {
    const kind = decidePaymentReminder(paymentFrom(doc.id, doc.data()), now);
    if (!kind) continue;
    const ok = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists) return false;
      if (decidePaymentReminder(paymentFrom(fresh.id, fresh.data()!), now) !== kind) return false;
      tx.update(doc.ref, { [reminderField(kind)]: FieldValue.serverTimestamp() });
      return true;
    });
    if (ok) claimed.push({ payment: paymentFrom(doc.id, doc.data()), kind });
  }

  const batches = groupReminders(claimed);
  if (batches.length === 0) {
    logger.info('payment reminders: nothing due', { candidates: snap.size });
    return { claimed: 0, batches: 0 };
  }

  const provider = createSmsProvider();
  const children = await loadChildren([...new Set(claimed.map((c) => c.payment.childId))]);
  const sportNames = new Map<string, string>();
  for (const sportId of new Set(claimed.map((c) => c.payment.sportId))) {
    const s = await db.doc(`sports/${sportId}`).get();
    sportNames.set(sportId, (s.exists && s.get('name')) || sportId);
  }
  const names = {
    childName: (id: string) => children.get(id)?.firstName ?? '',
    sportName: (id: string) => sportNames.get(id) ?? id,
  };

  for (const batch of batches) {
    const parent = await loadUser(batch.parentId);
    const text = renderReminderText(batch, names);
    const channels = decideReminderChannels(parent);
    const paymentIds = batch.payments.map((p) => p.id);
    const seg = smsSegments(text);
    const phone = normalizeGeorgianPhone(parent?.phone);

    if (channels.sms && phone) {
      let status = 'failed';
      let providerResponse = '';
      try {
        const r = await provider.send(phone, text);
        status = r.ok ? (provider.name === 'mock' ? 'mocked' : 'sent') : 'failed';
        providerResponse = r.response;
      } catch (e) {
        providerResponse = String(e).slice(0, 300);
      }
      await db.collection('smsLog').add({
        at: FieldValue.serverTimestamp(),
        phone: maskPhone(phone),
        status,
        provider: provider.name,
        providerResponse,
        paymentIds,
        kind: batch.kind,
        parentId: batch.parentId,
        segments: seg.segments,
        chars: seg.units,
      });
    } else {
      await db.collection('smsLog').add({
        at: FieldValue.serverTimestamp(),
        phone: maskPhone(parent?.phone),
        status: 'skipped',
        provider: provider.name,
        providerResponse: channels.smsSkipReason ?? (phone ? '' : 'invalid_phone'),
        paymentIds,
        kind: batch.kind,
        parentId: batch.parentId,
      });
    }

    if (channels.push && parent) {
      const msg = renderPush('paymentReminder', { text });
      await sendPushToUsers([parent], { ...msg, data: { type: 'paymentReminder', paymentIds: paymentIds.join(',') } });
    }
  }
  logger.info('payment reminders sent', { claimed: claimed.length, batches: batches.length, provider: provider.name });
  return { claimed: claimed.length, batches: batches.length };
}

/**
 * 7b. Monthly (1st, 06:00 Tbilisi): generate this month's payments from
 * active paymentPlans for every member child of the plan's group.
 * Idempotent: deterministic id `${planId}_${childId}_${yyyy-MM}` + create().
 */
export const generateRecurringPayments = onSchedule(
  { schedule: '0 6 1 * *', timeZone: TIMEZONE },
  async () => {
    await runRecurringPayments(new Date());
  },
);

export async function runRecurringPayments(now: Date): Promise<{ created: number; skipped: number }> {
  const { year, month } = tbilisiYearMonth(now);
  const monthKey = tbilisiMonthKey(now);
  const plans = await db.collection('paymentPlans').where('active', '==', true).get();
  let created = 0;
  let skipped = 0;
  for (const plan of plans.docs) {
    const p = plan.data();
    const group = await db.doc(`groups/${p.groupId}`).get();
    if (!group.exists) continue;
    const memberIds: string[] = group.get('memberChildIds') ?? [];
    const children = await loadChildren(memberIds);
    for (const child of children.values()) {
      const parentId = child.parentIds[0];
      if (!parentId) continue;
      const ref = db.doc(`payments/${recurringPaymentId(plan.id, child.id, monthKey)}`);
      try {
        await ref.create({
          childId: child.id,
          parentId,
          groupId: p.groupId,
          sportId: p.sportId,
          amount: p.amount,
          currency: 'GEL',
          dueDate: Timestamp.fromDate(recurringDueDate(p.dayOfMonth, year, month)),
          status: 'pending',
          reminders: {},
          planId: plan.id,
          createdAt: FieldValue.serverTimestamp(),
        });
        created++;
      } catch (e) {
        if ((e as { code?: number }).code === 6) skipped++; // ALREADY_EXISTS
        else throw e;
      }
    }
  }
  logger.info('recurring payments generated', { monthKey, created, skipped });
  return { created, skipped };
}
