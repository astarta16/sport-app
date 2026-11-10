// Pure moderation helpers: report target parsing and validation.

export const REPORT_TARGET_TYPES = ['chatMessage', 'mediaPost', 'trainingPhoto'] as const;
export type ReportTargetType = (typeof REPORT_TARGET_TYPES)[number];
export const REPORT_REASONS = ['inappropriate', 'privacy', 'spam', 'other'] as const;
export type ReportReason = (typeof REPORT_REASONS)[number];

export type ParsedTarget =
  | { type: 'chatMessage'; groupId: string; messageId: string; docPath: string }
  | { type: 'mediaPost'; postId: string; docPath: string }
  | { type: 'trainingPhoto'; groupId: string; storagePath: string };

/**
 * targetPath formats:
 * - chatMessage: `chats/{groupId}/messages/{messageId}`
 * - mediaPost: `mediaPosts/{postId}`
 * - trainingPhoto: `trainingPhotos/{groupId}/{file…}` (storage path, as stored in trainings.photoUrls)
 */
export function parseReportTarget(type: unknown, path: unknown): ParsedTarget | null {
  if (typeof path !== 'string' || path.length > 500 || path.includes('..') || path.includes('//')) return null;
  if (type === 'chatMessage') {
    const m = /^chats\/([^/]+)\/messages\/([^/]+)$/.exec(path);
    return m ? { type, groupId: m[1], messageId: m[2], docPath: path } : null;
  }
  if (type === 'mediaPost') {
    const m = /^mediaPosts\/([^/]+)$/.exec(path);
    return m ? { type, postId: m[1], docPath: path } : null;
  }
  if (type === 'trainingPhoto') {
    const m = /^trainingPhotos\/([^/]+)\/.+$/.exec(path);
    return m ? { type, groupId: m[1], storagePath: path } : null;
  }
  return null;
}

export function isReportReason(v: unknown): v is ReportReason {
  return typeof v === 'string' && (REPORT_REASONS as readonly string[]).includes(v);
}

export function isModerationDecision(v: unknown): v is 'hidden' | 'kept' {
  return v === 'hidden' || v === 'kept';
}

/** Optional free text: trimmed, ≤ max chars, otherwise null. */
export function cleanText(v: unknown, max: number): string | null {
  if (typeof v !== 'string') return null;
  const t = v.trim();
  return t ? Array.from(t).slice(0, max).join('') : null;
}
