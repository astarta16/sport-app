// Pure training-plan logic: validation (mirrors firestore.rules), status
// transitions, reader/coach computation and publish/archive events.

export const PLAN_TYPES = ['seasonal', 'monthly', 'weekly', 'exercise', 'homework'] as const;
export const PLAN_STATUSES = ['draft', 'published', 'archived'] as const;
export const MEDIA_KINDS = ['photo', 'video', 'pdf', 'link'] as const;
export const PROGRESS_STATUSES = ['not_started', 'in_progress', 'completed'] as const;
export type PlanStatus = (typeof PLAN_STATUSES)[number];

export const MAX_EXERCISES = 50;
export const MAX_MEDIA_PER_EXERCISE = 10;
export const MAX_GROUPS = 10;
export const MAX_PLAN_IMAGE_BYTES = 10 * 1024 * 1024;
export const MAX_PLAN_PDF_BYTES = 10 * 1024 * 1024;
export const MAX_PLAN_VIDEO_BYTES = 100 * 1024 * 1024;

/** Same pattern as the rules: https only, no whitespace, ≤ 2000 chars. */
export const HTTPS_LINK_RE = /^https:\/\/[^\s]+$/;
const DATE_RE = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;

export function isHttpsLink(v: unknown): boolean {
  return typeof v === 'string' && v.length <= 2000 && HTTPS_LINK_RE.test(v);
}

const isStr = (v: unknown, min: number, max: number) => typeof v === 'string' && v.length >= min && v.length <= max;
const optStr = (v: unknown, max: number) => v === undefined || v === null || isStr(v, 0, max);
const optInt = (v: unknown, min: number, max: number) =>
  v === undefined || v === null || (typeof v === 'number' && Number.isInteger(v) && v >= min && v <= max);

export interface PlanMedia {
  id: string;
  kind: string;
  path?: string | null;
  url?: string | null;
  name?: string | null;
}

export interface PlanExercise {
  id: string;
  order: number;
  name: string;
  description?: string | null;
  instructions?: string | null;
  durationMin?: number | null;
  reps?: number | null;
  sets?: number | null;
  restSec?: number | null;
  media?: PlanMedia[];
}

export interface PlanDoc {
  title: string;
  description?: string | null;
  type: string;
  groupIds: string[];
  clubId: string;
  startDate: string;
  endDate?: string | null;
  status: string;
  createdBy: string;
  exercises?: PlanExercise[];
}

/** Validation errors (empty = valid). `planId` scopes media storage paths. */
export function validatePlan(p: PlanDoc, planId: string): string[] {
  const e: string[] = [];
  if (!isStr(p.title, 1, 120)) e.push('title');
  if (!optStr(p.description, 4000)) e.push('description');
  if (!(PLAN_TYPES as readonly string[]).includes(p.type)) e.push('type');
  if (!Array.isArray(p.groupIds) || p.groupIds.length < 1 || p.groupIds.length > MAX_GROUPS
      || !p.groupIds.every((g) => isStr(g, 1, 128)) || new Set(p.groupIds).size !== p.groupIds.length) e.push('groupIds');
  if (!isStr(p.clubId, 1, 128)) e.push('clubId');
  if (typeof p.startDate !== 'string' || !DATE_RE.test(p.startDate)) e.push('startDate');
  if (p.endDate !== undefined && p.endDate !== null
      && (typeof p.endDate !== 'string' || !DATE_RE.test(p.endDate) || p.endDate < p.startDate)) e.push('endDate');
  if (!(PLAN_STATUSES as readonly string[]).includes(p.status)) e.push('status');
  const ex = p.exercises ?? [];
  if (!Array.isArray(ex) || ex.length > MAX_EXERCISES) e.push('exercises');
  else ex.forEach((x, i) => validateExercise(x, planId).forEach((m) => e.push(`exercises[${i}].${m}`)));
  return e;
}

