// v1.8 entitlement logic — same cases as test/v18/platform_domain_test.dart.
import { describe, expect, it } from 'vitest';
import {
  accessMode, checkOrgModuleChange, derivedFields, expandLegacy, isModuleOn, isValidSet, missingDependencies,
  moduleOfNotification, prune, templateDiff,
} from '../src/lib/orgs';

const now = Date.UTC(2026, 10, 16, 12);
const day = 86400_000;
const base = {
  featureSchema: 2, status: 'active' as const,
  allowedModules: ['trainings', 'payments', 'paymentReceipts', 'paymentVerification', 'brainAcademy', 'leaderboards'],
  enabledModules: ['trainings', 'payments', 'paymentReceipts', 'paymentVerification', 'brainAcademy', 'leaderboards'],
};

describe('feature dependency graph', () => {
  it('reports missing dependencies, any-of groups and pruning', () => {
    expect(missingDependencies(['paymentVerification'])).toEqual({ paymentVerification: [['payments'], ['paymentReceipts']] });
    expect(isValidSet(['parentRsvp', 'matches'])).toBe(true);
    expect(isValidSet(['parentRsvp'])).toBe(false);
    expect(prune(['payments', 'paymentReceipts', 'paymentVerification']).sort()).toEqual(['paymentReceipts', 'paymentVerification', 'payments']);
    expect(prune(['paymentReceipts', 'paymentVerification', 'leaderboards'])).toEqual([]);
  });

  it('expands v1.7 coarse modules', () => {
    const e = expandLegacy(['payments', 'communication', 'attendance', 'trainings']);
    for (const m of ['paymentReceipts', 'paymentVerification', 'paymentReminders', 'messageAcks', 'parentRsvp', 'reports', 'dataExports']) {
      expect(e).toContain(m);
    }
  });
});

describe('effective entitlement', () => {
  it('active × provisioned × full access × allowed × enabled × rollout × dependencies', () => {
    expect(isModuleOn(base, 'paymentVerification', now)).toBe(true);
    expect(isModuleOn({ ...base, enabledModules: base.enabledModules.filter((m) => m !== 'payments') }, 'paymentReceipts', now)).toBe(false);
    expect(isModuleOn({ ...base, provisioning: 'provisioning' }, 'trainings', now)).toBe(false);
    expect(isModuleOn({ ...base, status: 'suspended' }, 'trainings', now)).toBe(false);
    expect(isModuleOn({ ...base, rollout: { leaderboards: { state: 'trial', untilMs: now - 1 } } }, 'leaderboards', now)).toBe(false);
    expect(isModuleOn({ ...base, rollout: { leaderboards: { state: 'trial', untilMs: now + day } } }, 'leaderboards', now)).toBe(true);
    expect(isModuleOn({ ...base, rollout: { payments: { state: 'scheduled', atMs: now + day } } }, 'paymentReceipts', now)).toBe(false);
    expect(isModuleOn({ ...base, rollout: { payments: { state: 'scheduled', atMs: now - day } } }, 'paymentReceipts', now)).toBe(true);
  });

  it('subscription access policy keeps data but goes read-only', () => {
    expect(accessMode({ subscription: { status: 'active', endAtMs: now - 3 * day, graceDays: 14 } }, now)).toBe('full');
    expect(accessMode({ subscription: { status: 'pastDue', endAtMs: now - 20 * day, graceDays: 14 } }, now)).toBe('readOnly');
    for (const s of ['suspended', 'cancelled', 'expired'] as const) expect(accessMode({ subscription: { status: s } }, now)).toBe('readOnly');
    expect(isModuleOn({ ...base, subscription: { status: 'suspended' } }, 'trainings', now)).toBe(false);
    expect(derivedFields({ ...base, subscription: { status: 'expired' } }, now)).toEqual({ effectiveModules: [], accessMode: 'readOnly', featureSchema: 2 });
  });

  it('organization admins cannot self-enable or create invalid sets', () => {
    expect(checkOrgModuleChange(base, ['trainings', 'media'], now)).toBe('moduleNotAllowed:media');
    expect(checkOrgModuleChange(base, ['paymentReceipts'], now)).toBe('featureDependencies');
    expect(checkOrgModuleChange(base, ['trainings', 'payments'], now)).toBeNull();
  });

  it('notifications follow their feature; template preview lists changes', () => {
    expect(moduleOfNotification('paymentReminder')).toBe('paymentReminders');
    expect(moduleOfNotification('paymentProofSubmitted')).toBe('paymentReceipts');
    expect(moduleOfNotification('chatMessage')).toBe('communication');
    const diff = templateDiff({ ...base, packageId: 'professional' }, { modules: ['trainings', 'media'], packageId: 'enterprise' });
    expect(diff).toContainEqual({ key: 'module:payments', from: 'true', to: 'false' });
    expect(diff).toContainEqual({ key: 'module:media', from: 'false', to: 'true' });
    expect(diff).toContainEqual({ key: 'package', from: 'professional', to: 'enterprise' });
  });
});
