// Pure group-membership helpers used by the onGroupWritten trigger.

import { ChildLite } from './types';

/** Sorted, de-duplicated parentIds of all member children. */
export function computeGroupParentIds(memberChildIds: string[], children: Map<string, ChildLite>): string[] {
  const out = new Set<string>();
  for (const id of memberChildIds) {
    children.get(id)?.parentIds.forEach((p) => out.add(p));
  }
  return [...out].sort();
}

export interface ListDiff {
  added: string[];
  removed: string[];
}

export function diffIds(before: string[] = [], after: string[] = []): ListDiff {
  const b = new Set(before);
  const a = new Set(after);
  return {
    added: [...a].filter((x) => !b.has(x)),
    removed: [...b].filter((x) => !a.has(x)),
  };
}

export function sameSet(a: string[] = [], b: string[] = []): boolean {
  const sa = new Set(a);
  const sb = new Set(b);
  if (sa.size !== sb.size) return false;
  for (const x of sa) if (!sb.has(x)) return false;
  return true;
}

/** Union of coachIds of all groups a child belongs to (denormalized onto children/{id}.coachIds). */
export function computeChildCoachIds(groups: Array<{ coachIds?: string[] }>): string[] {
  return [...new Set(groups.flatMap((g) => g.coachIds ?? []))].sort();
}
