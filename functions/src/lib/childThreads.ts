// v1.5 child-context parent↔coach conversations: one thread per (child,
// coach), id `${childId}_${coachId}`. Participants are the child's CURRENT
// guardians and that coach while they coach a group containing the child
// (children.coachIds, server-maintained). Other parents never see it.

export function threadId(childId: string, coachId: string): string {
  return `${childId}_${coachId}`;
}

export function threadParticipants(t: { coachId: string; childParentIds: string[] }): string[] {
  return [...new Set([t.coachId, ...t.childParentIds])];
}

export function canUseThread(
  user: { uid: string; role: string; coachStatus?: string } | undefined,
  thread: { coachId: string },
  child: { parentIds: string[]; coachIds: string[] },
): boolean {
  if (!user) return false;
  if (user.role === 'parent') return child.parentIds.includes(user.uid);
  if (user.role === 'coach') {
    return user.coachStatus === 'approved' && user.uid === thread.coachId && child.coachIds.includes(user.uid);
  }
  return false;
}
