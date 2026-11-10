import { describe, expect, it } from 'vitest';
import {
  CATALOGS, LOCALES, cancelReasonTextL, flattenCatalog, normalizeLocale, placeholdersOf, pushText, t, weekdaySummaryL,
} from '../src/i18n';
import { MESSAGES_KA } from '../src/i18n/ka';
import {
  countGroupCompliance, decideCertificateReminder, decideExpiryNotification, expiryStageFor, reminderTemplateFor,
  selectCurrentCertificate,
} from '../src/lib/certificates';
import { categoryFor } from '../src/lib/notifications';
import {
  canReviewPayments, canViewReceipt, normalizeManagerIds, parseReceiptPath, paymentDisplayState, planReview,
  planStartReview, planSubmit, receiptMetadataMatches, validateProofInput, verificationStateOf,
} from '../src/lib/paymentProofs';
import { renderReminderText } from '../src/lib/payments';
import { RATE_LIMITS } from '../src/lib/rateLimit';
import {
  canViewPlan, computePlanCoachIds, computePlanReaderIds, isHttpsLink, planEvents, planTransitionAllowed, planUploadAllowed,
  validatePlan,
} from '../src/lib/trainingPlans';
import { CertificateLite } from '../src/lib/types';

// ------------------------------------------------------------------ i18n
describe('i18n: template completeness', () => {
  const ka = flattenCatalog(MESSAGES_KA);
  it('ka catalog is non-trivial', () => {
    expect(Object.keys(ka).length).toBeGreaterThan(50);
  });
  for (const locale of LOCALES) {
    it(`${locale}: exactly the same keys as ka`, () => {
      expect(Object.keys(flattenCatalog(CATALOGS[locale])).sort()).toEqual(Object.keys(ka).sort());
    });
    it(`${locale}: identical placeholders per key and no empty strings`, () => {
      const flat = flattenCatalog(CATALOGS[locale]);
      for (const [key, tpl] of Object.entries(ka)) {
        expect(placeholdersOf(flat[key]), `${locale}:${key}`).toEqual(placeholdersOf(tpl));
        expect(flat[key].trim().length, `${locale}:${key}`).toBeGreaterThan(0);
      }
    });
  }
  it('en/ru texts are not Georgian copies', () => {
    const geo = /[Ⴀ-ჿ]/;
    for (const l of ['en', 'ru'] as const) {
      for (const [k, v] of Object.entries(flattenCatalog(CATALOGS[l]))) expect(geo.test(v), `${l}:${k}`).toBe(false);
    }
  });
  it('English SMS stay GSM-7 friendly (no ₾)', () => {
    for (const v of Object.values(CATALOGS.en.sms)) expect(v.includes('₾')).toBe(false);
  });
});

