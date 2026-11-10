// Pure admin-scope checks from custom claims.
// Platform admin = claim `admin: true`. Club admin = claim `clubAdmin: [clubId…]`.
import { CoachStatus } from './types';

export interface AdminScope {
  platform: boolean;
  clubIds: string[];
}

export function adminScopeFromClaims(token: Record<string, unknown> | undefined | null): AdminScope {
  const platform = token?.admin === true;
  const raw = token?.clubAdmin;
  const clubIds = Array.isArray(raw) ? [...new Set(raw.filter((x): x is string => typeof x === 'string' && x.length > 0))] : [];
  return { platform, clubIds };
}

export function isAnyAdmin(s: AdminScope): boolean {
  return s.platform || s.clubIds.length > 0;
}

export function canActOnClub(s: AdminScope, clubId: string | undefined | null): boolean {
  if (s.platform) return true;
  return !!clubId && s.clubIds.includes(clubId);
}

/** Club admin may act on a coach only when the coach is assigned to one of their clubs. */
export function canManageCoach(s: AdminScope, coachClubIds: string[]): boolean {
  if (s.platform) return true;
  return coachClubIds.some((c) => s.clubIds.includes(c));
}

export const SETTABLE_COACH_STATUSES = ['approved', 'rejected', 'suspended', 'revoked'] as const;
export type SettableCoachStatus = (typeof SETTABLE_COACH_STATUSES)[number];

export function isSettableCoachStatus(v: unknown): v is SettableCoachStatus {
  return typeof v === 'string' && (SETTABLE_COACH_STATUSES as readonly string[]).includes(v);
}

export function coachAuditAction(status: SettableCoachStatus): 'coach.approve' | 'coach.reject' | 'coach.suspend' | 'coach.revoke' {
  return ({ approved: 'coach.approve', rejected: 'coach.reject', suspended: 'coach.suspend', revoked: 'coach.revoke' } as const)[status];
}

export type AdminRole = 'platform' | 'club' | 'none';

/**
 * New custom claims for setAdminRole: keeps unrelated claims, sets/removes
 * `admin` and `clubAdmin`. Throws on invalid input.
 */
export function computeAdminClaims(
  existing: Record<string, unknown> | undefined,
  role: AdminRole,
  clubIds: string[],
): Record<string, unknown> {
  const out: Record<string, unknown> = { ...(existing ?? {}) };
  delete out.admin;
  delete out.clubAdmin;
  if (role === 'platform') out.admin = true;
  else if (role === 'club') {
    const ids = [...new Set(clubIds.filter((c) => typeof c === 'string' && c.length > 0))].sort();
    if (ids.length === 0) throw new Error('club admin needs at least one clubId');
    out.clubAdmin = ids;
  } else if (role !== 'none') throw new Error(`invalid role ${String(role)}`);
  return out;
}

/** True when the coach may act as a coach (rules: isApprovedCoach). */
export function isActiveCoachStatus(s: CoachStatus | undefined): boolean {
  return s === 'approved';
}
