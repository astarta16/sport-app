// Firestore <-> plain domain type adapters.
import { DocumentData, Timestamp } from 'firebase-admin/firestore';
import { db } from './admin';
import { normalizeLocale } from './i18n';
import {
  CertificateLite, ChildLite, GroupLite, PaymentLite, TrainingLite, UserLite,
} from './lib/types';

export function toDate(v: unknown): Date | undefined {
  if (v instanceof Timestamp) return v.toDate();
  if (v instanceof Date) return v;
  if (v && typeof v === 'object' && typeof (v as { toDate?: unknown }).toDate === 'function') {
    return (v as { toDate: () => Date }).toDate();
  }
  return undefined;
}

const arr = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x) => typeof x === 'string') : []);

export function userFrom(uid: string, d: DocumentData): UserLite {
  return {
    uid,
    role: d.role,
    firstName: d.firstName,
    lastName: d.lastName,
    phone: d.phone,
    coachStatus: d.coachStatus,
    fcmTokens: arr(d.fcmTokens),
    notificationPrefs: d.notificationPrefs ?? {},
    smsConsentAt: toDate(d.smsConsentAt) ?? null,
    locale: normalizeLocale(d.locale),
  };
}

export function groupFrom(id: string, d: DocumentData): GroupLite {
  return {
    id,
    clubId: d.clubId,
    sportId: d.sportId,
    name: d.name,
    coachIds: arr(d.coachIds),
    parentIds: arr(d.parentIds),
    memberChildIds: arr(d.memberChildIds),
    status: d.status === 'archived' ? 'archived' : 'active',
    mediaDownloadsEnabled: d.mediaDownloadsEnabled !== false,
  };
}

export function childFrom(id: string, d: DocumentData): ChildLite {
  return {
    id,
    firstName: d.firstName ?? '',
    lastName: d.lastName,
    parentIds: arr(d.parentIds),
    photoConsent: d.photoConsent === true || d.mediaConsent === true,
    groupIds: arr(d.groupIds),
    status: d.status === 'pendingParent' ? 'pendingParent' : 'active',
    createdByCoachId: typeof d.createdByCoachId === 'string' ? d.createdByCoachId : null,
  };
}

export function trainingFrom(d: DocumentData): TrainingLite {
  return {
    groupId: d.groupId,
    venueId: d.venueId,
    startAt: toDate(d.startAt) ?? new Date(0),
    durationMin: d.durationMin,
    status: d.status,
    photoUrls: arr(d.photoUrls),
    reminderSentAt: toDate(d.reminderSentAt) ?? null,
    cancelReasonCode: d.cancelReasonCode ?? null,
    cancelReason: d.cancelReason ?? null,
    cancelledBy: d.cancelledBy ?? null,
    seriesId: d.seriesId ?? null,
    occurrenceDate: d.occurrenceDate ?? null,
    detached: d.detached === true,
  };
}

export function certificateFrom(id: string, d: DocumentData): CertificateLite {
  return {
    id,
    childId: d.childId,
    validUntil: toDate(d.validUntil) ?? new Date(0),
    status: d.status,
    notified14At: toDate(d.notified14At) ?? null,
    notified3At: toDate(d.notified3At) ?? null,
    notified0At: toDate(d.notified0At) ?? null,
    sportId: typeof d.sportId === 'string' && d.sportId ? d.sportId : null,
    groupId: typeof d.groupId === 'string' && d.groupId ? d.groupId : null,
    replacedBy: typeof d.replacedBy === 'string' && d.replacedBy ? d.replacedBy : null,
    createdAt: toDate(d.createdAt) ?? toDate(d.consentAt) ?? null,
    reminders: {
      d14SentAt: toDate(d.reminders?.d14SentAt) ?? null,
      d3SentAt: toDate(d.reminders?.d3SentAt) ?? null,
      d0SentAt: toDate(d.reminders?.d0SentAt) ?? null,
    },
  };
}

export function paymentFrom(id: string, d: DocumentData): PaymentLite {
  return {
    id,
    childId: d.childId,
    parentId: d.parentId,
    groupId: d.groupId,
    sportId: d.sportId,
    amount: Number(d.amount) || 0,
    currency: 'GEL',
    dueDate: toDate(d.dueDate) ?? new Date(0),
    status: d.status,
    createdAt: toDate(d.createdAt) ?? null,
    reminders: {
      d5SentAt: toDate(d.reminders?.d5SentAt) ?? null,
      d1SentAt: toDate(d.reminders?.d1SentAt) ?? null,
    },
  };
}

// ------------------------------------------------------------ loaders

export async function loadUsers(uids: string[]): Promise<Map<string, UserLite>> {
  const unique = [...new Set(uids.filter(Boolean))];
  const out = new Map<string, UserLite>();
  for (let i = 0; i < unique.length; i += 100) {
    const refs = unique.slice(i, i + 100).map((u) => db.doc(`users/${u}`));
    if (refs.length === 0) continue;
    const snaps = await db.getAll(...refs);
    for (const s of snaps) if (s.exists) out.set(s.id, userFrom(s.id, s.data()!));
  }
  return out;
}

export async function loadChildren(ids: string[]): Promise<Map<string, ChildLite>> {
  const unique = [...new Set(ids.filter(Boolean))];
  const out = new Map<string, ChildLite>();
  for (let i = 0; i < unique.length; i += 100) {
    const refs = unique.slice(i, i + 100).map((c) => db.doc(`children/${c}`));
    if (refs.length === 0) continue;
    const snaps = await db.getAll(...refs);
    for (const s of snaps) if (s.exists) out.set(s.id, childFrom(s.id, s.data()!));
  }
  return out;
}

export async function loadGroup(groupId: string): Promise<GroupLite | undefined> {
  if (!groupId) return undefined;
  const s = await db.doc(`groups/${groupId}`).get();
  return s.exists ? groupFrom(s.id, s.data()!) : undefined;
}

export async function loadUser(uid: string): Promise<UserLite | undefined> {
  const s = await db.doc(`users/${uid}`).get();
  return s.exists ? userFrom(s.id, s.data()!) : undefined;
}
