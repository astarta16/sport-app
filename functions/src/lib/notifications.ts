// Pure notification-inbox helpers: deterministic ids and type -> category mapping.
// Names are the contract with the Flutter app (NotificationType enum and
// users/{uid}.notificationPrefs keys).
import { createHash } from 'node:crypto';

export const NOTIFICATION_CATEGORIES = [
  'trainings', 'matches', 'invitations', 'attendance', 'payments', 'chat', 'certificates', 'announcements',
] as const;
export type NotificationCategory = (typeof NOTIFICATION_CATEGORIES)[number];

export const CATEGORY_TYPES: Record<NotificationCategory, readonly string[]> = {
  trainings: ['newTraining', 'trainingChanged', 'trainingReminder', 'scheduleChanged', 'trainingPlanPublished'],
  matches: ['newMatch', 'matchChanged', 'matchReminder', 'matchResult'],
  invitations: ['groupInvite', 'inviteAnswered'],
  attendance: ['attendanceRecorded', 'feedbackAdded'],
  payments: ['paymentReminder', 'paymentSms', 'paymentProofSubmitted', 'paymentProofApproved', 'paymentProofRejected'],
  chat: ['chatMessage', 'childMessage'],
  certificates: ['certificateExpiry'],
  announcements: ['announcement', 'newPhotos', 'newMedia', 'ackRequested'],
};

export const INBOX_TYPES = Object.values(CATEGORY_TYPES).flat();
export type InboxType = string;

/** Category of a notification type; throws for unknown types (programming error). */
export function categoryFor(type: string): NotificationCategory {
  for (const c of NOTIFICATION_CATEGORIES) if (CATEGORY_TYPES[c].includes(type)) return c;
  throw new Error(`unknown notification type: ${type}`);
}

/** Inbox doc id = sha1(`userId|dedupeKey`) (hex) -> the same event can never be stored twice. */
export function notificationId(userId: string, dedupeKey: string): string {
  return createHash('sha1').update(`${userId}|${dedupeKey}`).digest('hex');
}

/**
 * Push preference: the notification type is the preference key (missing = on).
 * Invitations are always pushed (they need an answer).
 */
export function pushAllowed(prefs: Record<string, boolean> | undefined, type: string): boolean {
  if (categoryFor(type) === 'invitations') return true;
  return prefs?.[type] !== false;
}
