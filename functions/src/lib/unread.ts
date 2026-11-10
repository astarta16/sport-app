// Pure unread-counter maths for userUnread/{uid} { total, byGroup }.

export interface UnreadState {
  total: number;
  byGroup: Record<string, number>;
}

export function normalizeUnread(raw: unknown): UnreadState {
  const byGroup: Record<string, number> = {};
  const src = (raw as { byGroup?: unknown })?.byGroup;
  if (src && typeof src === 'object') {
    for (const [k, v] of Object.entries(src as Record<string, unknown>)) {
      if (typeof v === 'number' && Number.isFinite(v) && v > 0) byGroup[k] = Math.floor(v);
    }
  }
  return { total: Object.values(byGroup).reduce((s, n) => s + n, 0), byGroup };
}

/** Clears one group's counter and recomputes the total. */
export function resetGroupUnread(raw: unknown, groupId: string): UnreadState {
  const s = normalizeUnread(raw);
  delete s.byGroup[groupId];
  return { byGroup: { ...s.byGroup, [groupId]: 0 }, total: Object.values(s.byGroup).reduce((a, n) => a + n, 0) };
}

/** Members whose counter a new message increments: everyone but the sender. */
export function unreadRecipients(memberUids: string[], senderId: string): string[] {
  return [...new Set(memberUids.filter((u) => u && u !== senderId))];
}
