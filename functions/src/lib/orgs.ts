// Tenant configuration and entitlements — pure mirror of
// lib/features/organizations/domain/organization.dart + platform.dart
// (v1.7 model, extended in v1.8). Keep ids and rules identical.

export const MODULES = [
  'trainings', 'matches', 'attendance', 'communication', 'studentAccounts', 'brainAcademy', 'trainingPlans',
  'payments', 'medicalCertificates', 'media', 'leaderboards', 'roomScheduling', 'notifications',
  // v1.8
  'parentRsvp', 'messageAcks', 'coachChallenges', 'paymentReceipts', 'paymentVerification', 'paymentReminders',
  'facilities', 'reports', 'dataExports',
] as const;
export type Module = (typeof MODULES)[number];
export type Plan = 'free' | 'standard' | 'premium';
export type OrgStatus = 'active' | 'suspended' | 'deactivated';

/** Any-of dependency groups: every group needs one enabled member. */
export const REQUIRES: Partial<Record<Module, Module[][]>> = {
  attendance: [['trainings', 'matches']],
  parentRsvp: [['trainings', 'matches']],
  messageAcks: [['communication']],
  coachChallenges: [['brainAcademy']],
  leaderboards: [['brainAcademy']],
  paymentReceipts: [['payments']],
  paymentVerification: [['payments'], ['paymentReceipts']],
  paymentReminders: [['payments']],
  roomScheduling: [['facilities']],
};

export const RESTRICTED: Module[] = ['leaderboards', 'roomScheduling', 'facilities', 'studentAccounts'];

const FREE: Module[] = ['trainings', 'matches', 'attendance', 'parentRsvp', 'communication', 'messageAcks', 'notifications', 'reports'];
const STANDARD: Module[] = [
  ...FREE, 'studentAccounts', 'brainAcademy', 'coachChallenges', 'trainingPlans', 'payments', 'paymentReceipts',
  'paymentVerification', 'paymentReminders', 'medicalCertificates', 'media', 'dataExports',
];

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

export type Rollout = { state: 'enabled' | 'disabled' | 'trial' | 'scheduled'; untilMs?: number | null; atMs?: number | null };
export type SubStatus = 'trial' | 'active' | 'pastDue' | 'suspended' | 'cancelled' | 'expired';

export interface OrgConfigDoc {
  status?: OrgStatus; plan?: Plan; allowedModules?: string[]; enabledModules?: string[];
  timezone?: string; bookingBufferMin?: number; featureSchema?: number; provisioning?: 'ready' | 'provisioning' | 'failed';
  packageId?: string; version?: number;
  subscription?: { status?: SubStatus; endAtMs?: number | null; graceDays?: number };
  rollout?: Record<string, Rollout>;
  limits?: { maxStudents?: number; maxCoaches?: number; maxRooms?: number; maxGroups?: number };
  leaderboard?: { enabled?: boolean; games?: string[]; periods?: string[]; byAgeBand?: boolean; minParticipants?: number };
  settings?: { coachesCanBookRooms?: boolean; coachesCanExport?: boolean };
}

/** v1.7 documents used coarse modules; add the finer features they implied. */
export function expandLegacy(mods: string[]): Module[] {
  const s = new Set(mods.filter((m): m is Module => (MODULES as readonly string[]).includes(m)));
  if (s.has('payments')) ['paymentReceipts', 'paymentVerification', 'paymentReminders'].forEach((m) => s.add(m as Module));
  if (s.has('brainAcademy')) s.add('coachChallenges');
  if (s.has('communication')) s.add('messageAcks');
  if (s.has('attendance')) s.add('parentRsvp');
  if (s.has('roomScheduling')) s.add('facilities');
  if (s.has('trainings') || s.has('attendance')) { s.add('reports'); s.add('dataExports'); }
  return [...s];
}

