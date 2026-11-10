// Pure helpers for the coach's child search (searchChildren callable).

export interface SearchableChild {
  id: string;
  firstName: string;
  lastName?: string;
  birthYear: number | null;
  status?: string;
}

export const SEARCH_MIN_CHARS = 2;
export const SEARCH_MAX_RESULTS = 20;

/** Trimmed query, or null when shorter than 2 characters / too long. */
export function normalizeQuery(q: unknown): string | null {
  if (typeof q !== 'string') return null;
  const t = q.trim().replace(/\s+/g, ' ');
  return Array.from(t).length >= SEARCH_MIN_CHARS && t.length <= 60 ? t : null;
}

/** Capitalised variant for prefix range queries (Latin names; Georgian has no case). */
export function prefixVariants(q: string): string[] {
  const first = q.split(' ')[0];
  const cap = first.charAt(0).toUpperCase() + first.slice(1).toLowerCase();
  return [...new Set([first, cap])];
}

/**
 * Filters + projects results: no pending children, no current members, every
 * query word must prefix-match first or last name (case-insensitive), max 20,
 * only {childId, firstName, lastName, birthYear} — never parent, contact or health fields.
 */
export function filterSearchResults(
  candidates: SearchableChild[],
  query: string,
  memberIds: string[],
): Array<{ childId: string; firstName: string; lastName: string; birthYear: number | null }> {
  const words = query.toLowerCase().split(' ').filter(Boolean);
  const members = new Set(memberIds);
  const seen = new Set<string>();
  const out: Array<{ childId: string; firstName: string; lastName: string; birthYear: number | null }> = [];
  for (const c of candidates) {
    if (seen.has(c.id) || members.has(c.id) || c.status === 'pendingParent') continue;
    const names = [c.firstName ?? '', c.lastName ?? ''].map((n) => n.toLowerCase());
    if (!words.every((w) => names.some((n) => n.startsWith(w)))) continue;
    seen.add(c.id);
    out.push({ childId: c.id, firstName: c.firstName, lastName: c.lastName ?? '', birthYear: c.birthYear });
    if (out.length >= SEARCH_MAX_RESULTS) break;
  }
  return out;
}