describe('i18n: t() and helpers', () => {
  it('renders in the requested locale', () => {
    expect(t('en', 'push.newTraining.title')).toBe('New training');
    expect(t('ru', 'push.newTraining.title')).toBe('Новая тренировка');
    expect(t('ka', 'push.newTraining.title')).toBe('ახალი ვარჯიში');
    expect(t('en', 'push.newMatch.body', { group: 'U12', opponent: 'Dinamo', date: '12.11', time: '18:00' })).toBe('U12: Dinamo, 12.11, 18:00');
  });
  it('falls back to ka for unknown locales and to the key for unknown keys', () => {
    expect(t('de', 'push.newTraining.title')).toBe('ახალი ვარჯიში');
    expect(t(undefined, 'sms.invite', { group: 'G', child: 'C' })).toMatch(/^G: მოწვევა \(C\)/);
    expect(t('en', 'nope.missing')).toBe('nope.missing');
  });
  it('normalizeLocale accepts only ka/en/ru', () => {
    expect(normalizeLocale('en')).toBe('en');
    expect(normalizeLocale('ru')).toBe('ru');
    expect(normalizeLocale('EN')).toBe('ka');
    expect(normalizeLocale(null)).toBe('ka');
  });
  it('pushText: ka fallback + per-locale rendering, vars may depend on the locale', () => {
    const p = pushText('inviteAnswered', (l) => ({ child: 'Nika', answer: t(l, 'words.inviteAccepted') }));
    expect(p.title).toBe('მოწვევაზე პასუხი');
    expect(p.localized('en')).toEqual({ title: 'Invitation answered', body: 'Nika: invitation accepted' });
    expect(p.localized('ru').body).toBe('Nika: приглашение принято');
  });
  it('weekday summary and cancel reasons are localized', () => {
    expect(weekdaySummaryL('en', [3, 1, 1], '18:00')).toBe('Mon, Wed 18:00');
    expect(weekdaySummaryL('ru', [1, 3], '18:00')).toBe('Пн, Ср 18:00');
    expect(weekdaySummaryL('ka', [1, 3], '18:00')).toBe('ორშ, ოთხ 18:00');
    expect(cancelReasonTextL('en', 'weather', ' heavy rain ')).toBe('Weather — heavy rain');
    expect(cancelReasonTextL('ru', 'illness', '')).toBe('Болезнь');
    expect(cancelReasonTextL('ka', 'bogus', 'x')).toBe('x');
  });
  it('payment reminder SMS in the parent locale', () => {
    const batch = { parentId: 'p', kind: 'd5' as const, dueDayKey: '2026-11-15', dueDate: new Date('2026-11-15T08:00:00Z'),
      payments: [{ id: 'a', childId: 'c1', parentId: 'p', groupId: 'g', sportId: 's', amount: 80, currency: 'GEL' as const, dueDate: new Date('2026-11-15T08:00:00Z'), status: 'pending' as const }] };
    const names = { childName: () => 'Nika', sportName: () => 'football' };
    expect(renderReminderText(batch, names, 'en')).toBe("Reminder: Nika's football fee of 80 GEL is due by 15.11.");
    expect(renderReminderText(batch, names, 'ru')).toBe('Напоминание: оплата за football (Nika) — 80 ₾ до 15.11.');
    expect(renderReminderText(batch, names)).toMatch(/^შეხსენება:/);
  });
  it('new notification types have categories', () => {
    expect(categoryFor('paymentProofSubmitted')).toBe('payments');
    expect(categoryFor('paymentProofApproved')).toBe('payments');
    expect(categoryFor('paymentProofRejected')).toBe('payments');
    expect(categoryFor('trainingPlanPublished')).toBe('trainings');
  });
});

// ------------------------------------------------------------------ certificates
const now = new Date('2026-11-10T05:00:00Z'); // 09:00 Tbilisi
const cert = (id: string, validUntil: string, extra: Partial<CertificateLite> = {}): CertificateLite => ({
  id, childId: 'k1', validUntil: new Date(validUntil), ...extra,
});

describe('current certificate selection', () => {
  it('latest validUntil among matching-sport and general, non-replaced', () => {
    const certs = [
      cert('gen', '2027-03-01T00:00:00Z'),
      cert('foot', '2027-01-01T00:00:00Z', { sportId: 'football' }),
      cert('swim', '2027-06-01T00:00:00Z', { sportId: 'swimming' }),
    ];
    expect(selectCurrentCertificate(certs, 'k1', 'football')?.id).toBe('gen');
    expect(selectCurrentCertificate(certs, 'k1', 'swimming')?.id).toBe('swim');
    expect(selectCurrentCertificate(certs, 'k1', null)?.id).toBe('gen');
    expect(selectCurrentCertificate(certs, 'other', 'football')).toBeNull();
  });
  it('replaced certificates are never current', () => {
    const certs = [cert('old', '2027-06-01T00:00:00Z', { replacedBy: 'new' }), cert('new', '2027-01-01T00:00:00Z')];
    expect(selectCurrentCertificate(certs, 'k1', 'football')?.id).toBe('new');
  });
  it('ties: sport-specific first, then newest createdAt', () => {
    const same = '2027-01-01T00:00:00Z';
    expect(selectCurrentCertificate([cert('g', same), cert('s', same, { sportId: 'football' })], 'k1', 'football')?.id).toBe('s');
    expect(selectCurrentCertificate([
      cert('a', same, { createdAt: new Date('2026-01-01') }), cert('b', same, { createdAt: new Date('2026-02-01') }),
    ], 'k1', 'football')?.id).toBe('b');
  });
  it('no certificate → null', () => {
    expect(selectCurrentCertificate([], 'k1', 'football')).toBeNull();
  });
});

