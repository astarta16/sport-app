// Append-only auditLog writer (server only; rules deny all client writes).
import { FieldValue } from 'firebase-admin/firestore';
import { db } from './admin';

export type AuditAction =
  | 'coach.approve' | 'coach.reject' | 'coach.suspend' | 'coach.revoke' | 'role.set'
  | 'club.create' | 'club.update' | 'club.archive' | 'group.update' | 'sport.upsert'
  | 'payment.status' | 'moderation.decide' | 'certificate.access' | 'account.deleteRequest'
  | 'account.exportRequest'
  // v1.3
  | 'certificate.view' | 'certificate.download' | 'receipt.view'
  | 'payment.proofSubmitted' | 'payment.proofResubmitted' | 'payment.proofApproved' | 'payment.proofRejected'
  | 'plan.publish' | 'plan.archive' | 'group.paymentManagers'
  | 'chat.acknowledge' | 'media.download' | 'group.mediaPolicy'
  | 'receipt.download' | 'match.result' | 'match.resultCorrected'
  // v1.7 multi-tenant administration
  | 'org.create' | 'org.platform' | 'org.settings' | 'org.admin.assign' | 'org.admin.remove' | 'org.coach.add'
  | 'org.coach.remove' | 'program.upsert' | 'room.create' | 'room.update' | 'room.status' | 'booking.create'
  | 'booking.series' | 'booking.update' | 'booking.series.update' | 'booking.cancel'
  | 'leaderboard.consent' | 'leaderboard.revoke';

export interface AuditEntry {
  action: AuditAction;
  actorId: string;
  actorRole: string;
  actorName?: string;
  targetType: string;
  targetId: string;
  clubId?: string | null;
  details?: Record<string, unknown>;
}

export async function writeAudit(e: AuditEntry, tx?: FirebaseFirestore.Transaction | FirebaseFirestore.WriteBatch): Promise<void> {
  const ref = db.collection('auditLog').doc();
  const doc = {
    action: e.action,
    actorId: e.actorId,
    actorRole: e.actorRole,
    actorName: e.actorName ?? '',
    targetType: e.targetType,
    targetId: e.targetId,
    clubId: e.clubId ?? null,
    details: e.details ?? {},
    at: FieldValue.serverTimestamp(),
  };
  if (tx) (tx as FirebaseFirestore.WriteBatch).set(ref, doc);
  else await ref.set(doc);
}

/** actorRole label from claims: platform admin > club admin > users.role. */
export function actorRoleOf(token: Record<string, unknown> | undefined, userRole?: string): string {
  if (token?.admin === true) return 'platformAdmin';
  if (Array.isArray(token?.clubAdmin) && (token!.clubAdmin as unknown[]).length) return 'clubAdmin';
  return userRole ?? 'unknown';
}
