import { describe, expect, it } from 'vitest';
import { t } from '../src/i18n';
import { categoryFor } from '../src/lib/notifications';
import { GroupLite, UserLite } from '../src/lib/types';
import {
  canSeeContactPhone, downloadFileName, groupContactsFor, mediaDownloadDecision, receiptCounts, receiptEligible,
  receiptRecipients, receiptState,
} from '../src/lib/v14';

const coach = (uid: string, status = 'approved'): UserLite => ({ uid, role: 'coach', coachStatus: status as UserLite['coachStatus'], firstName: 'C', lastName: uid, phone: `+9955000${uid.length}` });
const parent = (uid: string): UserLite => ({ uid, role: 'parent', firstName: 'P', lastName: uid, phone: `+995599${uid}` });
const group = (o: Partial<GroupLite> = {}): GroupLite => ({ id: 'g1', clubId: 'club1', name: 'U10', coachIds: ['c1'], parentIds: ['p1', 'p2', 'p3'], memberChildIds: ['k1', 'k2'], status: 'active', ...o });

describe('contact phone visibility', () => {
  it('coach ↔ parents of the same active group only', () => {
    expect(canSeeContactPhone(coach('c1'), parent('p1'), [group()])).toBe(true);
    expect(canSeeContactPhone(parent('p1'), coach('c1'), [group()])).toBe(true);
    expect(canSeeContactPhone(coach('c1'), parent('p9'), [group()])).toBe(false);
    expect(canSeeContactPhone(coach('c9'), parent('p1'), [group()])).toBe(false);
  });
  it('parents never see other parents; pending/suspended coaches get nothing and are not shown', () => {
    expect(canSeeContactPhone(parent('p1'), parent('p2'), [group()])).toBe(false);
    expect(canSeeContactPhone(coach('c1', 'pending'), parent('p1'), [group()])).toBe(false);
    expect(canSeeContactPhone(coach('c1', 'suspended'), parent('p1'), [group()])).toBe(false);
    expect(canSeeContactPhone(parent('p1'), coach('c1', 'pending'), [group()])).toBe(false);
  });
  it('archived groups and ended membership revoke access', () => {
    expect(canSeeContactPhone(coach('c1'), parent('p1'), [group({ status: 'archived' })])).toBe(false);
    expect(canSeeContactPhone(coach('c1'), parent('p1'), [group({ parentIds: ['p2'] })])).toBe(false);
    expect(canSeeContactPhone(parent('p1'), coach('c1'), [group({ coachIds: ['c2'] })])).toBe(false);
  });
});

describe('group contact projection', () => {
  const users = new Map<string, UserLite>([['c1', coach('c1')], ['c2', coach('c2', 'pending')], ['p1', parent('p1')], ['p2', parent('p2')], ['p3', parent('p3')]]);
  const kids = [
    { id: 'k1', firstName: 'Luka', parentIds: ['p1', 'p2'], guardianRelations: { p1: 'mother', p2: 'father' } },
    { id: 'k2', firstName: 'Ana', parentIds: ['p3'] },
    { id: 'kx', firstName: 'Other', parentIds: ['p1'] },
  ];
  it('coach gets every guardian with their children in this group and the relation', () => {
    const c = groupContactsFor(coach('c1'), group(), users, kids)!;
    expect(c.map((x) => x.uid)).toEqual(['p1', 'p2', 'p3']);
    expect(c[0].children).toEqual([{ id: 'k1', firstName: 'Luka', relation: 'mother' }]);
    expect(c[1].children[0].relation).toBe('father');
    expect(c[2].children[0].relation).toBeNull();
    expect(c[0].phone).toBe('+995599p1');
  });
  it('parent gets only approved coaches, never other parents', () => {
    const c = groupContactsFor(parent('p1'), group({ coachIds: ['c1', 'c2'] }), users, kids)!;
    expect(c.map((x) => x.uid)).toEqual(['c1']);
    expect(c.every((x) => x.role === 'coach')).toBe(true);
  });
  it('outsiders, pending coaches and archived groups get null', () => {
    expect(groupContactsFor(parent('p9'), group(), users, kids)).toBeNull();
    expect(groupContactsFor(coach('c1', 'pending'), group(), users, kids)).toBeNull();
    expect(groupContactsFor(coach('c1'), group({ status: 'archived' }), users, kids)).toBeNull();
  });
});