describe('certificate reminders 14 / 3 / 0', () => {
  it('stage selection by days left', () => {
    expect(expiryStageFor(15)).toBeNull();
    expect(expiryStageFor(14)).toBe(14);
    expect(expiryStageFor(4)).toBe(14);
    expect(expiryStageFor(3)).toBe(3);
    expect(expiryStageFor(1)).toBe(3);
    expect(expiryStageFor(0)).toBe(0);
    expect(expiryStageFor(-5)).toBe(0);
  });
  it('writes the v1.3 reminders.dXSentAt flags alongside the legacy ones', () => {
    const d = decideExpiryNotification(cert('c', '2026-11-13T10:00:00Z'), now);
    expect(d.stage).toBe(3);
    expect(d.reminderFields).toEqual(['reminders.d14SentAt', 'reminders.d3SentAt']);
  });
  it('idempotent via reminders.* flags', () => {
    const c = cert('c', '2026-11-24T10:00:00Z', { reminders: { d14SentAt: now } });
    expect(decideExpiryNotification(c, now).stage).toBeNull();
  });
  it('idempotent via legacy notifiedXAt flags (old certificates)', () => {
    const c = cert('c', '2026-11-13T10:00:00Z', { notified3At: now });
    expect(decideExpiryNotification(c, now).stage).toBeNull();
  });
  it('day 0 after a sent 3-day reminder', () => {
    const d = decideExpiryNotification(cert('c', '2026-11-10T15:00:00Z', { reminders: { d14SentAt: now, d3SentAt: now } }), now);
    expect(d.stage).toBe(0);
    expect(d.reminderFields).toEqual(['reminders.d0SentAt']);
  });
  it('replaced or superseded certificates are not reminded', () => {
    const old = cert('old', '2026-11-13T10:00:00Z');
    expect(decideCertificateReminder({ ...old, replacedBy: 'new' }, [], now)).toMatchObject({ stage: null, skipped: 'replaced' });
    const newer = cert('new', '2027-11-01T00:00:00Z');
    expect(decideCertificateReminder(old, [old, newer], now)).toMatchObject({ stage: null, skipped: 'superseded', reminderFields: [] });
    // A newer certificate for ANOTHER sport does not supersede a general one.
    expect(decideCertificateReminder(old, [old, cert('swim', '2027-11-01T00:00:00Z', { sportId: 'swimming' })], now).stage).toBe(3);
  });
  it('template per stage', () => {
    expect(reminderTemplateFor(14, 'expiring')).toBe('certificateExpiring');
    expect(reminderTemplateFor(0, 'expiring')).toBe('certificateExpiresToday');
    expect(reminderTemplateFor(0, 'expired')).toBe('certificateExpired');
  });
});

describe('compliance counting', () => {
  it('counts valid / expiring / expired / missing per group, current cert per child', () => {
    const certsByChild = new Map([
      ['a', [cert('a1', '2027-06-01T00:00:00Z')].map((c) => ({ ...c, childId: 'a' }))],
      ['b', [cert('b1', '2026-11-20T00:00:00Z', { sportId: 'football' })].map((c) => ({ ...c, childId: 'b' }))],
      ['c', [cert('c1', '2026-10-01T00:00:00Z')].map((c) => ({ ...c, childId: 'c' }))],
      ['d', [cert('d1', '2027-06-01T00:00:00Z', { sportId: 'swimming' })].map((c) => ({ ...c, childId: 'd' }))],
      ['e', [cert('e1', '2027-06-01T00:00:00Z', { replacedBy: 'x' })].map((c) => ({ ...c, childId: 'e' }))],
    ]);
    const r = countGroupCompliance({ groupId: 'g', groupName: 'U12', sportId: 'football', memberChildIds: ['a', 'b', 'c', 'd', 'e', 'f', 'a'] }, certsByChild, now);
    expect(r).toEqual({ groupId: 'g', groupName: 'U12', valid: 1, expiring: 1, expired: 1, missing: 3 });
  });
  it('returns counts only (no ids or names of children)', () => {
    const r = countGroupCompliance({ groupId: 'g', memberChildIds: ['secretChild'] }, new Map(), now);
    expect(JSON.stringify(r)).not.toContain('secretChild');
  });
});

