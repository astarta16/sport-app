import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { adminScopeFromClaims, canActOnClub, canManageCoach, coachAuditAction, computeAdminClaims, isSettableCoachStatus } from '../src/lib/adminScope';
import { cancelReasonText, isValidCancel } from '../src/lib/cancel';
import { buildExport } from '../src/lib/export';
import { encodeGeohash } from '../src/lib/geo';
import { INVITE_CODE_ALPHABET, generateInviteCode, normalizeInviteCode } from '../src/lib/inviteCode';
import { isInviteAddressee, normalizePhone, planInviteResponse, validateNewChild } from '../src/lib/invites';
import { classifyMatchWrite, matchReminderFields, matchReminderStage, movedMatchPatch } from '../src/lib/matches';
import { canViewMediaPost, computeReaderIds, parseMediaPath, validateMediaUpload } from '../src/lib/media';
import { cleanText, isModerationDecision, parseReportTarget } from '../src/lib/moderation';
import { CATEGORY_TYPES, categoryFor, notificationId, pushAllowed } from '../src/lib/notifications';
import { paymentAuditEntry } from '../src/lib/payments';
import { decideRateLimit } from '../src/lib/rateLimit';
import { filterSearchResults, normalizeQuery, prefixVariants } from '../src/lib/search';
import { resetGroupUnread, unreadRecipients } from '../src/lib/unread';
import { ChildLite } from '../src/lib/types';

describe('notifications: dedupe id and categories', () => {
  it('id = sha1(userId|dedupeKey), stable and distinct', () => {
    expect(notificationId('u1', 'training:t1:new')).toBe(notificationId('u1', 'training:t1:new'));
    expect(notificationId('u1', 'training:t1:new')).toMatch(/^[0-9a-f]{40}$/);
    expect(notificationId('u2', 'training:t1:new')).not.toBe(notificationId('u1', 'training:t1:new'));
    expect(notificationId('a', 'b')).toBe(createHash('sha1').update('a|b').digest('hex'));
  });
  it('maps every Flutter type to its category', () => {
    expect(categoryFor('newTraining')).toBe('trainings');
    expect(categoryFor('scheduleChanged')).toBe('trainings');
    expect(categoryFor('matchReminder')).toBe('matches');
    expect(categoryFor('groupInvite')).toBe('invitations');
    expect(categoryFor('inviteAnswered')).toBe('invitations');
    expect(categoryFor('attendanceRecorded')).toBe('attendance');
    expect(categoryFor('feedbackAdded')).toBe('attendance');
    expect(categoryFor('paymentSms')).toBe('payments');
    expect(categoryFor('chatMessage')).toBe('chat');
    expect(categoryFor('certificateExpiry')).toBe('certificates');
    expect(categoryFor('newPhotos')).toBe('announcements');
    expect(categoryFor('newMedia')).toBe('announcements');
    expect(() => categoryFor('bogus')).toThrow();
    expect(Object.values(CATEGORY_TYPES).flat().length).toBe(22); // 18 (v1.2) + 4 v1.3 types
  });
  it('push prefs: type key, default on, invitations always', () => {
    expect(pushAllowed(undefined, 'newMatch')).toBe(true);
    expect(pushAllowed({ newMatch: false }, 'newMatch')).toBe(false);
    expect(pushAllowed({ groupInvite: false }, 'groupInvite')).toBe(true);
  });
});

describe('rate limiter (sliding window)', () => {
  const W = 1000;
  it('allows up to limit within the window then blocks', () => {
    let hits: number[] = [];
    for (let i = 0; i < 3; i++) {
      const d = decideRateLimit(hits, 100 + i, 3, W);
      expect(d.allowed).toBe(true);
      hits = d.hits;
    }
    const blocked = decideRateLimit(hits, 200, 3, W);
    expect(blocked.allowed).toBe(false);
    expect(blocked.retryAfterMs).toBe(100 + W - 200);
  });
  it('old hits slide out of the window', () => {
    expect(decideRateLimit([0, 1, 2], 1001, 3, W).allowed).toBe(true);
    expect(decideRateLimit([0, 1, 2], 1001, 3, W).hits).toEqual([2, 1001]); // t > now - window
  });
  it('ignores garbage and future timestamps; limit 0 blocks', () => {
    expect(decideRateLimit([NaN as unknown as number, 5000], 100, 1, W).allowed).toBe(true);
    expect(decideRateLimit([], 0, 0, W).allowed).toBe(false);
  });
});