describe('read receipts and acknowledgments', () => {
  const users = new Map<string, UserLite>([['p1', parent('p1')], ['p2', parent('p2')], ['p3', parent('p3')], ['c1', coach('c1')]]);
  it('only coach text/announcement messages are eligible', () => {
    expect(receiptEligible({ senderRole: 'coach', type: 'text' })).toBe(true);
    expect(receiptEligible({ senderRole: 'coach', type: 'announcement' })).toBe(true);
    expect(receiptEligible({ senderRole: 'coach', type: 'system' })).toBe(false);
    expect(receiptEligible({ senderRole: 'parent', type: 'text' })).toBe(false);
  });
  it('recipients are unique parent accounts at creation (guardians separately, duplicates once)', () => {
    expect(receiptRecipients(group({ parentIds: ['p2', 'p1', 'p1', 'c1', 'p3', 'ghost'] }), users, 'c1')).toEqual(['p1', 'p2', 'p3']);
  });
  it('counts only the snapshot; an acknowledgment implies seen; reads never imply ack', () => {
    const c = receiptCounts(['p1', 'p2', 'p3'], ['p1', 'newMember'], ['p2', 'p2']);
    expect(c).toEqual({ recipientCount: 3, readCount: 2, ackCount: 1 });
    expect(receiptState('p1', new Set(['p1']), new Set())).toBe('seen');
    expect(receiptState('p2', new Set(), new Set(['p2']))).toBe('acknowledged');
    expect(receiptState('p3', new Set(), new Set())).toBe('notSeen');
  });
  it('ackRequested is an announcement-category notification with texts in every language', () => {
    expect(categoryFor('ackRequested')).toBe('announcements');
    for (const l of ['ka', 'en', 'ru']) expect(t(l, 'push.ackRequested.title', { group: 'U10' })).toContain('U10');
  });
});

describe('media download authorization', () => {
  const post = { coachId: 'c1', groupIds: ['g1'], hidden: false, consentConfirmed: true };
  it('a parent of an active group may download; others may not', () => {
    expect(mediaDownloadDecision(parent('p1'), post, [group()])).toEqual({ ok: true });
    expect(mediaDownloadDecision(parent('p9'), post, [group()])).toEqual({ ok: false, reason: 'notMember' });
    expect(mediaDownloadDecision(coach('c2'), post, [group({ coachIds: ['c1', 'c2'] })])).toEqual({ ok: false, reason: 'role' });
    expect(mediaDownloadDecision(coach('c1'), post, [])).toEqual({ ok: true });
  });
  it('hidden posts, archived groups, missing consent and a disabled policy are rejected', () => {
    expect(mediaDownloadDecision(parent('p1'), { ...post, hidden: true }, [group()])).toEqual({ ok: false, reason: 'hidden' });
    expect(mediaDownloadDecision(parent('p1'), post, [group({ status: 'archived' })])).toEqual({ ok: false, reason: 'notMember' });
    expect(mediaDownloadDecision(parent('p1'), { ...post, consentConfirmed: false }, [group()])).toEqual({ ok: false, reason: 'policy' });
    expect(mediaDownloadDecision(parent('p1'), post, [group({ mediaDownloadsEnabled: false })])).toEqual({ ok: false, reason: 'policy' });
    expect(mediaDownloadDecision(parent('p1'), undefined, [group()])).toEqual({ ok: false, reason: 'notFound' });
  });
  it('file names are ASCII with the right extension', () => {
    expect(downloadFileName({ id: 'post-1', type: 'photo' }, 'image/png', 'media/c1/post-1/a.png')).toBe('sportparent_photo_post-1.png');
    expect(downloadFileName({ id: 'p/2', type: 'video' }, undefined, 'media/c1/p2/clip.MOV')).toBe('sportparent_video_p2.mov');
    expect(downloadFileName({ id: 'x', type: 'video' }, undefined, 'media/c1/x/noext')).toBe('sportparent_video_x.mp4');
  });
});
