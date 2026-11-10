// Firestore-backed sliding-window rate limiter (rateLimits/{uid}_{bucket}, server only).
import { HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from './admin';
import { RATE_LIMITS, RateBucket, decideRateLimit, rateLimitDocId } from './lib/rateLimit';

/** Consumes one hit or throws `resource-exhausted`. */
export async function consumeRateLimit(uid: string, bucket: RateBucket, now = Date.now()): Promise<void> {
  const { limit, windowMs } = RATE_LIMITS[bucket];
  const ref = db.doc(`rateLimits/${rateLimitDocId(uid, bucket)}`);
  const allowed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = decideRateLimit(snap.exists ? (snap.get('hits') as number[]) : [], now, limit, windowMs);
    if (d.allowed) tx.set(ref, { uid, bucket, hits: d.hits, updatedAt: FieldValue.serverTimestamp() });
    return d.allowed;
  });
  if (!allowed) throw new HttpsError('resource-exhausted', `rate limit exceeded (${bucket})`);
}