// ------------------------------------------------------------------ payment proofs
describe('payment proof input', () => {
  const ok = {
    proofId: 'pr1', paymentId: 'pay1', paidOn: '2026-11-09', reference: ' TBC-123 ', note: '',
    receiptPath: 'receipts/par1/pr1/receipt.jpg', receiptMime: 'image/jpeg', receiptSize: 2048,
  };
  it('accepts a valid payload and takes proofId from the path', () => {
    const r = validateProofInput(ok, 'par1', '2026-11-10');
    expect(r.ok && r.value).toMatchObject({ proofId: 'pr1', reference: 'TBC-123', note: null });
  });
  it('rejects bad paths, foreign paths, mismatched proofId, mime, size, dates', () => {
    const bad = (o: Record<string, unknown>) => validateProofInput({ ...ok, ...o }, 'par1', '2026-11-10').ok;
    expect(bad({ receiptPath: 'receipts/par2/pr1/r.jpg' })).toBe(false);
    expect(bad({ receiptPath: 'medical/par1/pr1/r.jpg' })).toBe(false);
    expect(bad({ receiptPath: 'receipts/par1/../x/r.jpg' })).toBe(false);
    expect(bad({ proofId: 'other' })).toBe(false);
    expect(bad({ receiptMime: 'text/html' })).toBe(false);
    expect(bad({ receiptSize: 10 * 1024 * 1024 + 1 })).toBe(false);
    expect(bad({ receiptSize: 10 * 1024 * 1024 })).toBe(true);
    expect(bad({ paidOn: '2026-02-30' })).toBe(false);
    expect(bad({ paidOn: '2026-11-11' })).toBe(false);
    expect(bad({ reference: 'x'.repeat(61) })).toBe(false);
    expect(bad({ note: 'x'.repeat(301) })).toBe(false);
  });
  it('parses receipt paths and checks uploaded metadata', () => {
    expect(parseReceiptPath('receipts/u/p/f.pdf')).toEqual({ parentId: 'u', proofId: 'p', file: 'f.pdf' });
    expect(parseReceiptPath('receipts/u/p/q/f.pdf')).toBeNull();
    expect(receiptMetadataMatches({ receiptMime: 'image/png', receiptSize: 10 }, { contentType: 'image/png', size: '10' })).toBe(true);
    expect(receiptMetadataMatches({ receiptMime: 'image/png', receiptSize: 10 }, { contentType: 'image/jpeg', size: 10 })).toBe(false);
  });
});

