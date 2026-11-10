import { describe, expect, it } from 'vitest';
import { computeCertificateStatus, daysUntilExpiry, decideExpiryNotification } from '../src/lib/certificates';
import { CertificateLite } from '../src/lib/types';

const now = new Date('2026-11-10T05:00:00Z'); // 09:00 Tbilisi
const at = (iso: string) => new Date(iso);
const cert = (validUntil: string, extra: Partial<CertificateLite> = {}): CertificateLite => ({
  id: 'c1', childId: 'k1', validUntil: at(validUntil), ...extra,
});

describe('computeCertificateStatus', () => {
  it('valid / expiring (<=14 days) / expired', () => {
    expect(computeCertificateStatus(at('2026-12-31T20:00:00Z'), now)).toBe('valid');
    expect(computeCertificateStatus(at('2026-11-24T19:00:00Z'), now)).toBe('expiring'); // 14 days
    expect(computeCertificateStatus(at('2026-11-25T19:00:00Z'), now)).toBe('valid'); // 15 days
    expect(computeCertificateStatus(at('2026-11-10T04:00:00Z'), now)).toBe('expired');
  });

  it('days are Tbilisi calendar days', () => {
    expect(daysUntilExpiry(at('2026-11-10T19:59:00Z'), now)).toBe(0);
    expect(daysUntilExpiry(at('2026-11-10T20:00:00Z'), now)).toBe(1);
  });
});

describe('decideExpiryNotification', () => {
  it('fires the 14-day stage once', () => {
    const d = decideExpiryNotification(cert('2026-11-24T10:00:00Z'), now);
    expect(d.stage).toBe(14);
    expect(d.markFields).toEqual(['notified14At']);
    const again = decideExpiryNotification(cert('2026-11-24T10:00:00Z', { notified14At: now }), now);
    expect(again.stage).toBeNull();
  });

  it('fires the 3-day stage and supersedes an unsent 14-day stage', () => {
    const d = decideExpiryNotification(cert('2026-11-13T10:00:00Z'), now);
    expect(d.stage).toBe(3);
    expect(d.markFields).toEqual(['notified14At', 'notified3At']);
  });

  it('fires the expiry-day stage', () => {
    const d = decideExpiryNotification(cert('2026-11-10T15:00:00Z', { notified14At: now, notified3At: now }), now);
    expect(d.stage).toBe(0);
    expect(d.markFields).toEqual(['notified0At']);
    expect(d.status).toBe('expiring');
  });

  it('nothing outside 14 days; status is still computed', () => {
    const d = decideExpiryNotification(cert('2027-06-01T00:00:00Z', { status: 'expiring' }), now);
    expect(d.stage).toBeNull();
    expect(d.status).toBe('valid');
  });

  it('expired certificate notified once with stage 0', () => {
    const d = decideExpiryNotification(cert('2026-11-01T00:00:00Z'), now);
    expect(d.stage).toBe(0);
    expect(d.status).toBe('expired');
    expect(decideExpiryNotification(cert('2026-11-01T00:00:00Z', { notified0At: now }), now).stage).toBeNull();
  });
});
