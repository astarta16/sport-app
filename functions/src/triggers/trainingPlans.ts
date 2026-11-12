// v1.3 training plans: server-managed readerIds / coachIds, publish
// notification, audit, media URLs.
import { planActor } from '../lib/progressNotices';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { bucket, db } from '../admin';
import { writeAudit } from '../audit';
import { groupFrom, loadUser, loadUsers } from '../convert';
import { pushText } from '../i18n';
import { truncate } from '../i18n/ka';
import { groupParentUsers } from '../lib/recipients';
import { sameSet } from '../lib/membership';
import {
  PlanDoc, canViewPlan, computePlanCoachIds, computePlanReaderIds, planEvents, validatePlan,
} from '../lib/trainingPlans';
import { GroupLite } from '../lib/types';
import { notify } from '../notify';
import { signedOrEmulatorUrl } from './media';

const PLAN_MEDIA_URL_TTL_MS = 15 * 60 * 1000;

async function loadGroups(ids: unknown): Promise<GroupLite[]> {
  const list = Array.isArray(ids) ? ids : [];
  const unique = [...new Set(list.filter((x): x is string => typeof x === 'string' && !!x && !x.includes('/')))];
  if (!unique.length) return [];
  const snaps = await db.getAll(...unique.map((id) => db.doc(`groups/${id}`)));
  return snaps.filter((s) => s.exists).map((s) => groupFrom(s.id, s.data()!));
}

/**
 * Recomputes trainingPlans/{planId}.readerIds (parents + coaches of groupIds
 * while published and valid, else []) and .coachIds (coaches of groupIds,
 * always). Both are server-managed; rules and Storage read access use them.
 *
 * Quarantine: the rules cannot validate 50 exercises × 10 media within their
 * expression budget, so this is the authoritative validator. An invalid plan
 * (e.g. a non-https link) gets readerIds [] and validationErrors; if it was
 * published it is forced back to 'draft'.
 */
export async function refreshPlanAccess(planId: string): Promise<{ readerIds: string[]; coachIds: string[]; valid: boolean; quarantined: boolean } | null> {
  const ref = db.doc(`trainingPlans/${planId}`);
  const snap = await ref.get();
  if (!snap.exists) return null;
  const d = snap.data()!;
  const groups = await loadGroups(d.groupIds);
  const errors = validatePlan(d as PlanDoc, planId);
  const valid = errors.length === 0;
  const readerIds = computePlanReaderIds(String(d.status), groups, valid);
  const coachIds = computePlanCoachIds(groups);
  const patch: Record<string, unknown> = {};
  if (!Array.isArray(d.readerIds) || !sameSet(d.readerIds, readerIds)) patch.readerIds = readerIds;
  if (!Array.isArray(d.coachIds) || !sameSet(d.coachIds, coachIds)) patch.coachIds = coachIds;
  let quarantined = false;
  if (!valid) {
    const list = errors.slice(0, 20);
    if (JSON.stringify(d.validationErrors ?? null) !== JSON.stringify(list)) patch.validationErrors = list;
    if (d.status === 'published') {
      patch.status = 'draft';
      quarantined = true;
    }
    logger.warn('invalid training plan quarantined', { planId, errors: list });
  } else if (d.validationErrors !== undefined) {
    patch.validationErrors = FieldValue.delete();
  }
  if (Object.keys(patch).length) await ref.update(patch);
  return { readerIds, coachIds, valid, quarantined };
}

/** Membership/coach change of a group: refresh every plan that lists it. */
export async function refreshPlansForGroup(groupId: string): Promise<number> {
  const plans = await db.collection('trainingPlans').where('groupIds', 'array-contains', groupId).select().get();
  for (const p of plans.docs) await refreshPlanAccess(p.id);
  return plans.size;
}

/**
 * trainingPlans/{planId} written: validate (quarantine invalid plans, see
 * refreshPlanAccess), maintain readerIds/coachIds; on the first
 * publish notify the groups' parents once (trainingPlanPublished, dedupe
 * plan:{id}:published) and set publishedAt if missing; audit plan.publish /
 * plan.archive (actor = updatedBy, which the rules pin to the writer; plans
 * written before v1.3.1 fall back to the creator); on delete remove plans/{planId}/.
 */
