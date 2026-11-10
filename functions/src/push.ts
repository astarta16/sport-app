// FCM push sending with invalid-token cleanup.
import { logger } from 'firebase-functions';
import { FieldValue } from 'firebase-admin/firestore';
import { db, isEmulator, messaging } from './admin';
import { UserLite } from './lib/types';

export interface PushMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/**
 * Sends one push to every FCM token of the given users. Push delivery is
 * skipped (logged only) in the emulator or when PUSH_DISABLED=="true".
 * Returns the number of successfully delivered messages.
 */
export async function sendPushToUsers(users: UserLite[], msg: PushMessage): Promise<number> {
  const tokenOwner = new Map<string, string>();
  for (const u of users) for (const t of u.fcmTokens ?? []) if (t) tokenOwner.set(t, u.uid);
  const tokens = [...tokenOwner.keys()];
  if (tokens.length === 0) return 0;

  if (isEmulator || process.env.PUSH_DISABLED === 'true') {
    logger.info('push (not sent: emulator/disabled)', { title: msg.title, recipients: users.map((u) => u.uid), tokens: tokens.length });
    return 0;
  }

  let delivered = 0;
  const stale = new Map<string, string[]>();
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    const res = await messaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title: msg.title, body: msg.body },
      data: msg.data,
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    delivered += res.successCount;
    res.responses.forEach((r, idx) => {
      const code = r.error?.code;
      if (!r.success && code && INVALID_TOKEN_CODES.has(code)) {
        const t = chunk[idx];
        const owner = tokenOwner.get(t)!;
        stale.set(owner, [...(stale.get(owner) ?? []), t]);
      }
    });
  }

  await Promise.all(
    [...stale.entries()].map(([uid, ts]) =>
      db.doc(`users/${uid}`).update({ fcmTokens: FieldValue.arrayRemove(...ts) }).catch((e) =>
        logger.warn('failed to prune fcm tokens', { uid, error: String(e) }),
      ),
    ),
  );
  return delivered;
}