export function missingDependencies(enabled: Iterable<string>): Record<string, Module[][]> {
  const set = new Set(enabled);
  const out: Record<string, Module[][]> = {};
  for (const m of set) {
    const miss = (REQUIRES[m as Module] ?? []).filter((g) => !g.some((d) => set.has(d)));
    if (miss.length) out[m] = miss;
  }
  return out;
}

export function isValidSet(enabled: Iterable<string>): boolean {
  return Object.keys(missingDependencies(enabled)).length === 0;
}

/** Largest valid subset (drops features whose dependencies are gone). */
export function prune(enabled: Iterable<string>): Module[] {
  let s = new Set(enabled as Iterable<Module>);
  for (;;) {
    const miss = Object.keys(missingDependencies(s));
    if (!miss.length) return [...s];
    s = new Set([...s].filter((m) => !miss.includes(m)));
  }
}

/** Legacy clubs (no config document): the pre-v1.7 feature set. */
export function effectiveConfig(doc: OrgConfigDoc | undefined | null): Required<Pick<OrgConfigDoc, 'status' | 'allowedModules' | 'enabledModules'>> & OrgConfigDoc {
  if (!doc) return { status: 'active', plan: 'standard', allowedModules: [...STANDARD], enabledModules: [...STANDARD] };
  const plan = doc.plan ?? 'standard';
  const legacy = (doc.featureSchema ?? 1) < 2;
  const allowed = doc.allowedModules ?? planModules(plan);
  const enabled = doc.enabledModules ?? planModules(plan).filter((m) => !RESTRICTED.includes(m));
  return {
    ...doc,
    status: doc.status ?? 'active',
    allowedModules: legacy ? expandLegacy(allowed) : allowed,
    enabledModules: legacy ? expandLegacy(enabled) : enabled,
  };
}

/** Subscription access policy (mirror of SubscriptionInfo.accessAt). */
export function accessMode(doc: OrgConfigDoc | undefined | null, nowMs = Date.now()): 'full' | 'readOnly' {
  const sub = doc?.subscription;
  const status = sub?.status ?? 'active';
  if (status === 'suspended' || status === 'cancelled' || status === 'expired') return 'readOnly';
  const end = sub?.endAtMs;
  if (end == null) return 'full';
  return nowMs < end + (sub?.graceDays ?? 14) * 86400_000 ? 'full' : 'readOnly';
}

function rolloutAllows(r: Rollout | undefined, nowMs: number): boolean {
  if (!r) return true;
  if (r.state === 'enabled') return true;
  if (r.state === 'disabled') return false;
  if (r.state === 'trial') return r.untilMs == null || nowMs < r.untilMs;
  return r.atMs != null && nowMs >= r.atMs;
}

/** The single feature-flag rule (same as Dart OrgConfig.isEnabled). */
export function isModuleOn(doc: OrgConfigDoc | undefined | null, m: Module, nowMs = Date.now(), seen = new Set<string>()): boolean {
  const c = effectiveConfig(doc);
  if (c.status !== 'active' || (c.provisioning ?? 'ready') !== 'ready' || accessMode(c, nowMs) !== 'full') return false;
  if (!c.allowedModules.includes(m) || !c.enabledModules.includes(m)) return false;
  if (!rolloutAllows(c.rollout?.[m], nowMs)) return false;
  if (seen.has(m)) return true;
  seen.add(m);
  return (REQUIRES[m] ?? []).every((g) => g.some((d) => isModuleOn(doc, d, nowMs, seen)));
}

/** Derived fields the rules read (written with every config change). */
export function derivedFields(doc: OrgConfigDoc, nowMs = Date.now()) {
  return {
    effectiveModules: MODULES.filter((m) => isModuleOn(doc, m, nowMs)),
    accessMode: accessMode(doc, nowMs),
    featureSchema: 2,
  };
}

