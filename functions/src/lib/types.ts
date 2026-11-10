import type { Locale } from '../i18n';

// Plain domain types used by the pure business-logic modules.
// Timestamps are converted to JS Dates at the Firestore boundary so that the
// logic here is testable without Firebase.

export type Role = 'parent' | 'child' | 'coach' | 'admin';
export type CoachStatus = 'pending' | 'approved' | 'rejected' | 'suspended' | 'revoked';
export const COACH_STATUSES = ['pending', 'approved', 'rejected', 'suspended', 'revoked'] as const;

export const NOTIFICATION_TYPES = [
  'newTraining',
  'trainingChanged',
  'trainingReminder',
  'chatMessage',
  'certificateExpiry',
  'newPhotos',
  'paymentReminder',
  'paymentSms',
  // v1.3
  'paymentProofSubmitted',
  'paymentProofApproved',
  'paymentProofRejected',
  'trainingPlanPublished',
] as const;
export type NotificationType = (typeof NOTIFICATION_TYPES)[number];

export type NotificationPrefs = Partial<Record<NotificationType, boolean>>;

export interface UserLite {
  uid: string;
  role: Role;
  firstName?: string;
  lastName?: string;
  phone?: string;
  coachStatus?: CoachStatus;
  fcmTokens?: string[];
  notificationPrefs?: NotificationPrefs;
  smsConsentAt?: Date | null;
  /** users/{uid}.locale (normalized; missing/invalid → 'ka'). */
  locale?: Locale;
}

export interface GroupLite {
  id: string;
  clubId?: string;
  sportId?: string;
  name?: string;
  coachIds: string[];
  parentIds: string[];
  memberChildIds: string[];
}

export interface ChildLite {
  id: string;
  firstName: string;
  lastName?: string;
  parentIds: string[];
  photoConsent?: boolean;
  groupIds?: string[];
  status?: 'active' | 'pendingParent';
  createdByCoachId?: string | null;
}

export const TRAINING_FOCUS = ['technique', 'speed', 'physical', 'ball'] as const;
export type TrainingFocus = (typeof TRAINING_FOCUS)[number];
export type TrainingStatus = 'scheduled' | 'cancelled' | 'moved' | 'done';

export interface TrainingLite {
  groupId: string;
  venueId?: string;
  startAt: Date;
  durationMin?: number;
  status: TrainingStatus;
  photoUrls?: string[];
  reminderSentAt?: Date | null;
  cancelReasonCode?: string | null;
  cancelReason?: string | null;
  cancelledBy?: string | null;
  seriesId?: string | null;
  occurrenceDate?: string | null;
  detached?: boolean;
}

export type CertificateStatus = 'valid' | 'expiring' | 'expired';

export interface CertificateLite {
  id: string;
  childId: string;
  validUntil: Date;
  status?: CertificateStatus;
  notified14At?: Date | null;
  notified3At?: Date | null;
  notified0At?: Date | null;
  /** v1.3 */
  sportId?: string | null;
  groupId?: string | null;
  replacedBy?: string | null;
  createdAt?: Date | null;
  reminders?: { d14SentAt?: Date | null; d3SentAt?: Date | null; d0SentAt?: Date | null };
}

export type PaymentStatus = 'pending' | 'paid' | 'cancelled';

export interface PaymentLite {
  id: string;
  childId: string;
  parentId: string;
  groupId: string;
  sportId: string;
  amount: number;
  currency: 'GEL';
  dueDate: Date;
  status: PaymentStatus;
  createdAt?: Date | null;
  reminders?: { d5SentAt?: Date | null; d1SentAt?: Date | null };
}

/** Returns true when the user has not opted out of a notification type (default: on). */
export function prefEnabled(user: Pick<UserLite, 'notificationPrefs'>, type: NotificationType): boolean {
  return user.notificationPrefs?.[type] !== false;
}
