import { describe, expect, it } from 'vitest';
import { t } from '../src/i18n';
import { categoryFor } from '../src/lib/notifications';
import {
  attendanceDedupeKey, attendanceNotice, attendanceWordKey, feedbackNotice, planActor, scheduleSystemMessage,
} from '../src/lib/progressNotices';

describe('attendance notifications', () => {
  it('fires on a new mark and on a status change only', () => {
    expect(attendanceNotice(undefined, { status: 'present' })).toBe('present');
    expect(attendanceNotice({ status: 'present' }, { status: 'absent' })).toBe('absent');
    expect(attendanceNotice({ status: 'present' }, { status: 'present' })).toBeNull(); // note-only edit
    expect(attendanceNotice({ status: 'present' }, undefined)).toBeNull(); // unmarked
    expect(attendanceNotice(undefined, { status: 'late' })).toBeNull();
  });

  it('dedupes per status and localizes the status word', () => {
    expect(attendanceDedupeKey('t1_c1', 'excused')).toBe('att:t1_c1:excused');
    for (const l of ['ka', 'en', 'ru']) {
      for (const s of ['present', 'absent', 'excused'] as const) {
        const word = t(l, attendanceWordKey(s));
        expect(word).not.toContain('words.');
      }
    }
    expect(t('en', attendanceWordKey('absent'))).toBe('absent');
    expect(t('en', 'push.attendanceRecorded.body', { child: 'Luka', status: 'present', date: '12 Nov' })).toBe('Luka: present (12 Nov)');
  });

  it('both types live in the attendance category (honours prefs)', () => {
    expect(categoryFor('attendanceRecorded')).toBe('attendance');
    expect(categoryFor('feedbackAdded')).toBe('attendance');
  });
});

describe('feedback notifications', () => {
  it('only new, parent-visible feedback is announced', () => {
    expect(feedbackNotice(undefined, { childId: 'c1', visibleToParent: true })).toBe(true);
    expect(feedbackNotice({ childId: 'c1' }, { childId: 'c1', visibleToParent: true })).toBe(false);
    expect(feedbackNotice(undefined, { childId: 'c1', visibleToParent: false })).toBe(false);
    expect(feedbackNotice(undefined, undefined)).toBe(false);
  });
  it('has texts in every language', () => {
    expect(t('ru', 'push.feedbackAdded.title')).toBe('Отзыв тренера');
    expect(t('en', 'push.feedbackAdded.body', { child: 'Luka', coach: 'Giorgi' })).toBe('Luka: new feedback from Giorgi');
  });
});

describe('schedule / moved-training system messages', () => {
  it('new series → scheduleCreated; change → scheduleChanged from max(startDate, today)', () => {
    expect(scheduleSystemMessage(undefined, { startDate: '2026-11-20' }, '2026-11-12')).toEqual({ key: 'scheduleCreated', args: {} });
    const future = scheduleSystemMessage({ startDate: '2026-09-01' }, { startDate: '2026-11-20' }, '2026-11-12');
    expect(future.key).toBe('scheduleChanged');
    expect(future.args.from).toContain('20');
    const past = scheduleSystemMessage({ startDate: '2026-09-01' }, { startDate: '2026-09-01' }, '2026-11-12');
    expect(past.args.from).toContain('12');
  });
  it('system keys exist in ka/en/ru with the client placeholders', () => {
    for (const l of ['ka', 'en', 'ru']) {
      expect(t(l, 'system.trainingMoved', { from: 'A', to: 'B' })).toMatch(/A.*B/);
      expect(t(l, 'system.scheduleChanged', { from: 'X' })).toContain('X');
      expect(t(l, 'system.scheduleCreated')).not.toBe('system.scheduleCreated');
    }
  });
});

describe('plan audit actor', () => {
  it('uses updatedBy, falls back to the creator', () => {
    expect(planActor({ createdBy: 'a', updatedBy: 'b' })).toBe('b');
    expect(planActor({ createdBy: 'a' })).toBe('a');
    expect(planActor({})).toBe('unknown');
  });
});