describe('invite codes', () => {
  it('6 chars from the alphabet without 0/O/1/I', () => {
    expect(INVITE_CODE_ALPHABET).not.toMatch(/[0O1I]/);
    expect(INVITE_CODE_ALPHABET.length).toBe(32);
    for (let i = 0; i < 200; i++) expect(generateInviteCode()).toMatch(/^[A-HJ-NP-Z2-9]{6}$/);
    expect(generateInviteCode(() => 0)).toBe('AAAAAA');
  });
  it('normalizes user input', () => {
    expect(normalizeInviteCode(' abc-d23 ')).toBe('ABCD23');
    expect(normalizeInviteCode('ABCDE0')).toBeNull();
    expect(normalizeInviteCode('ABCD')).toBeNull();
    expect(normalizeInviteCode(42)).toBeNull();
  });
});

describe('invites', () => {
  const child = (o: Partial<ChildLite>): ChildLite => ({ id: 'c', firstName: 'N', parentIds: [], ...o });
  const invite = { id: 'i1', status: 'sent' as const, parentId: 'p1', phone: '+995599000001', groupId: 'g1', childId: 'pending', createdBy: 'coach' };
  const pending = child({ id: 'pending', status: 'pendingParent', createdByCoachId: 'coach' });

  it('phone normalisation', () => {
    expect(normalizePhone('599 00 00 01')).toBe('+995599000001');
    expect(normalizePhone('+49 151 23456789')).toBe('+4915123456789');
    expect(normalizePhone('123')).toBeNull();
  });
  it('validates the new pending child', () => {
    expect(validateNewChild({ firstName: ' ნიკა ', lastName: 'B', birthDate: '2015-03-01T00:00:00.000', parentPhone: '599000001' }, '2026-11-10'))
      .toEqual({ ok: true, value: { firstName: 'ნიკა', lastName: 'B', birthDate: '2015-03-01', parentPhone: '+995599000001' } });
    expect(validateNewChild({ firstName: '', birthDate: '2015-03-01', parentPhone: '599000001' }, '2026-11-10').ok).toBe(false);
    expect(validateNewChild({ firstName: 'a', birthDate: '2027-01-01', parentPhone: '599000001' }, '2026-11-10').ok).toBe(false);
    expect(validateNewChild({ firstName: 'a', birthDate: '2015-02-30', parentPhone: '599000001' }, '2026-11-10').ok).toBe(false);
    expect(validateNewChild({ firstName: 'a', birthDate: '2015-02-01', parentPhone: 'x' }, '2026-11-10').ok).toBe(false);
  });
  it('only the addressed parent (uid, or verified phone when unresolved)', () => {
    expect(isInviteAddressee(invite, 'p1')).toBe(true);
    expect(isInviteAddressee(invite, 'p2', '+995599000001')).toBe(false);
    expect(isInviteAddressee({ ...invite, parentId: null }, 'p2', '+995599000001')).toBe(true);
    expect(isInviteAddressee({ ...invite, parentId: null }, 'p2', null)).toBe(false);
  });
  it('accept with linkedChildId links own child and deletes the pending child', () => {
    const own = child({ id: 'own', parentIds: ['p1'], status: 'active' });
    expect(planInviteResponse({ invite, uid: 'p1', accept: true, inviteChild: pending, linkedChild: own, linkedChildId: 'own' }))
      .toEqual({ kind: 'link', memberChildId: 'own', deleteChildId: 'pending' });
  });
  it('cannot link someone else\'s child', () => {
    const other = child({ id: 'x', parentIds: ['p9'] });
    expect(planInviteResponse({ invite, uid: 'p1', accept: true, inviteChild: pending, linkedChild: other, linkedChildId: 'x' }).kind).toBe('error');
  });
  it('accept without link claims the pending child', () => {
    expect(planInviteResponse({ invite, uid: 'p1', accept: true, inviteChild: pending })).toEqual({ kind: 'claim', memberChildId: 'pending' });
  });
  it('existing-child invite: parent of the child joins; stranger cannot', () => {
    const existing = child({ id: 'e', parentIds: ['p1'], status: 'active' });
    expect(planInviteResponse({ invite: { ...invite, childId: 'e' }, uid: 'p1', accept: true, inviteChild: existing }).kind).toBe('join');
    expect(planInviteResponse({ invite: { ...invite, childId: 'e' }, uid: 'p2', accept: true, inviteChild: existing }).kind).toBe('error');
  });
  it('decline deletes an unused pending child only', () => {
    expect(planInviteResponse({ invite, uid: 'p1', accept: false, inviteChild: pending })).toEqual({ kind: 'decline', deleteChildId: 'pending' });
    const claimed = { ...pending, parentIds: ['p3'] };
    expect(planInviteResponse({ invite, uid: 'p1', accept: false, inviteChild: claimed })).toEqual({ kind: 'decline', deleteChildId: null });
  });
  it('already answered invites are rejected', () => {
    expect(planInviteResponse({ invite: { ...invite, status: 'accepted' }, uid: 'p1', accept: true, inviteChild: pending }).kind).toBe('error');
  });
});

