import { describe, expect, it, vi } from 'vitest';
import { SMS_TEMPLATES_KA, formatAmount, renderPush, renderTemplate, truncate } from '../src/i18n/ka';
import { canAccessCertificate, canCoachSeeParentPhone, canDeleteCertificate, planAccountDeletion } from '../src/lib/access';
import { computeChildCoachIds, computeGroupParentIds, diffIds, sameSet } from '../src/lib/membership';
import { maskPhone, normalizeGeorgianPhone } from '../src/lib/phone';
import { MockSmsProvider, selectSmsProviderName, smsSegments } from '../src/lib/sms/provider';
import { GenericHttpSmsProvider, TwilioSmsProvider } from '../src/lib/sms/realProviders';
import { ChildLite, GroupLite, UserLite } from '../src/lib/types';

describe('templates', () => {
  it('renders placeholders and leaves unknown ones', () => {
    expect(renderTemplate('{a}-{b}-{c}', { a: 1, b: 'x' })).toBe('1-x-{c}');
  });
  it('push templates are Georgian', () => {
    expect(renderPush('trainingCancelled', { group: 'U12', date: '12.11', time: '18:00' })).toEqual({
      title: 'ვარჯიში გაუქმდა', body: 'U12: 12.11, 18:00',
    });
  });
  it('amount formatting and truncation', () => {
    expect(formatAmount(80)).toBe('80');
    expect(formatAmount(80.5)).toBe('80.50');
    expect(truncate('აბგდე', 3)).toBe('აბ…');
  });
  it('SMS templates are UCS-2 and the d5 frame leaves room for short names', () => {
    const frame = renderTemplate(SMS_TEMPLATES_KA.d5, { child: '', sport: '', amount: '', date: '' });
    expect(smsSegments(frame).encoding).toBe('UCS-2');
    expect(frame.length).toBeLessThanOrEqual(70);
  });
});

describe('sms provider selection (never real by default)', () => {
  it('mock unless SMS_SENDING_ENABLED=="true" and a provider is set', () => {
    expect(selectSmsProviderName({})).toBe('mock');
    expect(selectSmsProviderName({ SMS_PROVIDER: 'twilio' })).toBe('mock');
    expect(selectSmsProviderName({ SMS_PROVIDER: 'twilio', SMS_SENDING_ENABLED: 'false' })).toBe('mock');
    expect(selectSmsProviderName({ SMS_PROVIDER: 'twilio', SMS_SENDING_ENABLED: 'TRUE' })).toBe('mock');
    expect(selectSmsProviderName({ SMS_SENDING_ENABLED: 'true' })).toBe('mock');
    expect(selectSmsProviderName({ SMS_PROVIDER: 'twilio', SMS_SENDING_ENABLED: 'true' })).toBe('twilio');
    expect(selectSmsProviderName({ SMS_PROVIDER: 'http', SMS_SENDING_ENABLED: 'true' })).toBe('http');
  });

  it('mock records without sending', async () => {
    const m = new MockSmsProvider();
    const r = await m.send('+995599123456', 'x');
    expect(r.ok).toBe(true);
    expect(m.sent).toEqual([{ to: '+995599123456', text: 'x' }]);
  });

  it('segment counting', () => {
    expect(smsSegments('a'.repeat(160))).toMatchObject({ encoding: 'GSM-7', segments: 1 });
    expect(smsSegments('ა'.repeat(70))).toMatchObject({ encoding: 'UCS-2', segments: 1 });
    expect(smsSegments('ა'.repeat(71))).toMatchObject({ encoding: 'UCS-2', segments: 2 });
    expect(smsSegments('ა'.repeat(135))).toMatchObject({ segments: 3 });
  });

  it('twilio stub posts form data with basic auth (fake fetch)', async () => {
    const fetchImpl = vi.fn(async () => new Response(JSON.stringify({ sid: 'SM1', status: 'queued' }), { status: 201 }));
    const p = new TwilioSmsProvider('AC1', 'secret', '+15550000000', fetchImpl as unknown as typeof fetch);
    const r = await p.send('+995599123456', 'გამარჯობა');
    expect(r).toMatchObject({ ok: true, messageId: 'SM1' });
    const [url, init] = fetchImpl.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toContain('/Accounts/AC1/Messages.json');
    expect((init.headers as Record<string, string>).Authorization).toMatch(/^Basic /);
  });

  it('generic http stub posts JSON with bearer key (fake fetch)', async () => {
    const fetchImpl = vi.fn(async () => new Response('{"id":"m1"}', { status: 200 }));
    const p = new GenericHttpSmsProvider('https://sms.example/send', 'k', 'SPORT', fetchImpl as unknown as typeof fetch);
    expect(await p.send('+995599123456', 'x')).toMatchObject({ ok: true, messageId: 'm1' });
    expect(() => new GenericHttpSmsProvider('', 'k', 's')).toThrow();
  });
});

