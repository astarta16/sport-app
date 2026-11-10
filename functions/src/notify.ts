// notify(): persisted inbox (notifications/{sha1(userId|dedupeKey)}) + FCM push.
// The inbox doc is created only if absent; a duplicate event (same dedupeKey)
// is neither stored nor pushed again. Push respects notificationPrefs
// (the type is the preference key; invitations are always pushed).
import { logger } from 'firebase-functions';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from './admin';
import { Locale, normalizeLocale } from './i18n';
import { categoryFor, notificationId, pushAllowed } from './lib/notifications';
import { UserLite } from './lib/types';
import { sendPushToUsers } from './push';

export interface NotifyInput {
  type: string;
  /** Georgian fallback text (used when `localized` is absent). */
  title: string;
  body: string;
  /**
   * v1.3: per-recipient text in users/{uid}.locale (ka fallback). Spread
   * `...pushText(key, vars)` from ./i18n to get title/body/localized at once.
   */
  localized?: (locale: Locale) => { title: string; body: string };
  route: string;
  args?: Record<string, string>;
  childId?: string | null;
  groupId?: string | null;
  dedupeKey: string;
  /** Extra FCM data (strings). */
  data?: Record<string, string>;
  /** false = inbox only. */
  push?: boolean;
}

const ALREADY_EXISTS = 6;

export async function notify(users: UserLite[], n: NotifyInput): Promise<{ created: number; pushed: number }> {
  const category = categoryFor(n.type);
  const unique = [...new Map(users.filter((u) => u && u.role !== 'child').map((u) => [u.uid, u])).values()];
  const fresh: UserLite[] = [];
  const textFor = (u: UserLite) => (n.localized ? n.localized(normalizeLocale(u.locale)) : { title: n.title, body: n.body });
  for (const u of unique) {
    const id = notificationId(u.uid, n.dedupeKey);
    const text = textFor(u);
    try {
      await db.doc(`notifications/${id}`).create({
        userId: u.uid,
        type: n.type,
        category,
        title: text.title,
        body: text.body,
        route: n.route,
        args: n.args ?? {},
        childId: n.childId ?? null,
        groupId: n.groupId ?? null,
        createdAt: FieldValue.serverTimestamp(),
        read: false,
        dedupeKey: n.dedupeKey,
      });
      fresh.push(u);
    } catch (e) {
      if ((e as { code?: number }).code === ALREADY_EXISTS) continue;
      logger.warn('notification inbox write failed', { uid: u.uid, type: n.type, error: String(e) });
    }
  }
  let pushed = 0;
  if (n.push !== false) {
    const pushUsers = fresh.filter((u) => pushAllowed(u.notificationPrefs as Record<string, boolean> | undefined, n.type));
    // One FCM multicast per distinct rendered text (i.e. per locale).
    const byText = new Map<string, { text: { title: string; body: string }; users: UserLite[] }>();
    for (const u of pushUsers) {
      const text = textFor(u);
      const key = `${text.title}\u0000${text.body}`;
      const entry = byText.get(key) ?? { text, users: [] };
      entry.users.push(u);
      byText.set(key, entry);
    }
    for (const { text, users: group } of byText.values()) {
      pushed += await sendPushToUsers(group, {
        title: text.title,
        body: text.body,
        data: { type: n.type, category, route: n.route, ...(n.groupId ? { groupId: n.groupId } : {}), ...(n.data ?? {}) },
      });
    }
  }
  return { created: fresh.length, pushed };
}
