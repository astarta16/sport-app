// Pure data-export builder: what a user receives from requestDataExport.
// Medical certificates are exported as metadata only (never file contents or
// storage paths); FCM tokens and server bookkeeping are stripped.

type Doc = Record<string, unknown> & { id: string };

const STRIP_USER = ['fcmTokens'];
const STRIP_CERT = ['storagePath', 'notified14At', 'notified3At', 'notified0At'];

function omit(d: Doc, keys: string[]): Doc {
  const out: Doc = { id: d.id };
  for (const [k, v] of Object.entries(d)) if (!keys.includes(k)) out[k] = v;
  return out;
}

/** Converts Firestore Timestamps / Dates to ISO strings, recursively. */
export function toJsonSafe(v: unknown): unknown {
  if (v === null || v === undefined) return v ?? null;
  if (v instanceof Date) return v.toISOString();
  if (typeof v === 'object' && typeof (v as { toDate?: unknown }).toDate === 'function') {
    return (v as { toDate: () => Date }).toDate().toISOString();
  }
  if (Array.isArray(v)) return v.map(toJsonSafe);
  if (typeof v === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, x] of Object.entries(v as Record<string, unknown>)) out[k] = toJsonSafe(x);
    return out;
  }
  return v;
}

export interface ExportInput {
  uid: string;
  generatedAt: Date;
  user?: Doc;
  children: Doc[];
  certificates: Doc[];
  rsvps: Doc[];
  attendance: Doc[];
  feedback: Doc[];
  payments: Doc[];
  membershipRequests: Doc[];
  invites: Doc[];
  notifications: Doc[];
}

export function buildExport(input: ExportInput): Record<string, unknown> {
  const childIds = new Set(input.children.map((c) => c.id));
  const forChildren = (docs: Doc[]) => docs.filter((d) => childIds.has(String(d.childId ?? '')));
  return toJsonSafe({
    format: 'sport-parent-export/1',
    uid: input.uid,
    generatedAt: input.generatedAt,
    user: input.user ? omit(input.user, STRIP_USER) : null,
    children: input.children.map((c) => omit(c, ['coachIds'])),
    medicalCertificates: forChildren(input.certificates).map((c) => omit(c, STRIP_CERT)),
    rsvps: forChildren(input.rsvps),
    attendance: forChildren(input.attendance),
    feedback: forChildren(input.feedback),
    payments: input.payments.filter((p) => p.parentId === input.uid).map((p) => omit(p, ['reminders'])),
    membershipRequests: input.membershipRequests.filter((r) => r.parentId === input.uid),
    invites: input.invites.filter((i) => i.parentId === input.uid).map((i) => omit(i, ['phone'])),
    notifications: input.notifications.filter((n) => n.userId === input.uid),
  }) as Record<string, unknown>;
}
