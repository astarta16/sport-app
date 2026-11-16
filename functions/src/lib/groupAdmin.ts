// v1.9.1: organization administrators manage their own organization's
// groups. Pure decision helpers (unit-tested) used by the callables.

export interface CoachDoc { role?: string; coachStatus?: string; clubIds?: string[] }

/** Coaches assigned to a group must be approved coaches of that club. */
export function validGroupCoaches(clubId: string, coaches: Array<CoachDoc | undefined>): boolean {
  return coaches.length > 0 && coaches.every(
    (c) => !!c && c.role === 'coach' && c.coachStatus === 'approved' && (c.clubIds ?? []).includes(clubId),
  );
}

/** Optional group capacity: null (no limit) or an integer 1..500. */
export function parseCapacity(v: unknown): number | null | 'invalid' {
  if (v === undefined || v === null || v === '') return null;
  const n = Number(v);
  return Number.isInteger(n) && n >= 1 && n <= 500 ? n : 'invalid';
}

/** Whether one more child fits (capacity null = unlimited). */
export function hasRoom(capacity: unknown, members: unknown[], childId: string): boolean {
  if (members.includes(childId)) return true;
  const cap = parseCapacity(capacity);
  return cap === null || cap === 'invalid' || members.length < cap;
}

/** Package / organization limit on active groups. */
export function withinGroupLimit(activeGroups: number, maxGroups: number | undefined): boolean {
  return maxGroups === undefined || activeGroups < maxGroups;
}