describe('cancel reasons', () => {
  it('code in the 4 values, reason 5..300 chars', () => {
    expect(isValidCancel('illness', 'Coach is ill')).toBe(true);
    expect(isValidCancel('weather', 'rain')).toBe(false);
    expect(isValidCancel('holiday', 'Public holiday')).toBe(false);
    expect(isValidCancel('other', 'x'.repeat(301))).toBe(false);
    expect(isValidCancel('other', '     ')).toBe(false);
    expect(cancelReasonText('weather', 'ძლიერი წვიმა')).toBe('ამინდი — ძლიერი წვიმა');
  });
});

describe('matches', () => {
  const m = (o = {}) => ({ groupId: 'g', startAt: new Date('2026-11-12T14:00:00Z'), status: 'scheduled' as const, ...o });
  it('classifies writes', () => {
    expect(classifyMatchWrite(undefined, m())).toEqual([{ type: 'newMatch' }]);
    expect(classifyMatchWrite(m(), m({ status: 'cancelled' }))).toEqual([{ type: 'matchChanged', change: 'cancelled' }]);
    expect(classifyMatchWrite(m(), m({ startAt: new Date('2026-11-13T14:00:00Z') }))).toEqual([{ type: 'matchChanged', change: 'moved' }]);
    expect(classifyMatchWrite(m(), m({ status: 'moved' }))).toEqual([]);
    expect(movedMatchPatch(m(), m({ startAt: new Date('2026-11-13T14:00:00Z') }))).toBe(true);
    expect(movedMatchPatch(m(), m({ status: 'cancelled', startAt: new Date('2026-11-13T14:00:00Z') }))).toBe(false);
  });
  it('reminder stages: 1 day and 2 hours, each once', () => {
    const start = new Date('2026-11-12T14:00:00Z');
    expect(matchReminderStage(m(), new Date(start.getTime() - 25 * 3600e3))).toBeNull();
    expect(matchReminderStage(m(), new Date(start.getTime() - 20 * 3600e3))).toBe('1d');
    expect(matchReminderStage(m({ reminder1dSentAt: new Date() }), new Date(start.getTime() - 20 * 3600e3))).toBeNull();
    expect(matchReminderStage(m({ reminder1dSentAt: new Date() }), new Date(start.getTime() - 3600e3))).toBe('2h');
    expect(matchReminderStage(m({ reminder2hSentAt: new Date() }), new Date(start.getTime() - 3600e3))).toBeNull();
    expect(matchReminderStage(m({ status: 'cancelled' }), new Date(start.getTime() - 3600e3))).toBeNull();
    expect(matchReminderFields('2h')).toEqual(['reminder2hSentAt', 'reminder1dSentAt']);
  });
});

describe('unread counters', () => {
  it('reset one group, total recomputed', () => {
    expect(resetGroupUnread({ total: 9, byGroup: { g1: 3, g2: 4, g3: -1 } }, 'g1')).toEqual({ total: 4, byGroup: { g2: 4, g1: 0 } });
    expect(resetGroupUnread(undefined, 'g1')).toEqual({ total: 0, byGroup: { g1: 0 } });
  });
  it('everyone except the sender', () => {
    expect(unreadRecipients(['a', 'b', 'a', 'c'], 'b')).toEqual(['a', 'c']);
  });
});