export const onTrainingPlanWritten = onDocumentWritten('trainingPlans/{planId}', async (event) => {
  const planId = event.params.planId;
  const before = event.data?.before.exists ? event.data.before.data()! : undefined;
  const after = event.data?.after.exists ? event.data.after.data()! : undefined;
  if (!after) {
    await bucket().deleteFiles({ prefix: `plans/${planId}/` }).catch((e) => logger.warn('plan media delete failed', { planId, error: String(e) }));
    return;
  }
  const access = await refreshPlanAccess(planId);
  if (!access || !access.valid) return; // quarantined: no publish audit / notification
  const events = planEvents(before, after);
  if (!events.length) return;
  const clubId = typeof after.clubId === 'string' ? after.clubId : null;
  for (const ev of events) {
    if (ev === 'publish') {
      if (!after.publishedAt) await event.data!.after.ref.update({ publishedAt: FieldValue.serverTimestamp() });
      await writeAudit({
        action: 'plan.publish', actorId: planActor(after), actorRole: 'coach', targetType: 'trainingPlan', targetId: planId,
        clubId, details: { groupIds: after.groupIds ?? [], from: before?.status ?? null },
      });
      const groups = await loadGroups(after.groupIds);
      for (const g of groups) {
        const parents = groupParentUsers(g, await loadUsers(g.parentIds));
        // One dedupe key per plan: a parent in several of the groups gets one notification, re-publishing never repeats it.
        await notify(parents, {
          type: 'trainingPlanPublished',
          ...pushText('trainingPlanPublished', { group: g.name ?? '', title: truncate(String(after.title ?? ''), 80) }),
          route: `/plans/${planId}`,
          args: { planId, groupId: g.id },
          groupId: g.id,
          dedupeKey: `plan:${planId}:published`,
          data: { planId },
        });
      }
    } else if (ev === 'archive') {
      await writeAudit({
        action: 'plan.archive', actorId: planActor(after), actorRole: 'coach', targetType: 'trainingPlan', targetId: planId,
        clubId, details: { groupIds: after.groupIds ?? [], from: before?.status ?? null },
      });
    }
  }
});

/**
 * getPlanMediaUrl {planId, path} → {url, expiresAt} (15 min). `path` must be
 * under plans/{planId}/ and referenced by one of the plan's exercises. Live
 * check: creator, approved coach of any plan group, or (published only) a
 * parent of any plan group.
 */
export const getPlanMediaUrl = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign in required');
  const planId = request.data?.planId;
  const path = request.data?.path;
  if (typeof planId !== 'string' || !planId || planId.includes('/')) throw new HttpsError('invalid-argument', 'planId is required');
  if (typeof path !== 'string' || !path.startsWith(`plans/${planId}/`) || path.includes('..') || path.length > 500) {
    throw new HttpsError('invalid-argument', 'path must be under plans/{planId}/');
  }
  const snap = await db.doc(`trainingPlans/${planId}`).get();
  if (!snap.exists) throw new HttpsError('not-found', 'plan not found');
  const plan = snap.data()!;
  const referenced = (Array.isArray(plan.exercises) ? plan.exercises : []).some((x: { media?: Array<{ path?: string }> }) =>
    (Array.isArray(x?.media) ? x.media : []).some((m) => m?.path === path));
  if (!referenced) throw new HttpsError('not-found', 'file is not part of this plan');
  const user = await loadUser(request.auth.uid);
  const groups = await loadGroups(plan.groupIds);
  const ok = canViewPlan(
    user ? { uid: user.uid, role: user.role, coachStatus: user.coachStatus } : undefined,
    { createdBy: String(plan.createdBy ?? ''), status: String(plan.status ?? ''), groupIds: Array.isArray(plan.groupIds) ? plan.groupIds : [] },
    groups,
  );
  if (!ok) throw new HttpsError('permission-denied', 'no access to this plan');
  const expiresAt = Date.now() + PLAN_MEDIA_URL_TTL_MS;
  return { url: await signedOrEmulatorUrl(path, expiresAt), expiresAt: new Date(expiresAt).toISOString() };
});
