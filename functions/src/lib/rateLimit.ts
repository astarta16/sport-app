// Pure sliding-window rate limiter. State = timestamps (ms) of recent hits.

export interface RateLimitDecision {
  allowed: boolean;
  /** State to persist (only meaningful when allowed; otherwise the pruned state). */
  hits: number[];
  /** Milliseconds until the next hit would be allowed (0 when allowed). */
  retryAfterMs: number;
}

export function decideRateLimit(hits: number[] | undefined, nowMs: number, limit: number, windowMs: number): RateLimitDecision {
  const recent = (hits ?? []).filter((t) => typeof t === 'number' && t > nowMs - windowMs && t <= nowMs).sort((a, b) => a - b);
  if (limit <= 0) return { allowed: false, hits: recent, retryAfterMs: windowMs };
  if (recent.length >= limit) {
    const oldestRelevant = recent[recent.length - limit];
    return { allowed: false, hits: recent, retryAfterMs: Math.max(1, oldestRelevant + windowMs - nowMs) };
  }
  return { allowed: true, hits: [...recent, nowMs], retryAfterMs: 0 };
}

export const DAY_MS = 86_400_000;

/** Limits used by the callables (per user, rolling 24 h). */
export const RATE_LIMITS = {
  invites: { limit: 30, windowMs: DAY_MS },
  reports: { limit: 20, windowMs: DAY_MS },
  joinCode: { limit: 20, windowMs: DAY_MS },
  accountRequests: { limit: 5, windowMs: DAY_MS },
  childSearch: { limit: 200, windowMs: DAY_MS },
  createGroup: { limit: 20, windowMs: DAY_MS },
  paymentProofs: { limit: 10, windowMs: DAY_MS },
} as const;
export type RateBucket = keyof typeof RATE_LIMITS;

export function rateLimitDocId(uid: string, bucket: string): string {
  return `${uid}_${bucket}`;
}