describe('media', () => {
  it('validates uploads', () => {
    expect(validateMediaUpload('image/jpeg', 1000)).toEqual({ ok: true, kind: 'photo' });
    expect(validateMediaUpload('image/jpeg', 10 * 1024 * 1024)).toEqual({ ok: false, reason: 'image_too_large' });
    expect(validateMediaUpload('video/mp4', 99 * 1024 * 1024)).toEqual({ ok: true, kind: 'video' });
    expect(validateMediaUpload('video/mp4', 100 * 1024 * 1024)).toEqual({ ok: false, reason: 'video_too_large' });
    expect(validateMediaUpload('application/pdf', 10)).toEqual({ ok: false, reason: 'content_type' });
    expect(validateMediaUpload('image/png', 0).ok).toBe(false);
  });
  it('parses paths and computes readers', () => {
    expect(parseMediaPath('media/c1/p1/a.jpg')).toEqual({ coachId: 'c1', postId: 'p1', file: 'a.jpg' });
    expect(parseMediaPath('media/c1/p1/x/a.jpg')).toBeNull();
    expect(computeReaderIds([{ coachIds: ['c1'], parentIds: ['p2', 'p1'] }, { coachIds: ['c2'], parentIds: ['p1'] }], 'c1'))
      .toEqual(['c1', 'c2', 'p1', 'p2']);
  });
  it('live access check', () => {
    const groups = [{ id: 'g1', coachIds: ['c1'], parentIds: ['p1'] }];
    const post = { coachId: 'c1', groupIds: ['g1'] };
    expect(canViewMediaPost({ uid: 'p1', role: 'parent' }, post, groups)).toBe(true);
    expect(canViewMediaPost({ uid: 'p2', role: 'parent' }, post, groups)).toBe(false);
    expect(canViewMediaPost({ uid: 'p1', role: 'parent' }, { ...post, hidden: true }, groups)).toBe(false);
    expect(canViewMediaPost({ uid: 'c1', role: 'coach', coachStatus: 'suspended' }, { ...post, hidden: true }, groups)).toBe(true); // owner
    expect(canViewMediaPost({ uid: 'c9', role: 'coach', coachStatus: 'approved' }, post, [{ id: 'g1', coachIds: ['c9'], parentIds: [] }])).toBe(true);
    expect(canViewMediaPost({ uid: 'c9', role: 'coach', coachStatus: 'suspended' }, post, [{ id: 'g1', coachIds: ['c9'], parentIds: [] }])).toBe(false);
  });
});

describe('moderation', () => {
  it('parses report targets', () => {
    expect(parseReportTarget('chatMessage', 'chats/g1/messages/m1')).toMatchObject({ groupId: 'g1', messageId: 'm1' });
    expect(parseReportTarget('mediaPost', 'mediaPosts/p1')).toMatchObject({ postId: 'p1' });
    expect(parseReportTarget('trainingPhoto', 'trainingPhotos/g1/x.jpg')).toMatchObject({ groupId: 'g1' });
    expect(parseReportTarget('chatMessage', 'chats/g1/messages/../x')).toBeNull();
    expect(parseReportTarget('mediaPost', 'chats/g1/messages/m1')).toBeNull();
    expect(parseReportTarget('user', 'users/u1')).toBeNull();
    expect(isModerationDecision('hidden')).toBe(true);
    expect(isModerationDecision('deleted')).toBe(false);
    expect(cleanText('  hi  ', 1)).toBe('h');
    expect(cleanText('   ', 10)).toBeNull();
  });
});

describe('admin scope', () => {
  it('claims parsing and club scope', () => {
    const club = adminScopeFromClaims({ clubAdmin: ['c1', 'c1', 5] });
    expect(club).toEqual({ platform: false, clubIds: ['c1'] });
    expect(canActOnClub(club, 'c1')).toBe(true);
    expect(canActOnClub(club, 'c2')).toBe(false);
    expect(canActOnClub(adminScopeFromClaims({ admin: true }), 'c2')).toBe(true);
    expect(canActOnClub(adminScopeFromClaims({ admin: 'true' }), 'c2')).toBe(false);
    expect(canManageCoach(club, ['c2', 'c1'])).toBe(true);
    expect(canManageCoach(club, ['c2'])).toBe(false);
  });
  it('coach statuses and audit actions', () => {
    expect(isSettableCoachStatus('suspended')).toBe(true);
    expect(isSettableCoachStatus('pending')).toBe(false);
    expect(coachAuditAction('revoked')).toBe('coach.revoke');
  });
  it('computes claims, keeping unrelated ones', () => {
    expect(computeAdminClaims({ x: 1, admin: true }, 'club', ['b', 'a', 'a'])).toEqual({ x: 1, clubAdmin: ['a', 'b'] });
    expect(computeAdminClaims({ clubAdmin: ['a'] }, 'platform', [])).toEqual({ admin: true });
    expect(computeAdminClaims({ admin: true, clubAdmin: ['a'] }, 'none', [])).toEqual({});
    expect(() => computeAdminClaims({}, 'club', [])).toThrow();
  });
});

