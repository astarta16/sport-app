// v1.7 tenant configuration — pure mirror of
// lib/features/organizations/domain/organization.dart.

export const MODULES = [
  'trainings', 'matches', 'attendance', 'communication', 'studentAccounts', 'brainAcademy', 'trainingPlans',
  'payments', 'medicalCertificates', 'media', 'leaderboards', 'roomScheduling', 'notifications',
] as const;
export type Module = (typeof MODULES)[number];
export type Plan = 'free' | 'standard' | 'premium';
export type OrgStatus = 'active' | 'suspended' | 'deactivated';

export const RESTRICTED: Module[] = ['leaderboards', 'roomScheduling', 'studentAccounts'];

const FREE: Module[] = ['trainings', 'matches', 'attendance', 'communication', 'notifications'];
const STANDARD: Module[] = [...FREE, 'studentAccounts', 'brainAcademy', 'trainingPlans', 'payments', 'medicalCertificates', 'media'];

export function planModules(p: Plan): Module[] {
  return p === 'free' ? [...FREE] : p === 'standard' ? [...STANDARD] : [...MODULES];
}

export function planLimits(p: Plan) {
  return p === 'free'
    ? { maxStudents: 50, maxCoaches: 5, maxRooms: 1, maxGroups: 5 }
    : p === 'standard'
      ? { maxStudents: 300, maxCoaches: 30, maxRooms: 5, maxGroups: 40 }
      : { maxStudents: 2000, maxCoaches: 200, maxRooms: 30, maxGroups: 300 };
}

export interface OrgConfigDoc {
  status?: OrgStatus; plan?: Plan; allowedModules?: string[]; enabledModules?: string[];
  timezone?: string; bookingBufferMin?: number;
  limits?: { maxStudents?: number; maxCoaches?: number; maxRooms?: number; maxGroups?: number };
  leaderboard?: { enabled?: boolean; games?: string[]; periods?: string[]; byAgeBand?: boolean; minParticipants?: number };
}

/** Legacy clubs (no config document): the pre-v1.7 feature set. */
export function effectiveConfig(doc: OrgConfigDoc | undefined | null): Required<Pick<OrgConfigDoc, 'status' | 'allowedModules' | 'enabledModules'>> & OrgConfigDoc {
  if (!doc) return { status: 'active', plan: 'standard', allowedModules: [...STANDARD], enabledModules: [...STANDARD] };
  const plan = doc.plan ?? 'standard';
  return {
    ...doc,
    status: doc.status ?? 'active',
    allowedModules: doc.allowedModules ?? planModules(plan),
    enabledModules: doc.enabledModules ?? planModules(plan).filter((m) => !RESTRICTED.includes(m)),
  };
}

/** The single feature-flag rule (same as Dart OrgConfig.isEnabled and the moduleOn() rule). */
export function isModuleOn(doc: OrgConfigDoc | undefined | null, m: Module): boolean {
  const c = effectiveConfig(doc);
  return c.status === 'active' && c.allowedModules.includes(m) && c.enabledModules.includes(m);
}

export function sanitizeModules(v: unknown): Module[] {
  if (!Array.isArray(v)) throw new Error('modules must be a list');
  const out = [...new Set(v.filter((x): x is Module => typeof x === 'string' && (MODULES as readonly string[]).includes(x)))];
  if (out.length !== new Set(v).size) throw new Error('unknown module');
  return out;
}

/**
 * Organization-admin edit of enabled modules: must be a subset of what
 * the platform allows (no self-enabling of premium/restricted modules).
 */
export function checkOrgModuleChange(doc: OrgConfigDoc | undefined | null, enabled: Module[]): string | null {
  const c = effectiveConfig(doc);
  if (c.status !== 'active') return 'orgInactive';
  const notAllowed = enabled.filter((m) => !c.allowedModules.includes(m));
  return notAllowed.length ? `moduleNotAllowed:${notAllowed.join(',')}` : null;
}