export function validateExercise(x: PlanExercise, planId: string): string[] {
  const e: string[] = [];
  if (!isStr(x.id, 1, 128)) e.push('id');
  if (!(typeof x.order === 'number' && Number.isInteger(x.order) && x.order >= 0 && x.order <= 1000)) e.push('order');
  if (!isStr(x.name, 1, 120)) e.push('name');
  if (!optStr(x.description, 2000)) e.push('description');
  if (!optStr(x.instructions, 4000)) e.push('instructions');
  if (!optInt(x.durationMin, 0, 600)) e.push('durationMin');
  if (!optInt(x.reps, 0, 1000)) e.push('reps');
  if (!optInt(x.sets, 0, 100)) e.push('sets');
  if (!optInt(x.restSec, 0, 3600)) e.push('restSec');
  const media = x.media ?? [];
  if (!Array.isArray(media) || media.length > MAX_MEDIA_PER_EXERCISE) e.push('media');
  else media.forEach((m, i) => validateMedia(m, planId).forEach((k) => e.push(`media[${i}].${k}`)));
  return e;
}

export function validateMedia(m: PlanMedia, planId: string): string[] {
  const e: string[] = [];
  if (!isStr(m.id, 1, 128)) e.push('id');
  if (!(MEDIA_KINDS as readonly string[]).includes(m.kind)) e.push('kind');
  if (m.url !== undefined && m.url !== null && !isHttpsLink(m.url)) e.push('url');
  if (m.path !== undefined && m.path !== null
      && !(typeof m.path === 'string' && m.path.startsWith(`plans/${planId}/`) && !m.path.includes('..') && m.path.length <= 500)) e.push('path');
  if (m.kind === 'link' && !isHttpsLink(m.url)) e.push('url');
  if (!optStr(m.name, 200)) e.push('name');
  return e;
}

/**
 * Allowed status transitions (coaches): draft→published, published→draft,
 * published→archived (and staying put). Archived is final.
 */
export function planTransitionAllowed(from: string | undefined, to: string): boolean {
  if (from === undefined) return to === 'draft' || to === 'published';
  if (from === to) return true;
  return (from === 'draft' && to === 'published') || (from === 'published' && to === 'draft') || (from === 'published' && to === 'archived');
}

interface GroupMembers { coachIds?: string[]; parentIds?: string[] }

/** Server-managed coachIds: union of coaches of the plan's groups (all statuses). */
export function computePlanCoachIds(groups: GroupMembers[]): string[] {
  return [...new Set(groups.flatMap((g) => g.coachIds ?? []))].sort();
}

/** readerIds: parents + coaches of the groups while published; [] otherwise (draft/archived/invalid). */
export function computePlanReaderIds(status: string, groups: GroupMembers[], valid = true): string[] {
  if (status !== 'published' || !valid) return [];
  return [...new Set(groups.flatMap((g) => [...(g.coachIds ?? []), ...(g.parentIds ?? [])]))].sort();
}

export type PlanEvent = 'publish' | 'archive' | 'unpublish';

export function planEvents(before: { status?: string } | undefined, after: { status?: string } | undefined): PlanEvent[] {
  if (!after) return [];
  const from = before?.status;
  const to = after.status;
  if (from === to) return [];
  if (to === 'published') return ['publish'];
  if (to === 'archived') return ['archive'];
  if (from === 'published' && to === 'draft') return ['unpublish'];
  return [];
}

/** Storage upload limits for plans/{planId}/{file}. */
export function planUploadAllowed(contentType: string | undefined, size: number): boolean {
  const ct = (contentType ?? '').toLowerCase();
  if (!(size > 0)) return false;
  if (ct.startsWith('image/')) return size <= MAX_PLAN_IMAGE_BYTES;
  if (ct.startsWith('video/')) return size <= MAX_PLAN_VIDEO_BYTES;
  if (ct === 'application/pdf') return size <= MAX_PLAN_PDF_BYTES;
  return false;
}

/**
 * Live access to a plan (getPlanMediaUrl): the creator, an approved coach of
 * any of its groups, or — only while published — a parent of any of its groups.
 */
export function canViewPlan(
  user: { uid: string; role?: string; coachStatus?: string } | undefined,
  plan: { createdBy: string; status: string; groupIds: string[] },
  groups: Array<{ id: string; coachIds: string[]; parentIds: string[] }>,
): boolean {
  if (!user) return false;
  const relevant = groups.filter((g) => plan.groupIds.includes(g.id));
  if (user.role === 'coach' && user.coachStatus === 'approved') {
    return user.uid === plan.createdBy || relevant.some((g) => g.coachIds.includes(user.uid));
  }
  if (user.role === 'parent') return plan.status === 'published' && relevant.some((g) => g.parentIds.includes(user.uid));
  return false;
}
