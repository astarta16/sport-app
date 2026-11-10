// Pure invite logic: input validation and the respondInvite decision.
import { normalizeGeorgianPhone } from './phone';
import { ChildLite } from './types';

export type InviteStatus = 'sent' | 'accepted' | 'declined' | 'revoked';

export interface InviteLite {
  id: string;
  status: InviteStatus;
  parentId?: string | null;
  phone: string;
  groupId: string;
  childId?: string | null;
  createdBy: string;
}

/** E.164 phone: Georgian numbers normalised to +995…, other E.164 accepted as-is. */
export function normalizePhone(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  const ge = normalizeGeorgianPhone(v);
  if (ge) return ge;
  const t = v.replace(/[\s()-]/g, '');
  return /^\+[1-9]\d{7,14}$/.test(t) ? t : null;
}

export interface NewChildInput {
  firstName: string;
  lastName: string;
  birthDate: string; // YYYY-MM-DD
  parentPhone: string; // E.164
}

const NAME_MAX = 100;

export function validateNewChild(raw: unknown, today: string): { ok: true; value: NewChildInput } | { ok: false; error: string } {
  if (!raw || typeof raw !== 'object') return { ok: false, error: 'child' };
  const r = raw as Record<string, unknown>;
  const firstName = typeof r.firstName === 'string' ? r.firstName.trim() : '';
  const lastName = typeof r.lastName === 'string' ? r.lastName.trim() : '';
  if (!firstName || firstName.length > NAME_MAX) return { ok: false, error: 'firstName' };
  if (lastName.length > NAME_MAX) return { ok: false, error: 'lastName' };
  const birthDate = typeof r.birthDate === 'string' ? r.birthDate.slice(0, 10) : '';
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(birthDate);
  if (!m) return { ok: false, error: 'birthDate' };
  const d = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
  if (d.toISOString().slice(0, 10) !== birthDate || birthDate >= today || Number(m[1]) < 1990) return { ok: false, error: 'birthDate' };
  const parentPhone = normalizePhone(r.parentPhone);
  if (!parentPhone) return { ok: false, error: 'parentPhone' };
  return { ok: true, value: { firstName, lastName, birthDate, parentPhone } };
}

/** Only the addressed parent (by uid, or by the verified phone of their auth token). */
export function isInviteAddressee(invite: InviteLite, uid: string, verifiedPhone?: string | null): boolean {
  if (invite.parentId) return invite.parentId === uid;
  return !!verifiedPhone && normalizePhone(verifiedPhone) === invite.phone;
}

/** A coach-created child nobody has claimed yet. */
export function isUnclaimedPendingChild(c: ChildLite | undefined): boolean {
  return !!c && c.status === 'pendingParent' && !!c.createdByCoachId && c.parentIds.length === 0;
}

export type InviteResponsePlan =
  | { kind: 'decline'; deleteChildId: string | null }
  | { kind: 'link'; memberChildId: string; deleteChildId: string | null }
  | { kind: 'claim'; memberChildId: string }
  | { kind: 'join'; memberChildId: string }
  | { kind: 'error'; code: 'failed-precondition' | 'permission-denied' | 'not-found'; message: string };

/**
 * respondInvite decision (no automatic linking by name/phone — the parent decides):
 * - decline → unused coach-created pending child is deleted;
 * - accept + linkedChildId (must be one of the caller's children) → that child joins,
 *   the coach-created pending child is deleted;
 * - accept without linkedChildId → caller becomes parent of the pending child
 *   ("claim"), or — for an invite about an existing child the caller already
 *   parents — that child joins.
 */
export function planInviteResponse(input: {
  invite: InviteLite;
  uid: string;
  accept: boolean;
  inviteChild?: ChildLite;
  linkedChild?: ChildLite;
  linkedChildId?: string | null;
}): InviteResponsePlan {
  const { invite, uid, accept, inviteChild, linkedChild, linkedChildId } = input;
  if (invite.status !== 'sent') return { kind: 'error', code: 'failed-precondition', message: `invite is ${invite.status}` };
  const pendingToDelete = isUnclaimedPendingChild(inviteChild) ? inviteChild!.id : null;
  if (!accept) return { kind: 'decline', deleteChildId: pendingToDelete };

  if (linkedChildId) {
    if (!linkedChild) return { kind: 'error', code: 'not-found', message: 'linked child not found' };
    if (!linkedChild.parentIds.includes(uid)) return { kind: 'error', code: 'permission-denied', message: 'not your child' };
    if (linkedChild.status === 'pendingParent') return { kind: 'error', code: 'failed-precondition', message: 'linked child is pending' };
    return { kind: 'link', memberChildId: linkedChild.id, deleteChildId: pendingToDelete && pendingToDelete !== linkedChild.id ? pendingToDelete : null };
  }
  if (!inviteChild) return { kind: 'error', code: 'not-found', message: 'invite child not found' };
  if (isUnclaimedPendingChild(inviteChild)) return { kind: 'claim', memberChildId: inviteChild.id };
  if (inviteChild.parentIds.includes(uid)) return { kind: 'join', memberChildId: inviteChild.id };
  return { kind: 'error', code: 'permission-denied', message: 'not a parent of the invited child' };
}
