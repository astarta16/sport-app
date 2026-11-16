import { describe, expect, it } from 'vitest';
import { t } from '../src/i18n';
import { canUseThread, threadId, threadParticipants } from '../src/lib/childThreads';
import { outcomeOf, resultChanged, validateResult } from '../src/lib/matchResults';
import { categoryFor } from '../src/lib/notifications';
import { receiptFileName } from '../src/lib/paymentProofs';

const now = new Date('2026-11-16T12:00:00Z');
const started = { status: 'scheduled', startAt: new Date('2026-11-16T09:00:00Z') };

describe('match results', () => {
  it('derives win / draw / loss from the coached team side', () => {
    expect(outcomeOf(3, 1)).toBe('win');
    expect(outcomeOf(2, 2)).toBe('draw');
    expect(outcomeOf(0, 1)).toBe('loss');
  });
  it('accepts whole scores 0–999, trims the summary, defaults completion to trusted now', () => {
    const v = validateResult({ ourScore: 3, opponentScore: 1, summary: '  Great passing  ' }, started, now);
    expect(v).toEqual({ ok: true, value: { ourScore: 3, opponentScore: 1, summary: 'Great passing', completedAt: now } });
  });
  it('rejects bad scores, future / pre-start completion, cancelled or not-yet-started matches', () => {
    for (const bad of [-1, 1.5, 1000, '3', null]) {
      expect(validateResult({ ourScore: bad, opponentScore: 0 }, started, now)).toEqual({ ok: false, error: 'score' });
    }
    expect(validateResult({ ourScore: 1, opponentScore: 0, completedAt: '2026-11-16T08:00:00Z' }, started, now)).toEqual({ ok: false, error: 'completedAt' });
    expect(validateResult({ ourScore: 1, opponentScore: 0, completedAt: '2026-11-17T08:00:00Z' }, started, now)).toEqual({ ok: false, error: 'completedAt' });
    expect(validateResult({ ourScore: 1, opponentScore: 0 }, { ...started, status: 'cancelled' }, now)).toEqual({ ok: false, error: 'cancelled' });
    expect(validateResult({ ourScore: 1, opponentScore: 0 }, { ...started, startAt: new Date('2026-11-17T09:00:00Z') }, now)).toEqual({ ok: false, error: 'notStarted' });
    expect(validateResult({ ourScore: 1, opponentScore: 0, summary: 'x'.repeat(1001) }, started, now)).toEqual({ ok: false, error: 'summary' });
  });
  it('a correction is only a change when score or summary differ', () => {
    const v = { ourScore: 3, opponentScore: 1, summary: null, completedAt: now };
    expect(resultChanged(undefined, v)).toBe(true);
    expect(resultChanged({ ourScore: 3, opponentScore: 1, summary: null }, v)).toBe(false);
    expect(resultChanged({ ourScore: 2, opponentScore: 1, summary: null }, v)).toBe(true);
  });
  it('result notifications are in the matches category, texts in every language', () => {
    expect(categoryFor('matchResult')).toBe('matches');
    for (const l of ['ka', 'en', 'ru']) {
      expect(t(l, 'push.matchResult.body', { opponent: 'Dinamo', our: 3, their: 1, date: '16 Nov' })).toMatch(/Dinamo.*3.*1/);
    }
  });
});

describe('child-context threads', () => {
  const child = { parentIds: ['p1', 'p2'], coachIds: ['c1'] };
  it('id and participants: the child guardians and that coach only', () => {
    expect(threadId('k1', 'c1')).toBe('k1_c1');
    expect(threadParticipants({ coachId: 'c1', childParentIds: ['p1', 'p2', 'p1'] })).toEqual(['c1', 'p1', 'p2']);
  });
  it('other parents, other coaches, pending coaches and children are refused', () => {
    expect(canUseThread({ uid: 'p1', role: 'parent' }, { coachId: 'c1' }, child)).toBe(true);
    expect(canUseThread({ uid: 'p2', role: 'parent' }, { coachId: 'c1' }, child)).toBe(true);
    expect(canUseThread({ uid: 'p9', role: 'parent' }, { coachId: 'c1' }, child)).toBe(false);
    expect(canUseThread({ uid: 'c1', role: 'coach', coachStatus: 'approved' }, { coachId: 'c1' }, child)).toBe(true);
    expect(canUseThread({ uid: 'c2', role: 'coach', coachStatus: 'approved' }, { coachId: 'c1' }, child)).toBe(false);
    expect(canUseThread({ uid: 'c1', role: 'coach', coachStatus: 'pending' }, { coachId: 'c1' }, child)).toBe(false);
    expect(canUseThread({ uid: 'c1', role: 'coach', coachStatus: 'approved' }, { coachId: 'c1' }, { ...child, coachIds: [] })).toBe(false);
    expect(canUseThread({ uid: 'k', role: 'child' }, { coachId: 'c1' }, child)).toBe(false);
  });
  it('childMessage is a chat notification', () => {
    expect(categoryFor('childMessage')).toBe('chat');
    expect(t('ru', 'push.childMessage.title', { child: 'Лука', sender: 'Нино' })).toBe('Лука · Нино');
  });
});

describe('receipt download file name', () => {
  it('is ASCII with the original extension', () => {
    expect(receiptFileName('proof-1', 'receipts/p/proof-1/ქვითარი.PDF')).toBe('receipt_proof-1.pdf');
    expect(receiptFileName('a/b', 'receipts/p/x/noext')).toBe('receipt_ab.bin');
  });
});