describe('payment proof state machine', () => {
  const pending = { status: 'pending', parentId: 'par1' };
  it('first submission', () => {
    expect(planSubmit(pending, 'par1', [], 'p1')).toEqual({ ok: true, action: 'submitted', supersede: [] });
  });
  it('only the payment parent; not when paid or cancelled', () => {
    expect(planSubmit(pending, 'par2', [], 'p1')).toMatchObject({ ok: false, code: 'permission-denied' });
    expect(planSubmit({ ...pending, status: 'paid' }, 'par1', [], 'p1')).toMatchObject({ ok: false, code: 'failed-precondition' });
    expect(planSubmit({ ...pending, status: 'cancelled' }, 'par1', [], 'p1')).toMatchObject({ ok: false, code: 'failed-precondition' });
    expect(planSubmit(undefined, 'par1', [], 'p1')).toMatchObject({ ok: false, code: 'not-found' });
  });
  it('second submission while one is open → already-exists', () => {
    expect(planSubmit(pending, 'par1', [{ id: 'p1', status: 'submitted' }], 'p2')).toMatchObject({ ok: false, code: 'already-exists' });
    expect(planSubmit(pending, 'par1', [{ id: 'p1', status: 'under_review' }], 'p2')).toMatchObject({ ok: false, code: 'already-exists' });
    expect(planSubmit(pending, 'par1', [{ id: 'p1', status: 'superseded' }], 'p1')).toMatchObject({ ok: false, code: 'already-exists' });
  });
  it('resubmission after a rejection supersedes the rejected proof', () => {
    const r = planSubmit({ ...pending, verification: { state: 'rejected' } }, 'par1', [{ id: 'p1', status: 'rejected' }, { id: 'p0', status: 'superseded' }], 'p2');
    expect(r).toEqual({ ok: true, action: 'resubmitted', supersede: ['p1'] });
  });
  it('approve marks paid; reject needs ≥ 5 chars', () => {
    expect(planReview({ status: 'submitted' }, { status: 'pending' }, 'approve', undefined)).toMatchObject({ ok: true, proofStatus: 'approved', markPaid: true, verificationState: 'none' });
    expect(planReview({ status: 'under_review' }, { status: 'pending' }, 'reject', 'Wrong amount')).toMatchObject({ ok: true, proofStatus: 'rejected', markPaid: false, reason: 'Wrong amount', verificationState: 'rejected' });
    expect(planReview({ status: 'submitted' }, { status: 'pending' }, 'reject', '  abc ')).toMatchObject({ ok: false, code: 'invalid-argument' });
    expect(planReview({ status: 'submitted' }, { status: 'pending' }, 'reject', undefined)).toMatchObject({ ok: false, code: 'invalid-argument' });
    expect(planReview({ status: 'submitted' }, { status: 'pending' }, 'maybe', undefined)).toMatchObject({ ok: false, code: 'invalid-argument' });
  });
  it('double / concurrent decisions: the second one sees the decided proof → failed-precondition', () => {
    // Simulates two reviewers whose transactions serialize: the loser re-reads the proof after the winner committed.
    let proof = { status: 'submitted' };
    let payment = { status: 'pending' };
    const decide = (decision: string, reason?: string) => {
      const r = planReview(proof, payment, decision, reason);
      if (r.ok) {
        proof = { status: r.proofStatus };
        if (r.markPaid) payment = { status: 'paid' };
      }
      return r;
    };
    expect(decide('approve').ok).toBe(true);
    expect(decide('approve')).toMatchObject({ ok: false, code: 'failed-precondition' });
    expect(decide('reject', 'Too late now')).toMatchObject({ ok: false, code: 'failed-precondition' });
    expect(payment.status).toBe('paid');
  });
  it('payment paid directly meanwhile → review fails', () => {
    expect(planReview({ status: 'submitted' }, { status: 'paid' }, 'approve', undefined)).toMatchObject({ ok: false, code: 'failed-precondition' });
  });
  it('start review is idempotent and fails on decided proofs', () => {
    expect(planStartReview({ status: 'submitted' })).toEqual({ ok: true, changed: true });
    expect(planStartReview({ status: 'under_review' })).toEqual({ ok: true, changed: false });
    expect(planStartReview({ status: 'approved' })).toMatchObject({ ok: false, code: 'failed-precondition' });
  });
  it('display state and migration default', () => {
    expect(verificationStateOf({})).toBe('none');
    expect(paymentDisplayState({ status: 'pending' })).toBe('pending');
    expect(paymentDisplayState({ status: 'pending', verification: { state: 'under_review' } })).toBe('under_review');
    expect(paymentDisplayState({ status: 'paid', verification: { state: 'rejected' } })).toBe('paid');
    expect(paymentDisplayState({ status: 'cancelled' })).toBe('cancelled');
  });
  it('rate limit: 10 proofs per 24 h', () => {
    expect(RATE_LIMITS.paymentProofs).toEqual({ limit: 10, windowMs: 86_400_000 });
  });
});