describe('payment audit', () => {
  it('only on status change, actor from updatedBy', () => {
    expect(paymentAuditEntry(undefined, { status: 'pending' })).toBeNull();
    expect(paymentAuditEntry({ status: 'pending' }, { status: 'pending' })).toBeNull();
    expect(paymentAuditEntry({ status: 'pending' }, { status: 'paid', updatedBy: 'coach1' })).toEqual({ from: 'pending', to: 'paid', actorId: 'coach1' });
    expect(paymentAuditEntry({ status: 'pending' }, { status: 'cancelled' })).toEqual({ from: 'pending', to: 'cancelled', actorId: 'unknown' });
  });
});

describe('data export', () => {
  it('metadata only, strips tokens / storage paths / other people', () => {
    const out = buildExport({
      uid: 'p1', generatedAt: new Date('2026-11-10T00:00:00Z'),
      user: { id: 'p1', role: 'parent', fcmTokens: ['secret'], createdAt: new Date('2026-01-01T00:00:00Z') },
      children: [{ id: 'c1', firstName: 'N', coachIds: ['x'] }],
      certificates: [{ id: 'cert', childId: 'c1', storagePath: 'medical/c1/cert', validUntil: new Date('2027-01-01T00:00:00Z') }, { id: 'o', childId: 'c9' }],
      rsvps: [{ id: 'r', childId: 'c1' }], attendance: [], feedback: [],
      payments: [{ id: 'pay', parentId: 'p1', reminders: {} }, { id: 'pay2', parentId: 'p2' }],
      membershipRequests: [], invites: [{ id: 'i', parentId: 'p1', phone: '+995' }], notifications: [{ id: 'n', userId: 'p2' }],
    }) as Record<string, any>;
    expect(out.user.fcmTokens).toBeUndefined();
    expect(out.user.createdAt).toBe('2026-01-01T00:00:00.000Z');
    expect(out.children[0].coachIds).toBeUndefined();
    expect(out.medicalCertificates).toEqual([{ id: 'cert', childId: 'c1', validUntil: '2027-01-01T00:00:00.000Z' }]);
    expect(out.payments.map((p: any) => p.id)).toEqual(['pay']);
    expect(out.invites[0].phone).toBeUndefined();
    expect(out.notifications).toEqual([]);
    expect(JSON.stringify(out)).not.toContain('medical/');
  });
});

describe('child search', () => {
  it('query normalisation', () => {
    expect(normalizeQuery(' a ')).toBeNull();
    expect(normalizeQuery('ნი')).toBe('ნი');
    expect(prefixVariants('nika b')).toEqual(['nika', 'Nika']);
  });
  it('filters pending/members, matches all words, projects minimal fields, max 20', () => {
    const cands = [
      { id: '1', firstName: 'Nika', lastName: 'Beridze', birthYear: 2015, status: 'active', parentIds: ['p'] } as any,
      { id: '2', firstName: 'Nika', lastName: 'Kapanadze', birthYear: 2014, status: 'pendingParent' },
      { id: '3', firstName: 'Nika', lastName: 'Bolkvadze', birthYear: 2016, status: 'active' },
      { id: '1', firstName: 'Nika', lastName: 'Beridze', birthYear: 2015, status: 'active' },
    ];
    expect(filterSearchResults(cands, 'nika b', ['3'])).toEqual([{ childId: '1', firstName: 'Nika', lastName: 'Beridze', birthYear: 2015 }]);
    const many = Array.from({ length: 30 }, (_, i) => ({ id: `x${i}`, firstName: 'Ana', birthYear: 2015 }));
    expect(filterSearchResults(many, 'an', []).length).toBe(20);
  });
});

describe('geohash', () => {
  it('encodes Tbilisi', () => {
    expect(encodeGeohash(41.7151, 44.8271).startsWith('szr')).toBe(true);
    expect(() => encodeGeohash(91, 0)).toThrow();
  });
});
