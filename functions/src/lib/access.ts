// Pure access checks used by callables (mirrors the security rules).

import { ChildLite, GroupLite, UserLite } from './types';

/**
 * Certificate file access: a parent of the child, or an approved coach of a
 * group that currently contains the child. Child accounts never.
 */
export function canAccessCertificate(
  user: UserLite | undefined,
  child: ChildLite | undefined,
  childGroups: GroupLite[],
): boolean {
  if (!user || !child) return false;
  if (user.role === 'parent') return child.parentIds.includes(user.uid);
  if (user.role === 'coach' && user.coachStatus === 'approved') {
    return childGroups.some((g) => g.memberChildIds.includes(child.id) && g.coachIds.includes(user.uid));
  }
  return false;
}

/** Only a parent of the child may delete a certificate. */
export function canDeleteCertificate(user: UserLite | undefined, child: ChildLite | undefined): boolean {
  return !!user && !!child && user.role === 'parent' && child.parentIds.includes(user.uid);
}

/**
 * A coach may see a parent's phone only if they are an approved coach of a
 * group whose parentIds contains that parent.
 */
export function canCoachSeeParentPhone(coach: UserLite | undefined, parentUid: string, groups: GroupLite[]): boolean {
  if (!coach || coach.role !== 'coach' || coach.coachStatus !== 'approved') return false;
  return groups.some((g) => g.coachIds.includes(coach.uid) && g.parentIds.includes(parentUid));
}

export interface AccountDeletionPlan {
  /** Children whose ONLY parent is the deleted user: delete with all certificates/files. */
  deleteChildIds: string[];
  /** Children shared with another parent: just remove the user from parentIds. */
  unlinkChildIds: string[];
}

export function planAccountDeletion(uid: string, children: ChildLite[]): AccountDeletionPlan {
  const plan: AccountDeletionPlan = { deleteChildIds: [], unlinkChildIds: [] };
  for (const c of children) {
    if (!c.parentIds.includes(uid)) continue;
    const others = c.parentIds.filter((p) => p !== uid);
    if (others.length === 0) plan.deleteChildIds.push(c.id);
    else plan.unlinkChildIds.push(c.id);
  }
  return plan;
}

export type CoachDecision = 'approved' | 'rejected';

export function isValidCoachDecision(v: unknown): v is CoachDecision {
  return v === 'approved' || v === 'rejected';
}
