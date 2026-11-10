import { describe, expect, it } from 'vitest';
import {
  collectTokens, selectCertificateRecipients, selectChatRecipients, selectTrainingRecipients,
} from '../src/lib/recipients';
import { ChildLite, GroupLite, UserLite } from '../src/lib/types';

const u = (uid: string, role: UserLite['role'], extra: Partial<UserLite> = {}): UserLite => ({
  uid, role, fcmTokens: [`tok-${uid}`], notificationPrefs: {}, ...extra,
});

const users = new Map<string, UserLite>([
  ['p1', u('p1', 'parent')],
  ['p2', u('p2', 'parent', { notificationPrefs: { newTraining: false, chatMessage: false } })],
  ['p3', u('p3', 'parent')],
  ['kid', u('kid', 'child')],
  ['c1', u('c1', 'coach', { coachStatus: 'approved' })],
  ['c2', u('c2', 'coach', { coachStatus: 'pending' })],
  ['outsider', u('outsider', 'parent')],
]);

const group: GroupLite = {
  id: 'g1', name: 'U12', coachIds: ['c1', 'c2'], parentIds: ['p1', 'p2', 'p3', 'kid'],
  memberChildIds: ['a', 'b', 'c'],
};

describe('selectTrainingRecipients', () => {
  it('only notifies parents in group.parentIds, never children or coaches or outsiders', () => {
    const r = selectTrainingRecipients({ group, users, type: 'trainingChanged' }).map((x) => x.uid);
    expect(r).toEqual(['p1', 'p2', 'p3']);
  });

  it('respects notificationPrefs (default on)', () => {
    const r = selectTrainingRecipients({ group, users, type: 'newTraining' }).map((x) => x.uid);
    expect(r).toEqual(['p1', 'p3']);
  });

  it('newPhotos: only parents with a consenting child in the group', () => {
    const children: ChildLite[] = [
      { id: 'a', firstName: 'A', parentIds: ['p1'], photoConsent: true },
      { id: 'b', firstName: 'B', parentIds: ['p2'], photoConsent: true },
      { id: 'c', firstName: 'C', parentIds: ['p3'], photoConsent: false },
      { id: 'x', firstName: 'X', parentIds: ['p3'], photoConsent: true }, // not a member
    ];
    const r = selectTrainingRecipients({ group, users, type: 'newPhotos', children }).map((x) => x.uid);
    expect(r).toEqual(['p1', 'p2']);
  });

  it('skips unknown users and the excluded uid', () => {
    const g = { ...group, parentIds: ['p1', 'ghost', 'p3'] };
    const r = selectTrainingRecipients({ group: g, users, type: 'trainingReminder', excludeUid: 'p3' }).map((x) => x.uid);
    expect(r).toEqual(['p1']);
  });
});

describe('selectChatRecipients', () => {
  it('notifies approved coaches + parents except sender, never child accounts', () => {
    const r = selectChatRecipients(group, users, 'p1').map((x) => x.uid);
    expect(r).toEqual(['c1', 'p3']); // c2 pending, p2 opted out, kid is a child
  });

  it('coach as sender is excluded', () => {
    const r = selectChatRecipients(group, users, 'c1').map((x) => x.uid);
    expect(r).toEqual(['p1', 'p3']);
  });

  it('a child uid listed in coachIds is still never notified', () => {
    const g = { ...group, coachIds: ['kid'] };
    expect(selectChatRecipients(g, users, 'p1').map((x) => x.uid)).toEqual(['p3']);
  });
});

describe('certificate recipients and tokens', () => {
  it('only parents of the child with certificateExpiry enabled', () => {
    const m = new Map(users);
    m.set('p3', u('p3', 'parent', { notificationPrefs: { certificateExpiry: false } }));
    const child: ChildLite = { id: 'a', firstName: 'A', parentIds: ['p1', 'p3', 'kid'] };
    expect(selectCertificateRecipients(child, m).map((x) => x.uid)).toEqual(['p1']);
  });

  it('collects unique non-empty tokens', () => {
    expect(collectTokens([u('a', 'parent', { fcmTokens: ['t1', 't2', ''] }), u('b', 'parent', { fcmTokens: ['t2'] })])).toEqual(['t1', 't2']);
  });
});