describe('phone', () => {
  it('masks phones', () => {
    expect(maskPhone('+995599123456')).toBe('+995*****3456');
    expect(maskPhone('599123456')).toBe('*****3456');
    expect(maskPhone(undefined)).toBe('');
  });
  it('normalizes Georgian mobiles', () => {
    expect(normalizeGeorgianPhone('599 12 34 56')).toBe('+995599123456');
    expect(normalizeGeorgianPhone('+995 599 123 456')).toBe('+995599123456');
    expect(normalizeGeorgianPhone('00995599123456')).toBe('+995599123456');
    expect(normalizeGeorgianPhone('12345')).toBeNull();
  });
});

describe('membership', () => {
  const children = new Map<string, ChildLite>([
    ['a', { id: 'a', firstName: 'A', parentIds: ['p2', 'p1'] }],
    ['b', { id: 'b', firstName: 'B', parentIds: ['p1'] }],
  ]);
  it('group parentIds = union of member children parents', () => {
    expect(computeGroupParentIds(['a', 'b', 'missing'], children)).toEqual(['p1', 'p2']);
    expect(computeGroupParentIds(['b'], children)).toEqual(['p1']);
  });
  it('diff / sameSet / coach union', () => {
    expect(diffIds(['a', 'b'], ['b', 'c'])).toEqual({ added: ['c'], removed: ['a'] });
    expect(sameSet(['a', 'b'], ['b', 'a'])).toBe(true);
    expect(sameSet(['a'], ['a', 'b'])).toBe(false);
    expect(computeChildCoachIds([{ coachIds: ['c2', 'c1'] }, { coachIds: ['c1'] }, {}])).toEqual(['c1', 'c2']);
  });
});

describe('access checks', () => {
  const parent: UserLite = { uid: 'p1', role: 'parent' };
  const coach: UserLite = { uid: 'c1', role: 'coach', coachStatus: 'approved' };
  const pendingCoach: UserLite = { uid: 'c1', role: 'coach', coachStatus: 'pending' };
  const kid: UserLite = { uid: 'k', role: 'child' };
  const child: ChildLite = { id: 'a', firstName: 'A', parentIds: ['p1'] };
  const g: GroupLite = { id: 'g1', coachIds: ['c1'], parentIds: ['p1'], memberChildIds: ['a'] };

  it('certificate access: parent or approved coach of a group containing the child', () => {
    expect(canAccessCertificate(parent, child, [])).toBe(true);
    expect(canAccessCertificate({ uid: 'p9', role: 'parent' }, child, [g])).toBe(false);
    expect(canAccessCertificate(coach, child, [g])).toBe(true);
    expect(canAccessCertificate(coach, child, [{ ...g, memberChildIds: [] }])).toBe(false);
    expect(canAccessCertificate(pendingCoach, child, [g])).toBe(false);
    expect(canAccessCertificate(kid, child, [g])).toBe(false);
  });
  it('certificate delete: parent only', () => {
    expect(canDeleteCertificate(parent, child)).toBe(true);
    expect(canDeleteCertificate(coach, child)).toBe(false);
  });
  it('parent phone visible only to approved coach sharing a group', () => {
    expect(canCoachSeeParentPhone(coach, 'p1', [g])).toBe(true);
    expect(canCoachSeeParentPhone(coach, 'p2', [g])).toBe(false);
    expect(canCoachSeeParentPhone(pendingCoach, 'p1', [g])).toBe(false);
    expect(canCoachSeeParentPhone(parent, 'p1', [g])).toBe(false);
  });
  it('account deletion: delete solely-owned children, unlink shared ones', () => {
    const plan = planAccountDeletion('p1', [
      { id: 'solo', firstName: 'S', parentIds: ['p1'] },
      { id: 'shared', firstName: 'X', parentIds: ['p1', 'p2'] },
      { id: 'other', firstName: 'O', parentIds: ['p2'] },
    ]);
    expect(plan).toEqual({ deleteChildIds: ['solo'], unlinkChildIds: ['shared'] });
  });
});