describe('payment reviewers', () => {
  const scope = (platform = false, clubIds: string[] = []) => ({ platform, clubIds });
  const group = { clubId: 'club1', paymentManagerIds: ['coachPM'] };
  it('payment manager (approved coach), club admin of the club, platform admin', () => {
    expect(canReviewPayments({ uid: 'coachPM', role: 'coach', coachStatus: 'approved', scope: scope() }, group)).toBe(true);
    expect(canReviewPayments({ uid: 'ca', role: 'parent', scope: scope(false, ['club1']) }, group)).toBe(true);
    expect(canReviewPayments({ uid: 'pa', scope: scope(true) }, group)).toBe(true);
  });
  it('coaches are not reviewers by default; suspended managers and other club admins are not', () => {
    expect(canReviewPayments({ uid: 'coach2', role: 'coach', coachStatus: 'approved', scope: scope() }, group)).toBe(false);
    expect(canReviewPayments({ uid: 'coachPM', role: 'coach', coachStatus: 'suspended', scope: scope() }, group)).toBe(false);
    expect(canReviewPayments({ uid: 'cb', role: 'parent', scope: scope(false, ['club2']) }, group)).toBe(false);
    expect(canReviewPayments({ uid: 'cb', scope: scope(false, ['club2']) }, { clubId: 'club1' })).toBe(false);
  });
  it('receipt: owner parent or reviewer', () => {
    expect(canViewReceipt({ uid: 'par1', role: 'parent', scope: scope() }, { parentId: 'par1' }, group)).toBe(true);
    expect(canViewReceipt({ uid: 'par2', role: 'parent', scope: scope() }, { parentId: 'par1' }, group)).toBe(false);
  });
  it('paymentManagerIds normalization', () => {
    expect(normalizeManagerIds(['b', 'a', 'a'])).toEqual(['a', 'b']);
    expect(normalizeManagerIds(['a/b'])).toBeNull();
    expect(normalizeManagerIds('a')).toBeNull();
    expect(normalizeManagerIds([])).toEqual([]);
  });
});