export function sanitizeModules(v: unknown): Module[] {
  if (!Array.isArray(v)) throw new Error('modules must be a list');
  const out = [...new Set(v.filter((x): x is Module => typeof x === 'string' && (MODULES as readonly string[]).includes(x)))];
  if (out.length !== new Set(v).size) throw new Error('unknown module');
  return out;
}

/**
 * Organization-admin edit of enabled modules: must be a subset of what
 * the platform allows (no self-enabling of premium/restricted modules)
 * and a valid dependency set.
 */
export function checkOrgModuleChange(doc: OrgConfigDoc | undefined | null, enabled: Module[], nowMs = Date.now()): string | null {
  const c = effectiveConfig(doc);
  if (c.status !== 'active' || accessMode(c, nowMs) !== 'full') return 'orgInactive';
  const notAllowed = enabled.filter((m) => !c.allowedModules.includes(m));
  if (notAllowed.length) return `moduleNotAllowed:${notAllowed.join(',')}`;
  return isValidSet(enabled) ? null : 'featureDependencies';
}

// ── packages & templates (defaults; the platform may edit the documents) ──

export interface PackageDoc {
  modules: Module[]; custom?: boolean; durationDays?: number; archived?: boolean;
  limits: { maxCoaches: number; maxStudents: number; maxGroups: number; maxRooms: number; storageMb?: number; notificationsPerMonth?: number; smsPerMonth?: number };
}

export const BUILTIN_PACKAGES: Record<string, PackageDoc> = {
  starter: { modules: planModules('free'), limits: { maxCoaches: 5, maxStudents: 50, maxGroups: 5, maxRooms: 1, storageMb: 512 } },
  professional: { modules: [...planModules('standard'), 'facilities', 'roomScheduling'], limits: { maxCoaches: 30, maxStudents: 300, maxGroups: 40, maxRooms: 5, storageMb: 10240 } },
  enterprise: { modules: [...MODULES], limits: { maxCoaches: 200, maxStudents: 2000, maxGroups: 300, maxRooms: 30, storageMb: 102400, smsPerMonth: 2000 } },
  custom: { modules: [...MODULES], custom: true, limits: { maxCoaches: 50, maxStudents: 500, maxGroups: 60, maxRooms: 10 } },
};

export function packageIncludes(p: PackageDoc, m: Module): boolean {
  return p.custom === true || p.modules.includes(m);
}

/** Feature a notification type belongs to (mirror of moduleOfNotification). */
export function moduleOfNotification(type: string): Module {
  switch (type) {
    case 'newTraining': case 'trainingChanged': case 'trainingReminder': case 'scheduleChanged': return 'trainings';
    case 'newMatch': case 'matchChanged': case 'matchReminder': case 'matchResult': return 'matches';
    case 'chatMessage': case 'announcement': return 'communication';
    case 'certificateExpiry': return 'medicalCertificates';
    case 'newPhotos': case 'newMedia': return 'media';
    case 'paymentReminder': case 'paymentSms': return 'paymentReminders';
    case 'paymentProofSubmitted': case 'paymentProofApproved': case 'paymentProofRejected': return 'paymentReceipts';
    case 'trainingPlanPublished': return 'trainingPlans';
    case 'attendanceRecorded': case 'feedbackAdded': return 'attendance';
    default: return 'notifications';
  }
}

/** Template diff (mirror of TemplateDiff.compute) for previews. */
export function templateDiff(cfg: OrgConfigDoc, t: { modules: string[]; packageId: string }): Array<{ key: string; from: string; to: string }> {
  const c = effectiveConfig(cfg);
  const out: Array<{ key: string; from: string; to: string }> = [];
  for (const m of MODULES) {
    const now = c.enabledModules.includes(m), next = t.modules.includes(m);
    if (now !== next) out.push({ key: `module:${m}`, from: `${now}`, to: `${next}` });
  }
  if ((cfg.packageId ?? 'professional') !== t.packageId) out.push({ key: 'package', from: cfg.packageId ?? 'professional', to: t.packageId });
  return out;
}
