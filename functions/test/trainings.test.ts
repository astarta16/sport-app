import { describe, expect, it } from 'vitest';
import { classifyTrainingWrite, isTrainingReminderDue, movedTrainingPatch } from '../src/lib/trainings';
import { TrainingLite } from '../src/lib/types';

const base: TrainingLite = {
  groupId: 'g1', startAt: new Date('2026-11-12T14:00:00Z'), status: 'scheduled', photoUrls: [],
};

describe('classifyTrainingWrite', () => {
  it('create -> newTraining', () => {
    expect(classifyTrainingWrite(undefined, base)).toEqual([{ type: 'newTraining' }]);
  });

  it('delete -> nothing', () => {
    expect(classifyTrainingWrite(base, undefined)).toEqual([]);
  });

  it('cancel -> trainingChanged/cancelled', () => {
    expect(classifyTrainingWrite(base, { ...base, status: 'cancelled' })).toEqual([
      { type: 'trainingChanged', change: 'cancelled' },
    ]);
  });

  it('startAt change -> trainingChanged/moved', () => {
    const after = { ...base, startAt: new Date('2026-11-13T14:00:00Z') };
    expect(classifyTrainingWrite(base, after)).toEqual([{ type: 'trainingChanged', change: 'moved' }]);
  });

  it('status-only change to moved (trigger follow-up write) -> nothing (no loop)', () => {
    expect(classifyTrainingWrite(base, { ...base, status: 'moved' })).toEqual([]);
  });

  it('photos grown -> newPhotos with count; shrink -> nothing', () => {
    const after = { ...base, photoUrls: ['a', 'b'] };
    expect(classifyTrainingWrite(base, after)).toEqual([{ type: 'newPhotos', added: 2 }]);
    expect(classifyTrainingWrite(after, base)).toEqual([]);
  });

  it('reminderSentAt bookkeeping -> nothing', () => {
    expect(classifyTrainingWrite(base, { ...base, reminderSentAt: new Date() })).toEqual([]);
  });
});

describe('movedTrainingPatch', () => {
  it('sets moved + previousStartAt when startAt changes', () => {
    const after = { ...base, startAt: new Date('2026-11-13T14:00:00Z') };
    expect(movedTrainingPatch(base, after)).toEqual({ status: 'moved', previousStartAt: base.startAt, clearReminder: true });
  });

  it('no patch when unchanged or cancelled', () => {
    expect(movedTrainingPatch(base, { ...base })).toBeNull();
    expect(movedTrainingPatch(base, { ...base, status: 'cancelled', startAt: new Date('2026-11-13T00:00:00Z') })).toBeNull();
    expect(movedTrainingPatch(undefined, base)).toBeNull();
  });
});

describe('isTrainingReminderDue', () => {
  const now = new Date('2026-11-12T12:00:00Z');
  it('due within (now, now+2h]', () => {
    expect(isTrainingReminderDue(base, now)).toBe(true); // exactly 2h
    expect(isTrainingReminderDue({ ...base, startAt: new Date('2026-11-12T12:01:00Z') }, now)).toBe(true);
  });
  it('not due outside the window, when already sent or not active', () => {
    expect(isTrainingReminderDue({ ...base, startAt: new Date('2026-11-12T14:00:01Z') }, now)).toBe(false);
    expect(isTrainingReminderDue({ ...base, startAt: now }, now)).toBe(false);
    expect(isTrainingReminderDue({ ...base, reminderSentAt: now }, now)).toBe(false);
    expect(isTrainingReminderDue({ ...base, status: 'cancelled' }, now)).toBe(false);
    expect(isTrainingReminderDue({ ...base, status: 'moved' }, now)).toBe(true);
  });
});