// ------------------------------------------------------------------ training plans
describe('training plan validation', () => {
  const plan = (o: Record<string, unknown> = {}) => ({
    title: 'Winter plan', description: '', type: 'weekly', groupIds: ['g1'], clubId: 'club1', startDate: '2026-12-01', endDate: null,
    status: 'draft', createdBy: 'coach', exercises: [{
      id: 'e1', order: 0, name: 'Juggling', description: null, instructions: null, durationMin: 10, reps: null, sets: 3, restSec: null,
      media: [{ id: 'm1', kind: 'link', path: null, url: 'https://example.com/video', name: 'Demo' }],
    }],
    ...o,
  });
  it('valid plan', () => {
    expect(validatePlan(plan() as never, 'p1')).toEqual([]);
  });
  it('https-only links', () => {
    expect(isHttpsLink('https://youtu.be/x')).toBe(true);
    for (const u of ['http://example.com', 'javascript:alert(1)', 'JAVASCRIPT:alert(1)', 'https://exa mple.com', 'ftp://x', 'data:text/html,x', ' https://x', 'https://']) {
      expect(isHttpsLink(u), u).toBe(false);
    }
    const withUrl = (url: string) => plan({ exercises: [{ id: 'e1', order: 0, name: 'x', media: [{ id: 'm', kind: 'link', url }] }] });
    expect(validatePlan(withUrl('javascript:alert(1)') as never, 'p1')).toContain('exercises[0].media[0].url');
    expect(validatePlan(withUrl('http://example.com') as never, 'p1')).toContain('exercises[0].media[0].url');
  });
  it('limits: ≤ 50 exercises, ≤ 10 media, 1–10 groups, field sizes, dates, enums', () => {
    const ex = (i: number) => ({ id: `e${i}`, order: i, name: 'x' });
    expect(validatePlan(plan({ exercises: Array.from({ length: 50 }, (_, i) => ex(i)) }) as never, 'p1')).toEqual([]);
    expect(validatePlan(plan({ exercises: Array.from({ length: 51 }, (_, i) => ex(i)) }) as never, 'p1')).toContain('exercises');
    const media = Array.from({ length: 11 }, (_, i) => ({ id: `m${i}`, kind: 'photo', path: `plans/p1/m${i}.jpg` }));
    expect(validatePlan(plan({ exercises: [{ ...ex(0), media }] }) as never, 'p1')).toContain('exercises[0].media');
    expect(validatePlan(plan({ groupIds: [] }) as never, 'p1')).toContain('groupIds');
    expect(validatePlan(plan({ groupIds: Array.from({ length: 11 }, (_, i) => `g${i}`) }) as never, 'p1')).toContain('groupIds');
    expect(validatePlan(plan({ groupIds: ['g1', 'g1'] }) as never, 'p1')).toContain('groupIds');
    expect(validatePlan(plan({ title: '' }) as never, 'p1')).toContain('title');
    expect(validatePlan(plan({ title: 'x'.repeat(121) }) as never, 'p1')).toContain('title');
    expect(validatePlan(plan({ description: 'x'.repeat(4001) }) as never, 'p1')).toContain('description');
    expect(validatePlan(plan({ type: 'daily' }) as never, 'p1')).toContain('type');
    expect(validatePlan(plan({ endDate: '2026-11-01' }) as never, 'p1')).toContain('endDate');
    expect(validatePlan(plan({ status: 'deleted' }) as never, 'p1')).toContain('status');
  });
  it('media paths must stay under plans/{planId}/', () => {
    const p = (path: string) => plan({ exercises: [{ id: 'e', order: 0, name: 'x', media: [{ id: 'm', kind: 'photo', path }] }] });
    expect(validatePlan(p('plans/p1/a.jpg') as never, 'p1')).toEqual([]);
    expect(validatePlan(p('plans/p2/a.jpg') as never, 'p1')).toContain('exercises[0].media[0].path');
    expect(validatePlan(p('plans/p1/../x') as never, 'p1')).toContain('exercises[0].media[0].path');
  });
  it('status transitions', () => {
    expect(planTransitionAllowed(undefined, 'draft')).toBe(true);
    expect(planTransitionAllowed(undefined, 'archived')).toBe(false);
    expect(planTransitionAllowed('draft', 'published')).toBe(true);
    expect(planTransitionAllowed('published', 'draft')).toBe(true);
    expect(planTransitionAllowed('published', 'archived')).toBe(true);
    expect(planTransitionAllowed('draft', 'archived')).toBe(false);
    expect(planTransitionAllowed('archived', 'published')).toBe(false);
  });
  it('readerIds only while published (and valid); coachIds always', () => {
    const groups = [{ coachIds: ['c1'], parentIds: ['p1', 'p2'] }, { coachIds: ['c2', 'c1'], parentIds: ['p2'] }];
    expect(computePlanReaderIds('published', groups)).toEqual(['c1', 'c2', 'p1', 'p2']);
    expect(computePlanReaderIds('draft', groups)).toEqual([]);
    expect(computePlanReaderIds('archived', groups)).toEqual([]);
    expect(computePlanReaderIds('published', groups, false)).toEqual([]);
    expect(computePlanCoachIds(groups)).toEqual(['c1', 'c2']);
  });
  it('publish / archive events', () => {
    expect(planEvents(undefined, { status: 'published' })).toEqual(['publish']);
    expect(planEvents({ status: 'draft' }, { status: 'published' })).toEqual(['publish']);
    expect(planEvents({ status: 'published' }, { status: 'published' })).toEqual([]);
    expect(planEvents({ status: 'published' }, { status: 'archived' })).toEqual(['archive']);
    expect(planEvents({ status: 'published' }, { status: 'draft' })).toEqual(['unpublish']);
  });
  it('upload limits', () => {
    expect(planUploadAllowed('image/jpeg', 10 * 1024 * 1024)).toBe(true);
    expect(planUploadAllowed('image/jpeg', 10 * 1024 * 1024 + 1)).toBe(false);
    expect(planUploadAllowed('video/mp4', 100 * 1024 * 1024)).toBe(true);
    expect(planUploadAllowed('application/pdf', 11 * 1024 * 1024)).toBe(false);
    expect(planUploadAllowed('text/html', 10)).toBe(false);
  });
  it('live plan access', () => {
    const groups = [{ id: 'g1', coachIds: ['c1'], parentIds: ['p1'] }];
    const draft = { createdBy: 'c0', status: 'draft', groupIds: ['g1'] };
    expect(canViewPlan({ uid: 'c1', role: 'coach', coachStatus: 'approved' }, draft, groups)).toBe(true);
    expect(canViewPlan({ uid: 'p1', role: 'parent' }, draft, groups)).toBe(false);
    expect(canViewPlan({ uid: 'p1', role: 'parent' }, { ...draft, status: 'published' }, groups)).toBe(true);
    expect(canViewPlan({ uid: 'p9', role: 'parent' }, { ...draft, status: 'published' }, groups)).toBe(false);
    expect(canViewPlan({ uid: 'c1', role: 'coach', coachStatus: 'suspended' }, draft, groups)).toBe(false);
  });
});
